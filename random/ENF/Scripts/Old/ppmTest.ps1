Param(
      [string]$csv,
      [string]$csr,
      [switch]$visable = $false,
      [string]$output = 'output.csv'
     );


$CSRs = @()
if ($csv) {
   $CSRsObj = Import-Csv $csv
   foreach($r in $CSRsObj) {
      $CSRs += $r.CSR
   }
   $CSRs = $CSRs | select -Unique
} elseif ($csr) {
   $CSRs += convertfrom-stringdata -stringdata "CSR = $csr"
} else {
   $csr = Read-Host -Prompt 'Input CSR Number'
   $CSRs += convertfrom-stringdata -stringdata "CSR = $csr"
}

Write-Progress -Activity "Getting Status of CSRs" -status "Accessing PPM" `
   -PercentComplete (0 / $CSRs.Count*100)


$CSRURL = "https://portal.insurity.com/itg/web/knta/crt/RequestDetail.jsp?REQUEST_ID="
$DashURL = "https://portal.insurity.com/itg/dashboard/app/portal/PageView.jsp"

$ie = New-Object -com InternetExplorer.Application
$ie.visible = if($visable) {$true} else {$false}
$ie.navigate2($DashURL);

while($ie.ReadyState -ne 4) {start-sleep -m 100}

$doc = $ie.Document

if ($doc.title -eq "PPM Logon" ) {
   $password = Read-Host -Prompt 'Input your password' -asSecureString
   $doc.getElementById("field-username").Value= $env:USERNAME
   $doc.getElementById("field-password").Value = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
   $checkbox = $doc.getElementById("field-rememberme")
   $checkbox.checked = $true
   $doc.getElementById("label-LOGON_SUBMIT_BUTTON_CAPTION").Click()
}


while($ie.ReadyState -ne 4) {start-sleep -m 100}


$aStatus = @()
$aCSR = @()
$csrHeaders = @("CSR","Status")
$csrStatus = @()
$csvStatus = New-Object PSObject
#$csvStatus | Add-Member -type NoteProperty -name "CSV" -Value "Status"
$i = 0
foreach ($csr in $CSRs) {

   Write-Progress -Activity "Getting Status of CSRs" -status "Finding Status of $csr" `
      -PercentComplete ($i++ / $CSRs.Count*100)

   $ie.navigate2($CSRURL + $csr)

   while($ie.ReadyState -ne 4) {start-sleep -m 100}

   $doc = $ie.Document

   $status = $doc.GetELementById("requestStatus").InnerText

   $statusStripped = $status.Trim().Substring(9)

   $csrStatus += , @("$csr","$statusStripped")

   $statusStr = """CSR#$csr"",""$status"""
   $statusStr | Write-Host
   $aCSR += $csr
   $aStatus += $statusStripped
}
Write-Progress -Activity "Writing CSV file" -status "Writing CSV file" `
   -PercentComplete ($i / $CSRs.Count*100)

$holdarr = @()
foreach ($row in $csrStatus){
    $obj = new-object PSObject
    for ($i=0;$i -lt $csrHeaders.Count; $i++){
              $obj | add-member -membertype NoteProperty -name $csrHeaders[$i] -value $row[$i]
      }
   $holdarr+=$obj
   $obj=$null
}



$holdarr | Export-CSV -Path $output -NoTypeInformation

$x = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Progress -Activity "Writing CSV file" -completed
$ie.Quit()
