;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; utils.ahk - Utility functions and helper methods
;
; This module contains common utility functions used throughout the application.
; Functions include logging, notifications, registry operations, and more.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class Utils {
    logFile := CONSTANTS.LOG_FILE
    
    /**
     * Show a temporary notification to the user
     * @param {String} message - Message to display
     * @param {Integer} duration - Duration in milliseconds
     */
    ShowNotification(message, duration := 2000) {
        try {
            ; Use ToolTip for simple notifications
            ToolTip(message)
            SetTimer(() => ToolTip(), -duration)
        } catch Error as e {
            this.LogError("Failed to show notification", e)
        }
    }
    
    /**
     * Log an informational message
     * @param {String} message - Message to log
     */
    LogInfo(message) {
        this.WriteLog(CONSTANTS.LOG_INFO, message)
    }
    
    /**
     * Log a warning message
     * @param {String} message - Message to log
     */
    LogWarning(message) {
        this.WriteLog(CONSTANTS.LOG_WARNING, message)
    }
    
    /**
     * Log an error message
     * @param {String} message - Message to log
     * @param {Error} error - Optional error object
     */
    LogError(message, error := "") {
        fullMessage := message
        if (error) {
            fullMessage .= " - Error: " . error.Message
            if (error.Stack) {
                fullMessage .= " - Stack: " . error.Stack
            }
        }
        this.WriteLog(CONSTANTS.LOG_ERROR, fullMessage)
    }
    
    /**
     * Write a log entry to the log file
     * @param {String} level - Log level (INFO, WARNING, ERROR)
     * @param {String} message - Message to log
     */
    WriteLog(level, message) {
        try {
            timestamp := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")
            logEntry := timestamp . " [" . level . "] " . message . "`n"
            
            ; Ensure log file doesn't get too large
            this.RotateLogIfNeeded()
            
            FileAppend(logEntry, this.logFile, "UTF-8")
        } catch Error as e {
            ; If logging fails, try to show error via MsgBox as last resort
            try {
                MsgBox("Logging failed: " . e.Message, "Logging Error", "OK Icon!")
            }
        }
    }
    
    /**
     * Rotate log file if it gets too large
     */
    RotateLogIfNeeded() {
        try {
            if (!FileExist(this.logFile)) {
                return
            }
            
            ; Get file size
            file := FileOpen(this.logFile, "r")
            fileSize := file.Length
            file.Close()
            
            ; Rotate if larger than 5MB
            if (fileSize > 5242880) {
                backupFile := StrReplace(this.logFile, ".txt", "_backup.txt")
                FileMove(this.logFile, backupFile, true)
                this.LogInfo("Log file rotated")
            }
        } catch Error as e {
            ; Ignore rotation errors
        }
    }
    
    /**
     * Get modifier key states as a string
     * @param {String} alphaForm - Reference parameter for alphabetic form
     * @return {String} - Modifier string for Send commands
     */
    GetModifierStates(&alphaForm := "") {
        try {
            alphaForm := ""
            returnValue := ""
            
            if (GetKeyState("LWin", "P") || GetKeyState("RWin", "P")) {
                returnValue .= "#"
                alphaForm .= "W"
            }
            
            if (GetKeyState("Ctrl", "P")) {
                returnValue .= "^"
                alphaForm .= "C"
            }
            
            if (GetKeyState("Alt", "P")) {
                returnValue .= "!"
                alphaForm .= "A"
            }
            
            if (GetKeyState("Shift", "P")) {
                returnValue .= "+"
                alphaForm .= "S"
            }
            
            return returnValue
        } catch Error as e {
            this.LogError("Failed to get modifier states", e)
            return ""
        }
    }
    
    /**
     * Send a key with proper modifier states
     * @param {String} key - Key to send
     */
    SendModifierStates(key) {
        try {
            modifierStates := this.GetModifierStates()
            
            ; Handle CapsLock state
            if (GetKeyState("CapsLock", "T") == 1 && !RegExMatch(key, CONSTANTS.CAPSLOCK_IGNORE_CHARS)) {
                if (GetKeyState("Shift", "P") == 1) {
                    modifierStates := RegExReplace(modifierStates, "[+]", "")
                } else {
                    modifierStates .= "+"
                }
            }
            
            ; Send the key
            if (key == " ") {
                Send(modifierStates . "{Space}")
            } else {
                Send(modifierStates . "{" . key . "}")
            }
            
            Sleep(CONSTANTS.KEY_DELAY)
        } catch Error as e {
            this.LogError("Failed to send key: " . key, e)
        }
    }
    
    /**
     * Safely write to Windows registry
     * @param {Any} value - Value to write
     * @param {String} valueType - Registry value type
     * @param {String} rootKey - Root registry key
     * @param {String} subKey - Registry subkey path
     * @param {String} valueName - Value name
     * @return {Boolean} - True if successful
     */
    SafeRegWrite(value, valueType, rootKey, subKey, valueName) {
        try {
            RegWrite(value, valueType, rootKey, subKey, valueName)
            this.LogInfo("Registry write successful: " . rootKey . "\" . subKey . "\" . valueName)
            return true
        } catch Error as e {
            this.LogError("Registry write failed: " . rootKey . "\" . subKey . "\" . valueName, e)
            return false
        }
    }
    
    /**
     * Safely read from Windows registry
     * @param {String} rootKey - Root registry key
     * @param {String} subKey - Registry subkey path
     * @param {String} valueName - Value name
     * @param {Any} defaultValue - Default value if read fails
     * @return {Any} - Registry value or default
     */
    SafeRegRead(rootKey, subKey, valueName, defaultValue := "") {
        try {
            value := RegRead(rootKey, subKey, valueName)
            this.LogInfo("Registry read successful: " . rootKey . "\" . subKey . "\" . valueName)
            return value
        } catch Error as e {
            this.LogError("Registry read failed: " . rootKey . "\" . subKey . "\" . valueName, e)
            return defaultValue
        }
    }
    
    /**
     * Lock the Windows workstation
     * @return {Boolean} - True if successful
     */
    LockWorkstation() {
        try {
            ; Temporarily enable workstation locking
            this.SafeRegWrite(CONSTANTS.LOCK_DISABLED, "REG_DWORD", 
                CONSTANTS.REGISTRY_BASE, CONSTANTS.LOCK_WORKSTATION_PATH, CONSTANTS.LOCK_WORKSTATION_KEY)
            
            ; Lock the workstation
            success := DllCall("LockWorkStation")
            
            if (success) {
                ; Wait a moment then disable locking again
                Sleep(1000)
                this.SafeRegWrite(CONSTANTS.LOCK_ENABLED, "REG_DWORD", 
                    CONSTANTS.REGISTRY_BASE, CONSTANTS.LOCK_WORKSTATION_PATH, CONSTANTS.LOCK_WORKSTATION_KEY)
                
                this.LogInfo("Workstation locked successfully")
                return true
            } else {
                this.LogError("Failed to lock workstation via DLL call")
                return false
            }
        } catch Error as e {
            this.LogError("Failed to lock workstation", e)
            return false
        }
    }
    
    /**
     * Enable or disable workstation locking
     * @param {Boolean} enabled - Whether locking should be enabled
     * @return {Boolean} - True if successful
     */
    SetWorkstationLockEnabled(enabled) {
        try {
            value := enabled ? CONSTANTS.LOCK_DISABLED : CONSTANTS.LOCK_ENABLED
            return this.SafeRegWrite(value, "REG_DWORD", 
                CONSTANTS.REGISTRY_BASE, CONSTANTS.LOCK_WORKSTATION_PATH, CONSTANTS.LOCK_WORKSTATION_KEY)
        } catch Error as e {
            this.LogError("Failed to set workstation lock state", e)
            return false
        }
    }
    
    /**
     * Check if a window with the given criteria is active
     * @param {String} windowCriteria - Window criteria (title, class, exe, etc.)
     * @return {Boolean} - True if window is active
     */
    IsWindowActive(windowCriteria) {
        try {
            return WinActive(windowCriteria) != 0
        } catch Error as e {
            this.LogError("Failed to check window active state: " . windowCriteria, e)
            return false
        }
    }
    
    /**
     * Get the active window title safely
     * @return {String} - Window title or empty string if failed
     */
    GetActiveWindowTitle() {
        try {
            return WinGetTitle("A")
        } catch Error as e {
            this.LogError("Failed to get active window title", e)
            return ""
        }
    }
    
    /**
     * Run an application asynchronously
     * @param {String} command - Command to run
     * @param {String} workingDir - Working directory (optional)
     * @return {Boolean} - True if successful
     */
    RunAsync(command, workingDir := "") {
        try {
            if (workingDir) {
                Run(command, workingDir)
            } else {
                Run(command)
            }
            this.LogInfo("Started application: " . command)
            return true
        } catch Error as e {
            this.LogError("Failed to run application: " . command, e)
            return false
        }
    }
    
    /**
     * Format a boolean value as a readable string
     * @param {Boolean} value - Boolean value
     * @return {String} - "Yes" or "No"
     */
    FormatBoolean(value) {
        return value ? "Yes" : "No"
    }
    
    /**
     * Get application version information
     * @return {String} - Version string
     */
    GetVersion() {
        return "Keyboard Customization v2.0"
    }
    
    /**
     * Validate that required files exist
     * @return {Boolean} - True if all required files exist
     */
    ValidateInstallation() {
        try {
            requiredFiles := ["constants.ahk", "config.ahk", "utils.ahk", "colemak.ahk", "pok3r.ahk", "applications.ahk"]
            
            for file in requiredFiles {
                fullPath := A_ScriptDir . "\" . file
                if (!FileExist(fullPath)) {
                    this.LogError("Missing required file: " . fullPath)
                    return false
                }
            }
            
            this.LogInfo("Installation validation successful")
            return true
        } catch Error as e {
            this.LogError("Installation validation failed", e)
            return false
        }
    }
}