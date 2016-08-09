#CommentFlag //
#InstallKeybdHook
#NoEnv 
SendMode Input 
SetTitleMatchMode, 2
SetTitleMatchMode, slow


//////////////////////////////
//      Set Variables       //
//////////////////////////////

colemak        := true
colemakAllTime := false
pok3r          := false
wasdKeyboard   := false
confKeyboard   := false
normKeyboard   := false
ModifierStates := ""

/////////////////////////////
//      Base Hotkeys       //
/////////////////////////////
   #::
      MsgBox, % getModifierStates()
      Return

//Suspend
//Pause,,1

+Pause::
   Suspend
   //Pause,,1
Return

<!Pause::
   Reload
Return


>#,::
>!,::
   pok3r:=not pok3r
Return

>#/::
>!/::
   colemak:=not colemak
   if (colemak) {
      colemakAllTime := false
   }
Return

>#?::
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

IncrementValue = 5
MouseDelay = 0

//////////////////////////////
//    Swap LCtrl & LWin     //
//////////////////////////////

//#If (wasdKeyboard or confKeyboard)
//   LWin::LCtrl
//   LCtrl::LWin
//   Rwin::Appskey
//   Appskey::RWin
//#If

//////////////////////////////
//         Defaults         //
//////////////////////////////

// Win
//#If (not wasdKeyboard or not confKeyboard)
//   LWin::
//   RWin::
//      Return
//   LWin & Space::SendInput {Blind}{LWin}
//#If


//////////////////////////////
//        Capslock          //
//////////////////////////////

#If (not pok3r)

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

   

   <!c::Capslock
   <#c::Capslock
      Return
      //If GetKeyState("Capslock", T)
      //   SetCapsLockState, On
      //Else
      //   SetCapsLockState, Off
      //Return
#If

//////////////////////////////
//         Pok3r            //
//////////////////////////////

#if (pok3r and not colemak and not WinActive("Title HwndWrapper") and not WinActive("ahk_Class Vim"))
   #Persistent
   SetCapsLockState, AlwaysOff
   
   Capslock::
   Return

   // Unused keys
   Capslock & `::
   Capslock & r::
   Capslock & t::
   Capslock & \::
   Capslock & g::
   Capslock & x::
   Capslock & c::
   Capslock & v::
   Capslock & b::
   Capslock & ,::
   Capslock & .::
   Capslock & /::  
   Capslock & w::
   Capslock & a::
   Capslock & s::
   Capslock & d::
   
   // Cursor Movement
   Capslock & h::Send {Blind}{Left DownTemp}
   Capslock & h up::Send {Blind}{Left Up}
   
   Capslock & j::Send {Blind}{Down DownTemp}
   Capslock & j up::Send {Blind}{Down Up}
   
   Capslock & k::Send {Blind}{Up DownTemp}
   Capslock & k up::Send {Blind}{Up Up}
   
   Capslock & l::Send {Blind}{Right DownTemp}
   Capslock & l up::Send {Blind}{Right Up}
   
   
   // Cursor Jumps
   Capslock & i::SendInput {Blind}{Home Down}
   Capslock & i up::SendInput {Blind}{Home Up}
   
   Capslock & n::SendInput {Blind}{End Down}
   Capslock & n up::SendInput {Blind}{End Up}
   
   Capslock & u::SendInput {Blind}{PgUp Down}
   Capslock & u up::SendInput {Blind}{PgUp Up}
   
   Capslock & o::SendInput {Blind}{PgDn Down}
   Capslock & o up::SendInput {Blind}{PgDn Up}
   
   
   // Function Keys
   Capslock & 1::SendInput {Blind}{F1}
   Capslock & 2::SendInput {Blind}{F2}
   Capslock & 3::SendInput {Blind}{F3}
   Capslock & 4::SendInput {Blind}{F4}
   Capslock & 5::SendInput {Blind}{F5}
   Capslock & 6::SendInput {Blind}{F6}
   Capslock & 7::SendInput {Blind}{F7}
   Capslock & 8::SendInput {Blind}{F8}
   Capslock & 9::SendInput {Blind}{F9}
   Capslock & 0::SendInput {Blind}{F10}
   Capslock & -::SendInput {Blind}{F11}
   Capslock & =::SendInput {Blind}{F12}
   
   // TKL Keys
   Capslock & ;::SendInput {Del Down}
   Capslock & ; up::SendInput {Del Up}
   
   Capslock & '::SendInput {Ins Down}
   Capslock & ' up::SendInput {Ins Up}
   
   Capslock & p::SendInput {PrintScreen}
   Capslock & ]::SendInput {Pause}
   

   // Random
   Capslock & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}
   Capslock & Space::SendInput {Ctrl down}{Space}{Ctrl up}

   CapsLock & y::Run calc.exe
   CapsLock & z::SendInput {AppsKey}
   

#If

#If (pok3r and not WinActive("Title HwndWrapper") and not WinActive("ahk_Class Vim"))

   // CapsLock behavior
   >!Capslock:
   If GetKeyState("CapsLock", "T") = 1
       SetCapsLockState, AlwaysOff
   Else 
       SetCapsLockState, AlwaysOn
   Return

#If


#If (pok3r and colemak and not wasdKeyboard)
   #Persistent
   SetCapsLockState, AlwaysOff
   
   Capslock::
   Return

   // Unused keys
   Capslock & `::
   Capslock & r::
   Capslock & t::
   Capslock & \::
   Capslock & g::
   Capslock & x::
   Capslock & c::
   Capslock & v::
   Capslock & b::
   Capslock & ,::
   Capslock & .::
   Capslock & /::  
   Capslock & w::
   Capslock & a::
   Capslock & s::
   Capslock & d::
   
   // Cursor Movement
   Capslock & h::Send {Blind}{Left DownTemp}
   Capslock & h up::Send {Blind}{Left Up}
   
   Capslock & n::Send {Blind}{Down DownTemp}
   Capslock & n up::Send {Blind}{Down Up}
   
   Capslock & e::Send {Blind}{Up DownTemp}
   Capslock & e up::Send {Blind}{Up Up}
   
   Capslock & i::Send {Blind}{Right DownTemp}
   Capslock & i up::Send {Blind}{Right Up}
   
   
   // Cursor Jumps
   Capslock & u::SendInput {Blind}{Home Down}
   Capslock & u up::SendInput {Blind}{Home Up}
   
   Capslock & k::SendInput {Blind}{End Down}
   Capslock & k up::SendInput {Blind}{End Up}
   
   Capslock & l::SendInput {Blind}{PgUp Down}
   Capslock & l up::SendInput {Blind}{PgUp Up}
   
   Capslock & y::SendInput {Blind}{PgDn Down}
   Capslock & y up::SendInput {Blind}{PgDn Up}
   
   
   // Function Keys
   Capslock & 1::SendInput {Blind}{F1}
   Capslock & 2::SendInput {Blind}{F2}
   Capslock & 3::SendInput {Blind}{F3}
   Capslock & 4::SendInput {Blind}{F4}
   Capslock & 5::SendInput {Blind}{F5}
   Capslock & 6::SendInput {Blind}{F6}
   Capslock & 7::SendInput {Blind}{F7}
   Capslock & 8::SendInput {Blind}{F8}
   Capslock & 9::SendInput {Blind}{F9}
   Capslock & 0::SendInput {Blind}{F10}
   Capslock & -::SendInput {Blind}{F11}
   Capslock & =::SendInput {Blind}{F12}
   
   // TKL Keys
   Capslock & o::SendInput {Blind}{Del}
   Capslock & '::SendInput {Blind}{Ins}
   
   Capslock & ;::SendInput {PrintScreen} Capslock & ]::SendInput {Pause}
   

   // Random
   Capslock & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}
   Capslock & Space::SendInput {Ctrl down}{Space}{Ctrl up}

   CapsLock & j::Run calc.exe
   CapsLock & z::SendInput {AppsKey}
   

#If


#If (pok3r and colemak and ConfKeyboard)
   #Persistent
   SetCapsLockState, AlwaysOff
   
   Capslock::
   Return

   // Unused keys
   RAlt & `::
   RAlt & r::
   RAlt & t::
   RAlt & \::
   RAlt & g::
   RAlt & x::
   RAlt & c::
   RAlt & v::
   RAlt & b::
   RAlt & ,::
   RAlt & .::
   //RAlt & /::  
   RAlt & w::
   RAlt & a::
   RAlt & s::
   RAlt & d::
   
   // Cursor Movement
   RAlt & h::Send {Blind}{Left DownTemp}
   RAlt & h up::Send {Blind}{Left Up}
   
   RAlt & n::Send {Blind}{Down DownTemp}
   RAlt & n up::Send {Blind}{Down Up}
   
   RAlt & e::Send {Blind}{Up DownTemp}
   RAlt & e up::Send {Blind}{Up Up}
   
   RAlt & i::Send {Blind}{Right DownTemp}
   RAlt & i up::Send {Blind}{Right Up}
   
   
   // Cursor Jumps
   RAlt & u::SendInput {Blind}{Home Down}
   RAlt & u up::SendInput {Blind}{Home Up}
   
   RAlt & k::SendInput {Blind}{End Down}
   RAlt & k up::SendInput {Blind}{End Up}
   
   RAlt & l::SendInput {Blind}{PgUp Down}
   RAlt & l up::SendInput {Blind}{PgUp Up}
   
   RAlt & y::SendInput {Blind}{PgDn Down}
   RAlt & y up::SendInput {Blind}{PgDn Up}
   
   
   // Function Keys
   RAlt & 1::SendInput {Blind}{F1}
   RAlt & 2::SendInput {Blind}{F2}
   RAlt & 3::SendInput {Blind}{F3}
   RAlt & 4::SendInput {Blind}{F4}
   RAlt & 5::SendInput {Blind}{F5}
   RAlt & 6::SendInput {Blind}{F6}
   RAlt & 7::SendInput {Blind}{F7}
   RAlt & 8::SendInput {Blind}{F8}
   RAlt & 9::SendInput {Blind}{F9}
   RAlt & 0::SendInput {Blind}{F10}
   RAlt & -::SendInput {Blind}{F11}
   RAlt & =::SendInput {Blind}{F12}
   
   // TKL Keys
   RAlt & o::SendInput {Blind}{Del}
   RAlt & '::SendInput {Blind}{Ins}
   
   RAlt & ;::SendInput {PrintScreen} RAlt & ]::SendInput {Pause}
   

   // Random
   RAlt & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}
   RAlt & Space::SendInput {Ctrl down}{Space}{Ctrl up}

   RAlt & j::Run calc.exe
   RAlt & z::SendInput {RAlt}
   

#If

#If (pok3r and colemak and wasdKeyboard)
   #Persistent
   SetCapsLockState, AlwaysOff
   
   Capslock::
   Return

   // Unused keys
   AppsKey & `::
   AppsKey & r::
   AppsKey & t::
   AppsKey & \::
   AppsKey & g::
   AppsKey & x::
   AppsKey & c::
   AppsKey & v::
   AppsKey & b::
   AppsKey & ,::
   AppsKey & .::
   AppsKey & /::  
   AppsKey & w::
   AppsKey & a::
   AppsKey & s::
   AppsKey & d::
   
   // Cursor Movement
   AppsKey & h::Send {Blind}{Left DownTemp}
   AppsKey & h up::Send {Blind}{Left Up}
   
   AppsKey & n::Send {Blind}{Down DownTemp}
   AppsKey & n up::Send {Blind}{Down Up}
   
   AppsKey & e::Send {Blind}{Up DownTemp}
   AppsKey & e up::Send {Blind}{Up Up}
   
   AppsKey & i::Send {Blind}{Right DownTemp}
   AppsKey & i up::Send {Blind}{Right Up}
   
   
   // Cursor Jumps
   AppsKey & u::SendInput {Blind}{Home Down}
   AppsKey & u up::SendInput {Blind}{Home Up}
   
   AppsKey & k::SendInput {Blind}{End Down}
   AppsKey & k up::SendInput {Blind}{End Up}
   
   AppsKey & l::SendInput {Blind}{PgUp Down}
   AppsKey & l up::SendInput {Blind}{PgUp Up}
   
   AppsKey & y::SendInput {Blind}{PgDn Down}
   AppsKey & y up::SendInput {Blind}{PgDn Up}
   
   
   // Function Keys
   AppsKey & 1::SendInput {Blind}{F1}
   AppsKey & 2::SendInput {Blind}{F2}
   AppsKey & 3::SendInput {Blind}{F3}
   AppsKey & 4::SendInput {Blind}{F4}
   AppsKey & 5::SendInput {Blind}{F5}
   AppsKey & 6::SendInput {Blind}{F6}
   AppsKey & 7::SendInput {Blind}{F7}
   AppsKey & 8::SendInput {Blind}{F8}
   AppsKey & 9::SendInput {Blind}{F9}
   AppsKey & 0::SendInput {Blind}{F10}
   AppsKey & -::SendInput {Blind}{F11}
   AppsKey & =::SendInput {Blind}{F12}
   
   // TKL Keys
   AppsKey & o::SendInput {Blind}{Del}
   AppsKey & '::SendInput {Blind}{Ins}
   
   AppsKey & ;::SendInput {PrintScreen} AppsKey & ]::SendInput {Pause}
   

   // Random
   AppsKey & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}
   AppsKey & Space::SendInput {Ctrl down}{Space}{Ctrl up}

   AppsKey & j::Run calc.exe
   AppsKey & z::SendInput {AppsKey}https://github.com/dhowland/EasyAVR.git
   

#If

//////////////////////////////
//         Colemak          //
//////////////////////////////

// Standard keys
#If (colemak and not pok3r and not normKeyboard and not confKeyboard and (((not WinActive("ahk_exe devenv.exe") and not WinActive("ahk_Class Vim") and not WinActive("ahk_Class VIM") and not WinActive("VIM")) or WinActive("ahk_Class Chrome"))) or colemakAllTime)

   *q::
      sendModifierStates("q")
      Return
   *w::
      sendModifierStates("w")
      Return
   *e::
      sendModifierStates("f")
      Return
   *r::
      sendModifierStates("p")
      Return
   *t::
      sendModifierStates("g")
      Return
   *y::
      sendModifierStates("j")
      Return
   *u::
      sendModifierStates("l")
      Return
   *i::
      sendModifierStates("u")
      Return
   *o::
      sendModifierStates("y")
      Return
   *p::
      sendModifierStates(";")
      Return
   *[::
      sendModifierStates("[")
      Return
   *]::
      sendModifierStates("]")
      Return
   *\::
      sendModifierStates("\")
      Return
   *a::
      sendModifierStates("a")
      Return
   *s::
      sendModifierStates("r")
      Return
   *d::
      sendModifierStates("s")
      Return
   *f::
      sendModifierStates("t")
      Return
   *g::
      sendModifierStates("d")
      Return
   *h::
      sendModifierStates("h")
      Return
   *j::
      sendModifierStates("n")
      Return
   *k::
      sendModifierStates("e")
      Return
   *l::
      sendModifierStates("i")
      Return
   *;::
      sendModifierStates("o")
      Return
   *'::
      sendModifierStates("'")
      Return
   *z::
      sendModifierStates("z")
      Return
   *x::
      sendModifierStates("x")
      Return
   *c::
      sendModifierStates("c")
      Return
   *v::
      sendModifierStates("v")
      Return
   *b::
      sendModifierStates("b")
         Return
   *n::
      sendModifierStates("k")
         Return
   *m::
      sendModifierStates("m")
         Return
   *,::
      sendModifierStates(",")
         Return
   *.::
      sendModifierStates(".")
         Return
   */::
      sendModifierStates("/")
         Return

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

SetColemak:
   colemak = true
   Return

getModifierStates(ByRef AlphaForm = "")
{
    AlphaForm := ""
    
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

    return ReturnValue
}

sendModifierStates(ByRef Key) 
{
      ModifierStates := getModifierStates()
      if GetKeyState("CapsLock", "T") = 1
         ModifierStates .= "+"
      Send, %ModifierStates%{%Key%}
}
