<#

   .SYNOPSIS
   This script is used to download the ENF zip(s) for an ENF and zip them together.

   .DESCRIPTION
   This is a download program to help download multiple ENF zips.
   A folder with the GUID as its name will be created and the zips will be downloaded into that folder.
      It will download from A7Prod, A7QA, or DailyBuilds depending on what you pass in.

   .NOTES
   By Default, this program uses `"C:\ENF`" for its download directory.
      Tohange this, add `"$ENFDir = 'C:\xxxx\xxxx'`" (sans the double quotes) in your Powershell Profile.

   .INPUTS
   The GUID for the ENF can be piped into this script instead of using the `"-Enf`" parameter.

   .OUTPUTS
   This file downloads the zip files for the ENF occurrences.

   .PARAMETER Enf
   This is the Triage guid used to identify the ENF. Encompass the GUID in quotes.
   This parameter is validated to ensure that it is a valid GUID value.

   .PARAMETER Env
   THis is the environment where the ENF exists is from. It correlates to the Database tables.
   The valid parameters are 'A7Prod', 'A7QA', and 'DailyBuilds'.

   .PARAMETER Number
   This is the number of occurrence zips that you want to download.
   Only the ENFs that were created within the last thirty days will be downloaded.

   .PARAMETER Zip
   This will zip all the downloaded zips into one zip with the name being the ENF GUID.

   .PARAMETER Delete
   This will delete all of the occurrence zips that were downloaded.

   .PARAMETER ZD
   This is shorthand for `"-Zip -Delete`".
   It will zip all the files into one zip, then delete all the occurrence files.

   .PARAMETER All
   This is shorthand for setting the `"-Number`" parameter to 1000. 
   Basically is used when there is a massive amount of ENFs created and you want to grab them all.

   .PARAMETER DD
   This will skip the downloading section of the code.
   This is useful if you just ran the script, but forgot to zip the files.

   .PARAMETER Asc
   This will set the query to start at the beginning of the list of ENFs instead of the most recent.

#>
Param(
      [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
      [ValidateScript({
         try {
            [System.Guid]::Parse($_) | Out-Null
            $true
         } catch {
            $false
         }
      })]
      [System.Guid]$Enf,
      [Parameter(Mandatory=$false,Position=1)]
      [ValidateSet("A7Prod","A7Prod","DailyBuilds")]
      [string]$Env   = "A7Prod",
      [Parameter(Mandatory=$false,Position=2)]
      [ValidateRange(1, 1000)]
      [int]$Number   = 10,
      [Parameter(Mandatory=$false)]
      [switch]$Zip   = $false,
      [Parameter(Mandatory=$false)]
      [switch]$ZD    = $false,
      [Parameter(Mandatory=$false)]
      [switch]$Delete   = $false,
      [Parameter(Mandatory=$false)]
      [switch]$All   = $false,
      [Parameter(Mandatory=$false)]
      [switch]$dd    = $false,
      [Parameter(Mandatory=$false)]
      [switch]$asc   = $false
     )

Process {

   ## Get the Environment Info
   $sqlServer, $sqlDbName, $envPrint, $zipDir = Get-EnvInfo $Env
   $destPath = "$zipDir\$Enf"

   ## If we are actually downloading the zip files
   If (-not $dd) {

      If ($All) {
         $Number = 1000
      }

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Getting ENF Zips" -Status "Getting list of zips from the Database"
      }

      ## Go perform the SQL query to get the list of ENF zip locations
      $dataSet = Get-DBZip $Enf $sqlServer $sqlDbName $Number $asc

      ## If we have zero zips for the ENF. (Possible if nothing has occurred in the last thirty days.
      If ($dataSet.Tables[0].Rows.Count -eq 0) {

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Getting ENF Zips" -Completed -Status "No Zips to Download"
         }

         Write-Output "No rows for ENF $Enf in ENV $envPrint were found."
         Exit

      } Else {

         ## Go create the new directory.
         New-Item -Itemtype Directory -Path $destPath -ErrorAction SilentlyContinue
         
         ## Set up the progress variables
         $percent  = 1
         $rowCount = $dataSet.Tables[0].Rows.Count

         ## Go through the set of ENF zip locations.
         $dataSet.Tables[0].Rows | ForEach-Object {

            If (-not (Get-VerboseStatus)) {
               Write-Progress -Activity "Getting ENF Zips" -Status "Downloading $($_.Item(0).Split(@{$true="\";$false="/"}[$_.Item(0).StartsWith("\\")])[-1]) to $destPath" -PercentComplete (($percent++ / $rowCount) * 100)
            }

            ## Go get the zip file and download it.
            Get-Zip $_['AlertZipFilePath'] $destPath
         }

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Getting ENF Zips" -Status "Done Downloading ENF Zips" -PercentComplete (100)
         }
      }

   }

}

End {

   ## If we are zipping the files together
   If ($Zip -or $ZD) {

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Getting ENF Zips" -Status "Zipping files into one zip"
      }

      ## Zip the files together into one zip
      Get-FinalZip $destPath $Enf
   }

   ## If we are deleting the occurrence zip files
   If ($ZD -or $Delete) {

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Getting ENF Zips" -Status "Deleting Occurrence Zips"
      }

      ## Delete the occurrence zip files
      Remove-OccurrenceZip $destPath $Enf $true
   }


   ## All Done
   If (-not (Get-VerboseStatus)) {
      Write-Progress -Activity "Getting ENF Zips" -Completed -Status "All Done"
   }

}

Begin {

   Function Get-VerboseStatus {

      ## Check to see if the Verbose flag has been set
      Return @{$true=$true;$false=$false}[$VerbosePreference -eq 'Continue']

   }

   Function Add-Zip {
      Param(
            [String]$zipfilename
           )

      ## List of files to zip together. Using system variable.
      $files = $input

      ## If the zip file does not already exist
      If (-not (Test-Path($zipfilename)))
      {
         ## Create the zip file
         Set-Content $zipfilename ("PK" + [Char]5 + [Char]6 + ("$([Char]0)" * 18))
         (Get-ChildItem $zipfilename).IsReadOnly = $false	
      }

      $shellApplication = new-object -com shell.application
      $zipPackage = $shellApplication.NameSpace($zipfilename)

      Foreach($file in $files) 
      { 
         ## Zip the files together
         $zipPackage.CopyHere($file.FullName)
         While (($zipPackage.Items() | Where-Object { $_.Name -like $file }).Size -lt 1) { Start-Sleep -m 100 };
      }
   }

   Function Get-EnvInfo {
      Param(
            [Parameter(Mandatory=$true,Position=0)]
            [ValidateSet("A7Prod","A7QA","DailyBuilds")]
            [String]$Env
           )

      Begin {

         ## Set up the variables
         $sqlDbName = ""
         $sqlServer = "HFDWPSQLV4\DAILYBUILDS02"
         $envPrint  = ""
         $zipFilePath = ""
         If ($ENFDir) {
            ## If the ENF directory is set up in the profile, use that.
            $zipFilePath = "$ENFDir\Zips"
         } Else {
            ## Else, default.
            $zipFilePath = "C:\ENF\Zips"
         }
      }

      Process {

         ## Figure out what database to use.
         Switch ($Env.ToLower()) {
            "a7prod"         { $sqlDbName = "Production_Alerts_A7" 
                               $envPrint  = "Allstate Production" }
            "a7qa"           { $sqlDbName = "Production_Alerts_A7_PreProd" 
                               $envPrint  = "Allstate QA" }
            "dailybuilds"    { $sqlDbName = "DailyBuild_Alerts_Test" 
                               $envPrint  = "Daily Builds" }
         }

      }

      End {

         Write-Verbose "SQLServer: $sqlServer - SQLTable: $sqlDbName`n"
         Write-Verbose "ENF Zip Directory: $zipFilePath`n"

         Return $sqlServer, $sqlDbName, $envPrint, $zipFilePath

      }
   }

   Function Get-Zip {
      Param(
            [Parameter(Mandatory=$true,Position=0)]
            [String]$Zip,
            [Parameter(Mandatory=$true,Position=1)]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            [String]$DestPath
           )

      Begin {
         ## Figure out if we are dealing with an FTP site or a network share
         $fileName  = $Zip.Split(@{$true="\";$false="/"}[$Zip.StartsWith("\\")])[-1]
         If (-not $Zip.StartsWith("\\")) {
            ## We are using an FTP site
            ## Open the web client
            $WebClient = New-Object System.Net.WebClient
         }
      }

      Process {
         Write-Verbose "Saving $DestPath\$fileName`n"

         If ($Zip.StartsWith("\\")) {
            ## We are using a network share
            ## Copy the file
            Copy-Item -Path $Zip -Destination "$DestPath\$fileName" -ErrorAction SilentlyContinue
         } Else {
            ## We are using an FTP site
            ## Download the file
            $WebClient.DownloadFile($Zip, "$DestPath\$fileName")
         }
      }

      End {
         If ([Boolean]$WebClient) {
            ## Close the web client if we used it.
            $WebClient.Dispose()
         }
      }

   }

   Function Get-DBZip {
      Param(
            [Parameter(Mandatory=$true,Position=0)]
            [ValidateScript({
               Try {
                  [GUID]::Parse($_) | Out-Null
                  $true
               } Catch { $false }})]
            [GUID]$Enf,
            [Parameter(Mandatory=$true,Position=1)]
            [String]$SqlServer,
            [Parameter(Mandatory=$true,Position=2)]
            [String]$SqlDbName,
            [Parameter(Mandatory=$false,Position=3)]
            #[ValidationRange(1,1000)]
            [Int]$Number = 10,
            [Parameter(Mandatory=$false,Position=4)]
            [Boolean]$Asc = $false
           )

      Begin {
         ## What order are we using?
         $order = @{$true="ASC";$false="DESC"}[$asc -eq $true]

         ## Set up the query that we are using. 
         ## Not using parameterized query since the only entered values have been verified
         $sqlQuery = @"
            SELECT DISTINCT TOP($Number) [DA].[AlertZipFilePath], [DA].[CreatedDateTime] 
            FROM [Distinct_Alerts] AS DA 
            WHERE [DA].[StackTrace] = 
            (SELECT [UA].[StackTrace] FROM [Unique_Alerts] AS UA WHERE [UA].[GUID] = '$Enf') 
            AND [DA].[CreatedDateTime] > DATEADD(day, -30, GETDATE()) 
            ORDER BY [DA].[CreatedDateTime] $order 
"@
         Write-Verbose "SQL query:`n$sqlQuery`n"

         $dataSet = New-Object System.Data.DataSet
      }

      Process {

         ## Go get them zip file paths
         $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
         $SqlConnection.ConnectionString = "Server = $SqlServer; Database = $SqlDbName; User ID = alerts; Password = alerts"
         
         $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
         $SqlCmd.CommandText = $sqlQuery
         $SqlCmd.Connection = $SqlConnection

         $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
         $SqlAdapter.SelectCommand = $SqlCmd

         $SqlAdapter.fill($dataSet) | Out-Null

         $SqlConnection.Close()
      }

      End {
         Return $dataSet
      }

   }

   Function Get-FinalZip {
      Param(
            [Parameter(Mandatory=$true,Position=0)]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            [String]$DestPath,
            [Parameter(Mandatory=$true,Position=1)]
            [ValidateScript({
               Try {
                  [GUID]::Parse($_) | Out-Null
                  $true
               } Catch { $false }})]
            [GUID]$Enf
           )
         
      ## If the zip already exists, delete it.
      Write-Verbose "Deleting $DestPath\$Enf.zip`n"
      Remove-Item -ErrorAction SilentlyContinue "$DestPath\$Enf.zip"

      ## Add the occurrence zip files to the final zip.
      Write-Verbose "Creating $DestPath\$Enf.zip`n"
      Get-ChildItem -Path $DestPath | Where-Object {$_.Extension -eq ".zip" -and $_.Name -ne "$Enf.zip"} | Add-Zip "$DestPath\$Enf.zip"
   }

   Function Remove-OccurrenceZip {
      [CmdletBinding(
            SupportsShouldProcess=$true,
            ConfirmImpact="Medium"
            )]
      Param(
            [Parameter(Mandatory=$true,Position=0)]
            [ValidateScript({Test-Path $_ -PathType 'Container'})]
            [String]$DestPath,
            [Parameter(Mandatory=$true,Position=1)]
            [ValidateScript({
               Try {
                  [GUID]::Parse($_) | Out-Null
                  $true
               } Catch { $false }})]
            [GUID]$Enf,
            [Parameter(Mandatory=$false,Position=2)]
            [Bool]$Force = $false
           )

      ## Remove the occurrence zip files.
      If ($pscmdlet.ShouldProcess("Occurrence Zips") -or $Force) {
         Write-Verbose "Deleting Occurrence Zips.`n"
         Get-ChildItem -Path $DestPath | Where-Object {$_.Name -ne "$Enf.zip"} | Remove-Item -ErrorAction SilentlyContinue
      }
   }


}

# SIG # Begin signature block
# MIIEPAYJKoZIhvcNAQcCoIIELTCCBCkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUW9ZhfJSpdfPHSlNjzSV5SyEh
# uTygggJDMIICPzCCAaygAwIBAgIQK1hHgwMalLpMVaX08TbQfTAJBgUrDgMCHQUA
# MC8xLTArBgNVBAMTJFBvd2VyU2hlbGwgVGltaW5zS3kgQ2VydGlmaWNhdGUgUm9v
# dDAeFw0xNjA0MTMxNDE5MzhaFw0zOTEyMzEyMzU5NTlaMBoxGDAWBgNVBAMTD1Bv
# d2VyU2hlbGwgVXNlcjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA1Dkfvmov
# RWlJfXoP29kHHk2qBxjgEM8A1TWSY53I11//68SH45cco44x/J4One6RYWTQC0sP
# Jt7PRuQ/7I4HppZluQzm2wjrQJd4O90g34axFab8Oda6OK7vrE32zNx1mTrvu0X6
# jW/PRZxRwBpqL3hu4SKcdJ8jIezuSH6bWh8CAwEAAaN5MHcwEwYDVR0lBAwwCgYI
# KwYBBQUHAwMwYAYDVR0BBFkwV4AQ6m29+1j46w+9skYwpaVEv6ExMC8xLTArBgNV
# BAMTJFBvd2VyU2hlbGwgVGltaW5zS3kgQ2VydGlmaWNhdGUgUm9vdIIQO3bxBMKU
# mKJMq/zllKj6nzAJBgUrDgMCHQUAA4GBAC46jzN/gr/wluYW1YGdz7+/XFJCexsP
# m3HLF5wPxTjIaDBWT0rQznAFqbB9ekxSELgUpOfWiVAwJ/G+WAQTG/QADt0C+s7a
# mlIsNyRCpiDKFGGQpfii6t5tnaBLJTYyw88t7sD0Fsbmg5VwUqZ1yYLziB33DV1K
# +OYDxM3OLMHMMYIBYzCCAV8CAQEwQzAvMS0wKwYDVQQDEyRQb3dlclNoZWxsIFRp
# bWluc0t5IENlcnRpZmljYXRlIFJvb3QCECtYR4MDGpS6TFWl9PE20H0wCQYFKw4D
# AhoFAKB4MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwG
# CisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZI
# hvcNAQkEMRYEFCCa/T7XZ+u+Eu7c75mBMLMTxzVwMA0GCSqGSIb3DQEBAQUABIGA
# TwExYl77Cdgpz5D/rua/6sBqAA7b67Wmbbcogm02bBo2jC8hEtbZ5tho2OCfaVSe
# 5e3NUgO1Rc+c9WXgd285cNZBXN5cWSlorCmFe+PU5ADwiXyYBJ3CMzDq4pzBMWHO
# U1yEXDv+aipNmtkdcvfM0aPh4fUOo+1IWAbQ4mRTb44=
# SIG # End signature block
