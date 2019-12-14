
<#
.SYNOPSIS
  Name: script.ps1
  The purpose of this script is to blah blah... What?
  
.DESCRIPTION
  A slightly longer description of example.ps1 Why and How?

.PARAMETER InitialDirectory
  The initial directory which this example script will use.
  
.PARAMETER Add
  A switch parameter that will cause the example function to ADD content.

Add or remove PARAMETERs as required.

.NOTES
    Updated: 2017-01-01        Change comment.
    Release Date: 2017-01-01
   
  Author: YourName

.EXAMPLE
  Run the Get-Example script to create the c:\example folder:
  Get-Example -Directory c:\example

.EXAMPLE 
  Run the Get-Example script to create the folder c:\example and
  overwrite any existing folder in that location:
  Get-Example -Directory c:\example -force

See Help about_Comment_Based_Help for more .Keywords

# Comment-based Help tags were introduced in PS 2.0
#requires -version 2
#>

[CmdletBinding()]

PARAM ( );
#----------------[ Declarations ]------------------------------------------------------

$CurrentClient;
$WorkingDir;
$Projects;
$Policies;
$FSW;

# Set Error Action
# $ErrorActionPreference = "Continue"

# Dot Source any required Function Libraries
# . "C:\Scripts\Functions.ps1"

# Set any initial values
# $Examplefile = "C:\scripts\example.txt"

#----------------[ Functions ]---------------------------------------------------------

Function Get-ParentPath () {
   Return $PSScriptRoot;
}

Function Get-CurrentClient () {
   $currentClient = $Script:CurrentClient;
   Return $currentClient;
}

Function Set-CurrentClient ([String]$ClientCd) {
   $Script:CurrentClient = $ClientCd;
}

Function Get-ClientBillingXmlDir () {
   Return (Join-Path -Path '\\Filer01\DailyBuilds' -ChildPath (Join-Path -Path (Get-CurrentClient) -ChildPath 'Print\TEMP\PFILES\BillingXML'));
}

Function Get-WorkingDir () {
   If ($Script:WorkingDir -eq $null) {
      Set-WorkingDir;
   }
   $workingDir = $Script:WorkingDir;
   Return $workingDir;
}

Function Set-WorkingDir () {
   $parent = Get-ParentPath;
   $path = Join-Path -Path $parent -ChildPath "WorkingDir";
   $Script:WorkingDir = $path;
}

Function Get-Projects () {
   If ($Script:Projects -eq $null) {
      Set-Projects;
   }
   $projects = $Script:Projects;
   Return $projects;
}

Function Set-Projects () {
   $parent = Get-ParentPath;
   $path = (Join-Path -Path $parent -ChildPath (Join-Path -Path "data" -ChildPath "projects.json"));
   $Script:Projects = (Get-Content $path -Raw) | ConvertFrom-Json;
}

Function Get-Policies () {
   If ($Script:Policies -eq $null) {
      Set-Policies;
   }
   $policies = $Script:Policies;
   Return $policies;
}

Function Set-Policies () {
   $parent = Get-ParentPath;
   $path = (Join-Path -Path $parent -ChildPath (Join-Path -Path "data" -ChildPath "policies.json"));
   $Script:Policies = ((Get-Content $path -Raw) | ConvertFrom-Json);
}

Function Get-LogsDir () {
   $parent = Get-ParentPath;
   Return (Join-Path -Path $parent -ChildPath "logs");
}

Function Get-OutputDir () {
   $parent = Get-ParentPath;
   Return (Join-Path -Path $parent -ChildPath "output");
}

Function Set-RegistryClient ([int]$Client) {
   Set-ItemProperty -Path "HKCU:\Software\PRC" -Name "CustSelect" -Value "$Client|0|0|0";
   Start-Sleep -Milliseconds 500;
}

Function Get-RegistryClient () {
   Return (Split-String -Separator "|" -Input ((Get-ItemProperty -Path "HKCU:\Software\PRC").CustSelect))[0];
}

Function Register-DLL ([String]$Path) {
   If (Test-Path -Path $Path) {
      Start-Process -FilePath "regsvr32.exe" -ArgumentList "/s $Path" -Wait;
      Start-Sleep -Milliseconds 500;
   }
}

Function Unregister-DLL ([String]$Path) {
   If (Test-Path -Path $Path) {
      Start-Process -FilePath "regsvr32.exe" -ArgumentList "/u /s $Path" -Wait;
      Start-Sleep -Milliseconds 500;
   }
}

Function Invoke-FixRef ([String]$Path) {
   $fixRefPath = (Join-Path -Path (Get-ParentPath) -ChildPath (Join-Path -Path "bin" -ChildPath "CmdFixRef.exe"));
   Start-Process $fixRefPath -ArgumentList $Path -Wait;
}

Function Invoke-StatCodeStub ([String[]]$Sans, [String]$Log) {
   $san = Join-String -Strings $Sans -Separator ",";
   $statPath = (Join-Path -Path (Get-ParentPath) -ChildPath (Join-Path -Path "bin" -ChildPath "StatCodeUltra.exe"));
   Start-Process -FilePath $statPath -ArgumentList "/SAN $san /LOG $Log /RUN /EXIT" -Wait;
}

Function Build-Project ([String]$Path) {
   Invoke-FixRef -Path $Path;
   $vb6 = "C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE";
   If (-not (Test-Path -Path (Get-OutputDir) -PathType Container)) {
      New-Item -Path (Get-OutputDir) -ItemType Directory;
   }
   If (-not (Test-Path -Path (Get-LogsDir) -PathType Container)) {
      New-Item -Path (Get-LogsDir) -ItemType Directory;
   }
   Start-Process -FilePath $vb6 -ArgumentList "/Make $Path /outdir $(Get-OutputDir)" -Wait;
}

Function Copy-XmlLocal([String]$Path) {
   $clientWorkingDir = (Join-Path -Path (Get-WorkingDir) -ChildPath (Get-CurrentClient));
   If (-not (Test-Path -Path $clientWorkingDir -PathType Container)) {
      New-Item -Path $clientWorkingDir -ItemType Directory;
   }
   ## TODO: Add filter for current working list of SANs.
   Copy-Item -Path (Join-Path -Path (Get-ClientBillingXmlDir) -ChildPath $Path) -Destination $clientWorkingDir;
}

Function New-Watchers () {
   $filter = '*.Billing.XML';
   $Script:FSW = New-Object IO.FileSystemWatcher (Get-ClientBillingXmlDir), $filter -Property @{IncludeSubdirectories = $false;NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}
   New-WatcherCreated;
   New-WatcherChanged;
}

Function New-WatcherCreated () {
   Register-ObjectEvent $Script:FSW Created -SourceIdentifier FileCreated -Action {
      $name = $Event.SourceEventArgs.Name;
      $changeType = $Event.SourceEventArgs.ChangeType;
      $timeStamp = $Event.TimeGenerated;
      Copy-XmlLocal -Path $name;
   }
}

Function New-WatcherChanged () {
   Register-ObjectEvent $Script:FSW Changed -SourceIdentifier FileChanged -Action {
      $name = $Event.SourceEventArgs.Name;
      $changeType = $Event.SourceEventArgs.ChangeType;
      $timeStamp = $Event.TimeGenerated;
      Copy-XmlLocal -Path $name;
   }
}

Function Remove-Watchers () {
   Unregister-Event FileCreated;
   Unregister-Event FileChanged;
}

Function Select-Project () {
   $projects = Get-Projects;
   $names = @($projects.Projects | Select-Object -ExpandProperty Name);
   $userInput = -1;
   Do {
      For ($i = 0; $i -lt $names.Count; $i++) {
         "$i -- $($names[$i])" | Write-Host;
      }
      $userInput = Read-Host;
   } until ([Int]$userInput -ge 0 -and [Int]$userInput -lt $names.Count)
   Return ($projects.Projects | Where-Object {$_.Name -eq $names[[Int]$userInput]});
}

Function Download-Policies ([Int]$CustomerNo, [Object[]]$Policies) {
   Foreach ($pol in $Policies) {
      Invoke-ErrorCorrect -SystemAssignId $pol.SAN -CustomerId $CustomerNo -Trans $pol.Transaction;
   }
}

Function Process-Policies () {
   $prevClient = Get-RegistryClient;
   $policies = Get-Policies;
   Foreach ($client in $policies.Client) {
      $customerNo = $client.CustomerNo;
      $name = $client.Name;
      $listNo = $client.ListNo;
      $clientCd = $client.CustomerId;
      Set-CurrentClient -ClientCd $clientCd;
      $sans = $client.Policies | Select-Object -ExpandProperty SAN;
      $log = (Join-Path -Path (Get-LogsDir) -ChildPath "$(Get-Date -Format "yyyyMMdd_HH_mm_ss").log");
      New-Watchers;
      Set-RegistryClient -Client $listNo;
      Download-Policies -CustomerNo $customerNo -Policies $client.Policies;
      Invoke-StatCodeStub -Sans $sans -Log $log;
      Remove-Watchers;
   }
   Set-RegistryClient -Client $prevClient;
}


#----------------[ Main Execution ]----------------------------------------------------

# Script Execution goes here

$project = Select-Project;
Unregister-DLL -Path (Join-Path -Path $project.CIDir -ChildPath $project.Output);
Build-Project -Path (Join-Path -Path $project.Directory -ChildPath $project.VBP);
Process-Policies;
Unregister-DLL -Path (Join-Path -Path (Get-OutputDir) -ChildPath $project.Output);
Register-DLL -Path (Join-Path -Path $project.CIDir -ChildPath $project.Output);
