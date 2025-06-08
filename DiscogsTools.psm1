<#
	TODO:
	- [!P1] Add pagination support! (-Page, -GetAll)
	- [!P2] Expose FolderID to Get-DiscogCollection
#>

$GlobalHeaders = @{
    "User-Agent" = "DiscogsTools/1.0 +https://github.com/sigilpunk/DiscogsTools"
}


function Get-DiscogsUsernameFromUri {
	param([string]$Uri)
	$res = $Uri | Select-String -Pattern "^https:\/\/www\.discogs\.com\/user\/(.+)$"
	if ($res.Matches.Count -eq 0) {
		throw "Invalid Discogs URL."
	}
	return $res.Matches.Groups[1].Value
}


<#
	.SYNOPSIS
	Returns a Discogs user's collection.

	.DESCRIPTION
	Returns a PSCustomObject representation (or raw JSON content) of a specified Discogs user's collection of media.
	This function supports lookup by either the user's URI or their username and provides sorting capabilities.

	.PARAMETER Uri
	The URI of the target Discogs user.

	.PARAMETER Username
	The username of the target Discogs user.

	.PARAMETER SortBy
	The key of the field to sort entries by.
	Valid SortBy keys are:
	- label
	- artist
	- title
	- catno
	- format
	- rating
	- added
	- year

	.PARAMETER SortOrder
	Sort items in ascending or descending order (defaults to descending)
	Valid values are:
	- asc
	- desc

	.PARAMETER Json
	Return the collection as raw JSON.

	.EXAMPLE
	# Get mxtcha616's collection by username
	Get-DiscogCollection -Username "mxtcha616"

	.EXAMPLE
	# Get mxtcha616's collection by URI
	Get-DiscogCollection -Uri "https://www.discogs.com/user/mxtcha616"

	.EXAMPLE
	# Get mxtcha616's collection as raw JSON, sorted ascending by title
	Get-DiscogCollection -Json -Uri "https://www.discogs.com/user/mxtcha616" -SortBy "title" -SortOrder "asc"
#>
function Get-DiscogCollection {
	#region parameters

	[CmdletBinding(DefaultParameterSetName = "Uri")]
	param (
		[Parameter(Mandatory, ParameterSetName = "Uri")]
		[String]$Uri,
		
		[Parameter(Mandatory, ParameterSetName = "Username")]
		[String]$Username,

		[Parameter(Mandatory = $false)]
		[ValidateSet("label", "artist", "title", "catno", "format", "rating", "added", "year")] # https://www.discogs.com/developers#page:user-collection,header:user-collection-collection-items-by-folder
		[String]$SortBy,

		[Parameter(Mandatory = $false)]
		[ValidateSet("asc", "desc")] # https://www.discogs.com/developers#page:user-collection,header:user-collection-collection-items-by-folder
		[String]$SortOrder,

		[Parameter(Mandatory = $false)]
		[switch]$Json
	)

	#endregion

	#region Main flow

	if($PSCmdlet.ParameterSetName -eq "Uri") {
		$Username = Get-DiscogsUsernameFromUri -Uri $Uri
	}
	
	$ApiUri = "https://api.discogs.com/users/${Username}/collection/folders/0/releases?"

	if($SortBy) {
		$ApiUri += "sort=${SortBy}&"
	}

	if($SortOrder) {
		$ApiUri += "sort_order=${SortOrder}&"
	}

	try {
		$Collection = Invoke-RestMethod -Uri $ApiUri -Headers $GlobalHeaders
		if($Json) {
			return $Collection | ConvertTo-Json -Depth 10 -Compress
		} else {
			return $Collection
		}
	} catch {
		Write-Error "Failed to fetch collection: $_"
	}

	#endregion
}


<#
	.SYNOPSIS
	Returns a Discogs user's wantlist.

	.DESCRIPTION
	Returns a PSCustomObject representation (or raw JSON content) of a specified Discogs user's wantlist.
	This function supports lookup by either the user's URI or their username.

	.PARAMETER Uri
	The URI of the target Discogs user.

	.PARAMETER Username
	The username of the target Discogs user.

	.PARAMETER Json
	Return the collection as raw JSON.

	.EXAMPLE
	# Get mxtcha616's wantlist by username
	Get-DiscogWants -Username "mxtcha616"

	.EXAMPLE
	# Get mxtcha616's wantlist by URI
	Get-DiscogWants -Uri "https://www.discogs.com/user/mxtcha616"

	.EXAMPLE
	# Get mxtcha616's wantlist as raw JSON
	Get-DiscogWants -Json -Uri "https://www.discogs.com/user/mxtcha616"
#>
function Get-DiscogWants {
	#region parameters

	[CmdletBinding(DefaultParameterSetName = "Uri")]
	param (
		[Parameter(Mandatory, ParameterSetName = "Uri")]
		[String]$Uri,
		
		[Parameter(Mandatory, ParameterSetName = "Username")]
		[String]$Username,

		[Parameter(Mandatory = $false)]
		[switch]$Json
	)

	#endregion

	#region Main flow

	if($PSCmdlet.ParameterSetName -eq "Uri") {
		$Username = Get-DiscogsUsernameFromUri -Uri $Uri
	}

	$ApiUri = "https://api.discogs.com/users/${Username}/wants?"

	try {
		$Wants = Invoke-RestMethod -Uri $ApiUri -Headers $GlobalHeaders
		if($Json){
			return $Wants | ConvertTo-Json -Depth 10 -Compress
		} else {
			return $Wants
		}
	} catch {
		Write-Error "Failed to fetch wants: $_"
	}

	#endregion
}

Export-ModuleMember -Function Get-DiscogCollection
Export-ModuleMember -Function Get-DiscogWants