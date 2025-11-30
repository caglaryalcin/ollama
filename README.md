## WSL + Ubuntu + Docker + Ollama Automated Installation Script

This script allows you to run Olla externally using your existing GPU by installing Docker on WSL on Windows 11 and then installing Ollama on Docker.

## Start the script

> [!NOTE]  
> After the script finishes, it will automatically start running on WSL. If you want to undo everything the script did after running it;

```powershell
iwr "caglaryalcin.com/ollama-del" -UseB | iex
```

> [!WARNING]  
> After the script finishes, Ollama will start running automatically on WSL. If you want to cancel Ollama, you can kill WSL via Task Manager and then disable the OllamaWSL task in Task Scheduler.

> [!IMPORTANT]  
> Powershell must be run as admin

```powershell
iwr "caglaryalcin.com/ollama" -UseB | iex
```

<img width="748" height="1454" alt="image" src="https://github.com/user-attachments/assets/a4a5824d-9a91-4881-9c15-9833abbceee1" />
