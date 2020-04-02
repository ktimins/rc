<#
   .SYNOPSIS
      This script will check the recent ENFs generated and create and email and 
      CSV report for those dependant on the config file used.
      
   .DESCRIPTION
      This script is used to make emergency alerts when ENFs of a specific 
      exception message are generated. 
      
      This script uses a config file to set the parameters, in which, it will 
      check the ENFs. The config file is a JSON file. See attached 'enfrc.json' 
      file for an example config file and 'enfrc.comment.json' for a 
      commented version of the config for the explanation. 
      Note: Comments are not allowed in JSON and will not work for this script.

      If no config file name is passed into the file (via pipe or parameter), 
      the default of '.\enfrc.json' will be used. To only validate the config 
      file, run script with the '-validateOnly' flag. As well, a starting 
      directory can be passed in with '-startDir'. This is used for running the
      script via a scheduled task.

      For each of the environments in the config setting, it goes out to the 
      database and grabs a list of Triage ENFs that match the exception 
      message in the ENFSet. It then goes and gets the occurrence counts with 
      the timespan specified. If this number is greater than the threshold, it 
      will process the ENFs.

      If specified in the config under Output.File.Zips, it will grab the zips 
      for the ENFs. If Output.File.Save, then it will save those out to a 
      directory under the BaseDir directory. These will not be attached to the 
      email due to attachment size constraints.

      If specified in the config under Output.File.CSV, it will create a CSV 
      file with the information. If Output.File.Save, it will save the CSV 
      files out to a directory under the BaseDir directory. If Output.Email.
      Attachment, it will attach the CSV files to the email when it sends it.

      Besides the CSV files and ENF Zips, the main output of this file is an
      email that is sent to the user who ran the script and any emails that are
      listed in the Output.Email.Recipient array in the config file. The email
      consists of two sections. 
      
      First is the summary which displays the environment and the ENF set name. 
      As well, it shows the timespan, total occurrence counts and triage 
      ENFs that occurred for that set, along with the exception messages used 
      for that set. The environment and ENFSet names are hyperlinks that will
      bring you down to the detail section for that set, if it exists.

      Second is the detail section, which is dictated by the ENFSets.NAME.Email
      section of the config. This section shows the Triage GUID (ENF), Count of
      that Triage ENF, the status of the ENF, the CSR linked to the ENF (if it 
      exists), the exception message, and the stack trace of the Triage ENF. As
      well, it includes a link to the latest zip (as of running the script).
      
   .NOTES
      This requires Powershell 3.0 or later to run.

      This script relies on adoLib.psm1 to function correctly. Please make 
      sure the file is in either in the same location as the script or in a 
      folder called "Modules" in the same directory.  As well, adoLib.psm1 can 
      be loaded into Powershell before calling the script.

   .INPUTS
      A string containing the filename for the config file can be piped into 
      this script.

   .OUTPUTS
      There are no direct outputs of this file. However, three possible things 
      can happen as a "side effect" of this script.
         1. The ENF Zips for each Triage ENF found. (Dependant on the config 
            setting of Output.File.Zips and within the ENFSets.)
         2. CSRs containing the information for each Triage ENF found. (
            Dependant on the config setting of Output.File.CSV.)
         3. An email containing the information for the Triage ENFs found. 
            This can also include the CSVs created.

      Detail section of the email will look like this:

      +----------------------+------------------+------------------+----------------+
      |          ENF         |       Count      |      Status      |      CSR       |
      +----------------------+------------------+------------------+----------------+
      | xxxxxxx-xxxxxx-xxxxx | 10               | Re-Opened        | 1234567        |
      +----------------------+------------------+------------------+----------------+
      |                      |                                                      |
      |  Exception Message   |  This is a sample exception message text.oienarsti   |
      |                      |                                                      |
      +----------------------+------------------------------------------------------+
      |                      |  This is a sample stack trace                        |
      |     Stack Trace      |     at noieanrstehoarsheioharieoshtars               |
      |                      |     at jyuhuahrstuynuy;aj lahtuyhuhlhntaor           |
      +----------------------+------------------------------------------------------+
      |      Latest Zip      |  FTP://10.0.0.123/here/are/the/zip/files/arst.zip    |
      +----------------------+------------------------------------------------------+
      |      ENF Notes       |  [AA 2016-06-01] This is because of...               |
      +----------------------+------------------------------------------------------+

   .COMPONENT
      This script depends upon the adoLib.psm1 module. This module must either 
      be loaded into Powershell or included in the same directory (or in a 
      directory called Modules). adoLib is used for the SQL lookups.

   .PARAMETER configFile
      This is the config file that will be used by the script. By default, 
      this is set to "enfrc.json" in the same directory as this script. It can 
      be passed in via Pipe, defined parameter, or in position 0.

   .PARAMETER startDir
      This is the starting directory for the script. Be default, it will run 
      in the same directory as it is called.  However, when running from a 
      Scheduled Task, Powershell does not start in the directory specified, so 
      a Set-Location in the script is necessary. The starting directory is 
      the directory where the config file and the adoLib.psm1 file exist in.

   .PARAMETER envConfigFile
      This is the environmental config file that will be used to pass in environmental
      settings to the file. These would in enclude things like Service Pack definitions,
      Database sever, SMTP server, etc... By default, this is set to "envrc.json" in the
      same directory as the script. It can be passed in a defined parameter or in 
      position 2

   .PARAMETER validateOnly
      This flag allows you to validate the config setting without running any 
      of the actual ENF processing.

   .EXAMPLE
      Get-ENFAlerts.ps1

      Run using the standard config file

   .EXAMPLE
      Get-ENFAlerts.ps1 -startDir "C:\Users\USERNAME\ENF\Scripts"

      Specifying the starting directory of the script.
      NOTE: The name and directory must be wrapped in single or double quotes. 

   .EXAMPLE
      "configFile.json" | Get-ENFAlerts.ps1
      
      Use a differently named (or in a different directory) config file than 
      "enfrc.json" using a pipe. 
      NOTE: The name must be wrapped in single or double quotes. 

   .EXAMPLE
      "configFile.json" | Get-ENFAlerts.ps1 -envConfigFile "environmental.json"

      Use a differenty named (or in a different directory) config file than
      "enfrc.json" using a pipe and "envrc.json" using a defined parameter.
      NOTE: Thes name must be wrapped in a single or double quotes.

   .EXAMPLE
      "configFile.json" | Get-ENFAlerts.ps1 "C:\Users\USERNAME\ENF\Scripts"

      Using a differently named config file using a pipe and specifying the 
      starting directory.
      NOTE: The name and directory must be wrapped in single or double quotes. 

   .EXAMPLE
      Get-ENFAlerts.ps1 -configFile "configFile.json"

      Use a differently named (or in a different directory) config file than 
      "enfrc.json" using a parameter. 
      NOTE: The name must be wrapped in single or double quotes. 

   .EXAMPLE
      Get-ENFAlerts.ps1 -envConfigFile "environmental.json"

      Use a differently named environmental config file using a defined parameter.
      NOTE: The name must be wrapped in single or double quotes.

   .EXAMPLE
      Get-ENFAlerts.ps1 "configFile.json" "C:\Users\USERNAME\ENF\Scripts"

      Using a differently named config file and starting directory using 
      positional parameters.
      NOTE: The name and directory must be wrapped in single or double quotes. 

   .EXAMPLE
      "configFile.json" | Get-ENFAlerts.ps1 -validateOnly

      Validate the config file using a differently named (or in a different 
      directory) config file than "enfrc.json" using a pipe.
      NOTE: The name must be wrapped in single or double quotes.

#>

#Requires -Version 3

Param(
      [Parameter(Mandatory=$false,ValueFromPipeline=$true,Position=0)]
      [String]$configFile = ".\enfrc.json",
      [Parameter(Mandatory=$false,Position=1)]
      [String]$startDir = ".",
      [Parameter(Mandatory=$false,Position=2)]
      [String]$envConfigFile = ".\envrc.json",
      [Parameter(Mandatory=$false,Position=3)]
      [Switch]$validateOnly = $false,
      [Parameter(Mandatory=$false)]
      [Switch]$Passwd
     )

Process {

   #Region Process Config

   If (-not $Passwd) {

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Getting the config files."
      }

      Try {
         $config = Get-Config $configFile 
      } Catch {
         Throw "Config File '$configfile' is not of the correct JSON format. " +
         "Please ensure that it is vaild JSON and it exists."
      }

      Try { 
         $envConfig = Get-Config $envConfigFile
      } Catch {
         Throw "Environment Config File '$envConfigFile' is not of the correct JSON format. " +
         "Please ensure that it is valid JSON and it exists."
      }

      If ([Boolean]$config.Output.Email.RecipientsScheduled) {
         $spDef = Get-ServicePacksDefinition $envConfig
      }

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (0)
      } Else {
         "Parsing Config Files" | Write-Verbose
      }

      $errorVar = $False

      $SMTPServer = Get-SmtpServer $envConfig
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (10)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $DBServer = Get-DBServer $envConfig

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (20)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $EnvsList = Get-EnvsList -config $config -envConfig $envConfig
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (30)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $ENFSets = Get-EnfSet -config $config
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (40)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $File = Get-File -config $config
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (50)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $EmailCfg = Get-Email -config $config -spDef $spDef
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (60)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $ENFPortfolios = Get-ENFPortfolio -config $config
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (70)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $ENFSkippedPortfolios = Get-ENFSkippedPortfolio -config $config
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (80)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $ENFSkippedStatuses = Get-ENFSkippedStatus -config $config
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (90)
      }
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      $ENFLobs = Get-ENFLOB -config $config
      $errorVar = @{$true=$errorVar;$false=$true}[$? -eq $true]
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Parsing the config files." -PercentComplete (100)
      }

      If (-not( Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Validating Config Files"
      }

      If ($validateOnly) {
         If ($errorVar -eq $false) {
            "Config file '$configFile' has been validated sucessfully." | Write-Host
         }
         Exit
      }

      If (-not( Get-VerboseStatus)) {
         Write-Progress -Activity "Config Files" -Status "Config files imported." -Completed
      } Else {
         "Config files imported" | Write-Verbose
      }


      #EndRegion


      #Region Set Variables

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Setting Variables"
      } Else {
         "Setting up System Variables" | Write-Verbose
      }

      $doEmail = @{$true=$true;$false=$false}[[Boolean]($config.Output.Email) -eq $true]
      $dlZips = @{$true=$true;$false=$false}[$File.Zips -eq $true]
      $suffix = @{$true=$File.Suffix;$false=""}[[Boolean]($config.Output.File.Suffix) -eq $true]
      $nowDate = [String](Get-Date -format 'yyyy-MM-dd_HH-mm')
      "NowDate: " + $nowDate | Write-Verbose

      $meetEmailThreshold = $false

      $outSets = @()

      $baseDir = $config | Get-BaseDir
      $DoCSRStatus = $config | Get-CSRStatus
      $outDir = "$baseDir\Output-$suffix"
      $zipDir = "$baseDir\Zips"

      $PPMVariables = Get-PPMVariables

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Setting Variables" -Completed
      }
   }

   #RegionEnd

   #Region Password Configuration

      If ($DoCSRStatus -or $Passwd) {

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Getting Password for CSR info lookup." -Status "Trying password file."
         } Else {
            "Getting Password for CSR info lookup." | Write-Verbose
         }

         ## Set the location of the password file.
         $PasswdFileLocation = 'C:\Files\Password.txt'

         ## If the user is resetting their password.
         If ($Passwd) {
            Try {
               ## Set the password.
               Set-PasswdFile $PasswdFileLocation ([Environment]::UserName)
               ## Exit.
               Exit
            } Catch { 
               ## Shouldn't hit.
               Exit
            }
         }

         Try {
            ## Try to get the password from the password file
            $Password = Get-PasswdFile $PasswdFileLocation ([Environment]::UserName)
            If (-not (Test-ADCredentials ([Environment]::UserName) (ConvertTo-UnsecureString $Password) "INS")) {
               ## If the password is not correct for the user based on a lookup in AD, Set the password to blank.
               $Password = ""
            }
         } Catch { }

         ## If we failed to get the password
         If (-not $Password) {
            Try {
               ## Reset the password
               Set-PasswdFile $PasswdFileLocation ([Environment]::UserName)
               ## Get the password
               $Password = Get-PasswdFile $PasswdFileLocation ([Environment]::UserName)
            } Catch {
               Exit
            }
         }

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Getting Password for CSR info lookup." -Status "Password Got!" -Completed
         } Else {
            "Password Got!" | Write-Verbose
         }

      }

   #EndRegion

   #Region Main

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Opening IE Instance" 
      } Else {
         "Opening IE Instance" | Write-Verbose
      }

      mkdir "$outDir" -ErrorAction SilentlyContinue | Out-Null

      ## Are we getting the status of CSRs in this run?
      If ($DoCSRStatus) {
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Opening IE Instance" -Status "Opening IE instance for CSR information lookups."
         } Else {
            "Opening IE Instance for CSR information lookups." | Write-Verbose
         }

         ## Get an instance of IE
         $IEInstance = Get-IEInstance 

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Opening IE Instance" -Status "Trying to open PPM Dashboard."
         } Else {
            "Trying to open PPM Dashboard." | Write-Verbose
         }

         ## Try to get to the PPM Dashboard
         $PageStatus = Set-URL $IEInstance ($PPMVariables.Dash_URL)

         If (-not $PageStatus) {
            Throw "Something is happeninp with PPM. Unable to connect."
         }
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Opening IE Instance" -Status "Logging into PPM."
         } Else {
            "Logging into PPM." | Write-Verbose
         }

         ## Log into PPM if we hit the PPM Login page
         Set-PPMLogin $IEInstance ([Environment]::UserName) $Password $PPMVariables.LoginFields

         ## Reset the password variable
         $Password = ""

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Opening IE Instance" -Completed
         }
      }



      ## Foreach environment in the enfrc config
      $EnvsList.GetEnumerator() | Foreach {
         ## Get the pertinent information
         $_.Name -match '(\w+) - (\w+)' | Out-Null
         $client  = $Matches[1]
         $env     = $Matches[2]
         $sqlDBName  = $_.Value

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Getting ENFs for $client / $env."
         } Else {
            "Getting ENFs for $client / $env." | Write-Verbose
         }

         ## Foreach of the ENF sets in the enfrc config
         Foreach ($enfSet in $ENFSets) {
            ## Get the information that was inputted on the config
            $name       = $enfSet.Name
            $time       = $enfSet.Time
            $zips       = $enfSet.Zips
            $exMsgs     = $enfSet.ExMsgs
            $notExMsgs  = $enfSet.NotExMsgs
            $orderBy    = $enfSet.Email.OrderBy
            $emailObj   = $enfSet.Email


            If (-not (Get-VerboseStatus)) {
               Write-Progress -Activity "Getting ENFs for $client / $env." -Status "Getting ENFs for group $name."
            } Else {
               "Getting ENFs for $client / $env. - Getting ENFs for group $name" | Write-Verbose
            }

            ## Set the fields used in the triage fields lookup
            $triageFields = @( "GUID", "ExceptionMessage", "Status", "CSR", "StackTrace", `
                               "AlertZipFilePathLatest", "AlertZipFilePath", "Comments", "Severity" )
            
            ## Lookup the triage ENFs information from the database
            $triageDataSet = Get-TriageEnfInfo $exMsgs $time $sqlDBName $enfPortfolios $enfSkippedStatuses $ENFLobs $triageFields $notExMsgs $ENFSkippedPortfolios $orderBy
            $triageDataSet.Tables.Rows | Out-String | Write-Verbose
            
            ## Create the set object for the Client-Env-ENFSet
            $setObj = New-Object -TypeName PSObject -Prop @{  `
               "Client"       = $client;  `
               "Env"          = $env;     `
               "SetName"      = $name;    `
               "Time"         = $time;    `
               "ExMsgs"       = $exMsgs;  `
               "TriageCount"  = 0;        `  
               "TotalCount"   = 0;        `
               "EnfMinCount"  = $enfSet.MinCount;  `
               "Threshold"    = $emailObj.Threshold; `
               "IncStack"     = [Boolean]$emailObj.Stack;   `
               "ShowDetail"   = [Boolean]$emailObj.Details;       `
               "IncNotes"     = [Boolean]$emailObj.IncNotes;`
               "IncEmptyNotes"= [Boolean]$emailObj.EmptyNotes; `
               "IncLatestInfo"= [Boolean]$emailObj.IncLatestInfo;`
               "DoCSRStatus"  = [Boolean]$DoCSRStatus; `
               "ENFs"         = @();      `
            }


            If ($triageDataSet.Tables.Rows.Count -gt 0) {
               ## Set up variables for use in the progress bar
               $i = 1
               $setObj.TriageCount = $triageDataSet.Tables.Rows.Count
               Foreach ($row in $triageDataSet.Tables[0].Rows) {
                  ## If we have rows in the dataset
                  If (-not (Get-VerboseStatus)) {
                     Write-Progress -Activity "Getting ENFs for $client / $env." -Status "Getting ENFs for group $name. - GUID {$($row[$triageFields[0]])}" -PercentComplete (($i++ / $triageDataSet.Tables.Rows.Count) * 100)
                  }
                  ## Get the information from the dataset
                  $triageGuid    = $row[$triageFields[0]]
                  $triageExMsg   = $row[$triageFields[1]]
                  $triageStatus  = $row[$triageFields[2]]
                  $triageCsr     = $row[$triageFields[3]]
                  $triageStack   = $row[$triageFields[4]]
                  If (-not([String]::IsNullOrEmpty($row[$triageFields[5]]))) {
                     $triageZip  = $row[$triageFields[5]]
                  } Else {
                     $triageZip  = $row[$triageFields[6]]
                  }
                  $triageNotes   = $row[$triageFields[7]]
                  $triageSeverity= $row[$triageFields[8]]
                  $triageCount   = $row

                  ## Set the lookup variables frot he occurrence database lookup
                  $occurFields = @( 'CustomerId', 'CustomerCd', 'BuildVersion', 'UserId', 'UserName', `
                        'MessageCreatedDate', 'PathTableId', 'ServiceLobCd', 'EnvironmentLabel', 'SAN' )

                  ## Perform the occurrence database lookup to get the latest information
                  $occurInfoDataSet = Get-OccurrenceLatestInfo $triageStack $sqlDBName $occurFields
                  $occurInfo = @{}
                  $occurInfoDataSet.Tables.Rows | Out-String | Write-Verbose
                  $occurDataRow = $occurInfoDataSet.Tables[0].Rows[0]

                  ## Convert to a PSCustomObject for some reason. Not really sure why I did this, but it works, so it stays.
                  $occurDataRow.Table.Columns | Foreach {$occurInfo=[ordered]@{}} `
                                                        {$occurInfo.Add($_.ColumnName, $occurDataRow[$_])} `
                                                        {[PSCustomObject]$occurInfo | Write-Verbose}

                  If ($zips -and $dlZips) {
                     ## If doing zips, get the zip groups
                     Get-ZipGroup $baseDir $zipDir $triageGuid $sqlDBName $nowDate $suffix $time $zips
                  }
                  
                  ## Get the occurrence count for the Triage ENF
                  $occurDataSet  = $triageStack | Get-OccurrenceCount -Count $time -sqlDBName $sqlDBName
                  $CSRData = @{}
                  ## If the count is greater than the minimum count
                  If ($occurDataSet.Tables.Rows.Column1 -ge $enfSet.MinCount) {
                     ## If we have occurrences
                     If ($occurDataSet.Tables.Rows.Column1 -gt 0) {
                        $occurCount = $occurDataSet.Tables.Rows.Column1
                        $setObj.TotalCount += $occurCount
                     }
                     ## If we are getting the CSR status information from PPM
                     If ($triageCsr -and $DoCSRStatus) {

                        "Navigating to PPM page for CSR#$triageCsr." | Write-Verbose

                        ## Navigate to the CSR PPM page
                        $PageStatus = Set-URL $IEInstance "$($PPMVariables.CSR_URL)$triageCsr"

                        If (-not $PageStatus) {
                           Throw "Something is happening with PPM. Unable to connect."
                        }

                        "Striping data from PPM page for CSR#$triageCsr." | Write-Verbose
                        ## Get data from the PPM Page
                        $CSRData = Get-CSRData $IEInstance $PPMVariables.CSRPageFields (New-Object -TypeName PSObject -Property @{"CSR" = $triageCsr;})
                     }

                     ## Create the object for holding the ENF information
                     $setObj.ENFs += New-Object -TypeName PSObject -Prop @{ `
                        "ENF"          = $triageGuid;             `
                        "Counts"       = $occurCount;             `
                        "Status"       = $triageStatus;           `
                        "CSR"          = $triageCsr;              `
                        "CSRStatus"    = $CSRData.CSRStatus;      `
                        "CSRResSP"     = $CSRData.ReleaseSP;      `
                        "CSRResDate"   = $CSRData.ReleaseDate;    `
                        "ExMsg"        = $triageExMsg;            `
                        "Stack"        = $triageStack;            `
                        "ZipPathLast"  = $triageZip;              `
                        "Zips"         = $zips;                   `
                        "ENFNotes"     = $triageNotes;            `
                        "Severity"     = $triageSeverity;         `
                        "Threshold"    = $emailObj.Threshold;     `
                        "CustId"       = $occurInfo.CustomerId;   `
                        "CustCd"       = $occurInfo.CustomerCd;   `
                        "BuildVersion" = $occurInfo.BuildVersion; `
                        "UserId"       = $occurInfo.UserId;       `
                        "UserName"     = $occurInfo.UserName;     `
                        "MsgCreatedDt" = $occurInfo.MessageCreatedDate;`
                        "PathTableId"  = $occurInfo.PathTableId;  `
                        "ServiceLobCd" = $occurInfo.ServiceLobCd; `
                        "EnvLabel"     = $occurInfo.EnvironmentLabel;`
                        "LatestSan"    = $occurInfo.SAN;          `
                     }
                  } Else {
                     ## If the occurrence count is not equal to or greater than the minimum count, decrement the triage count.
                     $setObj.TriageCount--
                  }

               }
               ## Determine if we should send the email.
               If ($setObj.TotalCount -ge $setObj.Threshold) {
                  $meetEmailThreshold = $true
                  "Email Threshold met." | Write-Verbose
               }
            }

            ## Determine if we should send the email.
            If ($setObj.Threshold -eq 0 -and $meetEmailThreshold -eq $false) {
               $meetEmailThreshold = $true
               "Email Threshold met." | Write-Verbose
            }

            ## Add the ENF object to the array of objects
            $outSets += $setObj

         }
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Getting ENFs for $client / $env." -Completed
         }
      }

      If ($DoCSRStatus) {
         ## Close the IE instance
         Try {
            $IEInstance.Quit()
         } Catch {
         }
      }

   #EndRegion
}

End {
   #Region File Output

      $filesCreated = $false
      $date = @{$true="-$nowDate";$false=""}[$File.AppendDate -eq $true]

      If ($File.CSV -or $File.JSON -or $File.XML) {
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Creating files"
         } Else {
            "Creating files" | Write-Verbose
         }
         Foreach ( $set in $outSets ) {
            $name = $set.Client + "-" + $set.Env + "-" + $set.SetName
            If (-not (Get-VerboseStatus)) {
               Write-Progress -Activity "Creating files" -Status "Creating files for $name."
            } Else {
               "Creating files for $name." | Write-Verbose
            }
            $data = $set.ENFs | Create-DataSet
            $Filename = "$outDir\$name-$suffix"
            If ($data) {
               If ($File.CSV) {
                  "CSV file - $name" | Write-Verbose
                  $data | Export-Csv -Path "$Filename.csv" -NoTypeInformation -Delimiter ','
                  $filesCreated = $true
               }
               If ($File.JSON) {
                  "JSON file - $name" | Write-Verbose
                  $data | ConvertTo-Json -depth 999 | Out-File ( "$Filename.json" )
                  $filesCreated = $true
               }
               If ($File.XML) {
                  "XML file - $name" | Write-Verbose
                  $data | ConvertTo-Xml -as String -Depth 999 -NoTypeInformation | Out-File ( "$Filename.xml" )
                  $filesCreated = $true
               }
            } 
         }
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Creating files" -Completed
         }
      }

   #End Region

   #Region Email

      If ($doEmail -and $meetEmailThreshold) {
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Email" -Status "Getting Attachments"
         } Else {
            "Getting Email Attachments" | Write-Verbose
         }

         $attachments = @()
         If ($EmailCfg.Attachment -eq $true) {
            Get-ChildItem -Recurse -Path $outDir | Where {$_.Extension -match "\.(csv|json|xml)"} | Foreach {
               $attachments += $_.Fullname
            }
         }

         ($outSets | Select-Object TotalCount) | Write-Verbose
         $allTotalCount = 0
         $outSets | Foreach {
            $allTotalCount += $_.TotalCount
         }

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Email" -Status "Creating Email."
         } Else {
            "Creating Email" | Write-Verbose
         }

         If ($allTotalCount -eq 0) {
            $emailBody = Create-EmailBodyEmpty -sets $ENFSets
         } Else {
            $emailBody = Create-EmailBody -sets $outSets
         }

         $subject = Substitute-Subject -subject $EmailCfg.Subject -NowDateTime $NowDate

         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Email" -Status "Sending Email."
         } Else {
            "Sending Email." | Write-Verbose
         }

         Send-Email -to $EmailCfg.Recipient -cc $EmailCfg.cc -subject $subject -body $emailBody -files $attachments -smtpSrv $SMTPServer
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Email" -Completed
         }
      }

   #End Region

   #Region Save or Delete Local Files

      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Dealing with local files."
      } Else {
         "Dealing with local files" | Write-Verbose
      }

      If ($File.Save -and $filesCreated) {
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Dealing with local files." -Status "Moving local files."
         } Else {
            "Moving Local Files." | Write-Verbose
         }

         $dest = "Files-$suffix-$nowDate"
         $saveDir = "$basedir\$nowDate-$suffix\$dest"
         If (-not (Test-Path $savedir)) {
            New-Item -ItemType directory -Path $saveDir -ErrorAction SilentlyContinue | Out-Null
         }
         Move-Item -Path $outDir -Destination $saveDir -ErrorAction SilentlyContinue | Out-Null
      } Else {
         If (-not (Get-VerboseStatus)) {
            Write-Progress -Activity "Dealing with local files." -Status "Deleting local files."
         } Else {
            "Deleting Local Files." | Write-Verbose
         }
         Remove-Item $outDir -Force -Recurse
      }
      If (-not (Get-VerboseStatus)) {
         Write-Progress -Activity "Dealing with local files." -Completed
      }

   #End Region
}

Begin {

   #Region Set Starting Directory
      
      Set-Location $startDir

   #EndRegion

   #Region Load needed modules

      If (Get-Module -ListAvailable -Name adoLib) {
         Import-Module adoLib
      } ElseIf (Test-Path "$PSScriptRoot\adoLib.psm1") {
         Import-Module $PSScriptRoot\adoLib.psm1
      } ElseIf (Test-Path "$PSScriptRoot\Modules\adoLib.psm1") {
         Import-Module $PSScriptRoot\Modules\adoLib.psm1
      } Else {
         Throw "Unable to find the 'adoLib.psm1' module. `nPlease make sure it is either in the same directory as this script or in a folder named 'Modules' under this directory."
      }

   #EndRegion

   #Region Set environmental variables

      Function Get-EnvLookup {
         <#
            .SYNOPSIS
            Get the valid Environments from the environmental config file and match them up with the 
            SQL database associated with it.

            .DESCRIPTION
            This function takes in the environmental config object and pulls out the clients,
            along with their environments and the database table that stores its ENFs.

            .PARAMETER envConfig
            This is a custom object that holds the environmental config information.

            .OUTPUT
            A hashtable of hashtables in the setup of @{ Client = @{ Environment = SQLTable } }.
         #>
         Param(
               [Parameter(Mandatory=$true,Valuefrompipeline=$true,Position=0)]
               [PSCustomObject]$envConfig
              )
         Begin {
            $envLookup = $envConfig.EnvLookup
            $return = @{}
         }

         Process {
            $envLookup | Foreach {
               $set = @{}
               $_.ENVs | Foreach {
                  $set.Add( $_.Name, $_.SQLDB )
               }
               $return.Add( $_.Client, $set )
            }
         }

         End {
            Return $return
         }
      }

      Function Get-SmtpServer {
         <#
            .SYNOPSIS
            Get the SMTP server from the environmental config file.

            .DESCRIPTION
            Get the SMTP server from the environmental config file.

            .PARAMETER envConfig
            This is a custom object that holds the environmental config information.

            .OUTPUT
            A string holding the SMTP server path.
         #>
         Param(
               [Parameter(Mandatory=$true,Valuefrompipeline=$true,Position=0)]
               [PSCustomObject]$envConfig
              )
         Return $envConfig.SMTPServer
      }

      Function Get-DBServer {
         <#
            .SYNOPSIS
            Get the Database server name from the environmental config file.

            .DESCRIPTION
            Get the Database server name/path from the environmental config file.

            .PARAMETER envConfig
            This is a custom object that holds the environmental config information.

            .OUTPUT
            A string holding the database server path.
         #>
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
               [PSCustomObject]$envConfig
              )
         Return $envConfig.DBServer
      }

      Function Get-TimeSpan {
         <#
            .SYNOPSIS
            Ensure that the timespan matches the desired format and that it is valid.

            .DESCRIPTION
            It takes a string with a timespan and verifies that it is a valid timespan. If it is not,
            it replaces the value with the default value and returns that.

            .PARAMETER TimeSpan
            A string that contains a timespan value in the format of:
               m/\d+[MmHhDd]/

            .OUTPUT
            A string containing a valid timespan value.
         #>
         Param(
               [Parameter(Mandatory=$false,ValueFromPipeline=$true,Position=0)]
               [String]$TimeSpan
              )

         $default = "2h"
         If ( -not [Boolean]$TimeSpan -or -not($TimeSpan -match "\d+[MmHhDd]")) { 
            $TimeSpan = $default
         }
                  
         Return $TimeSpan
      }

   #EndRegion

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
            If ([Boolean]($fileCfg.JSON)) {
               If ($fileCfg.JSON -is [Boolean]) {
                  $file.Add( "JSON", $fileCfg.JSON )
               } Else {
                  Throw "Output.File.JSON must be a boolean."
               }
            } Else {
               $file.add( "JSON", $false )
            }
            If ([Boolean]($fileCfg.XML)) {
               If ($fileCfg.XML -is [Boolean]) {
                  $file.Add( "XML", $fileCfg.XML )
               } Else {
                  Throw "Output.File.XML must be a boolean."
               }
            } Else {
               $file.add( "XML", $false )
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

      Function Get-CSRStatus { 
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
               [PSCustomObject]$config
               )
         $GetCSRStatus = $false
         If ([Boolean]($config.GetCSRStatus)) {
            $GetCSRStatus = $config.GetCSRStatus
         }
         Return $GetCSRStatus

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
               $config.ENFSets | Foreach {
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
                        If ($_ -match "'") {
                           Throw "Please remove all single quotes from exception messages in ENFSets." + $_.ExMsgs.Name + "."
                        } ElseIf ($_ -match '--') {
                           Throw "Please remove all double hyphens '--' from exception messages in ENFSets." + $_.ExMsgs.Name + "."
                        }
                     }
                     $set.Add( "ExMsgs", $enfSet.ExMsgs )
                  } Else {
                     Throw $enfSet.Name + " is missing Exception Messages."
                  }
                  If ([Boolean]($enfSet.NotExMsgs)) {
                     $enfSet.NotExMsgs | Foreach {
                        If ($_ -match "'") {
                           Throw "Please remove all single quotes from exception messages in ENFSets." + $_.ExMsgs.Name + "."
                        } ElseIf ($_ -match '--') {
                           Throw "Please remove all double hyphens '--' from exception messages in ENFSets." + $_.ExMsgs.Name + "."
                        }
                     }
                     $set.Add( "NotExMsgs", $enfSet.NotExMsgs )
                  }
                  If ([Boolean]($enfSet.MinCount)) {
                     If ($enfSet.MinCount -is [Int]) {
                        $set.Add( "MinCount", [Math]::Abs($enfSet.MinCount) )
                     } Else { 
                        Throw "ENFSets.$($enfSet.MinCount).MinCount is not a numeric value."
                     }
                  } Else {
                     $set.Add( "MinCount", 1 )
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
                     If ([boolean]($enfSet.Email.OrderBy)) {
                        If ($enfSet.Email.OrderBy -match "^date|count$") {
                           $email.Add( "OrderBy", $enfSet.Email.OrderBy )
                        } Else {
                           Throw "ENFSets." + $enfSet.Name + ".Email.OrderBy must be either 'date' or 'count'."
                        }
                     } Else {
                        $email.Add( "OrderBy", "date" )
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

      Function Get-ENFSkippedPortfolio {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
               [PSCustomObject]$config
              )
         Begin {
            $enfSkippedPortfolioSet = @()
         }

         Process {
            If ([Boolean]$config.ENFSkippedPortfolio) {
               $enfSkippedPortfolioSet = $config.ENFSkippedPortfolio
            }
         }

         End {
            Return $enfSkippedPortfolioSet
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

   #Region Zips

      Function Add-Zip {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
               [String]$zipfilename,
               [Parameter(Mandatory=$true)]
               [String[]]$filesToZip
              )
         If (-not (Test-Path($zipfilename))) {
            Set-Content $zipfilename ("PK" + [char]5 + [char]6 + ("$([char]0)" * 18))
            (dir $zipfilename).IsReadOnly = $false	
         }
   
         $shellApplication = New-Object -com shell.application
         $zipPackage = $shellApplication.NameSpace($zipfilename)
         Foreach ($file in $filesToZip) { 
            Try {
               $zipPackage.CopyHere($file)
               While (($zipPackage.Items() | Where-Object { $_.Name -like $file.Split("\")[-1] }).Size -lt 1) { Start-Sleep -m 100 };
            } Catch { }
         }
      }
   
      Function Get-ZipGroup {
         Param(
               [Parameter(Mandatory=$true,Position=1)]
               [String]$filePath,
               [Parameter(Mandatory=$true,Position=2)]
               [String]$outDir,
               [Parameter(Mandatory=$true,Position=3)]
               [System.GUID]$guid,
               [Parameter(Mandatory=$false,Position=4)]
               [String]$sqlDBName = [String](Get-DBName),
               [Parameter(Mandatory=$false,Position=5)]
               [String]$nowDate = [String](Get-Date -format 'yyyy-MM-dd_HH-mm'),
               [Parameter(Mandatory=$false,Position=6)]
               [String]$suffix = "",
               [Parameter(Mandatory=$false,Position=7)]
               [String]$timeFrame = '2h',
               [Parameter(Mandatory=$false,Position=8)]
               [String]$count = '5l'
              )
   
         Begin {
            $guidFilePath = "$filePath\$guid"
            New-Item -Path $guidFilePath -Type Directory -ErrorAction SilentlyContinue | Out-Null
   
            $WebClient = New-Object System.Net.WebClient
            $zips = @()
         }
         Process {
            $dataSet = $guid | Get-TriageZips $sqlDBName $count $timeFrame
            Foreach ($row in $dataSet.Tables[0].Rows) {
               $zipName = $row.Item(0)
               $splitChar =  @{$true="\";$false="/"}[$zipName.StartsWith("\\")]
               $fileName = $zipName.Split($splitChar)[-1]
               Try {
                  if ($zipName.StartsWith("\\")) {
                     cp -Path $zipName -Destination "$guidFilePath\$filename" -ErrorAction SilentlyContinue
                  } else {
                     $WebClient.DownloadFile($zipName, "$guidFilePath\$filename")
                  }
                  $zips += "$guidFilePath\$filename"
               } Catch { }
            }
         }
         End {
            $WebClient.Dispose()
   
            New-Item -Path "$filePath\$nowDate-$suffix\Zips" -Type Directory -ErrorAction SilentlyContinue | Out-Null
            "$filePath\$nowDate-$suffix\Zips\$guid.zip" | Add-Zip -filesToZip $zips
            Remove-Item $guidFilePath -Force -Recurse
         }
      }

   #EndRegion

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
               'w' {$days = [Int]$Matches[1] * 7}
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

   #Region Email

      Function Get-UserEmail {
         $searcher   = ([adsisearcher]"samaccountname=$env:USERNAME")
         $emailAddr  = $searcher.FindOne().Properties.mail
         Return $emailAddr
      }

      Function Create-EmailBodyEmpty {
         Param(
               [Parameter(Mandatory=$true,Position=0)]
               [PSCustomObject[]]$sets
              )

         Begin {
            $email  = "<h1>Summary</h1>`n"
            $email += "<p>There are no new ENFs for the following ENF sets:</p>"
         }

         Process {
            $sets | Foreach {
               $email += "<p>Set: " + $_.Name + "<br />`n"
               For ($i = 0; $i -lt $_.ExMsgs.Count; $i++) {
                  $email += "'" + $_.ExMsgs[$i] + "'<br />`n"
               }
               $email += "</p>`n"
            }

         }

         End {
            $email += "<br /><br />`n"
            $email += "<p>This message has been autogenterated by the ENF Emergency Alerts Monitoring tool.</p>"
            Return $email
         }
      }
      
      Function Create-EmailBody {
         Param(
               [Parameter(Mandatory=$true,Position=0)]
               [PSCustomObject[]]$sets
              )

         Begin {
            $clientKeep, $setNameKeep, $envKeep = "","",""
            $email    = "<h1>The ENF Tool</h1>`n"
            $email   += "<p>The ENF Tool can be found at <a href=`"\\filer01\DailyBuilds\LOGS\FTP\Consolidated_Alerts\EnterpriseNotifications.exe`">EnterpriseNotifications.exe<a> from within the Insurity network.</p>`n"
            $email   += "<h1>Summary</h1>`n"
            $email   += Create-EmailBodySummary $sets 
            $email   += "<h1>Details</h1>`n"
         }
   
         Process {
            $sets | Foreach {
               If ($_.ShowDetail -and $_.TotalCount -ge $_.Threshold) {
                  $client = $_.Client
                  $env = $_.Env
                  If ($client -ne $clientKeep -or $env -ne $envKeep) {
                     $setNameKeep = ""
                     $email   += "<a name=`"$client - $env`"><h1>ENV: $client - $env</h1></a>`n"
                  }
                  $envKeep = $env
                  $clientKeep = $client
                  $setName = $_.SetName
                  $_.Time -match '(\d+)([mhd])' | Out-Null;
                  $timeAmt = $Matches[1]
                  $timeSpan = @{"m" = "minute"; "h" = "hour"; "d" = "day"}[$Matches[2]]
                  $plural = @{$true = "s";$false = ""}[$timeAmt -gt 1]
                  if ($setName -ne $setNameKeep) {
                     $email   += "<a name=`"$client - $env - $setName`"><h2>Set: $setName</h2></a>`n"
                     $email   += "<p>Counts are for the last $timeAmt $timeSpan$plural.</p>`n"
                  }
                  $setNameKeep = $setName


                  If ($_.PSObject.Properties.Match('IncStack')) {
                     [Boolean]$includeStack = $_.IncStack
                  } Else {
                     [Boolean]$includeStack = $false
                  }
                  If ($_.PSObject.Properties.Match('IncNotes')) {
                     [Boolean]$includeNotes = $_.IncNotes
                  } Else {
                     [Boolean]$includeNotes = $false
                  }
                  If ($_.PSObject.Properties.Match('IncLatestInfo')) {
                     [Boolean]$includeLatestInfo   = $_.IncLatestInfo
                  } Else {
                     [Boolean]$includeLatestInfo   = $false
                  }
                  If ($_.PSObject.Properties.Match('DoCSRStatus')) {
                     [Boolean]$DoCSRStatus = $_.DoCSRStatus
                  } Else {
                     [Boolean]$DoCSRStatus = $false
                  }

                  $email   += Create-EmailTable -client $_.Client `
                  -env $_.Env `
                  -setName $_.SetName `
                  -time $_.Time `
                  -enfs $_.ENFs `
                  -includeStack $includeStack `
                  -includeNotes $includeNotes `
                  -includelatestInfo $includeLatestInfo `
                  -DoCSRStatus $DoCSRStatus
               }
            }
         }
   
         End {
            $email   += Create-RemediationSteps
            $email   += "<br /><br />`n"
            $email   += "<p>This message has been autogenterated by the ENF Emergency Alerts Monitoring tool.</p>"
            Return $email
         }
      }
   
      Function Create-EmailBodySummary {
         Param(
               [Parameter(Mandatory=$true,Position=0)]
               [PSCustomObject[]]$sets
              )
         Begin {
            $clientKeep, $setNameKeep, $envKeep = "","",""
            $email = ""
         }
   
         Process {
            $sets | Foreach {
               If ($_.TriageCount -gt 0 -and `
                     $_.TotalCount -ge $_.Threshold) {
                  $client = $_.Client
                  $env = $_.Env
                  If ($client -ne $clientKeep -or $env -ne $envKeep) { 
                     $email   += "<a href=`"`#$client - $env`"><h2>ENV: $client - $env</h2></a>`n" 
                  }
                  $setName = $_.SetName
                  $_.Time -match '(\d+)([mhd])' | Out-Null;
                  $timeAmt = $Matches[1]
                  $timeSpan = @{"m" = "minute"; "h" = "hour"; "d" = "day"}[$Matches[2]]
                  If ($setName -ne $setNameKeep -or ($client -ne $clientKeep -or $env -ne $envKeep)) {
                     $counts = $_.TotalCount
                     $ENFCounts = $_.TriageCount
                     if ($counts -gt 0) {
                        $email   += "<a href=`"`#$client - $env - $setName`"><h3>Set: $setName</h3></a>`n"
                        $plural = @{$true = "s";$false = ""}[$timeAmt -gt 1]
                        $email   += "<h5>For the last $timeAmt $timeSpan$plural, there have been $counts counts and $ENFCounts total Triage ENFs for the following Exception Messages:</h5>`n"
                        $email   += "<p>`n"
                        $_.ExMsgs | Foreach {
                           $email+= "'$_' <br />`n" 
                        }
                        $email   += "</p>`n"
                        $email   += "<br />`n"
                     }
                  }
                  $setNameKeep = $setName
                  $clientKeep = $client
                  $envKeep = $env
               }
            }
         }
   
         End {
            Return $email
         }
      }
   
      Function Create-EmailTable {
         Param(
               [Parameter(Mandatory=$true,Position=0)]
               [String]$client,
               [Parameter(Mandatory=$true,Position=1)]
               [String]$env,
               [Parameter(Mandatory=$true,Position=2)]
               [String]$setName,
               [Parameter(Mandatory=$true,Position=3)]
               [String]$time,
               [Parameter(Mandatory=$true,ValueFromPipeline,Position=4)]
               [AllowEmptyCollection()]
               [PSCustomObject[]]$enfs,
               [Parameter(Mandatory=$false,Position=5)]
               [Boolean]$includeStack = $false,
               [Parameter(Mandatory=$false,Position=6)]
               [Boolean]$includeNotes = $false,
               [Parameter(Mandatory=$false,Position=7)]
               [Boolean]$includeLatestInfo = $false,
               [Parameter(Mandatory=$false,Position=8)]
               [Boolean]$DoCSRStatus = $false
              )
   
         Begin {
            $time -match '(\d+)([mhd])' | Out-Null;
            $timeAmt  = $Matches[1]
            $timeSize = $Matches[2]
         }
   
         Process {
            For ($i = 0; $i -lt $enfs.Count; $i++) {
               $guid     = $enfs[$i].ENF
               $count    = $enfs[$i].Counts
               $status   = $enfs[$i].Status
               $csr      = $enfs[$i].CSR
               $csrStatus= $enfs[$i].CSRStatus
               $csrResSP = $enfs[$i].CSRResSP
               $csrResDt = $enfs[$i].CSRResDate
               $exMsg    = $enfs[$i].ExMsg
               $emailCnf = $enfs[$i].Email
               $stack    = $enfs[$i].Stack
               $zipPath  = $enfs[$i].ZipPathLast
               $enfNotes = $enfs[$i].ENFNotes
               $oSan     = $enfs[$i].LatestSan
               $custId   = $enfs[$i].CustId
               $custCd   = $enfs[$i].CustCd
               $build    = $enfs[$i].BuildVersion
               $userId   = $enfs[$i].UserId
               $username = $enfs[$i].UserName
               $lastOccur= $enfs[$i].MsgCreatedDt
               $pathTbl  = $enfs[$i].PathTableId
               $EnvLbl   = $enfs[$i].EnvLabel
               $severity = $enfs[$i].Severity


               If ($DoCSRStatus -and $csr) {
                  If ($csrStatus) {
                     $CSRInfo  = "<br/>CSR Status   = $csrStatus"
                  }
                  If ($csrResSP) {
                     $CSRInfo += "<br/>Release SP   = $csrResSP"
                     $CSRInfo += "<br/>Release Date = $csrResDt"
                  }
               } Else {
                  $CSRInfo = ""
               }

               $tblwidth = 1200
               $snglCol  = 25
               $tripCol  = $snglCol * 3
               $style    = "style=`"min-width: 270px; width: " + $snglCol + "%; valign: top; border-style: solid; border-color: black; border-width: 1px`""
               $style3   = "style=`"width: " + $tripcol + "%; valign: top; word-wrap: break-word; border-style: solid; border-color: black; border-width: 1px`""
   
               $email   += "<table style=`"min-width: 1200px; width: 90%; border-style: solid; border-color: black;`" border=`"1px`">`n"
               $email   += "<tbody>`n"
               $email   += "<tr><th $style>ENF</th>  <th $style>Count</th> <th $style>Status</th> <th $style>CSR</th> </tr>`n"
               $email   += "<tr><td $style>$guid</td><td $style>$count</td><td $style>$status</td><td $style><a href=`"https://portal.insurity.com/itg/web/knta/crt/RequestDetail.jsp?REQUEST_ID=$csr`">$csr</a>$CSRInfo</td></tr>`n"
               $email   += "<tr><th $style>Exception Message</th><td $style3 colspan=`"3`">$exMsg</td></tr>`n"
               If ($includeStack) {
                  $email+= "<tr><th $style>Stack Trace</th><td $style3 colspan=`"3`">$stack</td></tr>`n"
               }
               $email   += "<tr><th $style>Latest Zip</th><td $style colspan=`"3`">$zipPath</td></tr>`n"
               If ([Boolean]$includeLatestInfo) {
                  $email+= "<tr><th $style>SAN</th><td $style>$oSan</td><th $style>Severity</th><td $style>$severity</td></tr>`n"
                  $email+= "<tr><th $style>Customer</th><td $style>$custId / $custCd</td><th $style>Build Version</th><td $style>$build</td></tr>`n"
                  $email+= "<tr><th $style>Path Table ID</th><td $style>$pathTbl</td><th $style>Environment</th><td $style>$EnvLbl</td></tr>`n"
                  $email+= "<tr><th $style>User</th><td $style>$userId / $userName</td><th $style>Last Occurrence Timestamp</th><td $style>$lastOccur</td></tr>`n"
               }
               If (-not([String]::IsNullOrWhiteSpace($enfNotes)) -and [Boolean]$includeNotes) {
                  $email+= "<tr><th $style>ENF Notes</th><td $style colspan=`"3`">$enfNotes</td></tr>`n"
               }
               If ($includeNotes) {
                  $email+= "<tr><th $style>Resolution Notes</th><td $style colspan=`"3`"></td></tr>`n"
               }
               $email   += "</tbody>`n"
               $email   += "</table>`n"
               $email   += "<br />`n"
   
            }
         }
   
         End {
            Return $email
         }
      }

      Function Create-RemediationSteps {
         Param(
              )
         
         Begin {
            $steps    = "<h1>How to remediate an ENF</h1>`n"
            $steps   += "<p>Here are the basics on how to remediate an ENF. Please refer to the documentation for more detailed instructions.</p>`n"
         }

         Process {
            $steps   += @"
<ol>
<li>Determine the Severity of the ENF.
<br />   This is done by looking at the number of occurrences, frequency, and how impactful the error is.
<br />   I.e.: Does the error provent a user from rating or issuing a policy? Does it stop a screen from loading?
</li>

<li>Perform a minimal triage of the ENF.
<br />   Look at the the code where the error is occurring. Does anything stand out? Is anything obvious missing?
</li>

<li>Add comments to the ENF in the Tool.
<br />   Comments should be added to the ENF to show what the cause is (if known) and what the effect is. 
<br />   As well, if the error is a non-issue, this should also be noted in the comments.
<br />   Comments should be added in the following format:
<br />      [FL YYYY-MM-DD] This is the text of the comment.
</li>

<li>Determine if a CSR is needed for the issue.
<br />   If the issue causes an issue, a CSR should be created. Ensure to include all needed information in the CSR.
</li>

<li>Moving the ENF along.
<br />   If a CSR was created, then the ENF should be moved into a status of "In Progress" and the CSR added to the ENF.
<br />   If the ENF is considered a non-issue, then the ENF can be moved into a status of "Resolved". Make sure there are notes on the ENF if it is set to resolved.
<br />      NOTE: If a ENF in the status of "Resolved" occurs again, it will re-open. This is not recommended if the frequency of the occurrences is high. It should be set to Defered in this case.
</li>
</ol>
"@
         }

         End {
            Return $steps
         }

      }
   
      Function Create-DataSet {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
               [PSCustomObject[]]$set,
               [Parameter(Mandatory=$false,Position=1)]
               [String[]]$headers = @("GUID", "Count",  "Status", "CSR", "Exception Message", "Latest Zip", "Severity", `
                  "Latest San", "CustomerId", "CustomerCd", "Build Version", "UserId", "Username", "Last Occur Date", "Path Table Id", "Environment"),
               [Parameter(Mandatory=$false,Position=2)]
               [String[]]$values = @("ENF",  "Counts", "Status", "CSR", "ExMsg"            , "ZipPathLast", "Severity", `
                  "LatestSan",  "CustId",     "CustCd",     "BuildVersion",  "UserId", "UserName", "MsgCreatedDt",    "PathTableId",   "EnvLabel")
   
              )
   
         Begin {
            $body    = @()
         }
   
         Process {
            $set | Foreach {
               $obj = New-Object PSObject
               For ($j = 0; $j -lt $headers.Count; $j++) {
                  Try {
                     $obj | Add-Member -MemberType NoteProperty -Name $headers[$j] -Value (([String]$_.$($values[$j])).replace("`n",'\n').replace("`r",'\n').replace('\n\n','\n'))
                  } Catch { }
               }
               $body += $obj
            }
         }
   
         End { 
            Return $body
         }
      }

      Function Substitute-Subject {
         Param(
               [Parameter(Mandatory=$true,Position=0)]
               [String]$subject,
               [Parameter(Mandatory=$true,Position=1)]
               [String]$nowDateTime
              )
         Begin {
            $nowDate = $nowDateTime.Substring(0,10)
            $returnSubject = ""
         }

         Process {
            "Subject - '$subject'"   | Write-Verbose 
            "Subject matches \\date" | Write-Verbose 
            $returnSubject = $subject -Replace '\\date', $nowDate
         }

         End {
            Return [String]$returnSubject
         }
      }

      Function Get-IsInSP {
         Param (
               [Parameter(Mandatory=$true,Position=0)]
               [String]$ServicePack, 
               [Parameter(Mandatory=$true,Position=1)]
               [PSCustomObject]$spConfig
               )

         Begin {
            $returnVal = $false
         }

         Process {
            Foreach ($set in $spConfig) {
               If ($set.Release -eq $ServicePack) {
                  If ((Get-Date) -ge (GetDate $set.StartDate) -and `
                      (Get-Date) -le (GetDate $set.EndDate)) {
                     $returnVal = $true
                     Break;
                  }
               }
            }
         }

         End {
            return $returnVal
         }
      }

      Function Send-Email {
         Param(
               [Parameter(Mandatory=$true,Position=1)]
               [String[]]$to,
               [Parameter(Mandatory=$false,Position=2)]
               [AllowEmptyCollection()]
               [String[]]$cc,
               [Parameter(Mandatory=$true,Position=3)]
               [String]$subject,
               [Parameter(Mandatory=$true,Position=4)]
               [String]$body,
               [Parameter(Mandatory=$false,Position=5)]
               [string[]]$files,
               [Parameter(Mandatory=$false,Position=6)]
               [ValidateSet("low","normal","high")]
               [string]$priority = "High",
               [Parameter(Mandatory=$false,Position=7)]
               [string[]]$offHours,
               [Parameter(Mandatory=$true,Position=8)]
               [String]$smtpSrv
               
              )
   
         $from = Get-UserEmail
   
         If (-not ($offHours -contains ((Get-Date).ToString('HH')))) {
            If ([bool]$files -and [bool]$cc) {
               Send-MailMessage -To $to -Cc $cc -From $from -Subject $subject -Body $body -BodyAsHtml -SmtpServer $smtpSrv -Attachments $files
            } ElseIf ([bool]$files) {
               Send-MailMessage -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -SmtpServer $smtpSrv -Attachments $files
            } ElseIf ([bool]$cc) {
               Send-MailMessage -To $to -Cc $cc -From $from -Subject $subject -Body $body -BodyAsHtml -SmtpServer $smtpSrv
            } else {
               Send-MailMessage -To $to -From $from -Subject $subject -Body $body -BodyAsHtml -SmtpServer $smtpSrv
            }
         }
      }

   #EndRegion

   #Region CSR Information

      Function Set-PasswdFile {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
               [String]$FileLocation,
               [Parameter(Mandatory=$false,Position=1)]
               [String]$Username = [Environment]::UserName
            )
         
         ## Message to the user.
         $Disclosure = "To use PPM, a password is needed. This password will be stored in an encrypted format on the hard drive.`n"
         $Disclosure += "This file can only be decrypted under this username on this computer.`n"
         $Disclosure += "This file will need to be updated when your Windows (AD) password changes." 
         $Disclosure | Write-Host
         ## Get the password from the user.
         $Password = Read-Host -Prompt "Please enter your password." -asSecureString
         ## Check that the password is valid for the user.
         While (-not (Test-ADCredentials ([Environment]::UserName) (ConvertTo-UnsecureString $Password) "INS")) {
            "The password that you entered is not the valid password for user 'INS\$([Environment]::UserName)'." | Write-Host
            "NOTE: If you enter your password incorrectly three times, you will lock your account, so please get it right. Thank you." | Write-Host
            $Password = Read-Host -Prompt "Please enter your password." -asSecureString
         }
         ## Save the password out to the password file in encrypted format
         $Password | ConvertFrom-SecureString | Out-File $FileLocation
      }

      Function Get-PasswdFile {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
               [ValidateScript({
                  Test-Path $_
                  })]
               [String]$FileLocation,
               [Parameter(Mandatory=$false,Position=1)]
               [String]$Username = ([Environment]::UserName)
            )

         ## Read in the password from the password file and convert to a secure string.
         Return Get-Content $FileLocation | ConvertTo-SecureString
      }

      Function Get-PPMVariables {
         Param(
            )

         Begin {
            ## Set up the variables
            $CsrUrl = "https://portal.insurity.com/itg/web/knta/crt/RequestDetail.jsp?REQUEST_ID="
            $DashUrl = "https://portal.insurity.com/itg/dashboard/app/portal/PageView.jsp"
            $LoginFields = @{}
            $CsrPageFields = @{}
         }

         Process {
            ## Set the login page field names.
            $LoginFields['Username'] = "field-username"
            $LoginFields['Password'] = "field-password"
            $LoginFields['RememberMe'] = "field-rememberme"
            $LoginFields['Submit'] = "label-LOGON_SUBMIT_BUTTON_CAPTION"
            $LoginFields['Message'] = "message"

            ## Set the CSR page field names
            $CsrPageFields['CSRStatus'] = "requestStatus"
            $CsrPageFields['ReleaseSP'] = "DRIVEN_P_43"
            $CsrPageFields['ReleaseDate'] = "DRIVEN_P_31"
            $CsrPageFields['Hotfix'] = "DRIVEN_P_62"
            $CsrPageFields['ResDesc'] = "DRIVEN_P_242"
            $CsrPageFields['AssignmentRow'] = "DIV_EC_REF_REQUEST_"
         }

         End {
            ## Create the object and return it
            Return New-Object -TypeName PSObject -Property `
               (@{'CSR_URL' = $CsrUrl; `
                  'Dash_URL' = $DashUrl; `
                  'LoginFields' = $LoginFields; `
                  'CSRPageFields' = $CsrPageFields})
         }
      }

      Function Get-CSR {
         Param(
               [Parameter(ParameterSetName="ONE",Mandatory=$true)]
               [AllowEmptyString()]
               #[ValidatePattern("^\d{7}$")]
               [String]$CSR = "",
               [Parameter(ParameterSetName="FILE",Mandatory=$true)]
               [AllowEmptyString()]
               #[ValidateScript({
               #   If ($_) {
               #      Test-Path $_
               #   }
               #   })]
               [String]$CSV,
               [Parameter(Mandatory=$false)]
               [Switch]$Filter
            )

         Begin {
            ## Create the set object
            $Set = @()
         }

         Process {
            ## Determine if we are using one CSR or a CSV of CSRs
            Switch ($PSCmdLet.ParameterSetName) {
               "FILE"    {  
                           ## Get the CSV
                           $CsrObject = Import-Csv $CSV
                           ## Go through each row in the CSV
                           Foreach ($Row in $CsrObject) {
                              $hash = @{}
                              ## Copy each column in the row to the hash table
                              $CsrObject | Get-Member -Type NoteProperty | Foreach {
                                 $hash[$_.Name] = $Row.$($_.Name)
                              }
                              ## Add the object with the row's information to the Set
                              $Set += New-Object -Typename PSObject -Property $hash
                           }
                           ## If using Filter, get rid of duplicate CSRs
                           If ($Filter) { $Set = $Set | Select -Unique }
                        }
      
               "ONE"    { 
                           ## Add the CSR to the set object.
                           $Set += New-Object -TypeName PSObject -Property (@{'CSR' = $CSR}) 
                        }
            }
         }

         End {
            Return $Set
         }
      }

      Function Get-IEInstance {
         Param(
               [Parameter(Mandatory=$false,ValueFromPipeLine=$true,Position=0)]
               [Boolean]$Visible
            )

         ## Create an instance of Internet Explorer
         $IEInstance = New-Object -ComObject InternetExplorer.Application
         ## Wait for it to open
         Start-Sleep -m 750
         ## Set it to visible if desired
         $IEInstance.Visible = $Visible
         Return $IEInstance

      }

      Function Set-URL {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
               [__ComObject]$IEInstance,
               [Parameter(Mandatory=$true,Position=1)]
               [String]$URL
            )

         Begin {
            ## Navigate the IE object to the desired URL.
            $IEInstance.Navigate2($URL)
         }

         Process {
            ## Wait while the page is loading
            While ($IEInstance.ReadyState -ne 4) {
               Start-Sleep -m 100
            }
         }

         End {
            If ($IEInstance.Document.title -eq "HP Project and Portfolio Management Error") {
               ## We hit a PPM error page
               Return $false
            } Else {
               ## We got to the right page
               Return $true
            }
         }
      }

      Function Set-PPMLogin {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
               [__ComObject]$IEInstance,
               [Parameter(Mandatory=$true,Position=1)]
               [String]$Username,
               [Parameter(Mandatory=$true,Position=2)]
               [System.Security.SecureString]$Password,
               [Parameter(Mandatory=$true,Position=3)]
               [Hashtable]$LoginFields
            )

         Begin {
         }

         Process {
            ## If we are at the login page
            If ($IEInstance.Document.title -eq "PPM Logon") {
               ## Set the username
               $IEInstance.Document.getElementById($LoginFields['Username']).Value = $Username
               ## Set the password (This is using the clear text password.)
               $IEInstance.Document.getElementById($LoginFields['Password']).Value = (ConvertTo-UnsecureString $Password)
               ## Set the remember me field so we shouldn't have to login again
               $IEInstance.Document.getElementById($LoginFields['RememberMe']).Checked = $true
               ## Away we go
               $IEInstance.Document.getElementById($LoginFields['Submit']).Click()
            }

            ## Wait for the page to load
            While ($IEInstance.ReadyState -ne 4) {
               Start-Sleep -m 100
            }
            Start-Sleep -m 1000
         }

         End {
            If ($IEInstance.Document.title -eq "PPM Logon" `
                  -or $IEInstance.Document.getElementById($LoginFields['Message']).Value -match 'Invalid username/password.') {
               ## Username/Password combo was invalid.
               Throw "Your Username/Password is invalid. Please reset your password in the password file by running this script with the `"-Passwd`" flag."
            }
         }
      }

      Function ConvertTo-UnsecureString {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
               [System.Security.SecureString]$SecureString
            )

         Begin {
            ## Create the variables
            $UnsecureString = ""
            $UnmanagedString = 0
         }

         Process {
            ## If we have a secure string (We should)
            If ($SecureString) {
               Try {
                  ## Convert the secure string to a unsecure string
                  $UnmanagedString = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocAnsi($SecureString)
                  $UnsecureString = [System.Runtime.InteropServices.Marshal]::PtrToStringAnsi($UnmanagedString)
               } Finally {
                  ## Clean up the pointer to the unmannaged string
                  [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocAnsi($UnmanagedString)
               }
            }
         }

         End {
            ## Return the unsecure string
            Return $UnsecureString
         }
      }

      Function Get-CSRData {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
               [__ComObject]$IEInstance,
               [Parameter(Mandatory=$true,Position=1)]
               [Hashtable]$CSRPageFields,
               [Parameter(Mandatory=$true,Position=2)]
               [PSCustomObject]$CSRInfo
            )
         
         Begin {

            ## Get the IE document
            $Document = $IEInstance.Document

            ## Prefill the variable values
            $Status = " "
            $ResolutionSP = "Open"
            $ResolutionDate = " "
            $ResolutionDesc = " "
            $Hotfix = "No"
         }

         Process {
            ## Get the status of the CSR
            $Status = $Document.GetElementById($CSRPageFields.CSRStatus).InnerText.Trim().SubString(9)
            ## Get the Resolution servicepack
            $ResolutionSP = $Document.GetElementById($CSRPageFields.ReleaseSP).InnerText
            ## If there is a resolution ServicePack
            If ($ResolutionSP -ne $null) {
               ## Trim it
               $ResolutionSP = $ResolutionSP.Trim()
               ## Get the resolution description
               $ResolutionDesc = $Document.GetElementById($CSRPageFields.ResDesc)
               If ($ResolutionDesc.InnerText -ne $null) {
                  $ResolutionDesc = $ResolutionDesc.InnerText.Trim()
               } Else {
                  $ResolutionDesc = " "
               }
               ## Get whether a hotifx has been sent
               $Hotfix = $Document.GetElementById($CSRPageFields.Hotfix)
               If ($Hotfix.InnerText -ne $null) {
                  $Hotfix = $Hotfix.InnerText.Trim()
               } Else {
                  $HotFix = "No"
               }
               ## get the resolution date
               $ResolutionDate = $Document.GetElementById($CSRPageFields.ReleaseDate)
               If ($ResolutionDate.InnerText -ne $null) {
                  ## Manipulate it to work
                  $ResolutionDate = $ResolutionDate.InnerText.Trim()
                  $ResolutionDate = $ResolutionDate.Substring(0,$ResolutionDate.Length - 4)
                  Try {
                     If ($ResolutionDate -as [DateTime] -ne $null) {
                        ## Convert the date into ISO format
                        $ResolutionDate = Get-Date ($ResolutionDate -as [DateTime]) -Format "yyyy-MM-dd"
                     }
                  } Catch {
                  }

               }
            }


         }

         End {
               ## Add the values to the object for return
               $CSRInfo | Add-Member -MemberType NoteProperty -Name CSRStatus -Value $Status -Force
               $CSRInfo | Add-Member -MemberType NoteProperty -Name ReleaseSP -Value $ResolutionSP -Force
               $CSRInfo | Add-Member -MemberType NoteProperty -Name ReleaseDate -Value $ResolutionDate -Force
               $CSRInfo | Add-Member -MemberType NoteProperty -Name ReleaseDesc -Value $ResolutionDesc -Force
               $CSRInfo | Add-Member -MemberType NoteProperty -Name HotFix -Value $Hotfix -Force

            Return $CSRInfo
         }

      }

      Function Set-OutObject {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
               [Hashtable]$DistinctCSRs
            )
         Begin {
            $OutArr = @()
         }

         Process {
            ## Convert the hasttable into an Array
            Foreach ($CSR in $DistinctCSRs.Keys) {
               $OutArr += $DistinctCSRs[$CSR]
            }
         }

         End {
            Return $OutArr
         }

      }

      Function Test-ADCredentials {
         Param(
               [Parameter(Mandatory=$true,Position=0)]
               [String]$Username,
               [Parameter(Mandatory=$true,Position=1)]
               [String]$Password,
               [Parameter(Mandatory=$false,Position=2)]
               [String]$Domain = "INS"
            )

         Begin {
            ## Get/load the assembly type needed
            Add-Type -AssemblyName System.DirectoryServices.AccountManagement
         }

         Process {
            ## Get the needed objects from AD
            $ContextType = [System.DirectoryServices.AccountManagement.ContextType]::Domain
            $PrincipalContext = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ContextType, $Domain)
         } 

         End {
            ## Check if the username/password combitiation is valid.
            Return [Boolean]($PrincipalContext.ValidateCredentials($Username, $Password))
         }
      }


   #EndRegion

   #Region SQL Looksups

      Function Select-ParameterizedADOLib {
         Param (
               [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
               [String]$sqlQuery,
               [Parameter(Mandatory=$false)]
               [HashTable]$params,
               [Parameter(Mandatory=$true)]
               [String]$sqlDBName
               )
   
         $sqlServer = $DBServer
         $conn = New-Connection $sqlServer -database $sqlDBName -user 'alerts' -password 'alerts'
         $dataSet = Invoke-Query -connection $conn -sql $sqlQuery -parameters $params -AsResult "DataSet"
   
         Return $dataSet
      }
   
      Function Get-OccurrenceCount  {
         Param(
               [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
               [String]$stack,
               [Parameter(Mandatory=$false)]
               [String]$count = '1d',
               [Parameter(Mandatory=$false)]
               [String]$sqlDBName
              )
   
         $count -match '(\d+)([mhd])' | Out-Null
         $minutes = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'm']
         $hours   = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'h']
         $days    = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'd']
         $now     = Get-Date
         $ts      = New-TimeSpan -Days $days -Hours $hours -Minutes $minutes
         $date    = Get-Date ($now + $ts) -format 'MM/dd/yyyy HH:mm'
         $params  = @{"stack" = $stack; "date" = $date}
   
         $sqlQuery  = "SELECT COUNT([GUID]) " 
         $sqlQuery += "FROM [Distinct_Alerts] "
         $sqlQuery += "WHERE ( [StackTrace] = @stack ) "
         $sqlQuery += "AND [MessageCreatedDate] >= @date; "
   
         $dataSet = $sqlQuery | Select-ParameterizedADOLib -params $params -sqlDBName $sqlDBName
   
         Return $dataSet
      }
   
      Function Get-OccurrenceGuid  {
         Param (
               [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
               [String]$exMsgs,
               [Parametes(Mandatory=$false)]
               [String]$notExMsgs,
               [String]$count = '1d',
               [String]$sqlDBName
              )
   
         $count -match '(\d+)([mhd])'
         $minutes = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'm']
         $hours   = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'h']
         $days    = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'd']
         $now     = Get-Date
         $ts      = New-TimeSpan -Days $days -Hours $hours -Minutes $minutes
         $date    = Get-Date ($now + $ts) -format 'MM/dd/yyyy HH:mm'
         $params  = @{"date" = $date}
   
         $sqlQuery  = "SELECT COUNT([GUID]) " 
         $sqlQuery += "FROM [Distinct_Alerts] "
         $sqlQuery += "WHERE ( "
   
         For ($i = 0; $i -lt $exMsgs.Count; $i++) {
            if ($i -gt 0) { 
               $sqlQuery += "OR "
            }
            $sqlQuery += "[ExceptionMessage] LIKE @exMsg" + $i + "`n"
            $params.Add( "exMsg$i", $exMsgs[$i] )
         }
   
         $sqlQuery += " ) AND [MessageCreatedDate] >= @date " 
         $sqlQuery += "ORDER BY [MessageCreatedDate] DESC;"
   
         $dataSet = $sqlQuery | Select-ParameterizedADOLib -params $params -sqlDBName $sqlDBName
   
         Return $dateSet      
      }

      Function Get-OccurrenceLatestInfo {
         Param (
               [Parameter(Mandatory=$true,ValueFromPipeLine=$true,Position=0)]
               [String]$stack,
               [Parameter(Mandatory=$true,Position=1)]
               [String]$sqlDBName,
               [Parameter(Mandatory=$false,Position=2)]
               [String[]]$fields = @( 'CustomerId', 'CustomerCd', 'BuildVersion', 'UserId', 'UserName', 'MessageCreatedDate', 'PathTableId', 'ServiceLobCd', 'EnvironmentLabel', 'SAN' )

               )

         Begin {
            $params = @{ "stack" = $stack }
         }

         Process {
            $sqlQuery  = "SELECT DISTINCT TOP(1) "
            For ($i = 0; $i -lt $fields.Count; $i++) {
               $sqlQuery += '[' + $fields[$i] + ']'
               If ($i -lt $fields.Count - 1) {
                  $sqlQuery += ", "
               } Else {
                  $sqlQuery += " "
               }
            }
            $sqlQuery += "FROM [Distinct_Alerts] "
            $sqlQuery += "WHERE [StackTrace] = @stack "
            $sqlQuery += "ORDER BY [MessageCreatedDate] Desc;"

            $sqlQuery | Write-Verbose
            $params   | Out-String | Write-Verbose
            $dataSet = $sqlQuery | Select-ParameterizedADOLib -params $params -sqlDBName $sqlDBName
         }

         End {
            Return $dataSet
         }

      }
   
      Function Get-TriageEnfInfo {
         Param(
               [Parameter(Position=1)]
               [String[]]$exMsgs = @( "%" ),
               [Parameter(Position=2)]
               [String]$count = '1d',
               [Parameter(Position=3)]
               [String]$sqlDBName,
               [Parameter(Position=4)]
               [String[]]$portfolios,
               [Parameter(Position=5)]
               [String[]]$skippedStatuses,
               [Parameter(Position=6)]
               [String[]]$lobs,
               [Parameter(Position=7)]
               [String[]]$fields, 
               [Parameter(Position=8)]
               [String[]]$notExMsgs,
               [Parameter(Position=9)]
               [String[]]$skippedPortfolios,
               [Parameter(Position=10)]
               [ValidateSet("date","count")]
               [String]$orderBy
              )
   
         Begin {
            $count -match '(\d+)([mhd])'
            $minutes = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'm']
            $hours   = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'h']
            $days    = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'd']
            $now     = Get-Date
            $ts      = New-TimeSpan -Days $days -Hours $hours -Minutes $minutes
            $date    = Get-Date ($now + $ts) -format 'MM/dd/yyyy HH:mm'
            $order   = @{"date"="[UA].[LastOccurrenceDateTime]";"count"="Count([DA].[GUID])"}[$orderBy]
            $params  = @{"date" = $date}
         }
   
         Process {
            $sqlQuery = "SELECT "
            For ($i = 0; $i -lt $fields.Count; $i++) {
               $sqlQuery += "[UA].[$($fields[$i])]"
               $sqlQuery += ", "
            }
            $sqlQuery += "COUNT([DA].[GUID]) `n"
            $sqlQuery += "FROM [Unique_Alerts] AS UA`n" 
            $sqlQuery += "JOIN [Distinct_Alerts] AS DA`n"
            $sqlQuery += "ON [UA].[StackTrace] = [DA].[StackTrace]`n"
            $sqlQuery += "WHERE ( `n"
   
            For ($i = 0; $i -lt $exMsgs.Count; $i++) {
               If ($i -gt 0) {
                  $sqlQuery += "OR "
               }
               $sqlQuery += "[UA].[ExceptionMessage] LIKE @exMsg$i `n"
               $params.Add( "exMsg$i", $exMsgs[$i] )
            }
   
            $sqlQuery += " ) `n"
            if ([Boolean]$notExMsgs) {
               $sqlQuery += "AND ( "
               for ($i = 0; $i -lt $notExMsgs.Count; $i++ ) {
                  If ($i -gt 0) {
                     $sqlQuery += "AND "
                  }
                  $sqlQuery += "[UA].[ExceptionMessage] NOT LIKE @notExMsg$i"
                  if ($i -lt ($notExMsgs.Count - 1)) {
                     $sqlQuery += "`n"
                  }
                  $params.Add( "notExMsg$i", $notExMsgs[$i] )
               }
               $sqlQuery += " ) `n"
            }
            If ([Boolean]$portfolios) {
               $sqlQuery += "AND [UA].[Portfolio] IN ("
               For ($i = 0; $i -lt $portfolios.Count; $i++) {
                  If ($i -ne 0) {
                     $sqlQuery += ", "
                  }
                  $sqlQuery += "@port" + $i
                  $params.Add( "port$i", $portfolios[$i])
               }
               $sqlQuery += ") `n"
            }
            If ([Boolean]$skippedPortfolios) {
               $sqlQuery += "AND [UA].[Portfolio] NOT IN ("
               For ($i = 0; $i -lt $skippedPortfolios.Count; $i++) {
                  If ($i -ne 0) {
                     $sqlQuery += ", "
                  }
                  $sqlQuery += "@skippedPort$i"
                  $params.Add( "skippedPort$i", $skippedPortfolios[$i] )
               }
               $sqlQuery += ") `n"
            }
            If ([Boolean]$skippedStatuses) {
               $sqlQuery += "AND [UA].[Status] NOT IN ("
               For ($i = 0; $i -lt $skippedStatuses.Count; $i++) {
                  If ($i -ne 0) {
                     $sqlQuery += ", "
                  }
                  $sqlQuery += "@status" + $i
                  $params.Add( "status$i", $skippedStatuses[$i])
               }
               $sqlQuery += ") `n"
            }
            If ([Boolean]$lobs) {
               $sqlQuery += "AND [UA].[ServiceLobCd] IN ("
               For ($i = 0; $i -lt $lobs.Count; $i++) {
                  If ($i -ne 0) {
                     $sqlQuery += ", "
                  }
                  $SqlQuery += "@lob" + $i
                  $params.Add( "lob$i", $lobs[$i])
               }
               $sqlQuery += ") `n"
            }

            $sqlQuery += "AND [UA].[LastOccurrenceDateTime] >= @date `n"
            $sqlQuery += "AND [DA].[MessageCreatedDate] >= @date `n"
            $sqlQuery += "GROUP BY [UA].[LastOccurrenceDateTime], "
            For ($i = 0; $i -lt $fields.Count; $i++) {
               $sqlQuery += "[UA].[$($fields[$i])]"
               if ($i -lt ($fields.Count - 1)) {
                  $sqlQuery += ", "
               } Else {
                  $sqlQuery += " `n"
               }
            }
            $sqlQuery += "ORDER BY $order DESC;"
   
            $sqlQuery | Write-Verbose
            $params   | Out-String | Write-Verbose
            $dataSet = $sqlQuery | Select-ParameterizedADOLib -params $params -sqlDBName $sqlDBName
         }
   
         End {
            Return $dataSet
         }
      }
   
      Function Get-TriageZips {
         Param(
               [Parameter(Mandatory=$true,Position=1)]
               [String]$sqlDBName,
               [Parameter(Mandatory=$false,Position=2)]
               [String]$count = '5l',
               [Parameter(Mandatory=$false,Position=3)]
               [String]$timeFrame = '2h',
               [Parameter(Mandatory=$true,ValueFromPipeline,Position=4)]
               [System.GUID]$guid
              )
   
         Begin {
            $count -match '(\d+)([fl])'
            $amt   = [Int]$Matches[1]
            $order = $Matches[2]
            $order = @{'l' = 'desc';'f' = 'asc'}[$order]
            $timeFrame -match '(\d+)([mhd])'
            $minutes = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'm']
            $hours   = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'h']
            $days    = @{$true='-' + $Matches[1];$false=0}[$Matches[2] -eq 'd']
            $now     = Get-Date
            $ts      = New-TimeSpan -Days $days -Hours $hours -Minutes $minutes
            $date    = Get-Date ($now + $ts) -format 'MM/dd/yyyy HH:mm'
         }
   
         Process {
            $params = @{"guid" = $guid; "date" = $date}
   
            $innerSqlQuery  = "SELECT [StackTrace] "
            $innerSqlQuery += "FROM [Unique_Alerts] "
            $innerSqlQuery += "WHERE [GUID] = @guid"
   
            $sqlQuery  = "SELECT TOP($amt) [AlertZipFilePath] "
            $sqlQuery += "FROM [Distinct_Alerts] "
            $sqlQuery += "WHERE [StackTrace] = ( $innerSqlQuery ) "
            $sqlQuery += "AND [MessageCreatedDate] > @date "
            $sqlQuery += "ORDER BY [MessageCreatedDate] $order;"
   
            $dataSet = $sqlQuery | Select-ParameterizedADOLib -params $params -sqlDBName $sqlDBName
   
         }
   
         End {
            Return $dataSet
         }
   
      }

   #EndRegion

   #Region Misc

      Function Get-VerboseStatus {
         ## Check to see if the Verbose flag has been set
         Return @{$true=$true;$false=$false}[$VerbosePreference -eq 'Continue']
      }
         
   #EndRegion
}
