#Requires AutoHotkey v2.0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main.ahk - Core initialization and application entry point
; 
; This is the main entry point for the keyboard customization system.
; It initializes all components and starts the hotkey management system.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#InstallKeybdHook
#MaxHotkeysPerInterval 1000
SendMode("Input")
SetTitleMatchMode(2)
SetTitleMatchMode("slow")

; Include all module files
#Include "constants.ahk"
#Include "config.ahk"
#Include "utils.ahk"
#Include "colemak.ahk"
#Include "pok3r.ahk"
#Include "applications.ahk"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global instances
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

global appConfig := AppConfig()
global hotkeyManager := HotkeyManager()
global colemakLayout := ColemakLayout(appConfig, hotkeyManager)
global pok3rKeyboard := Pok3rKeyboard(appConfig, hotkeyManager)
global appSpecificKeys := AppSpecificKeys(appConfig, hotkeyManager)
global utils := Utils()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Main application class
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class KeyboardApp {
    /**
     * Initialize the keyboard customization application
     */
    static Init() {
        try {
            ; Load configuration from file
            appConfig.Load()
            
            ; Initialize all components
            colemakLayout.Initialize()
            pok3rKeyboard.Initialize()
            appSpecificKeys.Initialize()
            
            ; Register base hotkeys
            KeyboardApp.RegisterBaseHotkeys()
            
            ; Start async operations
            KeyboardApp.StartAsyncOperations()
            
            ; Show startup notification
            utils.ShowNotification("Keyboard customization loaded", CONSTANTS.NOTIFICATION_DURATION)
            
        } catch Error as e {
            utils.LogError("Failed to initialize application", e)
            MsgBox("Failed to initialize keyboard app: " . e.Message, "Error", "OK Icon!")
        }
    }
    
    /**
     * Register core application hotkeys that don't belong to specific modules
     */
    static RegisterBaseHotkeys() {
        ; Toggle Colemak layout
        hotkeyManager.Register("!/", () => colemakLayout.Toggle(), "Global")
        
        ; Toggle Colemak all-time mode
        hotkeyManager.Register("!?", () => colemakLayout.ToggleAllTime(), "Global")
        
        ; Toggle POK3R mode
        hotkeyManager.Register("!.", () => pok3rKeyboard.Toggle(), "Global")
        
        ; Enable/disable CapsLock
        hotkeyManager.Register(">+CapsLock", () => appConfig.Set("enableCapsLock", !appConfig.Get("enableCapsLock")), "Global")
        
        ; Multimedia controls
        hotkeyManager.Register("^Volume_Mute", () => Send("{Media_Play_Pause}"), "Global")
        hotkeyManager.Register("^Volume_Down", () => Send("{Media_Prev}"), "Global")
        hotkeyManager.Register("^Volume_Up", () => Send("{Media_Next}"), "Global")
        
        ; Window management
        hotkeyManager.Register("<#Space", () => Send("^``"), "Global")
        hotkeyManager.Register("!+w", () => KeyboardApp.ShowActiveWindowTitle(), "Global")
    }
    
    /**
     * Start background async operations
     */
    static StartAsyncOperations() {
        ; Auto-save configuration every 5 minutes
        SetTimer(() => KeyboardApp.AutoSave(), CONSTANTS.AUTO_SAVE_INTERVAL)
        
        ; Periodic status check
        SetTimer(() => KeyboardApp.StatusCheck(), CONSTANTS.STATUS_CHECK_INTERVAL)
    }
    
    /**
     * Auto-save configuration to file
     */
    static AutoSave() {
        try {
            appConfig.Save()
            utils.LogInfo("Configuration auto-saved")
        } catch Error as e {
            utils.LogError("Auto-save failed", e)
        }
    }
    
    /**
     * Perform periodic status checks
     */
    static StatusCheck() {
        ; Check if critical components are still functioning
        if (!hotkeyManager.IsHealthy()) {
            utils.LogWarning("Hotkey manager health check failed")
        }
    }
    
    /**
     * Show the title of the currently active window
     */
    static ShowActiveWindowTitle() {
        try {
            title := WinGetTitle("A")
            utils.ShowNotification('Active window: "' . title . '"', CONSTANTS.NOTIFICATION_DURATION)
        } catch Error as e {
            utils.LogError("Failed to get window title", e)
        }
    }
    
    /**
     * Graceful shutdown of the application
     */
    static Shutdown() {
        try {
            utils.LogInfo("Shutting down keyboard app")
            
            ; Save configuration
            appConfig.Save()
            
            ; Cleanup components
            hotkeyManager.Cleanup()
            colemakLayout.Cleanup()
            pok3rKeyboard.Cleanup()
            appSpecificKeys.Cleanup()
            
            utils.LogInfo("Shutdown complete")
        } catch Error as e {
            utils.LogError("Error during shutdown", e)
        }
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Hotkey Manager - Centralized hotkey registration and management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class HotkeyManager {
    registeredHotkeys := Map()
    contexts := Map()
    isEnabled := true
    
    /**
     * Register a hotkey with optional context condition
     * @param {String} key - The hotkey combination
     * @param {Func} action - Function to execute when hotkey is pressed
     * @param {String} context - Context name for conditional hotkeys
     * @param {Func} condition - Optional condition function
     */
    Register(key, action, context := "Global", condition := "") {
        try {
            hotkeyInfo := {
                key: key,
                action: action,
                context: context,
                condition: condition,
                enabled: true
            }
            
            this.registeredHotkeys[key . "_" . context] := hotkeyInfo
            
            if (context == "Global") {
                Hotkey(key, action)
            } else {
                this.RegisterContextualHotkey(hotkeyInfo)
            }
            
            utils.LogInfo("Registered hotkey: " . key . " in context: " . context)
        } catch Error as e {
            utils.LogError("Failed to register hotkey: " . key, e)
        }
    }
    
    /**
     * Register a conditional hotkey using #HotIf
     * @param {Object} hotkeyInfo - Hotkey information object
     */
    RegisterContextualHotkey(hotkeyInfo) {
        if (hotkeyInfo.condition) {
            #HotIf hotkeyInfo.condition
            Hotkey(hotkeyInfo.key, hotkeyInfo.action)
            #HotIf
        }
    }
    
    /**
     * Unregister a hotkey
     * @param {String} key - The hotkey combination
     * @param {String} context - Context name
     */
    Unregister(key, context := "Global") {
        try {
            hotkeyId := key . "_" . context
            if (this.registeredHotkeys.Has(hotkeyId)) {
                Hotkey(key, "Off")
                this.registeredHotkeys.Delete(hotkeyId)
                utils.LogInfo("Unregistered hotkey: " . key)
            }
        } catch Error as e {
            utils.LogError("Failed to unregister hotkey: " . key, e)
        }
    }
    
    /**
     * Enable or disable all hotkeys
     * @param {Boolean} enabled - Whether hotkeys should be enabled
     */
    SetEnabled(enabled) {
        this.isEnabled := enabled
        for hotkeyId, hotkeyInfo in this.registeredHotkeys {
            try {
                if (enabled && hotkeyInfo.enabled) {
                    Hotkey(hotkeyInfo.key, hotkeyInfo.action)
                } else {
                    Hotkey(hotkeyInfo.key, "Off")
                }
            } catch Error as e {
                utils.LogError("Failed to toggle hotkey: " . hotkeyInfo.key, e)
            }
        }
    }
    
    /**
     * Check if the hotkey manager is functioning properly
     * @return {Boolean} - True if healthy
     */
    IsHealthy() {
        return this.isEnabled && this.registeredHotkeys.Count > 0
    }
    
    /**
     * Clean up all registered hotkeys
     */
    Cleanup() {
        for hotkeyId, hotkeyInfo in this.registeredHotkeys {
            try {
                Hotkey(hotkeyInfo.key, "Off")
            } catch Error as e {
                utils.LogError("Failed to cleanup hotkey: " . hotkeyInfo.key, e)
            }
        }
        this.registeredHotkeys.Clear()
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Application startup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Initialize the application
KeyboardApp.Init()

; Handle application exit
OnExit((*) => KeyboardApp.Shutdown())

; Handle suspend/resume
Suspend::KeyboardApp.SetEnabled(false)
+Suspend::KeyboardApp.SetEnabled(true)