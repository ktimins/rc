###############################################
# Get-ENFZip.ps1
# A powershell tool to download multiple zip files from an ENF
# Created by Kyle Timins
# #############################################

<#

   .SYNOPSIS
   This script is used to download the ENF zip(s) for an ENF and zip them together.

   .DESCRIPTION

   This is a download program to help download multiple ENF zips.
   A folder with the GUID as it's name will be created and the zips will be downloaded into that folder.
    It will download from A7 Prod, PreProd, or Test depending on what you pass in."

   .NOTES
   By Default, this program uses `"C:\ENF`" for its download directory.
    To change this, Add `"$ENFDir = 'C:\xxxx\xxxx'`" (sans double quotes) in your Powershell Profile.

   This script can use standard Powershell 2 for download and ziping or use wget (downloads) and 7zip (zipping).
    Wget for Windows can be downloaded at: http://gnuwin32.sourceforge.net/packages/wget.htm
     Download the Complete package and install normally.
    7zip can be installed via LanDesk Portal Manager.

   .PARAMETER enf
   This is the Triage GUID used to identify the ENF. Encompass the GUID in quotes. 
   This is a mandatory parameter.  
   This parameter is validated to ensure that it is a valid GUID.
   This parameter can be passed in via a pipe on Powershell

   .PARAMETER env
   This is the environment where the ENF exists from. It correlates to the Database tables.
   The valid parameters are "prod", "preprod", "test", and "dailyBuild".

   .PARAMETER num
   This is the number of occurrence zips you want to download.
   Only the ENFs taht were created within the last 30 days will be downloaded.

   .PARAMETER all
   This is a shortcut to set num to 1000. This should download all of the available zips.

   .PARAMETER zip
   This will zip all the downloaded zips into one zip with the name being the GUID.
   This is usefull when adding zips to a CSR or emailing.

   .PARAMETER zd
   This is a combination of "-zip" and "del".

   .PARAMETER del
   This will delete all of occurrence zips downloaded.

   .PARAMETER dd
   Do not download anything. 
   This is useful if you just ran the script, but forgot to zip the files.

   .PARAMETER asc
   User this switch if you want to get the first zips instead of the latest.

   .INPUTS
   The GUID for the ENF can be piped into this script instead of using the "-enf 'XX'" parameter.

#>

Param(
      [Parameter(Mandatory=$true,ValueFromPipeline,Position=0)]
      [ValidateScript({
         try {
            [System.Guid]::Parse($_) | Out-Null
            $true
         } catch {
            $false
         }
      })]
      [System.Guid]$enf,
      [ValidateScript({
         If ($_ -gt 0) { $true } else { $false }
      })] 
      [Parameter(Mandatory=$false,Position=1)]
      [Int]$num      = 10,
      [Parameter(Mandatory=$false,Position=2)]
      [ValidateSet("prod","preprod","test","dailybuild")]
      [String]$env   = "prod",
      [Parameter(Mandatory=$false,Position=3)]
      [String]$ENFDir = "C:\Users\TiminsKY\Documents\ENF",
      [Switch]$zip   = $false,
      [Switch]$zd    = $false,
      [Switch]$del   = $false,
      [Switch]$all   = $false,
      [Switch]$dd    = $false,
      [Switch]$asc   = $false
     )


Process {
   $filePath = "$ENFDir\Zips\$enf"

   if (-not $dd) {

      switch ($env.ToLower()) {
         "prod"         { $SQLDBName = "Production_Alerts_A7" 
            $envPrint  = "Prod" }
         "preprod"      { $SQLDBName = "Production_Alerts_A7_PreProd" 
            $envPrint  = "PreProd / QA2"}
         "test"         { $SQLDBName = "Production_Alerts_A7_Test" 
            $envPrint  = "Test / QA1" }
         "dailybuild"   { $SQLDBName = "DailyBuild_Alerts_Test" 
            $envPrint  = "Daily Builds" }
      }

      Write-Progress -Activity "Getting ENF Zips" -Status "Getting list of zips from the Database"

      if ($all) { $num = 1000 }

      $order = @{$true="asc";$false="desc"}[$asc -eq $true]

      $SQLServer = "HFDWPSQLV4\DAILYBUILDS02"

      $SqlQuery  = "select top($num) AlertZipFilePath " +
      "from Distinct_Alerts " +
      "where StackTrace = (Select StackTrace from Unique_Alerts where GUID = '$enf') " +
      "and CreatedDateTime > dateadd(day, -30, getdate()) " +
      "Order By CreatedDateTime $order"

      $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
      $SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"

      $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
      $SqlCmd.CommandText = $SqlQuery
      $SqlCmd.Connection = $SqlConnection

      $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
      $SqlAdapter.SelectCommand = $sqlCmd

      $dataSet = New-Object System.Data.DataSet
      $SqlAdapter.Fill($dataSet) | Out-Null

      $SqlConnection.Close()

      if ($dataSet.Tables[0].Rows.Count -eq 0) {
         Write-Output "No rows for ENF $enf in ENV $env were found."
         Exit
      } else {
         mkdir $filePath -ErrorAction SilentlyContinue
         $i = 1
         $c = $dataSet.Tables[0].Rows.Count
         $WebClient = New-Object System.Net.WebClient
         Foreach ($row in $dataSet.Tables[0].Rows) {
            $zipName = $row.Item(0)
            $splitChar =  @{$true="\";$false="/"}[$zipName.StartsWith("\\")]
            $fileName = $zipName.Split($splitChar)[-1]
            Write-Progress -Activity "Getting ENF Zips" -Status "Downloading $filename to $filePath" -PercentComplete (($i++ / $c) * 100)
            if ($zipName.StartsWith("\\")) {
               cp -Path $zipName -Destination "$filePath\$filename" -ErrorAction SilentlyContinue
            } else {
               $WebClient.DownloadFile($zipName, "$filePath\$filename")
            }
         }
         $WebClient.Dispose()
      }

   }
}

End {
   
   $filePath = "$ENFDir\Zips\$enf"

   if ($zip -or $zd) {

      Write-Progress -Activity "Getting ENF Zips" -Status "Zipping files into one zip"

      $zipFile = "$enf.zip"

      rm -ErrorAction SilentlyContinue "$filePath\$enf.zip"

      Get-ChildItem -Path $filePath | Where-Object {$_.Name -ne $zipFile } | Add-Zip "$filePath\$enf.zip"

   }

   if ($zd -or $del) {                

      Write-Progress -Activity "Getting ENF Zips" -Status "Deleting occurrence zips."
      $files = Get-ChildItem -Path $filePath | Where-Object {$_.Name -ne "$ENF.zip"}
      $files | rm -ErrorAction SilentlyContinue

   }

   Write-Progress -Activity "Getting ENF Zips" -Completed -Status "All Done"
}

Begin {
   Function Add-Zip {
      Param(
            [String]$zipfilename
           )

      $files = $input
      $i = 0
      $c = $files.Length

      if(-not (test-path($zipfilename)))
      {
         set-content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
         (dir $zipfilename).IsReadOnly = $false	
      }

      $shellApplication = new-object -com shell.application
      $zipPackage = $shellApplication.NameSpace($zipfilename)

      foreach($file in $files) 
      { 
         Write-Progress -Activity "Getting ENF Zips" -Status "Adding $file to $zipfilename" -PercentComplete (($i++ / $c) * 100)
         $zipPackage.CopyHere($file.FullName)
         While (($zipPackage.Items() | Where-Object { $_.Name -like $file }).Size -lt 1) { Start-Sleep -m 100 };
      }
   }
}
