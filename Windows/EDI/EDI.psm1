Function Get-RecordInfo {
   Param(
         [Parameter(Mandatory=$False,Position=1)]
         [String]$OutputFile = "record.txt",
         [Parameter(Mandatory=$False)]
         [Switch]$RM
        )

   If (Test-Path $OutputFile) {
      If ($RM) {
         Remove-Item -Path $OutputFile -Force
         New-Item $OutputFile -Type file
      }
   } Else {
      New-Item $OutputFile -Type file
   }

   $files = Get-ChildItem -Filter "*.EDI*" | Sort-Object
   foreach ($file in $files) {                                                                         
      $data = Get-Content $file.PSPath                                                                                                           
         $i = 0                                                                                                                                     
         foreach ($line in $data) {                                                                                                                 
            $i++                                                                                                                                       
               $line -match '^.{88}(.{3})(..)' | Out-Null
               $type = @{"BNB"="NBIS";"BRN"="RIES";"BED"="PCNM";"B02"="CANI";"B04"="CARS";"B25"="CIRT"}[$matches[1]]                                                                             
               $record = @{"01"="01";"03"="ThirdParty";"04"="Coverage";"09"="Vehicle";"10"="Agent"}[$matches[2]]
               if ($record -eq "01") {
                  if ($type -eq "CANI") {
                     $record = "Cancel"
                  } elseif ($type -eq "CARS") {
                     $record = "Reinstatement"
                  } else {
                     $record = "Policy-Gen"
                  }
               }
               "File: $($file.Name) -- Line: $(($i.ToString()).PadLeft(2,'0')) -- Length: $($line.Length) -- RecordType: $type ($($matches[1])) - $($matches[2]) $record" | Add-Content $OutputFile              
         }                                                                                                                                          
      "" | Add-Content $OutputFile
   }                                                                                                                                          

}

##############################
#           Export           #
##############################
Export-ModuleMember -Function *
