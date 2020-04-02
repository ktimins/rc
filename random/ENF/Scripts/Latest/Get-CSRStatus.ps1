<#

   .SYNOPSIS
   This is a script that wll check the status of a CSR (or list of CSRs in CSV format) and get infomation about the CSR.

   .DESCRIPTION
   This is a script to check the status of (a) CSR(s). If the CSR has been closed, the Resolution information will be grabbed as well.
   A CSR can be passed in to check one or a CSV file can be passed in to check all of the CSRs on the CSV.

   This script uses a stored password in an encryted file on the hard disk. This is used to log into PPM. Is you have not created the password file, you will be prompted to do so. When your password changes, you will need to recreate the password file.

   This script goes to the PPM page for each CSR and strips the data that is needed.

   Then, the values can be outputted to a CSV file or to the Powershell console.

   As well, this script can clear IE's Temporary Internet Files and Cache.

   .NOTES
   This script is using the InternetExplorer.Application, which means that it is useable with Powershell v2, but it is slow.
   It takes about three seconds per CSR since it loads the actual PPM page in IE to grab the information.

   .PARAMETER Csr
   If looking up a single CSR, the value is passed in via this parameter.

   .PARAMETER InFIle
   If checking the value of multiple CSRs, a CSR filean be passed in via this parameter.
   The CSR should have column with a header of "CSR" with all the rows containing a single CSR. All other columns will be preserved.

   .PARAMETER OutFile
   If saving the values to a CSV file, a CSV file must be passed in this parameter.
   NOTE: If you enter the name of an existing file, the file will be overwritten.

   .PARAMETER Print
   If you would like the information outputted in this console, pass this parameter.

   .PARAMETER Filter
   If you pass in a CSV file, but don't want any repeat CSRs in the output file, pass this parameter.

   .PARAMETER Visible
   If you want to see the Internet Explorer window, pass this flag.

   .PARAMETER Passwd
   If you need to reset the password that is stored, pass this flag.
   No other code will be processed.

#>

#Requires -Version 2

Param(
      [Parameter(Mandatory=$true,ParameterSetName="CSR")]
      [Parameter(Mandatory=$false,ParameterSetName="Passwd")]
      [ValidatePattern("^\d{7}$")]
      [String]$Csr,
      [Parameter(Mandatory=$true,ParameterSetName="CSV")]
      [Parameter(Mandatory=$false,ParameterSetName="Passwd")]
      [ValidateScript({
         If (Test-Path $_) {$true} Else {Throw "`nInvalid CSV input path given: $_"}
         })]
      [String]$InFile,
      [Parameter(Mandatory=$false)]
      [String]$OutFile,
      [Parameter(Mandatory=$false)]
      [Switch]$Print,
      [Parameter(Mandatory=$false)]
      [Switch]$Filter, 
      [Parameter(Mandatory=$false)]
      [Switch]$Visible,
      [Parameter(Mandatory=$true,ParameterSetName="Passwd")]
      [Parameter(Mandatory=$false)]
      [Switch]$Passwd
     )

Process {

   Write-Progress -Activity "Getting Password" 
   
   ## Set the location of the password file.
   $PasswdFileLocation = 'C:\ENF\Passwd.txt'
   
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

   Write-Progress -Activity "Getting Password" -Complete

   Write-Progress -Activity "Getting Status of CSRs" -Status "Importing CSRs"

   ## Determine if we are working with one CSR or if we are working with a CSV of CSRs.
   If ($Csr) {
      $CSRs = Get-CSR -CSR $Csr
   } Else {
      $CSRs = Get-CSR -CSV $InFile -Filter
   }

   ## Get the PPM variables and set to an object
   $PPMVariables = Get-PPMVariables

   Write-Progress -Activity "Getting Status of CSRs" -Status "Accessing PPM"

   ## Go create an instance of IE
   $IEInstance = Get-IEInstance $Visible
   
   ## Go try to navigate to the the dashboard on PPM
   $PageStatus = Set-URL $IEInstance $PPMVariables.Dash_URL

   ## If we encountered a PPM error
   If (-not $PageStatus) {
      ## Throw an exception and get out.
      Throw "Something is happening with PPM. Unable to connect."
   }

   ## Go try to log in if we need to
   Set-PPMLogin $IEInstance ([Environment]::UserName) $Password $PPMVariables.LoginFields

   ## Get rid of the plain text password.
   $Password = ""

   ## Create the hash for the distinct CSRs
   $DistinctCSRs = @{}

   ## Current CSR counter
   $i = 0

   ## Go through each of the CSRs
   Foreach ($CSRObject in $CSRs) {
      ## Check if the CSR is already in the distinct CSR hash
      If ($DistinctCSRs.ContainsKey($CSRObject.CSR)) {
         ## If so, just grab the info from there and go to the next CSR
         $CSRObject = $DistinctCSRs[$CSRObject.CSR]
         Continue
      }

      Write-Progress -Activity "Getting Status of CSRs" -Status "Finding Status of $($CSRObject.CSR)" -PercentComplete ($i++ / @($CSRs).Count*100) -SecondsRemaining (((@($CSRs).Count - $i) * 3) + 3)

      ## Navigate to the CSR PPM page if it exists
      If (Set-URL $IEInstance "$($PPMVariables.CSR_URL)$($CSRObject.CSR)") {

         ## Go strip the information off the CSR page
         $CSRObject = Get-CSRData $IEInstance $PPMVariables.CSRPageFields $CSRObject

         ## Go add the CSR to the distinctCSRs Hash if it's not already there.
         If (-not $DistinctCSRs.ContainsKey($CSRObject.CSR)) {
            $DistinctCSRS.Add($CSRObject.CSR, $CSRObject)
         }
      }

   }

   Write-Progress -Activity "Getting Status of CSRs" -Status "Setting Output Object"

   ## Create the output objects/array
   $OutArray = $DistinctCSRs | Set-OutObject

   ## Write the information to the output file
   If ($OutFile) {
      Write-Progress -Activity "Getting Status of CSRs" -Status "Creating CSV File"
      $OutArray | Export-CSV -Path $OutFile -NoTypeInformation
   }

   ## Write the information to the screen.
   If ($Print) {
      $OutArray | Format-List
   }
   

   ## Close IE.
   Try {
      $IEInstance.Quit()
   } Catch { }
   Finally {
      Write-Progress -Activity "Getting Status of CSRs" -Completed
   }
   
}

End {
}

Begin {

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
                     $ResolutionDate = Get-Date ([DateTime]::ParseExact($ResolutionDate, "MMMM dd, yyyy, h:mm:ss tt", $null)) ` 
                        -format "yyyy-MM-dd HH:mm:ss"
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


}

# SIG # Begin signature block
# MIIEPAYJKoZIhvcNAQcCoIIELTCCBCkCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcDykAEaH8MuQrBaQw2AH/UsK
# IzegggJDMIICPzCCAaygAwIBAgIQK1hHgwMalLpMVaX08TbQfTAJBgUrDgMCHQUA
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
# hvcNAQkEMRYEFGUWxoM/WkZahjeZcarFgDu1POvYMA0GCSqGSIb3DQEBAQUABIGA
# nNvxM9yvCQtFSpCuQJElRznFROogybY7msgDHAuJzpDiQD0wg633UhDes0en2UcD
# NDNq6AxNAFiSHEGyAQoQniz55HiKOk92vh421n81+6gdiwLaKj3jU3dk/8vxS7Aj
# SAs4Xw9jshu4qi+y4xQ6OrwR+CmUyqhk5Xff1+iNz1I=
# SIG # End signature block
