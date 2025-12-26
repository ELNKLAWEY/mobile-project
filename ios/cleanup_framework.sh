#!/bin/bash
# Wrapper script to clean extended attributes from Flutter framework after unpack
# This script wraps Flutter's xcode_backend.sh and cleans extended attributes
# that can cause code signing failures

# Function to aggressively clean extended attributes
clean_framework_attributes() {
  local framework_path="$1"
  if [ -f "${framework_path}/Flutter" ]; then
    # Remove all extended attributes recursively (capital C is more aggressive)
    xattr -cr "${framework_path}" 2>/dev/null || true
    # Also try removing from the binary directly
    xattr -c "${framework_path}/Flutter" 2>/dev/null || true
    # Use cp -X to copy without extended attributes, then replace
    cp -X "${framework_path}/Flutter" "${framework_path}/Flutter.tmp" 2>/dev/null && \
    mv -f "${framework_path}/Flutter.tmp" "${framework_path}/Flutter" 2>/dev/null || true
  fi
}

# Run the Flutter build script
/bin/sh "$FLUTTER_ROOT/packages/flutter_tools/bin/xcode_backend.sh" "$@"
EXIT_CODE=$?

# Clean extended attributes from Flutter framework in multiple possible locations
# This handles both the unpack target and the Runner target build directories

# Clean from BUILT_PRODUCTS_DIR if available
if [ -n "${BUILT_PRODUCTS_DIR}" ]; then
  clean_framework_attributes "${BUILT_PRODUCTS_DIR}/Flutter.framework"
fi

# Also check the build/ios directory structure
# SRCROOT points to the ios directory, so go up one level for project root
PROJECT_DIR="${SRCROOT%/ios}"
PROJECT_DIR="${PROJECT_DIR:-${PWD%/ios}}"

for config in Debug-iphonesimulator Release-iphonesimulator Debug-iphoneos Release-iphoneos; do
  FRAMEWORK_PATH="${PROJECT_DIR}/build/ios/${config}/Flutter.framework"
  if [ -f "${FRAMEWORK_PATH}/Flutter" ]; then
    clean_framework_attributes "${FRAMEWORK_PATH}"
  fi
done

# Return the exit code from the Flutter script
exit $EXIT_CODE

