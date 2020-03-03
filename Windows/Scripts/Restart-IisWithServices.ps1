Param(
      [Parameter(Mandatory=$False,ValueFromPipeline=$true,Position=1)]
      [String]$WebSiteName = 'Default Web Site',
      [Parameter(Mandatory=$False,ValueFromPipeline=$true,Position=2)]
      [String]$AppPool = '.NET v4.5 Classic'
     );

Process {
   Write-Progress -Activity "Resetting IIS" -Id 0;
   
   Write-Progress -Activity "Resetting IIS" -Status "Stopping and Starting '$AppPool'" -CurrentOperation "Stopping '$AppPool'" -Id 1 -Parent 0;

   Stop-WebAppPool -Name $AppPool -ErrorAction SilentlyContinue;

   Start-Sleep -Milliseconds 500;

   Write-Progress -Activity "Resetting IIS" -Status "Stopping and Starting '$AppPool'" -CurrentOperation "Starting '$AppPool'" -Id 1 -Parent 0;

   Start-WebAppPool -Name $AppPool;

   Start-Sleep -Milliseconds 500;

   Write-Progress -Activity "Resetting IIS" -Completed -Id 1 -Parent 0;

   Write-Progress -Activity "Resetting IIS" -Status "'$WebSiteName' is $state" -CurrentOperation "Getting '$WebSiteName'" -Id 2 -Parent 0;

   $website = Get-WebSite -Name $WebSiteName;

   $state = Write-WebSiteStatus -WebSite $website;

   Start-Sleep -Milliseconds 250;

   Write-Progress -Activity "Resetting IIS" -Status "'$WebSiteName' is $state" -CurrentOperation "Stopping '$WebSiteName'" -Id 2 -Parent 0;

   $website | Stop-WebSite -ErrorAction SilentlyContinue;

   Start-Sleep -Milliseconds 500;

   $state = Write-WebSiteStatus -WebSite $website;

   Start-Sleep -Milliseconds 250;

   Write-Progress -Activity "Resetting IIS" -Status "'$WebSiteName' is $state" -CurrentOperation "Stopping '$WebSiteName'" -Id 2 -Parent 0;

   $website | Start-WebSite;

   Start-Sleep -Milliseconds 500;

   $state = Write-WebSiteStatus -WebSite $website;

   Start-Sleep -Milliseconds 250;

   Write-Progress -Activity "Resetting IIS" -Status "'$WebSiteName' is $state" -CurrentOperation "Calling PDServices via New-WebServiceProxy" -Id 3 -Parent 0;

   [bool]$hadError = $false;
   Try {
      Write-Progress -Activity "Starting PD Services" -Status "PD Services is Stopped" -CurrentOperation "Calling PDServices via New-WebServiceProxy" -Id 3 -Parent 0;

      $service = New-WebServiceProxy -Uri 'http://localhost/pdservices/wsservice.asmx?wsdl' -UseDefaultCredential;

      Start-Sleep -Milliseconds 500;

      Write-Progress -Activity "Starting PD Services" -Status "PD Services is Started" -CurrentOperation "Calling PDServices via New-WebServiceProxy" -Id 3 -Parent 0;
   } Catch {
      $hadError = $true;
      Write-Progress -Activity "Starting PD Services" -Status "PD Services is Errored" -Id 1 -Parent 0;
      Write-Error $_ -ErrorAction:'SilentlyContinue';
   } Finally {
      Write-Progress -Activity "Starting PD Services" -Completed -Id 1 -Parent 0;
   }
}

End {
   If ($hadError) {
      Write-Host 'Press any key to continue/close prompt...';
      $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');
   }

   Write-Progress -Activity "Resetting IIS" -Completed -Id 0

   Return;
}

Begin {
   Function Write-WebSiteStatus {
      Param(
            [Parameter(Mandatory=$true)]
            [System.Object]$WebSite
           );
      $state = ($WebSite | Get-WebSiteState);
      "Current state of '$($WebSite.Name)' is '$($state.Value)'." | Out-Host;
      Return $state.Value;
   }
}
