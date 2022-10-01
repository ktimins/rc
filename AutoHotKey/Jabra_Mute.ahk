InputBox, micNum, What number is the mic, , , 230, 100, , , 20, 12

Pause::  ;Pause Break button is my chosen hotkey
   ;SoundSet, +1, MASTER, mute, 12
   ;SoundGet, master_mute, , mute, 12

   SoundSet, +1, MASTER, mute, micNum
   SoundGet, master_mute, , mute, micNum

   ToolTip, Mute %master_mute% - mic %micNum% ;use a tool tip at mouse pointer to show what state mic is after toggle
   ;ToolTip, % "Microphone " (master_mute = "On" ? "OFF" : "ON")
   if (master_mute = "On") {
      SoundBeep, 500, 300
   } else {
      SoundBeep, 2000, 300
   }
   SetTimer, RemoveToolTip, 1000
   Return

RemoveToolTip:
   SetTimer, RemoveToolTip, Off
   ToolTip
   Return

