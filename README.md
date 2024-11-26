Here's a README text for the `groupmemership_md.ps1` script:


# Group Membership Markdown Generator

This PowerShell script recursively generates a Markdown file listing the Active Directory group memberships for a specified user. The script outputs the group hierarchy in a structured and readable Markdown format, including group descriptions.

## Prerequisites

- Windows PowerShell
- Active Directory Module for Windows PowerShell
- MarkMap Extention for VSCode - Extention id: gera2ld.markmap-vscode - https://markmap.js.org/

## Usage

1. **Open PowerShell with Administrative Privileges**:
   Ensure you have the necessary permissions to run the script and access Active Directory information.

2. **Run the Script**:
   Execute the script `groupmemership_md.ps1` in PowerShell.

   ```powershell
   .\groupmemership_md.ps1
   ```

3. **Provide User SAM Account Name**:
   When prompted, enter the SAM account name of the user whose group memberships you want to retrieve.

   ```plaintext
   Enter the user's SAM account name: [SAMAccountName]
   ```

4. **Output**:
   The script will generate a Markdown file named `[SAMAccountName].md` in the `C:\TEMP` directory. This file contains the group memberships and their descriptions.

## Script Details

- **Import Active Directory Module**:
  The script ensures the Active Directory module is imported before execution.

- **Recursive Group Membership Function**:
  The `Get-RecursiveGroupMembership` function retrieves group memberships recursively, preventing infinite loops by tracking visited groups.

- **Main Script Execution**:
  - Prompts for the user's SAM account name.
  - Retrieves the direct group memberships of the user.
  - Processes each group and generates a Markdown file with the group hierarchy and descriptions.
  - Saves the Markdown file to `C:\TEMP` directory.

## Error Handling

- The script includes error handling to manage cases where groups or users may not exist.
- Warnings are logged for skipped groups that no longer exist.

## Example Output

```markdown
# Group Memberships for [SAMAccountName]
Generated on [YYYY-MM-DD HH:mm:ss]

- GroupName1 (Description)
  - ParentGroup1 (Description)
  - ParentGroup2 (Description)
- GroupName2 (Description)
  - ParentGroup3 (Description)
```

## Notes

- Ensure the `C:\TEMP` directory exists or the script will create it.
- The script requires appropriate permissions to access Active Directory and retrieve group information.

## License

This script is provided "as is" without warranty of any kind.
