#!/bin/bash

# PEASS-ng Spell
# Clones PEASS-ng repository, builds linPEAS, and moves the result to bin folder

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
REPO_URL="https://github.com/IsaacNietoG/PEASS-ng"
TEMP_DIR="/tmp/peass-ng-build"
BUILD_SCRIPT="./buildCustom.sh"
OUTPUT_FILE="/tmp/linpeas_ctf.sh"
BIN_DIR="$(cd "$(dirname "$0")" && pwd)/../bin"
TARGET_NAME="ctflinpeas"

print_status "Starting PEASS-ng spell..."

# Create temporary directory
print_status "Creating temporary directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"

# Clone repository
print_status "Cloning PEASS-ng repository..."
cd "$TEMP_DIR"
git clone "$REPO_URL" .

# Change to linPEAS directory
print_status "Changing to linPEAS directory..."
cd linPEAS

# Check if build script exists
if [ ! -f "$BUILD_SCRIPT" ]; then
    print_error "Build script not found at $BUILD_SCRIPT"
    exit 1
fi

# Make build script executable and run it
print_status "Building linPEAS..."
chmod +x "$BUILD_SCRIPT"
./"$BUILD_SCRIPT"

# Check if output file was created
if [ ! -f "$OUTPUT_FILE" ]; then
    print_error "Expected output file not found at $OUTPUT_FILE"
    exit 1
fi

# Move file to bin directory
print_status "Moving linPEAS to bin directory..."
mkdir -p "$BIN_DIR"
cp "$OUTPUT_FILE" "$BIN_DIR/$TARGET_NAME"
chmod +x "$BIN_DIR/$TARGET_NAME"

print_status "Successfully installed linPEAS to $BIN_DIR/$TARGET_NAME"

# Cleanup
print_status "Cleaning up temporary files..."
rm -rf "$TEMP_DIR"
rm -f "$OUTPUT_FILE"

print_status "PEASS-ng spell completed successfully!" 