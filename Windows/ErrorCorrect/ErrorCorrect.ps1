Function Get-EnvironmentInformation {
   Param(
         [Parameter(Mandatory=$False,Position=1)]
         [ValidateSet("DailyBuilds")]
         [String]$Environment = "DailyBuilds",
         [Parameter(Mandatory=$False,Position=2)]
         [ValidateSet("WIP","CDB")]
         [String]$Database
         )

   $json = Get-Content .\Information.json | ConvertFrom-Json
   $env = $json.Environments | Where-Object {$_.Name -eq $Environment}
   Return $env.Databases | Where-Object {$_.Name -eq $Database}

}

Function Get-CdbPolicyInformation {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$True,Position=3)]
         [Int]$CustomerId
         )


   $query = @"
SELECT [cts].[SystemAssignId], [cts].[TransSeqNo], CONVERT(VARCHAR(10), [cts].[TransEffDt], 1) AS TransEffDt, [cts].[TransTypeCd], [cpp].[PolicyId], [cpp].[CustomerId]
  FROM CoTransactionSummary AS cts
  JOIN CoPolicyPointer AS cpp ON cts.SystemAssignId = cpp.SystemAssignId
 WHERE cts.SystemAssignId LIKE @SAN
   AND cpp.CustomerId = @CUSTID
 ORDER BY cts.TransSeqNo
"@

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@SAN", $SystemAssignId) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@CUSTID", $CustomerId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

   Return $dataset.Tables[0]

}

Function Get-WIPDeleteSan {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [String]$SystemAssignId
         )


   $query = "EXEC dbo.spDeleteSAN @newSAN"

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@newSAN", $SystemAssignId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

}

Function Get-Transaction {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$CDBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [PSCustomObject]$WIPInfo,
         [Parameter(Mandatory=$True,Position=3)]
         [PSCustomObject]$TransactionInfo
         )


   $json = Get-Content .\Information.json | ConvertFrom-Json
   $me = $json.Me
   $myMachine = $json.Machine

   $query = @"
EXEC dbo.spDLMain @CDBSAN
	,@newSAN
	,@PolicyNumber
	,@PolicyPrefix
	,0
	,0
	,@transseq
	,@transeffdt
	,'DOWN'
	,'CORR'
	,@transType
	,@Me
	,@Mymachine
	,@CDBServer
	,@CDBDb
	,@transseq
	,@ClientNumber
"@

   $connString = "Data Source=$($WIPInfo.Server);Initial Catalog=$($WIPInfo.Table);User Id=$($WIPInfo.Username); Password=$($WIPInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandText = $query


   $SqlCommand.Parameters.AddWithValue("@CDBSAN", $TransactionInfo.SystemAssignId) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@newSAN", $TransactionInfo.SystemAssignId) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@PolicyNumber", '') | Out-Null
   $SqlCommand.Parameters.AddWithValue("@PolicyPrefix", '') | Out-Null
   $SqlCommand.Parameters.AddWithValue("@transseq", [Int]$TransactionInfo.TransSeqNo) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@transeffdt", $TransactionInfo.TransEffDt) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@transType", $TransactionInfo.TransTypeCd) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@Me", $me) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@Mymachine", $myMachine) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@CDBServer", $CDBInfo.Server) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@CDBDb", $CDBInfo.Table) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@transseq", [Int]$TransactionInfo.TransSeqNo) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@ClientNumber", [Int]$TransactionInfo.CustomerId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

}

Function Update-CoTransSummary {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [PSCustomObject]$TransactionInfo
         )


   $query = @"
UPDATE CoTransactionSummary
SET TransInProcessCd = @transType
WHERE SystemAssignId = @newSAN
  AND TransSeqId = 1
"@

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@transType", $TransactionInfo.TransTypeCd) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@newSAN", $TransactionInfo.SystemAssignId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

}

Function Update-CoPolicyPointer {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [PSCustomObject]$TransactionInfo
         )


   $query = @"
IF @transType = 'CACA'
	UPDATE CoPolicyPointer
	SET CancEffDt = @transEffdt
	WHERE SystemAssignId = @newSAN
ELSE
	UPDATE CoPolicyPointer
	SET CancEffDt = NULL
	WHERE SystemAssignId = @newSAN
"@

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@transType", $TransactionInfo.TransTypeCd) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@newSAN", $TransactionInfo.SystemAssignId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

}

Function Create-ErrorCorrect {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$True,Position=2)]
         [Int]$CustomerId,
         [Parameter(Mandatory=$False,Position=3)]
         [String]$Environment = "DailyBuilds"
         )

   $cdbInfo = Get-EnvironmentInformation -Environment $Environment -Database "CDB"
   $wipInfo = Get-EnvironmentInformation -Environment $Environment -Database "WIP"

   $cdbTable = Get-CdbPolicyInformation -DBInfo $cdbInfo -SystemAssignId $SystemAssignId -CustomerId $CustomerId

   $cdbTable | Format-Table

   $bool = $false
   Do {
      $i = Read-Host "Please select a TransSeqId or 'q' to quit"
         If ($i-eq 'q') {
            Return
         } Else {
            $array = @()
            $cdbTable.TransSeqNo | ForEach-Object {
                  $array += $_
            }
            If ($array.Contains($i)) {
               $bool = $true
            } Else {
               "Invalid Input" | Write-Output
            }
         }
   } While (-not $bool)

   $transactionInfo = $cdbTable | Where-Object {$_.TransSeqNo -eq $i}

   Get-Transaction -CDBInfo $cdbInfo -WIPInfo $wipInfo -TransactionInfo $transactionInfo

   Update-CoTransSummary -DBInfo $wipInfo -TransactionInfo $transactionInfo

   Update-CoPolicyPointer -DBInfo $wipInfo -TransactionInfo $transactionInfo
}

Create-ErrorCorrect '73011020000000' 29
