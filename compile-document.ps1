# Author: Adam Papula
# Date: 2023-27-01
# Version: 1.0
# Beamer presentation compiler
#
[CmdletBinding()]
param(
    [string]$f,
    [string]$s = "main.tex",
    [string]$p = ".",
    [switch]$final,
    [switch]$o,
    [switch]$help
)

$start = Get-Date
$end = Get-Date

Function Compile {
    $compile_count = 1
    if ($final) {
        $compile_count = 3
    }
    for ($i = 0; $i -lt $compile_count; $i++) {
        lualatex --synctex=0 --interaction=nonstopmode --aux-directory=aux --output-directory=$p --jobname=$f .\$s > out.log
    }

    $end = Get-Date
    Write-Output "Success, compilation process took $((New-TimeSpan -Start $start -End $end).TotalSeconds) seconds."
    if ($o) {
        SumatraPDF.exe -reuse-instance "$p\$f.pdf"
    }
}


if ($help -eq $true) {
    Write-Host "Lualatex document compiler"
    Write-Host "Version: 1.0"
    Write-Host "Require: SumatraPDF, LuaLaTeX"
    Write-Host ""
    Write-Host "Usage: compile-document <opt. params> [-f OUTPUT_NAME]"
    Write-Host ""
    Write-Host "Required parameters:"
    Write-Host "    -f        Name of output file (without .pdf)"
    Write-Host ""
    Write-Host "Optional parameters:"
    Write-Host "    -s        Path to source file (commonly .tex file). (default: main.tex)"
    Write-Host "    -p        Path where to save the result. (default: .)"
    Write-Host "    -o        Open Sumatra after compilation."
    Write-Host "    -final    Compile presentation three times."
    Write-Host "    -help     Show this help."
    exit
}

if ($f.Length -eq 0) {
    Write-Host "Required parameter -f is missing." 
    exit 
}

Compile



