# Ensure Active Directory module is imported
Import-Module ActiveDirectory

# Function to recursively get group memberships with depth tracking
function Get-RecursiveGroupMembership {
    param (
        [Parameter(Mandatory=$true)]
        [string]$GroupName,
        [System.Text.StringBuilder]$MarkdownBuilder = $null,
        [int]$Depth = 0,
        [System.Collections.Generic.HashSet[string]]$VisitedGroups = $null
    )

    # Initialize Markdown Builder for output
    if ($null -eq $MarkdownBuilder) {
        $MarkdownBuilder = [System.Text.StringBuilder]::new()
    }

    # Initialize HashSet to prevent infinite recursion
    if ($null -eq $VisitedGroups) {
        $VisitedGroups = [System.Collections.Generic.HashSet[string]]::new()
    }

    # Prevent revisiting groups
    if ($VisitedGroups.Contains($GroupName)) {
        return
    }
    $VisitedGroups.Add($GroupName) | Out-Null

    try {
        # Get group details
        $group = Get-ADGroup -Identity $GroupName -Properties MemberOf, Description
        $groupDescription = if ($group.Description) { "($($group.Description))" } else { "" }

        # Indent based on depth and add the group to Markdown output
        $indent = ("  " * $Depth) + "- "
        $MarkdownBuilder.AppendLine("$indent$GroupName $groupDescription") | Out-Null

        # Recurse into parent groups
        if ($group.MemberOf) {
            foreach ($parentGroupDN in $group.MemberOf) {
                try {
                    $parentGroup = Get-ADGroup -Identity $parentGroupDN -Properties Description
                    $parentGroupName = $parentGroup.Name
                    Get-RecursiveGroupMembership -GroupName $parentGroupName -MarkdownBuilder $MarkdownBuilder -Depth ($Depth + 1) -VisitedGroups $VisitedGroups
                }
                catch {
                    # Log the error and continue with next group
                    Write-Warning "Skipping parent group ($parentGroupDN) - Group may no longer exist: $($_.Exception.Message)"
                    continue
                }
            }
        }
    }
    catch {
        Write-Warning "Skipping group ($GroupName) - Group may no longer exist: $($_.Exception.Message)"
        return $MarkdownBuilder
    }

    return $MarkdownBuilder
}

# Main script execution
try {
    # Prompt for SAM account name
    $samAccountName = Read-Host "Enter the user's SAM account name"

    # Get user's direct group memberships
    $user = Get-ADUser -Identity $samAccountName -Properties MemberOf
    $userGroups = @()
    
    # Process each group membership with error handling
    foreach ($groupDN in $user.MemberOf) {
        try {
            $group = Get-ADGroup $groupDN -Properties Description
            $userGroups += $group.Name
        }
        catch {
            Write-Warning "Skipping group ($groupDN) - Group may no longer exist: $($_.Exception.Message)"
            continue
        }
    }

    if ($userGroups) {
        # Initialize Markdown builder
        $MarkdownBuilder = [System.Text.StringBuilder]::new()
        $MarkdownBuilder.AppendLine("# Group Memberships for $samAccountName") | Out-Null
        $MarkdownBuilder.AppendLine("Generated on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") | Out-Null
        $MarkdownBuilder.AppendLine("") | Out-Null

        foreach ($groupName in $userGroups) {
            try {
                $group = Get-ADGroup -Identity $groupName -Properties Description
                $groupDescription = if ($group.Description) { "($($group.Description))" } else { "" }
                $MarkdownBuilder.AppendLine("- $groupName $groupDescription") | Out-Null
                Get-RecursiveGroupMembership -GroupName $groupName -MarkdownBuilder $MarkdownBuilder -Depth 1
            }
            catch {
                Write-Warning "Skipping group ($groupName) - Group may no longer exist: $($_.Exception.Message)"
                continue
            }
        }

        # Create TEMP directory if it doesn't exist
        if (-not (Test-Path -Path "c:\TEMP")) {
            New-Item -ItemType Directory -Path "c:\TEMP" | Out-Null
        }

        # Save the Markdown file
        $fileName = "$samAccountName.md"
        $MarkdownBuilder.ToString() | Set-Content -Path "c:\TEMP\$fileName"

        Write-Host "`nGroup memberships have been saved to: c:\TEMP\$fileName"
    }
    else {
        Write-Host "User $samAccountName is not a member of any accessible groups."
    }
}
catch {
    Write-Host "Error: Unable to process user $samAccountName - $($_.Exception.Message)"
}