<#
    .NOTES
    ===========================================================================
     Created on:    17/10/2022
     Created by:    Tiago Osvald Ramos, Leonardo Soares dos Santos
     Filename:      check_switchs_spanning-tree-state.ps1
    ===========================================================================
    .Synopsis
        Reach Switchs Spanning-tree state with SNMP v3
    .DESCRIPTION 
        

#>

Param (
    [Parameter(Mandatory=$true)][string]$Mode,
    [Parameter(Mandatory=$true)][string]$Option,
    #[Parameter(Mandatory=$false)][string]$Target,
    #[Parameter(Mandatory=$true)][string]$ItemOID,
    [Parameter(Mandatory=$true)][string]$Hostname,
    [Parameter(Mandatory=$true)][string]$UserName,
    #[Parameter(Mandatory=$true)][string]$AuthType,
    #[Parameter(Mandatory=$true)][string]$AuthSecret
	[Parameter(Mandatory=$true)][string]$Community
)

# Importacao de modulos
Try 
{
    #Import-Module -Name "C:\Program Files\Priax Agent\Modules\SNMPv3\SNMPv3\SNMPv3.psd1" -Force
}
Catch 
{
    #Write-Host $PSItem
    #throw "Import Module Failed"
}
	
#$Global:SaveLog = $true
##$LogPath = "C:\Temp\Logs"
##$LogFileName = "interface.log"  # must end with .log
#$Global:LogRetentionInDays = 7

# Funcao getSwitch
#function getSwitch {

  #  switch -wildcard ($Option)
  #  {
  #     "Spanning-treeStatus"
  #      {
  #         # exemplo chamada na linha de comando
			# .\check_switchs_spanning-tree-state-v5.ps1 -mode switch -option Spanning-treeStatus -UserName admin -Hostname 10.1.50.14 -Community M3d-S3n-SNmp

			# tempo de execucao de 1 a dois minutos
			#$retorno=(snmpwalk -v:2c -c:$Community -r:$Hostname | findstr 1.3.6.1.4.1.9.9.41.1.2.3.1.5 | findstr BPDU)
	  # 	$retorno=(snmpwalk -v:2c -c:$Community -r:$Hostname -os:1.3.6.1.4.1.9.9.41.1.2.3.1.1 -op:1.3.6.1.4.1.9.9.41.1.2.3.1.5 | findstr 1.3.6.1.4.1.9.9.41.1.2.3.1.5)
			#snmpwalk -v:2c -c:M3d-S3n-SNmp -r:10.1.50.34 -os:1.3.6.1.4.1.9.9.41.1.2.3.1.5 -op:1.3.6.1.4.1.9.9.41.1.2.3.1.6 -csv
			#echo $retorno
			#if ($retorno -like '*up*') {
			#	print $retorno
			#} else {
			#	echo $retorno
			#}
			 #   result=$(getSwitch)   
			#	  return $result

        #}
       # default
        #{
          #  throw "Invalid option selected"
        #}
    #}
#}

function getSwitch {
   switch -wildcard ($Option)
    {
        "Spanning-treeStatus"
       {
		   $result=(snmpwalk -v:2c -c:M3d-S3n-SNmp -r:$Hostname -os:1.3.6.1.4.1.9.9.41.1.2.3.1.5 -op:1.3.6.1.4.1.9.9.41.1.2.3.1.6 -csv) 
		   #Write-Host $result
           $interface= $result.split(",")[2]		   
           $Status= $result.split(",")[3]		    
		   #return $interface + $Status
		   $st= $Status.split(" ")	
		   if ($st -contains "err-disable")
		   {
		       $st= $Status.split(" ")[2]			
		   }
		   else
		   {
			   $st= 'OK'
		   }
		   return $st
       }
        default
        {
            throw "Invalid option selected"
        }
    }
}


function getWalkSNMPv3 {
    # exemplo snmpwalk
    # snmpwalk -v3 -l authPriv -u [User name] -a MD5 -A [User password] -x DES -X [DES password] [IP address of host] [OID of system information MIB]
    param ($tableOID)
    #param ($tableOID2)
    #param ($Target)

    try {
        $GetRequest = @{
        UserName = $UserName
        Target   = $Hostname
        OID      = $tableOID
        AuthType   = $AuthType
        AuthSecret = $AuthSecret    
        }
        #$result = Invoke-SNMPv3Get @GetRequest 
        $result = Invoke-SNMPv3Walk @GetRequest 
        #Write-Host $ItemOID
        return $result
        #Write-Host $result.value
        #[int]$saida = 1
        #Write-Output $saida

    }
    Catch {
        [int]$saida = 0
        Write-Output $saida 
        throw "SNMP Connection Fail" 
    }
}

function getChamadaSNMPv3 {

    param ($OID)

    try {
        $GetRequest = @{
        UserName = $UserName
        Target   = $Hostname
        OID      = $OID
        AuthType   = $AuthType
        AuthSecret = $AuthSecret    
        }

        $result = Invoke-SNMPv3Get @GetRequest 
        #Write-Host $result
        #Write-Host $result.value
        return $result.value
    }
    Catch {
        [int]$saida = 0
        Write-Output $saida 
        throw "SNMP Connection Fail" 
    }
}

# Run
function Run 
{ 
    # switch mode  
    switch -wildcard ($Mode) 
    {
	    "switch"
        {
            return getSwitch
        }
        default
        {
            throw "Invalid mode selected!"
        }
    }
}

# main function
function main 
{
    $r = Run
    Write-Output "$r"
}

main