<# 
$indicador = UsageMem, UsageCpu, AllStatus, Sensor
$option = Sensors, resources
$Target = "Nome do objeto no priax"
UserName= 'priax-monitor'


Example: .\check_Esxi_components.ps1 -HostEsxi '10.1.1.115' -Option 'resources' -Indicator 'UsageMem'

#>


Param (
    [Parameter(Mandatory=$true)][string]$HostEsxi,
	[Parameter(Mandatory=$true)][string]$Option,
    [Parameter(Mandatory=$true)][string]$Indicator
    )


function ResourceExists
{
    param($data)

    if ($Indicator)
	{
        return $true
    } else {
        return $false
    }
}

function SensorExists 
{
    param($data)

    if ($Indicator -eq $d.Sensor) 
	{
        return $true
    } else {
        return $false
    }
}

# Function Get Resources
function StatusResources
{ 
    foreach ($d in $data)
    {
        if (ResourceExists -data $d) 
        {	
            return $d.$Indicator
        } 
        else
        {
            continue
        }
    }
    throw "Not Found Object: $Indicator in Host: '$HostEsxi'"
}

# Function Get Sensors
function statusSensors
{ 
    foreach ($d in $data)
    {
        if (SensorExists -data $d) 
        {
            return $d.generalStatus
        } 
        else
        {
            continue
        }
    }
    throw "Not Found status: $Indicator in Host: '$HostEsxi'"
}


function Run 
{ 
    # switch mode  
    switch -wildcard ($Option) 
    {
	    "resources"
        {
            return StatusResources
        }
        "sensors"
        {
            return statusSensors
        } 
        default
        {
            throw "Invalid mode selected!"
        }
    }
}

# Read JSON file
function ReadVmWareData 
{
    for($i=0;$i -lt 3;$i++)
    {
        try
        {
            $data = Get-Content -Path $path -ErrorAction Stop -Raw | ConvertFrom-Json
            return $data
        } 
        catch [System.IO.IOException] 
        {
            $data = $false
            start-sleep 1
        }
        catch
        {
            $data = $false
            start-sleep 1
        }
    }
    return $data
}


# main function
function main 
{
    $path = "C:\temp\data-" + $HostEsxi + ".json"
    $data = ReadVmWareData -path $path
    $r = Run
    Write-Output "$r"
}

main