<#

.SYNOPSIS
Check the counts of ENFs based upon the GUID of the ENF.

.DESCRIPTION
This script is used to check the counts of ENFs based upon the execption message of the ENF.
Currently, this script can go against A7 Prod, A7 Test, A7 PreProd, and DailyBuilds.
A date range can be specified as to limit the amount of time to check against.
The output datetime stamps can be controlled to state how specific you want each row to be.
The output can be pushed the clipboard with built-in functonality.

Predefined sets of exception messages can be checked against. To view the sets and their exception messages, use "-list" flag.

.NOTES
The script must be modified to include new exception messages.

.PARAMETER env
This is used to set the environment to go against. The list of environments are:
A7 Prod        =  "prod"
A7 Test        =  "test"
A7 PreProd     =  "preprod"
DailyBuilds    =  "dailybuild"

NOTE: "test" is the same as "preprod" as both look at the same table in the ENF DB.

.PARAMETER days
This is used to define how many days back you want to look at. 
It allows a range of 0 (today only) to 365.
By default, only today is looked at.

It cannot be used in combination with "-date".

.PARAMETER level
This is used to state the level of precision the datetime stamp on the output should be.
By default, it is set to hours. The valid inputs are:
"m"   = Months
"d"   = Days
"h"   = Hours
"n"   = Minutes
"s"   = Seconds

.PARAMETER asc
This flag is used to format the output in ascending date order.
By default, the output is in decending date order.

.PARAMETER guid
This is the ENF GUID to look up.

.PARAMETER v
This flag is used in conjunction with "-guid" to paste the whole exception message instead of it being truncated.

.PARAMETER copy
This flag is used to copy the output to the clipboard.

#>

#Requires -Version 2

Function Get-GUIDCount {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=1)]
         [ValidateScript({
            try {
            [System.Guid]::Parse($_) | Out-Null
            $true
            } catch {
            $false
            }
            })]
         [System.GUID]$guid,
         [ValidateSet("prod","preprod","test","dailybuild")]
         [string]$env      = "prod",
         [ValidateRange(0, 365)]
         [int]$days        = 0,
         [Parameter(Mandatory=$false)]
         [ValidateSet("m","d","h","n","s")]
         [string]$level    = "h",
         [Parameter(Mandatory=$false)]
         [switch]$asc      = $false,
         [Parameter(Mandatory=$false)]
         [switch]$v        = $false,
         [Parameter(Mandatory=$false)]
         [switch]$copy     = $false
         )


         switch ($env.ToLower()) {
            "prod"         { $SQLDBName = "Production_Alerts_A7" }
            "preprod"      { $SQLDBName = "Production_Alerts_A7_PreProd" }
            "test"         { $SQLDBName = "Production_Alerts_A7_PreProd" }
            "dailybuild"   { $SQLDBName = "DailyBuild_Alerts_Test" }
            default        { $SQLDBName = "Production_Alerts_A7" }
         }


   if (-NOT $days) {
      if (-NOT $date) {
         $date = (Get-Date).ToShortDateString();
      } else {
         $date = "{0:MM/dd/yyyy}" -f $date
      }
   } else {
      $date = "{0:MM/dd/yyyy}" -f (get-date).AddDays(-1* ($days -as [int]))
   }

   $level = $level.ToLower();
   $lvlNum = 0

   switch ($level) {
      "m"      { $lvlNum = 0 }
      "d"      { $lvlNum = 1 }
      "h"      { $lvlNum = 2 }
      "n"      { $lvlNum = 3 }
      "s"      { $lvlNum = 4 }
      default  { $lvlNum = 0 }
   }

   if ($asc) {
      $order = "asc"
   } else {
      $order = "desc"
   }

   [bool]$first = $true

   $SQLServer = "HFDWPSQLV4\DAILYBUILDS02"

   $Sqlquery                        = "Select DATEPART(YEAR, MessageCreatedDate) [Year], DATEPART(MONTH, MessageCreatedDate) [Month]"
   If ($lvlNum -gt 0 ) { $sqlQuery += ", DATEPART(DAY, MessageCreatedDate) [Day]" } 
   If ($lvlNum -gt 1 ) { $sqlQuery += ", DATEPART(HOUR, MessageCreatedDate) [Hour]" }
   If ($lvlNum -gt 2 ) { $sqlQuery += ", DATEPART(MINUTE, MessageCreatedDate) [Minute]" }
   If ($lvlNum -gt 3 ) { $sqlQuery += ", DATEPART(SECOND, MessageCreatedDate) [Second]" }
   $SqlQuery                       += ", count(10) [Count] from Distinct_Alerts "
   $SqlQuery                       += "where [StackTrace] = (Select [StackTrace] from Unique_Alerts where [GUID] = '$guid') "
   $SqlQuery                       += "and MessageCreatedDate >= Convert(datetime,'$date') "
   $SqlQuery                       += "group by DATEPART(YEAR, MessageCreatedDate), DATEPART(MONTH, MessageCreatedDate)"
   If ($lvlNum -gt 0 ) { $sqlQuery += ", DATEPART(DAY, MessageCreatedDate)" }
   If ($lvlNum -gt 1 ) { $sqlQuery += ", DATEPART(HOUR, MessageCreatedDate)" }
   If ($lvlNum -gt 2 ) { $sqlQuery += ", DATEPART(MINUTE, MessageCreatedDate)" }
   If ($lvlNum -gt 3 ) { $sqlQuery += ", DATEPART(SECOND, MessageCreatedDate)" }
   $SqlQuery                       += "order by [YEAR] $order, [Month] $order"
   If ($lvlNum -gt 0 ) { $sqlQuery += ",[Day] $order" } 
   If ($lvlNum -gt 1 ) { $sqlQuery += ",[Hour] $order" }
   If ($lvlNum -gt 2 ) { $sqlQuery += ",[Minute] $order" }
   If ($lvlNum -gt 3 ) { $sqlQuery += ",[Second] $order" }

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"

   $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
   $SqlCmd.CommandText = $SqlQuery
   $SqlCmd.Connection = $SqlConnection

   $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
   $SqlAdapter.SelectCommand = $SqlCmd

   $dataSet = New-Object System.Data.DataSet
   $SqlAdapter.Fill($dataSet) | Out-Null

   $SqlConnection.Close();

   if ($dataSet.Tables[0].Rows.Count -eq 0) {
      Write-Output "Count between $date and now is Zero"
      Exit
   }

   $clip = ""

   $preamble = "This is the counts in env $ENV from $date until now for ENF GUID {$guid}.`n"
   $header   = "YYYY-MM-DD"
   $header  += @("", " HH:MM:SS")[[byte]($lvlNum -gt 1)]
   $header += "  :    Num occurrences"
   $lineSep  = @(("-" * 12),("-" * 21))[[byte]($lvlNum -gt 1)]
   $lineSep += "+" + ("-" * 19)
   Write-Output $preamble
   Write-Output $header
   Write-Output $lineSep

   if ($copy) {
      $clip += $header  + "`n"
      $clip += $lineSep + "`n"
   }

   $totalCount = 0

   Foreach ($row in $dataSet.Tables[0].Rows) {
      $year   = $row.Item(0)
      $month  = $row.Item(1).ToString("00")
      if ($lvlNum -gt 0 ) { $day    = $row.Item(2).ToString("00") } else {$day    = "00"}
      if ($lvlNum -gt 1 ) { $hour   = $row.Item(3).ToString("00") } else {$hour   = "00"}
      if ($lvlNum -gt 2 ) { $minute = $row.Item(4).ToString("00") } else {$minute = "00"}
      if ($lvlNum -gt 3 ) { $second = $row.Item(5).ToString("00") } else {$Second = "00"}
      switch ($lvlNum) {
         0  { $count  = $row.Item(2) } 
         1  { $count  = $row.Item(3) }
         2  { $count  = $row.Item(4) }
         3  { $count  = $row.Item(5) }
         4  { $count  = $row.Item(6) }
         default {}
      }

      $totalCount += $count

      $outputStr  =  "$year-$month"
      if ($lvlNum -gt 0 ) {$outputStr += "-$day"}
      if ($lvlNum -gt 1 ) {
         $outputStr += " $hour"
         $outputStr += ":"
         $outputStr += $minute
         $outputStr += ":$second"
      }


      $outputStr = @($outputStr.PadRight(10), $outputStr.PadRight(19))[[byte]($lvlNum -gt 1)]
      $outputStr += "  :"
      $outputStr += ($count -as [string]).PadLeft(7, ' ')
      $outputStr += " occurrences"
      Write-Output $outputStr

      if ($copy) { $clip += $outputStr + "`n" }

   }

   Write-Output $lineSep
   if ($copy) { $clip += $lineSep + "`n" }
   $totalStr +=  "Total count  :".PadLeft(22, ' ')
   $totalStr +=  ($totalCount -as [string]).PadLeft(7, ' ')
   $totalStr +=  " occurrences`n"

   Write-Output $totalStr
   if ($copy) { $clip += $totalStr + "`n" }

   if ($copy) { 
      Add-Type -AssemblyName System.Windows.Forms

      if ( ($clip -ne $null) -and ($clip -ne '') ) {
         [Windows.Forms.Clipboard]::SetText( $clip )
      }
   }
}
