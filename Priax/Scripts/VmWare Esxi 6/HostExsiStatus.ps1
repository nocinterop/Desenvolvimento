Param (
    [Parameter(Mandatory=$true)][string]$HostEsxi,
    [Parameter(Mandatory=$true)][string]$UserName,
    [Parameter(Mandatory=$true)][string]$Password
    )
	
# Import dos modulos powerCLI
Try 
{
    Import-Module "C:\Program Files\PHDService\Modules\VMware\VMware.VimAutomation.Sdk\11.2.0.12483635\VMware.VimAutomation.Sdk.psd1"
    Import-Module "C:\Program Files\PHDService\Modules\VMware\VMware.VimAutomation.Common\11.2.0.12483627\VMware.VimAutomation.Common.psd1"
    Import-Module "C:\Program Files\PHDService\Modules\VMware\VMware.Vim\6.7.0.12483609\VMware.Vim.psd1"
    Import-Module "C:\Program Files\PHDService\Modules\VMware\VMware.VimAutomation.Cis.Core\11.2.0.12483642\VMware.VimAutomation.Cis.Core.psd1"
    Import-Module "C:\Program Files\PHDService\Modules\VMware\VMware.VimAutomation.Core\11.2.0.12483638\VMware.VimAutomation.Core.psd1"
}
Catch
{ 
    throw "Import Module Failed" 
}

Try 
{
	$SecPassword = ConvertTo-SecureString $Password -AsPlainText -Force
	$cred = new-object -typename System.Management.Automation.PSCredential ($UserName, $secPassword)
	$session = Connect-VIServer $HostEsxi -Protocol https -Credential $cred -NotDefault
}
Catch
{ 
    throw "Host Connection Fail"
}
$filters = @('power','voltage','temperature','Memory','Storage','System')
$results = @()
$all_Status = @()
$results_network = @()
$results_disk = @()


$data=Get-VMHost -Server $HostEsxi | Get-View
$use=Get-VMHost -Server $HostEsxi
$esxcli=Get-EsxCli -Server $HostEsxi -V2
$interfaces=$esxcli.network.nic.list.Invoke() | ForEach-Object -Process {$esxcli.network.nic.stats.get.Invoke(@{nicname=$_.Name}) | select @{N='VMHost';E={$esxcli.VMHost.Name}}, NICName,Bytesreceived,Bytessent}
$datastores = Get-VMHost -server $HostEsxi | Get-Datastore

$UseMemPerc = [math]::round(($use.MemoryUsageGB * 100 / $use.MemoryTotalGB),0)
$UseCpuPerc = [math]::round(($use.CpuUsageMhz * 100 / $use.CpuTotalMhz),0)

$sensor_info = "" | select OverallStatus, UsageMem, UsageCpu
$sensor_info.OverallStatus = $data.OverallStatus
$sensor_info.UsageMem = $UseMemPerc
$sensor_info.UsageCpu = $UseCpuPerc

$results += $sensor_info


foreach ($item in $filters)
{
    $sensor_info = "" | select Sensor, generalStatus
	$sensor_info.Sensor = $item
	
    foreach ($resource in ($data.Runtime.HealthSystemRuntime.SystemHealthInfo.NumericSensorInfo | where{$_.SensorType -eq "$item"}))
    {	
	    $all_Status += $resource.HealthState.Label		
    }
	# Valida se existem algo nÃ£o ok
	if ($all_Status -notcontains "Green") 
	{
	    $sensor_info.generalStatus = 0			
	}
	else
	{
	    $sensor_info.generalStatus = 1
	}
	#Write-Output $sensor_info
	$results += $sensor_info
}

######### Create Data Interface Throughput ######################
foreach ($nicdata in $interfaces)
{
   $namenic = $nicdata.NICName
   $newreceivedata = $nicdata.Bytesreceived 
   $newsenddata = $nicdata.Bytessent
   $totalsenddata = 0
   $totalreceivedata = 0
   # Coletando dados antigos no arquivo JSON
   $path = "C:\temp\disk-nic-data-" + $HostEsxi + ".json"
   $data = Get-Content -Path $path -ErrorAction Stop -Raw | ConvertFrom-Json
   foreach ($n in $data.all_network)
   {
		if ($namenic -eq $n.nameinterface) 
		{
			$oldsenddata = $n.olddatasend
			$oldreceivedata = $n.olddatareceive
		}
		
   }
   
   $totalsenddata = $newsenddata - $oldsenddata
   $totalreceivedata = $newreceivedata - $oldreceivedata
   $throughput_info = "" | select nameinterface, received, transmitted, olddatasend, olddatareceive
   $throughput_info.nameinterface = $namenic

   # Campos com dados usados no monitoramento
   $throughput_info.received = $totalreceivedata
   $throughput_info.transmitted = $totalsenddata

   # Campo com dados da coleta anterior 
   $throughput_info.olddatasend = $newsenddata
   $throughput_info.olddatareceive = $newreceivedata
   
   $results_network += $throughput_info
}

#################### Create Datastore data #######################
foreach ($diskdata in $datastores)
{
   $namedisk = $diskdata.Name
   $freedisk = $diskdata.FreeSpaceGB
   $totaldisk = $diskdata.CapacityGB
   $perfreedisk = [math]::round(($freedisk * 100 / $totaldisk),0)
   $disk_info = "" | select diskname, disktotal, freediskperc
   $disk_info.diskname = $namedisk
   #$disk_info.diskfree = $freedisk
   $disk_info.disktotal = $totaldisk
   $disk_info.freediskperc = $perfreedisk
   
   $results_disk += $disk_info
}

########### Zip all file ####################
$all_info = "" | select all_disk, all_network
$all_info.all_network = $results_network
$all_info.all_disk = $results_disk
$all_result += $all_info

############## Path file ######################
$out_file = "C:\temp\data"
$net_out_file = "C:\temp\disk-nic-data"


############# Test Connect Host ##################
if ($session) 
{
    try 
    {
        if(-Not ($results.Count -eq 0))
        {
            $results | ConvertTo-Json | Out-File "$out_file-$HostEsxi.json"
			#$results_network | ConvertTo-Json | Out-File "$net_out_file-$HostEsxi.json"
			$all_result | ConvertTo-Json | Out-File "$net_out_file-$HostEsxi.json"
            [int]$saida = 1
            Write-Output $saida
        }
        else 
        {
            [int]$saida = 0
            Write-Output $saida
        }
    } 
    Catch
    { 
        throw "Export Failure! JSON File not created: $out_file"
    }
} 
else 
{ 
    [int]$saida = 0
    Write-Output $saida
}
try{
	Disconnect-VIServer -Server $HostEsxi -Force:$true -Confirm:$false -ErrorAction SilentlyContinue
}
catch{}
