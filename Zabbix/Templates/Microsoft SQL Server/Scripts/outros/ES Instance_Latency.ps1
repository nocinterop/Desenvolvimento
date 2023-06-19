$instance = 'mssql 2019'
$dbName = 'YourDatabaseName'

$database = Get-WmiObject -ComputerName $instance -Namespace 'root\Microsoft\SqlServer\ComputerManagement' -Class 'SqlDatabase' | Where-Object { $_.Name -eq $dbName }
$databaseFiles = Get-WmiObject -ComputerName $instance -Namespace 'root\Microsoft\SqlServer\ComputerManagement' -Class 'SqlDatabaseFile' | Where-Object { $_.InstanceName -eq $instance -and $_.DatabaseID -eq $database.ID }

foreach ($file in $databaseFiles) {
    $filePath = $file.FileName
    $driveLetter = [System.IO.Path]::GetPathRoot($filePath)

    $ioStats = Get-WmiObject -ComputerName $instance -Class 'Win32_PerfFormattedData_PerfDisk_PhysicalDisk' |
                Where-Object { $_.Name -like "$driveLetter%" } |
                Select-Object -Property Name, AvgDiskSecPerRead, AvgDiskSecPerWrite

    $diskName = $ioStats.Name
    $readLatency = $ioStats.AvgDiskSecPerRead
    $writeLatency = $ioStats.AvgDiskSecPerWrite

    Write-Output "Disk: $diskName"
    Write-Output "Read latency (ms): $readLatency"
    Write-Output "Write latency (ms): $writeLatency"
    Write-Output ""
}
