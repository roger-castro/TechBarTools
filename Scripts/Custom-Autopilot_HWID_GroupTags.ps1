<#PSScriptInfo
 
.VERSION 2.0
 
.AUTHOR Mahesh Kumar
 
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True,Position=0)][alias("DNSHostName","ComputerName","Computer")] [String[]] $Name = @("localhost"),
    [Parameter(Mandatory=$False)] [String] $OutputFile = "", 
    [Parameter(Mandatory=$False)] [Switch] $Append = $false,
    [Parameter(Mandatory=$False)] [System.Management.Automation.PSCredential] $Credential = $null,
    [Parameter(Mandatory=$False)] [Switch] $Partner = $false,
    [Parameter(Mandatory=$False)] [Switch] $Force = $false
)

Begin
{
    # Initialize empty list
    $computers = @()
}

Process
{
    foreach ($comp in $Name)
    {
        $bad = $false

        # Get a CIM session
        if ($comp -eq "localhost") {
            $session = New-CimSession
        }
        else
        {
            $session = New-CimSession -ComputerName $comp -Credential $Credential
        }

        # Get the common properties.
        Write-Verbose "Checking $comp"
        $serial = (Get-CimInstance -CimSession $session -Class Win32_BIOS).SerialNumber

        # Get the GroupTag
        Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Autopilot HWID Capture'
$form.Size = New-Object System.Drawing.Size(350,380)
$form.StartPosition = 'CenterScreen'

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(200,140)
$okButton.Size = New-Object System.Drawing.Size(105,53)
$okButton.Text = 'OK'
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)


$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(480,20)
$label.Text = 'Please select a GroupTag:'
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(15,40)
$listBox.Size = New-Object System.Drawing.Size(160,120)
$listBox.Height = 300

[void] $listBox.Items.Add('GroupTag-1')
[void] $listBox.Items.Add('GroupTag-2')
[void] $listBox.Items.Add('GroupTag-3')

$form.Controls.Add($listBox)

$form.Topmost = $true

$result = $form.ShowDialog()

if ($result -eq [System.Windows.Forms.DialogResult]::OK)
{
    $x = $listBox.SelectedItem
    $x
}

$GroupTag = $listBox.SelectedItem

        # Get the hash (if available)
        $devDetail = (Get-CimInstance -CimSession $session -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
        if ($devDetail -and (-not $Force))
        {
            $hash = $devDetail.DeviceHardwareData
        }
        else
        {
            $bad = $true
            $hash = ""
        }

        # If the hash isn't available, get the make and model
        if ($bad -or $Force)
        {
            $cs = Get-CimInstance -CimSession $session -Class Win32_ComputerSystem
            $make = $cs.Manufacturer.Trim()
            $model = $cs.Model.Trim()
            if ($Partner)
            {
                $bad = $false
            }
        }
        else
        {
            $make = ""
            $model = ""
        }

        # Getting the PKID is generally problematic for anyone other than OEMs, so let's skip it here
        $product = ""

        # Depending on the format requested, create the necessary object
        if ($Partner)
        {
            # Create a pipeline object
            $c = New-Object psobject -Property @{
                "Device Serial Number" = $serial
                "Windows Product ID" = $product
                "Hardware Hash" = $hash
                "Manufacturer name" = $make
                "Device model" = $model
		"Group Tag" = $GroupTag
            }
            # From spec:
            # "Manufacturer Name" = $make
            # "Device Name" = $model

        }
        else
        {
            # Create a pipeline object
            $c = New-Object psobject -Property @{
                "Device Serial Number" = $serial
                "Windows Product ID" = $product
                "Hardware Hash" = $hash
		"Group Tag" = $GroupTag
            }
        }

        # Write the object to the pipeline or array
        if ($bad)
        {
            # Report an error when the hash isn't available
            Write-Error -Message "Unable to retrieve device hardware data (hash) from computer $comp" -Category DeviceError
        }
        elseif ($OutputFile -eq "")
        {
            $c
        }
        else
        {
            $computers += $c
        }

        Remove-CimSession $session
    }
}

End
{
    if ($OutputFile -ne "")
    {
        if ($Append)
        {
            if (Test-Path $OutputFile)
            {
                $computers += Import-CSV -Path $OutputFile
            }
        }
        if ($Partner)
        {
            $computers | Select "Device Serial Number", "Windows Product ID", "Hardware Hash", "Manufacturer name", "Device model", "Group Tag" | ConvertTo-CSV -NoTypeInformation | % {$_ -replace '"',''} | Out-File $OutputFile
            # From spec:
            # $computers | Select "Device Serial Number", "Windows Product ID", "Hardware Hash", "Manufacturer Name", "Device Name", "Group Tag" | ConvertTo-CSV -NoTypeInformation | % {$_ -replace '"',''} | Out-File $OutputFile
        }
        else
        {
            $computers | Select "Device Serial Number", "Windows Product ID", "Hardware Hash", "Group Tag" | ConvertTo-CSV -NoTypeInformation| % {$_ -replace '"',''} | Out-File $OutputFile
        }
    }
}