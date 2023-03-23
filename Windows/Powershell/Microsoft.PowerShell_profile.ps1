
# vim:fdm=marker

# Basic {{{1
   Set-ExecutionPolicy Bypass;
   $username = $env:USERNAME;

   # {{{2
      # Include variables
      $varFile = (Join-Path -Path (Split-Path -Path $PROFILE -Parent) -ChildPath "Powershell_Variables.ps1");
      if (Test-Path -Path $varFile) {
      . $varFile;
      }
   # }}}

# }}}

# Modules {{{1

   Import-Module BurntToast;
   Import-Module CowsaySharp;
   Import-Module PowerShellGet;
   Import-Module ImportExcel;
   Import-Module posh-git;
   Import-Module PoshRSJob;
   Import-Module PSCalendar;
   Import-Module Pscx;
   Import-Module PSFolderSize;
   Import-Module PSLogging;
   Import-Module PSWriteHTML;
   Import-Module Terminal-Icons;
   Import-Module WriteAscii;
   if ($host.Name -eq 'ConsoleHost') {
      Import-Module PSReadline;
   }

   if ((Get-InstalledModule).Name -icontains 'sqlserver') {
      Import-Module SqlServer;
   }

   # AdvancedHistory {{{2

      Import-Module AdvancedHistory;
      Enable-AdvancedHistory;

   # }}}

   # Oh-My-Posh {{{2

      Import-Module oh-my-posh;
      Set-PoshPrompt -Theme C:\Users\KTimins\oh_my_posh_theme-custom.omp.json
      #Set-PoshPrompt -Theme slimfat

   # }}}

# }}}

# Variables {{{1

   $User = $env:USERNAME;
   $HomeDir = $env:USERPROFILE;
   $TempDir = Join-Path -Path $env:LOCALAPPDATA -ChildPath 'Temp';

   $GitDir = (Join-Path -Path $HomeDir -ChildPath 'Git');
   $rcGitDir = (Join-Path -Path $GitDir -ChildPath 'rc');
   $ps1ScriptDir = (Join-Path -Path (Join-Path -Path $rcGitDir -ChildPath 'Windows') -ChildPath 'Scripts');

# }}}

# Change Dirs {{{1

   Function Cd-Git {
      Set-LocationEx -Path $GitDir;
   }

   Function Cd-RcGit {
      Set-LocationEx -Path $rcGitDir;
   }

   Function Cd-ScriptsDir {
      Push-Location $ps1ScriptDir;
   }

   # Aliases {{{2

      Set-Alias pl Push-Location;
      Set-Alias ppl Pop-Location;

   # }}}

# }}}

# Powershell Helpers {{{1

   Function Get-UpdateHelpVersion {
      Param(
            [parameter(Mandatory=$False)]
            [String[]]
            $Module
           );

      $HelpInfoNamespace = @{helpInfo='http://schemas.microsoft.com/powershell/help/2010/05'}

      if ($Module) { 
         $Modules = Get-Module $Module -ListAvailable | where {$_.HelpInfoUri} 
      } else { 
         $Modules = Get-Module -ListAvailable | where {$_.HelpInfoUri} 
      }

      foreach ($mModule in $Modules) {
         $mDir = $mModule.ModuleBase;

         if (Test-Path $mdir\*helpinfo.xml)
         {
            $mName=$mModule.Name;
            $mNodes = dir $mdir\*helpinfo.xml -ErrorAction SilentlyContinue |
               Select-Xml -Namespace $HelpInfoNamespace -XPath "//helpInfo:UICulture";
            foreach ($mNode in $mNodes) {
               $mCulture=$mNode.Node.UICultureName;
               $mVer=$mNode.Node.UICultureVersion;

               [PSCustomObject]@{
                  "ModuleName"=$mName; 
                  "Culture"=$mCulture; 
                  "Version"=$mVer
               };
            }
         }
      }
   }

# }}}

# Custom Functions {{{1

   Function Get-WebsiteStatusCode {
      Param(
            [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)]
            [string]$Url
           );

      try{
         $req = Invoke-WebRequest -URI $Url;
         Write-output    "Status Code -- $($req.StatusCode)";
      } catch{
         Write-Output "Status Code --- $($_.Exception.Response.StatusCode.Value__)";
      }
   }

   Function Get-E2ProdStatusCode {
      Get-WebsiteStatusCode -Url $E2_URL;
   }

   Function Get-BcLocationCounts {
      Param(
            [switch]$Migration
           );

      $mig = 'f598f114-2e76-ec11-83a8-005056a922d8';
      $sandbox1 = '323a17e1-ddb9-ec11-83b1-005056a922d8';

      $company = $sandbox1;
      $fileName = "Sandbox1";
      if ($Migration) {
         $company = $mig;
         $fileName = "Migration";
      }

      $filePath = (Join-Path -Path $TempPath -ChildPath "$fileName.csv");

      "Region, Total, Admin, Lease, Managed, Insurance" > $filePath;
      $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]";
      $headers.Add("Authorization", "Basic $BcPasswd")
         $headers.Add("Content-Type", "application/json");
      $response = Invoke-RestMethod "https://10.0.1.64:7248/BC_userauth/api/lazparking/e2/v1.0/companies($company)/parkings" -Method 'GET' -Headers $headers -SkipCertificateCheck;
      foreach ($reg in 0..50) {
         $regStr = $reg.ToString().PadLeft(2, '0');
         $regStr | Write-Host;

         $val = ($response.value | Where-Object { Select-String -Pattern "^[aAlLmMiI]$regStr\d{3}$"  -InputObject $_.code.ToUpper() }).count;
         $a = ($response.value | Where-Object { Select-String -Pattern "^[aA]$regStr\d{3}$"  -InputObject $_.code.ToUpper() }).count;
         $l = ($response.value | Where-Object { Select-String -Pattern "^[lL]$regStr\d{3}$"  -InputObject $_.code.ToUpper() }).count;
         $m = ($response.value | Where-Object { Select-String -Pattern "^[mM]$regStr\d{3}$"  -InputObject $_.code.ToUpper() }).count;
         $i = ($response.value | Where-Object { Select-String -Pattern "^[iI]$regStr\d{3}$"  -InputObject $_.code.ToUpper() }).count;
         "$regStr, $val, $a, $l, $m, $i" >> $filePath;
      }
   }

   Function Get-BCUserauthStatus {
      &  sc \\bccode query "MicrosoftDynamicsNavServer`$BC_userauth";
   }

   Function Start-BCUserauth {
      & sc \\bccode start "MicrosoftDynamicsNavServer`$BC_userauth";
   }

   Function Stop-BCUserauth {
      & sc \\bccode stop "MicrosoftDynamicsNavServer`$BC_userauth"
   }

   Function Get-BC200Status {
      &  sc \\bccode query "MicrosoftDynamicsNavServer`$BC200";
   }

   Function Start-BC200 {
      & sc \\bccode start "MicrosoftDynamicsNavServer`$BC200";
   }

   Function Stop-BC200 {
      & sc \\bccode stop "MicrosoftDynamicsNavServer`$BC200"
   }

   Function Get-BC200_AAStatus {
      &  sc \\bccode query "MicrosoftDynamicsNavServer`$BC200_AA";
   }

   Function Start-BC200_AA {
      & sc \\bccode start "MicrosoftDynamicsNavServer`$BC200_AA";
   }

   Function Stop-BC200_AA {
      & sc \\bccode stop "MicrosoftDynamicsNavServer`$BC200_AA"
   }

   Function Update-PythonPackages {
      pip freeze | %{$_.split('==')[0]} | %{pip install --upgrade $_}
   }

   Function Start-Teams {
      & 'C:\Users\KTimins\AppData\Local\Microsoft\Teams\Update.exe' --processStart "Teams.exe"
   }

   Function Kill-Chrome {
      Get-Process -Name 'chrome' | Stop-Process;
   }

   Function Start-Chrome {
      Param(
            [switch]$NoRestore
           );
      
      if ($NoRestore) {
         Start-Process -FilePath (Get-Command chrome).Source;
      } else {
         Start-Process -FilePath (Get-Command chrome).Source -ArgumentList "--restore-last-sessions";
      }
   }

   Function Restart-Chrome {
      Param(
            [switch]$NoRestore
           );

      Kill-Chrome; 
      if ($NoRestore) {
         Start-Chrome -NoRestore;
      } else {
         Start-Chrome;
      }
   }

   Function Open-ExplorerHere {
      & explorer.exe .;
   }

   Function Restart-Explorer {
      Get-Process -Name 'explorer' | Stop-Process;
      & explorer.exe;
   }

   Function Copy-DevEnvPasswd {
      $DevEnvPasswd | Set-Clipboard;
   }

   Function Get-ct100ssql3 {
      $ct100ssqlInfo;
   }

   Function Get-sqlDevInfo {
      $sqlDevInfo;
   }

   Function Get-DevonE2SqlCsv {
      Param(
            [Parameter(Mandatory=$False,Position=0,ValueFromPipeline=$True)]
            [String]$Path = 'C:\Users\KTimins\Temp\DevonE2Sql.csv'
           );

      $sqlInfo = Get-sqlDevInfo;
      $query = "select Aid, LocationNumber, BcLocationNumber, ModifiedTime, SyncTime from BC_Audit where [Action] = 'CreateLocationNumber'";
      $output = Invoke-Sqlcmd -ServerInstance $sqlDev.Server -Database $sqlDev.InitialCatalog -Query $query -Username $sqlDev.UserID -Password $sqlDev.Password;
      $output | Select-Object | Export-Csv -Path $Path -NoTypeInformation;
   }

   Function Get-PrintPassCode {
      "Your Print Pass Code is: $PrintPassCode" | Write-Output;
   }

   Function Get-UnixEpoch{
      Param(
            [Parameter(Mandatory=$False,Position=0,ValueFromPipeline=$True)]
            [Int]$Epoch = 0,
            [Switch]$String
           );

      if ($Epoch -gt 0) {
         $date = (Get-Date "1970-01-01").AddSeconds($Epoch);
         if ($String) {
            return (Get-Date $date -Format "yyyy-MM-ddTHH:mm:ss")
         } else {
            return $date;
         }
      } else {
         return (Get-Date -UFormat %s);
      }
   }

   Function Get-Utc {
      Param(
            [switch]$String
           );
      if ($String) {
         Get-Date -AsUTC -Format "yyyy-MM-ddTHH:mm:ss.fffZ";
      } else {
         Get-Date -AsUTC;
      }
   }

   Function Kill-Process {
      Param(
            [string]$Name
           );
      try {
         $proc = Get-Process -Name $Name -ErrorAction Stop;
         $proc | Stop-Process -ErrorAction Stop;
      } catch {
         Write-Host "Failed to kill '$Name'" -ForegroundColor Red;
      }
   }

   Function New-File {
      Param(
            [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)]
            [String]$Name
           );
      New-Item -ItemType File -Name $Name;
   }

   Function Upgrade-VimViaChoco {
      $proc = Start-Process -FilePath "choco.exe" -ArgumentList @('Upgrade','vim', "--params=`"'/NoDesktopShortcuts'`"", '--svc') -NoNewWindow -PassThru;
      $proc | Wait-Process;
   }

   Function Get-ChocolateyOutdatedPrograms {
      $proc = Start-Process -FilePath "choco.exe" -ArgumentList @('Outdated') -NoNewWindow -PassThru;
      $proc | Wait-Process;
   }

   Function Remove-GitBranch {
      Param(
            [Parameter(Mandatory=$True,Position=0,ValueFromPipeline=$True)]
            [String]$Branch,
            [Parameter(Mandatory=$False,Position=1)]
            [String]$Remote = "origin",
            [Switch]$LocalOnly,
            [Switch]$Y
           );
      $currentBranch = (git branch --show-current);
      if ($currentBranch -imatch $Branch) {
         Write-Error "Unable to continue. Current branch is the selected to delete branch `"$currentBranch`".";
      } else {
         $decision = 1;
         if ($Y) {
            $decision = 0;
         } else {
            $title = "Remove Git Branch `"$Branch`"";
            $question = "Are you sure you want to remove git branch `"$Branch`"?";
            $choices = '&Yes', '&No';

            $decision = $Host.Ui.PromptForChoice($title, $question, $choices, 1);
         }
         if ($decision -eq 0) {
            Write-Host "`nDeleting branch `"$Branch`" from local.`n";
            git branch -D $Branch;
            if (!$LocalOnly) {
               Write-Host "`nDeleting branch `"$Branch`" from remote `"$Remote`".`n";
               git push $Remote --delete $Branch;
            }
         }
      }
   }

   Function Set-GitUpstreamBranch {
      Param(
            [Parameter(Mandatory=$False)]
            [String]$Branch = (git branch --show-current),
            [Switch]$Y
           );

      $decision = 1;
      if ($Y) {
         $decision = 0;
      } else {
         $title = "Set Upstream branch to `"$Branch`"";
         $question = "You want to set the upstream branch to `"$Branch`"?";
         $choices = '&Yes', '&No';

         $decision = $Host.Ui.PromptForChoice($title, $question, $choices, 1);
      }

      if ($decision -eq 0) {
          Write-Host "`nSetting Upstream branch to `"$Branch`"`n";
          git push --set-upstream origin $Branch;
      }
   }

   Function Set-SSMSDarkMode {
      (Get-Content 'C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.pkgundef') -replace '\[\`$RootKey\`$\\Themes\\{1ded0138-47ce-435e-84ef-9ec1f439b749}\]', '//[`$RootKey`$\Themes\{1ded0138-47ce-435e-84ef-9ec1f439b749}]' | Out-File 'C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.pkgundef'
   }

   Function Start-CountdownTimer {
      <#

         .SYNOPSIS
         Displays a text-based countdown timer in the console.

         .DESCRIPTION
         Displays a timer counting down the seconds until the script terminates.
         Parameters control the length that it runs for.
         Only works in the console, because of some console tricks used to display the output.

         .EXAMPLE
         ./Start-CountdownTimer -Hours 1 -Minutes 2 -Seconds 3

         .PARAMETER Days
         Optional. The number of Days to wait before finishing

         .PARAMETER Hours
         Optional. The number of hours to wait before finishing

         .PARAMETER Minutes
         Optional. The number of Minutes to wait before finishing

         .PARAMETER Seconds
         Optional. The number of Seconds to wait before finishing

         .PARAMETER TickLength
         Optional. How long to wait before refreshing

         .LINK
         http://blob.pureandapplied.com.au/?p=875

#>
         param (
               [int]$Days = 0,
               [int]$Hours = 0,
               [int]$Minutes = 0,
               [int]$Seconds = 0,
               [int]$TickLength = 1
               );
      $t = New-TimeSpan -Days $Days -Hours $Hours -Minutes $Minutes -Seconds $Seconds;
      $origpos = $host.UI.RawUI.CursorPosition;
      $spinner =@('|', '/', '-', '\');
      $spinnerPos = 0;
      $remain = $t;
      $d =( get-date) + $t;
      $remain = ($d - (get-date));
      while ($remain.TotalSeconds -gt 0){
         Write-Host ("{0}" -f $(' ' * 48)) -NoNewline;
         Write-Host (" {0} " -f $spinner[$spinnerPos%4]) -BackgroundColor White -ForegroundColor Black -NoNewline;
         write-host (" {0}D {1:d2}h {2:d2}m {3:d2}s " -f $remain.Days, $remain.Hours, $remain.Minutes, $remain.Seconds);
         $host.UI.RawUI.CursorPosition = $origpos;
         $spinnerPos += 1;
         Start-Sleep -seconds $TickLength;
         $remain = ($d - (get-date));
      }
      $host.UI.RawUI.CursorPosition = $origpos;
      Write-Host " * "  -BackgroundColor White -ForegroundColor Black -NoNewline;
      Write-Host " Countdown finished";
   }

   Function Start-EndOfWorkCountdownTimer {
      param (
            [int]$Hour = 8,
            [int]$Minute = 0,
            [int]$Second = 0,
            [int]$Millisecond = 0,
            [int]$Length = 8,
            [Switch]$Toast
            );
      Clear-Host; 
      $endTime = ((Get-Date -Hour $Hour -Minute $Minute -Second $Second -Millisecond $Millisecond) + (New-TimeSpan -Hours $Length));
      $ts =(New-TimeSpan -End ($endTime)); 
      Write-Host (" {0}{1} " -f $(" " * 46), $endTime.ToString("yyyy-MM-dd HH:mm:ss"));
      Start-CountdownTimer -Hours $ts.Hours -Minutes $ts.Minutes -Seconds $ts.Seconds;
      If ($Toast) {
         New-BurntToastNotification -Text "TIME TO LEAVE!";
      }
   }

   Function Execute-Shutdown {
      param (
            [Switch]$Full
            );

      $command = "";
      if ($Full) {
         $command = "cmd.exe /C $($env:windir)\System32\shutdown.exe /s /f /t 00";
      } else {
         $command = "cmd.exe /C $($env:windir)\System32\shutdown.exe /s /hybrid /f /t 00";
      }

      Invoke-Expression -Command:$command;
   }

   function Get-NTPDateTime 
   {
      param (
            [string] $sNTPServer = 'pool.ntp.org'
            );
       $StartOfEpoch=New-Object DateTime(1900,1,1,0,0,0,[DateTimeKind]::Utc);
       [Byte[]]$NtpData = ,0 * 48;
       $NtpData[0] = 0x1B;    # NTP Request header in first byte
       $Socket = New-Object Net.Sockets.Socket([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Dgram, [Net.Sockets.ProtocolType]::Udp);
       $Socket.Connect($sNTPServer,123);
        
       $t1 = Get-Date;    # Start of transaction... the clock is ticking...
       [Void]$Socket.Send($NtpData);
       [Void]$Socket.Receive($NtpData);
       $t4 = Get-Date;    # End of transaction time
       $Socket.Close();
    
       $IntPart = [BitConverter]::ToUInt32($NtpData[43..40],0);   # t3
       $FracPart = [BitConverter]::ToUInt32($NtpData[47..44],0);
       $t3ms = $IntPart * 1000 + ($FracPart * 1000 / 0x100000000);
    
       $IntPart = [BitConverter]::ToUInt32($NtpData[35..32],0);   # t2
       $FracPart = [BitConverter]::ToUInt32($NtpData[39..36],0);
       $t2ms = $IntPart * 1000 + ($FracPart * 1000 / 0x100000000);
    
       $t1ms = ([TimeZoneInfo]::ConvertTimeToUtc($t1) - $StartOfEpoch).TotalMilliseconds;
       $t4ms = ([TimeZoneInfo]::ConvertTimeToUtc($t4) - $StartOfEpoch).TotalMilliseconds;
     
       $Offset = (($t2ms - $t1ms) + ($t3ms-$t4ms))/2;
        
       [String]$NTPDateTime = $StartOfEpoch.AddMilliseconds($t4ms + $Offset).ToLocalTime();
    
       return (Get-Date $NTPDateTime);
   }

   function Get-ExeTargetMachine {
       <#
       .SYNOPSIS Displays the machine type of any Windows executable.
        
       .DESCRIPTION
           Displays the target machine type of any Windows executable file (.exe or .dll).
           The expected usage is to determine if an executable is 32- or 64-bit, in which case it will return "x86" or "x64", respectively.
           However, all machine types that were known as of the date of this script's authoring are detected.
            
       .PARAMETER Path
           A string that contains the path to the file to be checked. Can be relative or absolute.
        
       .PARAMETER IncludeFileName
           If set, includes the file name in the displayed output.
            
       .PARAMETER IgnoreInvalidFiles
           Silently skips 16-bit or non-executable files.
            
       .PARAMETER SuppressErrors
           Errors (except invalid path) are not reported.
           Warnings about 16-bit and non-PE files are still reported; use IgnoreInvalidFiles to suppress.
            
       .LINK
           http://msdn.microsoft.com/en-us/windows/hardware/gg463119.aspx
           https://etechgoodness.wordpress.com/2014/12/11/powershell-determine-if-an-exe-is-32-or-64-bit-and-other-tricks/
            
       .OUTPUTS
           If IncludeFileName is not specified, outputs a custom object with a TargetMachine property that contains a string with the executable's target machine type.
           If IncludeFileName is specified, outputs a custom object with a Path property that contains the full path of the executable's name and a TargetMachine property that contains a string with the executable's target machine type.
            
       .NOTES
           Author: Eric Siron
           Copyright: (C) 2014 Eric Siron
           Version 1.0.1 November 3, 2015 Modified non-EXE handling to return as soon as further processing is unnecessary
           Version 1.0 Authored Date: December 10, 2014
        
       .EXAMPLE PS C:\> Get-ExeTargetMachine C:\Windows\bfsvc.exe
            
           Description
           -----------
           Returns a TargetMachine of x64
       .EXAMPLE
           PS C:\> Get-ExeTargetMachine C:\Windows\winhlp32.exe
            
           Description
           -----------
           Returns a TargetMachine of x86
       .EXAMPLE
           PS C:\> Get-ChildItem 'C:\Program Files (x86)\*.exe' -Recurse | Get-ExeTargetMachine -IncludeFileName
            
           Description
           -----------
           Returns the TargetMachine of all EXE files under C:\Program Files (x86) and all subfolders, displaying their complete path names along with their machine type.
       .EXAMPLE
           PS C:\> Get-ChildItem 'C:\Program Files\*.exe' -Recurse | Get-ExeTargetMachine -IncludeFileName | where { $_.TargetMachine -ne "x64" }
            
           Description
           -----------
           Returns the Path and TargetMachine of all EXE files under C:\Program Files and all subfolders that are not 64-bit (x64).
       .EXAMPLE
           PS C:\> Get-ChildItem 'C:\windows\*.exe' -Recurse | Get-ExeTargetMachine | where { $_.TargetMachine -eq "" }
            
           Description
           -----------
           Shows only errors and warnings for the EXE files under C:\Windows and subfolders. This can be used to find 16-bit and other EXEs that don't conform to the portable executable standard.
            
       .EXAMPLE
           PS C:\> Get-ChildItem 'C:\Program Files\' -Recurse | Get-ExeTargetMachine -IncludeFileName -IgnoreInvalidFiles -SuppressErrors | Out-GridView
            
           Description
           -----------
           Finds every file in C:\Program Files and subfolders with a portable executable header, regardless of extension, and displays their names and Target Machine in a grid view.
       #>
       [CmdletBinding()]
       param(
           [Parameter(Mandatory=$true, Position=1, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
           [Alias("FullName")][String]$Path,
           [Parameter()][Switch]$IncludeFileName = $false,
           [Parameter()][Switch]$IgnoreInvalidFiles = $false,
           [Parameter()][Switch]$SuppressErrors = $false
       );
       BEGIN {
           ## Constants ##
           New-Variable -Name PEHeaderOffsetLocation -Option Constant -Value 0x3c;
           New-Variable -Name PEHeaderOffsetLocationNumBytes -Option Constant -Value 2;
           New-Variable -Name PESignatureNumBytes -Option Constant -Value 4;
           New-Variable -Name MachineTypeNumBytes -Option Constant -Value 2;
            
           ## Globals ##
           $NonStandardExeFound = $false;
       }
    
       PROCESS {
           $Path = (Get-Item -Path $Path -ErrorAction Stop).FullName;
           try {
               $PEHeaderOffset = New-Object Byte[] $PEHeaderOffsetLocationNumBytes;
               $PESignature = New-Object Byte[] $PESignatureNumBytes;
               $MachineType = New-Object Byte[] $MachineTypeNumBytes;
                
               Write-Verbose "Opening $Path for reading.";
               try {
                   $FileStream = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite);
               }
               catch {
                   if($SuppressErrors) {
                       return;
                   }
                   throw $_;    #implicit 'else'
               }
                
               Write-Verbose "Moving to the header location expected to contain the location of the PE (portable executable) header.";
               $FileStream.Position = $PEHeaderOffsetLocation;
               $BytesRead = $FileStream.Read($PEHeaderOffset, 0, $PEHeaderOffsetLocationNumBytes);
               if($BytesRead -eq 0) {
                   if($SuppressErrors) {
                       return;
                   }
                   throw "$Path is not the correct format (PE header location not found).";    #implicit 'else'
               }
               Write-Verbose "Moving to the indicated position of the PE header.";
               $FileStream.Position = [System.BitConverter]::ToUInt16($PEHeaderOffset, 0);
               Write-Verbose "Reading the PE signature.";
               $BytesRead = $FileStream.Read($PESignature, 0, $PESignatureNumBytes);
               if($BytesRead -ne $PESignatureNumBytes) {
                   if($IgnoreInvalidFiles) {
                       return;
                   }
                   throw("$Path is not the correct format (PE Signature is an incorrect size).");    # implicit 'else'
               }
               Write-Verbose "Verifying the contents of the PE signature (must be characters `"P`" and `"E`" followed by two null characters).";
               if(-not($PESignature[0] -eq [Char]'P' -and $PESignature[1] -eq [Char]'E' -and $PESignature[2] -eq 0 -and $PESignature[3] -eq 0)) {
                   if(-not($IgnoreInvalidFiles)) {
                       Write-Warning "$Path is 16-bit or is not a Windows executable.";
                   }
                   return;                
    
               }
               Write-Verbose "Retrieving machine type.";
               $BytesRead = $FileStream.Read($MachineType, 0, $MachineTypeNumBytes);
               if($BytesRead -ne $MachineTypeNumBytes) {
                   if($SuppressErrors) {
                       return;
                   }
                   throw "$Path appears damaged (Machine Type not correct size).";    # implicit 'else'
               }
               $RawMachineType = [System.BitConverter]::ToUInt16($MachineType, 0);
               $TargetMachine = switch ($RawMachineType) {
                   0x0        { 'Unknown' }
                   0x1d3        { 'Matsushita AM33' }
                   0x8664    { 'x64' }
                   0x1c0        { 'ARM little endian' }
                   0x1c4        { 'ARMv7 (or higher) thumb mode only' }
                   0xaa64    { 'ARMv8 in 64-bit mode' }
                   0xebc        { 'EFI byte code' }
                   0x14c        { 'x86' }
                   0x200        { 'Itanium 64 bit' }
                   0x9041    { 'Mitsubishi M32R little endian' }
                   0x266        { 'MIPS16' }
                   0x366        { 'MIPS with FPU' }
                   0x466        { 'MIPS16 with FPU' }
                   0x1f0        { 'PowerPC little endian' }
                   0x1f1        { 'PowerPC with floating point support' }
                   0x166        { 'MIPS little endian' }
                   0x1a2        { 'Hitachi SH3' }
                   0x1a3        { 'Hitachi SH3 DSP' }
                   0x1a6        { 'Hitachi SH4' }
                   0x1a8        { 'Hitachi SH5' }
                   0x1c2        { 'ARM or Thumb ("interworking")' }
                   0x169        { 'MIPS little endian WCE v2' }
                   default {
                       $NonStandardExeFound = $true;
                       "{0:X0}" -f $RawMachineType;
                   }
               }
               $Output = New-Object PSCustomObject;
               if($IncludeFileName) {
                   Add-Member -InputObject $Output -MemberType NoteProperty -Name Path -Value $Path;
               }
               Add-Member -InputObject $Output -MemberType NoteProperty -Name TargetMachine -Value $TargetMachine;
               $Output;
           }
           catch
           {
               # the real purpose of the outer try/catch is to ensure that any file streams are properly closed. pass errors through
               Write-Error $_;
           }
           finally {
               if($FileStream) {
                   $FileStream.Close();
               }
           }
       }
    
       END {
           if($NonStandardExeFound) {
               Write-Warning -Message "Executable found with an unknown target machine type. Please refer to section 2.3.1 of the Microsoft documentation (http://msdn.microsoft.com/en-us/windows/hardware/gg463119.aspx).";
           }
       }
   }

   Function Test-Uri
   {
       ##############################################################################
       ##
       ## Test-Uri
       ##
       ## From Windows PowerShell Cookbook (O'Reilly)
       ## by Lee Holmes (http://www.leeholmes.com/guide)
       ##
       ##############################################################################
       
       <#
        
       .SYNOPSIS
        
       Connects to a given URI and returns status about it: URI, response code,
       and time taken.
        
       .EXAMPLE
        
       PS > Test-Uri bing.com
        
       Uri : bing.com
       StatusCode : 200
       StatusDescription : OK
       ResponseLength : 34001
       TimeTaken : 459.0009
        
       #>
       
       Param(
           ## The URI to test
           $Uri
       );
       
       $request = $null;
       $time = try {
           ## Request the URI, and measure how long the response took.
           $result = Measure-Command { $request = Invoke-WebRequest -Uri $uri };
           $result.TotalMilliseconds;
       }
       catch {
           ## If the request generated an exception (i.e.: 500 server
           ## error or 404 not found), we can pull the status code from the
           ## Exception.Response property
           $request = $_.Exception.Response;
           $time = -1;
       }
       
       $result = [PSCustomObject] @{
           Time = Get-Date;
           Uri = $uri;
           StatusCode = [int] $request.StatusCode;
           StatusDescription = $request.StatusDescription;
           ResponseLength = $request.RawContentLength;
           TimeTaken = $time;
       }
       
       $result;
   }

   Function Set-SsmsDarkMode {
      Invoke-Expression (Get-Content 'C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.pkgundef') 
         -replace '\[\`$RootKey\`$\\Themes\\{1ded0138-47ce-435e-84ef-9ec1f439b749}\]', '//[`$RootKey`$\Themes\{1ded0138-47ce-435e-84ef-9ec1f439b749}]' | 
      Out-File 'C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\IDE\ssms.pkgundef';
   }

# }}}

# Console Display settings {{{1

   # 256 COLOR {{{2

      Add-Type -MemberDefinition "
         [DllImport(""kernel32.dll"", SetLastError=true)]
         public static extern bool SetConsoleMode(IntPtr hConsoleHandle, int mode);
      [DllImport(""kernel32.dll"", SetLastError=true)]
         public static extern IntPtr GetStdHandle(int handle);
      [DllImport(""kernel32.dll"", SetLastError=true)]
         public static extern bool GetConsoleMode(IntPtr handle, out int mode);
      " -namespace win32 -name nativemethods;

      $h = [win32.nativemethods]::getstdhandle(-11); #  stdout;
      $m = 0;
      $success = [win32.nativemethods]::getconsolemode($h, [ref]$m);
      $m = $m -bor 4; # undocumented flag to enable ansi/vt100;
      $success = [win32.nativemethods]::setconsolemode($h, $m);

   # }}}

# }}}

# Start Up - Welcome Message {{{1

   Clear-Host;
   $PSVers = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor).$($PSVersionTable.PSVersion.Patch)";
   $welcome = "$env:USERNAME: Welcome to Powershell $($PSVersionTable.PSEdition) v$PSVers.";
   cowthink -r $welcome | lolcat;

# }}}

# Aliases {{{1

   # Remove System Aliases {{{2

      Remove-Item alias:touch -Force;

   #}}}

   Set-Alias touch New-File;
   Set-Alias which Get-Command;
   Set-Alias cupVim Upgrade-VimViaChoco;
   Set-Alias cout Get-ChocolateyOutdatedPrograms;
   Set-Alias devPasswd Copy-DevEnvPasswd;
   Set-Alias printCode Get-PrintPassCode;
   Set-Alias exp Open-ExplorerHere;
   Set-Alias Test-E2Prod Get-E2ProdStatusCode;
   Set-Alias rechrome Restart-Chrome;

# }}}

# Needed Loadups {{{1

   # Chocolatey profile {{{2

      $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1";
      if (Test-Path($ChocolateyProfile)) {
         Import-Module "$ChocolateyProfile";
      }

   # }}}

# }}}
