#include <windows.h>
#include <fstream>
#include <string>

// Plugin interface definition (must match the service)
typedef struct {
    const char* name;
    const char* version;
    const char* description;
} PluginInfo;

// Plugin information
static PluginInfo g_PluginInfo = {
    "Sample Plugin",
    "1.0.0",
    "A sample plugin that demonstrates the plugin interface"
};

// Plugin state
static int g_ExecutionCount = 0;
static bool g_IsInitialized = false;

// Helper function to write to plugin log
void WritePluginLog(const std::string& message) {
    std::ofstream logFile("C:\\temp\\SamplePlugin.log", std::ios::app);
    if (logFile.is_open()) {
        SYSTEMTIME st;
        GetSystemTime(&st);
        logFile << "[" << st.wYear << "-" << st.wMonth << "-" << st.wDay 
                << " " << st.wHour << ":" << st.wMinute << ":" << st.wSecond 
                << "] " << message << std::endl;
        logFile.close();
    }
}

// Required plugin functions - these must be exported
extern "C" {
    
    // Get plugin information
    __declspec(dllexport) PluginInfo* GetPluginInfo() {
        return &g_PluginInfo;
    }
    
    // Initialize the plugin
    __declspec(dllexport) BOOL InitializePlugin() {
        WritePluginLog("Sample Plugin: Initializing...");
        
        // Perform any initialization here
        g_ExecutionCount = 0;
        g_IsInitialized = true;
        
        WritePluginLog("Sample Plugin: Initialization complete");
        return TRUE;
    }
    
    // Execute plugin functionality (called every 5 seconds by service)
    __declspec(dllexport) void ExecutePlugin() {
        if (!g_IsInitialized) {
            return;
        }
        
        g_ExecutionCount++;
        
        // Your plugin logic goes here
        WritePluginLog("Sample Plugin: Execution #" + std::to_string(g_ExecutionCount));
        
        // Example: Do some work every 10 executions (50 seconds)
        if (g_ExecutionCount % 10 == 0) {
            WritePluginLog("Sample Plugin: Performing periodic task...");
            // Add your periodic functionality here
        }
    }
    
    // Cleanup plugin resources
    __declspec(dllexport) void CleanupPlugin() {
        WritePluginLog("Sample Plugin: Cleaning up...");
        
        // Perform cleanup here
        g_IsInitialized = false;
        g_ExecutionCount = 0;
        
        WritePluginLog("Sample Plugin: Cleanup complete");
    }
    
    // DLL entry point
    BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved) {
        switch (fdwReason) {
        case DLL_PROCESS_ATTACH:
            WritePluginLog("Sample Plugin: DLL attached to process");
            break;
        case DLL_PROCESS_DETACH:
            WritePluginLog("Sample Plugin: DLL detached from process");
            break;
        }
        return TRUE;
    }
}

// Additional plugin functionality can be added here
class SamplePluginClass {
private:
    std::string m_data;
    
public:
    SamplePluginClass() : m_data("Sample plugin data") {}
    
    void DoSomething() {
        WritePluginLog("Sample Plugin Class: Doing something with: " + m_data);
    }
    
    void SetData(const std::string& data) {
        m_data = data;
        WritePluginLog("Sample Plugin Class: Data set to: " + m_data);
    }
};

// Global plugin instance
static SamplePluginClass g_PluginInstance;
