Class DataBaseInfo {

   # Properties
   [String]$Environment
   [String]$Database
   [String]$SqlQuery
   [Hashtable]$Params

   # Hidden Static Properties
   [String] Hidden Static $GARDEF = "GARDEF"

   # Hidden Properties
   [String] Hidden $Server
   [String] Hidden $DBName
   [String] Hidden $Username
   [String] Hidden $Password

   # Parameterless Constructor
   DataBaseInfo () {
   }

   # Constructor
   DataBaseInfo([String]$Environment, [String]$Database) {
      $this.Environment = $Environment
      $this.Database = $Database

      $this.GetDBInformation()
   }

   DataBaseInfo([String]$Environment, [String]$Database, [String]$SqlQuery) {
      $this.Environment = $Environment
      $this.Database = $Database
      $this.SqlQuery = $SqlQuery

      $this.GetDBInformation()
   }

   DataBaseInfo([String]$Environment, [String]$Database, [String]$SqlQuery, [HashTable]$Params) {
      $this.Environment = $Environment
      $this.Database = $Database
      $this.SqlQuery = $SqlQuery
      $this.Params = $Params

      $this.GetDBInformation()
   }


   [void] Hidden GetDBInformation () {
      $this.Username = [DataBaseInfo]::GARDEF
      $this.Password = [DataBaseInfo]::GARDEF

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

   [HashTable]GetInfo () {
      Return @{Environment = $this.Environment; Database = $this.Database; Server = $this.Server; DBName = $this.DBName; SqlQuery = $this.SqlQuery; Params = $this.Params; Username = $this.Username}
   }

   [System.Data.Dataset]GetSqlResult () {
      If (-not [String]::IsNullOrWhiteSpace($this.SqlQuery)) {
         Return $this.SelectParameterizedADOLib($this.SqlQuery, $this.Params)
      } Else {
         Throw("SQL Query must be real.")
      }
   }

   [System.Data.Dataset] Hidden SelectParameterizedADOLib([String]$SqlQuery, [HashTable]$Params) {
      $conn = New-Connection -server $this.Server -database $this.DBName -user $this.Username -password $this.Password
      $dataSet = Invoke-Query -connection $conn -sql $SqlQuery -parameters $Params -AsResult "DataSet"
      Return $dataSet
   }

}
