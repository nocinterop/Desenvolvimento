$instance = 'mssql 2019'
$dbName = 'YourDatabaseName'

$pendingTrans = Invoke-Sqlcmd -ServerInstance $instance -Database $dbName -Query "SELECT COUNT(*) FROM sys.dm_tran_active_transactions"

Write-Output "There are $pendingTrans pending transactions in database $dbName"
