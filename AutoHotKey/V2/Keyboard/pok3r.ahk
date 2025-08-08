;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; pok3r.ahk - POK3R keyboard functionality
;
; This module handles POK3R keyboard emulation, providing Fn layer functionality
; through Space key combinations and context-aware behavior.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class Pok3rKeyboard {
    config := ""
    hotkeyManager := ""
    isInitialized := false
    spacePressed := false
    spaceTimeout := CONSTANTS.POK3R_TIMEOUT
    
    /**
     * Initialize the POK3R keyboard manager
     * @param {AppConfig} config - Application configuration
     * @param {HotkeyManager} hotkeyManager - Hotkey management system
     */
    __New(config, hotkeyManager) {
        this.config := config
        this.hotkeyManager := hotkeyManager
    }
    
    /**
     * Initialize the POK3R keyboard system
     */
    Initialize() {
        try {
            this.RegisterPok3rHotkeys()
            this.isInitialized := true
            utils.LogInfo("POK3R keyboard system initialized")
        } catch Error as e {
            utils.LogError("Failed to initialize POK3R keyboard", e)
        }
    }
    
    /**
     * Register all POK3R-related hotkeys
     */
    RegisterPok3rHotkeys() {
        ; Register single set of POK3R hotkeys that work for both modes
        this.RegisterSpaceModifiers()
        this.RegisterMainSpaceHandler()
        this.RegisterSpaceCombinations()
    }
    
    /**
     * Register space modifier combinations
     */
    RegisterSpaceModifiers() {
        modifiers := ["!", "!#", "!^", "!+", "+", "^", "^+"]
        
        for modifier in modifiers {
            this.hotkeyManager.Register(
                modifier . "Space",
                this.CreateModifierSpaceHandler(modifier),
                "Pok3rModifiers",
                () => this.IsAnyPok3rModeActive()
            )
        }
    }
    
    /**
     * Register main space handler
     */
    RegisterMainSpaceHandler() {
        this.hotkeyManager.Register(
            "$Space",
            () => this.HandleSpacePress(),
            "Pok3rMain",
            () => this.IsAnyPok3rModeActive()
        )
    }
    
    /**
     * Register space key combinations
     */
    RegisterSpaceCombinations() {
        ; Unused keys (return without action)
        for unusedKey in CONSTANTS.POK3R_UNUSED_KEYS {
            this.hotkeyManager.Register(
                "Space & " . unusedKey,
                () => "",  ; Empty function - no action
                "Pok3rUnused",
                () => this.IsAnyPok3rModeActive()
            )
        }
        
        ; Cursor movement keys
        for qwertyKey, direction in CONSTANTS.POK3R_CURSOR_KEYS {
            this.RegisterCursorKey(qwertyKey, direction)
        }
        
        ; Cursor jump keys
        for qwertyKey, jumpKey in CONSTANTS.POK3R_JUMP_KEYS {
            this.RegisterJumpKey(qwertyKey, jumpKey)
        }
        
        ; Function keys (1-0, -, =)
        this.RegisterFunctionKeys()
        
        ; TKL (Ten Key Less) keys
        for qwertyKey, tklKey in CONSTANTS.POK3R_TKL_KEYS {
            this.RegisterTKLKey(qwertyKey, tklKey)
        }
        
        ; Special combinations
        this.RegisterSpecialCombinations()
    }
    
    /**
     * Create a modifier space handler
     * @param {String} modifier - Modifier string
     * @return {Func} - Handler function
     */
    CreateModifierSpaceHandler(modifier) {
        return () => Send(modifier . "{Space}")
    }
    
    /**
     * Register a cursor movement key
     * @param {String} key - Trigger key
     * @param {String} direction - Cursor direction
     */
    RegisterCursorKey(key, direction) {
        ; Key down
        this.hotkeyManager.Register(
            "Space & " . key,
            () => Send("{Blind}{" . direction . " DownTemp}"),
            "Pok3rCursor",
            () => this.IsAnyPok3rModeActive()
        )
        
        ; Key up
        this.hotkeyManager.Register(
            "Space & " . key . " up",
            () => Send("{Blind}{" . direction . " Up}"),
            "Pok3rCursorUp",
            () => this.IsAnyPok3rModeActive()
        )
    }
    
    /**
     * Register a cursor jump key
     * @param {String} key - Trigger key
     * @param {String} jumpKey - Jump key (Home, End, etc.)
     */
    RegisterJumpKey(key, jumpKey) {
        ; Key down
        this.hotkeyManager.Register(
            "Space & " . key,
            () => SendInput("{Blind}{" . jumpKey . " Down}"),
            "Pok3rJump",
            () => this.IsAnyPok3rModeActive()
        )
        
        ; Key up
        this.hotkeyManager.Register(
            "Space & " . key . " up",
            () => SendInput("{Blind}{" . jumpKey . " Up}"),
            "Pok3rJumpUp",
            () => this.IsAnyPok3rModeActive()
        )
    }
    
    /**
     * Register function keys (F1-F12)
     */
    RegisterFunctionKeys() {
        ; Number keys 1-0 map to F1-F10
        numberKeys := ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        
        for index, numberKey in numberKeys {
            fKey := "F" . index
            this.hotkeyManager.Register(
                "Space & " . numberKey,
                () => SendInput("{Blind}{" . fKey . "}"),
                "Pok3rFunction",
                () => this.IsAnyPok3rModeActive()
            )
        }
        
        ; - maps to F11, = maps to F12
        this.hotkeyManager.Register(
            "Space & -",
            () => SendInput("{Blind}{F11}"),
            "Pok3rFunction",
            () => this.IsAnyPok3rModeActive()
        )
        
        this.hotkeyManager.Register(
            "Space & =",
            () => SendInput("{Blind}{F12}"),
            "Pok3rFunction",
            () => this.IsAnyPok3rModeActive()
        )
    }
    
    /**
     * Register TKL (Ten Key Less) keys
     * @param {String} key - Trigger key
     * @param {String} tklKey - TKL key
     */
    RegisterTKLKey(key, tklKey) {
        if (tklKey == "Del" || tklKey == "Ins") {
            ; Keys that support down/up
            this.hotkeyManager.Register(
                "Space & " . key,
                () => SendInput("{" . tklKey . " Down}"),
                "Pok3rTKL",
                () => this.IsAnyPok3rModeActive()
            )
            
            this.hotkeyManager.Register(
                "Space & " . key . " up",
                () => SendInput("{" . tklKey . " Up}"),
                "Pok3rTKLUp",
                () => this.IsAnyPok3rModeActive()
            )
        } else {
            ; Single press keys
            this.hotkeyManager.Register(
                "Space & " . key,
                () => SendInput("{" . tklKey . "}"),
                "Pok3rTKL",
                () => this.IsAnyPok3rModeActive()
            )
        }
    }
    
    /**
     * Register special key combinations
     */
    RegisterSpecialCombinations() {
        ; Ctrl+Enter
        this.hotkeyManager.Register(
            "Space & Enter",
            () => SendInput("{Ctrl down}{Enter}{Ctrl up}"),
            "Pok3rSpecial",
            () => this.IsAnyPok3rModeActive()
        )
        
        ; Calculator
        this.hotkeyManager.Register(
            "Space & y",
            () => utils.RunAsync("calc.exe"),
            "Pok3rSpecial",
            () => this.IsAnyPok3rModeActive()
        )
        
        ; Apps key
        this.hotkeyManager.Register(
            "Space & z",
            () => this.HandleAppsKey(),
            "Pok3rSpecial",
            () => this.IsAnyPok3rModeActive()
        )
    }
    
    /**
     * Handle Space key press with timeout logic
     */
    HandleSpacePress() {
        try {
            ; Wait for timeout to see if this is a space combination
            if (KeyWait("Space", "T" . (this.spaceTimeout / 1000))) {
                ; Timeout occurred - send space with modifiers
                utils.SendModifierStates(" ")
            }
            ; If no timeout, space combinations will handle the keypress
        } catch Error as e {
            utils.LogError("Failed to handle Space press", e)
        }
    }
    
    /**
     * Handle Apps key with shift modifier support
     */
    HandleAppsKey() {
        try {
            if (GetKeyState("Shift", "p")) {
                SendInput("{Shift Down}{AppsKey}{Shift Up}")
            } else {
                SendInput("{AppsKey}")
            }
        } catch Error as e {
            utils.LogError("Failed to handle Apps key", e)
        }
    }
    
    /**
     * Determine if POK3R Colemak mode should be active
     * @return {Boolean} - True if POK3R Colemak should be active
     */
    ShouldUsePok3rColemak() {
        return this.config.Get("pok3rColemak") && !this.config.Get("pok3r")
    }
    
    /**
     * Determine if POK3R QWERTY mode should be active
     * @return {Boolean} - True if POK3R QWERTY should be active
     */
    ShouldUsePok3rQwerty() {
        return this.config.Get("pok3r") && !this.config.Get("pok3rColemak")
    }
    
    /**
     * Toggle POK3R mode based on current Colemak state
     * @return {Boolean} - New POK3R state
     */
    Toggle() {
        try {
            colemakMode := this.config.Get("colemak") || this.config.Get("colemakAllTime")
            
            if (colemakMode) {
                ; Toggle POK3R Colemak mode
                newState := this.config.Toggle("pok3rColemak")
                if (newState) {
                    this.config.Set("pok3r", false)
                }
                statusMsg := "POK3R Colemak mode " . (newState ? "enabled" : "disabled")
            } else {
                ; Toggle POK3R QWERTY mode
                newState := this.config.Toggle("pok3r")
                if (newState) {
                    this.config.Set("pok3rColemak", false)
                }
                statusMsg := "POK3R QWERTY mode " . (newState ? "enabled" : "disabled")
            }
            
            utils.ShowNotification(statusMsg, CONSTANTS.NOTIFICATION_DURATION)
            utils.LogInfo(statusMsg)
            return newState
        } catch Error as e {
            utils.LogError("Failed to toggle POK3R mode", e)
            return false
        }
    }
    
    /**
     * Enable POK3R mode
     * @param {Boolean} colemakMode - True for Colemak mode, false for QWERTY
     */
    Enable(colemakMode := false) {
        try {
            if (colemakMode) {
                this.config.Set("pok3rColemak", true)
                this.config.Set("pok3r", false)
                utils.ShowNotification("POK3R Colemak mode enabled", CONSTANTS.NOTIFICATION_DURATION)
            } else {
                this.config.Set("pok3r", true)
                this.config.Set("pok3rColemak", false)
                utils.ShowNotification("POK3R QWERTY mode enabled", CONSTANTS.NOTIFICATION_DURATION)
            }
            utils.LogInfo("POK3R mode enabled: " . (colemakMode ? "Colemak" : "QWERTY"))
        } catch Error as e {
            utils.LogError("Failed to enable POK3R mode", e)
        }
    }
    
    /**
     * Disable POK3R mode
     */
    Disable() {
        try {
            this.config.Set("pok3r", false)
            this.config.Set("pok3rColemak", false)
            utils.ShowNotification("POK3R mode disabled", CONSTANTS.NOTIFICATION_DURATION)
            utils.LogInfo("POK3R mode disabled")
        } catch Error as e {
            utils.LogError("Failed to disable POK3R mode", e)
        }
    }
    
    /**
     * Get current POK3R status
     * @return {Object} - Status information
     */
    GetStatus() {
        try {
            return {
                pok3r: this.config.Get("pok3r"),
                pok3rColemak: this.config.Get("pok3rColemak"),
                isActive: this.config.Get("pok3r") || this.config.Get("pok3rColemak"),
                currentMode: this.GetCurrentModeName(),
                spaceTimeout: this.spaceTimeout
            }
        } catch Error as e {
            utils.LogError("Failed to get POK3R status", e)
            return {}
        }
    }
    
    /**
     * Get the name of the current POK3R mode
     * @return {String} - Mode name
     */
    GetCurrentModeName() {
        if (this.config.Get("pok3rColemak")) {
            return "POK3R Colemak"
        }
        if (this.config.Get("pok3r")) {
            return "POK3R QWERTY"
        }
        return "Disabled"
    }
    
    /**
     * Set the space key timeout
     * @param {Integer} timeout - Timeout in milliseconds
     */
    SetSpaceTimeout(timeout) {
        try {
            if (timeout > 0 && timeout <= 2000) {
                this.spaceTimeout := timeout
                utils.LogInfo("POK3R space timeout set to: " . timeout . "ms")
            } else {
                utils.LogError("Invalid space timeout value: " . timeout)
            }
        } catch Error as e {
            utils.LogError("Failed to set space timeout", e)
        }
    }
    
    /**
     * Test POK3R functionality
     */
    TestFunctionality() {
        try {
            utils.ShowNotification("Testing POK3R functionality...", CONSTANTS.NOTIFICATION_DURATION)
            
            ; Test sequence: Space+h (left), Space+j (down), Space+k (up), Space+l (right)
            testSequence := [
                () => Send("{Left}"),
                () => Send("{Down}"),
                () => Send("{Up}"),
                () => Send("{Right}")
            ]
            
            ; Execute test sequence with delays
            for index, testFunc in testSequence {
                SetTimer(testFunc, -index * 500)
            }
            
            utils.LogInfo("POK3R functionality test initiated")
        } catch Error as e {
            utils.LogError("Failed to test POK3R functionality", e)
        }
    }
    
    /**
     * Get POK3R help information
     * @return {String} - Help text
     */
    GetHelp() {
        helpText := "POK3R Keyboard Help:`n`n"
        helpText .= "Cursor Movement:`n"
        helpText .= "  Space+H/J/K/L = Left/Down/Up/Right`n`n"
        helpText .= "Cursor Jumps:`n"
        helpText .= "  Space+I/N = Home/End`n"
        helpText .= "  Space+U/O = Page Up/Page Down`n`n"
        helpText .= "Function Keys:`n"
        helpText .= "  Space+1-0 = F1-F10`n"
        helpText .= "  Space+-/= = F11/F12`n`n"
        helpText .= "Special Keys:`n"
        helpText .= "  Space+; = Delete`n"
        helpText .= "  Space+' = Insert`n"
        helpText .= "  Space+P = Print Screen`n"
        helpText .= "  Space+] = Pause`n`n"
        helpText .= "Other:`n"
        helpText .= "  Space+Enter = Ctrl+Enter`n"
        helpText .= "  Space+Y = Calculator`n"
        helpText .= "  Space+Z = Apps Key"
        
        return helpText
    }
    
    /**
     * Clean up POK3R resources
     */
    Cleanup() {
        try {
            ; Cleanup would be handled by the hotkey manager
            this.isInitialized := false
            utils.LogInfo("POK3R keyboard cleanup completed")
        } catch Error as e {
            utils.LogError("Error during POK3R cleanup", e)
        }
    }
}