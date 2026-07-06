# Vast.ai Setup

## Generate SSH Key (Windows)

```powershell
ssh-keygen -t ed25519 -C "vast-ai"
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

### Windows - Lenovo Laptop

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOV31m/yAx7W3D8N6RHt682E923cbwpj3Ktm3smbf6ee
```

### MacOs - Personal laptop

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK8gCu9dkrbujaUn/17Z0A6tsIn+5I7CO4a1Re5k7r3b
```

---

## Clone Repository & Install Dependencies

```bash
git clone https://github.com/XeroDays/Wifi-Hashcat-Helper.git
apt update
apt install -y hashcat
sudo apt install -y p7zip-full
cd Wifi-Hashcat-Helper/dicts
```

## Test Hashcat (GPU dry run)

```bash
hashcat -b -m 22000
```

## Download Dictionary File

```bash
wget -c URL
wget -c https://weakpass.com/download/2012/weakpass_4.txt.7z
7z x weakpass_4.txt.7z
```

## Delete Dictionary File

```bash
rm weakpass_4.txt.7z
```

## Run Hashcat

```bash
cd Wifi-Hashcat-Helper
cd ..
chmod +x hashcat-linux.sh
./hashcat-linux.sh
```

---

## URL

https://seth-stumpier-ophelia.ngrok-free.dev
