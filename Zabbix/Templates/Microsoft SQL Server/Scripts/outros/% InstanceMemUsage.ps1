$instance = 'mssql 2019'

$memUsage = Get-Counter -Counter "\Memory\Available MBytes" -SampleInterval 1 -MaxSamples 5 | Select-Object -ExpandProperty CounterSamples | Measure-Object -Property CookedValue -Average | Select-Object -ExpandProperty Average

Write-Output "Memory usage for SQL Server instance $instance: $memUsage MB"
