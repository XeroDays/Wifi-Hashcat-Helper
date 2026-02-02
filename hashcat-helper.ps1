# Hashcat Helper PowerShell Script
# Interactive menu-driven hashcat execution tool

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$hashesDir = Join-Path $scriptDir "hashes"
$dictsDir = Join-Path $scriptDir "dicts"
$rulesDir = Join-Path $scriptDir "rules"

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
        
        $numSelection = [int]::TryParse($selection, [ref]$null)
        if ($numSelection -and $numSelection -ge 1 -and $numSelection -le $Items.Count) {
            return $Items[$numSelection - 1]
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

# Build hashcat command
$hashPath = $hashFile.FullName
$dictPath = $dictFile.FullName

$hashcatArgs = @(
    "-m", "22000",           # WPA2/WPA3 mode
    "-a", "0",               # Dictionary attack mode
    "`"$hashPath`"",
    "`"$dictPath`"",
    "--status",              # Enable status output
    "--status-timer", "5"    # Status update every 5 seconds
)

# Add rule file if selected
if ($ruleFile) {
    $rulePath = $ruleFile.FullName
    $hashcatArgs += "-r"
    $hashcatArgs += "`"$rulePath`""
}

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
Write-Host "`nHashcat Command:" -ForegroundColor Yellow
$commandLine = "hashcat " + ($hashcatArgs -join " ")
Write-Host $commandLine -ForegroundColor Green
Write-Host "`n========================================`n" -ForegroundColor Cyan

# Execute hashcat directly
Write-Host "Starting hashcat...`n" -ForegroundColor Green
Write-Host "Status updates will appear every 5 seconds.`n" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop hashcat.`n" -ForegroundColor Yellow
Write-Host "----------------------------------------`n" -ForegroundColor Gray

try {
    # Execute hashcat directly (not as background process) to see real-time output
    & hashcat $hashcatArgs
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`nHashcat completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "`nHashcat exited with code: $LASTEXITCODE" -ForegroundColor Yellow
    }
} catch {
    Write-Host "`nError executing hashcat: $_" -ForegroundColor Red
    Write-Host "Make sure hashcat is installed and available in your PATH." -ForegroundColor Yellow
    exit 1
}
