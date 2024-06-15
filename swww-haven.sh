#!/bin/bash

# Version Data
VERSION_MAJOR=0
VERSION_MINOR=1
VERSION_PATCH=1
VERSION_BUILD=1

# Dependencies check
if ! command -v curl &> /dev/null
then
    echo "cURL is required but it's not installed. Exiting." >&2
    exit 1
fi

SQLITE3_ENABLED=false
if command -v sqlite3 &> /dev/null
then
    SQLITE3_ENABLED=true
fi

# Default values for arguments
VERBOSE=false
USE_COLOR=false
USE_DEBUG=false
ACTION=""
DB_FILE="$HOME/.wallpapers.db"

# Define API endpoint and directories
API_ENDPOINT="https://wallhaven.cc/api/v1/search"
QUERY_FILE="query.json"
DOWNLOAD_DIR="$HOME/Pictures/.wallpapers"
SCHEMA_FILE="schema.sql"

# ANSI color codes
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
NC="\033[0m" # No Color

# Print usage information
print_help() {
    echo "Usage: $(basename $0) [options] <action>"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message and exit"
    echo "  -v, --version       Show version information and exit"
    echo "      --verbose       Enable verbose output"
    echo "      --color         Enable colored output"
    echo "  -d, --debug         Enable debug output"
    echo ""
    echo "Actions:"
    echo "  help                Show this help message and exit"
    echo "  init                Initialize the database"
    echo "  download            Run the main script and download the files"
    echo "  dry                 Run the script but don't save any files or database entries"
    echo "  set                 Placeholder action (echoes 'TODO')"
}

print_version() {
  echo "Swww Haven v$VERSION_MAJOR.$VERSION_MINOR.$VERSION_PATCH"
  echo "Build #$VERSION_BUILD"
}

# Log messages if verbose mode is enabled
log() {
    if $VERBOSE; then
        if $USE_COLOR; then
            echo -e "${GREEN}$1${NC}"
        else
            echo "$1"
        fi
    fi
}

# Informative text code
info() {
    if $VERBOSE; then
        if $USE_COLOR; then
            echo -e "${BLUE}$1${NC}"
        else
            echo "$1"
        fi
    fi
}

# Log error messages to stderr
debug() {
    if ! $DEBUG; then
      continue
    fi
    if $USE_COLOR; then
        echo -e "${YELLOW}$1${NC}" >&2
    else
        echo "$1" >&2
    fi
}

# Log error messages to stderr
error() {
    if $USE_COLOR; then
        echo -e "${RED}$1${NC}" >&2
    else
        echo "$1" >&2
    fi
}

# Database setup (if sqlite3 is enabled)
initialise_database() {
    if [ -f "$DB_FILE" ]; then
        info "Database already exists at: $DB_FILE"
    else
        if [ -f "$SCHEMA_FILE" ]; then
            sqlite3 "$DB_FILE" < "$SCHEMA_FILE"
	    local res=$?
            if [ $res -eq 0 ]; then
                info  "Database initialised using schema file: $SCHEMA_FILE"
                info  "Database location: $DB_FILE"
            else
                error "Failed to initialise database from schema file: $SCHEMA_FILE"
		>&2 echo $res
                exit 1
            fi
        else
            error "Schema file not found: $SCHEMA_FILE"
            exit 1
        fi
    fi
}

# Function to make the initial API request
make_api_request() {
    RESPONSE=$(curl -s -X GET -H "Content-Type: application/json" -d @"$QUERY_FILE" "$API_ENDPOINT")
    echo $RESPONSE
    local res=$?
    if [ $res -eq 0 ]; then
        log "API request made to $API_ENDPOINT"
    else
        error "Failed to make API request to $API_ENDPOINT"
        exit 1
    fi
    # debug "$RESPONSE" | jq .  # Print response for debugging purposes
    debug $RESPONSE | jq
    echo $RESPONSE
}

# Function to process the API response and download images
process_response() {
    local response="$1"
    local dry_run="$2"
    local skipped_count=0
    local total_count=0

    if $SQLITE3_ENABLED && ! $dry_run; then
        REQUEST_ID=$(sqlite3 "$DB_FILE" "INSERT INTO Requests (request_date) VALUES (datetime('now')); SELECT last_insert_rowid();")
        if [ $? -eq 0 ]; then
            log "Inserted request record with ID $REQUEST_ID"
        else
            error "Failed to insert request record"
            exit 1
        fi
    fi

    debug $response 
    total_count=$(echo "$response" | jq '.data | length')
    log "Total results retrieved: $total_count"

    echo "$response" | jq -c '.data[]' | while read -r item; do
        id=$(echo "$item" | jq -r '.id')
        path=$(echo "$item" | jq -r '.path')
        category=$(echo "$item" | jq -r '.category')
        purity=$(echo "$item" | jq -r '.purity')
        resolution_x=$(echo "$item" | jq -r '.dimension_x')
        resolution_y=$(echo "$item" | jq -r '.dimension_y')
        ratio=$(echo "$item" | jq -r '.ratio')
        created_at=$(echo "$item" | jq -r '.created_at')
        colours=$(echo "$item" | jq -r '.colors[]')

        # Check if the wallpaper already exists in the database
        if $SQLITE3_ENABLED; then
            exists=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM Wallpapers WHERE id='$id';")
            if [ "$exists" -gt 0 ]; then
                log "Skipping already downloaded wallpaper with ID $id"
                skipped_count=$((skipped_count + 1))
                continue
            fi
        fi

        # Download the image
        filename=$(basename "$path")
        if ! $dry_run; then
            curl -s -o "$DOWNLOAD_DIR/$filename" "$path"
            if [ $? -eq 0 ]; then
                log "Downloaded image: $filename"
            else
                error "Failed to download image: $filename"
                continue
            fi
        else
            log "Dry run: Skipping download of image: $filename"
        fi

        if $SQLITE3_ENABLED && ! $dry_run; then
            downloaded_at=$(date +"%Y-%m-%d %H:%M:%S")
            sqlite3 "$DB_FILE" <<EOF
INSERT OR IGNORE INTO Wallpapers (id, category, purity, path, resolution_x, resolution_y, ratio, created_at, downloaded_at) VALUES ('$id', '$category', '$purity', '$path', $resolution_x, $resolution_y, '$ratio', '$created_at', '$downloaded_at');
EOF
            if [ $? -eq 0 ]; then
                log "Inserted wallpaper record with ID $id"
            else
                error "Failed to insert wallpaper record with ID $id"
                continue
            fi
            for colour in $colours; do
                sqlite3 "$DB_FILE" <<EOF
INSERT OR IGNORE INTO Wallpaper_Colours (id, colour) VALUES ('$id', '$colour');
EOF
                if [ $? -eq 0 ]; then
                    log "Inserted colour record for wallpaper $id with colour $colour"
                else
                    error "Failed to insert colour record for wallpaper $id with colour $colour"
                fi
            done
            sqlite3 "$DB_FILE" <<EOF
INSERT OR IGNORE INTO Wallpaper_Discoveries (request, wallpaper) VALUES ($REQUEST_ID, '$id');
EOF
            if [ $? -eq 0 ]; then
                log "Linked request $REQUEST_ID with wallpaper $id"
            else
                error "Failed to link request $REQUEST_ID with wallpaper $id"
            fi
        fi
    done

    log "Skipped $skipped_count out of $total_count results."
}

# Function to parse command line arguments
parse_args() {
    if [[ "$#" -eq 0 ]]; then
        print_help
        exit 1
    fi

    while [[ "$#" -gt 0 ]]; do
        case "$1" in
            -h|--help)
		ACTION=help
                print_help
                exit 0
                ;;
            -v|--version)
		ACTION=version
                print_version
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                ;;
            --d|--debug)
                USE_DEBUG=true
                ;;
            --color|--colour)
                USE_COLOR=true
                ;;
            version|help|init|download|dry|set)
                ACTION="$1"
                ;;
            *)
                error "Unknown option or action: $1"
                print_help
                exit 1
                ;;
        esac
        shift
    done
}

# Main function
main() {
    parse_args "$@"

    # Handle actions
    case "$ACTION" in
        help)
            print_help
            ;;
        version)
            print_version
            ;;
        init)
            if $SQLITE3_ENABLED; then
                initialise_database
            else
                error "sqlite3 is not installed. Database cannot be initialised."
                exit 1
            fi
            ;;
        download)
            # Create download directory if it doesn't exist
            mkdir -p "$DOWNLOAD_DIR"
            if [ $? -eq 0 ]; then
                log "Download directory set to $DOWNLOAD_DIR"
            else
                error "Failed to create download directory: $DOWNLOAD_DIR"
                exit 1
            fi
            
            # Make API request and process the response
            response=$(make_api_request)
            process_response "$response" false
            ;;
        dry)
            response=$(make_api_request)
            process_response "$response" true
            ;;
        set)
            echo "TODO"
            ;;
        *)
            error "Unknown action: $ACTION"
            print_help
            exit 1
            ;;
    esac

    log "Processing complete."
}

# Execute main function
main "$@"

