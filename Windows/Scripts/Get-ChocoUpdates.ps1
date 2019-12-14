
Process {
   $result = ( & "C:\ProgramData\chocolatey\bin\choco.exe" outdated ) | Out-String -Stream;

   If ($LASTEXITCODE -eq 0) {
      Send-OutlookEmail -From 'Kyle.Timins@insurity.com' -To 'Kyle.Timins@insurity.com' -Subject 'Chocolatey - Outdated packages' -Body (@($result) -join "`r`n");
   }
}

Begin {

   Function Send-OutlookEmail {
      Param(
            [Parameter(Mandatory=$true,Position=1)]
            [String]$From,
            [Parameter(Mandatory=$true,Position=2)]
            [String[]]$To,
            [Parameter(Mandatory=$false,Position=3)]
            [AllowEmptyCollection()]
            [String[]]$Cc,
            [Parameter(Mandatory=$true,Position=4)]
            [String]$Subject,
            [Parameter(Mandatory=$true,Position=5)]
            [String]$Body,
            [Parameter(Mandatory=$false,Position=6)]
            [AllowEmptyCollection()]
            [String[]]$attachments = @(),
            [Parameter(Mandatory=$false,Position=7)]
            [ValidateSet("low","normal","high")]
            [string]$priority = "normal"
           );
   
      Begin {
         # Add-Type -assembly "Microsoft.Office.Interop.Outlook"
         $Outlook = New-Object -ComObject Outlook.Application;
      }
      Process {
   
         If ([Bool]$WhatIfSend) {
            "To: $to" | Write-Host;
            "CC: $cc" | Write-Host;
         } Else {
            # Create an instance Microsoft Outlook
            $Mail = $Outlook.CreateItem(0);
            $Mail.To = $To -join ';';
            $Mail.CC = $Cc -join ';';
            $Mail.Subject = $Subject;
            $Mail.HTMLBody = $Body;
            $Attachments | ForEach-Object {;
               $Mail.Attachments.Add($_);
            }
            $Mail.Send();
         }
      }
      End {
         # Section to prevent error message in Outlook
         #$Outlook.Quit()
         #[System.Runtime.Interopservices.Marshal]::ReleaseComObject($Outlook)
         #$Outlook = $null
      } 
   }
}
