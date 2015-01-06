net use "\\it153cfs03\itapp\ConfluenceBackups\AutomatedBackups" /delete

# $username = Get-Content -Path D:\PowerShell-backup\storedEncryptedUsername.txt | ConvertTo-SecureString
$username = "Cwikbupitsvc"

$password = Get-Content -Path D:\PowerShell-backup\storedEncryptedPassword.txt | ConvertTo-SecureString

$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password

New-PSDrive -name X -psprovider FileSystem -root "\\it153cfs03\itapp\ConfluenceBackups\AutomatedBackups" -Credential $cred -Description "Maps to confluence backup folder on the network drive."

# Move-Item $srcfile -Destination $destParentFolder -Force

Copy-Item "D:\eula.1028.txt" -Destination "X:\PSBackups" -Force