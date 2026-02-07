#!/bin/bash
# Hashcat Helper Linux Script
# Interactive menu-driven hashcat execution tool

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN} $title${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    for i in "${!items[@]}"; do
        echo -e "  ${YELLOW}[$((i + 1))] ${items[$i]}${NC}"
    done
    
    if [ "$optional" = "true" ]; then
        echo -e "  ${GRAY}[0] Skip (Optional)${NC}"
    fi
    
    echo ""
    
    while true; do
        if [ "$optional" = "true" ]; then
            read -p "Select an option (Enter for Skip/0): " selection
        else
            read -p "Select an option: " selection
        fi
        
        # Handle empty input as 0 (Skip) when optional
        if [ "$optional" = "true" ] && [ -z "$selection" -o "$selection" = "0" ]; then
            return 0
        fi
        
        # Validate selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#items[@]}" ]; then
            return "$selection"
        fi
        
        echo -e "${RED}Invalid selection. Please try again.${NC}"
    done
}

# Function to select hash file
select_hash_file() {
    echo -e "\n${GREEN}=== Hash File Selection (Mandatory) ===${NC}"
    
    if [ ! -d "$HASHES_DIR" ]; then
        echo -e "${RED}Error: Hashes directory not found: $HASHES_DIR${NC}"
        exit 1
    fi
    
    local hash_files=()
    while IFS= read -r -d '' file; do
        hash_files+=("$(basename "$file")")
    done < <(find "$HASHES_DIR" -maxdepth 1 -name "*.hc22000" -type f -print0 | sort -z)
    
    if [ ${#hash_files[@]} -eq 0 ]; then
        echo -e "${RED}Error: No .hc22000 files found in $HASHES_DIR${NC}"
        exit 1
    fi
    
    show_menu "Select Hash File" "false" "${hash_files[@]}"
    local selection=$?
    SELECTED_HASH_FILE="${hash_files[$((selection - 1))]}"
    SELECTED_HASH_PATH="$HASHES_DIR/$SELECTED_HASH_FILE"
}

# Function to select dictionary file
select_dict_file() {
    echo -e "\n${GREEN}=== Dictionary Selection (Mandatory) ===${NC}"
    
    if [ ! -d "$DICTS_DIR" ]; then
        echo -e "${RED}Error: Dictionaries directory not found: $DICTS_DIR${NC}"
        exit 1
    fi
    
    local dict_files=()
    while IFS= read -r -d '' file; do
        dict_files+=("$(basename "$file")")
    done < <(find "$DICTS_DIR" -maxdepth 1 -type f -print0 | sort -z)
    
    if [ ${#dict_files[@]} -eq 0 ]; then
        echo -e "${RED}Error: No dictionary files found in $DICTS_DIR${NC}"
        exit 1
    fi
    
    show_menu "Select Dictionary File" "false" "${dict_files[@]}"
    local selection=$?
    SELECTED_DICT_FILE="${dict_files[$((selection - 1))]}"
    SELECTED_DICT_PATH="$DICTS_DIR/$SELECTED_DICT_FILE"
}

# Function to select rule file (optional)
select_rule_file() {
    echo -e "\n${GREEN}=== Rule File Selection (Optional) ===${NC}"
    
    if [ ! -d "$RULES_DIR" ]; then
        echo -e "${YELLOW}Warning: Rules directory not found: $RULES_DIR${NC}"
        echo -e "${YELLOW}Skipping rule selection...${NC}"
        SELECTED_RULE_FILE=""
        SELECTED_RULE_PATH=""
        return
    fi
    
    local rule_files=()
    while IFS= read -r -d '' file; do
        rule_files+=("$(basename "$file")")
    done < <(find "$RULES_DIR" -maxdepth 1 -name "*.rule" -type f -print0 | sort -z)
    
    if [ ${#rule_files[@]} -eq 0 ]; then
        echo -e "${YELLOW}No .rule files found in $RULES_DIR${NC}"
        echo -e "${YELLOW}Skipping rule selection...${NC}"
        SELECTED_RULE_FILE=""
        SELECTED_RULE_PATH=""
        return
    fi
    
    show_menu "Select Rule File" "true" "${rule_files[@]}"
    local selection=$?
    
    if [ $selection -eq 0 ]; then
        SELECTED_RULE_FILE=""
        SELECTED_RULE_PATH=""
    else
        SELECTED_RULE_FILE="${rule_files[$((selection - 1))]}"
        SELECTED_RULE_PATH="$RULES_DIR/$SELECTED_RULE_FILE"
    fi
}

# Get workload value
get_workload() {
    echo -e "\n${GREEN}=== Workload Configuration ===${NC}"
    echo -e "${YELLOW}Workload profile (1=Low, 2=Default, 3=High, 4=Nightmare)${NC}"
    
    while true; do
        read -p "Enter workload value (1-4, default: 2): " workload
        
        if [ -z "$workload" ]; then
            WORKLOAD="2"
            break
        fi
        
        if [[ "$workload" =~ ^[1-4]$ ]]; then
            WORKLOAD="$workload"
            break
        fi
        
        echo -e "${RED}Invalid workload value. Please enter 1, 2, 3, or 4.${NC}"
    done
}

# Main execution
clear
echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}   Hashcat Helper - WPA2/WPA3 Cracker${NC}"
echo -e "${CYAN}========================================${NC}"

# Check if hashcat is available
if ! command -v hashcat &> /dev/null; then
    echo -e "${RED}Error: hashcat is not installed or not in PATH${NC}"
    echo -e "${YELLOW}Please install hashcat first.${NC}"
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
HASH_BASENAME=$(basename "$SELECTED_HASH_FILE" .hc22000)
OUTPUT_FILE="${HASH_BASENAME}_cracked_${TIMESTAMP}.txt"
OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILE"

# Build hashcat command
HASHCAT_CMD="hashcat -m 22000 -a 0 \"$SELECTED_HASH_PATH\" \"$SELECTED_DICT_PATH\" --status --status-timer 10 -o \"$OUTPUT_PATH\""

# Add rule file if selected
if [ -n "$SELECTED_RULE_PATH" ]; then
    HASHCAT_CMD="$HASHCAT_CMD -r \"$SELECTED_RULE_PATH\""
fi

# Add workload value
HASHCAT_CMD="$HASHCAT_CMD -w $WORKLOAD"

# Show cracked passwords on exit (normal or Ctrl+C)
# Uses -o file first; if empty (e.g. "All hashes in potfile"), uses hashcat -m 22000 --show
show_cracked_passwords() {
    [ -z "$SELECTED_HASH_PATH" ] && return
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN} Cracked Passwords${NC}"
    echo -e "${CYAN}========================================${NC}"
    CRACKED_OUTPUT=""
    if [ -f "$OUTPUT_PATH" ] && [ -s "$OUTPUT_PATH" ]; then
        CRACKED_OUTPUT=$(cat "$OUTPUT_PATH")
    fi
    if [ -z "$CRACKED_OUTPUT" ]; then
        CRACKED_OUTPUT=$(hashcat -m 22000 --show "$SELECTED_HASH_PATH" 2>/dev/null)
    fi
    if [ -n "$CRACKED_OUTPUT" ]; then
        CRACKED_COUNT=$(echo "$CRACKED_OUTPUT" | wc -l | tr -d ' ')
        echo -e "${GREEN}$CRACKED_COUNT password(s) cracked:${NC}\n"
        while IFS= read -r line; do
            echo -e "${WHITE}  $line${NC}"
        done <<< "$CRACKED_OUTPUT"
        if [ -f "$OUTPUT_PATH" ] && [ -s "$OUTPUT_PATH" ]; then
            echo -e "\n${GREEN}Saved to: ${WHITE}$OUTPUT_PATH${NC}"
        else
            echo -e "\n${GRAY}(From potfile; use hashcat -m 22000 --show \"$SELECTED_HASH_PATH\" to view again)${NC}"
        fi
    else
        echo -e "\n${YELLOW}No passwords cracked yet.${NC}"
    fi
    echo ""
}

# Display configuration summary
echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN} Configuration Summary${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${WHITE}Hash File:   $SELECTED_HASH_FILE${NC}"
echo -e "${WHITE}Dictionary:  $SELECTED_DICT_FILE${NC}"
if [ -n "$SELECTED_RULE_FILE" ]; then
    echo -e "${WHITE}Rule File:   $SELECTED_RULE_FILE${NC}"
else
    echo -e "${GRAY}Rule File:   None (skipped)${NC}"
fi
echo -e "${WHITE}Workload:    $WORKLOAD${NC}"
echo -e "${WHITE}Output File: $OUTPUT_FILE${NC}"
echo -e "\n${YELLOW}Hashcat Command:${NC}"
echo -e "${GREEN}$HASHCAT_CMD${NC}"
echo -e "\n${CYAN}========================================${NC}\n"

# Execute hashcat
echo -e "${GREEN}Starting hashcat...${NC}\n"
echo -e "${CYAN}Status updates will appear every 10 seconds.${NC}\n"
echo -e "${YELLOW}Press Ctrl+C to stop hashcat.${NC}\n"
echo -e "${GRAY}----------------------------------------${NC}\n"

# Run hashcat; EXIT trap ensures cracked passwords are shown even on Ctrl+C
trap show_cracked_passwords EXIT
eval $HASHCAT_CMD
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo -e "\n${GREEN}Hashcat completed successfully!${NC}"
elif [ $EXIT_CODE -eq 1 ]; then
    echo -e "\n${GREEN}Hashcat exhausted - all passwords tried.${NC}"
else
    echo -e "\n${YELLOW}Hashcat exited with code: $EXIT_CODE${NC}"
fi
