function Invoke-API {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $Method,
        [Parameter(Mandatory = $true)]
        [String]
        $Endpoint
    )

    $BaseUri = "https://api.spacetraders.io"
    $Uri = $BaseUri + "/" + $Endpoint

    if ($env:SpaceTraders_Token) {
        $Bearer = "Bearer $env:SpaceTraders_Token"
    }
    elseif ($Token) {
        $Bearer = "Bearer $Token"
    }
    elseif (($null -eq $Token) -and ($null -eq $env:SpaceTraders_Token)) {
        Return "Please set token"
    }

    try {
        Invoke-RestMethod -Headers @{"Authorization" = $Bearer } -Method $Method -Uri $Uri
    }
    catch {
        Write-Error $_.Exception
    }
}

function New-AccessToken {
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Username
    )
    $Response = Invoke-API -Token $Token -Method "POST" -Endpoint "users/$Username/claim" 
    return $Response
}
Export-ModuleMember -Function New-AccessToken

function Update-ShipInfo {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $ShipId
    )
    $global:Ship = (Invoke-API -Token $Token -Method GET -Endpoint "my/ships/$Shipid").ship
}

function Get-ShipInfo {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $ShipId
    )
    $Response = (Invoke-API -Token $Token -Method GET -Endpoint "my/ships/$Shipid").ship
    return $Response
}

function Get-AccountDetails($Token) {
    $Response = (Invoke-API -Token $Token -Method "GET" -Endpoint "my/account").user
    return $Response
}

function Get-AvailableLoans($Token) {
    $Response = (Invoke-API -Token $Token -Method "GET" -Endpoint "types/loans").loans
    return $Response
}

function New-Loan($Token, $Type) {
    $Response = Invoke-API -Token $Token -Method "POST" -Endpoint "my/loans?type=$Type"
    return $Response
}

function Get-ActiveLoans {
    $Response = (Invoke-API -Token $Token -Method GET -Endpoint "my/loans").loans
    return $Response
}

function Get-PurchaseableShips($Token, $Class) {
    if ($Class) {
        $Endpoint = "systems/OE/ship-listings?class=$Class"
    }
    else {
        $Endpoint = "systems/OE/ship-listings"
    }
    $Response = (Invoke-API -Token $Token -Method "GET" -Endpoint $Endpoint).shipListings
    return $Response
}

function New-Ship() {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $Location,
        [Parameter(Mandatory = $true)]
        [String]
        $Type
    )
    $Response = Invoke-API -Token $Token -Method "POST" -Endpoint "my/ships?location=$Location&type=$Type"
    Update-ShipInfo -ShipId $Response.ship.id
}

function New-PurchaseOrder {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $ShipId,
        [Parameter(Mandatory = $true)]
        [String]
        $Good,
        [Parameter(Mandatory = $true)]
        [String]
        $Quantity
    )
    
    $Response = Invoke-API -Token $Token -Method "POST" -Endpoint "my/purchase-orders?shipId=$ShipId&good=$Good&quantity=$Quantity"
    Update-ShipInfo -ShipId $Response.ship.id
    return $Response
}

function Get-Marketplace {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $Location
    )
    
    $Response = (Invoke-API -Token $Token -Method "GET" -Endpoint "locations/$Location/marketplace").marketplace
    return $Response
}

function Get-SystemLocation {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $Type
    )
    
    $Response = (Invoke-API -Token $Token -Method "GET" -Endpoint "systems/OE/locations?type=$Type").locations
    return $Response
}

function Find-AvailableShip($Token) {
    $Response = ((Invoke-API -Method GET -Endpoint "my/ships").ships | Where-Object { $null -eq $flightPlanId })[0]
    return $Response
}

function New-FlightPlan {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $ShipId,
        [Parameter(Mandatory = $true)]
        [String]
        $Destination
    )

    $Response = (Invoke-API -Method POST -Endpoint "my/flight-plans?shipId=$ShipId&destination=$Destination").flightPlan
    Update-ShipInfo -ShipId $Respose.shipId
    return $Response
}

function Get-FlightPlan {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $FlightPlanId
    )

    $Response = (Invoke-API -Method GET -Endpoint "my/flight-plans/$FlightPlanId").flightPlan
    return $Response
}

function New-SellOrder {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $ShipId,
        [Parameter(Mandatory = $true)]
        [String]
        $Good,
        [Parameter(Mandatory = $true)]
        [String]
        $Quantity
    )

    $Response = Invoke-API -Method POST -Endpoint "my/sell-orders?shipId=$ShipId&good=$Good&quantity=$Quantity"
    Update-ShipInfo -ShipId $ShipId
    return $Response
}

function Get-CargoInformation {
    param (
        [Parameter()]
        [String]
        $Token,
        [Parameter(Mandatory = $true)]
        [String]
        $ShipId
    )

    $Response = (Invoke-API -Method GET -Endpoint "my/ships/$Shipid").ship.cargo
    return $Response
}