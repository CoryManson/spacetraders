Import-Module $PSScriptRoot/Modules/spacetraders/spacetraders.psd1
# Create Cache Folders
New-Item -ItemType Directory -Path ./cache/marketplace -Force

# Register an Account
$Username = -join ((65..90) + (97..122) | Get-Random -Count 5 | ForEach-Object { [char]$_ })
$Token = New-AccessToken -Username $Username

# Get Startup Loan
Write-Host "Taking startup loan"
New-Loan -Token $Token -Type STARTUP

# Purchase a JW-MK-I Ship
Write-Host "Purchasing JW-MK-I ship"
$PurchaseableShip = (Get-PurchaseableShips -Token $Token -Class "MK-I" | Where-Object { $_.type -eq "JW-MK-I" })[0]
$Ship = (New-Ship -Token $Token -Location $PurchaseableShip.purchaseLocations.location -Type $PurchaseableShip.Type).Ship

# Purchase 20 units of fuel
Write-Host "Purchasing 20 units of fuel"
$FuelNeeded = 20 - (($Ship.cargo | where-object { $_.good -eq "FUEL" }).quantity)
New-PurchaseOrder -Token $Token -ShipId $Ship.Id -Good FUEL -Quantity $FuelNeeded

# Update Ship Info
$Ship = Update-ShipInfo -Token $Token -ShipId $Ship.id

# Dump Marketplace Info for Current Location
Write-Host "Dumping marketplace Info for current location"
Get-Marketplace -Token $Token -Location $Ship.location | ConvertTo-Json | Out-File -Path $PSScriptRoot/cache/marketplace/$($Ship.Location).json -Force

# Purchase Metals
Write-Host "Purchasing metals"
$PurchasePrice = (Get-Marketplace -Token $Token -Location $Ship.location | Where-Object {$_.symbol -eq "METALS"}).purchasePricePerUnit
New-PurchaseOrder -Token $Token -ShipId $Ship.Id -Good "METALS" -Quantity ($ship.spaceAvailable -5)

# Update Ship Info
$Ship = Update-ShipInfo -Token $Token -ShipId $Ship.id

# Get list of available locations in system
Write-Host "Getting list of available locations"
$Locations = Get-SystemLocation -Token $Token -Type "PLANET" | Where-Object {$_.symbol -ne $Ship.location}

# Create flight plan to another planet with metals
Write-Host "Creating flight plan"
$Destination = $Locations | Where-object {$_.symbol -ne $Ship.location} | Where-Object {$_.traits -contains "METAL_ORES"} | Get-Random
Write-Host "Destination is $($Destination.symbol)"
$Flightplan = New-FlightPlan -Token $Token -ShipId $Ship.id -Destination $Destination.symbol

while ($Flightplan.timeRemainingInSeconds -gt 0) {
    Write-Host "$($Flightplan.timeRemainingInSeconds) seconds remaining...."
    Start-Sleep -Seconds 5
    $Flightplan = Get-FlightPlan -Token $Token -FlightPlanId $Flightplan.id
}

# Sell Metals as long as they're below purchase price

# Update Ship Info
$Ship = Update-ShipInfo -Token $Token -ShipId $Ship.id
# Dump Marketplace Info for Current Location
Write-Host "Selling metals at location $($Ship.Location)"
Get-Marketplace -Token $Token -Location $Ship.location | ConvertTo-Json | Out-File -Path ./cache/marketplace/$($Ship.Location).json -Force
$CurrentMarketplace = Get-Content -Path ./cache/marketplace/$($Ship.Location).json | ConvertFrom-Json
$Sellprice = ($CurrentMarketplace | Where-Object {$_.symbol -eq "METALS"}).sellPricePerUnit
Write-Host "Purchase Price: $PurchasePrice Sell Price: $SellPrice"
if ($SellPrice -gt $PurchasePrice) {
    New-SellOrder -Token $Token -ShipId $Ship.id -Good METALS -Quantity ($ship.cargo | Where-Object {$_.good -eq "METALS"}).quantity
}
