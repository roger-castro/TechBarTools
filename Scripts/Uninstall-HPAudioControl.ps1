# Uninstall-HPAudioControl.ps1
# Checks for HP Audio Control and uninstalls it if found.
# Run as Administrator.

#Requires -RunAsAdministrator

$appName = "HP Audio Control"

Write-Host "Searching for '$appName'..." -ForegroundColor Cyan

# Search across both 32-bit and 64-bit registry hives, plus HKCU
$registryPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

$app = Get-ItemProperty -Path $registryPaths -ErrorAction SilentlyContinue |
       Where-Object { $_.DisplayName -like "*HP Audio Control*" } |
       Select-Object -First 1

if ($null -eq $app) {
    # Fallback: check via Get-Package (works for Store/modern apps too)
    $app = Get-Package -Name "*HP Audio Control*" -ErrorAction SilentlyContinue | Select-Object -First 1

    if ($null -eq $app) {
        Write-Host "HP Audio Control was not found on this system." -ForegroundColor Green
        exit 0
    }

    # Uninstall via Get-Package / Uninstall-Package
    Write-Host "Found '$($app.Name)' (version $($app.Version)). Uninstalling..." -ForegroundColor Yellow
    try {
        $app | Uninstall-Package -Force -ErrorAction Stop
        Write-Host "Successfully uninstalled '$($app.Name)'." -ForegroundColor Green
    } catch {
        Write-Error "Uninstall failed: $_"
        exit 1
    }

} else {
    Write-Host "Found '$($app.DisplayName)' (version $($app.DisplayVersion))." -ForegroundColor Yellow

    # Prefer a quiet uninstall string if available
    $uninstallString = if ($app.QuietUninstallString) {
        $app.QuietUninstallString
    } elseif ($app.UninstallString) {
        # Append silent flags if it's an MSI
        if ($app.UninstallString -match "msiexec") {
            $app.UninstallString -replace "/I", "/X" -replace "/i", "/X"
            # Ensure quiet flags are present
            if ($app.UninstallString -notmatch "/q") {
                $app.UninstallString + " /qn /norestart"
            } else {
                $app.UninstallString
            }
        } else {
            $app.UninstallString
        }
    } else {
        $null
    }

    if ($null -eq $uninstallString) {
        Write-Error "No uninstall string found for '$($app.DisplayName)'. Manual removal may be required."
        exit 1
    }

    Write-Host "Running uninstaller..." -ForegroundColor Cyan

    try {
        # Split executable from arguments
        if ($uninstallString -match '^"([^"]+)"\s*(.*)$') {
            $exe  = $Matches[1]
            $args = $Matches[2]
        } elseif ($uninstallString -match '^(\S+)\s*(.*)$') {
            $exe  = $Matches[1]
            $args = $Matches[2]
        } else {
            $exe  = $uninstallString
            $args = ""
        }

        $proc = Start-Process -FilePath $exe -ArgumentList $args -Wait -PassThru -ErrorAction Stop
        if ($proc.ExitCode -eq 0) {
            Write-Host "Successfully uninstalled '$($app.DisplayName)'." -ForegroundColor Green
        } else {
            Write-Warning "Uninstaller exited with code $($proc.ExitCode). The app may not have been fully removed."
        }
    } catch {
        Write-Error "Failed to run uninstaller: $_"
        exit 1
    }
}