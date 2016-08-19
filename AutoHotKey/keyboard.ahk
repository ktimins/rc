#CommentFlag //
#InstallKeybdHook
#NoEnv 
SendMode Input 
SetTitleMatchMode, 2
SetTitleMatchMode, slow

//////////////////////////////
//         Includes         //
//////////////////////////////

//////////////////////////////
//      Set Variables       //
//////////////////////////////

colemak        := true
colemakAllTime := false
wasdKeyboard   := false
confKeyboard   := false
normKeyboard   := false
ModifierStates := ""

///////////////////////
// QWERTY to Colemak //
///////////////////////

dictColemak    := {"q":"q"
                  ,"w":"w"
                  ,"e":"f"
                  ,"r":"p"
                  ,"t":"g"
                  ,"y":"j"
                  ,"u":"l"
                  ,"i":"u"
                  ,"o":"y"
                  ,"p":";"
                  ,"[":"["
                  ,"]":"]"
                  ,"\":"\"
                  ,"a":"a"
                  ,"s":"r"
                  ,"d":"s"
                  ,"f":"t"
                  ,"g":"d"
                  ,"h":"h"
                  ,"j":"n"
                  ,"k":"e"
                  ,"l":"i"
                  ,";":"o"
                  ,"'":"'"
                  ,"z":"z"
                  ,"x":"x"
                  ,"c":"c"
                  ,"v":"v"
                  ,"b":"b"
                  ,"n":"k"
                  ,"m":"m"
                  ,",":","
                  ,".":"."
                  ,"/":"/"}


/////////////////////////////
//      Base Hotkeys       //
/////////////////////////////

//Suspend
//Pause,,1

+Pause::
   Suspend
   //Pause,,1
Return

<!Pause::
   Reload
Return

>!/::
   colemak:=not colemak
   if (colemak) {
      colemakAllTime := false
   }
Return

>!?::
   colemakAllTime := not colemakAllTime
   if (colemakAllTime) {
      colemak := false
   }
Return

>!Scrolllock::
   normKeyboard:=not normKeyboard
Return

>!+Scrolllock::
<#+f::
   confKeyboard:=not confKeyboard
Return

<!+Scrolllock::
   wasdKeyboard:=not wasdKeyboard
Return

!+w::
   WinGetTitle, Title, A
   MsgBox, The active window Title is "%Title%"
Return

//////////////////////////////
//    Swap LCtrl & LWin     //
//////////////////////////////

#If (wasdKeyboard or normKeyboard)
   LWin::LCtrl
   LCtrl::LWin
   Rwin::Appskey
   Appskey::RWin
#If

#if (confKeyboard)
   LWin::LCtrl
   LCtrl::LWIn
   
#if

//////////////////////////////
//        Capslock          //
//////////////////////////////

   Capslock::
      SendInput {Blind}{Backspace DownTemp}
      SendInput {Blind}{Backspace Up}
      Return

   ^Capslock::
   ^!Capslock::
   ^!+Capslock::
   ^+Capslock::
   !Capslock::
   !+Capslock::
   +Capslock::
   #Capslock::
   #!Capslock::
   #^Capslock::
   #^!Capslock::
   #+Capslock::
      Return

   

   <#c::Capslock

//////////////////////////////
//         Pok3r            //
//////////////////////////////

   ^Space::
      Send ^{Space}
      Return
   *Space::
      KeyWait, Space, T0.5
      If ErrorLevel {
         #Persistent
         SetCapsLockState, AlwaysOff
         
         // Unused keys
         Space & `::
         Space & r::
         Space & t::
         Space & \::
         Space & g::
         Space & x::
         Space & c::
         Space & v::
         Space & b::
         Space & ,::
         Space & .::
         Space & /::  
         Space & w::
         Space & a::
         Space & s::
         Space & d::
            Return

         // Cursor Movement
         Space & h::Send {Blind}{Left DownTemp}
         Space & h up::Send {Blind}{Left Up}
         
         Space & j::Send {Blind}{Down DownTemp}
         Space & j up::Send {Blind}{Down Up}
         
         Space & k::Send {Blind}{Up DownTemp}
         Space & k up::Send {Blind}{Up Up}
         
         Space & l::Send {Blind}{Right DownTemp}
         Space & l up::Send {Blind}{Right Up}
         
         
         // Cursor Jumps
         Space & i::SendInput {Blind}{Home Down}
         Space & i up::SendInput {Blind}{Home Up}
         
         Space & n::SendInput {Blind}{End Down}
         Space & n up::SendInput {Blind}{End Up}
         
         Space & u::SendInput {Blind}{PgUp Down}
         Space & u up::SendInput {Blind}{PgUp Up}
         
         Space & o::SendInput {Blind}{PgDn Down}
         Space & o up::SendInput {Blind}{PgDn Up}
         
         
         // Function Keys
         Space & 1::SendInput {Blind}{F1}
         Space & 2::SendInput {Blind}{F2}
         Space & 3::SendInput {Blind}{F3}
         Space & 4::SendInput {Blind}{F4}
         Space & 5::SendInput {Blind}{F5}
         Space & 6::SendInput {Blind}{F6}
         Space & 7::SendInput {Blind}{F7}
         Space & 8::SendInput {Blind}{F8}
         Space & 9::SendInput {Blind}{F9}
         Space & 0::SendInput {Blind}{F10}
         Space & -::SendInput {Blind}{F11}
         Space & =::SendInput {Blind}{F12}
         
         // TKL Keys
         Space & ;::SendInput {Del Down}
         Space & ; up::SendInput {Del Up}
         
         Space & '::SendInput {Ins Down}
         Space & ' up::SendInput {Ins Up}
         
         Space & p::SendInput {PrintScreen}
         Space & ]::SendInput {Pause}
         

         // Random
         Space & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}

         Space & y::Run calc.exe
         Space & z::SendInput {AppsKey}
         
      } Else
         Send {Space}
   Return

//////////////////////////////
//         Colemak          //
//////////////////////////////

// Standard keys
#If (colemak and  (((not WinActive("ahk_exe devenv.exe") and not WinActive("ahk_Class Vim") and not WinActive("ahk_Class VIM") and not WinActive("VIM")) or WinActive("ahk_Class Chrome"))) or colemakAllTime)
   *q::
      sendModifierStates(dictColemak["q"])
      Return
   *w::
      sendModifierStates(dictColemak["w"])
      Return
   *e::
      sendModifierStates(dictColemak["e"])
      Return
   *r::
      sendModifierStates(dictColemak["r"])
      Return
   *t::
      sendModifierStates(dictColemak["t"])
      Return
   *y::
      sendModifierStates(dictColemak["y"])
      Return
   *u::
      sendModifierStates(dictColemak["u"])
      Return
   *i::
      sendModifierStates(dictColemak["i"])
      Return
   *o::
      sendModifierStates(dictColemak["o"])
      Return
   *p::
      sendModifierStates(dictColemak["p"])
      Return
   *[::
      sendModifierStates(dictColemak["["])
      Return
   *]::
      sendModifierStates(dictColemak["]"])
      Return
   *\::
      sendModifierStates(dictColemak["\"])
      Return
   *a::
      sendModifierStates(dictColemak["a"])
      Return
   *s::
      sendModifierStates(dictColemak["s"])
      Return
   *d::
      sendModifierStates(dictColemak["d"])
      Return
   *f::
      sendModifierStates(dictColemak["f"])
      Return
   *g::
      sendModifierStates(dictColemak["g"])
      Return
   *h::
      sendModifierStates(dictColemak["h"])
      Return
   *j::
      sendModifierStates(dictColemak["j"])
      Return
   *k::
      sendModifierStates(dictColemak["k"])
      Return
   *l::
      sendModifierStates(dictColemak["l"])
      Return
   *;::
      sendModifierStates(dictColemak[";"])
      Return
   *'::
      sendModifierStates(dictColemak["'"])
      Return
   *z::
      sendModifierStates(dictColemak["z"])
      Return
   *x::
      sendModifierStates(dictColemak["x"])
      Return
   *c::
      sendModifierStates(dictColemak["c"])
      Return
   *v::
      sendModifierStates(dictColemak["v"])
      Return
   *b::
      sendModifierStates(dictColemak["b"])
         Return
   *n::
      sendModifierStates(dictColemak["n"])
         Return
   *m::
      sendModifierStates(dictColemak["m"])
         Return
   *,::
      sendModifierStates(dictColemak[","])
         Return
   *.::
      sendModifierStates(dictColemak["."])
         Return
   */::
      sendModifierStates(dictColemak["/"])
         Return

   sleep 100

#If

//////////////////////////////
//         Win Lock         //
//////////////////////////////
#If (true)
   
   #l::
      Return

   #+q:: 
      {
         RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 0
         DllCall("LockWorkStation")
         sleep, 1000
         RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 1
      }
      Return

#If


/////////////////////////////
//       Sub-Routines      //
/////////////////////////////

getModifierStates(ByRef AlphaForm := "")
{
   AlphaForm := ""
   
   if (confKeyboard) {
      if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
      {
         ReturnValue .= "^"
         AlphaForm .= "C"
      }

      if GetKeyState("Ctrl", "P")
      {
         ReturnValue .= "#"
         AlphaForm .= "W"
      }
   } Else {
      if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
      {
         ReturnValue .= "#"
         AlphaForm .= "W"
      }

      if GetKeyState("Ctrl", "P")
      {
         ReturnValue .= "^"
         AlphaForm .= "C"
      }

      if GetKeyState("Alt", "P")
      {
         ReturnValue .= "!"
         AlphaForm .= "A"
      }

      if GetKeyState("Shift", "P")
      {
         ReturnValue .= "+"
         AlphaForm .= "S"
      }
   }

   return ReturnValue
}

sendModifierStates(ByRef Key) 
{
      ModifierStates := getModifierStates()
      If GetKeyState("CapsLock", "T") = 1 and not RegExMatch(Key, "[,.;'\\\/\[\]]") {
         If GetKeyState("Shift", "P") = 1
            ModifierStates := RegExReplace(ModifierStates, "[+]", "")
         Else
            ModifierStates .= "+"
      }
      Send, %ModifierStates%{%Key%}
      sleep 100
}
