#!/bin/bash

# Spell: Generate tmux configuration with hardcoded paths
# This spell generates a tmux.conf file with absolute paths resolved at execution time

# Get the repository base directory (where this spell is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_BASE="$(cd "$SCRIPT_DIR/.." && pwd)"
TMUX_CONFIG_DIR="$REPO_BASE/.config/tmux"
PLUGIN_DIR="$REPO_BASE/.config/tmux/plugins"
TMUX_CONF_FILE="$TMUX_CONFIG_DIR/tmux.conf"
TEMPLATE_FILE="$SCRIPT_DIR/tmux-config.template"

echo "Generating tmux configuration..."
echo "Repository base: $REPO_BASE"
echo "Plugin directory: $PLUGIN_DIR"
echo "Config file: $TMUX_CONF_FILE"
echo "Template file: $TEMPLATE_FILE"

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

# Create tmux config directory if it doesn't exist
mkdir -p "$TMUX_CONFIG_DIR"

# Copy template to config file
cp "$TEMPLATE_FILE" "$TMUX_CONF_FILE"

# Replace placeholders with actual values
sed -i "s|PLUGIN_DIR_PLACEHOLDER|$PLUGIN_DIR|g" "$TMUX_CONF_FILE"
sed -i "s|PLACEHOLDER_DATE|$(date)|g" "$TMUX_CONF_FILE"

echo "✅ Tmux configuration generated successfully!"
echo "📁 Config file: $TMUX_CONF_FILE"
echo "🔧 Plugin directory: $PLUGIN_DIR"
echo "📝 Template used: $TEMPLATE_FILE"
