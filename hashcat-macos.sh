#!/bin/zsh
# Hashcat Helper macOS Script
# Interactive menu-driven hashcat execution tool
#
# INSTALLATION:
# 1. Install hashcat via Homebrew: brew install hashcat
# 2. Make this script executable: chmod +x hashcat-macos.sh
# 3. Run: ./hashcat-macos.sh
#
# NOTE: If you get "permission denied", run: chmod +x hashcat-macos.sh

# Get script directory (zsh compatible)
SCRIPT_DIR="${0:A:h}"
HASHES_DIR="$SCRIPT_DIR/hashes"
DICTS_DIR="$SCRIPT_DIR/dicts"
OUTPUT_DIR="$SCRIPT_DIR/output"

# Colors
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
GRAY='\033[0;37m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Function to display menu and get user selection
show_menu() {
    local title="$1"
    shift
    local items=("$@")
    
    echo "\n${CYAN}========================================${NC}"
    echo "${CYAN} $title${NC}"
    echo "${CYAN}========================================${NC}\n"
    
    local i=1
    for item in "${items[@]}"; do
        echo "  ${YELLOW}[$i] $item${NC}"
        ((i++))
    done
    
    echo ""
    
    while true; do
        echo -n "Select an option: "
        read selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [[ "$selection" -ge 1 ]] && [[ "$selection" -le "${#items[@]}" ]]; then
            MENU_SELECTION="$selection"
            return 0
        fi
        
        echo "${RED}Invalid selection. Please try again.${NC}"
    done
}

# Function to select hash file
select_hash_file() {
    echo "\n${GREEN}=== Hash File Selection (Mandatory) ===${NC}"
    
    if [[ ! -d "$HASHES_DIR" ]]; then
        echo "${RED}Error: Hashes directory not found: $HASHES_DIR${NC}"
        exit 1
    fi
    
    local hash_files=()
    for file in "$HASHES_DIR"/*.hc22000(N); do
        [[ -f "$file" ]] && hash_files+=("${file:t}")
    done
    
    if [[ ${#hash_files[@]} -eq 0 ]]; then
        echo "${RED}Error: No .hc22000 files found in $HASHES_DIR${NC}"
        exit 1
    fi
    
    show_menu "Select Hash File" "${hash_files[@]}"
    SELECTED_HASH_FILE="${hash_files[$MENU_SELECTION]}"
    SELECTED_HASH_PATH="$HASHES_DIR/$SELECTED_HASH_FILE"
}

# Function to select dictionary file
select_dict_file() {
    echo "\n${GREEN}=== Dictionary Selection (Mandatory) ===${NC}"
    
    if [[ ! -d "$DICTS_DIR" ]]; then
        echo "${RED}Error: Dictionaries directory not found: $DICTS_DIR${NC}"
        exit 1
    fi
    
    local dict_files=()
    for file in "$DICTS_DIR"/*(N.); do
        [[ -f "$file" ]] && dict_files+=("${file:t}")
    done
    
    if [[ ${#dict_files[@]} -eq 0 ]]; then
        echo "${RED}Error: No dictionary files found in $DICTS_DIR${NC}"
        exit 1
    fi
    
    show_menu "Select Dictionary File" "${dict_files[@]}"
    SELECTED_DICT_FILE="${dict_files[$MENU_SELECTION]}"
    SELECTED_DICT_PATH="$DICTS_DIR/$SELECTED_DICT_FILE"
}

# Get workload value
get_workload() {
    echo "\n${GREEN}=== Workload Configuration ===${NC}"
    echo "${YELLOW}Workload profile (1=Low, 2=Default, 3=High, 4=Nightmare)${NC}"
    
    while true; do
        echo -n "Enter workload value (1-4, default: 2): "
        read workload
        
        if [[ -z "$workload" ]]; then
            WORKLOAD="2"
            break
        fi
        
        if [[ "$workload" =~ ^[1-4]$ ]]; then
            WORKLOAD="$workload"
            break
        fi
        
        echo "${RED}Invalid workload value. Please enter 1, 2, 3, or 4.${NC}"
    done
}

# Main execution
clear
echo "${CYAN}========================================${NC}"
echo "${CYAN}   Hashcat Helper - WPA2/WPA3 Cracker${NC}"
echo "${CYAN}        (macOS Version)${NC}"
echo "${CYAN}========================================${NC}"

# Check if hashcat is available
if ! command -v hashcat &> /dev/null; then
    echo "${RED}Error: hashcat is not installed${NC}"
    echo "${YELLOW}Install via Homebrew: brew install hashcat${NC}"
    exit 1
fi

# Select files
select_hash_file
select_dict_file
get_workload

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Generate output file name
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
HASH_BASENAME="${SELECTED_HASH_FILE:r}"
OUTPUT_FILE="${HASH_BASENAME}_cracked_${TIMESTAMP}.txt"
OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILE"

# Build hashcat command
HASHCAT_CMD="hashcat -m 22000 -a 0 \"$SELECTED_HASH_PATH\" \"$SELECTED_DICT_PATH\" --status --status-timer 10 -o \"$OUTPUT_PATH\""

# Add workload value
HASHCAT_CMD="$HASHCAT_CMD -w $WORKLOAD"

# Optional: ignore potfile (useful to re-crack already-cracked hashes)
POTFILE_DISABLE_ENABLED=0
echo ""
echo "${GREEN}=== Potfile Option (Optional) ===${NC}"
echo "${YELLOW}Add --potfile-disable to ignore the potfile (re-crack even if already cracked)?${NC}"
echo -n "Enter = default (no), Y = yes: "
read potfile_choice
if [[ "$potfile_choice" == "Y" || "$potfile_choice" == "y" ]]; then
    HASHCAT_CMD="$HASHCAT_CMD --potfile-disable"
    POTFILE_DISABLE_ENABLED=1
fi

# Show cracked passwords on exit (normal or Ctrl+C)
# Uses -o file first; if empty (e.g. "All hashes in potfile"), uses hashcat -m 22000 --show
show_cracked_passwords() {
    [[ -z "$SELECTED_HASH_PATH" ]] && return
    echo "\n${CYAN}========================================${NC}"
    echo "${CYAN} Cracked Passwords${NC}"
    echo "${CYAN}========================================${NC}"
    CRACKED_OUTPUT=""
    if [[ -f "$OUTPUT_PATH" ]] && [[ -s "$OUTPUT_PATH" ]]; then
        CRACKED_OUTPUT=$(cat "$OUTPUT_PATH")
    fi
    if [[ -z "$CRACKED_OUTPUT" ]] && [[ $POTFILE_DISABLE_ENABLED -eq 0 ]]; then
        CRACKED_OUTPUT=$(hashcat -m 22000 --show "$SELECTED_HASH_PATH" 2>/dev/null)
    fi
    if [[ -n "$CRACKED_OUTPUT" ]]; then
        CRACKED_COUNT=$(echo "$CRACKED_OUTPUT" | wc -l | tr -d ' ')
        echo "${GREEN}$CRACKED_COUNT password(s) cracked:${NC}\n"
        while IFS= read -r line; do
            echo "${WHITE}  $line${NC}"
        done <<< "$CRACKED_OUTPUT"
        if [[ -f "$OUTPUT_PATH" ]] && [[ -s "$OUTPUT_PATH" ]]; then
            echo "\n${GREEN}Saved to: ${WHITE}$OUTPUT_PATH${NC}"
        else
            echo "\n${GRAY}(From potfile; use hashcat -m 22000 --show \"$SELECTED_HASH_PATH\" to view again)${NC}"
        fi
    else
        if [[ $POTFILE_DISABLE_ENABLED -eq 1 ]]; then
            echo "\n${YELLOW}No passwords captured in output file yet (potfile was disabled).${NC}"
        else
            echo "\n${YELLOW}No passwords cracked yet.${NC}"
        fi
    fi
    echo ""
}

# Display configuration summary
echo "\n${CYAN}========================================${NC}"
echo "${CYAN} Configuration Summary${NC}"
echo "${CYAN}========================================${NC}"
echo "${WHITE}Hash File:   $SELECTED_HASH_FILE${NC}"
echo "${WHITE}Dictionary:  $SELECTED_DICT_FILE${NC}"
echo "${WHITE}Workload:    $WORKLOAD${NC}"
echo "${WHITE}Output File: $OUTPUT_FILE${NC}"
echo "\n${YELLOW}Hashcat Command:${NC}"
echo "${GREEN}$HASHCAT_CMD${NC}"
echo "\n${CYAN}========================================${NC}\n"

# Confirm before starting hashcat so the user can review the command
echo -n "${YELLOW}Press Enter to start hashcat (or Ctrl+C to cancel)... ${NC}"
read _

# Execute hashcat
echo "${GREEN}Starting hashcat...${NC}\n"
echo "${CYAN}Status updates will appear every 10 seconds.${NC}\n"
echo "${YELLOW}Press Ctrl+C to stop hashcat.${NC}\n"
echo "${GRAY}----------------------------------------${NC}\n"

# Run hashcat; EXIT trap ensures cracked passwords are shown even on Ctrl+C
trap show_cracked_passwords EXIT
eval $HASHCAT_CMD
EXIT_CODE=$?

if [[ $EXIT_CODE -eq 0 ]]; then
    echo "\n${GREEN}Hashcat completed successfully!${NC}"
elif [[ $EXIT_CODE -eq 1 ]]; then
    echo "\n${GREEN}Hashcat exhausted - all passwords tried.${NC}"
else
    echo "\n${YELLOW}Hashcat exited with code: $EXIT_CODE${NC}"
fi
