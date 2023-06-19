$instance = 'mssql 2019'
$dbName = 'YourDatabaseName'

$query = "SELECT OBJECT_NAME(ps.OBJECT_ID) AS TableName, si.name AS IndexName, ps.avg_fragmentation_in_percent FROM sys.dm_db_index_physical_stats(DB_ID('$dbName'), NULL, NULL, NULL, NULL) ps INNER JOIN sys.indexes si ON ps.OBJECT_ID = si.OBJECT_ID AND ps.index_id = si.index_id WHERE ps.database_id = DB_ID('$dbName')"

$fragIndexes = Invoke-Sqlcmd -ServerInstance $instance -Database 'master' -Query $query

foreach ($index in $fragIndexes) {
    if ($index.avg_fragmentation_in_percent -gt 30) {
        Write-Output "Index $($index.IndexName) on table $($index.TableName) is fragmented at $($index.avg_fragmentation_in_percent)%"
        # Schedule index maintenance here
    }
}
