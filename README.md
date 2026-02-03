# Hashcat Helper

Interactive tool for WPA2/WPA3 password cracking with hashcat.

## GPU Speed Estimates

Approximate `-m 22000` speeds by GPU. Avg Speed values are GPT-based; Actual (Tested) is left as `-` until measured.

| GPU                          | Avg Speed (GPT)      | Actual (Tested) |
| ---------------------------- | -------------------- | --------------- |
| L40S 45 GB        | ~3 000 – 3 200 kH/s   | -               |
| Q RTX 8000 45 GB             | ~1 900 – 2 200 kH/s   | -               |
| A40 45 GB                    | ~1 700 – 1 900 kH/s   | -               |
| RTX 5080 16 GB               | ~1 400 – 1 650 kH/s   | -               |
| RTX 5070 Ti 16 GB            | ~1 200 – 1 400 kH/s   | -               |
| RTX 4500 Ada 24 GB           | ~1 200 – 1 400 kH/s   | -               |
| RTX 5070 12 GB               | ~1 050 – 1 250 kH/s   | -               |
| RTX 4070 Super 12 GB         | ~950 – 1 100 kH/s     | -               |
| RTX 5060 Ti 16 GB            | ~850 – 1 000 kH/s     | -               |
| RTX 4070 12 GB               | ~750 – 900 kH/s       | -               |
| RTX 3070 Ti 8 GB             | ~650 – 800 kH/s       | -               |
| RTX 4060 Ti 16 GB            | ~600 – 700 kH/s       | -               |
| RTX 2060 Super 8 GB          | ~400 – 550 kH/s       | -               |
| RTX 3060 12 GB               | ~390 – 420 kH/s       | -               |
| RTX A4000 16 GB              | ~300 – 400 kH/s       | -               |
| GTX 1660 6 GB                | ~250 – 350 kH/s       | -               |

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
   ```

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
