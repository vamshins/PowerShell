# Prompt the user to enter a password
$secureString = Read-Host -AsSecureString "Enter a secret password"

$secureString | ConvertFrom-SecureString | Out-File -FilePath D:\PowerShell-backup\storedEncryptedPassword.txt