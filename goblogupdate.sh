#!/bin/bash

# Define the location of your existing GoBlog installation
GOBLOG_LOCATION="/usr/local/bin/GoBlog"
GOBLOG_INSTALL_DIR="/var/GoBlog"

# Save the current working directory
current_dir=$(pwd)

# Change to the temporary directory
cd /tmp

# Remove any existing GoBlog clone
rm -rf GoBlog

# Clone the latest version of GoBlog
git clone https://github.com/jlelse/GoBlog.git

# Change to the new GoBlog directory
cd GoBlog

# Build GoBlog
go-devel build -tags=sqlite_fts5 -ldflags '-w -s' -o GoBlog

# Replace the existing GoBlog binary with the new one
mv GoBlog $GOBLOG_LOCATION

# Replace other necessary files (excluding config and data directories)
rsync -av --exclude='/config' --exclude='/data' pkgs testdata templates leaflet hlsjs dbmigrations strings plugins $GOBLOG_INSTALL_DIR/

# Change back to the previous working directory
cd "$current_dir"

# Print out a success message
echo "GoBlog has been successfully updated."
