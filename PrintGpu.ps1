$host.UI.RawUI.BackgroundColor = "Black"
Write-Host 'Gpu Print Script, For all kind of computers (even laptops)' -ForegroundColor Green

Function Get-WindowsCompatibleOS {
$build = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
if ($build.CurrentBuild -ge 19041 -and ($($build.editionid -like 'Professional*') -or $($build.editionid -like 'Enterprise*'))) {
    Return $true
    }
Else {
    Write-Host "Only Windows 10 20H1 or Windows 11 (Pro or Enterprise) is supported" -ForegroundColor Red
    Return $false
    }
}


Function Get-HyperVEnabled {
if (Get-WindowsOptionalFeature -Online | Where-Object FeatureName -Like 'Microsoft-Hyper-V-All'){
    Return $true
    }
Else {
    Write-Host "You need to enable Virtualisation in your motherboard and then add the Hyper-V Windows Feature and reboot" -ForegroundColor Red
    Return $false
    }
}

Function Get-WSLEnabled {
    if ((wsl -l -v)[2].length -gt 1 ) {
        Write-Host "WSL is Enabled. This may interferre with GPU-P and produce an error 43 in the VM" -ForegroundColor Red
        Return $true
        }
    Else {
        Return $false
        }
}

Function Get-VMGpuPartitionAdapterFriendlyName {
    $Devices = (Get-WmiObject -Class "Msvm_PartitionableGpu" -ComputerName $env:COMPUTERNAME -Namespace "ROOT\virtualization\v2").name
    Foreach ($GPU in $Devices) {
        $GPUParse = $GPU.Split('#')[1]
        Get-WmiObject Win32_PNPSignedDriver | where {($_.HardwareID -eq "PCI\$GPUParse")} | select DeviceName -ExpandProperty DeviceName
        }
}

If ((Get-WindowsCompatibleOS) -and (Get-HyperVEnabled)) {
Write-Host "System Compatible" -ForegroundColor Green
Write-Host "Printing a list of compatible GPUs...May take a second" -ForegroundColor Green
Write-Host "Copy the name of the GPU you want to share..." -ForegroundColor Green
Get-VMGpuPartitionAdapterFriendlyName
Read-Host -Prompt "Press Enter to Exit"
}
else {
Read-Host -Prompt "Press Enter to Exit"
}
