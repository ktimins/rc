param(
      [String]$Path,
      [String]$CopyToPath,
      [Switch]$Recursive
     );

$FileSystemWatcher = New-Object System.IO.FileSystemWatcher;
$FileSystemWatcher.Path  = $Path;
$FileSystemWatcher.IncludeSubdirectories = $Recursive;

# make sure the watcher emits events
$FileSystemWatcher.EnableRaisingEvents = $true;

# define the code that should execute when a file change is detected
$Action = {
   $details = $event.SourceEventArgs;
   $Name = $details.Name;
   $FullPath = $details.FullPath;
   #$OldFullPath = $details.OldFullPath;
   $OldName = $details.OldName;
   $ChangeType = $details.ChangeType;
   $Timestamp = $event.TimeGenerated;
   $text = "{0} was {1} at {2}" -f $FullPath, $ChangeType, $Timestamp;
   Write-Host "";
   Write-Host $text -ForegroundColor Green;

   # you can also execute code based on change type here
   switch ($ChangeType)
   {
      'Changed' { 
         Write-Output "CHANGED";
         if ([string]::IsNullOrWhiteSpace($CopyToPath)) {
            Copy-Item -Path $FullPath -Destination (Join-Path -Path 'C:\Temp\temp' -ChildPath $Name);
         }
      }
      'Created' { 
         Write-Output "CREATED";
         Copy-Item -Path $FullPath -Destination (Join-Path -Path 'C:\Temp\temp' -ChildPath $Name);
      }
      'Deleted' { "DELETED"
         # uncomment the below to mimick a time intensive handler
         <#
            Write-Host "Deletion Handler Start" -ForegroundColor Gray
            Start-Sleep -Seconds 4    
            Write-Host "Deletion Handler End" -ForegroundColor Gray
         #>
      }
      'Renamed' { 
         # this executes only when a file was renamed
         $text = "File {0} was renamed to {1}" -f $OldName, $Name;
         Write-Host $text -ForegroundColor Yellow;
      }
      default { Write-Host $_ -ForegroundColor Red -BackgroundColor White; }
   }
}

# add event handlers
$handlers = . {
   Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Changed -Action $Action -SourceIdentifier FSChange;
   Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Created -Action $Action -SourceIdentifier FSCreate;
   Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Deleted -Action $Action -SourceIdentifier FSDelete;
   Register-ObjectEvent -InputObject $FileSystemWatcher -EventName Renamed -Action $Action -SourceIdentifier FSRename;
}

Write-Host "Watching for changes to $PathToMonitor";

try
{
   do
   {
      Wait-Event -Timeout 1;
      Write-Host "." -NoNewline;

   } while ($true)
}
finally
{
   # this gets executed when user presses CTRL+C
   # remove the event handlers
   Unregister-Event -SourceIdentifier FSChange;
   Unregister-Event -SourceIdentifier FSCreate;
   Unregister-Event -SourceIdentifier FSDelete;
   Unregister-Event -SourceIdentifier FSRename;
   # remove background jobs
   $handlers | Remove-Job;
   # remove filesystemwatcher
   $FileSystemWatcher.EnableRaisingEvents = $false;
   $FileSystemWatcher.Dispose();
   "Event Handler disabled."
}

