<#
    .NOTES
    ===========================================================================
     Created on:    Tue Mar  3 18:00:00 -02 2021
     Created by:    Wagner Garcez
     Filename:      check_vcenter_components.ps1
    ===========================================================================
    .Synopsis
        Monitoring vcenter components by dump file
    .DESCRIPTION
        Validates the status of datastores and virtual machines
    .PARAMETER DatacenterName
        Name of Datacenter in vcenter
    .PARAMETER ClusterName
        Name of Cluster in vcenter
    .PARAMETER Target
        Target to be monitored
    .PARAMETER Option
        Target options to be monitored
     .PARAMETER Mode
        Monitoring mode
    .EXAMPLE
        check_vcenter_components.ps1 -DatacenterName <STRING> -ClusterName <STRING> -Mode <STRING> -Target <STRING> -Option <STRING>        
        
        DS
        ::FreeSpace
            check_vcenter_components.ps1 -DatacenterName 'Cloud_SescDN 01' -ClusterName 'Cluster_Prod_01' -Mode "DS" -Target "STG36_V7000_VMFS_SAS" -Option "FreeSpace" 
        ::Accessible
            check_vcenter_components.ps1 -DatacenterName 'Cloud_SescDN 01' -ClusterName 'Cluster_Prod_01' -Mode "DS" -Target "STG36_V7000_VMFS_SAS" -Option "Accessible"         
        VM
        ::PowerState
            check_vcenter_components.ps1 -DatacenterName 'Cloud_SescDN 01' -ClusterName 'Cluster_Prod_01' -Mode "VM" -Target "ESEMVM211 (IIS - Homologação)" -Option "PowerState" 

#>

Param (
    [Parameter(Mandatory=$true)][string]$Mode,
    [Parameter(Mandatory=$true)][string]$Option,
    [Parameter(Mandatory=$true)][string]$Target,
    [Parameter(Mandatory=$false)][string]$ClusterName,
    [Parameter(Mandatory=$true)][string]$DatacenterName
    )

# functions aux
function targetVMExists 
{
    param($data)

    if ($Target -eq $d.Name -And $ClusterName -eq $d.cluster -And $DatacenterName -eq $d.datacenter) {
        return $true
    } else {
        return $false
    }
}

function targetDSExists 
{
    param($data)

    if ($Target -eq $d.Name -And $DatacenterName -eq $d.datacenter) {
        return $true
    } else {
        return $false
    }
}

# get options
function getPowerState
{
    # return VM status

    # Enum - VirtualMachinePowerState
    #
    # CODE	NAME		DESCRIPTION
    # 0		poweredOff	The virtual machine is currently powered off.
    # 1 	poweredOn	The virtual machine is currently powered on.
    # 2		suspended	The virtual machine is currently suspended.
    
    foreach ($d in $data)
    {
        $a = 0
        if (targetVMExists -data $d) 
        {
            return $d.Runtime
        }
        else 
        {
            continue
        }
        
    }
    throw "Not Found VM: $Target in Datacenter: '$DatacenterName' Cluster: '$ClusterName'"
}

function getAccessible
{
    # return: datastores is accessible

    # Enum - DatastoreAccessible(vim.Datastore.Accessible)
    # 
    # NAME	DESCRIPTION
    # False	Is not accessible
    # True	Is accessible
    
    foreach ($d in $data)
    {
        if (targetDSExists -data $d) 
        {
            return $d.accessible
        } 
        else
        {
            continue
        }
    }
    throw "Not Found DS: $Target in Datacenter: '$DatacenterName' Cluster: '$ClusterName'"
}

function getFreeSpace
{
    # return percentage of free space

    foreach ($d in $data)
    {
        if (targetDSExists -data $d) 
        {
            try
            {
                $capacity = $d.capacity
                $freeSpace = $d.freeSpace
                return [math]::round( ($freeSpace * 100) / $capacity,2)
            }
            Catch
            {
                throw "Error during calculation: function getFreeSpace"
            }
        } else 
        {
            continue
        }
    }
    throw "Not Found DS: '$Target' in Datacenter: '$DatacenterName' Cluster: '$ClusterName'"
}

# switch Options
function getVM 
{
    switch -wildcard ($Option)
    {
        "PowerState"
        {
            return getPowerState
        }
        default
        {
            throw "Invalid option selected"
        }        
    }
    Write-Host Target = "$Target"
}

function getDataStore 
{
    switch -wildcard ($Option)
    {
        "Accessible"
        {
            return getAccessible
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

# Run
function Run 
{ 
    # switch mode  
    switch -wildcard ($Mode) 
    {
	    "DS"
        {
            return getDataStore
        }
        "VM"
        {
            return getVM
        } 
        default
        {
            throw "Invalid mode selected!"
        }
    }
}

# read JSON file
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
    $path = "C:\temp\" + $DatacenterName + "-" + $Mode + ".json"
    $data = ReadVmWareData -path $path
    $r = Run
    Write-Output "$r"
}

main
