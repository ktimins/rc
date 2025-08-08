#CommentFlag //
#InstallKeybdHook
#NoEnv 
SendMode Input 

pok3r:=false
!+/::
>+Backspace::
   pok3r:=not pok3r
Return

normKeyboard:=true
RAlt & Scrolllock::
   normKeyboard:=not normKeyboard
Return


#If (normKeyboard)
   LWin::LCtrl
   LCtrl::LWin
   RWin::Appskey
   Appskey::RWin
   >!Space::Capslock
#If


#If (not pok3r)
   Capslock::
      SendInput {Blind}{Backspace DownTemp}
      SendInput {Blind}{Backspace Up}
   Return
   SetScrollLockState, off
#If


#If (pok3r)
   #Persistent
   SetCapsLockState, AlwaysOff
   SetScrollLockState, on

   // CapsLock behavior
   >!Capslock:
   If GetKeyState("CapsLock", "T") = 1
       SetCapsLockState, AlwaysOff
   Else 
       SetCapsLockState, AlwaysOn
   Return

   Backspace::
   Return
   
   // Unused keys
   Backspace & `::
   Backspace & r::
   Backspace & t::
   Backspace & \::
   Backspace & g::
   Backspace & x::
   Backspace & c::
   Backspace & v::
   Backspace & b::
   Backspace & ,::
   Backspace & .::
   Backspace & /::  
   Backspace & w::
   Backspace & a::
   Backspace & s::
   Backspace & d::
   
   // Cursor Movement
   Backspace & h::Send {Blind}{Left DownTemp}
   Backspace & h up::Send {Blind}{Left Up}
   
   Backspace & n::Send {Blind}{Down DownTemp}
   Backspace & n up::Send {Blind}{Down Up}
   
   Backspace & e::Send {Blind}{Up DownTemp}
   Backspace & e up::Send {Blind}{Up Up}
   
   Backspace & i::Send {Blind}{Right DownTemp}
   Backspace & i up::Send {Blind}{Right Up}
   
   
   // Cursor Jumps
   Backspace & u::SendInput {Blind}{Home Down}
   Backspace & u up::SendInput {Blind}{Home Up}
   
   Backspace & k::SendInput {Blind}{End Down}
   Backspace & k up::SendInput {Blind}{End Up}
   
   Backspace & l::SendInput {Blind}{PgUp Down}
   Backspace & l up::SendInput {Blind}{PgUp Up}
   
   Backspace & y::SendInput {Blind}{PgDn Down}
   Backspace & y up::SendInput {Blind}{PgDn Up}
   
   
   // Function Keys
   Backspace & 1::SendInput {Blind}{F1}
   Backspace & 2::SendInput {Blind}{F2}
   Backspace & 3::SendInput {Blind}{F3}
   Backspace & 4::SendInput {Blind}{F4}
   Backspace & 5::SendInput {Blind}{F5}
   Backspace & 6::SendInput {Blind}{F6}
   Backspace & 7::SendInput {Blind}{F7}
   Backspace & 8::SendInput {Blind}{F8}
   Backspace & 9::SendInput {Blind}{F9}
   Backspace & 0::SendInput {Blind}{F10}
   Backspace & -::SendInput {Blind}{F11}
   Backspace & =::SendInput {Blind}{F12}
   
   // TKL Keys
   Backspace & o::SendInput {Del Down}
   Backspace & o up::SendInput {Del Up}
   
   Backspace & '::SendInput {Ins Down}
   Backspace & ' up::SendInput {Ins Up}
   
   Backspace & ;::SendInput {PrintScreen}
   Backspace & ]::SendInput {Pause}
   

   // Random
   Backspace & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}
   Backspace & Space::SendInput {Ctrl down}{Space}{Ctrl up}

   Backspace & j::Run calc.exe
   Backspace & z::SendInput {AppsKey}
   

#If

