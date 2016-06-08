#CommentFlag //
#InstallKeybdHook
#NoEnv 
SendMode Input 
SetTitleMatchMode 3  

SetDefaultMouseSpeed, 0

Suspend
//Pause,,1

+Pause::
   Suspend
   //Pause,,1
Return

!Pause::
   Reload
Return

//////////////////////////////
//      Set Variables       //
//////////////////////////////

pok3r:=false
>#,::
>!,::
   pok3r:=not pok3r
Return

colemak:=true
>#/::
>!/::
   colemak:=not colemak
Return

normKeyboard:=false
RAlt & Scrolllock::
   normKeyboard:=not normKeyboard
Return

!+w::
   WinGetClass, Title, A
   MsgBox, The active window is "%Title%"
Return

IncrementValue = 5
MouseDelay = 0

//////////////////////////////
//    Swap LCtrl & LWin     //
//////////////////////////////

#If (normKeyboard)
   LWin::LCtrl
   LCtrl::LWin
   Rwin::Appskey
   Appskey::RWin
#If

//////////////////////////////
//        Capslock          //
//////////////////////////////

#If (not pok3r and not WinActive("ahk_Class Vim"))

   Capslock::
      SendInput {Blind}{Backspace DownTemp}
      SendInput {Blind}{Backspace Up}
   Return
#If

//////////////////////////////
//         Pok3r            //
//////////////////////////////

#if (pok3r and not colemak and not WinActive("ahk_Class Vim"))
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

#If (pok3r and not WinActive("ahk_Class Vim"))

   // CapsLock behavior
   >!Capslock:
   If GetKeyState("CapsLock", "T") = 1
       SetCapsLockState, AlwaysOff
   Else 
       SetCapsLockState, AlwaysOn
   Return

#If


#If (pok3r and colemak and not WinActive("ahk_Class Vim"))
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
   Capslock & o::SendInput {Del Down}
   Capslock & o up::SendInput {Del Up}
   
   Capslock & '::SendInput {Ins Down}
   Capslock & ' up::SendInput {Ins Up}
   
   Capslock & ;::SendInput {PrintScreen}
   Capslock & ]::SendInput {Pause}
   

   // Random
   Capslock & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}
   Capslock & Space::SendInput {Ctrl down}{Space}{Ctrl up}

   CapsLock & j::Run calc.exe
   CapsLock & z::SendInput {AppsKey}
   

#If

//////////////////////////////
//         Colemak          //
//////////////////////////////


#If (colemak and not pok3r and not WinActive("ahk_Class Vim"))

   e::SendInput {Blind}{f Down}{f Up}
   r::SendInput {Blind}{p Down}{p Up}
   t::SendInput {Blind}{g Down}{g Up}
   y::SendInput {Blind}{j Down}{j Up}
   u::SendInput {Blind}{l Down}{l Up}
   i::SendInput {Blind}{u Down}{u Up}
   o::SendInput {Blind}{y Down}{y Up}
   p::SendInput {Blind}{; Down}{; Up}
   s::SendInput {Blind}{r Down}{r Up}
   d::SendInput {Blind}{s Down}{s Up}
   f::SendInput {Blind}{t Down}{t Up}
   g::SendInput {Blind}{d Down}{d Up}
   j::SendInput {Blind}{n Down}{n Up}
   k::SendInput {Blind}{e Down}{e Up}
   l::SendInput {Blind}{i Down}{i Up}
   ;::SendInput {Blind}{o Down}{o Up}
   n::SendInput {Blind}{k Down}{k Up}

   +e::SendInput {Blind}{F Down}{F Up}
   +r::SendInput {Blind}{P Down}{P Up}
   +t::SendInput {Blind}{G Down}{G Up}
   +y::SendInput {Blind}{J Down}{J Up}
   +u::SendInput {Blind}{L Down}{L Up}
   +i::SendInput {Blind}{U Down}{U Up}
   +o::SendInput {Blind}{Y Down}{Y Up}
   +p::SendInput {Blind}{: Down}{: Up}
   +s::SendInput {Blind}{R Down}{R Up}
   +d::SendInput {Blind}{S Down}{S Up}
   +f::SendInput {Blind}{T Down}{T Up}
   +g::SendInput {Blind}{D Down}{D Up}
   +j::SendInput {Blind}{N Down}{N Up}
   +k::SendInput {Blind}{E Down}{E Up}
   +l::SendInput {Blind}{I Down}{I Up}
   +;::SendInput {Blind}{O Down}{O Up}
   +n::SendInput {Blind}{K Down}{K Up}

#If
