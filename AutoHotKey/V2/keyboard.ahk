#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
; ============================================================
; Clean AHK v2 Script (no LEDs, no pok3r, no Montsinger)
; Features:
;  - Colemak modes: toggle, all-time, sub-mode placeholder
;  - Colemak letter remap with Shift preservation
;  - PrintScreen toggle (Colemak-aware hotkey sets)
;  - CapsLock enable/disable via RightShift+CapsLock
;  - F24 multi-purpose: app-shortcuts vs mouse simulator
;  - App-specific F24 (ccsa.exe, devenv.exe)
;  - Media controls, F14/F15 volume keys
;  - Quick workstation lock
; ============================================================

; -------------------------
; Global State Flags
; -------------------------
global colemak := false          ; Alt+/
global colemakAllTime := false   ; Alt+?
global colemakSub := false       ; Alt+.
global printScreen := false
global enableCapsLock := true

global useF24MouseSim := false   ; RightCtrl+F24
global F24Paste := false         ; LeftAlt+F24 (flag only)

; -------------------------
; Helpers
; -------------------------
ColemakActive() {
    return colemak || colemakAllTime || colemakSub
}

Notify(msg, ms := 900) {
    TrayTip "AHK", msg, "Mute"
    SetTimer(() => TrayTip(), -ms)
}

; -------------------------
; Colemak Mapping
;  QWERTY -> Colemak (classic, letters only)
;  Shift is preserved.
; -------------------------
global Colemap := Map(
 ; row 1
 "q","q",
 "w","w",
 "e","f",
 "r","p",
 "t","g",
 "y","j",
 "u","l",
 "i","u",
 "o","y",
 "p","p",

 ; row 2
 "a","a",
 "s","r",
 "d","s",
 "f","t",
 "g","d",
 "h","h",
 "j","n",
 "k","e",
 "l","i",

 ; row 3
 "z","z",
 "x","x",
 "c","c",
 "v","v",
 "b","b",
 "n","k",
 "m","m"
)

; --- Register Colemak remaps (letters only) ---
_forEachColeKey := StrSplit("abcdefghijklmnopqrstuvwxyz")

; Give HotIf a callable (lambda) instead of a bare name:
#HotIf ColemakActive()

for k in _forEachColeKey {
    ; One wildcard hotkey per letter is enough; it fires with Shift/Ctrl/Alt/Win.
    Hotkey("*" k, ColeRemap.Bind(k))
}

#HotIf  ; reset context

; --- Remapper preserving case (Shift/CapsLock) and avoiding recursion ---
ColeRemap(origKey) {
    if !ColemakActive() {
        Send "{" origKey "}"
        return
    }

    out := Colemap.Has(origKey) ? Colemap[origKey] : origKey

    ; Uppercase if Shift XOR CapsLock is active.
    up := (GetKeyState("Shift","P") ? 1 : 0) ^ (GetKeyState("CapsLock","T") ? 1 : 0)

    ; SendText avoids re-triggering our hotkeys (no recursion).
    if up
        SendText StrUpper(out)
    else
        SendText out
}

; -------------------------
; Colemak Mode Toggles
; -------------------------
; Alt+/
!/:: {
    global colemak := !colemak
    Notify("Colemak: " (colemak ? "ON" : "OFF"))
}

; Alt+.
!.:: {
    global colemakSub := !colemakSub
    Notify("Colemak Sub-Mode: " (colemakSub ? "ON" : "OFF"))
}

; Alt+?
!?:: {
    global colemakAllTime := !colemakAllTime
    Notify("Colemak All-Time: " (colemakAllTime ? "ON" : "OFF"))
}

; -------------------------
; PrintScreen Mode (Colemak-aware hotkeys)
; If Colemak ACTIVE -> use Win+Alt+R to toggle, Win+Alt+Shift+R to turn OFF
; If Colemak INACTIVE -> use Win+Alt+P to toggle, Win+Alt+Shift+P to turn OFF
; -------------------------
; Win+Alt+R  (only when Colemak active)
#!r:: {
    if ColemakActive() {
        global printScreen := !printScreen
        Notify("printScreen: " (printScreen ? "ON" : "OFF"))
    }
}

; Win+Alt+Shift+R  (only when Colemak active) -> force OFF
#!+r:: {
    if ColemakActive() {
        global printScreen := false
        Notify("printScreen: OFF")
    }
}

; Win+Alt+P  (only when Colemak inactive)
#!p:: {
    if !ColemakActive() {
        global printScreen := !printScreen
        Notify("printScreen: " (printScreen ? "ON" : "OFF"))
    }
}

; Win+Alt+Shift+P  (only when Colemak inactive) -> force OFF
#!+p:: {
    if !ColemakActive() {
        global printScreen := false
        Notify("printScreen: OFF")
    }
}

; -------------------------
; CapsLock Control
; RightShift+CapsLock toggles CapsLock functionality
; CapsLock alone: does nothing if disabled; normal if enabled
; -------------------------
>+CapsLock:: { ; Right Shift + CapsLock
    global enableCapsLock := !enableCapsLock
    Notify("CapsLock enabled: " (enableCapsLock ? "YES" : "NO"))
}

*CapsLock:: {
    if enableCapsLock
        Send "{CapsLock}"
    ; else swallow
}

; -------------------------
; F24 Multi-Purpose
;   - Toggle mouse-sim vs app-shortcuts: RightCtrl+F24
;   - Toggle F24Paste flag: LeftAlt+F24
;   - Default app-shortcuts: F24=Ctrl+F8, Shift+F24=Shift+Ctrl+F8
;   - Mouse-sim: F24=LeftClick, RightShift+F24=RightClick
; App-specific overrides for ccsa.exe, devenv.exe
; -------------------------
>^F24:: { ; Right Ctrl + F24
    global useF24MouseSim := !useF24MouseSim
    Notify("F24 mode: " (useF24MouseSim ? "Mouse Sim" : "App Shortcuts"))
}

<!F24:: { ; Left Alt + F24
    global F24Paste := !F24Paste
    Notify("F24Paste flag: " (F24Paste ? "ON" : "OFF"))
}

; --- Mouse Simulator bindings (active only when useF24MouseSim = true)
#HotIf useF24MouseSim
F24:: {
    Click "Left"
}
>+F24:: { ; Right Shift + F24
    Click "Right"
}
#HotIf

; --- App Shortcut defaults (only when NOT in mouse-sim)
#HotIf !useF24MouseSim
; Global default
F24:: {
    Send "^{" "F8" "}"
}
+F24:: {
    Send "+^{" "F8" "}"
}
#HotIf

; -------- App-specific: ccsa.exe --------
#HotIf !useF24MouseSim && WinActive("ahk_exe ccsa.exe")
F24:: {
    Send "!{" "Down" "}"
}
+F24:: {
    Send "!{" "Up" "}"
}
#HotIf

; -------- App-specific: devenv.exe (Visual Studio) --------
#HotIf !useF24MouseSim && WinActive("ahk_exe devenv.exe")
F24:: {
    Send "^{" "F8" "}"
}
+F24:: {
    Send "+^{" "F8" "}"
}
#HotIf

; (Placeholders exist IRL for Postman.exe / EXCEL.EXE; not mapped here per brief)

; -------------------------
; Media & Transport Controls
; -------------------------
^Volume_Mute:: {
    Send "{Media_Play_Pause}"
}
^Volume_Down:: {
    Send "{Media_Prev}"
}
^Volume_Up:: {
    Send "{Media_Next}"
}

; Mac-style F-keys for volume (if present)
F14:: {
    Send "{Volume_Down}"
}
F15:: {
    Send "{Volume_Up}"
}

; -------------------------
; System / Workstation Control
; LeftWin+Shift+Q -> Lock workstation
; -------------------------
<#+q:: {
    DllCall("LockWorkStation")
}

; ============================================================
; End of file
; ============================================================

