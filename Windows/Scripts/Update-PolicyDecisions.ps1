Param(
      [Switch]$Build,
      [Switch]$Prompt
     );

$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path;

$ngaBuilderProc = Start-Process -FilePath 'C:\Work\Temp\NGABuilder2012_Output\AutoRunNGABuilder.exe' -Passthru;

$ngaBuilderProc.WaitForExit();

& 'Update-LocalhostUI.ps1';

$lightbulbProc = Start-Process -FilePath 'C:\ddrive\Lightbulb\Lightbulb_Prod.cmd' -Passthru;

$lightbulbProc.WaitForExit();

Exit;
