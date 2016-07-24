##############################
#           Basic            #
##############################
Set-ExecutionPolicy Unrestricted

$ProfileRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path)
$env:path += ";$ProfileRoot"

$provider = Get-PSProvider filesystem
$provider.Home = 'C:\Users\TiminsKy'


##############################
#         Variables          #
##############################

$TempDir = 'C:\Users\TiminsKy\AppData\Local\Temp'
$ENFDir = 'C:\Users\TiminsKy\Documents\ENF'


##############################
#          Modules           #
##############################
Import-Module Pscx -arg "$(Split-Path $profile -parent)\Pscx.UserPreferences.ps1"

Import-Module cowsay

#Import-Module posh-git-master

if ($host.Name -eq 'ConsoleHost') {
   Import-Module PSReadline
}

Import-Module TiminsKy -DisableNameChecking

Import-Module adoLib

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

$buffer = $console.BufferSize
$buffer.Width  = 130
$buffer.Height = 2000
$console.BufferSize = $buffer

$size = $console.WindowSize
$size.Width  = 130
$size.Height = 35
$console.WindowSize = $size


##############################
#            VIM             #
##############################
set-alias vim "C:/Program Files (x86)/Vim/vim74/./vim.exe"
set-alias gvim "C:/Program Files (x86)/Vim/vim74/./gvim.exe"

# To edit the Powershell Profile
Function Edit-Profile {
   vim $profile
}

# To edit vim Settings
Function Edit-Vimrc {
   vim $HOME\_vimrc
}


##############################
#          Fortune           #
##############################
Function fortune {
   param(
         [switch]$hh
        )
   if ($hh) {
      [System.IO.File]::ReadAllText((Split-Path $profile)+'\hitchhiker.txt') -replace "`r`n", "`n" -split "`n%`n" | Get-Random
   } else {
      [System.IO.File]::ReadAllText((Split-Path $profile)+'\fortune.txt') -replace "`r`n", "`n" -split "`n%`n" | Get-Random
   }

}


##############################
# Start Up - Welcome Message #
##############################
Clear-Host
$PSVers = $PSVersionTable.PSVersion.Major
$prngFortune = Get-Random -minimum 0 -maximum 3
$fort = "`n"
if ($prngFortune -eq 0) {
   $fort += fortune
} elseif ($prngFortune -eq 1){
   $fort += fortune -hh
} else {
   $fort = ""
}
$welcome = $env:USERNAME + ": Welcome to Powershell v" + $PSVers + "."
$fort
if ($PSVers -gt 2) {
   cowsay $welcome
} else {
   $wecome
}

# Load posh-git example profile
. 'C:\Users\TiminsKy\git\posh-git\profile.example.ps1'

