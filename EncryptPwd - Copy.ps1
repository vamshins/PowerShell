# Prompt the user to enter a password
$secure = Read-Host -AsSecureString "Enter a secret password"

$encrypted = convertfrom-securestring -secureString $secure -key (1..16)

$encrypted | set-content D:\PowerShell-backup\encrypted.txt