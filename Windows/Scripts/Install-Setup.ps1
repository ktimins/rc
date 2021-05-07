Param(
     );

Push-Location -Path $env:HOMEPATH;

###################
# New Directories #
###################

$sshDir = New-Item -ItemType Directory -Name .ssh;
$vimDir = New-Item -ItemType Directory -Name .vim;
$vimstorageDir = New-Item -ItemType Directory -Name .vimstorage;
$vimfilesDir = New-Item -ItemType Directory -Name vimfiles;
$binDir = New-Item -ItemType Directory -Name bin;
$gitDir = New-Item -ItemType Directory -Name Git;


###################
#      Path       #
###################
$userPath = [System.Environment]::GetEnvironmentVariable("PATH", "User");
$userPath = ($userPath,$binDir.FullName -join ";");
[System.Environment]::SetEnvironmentVariable("PATH", $userPath, "User");
