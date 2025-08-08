;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; constants.ahk - Application-wide constants
;
; This file contains all constant values used throughout the application.
; Centralizing constants makes the code more maintainable and configurable.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

class CONSTANTS {
    ; Timing constants (in milliseconds)
    static KEY_DELAY := 50
    static NOTIFICATION_DURATION := 2000
    static AUTO_SAVE_INTERVAL := 300000  ; 5 minutes
    static STATUS_CHECK_INTERVAL := 60000 ; 1 minute
    static POK3R_TIMEOUT := 500
    
    ; File paths
    static CONFIG_FILE := A_ScriptDir . "\keyboard_config.json"
    static LOG_FILE := A_ScriptDir . "\keyboard_log.txt"
    
    ; Registry paths
    static REGISTRY_BASE := "HKEY_CURRENT_USER"
    static LOCK_WORKSTATION_PATH := "Software\Microsoft\Windows\CurrentVersion\Policies\System"
    static LOCK_WORKSTATION_KEY := "DisableLockWorkstation"
    
    ; Application executables
    static VISUAL_STUDIO := "ahk_exe devenv.exe"
    static POSTMAN := "ahk_exe Postman.exe"
    static CCSA := "ahk_exe ccsa.exe"
    static EXCEL := "ahk_exe EXCEL.EXE"
    static PLEX := "Plex"
    static VIM_CLASSES := ["ahk_Class Vim", "ahk_Class VIM", "VIM"]
    static CHROME_CLASS := "ahk_Class Chrome"
    
    ; Special key codes
    static FUNCTION_KEYS := ["F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12"]
    static MODIFIER_KEYS := ["Ctrl", "Alt", "Shift", "LWin", "RWin"]
    
    ; POK3R key mappings
    static POK3R_UNUSED_KEYS := ["`", "r", "t", "\", "g", "x", "c", "v", "b", ",", ".", "/", "w", "a", "s", "d"]
    static POK3R_CURSOR_KEYS := Map("h", "Left", "j", "Down", "k", "Up", "l", "Right")
    static POK3R_JUMP_KEYS := Map("i", "Home", "n", "End", "u", "PgUp", "o", "PgDn")
    static POK3R_TKL_KEYS := Map(";", "Del", "'", "Ins", "p", "PrintScreen", "]", "Pause", "}", "Break")
    
    ; Colemak layout mapping
    static COLEMAK_LAYOUT := Map(
        "q", "q", "w", "w", "e", "f", "r", "p", "t", "g",
        "y", "j", "u", "l", "i", "u", "o", "y", "p", ";",
        "[", "[", "]", "]", "\", "\",
        "a", "a", "s", "r", "d", "s", "f", "t", "g", "d",
        "h", "h", "j", "n", "k", "e", "l", "i", ";", "o", "'", "'",
        "z", "z", "x", "x", "c", "c", "v", "v", "b", "b",
        "n", "k", "m", "m", ",", ",", ".", ".", "/", "/"
    )
    
    ; Characters that should not be affected by CapsLock toggle
    static CAPSLOCK_IGNORE_CHARS := "[,.;'\\\/\[\]]"
    
    ; Window lock registry values
    static LOCK_ENABLED := 1
    static LOCK_DISABLED := 0
    
    ; Log levels
    static LOG_INFO := "INFO"
    static LOG_WARNING := "WARNING"  
    static LOG_ERROR := "ERROR"
    
    ; Default configuration values
    static DEFAULT_CONFIG := Map(
        "colemak", false,
        "colemakAllTime", false,
        "wasdKeyboard", false,
        "confKeyboard", false,
        "normKeyboard", false,
        "pok3r", false,
        "pok3rColemak", false,
        "printScreen", false,
        "changeCapslock", false,
        "montsinger", false,
        "montsingerVol", false,
        "useF24MouseSim", false,
        "f24Paste", false,
        "enableCapsLock", true
    )
}