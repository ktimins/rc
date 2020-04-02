<#

.SYNOPSIS
Check the counts of ENFs based upon the exception message and stack trace of the ENF.

.DESCRIPTION
This script is used to check the counts of ENFs based upon the execption message of the ENF.
Currently, this script can go against A7 Prod, A7 QA, and DailyBuilds.
The output datetime stamps can be controlled to state how specific you want each row to be.
The output can be pushed the clipboard with built-in functonality.

Predefined sets of exception messages can be checked against. To view the sets and their exception messages, use "-List" flag.

.NOTES
Thes script must be modified to add new message sets. A custom message can be passed in though.

.PARAMETER ENV
This is used to set the environment to go against. The list of environments are:
A7 Prod        =  "A7Prod"
A7 QA          =  "A7QA"
DailyBuilds    =  "DailyBuilds"

.PARAMETER List
This flag displays the sets of exception messages. No other functionality will be executed.

.PARAMETER Days
This is used to define how many days back that you want to look at.
It allows a range of 1 (last 24 hours) to 732 (two years).
By default, it is set to 1.

.PARAMETER Level
This is used to state tne level of precicion the datetime stamp on the output should be.

.PARAMETER Group
This is used to state what group of messages you want to check against.
Use the parameter "-List" to see the list of messages that are programmed in.

.PARAMETER Message
This is used to supply a custom message to check against instead of using the supplied messages.

.PARAMETER Guid
This flag gets all the Triage GUIDs that match the messagesnd outputs them. 
The exception message of the GUID/ENF is outputed as well.
Only the GUIDS/ENFs within the datetime specified will be outputed.

.PARAMETER Asc
This flag is used to format the output in ascending date order instead of descending.

.PARAMETER Copy
This flag is used to copy the output to the clipboard.

#> 

#Requires -Version 2

Param(
      [Parameter(Mandatory=$false,Position=1)]
      [ValidateSet("A7Prod","A7QA","DailyBuilds")]
      [String]$Env       = "A7Prod",
      [Parameter(Mandatory=$false,Position=0)]
      [ValidateSet("Trans","Billing","Format","FileLock","WC","RdTimeOut","Timeout","Deadlock","Endpoint","Disk","Custom")]
      [String]$Group     = "trans",
      [Parameter(Mandatory=$false,Position=2)]
      [ValidateRange(1, 732)]
      [Int]$Days         = 1,
      [Parameter(Mandatory=$false,Position=3)]
      [ValidateSet("Month","Day","Hour","Minute","Second")]
      [String]$Level     = "hour",
      [Parameter(Mandatory=$false)]
      [ValidateScript({ -not ($_ -match "(['`";]|--)") })]
      [String]$Message   = "",
      [Parameter(Mandatory=$false)]
      [Switch]$List      = $false,
      [Parameter(Mandatory=$false)]
      [Switch]$Asc       = $false,
      [Parameter(Mandatory=$false)]
      [Switch]$Guid      = $false,
      [Parameter(Mandatory=$false)]
      [Switch]$Copy      = $false
      )

Process {

   ## Use custom group if the message was supplied.
   If ($Message) {
      $Group = "Custom"
   }

   ## Go get the list of messages that will be used based on the group.
   $MessageListInfo = Set-ExceptionStackList $Group $Message $List

   ## If using the "-List" switch, create the list and display. Then quit the script.
   If ($List) {
      $MessageListInfo | Get-List
      Exit
   }

   ## Get the server information
   $ServerInfo = $Env | Get-ServerEnvironment

   ## Convert the level (time granularity) to a number for use in the SQL query
   $LevelNumber = $Level | Get-LevelNumber

   ## Go get the counts from SQL
   $CountsDataSet = Get-TimeAndCount $MessageListInfo.MsgList $ServerInfo $Days $LevelNumber $Asc

   If ($Guid) {
      ## If we are looking at the GUIDs, go get the GUID information from SQL
      $GuidDataSet = Get-GUID $MessageListInfo.MsgList $ServerInfo $Days
   }

   ## Create the output information
   $Output = Get-Output $CountsDataSet $MessageListInfo.NameLookup[$Group] $ServerInfo.Name $Days $GuidDataSet

}

End {

   ## Show the output information
   $Output | Write-Output

   If ($Copy) {
      ## Copy the output to the copy buffer (Clipboard).
      $Output | Set-CopyBuffer
   }
}

Begin {

   Function Set-ExceptionStackList {
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
            [String]$Group,
            [Parameter(Mandatory=$false,Position=1)]
            [String]$Message = '',
            [Parameter(Mandatory=$false,Position=2)]
            [Boolean]$List = $false
           )

      Begin {

         ## Create the MessageInfo object
         $MessageInfo = "" | Select-Object -Property MsgList,NameLookup
         $MessageInfo.MsgList = @()
         $MessageInfo.NameLookup = @{}
      }

      Process {

         ## For each group, set the Message list and the name lookup information.
         ## If adding new groups, Add a new if case here and modify the Group validateSet at the top of the script.

         If ($Group -eq "trans" -or $List) {
            $ID = "trans"
            $Name = "Trans in Doubts"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += '%The transaction is in doubt.%'
            $MessageInfo.MsgList += '%This SqlTransaction has completed; it is no longer usable.%'
            $MessageInfo.MsgList += '%deadlocked on lock resources with another process%'
         } 
         If ($Group -eq "billing" -or $List) {
            $ID = "billing"
            $Name = "Billing Timeouts and Errors"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += '%Error Calling the Interface Submit ResponseResult:1-The request channel timed out while waiting for a reply after 00%'
            $MessageInfo.MsgList += '%Error Calling the Interface Submit ResponseResult:1-An error occurred while receiving the HTTP response to%'  
            $MessageInfo.MsgList += '%Error Calling the Interface Submit ResponseResult:1-The request channel timed out while waiting for a reply after 59%'
            $MessageInfo.MsgList += 'The request channel timed out while waiting for a reply after 00:01:00.%'
         }
         If ($Group -eq "format" -or $List) {
            $ID = "format"
            $Name = "Formatting Errors"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += '%An error occurred in the Remote Service Provider RSFORMAT.%'
            $MessageInfo.MsgList += 'FormX Create PDF Error:%'
         }
         If ($Group -eq " + fileLock" -or $List) {
            $ID = "fileLock"
            $Name = "Filelocks"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += '%Lock file region failed%'
            $MessageInfo.MsgList += '%Error writing to file%'
         }
         If ($Group -eq "wc" -or $List) {
            $ID = "wc"
            $Name = "CoName Objects with TypeCd = 'WC','RS'"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += "%Wrong number of CoName Objects with TypeCd = _WC_,_RS_.%"
         }
         If ($Group -eq "RDTimeOut" -or $List) {
            $ID = "rdtimeout"
            $Name = "Reporting Decisions Time Outs"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += "%connection failure, timeout or low disk condition%"
            $MessageInfo.MsgList += "%The underlying connection was closed%"
            $MessageInfo.MsgList += "%An error has occurred during report processing%"
         }
         If ($Group -eq "timeout" -or $List) {
            $ID = "timeout"
            $Name = "Policy Decisions Time Outs"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += "%Microsoft ofe DB Provider for SQL Server - Connection failure%" 
            $MessageInfo.MsgList += "%[DBNETLIB][ConnectionWrite (send()).]General network error. Check your network documentation."
            $MessageInfo.MsgList += "%Rating ended with errors: Connection failure%"
            $MessageInfo.MsgList += "%Connection failure%"
            $MessageInfo.MsgList += "%General Network Error%"
            $MessageInfo.MsgList += "%SSO Web Service Error Expired%"
            $MessageInfo.MsgList += "%The operation timed out%"
            $MessageInfo.MsgList += "%The network path was not found.%"
         }
         If ($Group -eq "deadlock" -or $List) {
            $ID = "deadlock"
            $Name = "Deadlocks"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += "%deadlock%"
            $MessageInfo.MsgList += "%Deadlock%"
         }
         If ($Group -eq "endpoint" -or $List) {
            $ID = "endpoint"
            $Name = "No Endpoint Listening"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += "%There was no endpoint listening at%"
         }
         If ($Group -eq "disk" -or $List) {
            $ID = "disk"
            $Name = "There is not enough space on the disk."
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += "%There is not enough space on the disk.%"
            $MessageInfo.MsgList += "%Disk full%"
         }
         If ($Group -eq "custom" -or ($List -and $Group -eq "custom")) {
            $ID = "custom"
            $Name = "Custom Message"
            If ($List) { $MessageInfo.MsgList += "List - $ID - $Name" }
            $MessageInfo.NameLookup.Add($ID, $Name)
            $MessageInfo.MsgList += $Message
         }
      }

      End {
         Return $MessageInfo
      }
   }

   Function Get-List {
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
            [PSCustomObject]$MessageListInfo
           )

      Begin {
         ## Start the top header of the List output
         $Header = "These are the Exception Messages/Stack Traces used in the lookups."
         $Separator += "+" + ("-" * ($Header.Length + 2))
         $SeparatorBig += "+" + ("=" * ($Header.Length + 2))
         $ExHelpText  = "|$Header`n|`n"
         $ExHelpText += $SeparatorBig + "`n|"
      }

      Process {
         ## We have a huge list of messages to loop through
         Foreach ($Message in $MessageListInfo.MsgList) {
            ## Any line that starts with "List - " is used as a subheader line in the List output.
            If ($Message.StartsWIth("List - ")) {
               ## Remove the "List - " from the line.
               $title = $Message.Remove(0,7)
               ## Format the subheader.
               $ExHelpText += "`n|`n|$($title):"
               $ExHelpText += "`n|" + ("-" * ($title.Length + 1))
            } Else {
               ## This is a normal message.
               $ExHelpText += "`n|   - '$Message'"
            }
         }
      }

      End {
         ## Output all the List
         "`n$Separator`n$ExHelpText`n$Separator`n" | Write-Output
      }
   }

   Function Get-ServerEnvironment {
      Param(
            [Parameter(Mandatory=$false,ValueFromPipeLine=$true,Position=0)]
            [String]$Env = "A7Prod"
           )

      Begin {
         ## Create the Server info object
         $ServerInfo = "" | Select-Object -Property Server,Database,Name
      }

      Process {
         ## Set the Server value
         $ServerInfo.Server = "HFDWPSQLV4\DAILYBUILDS02"
         ## Set the Server Database
         Switch ($Env.ToLower()) {
            "a7prod"          { $ServerInfo.Database = "Production_Alerts_A7" 
                                $ServerInfo.Name = "Allstate Production" }
            "a7qa"            { $ServerInfo.Database = "Production_Alerts_A7_PreProd" 
                                $ServerInfo.Name = "Allstate QA" }
            "dailybuilds"     { $ServerInfo.Database = "DailyBuild_Alerts_Test" 
                                $ServerInfo.Name = "Daily Builds" }
         }
      }

      End {
         Return $ServerInfo
      }
   }

   Function Get-LevelNumber {
      Param(
            [Parameter(Mandatory=$false,ValueFromPipeLine=$true,Position=0)]
            [String]$Level
           )

      Begin {
         $LevelNumber = 0
      }

      Process {
         ## Convert the English value to a number for use in the code. Allows for greater than comparisons.
         ## TODO: Turn this into an Enum instead of a transformation function.
         Switch ($Level) {
            "Month"        { $LevelNumber = 0 }
            "Day"          { $LevelNumber = 1 }
            "Hour"         { $LevelNumber = 2 }
            "Minute"       { $LevelNumber = 3 }
            "Second"       { $LevelNumber = 4 }
         }
      }

      End {
         Return $LevelNumber
      }
   }

   Function Get-TimeAndCount {
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
            [String[]]$Messages,
            [Parameter(Mandatory=$true,Position=1)]
            [PSCustomObject]$ServerInfo,
            [Parameter(Mandatory=$true,Position=2)]
            [Int]$Days,
            [Parameter(Mandatory=$true,Position=3)]
            [Int]$LevelNumber,
            [Parameter(Mandatory=$true,Position=4)]
            [Boolean]$Asc
           )

      Begin {
         ## Determine what order the dates should be in
         $Order = @{$true='ASC';$false='DESC'}[$Asc]
      }

      Process {
         ## Set up the correct SELECT statement for the granularity/level desired
         $SqlQuery = "SELECT DATEPART(YEAR, [Distinct_Alerts].[MessageCreatedDate]) [Year], RIGHT('00' + CAST((DATEPART(MONTH, [Distinct_Alerts].[MessageCreatedDate])) AS VARCHAR(2)), 2) [Month]"
         If ($LevelNumber -gt 0 ) { $SqlQuery += ", RIGHT('00' + CAST((DATEPART(DAY,    [Distinct_Alerts].[MessageCreatedDate])) AS VARCHAR(2)) ,    2) [Day]`n" } Else { $SqlQuery += ", '00' [Day]"    }
         If ($LevelNumber -gt 1 ) { $SqlQuery += ", RIGHT('00' + CAST((DATEPART(HOUR,   [Distinct_Alerts].[MessageCreatedDate])) AS VARCHAR(2)) ,   2) [Hour]`n" } Else { $SqlQuery += ", '00' [Hour]"   }
         If ($LevelNumber -gt 2 ) { $SqlQuery += ", RIGHT('00' + CAST((DATEPART(MINUTE, [Distinct_Alerts].[MessageCreatedDate])) AS VARCHAR(2)) , 2) [Minute]`n" } Else { $SqlQuery += ", '00' [Minute]" }
         If ($LevelNumber -gt 3 ) { $SqlQuery += ", RIGHT('00' + CAST((DATEPART(SECOND, [Distinct_Alerts].[MessageCreatedDate])) AS VARCHAR(2)) , 2) [Second]`n" } Else { $SqlQuery += ", '00' [Second]" }
         $SqlQuery += ", COUNT(10) [Count] FROM [Distinct_Alerts] "
         $SqlQuery += "WHERE (("

         ## Go through all the messages and set up the comparison to the Exception Message Field
         $First = $true
         Foreach ($ExMsg in $Messages) {
            $String = ""
            If ($First) { $First = $false } Else { $String += "OR " }
            $ExMsg = $ExMsg -replace '"','' -replace "'","''" -replace ';','' -replace '--',''
            $String += "[Distinct_Alerts].[ExceptionMessage] like '$ExMsg' "
            $SqlQuery  += $String
         }

         $SqlQuery += ") OR ( "

         ## Go through all the messages and set up the comparison to the Stack Trace Field
         $First = $true
         Foreach ($Stack in $Messages) {
            $String = ""
            If ($First) { $First = $false } Else { $String += "OR " }
            $Stack = $Stack -replace '"','' -replace "'", "''" -replace ';','' -replace '--',''
            $String += "[Distinct_Alerts].[StackTrace] like '$Stack' "
            $SqlQuery += $String
         }

         $SqlQuery += ")) AND [Distinct_Alerts].[MessageCreatedDate] >= DATEADD(DAY, -$days, GETDATE()) "
         $SqlQuery += "GROUP by DATEPART(YEAR, [Distinct_Alerts].[MessageCreatedDate]), DATEPART(MONTH, [Distinct_Alerts].[MessageCreatedDate])"
         If ($LevelNumber -gt 0 ) { $SqlQuery += ", DATEPART(DAY, [Distinct_Alerts].[MessageCreatedDate])" }
         If ($LevelNumber -gt 1 ) { $SqlQuery += ", DATEPART(HOUR, [Distinct_Alerts].[MessageCreatedDate])" }
         If ($LevelNumber -gt 2 ) { $SqlQuery += ", DATEPART(MINUTE, [Distinct_Alerts].[MessageCreatedDate])" }
         If ($LevelNumber -gt 3 ) { $SqlQuery += ", DATEPART(SECOND, [Distinct_Alerts].[MessageCreatedDate])" }
         $SqlQuery += "ORDER BY [Year] $Order, [Month] $Order"
         If ($LevelNumber -gt 0 ) { $SqlQuery += ",[Day] $Order" } 
         If ($LevelNumber -gt 1 ) { $SqlQuery += ",[Hour] $Order" }
         If ($LevelNumber -gt 2 ) { $SqlQuery += ",[Minute] $Order" }
         If ($LevelNumber -gt 3 ) { $SqlQuery += ",[Second] $Order" }
         Write-Verbose "Counts SQL Lookup"
         Write-Verbose $SqlQuery

         ## Go get the information
         $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
         $SqlConnection.ConnectionString = "Server = $($ServerInfo.Server); Database = $($ServerInfo.Database); Integrated Security = True"

         $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
         $SqlCmd.CommandText = $SqlQuery
         $SqlCmd.Connection = $SqlConnection

         $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
         $SqlAdapter.SelectCommand = $SqlCmd

         $DataSet = New-Object System.Data.DataSet
         $SqlAdapter.Fill($DataSet) | Out-Null

         $SqlConnection.Close()
      }

      End {
         Return $DataSet
      }

   }

   Function Get-GUID {
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
            [String[]]$Messages,
            [Parameter(Mandatory=$true,Position=1)]
            [PSCustomObject]$ServerInfo,
            [Parameter(Mandatory=$true,Position=2)]
            [Int]$Days
           )

      Begin {
      }

      Process {
         ## Set up the SELECT statement
         $SqlQuery    = "SELECT [UA].[GUID], [UA].[ExceptionMessage] FROM [Unique_Alerts] UA WHERE (( "

         ## Go through all the messages and set up the comparision to the Exception Message Field
         $First = $true
         Foreach ($ExMsg in $Messages) {
            $String   = ""
            If ($First) { $First = $false } Else { $String += "OR " }
            $ExMsg    = $ExMsg -replace '"','' -replace "'","''" -replace ';','' -replace '--',''
            $String  += "[UA].[ExceptionMessage] like '$ExMsg' "
            $SqlQuery+= $String
         }

         $SqlQuery   += ") OR ( "

         ## Go through all the messages and set up the comparision to the Stack Trace Field
         $First = $true
         Foreach ($Stack in $Messages) {
            $String   = ""
            If ($First) { $First = $false } Else { $String += "OR " }
            $Stack    = $Stack -replace '"','' -replace "'", "''" -replace ';','' -replace '--',''
            $String  += "[StackTrace] like '$Stack' "
            $SqlQuery+= $String
         }

         $SqlQuery   += " )) AND [UA].[LastOccurrenceDateTime] >= DATEADD(DAY, -$days, GETDATE()) "
         $SqlQuery   += "ORDER BY [UA].[ExceptionMessage]"
         Write-Verbose "GUID SQL Lookup"
         Write-Verbose $SqlQuery

         ## Go get the information.
         $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
         $SqlConnection.ConnectionString = "Server = $($ServerInfo.Server); Database = $($ServerInfo.Database); Integrated Security = True"

         $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
         $SqlCmd.CommandText = $SqlQuery
         $SqlCmd.Connection = $SqlConnection

         $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
         $SqlAdapter.SelectCommand = $SqlCmd

         $DataSet = New-Object System.Data.DataSet
         $SqlAdapter.Fill($DataSet) | Out-Null

         $SqlConnection.Close()
      }

      End {
         Return $DataSet
      }

   }

   Function Get-Output {
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
            [System.Data.DataSet]$CountsDataSet,
            [Parameter(Mandatory=$true,Position=1)]
            [String]$TypeOfMessage,
            [Parameter(Mandatory=$true,Position=2)]
            [String]$Environment,
            [Parameter(Mandatory=$true,Position=3)]
            [Int]$Days,
            [Parameter(Mandatory=$false,Position=4)]
            [AllowNull()]
            [System.Data.DataSet]$GuidDataSet
           )

      Begin {
         ## Format the current date into ISO format.
         $Date = "{0:yyyy-MM-dd}" -f (get-date).AddDays(-1 * ($Days -as [Int]))
         $LineSeparator = ("-" * 21) + "+" + ("-" * 19) + "`n"
         ## Set up the Header
         $Output = "This is the '$TypeOfMessage' counts in Environment '$Environment' from $Date until now.`n`n"
      }

      Process {
         If ($CountsDataSet.Tables[0].Rows.Count -eq 0) {
            ## There were no occurrences in the given time frame
            $Output = "   Counts between $Date and now is Zero.`n"
         } Else {
            ## Setup the subheader
            $Output += "YYYY-MM-DD HH:MM:SS  :    Num Occurrences`n"
            $Output += $LineSeparator

            ## Total count index
            $TotalCount = 0

            ## Go through each of the results in the set
            Foreach ($Row in $CountsDataSet.Tables[0].Rows) {

               ## Get the specific outputs.
               $Year   = $Row['Year']
               $Month  = $Row['Month']
               $Day    = $Row['Day']
               $Hour   = $Row['Hour']
               $Minute = $Row['Minute']
               $Second = $Row['Second']
               $TotalCount += $Row['Count']

               ## Combine the results into the readable row
               $Output  +=  "$Year-$Month-$Day $($Hour):$($Minute):$Second  :" + ` 
                            ($row['Count'] -as [string]).PadLeft(7, ' ') + " Occurrences`n"
            }

            $Output += $LineSeparator
            ## Show the total count in the output.
            $Output += "Total Count  :".PadLeft(22, ' ') + ($TotalCount -as [String]).PadLeft(7, ' ') + " Occurrences`n"

            ## If we are showing the GUID information
            If ([Boolean]$GuidDataSet) {
               $Output += "`n`n"
               ## Setup the Sub header
               $Output += "GUIDS".PadRight(36, ' ') + " : Exception Message`n"
               $Output += ("-" * 37) + "+" + ("-" * 18) + "`n"
               ## Go through each of the results in the set
               Foreach ($Row in $GuidDataSet.Tables[0].Rows) {
                  $Guid = $Row['GUID']
                  $ExMsg = $Row['ExceptionMessage']
                  ## Get rid of any newlines and replace with spaces for readability
                  $ExMsg = [Regex]::Replace($ExMsg, "[\n\r]", " ")
                  ## Shorten the exception message to 75 characters so it fits on the screen.
                  $ExMsg = $ExMsg.SubString(0, [Math]::Min(75, $ExMsg.Length))
                  ## Output the GUID information
                  $Output += "$Guid : $ExMsg`n"
               }
            }
         }
      }

      End {
         Return $Output
      }
   }

   Function Set-CopyBuffer {
      Param(
            [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
            [String]$Output
           )

      ## Get the Assembly loaded
      Add-Type -AssemblyName System.Windows.Forms
      If ( $Output -ne $null -and $Output -ne '' ) {
         ## Copy the output to to the copy buffer (Clipboard)
         [Windows.Forms.Clipboard]::SetText( $Output )
      }

   }

}

# SIG # Begin signature block
# MIIEPAYJKoZIhvcNAQcCoIIELTCCBCkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/WcxWBaw70fU6h1+BaSCJokq
# VfegggJDMIICPzCCAaygAwIBAgIQK1hHgwMalLpMVaX08TbQfTAJBgUrDgMCHQUA
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
# hvcNAQkEMRYEFDCWAesM3NwzRt/6ajQ8KLJlGdieMA0GCSqGSIb3DQEBAQUABIGA
# rZtFdUrtvB4jbHC77k1cp1KKyVwpfZD6zC573JYBeBq1iQErnelGpkleiYU5nGZH
# CsVIVVix3RfvFOG+1Z/vuoSfuG37qKwO8cp47KiBCkD4uwygXcWNWMaULCfsZ64/
# wDCaC2++sGedthyNHarcNI+mHcpM5hTCnYhjNTvBn7I=
# SIG # End signature block
