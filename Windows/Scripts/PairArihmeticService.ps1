$env:WCF="C:\Program Files\Microsoft SDKs\Windows\v6.0A\bin"
$env:CSC="C:\Windows\microsoft.net\framework\v2.0.50727"
$env:Path="$env:WCF;$env:CSC"

svcutil.exe http://localhost:51874/PairArihmeticService.svc?wsdl

csc /t:library TestService.cs TestService.cs

[Reflection.Assembly]::LoadFrom("$pwd\TestService.dll")

[Reflection.Assembly]::LoadWithPartialName("System.ServiceModel")

$wsHttpBinding=New-Object system.servicemodel.WSHttpBinding
$endpoint=New-Object System.servicemodel.endpointaddress("http://localhost:51874/PairArihmeticService.svc")

$testService=New-Object TestService($wsHttpBinding, $endpoint)
