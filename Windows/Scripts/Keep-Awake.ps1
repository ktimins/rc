Param(
      [Switch]$Resize,
      [Switch]$Slow,
      [Switch]$Clear
     );

$elapsed_time = 0;

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
   $elapsed_time = 0;

   $sleepSeconds = 5;
   If ($Slow) {
      $sleepSeconds = 30;
   }

   Write-Host "I am awake!";

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
         $elapsed_time = $current_time - $start_time;

         Write-Host "I've been awake for "([System.Math]::Round(($elapsed_time / 60), 2))" minutes!";

      } else { Write-Host "Must stay awake..." };

      $count ++;

#Start-Sleep -Seconds 2.5;
      Wait-Event -Timeout $sleepSeconds;

   }

} Finally {

   Write-Host "I was awake for "([System.Math]::Round(($elapsed_time / 60), 2))" minutes!";

}
