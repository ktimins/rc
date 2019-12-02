Param(
      [int]$Spins = 1
     );

$spots = @('0', '28', '9', '26', '30', '11', '7', '20', '32', '17', '5', '22', '34', '15', '3', '24', '36', '13', '1', '00', '27', '10', '25', '29', '12', '8', '19', '31', '18', '6', '21', '33', '16', '4', '23', '35', '14', '2');
$numOfSpots = $spots.Count
[double]$odds = [double]([double]1 /$numOfSpots);

$outcome = @();

1..$Spins | % { $outcome += $spots[$(Get-Random -Minimum 0 -Maximum ($numOfSpots -1))]; }

Return $outcome;

