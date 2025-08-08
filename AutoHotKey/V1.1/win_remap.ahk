CapsLock::
   ToolTip % " ", 5000, 3000
   WinActivate, ahk_class tooltips_class32
   if (caps > 0) {
      caps++
      return
   }
   caps := 1
   SetTimer, Cappy, 350
Return

Cappy:
   if (caps = 1) {
      Send, {RWin down}
      KeyWait, CapsLock, U
      Send, !{RWin Up}
      ToolTip
      if (A_PriorKey = "CapsLock") {
         ToolTip, "Win"
         Send, {RWin}
      } else if (A_PriorKey = "l") {
         ToolTip, "Lock"
         DllCall("LockWorkStation")
      } else if (A_PriorKey != "CapsLock"){
         ToolTip, %A_PriorKey%
         Send, {RWin down}{%A_PriorKey%}{RWin Up}
      }
   } else if (caps = 2) {
      Input, SingleKey, V L1
      if GetKeyState("CapsLock", "T") = 1 {
         SetCapsLockState, off 
      } else if GetKeyState("CapsLock", "F") = 0 {
         SetCapsLockState, on 
      }
   }
   caps := 0
Return
