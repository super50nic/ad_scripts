# Import the Active Directory module
Import-Module ActiveDirectory

# Define the path to the input CSV file and output CSV file
$InputCSV = "C:\Path\To\users.csv"
$OutputCSV = "C:\Path\To\UserDetails.csv"

# Import the list of identifiers (SamAccountName, EmployeeID, or Email) from the CSV file
$Users = Import-Csv -Path $InputCSV
$Identifiers = $Users.Identifier # Assume a column named 'Identifier'

# Initialize arrays to store results
$Results = @()
$NotFoundUsers = @()

# Define chunk size for batch queries (e.g., 500 identifiers per query)
$ChunkSize = 500

# Split the identifiers into chunks
$Chunks = $Identifiers | ForEach-Object -Begin { $chunk = @() } `
                        -Process { $chunk += $_; if ($chunk.Count -ge $ChunkSize) { $chunk; $chunk = @() } } `
                        -End { if ($chunk) { $chunk } }

# Process each chunk in parallel
$Results = $Chunks | ForEach-Object -Parallel {
    Import-Module ActiveDirectory # Import module in the parallel runspace

    # Prepare an array for results in this thread
    $ThreadResults = @()
    $ThreadNotFound = @()

    foreach ($Identifier in $_) {
        try {
            # Determine whether input is Email, EmployeeID, or SamAccountName
            if ($Identifier -match '@') {
                $User = Get-ADUser -Filter "Mail -eq '$Identifier'" -Properties Department, DisplayName
            } elseif ($Identifier -match '^a\d{8}$') {
                $User = Get-ADUser -Filter "EmployeeID -eq '$Identifier'" -Properties Department, DisplayName
            } else {
                $User = Get-ADUser -Identity $Identifier -Properties Department, DisplayName
            }

            # Process the user if found
            if ($User -ne $null) {
                # Add to results
                $ThreadResults += [PSCustomObject]@{
                    SamAccountName = $User.SamAccountName
                    DisplayName    = $User.DisplayName
                    Department     = $User.Department
                }
            } else {
                # Add to "not found" list
                $ThreadNotFound += $Identifier
            }
        } catch {
            # Handle errors and add to "not found" list
            $ThreadNotFound += $Identifier
        }
    }

    # Return results and not-found users
    @($ThreadResults, $ThreadNotFound)
} -ThrottleLimit 4 # Adjust throttle limit based on resources

# Aggregate results from all threads
foreach ($ResultSet in $Results) {
    $Results += $ResultSet[0]
    $NotFoundUsers += $ResultSet[1]
}

# Export results to CSV files
if ($Results.Count -gt 0) {
    $Results | Export-Csv -Path $OutputCSV -NoTypeInformation -Encoding UTF8
}

if ($NotFoundUsers.Count -gt 0) {
    $NotFoundUsers | ForEach-Object { [PSCustomObject]@{ Identifier = $_ } } | Export-Csv -Path "C:\Path\To\NotFoundUsers.csv" -NoTypeInformation -Encoding UTF8
}

Write-Host "Script completed. Results saved to $OutputCSV and missing users saved to NotFoundUsers.csv."
