#Region Set environmental variables

Function Get-EnvLookup {
   $return = @{ "DailyBuilds" = @{ "Prod" = "DailyBuild_Alerts_Test" }; `
      "Allstate"    = @{ "Prod" = "Production_Alerts_A7";     `
         "QA"   = "Production_Alerts_A7_PreProd" } }
   Return $return
}

Function Get-SmtpServer {
   $smtp = "appmail.insurity.net"
   Return $smtp
}

Function Get-DBServer {
   Return "HFDWPSQLV4\DAILYBUILDS02"
}

Function Get-TimeSpan {
   Param(
         [Parameter(Mandatory=$false,ValueFromPipeline=$true,Position=0)]
         [String]$TimeSpan
        )

   $default = "2h"
   If ( -not [Boolean]$TimeSpan ) { 
      $TimeSpan = $default
   }

   Return $TimeSpan
}

#End Region

#Region Get and Validate Config

Function Get-Config {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [string]$configFile
        )

   Begin {
      "Config File - $configFile" | Write-Verbose
      If (Test-Path $configFile) {
         $text = Get-Content $configFile
      } Else {
         Throw "Config file is not found."
      }
   }

   Process {
      If ($text -match "//") {
         Throw "Config File must be a valid JSON file. It cannot contain any comments including lines starting with '//'."
      } Else {
         Try {
            $config = $text -join "`n" | ConvertFrom-Json
         } Catch {
            Throw "Config file is not a valid JSON file."
         }
      }
   }

   End {
      Return $config
   }
}

Function Get-Email {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [PSCustomObject]$config,
         [Parameter(Mandatory=$false,Position=1)]
         [HashTable]$spDef
        )

   Begin {
      $emailCfg = $config.Output.Email
      $email = @{}
   }

   Process {
      If ([Boolean]($config.Output.Email)) {
         If ($config.Output.Email.PSObject.Properties['Subject']) {
            $subject = $config.Output.Email.Subject
         } Else {
            Write-Warning "Default subject line will be used on email."
            $subject = "ENF Alert Email"
         }
         If ([Boolean]($config.Output.Email.Recipient)) {
            Foreach ($addr in $config.Output.Email.Recipient) {
               If (-not [Boolean]($addr -as [Net.Mail.MailAddress])) {
                  Throw "$addr is not a valid email address."
               }
            }
            $recipient = @()
            $recipient = $config.Output.Email.Recipient
            $userEmail = Get-UserEmail
            If (-not ($config.Output.Email.Recipient.Contains($userEmail) -and $recipient.count -gt 0)) {
               $recipient += $userEmail
            }
         } Else {
            $recipient = @()
            $userEmail = Get-UserEmail
            $recipient += $userEmail
         }
         $recipient | Write-Verbose
         If ([Boolean]($config.Output.Email.RecipientsScheduled) -and ([Boolean]$spDef)) {
            Foreach ($emailSet in $config.Output.Email.RecipientsScheduled) {
               if (-not [Boolean]($emailSet.Email -as [Net.Mail.MailAddress])) {
                  Throw $emailSet.Email + "is not a valid email address."
               }
            }
            $recipientScheduled = Get-ValidScheduledRecipient $config.Output.Email.RecipientsScheduled $spDef
            $recipient = $recipient + $recipientScheduled #| Select -Unique
         }
         $recipient | Write-Verbose
         If ([Boolean]($config.Output.Email.CC)) {
            Foreach ($addr in $config.Output.Email.CC) {
               If (-not [Boolean]($addr -as [Net.Mail.MailAddress])) {
                  Throw "$addr is not a valid email address."
               }
            }
            $cc = @()
            $cc += $config.Output.Email.CC
         } Else {
            $cc = @()
         }
         If ([Boolean]($config.Output.Email.Attachment)) {
            If (-not ($config.Output.Email.Attachment -is [Boolean])) {
               Throw 'Attachment must be a boolean.'
            } Else {
               $attachment = $config.Output.Email.Attachment
            }
         } Else {
            $attachment = $false
         }
         If ([Boolean]($config.Output.Email.Priority)) {
            if (-not ($config.Output.Email.Priority -match "(low|normal|high)")) {
               Throw 'If setting the Priority, it must be "Low", "Normal", or "High".'
            } Else {
               $priority = $config.Output.Email.Priority
            }
         } Else {
            Write-Warning "Priority will be set to High."
            $priority = "high"
         }
      }

      $email.Add( "Subject", $subject )
      $email.Add( "Recipient", $recipient )
      $email.Add( "CC", $cc )
      $email.Add( "Attachment", $attachment )
      $email.Add( "Priority", $priority )
   }

   End {
      Return New-Object -TypeName PSObject -Prop $email
   }
}

Function Get-File {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [PSCustomObject]$config
        )

   Begin {
      $fileCfg = $config.Output.File
      $fileCfg = $config.Output.File
      $file = @{}
   }

   Process {
      If ([Boolean]($fileCfg.CSV)) {
         If ($fileCfg.CSV -is [Boolean]) {
            $file.Add( "CSV", $fileCfg.CSV )
         } Else {
            Throw "Output.File.CSV must be a boolean."
         }
      } Else {
         $file.add( "CSV", $false )
      }
      If ([Boolean]($fileCfg.Zips)) {
         If ($fileCfg.Zips -is [Boolean]) {
            $file.Add( "Zips", $fileCfg.Zips )
         } Else {
            Throw "Output.File.Zips must be a boolean."
         }
      } Else {
         $file.Add( "Zips", $false )
      }
      If ([Boolean]($fileCfg.Suffix)) {
         If (-not ($fileCfg.Suffix -match '[.?/\|!@#$%^&*()-+= ]')) {
            $file.Add( "Suffix", $fileCfg.Suffix )
         } Else {
            Throw 'Output.File.Suffix should only contain alphanumeric and underscores.'
         }
      } Else {
         $file.Add( "Suffix", "" )
      }
      If ([Boolean]($fileCfg.AppendDate)) {
         If ($fileCfg.AppendDate -is [Boolean]) {
            $file.Add( "AppendDate", $fileCfg.AppendDate )
         } Else {
            Throw "Output.File.AppendDate must be a boolean."
         }
      } Else {
         $file.Add( "AppendDate", $false )
      }
      If ([Boolean]($fileCfg.Save)) {
         If ($fileCfg.Save -is [Boolean]) {
            $file.Add( "Save", $fileCfg.Save )
         } Else {
            Throw "Output.File.Save must be a boolean."
         }
      } Else {
         $file.Add( "Save", $false )
      }
   }

   End {
      Return New-Object -TypeName PSObject -Prop $file
   }
}

Function Get-BaseDir {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [PSCustomObject]$config
        )
   $baseDir = 'C:\ENF'
   If ( [Boolean]($config.BaseDir) ) {
      $baseDir = $config.BaseDir
   }
   If (-not (Test-Path $baseDir) ) {
      Write-Warning "Creating directory $basedir."
      New-Item -ItemType Directory -Path $baseDir
   }
   Return $baseDir
}


##############################
#       ENFs Functions       #
##############################


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


Function Get-ENFSet {
   param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [PSCustomObject]$config
        )

   Begin {
      $enfSets = @()
   }

   Process {
      If ([Boolean]$config.ENFSets) {
         $config.ENFSets.PSObject.Properties.Value | Foreach {
            $enfSet = $_
            $set = @{}

            If (-not [Boolean]($enfSet.Name) ) {
               Throw "ENF set is missing a name."
            } Else {
               $set.Add( "Name", $enfSet.Name )
            }
            $set.Add( "Time", [String](Get-TimeSpan $enfSet.TimeSpan) )
            If ([Boolean]($enfSet.Zips)) {
               If (-not ($enfSet.Zips -match '^\d+[fl]$')) {
                  Throw $enfSet.Name + ".Zips is not in /\d+[fl]/ format."
               } Else {
                  $set.Add( "Zips", $enfSet.Zips )
               }
            }
            If ([Boolean]($enfSet.ExMsgs)) {
               $enfSet.ExMsgs | Foreach {
                  $exMsg = $_
                  If ($exMsg -match "'") {
                     Throw "Please remove all single quotes from exception messages in ENFSets." + $enfSet.ExMsgs.Name + "."
                  } ElseIf ($exMsg -match '--') {
                     Throw "Please remove all double hyphens '--' from exception messages in ENFSets." + $enfSet.ExMsgs.Name + "."
                  }
               }
               $set.Add( "ExMsgs", $enfSet.ExMsgs )
            } Else {
               Throw $enfSet.Name + " is missing Exception Messages."
            }
            If ([Boolean]($enfSet.NotExMsgs)) {
               $set.Add( "NotExMsgs", $enfSet.NotExMsgs )
            }
            If ([Boolean]($enfSet.Email)) {
               $email = @{}
               If ([Boolean]($enfSet.Email.Stack)) {
                  If ($enfSet.Email.Stack -is [Boolean]) {
                     $email.Add( "Stack", $enfSet.Email.Stack )
                  } Else {
                     Throw "ENFSets." + $enfSet.Name + ".Email.Stack must be a boolean"
                  }
               }
               If ([Boolean]($enfSet.Email.Details)) {
                  If ($enfSet.Email.Details -is [Boolean]) {
                     $email.Add( "Details", $enfSet.Email.Details )
                  } Else {
                     Throw "ENFSets." + $enfSet.Name + ".Email.Details must be a boolean"
                  }
               }
               If ([Boolean]($enfSet.Email.Threshold)) {
                  If ($enfSet.Email.Threshold -match '^\d+$') {
                     $email.Add( "Threshold", $enfSet.Email.Threshold )
                  } Else {
                     Throw "ENFSets." + $enfSet.Name + ".Email.Threshold must be a number"
                  }
               }
               If ([Boolean]($enfSet.Email.IncludeNotes)) {
                  If ($enfSet.Email.IncludeNotes -is [Boolean]) {
                     $email.Add( "IncNotes", $enfSet.Email.IncludeNotes )
                  } Else {
                     Throw "ENFSets." + $enfSet.Name + ".Email.IncludeNotes must be a boolean."
                  }
               }
               If ([Boolean]($enfSet.Email.San)) {
                  If ($enfSet.Email.San -is [Boolean]) {
                     $email.Add( "IncSan", $enfSet.Email.San )
                  } Else {
                     Throw "ENFSets." + $enfSet.Name + ".Email.San must be a boolean."
                  }
               }
               If ([Boolean]($enfSet.Email.IncludeEmptyNotes)) {
                  If ($enfSet.Email.IncludeEmptyNotes -is [Boolean]) {
                     $email.Add( "IncEmptyNotes", $enfSet.Email.IncludeEmptyNotes )
                  } Else {
                     Throw "ENFSets." + $enfSet.Name + ".Email.IncludeEmptyNotes must be a boolean."
                  }
               }
               If ([Boolean]($enfSet.Email.IncludeLatestInfo)) {
                  If ($enfSet.Email.IncludeLatestInfo -is [Boolean]) {
                     $email.Add( "IncLatestInfo", $enfSet.Email.IncludeLatestInfo )
                  } Else {
                     Throw "ENFSets." + $enfSet.Name + ".Email.IncludeLatestInfo must be a boolean."
                  }
               }
               $set.Add( "Email", $email )
            }
            $enfSets += $set
         }
      }
   }

   End {
      Return $enfSets
   }
}

Function Get-ENFPortfolio {
   param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [PSCustomObject]$config
        )

   Begin {
      $enfPortfolioSet = @()
   }

   Process {
      If ([Boolean]$config.ENFPortfolio) {
         $enfPortfolioSet = $config.ENFPortfolio
      }
   }

   End {
      Return $enfPortfolioSet
   }
}

Function Get-ENFSkippedStatus {
   param(
         [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
         [PSCustomObject]$config
        )

   Begin {
      $enfSkippedStatuses = @()
   }

   Process {
      If ([Boolean]$config.ENFSkippedStatuses) {
         $enfSkippedStatuses = $config.ENFSkippedStatuses
      }
   }

   End {
      Return $enfSkippedStatuses
   }
}

Function Get-ENFLOB {
   Param(
         [Parameter(Mandatory=$True,ValueFromPipeline=$true,Position=0)]
         [PSCustomObject]$config
        )

   Begin {
      $enfLobs = @()
   }

   Process {
      If ([Boolean]$config.ENFLOBs) {
         $enfLobs = $config.ENFLOBs
      }
   }

   End {
      Return $enfLobs
   }
}

Function Get-EnvsList {
   Param(
         [Parameter(Mandatory=$true,ValueFromPipeline,Position=0)]
         [PsCustomObject]$config,
         [Parameter(Mandatory=$true,Position=1)]
         [PsCustomObject]$envConfig
        )

   Begin {
      $lookup = @{}
      $lookup = Get-EnvLookup $envConfig
      $envsList = @{}
      $envsConfig = $config.Envs
   }

   Process {
      $envsConfig | Foreach {
         $env = $_
         #If (-not [Boolean]($env.Client)) {
            #   Throw "An object in Config.Envs does not contain a client. Please ensure all environments contain a client and environment."
            #} Elseif (-not [Boolean]($env.env)) {
               #   Throw "An object in Config.Envs does not contain an environment. Please ensure all environments contain a client and environment."
               #}
         $envValidate = Compare-Env $env.Client $env.Env $lookup
         If ($envValidate -eq $true) {
            $envsList.Add( [String]($env.Client + " - " + $env.Env), $lookup.Get_Item($env.Client).Get_Item($env.Env) )
         } Else {
            Throw $envValidate
         }
      }
   }

   End {
      Return $envsList
   }
}

Function Get-ServicePacksDefinition {
   Param (
         [Parameter(Mandatory=$false,ValueFromPipeLine,Position=0)]
         [PsCustomObject]$envConfig
         )

   Begin {
      $spDef = @{}
   }

   Process {
      If ([Boolean]$envConfig.ServicePacks) {
         $envConfig.ServicePacks | Foreach {
            $spDef.Add( $_.Release, @{ `
                  "StartDate" = $_.StartDate; "EndDate" = $_.EndDate; })
         }
      }
   }

   End {
      Return $spDef
   }
}

Function Compare-Env {
   Param (
         [Parameter(Mandatory=$true,Position=0)]
         [String]$client,
         [Parameter(Mandatory=$true,Position=1)]
         [String]$env,
         [Parameter(Mandatory=$true,Position=2)]
         [Hashtable]$lookup
         )
   Begin {
   }

   Process {
      If ($lookup.ContainsKey($client)) {
         If ($lookup.Get_Item($client).ContainsKey($env)) {
            $return = $true
         } Else {
            $return = "Client '$client' does not have environment '$env'."
         }
      } Else {
         $return = "Client '$client' is not a valid client."
      }
   }

   End {
      Return $return
   }
}

#EndRegion

Function Get-UserEmail {
   $searcher   = ([adsisearcher]"samaccountname=$env:USERNAME")
   $emailAddr  = $searcher.FindOne().Properties.mail
   Return $emailAddr
}
#Region Dates

Function Get-ValidScheduledRecipient {
   Param(
         [Parameter(Mandatory=$true,Position=0)]
         [PSCustomObject[]]$RecipientsScheduled,
         [Parameter(Mandatory=$true,Position=1)]
         [HashTable]$spDef
        )

   Begin {
      $Recipients = @()
      $dateMatch = "(\d{4}[\/-]\d{2}[\/-]\d{2}|\d{2}[\/-]\d{2}[\/-]\d{4})"
   }

   Process {
      Foreach ($_ in $RecipientsScheduled) {
         $isAdd = $false
         If ([Boolean]$_.ServicePack) {
            $_.ServicePack | Foreach {
               If (Test-DateInRange $spDef.Get_Item($_).StartDate $spDef.Get_Item($_).EndDate) {
                  $isAdd = $true
               }
            }
         } ElseIf ([Boolean]$_.Dates) {
            $_.Dates | Foreach {
               If (([Boolean]$_.StartDate) -and $_.StartDate -match $dateMatch) {
                  If (([Boolean]$_.EndDate) -and $_.EndDate -match $dateMatch) {
                     If (Test-DateInRange $_.StartDate $_.EndDate ) {
                        $isAdd = $true
                     }
                  } Elseif (([Boolean]$_.TimeSpan) -and $_.TimeSpan -match "(\d+)([WwDd])") {
                     If (Test-DateInRange $_.StartDate (Get-EndDate $_.StartDate $_.TimeSpan )) {
                        $isAdd = $true
                     }
                  }
               }
            }
         }
         If ($isAdd) {
            $Recipients += $_.Name + ' <' + $_.Email + '>'
         }
      }
   }

   End {
      Return $Recipients
   }
}

Function Get-EndDate {
   Param(
         [Parameter(Mandatory=$true,Position=0)]
         [String]$startDate,
         [Parameter(Mandatory=$true,Position=1)]
         [String]$timeSpan
        )

   Begin {
      $timeSpan -match "(\d+)([WwDd])" | Out-Null
      $length = $Matches[2].ToLower()
      $days = 0
   }

   Process {
      Switch ($length) {
         'd' {$days = $Matches[1]}
         'w' {$days = [Int]($Matches[1]) * 7}
         default {Throw "The timespan must be in the following format: m/\d+[WwDd]/."}
      }
   }

   End {
      Return (Get-Date(Get-Date(Get-Date $startDate).AddDays($days) -format 'yyyy-MM-dd'))
   }
}

Function Test-DateInRange {
   Param(
         [Parameter(Mandatory=$true,Position=0)]
         [String]$startDate,
         [Parameter(Mandatory=$true,Position=1)]
         [String]$endDate,
         [Parameter(Mandatory=$false,Position=2)]
         [String]$date = (Get-Date -Hour 0 -Minute 0 -Second 0 -Millisecond 0 -Format 'yyyy-MM-dd')
        )

   End {
      Return (((Get-Date $date) -ge (Get-Date $startDate)) -and `
            ((Get-Date $date) -le (Get-Date $endDate)))
   }
}

#EndRegion

Export-ModuleMember -Function * 
