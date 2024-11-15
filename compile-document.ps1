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

    $sourceDir = Get-Location
    $targetDir = "$sourceDir\auxdir"
    
    # Vytvoření cílového adresáře auxdir
    New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
    
    # Rekurzivně projdi všechny složky v aktuálním adresáři a vytvoř je v auxdir
    Get-ChildItem -Path $sourceDir -Directory -Recurse | Where-Object { $_.FullName -ne $targetDir } | ForEach-Object {
        if ($_.FullName -notmatch '\\auxdir\\') {
            $newDir = $_.FullName.Substring($sourceDir.Path.Length)  
            $newDir = Join-Path $targetDir $newDir
            New-Item -Path $newDir -ItemType Directory -Force | Out-Null
        }
    }

    Write-Host "Spouštím kompilaci: " -NoNewline -ForegroundColor White
    Write-Host "$s" -ForegroundColor DarkGray


    for ($i = 0; $i -lt $compile_count; $i++) {
        lualatex --synctex=0 --interaction=nonstopmode --output-directory=auxdir --jobname=$f $s > out.log
    }
    Move-Item -Path "auxdir\$f.pdf" -Destination "./$p" -Force > $null


    $end = Get-Date
    Write-Host "Kompilace trvala: " -NoNewline -ForegroundColor White
    Write-Host "$([math]::Round((New-TimeSpan -Start $start -End $end).TotalSeconds))s." -ForegroundColor DarkGray
    
    Write-Host "Výstup uložen do: " -NoNewline -ForegroundColor White
    Write-Host "out.log" -ForegroundColor DarkGray
    
    if (Test-Path "./out.log") {
        $logContent = Get-Content "./out.log"
        $filteredErrors = $logContent | Where-Object {
            ($_ -notmatch "pgfplots\.errorbars\.code")
        }
        $filteredWarnings = $logContent | Where-Object { 
            ($_ -notmatch "multiply defined") -and
            ($_ -notmatch "multiply-defined labels") -and 
            ($_ -notmatch "LaTeX Warning: Unused global option\(s\)") -and 
            ($_ -notmatch "warning\s+\(file images/") -and 
            ($_ -notmatch "ignoring duplicate destination") -and 
            ($_ -notmatch "Package xcolor Warning") -and 
            ($_ -notmatch "Package pdfx Warning") -and 
            ($_ -notmatch "warning\s+\(map file\)")            
        }
        $warningCount = ($filteredWarnings | Select-String -Pattern "warning" -CaseSensitive:$false).Count
        $errorCount = ($filteredErrors | Select-String -Pattern "error" -CaseSensitive:$false).Count

        # Vytisknout výsledky
        if ($warningCount -gt 0) {
            Write-Host "    varování: $warningCount" -ForegroundColor Yellow
        } else {
            Write-Host "    varování: 0" -ForegroundColor Green
        }
        
        if ($errorCount -gt 0) {
            Write-Host "    chyby: $errorCount" -ForegroundColor Red
        } else {
            Write-Host "    chyby: 0" -ForegroundColor Green
        }
        
        # Pokud nejsou žádné chyby ani varování, smaž log
        if ($warningCount -eq 0 -and $errorCount -eq 0) {
            Remove-Item "out.log" -Force
        }
    } else {
        Write-Host "Log soubor out.log nebyl nalezen." -ForegroundColor Red
    }

    if ($o) {
        SumatraPDF.exe -reuse-instance "$p\$f.pdf"
    }
}


if ($help -eq $true) {
    Write-Host "Lualatex document compiler"
    Write-Host "Version: 2.0"
    Write-Host "Require: SumatraPDF, TexLive"
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
