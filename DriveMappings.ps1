<#
script pulls all drive mappings contained in GPO's
!!!! Note: Script will prompt you for the domain you wish to search !!!! 
Recommended to be run with elevated account permissions
written on 20240813 by NCM
#>

# Import the required module GroupPolicy
try {
    Import-Module GroupPolicy -ErrorAction Stop
} catch {
    throw "Module GroupPolicy not Installed"
}

# Define the specific domain to search
$domain = Read-Host "Please enter the domain you want to search"

# Define the path for the CSV output
$outputCsv = "C:\Temp\GPO_DriveMappings.csv"

# Create an empty array to hold the results
$results = @()

$GPO = Get-GPO -All -Domain $domain

foreach ($Policy in $GPO) {

    $GPOID = $Policy.Id
    $GPODom = $Policy.DomainName
    $GPODisp = $Policy.DisplayName

    if (Test-Path "\\$($GPODom)\SYSVOL\$($GPODom)\Policies\{$($GPOID)}\User\Preferences\Drives\Drives.xml") {
        [xml]$DriveXML = Get-Content "\\$($GPODom)\SYSVOL\$($GPODom)\Policies\{$($GPOID)}\User\Preferences\Drives\Drives.xml"

        foreach ($drivemap in $DriveXML.Drives.Drive) {

            $result = New-Object PSObject -Property @{
                GPOName = $GPODisp
                DriveLetter = $drivemap.Properties.Letter + ":"
                DrivePath = $drivemap.Properties.Path
                DriveAction = $drivemap.Properties.action.Replace("U", "Update").Replace("C", "Create").Replace("D", "Delete").Replace("R", "Replace")
                DriveLabel = $drivemap.Properties.label
                DrivePersistent = $drivemap.Properties.persistent.Replace("0", "False").Replace("1", "True")
                DriveFilterGroup = $drivemap.Filters.FilterGroup.Name
            }

            # Add the custom object to the results array
            $results += $result
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path $outputCsv -NoTypeInformation

# Output the path to the CSV file
Write-Host "Drive mappings have been written to:" $outputCsv
