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
RULES_DIR="$SCRIPT_DIR/rules"
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
    local optional="$2"
    shift 2
    local items=("$@")
    
    echo "\n${CYAN}========================================${NC}"
    echo "${CYAN} $title${NC}"
    echo "${CYAN}========================================${NC}\n"
    
    local i=1
    for item in "${items[@]}"; do
        echo "  ${YELLOW}[$i] $item${NC}"
        ((i++))
    done
    
    if [[ "$optional" == "true" ]]; then
        echo "  ${GRAY}[0] Skip (Optional)${NC}"
    fi
    
    echo ""
    
    while true; do
        if [[ "$optional" == "true" ]]; then
            echo -n "Select an option (Enter for Skip/0): "
        else
            echo -n "Select an option: "
        fi
        read selection
        
        # Handle empty input as 0 (Skip) when optional
        if [[ "$optional" == "true" ]] && [[ -z "$selection" || "$selection" == "0" ]]; then
            MENU_SELECTION=0
            return 0
        fi
        
        # Validate selection
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
    
    show_menu "Select Hash File" "false" "${hash_files[@]}"
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
    
    show_menu "Select Dictionary File" "false" "${dict_files[@]}"
    SELECTED_DICT_FILE="${dict_files[$MENU_SELECTION]}"
    SELECTED_DICT_PATH="$DICTS_DIR/$SELECTED_DICT_FILE"
}

# Function to select rule file (optional)
select_rule_file() {
    echo "\n${GREEN}=== Rule File Selection (Optional) ===${NC}"
    
    if [[ ! -d "$RULES_DIR" ]]; then
        echo "${YELLOW}Warning: Rules directory not found: $RULES_DIR${NC}"
        echo "${YELLOW}Skipping rule selection...${NC}"
        SELECTED_RULE_FILE=""
        SELECTED_RULE_PATH=""
        return
    fi
    
    local rule_files=()
    for file in "$RULES_DIR"/*.rule(N); do
        [[ -f "$file" ]] && rule_files+=("${file:t}")
    done
    
    if [[ ${#rule_files[@]} -eq 0 ]]; then
        echo "${YELLOW}No .rule files found in $RULES_DIR${NC}"
        echo "${YELLOW}Skipping rule selection...${NC}"
        SELECTED_RULE_FILE=""
        SELECTED_RULE_PATH=""
        return
    fi
    
    show_menu "Select Rule File" "true" "${rule_files[@]}"
    
    if [[ $MENU_SELECTION -eq 0 ]]; then
        SELECTED_RULE_FILE=""
        SELECTED_RULE_PATH=""
    else
        SELECTED_RULE_FILE="${rule_files[$MENU_SELECTION]}"
        SELECTED_RULE_PATH="$RULES_DIR/$SELECTED_RULE_FILE"
    fi
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
select_rule_file
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

# Add rule file if selected
if [[ -n "$SELECTED_RULE_PATH" ]]; then
    HASHCAT_CMD="$HASHCAT_CMD -r \"$SELECTED_RULE_PATH\""
fi

# Add workload value
HASHCAT_CMD="$HASHCAT_CMD -w $WORKLOAD"

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
    if [[ -z "$CRACKED_OUTPUT" ]]; then
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
        echo "\n${YELLOW}No passwords cracked yet.${NC}"
    fi
    echo ""
}

# Display configuration summary
echo "\n${CYAN}========================================${NC}"
echo "${CYAN} Configuration Summary${NC}"
echo "${CYAN}========================================${NC}"
echo "${WHITE}Hash File:   $SELECTED_HASH_FILE${NC}"
echo "${WHITE}Dictionary:  $SELECTED_DICT_FILE${NC}"
if [[ -n "$SELECTED_RULE_FILE" ]]; then
    echo "${WHITE}Rule File:   $SELECTED_RULE_FILE${NC}"
else
    echo "${GRAY}Rule File:   None (skipped)${NC}"
fi
echo "${WHITE}Workload:    $WORKLOAD${NC}"
echo "${WHITE}Output File: $OUTPUT_FILE${NC}"
echo "\n${YELLOW}Hashcat Command:${NC}"
echo "${GREEN}$HASHCAT_CMD${NC}"
echo "\n${CYAN}========================================${NC}\n"

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
