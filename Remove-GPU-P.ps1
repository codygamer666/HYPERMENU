'This script removes the gpu-p adapter from a vm'
$vm = Read-Host -Prompt 'Write the name of the vm'
Remove-VMGpuPartitionAdapter -VMName $vm