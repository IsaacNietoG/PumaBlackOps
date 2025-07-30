#!/bin/bash

# pspy64 Spell
# Descarga la ultima version de pspy64 y lo coloca en assaultrepository/

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration
REPO_URL="https://api.github.com/repos/DominicBreuker/pspy/releases/latest"
TARGET_DIR="$(cd "$(dirname "$0")" && pwd)/../assaultrepository"
TARGET_NAME="pspy64"

print_status "Starting pspy64 spell..."

# Check if curl is available
if ! command -v curl &> /dev/null; then
    print_error "curl is required but not installed"
    exit 1
fi

# Check if jq is available for JSON parsing
if ! command -v jq &> /dev/null; then
    print_warning "jq not found, will use fallback method"
    USE_JQ=false
else
    USE_JQ=true
fi

# Create target directory if it doesn't exist
print_status "Creating target directory..."
mkdir -p "$TARGET_DIR"

# Get the latest release information
print_status "Fetching latest release information..."
if [ "$USE_JQ" = true ]; then
    # Use jq to parse JSON and get download URL
    DOWNLOAD_URL=$(curl -s "$REPO_URL" | jq -r '.assets[] | select(.name | contains("pspy64")) | .browser_download_url' | head -1)
    
    if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
        print_error "Could not find pspy64 download URL in latest release"
        exit 1
    fi
else
    # Fallback method without jq
    print_warning "Using fallback method to find download URL"
    RELEASE_INFO=$(curl -s "$REPO_URL")
    DOWNLOAD_URL=$(echo "$RELEASE_INFO" | grep -o 'https://[^"]*pspy64[^"]*' | head -1)
    
    if [ -z "$DOWNLOAD_URL" ]; then
        print_error "Could not find pspy64 download URL in latest release"
        exit 1
    fi
fi

print_status "Found download URL: $DOWNLOAD_URL"

# Download pspy64
print_status "Downloading pspy64..."
TEMP_FILE="/tmp/pspy64_temp"
curl -L -o "$TEMP_FILE" "$DOWNLOAD_URL"

# Check if download was successful
if [ ! -f "$TEMP_FILE" ] || [ ! -s "$TEMP_FILE" ]; then
    print_error "Failed to download pspy64"
    exit 1
fi

# Move to target directory and make executable
print_status "Installing pspy64 to $TARGET_DIR/$TARGET_NAME..."
cp "$TEMP_FILE" "$TARGET_DIR/$TARGET_NAME"
chmod +x "$TARGET_DIR/$TARGET_NAME"

# Verify installation
if [ -f "$TARGET_DIR/$TARGET_NAME" ] && [ -x "$TARGET_DIR/$TARGET_NAME" ]; then
    print_status "Successfully installed pspy64 to $TARGET_DIR/$TARGET_NAME"
    
    # Show file info
    FILE_SIZE=$(du -h "$TARGET_DIR/$TARGET_NAME" | cut -f1)
    print_status "File size: $FILE_SIZE"
else
    print_error "Failed to install pspy64"
    exit 1
fi

# Cleanup
print_status "Cleaning up temporary files..."
rm -f "$TEMP_FILE"

print_status "pspy64 spell completed successfully!" 