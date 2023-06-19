$instance = 'mssql 2019'

$cpuUsage = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5 | Select-Object -ExpandProperty CounterSamples | Measure-Object -Property CookedValue -Average | Select-Object -ExpandProperty Average

Write-Output "CPU usage for SQL Server instance $instance: $cpuUsage%"
