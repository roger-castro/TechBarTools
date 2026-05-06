# TechBarTools

A USB-based IT support toolkit for enterprise and corporate tech bar environments. Consolidates common Windows device management tasks into a single menu-driven launcher — no installation required, runs directly from a USB drive.

Designed for IT support professionals handling device provisioning, reimaging, user management, and driver tracking in a Windows 10/11 environment.

---

## Requirements

- Windows 10 or Windows 11
- **Must be run as Administrator**
- PowerShell (built into Windows; no additional install required)

---

## Setup

1. Copy all files to the **root of a USB drive**, preserving the folder structure below.
2. Open `TechBarTools.cmd` in a text editor and set your organization's domain on the following line near the top:
   ```
   set "DOMAIN=YOUR_DOMAIN"
   ```
3. Edit `Scripts\Custom-Autopilot_HWID_GroupTags.ps1` and replace the placeholder group tag entries with your organization's actual Autopilot group tags:
   ```powershell
   [void] $listBox.Items.Add('GroupTag-1')
   [void] $listBox.Items.Add('GroupTag-2')
   [void] $listBox.Items.Add('GroupTag-3')
   ```
4. Right-click `TechBarTools.cmd` and select **Run as administrator**.

---

## Folder Structure

```
D:\
├── TechBarTools.cmd                        ← Main launcher (run this)
├── README.md
├── Scripts\
│   ├── Custom-Autopilot_HWID_GroupTags.ps1
│   ├── Uninstall-HPAudioControl.ps1
│   ├── 1-DriverVersion.ps1                 ← Before Fresh Start
│   ├── 2-DriverVersion.ps1                 ← After Fresh Start, Before Updates
│   ├── 3-DriverVersion.ps1                 ← After Fresh Start, After Updates
│   └── 4-DriverVersion.ps1                 ← After Autopilot
├── Completed Driver Checks\                ← Driver version CSV output (created automatically if missing)
└── Completed Imports\                      ← Processed Autopilot HWID CSVs (created automatically if missing)
```

---

## Menu Options

### User Management

| Option | Description |
|--------|-------------|
| `[1]` Add Local Administrator | Adds a domain user to the local Administrators group |
| `[2]` Delete Local Administrator | Removes a domain user from the local Administrators group |
| `[3]` Remove Hello PIN (English) | Clears the Windows Hello for Business PIN by taking ownership of and clearing the NGC folder |

### Device Management

| Option | Description |
|--------|-------------|
| `[4]` Get Hardware ID | Launches a GUI to select an Autopilot group tag, then captures the device HWID and exports it as a CSV named after the device serial number |
| `[5]` Clear Completed CSV Imports | Moves processed HWID CSV files to the `Completed Imports\` folder to keep the root of the drive clean |
| `[6]` Check Driver Versions | Sub-menu to run driver version snapshots at four stages of the imaging/provisioning process |
| `[7]` Return Device to OOBE (Preserve Hostname) | Runs Sysprep `/oobe /reboot` while dynamically writing a minimal `unattend.xml` to preserve the Autopilot-assigned hostname through the specialize pass |

### Application Management

| Option | Description |
|--------|-------------|
| `[8]` Remove Application | Sub-menu for uninstalling known applications via dedicated PS1 scripts |

---

## Notes

### Autopilot HWID Export
Option `[4]` uses a modified version of the Autopilot HWID capture script originally authored by **Mahesh Kumar**. It captures the device hardware hash and exports it as a CSV to the root of the USB drive, named after the device serial number (e.g. `ABC1234567.csv`). Once uploaded to Intune/your MDM platform, use option `[5]` to move the file to `Completed Imports\`.

### Driver Version Tracking
Options `1–4` under Check Driver Versions are designed to be run at specific stages of the imaging workflow, producing a comparative record of driver states before and after each phase. Output CSVs are saved to the `Completed Driver Checks\` folder.

### Return to OOBE / Hostname Preservation
By default, Sysprep resets the computer name to a random `DESKTOP-XXXXXXX` value. Option `[7]` captures the current hostname before Sysprep runs and writes a temporary `TechBar-unattend.xml` to the Sysprep folder that pins the name through the specialize pass. The file is cleaned up automatically.

### Adding New Menu Items
Both the main menu and the Remove Application sub-menu include inline comments explaining exactly how to add new entries. Search for `TO ADD A NEW MENU ITEM` or `TO ADD A NEW APPLICATION` in `TechBarTools.cmd`.

---

## Contributing

Pull requests welcome. If you add support for new applications or expand the toolkit for your environment, feel free to submit a PR or open an issue.

---

## License

MIT License — free to use, modify, and distribute.
