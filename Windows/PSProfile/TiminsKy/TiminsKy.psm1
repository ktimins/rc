##############################
#            VIM             #
##############################
Function Open-Vim { Invoke-Expression "C:/Program Files (x86)/Vim/vim80/vim.exe" }
New-Alias -Name vim -Value Open-Vim -Description "Open normal Vim from Vim80"

Function Open-GVim { Invoke-Expression "C:/Program Files (x86)/Vim/vim80/gvim.exe" }
New-Alias -Name gvim -Value Open-GVim -Description "Open GVim from Vim80"

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

Function Edit-Profile { Invoke-Expression "'C:/Program Files (x86)/Vim/vim80/vim.exe' $Profile" }
New-Alias -Name EditPro -Value Edit-Profile -Description "Edit my profile with GVIM"

function Reload-Profile { & $profile }
New-Alias -name RePro -value Reload-Profile -Description "Reload my profile"

New-Alias -name Reg-Asm -value "C:\Windows\Microsoft.NET\Framework\v4.0.30319\regasm.exe"

Function aria-DL {
   Param(
         [Parameter(Mandatory=$True, Position=1)]
         [String]$Link
        )

   Invoke-Expression "C:\Users\TiminsKY\bin\aria2c.exe --file-allocation=none $Link"
}

Function Remote-AR7VM { Enter-PSSession HFDARIVERA7VM }
New-Alias -name AR7VM -value Remote-AR7VM -description "Create a remote session to HFDARIVERA7VM"


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

   Remove-Item "$($env:TEMP)\$File.OLD" -Force
   avlrecov32.exe "$($env:TEMP)\$File"

   Copy-Item -Path "$($env:TEMP)\$File" -Destination "$Location$File" -Force
   
}


##############################
#           Random           #
##############################

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
            "All Day Event : {0} Organized by {1}" -f $appt.Subject, $appt.Organizer
         }
         Else {
            "{0:ddd hh:mmtt} - {1:hh:mmtt} : {2} Organized by {3}" -f [DateTime]$appt.Start, [DateTime]$appt.End, $appt.Subject, $appt.Organizer
         }

      }

      $outlook = $session = $null;
   }
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

##############################
#           Export           #
##############################
Export-ModuleMember -Alias * -Function *
