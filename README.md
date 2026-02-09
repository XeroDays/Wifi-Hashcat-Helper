# Hashcat Helper

Interactive tool for WPA2/WPA3 password cracking with hashcat.

## GPU Speed Estimates

Approximate `-m 22000` speeds by GPU. Avg Speed values are GPT-based; Actual (Tested) is left as `-` until measured.

| GPU                          | Avg Speed (GPT)  | Actual (Tested) | Weakpass_4 | USD/h   |
| ---------------------------- | ---------------- | --------------- | ---------- | ------- |
| L40S 45 GB                   | ~3 100 kH/s      | -               | -          | -       |
| Q RTX 8000 45 GB             | ~2 050 kH/s      | -               | -          | -       |
| A40 45 GB                    | ~1 800 kH/s      | -               | -          | -       |
| RTX 5080 16 GB               | ~1 525 kH/s      | -               | -          | -       |
| RTX 5070 Ti 16 GB            | ~1 300 kH/s      | -               | -          | -       |
| RTX 4500 Ada 24 GB           | ~1 300 kH/s      | -               | -          | -       |
| RTX 5070 12 GB               | ~1 150 kH/s      | -               | -          | -       |
| RTX 4070 Super 12 GB         | ~1 025 kH/s      | -               | -          | -       |
| RTX 5060 Ti 16 GB 36 MCU     | ~925 kH/s        | 688 kH/s        | -          | -       |
| 2x RTX 5060 Ti 16 GB         | ~1 850 kH/s      | 1216 kH/s       | 29m        | 0.153$  |
| RTX 4070 12 GB               | ~825 kH/s        | -               | -          | -       |
| 2x NVIDIA RTX 3060 28 MCU    | ~810 kH/s        | 710 kH/s        | 2h 32m     | -       |
| RTX 3070 Ti 8 GB             | ~725 kH/s        | -               | -          | -       |
| RTX 4060 Ti 16 GB            | ~650 kH/s        | 621 kH/s        | 59m        | -       |
| 2x RTX 4060 Ti 16 GB         | ~1 300 kH/s      | -               | -          | -       |
| RTX 2060 Super 8 GB          | ~475 kH/s        | -               | -          | -       |
| RTX 3060 12 GB 28 MCU        | ~405 kH/s        | 321 kH/s        | 1h 52m     | 0.049$  |
| RTX A4000 16 GB              | ~350 kH/s        | -               | -          | -       |
| GTX 1660 6 GB                | ~300 kH/s        | -               | -          | -       |

## Folder Structure

```
├── hashes/          # Place your .hc22000 hash files here
├── dicts/           # Place your dictionary/wordlist files here
├── rules/           # Place your .rule files here (optional)
├── output/          # Cracked passwords saved here (auto-created)
├── hashcat-windows.ps1
├── hashcat-windows.bat
├── hashcat-linux.sh
└── hashcat-macos.sh
```

## Requirements

- [Hashcat](https://hashcat.net/hashcat/) installed on your system
- `.hc22000` hash files (captured WPA handshakes)
- Dictionary/wordlist files

## Installation

### Windows

1. Download hashcat from https://hashcat.net/hashcat/
2. Extract to `C:\hashcat\` (or any location)
3. Edit `hashcat-windows.ps1` line 12 to set your hashcat path:
   ```powershell
   $hashcatPath = "C:\hashcat\hashcat.exe"
   ```ss

### Linux

```bash
# Ubuntu/Debian
sudo apt install hashcat

# Fedora
sudo dnf install hashcat

# Arch
sudo pacman -S hashcat
```

### macOS

```bash
brew install hashcat
```

## Usage

### Windows

**Option 1:** Double-click `hashcat-windows.bat`

**Option 2:** Run in PowerShell:
```powershell
powershell -ExecutionPolicy Bypass -File .\hashcat-windows.ps1
```

### Linux

```bash
# Make executable (first time only)
chmod +x hashcat-linux.sh

# Run
./hashcat-linux.sh
```

### macOS

```bash
# Make executable (first time only)
chmod +x hashcat-macos.sh

# Run
./hashcat-macos.sh
```

### Via SSH (Linux/macOS)

```bash
# Copy folder to remote server
scp -r "Wifi Hashcat Helper" user@server:/path/

# SSH into server
ssh user@server

# Navigate and run
cd /path/Wifi\ Hashcat\ Helper
chmod +x hashcat-linux.sh
./hashcat-linux.sh
```

## Interactive Menu

The script will guide you through:

1. **Select Hash File** - Choose from `.hc22000` files in `hashes/`
2. **Select Dictionary** - Choose wordlist from `dicts/`
3. **Select Rule File** - Optional, press Enter to skip
4. **Set Workload** - 1 (Low) to 4 (Nightmare), default is 2

## Workload Profiles

| Value | Profile   | Description                          |
|-------|-----------|--------------------------------------|
| 1     | Low       | Minimal impact, slower cracking      |
| 2     | Default   | Balanced performance                 |
| 3     | High      | High performance, may lag system     |
| 4     | Nightmare | Maximum performance, system may hang |

## Output

- Cracked passwords are saved to `output/` folder
- Filename format: `{hashfile}_cracked_{timestamp}.txt`
- Results are also displayed at the end using `--show`

## Troubleshooting

### Windows: "hashcat not recognized"
- Set the correct path in `hashcat-windows.ps1` line 12

### Windows: "Script cannot be loaded"
- Use `hashcat-windows.bat` instead, or run:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\hashcat-windows.ps1
  ```

### Windows: "OpenCL not found" or "No devices found"
- Install GPU drivers (NVIDIA/AMD/Intel)
- Or install [Intel OpenCL Runtime](https://www.intel.com/content/www/us/en/developer/tools/opencl-cpu-runtime/overview.html) for CPU-only mode

### Linux/macOS: "Permission denied"
```bash
chmod +x hashcat-linux.sh   # or hashcat-macos.sh
```

### Linux/macOS: "hashcat: command not found"
- Install hashcat using your package manager (see Installation)

## Creating Hash Files

To capture WPA handshakes and convert to `.hc22000` format:

```bash
# Using hcxdumptool (capture)
hcxdumptool -i wlan0 -o capture.pcapng

# Convert to hashcat format
hcxpcapngtool -o output.hc22000 capture.pcapng
```

Or use online converters like https://hashcat.net/cap2hashcat/
