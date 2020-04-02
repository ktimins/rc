$files = Get-ChildItem -Path c:\Temp
For($i = 1; $i -le $files.count; $i++) { 
   Write-Progress -Activity "Collecting files" -status "Finding file $i" `
   -percentComplete ($i / $files.count*100)
}
$files | Select name
