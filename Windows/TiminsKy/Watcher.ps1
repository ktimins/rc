Function Invoke-Watcher {
   Param(
         [Parameter(Mandatory=$true,)]
         [String]$Folder;
         [Parameter(Mandatory=$false)]
         [String]$Filter
        );

}


$folder = '\\Filer01\dailybuilds\C2\PRINT\TEMP\PFILES\BillingXML'

$filter = '*.Billing.XML'

$watcher = New-Object System.IO.FileSystemWatcher $folder, $filter -Property @{
   IncludeSubdirectories = $true;
   NotifyFilter = [System.IO.NotifyFilters]'FileName,LastWrite,CreationTime';
}

$action = {
   $name = $Event.SourceEventArgs.Name;
   $fullName = $Event.SourceEventArgs.FullPath;
   $timeStamp = $Event.TimeGenerated;
   $changeType = $Event.SourceEventArgs.ChangeType;
   $str = "The file '$name' was $changeType at $timeStamp";
   Write-Host $str -fore green;
   Out-File -FilePath 'F:\XML\C2\outlog.txt' -Append -InputObject $str;
   Copy-Item -Path $fullName -Destination "F:\XML\C2\GoodXML\$name"
      If ($?) {
         $strCopy = "The file '$name' was copied to 'F:\XML\C2\GoodXML\$name'.";
         Write-Host $strCopy -fore blue;
         Out-File -FilePath 'F:\XML\C2\outlog.txt' -Append -InputObject $strCopy;
      }
}
Register-ObjectEvent $watcher Created -SourceIdentifier FileCreated -Action $action;
Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action $action;
