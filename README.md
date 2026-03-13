# Powershell Device Enable Script

This script assists in scenarios where you need to enable a device programmatically in Windows using the device's Friendly name. Wildcards OK.

# Usage

Syntax Examples: 

```
./Enable-Device.ps1 -DeviceName "Realtek*Ethernet*"
```
```
./Enable-Device.ps1 -DeviceName "Intel(R) Wi-Fi 6 AX201 160MHz"
```
If you want, you can manually create the scheduled task in the Task Scheduler application in Windows, or edit the provided XML file for your case and import it using the following Powershell command:
```
Register-ScheduledTask -Xml (Get-Content "EnableDeviceAtBoot.xml" -Raw) -TaskName "EnableDeviceAtBoot"
```

# Purpose

I created this script to help me with a persistent AMD GPU issue I was having on a Proxmox VM, which started up in a state where it needed to be enabled before use. I created a task to run in Task Scheduler to run at boot to resolve this. The Task Scheduler XML is provided for this purpose. 

# LICENSE

Please refer to [LICENSE](LICENSE).
