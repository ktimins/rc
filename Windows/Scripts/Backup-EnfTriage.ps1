$date = Get-Date -format yyyy-MM-dd

$sourceDir     = 'C:\Users\TiminsKY\Documents\ENF\ENF Triage'
$descDir       = "\\filer02\GDrive\USERS\TiminsKy\ENF\ENF Triage"
$descDirDate   = "$descDir\$date"

Robocopy.exe $sourceDir $descDir
Robocopy.exe $sourceDir $descDirDate
