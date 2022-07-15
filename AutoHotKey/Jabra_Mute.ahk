Pause::  ;Pause Break button is my chosen hotkey

SoundSet, +1, MASTER, mute, 19
SoundGet, master_mute, , mute, 19

ToolTip, Mute %master_mute% ;use a tool tip at mouse pointer to show what state mic is after toggle
;ToolTip, % "Microphone " (master_mute = "On" ? "OFF" : "ON")
if (master_mute = "On") {
   SoundBeep, 500, 300
} else {
   SoundBeep, 2000, 300
}
SetTimer, RemoveToolTip, 1000
return

RemoveToolTip:
SetTimer, RemoveToolTip, Off
ToolTip
return
