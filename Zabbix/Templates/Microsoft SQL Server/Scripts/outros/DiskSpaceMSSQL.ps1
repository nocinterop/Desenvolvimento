$instance = 'mssql 2019'
$dbName = 'YourDatabaseName'
$dataDrive = 'C:'

$dbSize = Get-WmiObject -ComputerName $instance -Namespace 'root\Microsoft\SqlServer\ComputerManagement' -Class 'SqlServiceAdvancedProperty' -Filter "ServiceName = 'MSSQLSERVER' AND PropertyName = 'Database Size (MB)' AND DisplayName = '$dbName'" | Select-Object -ExpandProperty PropertyStrValue
$logSize = Get-WmiObject -ComputerName $instance -Namespace 'root\Microsoft\SqlServer\ComputerManagement' -Class 'SqlServiceAdvancedProperty' -Filter "ServiceName = 'MSSQLSERVER' AND PropertyName = 'Log Size (MB)' AND DisplayName = '$dbName'" | Select-Object -ExpandProperty PropertyStrValue

$dataDriveFreeSpace = Get-PSDrive -Name $dataDrive | Select-Object -ExpandProperty Free

Write-Output "Database size: $dbSize MB"
Write-Output "Log size: $logSize MB"
Write-Output "Free space on $dataDrive: $dataDriveFreeSpace MB"
