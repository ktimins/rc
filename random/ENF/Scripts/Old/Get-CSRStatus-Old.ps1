<# 

.SYNOPSIS
This is a script that will check the status of a CSR and get the resolution date/SP if the CSR is closed.

.DESCRIPTION
This is a script to check the status of a CSR. If the CSR has been closed, the Resolution Date and Resolution SP will be grabbed as well.
A CSR can be passed in to check one or a CSV file can be passed in to check all of the CSRs on the CSV.

If you are not currently logged into PPM via a cookie, you will be prompted for your passed. 
This is because PPM redirected the script to the login page.
NOTE: Your username is auto generated using the username of the current user on Windows.

This script goes to the PPM page for each CSR and strips that data that is needed. 

Then, the values can be outputted to CSV file and/or outputed to the Powershell Console.
If outputted to a CSV file, the file should be different than the input CSV as all rows will be overwritten.

As well, this function can clear IE's "Temporary Internet Files" and "Cache". This is useful if PPM throws an error.

.NOTES
This script is using InternetExplorer.Application, which means it is useable with Powershell v2, but is slow.
It takes about three seconds per CSR since it loads the actual PPM page in IE to grab the information.

In the future, I will be creating a Powershell v3 version using Invoke-WebRequest or directly link into PPM via an API.
As well, I plan to inplement a PSCredentials stored to an encrypted file so that you only need to enter your password once until your change it.

.PARAMETER csr
If using a single CSR is being looked up, the value is passed in via this parameter. 

NOTE: This cannot be combined with -csvIn.

.PARAMETER csvIn
If checking the value of multiple CSRs, a CSV file can be passed in instead.
The CSV should have a header of "CSR" with all other lines containing a single CSR value. All other columns are ignored.

NOTE: This cannot be combined with -csr.

.PARAMETER csvOut
If saving the values to a CSV file, a CSV file name must be provided.

NOTE: If you enter the name of an existing file, the file will be overwritten by this script.
      Please make sure you do not have the file open in any application (eg. Excel) when running this script.

.PARAMETER out
If you would like to view the information collected without saving to a file, this parameter will output the grabbed values to a list.

.PARAMETER outf
If you would like to view the information collected without saving to a file, this parameter will output the grabbed values to a table.

.PARAMETER filter
If you pass in a CSV file, but don't want any repeat CSRs in the output, pass this flag.

.PARAMETER noProg
If you don't want the Progress bar to appear, pass this flag.

.PARAMETER visible
If you want the IE window to be visible instead of hidden, pass this flag.

.PARAMETER clear
If you want to clear your "Temporary Internet Files" and "Cache" for IE, pass this flag.
NOTE: Be very wary of this as this will delete all Temp Internet Files and Cache for IE. Can become annoying after done.

#>

#Requires -Version 2

Param(
      [Parameter(Mandatory=$true,ParameterSetName="CSR",Position=0)]
      [ValidatePattern("^\d{7}$")]
      [string]$csr,
      [Parameter(Mandatory=$true,ParameterSetName="CSV",Position=0)]
      [ValidateScript({
         If (Test-Path $_){$true}else{Throw "`nInvalid CSV input path given: $_"}
         })]
      [string]$csvIn,
      [Parameter(Mandatory=$false,ParameterSetName="CSR")]
      [Parameter(Mandatory=$false,ParameterSetName="CSV")]
      [string]$csvOut,
      [Parameter(Mandatory=$false,ParameterSetName="CSR")]
      [Parameter(Mandatory=$false,ParameterSetName="CSV")]
      [switch]$out = $false,
      [Parameter(Mandatory=$false,ParameterSetName="CSR")]
      [Parameter(Mandatory=$false,ParameterSetName="CSV")]
      [switch]$outf = $false,
      [Parameter(Mandatory=$false,ParameterSetName="CSV")]
      [switch]$filter = $false,
      [switch]$noProg = $false,
      [switch]$times = $false,
      [switch]$visible = $false,
      [string]$passwd = $false,
      [Parameter(Mandatory=$false,ParameterSetName="Clear")]
      [switch]$clear = $false
     );

Function Clear-IE {
   $t_path_7 = "C:\Users\$env:username\AppData\Local\Microsoft\Windows\Temporary Internet Files"
   $c_path_7 = "C:\Users\$env:username\AppData\Local\Microsoft\Windows\Caches"

   $temporary_path =  Test-Path $t_path_7
   $check_cashe =    Test-Path $c_path_7

   {
      Write-Host "Clean Temporary internet files"
      RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 8
      (Remove-Item $t_path_7\* -Force -Recurse) 2> $null
      RunDll32.exe InetCpl.cpl,ClearMyTracksByProcess 2

      Write-Host "Clean Cashe"
      (Remove-Item $c_path_7\* -Force -Recurse) 2> $null

      Write-Host "Done"
   }
}

Function Create-PasswordFile {
   Param(
         [Security.SecureString]$Password
        )

   $Password | ConvertFrom-SecureString

}

if ($clear) {
   Clear-IE
   exit
}

if ($times) { Get-Date -format "HH:mm:ss.fff" | % { Write-Host "$_ - Start" } }

$CSRs = @();

switch ($PSCmdLet.ParameterSetName) {
   "CSV"       { $CSRsObj = Import-Csv $csvIn
                 foreach($r in $CSRsObj) {
                 $CSRs += $r.CSR
                 }
                 if ($filter) { $CSRs = $CSRs | select -Unique } }
   "CSR"       { $CSRs += $csr }
   Default     { $csr = Read-Host -Prompt 'Input CSR Number'
                 if ($csr -match "^\d{7}$") { $CSRs += $csr }
                 else { Throw "$csr is not a valid CSR number" } }
}


$i = 0
if (-not $noProg) {Write-Progress -Activity "Getting Status of CSRs" -status "Accessing PPM" -PercentComplete ($i / $CSRs.Count*100) }


$CSRURL = "https://portal.insurity.com/itg/web/knta/crt/RequestDetail.jsp?REQUEST_ID="
$DashURL = "https://portal.insurity.com/itg/dashboard/app/portal/PageView.jsp"

$ie = New-Object -com InternetExplorer.Application
$ie.visible = if($visible) {$true} else {$false}

Do {
   $ie.navigate2($DashURL);

   while($ie.ReadyState -ne 4) {start-sleep -m 100}
   Start-Sleep -m 750

   if ($times) { Get-Date -format "HH:mm:ss.fff" | % { Write-Host "$_ - After PPM start" } }


   if ($ie.Document.title -eq "PPM Logon" ) {
      $password = Read-Host -Prompt 'Input your password' -asSecureString
      $ie.Document.getElementById("field-username").Value= "$env:USERNAME"
      $ie.Document.getElementById("field-password").Value = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
      $checkbox = $ie.Document.getElementById("field-rememberme")
      $checkbox.checked = $true
      $ie.Document.getElementById("label-LOGON_SUBMIT_BUTTON_CAPTION").Click()

      while($ie.ReadyState -ne 4) {start-sleep -m 100}
      Start-Sleep -m 750

   }

   if ($times) { Get-Date -format "HH:mm:ss.fff" | % { Write-Host "$_ - After Login" } }

   $doc = $ie.Document

} Until ($ie.Document.title -eq "Dashboard - My stuff")

if (-not $noProg) {Write-Progress -Activity "Getting Status of CSRs" -status "Accessing PPM" -PercentComplete ($i / $CSRs.Count*100) }

$csrHeaders = @("CSR","Status","Resolution Release","Resolution Date");
$csrStatus = @();
$distinctCSRs = @{};
foreach ($csrVal in $CSRs) {

   if (-not $noProg) {Write-Progress -Activity "Getting Status of CSRs" -status "Finding Status of $csrVal" -PercentComplete ($i++ / $CSRs.Count*100) -SecondsRemaining ((($CSRs.Count - $i) * 3) + 3) }

   if ($distinctCSRs.ContainsKey($csrVal)) {

      $csrStatus += , @($csrVal, $distinctCSRs.Get_Item($csrVal)[0],$distinctCSRs.Get_Item($csrVal)[1],$distinctCSRs.Get_Item($csrVal)[2])
      continue
   }


   if ($times) { Get-Date -format "HH:mm:ss.fff" | % { Write-Host "$_ - CSR $csrVal" } }

   $ie.navigate2($CSRURL + $csrVal)

   while($ie.ReadyState -ne 4) {start-sleep -m 100}

   $doc = $ie.Document

   $status = $doc.GetElementById("requestStatus").InnerText.Trim().Substring(9)

   $ResSP = "Open"
   $ResDateStr = " "

   $ResRelease = $doc.GetElementById("DRIVEN_P_43")

   If ($ResRelease.InnerText -ne $null) {

      $ResSP = $ResRelease.InnerText.Trim()

      $ResDate = $doc.GetElementById("DRIVEN_P_31")
      if ($ResDate.InnerText -ne $null) {
         $ResDate = $ResDate.InnerText.Trim()
         $ResDate = $ResDate.Substring(0,$ResDate.Length - 4)
         Try {
            if ($ResDate -as [DateTime] -ne $null) {
               $ResDateTime = [datetime]::ParseExact($ResDate, "MMMM dd, yyyy h:mm:ss tt", $null)
               $ResDateStr = Get-date $ResDateTime -format "yyyy-MM-dd HH:mm:ss"
            }
         } Catch { }
      }
   }

   $csrStatus += , @($csrVal,$status,$ResSP,$ResDateStr)

   if (-not $distinctCSRs.ContainsKey($csrVal)) {
      $distinctCSRs.Add($csrVal, @($status, $ResSP, $ResDateStr))
   }

}

if ($times) { Get-Date -format "HH:mm:ss.fff" | % { Write-Host "$_ - After CSRs" } }

if (-not $noProg) {Write-Progress -Activity "Writing CSV file" -status "Writing CSV file" -PercentComplete ($i / $CSRs.Count*100) -SecondsRemaining (3)}

$holdarr = @();
foreach ($row in $csrStatus){
   $obj = new-object PSObject
   for ($i=0;$i -lt $csrHeaders.Count; $i++){
      $obj | add-member -membertype NoteProperty -name $csrHeaders[$i] -value $row[$i]
   }
   $holdarr+=$obj
   $obj=$null
}

if ($csvOut) {
   $holdarr | Export-CSV -Path $csvOut -NoTypeInformation
}

If ($out) {
   $holdarr | Format-List
} ElseIf ($outf) {
   $holdarr | Format-Table
}


if (-not $noProg) {Write-Progress -Activity "Writing CSV file" -completed }

if ($times) { Get-Date -format "HH:mm:ss.fff" | % { Write-Host "$_ - End" } }

$ie.Quit()
