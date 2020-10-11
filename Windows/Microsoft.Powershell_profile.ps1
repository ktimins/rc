# vim:fdm=marker

# Basic {{{1
Set-ExecutionPolicy Unrestricted;

$username = $env:USERNAME;

#$ProfileRoot = (Split-Path -Parent $MyInvocation.MyCommand.Path)
#$env:path += ";$ProfileRoot"
#
#$provider = Get-PSProvider filesystem
#$provider.Home = 'C:\Users\TiminsKy'

# }}}

# Aliases {{{1
#New-Alias which Get-Command
#New-Alias vim Invoke-Vim -Force;
#New-Alias gvim Invoke-GVim -Force;

# }}}

# Modules {{{1
#Import-Module Pscx -arg "$(Split-Path $profile -parent)\Pscx.UserPreferences.ps1" 

Import-Module cowsay

Import-Module posh-git

#Import-Module PowerSSH

if ($host.Name -eq 'ConsoleHost') {
   Import-Module PSReadline
}

Import-Module PSCalendar;

Import-Module AdvancedHistory

Import-Module PowerShellGet

#Import-Module PSExcel

Import-Module oh-my-posh

# }}}

# Variables {{{1

$TempDir = "C:\Users\$username\AppData\Local\Temp";

$HomeDir = "C:\Users\$username\";
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

# Console Display settings {{{1

$console = $host.UI.RawUI
#$console.BackgroundColor = "black"
#$console.ForegroundColor = "green"

#$colors = $host.PrivateData
#$colors.VerboseForegroundColor = "white"
#$colors.VerboseBackgroundColor = "blue"
#$colors.WarningForegroundColor = "yellow"
#$colors.WarningBackgroundColor = "darkgreen"
#$colors.ErrorForegroundColor = "white"
#$colors.ErrorBackgroundColor = "red"

#$buffer = $console.BufferSize
#$buffer.Width  = 130
#$buffer.Height = 2000
$console.BufferSize = New-Object System.Management.Automation.Host.Size(130,2000)

$size = $console.WindowSize
$size.Width  = 130
$size.Height = 35
$console.WindowSize = $size

#Set-Theme Darkblood

  # 256 COLOR {{{2

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
   # }}}

# }}}

# Custom Functions {{{1

Function Copy-Profile {
   Copy-Item -Path "C:\Users\$username\Git\rc\Windows\Microsoft.Powershell_profile.ps1" -Destination $PROFILE -Force
}

Function Edit-Profile {
   Param(
         [Parameter(Mandatory=$false)]
         [Switch]$GVim
        )
   $file = "C:\Users\$username\Git\rc\Windows\Microsoft.Powershell_profile.ps1";
   If ($GVim) {
      gvim.bat $file;
   } Else {
      vim.bat $file;
   }
   Copy-Profile;
   . $PROFILE;
}

Function Reload-Profile { & $profile }

Function Copy-Vimrc {
   Get-ChildItem -Path "C:\Users\$username\Git\rc\Vim\vimrc" -Recurse | ForEach-Object {
      Copy-Item -Path $_.FullName -Destination $HomeDir -Recurse -Force -Container -Verbose -ErrorAction SilentlyContinue;
   }
}

Function Edit-Vimrc {
   Param(
         [Parameter(Mandatory=$false)]
         [Switch]$GVim
        )
   $file = "C:\Users\$username\Git\rc\Vim\vimrc\_vimrc";
   If ($GVim) {
      gvim $file;
   } Else {
      vim $file;
   }
   Copy-Vimrc;
}


# }}}

# Start Up - Welcome Message {{{1
Clear-Host
$PSVers = "$($PSVersionTable.PSVersion.Major).$($PSVersionTable.PSVersion.Minor)"
#$prngFortune = Get-Random -minimum 0 -maximum 6
#$fort = "`n"
#switch ($prngFortune) {
   #0        { $fort += fortune }
   #1        { $fort += fortune -hh }
   #2        { $fort += fortune -simpsons }
   #3        { $fort += fortune -gump }
   #4        { $fort += fortune -friends }
   #Default  { $fort  = "" }
#}
$welcome = $env:USERNAME + ": Welcome to Powershell v" + $PSVers + "."
#$fort
if ($PSVers -gt 2) {
   Show-Calendar;
   cowsay $wecome;
}
# }}}

# Needed Loadups {{{1

# Chocolatey profile
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}

# }}}

# Aliases {{{1

   # New-Alias {{{2

      New-Alias -Name RePro -Value Reload-Profile -Description "Reload my profile";
      New-Alias -Name Reg-Asm -Value "& C:\Windows\Microsoft.NET\Framework\v4.0.30319\regasm.exe";
      New-Alias -Name pl -Value Push-Location -Description "Shorthand for Push-Location";
      New-Alias -Name ppl -Value Pop-Location -Description "Shorthand for Pop-Location";

   # }}}

   # Set-Alias {{{2

      Set-Alias -Name ssh-keygen -Value Invoke-BashCommand;
      Set-Alias -Name ssh-copy-id -Value Invoke-BashCommand;
      Set-Alias -Name ssh-keyscan -Value Invoke-BashCommand;
      Set-Alias -Name ssh -Value Invoke-PowerSshCommand;
      Set-Alias -Name ssh-agent -Value Invoke-PowerSshCommand;
      Set-Alias -Name ssh-add -Value Invoke-PowerSshCommand;
      Set-Alias -Name scp -Value Invoke-PowerSshCommand;
      Set-Alias -Name sftp -Value Invoke-PowerSshCommand;
      Set-Alias -Name rsync -Value Invoke-PowerSshCommand;
      Set-Alias -Name cupVim -Value Upgrade-VimViaChoco;
      Set-Alias -Name cupVimInstall -Value Upgrade-VimInstallViaChoco;
  
  # }}}

# }}}

