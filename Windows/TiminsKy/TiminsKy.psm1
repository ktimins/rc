##############################
#            VIM             #
##############################
function CD-ENF {Set-Location $ENFDir}
New-Alias -name cdenf -value CD-ENF -Description "Change folder to ENF directory"

function CD-TEMP {Set-Location $env:TEMP}

function CD-Alex {Set-Location 'C:\Users\TiminsKY\Git\Alex'}
New-Alias -name cdalex -value CD-Alex -Description "Change folder to the Service Pack Planning Directory."

function Get-Trans {
   $currLoc = Get-Location
   Set-Location "$ENFDir\Scripts"
   & .\ENFCounts.ps1
   Set-Location $currLoc
}
New-Alias -name getTrans -value Get-Trans -Description "Get the number of `"Trans In Doubts`" for today"

#Function Edit-Profile { Invoke-Expression "& 'C:/Program Files (x86)/Vim/vim80/vim.exe' $Profile" }
#New-Alias -Name EditPro -Value Edit-Profile -Description "Edit my profile with GVIM"

function Reload-Profile { & $profile }
New-Alias -name RePro -value Reload-Profile -Description "Reload my profile"

New-Alias -name Reg-Asm -value "& C:\Windows\Microsoft.NET\Framework\v4.0.30319\regasm.exe"

New-Alias -Name pl -value Push-Location -Description "Shorthand for Push-Location"
New-Alias -Name ppl -Value Pop-Location -Description "Shorthand for Pop-Location"

Function aria-DL {
   Param(
         [Parameter(Mandatory=$True, Position=1)]
         [String]$Link
        )

   Invoke-Expression "& C:\Users\TiminsKY\bin\aria2c.exe --file-allocation=none $Link"
}

Function Remote-AR7VM { Enter-PSSession HFDARIVERA7VM }
New-Alias -name AR7VM -value Remote-AR7VM -description "Create a remote session to HFDARIVERA7VM"

Function Remote-HFDDEVTEST10VM2 { Enter-PSSession -ComputerName HFDDEVTEST10VM2 -Authentication Default }
Function RDP-HFDDEVTEST10VM2 { mstsc 'C:\Users\TiminsKY\Desktop\HFDDEVTEST10VM2.RDP' }

##############################
#            TFS             #
##############################

$vs19Tf = 'C:\Program Files (x86)\Microsoft Visual Studio\2019\Preview\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\TF.exe';
$vsTf = "$env:VS140COMNTOOLS..\IDE\tf.exe";
If (Test-Path -Path $vs19Tf) { $vsTf = $vs19Tf; }
Set-Alias tf $vsTf;

Set-Alias vb6 "C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE";

##############################
#            PPM             #
##############################

Function Open-PPM {
   Param(
         [Parameter(Mandatory=$False,ValueFromPipeline=$true,Position=1)]
         [ValidateScript({$_ -match "^\d{7}$"})]
         [String]$Number
        );

   $chrome = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe";
   $opera = "C:\Users\TiminsKY\AppData\Local\Programs\Opera\launcher.exe";
   $ppmUrl = "https://portal.insurity.com/";
   $ppmRequestUrl = "https://portal.insurity.com/itg/web/knta/crt/RequestDetail.jsp?REQUEST_ID=";

   $url = "";

   If ([Bool]$Number) {
      $url = "$ppmRequestUrl$Number";
   } Else {
      $url = $ppmUrl;
   }

   Start-Process -FilePath $opera -ArgumentList $url

}

Set-Alias ppm Open-PPM;

Function Get-CompsLink {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [String]$Name,
         [Parameter(Mandatory=$false)]
         [Switch]$Copy,
         [Parameter(Mandatory=$false)]
         [Switch]$CopyAll
        );

   New-Variable -Name 'COMPS_DIR_DAILY_BUILDS' -Value '\\filer01\ci-builds\DailyBuilds\Distribution\Patches\Comps' -Option Constant;

   If ($Name -inotmatch '^.+\.[^\*]{3}$') {
      $Name = "$Name*"
   }
   $contents = Get-ChildItem -Path $COMPS_DIR_DAILY_BUILDS -Filter $Name -Recurse -File;

   $return = @();
   $contents | Sort-Object | ForEach-Object {
      $return += [pscustomObject][ordered]@{
         DLL =  $_.Name;
         Path = $_.FullName;
      };
   }

   If ($Copy) {
      $return[0].Path | Write-Verbose;
      $return[0].Path | Set-Clipboard;
   } ElseIf ($CopyAll) {
      $str = $return.Path -join "`n";
      $str | Write-Verbose;
      $str | Set-Clipboard;
   }

   Return $return;

}

Function Get-BIComps {
   Get-CompsLink -Name 'CiBilling' -Copy;
}

##############################
#         CmdFixRef          #
##############################

   Function Invoke-FixRef {
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=1)]
            [String]$Path
            );
      $fixRefPath = (Join-Path -Path 'C:\Users\TiminsKY' -ChildPath (Join-Path -Path "bin" -ChildPath "CmdFixRef.exe"));
      $paths = @();
      $Path | ForEach-Object {
         $paths += (Resolve-Path $_);
      }
      Start-Process $fixRefPath -ArgumentList $paths -Wait;
   }

   Set-Alias IFix Invoke-FixRef;

   Function Invoke-FixRefAndRun ([String]$Path) {
      Invoke-FixRef $Path;
      & $Path;
   }

   Set-Alias FixRun Invoke-FixRefAndRun;

   Function Cmd-FixRef {
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=1)]
            [String]$In,
            [Parameter(Mandatory=$false,Position=2)]
            [Int]$Depth = 32
           );

      Begin { 
         Set-Alias cmdFixRef "C:\Users\TiminsKY\bin\CmdFixRef.exe"; 
      }

      Process {

         switch(Test-Path -Path $In -PathType Container) {
            $True {
               Get-ChildItem -Path (Resolve-Path $Directory) -Recurse -Depth $Depth | Where-Object {$_.Name -match '.*\.(?:vbp|vbg)'} | Select-Object -Property FullName | ForEach-Object {
                  Start-Process cmdFixRef -ArgumentList $_.FullName -Wait;
                  if ($?) {
                     "Fixrefed $($_.FullName)" | Write-Output
                  }
               }
            }
            $False {
               If (Test-Path $In) {
                  Start-Process cmdFixRef -ArgumentList $In -Wait;
                  if ($?) {
                     "Fixrefed $($In)" | Write-Output
                  }
               } Else {
                  "File `"$In`" does not exist!" | Write-Output
               }
            }
         }

      }
   }

Function Start-CiBillVbg {
   Param();
   Invoke-FixRefAndRun -Path 'F:\Work\Products\DailyBuild\App\core\Coding\BillingDecisions\BillingInterface.vbg';
}

Set-Alias CiBillVbg Start-CiBillVbg;

Function Start-VB6 {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=1)]
         [ValidateScript({[System.IO.Path]::GetExtension($_) -match "(?:vbp|vbg)"})]
         [String]$ToOpen
        )
      Start-Process "C:\Program Files (x86)\Microsoft Visual Studio\VB98\VB6.EXE" -ArgumentList $ToOpen;
}

Function FixRef-VB6 {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=1)]
         [ValidateScript({[System.IO.Path]::GetExtension($_) -match "(?:vbp|vbg)"})]
         [String]$ToOpen
        )
   Cmd-FixRef $ToOpen;
   Start-VB6 $ToOpen;
}

Function Kill-VB6 {
   Param();
   Try {
      $proc = Get-Process -Name 'VB6' -ErrorAction Stop;
      $num = $proc.Count;
      $proc | Stop-Process -ErrorAction Stop;
      $singular = 'process has';
      $plural = 'processes have';
      "$num VB6 $(@{$true=$plural;$false=$singular}[($num -gt 1)]) been killed." | Write-Output;
   } Catch [ProcessCommandException] {
      "No VB6 process was running at time of command execution." | Write-Output;
   } Catch {}
}

##############################
#           Pass2            #
##############################

Function Avl-Recov {
   Param(
         [Parameter(Mandatory=$false,Position=1)]
         [String]$Location = "\\hfdnafile1\RWG\Crum\",
         [Parameter(Mandatory=$false,Position=2)]
         [String]$File = "CIISWH01.FIL",
         [Parameter(Mandatory=$false,Position=3)]
         [String]$Archive = "CIISWH01.FIL Archives\"
        )

      $date = Get-Date -format "yyyyMMdd"
      Copy-Item -Path "$Location$File" -Destination "$Location$Archive$File-$date.old" -Force
      Copy-Item -Path "$Location$File" -Destination "$($env:TEMP)\$File" -Force

      If (Test-Item "$($env:TEMP)\$File.OLD") {
         Remove-Item "$($env:TEMP)\$File.OLD" -Force;
      }
      & 'C:\Users\TiminsKy\bin\avlrecov32.exe' "$($env:TEMP)\$File"

      Copy-Item -Path "$($env:TEMP)\$File" -Destination "$Location$File" -Force

}


##############################
#           Random           #
##############################

Function Create-Msgbox {
Param (
    [String]$Message,
    [String]$Title = 'Message box title',   
    [String]$buttons = 'OKCancel'
)
# This function displays a message box by calling the .Net Windows.Forms (MessageBox class)
 
# Load the assembly
Add-Type -AssemblyName System.Windows.Forms | Out-Null
 
# Define the button types
Switch ($buttons) {
   'ok' {$btn = [System.Windows.Forms.MessageBoxButtons]::OK; break}
   'okcancel' {$btn = [System.Windows.Forms.MessageBoxButtons]::OKCancel; break}
   'AbortRetryIgnore' {$btn = [System.Windows.Forms.MessageBoxButtons]::AbortRetryIgnore; break}
   'YesNoCancel' {$btn = [System.Windows.Forms.MessageBoxButtons]::YesNoCancel; break}
   'YesNo' {$btn = [System.Windows.Forms.MessageBoxButtons]::yesno; break}
   'RetryCancel'{$btn = [System.Windows.Forms.MessageBoxButtons]::RetryCancel; break}
   Default {$btn = [System.Windows.Forms.MessageBoxButtons]::RetryCancel; break}
}
 
  # Display the message box
  $Return=[System.Windows.Forms.MessageBox]::Show($Message,$Title,$btn)
  $Return
}

New-Alias -Name msgbox -Value Create-Msgbox;

Function Invoke-FileWatcher {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [String]$Folder,
         [Parameter(Mandatory=$true,Position=1)]
         [String]$Destination,
         [Parameter(Mandatory=$false,Position=2)]
         [String]$Filter = '*.*'
        );



   $watcher = New-Object System.IO.FileSystemWatcher $Folder, $Filter -Property @{
      IncludeSubdirectories = $true;
      NotifyFilter = [System.IO.NotifyFilters]'FileName,LastWrite,CreationTime';
   }

   $log = 'outlog.txt';

   $action = {
      $name = $Event.SourceEventArgs.Name;
      $fullName = $Event.SourceEventArgs.FullPath;
      $timeStamp = $Event.TimeGenerated;
      $changeType = $Event.SourceEventArgs.ChangeType;
      $str = "The file '$name' was $changeType at $timeStamp";

      $outlog = (Join-Path -Path $Destination -ChildPath $log);
      $outFile = (Join-path -Path $Destination -ChildPath $name);

      Write-Host $str -fore green;
      Out-File -FilePath $outlog -Append -InputObject $str;
      Copy-Item -Path $fullName -Destination $outFile
         If ($?) {
            $strCopy = "The file '$name' was copied to '$outFile'.";
            Write-Host $strCopy -fore blue;
            Out-File -FilePath $outlog -Append -InputObject $strCopy;
         }
   }
   Register-ObjectEvent $watcher Created -SourceIdentifier FileCreated -Action $action;
   Register-ObjectEvent $watcher Changed -SourceIdentifier FileChanged -Action $action;
}

Function Get-FileInfoC2 {
   param(
         [string]$path, 
         [string]$outputFile, 
         [string]$include = "*.*", 
         [string]$exclude = ""
        )
      "File Name,Trans Type,Last Write Time,Line Count,Character Count Excluding First Line,Last Line Length Count,Last Node Name,Is Valid XML" | Out-File $outputFile -encoding "UTF8"
      Get-ChildItem -Recurse -Depth 1 -Include $include -Exclude $exclude -Path $path |
      Foreach-Object { Write-Host "Counting $($_.FullName)"
         $file = Get-Content $_.FullName
            If (((Join-String $file) | Where-Object {$_ -match '(PCNM|CACA|CANC)<\/CoTransTypeCd'})) {
               $validXML = $true
                  If (((Join-String $file) | Where-Object {$_ -notmatch '<\/CPMessage>'} )) {
                     $validXML = $false;
                  }
               $fileStats = $file | Measure-Object -line
                  $linesInFile = $fileStats.Lines
                  $stats = (Join-String ($file | Select-Object -Skip 1)) | Measure-Object -Character
                  $charInFile = $stats.Characters
                  $secLineLength = ($file | Select-Object -Index ($linesInFile - 1) | Measure-Object -Character).Characters
                  $words = ([regex]::matches($file, '(PCNM|CACA|CANC)<\/CoTransTypeCd') | %{$_.value.SubString(0,4)})
                  $lastTag = (Select-String -InputObject (Join-String $file) -Pattern "<[^ \/<>]+(?:_\d+)?>" -AllMatches).Matches.Value[-1]
                  "$_,$words,$($_.LastWriteTime),$linesInFile,$charInFile,$secLineLength,$lastTag,$validXML"
            }
      } | Out-File $outputFile -append -encoding "UTF8"
   Write-Host "Complete"
}

Function Test-Command {
   Param(
         [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=1)]
         [String]$Command,
         [Parameter(Mandatory=$False,Position=2)]
         [Int]$Reps = 20
        )

      $time = 0
      For ($i = 0; $i -lt $Reps; $i++) {
         $measure = Measure-Command { Invoke-Expression $Command }
         $seconds = [Math]::Round(($measure.TotalSeconds),2)
            $time += $seconds
            "Run : $('{0,-5}' -f $i)  --- Time : $( '{0:###.00}' -f $seconds) Seconds"
      }

   $testTime = [Math]::Round(($time / $Reps),2)
      Return @( $testTime, $Reps )
}



Function Get-Config {
   <#
      .DESCRIPTION
      This reads in the config file and translates it from JSON to an object.
      If the config file includes C style comments "//", It will parse those out and then convert to an object.
      To parse out the comment lines, external JsonFormatterPlus.DLL is needed.

      .PARAMETER configFile
      This is the location of the config file being used by the script.
#>
      [CmdletBinding()]
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
            [string]$configFile
           )

         Begin {
            $configFile | Write-Host
               If (Test-Path $configFile) {
                  $text = Get-Content $configFile
               } Else {
                  Throw "Config file is not found."
               }
         }

   Process {
      If ($text -match "//") {
         If (Test-Path "$PSScriptRoot\JsonFormatterPlus.dll") {
            Add-Type -Path "$PSScriptRoot\JsonFormatterPlus.dll"
         } ElseIf (Test-Path "$PSScriptRoot\Modules\JsonFormatterPlus.dll") {
            Add-Type -Path "$PSScriptRoot\Modules\JsonFormatterPlus.dll"
         } Else {
            Throw "Unable to find the 'JsonFormatterPlus.dll' module. `nPlease make sure it is either in the same directory as this script or in a folder named 'Modules' under this directory."
         }

         $textNoQuote = $text -Replace "'",''
            $textNoComment = $textNoQuote -Replace '(?m)^[ ]+//(?:[\w]+ : "[\w\W]+")?',''
            $config = [JsonFormatterPlus.JsonFormatter]::Minify($textNoComment) | ConvertFrom-Json
      } Else {
         $config = $text -join "`n" | ConvertFrom-Json
      }
   }

   End {
      Return $config
   }
}

##############################
# Externally grabbed scripts #
##############################


Function Start-FileSystemWatcher  {
   [cmdletbinding()]
   Param (
         [parameter()]
         [string]$Path,
         [parameter()]
         [ValidateSet('Changed','Created','Deleted','Renamed')]
         [string[]]$EventName,
         [parameter()]
         [string]$Filter,
         [parameter()]
         [System.IO.NotifyFilters]$NotifyFilter,
         [parameter()]
         [switch]$Recurse,
         [parameter()]
         [scriptblock]$Action
         );
#region Build  FileSystemWatcher
   $FileSystemWatcher  = New-Object  System.IO.FileSystemWatcher;
   If (-NOT $PSBoundParameters.ContainsKey('Path')){
      $Path  = $PWD;
   }
   $FileSystemWatcher.Path = $Path;
   If ($PSBoundParameters.ContainsKey('Filter')) {
      $FileSystemWatcher.Filter = $Filter;
   }
   If ($PSBoundParameters.ContainsKey('NotifyFilter')) {
      $FileSystemWatcher.NotifyFilter =  $NotifyFilter;
   }
   If ($PSBoundParameters.ContainsKey('Recurse')) {
      $FileSystemWatcher.IncludeSubdirectories =  $True;
   }
   If (-NOT $PSBoundParameters.ContainsKey('EventName')){
      $EventName  = 'Changed','Created','Deleted','Renamed';
   }
   If (-NOT $PSBoundParameters.ContainsKey('Action')){
      $Action  = {
         Switch  ($Event.SourceEventArgs.ChangeType) {
            'Renamed'  {
               $Object  = "{0} was  {1} to {2} at {3}" -f $Event.SourceArgs[-1].OldFullPath,
               $Event.SourceEventArgs.ChangeType,
               $Event.SourceArgs[-1].FullPath,
               $Event.TimeGenerated;
            }
            Default  {
               $Object  = "{0} was  {1} at {2}" -f $Event.SourceEventArgs.FullPath,
               $Event.SourceEventArgs.ChangeType,
               $Event.TimeGenerated;
            }
         }
         $WriteHostParams  = @{
            ForegroundColor = 'Green'
               BackgroundColor = 'Black'
               Object =  $Object;
         }
         Write-Host  @WriteHostParams;
      }
   }
#region  Initiate Jobs for FileSystemWatcher
   $ObjectEventParams  = @{
      InputObject =  $FileSystemWatcher;
      Action =  $Action;
   }
   ForEach  ($Item in  $EventName) {
      $ObjectEventParams.EventName = $Item;
      $ObjectEventParams.SourceIdentifier =  "File.$($Item)";
      Write-Verbose  "Starting watcher for Event: $($Item)";
      $Null  = Register-ObjectEvent  @ObjectEventParams;
   }
#endregion  Initiate Jobs for FileSystemWatcher
}


function Get-Assembly
{
   <#
      .SYNOPSIS
      Get .net assemblies loaded in your session
      .DESCRIPTION
      List assemblies loaded in the current session. Wildcards are supported. 
      Requires powershell version 2
      .PARAMETER Name
      Name of the assembly to look for. Supports wildcards
      .EXAMPLE
      Get-Assembly

      Returns all assemblies loaded in the current session
      .EXAMPLE
      Get-Assembly -Name *ServiceBus*

      Returns loaded assemblies which contains ServiceBus

      .NOTES 
      SMART
      AUTHOR: Tore Groneng tore@firstpoint.no @toregroneng tore.groneng@gmail.com
#>
      [cmdletbinding()]
      Param(
            [String] $Name
           )
         $f = $MyInvocation.MyCommand.Name 
         Write-Verbose -Message "$f - Start"

         if($name)
         {
            $dlls = [System.AppDomain]::CurrentDomain.GetAssemblies() | where {$_.FullName -like "$name"}
         }
         else
         {
            $dlls = [System.AppDomain]::CurrentDomain.GetAssemblies()
         }

   if($dlls)
   {
      foreach ($dll in $dlls)
      {
         $Assembly = "" | Select-Object FullName, Version, Culture, PublicKeyToken
            $DllArray = $dll -split ","
            if($DllArray.Count -eq 4)
            {
               Write-Verbose -Message "$f -  Building custom object"
                  $Assembly.Fullname = $DllArray[0]
                  $Assembly.Version = $DllArray[1].Replace("Version=","")
                  $Assembly.Culture = $DllArray[2].Replace("Culture=","")
                  $Assembly.PublicKeyToken = $DllArray[3].Replace("PublicKeyToken=","")
                  $Assembly
            }
            else
            {
               Write-Verbose -Message "$f-  Array length/count is NOT 4"
            }
      }
   }
   else
   {
      Write-Verbose -Message "$f -  nothing found"
   }
   Write-Verbose -Message "$f - End"
}

Function Register-File {
   <#
      .SYNOPSIS
      A function that uses the utility regsvr32.exe ltility to register a file
      .PARAMETER Filepath
      The file path of the file to be registered.
#>
      [CmdletBinding()]
      Param(
#[Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
            [ValidateScript({ Test-Path -Path $_ -PathType 'Leaf' })]
            [String]$FilePath
           )
         Process {
            Try {
               $Result = Start-Process -FilePath 'echoargs.exe' -Args "/s <code>$FilePath</code>" -Wait -NoNewWindow -PassThru
                  $Result = Start-Process -FilePath 'regsvr32.exe' -Args "/s <code>$FilePath</code>" -Wait -NoNewWindow -PassThru
                  Wait-Process -Id $Result.Id
            } Catch {
               Write-Error $_.Exception.Message
                  $false
            }
         }
}

Function Get-OutlookAppointments {
   param ( 
         [Int] $NumDays = 7,
         [DateTime] $Start = [DateTime]::Now ,
         [DateTime] $End   = [DateTime]::Now.AddDays($NumDays)
         )

      Process {
         $outlook = New-Object -ComObject Outlook.Application

            $session = $outlook.Session
            $session.Logon()

            $apptItems = $session.GetDefaultFolder(9).Items
            $apptItems.Sort("[Start]")
            $apptItems.IncludeRecurrences = $true
            $apptItems = $apptItems

            $restriction = "[End] >= '{0}' AND [Start] <= '{1}'" -f $Start.ToString("g"), $End.ToString("g")

            foreach($appt in $apptItems.Restrict($restriction))
            {
               If (([DateTime]$Appt.Start -[DateTime]$appt.End).Days -eq "-1") {
                  "All Day Event : {0}  -- Location: {3} -- Organized by {2}" -f $appt.Subject, $appt.Location, $appt.Organizer
               }
               Else {
                  "{0:ddd HH:mm:ss} - {1:HH:mm:ss} : {2} -- Location: {3} -- Organized by {4}" -f [DateTime]$appt.Start, [DateTime]$appt.End, $appt.Subject, $appt.Location, $appt.Organizer
               }

            }

         $outlook = $session = $null;
      }
}

function Get-DomainUser {
   PARAM($DisplayName)
      $Search = [adsisearcher]"(&(objectCategory=person)(objectClass=User)(displayname=$DisplayName))"
      foreach ($user in $($Search.FindAll())){
         New-Object -TypeName PSObject -Property @{
            "DisplayName" = $user.properties.displayname
               "UserName"    = $user.properties.samaccountname
               "Description" = $user.properties.description}
      }
}

Function Get-IniContent {  
   <#  
      .Synopsis  
      Gets the content of an INI file  

      .Description  
      Gets the content of an INI file and returns it as a hashtable  

      .Notes  
      Author        : Oliver Lipkau <oliver@lipkau.net>  
      Blog        : http://oliver.lipkau.net/blog/  
      Source        : https://github.com/lipkau/PsIni 
      http://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91 
Version        : 1.0 - 2010/03/12 - Initial release  
                 1.1 - 2014/12/11 - Typo (Thx SLDR) 
                 Typo (Thx Dave Stiff) 

#Requires -Version 2.0  

                 .Inputs  
                 System.String  

                 .Outputs  
                 System.Collections.Hashtable  

                 .Parameter FilePath  
                 Specifies the path to the input file.  

                 .Example  
                 $FileContent = Get-IniContent "C:\myinifile.ini"  
                 -----------  
                 Description  
                 Saves the content of the c:\myinifile.ini in a hashtable called $FileContent  

                 .Example  
                 $inifilepath | $FileContent = Get-IniContent  
                 -----------  
                 Description  
                 Gets the content of the ini file passed through the pipe into a hashtable called $FileContent  

                 .Example  
                 C:\PS>$FileContent = Get-IniContent "c:\settings.ini"  
                 C:\PS>$FileContent["Section"]["Key"]  
                 -----------  
                 Description  
                 Returns the key "Key" of the section "Section" from the C:\settings.ini file  

                 .Link  
                 Out-IniFile  
#>  

                 [CmdletBinding()]  
                 Param(  
                       [ValidateNotNullOrEmpty()]  
                       [ValidateScript({(Test-Path $_) -and ((Get-Item $_).Extension -eq ".ini")})]  
                       [Parameter(ValueFromPipeline=$True,Mandatory=$True)]  
                       [string]$FilePath  
                      )  

                    Begin  
                    {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function started"}  

   Process  
   {  
      Write-Verbose "$($MyInvocation.MyCommand.Name):: Processing file: $Filepath"  

         $ini = @{}  
      switch -regex -file $FilePath  
      {  
         "^\[(.+)\]$" # Section  
         {  
            $section = $matches[1]  
               $ini[$section] = @{}  
            $CommentCount = 0  
         }  
         "^(;.*)$" # Comment  
         {  
            if (!($section))  
            {  
               $section = "No-Section"  
                  $ini[$section] = @{}  
            }  
            $value = $matches[1]  
               $CommentCount = $CommentCount + 1  
               $name = "Comment" + $CommentCount  
               $ini[$section][$name] = $value  
         }   
         "(.+?)\s*=\s*(.*)" # Key  
         {  
            if (!($section))  
            {  
               $section = "No-Section"  
                  $ini[$section] = @{}  
            }  
            $name,$value = $matches[1..2]  
               $ini[$section][$name] = $value  
         }  
      }  
      Write-Verbose "$($MyInvocation.MyCommand.Name):: Finished Processing file: $FilePath"  
         Return $ini  
   }  

   End  
   {Write-Verbose "$($MyInvocation.MyCommand.Name):: Function ended"}  
} 

############################################################################## 
## 
## Compare-File 
## 
##############################################################################
Function Compare-File {

   <# 

      .SYNOPSIS 

      Compares two files, displaying differences in a manner similar to traditional 
      console-based diff utilities. 

#>

      param( 
## The first file to compare 
            $file1, 

## The second file to compare 
            $file2,

## The pattern (if any) to use as a filter for file 
## differences 
            $pattern = ".*" 
           )

## Get the content from each file 
      $content1 = Get-Content $file1 
      $content2 = Get-Content $file2

## Compare the two files. Get-Content annotates output objects with 
## a 'ReadCount' property that represents the line number in the file 
## that the text came from. 
      $comparedLines = Compare-Object $content1 $content2 -IncludeEqual | 
      Sort-Object { $_.InputObject.ReadCount } 

   $lineNumber = 0 
      $comparedLines | foreach {

## Keep track of the current line number, using the line 
## numbers in the "after" file for reference. 
         if($_.SideIndicator -eq "==" -or $_.SideIndicator -eq "=>") 
         { 
            $lineNumber = $_.InputObject.ReadCount 
         } 

## If the text matches the pattern, output a custom object 
## that displays text like this: 
## 
## Line Operation Text 
## ---- --------- ---- 
## 59 added New text added 
## 
         if($_.InputObject -match $pattern) 
         { 
            if($_.SideIndicator -ne "==") 
            { 
               if($_.SideIndicator -eq "=>") 
               { 
                  $lineOperation = "added" 
               } 
               elseif($_.SideIndicator -eq "<=") 
               { 
                  $lineOperation = "deleted" 
               } 

               [PSCustomObject] @{ 
                  Line = $lineNumber 
                     Operation =$lineOperation 
                     Text = $_.InputObject  
               } 
            } 
         } 
      }
}

Function Test-ADAuthentication {
   param($username,$password)
      (new-object directoryservices.directoryentry "",$username,$password).psbase.name -ne $null
}

##############################
#        SharePoint          #
#############################

<#  
.SYNOPSIS  
Retieve Folder        
.DESCRIPTION  
Read Folder operation via SharePoint 2013 REST API
url: http://site url/_api/web/GetFolderByServerRelativeUrl('/Shared Documents')
method: GET
headers:
Authorization: "Bearer " + accessToken
accept: "application/json;odata=verbose" or "application/atom+xml"
.NOTES  
Prerequisite   : Invoke-RestSPO function     
.EXAMPLE  
$Folder = Get-SPOFolder -WebUrl $WebUrl -UserName $UserName -Password $Password -FolderUrl '/Shared Documents/Folder To Read'     
#>
Function Get-SPOFolder(){

   Param(
         [Parameter(Mandatory=$True)]
         [String]$WebUrl,

         [Parameter(Mandatory=$True)]
         [String]$UserName,

         [Parameter(Mandatory=$False)]
         [String]$Password, 

         [Parameter(Mandatory=$True)]
         [String]$FolderUrl

        )


      $Url = $WebUrl + "/_api/web/GetFolderByServerRelativeUrl('" + $FolderUrl + "')"
      Invoke-RestSPO $Url Get $UserName $Password 
}

<#  
.SYNOPSIS  
Create Folder        
.DESCRIPTION  
Create Folder operation via SharePoint 2013 REST API.
url: http://site url/_api/web/folders
method: POST
body: { '__metadata': { 'type': 'SP.Folder' }, 'ServerRelativeUrl': '/document library relative url/folder name'}     
Headers: 
Authorization: "Bearer " + accessToken
X-RequestDigest: form digest value
accept: "application/json;odata=verbose"
content-type: "application/json;odata=verbose"
content-length:length of post body
.NOTES  
Prerequisite   : Invoke-RestSPO function     
.EXAMPLE  
$Folder = Create-SPOFolder -WebUrl $WebUrl -UserName $UserName -Password $Password -FolderUrl '/Shared Documents/Folder To Create'     
#>
Function Create-SPOFolder(){

   Param(
         [Parameter(Mandatory=$True)]
         [String]$WebUrl,

         [Parameter(Mandatory=$True)]
         [String]$UserName,

         [Parameter(Mandatory=$False)]
         [String]$Password, 

         [Parameter(Mandatory=$True)]
         [String]$FolderUrl

        )


      $Url = $WebUrl + "/_api/web/folders"
      $folderPayload = @{ 
         __metadata =  @{'type' = 'SP.Folder' }; 
         ServerRelativeUrl = $FolderUrl; 
      } | ConvertTo-Json


   $contextInfo = Get-SPOContextInfo  $WebUrl $UserName $Password
      Invoke-RestSPO -Url $Url -Method Post -UserName $UserName -Password $Password -Metadata $folderPayload -RequestDigest $contextInfo.GetContextWebInformation.FormDigestValue 
}


<#  
.SYNOPSIS  
Update Folder        
.DESCRIPTION  
Update Folder operation via SharePoint 2013 REST API.
url: http://site url/_api/web/GetFolderByServerRelativeUrl('/Folder Name')
method: POST
body: { '__metadata': { 'type': 'SP.Folder' }, 'Name': 'New name' }
Headers: 
Authorization: "Bearer " + accessToken
X-RequestDigest: form digest value
"IF-MATCH": etag or "*"
"X-HTTP-Method":"MERGE",
   accept: "application/json;odata=verbose"
   content-type: "application/json;odata=verbose"
   content-length:length of post body
   .NOTES  
   Prerequisite   : Invoke-RestSPO function     
   .EXAMPLE  
   Update-SPOFolder -WebUrl $WebUrl -UserName $UserName -Password $Password -FolderUrl '/Shared Documents/Folder To Update'  -FolderName "New Folder Name"     
#>
   Function Update-SPOFolder(){

      Param(
            [Parameter(Mandatory=$True)]
            [String]$WebUrl,

            [Parameter(Mandatory=$True)]
            [String]$UserName,

            [Parameter(Mandatory=$False)]
            [String]$Password, 

            [Parameter(Mandatory=$True)]
            [String]$FolderUrl,

            [Parameter(Mandatory=$True)]
            [String]$FolderName

           )


         $Url = $WebUrl + "/_api/web/GetFolderByServerRelativeUrl('" + $FolderUrl + "')"
         $folderPayload = @{ 
            __metadata =  @{'type' = 'SP.Folder' }; 
         } 
      if($FolderName) {
         $folderPayload['Name'] = $FolderName
      }

      $folderPayload = $folderPayload | ConvertTo-Json


         $contextInfo = Get-SPOContextInfo  $WebUrl $UserName $Password
         Invoke-RestSPO -Url $Url -Method Post -UserName $UserName -Password $Password -Metadata $folderPayload -RequestDigest $contextInfo.GetContextWebInformation.FormDigestValue -ETag "*" -XHTTPMethod "MERGE"
   }

<#  
.SYNOPSIS  
Delete Folder        
.DESCRIPTION  
Delete Folder operation via SharePoint 2013 REST API.
url: http://site url/_api/web/GetFolderByServerRelativeUrl('/Folder Name')
method: POST
Headers: 
Authorization: "Bearer " + accessToken
X-RequestDigest: form digest value
"IF-MATCH": etag or "*"
"X-HTTP-Method":"DELETE"
.NOTES  
Prerequisite   : Invoke-RestSPO function     
.EXAMPLE  
Delete-SPOFolder -WebUrl $WebUrl -UserName $UserName -Password $Password -FolderUrl '/Shared Documents/Folder To Delete'      
#>
Function Delete-SPOFolder(){

   Param(
         [Parameter(Mandatory=$True)]
         [String]$WebUrl,

         [Parameter(Mandatory=$True)]
         [String]$UserName,

         [Parameter(Mandatory=$False)]
         [String]$Password, 

         [Parameter(Mandatory=$True)]
         [String]$FolderUrl

        )


      $Url = $WebUrl + "/_api/web/GetFolderByServerRelativeUrl('" + $FolderUrl + "')"
      $contextInfo = Get-SPOContextInfo  $WebUrl $UserName $Password
      Invoke-RestSPO -Url $Url -Method Post -UserName $UserName -Password $Password -RequestDigest $contextInfo.GetContextWebInformation.FormDigestValue -ETag "*" -XHTTPMethod "DELETE"
}
Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

<#
.Synopsis
Sends an HTTP or HTTPS request to a SharePoint Online REST-compliant web service.
.DESCRIPTION
This function sends an HTTP or HTTPS request to a Representational State
Transfer (REST)-compliant ("RESTful") SharePoint Online web service.
.EXAMPLE
Invoke-SPORestMethod -Url "https://contoso.sharepoint.com/_api/web"
.EXAMPLE
Invoke-SPORestMethod -Url "https://contoso.sharepoint.com/_api/contextinfo" -Method "Post"
#>

Function Invoke-RestSPO(){

   Param(
         [Parameter(Mandatory=$True)]
         [String]$Url,

         [Parameter(Mandatory=$False)]
         [Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

         [Parameter(Mandatory=$True)]
         [String]$UserName,

         [Parameter(Mandatory=$False)]
         [String]$Password,

         [Parameter(Mandatory=$False)]
         [String]$Metadata,

         [Parameter(Mandatory=$False)]
         [System.Byte[]]$Body,

         [Parameter(Mandatory=$False)]
         [String]$RequestDigest,

         [Parameter(Mandatory=$False)]
            [String]$ETag,

         [Parameter(Mandatory=$False)]
            [String]$XHTTPMethod,

         [Parameter(Mandatory=$False)]
            [System.String]$Accept = "application/json;odata=verbose",

         [Parameter(Mandatory=$False)]
            [String]$ContentType = "application/json;odata=verbose",

         [Parameter(Mandatory=$False)]
            [Boolean]$BinaryStringResponseBody = $False

               )




                  if([string]::IsNullOrEmpty($Password)) {
                     $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
                  }
                  else {
                     $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
                  }


   $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
      $request = [System.Net.WebRequest]::Create($Url)
      $request.Credentials = $credentials
      $request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
      $request.ContentType = $ContentType
      $request.Accept = $Accept
      $request.Method=$Method

      if($RequestDigest) { 
         $request.Headers.Add("X-RequestDigest", $RequestDigest)
      }
   if($ETag) { 
      $request.Headers.Add("If-Match", $ETag)
   }
   if($XHTTPMethod) { 
      $request.Headers.Add("X-HTTP-Method", $XHTTPMethod)
   }
   if($Metadata -or $Body) {
      if($Metadata) {     
         $Body = [byte[]][char[]]$Metadata
      }      
      $request.ContentLength = $Body.Length 
         $stream = $request.GetRequestStream()
         $stream.Write($Body, 0, $Body.Length)
   }
   else {
      $request.ContentLength = 0
   }

#Process Response
   $response = $request.GetResponse()
      try {
         if($BinaryStringResponseBody -eq $False) {    
            $streamReader = New-Object System.IO.StreamReader $response.GetResponseStream()
               try {
                  $data=$streamReader.ReadToEnd()
                     $results = $data | ConvertFrom-Json
                     $results.d 
               }
            finally {
               $streamReader.Dispose()
            }
         }
         else {
            $dataStream = New-Object System.IO.MemoryStream
               try {
                  Stream-CopyTo -Source $response.GetResponseStream() -Destination $dataStream
                     $dataStream.ToArray()
               }
            finally {
               $dataStream.Dispose()
            } 
         }
      }
   finally {
      $response.Dispose()
   }

}


# Get Context Info 
Function Get-SPOContextInfo(){

   Param(
         [Parameter(Mandatory=$True)]
         [String]$WebUrl,

         [Parameter(Mandatory=$True)]
         [String]$UserName,

         [Parameter(Mandatory=$False)]
         [String]$Password
        )


      $Url = $WebUrl + "/_api/contextinfo"
      Invoke-RestSPO $Url Post $UserName $Password
}



Function Stream-CopyTo([System.IO.Stream]$Source, [System.IO.Stream]$Destination)
{
   $buffer = New-Object Byte[] 8192 
      $bytesRead = 0
      while (($bytesRead = $Source.Read($buffer, 0, $buffer.Length)) -gt 0)
      {
         $Destination.Write($buffer, 0, $bytesRead)
      }
}

#requires -version 5.0
Function ConvertTo-Markdown {
    <#
.Synopsis
Convert pipeline output to a markdown document.
.Description
This command is designed to accept pipelined output and create a markdown document. The pipeline output will formatted as a text block. You can optionally define a title, content to appear before the output and content to appear after the output.

The command does not create a text file. You need to pipe results from this command to a cmdlet like Out-File or Set-Content. See examples.
.Parameter Title
Specify a top level title. You do not need to include any markdown.
.Parameter PreContent
Enter whatever content you want to appear before converted input. You can use whatever markdown you wish.
.Parameter PostContent
Enter whatever content you want to appear after converted input. You can use whatever markdown you wish.
.Parameter Width
Specify the document width. Depending on what you intend to do with the markdown from this command you may want to adjust this value.
.Example
PS C:\> Get-Service Bits,Winrm | Convertto-Markdown -title "Service Check" -precontent "## $($env:computername)" -postcontent "_report $(Get-Date)_" 

# Service Check

## THINK51

```text

 Status   Name               DisplayName
 ------   ----               -----------
 Running  Bits               Background Intelligent Transfer Ser...
 Running  Winrm              Windows Remote Management (WS-Manag...
```

_report 07/20/2018 18:40:52_

.Example
PS C:\> Get-Service Bits,Winrm | Convertto-Markdown -title "Service Check" -precontent "## $($env:computername)" -postcontent "_report $(Get-Date)_" | Out-File c:\work\svc.md

Re-run the previous command and save output to a file.

.Example
PS C:\> $computers = "srv1","srv2","srv4"
PS C:\> $Title = "System Report"
PS C:\> $footer = "_report run $(Get-Date) by $($env:USERDOMAIN)\$($env:USERNAME)_"
PS C:\> $sb =  {
>> $os = get-ciminstance -classname win32_operatingsystem -property caption,lastbootUptime
>> [PSCustomObject]@{
>> PSVersion = $PSVersionTable.PSVersion
>> OS = $os.caption
>> Uptime = (Get-Date) - $os.lastbootUpTime
>> SizeFreeGB = (Get-Volume -DriveLetter C).SizeRemaining /1GB
>> }
>> }
PS C:\> $out = Convertto-Markdown -title $Title
PS C:\> foreach ($computer in $computers) {
>>  $out+= Invoke-command -scriptblock $sb -ComputerName $computer -HideComputerName |
>>  Select-Object -Property * -ExcludeProperty RunspaceID |
>>  ConvertTo-Markdown -PreContent "## $($computer.toUpper())"
>> }
PS C:\>$out += ConvertTo-Markdown -PostContent $footer
PS C:\>$out | set-content c:\work\report.md

Here is an example that create a series of markdown fragments for each computer and at the end creates a markdown document.
.Link
Convertto-HTML
.Link
Out-File

.Notes
Learn more about PowerShell: https://jdhitsolutions.com/blog/essential-powershell-resources/

.Inputs
[object]
#>

   [cmdletbinding()]
   [outputtype([string[]])]
   Param(
       [Parameter(Position = 0, ValueFromPipeline)]
       [object]$Inputobject,
       [Parameter()]
       [string]$Title,
       [string[]]$PreContent,
       [string[]]$PostContent,
       [ValidateScript( {$_ -ge 10})]
       [int]$Width = 80
   )

   Begin {
       Write-Verbose "[BEGIN  ] Starting $($myinvocation.MyCommand)"
       #initialize an array to hold incoming data
       $data = @()

       #initialize an empty here string for markdown text
       $Text = @"

"@
       If ($title) {
           Write-Verbose "[BEGIN  ] Adding Title: $Title"
           $Text += "# $Title`n`n"
       }
       If ($precontent) {
           Write-Verbose "[BEGIN  ] Adding Precontent"
           $Text += $precontent
           $text += "`n`n"
       }

   } #begin

   Process {
       #add incoming objects to data array
       Write-Verbose "[PROCESS] Adding processed object"
       $data += $Inputobject

   } #process
   End {
       #add the data to the text
       if ($data) {
           #convert data to strings and trim each line
           Write-Verbose "[END    ] Converting data to strings"
           [string]$trimmed = (($data | Out-String -Width $width).split("`n")).ForEach( {"$($_.trimend())`n"})
           Write-Verbose "[END    ] Adding to markdown"
           $text += @"
``````text
$($trimmed.trimend())
``````

"@
        }

        If ($postcontent) {
            Write-Verbose "[END    ] Adding postcontent"
            $text += "`n"
            $text += $postcontent
        }
        #write the markdown to the pipeline
        $text
        Write-Verbose "[END    ] Ending $($myinvocation.MyCommand)"
    } #end

} #close ConvertTo-Markdown


function Get-ComObject {
<#
.Synopsis
Returns a list of ComObjects

.DESCRIPTION
This function has two parameter sets, it can either return all ComObject or a sub-section by the filter parameter. This information is gathered from the HKLM:\Software\Classes container.

.NOTES   
Name: Get-ComObject
Author: Jaap Brasser
Version: 1.0
DateUpdated: 2013-06-24

.LINK
http://www.jaapbrasser.com

.PARAMETER Filter
The string that will be used as a filter. Wildcard characters are allowed.
	
.PARAMETER ListAll
Switch parameter, if this parameter is used no filter is required and all ComObjects are returned

.EXAMPLE
Get-ComObject -Filter *Application

Description:
Returns all objects that match the filter

.EXAMPLE
Get-ComObject -Filter ????.Application

Description:
Returns all objects that match the filter

.EXAMPLE
Get-ComObject -ListAll

Description:
Returns all ComObjects
#>
    param(
        [Parameter(Mandatory=$true,
        ParameterSetName='FilterByName')]
            [string]$Filter,
        [Parameter(Mandatory=$true,
        ParameterSetName='ListAllComObjects')]
            [switch]$ListAll
    )
    $ListofObjects = Get-ChildItem HKLM:\Software\Classes -ErrorAction SilentlyContinue | 
    Where-Object {
        $_.PSChildName -match '^\w+\.\w+$' -and (Test-Path -Path "$($_.PSPath)\CLSID")
    } | Select-Object -ExpandProperty PSChildName 
    
    if ($Filter) {
        $ListofObjects | Where-Object {$_ -match $Filter}
    } else {
        $ListofObjects
    }
}

##############################
#           Export           #
##############################
Export-ModuleMember -Alias * -Function *
