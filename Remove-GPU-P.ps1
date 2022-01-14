$host.UI.RawUI.BackgroundColor = "Black"

Write-Host 'This script removes the gpu-p adapter from a vm' -ForegroundColor Red
$vm = Read-Host -Prompt 'Write the name of the vm'
Remove-VMGpuPartitionAdapter -VMName $vm
