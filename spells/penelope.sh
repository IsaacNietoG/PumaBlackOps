#!/bin/bash

# Penelope Spell
# Downloads penelope.py tool and sets it up in bin folder

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
PENELOPE_URL="https://raw.githubusercontent.com/brightio/penelope/refs/heads/main/penelope.py"
TEMP_DIR="/tmp/penelope-download"
BIN_DIR="$(cd "$(dirname "$0")" && pwd)/../bin"
TARGET_NAME="penelope"

print_status "Starting Penelope spell..."

# Create temporary directory
print_status "Creating temporary directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Download penelope.py
print_status "Downloading penelope.py..."
cd "$TEMP_DIR"
wget "$PENELOPE_URL" -O penelope.py

# Check if download was successful
if [ ! -f "penelope.py" ]; then
    print_error "Failed to download penelope.py"
    exit 1
fi

# Move file to bin directory
print_status "Installing penelope to bin directory..."
mkdir -p "$BIN_DIR"
cp "penelope.py" "$BIN_DIR/$TARGET_NAME"
chmod +x "$BIN_DIR/$TARGET_NAME"

print_status "Successfully installed penelope to $BIN_DIR/$TARGET_NAME"

# Cleanup
print_status "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"

print_status "Penelope spell completed successfully!" 