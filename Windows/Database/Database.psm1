Class DatabaseInformation {

   # Hidden Properties
   [String] Hidden $Server
   [String] Hidden $DBName
   [String] Hidden $Username
   [String] Hidden $Password

   [String] Static $Gardef = "GARDEF"

   DatabaseInformation () {
   }

   DatabaseInformation ([String]$Environment, [String]$Database) {
      $this.Username = [DatabaseInformation]::GARDEF
      $this.Password = [DatabaseInformation]::GARDEF

      Switch ($Environment) {
         "DailyBuilds" {
            Switch ($Database) {
               "WIP" {  
                  $this.Server = "HFDWPINSQL16PV2\DAILYBUILDS08"
                  $this.DBName = "ID1000WIP"
               }
               "CDB" {
                  $this.Server = "HFDWPINSQL16PV1\DailyBuilds07"
                  $this.DBName = "ID1000CDB"
               }
            }
         }
      }
   }

   DatabaseInformation ([String]$Environment, [String]$Database, [String]$Username, [String]$Password) {
      $this.Username = $Username
      $this.Password = $Password

      Switch ($this.Environment) {
         "DailyBuilds" {
            Switch ($this.Database) {
               "WIP" {  
                  $this.Server = "HFDWPINSQL16PV2\DAILYBUILDS08"
                  $this.DBName = "ID1000WIP"
               }
               "CDB" {
                  $this.Server = "HFDWPINSQL16PV1\DailyBuilds07"
                  $this.DBName = "ID1000CDB"
               }
            }
         }
      }
   }

   [String] getInformation() {
      [Hashtable]$DBInfo = @{}
      $DBInfo.Add("Server", $this.Server)
      $DBInfo.Add("DBName", $this.DBName)
      $DBInfo.Add("Username", $this.Username)
      $DBInfo.Add("Password", $this.Password)
      Return $DBInfo
   }

}


Class Database {

   # Hidden Static Properties
   [String] Static $EnvironmentDefault = "DailyBuilds"
   [String] Static $DatabaseDefault = "WIP"

   # Hidden Properties
   [String] Hidden $Server
   [String] Hidden $DBName
   [String] Hidden $Username
   [String] Hidden $Password
   [System.Data.SqlClient.SQLConnection] Hidden $Conn

   # Parameterless Constructor
   Database () {
      $this.SetDBInformation([Database]::EnvironmentDefault, [Database]::DatabaseDefault)
   }

   # Constructor
   Database([String]$Environment, [String]$Database) {
      $this.SetDBInformation($Environment, $Database)
   }

   [void] Hidden SetDBInformation([String]$Environment, [String]$Database) {
      $DBInfo = [DatabaseInformation]::new($Environment, $Database)
      $this.Server = $DBInfo.Server
      $this.DBName = $DBInfo.DBName
      $this.Username = $DBInfo.Username
      $this.Password = $DBInfo.Password
   }

   [void] Hidden GetSQLConn() {
      $this.Conn = New-Connection -server $this.Server -database $this.DBName -user $this.Username -password $this.Password
   }

   [void] Hidden CloseSQLConn() {
      $this.Conn.Close()
   }

}

Class DatabaseResult : Database {

   [String] Hidden $SqlQuery
   [Hashtable] Hidden $Params
   [System.Data.Dataset] Hidden $Dataset

   DatabaseResult() : base() {
   }

   DatabaseResult([String]$Environment, [String]$Database) : base($Environment, $Database) {
   }

   [void] SetQuery([String]$SqlQuery, [Hashtable]$Params) {
      if ($Params.Count -ne ([regex]::Matches($Params, "@")).Count) {
         Throw "Paramater counts do not match number of variables in SQL Statement."
      }
      $this.SqlQuery = $SqlQuery
      $this.Params = $Params
   }

   [void] Hidden SelectParameterizedADOLib() {
      $this.GetSQLConn()
      $this.DataSet = Invoke-Query -connection $this.Conn -sql $this.SqlQuery -parameters $this.Params -AsResult "DataSet"
      $this.CloseSQLConn()
   }

   [void] GetSelectOutput() {
      $this.SelectParameterizedADOLib()
   }

}

Class GetPolicyCDBInfo : DatabaseResult {

   [String] Hidden $SystemAssignId
   [Int] Hidden $CustomerId = -1
   [Hashtable[]] Hidden $Output

   [String] Static $CDBQuery = @"
SELECT [cts].[SystemAssignId], [cts].[TransSeqNo], CONVERT(VARCHAR(10), [cts].[TransEffDt], 1) AS TransEffDt, [cts].[TransTypeCd], [cpp].[PolicyId], [cpp].[CustomerId]
  FROM CoTransactionSummary AS cts
  JOIN CoPolicyPointer AS cpp ON cts.SystemAssignId = cpp.SystemAssignId
 WHERE cts.SystemAssignId LIKE @SAN
   AND cpp.CustomerId = @CUSTID
 ORDER BY cts.TransSeqNo
"@

   [String] Static $GetCustomerIdQuery = @"
SELECT DISTINCT [cpp].[CustomerId]
  FROM [CoPolicyPointer] AS cpp
 WHERE [cpp].[SystemAssignId] = @SAN
 ORDER BY [cpp].[CustomerId]
"@
   
   GetPolicyCDBInfo() : base([Database]::EnvironmentDefault, "CDB") {
   }

   GetPolicyCDBInfo([String]$Environment, [String]$Database) : base($Environment, $Database) {
   }

   [void] SetSystemAssignId([String]$SystemAssignId) {
      If (($SystemAssignId -match "[^0-9a-zA-Z]") -and $SystemAssignId.Length -le 14) {
         Throw "SystemAssignId is Invalid"
      }
      $this.SystemAssignId = $SystemAssignId.PadRight(14, "0")
   }

   [void] SetCustomerId() {
      If (-not ($this.SystemAssignId)) {
         Throw "SystemAssignId not set"
      }
      $this.GetCustomerId()
      If ([Int]$this.Dataset.Tables[0].Rows.Count -ne 1) { 
         Throw "No CustomerId returned from query"
      }
      $this.CustomerId = [Int]$this.Dataset.Tables[0].Rows[0][0]
   }

   [void] SetCustomerId([Int]$CustomerId) {
      If ($CustomerId -lt 0) {
         Throw "CustomerId is Invalid"
      }
      $this.CustomerId = $CustomerId
   }

   [void] Hidden SetOutput() {
   }

   [System.Data.Dataset] GetOutput() {
      Return $this.Dataset
   }

   [void] GetCustomerId() {
      $this.Params = @{
         "SAN" = $this.SystemAssignId
      }
      $this.SqlQuery = [GetPolicyCDBInfo]::GetCustomerIdQuery
      $this.SelectParameterizedADOLib()
   }

   [void] GetSelectOutput() {
      $this.Params = @{
         "SAN" = $this.SystemAssignId;
         "CUSTID" = $this.CustomerId
      }
      $this.SqlQuery = [GetPolicyCDBInfo]::CDBQuery
      $this.SelectParameterizedADOLib()
   }

}

Class DatabaseSPExecute : Database {

   [String] Hidden $StoredProc
   [Hashtable] Hidden $Params
   [Hashtable] Hidden $OutParams
   [System.Data.Dataset] Hidden $Dataset

   DatabaseSPExecute() : base() {
   }

   DatabaseSPExecute([String]$Environment, [String]$Database) : base($Environment, $Database) {
   }

   [void] SetStoredProc([String]$StoredProc, [Hashtable]$Params, [HashTable]$OutParams) {
      $this.StoredProc = $StoredProc
      $this.Params = $Params
      $this.OutParams = $OutParams
   }

   [void] Hidden InvokeStoredProcADOLib() {
      $this.GetSQLConn()
      $this.Dataset = Invoke-StoredProcedure -storedProcName $this.StoredProc -connection $this.Conn -parameters $this.Params -outparameters $this.OutParams
   }
}


Class PolicyCustIdLookup : Database {

   [String]$SystemAssignId

   [String] Static $SqlQuery = "SELECT cpp.CustomerId FROM CoPolicyPointer AS cpp WHERE cpp.SystemAssignId = @SAN;"

   PolicyCustIdLookup([String]$Environment, [String]$Database, [String]$SystemAssignId) {
      If (-not ($SystemAssignId -match "[^0-9a-zA-Z]") -and $SystemAssignId.Length -le 14) {
         $this.Environment = $Environment
         $this.Database = $Database
         $this.SystemAssignId = $SystemAssignId.PadRight(14, '0')
         $this.Params = @{SAN = $this.SystemAssignId}
         $this.GetDBInformation()
      }
   }

   [System.Data.Dataset] GetSqlResult () {
      If (-not [String]::IsNullOrWhiteSpace([PolicyCustIdLookup]::SqlQuery)) {
         Return $this.SelectParameterizedADOLib([PolicyCustIdLookup]::SqlQuery, $this.Params)
      } Else {
         Throw("SQL Query must be real.")
      }
   }

   [String]GetCustId () {
      $ds = $this.GetSqlResult()
      Return $ds.Tables[0].Rows[0][0]
   }
}


Class Policy {

   [String] $SystemAssignId
   [Int] $CustomerId

   [Database] Hidden $CDB
   [Database] Hidden $WIP

   Policy () {
      Throw("Must have parameters.")
   }

   Policy ([String]$Environment) {
      $this.CDB = [Database]::New($Environment, "CDB")
      $this.WIP = [Database]::New($Environment, "WIP")
   }

   Policy ([String]$Environment, [String]$SystemAssignId) {
      If (-not ($SystemAssignId -match "[^0-9a-zA-Z]") -and $SystemAssignId.Length -le 14) {
         $this.CDB = [Database]::New($Environment, "CDB")
         $this.WIP = [Database]::New($Environment, "WIP")
         $this.SystemAssignId = $SystemAssignId
      } Else {
         Throw("Invalid Parameters.")
      }
   }

   Policy ([String]$Environment, [String]$SystemAssignId, [Int]$CustomerId) {
      If (-not ($SystemAssignId -match "[^0-9a-zA-Z]") -and $SystemAssignId.Length -le 14 -and $CustomerId -ge 0) {
         $this.CDB = [Database]::New($Environment, "CDB")
         $this.WIP = [Database]::New($Environment, "WIP")
         $this.SystemAssignId = $SystemAssignId
         $this.CustomerId = $CustomerId
      } Else {
         Throw("Invalid Parameters.")
      }
   }

}
