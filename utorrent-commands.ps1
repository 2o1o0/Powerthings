<#	
	.NOTES
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2016 v5.2.119
	 Created on:   	12/04/2016 23:27
	 Created by:   	2o1o0
	 Organization: 	
	 Filename:     	
	===========================================================================
	.DESCRIPTION
		A set of function to remote control utorrent.
#>
function Get-utorrent-torrents
{
		<#
	.SYNOPSIS
		Get a torrents list from a utorrent client with WebGUI enabled. NO TOKEN AUTH. LOCAL USE ONLY.
	
	.DESCRIPTION
		Return a hashtable with following torrents details : 
		Hash, status, name, size, % progress, downloaded, uploaded, ratio, upload speed (bps), download speed (bps), ETA (seconds), 
		label, peers connected, peers (swarm), seeds connected, seeds (swarm), availability, queue order, remaining
	
	.PARAMETER server
		Server IP or hostname
	
	.PARAMETER port
		Server port (by default, same as listning port)
	
	.PARAMETER user
		server webui user
	
	.PARAMETER password
		server webui password
	
	.PARAMETER torrenthash
		torrent to delete hash
	
	.PARAMETER torrentname
		A description of the torrentname parameter.
	
	.NOTES
		STATUS: The STATUS is a bitwise value, which is obtained by adding up the different values for corresponding statuses:
		1 = Started / 2 = Checking / 4 = Start after check / 8 = Checked / 16 = Error / 32 = Paused / 64 = Queued / 128 = Loaded
		For example, if a torrent job has a status of 201 = 128 + 64 + 8 + 1, then it is loaded, queued, checked, and started.
		A bitwise AND operator should be used to determine whether the given STATUS contains a particular status.
	
	.EXAMPLE
		Get-utorrent-torrents  -server torrentsrv -port 15000 -user admin -password pass 
		Will connect to utorrent on torrentsrv:15000 as admin and return torrents list
	.LINK
		https://forum.utorrent.com/topic/21814-web-ui-api/
	#>
	[CmdletBinding()]
	[OutputType([hashtable])]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[string]$server,
		[Parameter(Mandatory = $true,
				   Position = 2)]
		[int32]$port,
		[Parameter(Mandatory = $true,
				   Position = 3)]
		[string]$user,
		[Parameter(Mandatory = $true,
				   Position = 4)]
		[string]$password
	)
	$uri = "http://$($Server):$($Port)/gui/?list=1"
	$secpasswd = ConvertTo-SecureString $user -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential ($pass, $secpasswd)
	$json = Invoke-RestMethod -Uri $uri -Method get -Credential $cred -ContentType "application/json" -UseBasicParsing
	$torrents = @{ }
	foreach ($torrent in $json.torrents)
	{
		$torrentdetails = @{
			[string]"hash" = $torrent[0];
			"status" = $torrent[1]; # 201 =  loaded, queued, checked, and started!
			[string]"name" = $torrent[2];
			"size" = $torrent[3];
			"progress(%)" = $torrent[4];
			"downloaded" = $torrent[5];
			"uploaded" = $torrent[6];
			"ratio" = $torrent[7];
			"uploadspeed" = $torrent[8];
			"downloadspeed" = $torrent[9];
			"ETA" = $torrent[10];
			"label" = $torrent[11];
			"peersconnected" = $torrent[12];
			"peers(swarm)" = $torrent[13];
			"seedsconnected" = $torrent[14];
			"seeds(swarm)" = $torrent[15];
			"availability" = $torrent[16];
			"queue" = $torrent[17];
			"remaining" = $torrent[18];
		}
		$torrents.Add($torrent[2], $torrentdetails)
	}
	return $torrents
}

function Remove-utorrent-torrent
{
	<#
	.SYNOPSIS
		Remove a torrent from a utorrent client with WebGUI enabled. NO TOKEN AUTH. LOCAL USE ONLY.
	
	.DESCRIPTION
		Remove a file from its hash or name
	
	.PARAMETER server
		Server IP or hostname
	
	.PARAMETER port
		Server port (by default, same as listning port)
	
	.PARAMETER user
		server webui user
	
	.PARAMETER password
		server webui password
	
	.PARAMETER torrenthash
		torrent to delete hash
	
	.PARAMETER torrentname
		torrent to delete name
	
	.EXAMPLE
		Remove-utorrent-torrent -server torrentsrv -port 15000 -user admin -password pass -torrenthash CD3E77BBF7DDE3DD6A7A1492D1578C6062AFCB20
		Will connect to utorrent on torrentsrv:15000 as admin to delete torrent with hash CD3E77BBF7DDE3DD6A7A1492D1578C6062AFCB20
	.EXAMPLE
		Remove-utorrent-torrent -server torrentsrv -port 15000 -user admin -password pass -torrentname linuxdistribv1.0
		Will connect to utorrent on torrentsrv:15000 as admin to delete torrent with name linuxdistribv1.0
#>
	[CmdletBinding(DefaultParameterSetName = 'byname')]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 1)]
		[Alias('instance')]
		[string]$server,
		[Parameter(Mandatory = $true,
				   Position = 2)]
		[int32]$port,
		[Parameter(Mandatory = $true,
				   Position = 3)]
		[string]$user,
		[Parameter(Mandatory = $true,
				   Position = 4)]
		[string]$password,
		[Parameter(ParameterSetName = 'byhash',
				   Mandatory = $true,
				   Position = 5)]
		[string]$torrenthash,
		[Parameter(ParameterSetName = 'byname',
				   Mandatory = $true,
				   Position = 6)]
		[string]$torrentname
	)
	
	$secpasswd = ConvertTo-SecureString $user -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential ($pass, $secpasswd)
	
	[string]$uritorrents = "http://$($Server):$($Port)/gui/?list=1"
	
	
	
	if ($torrenthash)
	{
		$uriremove = "http://$($Server):$($Port)/gui/?action=removedata&hash=$($torrenthash)"
		$uricheck = "http://$($Server):$($Port)/gui/?action=getprops&hash=$($torrenthash)"
		
		Invoke-RestMethod -Uri $uriremove -Method get -Credential $cred
		if (!$(Invoke-RestMethod -Uri $uricheck -Method get -Credential $cred -ContentType "application/json"))
		{
			Write-Error "couldnt remove torrent"
		}
	}
	else
	{
		$json = Invoke-RestMethod -Uri $uritorrents -Method get -Credential $cred -ContentType "application/json" -UseBasicParsing
		[hashtable]$torrents = @{ }
		foreach ($torrent in $json.torrents)
		{
			$torrents.Add([string]$torrent[2], [string]$torrent[0])
		}
		[string]$uriremove = "http://$($Server):$($Port)/gui/?action=removedata&hash=$($torrents[$torrentname])"
		[string]$uricheck = "http://$($Server):$($Port)/gui/?action=getprops&hash=$($torrents[$torrentname])"
		Invoke-RestMethod -Uri $uriremove -Method get -Credential $cred
		if (!$(Invoke-RestMethod -Uri $uricheck -Method get -Credential $cred -ContentType "application/json"))
		{
			Write-Error "couldnt remove torrent"
		}
	}
}