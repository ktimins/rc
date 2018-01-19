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
#          Aliases           #
##############################
#New-Alias which Get-Command

##############################
#         Variables          #
##############################

$TempDir = 'C:\Users\TiminsKy\AppData\Local\Temp'
$ENFDir = 'C:\Users\TiminsKy\Documents\ENF'


##############################
#          Modules           #
##############################
#Import-Module Pscx -arg "$(Split-Path $profile -parent)\Pscx.UserPreferences.ps1" 

Import-Module cowsay

#Import-Module posh-git-master

if ($host.Name -eq 'ConsoleHost') {
   Import-Module PSReadline
}

Import-Module TiminsKy -DisableNameChecking

Import-Module adoLib

Import-Module GetSPOListModule

Import-Module PersistentHistory

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

# To edit the Powershell Profile
Function Edit-Profile {
   gvim $profile
}

# To edit vim Settings
Function Edit-Vimrc {
   gvim $HOME\_vimrc
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
$PSVers = $PSVersionTable.PSVersion.Major
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

# Load posh-git example profile
. 'C:\tools\poshgit\dahlbyk-posh-git-a4faccd\profile.example.ps1' choco


# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

