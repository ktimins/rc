# vim:fdm=marker

# Basic {{{1
   Set-ExecutionPolicy Unrestricted;
   $username = $env:USERNAME;

# }}}

# Modules {{{1

   Import-Module AdvancedHistory;
   Import-Module BurntToast;
   Import-Module cowsay
      Import-Module oh-my-posh;
   Import-Module posh-git
      Import-Module PowerShellGet
      Import-Module PSCalendar;
   Import-Module PSExcel
      if ($host.Name -eq 'ConsoleHost') {
         Import-Module PSReadline
      }

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

   Function Upgrade-VimViaChoco {
      $proc = Start-Process -FilePath "choco.exe" -ArgumentList @('Upgrade','vim-tux', "--ia=`"'/InstallPopUp /RestartExplorer'`"", '--svc', '--force') -NoNewWindow -PassThru;
      $proc | Wait-Process;
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
      Write-Host (" {0}{1} " -f $(" " * 46), $endTime);
      Start-CountdownTimer -Hours $ts.Hours -Minutes $ts.Minutes -Seconds $ts.Seconds;
      If ($Toast) {
         New-BurntToastNotification -Text "TIME TO LEAVE!";
      }
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
   cowsay $welcome;

# }}}

# Aliases {{{1

   Set-Alias which Get-Command;
   Set-Alias cupVim Upgrade-VimViaChoco;

# }}}

# Needed Loadups {{{1

   # Chocolatey profile {{{2

      $ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1";
      if (Test-Path($ChocolateyProfile)) {
         Import-Module "$ChocolateyProfile";
      }

   # }}}

# }}}
