param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}

'running with full privileges'
 
 # Main menu, allowing user selection
 function Show-Menu {
     param (
         [string]$Title = 'Easy GPU-P'
     )
     Clear-Host
     Write-Host "================ $Title ================"
     Write-Host "1: Press '1' to Create A New VM"
     Write-Host "2: Press '2' to Add GPU-P To A VM"
     Write-Host "3: Press '3' to Update GPU-P Drivers"
         
     Write-Host "Q: Press 'Q' to quit."
 }
       
 #Functions go here
 Function NewVM 
 {
 write-host "Running The Script"
$PSScriptRoot 

$ScriptToRun= $PSScriptRoot+"\New-VM.ps1"

&$ScriptToRun
 }
 Function ExistingVM 
 {
 "Running The Script"
$PSScriptRoot 

$ScriptToRun= $PSScriptRoot+"\Existing-VM.ps1"

&$ScriptToRun
 }
 Function UpdateDrivers 
 {
 "Running The Script"
$PSScriptRoot 

$ScriptToRun= $PSScriptRoot+"\Update-VMGpuPartitionDriver.ps1"

&$ScriptToRun
 } 
 #Main menu loop
 do {
     Show-Menu
     $input = Read-Host "Please make a selection"
     Clear-Host
     switch ($input) {
         '1' {NewVM; break}
         '2' {ExistingVM; break}
         '3' {UpdateDrivers; break}
         'q' {break} # do nothing
         default{
             Write-Host "You entered '$input'" -ForegroundColor Red
             Write-Host "Please select one of the choices from the menu." -ForegroundColor Red}
     }
     Pause
 } until ($input -eq 'q')
