#!/bin/bash

# Exit on any error
set -e

echo "⚙️ Creating DMG for SysWidget..."

# Variables
APP_NAME="SysWidget"
APP_PATH="Distribution/${APP_NAME}.app"
DMG_PATH="Distribution/${APP_NAME}.dmg"
DMG_TEMP_PATH="Distribution/${APP_NAME}_temp.dmg"
VOLUME_NAME="${APP_NAME}"

# Create Distribution directory if it doesn't exist
mkdir -p Distribution

# Remove existing DMG if it exists
if [ -f "$DMG_PATH" ]; then
  echo "🗑️ Removing existing DMG..."
  rm "$DMG_PATH"
fi

# Check if we need to copy the app from another location
if [ ! -d "$APP_PATH" ]; then
  echo "⚠️ App not found in Distribution folder."
  echo "Please make sure the app is built and located at $APP_PATH"
  echo "Alternatively, specify path to the built app as an argument to this script."
  
  if [ ! -z "$1" ]; then
    SOURCE_APP="$1"
    echo "📦 Copying app from $SOURCE_APP..."
    cp -R "$SOURCE_APP" "$APP_PATH"
  else
    exit 1
  fi
fi

# Create temporary DMG
echo "🔧 Creating temporary DMG..."
hdiutil create -volname "$VOLUME_NAME" -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_TEMP_PATH"

# Move to final location
echo "✅ Moving DMG to final location..."
mv "$DMG_TEMP_PATH" "$DMG_PATH"

echo "🎉 DMG created successfully at $DMG_PATH"
echo "   Size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "To use the DMG, double-click it and drag the app to Applications folder." 