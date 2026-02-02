# Hashcat Helper PowerShell Script
# Interactive menu-driven hashcat execution tool

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$hashesDir = Join-Path $scriptDir "hashes"
$dictsDir = Join-Path $scriptDir "dicts"
$rulesDir = Join-Path $scriptDir "rules"
$outputDir = Join-Path $scriptDir "output"

# Hashcat executable path - Set this to your hashcat.exe full path, or leave empty to use PATH
# Example: $hashcatPath = "C:\hashcat\hashcat.exe"
$hashcatPath = "C:\hashcat\hashcat.exe"

# Function to display menu and get user selection
function Show-Menu {
    param(
        [string]$Title,
        [array]$Items,
        [bool]$Optional = $false
    )
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "========================================`n" -ForegroundColor Cyan
    
    for ($i = 0; $i -lt $Items.Count; $i++) {
        Write-Host "  [$($i + 1)] $($Items[$i].Name)" -ForegroundColor Yellow
    }
    
    if ($Optional) {
        Write-Host "  [0] Skip (Optional)" -ForegroundColor Gray
    }
    
    Write-Host ""
    
    while ($true) {
        if ($Optional) {
            $prompt = "Select an option (Enter for Skip/0)"
        } else {
            $prompt = "Select an option"
        }
        $selection = Read-Host $prompt
        
        # Handle empty input as 0 (Skip) when optional
        if ($Optional -and ($selection -eq "" -or $selection -eq "0")) {
            return $null
        }
        
        $parsedValue = 0
        if ([int]::TryParse($selection, [ref]$parsedValue) -and $parsedValue -ge 1 -and $parsedValue -le $Items.Count) {
            return $Items[$parsedValue - 1]
        }
        
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
    }
}

# Function to select hash file
function Select-HashFile {
    Write-Host "`n=== Hash File Selection (Mandatory) ===" -ForegroundColor Green
    
    if (-not (Test-Path $hashesDir)) {
        Write-Host "Error: Hashes directory not found: $hashesDir" -ForegroundColor Red
        exit 1
    }
    
    $hashFiles = Get-ChildItem -Path $hashesDir -Filter "*.hc22000" -File | Sort-Object Name
    
    if ($hashFiles.Count -eq 0) {
        Write-Host "Error: No .hc22000 files found in $hashesDir" -ForegroundColor Red
        exit 1
    }
    
    $selected = Show-Menu -Title "Select Hash File" -Items $hashFiles
    return $selected
}

# Function to select dictionary file
function Select-DictionaryFile {
    Write-Host "`n=== Dictionary Selection (Mandatory) ===" -ForegroundColor Green
    
    if (-not (Test-Path $dictsDir)) {
        Write-Host "Error: Dictionaries directory not found: $dictsDir" -ForegroundColor Red
        exit 1
    }
    
    $dictFiles = Get-ChildItem -Path $dictsDir -Filter "*.*" -File | Sort-Object Name
    
    if ($dictFiles.Count -eq 0) {
        Write-Host "Error: No dictionary files found in $dictsDir" -ForegroundColor Red
        exit 1
    }
    
    $selected = Show-Menu -Title "Select Dictionary File" -Items $dictFiles
    return $selected
}

# Function to select rule file (optional)
function Select-RuleFile {
    Write-Host "`n=== Rule File Selection (Optional) ===" -ForegroundColor Green
    
    if (-not (Test-Path $rulesDir)) {
        Write-Host "Warning: Rules directory not found: $rulesDir" -ForegroundColor Yellow
        Write-Host "Skipping rule selection..." -ForegroundColor Yellow
        return $null
    }
    
    $ruleFiles = Get-ChildItem -Path $rulesDir -Filter "*.rule" -File | Sort-Object Name
    
    if ($ruleFiles.Count -eq 0) {
        Write-Host "No .rule files found in $rulesDir" -ForegroundColor Yellow
        Write-Host "Skipping rule selection..." -ForegroundColor Yellow
        return $null
    }
    
    $selected = Show-Menu -Title "Select Rule File" -Items $ruleFiles -Optional $true
    return $selected
}

# Determine hashcat executable path
if ($hashcatPath -eq "" -or -not (Test-Path $hashcatPath)) {
    # Try to find hashcat in PATH
    $hashcatInPath = Get-Command hashcat -ErrorAction SilentlyContinue
    if ($hashcatInPath) {
        $hashcatExe = "hashcat"
    } else {
        Write-Host "Error: Hashcat executable not found!" -ForegroundColor Red
        Write-Host "Please set the `$hashcatPath variable at the top of this script" -ForegroundColor Yellow
        Write-Host "with the full path to your hashcat.exe file." -ForegroundColor Yellow
        Write-Host "Example: `$hashcatPath = `"C:\hashcat\hashcat.exe`"" -ForegroundColor Yellow
        exit 1
    }
} else {
    $hashcatExe = $hashcatPath
}

# Main execution
Clear-Host
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Hashcat Helper - WPA2/WPA3 Cracker" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Select hash file (mandatory)
$hashFile = Select-HashFile
if (-not $hashFile) {
    Write-Host "Error: Hash file selection is mandatory!" -ForegroundColor Red
    exit 1
}

# Select dictionary file (mandatory)
$dictFile = Select-DictionaryFile
if (-not $dictFile) {
    Write-Host "Error: Dictionary file selection is mandatory!" -ForegroundColor Red
    exit 1
}

# Select rule file (optional)
$ruleFile = Select-RuleFile

# Get workload value
Write-Host "`n=== Workload Configuration ===" -ForegroundColor Green
Write-Host "Workload profile (1=Low, 2=Default, 3=High, 4=Nightmare)" -ForegroundColor Yellow
while ($true) {
    $workload = Read-Host "Enter workload value (1-4, default: 2)"
    if ($workload -eq "") {
        $workload = "2"
        break
    }
    if ($workload -match "^(1|2|3|4)$") {
        break
    }
    Write-Host "Invalid workload value. Please enter 1, 2, 3, or 4." -ForegroundColor Red
}

# Build hashcat command
$hashPath = $hashFile.FullName
$dictPath = $dictFile.FullName

# Create output directory if it doesn't exist
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

# Generate output file name based on hash file name
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$outputFileName = "$($hashFile.BaseName)_cracked_$timestamp.txt"
$outputPath = Join-Path $outputDir $outputFileName

$hashcatArgs = @(
    "-m", "22000",           # WPA2/WPA3 mode
    "-a", "0",               # Dictionary attack mode
    "`"$hashPath`"",
    "`"$dictPath`"",
    "--status",
    "--status-timer", "10",
    "-o", "`"$outputPath`""  # Output cracked passwords to file
)

# Add rule file if selected
if ($ruleFile) {
    $rulePath = $ruleFile.FullName
    $hashcatArgs += "-r"
    $hashcatArgs += "`"$rulePath`""
}

# Add workload value
$hashcatArgs += "-w"
$hashcatArgs += $workload

# Display configuration summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host " Configuration Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Hash File:   $($hashFile.Name)" -ForegroundColor White
Write-Host "Dictionary:  $($dictFile.Name)" -ForegroundColor White
if ($ruleFile) {
    Write-Host "Rule File:   $($ruleFile.Name)" -ForegroundColor White
} else {
    Write-Host "Rule File:   None (skipped)" -ForegroundColor Gray
}
Write-Host "Workload:    $workload" -ForegroundColor White
Write-Host "Output File: $outputFileName" -ForegroundColor White
Write-Host "`nHashcat Command:" -ForegroundColor Yellow
$commandLine = "`"$hashcatExe`" " + ($hashcatArgs -join " ")
Write-Host $commandLine -ForegroundColor Green
Write-Host "`n========================================`n" -ForegroundColor Cyan

# Execute hashcat directly
Write-Host "Starting hashcat...`n" -ForegroundColor Green
Write-Host "Status updates will appear every 5 seconds.`n" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop hashcat.`n" -ForegroundColor Yellow
Write-Host "----------------------------------------`n" -ForegroundColor Gray

try {
    # Change to hashcat directory so it can find OpenCL folder
    $hashcatDir = Split-Path -Parent $hashcatExe
    Push-Location $hashcatDir
    
    # Execute hashcat directly (not as background process) to see real-time output
    & $hashcatExe $hashcatArgs
    
    $exitCode = $LASTEXITCODE
    
    if ($exitCode -eq 0) {
        Write-Host "`nHashcat completed successfully!" -ForegroundColor Green
    } elseif ($exitCode -eq -1) {
        Write-Host "`nHashcat exited with error code -1." -ForegroundColor Red
        Write-Host "Run 'hashcat -I' in the hashcat folder to check available devices." -ForegroundColor Yellow
        Write-Host "You may need to install GPU drivers or OpenCL runtime." -ForegroundColor Yellow
    } else {
        Write-Host "`nHashcat exited with code: $exitCode" -ForegroundColor Yellow
    }
    
    # Show cracked passwords (runs regardless of exit code)
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host " Cracked Passwords (--show)" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    
    $showArgs = @("-m", "22000", "`"$hashPath`"", "--show")
    & $hashcatExe $showArgs
    
    # Return to original directory
    Pop-Location
    
    # Check if output file has content
    if (Test-Path $outputPath) {
        $crackedCount = (Get-Content $outputPath | Measure-Object -Line).Lines
        if ($crackedCount -gt 0) {
            Write-Host "`n========================================" -ForegroundColor Green
            Write-Host " $crackedCount password(s) saved to:" -ForegroundColor Green
            Write-Host " $outputPath" -ForegroundColor White
            Write-Host "========================================" -ForegroundColor Green
        } else {
            Write-Host "`nNo passwords cracked yet." -ForegroundColor Yellow
        }
    }
    
} catch {
    Pop-Location
    Write-Host "`nError executing hashcat: $_" -ForegroundColor Red
    Write-Host "Make sure hashcat is installed and available in your PATH." -ForegroundColor Yellow
    exit 1
}
