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

$host.UI.RawUI.BackgroundColor = "Black"
 # Main menu, allowing user selection
 function Show-Menu {
     param (
         [string]$Title = 'Easy GPU-P'
     )
     Clear-Host
     Write-Host "================ EASY-GPU-P-MENU ================" -ForegroundColor Green
     Write-Host "1: Press '1' to Create A New VM" -ForegroundColor Yellow
     Write-Host "2: Press '2' to Add GPU-P To A VM" -ForegroundColor Yellow
     Write-Host "3: Press '3' to Update GPU-P Drivers" -ForegroundColor Yellow
     Write-Host "4: Press '4' to Run The GPU-P PreChecks" -ForegroundColor Yellow
     Write-Host "5: Press '5' to Remove A GPU-P Adapter From A VM" -ForegroundColor Yellow
     Write-Host "6: Press '6'  to Print A List Of Available GPUS In Your System" -ForegroundColor Yellow

     Write-Host "Q: Press 'Q' to quit." -ForegroundColor Red
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
  Function PreChecks
 {
 "Running The Script"
$PSScriptRoot

$ScriptToRun= $PSScriptRoot+"\PreChecks.ps1"

&$ScriptToRun
 }
   Function RemoveGpu
 {
 "Running The Script"
$PSScriptRoot

$ScriptToRun= $PSScriptRoot+"\Remove-GPU-P.ps1"

&$ScriptToRun
 }
  Function PrintGpu
{
"Running The Script"
$PSScriptRoot

$ScriptToRun= $PSScriptRoot+"\PrintGpu.ps1"

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
         '4' {PreChecks; break}
         '5' {RemoveGpu; break}
         '6' {PrintGpu; break}
         'q' {break} # do nothing
         default{
             Write-Host "You entered '$input'" -ForegroundColor Red
             Write-Host "Please select one of the choices from the menu." -ForegroundColor Red}
     }
     stop-process -Id $PID
  } until ($input -eq '')
