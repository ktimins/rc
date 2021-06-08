$ip = "192.168.50.130";
$maskBits = 24; # This means subnet mask = 255.255.255.0
$gateway = "192.168.50.1";
$dns = @("64.6.65.6","8.8.8.8");
$ipType = "IPv4";
# Retrieve the network adapter that you want to configure
$adapter = Get-NetAdapter | ? {$_.Status -eq "up"};
# Remove any existing IP, gateway from our ipv4 adapter
If (($adapter | Get-NetIPConfiguration).IPv4Address.IPAddress) {
 $adapter | Remove-NetIPAddress -AddressFamily $ipType -Confirm $false;
}
If (($adapter | Get-NetIPConfiguration).Ipv4DefaultGateway) {
 $adapter | Remove-NetRoute -AddressFamily $ipType -Confirm $false;
}
 # Configure the IP address and default gateway
$adapter | New-NetIPAddress `
 -AddressFamily $ipType `
 -IPAddress $ip `
 -PrefixLength $maskBits `
 -DefaultGateway $gateway;
# Configure the DNS client server IP addresses
$adapter | Set-DnsClientServerAddress -ServerAddresses $dns;
