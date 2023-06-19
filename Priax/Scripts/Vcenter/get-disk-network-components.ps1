<# 
Opções indicador = power, temp
UserName= 'priax-monitor'
Password='f6v%d&5>89@7'

Example: .\check_datasource_nic.ps1'

#>

# main function

Param (
    [Parameter(Mandatory=$true)][string]$HostEsxi,
	[Parameter(Mandatory=$true)][string]$Option,
	[Parameter(Mandatory=$true)][string]$Mode,
	[Parameter(Mandatory=$true)][string]$Target
    #[Parameter(Mandatory=$true)][string]$Indicator
    )
	
function targetDSExists
{
	param($data)
	foreach ($d in $data)
	{
		if ($Target -eq $d.diskname) {
			return $true
		} else {
			return $false
		}
	}
}


function targetNetExists
{
	param($data)
	foreach ($d in $data)
	{
		if ($Target -eq $d.nameinterface) {
			return $true
		} else {
			return $false
		}
	}
}



function getReceicedBytes
{
	foreach ($d in $data)
    {
		foreach ($nic in $d.all_network)
		{
			if (targetNetExists -data $nic) 
			{
				return $nic.received
			} 
			else
			{
				continue
			}
		}
    }
    throw "Not Found DS: $Target in Host: $HostEsxi"

}

function getSentBytes
{
	foreach ($d in $data)
    {
		foreach ($nic in $d.all_network)
		{
			if (targetNetExists -data $nic) 
			{
				return $nic.transmitted
			} 
			else
			{
				continue
			}
		}
    }
    throw "Not Found DS: $Target in Host: $HostEsxi"

}




function getTotalSpace
{
	foreach ($d in $data)
    {
		foreach ($disk in $d.all_disk)
		{
			if (targetDSExists -data $disk) 
			{
				return $disk.disktotal
			} 
			else
			{
				continue
			}
		}
    }
    throw "Not Found DS: $Target in Host: $HostEsxi"
}


function getFreeSpace
{
    # return percentage of free space

    foreach ($d in $data)
    {
		foreach ($disk in $d.all_disk)
		{
			if (targetDSExists -data $disk)
			{
				return $disk.freediskperc
			}
			else
			{
				continue
			}
		}
	}
	throw "Not Found DS: $Target in Host: $HostEsxi"
}


function getDataStore 
{
    switch -wildcard ($Option)
    {
        "totalSpace"
        {
            return getTotalSpace
        }
        "FreeSpace"
        {
            return getFreeSpace
        }
        default
        {
            throw "Invalid option selected"
        }        
    }
    Write-Host Target = "$Target"
}

function getNetwork
{
    switch -wildcard ($Option)
    {
        "bytesreceived"
        {
            return getReceicedBytes
        }
        "bytessent"
        {
            return getSentBytes
        }
        default
        {
            throw "Invalid option selected"
        }        
    }
    Write-Host Target = "$Target"


}

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
	}
	return $data

}



function Run
{
    switch -wildcard ($Mode)
	{
	    "ds"
        {
            return getDataStore
        }
        "net"
        {
            return getNetwork
        } 
        default
        {
            throw "Invalid mode selected!"
        }
    }
}


function main 
{
    $path = "C:\temp\disk-nic-data-" + $HostEsxi + ".json"
	$data = ReadVmWareData -path $path
	
    $resp = Run
    write-output $resp
}

main