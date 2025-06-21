using namespace System.Management.Automation

$ModuleRoot = $PSScriptRoot
$PublicFunctions = @(Get-ChildItem -Path "$ModuleRoot\Public\*.ps1" -ErrorAction SilentlyContinue)
$PrivateFunctions = @(Get-ChildItem -Path "$ModuleRoot\Private\*.ps1" -ErrorAction SilentlyContinue)
$Classes = @(Get-ChildItem -Path "$ModuleRoot\Classes\*.ps1" -ErrorAction SilentlyContinue)

foreach ($Class in $Classes) {
    try {
        . $Class.FullName
        Write-Verbose "Imported class: $($Class.Name)"
    }
    catch {
        Write-Error "Failed to import class $($Class.Name): $_"
    }
}

foreach ($Function in $PrivateFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Imported private function: $($Function.Name)"
    }
    catch {
        Write-Error "Failed to import private function $($Function.Name): $_"
    }
}

foreach ($Function in $PublicFunctions) {
    try {
        . $Function.FullName
        Write-Verbose "Imported public function: $($Function.Name)"
    }
    catch {
        Write-Error "Failed to import public function $($Function.Name): $_"
    }
}

Initialize-ZapretModule

Export-ModuleMember -Function $PublicFunctions.BaseName