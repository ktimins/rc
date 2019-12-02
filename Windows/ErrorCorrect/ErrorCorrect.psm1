[Int]$timeout = 240;

Function Get-EnvironmentInformation {
   Param(
         [Parameter(Mandatory=$False,Position=1)]
         [ValidateSet("DailyBuilds")]
         [String]$Environment = "DailyBuilds",
         [Parameter(Mandatory=$False,Position=2)]
         [ValidateSet("WIP","CDB")]
         [String]$Database
         )

   $json = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "Information.json") | ConvertFrom-Json
   $env = $json.Environments | Where-Object {$_.Name -eq $Environment}
   Return $env.Databases | Where-Object {$_.Name -eq $Database}

}

Function Get-Policy {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$PolicyId,
         [Parameter(Mandatory=$False,Position=2)]
         [String]$Environment = "DailyBuilds",
         [Parameter(Mandatory=$False,Position=3)]
         [String]$Server = "CDB"
         )


   $dbInfo = Get-EnvironmentInformation -Environment $Environment -Database $Server
   
   $policies = Get-SanFromPolicy -DBInfo $dbInfo -PolicyId $PolicyId 

   $policies | Format-Table

}

Function Get-SanFromPolicy {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [String]$PolicyId
         )


   #$query = @"
#SELECT [cpp].[CustomerID]
	#,[cpp].[SystemAssignId]
	#,CONCAT (
		#TRIM([cpp].[PolicyPrefixCd])
		#,TRIM([cpp].[PolicyId])
		#,TRIM([cpp].[PolicySeqNo])
		#) AS 'FullPolicyId'
#FROM [CoPolicyPointer] AS cpp
#WHERE CONCAT (
		#TRIM([cpp].[PolicyPrefixCd])
		#,TRIM([cpp].[PolicyId])
		#,TRIM([cpp].[PolicySeqNo])
		#) LIKE @POLICY
#"@;
   $query = @"
SELECT [cpp].[SystemAssignId]
	,[cpp].[CustomerID]
FROM [CoPolicyPointer] AS cpp
WHERE [cpp].[PolicyId] LIKE @POLICY
"@;

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandTimeout = $timeout;
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@POLICY", "%$PolicyId%") | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
   $dataTable = New-Object System.Data.DataTable
 
   Try {
      $DataAdapter.Fill($dataset)
      $dataTable = $dataset.Tables[0]
   } Catch {
      "Failed to get anything from $($DBInfo.Table) for PolicyId '$PolicyId'." | Write-Output
   }

   Return $dataTable

}

Function Get-CustomerId {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [String]$SystemAssignId
         )


   $query = @"
SELECT [cpp].[CustomerID]
  FROM CoPolicyPointer AS cpp 
 WHERE cpp.SystemAssignId LIKE @SAN
"@

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandTimeout = $timeout;
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@SAN", $SystemAssignId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
   $dataTable = New-Object System.Data.DataTable
 
   Try {
      $DataAdapter.Fill($dataset)
      $dataTable = $dataset.Tables[0]
   } Catch {
      "Failed to get anything from $(DBInfo.Table)." | Write-Output
   }

   Return $dataTable

}

Function Get-PolicyInformation {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$True,Position=3)]
         [Int]$CustomerId
         )

      If ($DBInfo.Name -eq "CDB") {
         $transSeq = "[TransSeqNo]"
      } Else {
         $transSeq = "[TransSeqId]"
      }

   $query = @"
SELECT [cts].[SystemAssignId], [cts].$transSeq, CONVERT(VARCHAR(10), [cts].[TransEffDt], 1) AS TransEffDt, [cts].[TransTypeCd], [cpp].[PolicyId], [cpp].[CustomerId]
  FROM [CoTransactionSummary] AS [cts]
  JOIN [CoPolicyPointer] AS [cpp] ON [cts].[SystemAssignId] = [cpp].[SystemAssignId]
 WHERE [cts].[SystemAssignId] LIKE @SAN
   AND [cpp].[CustomerId] = @CUSTID
 ORDER BY [cts].$transSeq
"@

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandTimeout = $timeout;
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
   $SqlCommand.CommandTimeout = $timeout;
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


   $json = Get-Content (Join-Path -Path $PSScriptRoot -ChildPath "Information.json") | ConvertFrom-Json
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
   $SqlCommand.CommandTimeout = $timeout;
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
   $SqlCommand.CommandTimeout = $timeout;
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
   $SqlCommand.CommandTimeout = $timeout;
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@transType", $TransactionInfo.TransTypeCd) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@transEffdt", $TransactionInfo.TransEffDt) | Out-Null
   $SqlCommand.Parameters.AddWithValue("@newSAN", $TransactionInfo.SystemAssignId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

}

Function Remove-HistoryList {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [String]$SystemAssignId
         )


   $query = "Delete from TmpWCoHistoryList where SystemAssignId = @SAN"

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandTimeout = $timeout;
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@SAN", $SystemAssignId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

}

Function Get-Checkout {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [String]$Compare
         )


   $query = "SELECT * FROM TmpCoCheckout WHERE SystemAssignId like @SAN";

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandTimeout = $timeout;
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@SAN", "%$Compare%") | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

}

Function Update-Checkout {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [PSCustomObject]$DBInfo,
         [Parameter(Mandatory=$True,Position=2)]
         [String]$SystemAssignId
         )


   $query = "Delete from TmpCoCheckout where SystemAssignId = @SAN"

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);"

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
   $SqlConnection.ConnectionString = $connString
   $SqlCommand = $SqlConnection.CreateCommand()
   $SqlCommand.CommandTimeout = $timeout;
   $SqlCommand.CommandText = $query

   $SqlCommand.Parameters.AddWithValue("@SAN", $SystemAssignId) | Out-Null
   
   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand
   $dataset = New-Object System.Data.Dataset
 
   $DataAdapter.Fill($dataset)

}

Function Show-Checkout {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$False,Position=2)]
         [String]$Environment = "DailyBuilds"
         );

   ($wipInfo = Get-EnvironmentInformation -Environment $Environment -Database "WIP") | Out-Null;

   Get-Checkout -DBInfo $wipInfo -Compare $SystemAssignId;
}

Function Remove-Checkout {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$False,Position=2)]
         [String]$Environment = "DailyBuilds"
         );

   $SystemAssignId = $SystemAssignId.PadRight(14, "0")
   ($wipInfo = Get-EnvironmentInformation -Environment $Environment -Database "WIP") | Out-Null;
   ($cdbInfo = Get-EnvironmentInformation -Environment $Environment -Database "CDB") | Out-Null;

   Update-Checkout -DBInfo $wipInfo -SystemAssignId $SystemAssignId;
   Update-Checkout -DBInfo $cdbInfo -SystemAssignId $SystemAssignId;

}

Function Remove-Wip {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$False,Position=2)]
         [String]$Environment = "DailyBuilds"
         )


   $SystemAssignId = $SystemAssignId.PadRight(14, "0")
   ($wipInfo = Get-EnvironmentInformation -Environment $Environment -Database "WIP") | Out-Null;

   ($custId = Get-Cust -SystemAssignId $SystemAssignId -Environment $Environment) | Out-Null;
   If ((Get-PolicyInformation -DBInfo $wipInfo -SystemAssignId $SystemAssignId $custId[1].CustomerID).Rows.Count -gt 0) {
      Get-WIPDeleteSan -DBInfo $wipInfo -SystemAssignId $SystemAssignId
   }

}


Function Get-WipInfo {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$False,Position=2)]
         [Int]$CustomerId = -1,
         [Parameter(Mandatory=$False,Position=3)]
         [String]$Environment = "DailyBuilds"
         )


   $SystemAssignId = $SystemAssignId.PadRight(14, "0")
   $wipInfo = Get-EnvironmentInformation -Environment $Environment -Database "WIP"

   If ($CustomerId -lt 0) {
      $dt = (Get-CustomerId -DBInfo $wipInfo -SystemAssignId $SystemAssignId)
      If ($dt.Rows.Count -gt 0) {
         $CustomerId = $dt.Rows[0]
      }
   }
   $CustomerId | Write-Verbose
   If ($CustomerId -lt 0) {
      Get-PolicyInformation -DBInfo $wipInfo -SystemAssignId $SystemAssignId -CustomerId $CustomerId | Format-Table
   } Else {
      "'$SystemAssignId' does not exist on WIP for $Environment." | Write-Output
   }
}


Function Out-Query {
   Param(
         [Parameter(Mandatory=$True,ValueFromPipeline=$True,Position=1)]
         [String]$Query,
         [Parameter(Mandatory=$False,Position=2)]
         [ValidateSet("DailyBuilds","MP01","MP02","MP03","MP04","MP05","MP06","MP07","MP08")]
         [String]$Environment = "DailyBuilds",
         [Parameter(Mandatory=$False,Position=3)]
         [ValidateSet("WIP","CDB")]
         [String]$Database = "WIP"
         )


   ($DBInfo = Get-EnvironmentInformation -Environment $Environment -Database $Database) | Out-Null;

   $connString = "Data Source=$($DBInfo.Server);Initial Catalog=$($DBInfo.Table);User Id=$($DBInfo.Username); Password=$($DBInfo.Password);";

   $SqlConnection = New-Object System.Data.SqlClient.SqlConnection;
   $SqlConnection.ConnectionString = $connString;
   $SqlCommand = $SqlConnection.CreateCommand();
   $SqlCommand.CommandTimeout = $timeout;
   $SqlCommand.CommandText = $query;

   $DataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter $SqlCommand;
   $dataset = New-Object System.Data.Dataset;
 
   $DataAdapter.Fill($dataset);

   Return $dataset.Tables;
   
}

Function Get-Cust {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$False,Position=2)]
         [String]$Environment = "DailyBuilds"
         )


   $SystemAssignId = $SystemAssignId.PadRight(14, "0")
   ($cdbInfo = Get-EnvironmentInformation -Environment $Environment -Database "CDB") | Out-Null

   Return (Get-CustomerId -DBInfo $cdbInfo -SystemAssignId $SystemAssignId)
   
   #$customerId | Format-Table

}

Function Clear-Wip {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$False,Position=2)]
         [String]$Environment = "DailyBuilds"
         )


   $SystemAssignId = $SystemAssignId.PadRight(14, "0")

   Remove-Checkout -SystemAssignId $SystemAssignId -Environment $Environment;

   ($wipInfo = Get-EnvironmentInformation -Environment $Environment -Database "WIP") | Out-Null;
   Get-WIPDeleteSan -DBInfo $wipInfo -SystemAssignId $SystemAssignId;
   Remove-HistoryList -SystemAssignId $SystemAssignId -DBInfo $wipInfo;
}

Function Invoke-ErrorCorrect {
   Param(
         [Parameter(Mandatory=$True,Position=1)]
         [String]$SystemAssignId,
         [Parameter(Mandatory=$False,Position=2)]
         [Int]$CustomerId = -1,
         [Parameter(Mandatory=$False,Position=3)]
         [Int]$Trans = -1,
         [Parameter(Mandatory=$False,Position=4)]
         [String]$Environment = "DailyBuilds",
         [Parameter(Mandatory=$False)]
         [Switch]$LastTrans
         )


   $SystemAssignId = $SystemAssignId.PadRight(14, "0")
   $cdbInfo = Get-EnvironmentInformation -Environment $Environment -Database "CDB"
   $wipInfo = Get-EnvironmentInformation -Environment $Environment -Database "WIP"

   if ($CustomerId = -1) {
      $customerTable = Get-CustomerId -DBInfo $cdbInfo -SystemAssignId $SystemAssignId
      $CustomerId = [Int]$customerTable.CustomerId[0]
      "Customer: $CustomerId" | Write-Output
   }

   $cdbTable = Get-PolicyInformation -DBInfo $cdbInfo -SystemAssignId $SystemAssignId -CustomerId $CustomerId
   $cdbTable | Format-Table

   $bool = $false
   $array = @()
   $cdbTable.TransSeqNo | ForEach-Object {
      $array += $_
   }
   $maxTrans = ($array | Measure-Object -Maximum).Maximum   
   If ($LastTrans) {
      $i = $maxTrans
   } ElseIf ($Trans -gt 0) {
      
      If ($Trans -le $maxTrans) {
         $i = $Trans
      } Else {
         $i = $maxTrans
      }
   } Else {
      Do {
         $i = Read-Host "Please select a TransSeqId or 'q' to quit"
            If ($i-eq 'q') {
               Return
            } Else {
               If ($array.Contains($i)) {
                  $bool = $true
               } Else {
                  "Invalid Input" | Write-Output
               }
            }
      } While (-not $bool)
   }

   $transactionInfo = $cdbTable | Where-Object {$_.TransSeqNo -eq $i}

   Get-WIPDeleteSan -DBInfo $wipInfo -SystemAssignId $SystemAssignId

   Get-Transaction -CDBInfo $cdbInfo -WIPInfo $wipInfo -TransactionInfo $transactionInfo

   Update-CoTransSummary -DBInfo $wipInfo -TransactionInfo $transactionInfo

   Update-CoPolicyPointer -DBInfo $wipInfo -TransactionInfo $transactionInfo
}
