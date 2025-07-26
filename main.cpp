#include <windows.h>
#include <psapi.h>
#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <filesystem>
#include <thread>
#include <chrono>
#include <signal.h>

// Application name
const char APP_NAME[] = "MyBackgroundApp";

// Plugin interface definition
typedef struct {
    const char* name;
    const char* version;
    const char* description;
} PluginInfo;

// Plugin function types
typedef PluginInfo* (*GetPluginInfoFunc)();
typedef BOOL (*InitializePluginFunc)(void);
typedef void (*ExecutePluginFunc)(void);
typedef void (*CleanupPluginFunc)(void);

// Plugin structure
struct Plugin {
    HMODULE handle;
    PluginInfo* info;
    InitializePluginFunc initialize;
    ExecutePluginFunc execute;
    CleanupPluginFunc cleanup;
    std::string path;
};

// Global variables
std::vector<Plugin> g_LoadedPlugins;
bool g_Running = true;
bool g_ShowConsole = true;

// Function declarations
void WriteToLog(const std::string& message);
void LoadPlugins();
void UnloadPlugins();
void ExecutePlugins();
BOOL LoadPlugin(const std::string& pluginPath);
void ShowMenu();
void HandleInput();
void SignalHandler(int signal);
void RunInBackground();
void RunInteractive();

// Entry point
int main(int argc, char* argv[]) {
    // Set up signal handler for graceful shutdown
    signal(SIGINT, SignalHandler);
    signal(SIGTERM, SignalHandler);
    
    std::cout << "=== " << APP_NAME << " v1.0 ===" << std::endl;
    std::cout << "32-bit Standalone Application with Plugin System" << std::endl;
    std::cout << "=================================================" << std::endl;
    
    // Check command line arguments
    bool backgroundMode = false;
    bool hideConsole = false;
    
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-background") == 0 || strcmp(argv[i], "-b") == 0) {
            backgroundMode = true;
        } else if (strcmp(argv[i], "-hide") == 0 || strcmp(argv[i], "-h") == 0) {
            hideConsole = true;
        } else if (strcmp(argv[i], "-help") == 0 || strcmp(argv[i], "--help") == 0) {
            std::cout << "Usage: " << argv[0] << " [options]" << std::endl;
            std::cout << "Options:" << std::endl;
            std::cout << "  -background, -b    Run in background mode (no menu)" << std::endl;
            std::cout << "  -hide, -h         Hide console window" << std::endl;
            std::cout << "  -help, --help     Show this help message" << std::endl;
            return 0;
        }
    }
    
    // Hide console if requested
    if (hideConsole) {
        ShowWindow(GetConsoleWindow(), SW_HIDE);
        g_ShowConsole = false;
    }
    
    WriteToLog("Application starting...");
    
    // Load plugins
    LoadPlugins();
    
    if (backgroundMode) {
        std::cout << "Running in background mode. Press Ctrl+C to stop." << std::endl;
        RunInBackground();
    } else {
        std::cout << "Running in interactive mode." << std::endl;
        RunInteractive();
    }
    
    // Cleanup
    WriteToLog("Application shutting down...");
    UnloadPlugins();
    WriteToLog("Application stopped");
    
    return 0;
}

// Run in background mode
void RunInBackground() {
    WriteToLog("Background mode started");
    
    while (g_Running) {
        // Execute plugins
        ExecutePlugins();
        
        // Wait 5 seconds
        std::this_thread::sleep_for(std::chrono::seconds(5));
    }
    
    WriteToLog("Background mode stopped");
}

// Run in interactive mode with menu
void RunInteractive() {
    WriteToLog("Interactive mode started");
    
    // Start background thread for plugin execution
    std::thread backgroundThread([]{
        while (g_Running) {
            ExecutePlugins();
            std::this_thread::sleep_for(std::chrono::seconds(5));
        }
    });
    
    // Show menu and handle input
    while (g_Running) {
        ShowMenu();
        HandleInput();
    }
    
    // Wait for background thread to finish
    if (backgroundThread.joinable()) {
        backgroundThread.join();
    }
    
    WriteToLog("Interactive mode stopped");
}

// Show interactive menu
void ShowMenu() {
    std::cout << "\n=== " << APP_NAME << " Menu ===" << std::endl;
    std::cout << "1. Show loaded plugins" << std::endl;
    std::cout << "2. Show application status" << std::endl;
    std::cout << "3. Reload plugins" << std::endl;
    std::cout << "4. View recent log entries" << std::endl;
    std::cout << "5. Toggle console visibility" << std::endl;
    std::cout << "6. Execute plugins once" << std::endl;
    std::cout << "q. Quit application" << std::endl;
    std::cout << "Enter choice: ";
}

// Handle user input
void HandleInput() {
    std::string input;
    std::getline(std::cin, input);
    
    if (input == "1") {
        std::cout << "\nLoaded Plugins (" << g_LoadedPlugins.size() << "):" << std::endl;
        for (size_t i = 0; i < g_LoadedPlugins.size(); i++) {
            const auto& plugin = g_LoadedPlugins[i];
            std::cout << (i + 1) << ". " << plugin.info->name 
                      << " v" << plugin.info->version << std::endl;
            std::cout << "   Description: " << plugin.info->description << std::endl;
            std::cout << "   Path: " << plugin.path << std::endl;
        }
        if (g_LoadedPlugins.empty()) {
            std::cout << "No plugins loaded." << std::endl;
        }
    }
    else if (input == "2") {
        std::cout << "\nApplication Status:" << std::endl;
        std::cout << "Running: " << (g_Running ? "Yes" : "No") << std::endl;
        std::cout << "Plugins loaded: " << g_LoadedPlugins.size() << std::endl;
        std::cout << "Console visible: " << (g_ShowConsole ? "Yes" : "No") << std::endl;
        
        // Show memory usage
        PROCESS_MEMORY_COUNTERS pmc;
        if (GetProcessMemoryInfo(GetCurrentProcess(), &pmc, sizeof(pmc))) {
            std::cout << "Memory usage: " << (pmc.WorkingSetSize / 1024 / 1024) << " MB" << std::endl;
        }
    }
    else if (input == "3") {
        std::cout << "\nReloading plugins..." << std::endl;
        UnloadPlugins();
        LoadPlugins();
        std::cout << "Plugins reloaded. Total: " << g_LoadedPlugins.size() << std::endl;
    }
    else if (input == "4") {
        std::cout << "\nRecent log entries:" << std::endl;
        std::ifstream logFile("C:\\temp\\MyApp.log");
        if (logFile.is_open()) {
            std::vector<std::string> lines;
            std::string line;
            while (std::getline(logFile, line)) {
                lines.push_back(line);
            }
            
            // Show last 10 lines
            size_t start = lines.size() > 10 ? lines.size() - 10 : 0;
            for (size_t i = start; i < lines.size(); i++) {
                std::cout << lines[i] << std::endl;
            }
        } else {
            std::cout << "Could not open log file." << std::endl;
        }
    }
    else if (input == "5") {
        g_ShowConsole = !g_ShowConsole;
        ShowWindow(GetConsoleWindow(), g_ShowConsole ? SW_SHOW : SW_HIDE);
        std::cout << "Console " << (g_ShowConsole ? "shown" : "hidden") << std::endl;
    }
    else if (input == "6") {
        std::cout << "\nExecuting plugins once..." << std::endl;
        ExecutePlugins();
        std::cout << "Plugin execution completed." << std::endl;
    }
    else if (input == "q" || input == "quit" || input == "exit") {
        g_Running = false;
        std::cout << "Shutting down..." << std::endl;
    }
    else {
        std::cout << "Invalid choice. Please try again." << std::endl;
    }
}

// Signal handler for graceful shutdown
void SignalHandler(int signal) {
    WriteToLog("Received signal: " + std::to_string(signal));
    g_Running = false;
    std::cout << "\nShutting down..." << std::endl;
}

// Load all plugins from the plugins directory
void LoadPlugins() {
    WriteToLog("Loading plugins...");
    
    // Get the current executable directory
    char exePath[MAX_PATH];
    GetModuleFileName(NULL, exePath, MAX_PATH);
    std::string exeDir = std::string(exePath);
    size_t lastSlash = exeDir.find_last_of("\\/");
    if (lastSlash != std::string::npos) {
        exeDir = exeDir.substr(0, lastSlash);
    }
    
    std::string pluginsDir = exeDir + "\\plugins";
    
    // Create plugins directory if it doesn't exist
    CreateDirectory(pluginsDir.c_str(), NULL);
    
    // Search for DLL files in the plugins directory
    std::string searchPattern = pluginsDir + "\\*.dll";
    WIN32_FIND_DATA findData;
    HANDLE hFind = FindFirstFile(searchPattern.c_str(), &findData);
    
    if (hFind != INVALID_HANDLE_VALUE) {
        do {
            std::string pluginPath = pluginsDir + "\\" + findData.cFileName;
            if (LoadPlugin(pluginPath)) {
                WriteToLog("Loaded plugin: " + std::string(findData.cFileName));
                std::cout << "Loaded plugin: " << findData.cFileName << std::endl;
            } else {
                WriteToLog("Failed to load plugin: " + std::string(findData.cFileName));
                std::cout << "Failed to load plugin: " << findData.cFileName << std::endl;
            }
        } while (FindNextFile(hFind, &findData) != 0);
        FindClose(hFind);
    }
    
    WriteToLog("Plugin loading complete. Total plugins: " + std::to_string(g_LoadedPlugins.size()));
    std::cout << "Plugin loading complete. Total plugins: " << g_LoadedPlugins.size() << std::endl;
}

// Load a specific plugin
BOOL LoadPlugin(const std::string& pluginPath) {
    Plugin plugin = {};
    plugin.path = pluginPath;
    
    // Load the DLL
    plugin.handle = LoadLibrary(pluginPath.c_str());
    if (plugin.handle == NULL) {
        WriteToLog("Failed to load DLL: " + pluginPath);
        return FALSE;
    }
    
    // Get function pointers
    GetPluginInfoFunc getInfo = (GetPluginInfoFunc)GetProcAddress(plugin.handle, "GetPluginInfo");
    plugin.initialize = (InitializePluginFunc)GetProcAddress(plugin.handle, "InitializePlugin");
    plugin.execute = (ExecutePluginFunc)GetProcAddress(plugin.handle, "ExecutePlugin");
    plugin.cleanup = (CleanupPluginFunc)GetProcAddress(plugin.handle, "CleanupPlugin");
    
    // Verify required functions exist
    if (!getInfo || !plugin.initialize || !plugin.execute || !plugin.cleanup) {
        WriteToLog("Plugin missing required functions: " + pluginPath);
        FreeLibrary(plugin.handle);
        return FALSE;
    }
    
    // Get plugin info
    plugin.info = getInfo();
    if (!plugin.info) {
        WriteToLog("Failed to get plugin info: " + pluginPath);
        FreeLibrary(plugin.handle);
        return FALSE;
    }
    
    // Initialize the plugin
    if (!plugin.initialize()) {
        WriteToLog("Failed to initialize plugin: " + pluginPath);
        FreeLibrary(plugin.handle);
        return FALSE;
    }
    
    // Add to loaded plugins
    g_LoadedPlugins.push_back(plugin);
    
    WriteToLog("Plugin loaded - Name: " + std::string(plugin.info->name) + 
               ", Version: " + std::string(plugin.info->version) + 
               ", Description: " + std::string(plugin.info->description));
    
    return TRUE;
}

// Execute all loaded plugins
void ExecutePlugins() {
    for (auto& plugin : g_LoadedPlugins) {
        try {
            plugin.execute();
        } catch (...) {
            WriteToLog("Exception in plugin: " + plugin.path);
        }
    }
}

// Unload all plugins
void UnloadPlugins() {
    WriteToLog("Unloading plugins...");
    
    for (auto& plugin : g_LoadedPlugins) {
        try {
            plugin.cleanup();
        } catch (...) {
            WriteToLog("Exception during plugin cleanup: " + plugin.path);
        }
        
        FreeLibrary(plugin.handle);
        WriteToLog("Unloaded plugin: " + plugin.path);
    }
    
    g_LoadedPlugins.clear();
    WriteToLog("All plugins unloaded");
}

// Simple logging function
void WriteToLog(const std::string& message) {
    std::ofstream logFile("C:\\temp\\MyApp.log", std::ios::app);
    if (logFile.is_open()) {
        SYSTEMTIME st;
        GetSystemTime(&st);
        logFile << "[" << st.wYear << "-" << st.wMonth << "-" << st.wDay 
                << " " << st.wHour << ":" << st.wMinute << ":" << st.wSecond 
                << "] " << message << std::endl;
        logFile.close();
    }
}
