# MyBackgroundApp

A lightweight 32-bit Windows application with a dynamic plugin system, built for extensibility and ease of use.
> Can be used as a payload horse for Shellter injection

##  Features

- **Cross-platform development**: Built on Linux, runs on Windows
- **Plugin System**: Dynamic loading of DLL plugins at runtime
- **Interactive Mode**: Real-time control with menu interface
- **Background Mode**: Silent operation with command-line options
- **Memory Monitoring**: Built-in memory usage tracking
- **Comprehensive Logging**: Detailed logs for debugging and monitoring
- **No Admin Rights Required**: Runs as regular user (unlike Windows services)

##  Table of Contents

- [Quick Start](#quick-start)
- [Usage](#usage)
- [Plugin Development](#plugin-development)
- [Building from Source](#building-from-source)
- [Command Line Options](#command-line-options)
- [File Structure](#file-structure)
- [Contributing](#contributing)
- [License](#license)

##  Quick Start

### Windows Users

1. **Download** the latest release from the [Releases](../../releases) page
2. **Extract** the ZIP file to your desired location
3. **Run** `MyBackgroundApp.exe` or double-click `run_app.bat`
4. **Interact** with the application using the menu options

### First Run
```cmd
# Interactive mode with menu
MyBackgroundApp.exe

# Background mode (no interaction)
MyBackgroundApp.exe -background

# Hidden console mode
MyBackgroundApp.exe -hide

# Silent background mode
MyBackgroundApp.exe -background -hide
```

## Usage

### Interactive Mode

When you run the application without arguments, you'll see a menu with these options:

```
=== MyBackgroundApp Menu ===
1. Show loaded plugins
2. Show application status
3. Reload plugins
4. View recent log entries
5. Toggle console visibility
6. Execute plugins once
q. Quit application
```

### Plugin Management

- **View Plugins**: See all loaded plugins with their versions and descriptions
- **Reload Plugins**: Refresh the plugin system without restarting the application
- **Manual Execution**: Trigger plugin execution outside the normal 5-second cycle

### Monitoring

- **Memory Usage**: Real-time memory consumption tracking
- **Log Viewing**: Browse recent log entries from within the application
- **Plugin Status**: Monitor individual plugin health and execution

## Plugin Development

### Creating a Plugin

1. **Use the template**: Start with `sample_plugin.cpp`
2. **Implement required functions**:
   - `GetPluginInfo()` - Return plugin metadata
   - `InitializePlugin()` - Setup plugin resources
   - `ExecutePlugin()` - Main plugin logic (called every 5 seconds)
   - `CleanupPlugin()` - Release resources

3. **Build the DLL**:
   ```bash
   # Linux cross-compilation
   i686-w64-mingw32-g++ -shared -o your_plugin.dll your_plugin.cpp -static-libgcc -static-libstdc++
   
   # Windows with MinGW
   g++ -shared -o your_plugin.dll your_plugin.cpp
   
   # Windows with Visual Studio
   cl /LD your_plugin.cpp /link /OUT:your_plugin.dll
   ```

4. **Deploy**: Place the DLL in the `plugins` folder

### Plugin Template

```cpp
#include <windows.h>

typedef struct {
    const char* name;
    const char* version;
    const char* description;
} PluginInfo;

static PluginInfo g_PluginInfo = {
    "Your Plugin Name",
    "1.0.0",
    "Description of your plugin functionality"
};

extern "C" {
    __declspec(dllexport) PluginInfo* GetPluginInfo() {
        return &g_PluginInfo;
    }
    
    __declspec(dllexport) BOOL InitializePlugin() {
        // Initialize your plugin
        return TRUE;
    }
    
    __declspec(dllexport) void ExecutePlugin() {
        // Your main plugin logic here
        // Called every 5 seconds
    }
    
    __declspec(dllexport) void CleanupPlugin() {
        // Clean up resources
    }
}
```

## Building from Source

### Prerequisites

**Linux (Cross-compilation)**:
```bash
# Ubuntu/Debian
sudo apt install gcc-mingw-w64-i686 g++-mingw-w64-i686

# Fedora/RHEL
sudo dnf install mingw32-gcc-c++

# Arch Linux
sudo pacman -S mingw-w64-gcc
```

**Windows**:
- MinGW-w64 or Visual Studio with C++ support

### Build Process

```bash
# Clone the repository
git clone https://github.com/yourusername/MyBackgroundApp.git
cd MyBackgroundApp

# Make build script executable
chmod +x build.sh

# Build everything
./build.sh
```

### Build Output

- `MyBackgroundApp.exe` - Main 32-bit application
- `plugins/sample_plugin.dll` - Example plugin
- `run_app.bat` - Windows runner script

## Command Line Options

| Option | Short | Description |
|--------|-------|-------------|
| `-background` | `-b` | Run in background mode (no interactive menu) |
| `-hide` | `-h` | Hide console window |
| `-help` | `--help` | Show help message and exit |

### Examples

```cmd
# Standard interactive mode
MyBackgroundApp.exe

# Background mode with visible console
MyBackgroundApp.exe -background

# Completely hidden operation
MyBackgroundApp.exe -background -hide

# Show help
MyBackgroundApp.exe -help
```

## File Structure

```
MyBackgroundApp/
├── MyBackgroundApp.exe          # Main application (32-bit)
├── plugins/                     # Plugin directory
│   └── sample_plugin.dll        # Example plugin
├── run_app.bat                  # Windows runner script
├── main.cpp                     # Source code
├── sample_plugin.cpp            # Plugin template
├── build.sh                     # Build script
└── README.md                    # This file

# Runtime files (created automatically)
C:\temp\
├── MyApp.log                    # Application log
└── SamplePlugin.log             # Plugin logs
```

## System Requirements

- **Windows**: XP SP3 or later (32-bit and 64-bit compatible)
- **Memory**: 1 MB RAM (minimal footprint)
- **Disk**: 2 MB for application + plugins
- **Privileges**: No administrator rights required

## Logging

### Log Locations

- **Application Log**: `C:\temp\MyApp.log`
- **Plugin Logs**: `C:\temp\[PluginName].log`

### Log Format

```
[YYYY-MM-DD HH:MM:SS] Log message here
```

## Troubleshooting

### Common Issues

**Application won't start**:
- Ensure you're running on Windows
- Check that `C:\temp` directory is writable
- Verify 32-bit compatibility

**Plugins not loading**:
- Check that DLL files are in the `plugins` folder
- Verify plugin exports all required functions
- Review application log for specific errors

**High memory usage**:
- Use option 2 in the menu to check memory consumption
- Consider plugin optimization
- Restart application to clear memory

### Getting Help

1. Check the logs in `C:\temp\`
2. Use the application's built-in log viewer (menu option 4)
3. Create an issue on GitHub with log details

## Contributing

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-plugin`)
3. **Commit** your changes (`git commit -m 'Add amazing plugin'`)
4. **Push** to the branch (`git push origin feature/amazing-plugin`)
5. **Open** a Pull Request

### Development Guidelines

- Follow the existing code style
- Add logging for debugging
- Test plugins thoroughly
- Update documentation for new features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with MinGW-w64 cross-compiler
- Developed on Linux for Windows compatibility
- Plugin architecture inspired by modern extensible applications

## Roadmap

- [ ] Plugin configuration files
- [ ] Network communication plugins
- [ ] GUI configuration interface
- [ ] Plugin marketplace/repository
- [ ] Enhanced security features
- [ ] Performance monitoring dashboard

---

**Made with ❤️ for extensible Windows applications**
