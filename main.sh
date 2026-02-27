#!/bin/bash

echo "========================================"
echo " macOS Tahoe Tamer"
echo "========================================"

# Get Input App
if [ -n "$1" ]; then
    INPUT_APP="$1"
else
    read -p "Drag and drop the Application here (then press Enter): " INPUT_APP
fi
# Remove trailing spaces and single quotes (Terminal drag-and-drop artifacts)
INPUT_APP="${INPUT_APP%"${INPUT_APP##*[![:space:]]}"}"
INPUT_APP="${INPUT_APP#\'}"
INPUT_APP="${INPUT_APP%\'}"

# Get Output Directory
if [ -n "$2" ]; then
    OUTPUT_DIR="$2"
else
    read -p "Drag and drop the Output Directory here (then press Enter): " OUTPUT_DIR
fi
OUTPUT_DIR="${OUTPUT_DIR%"${OUTPUT_DIR##*[![:space:]]}"}"
OUTPUT_DIR="${OUTPUT_DIR#\'}"
OUTPUT_DIR="${OUTPUT_DIR%\'}"

# Validate paths
if [ ! -d "$INPUT_APP" ] || [ ! -d "$OUTPUT_DIR" ]; then
    echo "Error: Invalid Application or Output Directory path."
    exit 1
fi

# Extract names
APP_NAME=$(basename "$INPUT_APP")
BASE_NAME="${APP_NAME%.*}"
NEW_APP_NAME="${BASE_NAME}_Tamed.app"
TARGET_APP="$OUTPUT_DIR/$NEW_APP_NAME"

echo ""
echo "[1/6] Copying $APP_NAME to $OUTPUT_DIR as $NEW_APP_NAME..."
cp -R "$INPUT_APP" "$TARGET_APP"

echo "[2/6] Clearing quarantine flags..."
xattr -cr "$TARGET_APP"

INFO_PLIST="$TARGET_APP/Contents/Info.plist"
if [ -f "$INFO_PLIST" ]; then
    echo "[3/6] Modifying Bundle Identifier..."
    # Format a safe bundle ID (lowercase, remove spaces)
    SAFE_NAME=$(echo "$BASE_NAME" | tr '[:upper:]' '[:lower:]' | tr -d ' ')
    plutil -replace CFBundleIdentifier -string "com.custom.$SAFE_NAME.tamed" "$INFO_PLIST"
    
    # Safely extract exact executable name from Info.plist
    EXEC_NAME=$(plutil -extract CFBundleExecutable raw -o - "$INFO_PLIST")
else
    echo "Warning: Info.plist not found. Guessing executable name..."
    EXEC_NAME="$BASE_NAME"
fi

EXEC_PATH="$TARGET_APP/Contents/MacOS/$EXEC_NAME"

if [ ! -f "$EXEC_PATH" ]; then
    echo "Error: Executable not found at $EXEC_PATH"
    exit 1
fi

echo "[4/6] Thinning architecture (extracting x86_64 for Rosetta)..."
lipo -thin x86_64 "$EXEC_PATH" -output "$EXEC_PATH" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "      Warning: lipo failed. Binary might not be a fat binary or lacks an x86_64 slice."
fi

echo "[5/6] Stripping signature and Spoofing Mach-O SDK header (15.0)..."
codesign --remove-signature "$EXEC_PATH" 2>/dev/null
vtool -set-build-version macos 15.0 15.0 -replace -output "$EXEC_PATH" "$EXEC_PATH"

echo "[6/6] Resigning the application (Ad-hoc)..."
codesign --force --deep --sign - "$TARGET_APP"

echo "========================================"
echo " Done! You can now launch: $TARGET_APP"
echo "========================================"

