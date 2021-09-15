
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
   Import-Module posh-git;
   Import-Module PoshRSJob;
   Import-Module PSCalendar;
   Import-Module Pscx;
   Import-Module PSExcel;
   Import-Module PSFolderSize;
   Import-Module PSWriteHTML;
   Import-Module Terminal-Icons;
   Import-Module WriteAscii;
   if ($host.Name -eq 'ConsoleHost') {
      Import-Module PSReadline;
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
      Push-Location $GitDir;
   }

   Function Cd-RcGit {
      Push-Location $rcGitDir;
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

   Function Copy-DevEnvPasswd {
      $DevEnvPasswd | Set-Clipboard;
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
      $proc = Start-Process -FilePath "choco.exe" -ArgumentList @('Upgrade','vim', "--params=`"'/NoDesktopShortcuts /RestartExplorer'`"", '--svc') -NoNewWindow -PassThru;
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
            [int]$Minute = 45,
            [int]$Second = 0,
            [int]$Millisecond = 0,
            [int]$Length = 8,
            [Switch]$Toast
            );
      Clear-Host; 
      $endTime = ((Get-Date -Hour $Hour -Minute $Minute -Second $Second -Millisecond $Millisecond) + (New-TimeSpan -Hours $Length));
      $ts =(New-TimeSpan -End ($endTime)); 
      Write-Host (" {0}{1} " -f $(" " * 46), $endTime.ToString("yyyy-MM-dd hh:mm:ss"));
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
   $PSVers = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)";
   $welcome = $env:USERNAME + ": Welcome to Powershell v" + $PSVers + ".";
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

# }}}

# Needed Loadups {{{1

   # Chocolatey profile {{{2

      $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1";
      if (Test-Path($ChocolateyProfile)) {
         Import-Module "$ChocolateyProfile";
      }

   # }}}

# }}}
