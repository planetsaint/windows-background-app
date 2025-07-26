#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Building 32-bit Standalone Application with Plugin System...${NC}"

# Check if cross-compiler is installed
if ! command -v i686-w64-mingw32-g++ &>/dev/null; then
  echo -e "${RED}Error: 32-bit MinGW cross-compiler not found!${NC}"
  echo "Install it with:"
  echo "  Ubuntu/Debian: sudo apt install gcc-mingw-w64-i686 g++-mingw-w64-i686"
  echo "  Fedora/RHEL: sudo dnf install mingw32-gcc-c++"
  echo "  Arch: sudo pacman -S mingw-w64-gcc"
  exit 1
fi

# Clean previous builds
echo -e "${YELLOW}Cleaning previous builds...${NC}"
rm -f MyBackgroundApp.exe
rm -f sample_plugin.dll
rm -rf plugins

# Create plugins directory
mkdir -p plugins

# Build main application
echo -e "${YELLOW}Building standalone application...${NC}"
i686-w64-mingw32-g++ \
  -O2 \
  -DNDEBUG \
  -DWIN32 \
  -D_WIN32_WINNT=0x0601 \
  -m32 \
  -std=c++17 \
  -o MyBackgroundApp.exe \
  main.cpp \
  -lpsapi \
  -static-libgcc \
  -static-libstdc++ \
  -s \
  -Wl,--subsystem,console

# Check if application build was successful
if [ $? -eq 0 ] && [ -f "MyBackgroundApp.exe" ]; then
  echo -e "${GREEN}✓ Application build successful!${NC}"
else
  echo -e "${RED}✗ Application build failed!${NC}"
  exit 1
fi

# Build sample plugin
echo -e "${YELLOW}Building sample plugin...${NC}"
i686-w64-mingw32-g++ \
  -O2 \
  -DNDEBUG \
  -DWIN32 \
  -D_WIN32_WINNT=0x0601 \
  -m32 \
  -std=c++17 \
  -shared \
  -o plugins/sample_plugin.dll \
  sample_plugin.cpp \
  -static-libgcc \
  -static-libstdc++ \
  -s \
  -Wl,--subsystem,windows

# Check if plugin build was successful
if [ $? -eq 0 ] && [ -f "plugins/sample_plugin.dll" ]; then
  echo -e "${GREEN}✓ Plugin build successful!${NC}"
else
  echo -e "${RED}✗ Plugin build failed!${NC}"
  exit 1
fi

# Show file info
echo -e "${YELLOW}Build Results:${NC}"
echo "Application executable:"
ls -lh MyBackgroundApp.exe
file MyBackgroundApp.exe

echo -e "\nPlugin DLL:"
ls -lh plugins/sample_plugin.dll
file plugins/sample_plugin.dll

echo ""
echo -e "${GREEN}✓ All builds completed successfully!${NC}"
echo ""
echo -e "${YELLOW}Files created:${NC}"
echo "- MyBackgroundApp.exe (Main application)"
echo "- plugins/sample_plugin.dll (Sample plugin)"
echo "- run_app.bat (Windows runner script)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Copy all files to a Windows machine"
echo "2. Double-click MyBackgroundApp.exe or run_app.bat"
echo "3. Check logs: C:\\temp\\MyApp.log and C:\\temp\\SamplePlugin.log"
echo "4. Create additional plugins by following the sample_plugin.cpp template"
echo ""
echo -e "${YELLOW}Usage:${NC}"
echo "  MyBackgroundApp.exe                    # Interactive mode with menu"
echo "  MyBackgroundApp.exe -background        # Background mode"
echo "  MyBackgroundApp.exe -hide              # Hidden console mode"
echo "  MyBackgroundApp.exe -background -hide  # Silent background mode"

# Create runner script for Windows
cat >run_app.bat <<'EOF'
@echo off
title MyBackgroundApp
echo Starting MyBackgroundApp...
echo.

REM Create temp directory for logs if it doesn't exist
if not exist "C:\temp" mkdir "C:\temp"

REM Run the application
MyBackgroundApp.exe

echo.
echo Application stopped.
pause
EOF

echo -e "${GREEN}Installation scripts created!${NC}"
