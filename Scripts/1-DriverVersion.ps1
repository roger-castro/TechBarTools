# Get the system's serial number
$SerialNumber = (Get-WmiObject Win32_BIOS).SerialNumber

# Prompt for the drive letter
$DriveLetter = (Read-Host "Enter the drive letter to save the file (e.g., D, E, F)").ToUpper() + ":"

# Define the output file path
$FilePath = "$DriveLetter\Completed Driver Checks\$SerialNumber-DriverVersion_1_Before_FreshStart.csv"

# Ensure the directory exists
New-Item -ItemType Directory -Path (Split-Path -Parent $FilePath) -Force | Out-Null

# Retrieve driver information and export to CSV
Get-WmiObject Win32_PnPSignedDriver | 
Select-Object DeviceName, Manufacturer, DriverVersion | 
Export-Csv -Path $FilePath -NoTypeInformation

# Confirm report creation
echo ""
Write-Host "Report $SerialNumber-DriverVersion_1_Before_FreshStart.csv created successfully"
echo ""