
Write-Progress -Activity "Resetting IIS" -Id 0;

Write-Progress -Activity "Resetting IIS" -Status "Stopping and Starting IIS" -CurrentOperation "Running `"iisreset.exe`"" -Id 0;

& iisreset;

Write-Progress -Activity "Resetting IIS" -Status "Pulling Up PDServices" -CurrentOperation "Calling PDServices via New-WebServiceProxy" -Id 0;

[bool]$hadError = $false;
Try {
   $service = New-WebServiceProxy -Uri 'http://localhost/pdservices/wsservice.asmx?wsdl' -UseDefaultCredential;
} Catch {
   $hadError = $true;
   Write-Error $_ -ErrorAction:'SilentlyContinue';
} Finally {
   Write-Progress -Activity "Resetting IIS" -Completed -Id 0
}

If ($hadError) {
   Write-Host 'Press any key to continue/close prompt...';
   $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
}
Return;
