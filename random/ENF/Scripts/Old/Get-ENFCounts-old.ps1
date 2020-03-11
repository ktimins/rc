<#

.SYNOPSIS
Check the counts of ENFs based upon the exception message of the ENF.

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

.PARAMETER list
This flag displays the sets of exception messages. No other functionality will be executed.

.PARAMETER days
This is used to define how many days back you want to look at. 
It allows a range of 0 (today only) to 365.
By default, only today is looked at.

It cannot be used in combination with "-date".

.PARAMETER date
This is used to define a starting date to look at.
By default, only today is looked at.

It cannot be used in combination with "-days".

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
This flag gets all the Triage GUIDs that match the exception messages and outputs them. The exception message of the GUID/ENF is outputed as well.
Only GUIDs/ENFs within the datetime specified will be outputed.

.PARAMETER group
This is used to state what group of exception messages you want to check against.
The valid values are:
"trans"     =  Trans in Doubts
"billing"   =  Billing timeouts
"format"    =  Formatting errors from RSFormat or FormX

.PARAMETER trans
This flag is used to set the "-group" flag to "trans"

.PARAMETER billing
This flag is used to set the "-group" flag to "billing"

.PARAMETER format
This flag is used to set the "-group" flag to "format"

.PARAMETER fileLock
This flag is used to set the "-group" flag to "fileLock"

.PARAMETER wc
This flag is used to set the "-group" flag to "WC"

.PARAMETER v
This flag is used in conjunction with "-guid" to paste the whole exception message instead of it being truncated.

.PARAMETER copy
This flag is used to copy the output to the clipboard.

.PARAMETER copi
This flag is used to copy the output to the clipboard, but include 6 spaces in the beginning of the line. 
It is used for copying to the TriageList.txt document.

#>

#Requires -Version 2

[CmdletBinding(DefaultParameterSetName="days")]
Param(
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [ValidateSet("prod","qa","dailybuild")]
      [string]$env       = "prod",
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [ValidateRange(0, 365)]
      [int]$days         = 0,
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [datetime]$date    = (Get-Date -Format g), 
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [ValidateSet("m","d","h","n","s")]
      [string]$level     = "h",
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [ValidateSet("trans","billing","format","fileLock","wc","rdTimeOut","timeout","deadlock","custom")]
      [string]$group     = "trans",
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [string]$exMsg,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [string]$stack,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$list      = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$asc       = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$trans     = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$billing   = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$format    = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$fileLock  = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$wc        = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$rdtimeout = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$timeout   = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$deadlock  = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$guid      = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$v         = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copy")]
      [switch]$copy      = $false,
      [Parameter(Mandatory=$false,ParameterSetName="days")]
      [Parameter(Mandatory=$false,ParameterSetName="date")]
      [Parameter(Mandatory=$false)]
      [Parameter(Mandatory=$false,ParameterSetName="copi")]
      [switch]$copi      = $false
     )

If (-not ($exMsg -or $stack)) {
   $group = $group.ToLower()
   If ($billing) { $group = "billing" } 
   Elseif ($format) { $group = "format" } 
   Elseif ($trans) { $group = "trans" } 
   Elseif ($fileLock) { $group = "fileLock" } 
   Elseif ($wc) { $group = "WC" }
   Elseif ($rdtimeout) { $group = "rdTimeOut" }
   Elseif ($timeout) { $group = "timeout" }
   Elseif ($deadlock) { $group = "deadlock" }
   Else   { $group = "trans" }
} Else {
   $group = "custom"
}

$exMsgList = @()
$stTrcList = @()

if ($group -eq "trans" -or $list) {
   if ($list) { $exMsgList += "trans" }
   $exMsgList += '%The transaction is in doubt.%'
   $exMsglist += '%This SqlTransaction has completed; it is no longer usable.%'
   $exMsgList += '%deadlocked on lock resources with another process%'
} 
if ($group -eq "billing" -or $list) {
   if ($list) { $exMsgList += "billing" }
   $exMsgList += '%Error Calling the Interface Submit ResponseResult:1-The request channel timed out while waiting for a reply after 00%'
   $exMsgList += '%Error Calling the Interface Submit ResponseResult:1-An error occurred while receiving the HTTP response to%'  
   $exMsgList += '%Error Calling the Interface Submit ResponseResult:1-The request channel timed out while waiting for a reply after 59%'
   $exMsgList += 'The request channel timed out while waiting for a reply after 00:01:00.%'
}
if ($group -eq "format" -or $list) {
   if ($list) { $exMsgList += "format" }
   $exMsgList += '%An error occurred in the Remote Service Provider RSFORMAT.%'
   $exMsgList += 'FormX Create PDF Error: PDF Conversion Job Failed.%'
}
if ($group -eq "fileLock" -or $list) {
   if ($list) { $exMsgList += "fileLock" }
   $exMsgList += '%Lock file region failed%'
   $exMsgList += '%Error writing to file%'
}
if ($group -eq "WC" -or $list) {
   if ($list) { $exMsgList += "CoName Objects with TypeCd = 'WC','RS'" }
   $exMsgList += "%Wrong number of CoName Objects with TypeCd = _WC_,_RS_.%"
}
if ($group -eq "RDTimeOut" -or $list) {
   if ($list) { $exMsgList += "Reporting Decisions Time Outs" }
   $exMsgList += "%connection failure, timeout or low disk condition%"
}
if ($group -eq "timeout" -or $list) {
   $stTrcList += "%Microsoft ofe DB Provider for SQL Server - Connection failure%" 
   $stTrcList += "%[DBNETLIB][ConnectionWrite (send()).]General network error. Check your network documentation."
   $stTrcList += "%Rating ended with errors: Connection failue%"
   $stTrcList += "%Connection failure%"
}
if ($group -eq "deadlock" -or $list) {
   if ($list) { $exMsgList += "Deadlock" }
   $exMsgList += "%deadlock%"
   $exMsglist += "%Deadlock%"
}
If ($group -eq "custom") {
   $exMsgList += $exMsg
   $stTrcList += $stack
}

if ($list) {
   $ExHelpText += "These are the Exception Messages used in the lookups."
   $ExHelpText += "`n`n"
   $ExHelpText += "+" + ("-" * 50)
   foreach ($exMsg in $ExMsgList) {
      if ($exMsg -eq "trans") {
         $ExHelpText += "`n|Trans in Doubts : " 
         $ExHelpText += "`n|"
         $ExHelpText += ("-" * 17)
      } elseif ($exMsg -eq "billing") {
         $ExHelpText += "`n|Billing Timeouts: "
         $ExHelpText += "`n|"
         $ExHelpText += ("-" * 17)
      } elseif ($exMsg -eq "format") {
         $ExHelpText += "`n|Formatting:       "
         $ExHelpText += "`n|"
         $ExHelpText += ("-" * 11)
      } else {
         $ExHelpText += "`n|   - '" + $exMsg
      }
   }

   Write-Output "`n"
   $ExHelpText | Write-Output 
   "+" + ("-" * 50) | Write-Output
   Write-Output "`n"
   Exit
}

switch ($env.ToLower()) {
   "prod"         { $SQLDBName = "Production_Alerts_A7" }
   "qa"           { $SQLDBName = "Production_Alerts_A7_PreProd" }
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


$SQLServer = "HFDWPSQLV4\DAILYBUILDS02"

$Sqlquery                        = "Select DATEPART(YEAR, MessageCreatedDate) [Year], RIGHT('00' + CAST((DATEPART(MONTH, MessageCreatedDate)) AS VARCHAR(2)), 2) [Month]"
If ($lvlNum -gt 0 ) { $sqlQuery += ", RIGHT('00' + CAST((DATEPART(DAY,    MessageCreatedDate)) AS VARCHAR(2)) ,    2) [Day]" } Else { $sqlQuery += ", '00' [Day]"    }
If ($lvlNum -gt 1 ) { $sqlQuery += ", RIGHT('00' + CAST((DATEPART(HOUR,   MessageCreatedDate)) AS VARCHAR(2)) ,   2) [Hour]" } Else { $sqlQuery += ", '00' [Hour]"   }
If ($lvlNum -gt 2 ) { $sqlQuery += ", RIGHT('00' + CAST((DATEPART(MINUTE, MessageCreatedDate)) AS VARCHAR(2)) , 2) [Minute]" } Else { $sqlQuery += ", '00' [Minute]" }
If ($lvlNum -gt 3 ) { $sqlQuery += ", RIGHT('00' + CAST((DATEPART(SECOND, MessageCreatedDate)) AS VARCHAR(2)) , 2) [Second]" } Else { $sqlQuery += ", '00' [Second]" }
$SqlQuery                       += ", count(10) [Count] from Distinct_Alerts "
$SqlQuery                       += "where ("
If ($exMsgList) {
   [bool]$first = $true
   foreach ($exMsg in $exMsgList) {
      $str = ""
      if ($first) { $first = $false } else { $str += "or " }
      $exMsg = $exMsg -replace '"','' -replace "'","''" -replace ';','' -replace '--',''
      $str += "ExceptionMessage like " + "'" + $exMsg + "'"
      $SqlQuery += $str
   }
}
If ($stTrcList) {
   if ($exMsgList) {
      $SqlQuery                 += ") and ("
   }
   [bool]$first = $true
   foreach ($stTrc in $stTrcList) {
      $str = ""
      if ($first) { $first = $false } else { $str += "or " }
      $stTrc = $stTrc -replace '"','' -replace "'", "''" -replace ';','' -replace '--',''
      $str += "StackTrace like '$stTrc'"
      $SqlQuery += $str
   }
}
$SqlQuery                       += ") "
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
Write-Verbose $sqlQuery

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

#if ($dataSet.Tables[0].Rows.Count -eq 0) {
#   Write-Output "Count between $date and now is Zero"
   #Exit
#}

$clip = ""
$copyIndent = "      "

$preamble = "This is the Trans in Doubt counts in env $ENV from $date until now.`n"
$header   = "YYYY-MM-DD HH:MM:SS  :    Num occurrences"
$lineSep += ("-" * 21) + "+" + ("-" * 19)
Write-Output $preamble
Write-Output $header
Write-Output $lineSep

if ($copy) {
   $clip += $header  + "`n"
   $clip += $lineSep + "`n"
} elseif ($copi) {
   $clip += $copyIndent + $header  + "`n"
   $clip += $copyIndent + $lineSep + "`n"
}

$totalCount = 0

Foreach ($row in $dataSet.Tables[0].Rows) {
   $row | write-verbose
   $year   = $row['Year']
   $month  = $row['Month']
   $day    = $row['Day']
   $hour   = $row['Hour']
   $minute = $row['Minute']
   $second = $row['Second']
   $totalCount += $row['Count']

   $outputStr  =  "$year-$month"
   $outputStr += "-$day"
   $outputStr += " $hour"
   $outputStr += ":"
   $outputStr += $minute
   $outputStr += ":$second"


   $outputStr = @($outputStr.PadRight(10), $outputStr.PadRight(19))[[byte]($lvlNum -gt 1)]
   $outputStr += "  :"
   $outputStr += ($row['Count'] -as [string]).PadLeft(7, ' ')
   $outputStr += " occurrences"
   Write-Output $outputStr

   If ($copy) { 
      $clip += $outputStr + "`n" 
   } ElseIf ($copi) { 
      $clip += $copyIndent + $outputStr + "`n" 
   }

}

Write-Output $lineSep
if ($copy) { 
   $clip += $lineSep + "`n" 
} Elseif ($copi) { 
   $clip += $copyIndent + $lineSep + "`n" 
}
$totalStr +=  "Total count  :".PadLeft(22, ' ')
$totalStr +=  ($totalCount -as [string]).PadLeft(7, ' ')
$totalStr +=  " occurrences`n"

Write-Output $totalStr
if ($copy) { 
   $clip += $totalStr + "`n" 
} Elseif ($copi) { 
   $clip += $copyIndent + $totalStr + "`n" 
}

if ($guid) {

   $first = $true

   $guidQuery   = "select GUID, ExceptionMessage from Unique_Alerts "
   $guidQuery  += "where ("
   foreach ($exMsg in $exMsgList) {
      $str = ""
      if ($first) { $first = $false } else { $str += "or " }
      $str += "ExceptionMessage like " + "'" + $exMsg + "'"
      $guidQuery += $str
   }
   $guidQuery  += ") "
   $guidQuery  += "and LastOccurrenceDateTime >= Convert(datetime,'$date') "
   $guidQuery  += "order by ExceptionMessage"

   $guidSqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $guidSqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"

   $guidSqlCmd = New-Object System.Data.SqlClient.SqlCommand
   $guidSqlCmd.CommandText = $guidQuery
   $guidSqlCmd.Connection = $guidSqlConnection

   $guidSqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
   $guidSqlAdapter.SelectCommand = $guidSqlCmd

   $guidDataSet = New-Object System.Data.DataSet
   $guidSqlAdapter.Fill($guidDataSet) | Out-Null

   $guidSqlConnection.Close();

   $guidTitleStr = "GUIDS".PadRight(36, ' ') + " : " + "Exception Message"
   Write-Output $guidTitleStr

   if ($copy) {
      $clip += "`n`n"
      $clip += $guidTitleStr + "`n"
   } Elseif ($copi) {
      $clip += $copyIndent + $guidTitleStr + "`n"
   }

   $barStr = ("-" * 37) + "+" + ("-" * 18)
   Write-Output $barStr
   if ($copy) { 
      $clip += $barStr + "`n" 
   } Elseif ($copi) { 
      $clip += $copyIndent + $barStr + "`n" 
   }
   Foreach ($row in $guidDataSet.Tables[0].Rows) {
      $guidStr = $row.item(0)
      $exMsg = $row.item(1)
      if ([regex]::Matches($exMsg, "[\n\r]")) {
         $exMsg = [regex]::replace($exMsg, "[\n\r]", " ")
      }
      if ($v) {
         $exMsg = $exMsg
      } else {
         $exMsg   = $exMsg.subString(0, [System.Math]::Min(75, $exMsg.Length))
      }
      Write-Output "$guidStr : $exMsg"
      if ($copy) { 
         $clip += "$guidStr : $exMsg`n" 
      } Elseif ($copi) { 
         $clip += $copyIndent + "$guidStr : $exMsg`n" 
      }
   }

}

if ($copy -or $copi) { 
   Add-Type -AssemblyName System.Windows.Forms

   if ( ($clip -ne $null) -and ($clip -ne '') ) {
      [Windows.Forms.Clipboard]::SetText( $clip )
   }
}
