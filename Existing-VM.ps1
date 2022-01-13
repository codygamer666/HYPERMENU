Param (
[decimal]$GPUResourceAllocationPercentage = 100
)

$VMName = Read-Host -Prompt 'Input your VM name'
$GPUName = Read-Host -Prompt 'Input the gpu model or type AUTO for automatic installation'
$Hostname = $ENV:Computername

Function Add-VMGpuPartitionAdapterFiles {
param(
[string]$hostname = $ENV:COMPUTERNAME,
[string]$DriveLetter,
[string]$GPUName
)

If (!($DriveLetter -like "*:*")) {
    $DriveLetter = $Driveletter + ":"
    }

If ($GPUName -eq "AUTO") {
    $PartitionableGPUList = Get-WmiObject -Class "Msvm_PartitionableGpu" -ComputerName $env:COMPUTERNAME -Namespace "ROOT\virtualization\v2"
    $DevicePathName = $PartitionableGPUList.Name | Select-Object -First 1
    $GPU = Get-PnpDevice | Where-Object {($_.DeviceID -like "*$($DevicePathName.Substring(8,16))*") -and ($_.Status -eq "OK")} | Select-Object -First 1
    $GPUName = $GPU.Friendlyname
    $GPUServiceName = $GPU.Service 
    }
Else {
    $GPU = Get-PnpDevice | Where-Object {($_.Name -eq "$GPUName") -and ($_.Status -eq "OK")} | Select-Object -First 1
    $GPUServiceName = $GPU.Service
    }
# Get Third Party drivers used, that are not provided by Microsoft and presumably included in the OS

Write-Host "INFO   : Finding and copying driver files for $GPUName to VM. This could take a while..."

$Drivers = Get-WmiObject Win32_PNPSignedDriver | where {$_.DeviceName -eq "$GPUName"}

New-Item -ItemType Directory -Path "$DriveLetter\windows\system32\HostDriverStore" -Force | Out-Null

#copy directory associated with sys file 
$servicePath = (Get-WmiObject Win32_SystemDriver | Where-Object {$_.Name -eq "$GPUServiceName"}).Pathname
                $ServiceDriverDir = $servicepath.split('\')[0..5] -join('\')
                $ServicedriverDest = ("$driveletter" + "\" + $($servicepath.split('\')[1..5] -join('\'))).Replace("DriverStore","HostDriverStore")
                if (!(Test-Path $ServicedriverDest)) {
                Copy-item -path "$ServiceDriverDir" -Destination "$ServicedriverDest" -Recurse
                }

# Initialize the list of detected driver packages as an array
$DriverFolders = @()
foreach ($d in $drivers) {

    $DriverFiles = @()
    $ModifiedDeviceID = $d.DeviceID -replace "\\", "\\"
    $Antecedent = "\\" + $hostname + "\ROOT\cimv2:Win32_PNPSignedDriver.DeviceID=""$ModifiedDeviceID"""
    $DriverFiles += Get-WmiObject Win32_PNPSignedDriverCIMDataFile | where {$_.Antecedent -eq $Antecedent}
    $DriverName = $d.DeviceName
    $DriverID = $d.DeviceID
    if ($DriverName -like "NVIDIA*") {
        New-Item -ItemType Directory -Path "$driveletter\Windows\System32\drivers\Nvidia Corporation\" -Force | Out-Null
        }
    foreach ($i in $DriverFiles) {
            $path = $i.Dependent.Split("=")[1] -replace '\\\\', '\'
            $path2 = $path.Substring(1,$path.Length-2)
            $InfItem = Get-Item -Path $path2
            $Version = $InfItem.VersionInfo.FileVersion
            If ($path2 -like "c:\windows\system32\driverstore\*") {
                $DriverDir = $path2.split('\')[0..5] -join('\')
                $driverDest = ("$driveletter" + "\" + $($path2.split('\')[1..5] -join('\'))).Replace("driverstore","HostDriverStore")
                if (!(Test-Path $driverDest)) {
                Copy-item -path "$DriverDir" -Destination "$driverDest" -Recurse
                }
            }
            Else {
                $ParseDestination = $path2.Replace("c:", "$driveletter")
                $Destination = $ParseDestination.Substring(0, $ParseDestination.LastIndexOf('\'))
                if (!$(Test-Path -Path $Destination)) {
                    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
                    }
                Copy-Item $path2 -Destination $Destination -Force
                
            }

    }
    }

}

$VM = Get-VM -VMName $VMName
$VHD = Get-VHD -VMId $VM.VMId

If ($VM.state -eq "Running") {
    [bool]$state_was_running = $true
    }

if ($VM.state -ne "Off"){
    "Attemping to shutdown VM..."
    Stop-VM -Name $VMName -Force
    } 

While ($VM.State -ne "Off") {
    Start-Sleep -s 3
    "Waiting for VM to shutdown - make sure there are no unsaved documents..."
    }

"Mounting Drive..."
$DriveLetter = (Mount-VHD -Path $VHD.Path -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.DriveLetter} | ForEach-Object DriveLetter)

"Copying GPU Files - this could take a while..."
Add-VMGPUPartitionAdapterFiles -hostname $Hostname -DriveLetter $DriveLetter -GPUName $GPUName

"Dismounting Drive..."
Dismount-VHD -Path $VHD.Path

function Assign-VMGPUPartitionAdapter 
{  
    $PartitionableGPUList = Get-WmiObject -Class "Msvm_PartitionableGpu" -ComputerName $env:COMPUTERNAME -Namespace "ROOT\virtualization\v2" 
    if ($GPUName -eq "AUTO") {
        $DevicePathName = $PartitionableGPUList.Name[0]
        Add-VMGpuPartitionAdapter -VMName $VMName
        }
    else {
        $DeviceID = ((Get-WmiObject Win32_PNPSignedDriver | where {($_.Devicename -eq "$GPUNAME")}).hardwareid).split('\')[1]
        $DevicePathName = ($PartitionableGPUList | Where-Object name -like "*$deviceid*").Name
        Add-VMGpuPartitionAdapter -VMName $VMName -InstancePath $DevicePathName
        }

    [float]$devider = [math]::round($(100 / $GPUResourceAllocationPercentage),2)

    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionVRAM ([math]::round($(1000000000 / $devider))) -MaxPartitionVRAM ([math]::round($(1000000000 / $devider))) -OptimalPartitionVRAM ([math]::round($(1000000000 / $devider)))
    Set-VMGPUPartitionAdapter -VMName $VMName -MinPartitionEncode ([math]::round($(18446744073709551615 / $devider))) -MaxPartitionEncode ([math]::round($(18446744073709551615 / $devider))) -OptimalPartitionEncode ([math]::round($(18446744073709551615 / $devider)))
    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionDecode ([math]::round($(1000000000 / $devider))) -MaxPartitionDecode ([math]::round($(1000000000 / $devider))) -OptimalPartitionDecode ([math]::round($(1000000000 / $devider)))
    Set-VMGpuPartitionAdapter -VMName $VMName -MinPartitionCompute ([math]::round($(1000000000 / $devider))) -MaxPartitionCompute ([math]::round($(1000000000 / $devider))) -OptimalPartitionCompute ([math]::round($(1000000000 / $devider)))

}

"Assigning GPU-P Adapter"
Assign-VMGPUPartitionAdapter

If ($state_was_running){
    "Previous State was running so starting VM..."
    Start-VM $VMName
    }

"Done..."