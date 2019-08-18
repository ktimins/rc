##############################
#           Basic            #
##############################
Set-ExecutionPolicy Unrestricted

#$ProfileRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path)
#$env:path += ";$ProfileRoot"
#
#$provider = Get-PSProvider filesystem
#$provider.Home = 'C:\Users\TiminsKy'

##############################
#    (G)Vim.bat Functions    #
##############################
Function Run-Vim {
   param(
         [Parameter(Mandatory=$False, Position=0)]
         [Boolean]$Gui,
         [Parameter(Mandatory=$False, ValueFromRemainingArguments=$True, Position=1)]
         [String[]]$FileArgs
        );

   If ($Gui) {
      Invoke-GVim $FileArgs;
   } Else {
      Invoke-Vim $FileArgs;
   }
}

Function Invoke-Vim {
   param(
         [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromRemainingArguments=$True, Position=0)]
         [String[]]$FileArgs = $Null
        );

   ($sp = "Start-Process vim.bat $(if ($FileArgs) {-ArgumentList $("$FileArgs")}) -Wait;");
   Invoke-Expression $sp;
}

Function Invoke-GVim {
   param(
         [Parameter(Mandatory=$False, ValueFromPipeline=$True, ValueFromRemainingArguments=$True, Position=0)]
         [String[]]$FileArgs = $Null
        );

   ($sp = "Start-Process gvim.bat $(if ($FileArgs) {-ArgumentList $("$FileArgs")}) -Wait;");
   Invoke-Expression $sp;
}

##############################
#          Aliases           #
##############################
#New-Alias which Get-Command
#New-Alias vim Invoke-Vim -Force;
#New-Alias gvim Invoke-GVim -Force;

##############################
#         Variables          #
##############################

$TempDir = 'C:\Users\TiminsKy\AppData\Local\Temp'
$ENFDir = 'C:\Users\TiminsKy\Documents\ENF'

$AppDir = 'F:\Work\Products\DailyBuild\App'
$Pass2Dir = (Join-Path -Path $AppDir -ChildPath 'core\Coding')
$CrumDir = 'L:'
$BillingSchemaDir = "F:\Work\Products\DailyBuild\System\Shared\BillingSchema";

##############################
#          Modules           #
##############################
#Import-Module Pscx -arg "$(Split-Path $profile -parent)\Pscx.UserPreferences.ps1" 

Import-Module cowsay

Import-Module posh-git

if ($host.Name -eq 'ConsoleHost') {
   Import-Module PSReadline
}

Import-Module TiminsKy -DisableNameChecking

Import-Module ErrorCorrect -DisableNameChecking

Import-Module EDI -DisableNameChecking

Import-Module adoLib

Import-Module GetSPOListModule

#Import-Module PersistentHistory
Import-Module AdvancedHistory

Import-Module ActiveDirectory

Import-Module PowerShellGet

Import-Module PSExcel

Import-Module oh-my-posh

#Import-Module TfsCmdlets
#Import-Module TFS       
#Import-Module TFVC      
#Import-Module posh-tex  
#Import-Module posh-vs
#Install-PoshVs

##############################
#  Console Display settings  #
##############################

$console = $host.UI.RawUI
$console.BackgroundColor = "black"
$console.ForegroundColor = "green"

$colors = $host.PrivateData
$colors.VerboseForegroundColor = "white"
$colors.VerboseBackgroundColor = "blue"
$colors.WarningForegroundColor = "yellow"
$colors.WarningBackgroundColor = "darkgreen"
$colors.ErrorForegroundColor = "white"
$colors.ErrorBackgroundColor = "red"

#$buffer = $console.BufferSize
#$buffer.Width  = 130
#$buffer.Height = 2000
$console.BufferSize = New-Object System.Management.Automation.Host.Size(130,2000)

$size = $console.WindowSize
$size.Width  = 130
$size.Height = 35
$console.WindowSize = $size

Set-Theme Darkblood

  #########################
  #      256 COLOR        #
  #########################

Add-Type -MemberDefinition @"
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool SetConsoleMode(IntPtr hConsoleHandle, int mode);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern IntPtr GetStdHandle(int handle);
[DllImport("kernel32.dll", SetLastError=true)]
public static extern bool GetConsoleMode(IntPtr handle, out int mode);
"@ -namespace win32 -name nativemethods

$h = [win32.nativemethods]::getstdhandle(-11) #  stdout
$m = 0
$success = [win32.nativemethods]::getconsolemode($h, [ref]$m)
$m = $m -bor 4 # undocumented flag to enable ansi/vt100
$success = [win32.nativemethods]::setconsolemode($h, $m)

Function Copy-Profile {
   Copy-Item -Path 'C:\Users\TiminsKY\Git\rc\Windows\Microsoft.Powershell_profile.ps1' -Destination $PROFILE -Force
}

Function Edit-Profile {
   Param(
         [Parameter(Mandatory=$false)]
         [Switch]$GVim
        )
   $file = 'C:\Users\TiminsKY\Git\rc\Windows\Microsoft.Powershell_profile.ps1';
   If ($GVim) {
      gvim.bat $file;
   } Else {
      vim.bat $file;
   }
   Copy-Profile;
   . $PROFILE;
}

Function Copy-Vimrc {
   Copy-Item -Path 'C:\Users\TiminsKy\Git\rc\Vim\_vimrc' -Destination 'Z:\_vimrc' -Force
}

Function Edit-Vimrc {
   Param(
         [Parameter(Mandatory=$false)]
         [Switch]$GVim
        )
   $file = 'C:\Users\TiminsKy\Git\rc\Vim\_vimrc';
   If ($GVim) {
      gvim.bat $file;
   } Else {
      vim.bat $file;
   }
   Copy-Vimrc;
}

Function Cd-Pass2 {
   Push-Location $Pass2Dir
}

Function Cd-Bill {
   Push-Location (Join-Path -Path $Pass2Dir -ChildPath 'BillingDecisions')
}

Function Cd-App {
   Push-Location $AppDir
}

Function Cd-Crum {
   Push-Location $CrumDir
}

Function Cd-BillingSchema {
   Push-Location $BillingSchemaDir;
}

Function Update-BillingSchema {
   Start-Process -FilePath (Get-Command tf).Definition -ArgumentList "vc get $BillingSchemaDir /recursive /overwrite /noprompt" -NoNewWindow -Wait;
}

Function Update-TfsFiles {
   Param(
         [Switch]$Recursive
        )
   $pwd = Get-Location;
   $args = "vc get $pwd $(If ($Recursive) {"/recursive "})/noprompt";
   Start-Process -FilePath (Get-Command tf).Definition -ArgumentList $args -NoNewWindow -Wait;
}


##############################
#          Fortune           #
##############################
Function fortune {
   param(
         [switch]$hh
        )
   $dir = 'C:\Users\TiminsKY\Documents\WindowsPowerShell'
   If ($hh) {
      [System.IO.File]::ReadAllText((Split-Path $profile)+'\hitchhiker.txt') -replace "`r`n", "`n" -split "`n%`n" | Get-Random
   } ElseIf ($simpsons) {
      [System.IO.File]::ReadAllText((Split-Path $profile)+'\chalkboard.txt') -replace "`r`n", "`n" -split "`n%`n" | Get-Random
   } ElseIf ($gump) {
      [System.IO.File]::ReadAllText((Split-Path $profile)+'\fgump.txt') -replace "`r`n", "`n" -split "`n%`n" | Get-Random
   } ElseIf ($friends) {
      [System.IO.File]::ReadAllText((Split-Path $profile)+'\friends.txt') -replace "`r`n", "`n" -split "`n%`n" | Get-Random
   } Else {
      [System.IO.File]::ReadAllText((Split-Path $profile)+'\fortune.txt') -replace "`r`n", "`n" -split "`n%`n" | Get-Random
   }

}


##############################
# Start Up - Welcome Message #
##############################
Clear-Host
$PSVers = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
$prngFortune = Get-Random -minimum 0 -maximum 6
$fort = "`n"
switch ($prngFortune) {
   0        { $fort += fortune }
   1        { $fort += fortune -hh }
   2        { $fort += fortune -simpsons }
   3        { $fort += fortune -gump }
   4        { $fort += fortune -friends }
   Default  { $fort  = "" }
}
$welcome = $env:USERNAME + ": Welcome to Powershell v" + $PSVers + "."
$fort
if ($PSVers -gt 2) {
   cowsay $welcome
} else {
   $wecome
}



# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}



# Load Posh-GitHub
. 'C:\Users\TiminsKY\Documents\WindowsPowerShell\Modules\Posh-GitHub\Posh-GitHub-Profile.ps1'
