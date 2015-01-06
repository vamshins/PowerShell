
#==========
# Author : Vamshi
# Function :
# Date created : 12/11/2014
#==========

# These two come from the command line arguments.
# $Src = "E:\UNM IT\PowerShell\Moving_Confluence_Backups\src".ToLower()
# $DestPath = "E:\UNM IT\PowerShell\Moving_Confluence_Backups\dest".ToLower()

$Src = $args[0].ToLower()
$DestPath = $args[1].ToLower()
[datetime[]]$destDateArray = @()

$dte = Get-Date
$dteformatted = Get-Date $dte -format yyyy_M_dd-h_m_s

$destParentPath = Split-Path $DestPath -Parent
$logPath = "$destParentPath`\PowerShellLogs\PS_Backup-$dteformatted.log"

#==========
# Functions
#==========

function writeLog($logString){
    Write-Host "$logString"
    $SampleString = "{0} INFO: $logString" -f (Get-Date).ToString("yyyy_M_dd-h:m:s")
    add-content -Path $logPath -Value $SampleString -Force
}


function process-file ($srcfile) {
    #$srcfile should be a string, full path to a file
    #e.g. 'c:\users\test\Documents\file.txt'

    # Make the destination file full path
    $destItem = $srcfile.ToLower().Replace($Src, $DestPath)

    if (-not (Test-Path $destItem)) {                                            #File doesn't exist in destination
        
       

        #Is there a folder to put it in? If not, make one
       # $destParentFolder = Split-Path $destItem -Parent
       # if (-not (Test-Path $destParentFolder)) { mkdir $destParentFolder }

        # Move file
        writeLog("Moving file $srcfile to $DestPath")
        
        Move-Item $srcfile -Destination $DestPath

    } else {  #File does exist

        if ((Get-Item $srcfile).LastAccessTimeUtc -gt (Get-Item $destItem).LastAccessTimeUtc) {

            #Source file is newer, move it
            $destParentFolder = Split-Path $destItem -Parent

            writeLog("Moving file $srcfile to $destParentFolder")

            Move-Item $srcfile -Destination $destParentFolder -Force
        }
    }
}

function process-dest($destfile){

    #$srcfile should be a string, full path to a file
    #e.g. 'c:\users\test\Documents\file.txt'
        
    $fileName = split-path $destfile -leaf -resolve           # get the filename in the dest folder (not the full path, just filename)
    
    if ($fileName -like "*01_31*" -or
        $fileName -like "*02_28*" -or
        $fileName -like "*02_29*" -or
        $fileName -like "*03_31*" -or
        $fileName -like "*04_30*" -or
        $fileName -like "*05_31*" -or
        $fileName -like "*06_30*" -or
        $fileName -like "*07_31*" -or
        $fileName -like "*08_31*" -or
        $fileName -like "*09_30*" -or
        $fileName -like "*10_31*" -or
        $fileName -like "*11_30*" -or
        $fileName -like "*12_31*") {
        
        $enddatesdir = [string]::Concat($DestPath, '\enddates')
        if (-not (Test-Path $enddatesdir)) {
            New-Item -ItemType Directory -Force -Path $enddatesdir
        }

        writeLog("Moving file $destfile to $enddatesdir")

        Move-Item $destfile -Destination $enddatesdir -Force

        return $null
    
    }
    else {

    $fileName = split-path $destfile -leaf -resolve                           # get the filename in the src folder (not the full path, just filename)

    $lastIndexOfHyphen = $fileName.LastIndexOf("-")                          # Since the format is backup-yyyy_MM_dd, we want extract only the date part.
    $dateOfBackup = $fileName.Substring($lastIndexOfHyphen+1, 10)
    
    $tempdate=[datetime]::ParseExact($dateOfBackup, "yyyy_MM_dd", $null)     # Parse the date into format "12/11/2014 12:00:00 AM"
    
    return $tempdate

    }
}


#==========
# Main code
#==========

writeLog("============================================")
writeLog("         Movement of Backup files")
writeLog("============================================")
writeLog("Source Folder : $Src")
writeLog("Source Folder : $DestPath `n")

writeLog("Step 1: Finding the files corresponding to last dates of the months and moving them into separate folder $DestPath`\enddates...")
Get-ChildItem $DestPath | ForEach { 
    if (-not($_.PsIsContainer)) {
        $date = process-dest ($_.FullName)
        if ($date -ne $null) {
            $destDateArray += $date
        }
    }
}|Out-Null

writeLog("Step 1: Done.. Please check for errors")
writeLog("-----------------------------------------------------------------")

writeLog("Step 2: Finding the files older than 30 days and deleting them...")

$destDateArrayCount = $destDateArray.Count
$tempCount = $destDateArrayCount - 30

if($destDateArrayCount -ne 30){
    for ($i=0; $i -le $tempCount-1; $i++) {
        $destDateArray[$i]
        # writeLog($destDateArrayCount)
        
        $destDateArrayFormatted = Get-Date $destDateArray[$i] -format yyyy_MM_dd
        $destDateArrayFormatted
        # writeLog($DateStr)
        $DateFile = get-childitem -Path "$DestPath\*" -Include *$destDateArrayFormatted*
        # writeLog($DateFile)
        writeLog("Deleting : $DateFile as it is older than 30 last backed up files `n")
        Remove-Item $DateFile
        $destDateArrayCount = $destDateArrayCount - 1
    }
} else {
    writeLog("Number of files in the destination are < 30. No files deleted!")
}

writeLog("Step 2: Done.. Please check for errors")
writeLog("-----------------------------------------------------------------")

writeLog("Step 3: Moving the backup files from $Src to $DestPath...")

Get-ChildItem $Src -Recurse | ForEach { 
    if (-not($_.PsIsContainer)) {
        process-file ($_.FullName)
    }
}|Out-Null

writeLog("Step 3: Done.. Please check for errors")
writeLog("-----------------------------------------------------------------")

writeLog("Step 4: If there are any files which belongs to last date of the months, then moving them from $DestPath to $DestPath`\enddates")

Get-ChildItem $DestPath | ForEach { 
    if (-not($_.PsIsContainer)) {
        $date = process-dest ($_.FullName)
        if ($date -ne $null) {
            $destDateArray += $date
        }
    }
}|Out-Null

writeLog("Step 4: Done.. Please check for errors")
writeLog("-----------------------------------------------------------------")

writeLog("Completed!!!")
