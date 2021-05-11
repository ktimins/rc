Param(
      [Switch]$Pull,
      [Switch]$Push
     );

$servers = $('origin', 'gitlab');

If ($Pull) {
   $servers | ForEach-Object {git pull $_};
} ElseIf ($Push) {
   $servers | ForEach-Object {git push $_};
}
