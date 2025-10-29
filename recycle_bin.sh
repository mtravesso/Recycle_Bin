#!/bin/bash

#################################################
# Linux Recycle Bin Simulation
# Author: [Your Name]
# Date: [Date]
# Description: Shell-based recycle bin system
#################################################
# Global Configuration
RECYCLE_BIN_DIR="$HOME/.recycle_bin"
FILES_DIR="$RECYCLE_BIN_DIR/files"
METADATA_FILE="$RECYCLE_BIN_DIR/metadata.db"
CONFIG_FILE="$RECYCLE_BIN_DIR/config.cfg"
LOG_FILE="$RECYCLE_BIN_DIR/log.txt"
# Color codes for output (optional)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color


#################################################
# Function: initialize_recyclebin
# Description: Creates recycle bin directory structure
# Parameters: None
# Returns: 0 on success, 1 on failure
#################################################
initialize_recyclebin() {
    # Create recycle bin directory if it doesn't exist
    if [ ! -d "$RECYCLE_BIN_DIR" ]; then
        mkdir -p "$RECYCLE_BIN_DIR"
        mkdir -p "$FILES_DIR"

        # Initialize metadata file
        touch "$METADATA_FILE"
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"

        # Initialize config file
        touch "$CONFIG_FILE"
        echo "# Recycle Bin Configuration" > "$CONFIG_FILE"
        echo "MAX_SIZE_MB=1024" >> "$CONFIG_FILE"         # default Max Size in MB
        echo "RETENTION_DAYS=30" >> "$CONFIG_FILE"  # default Retention Time Limit until permanent deletion in days

        # Initialize empty log file
        touch "$LOG_FILE"

        echo "Recycle bin initialized at $RECYCLE_BIN_DIR"
        return 0
    fi
    return 0
}


#################################################
# Function: generate_unique_id
# Description: Generates unique ID for deleted files
# Parameters: None
# Returns: Prints unique ID to stdout
#################################################
generate_unique_id() {
local timestamp=$(date +%s)
local random=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 6 | head -n 1)
echo "${timestamp}_${random}"
}


#################################################
# Function: delete_file
# Description: Moves file/directory to recycle bin with error handling
# Parameters: $@ - All files/directories being passed to the function
# Returns: 0 on success, 1 on failure
#################################################
delete_file() {

    #Checks if metadata file is corrupted, if so, recreate it
    if [ ! -f "$METADATA_FILE" ]; then
        echo "Metadata file missing: $METADATA_FILE"
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"
        continue
    fi

    local id name path delete_date size type permissions owner
    local rel_path=$FILES_DIR
    local failed=0  # tracks if there were any failures during deletion

    # No arguments
    if [ "$#" -eq 0 ]; then
        echo "Error: No file specified"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | No file specified" >> "$LOG_FILE"
        return 1
    fi

    for file in "$@"; do
        # Prevent deleting recycle bin itself
        if [[ "$file" == "$RECYCLE_BIN_DIR"* ]]; then
            echo -e "${RED}Error: Cannot delete the recycle bin itself (${file})${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | Attempted to delete recycle bin itself: '$file'" >> "$LOG_FILE"
            failed=1
            continue
        fi

        #Handle symbolic links (this handling comes before the permission check because symlinks may fail when checking permissions)
        if [ -L "$file" ]; then
            id=$(generate_unique_id)
            name=$(basename "$file")
            path="$file"
            delete_date=$(date "+%Y-%m-%d %H:%M:%S")
            type="symlink"
            permissions=$(stat -c %A "$file")
            owner=$(stat -c %U "$file")

            echo "$id,$name,$path,$delete_date,0,$type,$permissions,$owner" >> "$METADATA_FILE"

            if cp -P "$file" "$FILES_DIR/$id.$type" 2>/dev/null; then
                rm -f "$file"
                echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | SUCCESS | Symlink '$path' -> ID: $id.$type" >> "$LOG_FILE"
            else
                echo -e "${RED}Error: Failed to copy symlink '$file'${NC}"
                echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | Failed to copy symlink '$file'" >> "$LOG_FILE"
                failed=1
            fi
            continue
        fi

        # File doesn't exist
        if [ ! -e "$file" ]; then
            echo -e "${RED}Error: '$file' does not exist${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | '$file' does not exist" >> "$LOG_FILE"
            failed=1
            continue
        fi

        # Permission check (read + write)
        if [ ! -r "$file" ] || [ ! -w "$file" ]; then
            echo -e "${RED}Error: No read/write permission for '$file'${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | Permission denied for '$file'" >> "$LOG_FILE"
            failed=1
            continue
        fi

        # Get size of the file (for disk space check)
        size=$(du -sk "$file" 2>/dev/null | awk '{print $1}')
        available=$(df -k "$FILES_DIR" | tail -1 | awk '{print $4}')

        if [ "$available" -lt "$size" ]; then
            echo -e "${RED}Error: Insufficient disk space in recycle bin${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | Not enough space to move '$file' (needed ${size}KB, available ${available}KB)" >> "$LOG_FILE"
            failed=1
            continue
        fi

        # Gather file info
        id=$(generate_unique_id)
        name=$(basename "$file")
        path=$(realpath "$file")
        delete_date=$(date "+%Y-%m-%d %H:%M:%S")
        type=$(basename "$file" | sed 's/.*\.//')
        permissions=$(stat -c %A "$file")
        owner=$(stat -c %U "$file")

        if [ ${#name} -gt 255 ]; then
            echo -e "${RED}Error: Filename too long (${#name} characters): '$file'${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | Filename too long (${#name} chars): '$file'" >> "$LOG_FILE"
            failed=1
            continue
        fi

        # Handle directory
        if [[ -d "$file" ]]; then
            find "$file" -mindepth 1 | while read -r sub_item; do
                delete_file "$sub_item"
            done
            echo "$id,$name,$path,$delete_date,$size,DIR,$permissions,$owner" >> "$METADATA_FILE"
            if mv "$file" "$FILES_DIR/$id" 2>/dev/null; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | SUCCESS | Directory '$path' -> ID: $id" >> "$LOG_FILE"
            else
                echo -e "${RED}Error: Failed to move directory '$file'${NC}"
                echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | Failed to move directory '$file'" >> "$LOG_FILE"
            fi
            continue
        fi

        



        # Handle file
        if [ -f "$file" ]; then
            echo "$id,$name,$path,$delete_date,$size,$type,$permissions,$owner" >> "$METADATA_FILE"
            if mv "$file" "$FILES_DIR/$id.$type" 2>/dev/null; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | SUCCESS | File '$path' -> ID: $id.$type" >> "$LOG_FILE"
            else
                echo -e "${RED}Error: Failed to move file '$file'${NC}"
                echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | Failed to move file '$file'" >> "$LOG_FILE"
            fi
        else
            echo -e "${RED}Error: Unknown item type '$file'${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | DELETE | ERROR | Unknown item type '$file'" >> "$LOG_FILE"
        fi
    done

    return $failed
}



#################################################
# Function: list_recycled
# Description: Lists all items in recycle bin
# Parameters: None
# Returns: 0 on success
#################################################
list_recycled() {
    local error_status=0
    # Validate metadata header and bail out early if invalid
    local expected_header="ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER"
    if [ ! -f "$METADATA_FILE" ] || ! head -n 2 "$METADATA_FILE" 2>/dev/null | grep -qF "$expected_header"; then
        echo "Metadata file missing: $METADATA_FILE"
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "$expected_header" >> "$METADATA_FILE"
        echo -e "${YELLOW}Warning: Metadata was recreated.${NC}"
        return 1    
    fi

    echo "=== Recycle Bin Content ==="

    # Ensure metadata file exists
    if [ ! -f "$METADATA_FILE" ]; then
        echo "Metadata file missing: $METADATA_FILE"
        return 1
    fi

    # Check if metadata has any entries beyond the first two lines
    if [ "$(tail -n +3 "$METADATA_FILE" | wc -l)" -eq 0 ]; then
        echo "The Recycle Bin is empty."
        return 0
    fi

    local detailed=false
    local sort_by="name"
    local pattern=""
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --detailed)
                detailed=true; shift ;;
            --sort)
                if [[ "$2" =~ ^(name|date|size)$ ]]; then
                    sort_by="$2"; shift 2
                else
                    echo -e "${RED}Invalid sort option. Use: name, date, or size.${NC}"
                    return 1
                fi ;;
            *)
                pattern="$1"; shift ;;
        esac
    done

    local sort_field sort_opts
    case "$sort_by" in
        name) sort_field=2; sort_opts="-t, -k${sort_field},${sort_field}" ;;
        date) sort_field=4; sort_opts="-t, -k${sort_field},${sort_field}" ;;
        size) sort_field=5; sort_opts="-t, -k${sort_field},${sort_field}n" ;;
    esac

    if [ "$detailed" = true ]; then
        printf "%-20s %-20s %-10s %-25s %-10s %-15s %-15s %-s\n" \
            "ID" "NAME" "TYPE" "DELETION_DATE" "SIZE" "PERMS" "OWNER" "PATH"
        printf "%0.s-" {1..160}; echo

        tail -n +3 "$METADATA_FILE" | sort $sort_opts | while IFS=',' read -r id name path date size type perms owner; do
            if command -v numfmt >/dev/null 2>&1; then
                size_h=$(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "$size B")
            else
                size_h="$size B"
            fi
            printf "%-20s %-20s %-10s %-25s %-10s %-15s %-15s %-s\n" \
                "$id" "$name" "$type" "$date" "$size_h" "$perms" "$owner" "$path"
        done
        echo
        echo "Detailed mode enabled (sorted by: $sort_by)"
        return 0
    fi

    printf "%-20s %-20s %-25s %-10s %-s\n" \
        "ID" "NAME" "DELETION_DATE" "SIZE"
    printf "%0.s-" {1..75}; echo

    tail -n +3 "$METADATA_FILE" | sort $sort_opts | while IFS=',' read -r id name path date size type perms owner; do
        printf "%-20s %-20s %-25s %-10s %-s\n" \
            "$id" "$name" "$date" "$size"
    done

    echo
    echo "Sorted by: $sort_by"
    return 0
}








#################################################
# Function: restore_file
# Description: Restores file from recycle bin
# Parameters: $1 - unique ID of file to restore
# Returns: 0 on success, 1 on failure
#################################################
restore_file() {
    local input="$1"

    #Checks if metadata file is corrupted, if so, recreate it
    if [ ! -f "$METADATA_FILE" ] || ! head -n2 "$METADATA_FILE" | grep -q "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER"; then
        echo "Metadata file missing or corrupted: $METADATA_FILE"
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"
        echo -e "${YELLOW}Warning: Metadata was recreated.${NC}"
        return 1
    fi

    if [ -z "$input" ]; then
        echo -e "${RED}Error: No file ID or filename specified${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | No file ID or name specified" >> "$LOG_FILE"
        return 1
    fi

    # Try to find a match by ID first
    local metadata
    metadata=$(grep "^$input," "$METADATA_FILE")

    # If not found by ID, try to find by filename (case-insensitive)
    if [ -z "$metadata" ]; then
        metadata=$(awk -F',' -v name="$input" 'tolower($2) == tolower(name) {print; exit}' "$METADATA_FILE")
    fi

    if [ -z "$metadata" ]; then
        echo -e "${RED}Error: No file found with ID or name '$input'${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | No file found for ID or name '$input'" >> "$LOG_FILE"
        return 1
    fi

    # Split metadata fields
    IFS=',' read -r id name original_path deletion_date size type perms owner <<< "$metadata"
    id=$(echo "$id" | tr -d '[:space:]')
    type=$(echo "$type" | tr -d '[:space:]')
    owner=$(echo "$owner" | tr -d '[:space:]')


    # Prevent restoring into recycle bin itself
    if [[ "$original_path" == "$RECYCLE_BIN_DIR"* ]]; then
        echo -e "${RED}Error: Cannot restore inside recycle bin itself${NC}"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Attempt to restore inside recycle bin -> ID: $id" >> "$LOG_FILE"
        return 1
    fi

    # Restoration process for symbolic links
    if [[ "$type" == "symlink" ]]; then
        # Trim variables to remove whitespace/newlines
        id=$(echo "$id" | tr -d '[:space:]')
        type=$(echo "$type" | tr -d '[:space:]')

        recycle_path="$FILES_DIR/$id.$type"

        

        # Ensure parent directory exists
        mkdir -p "$(dirname "$original_path")" 2>/dev/null

        # Restore the symlink itself
        if ! mv "$recycle_path" "$original_path"; then
            echo -e "${RED}Error: Failed to restore symlink '$original_path'${NC}"
            return 1
        fi

        echo "Symlink restored: $original_path"
        echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | SUCCESS | Symlink '$original_path' -> ID: $id" >> "$LOG_FILE"

        # Remove metadata entry
        grep -v "^$id," "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"

        return 0
    fi


    # Restoration process for directories
    if [[ "$type" == "DIR" ]]; then
        # Check disk space before merge or move
        required_space=$(du -s "$FILES_DIR/$id" | awk '{print $1}') # KB
        avail_space=$(df -k "$(dirname "$original_path")" | tail -1 | awk '{print $4}') # KB

        #Logging and Error Handling in case of insuficient disk space
        if [ "$avail_space" -lt "$required_space" ]; then
            echo -e "${RED}Error: Insufficient disk space to restore '$original_path'${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Insufficient disk space for directory '$original_path' -> ID: $id" >> "$LOG_FILE"
            return 1
        fi

        # Logging and Error Handling in case of denied permissions during merging
        if [ -d "$original_path" ]; then
            if ! rsync -a "$FILES_DIR/$id/" "$original_path/" 2>/dev/null; then
                echo -e "${RED}Error: Permission denied while merging directory '$original_path'${NC}"
                echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Permission denied for '$original_path' -> ID: $id" >> "$LOG_FILE"
                return 1
            fi
            rm -rf "$FILES_DIR/$id"
            echo "Directory restored (merged): $original_path"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | MERGED | Directory '$original_path' -> ID: $id" >> "$LOG_FILE"
        # Logging and Error Handling in case of denied permissions during restoring
        else
            if ! mv "$FILES_DIR/$id" "$original_path" 2>/dev/null; then
                echo -e "${RED}Error: Permission denied while restoring directory '$original_path'${NC}"
                echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Permission denied for '$original_path' -> ID: $id" >> "$LOG_FILE"
                return 1
            #Logging the successful restoration of the directory
            fi
            echo "Directory restored: $original_path"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | SUCCESS | Directory '$original_path' -> ID: $id" >> "$LOG_FILE"
        fi
    else
        # Restoration process for files
        # Ensure parent directory exists
        if ! mkdir -p "$(dirname "$original_path")" 2>/dev/null; then
            echo -e "${RED}Error: Cannot create parent directory for '$original_path' (permission denied)${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Cannot create parent directory for '$original_path' -> ID: $id" >> "$LOG_FILE"
            return 1
        fi

        recycle_path="$FILES_DIR/$id.$type"

        #Error Handling in the case of the file not existing inside the recycle b
        if [ ! -e "$recycle_path" ]; then
            echo -e "${YELLOW}Warning: File not found in recycle bin: $recycle_path${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | File missing: '$recycle_path' -> ID: $id" >> "$LOG_FILE"
            return 1
        fi

        # Error Handling in case of insuficient disk space
        required_space=$(du -k "$recycle_path" | awk '{print $1}')
        avail_space=$(df -k "$(dirname "$original_path")" | tail -1 | awk '{print $4}')
        if [ "$avail_space" -lt "$required_space" ]; then
            echo -e "${RED}Error: Insufficient disk space to restore '$original_path'${NC}"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Insufficient disk space for '$original_path' -> ID: $id" >> "$LOG_FILE"
            return 1
        fi

        # Handle conflicts
        if [ -e "$original_path" ]; then
            echo -e "${YELLOW}Warning: File already exists at original location: $original_path${NC}"
            echo "Choose action: [O]verwrite / [R]estore with modified name / [C]ancel"
            read -rp "(O/R/C): " choice
            case "$choice" in
                [Oo]*)
                    if ! mv -f "$recycle_path" "$original_path" 2>/dev/null; then
                        echo -e "${RED}Error: Permission denied while overwriting '$original_path'${NC}"
                        echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Permission denied for '$original_path' -> ID: $id" >> "$LOG_FILE"
                        return 1
                    fi
                    echo "File restored (overwritten): $original_path"
                    echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | OVERWRITE | File '$original_path' -> ID: $id" >> "$LOG_FILE"
                    ;;
                [Rr]*)
                    timestamp=$(date "+%Y%m%d%H%M%S")
                    new_name="${original_path%.*}_$timestamp.${type}"
                    if ! mv "$recycle_path" "$new_name" 2>/dev/null; then
                        echo -e "${RED}Error: Permission denied while restoring with new name '$new_name'${NC}"
                        echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Permission denied for '$new_name' -> ID: $id" >> "$LOG_FILE"
                        return 1
                    fi
                    echo "File restored with new name: $new_name"
                    echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | RENAMED | File '$new_name' -> ID: $id" >> "$LOG_FILE"
                    original_path="$new_name"
                    ;;
                [Cc]*)
                    echo "Restore cancelled for $original_path"
                    echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | CANCEL | File '$original_path' -> ID: $id" >> "$LOG_FILE"
                    return 0
                    ;;
                *)
                    echo "Invalid choice. Skipping $original_path"
                    echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | CANCEL | File '$original_path' -> ID: $id" >> "$LOG_FILE"
                    return 0
                    ;;
            esac
        else
            if ! mv "$recycle_path" "$original_path" 2>/dev/null; then
                echo -e "${RED}Error: Permission denied while restoring '$original_path'${NC}"
                echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | ERROR | Permission denied for '$original_path' -> ID: $id" >> "$LOG_FILE"
                return 1
            fi
            echo "File restored: $original_path"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | RESTORE | SUCCESS | File '$original_path' -> ID: $id" >> "$LOG_FILE"
        fi

        # Restore permissions
        perm_bits="${perms#-}"
        owner_bits=0; group_bits=0; other_bits=0
        [[ ${perm_bits:0:1} == "r" ]] && ((owner_bits+=4))
        [[ ${perm_bits:1:1} == "w" ]] && ((owner_bits+=2))
        [[ ${perm_bits:2:1} == "x" ]] && ((owner_bits+=1))
        [[ ${perm_bits:3:1} == "r" ]] && ((group_bits+=4))
        [[ ${perm_bits:4:1} == "w" ]] && ((group_bits+=2))
        [[ ${perm_bits:5:1} == "x" ]] && ((group_bits+=1))
        [[ ${perm_bits:6:1} == "r" ]] && ((other_bits+=4))
        [[ ${perm_bits:7:1} == "w" ]] && ((other_bits+=2))
        [[ ${perm_bits:8:1} == "x" ]] && ((other_bits+=1))

        num_permissions="${owner_bits}${group_bits}${other_bits}"
        chmod "$num_permissions" "$original_path"
        echo "Permissions restored: $perms ($num_permissions)"
    fi

    # Remove entry from metadata
    grep -v "^$id," "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"

    return 0
}




#################################################
# Function: empty_recyclebin
# Description: Permanently deletes all items
# Parameters: None
# Returns: 0 on success
#################################################
empty_recyclebin() {

    # Checks if metadata file is corrupted, if so, recreate it
    if [ ! -f "$METADATA_FILE" ] || ! head -n2 "$METADATA_FILE" | grep -q "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER"; then
        echo "Metadata file missing or corrupted: $METADATA_FILE"
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"
        echo -e "${YELLOW}Warning: Metadata was recreated.${NC}"
        return 1
    fi

    local auto_confirm="${AUTO_CONFIRM:-false}"
    local noninteractive=false
    if [ ! -t 0 ]; then
        noninteractive=true
    fi

    # Check for --force flag
    local force=false
    for arg in "$@"; do
        if [ "$arg" = "--force" ]; then
            force=true
            shift # remove the flag from positional parameters
            break
        fi
    done

    # If there are no arguments (after removing --force), empty the entire recycle bin
    if [ "$#" -eq 0 ]; then
        echo "Delete all items in recycle bin permanently?"

        # Skip confirmation if forced or auto-confirmed
        if [ "$force" = true ] || [ "$auto_confirm" = true ]; then
            confirm="y"
        else
            read -rp "(y/n): " confirm
        fi

        case "$confirm" in
            [Yy]*)
                echo "Deleting all files..."
                echo "List of files being deleted:"
                list_recycled
                count=$(find "$FILES_DIR" -type f | wc -l)
                size=$(du -ch "$FILES_DIR" | tail -n 1 | awk '{print $1}')
                rm -rf "$FILES_DIR"/*
                echo "Recycle Bin emptied ($count files, total size $size)."
                echo "# Recycle Bin Metadata" > "$METADATA_FILE"
                echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"
                ;;
            [Nn]*)
                echo "Operation cancelled."
                ;;
            *)
                echo "Invalid input. Please enter y or n."
                ;;
        esac

    # If arguments are given, delete only specified items
    else
        echo "Delete specified items permanently?"

        # Skip confirmation if forced
        if [ "$force" = true ]; then
            confirm="y"
        else
            read -rp "(y/n): " confirm
        fi

        case "$confirm" in
            [Yy]*)
                for key in "$@"; do
                    match=$(grep "^$key," "$METADATA_FILE")
                    if [ -z "$match" ]; then
                        match=$(awk -F',' -v name="$key" '$2==name {print $0}' "$METADATA_FILE")
                    fi
                    if [ -z "$match" ]; then
                        echo "No metadata found for ID or name: $key"
                        continue
                    fi
                    id=$(echo "$match" | cut -d',' -f1)
                    type=$(echo "$match" | cut -d',' -f6)
                    file_path="$FILES_DIR/$id.$type"

                    if [ -e "$file_path" ]; then
                        echo "Deleting $file_path permanently..."
                        rm -rf "$file_path"
                    else
                        echo "File not found in recycle bin: $file_path"
                    fi

                    grep -v "^$id," "$METADATA_FILE" > "$METADATA_FILE.tmp"
                    mv "$METADATA_FILE.tmp" "$METADATA_FILE"
                done
                echo "Specified items permanently deleted."
                ;;
            [Nn]*)
                echo "Operation cancelled."
                ;;
            *)
                echo "Invalid input. Please enter y or n."
                ;;
        esac
    fi

    return 0
}





#################################################
# Function: search_recycled
# Description: Searches for files in recycle bin
# Parameters: $1 - search pattern
# Returns: 0 on success
#################################################
search_recycled() {

    #Checks if metadata file is corrupted, if so, recreate it
    if [ ! -f "$METADATA_FILE" ] || ! head -n2 "$METADATA_FILE" | grep -q "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER"; then
        echo "Metadata file missing or corrupted: $METADATA_FILE"
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"
        echo -e "${YELLOW}Warning: Metadata was recreated.${NC}"
        return 1
    fi

    # --- Search by date range ---
    if [ "$1" = "date" ]; then
        local start_date="$2"
        local end_date="$3"

        if [ -z "$start_date" ] || [ -z "$end_date" ]; then
            echo -e "${RED}Error: Please provide start and end dates${NC}"
            echo "Usage: $0 search date 'YYYY-MM-DD HH:MM:SS' 'YYYY-MM-DD HH:MM:SS'"
            return 1
        fi

        echo "Results for deletion dates between '$start_date' and '$end_date':"
        local start_ts end_ts file_ts results_found=0

        start_ts=$(date -d "$start_date" +%s 2>/dev/null)
        end_ts=$(date -d "$end_date" +%s 2>/dev/null)
        if [ -z "$start_ts" ] || [ -z "$end_ts" ]; then
            echo -e "${RED}Error: Invalid date format.${NC}"
            echo "Use format: YYYY-MM-DD HH:MM:SS"
            return 1
        fi

        # Cabeçalho da tabela
        printf "%-20s %-20s %-10s %-25s %-10s %-10s %-15s %-40s\n" \
            "ID" "NAME" "TYPE" "DELETION_DATE" "SIZE" "PERMS" "OWNER" "ORIGINAL_PATH"
        printf "%0.s-" {1..160}; echo

        tail -n +3 "$METADATA_FILE" | while IFS=',' read -r id name path date size type perms owner; do
            file_ts=$(date -d "$date" +%s 2>/dev/null)
            if [ "$file_ts" -ge "$start_ts" ] && [ "$file_ts" -le "$end_ts" ]; then
                if command -v numfmt >/dev/null 2>&1; then
                    size_h=$(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "$size B")
                else
                    size_h="$size B"
                fi

                printf "%-20s %-20s %-10s %-25s %-10s %-10s %-15s %-40s\n" \
                    "$id" "$name" "$type" "$date" "$size_h" "$perms" "$owner" "$path"
                results_found=1
            fi
        done

        if [ "$results_found" -eq 0 ]; then
            echo "No results found."
        fi
        return 0
    fi

    # --- Search by pattern or type ---
    local pattern="$1"
    if [ -z "$pattern" ]; then
        echo -e "${RED}Error: No search pattern specified${NC}"
        echo "Usage: $0 search <pattern> OR $0 search date <start> <end>"
        return 1
    fi

    echo "Results for pattern '$pattern':"
    local results_found=0

    # Cabeçalho da tabela
    printf "%-20s %-20s %-10s %-25s %-10s %-10s %-15s %-40s\n" \
        "ID" "NAME" "TYPE" "DELETION_DATE" "SIZE" "PERMS" "OWNER" "ORIGINAL_PATH"
    printf "%0.s-" {1..160}; echo

    tail -n +3 "$METADATA_FILE" | while IFS=',' read -r id name path date size type perms owner; do
        # Pesquisa no nome, path e tipo (extensão)
        if echo "$name,$path,$type" | grep -Eiq "$pattern"; then
            if command -v numfmt >/dev/null 2>&1; then
                size_h=$(numfmt --to=iec --suffix=B "$size" 2>/dev/null || echo "$size B")
            else
                size_h="$size B"
            fi

            printf "%-20s %-20s %-10s %-25s %-10s %-10s %-15s %-40s\n" \
                "$id" "$name" "$type" "$date" "$size_h" "$perms" "$owner" "$path"
            results_found=1
        fi
    done

    if [ "$results_found" -eq 0 ]; then
        echo "No results found."
    fi

    return 0
}



#################################################
# Function: display_help
# Description: Shows usage information
# Parameters: None
# Returns: 0
#################################################
display_help() {
    echo "==============================================="
    echo "               Linux Recycle Bin"
    echo "==============================================="
    echo
    echo "Usage:"
    echo "  $0 <command> [options]"
    echo
    echo "-----------------------------------------------"
    echo "Available Commands:"
    echo "-----------------------------------------------"
    echo "  delete <file|directory>"
    echo "      Moves the specified file or directory to the recycle bin."
    echo "      The original path and metadata are stored for future restoration."
    echo
    echo "  list"
    echo "      Displays all items currently stored in the recycle bin."
    echo "      Shows ID, original name, deletion date, size, permissions, and owner."
    echo
    echo "  restore <name|id> [target_path]"
    echo "      Restores a deleted file or directory."
    echo "      If the original path no longer exists, you may specify an alternative target path."
    echo
    echo "  empty [name|id|all]"
    echo "      Permanently deletes one item (by name or ID) or clears the entire recycle bin."
    echo "      This action cannot be undone."
    echo
    echo "  search <pattern>"
    echo "      Searches items in the recycle bin by name, original path, or file type."
    echo
    echo "  search date <start> <end>"
    echo "      Searches files deleted within the specified date range."
    echo "      Example format: 'YYYY-MM-DD HH:MM:SS'"
    echo
    echo "  stats"
    echo "      Displays usage statistics including total files, total size, and oldest/newest deletions."
    echo
    echo "  cleanup"
    echo "      Automatically removes items older than a configured retention period."
    echo "      Useful for keeping the recycle bin size manageable."
    echo
    echo "  quota"
    echo "      Checks the current recycle bin size against the configured maximum limit."
    echo "      Displays warnings if the quota is exceeded."
    echo
    echo "  preview <name|id>"
    echo "      Displays the first few lines of a text file stored in the recycle bin."
    echo "      Helpful for identifying files before restoring them."
    echo
    echo "  help"
    echo "      Displays this help message."
    echo
    echo "-----------------------------------------------"
    echo "Examples:"
    echo "-----------------------------------------------"
    echo "  $0 delete file.txt"
    echo "  $0 restore file.txt"
    echo "  $0 empty all"
    echo "  $0 search date '2025-10-01 00:00:00' '2025-10-10 23:59:59'"
    echo "  $0 quota"
    echo "  $0 stats"
    echo
    echo "-----------------------------------------------"
    echo "Notes:"
    echo "-----------------------------------------------"
    echo "  - Deleted files are stored in a hidden recycle bin folder in your home directory."
    echo "  - Metadata (such as name, path, size, and owner) is logged for each deleted item."
    echo "  - Restored files will be placed in their original location, if the path no longer exists the folders will be recreated to match the original path."
    echo
}


#################################################
# Function: show_statistics
# Description: Shows stats about the recycle bin
# Parameters: None
# Returns: 0
#################################################
show_statistics() {
    #Checks if metadata file is corrupted, if so, recreate it
    if [ ! -f "$METADATA_FILE" ] || ! head -n2 "$METADATA_FILE" | grep -q "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER"; then
        echo "Metadata file missing or corrupted: $METADATA_FILE"
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"
        echo -e "${YELLOW}Warning: Metadata was recreated.${NC}"
        return 1
    fi

    # Verifica se há itens na recycle bin
    if [ "$(tail -n +3 "$METADATA_FILE" | wc -l)" -eq 0 ]; then
        echo "The Recycle Bin is empty."
        return 0
    fi

    total_items=$(tail -n +3 "$METADATA_FILE" | wc -l)
    total_size_bytes=$(tail -n +3 "$METADATA_FILE" | awk -F',' '{sum+=$5} END{print sum}')

    # Calcula total em formato legível
    if [ "$total_size_bytes" -ge 1073741824 ]; then

    # O valor 1073741824 segundo o chatgpt vem da expressão 1GB=1024MB×1024KB×1024B=1073741824B
        total_size=$(echo "scale=2; $total_size_bytes/1073741824" | bc)GB
    elif [ "$total_size_bytes" -ge 1048576 ]; then
        total_size=$(echo "scale=2; $total_size_bytes/1048576" | bc)MB
    elif [ "$total_size_bytes" -ge 1024 ]; then
        total_size=$(echo "scale=2; $total_size_bytes/1024" | bc)KB
    else
        total_size="${total_size_bytes}B"
    fi

    # Tipo de arquivo
    files_count=$(tail -n +3 "$METADATA_FILE" | awk -F',' '$6 != "DIR" {count++} END{print count+0}')
    dirs_count=$(tail -n +3 "$METADATA_FILE" | awk -F',' '$6 == "DIR" {count++} END{print count+0}')

    # Data mais antiga e mais recente
    oldest_date=$(tail -n +3 "$METADATA_FILE" | sort -t',' -k4 | head -n1 | awk -F',' '{print $4}')
    newest_date=$(tail -n +3 "$METADATA_FILE" | sort -t',' -k4 | tail -n1 | awk -F',' '{print $4}')

    # Tamanho médio
    avg_size=$(tail -n +3 "$METADATA_FILE" | awk -F',' '{sum+=$5; count++} END{if(count>0) printf "%.2f", sum/count; else print 0}')

    echo "=== Recycle Bin Statistics ==="
    echo "Total items      : $total_items"
    echo "Total size       : $total_size"
    echo "Files            : $files_count"
    echo "Directories      : $dirs_count"
    echo "Oldest item      : $oldest_date"
    echo "Newest item      : $newest_date"
    echo "Average file size: $avg_size bytes"
    echo "=============================="
    return 0
}


#################################################
# Function: auto_cleanup
# Description: Automatically deletes files from the recycle bin that have been there for more than 30 days.
# Arguments: None
# Returns: 0 if recycle bin is empty; otherwise performs deletions.
#################################################
auto_cleanup() {

    # Read RETENTION_DAYS from config (fallback 30)
    local DEFAULT_RETENTION=30
    local cfg_retention
    if [ -f "$CONFIG_FILE" ]; then
        cfg_retention=$(sed -n 's/^[[:space:]]*RETENTION_DAYS[[:space:]]*=[[:space:]]*\([0-9][0-9]*\).*$/\1/p' "$CONFIG_FILE")
    fi
    if [[ -n "$cfg_retention" && "$cfg_retention" =~ ^[0-9]+$ ]]; then
        RETENTION_DAYS=$cfg_retention
    else
        RETENTION_DAYS=$DEFAULT_RETENTION
    fi

    # Ensure metadata exists and header is valid
    if [ ! -f "$METADATA_FILE" ] || ! head -n2 "$METADATA_FILE" | grep -q "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER"; then
        echo "Metadata file missing or corrupted: $METADATA_FILE"
        echo "# Recycle Bin Metadata" > "$METADATA_FILE"
        echo "ID,ORIGINAL_NAME,ORIGINAL_PATH,DELETION_DATE,FILE_SIZE,FILE_TYPE,PERMISSIONS,OWNER" >> "$METADATA_FILE"
        echo -e "${YELLOW}Warning: Metadata was recreated.${NC}"
        return 1
    fi

    local now cutoff tmp_ids id name deletion_date type file_ts
    now=$(date +%s)
    cutoff=$(( now - RETENTION_DAYS * 86400 ))
    tmp_ids=$(mktemp)

    # Collect and remove items older than retention
    tail -n +3 "$METADATA_FILE" | while IFS=',' read -r id name original_path deletion_date size type perms owner; do
        file_ts=$(date -d "$deletion_date" +%s 2>/dev/null || echo 0)
        if [ "$file_ts" -gt 0 ] && [ "$file_ts" -le "$cutoff" ]; then
            # remove stored item
            if [ "$type" = "DIR" ]; then
                rm -rf "$FILES_DIR/$id" 2>/dev/null || true
            else
                rm -f "$FILES_DIR/$id"* 2>/dev/null || true
            fi
            echo "$id" >> "$tmp_ids"
            echo "$(date '+%Y-%m-%d %H:%M:%S') | AUTO_CLEANUP | REMOVED | ID: $id" >> "$LOG_FILE"
        fi
    done

    # Remove metadata entries for removed IDs
    if [ -s "$tmp_ids" ]; then
        while IFS= read -r rid; do
            [ -z "$rid" ] && continue
            grep -v "^$rid," "$METADATA_FILE" > "$METADATA_FILE.tmp" && mv "$METADATA_FILE.tmp" "$METADATA_FILE"
        done < "$tmp_ids"
        echo "Auto cleanup removed items older than $RETENTION_DAYS days."
    fi

    rm -f "$tmp_ids"
    return 0
}


#################################################
# Function: check_quota
# Description: Checks if the total size of files in the recycle bin exceeds the defined maximum size (1 GB). Triggers auto_cleanup() if exceeded.
# Arguments: None
# Returns: Displays a warning if the quota is exceeded.
#################################################
check_quota() {
    # Default fallback
    local DEFAULT_MAX_MB=2048
    local cfg_max_mb

    # Try to read MAX_SIZE_MB from config file (simple safe parse)
    if [ -f "$CONFIG_FILE" ]; then
        cfg_max_mb=$(awk -F= '/^\s*MAX_SIZE_MB\s*=/ { gsub(/["'\'']/,"",$2); gsub(/[^0-9]/,"",$2); print $2; exit }' "$CONFIG_FILE")
    fi

    if [[ -n "$cfg_max_mb" && "$cfg_max_mb" =~ ^[0-9]+$ ]]; then
        MAX_SIZE_MB=$cfg_max_mb
    else
        MAX_SIZE_MB=$DEFAULT_MAX_MB
    fi

    MAX_SIZE_BYTES=$(( MAX_SIZE_MB * 1024 * 1024 ))

    # Compute current size of the files directory in bytes (handle empty dir)
    if [ -d "$FILES_DIR" ]; then
        current_size=$(du -sb "$FILES_DIR" 2>/dev/null | awk '{print $1}')
        [ -z "$current_size" ] && current_size=0
    else
        current_size=0
    fi

    if [ "$current_size" -gt "$MAX_SIZE_BYTES" ]; then
        echo "Warning: Recycle bin quota exceeded ($current_size bytes > $MAX_SIZE_BYTES bytes) (MAX_SIZE_MB=$MAX_SIZE_MB)"
        auto_cleanup
    fi
}

#################################################
# Function: preview_file
# Description: Displays the first 10 lines of a text file or shows file type information if it is a binary file.
# Arguments: 
#   $1 - File ID (identifier of the file to preview)
# Returns: Displays preview or file type info on screen.
#################################################
preview_file() {
    local input="$1"
    local metadata recycle_path id name original_path type display_label mime

    # trim whitespace
    input=$(printf '%s' "$input" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    if [ -z "$input" ]; then
        echo -e "${RED}Error: No ID or filename provided${NC}"
        return 1
    fi

    # Ensure metadata file exists
    if [ -f "$METADATA_FILE" ]; then
        # try exact ID match using awk (safe, no regex)
        metadata=$(awk -F',' -v id="$input" '$1==id {print; exit}' "$METADATA_FILE" 2>/dev/null || true)

        # if not found by ID, try filename (case-insensitive)
        if [ -z "$metadata" ]; then
            metadata=$(awk -F',' -v nm="$(printf '%s' "$input" | tr '[:upper:]' '[:lower:]')" 'tolower($2)==nm {print; exit}' "$METADATA_FILE" 2>/dev/null || true)
        fi
    fi

    if [ -n "$metadata" ]; then
        IFS=',' read -r id name original_path _ _ type _ _ <<< "$metadata"
        id=$(printf '%s' "$id" | tr -d '[:space:]')
        type=$(printf '%s' "$type" | tr -d '[:space:]')
        display_label="${input}"

        # locate stored item: dirs or files (accept id without extension)
        if [ "$type" = "DIR" ]; then
            if [ -d "$FILES_DIR/$id" ]; then
                recycle_path="$FILES_DIR/$id"
            fi
        else
            if [ -e "$FILES_DIR/$id.$type" ]; then
                recycle_path="$FILES_DIR/$id.$type"
            else
                for f in "$FILES_DIR"/"$id".* "$FILES_DIR"/"$id"*; do
                    [ -e "$f" ] || continue
                    recycle_path="$f"
                    break
                done
            fi
        fi

        if [ -z "$recycle_path" ]; then
            echo -e "${YELLOW}Warning: Stored item for ID '$id' not found in $FILES_DIR${NC}"
            return 1
        fi
    else
        # fallback: search by filename in files tree (case-insensitive)
        recycle_path=$(find "$FILES_DIR" -iname "$input" -print -quit 2>/dev/null || true)
        if [ -z "$recycle_path" ]; then
            echo -e "${RED}Error: No item found by ID or name '$input'${NC}"
            return 1
        fi
        display_label="$input"
    fi

    # Directory preview
    if [ -d "$recycle_path" ]; then
        echo "---- Preview: Directory $display_label ----"
        echo "Contents (up to 100 entries):"
        ls -la -- "$recycle_path" | sed -n '1,100p'
        return 0
    fi

    # File preview
    if [ ! -f "$recycle_path" ]; then
        echo -e "${RED}Error: Recycle item not found: $recycle_path${NC}"
        return 1
    fi

    mime=$(file --mime-type -b -- "$recycle_path" 2>/dev/null || echo "application/octet-stream")
    echo "---- Preview: $display_label (stored: $(basename "$recycle_path")) ----"
    if [[ "$mime" == text/* ]] || file --brief "$recycle_path" | grep -qi 'ASCII\|text'; then
        head -n 30 -- "$recycle_path"
    else
        file --brief "$recycle_path"
    fi

    return 0
}


#################################################
# Function: main
# Description: Main program logic
# Parameters: Command line arguments
# Returns: Exit code
#################################################
main() {
    # Initialize recycle bin
    initialize_recyclebin
    auto_cleanup
    check_quota

    # Parse command line arguments
    case "$1" in
        delete)
            shift
            delete_file "$@"
            ;;
        list)
            list_recycled "$@"
            ;;
        restore)
            shift
            restore_file "$@"
            ;;
        search)
            shift
            search_recycled "$@"
            ;;
        empty)
            shift
            empty_recyclebin "$@"
            ;;
        help|--help|-h)
            display_help
            ;;
        stats)
            show_statistics
            ;;
        preview)
            shift
            preview_file "$@"
            ;;
        quota)
            check_quota
            ;;
        *)
            echo "Invalid option. Use 'help' for usage information."
            exit 1
            ;;
        esac
}

# Execute main function with all arguments
main "$@"