Write-Host "Everything loaded with the Ollama script is being removed..." -NoNewLine
netsh interface portproxy reset
Get-NetFirewallRule -DisplayName "*WSL*" | Remove-NetFirewallRule
Unregister-ScheduledTask -TaskName "*WSL*" -Confirm:$false -ErrorAction SilentlyContinue
taskkill /F /IM wsl.exe *>$null
Remove-Item "$env:USERPROFILE\.wslconfig" -Force -ErrorAction SilentlyContinue
wsl --shutdown
wsl --unregister Ubuntu *>$null
Write-Host "[DONE]Everything has been cleaned up" -ForegroundColor Green
