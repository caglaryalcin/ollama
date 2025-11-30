[IO.File]::WriteAllText("$env:TEMP\i.ps1",(iwr https://raw.githubusercontent.com/caglaryalcin/ollama/main/install.ps1).Content,[Text.Encoding]::UTF8);&$env:TEMP\i.ps1
