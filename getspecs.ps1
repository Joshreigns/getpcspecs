# ============================================================
# COMPUTER INVENTORY SYSTEM
# Version: 1.0
# Author: Custom PowerShell Inventory Script
#
# Generates a professional HTML hardware/software report
# ============================================================

Clear-Host

# -------------------------------
# Script Location
# -------------------------------

$ScriptPath = "C:\"

if (!(Test-Path $ScriptPath)) {
    New-Item -Path $ScriptPath -ItemType Directory | Out-Null
}

$ComputerName = $env:COMPUTERNAME

$ReportFile = Join-Path `
    $ScriptPath `
    "ComputerReport-$ComputerName.html"


# -------------------------------
# Start Timer
# -------------------------------

$StartTime = Get-Date


Write-Host ""
Write-Host "============================================"
Write-Host " COMPUTER INVENTORY COLLECTION STARTED"
Write-Host "============================================"
Write-Host ""


# -------------------------------
# Inventory Object
# -------------------------------

$Inventory = [ordered]@{}


# -------------------------------
# Helper Function
# -------------------------------

function Safe-Get {

    param(
        [scriptblock]$Command
    )

    try {
        & $Command
    }
    catch {
        return "Not Available"
    }
}


function Convert-Size {

    param(
        [double]$Bytes
    )

    if ($Bytes -ge 1TB) {

        return "{0:N2} TB" -f ($Bytes / 1TB)

    }
    elseif ($Bytes -ge 1GB) {

        return "{0:N2} GB" -f ($Bytes / 1GB)

    }
    elseif ($Bytes -ge 1MB) {

        return "{0:N2} MB" -f ($Bytes / 1MB)

    }
    else {

        return "$Bytes Bytes"

    }
}


# ============================================================
# HTML HEADER
# ============================================================

$HTML = @"

<!DOCTYPE html>

<html>

<head>

<meta charset="UTF-8">

<title>
Computer Inventory Report - $ComputerName
</title>


<style>

body {

    font-family:
    "Segoe UI",
    Arial,
    sans-serif;

    background:#f4f6f9;

    color:#333;

    margin:0;

}



.header {

    background:
    linear-gradient(
    135deg,
    #1f4e79,
    #0b2239
    );

    color:white;

    padding:30px;

}



.header h1 {

    margin:0;

    font-size:32px;

}



.container {

    padding:25px;

}



.card {

    background:white;

    border-radius:12px;

    padding:20px;

    margin-bottom:20px;

    box-shadow:
    0 4px 12px
    rgba(0,0,0,.08);

}



.card-title {

    font-size:20px;

    font-weight:bold;

    color:#1f4e79;

    margin-bottom:15px;

}



.grid {

    display:grid;

    grid-template-columns:
    repeat(auto-fit,minmax(250px,1fr));

    gap:15px;

}



.item {

    background:#f8f9fa;

    padding:12px;

    border-radius:8px;

}



.label {

    color:#666;

    font-size:13px;

}



.value {

    font-size:16px;

    font-weight:bold;

    margin-top:5px;

}



table {

    width:100%;

    border-collapse:collapse;

}



th {

    background:#1f4e79;

    color:white;

    padding:10px;

    text-align:left;

}



td {

    padding:10px;

    border-bottom:
    1px solid #ddd;

}



tr:hover {

    background:#f1f5f9;

}



.good {

    color:#198754;

    font-weight:bold;

}



.warning {

    color:#d39e00;

    font-weight:bold;

}



.bad {

    color:#dc3545;

    font-weight:bold;

}



.footer {

    text-align:center;

    color:#777;

    padding:20px;

    font-size:13px;

}


</style>


</head>


<body>


<div class="header">

<h1>
Computer Inventory Report
</h1>

<p>
Computer:
<b>$ComputerName</b>
</p>

<p>
Generated:
<b>$(Get-Date)</b>
</p>

</div>


<div class="container">


"@

# ============================================================
# PART 2/6
# SYSTEM INFORMATION COLLECTION
# ============================================================


Write-Host "Collecting system information..." -ForegroundColor Cyan


# -------------------------------
# Computer Information
# -------------------------------

$ComputerSystem = Get-CimInstance Win32_ComputerSystem


$Inventory.Computer = [ordered]@{

    Name = $ComputerSystem.Name

    Manufacturer = $ComputerSystem.Manufacturer

    Model = $ComputerSystem.Model

    Username = "$($ComputerSystem.UserName)"

    Domain = $ComputerSystem.Domain

}



# -------------------------------
# Operating System
# -------------------------------
$OS = Get-CimInstance Win32_OperatingSystem


$Inventory.Windows = [ordered]@{

    Caption = $OS.Caption

    Version = $OS.Version

    Build = $OS.BuildNumber

    Architecture = $OS.OSArchitecture

    InstallDate = $OS.InstallDate

}




# -------------------------------
# BIOS Information
# -------------------------------

$BIOS = Get-CimInstance Win32_BIOS


$Inventory.BIOS = [ordered]@{

    Manufacturer = $BIOS.Manufacturer

    Version = $BIOS.SMBIOSBIOSVersion

    ReleaseDate = $BIOS.ReleaseDate

}



# -------------------------------
# Motherboard
# -------------------------------

$Board = Get-CimInstance Win32_BaseBoard


$Inventory.Motherboard = [ordered]@{

    Manufacturer = $Board.Manufacturer

    Product = $Board.Product

    Version = $Board.Version

    SerialNumber = $Board.SerialNumber

}



# -------------------------------
# CPU Information
# -------------------------------

$CPU = Get-CimInstance Win32_Processor


$Inventory.CPU = [ordered]@{

    Name = $CPU.Name

    Manufacturer = $CPU.Manufacturer

    Cores = $CPU.NumberOfCores

    LogicalProcessors = 
        $CPU.NumberOfLogicalProcessors

    MaxSpeedMHz =
        $CPU.MaxClockSpeed

}



# -------------------------------
# Memory Information
# -------------------------------

$MemoryModules = Get-CimInstance Win32_PhysicalMemory


$TotalMemory = 
(
    $MemoryModules |
    Measure-Object Capacity -Sum
).Sum



$Inventory.Memory = [ordered]@{

    Total =
        Convert-Size $TotalMemory

    Modules =
        $MemoryModules.Count

    Details =
        @()

}



foreach ($Module in $MemoryModules)
{

    $Inventory.Memory.Details += [ordered]@{

        Manufacturer =
            $Module.Manufacturer

        Capacity =
            Convert-Size $Module.Capacity

        Speed =
            "$($Module.Speed) MHz"

        PartNumber =
            $Module.PartNumber

        Serial =
            $Module.SerialNumber

    }

}



# -------------------------------
# Uptime
# -------------------------------

$BootTime = $OS.LastBootUpTime


$Uptime =
(Get-Date) - $BootTime



$Inventory.Uptime = [ordered]@{

    LastBoot =
        $BootTime

    Days =
        $Uptime.Days

    Hours =
        $Uptime.Hours

    Minutes =
        $Uptime.Minutes

}



# -------------------------------
# Hardware Summary
# -------------------------------

$Inventory.Summary = [ordered]@{

    Generated =
        Get-Date

    ScriptVersion =
        "1.0"

}


Write-Host "System information collected." -ForegroundColor Green

# ============================================================
# PART 3/6
# GRAPHICS, STORAGE AND NETWORK COLLECTION
# ============================================================


Write-Host "Collecting GPU, storage and network information..." -ForegroundColor Cyan



# ============================================================
# GPU INFORMATION
# ============================================================


$GPUList = Get-CimInstance Win32_VideoController


$Inventory.GPU = @()


foreach ($GPU in $GPUList)
{

    $Inventory.GPU += [ordered]@{

        Name =
            $GPU.Name

        DriverVersion =
            $GPU.DriverVersion

        VideoMemory =
            Convert-Size $GPU.AdapterRAM

        Resolution =
            "$($GPU.CurrentHorizontalResolution)x$($GPU.CurrentVerticalResolution)"

    }

}



# ============================================================
# STORAGE INFORMATION
# ============================================================


$Inventory.Storage = @()


$Disks = Get-CimInstance Win32_DiskDrive


foreach ($Disk in $Disks)
{

    $DiskHealth = "Unknown"


    try {

        $PhysicalDisk =
        Get-PhysicalDisk |
        Where-Object {
            $_.FriendlyName -eq $Disk.Model
        }


        if ($PhysicalDisk)
        {
            $DiskHealth =
            $PhysicalDisk.HealthStatus
        }

    }
    catch {

        $DiskHealth = "Unavailable"

    }



    $Inventory.Storage += [ordered]@{

        Model =
            $Disk.Model

        Serial =
            $Disk.SerialNumber

        Interface =
            $Disk.InterfaceType

        MediaType =
            $Disk.MediaType

        Size =
            Convert-Size $Disk.Size

        Health =
            $DiskHealth

    }

}



# ============================================================
# NETWORK ADAPTER INFORMATION
# ============================================================


$Inventory.Network = @()



    $Adapters =
    Get-NetAdapter |
    Where-Object {
    $_.Status -eq "Up" -and
    $_.HardwareInterface -eq $true
    }



foreach ($Adapter in $Adapters)
{

    $AdapterIP =
    Get-NetIPAddress `
    -InterfaceIndex $Adapter.ifIndex `
    -AddressFamily IPv4 |
    Select-Object -First 1



    $Gateway = $null

    try
    {

        $Gateway =
        Get-NetRoute `
        -InterfaceIndex $Adapter.ifIndex `
        -DestinationPrefix "0.0.0.0/0" `
        -ErrorAction SilentlyContinue |
        Select-Object -First 1

    }
    catch
    {

    }



    $DNS =
    Get-DnsClientServerAddress `
    -InterfaceIndex $Adapter.ifIndex |
    Select-Object -ExpandProperty ServerAddresses



    $Inventory.Network += [ordered]@{

        Name =
            $Adapter.Name

        Description =
            $Adapter.InterfaceDescription

        MAC =
            $Adapter.MacAddress

        Speed =
            $Adapter.LinkSpeed

        IP =
            $AdapterIP.IPAddress

        Gateway =
            if ($Gateway) {
                $Gateway.NextHop
            }
            else {
                "None"
            }
        DNS =
            ($DNS -join ", ")

    }

}



# ============================================================
# ALL IP ADDRESSES SUMMARY
# ============================================================


$Inventory.IPAddresses = @()


Get-NetIPAddress |
Where-Object {
    $_.AddressFamily -eq "IPv4"
} |
ForEach-Object {


    $Inventory.IPAddresses += [ordered]@{

        Adapter =
            $_.InterfaceAlias

        Address =
            $_.IPAddress

        Type =
            $_.PrefixOrigin

    }


}



Write-Host "GPU, storage and network information collected." -ForegroundColor Green


# ============================================================
# PART 4/6
# SOFTWARE, SECURITY AND DEVICE INFORMATION
# ============================================================


Write-Host "Collecting software and security information..." -ForegroundColor Cyan



# ============================================================
# INSTALLED SOFTWARE
# ============================================================


$Inventory.Software = @()


$SoftwarePaths = @(

"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"

"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"

"HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"

)



foreach ($Path in $SoftwarePaths)
{

    try
    {

        $Apps =
        Get-ItemProperty $Path -ErrorAction SilentlyContinue |
        Where-Object {
            $_.DisplayName
        }



        foreach ($App in $Apps)
        {

            $Inventory.Software += [ordered]@{

                Name =
                    $App.DisplayName

                Version =
                    $App.DisplayVersion

                Publisher =
                    $App.Publisher

                InstallDate =
                    $App.InstallDate

            }

        }

    }
    catch
    {

    }

}



# Remove duplicate software entries

$Inventory.Software =
$Inventory.Software |
Sort-Object Name -Unique




# ============================================================
# ANTIVIRUS INFORMATION
# ============================================================


$Inventory.Antivirus = @()


try
{

    $AV =
    Get-CimInstance `
    -Namespace root/SecurityCenter2 `
    -ClassName AntivirusProduct



    foreach ($Product in $AV)
    {

        $Inventory.Antivirus += [ordered]@{

            Name =
                $Product.displayName

            Path =
                $Product.pathToSignedProductExe

        }

    }

}
catch
{

    $Inventory.Antivirus += "Unable to detect antivirus"

}





# ============================================================
# WINDOWS DEFENDER STATUS
# ============================================================


$Inventory.Defender = [ordered]@{}



try
{

    $Defender =
    Get-MpComputerStatus


    $Inventory.Defender = [ordered]@{

        AntivirusEnabled =
            $Defender.AntivirusEnabled

        RealTimeProtection =
            $Defender.RealTimeProtectionEnabled

        LastScan =
            $Defender.LastFullScanTime

        SignatureVersion =
            $Defender.AntivirusSignatureVersion

    }


}
catch
{

    $Inventory.Defender =
    "Windows Defender information unavailable"

}




# ============================================================
# FIREWALL STATUS
# ============================================================


$Inventory.Firewall = @()


try
{

    $Firewall =
    Get-NetFirewallProfile



    foreach ($FW in $Firewall)
    {

        $Inventory.Firewall += [ordered]@{

            Profile =
                $FW.Name

            Enabled =
                $FW.Enabled

        }

    }


}
catch
{

}




# ============================================================
# BITLOCKER STATUS
# ============================================================


$Inventory.BitLocker = @()


try
{

    $Volumes =
    Get-BitLockerVolume



    foreach ($Volume in $Volumes)
    {

        $Inventory.BitLocker += [ordered]@{

            Drive =
                $Volume.MountPoint

            Protection =
                $Volume.ProtectionStatus

            Encryption =
                $Volume.EncryptionMethod

        }

    }

}
catch
{

    $Inventory.BitLocker =
    "BitLocker information unavailable"

}





# ============================================================
# TPM INFORMATION
# ============================================================


$Inventory.TPM = [ordered]@{}



try
{

    $TPM =
    Get-Tpm



    $Inventory.TPM = [ordered]@{

        Present =
            $TPM.TpmPresent

        Ready =
            $TPM.TpmReady

        Enabled =
            $TPM.TpmEnabled

        Activated =
            $TPM.TpmActivated

    }


}
catch
{

    $Inventory.TPM =
    "TPM information unavailable"

}




# ============================================================
# SECURE BOOT
# ============================================================


$Inventory.SecureBoot = "Unknown"


try
{

    $Inventory.SecureBoot =
    Confirm-SecureBootUEFI

}
catch
{

    $Inventory.SecureBoot =
    "Not Supported"

}





# ============================================================
# MONITOR INFORMATION
# ============================================================


$Inventory.Monitors = @()


try
{

    $Monitors =
    Get-CimInstance `
    -Namespace root\wmi `
    -ClassName WmiMonitorID



    foreach ($Monitor in $Monitors)
    {


        $Manufacturer =
        (
            $Monitor.ManufacturerName |
            ForEach-Object {
                [char]$_
            }
        ) -join ""


        $Name =
        (
            $Monitor.UserFriendlyName |
            ForEach-Object {
                [char]$_
            }
        ) -join ""


        $Serial =
        (
            $Monitor.SerialNumberID |
            ForEach-Object {
                [char]$_
            }
        ) -join ""



        $Inventory.Monitors += [ordered]@{

            Manufacturer =
                $Manufacturer.Trim()

            Model =
                $Name.Trim()

            Serial =
                $Serial.Trim()

        }

    }


}
catch
{

}





# ============================================================
# BATTERY INFORMATION
# ============================================================


$Inventory.Battery = @()


try
{

    $Battery =
    Get-CimInstance Win32_Battery



    foreach ($B in $Battery)
    {

        $Inventory.Battery += [ordered]@{

            Name =
                $B.Name

            Status =
                $B.Status

            EstimatedCharge =
                "$($B.EstimatedChargeRemaining)%"

        }

    }

}
catch
{

}


# ============================================================
# ANYDESK INFORMATION
# ============================================================


$Inventory.AnyDesk = [ordered]@{

    Installed = $false

    ID = "Not Found"

}



$AnyDeskPath = "C:\ProgramData\AnyDesk"



if (Test-Path $AnyDeskPath)
{

    $Inventory.AnyDesk.Installed = $true


    $ConfFiles =
    Get-ChildItem `
    -Path $AnyDeskPath `
    -Filter "*.conf" `
    -ErrorAction SilentlyContinue



    foreach ($file in $ConfFiles)
    {

        $Content =
        Get-Content `
        $file.FullName `
        -ErrorAction SilentlyContinue



        foreach ($line in $Content)
        {

            if ($line -match "ad\.anynet\.id")
            {

                $Inventory.AnyDesk.ID =
                $line.Split('=')[1].Trim()

            }

        }

    }

}

Write-Host "Software and security information collected." -ForegroundColor Green


# ============================================================
# PART 5/6
# HTML REPORT GENERATION
# ============================================================


Write-Host "Building HTML report..." -ForegroundColor Cyan



function HTML-Encode {

    param($Text)

    if ($null -eq $Text)
    {
        return ""
    }

    return [System.Web.HttpUtility]::HtmlEncode(
        [string]$Text
    )

}



function Create-Table {

param(
    $Data
)


if (-not $Data)
{
    return "<p>No information available</p>"
}



$html = "<table><tr>"


$First =
$Data | Select-Object -First 1


foreach ($Property in $First.Keys)
{

    $html += "<th>$Property</th>"

}


$html += "</tr>"



foreach ($Row in $Data)
{

    $html += "<tr>"


    foreach ($Value in $Row.Values)
    {

        $html += "<td>$(
            HTML-Encode $Value
        )</td>"

    }


    $html += "</tr>"

}



$html += "</table>"


return $html

}





# ============================================================
# SUMMARY DASHBOARD
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
System Summary
</div>


<div class="grid">


<div class="item">

<div class="label">
Computer Name
</div>

<div class="value">
$($Inventory.Computer.Name)
</div>

</div>



<div class="item">

<div class="label">
Manufacturer
</div>

<div class="value">
$($Inventory.Computer.Manufacturer)
</div>

</div>



<div class="item">

<div class="label">
Model
</div>

<div class="value">
$($Inventory.Computer.Model)
</div>

</div>



<div class="item">

<div class="label">
Username
</div>

<div class="value">
$($Inventory.Computer.Username)
</div>

</div>



<div class="item">

<div class="label">
Motherboard Serial Number
</div>

<div class="value">
$($Inventory.Motherboard.SerialNumber)
</div>

</div>



<div class="item">

<div class="label">
Operating System
</div>

<div class="value">
$($Inventory.Windows.Caption) $($Inventory.Windows.Architecture)
</div>
</div>
</div>
</div>
</div>
"@





# ============================================================
# CPU SECTION
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
CPU Information
</div>


<div class="grid">


<div class="item">
<div class="label">Processor</div>
<div class="value">
$($Inventory.CPU.Name)
</div>
</div>


<div class="item">
<div class="label">Cores</div>
<div class="value">
$($Inventory.CPU.Cores)
</div>
</div>


<div class="item">
<div class="label">Threads</div>
<div class="value">
$($Inventory.CPU.LogicalProcessors)
</div>
</div>


<div class="item">
<div class="label">Maximum Speed</div>
<div class="value">
$($Inventory.CPU.MaxSpeedMHz) MHz
</div>
</div>


</div>

</div>

"@





# ============================================================
# MEMORY SECTION
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
Memory Information
</div>


<div class="grid">


<div class="item">

<div class="label">
Total RAM
</div>

<div class="value">
$($Inventory.Memory.Total)
</div>

</div>



<div class="item">

<div class="label">
Memory Modules
</div>

<div class="value">
$($Inventory.Memory.Modules)
</div>

</div>


</div>


<br>


$(Create-Table $Inventory.Memory.Details)


</div>

"@






# ============================================================
# STORAGE SECTION
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
Storage Devices
</div>


$(Create-Table $Inventory.Storage)


</div>


<div class="card">

<div class="card-title">
Disk Partitions
</div>


$(Create-Table $Inventory.Partitions)


</div>

"@





# ============================================================
# GPU SECTION
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
Graphics Processing Unit
</div>


$(Create-Table $Inventory.GPU)


</div>

"@





# ============================================================
# NETWORK SECTION
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
Network Information
</div>


$(Create-Table $Inventory.Network)


</div>

"@



# ============================================================
# ANYDESK SECTION
# ============================================================


$HTML += @"


<div class="card">

<div class="card-title">
Remote Access Information
</div>


<div class="grid">


<div class="item">

<div class="label">
AnyDesk Installed
</div>

<div class="value">
$($Inventory.AnyDesk.Installed)
</div>

</div>



<div class="item">

<div class="label">
AnyDesk ID
</div>

<div class="value">
$($Inventory.AnyDesk.ID)
</div>

</div>


</div>


</div>


"@

# ============================================================
# SECURITY SECTION
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
Security Status
</div>


<div class="grid">


<div class="item">

<div class="label">
Secure Boot
</div>

<div class="value">
$($Inventory.SecureBoot)
</div>

</div>



<div class="item">

<div class="label">
TPM Present
</div>

<div class="value">
$($Inventory.TPM.Present)
</div>

</div>



<div class="item">

<div class="label">
TPM Ready
</div>

<div class="value">
$($Inventory.TPM.Ready)
</div>

</div>


</div>


<h3>
Antivirus
</h3>


$(Create-Table $Inventory.Antivirus)



<h3>
Firewall
</h3>


$(Create-Table $Inventory.Firewall)


</div>

"@






# ============================================================
# SOFTWARE SECTION
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
Installed Software
</div>


<p>
Total Installed Applications:
<b>
$($Inventory.Software.Count)
</b>
</p>


$(Create-Table $Inventory.Software)


</div>

"@


Write-Host "HTML sections generated." -ForegroundColor Green


# ============================================================
# PART 6/6
# FINALIZE REPORT AND SAVE HTML
# ============================================================


Write-Host "Finalizing report..." -ForegroundColor Cyan



# ============================================================
# EXECUTION TIME
# ============================================================


$EndTime = Get-Date


$Duration =
$EndTime - $StartTime



# ============================================================
# FOOTER
# ============================================================


$HTML += @"

<div class="card">

<div class="card-title">
Computer Inventory Report
</div>


<div class="grid">


<div class="item">

<div class="label">
Report Generated
</div>

<div class="value">
$(Get-Date)
</div>

</div>



<div class="item">

<div class="label">
Collection Time
</div>

<div class="value">
$(
"{0:N2} seconds" -f 
$Duration.TotalSeconds
)
</div>

</div>



<div class="item">

<div class="label">
Computer
</div>

<div class="value">
$ComputerName
</div>

</div>



<div class="item">

<div class="label">
Script Version
</div>

<div class="value">
1.0
</div>

</div>


</div>

</div>



<div class="footer">

Generated by PowerShell Computer Inventory System

<br>

Report Location:

<br>

$ReportFile

</div>



</div>


</body>

</html>

"@





# ============================================================
# SAVE HTML FILE
# ============================================================


try
{

    $HTML |
    Out-File `
    -FilePath $ReportFile `
    -Encoding UTF8



    Write-Host ""
    Write-Host "============================================"
    Write-Host " INVENTORY COMPLETED SUCCESSFULLY "
    Write-Host "============================================"
    Write-Host ""

    Write-Host "Report saved:"
    Write-Host $ReportFile `
        -ForegroundColor Green



}
catch
{

    Write-Host ""
    Write-Host "ERROR SAVING REPORT"
    Write-Host $_.Exception.Message `
        -ForegroundColor Red

}





# ============================================================
# OPEN REPORT
# ============================================================


Start-Process `
    $ReportFile



Write-Host ""

Write-Host "Finished."

Write-Host "Press Ctrl+C to exit."
