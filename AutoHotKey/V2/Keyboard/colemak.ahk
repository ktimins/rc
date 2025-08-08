;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; colemak.ahk - Colemak keyboard layout management
;
; This module handles the Colemak keyboard layout functionality, including
; layout switching, key remapping, and application-specific behavior.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class ColemakLayout {
    config := ""
    hotkeyManager := ""
    layoutMap := ""
    isInitialized := false
    
    /**
     * Initialize the Colemak layout manager
     * @param {AppConfig} config - Application configuration
     * @param {HotkeyManager} hotkeyManager - Hotkey management system
     */
    __New(config, hotkeyManager) {
        this.config := config
        this.hotkeyManager := hotkeyManager
        this.layoutMap := CONSTANTS.COLEMAK_LAYOUT
    }
    
    /**
     * Initialize the Colemak layout system
     */
    Initialize() {
        try {
            this.RegisterColemakHotkeys()
            this.RegisterSpecialHotkeys()
            this.isInitialized := true
            utils.LogInfo("Colemak layout system initialized")
        } catch Error as e {
            utils.LogError("Failed to initialize Colemak layout", e)
        }
    }
    
    /**
     * Register all Colemak-related hotkeys
     */
    RegisterColemakHotkeys() {
        ; Register hotkeys for each key that needs remapping
        for qwertyKey, colemakKey in this.layoutMap {
            ; Standard Colemak remapping (excluding IDE/Vim contexts)
            this.hotkeyManager.Register(
                "*" . qwertyKey,
                this.CreateColemakKeyHandler(qwertyKey, colemakKey),
                "ColemakStandard",
                () => this.ShouldUseColemakStandard()
            )
            
            ; IDE/Vim context - use QWERTY for better shortcuts
            this.hotkeyManager.Register(
                "*" . qwertyKey,
                this.CreateQwertyKeyHandler(qwertyKey),
                "ColemakIDE",
                () => this.ShouldUseColemakIDE()
            )
        }
    }
    
    /**
     * Register special Colemak-related hotkeys
     */
    RegisterSpecialHotkeys() {
        ; Alt+F4 equivalent for Colemak mode
        this.hotkeyManager.Register(
            "<!<+f",
            () => Send("{Blind}{Alt down}{F4}{Alt up}"),
            "ColemakAltF4",
            () => this.config.Get("colemak") || this.config.Get("colemakAllTime")
        )
        
        ; Alt+F4 equivalent for QWERTY mode
        this.hotkeyManager.Register(
            "<!<+t", 
            () => Send("{Blind}{Alt down}{F4}{Alt up}"),
            "QwertyAltF4",
            () => !(this.config.Get("colemak") || this.config.Get("colemakAllTime"))
        )
        
        ; Print screen toggle hotkeys
        this.RegisterPrintScreenHotkeys()
    }
    
    /**
     * Register print screen toggle hotkeys
     */
    RegisterPrintScreenHotkeys() {
        ; Colemak mode print screen toggle (Win+Alt+R)
        this.hotkeyManager.Register(
            "#!r",
            () => this.config.Toggle("printScreen"),
            "ColemakPrintScreen",
            () => this.config.Get("colemak") || this.config.Get("colemakAllTime")
        )
        
        ; QWERTY mode print screen toggle (Win+Alt+P)
        this.hotkeyManager.Register(
            "#!p",
            () => this.config.Toggle("printScreen"),
            "QwertyPrintScreen", 
            () => !(this.config.Get("colemak") || this.config.Get("colemakAllTime"))
        )
        
        ; Reset print screen
        this.hotkeyManager.Register(
            "#!+r",
            () => this.config.Set("printScreen", false),
            "ColemakPrintScreenReset",
            () => this.config.Get("colemak") || this.config.Get("colemakAllTime")
        )
        
        this.hotkeyManager.Register(
            "#!+p",
            () => this.config.Set("printScreen", false),
            "QwertyPrintScreenReset",
            () => !(this.config.Get("colemak") || this.config.Get("colemakAllTime"))
        )
        
        ; Print screen activation
        this.hotkeyManager.Register(
            "<+Space",
            () => Send("{PrintScreen}"),
            "PrintScreenActivate",
            () => this.config.Get("printScreen")
        )
    }
    
    /**
     * Create a key handler for Colemak remapping
     * @param {String} qwertyKey - Original QWERTY key
     * @param {String} colemakKey - Colemak equivalent key
     * @return {Func} - Handler function
     */
    CreateColemakKeyHandler(qwertyKey, colemakKey) {
        return () => utils.SendModifierStates(colemakKey)
    }
    
    /**
     * Create a key handler for QWERTY (no remapping)
     * @param {String} qwertyKey - QWERTY key
     * @return {Func} - Handler function
     */
    CreateQwertyKeyHandler(qwertyKey) {
        return () => utils.SendModifierStates(qwertyKey)
    }
    
    /**
     * Determine if standard Colemak remapping should be used
     * @return {Boolean} - True if standard Colemak should be active
     */
    ShouldUseColemakStandard() {
        ; Always use Colemak if colemakAllTime is enabled
        if (this.config.Get("colemakAllTime")) {
            return true
        }
        
        ; Use Colemak if enabled and not in IDE/Vim context
        if (this.config.Get("colemak")) {
            return !this.IsInIDEContext() || this.IsInChromeContext()
        }
        
        return false
    }
    
    /**
     * Determine if IDE-specific behavior should be used
     * @return {Boolean} - True if in IDE context with Colemak enabled
     */
    ShouldUseColemakIDE() {
        return this.config.Get("colemak") && 
               this.IsInIDEContext() && 
               !this.config.Get("colemakAllTime") &&
               !this.IsInChromeContext()
    }
    
    /**
     * Check if currently in an IDE or Vim context
     * @return {Boolean} - True if in IDE/Vim
     */
    IsInIDEContext() {
        try {
            ; Check Visual Studio
            if (utils.IsWindowActive(CONSTANTS.VISUAL_STUDIO)) {
                return true
            }
            
            ; Check Vim classes
            for vimClass in CONSTANTS.VIM_CLASSES {
                if (utils.IsWindowActive(vimClass)) {
                    return true
                }
            }
            
            return false
        } catch Error as e {
            utils.LogError("Failed to check IDE context", e)
            return false
        }
    }
    
    /**
     * Check if currently in Chrome context
     * @return {Boolean} - True if in Chrome
     */
    IsInChromeContext() {
        try {
            return utils.IsWindowActive(CONSTANTS.CHROME_CLASS)
        } catch Error as e {
            utils.LogError("Failed to check Chrome context", e)
            return false
        }
    }
    
    /**
     * Toggle Colemak layout on/off
     * @return {Boolean} - New state after toggle
     */
    Toggle() {
        try {
            newState := this.config.Toggle("colemak")
            statusMsg := "Colemak layout " . (newState ? "enabled" : "disabled")
            utils.ShowNotification(statusMsg, CONSTANTS.NOTIFICATION_DURATION)
            utils.LogInfo(statusMsg)
            return newState
        } catch Error as e {
            utils.LogError("Failed to toggle Colemak layout", e)
            return false
        }
    }
    
    /**
     * Toggle Colemak all-time mode
     * @return {Boolean} - New state after toggle
     */
    ToggleAllTime() {
        try {
            newState := this.config.Toggle("colemakAllTime")
            statusMsg := "Colemak all-time mode " . (newState ? "enabled" : "disabled")
            utils.ShowNotification(statusMsg, CONSTANTS.NOTIFICATION_DURATION)
            utils.LogInfo(statusMsg)
            return newState
        } catch Error as e {
            utils.LogError("Failed to toggle Colemak all-time mode", e)
            return false
        }
    }
    
    /**
     * Get current Colemak status
     * @return {Object} - Status information
     */
    GetStatus() {
        try {
            return {
                colemak: this.config.Get("colemak"),
                colemakAllTime: this.config.Get("colemakAllTime"),
                printScreen: this.config.Get("printScreen"),
                inIDEContext: this.IsInIDEContext(),
                inChromeContext: this.IsInChromeContext(),
                activeLayout: this.GetActiveLayoutName()
            }
        } catch Error as e {
            utils.LogError("Failed to get Colemak status", e)
            return {}
        }
    }
    
    /**
     * Get the name of the currently active layout
     * @return {String} - Layout name
     */
    GetActiveLayoutName() {
        if (this.config.Get("colemakAllTime")) {
            return "Colemak (All-Time)"
        }
        
        if (this.config.Get("colemak")) {
            if (this.IsInIDEContext() && !this.IsInChromeContext()) {
                return "QWERTY (IDE Context)"
            }
            return "Colemak"
        }
        
        return "QWERTY"
    }
    
    /**
     * Enable Colemak layout
     */
    Enable() {
        try {
            this.config.Set("colemak", true)
            utils.ShowNotification("Colemak layout enabled", CONSTANTS.NOTIFICATION_DURATION)
            utils.LogInfo("Colemak layout enabled")
        } catch Error as e {
            utils.LogError("Failed to enable Colemak layout", e)
        }
    }
    
    /**
     * Disable Colemak layout
     */
    Disable() {
        try {
            this.config.Set("colemak", false)
            this.config.Set("colemakAllTime", false)
            utils.ShowNotification("Colemak layout disabled", CONSTANTS.NOTIFICATION_DURATION)
            utils.LogInfo("Colemak layout disabled")
        } catch Error as e {
            utils.LogError("Failed to disable Colemak layout", e)
        }
    }
    
    /**
     * Test Colemak functionality by typing a test string
     */
    TestLayout() {
        try {
            testString := "The quick brown fox jumps over the lazy dog"
            utils.ShowNotification("Testing layout with: " . testString, CONSTANTS.NOTIFICATION_DURATION * 2)
            
            ; Small delay then type the test string
            SetTimer(() => SendText(testString), -1000)
            
            utils.LogInfo("Layout test initiated")
        } catch Error as e {
            utils.LogError("Failed to test layout", e)
        }
    }
    
    /**
     * Clean up Colemak resources
     */
    Cleanup() {
        try {
            ; Unregister hotkeys would be handled by the hotkey manager
            this.isInitialized := false
            utils.LogInfo("Colemak layout cleanup completed")
        } catch Error as e {
            utils.LogError("Error during Colemak cleanup", e)
        }
    }
}