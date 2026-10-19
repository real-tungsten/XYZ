# 1. Check for Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[-] Please run this script as Administrator!" -ForegroundColor Red
    Pause
    Exit
}

Write-Host "[+] Admin privileges confirmed." -ForegroundColor Green

# 2. Install OpenSSH Server if not already installed
$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshServer.State -ne 'Installed') {
    Write-Host "[*] Installing OpenSSH Server..." -ForegroundColor Yellow
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
} else {
    Write-Host "[+] OpenSSH Server is already installed." -ForegroundColor Green
}

# 3. Start and Enable SSH Service
Write-Host "[*] Configuring SSH Service..." -ForegroundColor Yellow
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 4. Ensure Firewall Allows SSH (Port 22)
$fwRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if (-not $fwRule) {
    Write-Host "[*] Creating Firewall Rule for SSH..." -ForegroundColor Yellow
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
} else {
    Write-Host "[+] Firewall rule for SSH already exists." -ForegroundColor Green
}

# 5. Download Ngrok if not present in the current folder
$ngrokPath = "$PSScriptRoot\ngrok.exe"
if (-not (Test-Path $ngrokPath)) {
    Write-Host "[*] Downloading Ngrok..." -ForegroundColor Yellow
    $zipPath = "$PSScriptRoot\ngrok.zip"
    Invoke-WebRequest -Uri "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip" -OutFile $zipPath
    Write-Host "[*] Extracting Ngrok..." -ForegroundColor Yellow
    Expand-Archive -Path $zipPath -DestinationPath $PSScriptRoot -Force
    Remove-Item $zipPath
} else {
    Write-Host "[+] Ngrok found locally." -ForegroundColor Green
}

# 6. Automatically start Ngrok TCP Tunnel for Port 22
Write-Host "[+] Starting Ngrok Tunnel automatically..." -ForegroundColor Green
Write-Host "[*] Copy the forwarding address below and use it on Kali Linux!" -ForegroundColor Cyan
Write-Host "--------------------------------------------------------" -ForegroundColor DarkGray

Start-Process -FilePath "$ngrokPath" -ArgumentList "tcp 22" -NoNewWindow
