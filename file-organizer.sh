#!/bin/bash
# File Organizer Script
# Organize files in a directory by type

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

show_help() {
    echo -e "${CYAN}File Organizer Script${NC}"
    echo ""
    echo "Usage: $0 [directory] [options]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run    Show what would be done without moving files"
    echo "  -h, --help       Show this help message"
    echo "  -v, --verbose    Show detailed output"
    echo ""
    echo "Examples:"
    echo "  $0 /home/user/Downloads"
    echo "  $0 /home/user/Downloads --dry-run"
    echo "  $0 . -v"
}

# File type categories and their extensions
declare -A EXTENSIONS
EXTENSIONS=(
    ["images"]="jpg jpeg png gif bmp svg webp ico"
    ["videos"]="mp4 mkv movavi wmv flv webm"
    ["audio"]="mp3 wav ogg flac m4a aac"
    ["documents"]="pdf doc docx txt rtf odt ods odt xlsx xls csv"
    ["archives"]="zip tar gz bz2 xz 7z rar"
    ["scripts"]="sh bash py js ts tsx jsx vue"
    ["config"]="json yaml yml xml cfg conf ini"
)

organize_files() {
    local dir="${1:-.}"
    local dry_run=false
    local verbose=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                if [[ -d "$1" ]]; then
                    dir="$1"
                fi
                shift
                ;;
        esac
    done
    
    # Check if directory exists
    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}Error: Directory '$dir' does not exist${NC}"
        exit 1
    fi
    
    # Change to directory
    cd "$dir" || exit 1
    
    echo -e "${BOLD}${BLUE}━━━ FILE ORGANIZER ━━━${NC}"
    echo -e "${CYAN}Working directory:${NC} $(pwd)"
    [[ "$dry_run" == true ]] && echo -e "${YELLOW}[DRY RUN - No files will be moved]${NC}"
    echo ""
    
    local moved_count=0
    local skipped_count=0
    
    # Process each file
    for file in *; do
        [[ ! -f "$file" ]] && continue
        [[ "$file" == "$0" ]] && continue
        
        local file_ext="${file##*.}"
        local moved=false
        
        # Check each category
        for category in "${!EXTENSIONS[@]}"; do
            for ext in ${EXTENSIONS[$category]}; do
                if [[ "${file_ext,,}" == "${ext,,}" ]]; then
                    # Create directory if it doesn't exist
                    if [[ ! -d "$category" ]]; then
                        if [[ "$dry_run" == true ]]; then
                            echo -e "${CYAN}Would create directory:${NC} $category/"
                        else
                            mkdir -p "$category"
                        fi
                    fi
                    
                    # Move file
                    if [[ "$dry_run" == true ]]; then
                        echo -e "${YELLOW}Would move:${NC} $file -> $category/"
                        moved=true
                    else
                        # Handle duplicate filenames
                        if [[ -f "$category/$file" ]]; then
                            local base="${file%.*}"
                            local ext="${file##*.}"
                            local timestamp=$(date +%s)
                            local new_name="${base}_${timestamp}.${ext}"
                            
                            if [[ "$verbose" == true ]]; then
                                echo -e "${YELLOW}Renaming duplicate:${NC} $file -> $new_name"
                            fi
                            
                            if mv "$file" "$category/$new_name"; then
                                moved=true
                                ((moved_count++))
                            fi
                        else
                            if mv "$file" "$category/"; then
                                moved=true
                                ((moved_count++))
                            fi
                        fi
                    fi
                    break
                fi
            done
            [[ "$moved" == true ]] && break
        done
        
        if [[ "$moved" == false ]]; then
            [[ "$verbose" == true ]] && echo -e "${PURPLE}Skipped:${NC} $file (unknown type)"
            ((skipped_count++))
        fi
    done
    
    echo ""
    echo -e "${BOLD}${GREEN}━━━ RESULTS ━━━${NC}"
    if [[ "$dry_run" == true ]]; then
        echo -e "${CYAN}Dry run complete. Would have processed files.${NC}"
    else
        echo -e "${GREEN}Files moved:${NC} $moved_count"
        echo -e "${YELLOW}Files skipped:${NC} $skipped_count"
    fi
    
    # Show created directories
    echo -e "\n${BOLD}${BLUE}━━━ DIRECTORY STRUCTURE ━━━${NC}"
    tree -L 1 2>/dev/null || ls -la | grep "^d"
}

organize_files "$@"
