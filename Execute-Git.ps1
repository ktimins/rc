Param(
      [Parameter(ValueFromPipeline=$true,Position=0)]
      [ValidateSet("Push","Pull")]
      [String]$Run = "Push",
      [Parameter(Position=1)]
      [String[]]$Servers= @('origin', 'gitlab')

     );

$currentBranch = (git branch --show-current);

"Running: 'git $($Run.ToLower())' on Servers: $($Servers -join ", ")" | Write-Output;

If ($Run -eq "Pull") {
   $Servers | ForEach-Object {git pull $_ $currentBranch};
} ElseIf ($Run -eq "Push") {
   $Servers | ForEach-Object {git push $_ $currentBranch};
}
