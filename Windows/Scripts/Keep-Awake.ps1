Param(
      [Switch]$Resize,
      [Switch]$Slow,
      [Switch]$Clear,
      [int]$SleepTime = 5
     );

$elapsed_time = New-TimeSpan;
$stopwatch = [System.Diagnostics.Stopwatch]::new();
$formatTime = "{0:hh}h:{0:mm}m:{0:ss}s";

Try {

   If ($Clear) {
      Clear-Host;
   }

   (Get-Host).UI.RawUI.WindowTitle = "Stay Awake";

   If ($Resize) {
      [System.Console]::BufferWidth  = [System.Console]::WindowWidth  = 40;
      [System.Console]::BufferHeight = [System.Console]::WindowHeight = 10;
   }

   $shell = New-Object -ComObject WScript.Shell;

   $start_time = Get-Date -UFormat %s; 
   $current_time = $start_time;

   $sleepSeconds = 5;
   If ($Slow) {
      $sleepSeconds = 30;
   }

   $stopwatch.Start();

   Write-Host "Must stay awake!";

   Start-Sleep -Seconds 5;

   $count = 0;

   while($true) {

      $shell.sendkeys("{NUMLOCK}{NUMLOCK}");

      if ($count -eq 8) {

         $count = 0;
         Clear-Host;

      }

      if ($count -eq 0) {

         $current_time = Get-Date -UFormat %s;
         $elapsed_time = $stopwatch.Elapsed;

         Write-Host "I've been awake for $($formatTime -f $elapsed_time)!";

      } else { Write-Host "Must stay awake..." };

      $count ++;

      Wait-Event -Timeout $sleepSeconds;

   }

} Finally {

   $stopwatch.Stop();
   $elapsed_time = $stopwatch.Elapsed;
   Write-Host "I've was awake for $($formatTime -f $elapsed_time)!";

}
