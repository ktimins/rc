Param(
   [Parameter(Mandatory=$True,ValueFromPipeLine=$True,Position=1)]
   [String]$CompName,
   [Parameter(Mandatory=$False,Position=2)]
   [ValidateRange(1000, 3600000)]
   [Int]$Interval = 600000
   )

$CompName = "HFDDEV11W10VM"
$Interval = 500
$timer = New-Object timers.timer
$timer.Interval = $Interval
$return = $False
Register-ObjectEvent -InputObject $timer -EventName Elapsed -SourceIdentifier Timer.Output -Action {
   $return = Test-Connection -Quiet -ComputerName $CompName -Count 1
   if ($return) {
      $wshell = New-Object -ComObject Wscript.Shell
      $wshell.Popup("HFDDEV11W10VM is alive", 0, "Done", 0x1)
   }
}
$timer.Enabled = $True
