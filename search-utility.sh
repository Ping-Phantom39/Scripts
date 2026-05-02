#!/bin/bash
# Search Utility Script
# Enhanced file search with various filtering options

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
    echo -e "${CYAN}Search Utility Script${NC}"
    echo ""
    echo "Usage: $0 [options] <search_term>"
    echo ""
    echo "Options:"
    echo "  -d, --dir DIR       Directory to search in (default: current)"
    echo "  -t, --type TYPE     File type: all, file, dir, link"
    echo "  -m, --modified MIN  Files modified in last MIN minutes"
    echo "  -s, --size SIZE     Files larger than SIZE (e.g., 1M, 500K)"
    echo "  -e, --extension EXT Filter by extension (e.g., txt, py, jpg)"
    echo "  -i, --ignore-case   Case insensitive search"
    echo "  -x, --exclude DIR   Exclude directory (can be repeated)"
    echo "  -p, --print         Show full path (default: relative)"
    echo "  -n, --no-color      Disable colored output"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -d /home user -e txt"
    echo "  $0 --modified 60 --size 1M"
    echo "  $0 -x node_modules -x .git pattern"
}

# Parse arguments
DIR="."
SEARCH_TERM=""
TYPE_FILTER=""
MODIFIED_MIN=""
SIZE_FILTER=""
EXT_FILTER=""
IGNORE_CASE=false
EXCLUDES=()
FULL_PATH=false
COLOR=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dir)
            DIR="$2"
            shift 2
            ;;
        -t|--type)
            TYPE_FILTER="$2"
            shift 2
            ;;
        -m|--modified)
            MODIFIED_MIN="$2"
            shift 2
            ;;
        -s|--size)
            SIZE_FILTER="$2"
            shift 2
            ;;
        -e|--extension)
            EXT_FILTER="$2"
            shift 2
            ;;
        -i|--ignore-case)
            IGNORE_CASE=true
            shift
            ;;
        -x|--exclude)
            EXCLUDES+=("$2")
            shift 2
            ;;
        -p|--print)
            FULL_PATH=true
            shift
            ;;
        -n|--no-color)
            COLOR=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            if [[ -z "$SEARCH_TERM" ]]; then
                SEARCH_TERM="$1"
            fi
            shift
            ;;
    esac
done

# Check if directory exists
if [[ ! -d "$DIR" ]]; then
    echo -e "${RED}Error: Directory '$DIR' does not exist${NC}"
    exit 1
fi

# Build find command
FIND_CMD="find \"$DIR\" -type"

# Type filter
case "$TYPE_FILTER" in
    file)  FIND_CMD+=" f" ;;
    dir)   FIND_CMD+=" d" ;;
    link)  FIND_CMD+=" l" ;;
    *)     FIND_CMD+=" f" ;;
esac

# Size filter
if [[ -n "$SIZE_FILTER" ]]; then
    FIND_CMD+=" -size +$SIZE_FILTER"
fi

# Modified filter
if [[ -n "$MODIFIED_MIN" ]]; then
    FIND_CMD+=" -mmin -$MODIFIED_MIN"
fi

# Build exclude arguments
for exclude in "${EXCLUDES[@]}"; do
    FIND_CMD+=" -path \"$DIR/$exclude\" -prune -o"
done

# Name search
if [[ -n "$SEARCH_TERM" ]]; then
    if [[ "$IGNORE_CASE" == true ]]; then
        FIND_CMD+=" -iname \"$SEARCH_TERM\""
    else
        FIND_CMD+=" -name \"$SEARCH_TERM\""
    fi
else
    FIND_CMD+=" -name \"*\""
fi

# Extension filter (apply after name search)
if [[ -n "$EXT_FILTER" ]]; then
    if [[ "$IGNORE_CASE" == true ]]; then
        FIND_CMD+=" -iname \"*.$EXT_FILTER\""
    else
        FIND_CMD+=" -name \"*.$EXT_FILTER\""
    fi
fi

FIND_CMD+=" -print0"

# Execute and format output
if [[ "$COLOR" == true ]]; then
    # Colorize output
    eval $FIND_CMD | while IFS= read -r -d '' file; do
        if [[ -f "$file" ]]; then
            echo -e "${GREEN}$file${NC}"
        elif [[ -d "$file" ]]; then
            echo -e "${BLUE}$file/${NC}"
        elif [[ -L "$file" ]]; then
            echo -e "${PURPLE}$file${NC}"
        fi
    done
else
    eval $FIND_CMD | while IFS= read -r -d '' file; do
        echo "$file"
    done
fi | head -n 100  # Limit to 100 results

# Show count
if [[ "$COLOR" == true ]]; then
    COUNT=$(eval $FIND_CMD | tr -cd '\0' | wc -c)
    echo -e "\n${CYAN}Found ${GREEN}$COUNT${CYAN} results${NC}"
else
    COUNT=$(eval $FIND_CMD | tr -cd '\0' | wc -c)
    echo -e "\nFound $COUNT results"
fi

# Show search summary
echo -e "\n${BOLD}${BLUE}━━━ SEARCH SUMMARY ━━━${NC}"
echo -e "${CYAN}Directory:${NC} $DIR"
if [[ -n "$SEARCH_TERM" ]]; then
    echo -e "${CYAN}Pattern:${NC} $SEARCH_TERM"
fi
if [[ -n "$EXT_FILTER" ]]; then
    echo -e "${CYAN}Extension:${NC} .$EXT_FILTER"
fi
if [[ -n "$SIZE_FILTER" ]]; then
    echo -e "${CYAN}Size:${NC} > $SIZE_FILTER"
fi
if [[ -n "$MODIFIED_MIN" ]]; then
    echo -e "${CYAN}Modified:${NC} within $MODIFIED_MIN minutes"
fi
if [[ -n "$TYPE_FILTER" ]]; then
    echo -e "${CYAN}Type:${NC} $TYPE_FILTER"
fi
[[ ${#EXCLUDES[@]} -gt 0 ]] && echo -e "${YELLOW}Excluded:${NC} ${EXCLUDES[*]}"
