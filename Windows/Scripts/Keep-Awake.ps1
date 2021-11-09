Param(
      [Switch]$Resize,
      [Switch]$Slow,
      [Switch]$Clear,
      [int]$SleepTime = 5
     );

Begin {

   $elapsed_time = New-TimeSpan;
   $stopwatch = [System.Diagnostics.Stopwatch]::new();
   $formatTime = "{0:dd}d {0:hh}h:{0:mm}m:{0:ss}s";

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

   If ($Slow) {
      $SleepTime = 30;
   }

}

Process {
   Try {

      $stopwatch.Start();

      #"Sleep Time: $($SleepTime) seconds" | Write-Output;

      $firstSleepTime = 5;

      If ($SleepTime -lt $firstSleepTime) {
         $firstSleepTime = $SleepTime;
      }

      #Start-Sleep -Seconds $firstSleepTime;

      $count = 0;

      while($true) {

         $shell.sendkeys("{SCROLLLOCK}{SCROLLLOCK}");

         if ($count -eq 8) {

            $count = 0;
            Clear-Host;

         }

         if ($count -eq 0) {

            $current_time = Get-Date -UFormat %s;
            $elapsed_time = $stopwatch.Elapsed;

            "Sleep Time: $($SleepTime) seconds" | Write-Output;
            Write-Host "I've been awake for $($formatTime -f $elapsed_time)!";

         } else { Write-Host "Must stay awake..." };

         $count ++;

         Wait-Event -Timeout $SleepTime;

      }

   } Finally {

      $stopwatch.Stop();
      Write-Host "I've was awake for $($formatTime -f ($stopwatch.Elapsed))!";

   }
}

