
#===============================================================================================================================================
# File Name     : Move-Item.ps1
# Author        : Vamshi
# Date created  : 12/11/2014
# Functionality : Confluence takes backup of it's DB every single day in a folder (Source Dir for this program).
#                 This program copies all the stuff from Source to Destination directory based on some conditions.
#                 The conditions are:
#                           Step 1: Copy the end date files in the destination folder into separate folder called as "enddates".
#                                   End dates are last days of the months.
#                           Step 2: Find the files older than 30 days and delete them.
#                           Step 3: Move the backup files from <Source> to <Destination>
#                           Step 4: If there are any files which belong to last date of the months, then move them from <Destination> to <Destination>\enddates
#                                   (This is same as Step 1)
#                 Folder Structure:
#                 Source      : ....>\<source folder>
#                 Destination : ....>\PSBackups             # Store the files of normal dates. (No month end dates)
#                                    \PSBackups\enddates    # Store the files of month end dates of respective months
#                                    \PowerShellLogs        # Store the log files
# Execution     : Executed as part of the batch command file 'Move-Backups.bat'
#                    --> Move-Backups.bat <SourceDir> <DestinationDir>
#                    --> Move-Backups.bat contains the following code
#                        
#                        powershell.exe -executionpolicy ByPass -File "<some_path>\Move-Item.ps1" %1 %2                 
#===============================================================================================================================================

# These two come from the command line arguments.
# $Src = "E:\UNM IT\PowerShell\Moving_Confluence_Backups\src".ToLower()
# $DestPath = "E:\UNM IT\PowerShell\Moving_Confluence_Backups\dest".ToLower()

# Source Directory where backups are present
$Src = $args[0].ToLower()

# Destination Directory			
$DestPath = $args[1].ToLower()

# Array to store the information of Normal date files.
[datetime[]]$destDateArray = @()

# Get the current datetime.
$dte = Get-Date

# Format the current datetime
$dteformatted = Get-Date $dte -format yyyy_M_dd-h_m_s   #Format the date

# Get the parent folder path of the destination so that the log file can be created in the folder "PowerShellLogs" present in the parent folder.
$destParentPath = Split-Path $DestPath -Parent

# Path of the log file
$logPath = "$destParentPath`\PowerShellLogs\PS_Backup-$dteformatted.log"

#==========
# Functions
#==========

# Function to write log to the Host (Command window) and also to the log file
function writeLog($logString){
    Write-Host "$logString"
    $SampleString = "{0} INFO: $logString" -f (Get-Date).ToString("yyyy_M_dd-h:m:s")
    add-content -Path $logPath -Value $SampleString -Force
}

# Function to process the source files i.e., copying them to the destination folder.
# This function doesn't return anything.
function process-file ($srcfile) {
    # $srcfile should be a string, full path to a file
    # e.g. 'E:\UNM IT\PowerShell\Moving_Confluence_Backups\src\backup-2014_08_31.zip'

    # Make the destination file full path
    $destItem = $srcfile.ToLower().Replace($Src, $DestPath)

    # Check if file doesn't exist in destination
    if (-not (Test-Path $destItem)) {
       

        # Is there a folder to put it in? If not, make one
        # $destParentFolder = Split-Path $destItem -Parent
        # if (-not (Test-Path $destParentFolder)) { mkdir $destParentFolder }

        writeLog("Moving file $srcfile to $DestPath")
        
        # Move file
        Move-Item $srcfile -Destination $DestPath

    } else {  # File does exist and we want to copy the latest modified file.

        if ((Get-Item $srcfile).LastAccessTimeUtc -gt (Get-Item $destItem).LastAccessTimeUtc) {

            # Source file is newer, move it
            $destParentFolder = Split-Path $destItem -Parent

            writeLog("Moving file $srcfile to $destParentFolder")

            Move-Item $srcfile -Destination $destParentFolder -Force
        }
    }
}

# Function to process the destination files i.e., copying backup of end dates to separate folder "enddates".
# This function returns - null, if the file is end date file.
#                         date, if the file is normal date file.
# The reason why we are doing is, we are storing the dates of normal files in the array '$destDateArray' to process and 
# delete the files which are older than last 30 latest files in the destination folder.
function process-dest($destfile){

    # $destfile should be a string, full path to a file
    # e.g. 'E:\UNM IT\PowerShell\Moving_Confluence_Backups\dest\backup-2014_01_02.zip'
    
    # get the filename in the dest folder (not the full path, just filename)
    $fileName = split-path $destfile -leaf -resolve
    
    # Check if the file name is end date of the respective month or not. If it is, then move to 'enddates' folder
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
        
        # If there is no 'enddates' directory, then create one.
        $enddatesdir = [string]::Concat($DestPath, '\enddates')
        if (-not (Test-Path $enddatesdir)) {
            New-Item -ItemType Directory -Force -Path $enddatesdir
        }

        writeLog("Moving file $destfile to $enddatesdir")

        # Move file
        Move-Item $destfile -Destination $enddatesdir -Force

        return $null
    
    }
    # If the file is normal date file, then get the date out of the filename and return it to the caller.
    else {
        # get the filename in the destination folder (not the full path, just filename)
        $fileName = split-path $destfile -leaf -resolve

        # Since the format is backup-yyyy_MM_dd, we want to extract only the date part.
        $lastIndexOfHyphen = $fileName.LastIndexOf("-")
        $dateOfBackup = $fileName.Substring($lastIndexOfHyphen+1, 10)
        
        # Parse the date into format "12/11/2014 12:00:00 AM"
        $tempdate=[datetime]::ParseExact($dateOfBackup, "yyyy_MM_dd", $null)
    
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

# Get the files in the Destination folder and pipe them to ForEach for processing.
# Stores the return values(normal dates) from the function 'process-dest' and stores them in the array $destDateArray
# If it returns null(end dates), then we don't store them in the array.
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

writeLog("Step 2: Finding the files older than last 30 latest files in the destination folder and deleting them...")

# Finds older files and delete them 
$destDateArrayCount = $destDateArray.Count
$tempCount = $destDateArrayCount - 30

if($destDateArrayCount -ge 30){
    for ($i=0; $i -le $tempCount-1; $i++) {
        $destDateArray[$i]
        # writeLog($destDateArrayCount)
        
        $destDateArrayFormatted = Get-Date $destDateArray[$i] -format yyyy_MM_dd
        $destDateArrayFormatted

        # Find the file that matches with the pattern of value from the '$destDateArray[$i]'
        $DateFile = get-childitem -Path "$DestPath\*" -Include *$destDateArrayFormatted*

        writeLog("Deleting : $DateFile as it is older than 30 last backed up files `n")

        # Deletes file
        Remove-Item $DateFile

        $destDateArrayCount = $destDateArrayCount - 1
    }
} else {
    writeLog("Number of files in the destination are < 30. No files deleted!")
}

writeLog("Step 2: Done.. Please check for errors")
writeLog("-----------------------------------------------------------------")

writeLog("Step 3: Moving the backup files from $Src to $DestPath...")

# Get the files in the source folder and pipe them to ForEach for processing. The function process-file() copies the files from source to the destination.
Get-ChildItem $Src -Recurse | ForEach { 
    if (-not($_.PsIsContainer)) {
        process-file ($_.FullName)
    }
}|Out-Null

writeLog("Step 3: Done.. Please check for errors")
writeLog("-----------------------------------------------------------------")

writeLog("Step 4: If there are any files which belong to last date of the months, then moving them from $DestPath to $DestPath`\enddates")

# Calling this code again(same as Step 1), just to ensure that if there any files from source folder which are enddate files, we move them to the enddates folder in the destination.
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
