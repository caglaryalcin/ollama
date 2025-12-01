Write-Host "╔═════════════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║    WSL + Ubuntu + Docker + Ollama Automated Installation Script     ║" -ForegroundColor Cyan
Write-Host "╚═════════════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan

# =============================================================================
# 0. User Information
# =============================================================================
Write-Host "`n[0/12] User information..." -ForegroundColor Yellow

do {
    $wslUsername = Read-Host "Enter WSL username"
    if ([string]::IsNullOrWhiteSpace($wslUsername)) {
        Write-Host "  ✗ Username cannot be empty!" -ForegroundColor Red
    }
} while ([string]::IsNullOrWhiteSpace($wslUsername))

do {
    $wslPasswordSecure = Read-Host "Enter WSL password" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($wslPasswordSecure)
    $wslPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    
    if ([string]::IsNullOrWhiteSpace($wslPassword)) {
        Write-Host "  ✗ Password cannot be empty!" -ForegroundColor Red
    }
} while ([string]::IsNullOrWhiteSpace($wslPassword))

Write-Host "  ✓ Username: $wslUsername" -ForegroundColor Green
Write-Host "  ✓ Password: "("*"* $wslPassword.Length) -ForegroundColor Green

# =============================================================================
# 1. .wslconfig Configuration
# =============================================================================
Write-Host "`n[1/12] .wslconfig is being created..." -ForegroundColor Yellow

$wslConfig = @"
[wsl2]
memory=8GB
processors=4
networkingMode=mirrored
dnsTunneling=true
firewall=false
autoProxy=false
"@

$wslConfig | Out-File -FilePath "$env:USERPROFILE\.wslconfig" -Encoding UTF8 -Force
Write-Host "  ✓ .wslconfig created" -ForegroundColor Green

# =============================================================================
# 2. Ubuntu Installation
# =============================================================================
Write-Host "`n[2/12] Installing Ubuntu..." -ForegroundColor Yellow
wsl --install -d Ubuntu --no-launch *>$null
Start-Sleep 5
Write-Host "  ✓ Ubuntu has been installed" -ForegroundColor Green

# =============================================================================
# 3. WSL First Start
# =============================================================================
Write-Host "`n[3/12] Ubuntu is starting up for the first time..." -ForegroundColor Yellow
wsl -d Ubuntu -u root -- bash -c "exit" 2>$null
Start-Sleep 3
Write-Host "  ✓ Ubuntu has been launched" -ForegroundColor Green

# =============================================================================
# 4. User Creation
# =============================================================================
Write-Host "`n[4/12] User configuration..." -ForegroundColor Yellow
wsl -d Ubuntu -u root -- useradd -m -s /bin/bash $wslUsername 2>$null
wsl -d Ubuntu -u root -- bash -c "echo '${wslUsername}:${wslPassword}' | chpasswd" 2>$null
wsl -d Ubuntu -u root -- bash -c "usermod -aG sudo $wslUsername" 2>$null
Write-Host "  ✓ User " -NoNewLine
Write-Host "$wslUsername " -ForegroundColor Green -NoNewLine
Write-Host "created"

# =============================================================================
# 5. Passwordless Sudo
# =============================================================================
Write-Host "`n[5/13] Sudo passwordless configuration..." -ForegroundColor Yellow
wsl -d Ubuntu -u root -- bash -c "echo '$wslUsername ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/$wslUsername" 2>$null
wsl -d Ubuntu -u root -- bash -c "chmod 0440 /etc/sudoers.d/$wslUsername" 2>$null
Write-Host "  ✓ Passwordless sudo has been set up" -ForegroundColor Green

# =============================================================================
# 6. WSL Configuration
# =============================================================================
Write-Host "`n[6/12] ⏳ wsl.conf Configuration..." -ForegroundColor Yellow
wsl -d Ubuntu -u root -- bash -c "cat > /etc/wsl.conf << EOF
[user]
default=$wslUsername

[boot]
systemd=true

[network]
generateResolvConf=true
hostname=$wslUsername
EOF" 2>$null
Write-Host "  ✓ /etc/wsl.conf has been created" -ForegroundColor Green

Write-Host "  ⏳ WSL is restarting..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep 5
wsl -d Ubuntu -u $wslUsername -- bash -c "exit" 2>$null
Start-Sleep 2
Write-Host "  ✓ WSL restarted with user $wslUsername" -ForegroundColor Green

# =============================================================================
# 7. System Update & Docker Installation
# =============================================================================
Write-Host "`n[7/12] The system is updating and Docker is being installed..." -ForegroundColor Yellow
wsl -d Ubuntu -u root -- bash -c 'DEBIAN_FRONTEND=noninteractive apt update -qq > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c 'DEBIAN_FRONTEND=noninteractive apt upgrade -y -qq > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c 'apt install -y -qq ca-certificates curl gnupg lsb-release > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c 'mkdir -p /etc/apt/keyrings' 2>$null
wsl -d Ubuntu -u root -- bash -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null'
wsl -d Ubuntu -u root -- bash -c 'cat > /etc/apt/sources.list.d/docker.list << EOF
deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable
EOF' 2>$null

wsl -d Ubuntu -u root -- bash -c 'apt update -qq > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c 'apt install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c "usermod -aG docker $wslUsername" 2>$null
wsl -d Ubuntu -u root -- bash -c 'systemctl enable docker > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c 'systemctl start docker' 2>$null
Start-Sleep 5

$dockerVersion = wsl -d Ubuntu -u root -- docker --version 2>$null
if ($dockerVersion) {
    Write-Host "  ✓ Docker has been installed: $dockerVersion" -ForegroundColor Green
} else {
    Write-Host "  ✗ Docker installation failed!" -ForegroundColor Red
    exit 1
}

Write-Host "  ⏳ Restarting WSL for Docker group changes..." -ForegroundColor Yellow
wsl --shutdown
Start-Sleep 5
wsl -d Ubuntu -u $wslUsername -- bash -c "exit" 2>$null
Start-Sleep 2
Write-Host "  ✓ WSL restarted" -ForegroundColor Green

# =============================================================================
# 8. NVIDIA Container Toolkit
# =============================================================================
Write-Host "`n[8/12] NVIDIA Container Toolkit is being installed..." -ForegroundColor Yellow

wsl -d Ubuntu -u root -- bash -c 'curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg 2>/dev/null'
wsl -d Ubuntu -u root -- bash -c "curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' > /etc/apt/sources.list.d/nvidia-container-toolkit.list 2>/dev/null"
wsl -d Ubuntu -u root -- bash -c 'apt update -qq > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c 'apt install -y -qq nvidia-container-toolkit > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c 'nvidia-ctk runtime configure --runtime=docker > /dev/null 2>&1'
wsl -d Ubuntu -u root -- bash -c 'mkdir -p /etc/systemd/system/docker.service.d' 2>$null
wsl -d Ubuntu -u root -- bash -c 'cat > /etc/systemd/system/docker.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd
EOF' 2>$null

wsl -d Ubuntu -u root -- bash -c 'systemctl daemon-reload' 2>$null
wsl -d Ubuntu -u root -- bash -c 'systemctl restart docker' 2>$null
Start-Sleep 5

$nvidiaSmi = wsl -d Ubuntu -- nvidia-smi 2>$null
if ($nvidiaSmi -match "NVIDIA-SMI") {
    Write-Host "  ✓ NVIDIA Container Toolkit has been installed and the GPU has been detected" -ForegroundColor Green
} else {
    Write-Host "  ⚠ NVIDIA Container Toolkit was installed but the GPU could not be detected" -ForegroundColor Yellow
}

# =============================================================================
# 9. Ollama Container
# =============================================================================
Write-Host "`n[9/12] Ollama container is starting..." -ForegroundColor Yellow

wsl -d Ubuntu -- bash -c 'docker pull ollama/ollama' 2>$null | Out-Null
wsl -d Ubuntu -- bash -c 'docker run -d --gpus=all --restart=always -p 0.0.0.0:11434:11434 --name ollama ollama/ollama' 2>$null | Out-Null
Start-Sleep 10

$containerCheck = wsl -d Ubuntu -- docker ps --filter "name=ollama" --format "{{.Status}}" 2>$null
if ($containerCheck -match "Up") {
    Write-Host "  ✓ Ollama container started (with GPU support)" -ForegroundColor Green
} else {
    Write-Host "  ✗ The container could not be started!" -ForegroundColor Red
    wsl -d Ubuntu -- docker logs ollama
    exit 1
}

# =============================================================================
# 10. Windows Firewall
# =============================================================================
Write-Host "`n[10/12] Windows Firewall is being configured..." -ForegroundColor Yellow
Get-NetFirewallRule -DisplayName "*Ollama*" -ErrorAction SilentlyContinue | Remove-NetFirewallRule 2>$null
New-NetFirewallRule -DisplayName "Ollama WSL Docker" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 11434 -Profile Any -Enabled True *>$null
Write-Host "  ✓ Firewall rule added" -ForegroundColor Green

# =============================================================================
# 11. Windows Startup Task
# =============================================================================
Write-Host "`n[11/12] Windows startup task is being created..." -ForegroundColor Yellow

Unregister-ScheduledTask -TaskName "OllamaWSL" -Confirm:$false -ErrorAction SilentlyContinue 2>$null

$vbsScript = @"
Set WshShell = CreateObject("WScript.Shell")
WshShell.Run "wsl.exe -d Ubuntu -- sleep infinity", 0, False
"@

$vbsPath = "$env:TEMP\StartOllamaWSL.vbs"
$vbsScript | Out-File -FilePath $vbsPath -Encoding ASCII

$currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
$action = New-ScheduledTaskAction -Execute "wscript.exe" -Argument "`"$vbsPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId $currentUser -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -Hidden

Register-ScheduledTask -TaskName "OllamaWSL" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force *>$null
Start-ScheduledTask -TaskName "OllamaWSL" 2>$null
Start-Sleep 10

Write-Host "  ✓ The startup task has been created and WSL has been launched" -ForegroundColor Green

# =============================================================================
# 12. Final Verification
# =============================================================================
Write-Host "`n[12/12] Status checks are being performed..." -ForegroundColor Yellow

$dockerStatus = wsl -d Ubuntu -- docker ps --filter "name=ollama" --format "{{.Status}}" 2>$null
if ($dockerStatus -match "Up") {
    Write-Host "  ✓ The container is working" -ForegroundColor Green
} else {
    Write-Host "  ✗ The container isn't working!" -ForegroundColor Red
}

Write-Host "  ⏳ http://localhost:11434 is being tested (waiting 20 seconds)..." -ForegroundColor Yellow
Start-Sleep 20

$curlResult = curl.exe -s http://localhost:11434
if ($curlResult -match "Ollama is running") {
    Write-Host "  ✓ localhost:11434 is accessible" -ForegroundColor Green
} else {
    Write-Host "  ⚠ localhost:11434 is currently unavailable (WSL may be starting)" -ForegroundColor Yellow
}

$externalIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Ethernet*" | Where-Object {$_.IPAddress -notmatch "^169"} | Select-Object -First 1).IPAddress

# =============================================================================
# Results
# =============================================================================
Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║           Installation Successfully Completed!             ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green

Write-Host "`n📍 Access Information:" -ForegroundColor Cyan
Write-Host "  • Local access:     http://localhost:11434" -ForegroundColor White
if ($externalIP) {
    Write-Host "  • External access:  http://${externalIP}:11434" -ForegroundColor White
}

Write-Host "`n🎮 GPU Support:" -ForegroundColor Cyan
$nvidiaSmiCheck = wsl -d Ubuntu -- nvidia-smi 2>$null
if ($nvidiaSmiCheck -match "NVIDIA-SMI") {
    Write-Host "  ✓ NVIDIA Container Toolkit installed"
    
    $ollamaGpuCheck = wsl -d Ubuntu -- docker exec ollama nvidia-smi 2>$null
    if ($ollamaGpuCheck -match "NVIDIA-SMI") {
        Write-Host "  ✓ Ollama running with GPU support"
    } else {
        Write-Host "  ⚠ Ollama container started but GPU not detected" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ✗ NVIDIA GPU not detected" -ForegroundColor Red
}

$taskCheck = Get-ScheduledTask -TaskName "OllamaWSL" -ErrorAction SilentlyContinue
if ($taskCheck -and $taskCheck.State -eq "Ready") {
    Write-Host "`n✅ Ollama will start automatically on Windows boot"
} else {
    Write-Host "`n⚠ Auto-start task may not be configured correctly" -ForegroundColor Yellow
}

Write-Host "`n💡 Tip: Wait 30-60 seconds after first boot" -ForegroundColor Cyan