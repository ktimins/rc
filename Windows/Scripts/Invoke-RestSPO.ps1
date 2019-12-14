Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

[Parameter(Mandatory=$True)]
[String]$UserName,

[Parameter(Mandatory=$False)]
[String]$Password
)

Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

 
if([string]::IsNullOrEmpty($Password)) {
   $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
}
else {
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
}
 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$request = [System.Net.WebRequest]::Create($Url)
$request.Credentials = $credentials
$request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
$request.Accept = "application/json;odata=verbose"
$request.Method=$Method
$response = $request.GetResponse()
$requestStream = $response.GetResponseStream()
$readStream = New-Object System.IO.StreamReader $requestStream
$data=$readStream.ReadToEnd()
$results = $data | ConvertFrom-Json
$results.d.results 
Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

[Parameter(Mandatory=$True)]
[String]$UserName,

[Parameter(Mandatory=$False)]
[String]$Password
)

Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

 
if([string]::IsNullOrEmpty($Password)) {
   $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
}
else {
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
}
 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$request = [System.Net.WebRequest]::Create($Url)
$request.Credentials = $credentials
$request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
$request.Accept = "application/json;odata=verbose"
$request.Method=$Method
$response = $request.GetResponse()
$requestStream = $response.GetResponseStream()
$readStream = New-Object System.IO.StreamReader $requestStream
$data=$readStream.ReadToEnd()
$results = $data | ConvertFrom-Json
$results.d.results 
Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

[Parameter(Mandatory=$True)]
[String]$UserName,

[Parameter(Mandatory=$False)]
[String]$Password
)

Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

 
if([string]::IsNullOrEmpty($Password)) {
   $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
}
else {
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
}
 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$request = [System.Net.WebRequest]::Create($Url)
$request.Credentials = $credentials
$request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
$request.Accept = "application/json;odata=verbose"
$request.Method=$Method
$response = $request.GetResponse()
$requestStream = $response.GetResponseStream()
$readStream = New-Object System.IO.StreamReader $requestStream
$data=$readStream.ReadToEnd()
$results = $data | ConvertFrom-Json
$results.d.results 
Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

[Parameter(Mandatory=$True)]
[String]$UserName,

[Parameter(Mandatory=$False)]
[String]$Password
)

Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

 
if([string]::IsNullOrEmpty($Password)) {
   $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
}
else {
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
}
 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$request = [System.Net.WebRequest]::Create($Url)
$request.Credentials = $credentials
$request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
$request.Accept = "application/json;odata=verbose"
$request.Method=$Method
$response = $request.GetResponse()
$requestStream = $response.GetResponseStream()
$readStream = New-Object System.IO.StreamReader $requestStream
$data=$readStream.ReadToEnd()
$results = $data | ConvertFrom-Json
$results.d.results 
Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

[Parameter(Mandatory=$True)]
[String]$UserName,

[Parameter(Mandatory=$False)]
[String]$Password
)

Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

 
if([string]::IsNullOrEmpty($Password)) {
   $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
}
else {
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
}
 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$request = [System.Net.WebRequest]::Create($Url)
$request.Credentials = $credentials
$request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
$request.Accept = "application/json;odata=verbose"
$request.Method=$Method
$response = $request.GetResponse()
$requestStream = $response.GetResponseStream()
$readStream = New-Object System.IO.StreamReader $requestStream
$data=$readStream.ReadToEnd()
$results = $data | ConvertFrom-Json
$results.d.results 
Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

[Parameter(Mandatory=$True)]
[String]$UserName,

[Parameter(Mandatory=$False)]
[String]$Password
)

Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

 
if([string]::IsNullOrEmpty($Password)) {
   $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
}
else {
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
}
 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$request = [System.Net.WebRequest]::Create($Url)
$request.Credentials = $credentials
$request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
$request.Accept = "application/json;odata=verbose"
$request.Method=$Method
$response = $request.GetResponse()
$requestStream = $response.GetResponseStream()
$readStream = New-Object System.IO.StreamReader $requestStream
$data=$readStream.ReadToEnd()
$results = $data | ConvertFrom-Json
$results.d.results 
Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

[Parameter(Mandatory=$True)]
[String]$UserName,

[Parameter(Mandatory=$False)]
[String]$Password
)

Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

 
if([string]::IsNullOrEmpty($Password)) {
   $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
}
else {
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
}
 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$request = [System.Net.WebRequest]::Create($Url)
$request.Credentials = $credentials
$request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
$request.Accept = "application/json;odata=verbose"
$request.Method=$Method
$response = $request.GetResponse()
$requestStream = $response.GetResponseStream()
$readStream = New-Object System.IO.StreamReader $requestStream
$data=$readStream.ReadToEnd()
$results = $data | ConvertFrom-Json
$results.d.results 
Param(
[Parameter(Mandatory=$True)]
[String]$Url,

[Parameter(Mandatory=$False)]
[Microsoft.PowerShell.Commands.WebRequestMethod]$Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Get,

[Parameter(Mandatory=$True)]
[String]$UserName,

[Parameter(Mandatory=$False)]
[String]$Password
)

Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type �Path "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 

 
if([string]::IsNullOrEmpty($Password)) {
   $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
}
else {
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
}
 

$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
$request = [System.Net.WebRequest]::Create($Url)
$request.Credentials = $credentials
$request.Headers.Add("X-FORMS_BASED_AUTH_ACCEPTED", "f")
$request.Accept = "application/json;odata=verbose"
$request.Method=$Method
$response = $request.GetResponse()
$requestStream = $response.GetResponseStream()
$readStream = New-Object System.IO.StreamReader $requestStream
$data=$readStream.ReadToEnd()
$results = $data | ConvertFrom-Json
$results.d.results 