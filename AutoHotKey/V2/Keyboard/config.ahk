;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; config.ahk - Configuration management system
;
; This module handles loading, saving, and managing application configuration.
; Configuration is stored in JSON format for easy editing and portability.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class AppConfig {
    settings := Map()
    configFile := CONSTANTS.CONFIG_FILE
    isDirty := false
    
    /**
     * Initialize configuration with default values
     */
    __New() {
        ; Load default configuration
        for key, value in CONSTANTS.DEFAULT_CONFIG {
            this.settings[key] := value
        }
    }
    
    /**
     * Get a configuration value
     * @param {String} key - Configuration key
     * @param {Any} defaultValue - Default value if key doesn't exist
     * @return {Any} - Configuration value
     */
    Get(key, defaultValue := "") {
        try {
            if (this.settings.Has(key)) {
                return this.settings[key]
            }
            return defaultValue
        } catch Error as e {
            utils.LogError("Failed to get config value: " . key, e)
            return defaultValue
        }
    }
    
    /**
     * Set a configuration value
     * @param {String} key - Configuration key
     * @param {Any} value - Value to set
     */
    Set(key, value) {
        try {
            oldValue := this.Get(key)
            this.settings[key] := value
            this.isDirty := true
            
            ; Trigger change notifications
            this.OnConfigChanged(key, oldValue, value)
            
            utils.LogInfo("Config changed: " . key . " = " . String(value))
        } catch Error as e {
            utils.LogError("Failed to set config value: " . key, e)
        }
    }
    
    /**
     * Toggle a boolean configuration value
     * @param {String} key - Configuration key
     * @return {Boolean} - New value after toggle
     */
    Toggle(key) {
        try {
            currentValue := this.Get(key, false)
            newValue := !currentValue
            this.Set(key, newValue)
            return newValue
        } catch Error as e {
            utils.LogError("Failed to toggle config value: " . key, e)
            return false
        }
    }
    
    /**
     * Load configuration from file
     */
    Load() {
        try {
            if (FileExist(this.configFile)) {
                jsonContent := FileRead(this.configFile, "UTF-8")
                configData := JSON.parse(jsonContent)
                
                ; Merge loaded config with defaults
                for key, value in configData {
                    this.settings[key] := value
                }
                
                this.isDirty := false
                utils.LogInfo("Configuration loaded from: " . this.configFile)
            } else {
                utils.LogInfo("No config file found, using defaults")
                this.Save() ; Create initial config file
            }
        } catch Error as e {
            utils.LogError("Failed to load configuration", e)
            ; Continue with default configuration
        }
    }
    
    /**
     * Save configuration to file
     */
    Save() {
        try {
            ; Convert Map to object for JSON serialization
            configObj := {}
            for key, value in this.settings {
                configObj.%key% := value
            }
            
            jsonContent := JSON.stringify(configObj, "", 2)
            FileDelete(this.configFile)
            FileAppend(jsonContent, this.configFile, "UTF-8")
            
            this.isDirty := false
            utils.LogInfo("Configuration saved to: " . this.configFile)
        } catch Error as e {
            utils.LogError("Failed to save configuration", e)
        }
    }
    
    /**
     * Handle configuration changes
     * @param {String} key - Changed key
     * @param {Any} oldValue - Previous value
     * @param {Any} newValue - New value
     */
    OnConfigChanged(key, oldValue, newValue) {
        ; Handle specific configuration changes
        switch key {
            case "colemak":
                this.HandleColemakChange(newValue)
            case "colemakAllTime":
                this.HandleColemakAllTimeChange(newValue)
            case "pok3r", "pok3rColemak":
                this.HandlePok3rChange()
            case "enableCapsLock":
                this.HandleCapsLockChange(newValue)
        }
    }
    
    /**
     * Handle Colemak layout changes
     * @param {Boolean} enabled - Whether Colemak is enabled
     */
    HandleColemakChange(enabled) {
        if (enabled) {
            this.Set("colemakAllTime", false)
        }
        ; LED functionality would go here if implemented
    }
    
    /**
     * Handle Colemak all-time mode changes
     * @param {Boolean} enabled - Whether Colemak all-time is enabled
     */
    HandleColemakAllTimeChange(enabled) {
        if (enabled) {
            this.Set("colemak", false)
        }
        ; LED functionality would go here if implemented
    }
    
    /**
     * Handle POK3R keyboard mode changes
     */
    HandlePok3rChange() {
        colemakMode := this.Get("colemak") || this.Get("colemakAllTime")
        
        if (colemakMode) {
            if (this.Get("pok3rColemak")) {
                this.Set("pok3r", false)
            }
        } else {
            if (this.Get("pok3r")) {
                this.Set("pok3rColemak", false)
            }
        }
    }
    
    /**
     * Handle CapsLock enable/disable changes
     * @param {Boolean} enabled - Whether CapsLock should be enabled
     */
    HandleCapsLockChange(enabled) {
        ; This would be handled by the hotkey registration system
        ; The actual hotkey enabling/disabling is done elsewhere
    }
    
    /**
     * Reset configuration to defaults
     */
    Reset() {
        try {
            this.settings.Clear()
            for key, value in CONSTANTS.DEFAULT_CONFIG {
                this.settings[key] := value
            }
            this.isDirty := true
            utils.LogInfo("Configuration reset to defaults")
        } catch Error as e {
            utils.LogError("Failed to reset configuration", e)
        }
    }
    
    /**
     * Get all configuration as a readable string
     * @return {String} - Formatted configuration string
     */
    ToString() {
        try {
            result := "Current Configuration:`n"
            for key, value in this.settings {
                result .= "  " . key . ": " . String(value) . "`n"
            }
            return result
        } catch Error as e {
            utils.LogError("Failed to convert config to string", e)
            return "Error reading configuration"
        }
    }
    
    /**
     * Check if configuration has unsaved changes
     * @return {Boolean} - True if there are unsaved changes
     */
    HasUnsavedChanges() {
        return this.isDirty
    }
}

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Simple JSON implementation for configuration serialization
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class JSON {
    /**
     * Parse JSON string into AutoHotkey object
     * @param {String} jsonString - JSON string to parse
     * @return {Object} - Parsed object
     */
    static parse(jsonString) {
        ; Simple JSON parser implementation
        ; For production use, consider a more robust JSON library
        try {
            ; Remove whitespace and newlines
            cleaned := RegExReplace(jsonString, "\s+", " ")
            cleaned := Trim(cleaned)
            
            if (SubStr(cleaned, 1, 1) == "{" && SubStr(cleaned, -1) == "}") {
                return JSON.parseObject(SubStr(cleaned, 2, -2))
            }
            
            throw Error("Invalid JSON format")
        } catch Error as e {
            throw Error("JSON parse error: " . e.Message)
        }
    }
    
    /**
     * Convert object to JSON string
     * @param {Object} obj - Object to stringify
     * @param {String} replacer - Not used (compatibility parameter)
     * @param {Integer} space - Number of spaces for indentation
     * @return {String} - JSON string
     */
    static stringify(obj, replacer := "", space := 0) {
        try {
            return JSON.stringifyValue(obj, 0, space)
        } catch Error as e {
            throw Error("JSON stringify error: " . e.Message)
        }
    }
    
    /**
     * Parse a JSON object string
     * @param {String} objString - Object content without braces
     * @return {Object} - Parsed object
     */
    static parseObject(objString) {
        result := {}
        if (Trim(objString) == "") {
            return result
        }
        
        ; Simple parsing - split by commas and parse key-value pairs
        pairs := StrSplit(objString, ",")
        for pair in pairs {
            colonPos := InStr(pair, ":")
            if (colonPos > 0) {
                key := JSON.parseValue(Trim(SubStr(pair, 1, colonPos - 1)))
                value := JSON.parseValue(Trim(SubStr(pair, colonPos + 1)))
                result.%key% := value
            }
        }
        
        return result
    }
    
    /**
     * Parse a JSON value
     * @param {String} valueString - Value string to parse
     * @return {Any} - Parsed value
     */
    static parseValue(valueString) {
        valueString := Trim(valueString)
        
        ; String
        if (SubStr(valueString, 1, 1) == '"' && SubStr(valueString, -1) == '"') {
            return SubStr(valueString, 2, -2)
        }
        
        ; Boolean
        if (valueString == "true") {
            return true
        }
        if (valueString == "false") {
            return false
        }
        
        ; Number
        if (IsNumber(valueString)) {
            return Number(valueString)
        }
        
        ; Default to string
        return valueString
    }
    
    /**
     * Stringify a value with proper indentation
     * @param {Any} value - Value to stringify
     * @param {Integer} depth - Current depth for indentation
     * @param {Integer} space - Number of spaces per indent level
     * @return {String} - Stringified value
     */
    static stringifyValue(value, depth := 0, space := 0) {
        indent := ""
        if (space > 0) {
            Loop space * depth {
                indent .= " "
            }
        }
        
        nextIndent := ""
        if (space > 0) {
            Loop space * (depth + 1) {
                nextIndent .= " "
            }
        }
        
        ; Handle different types
        if (Type(value) == "String") {
            return '"' . value . '"'
        }
        
        if (Type(value) == "Integer" || Type(value) == "Float") {
            return String(value)
        }
        
        if (Type(value) == "Object") {
            if (value == true) {
                return "true"
            }
            if (value == false) {
                return "false"
            }
            
            ; Object
            result := "{"
            if (space > 0) {
                result .= "`n"
            }
            
            first := true
            for key, val in value.OwnProps() {
                if (!first) {
                    result .= ","
                    if (space > 0) {
                        result .= "`n"
                    }
                }
                
                if (space > 0) {
                    result .= nextIndent
                }
                
                result .= '"' . key . '":' . (space > 0 ? " " : "") . JSON.stringifyValue(val, depth + 1, space)
                first := false
            }
            
            if (space > 0) {
                result .= "`n" . indent
            }
            result .= "}"
            return result
        }
        
        ; Default
        return '"' . String(value) . '"'
    }
}