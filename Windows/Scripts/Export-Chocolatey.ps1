#Put this in Export-Chocolatey.ps1 file and run it:
#.\Export-Chocolatey.ps1 > packages.config
#You can install the packages using
#choco install packages.config -y

Param(
      [Switch]$Version
     );

$str = "<?xml version=`"1.0`" encoding=`"utf-8`"?>`n";
$str += "<packages>`n";
$choco = (choco list -lo -r -y);
$choco | ForEach-Object {
   $str += "   <package id=`"$($_.SubString(0, $_.IndexOf("|")))`"";
   If ($Version) {
      $str += " version=`"$($_.SubString($_.IndexOf("|") + 1))`"";
   }
   $str += " />`n";
}
$str += "</packages>";
$str | Write-Output;
