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

#If (wasdKeyboard or confKeyboard)
   LWin::LCtrl
   LCtrl::LWin
   Rwin::Appskey
   Appskey::RWin
#If

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

   // Normal
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
   q::SendInput {Blind}{q Down}{q Up}
   w::SendInput {Blind}{w Down}{w Up}
   [::SendInput {Blind}{[ Down}{[ Up}
   ]::SendInput {Blind}{] Down}{] Up}
   \::SendInput {Blind}{\ Down}{\ Up}
   a::SendInput {Blind}{a Down}{a Up}
   h::SendInput {Blind}{h Down}{h Up}
   '::SendInput {Blind}{' Down}{' Up}
   z::SendInput {Blind}{z Down}{z Up}
   x::SendInput {Blind}{x Down}{x Up}
   c::SendInput {Blind}{c Down}{c Up}
   v::SendInput {Blind}{v Down}{v Up}
   b::SendInput {Blind}{b Down}{b Up}
   m::SendInput {Blind}{m Down}{m Up}
   ,::SendInput {Blind}{, Down}{, Up}
   .::SendInput {Blind}{. Down}{. Up}
   /::SendInput {Blind}{/ Down}{/ Up}

   // Shift
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
   +q::SendInput {Blind}{Q Down}{Q Up}
   +w::SendInput {Blind}{W Down}{W Up}
   +[::SendInput {Blind}{[ Down}{[ Up}
   +]::SendInput {Blind}{] Down}{] Up}
   +\::SendInput {Blind}{| Down}{| Up}
   +a::SendInput {Blind}{A Down}{A Up}
   +h::SendInput {Blind}{H Down}{H Up}
   +'::SendInput {Blind}{" Down}{" Up}
   +z::SendInput {Blind}{Z Down}{Z Up}
   +x::SendInput {Blind}{X Down}{X Up}
   +c::SendInput {Blind}{C Down}{C Up}
   +v::SendInput {Blind}{V Down}{V Up}
   +b::SendInput {Blind}{B Down}{B Up}
   +m::SendInput {Blind}{M Down}{M Up}
   +,::SendInput {Blind}{< Down}{< Up}
   +.::SendInput {Blind}{> Down}{> Up}
   +/::SendInput {Blind}{? Down}{? Up}

   <+Esc::SendInput {Blind}{~ Down}{~ Up}
   >+Esc::SendInput {Blind}{` Down}{` Up}

   // Shift + Alt
   +!e::SendInput {Blind}{Shift Down}{Alt Down}{f Down}{f Up}{Alt Up}{Shift Up}
   +!r::SendInput {Blind}{Shift Down}{Alt Down}{p Down}{p Up}{Alt Up}{Shift Up}
   +!t::SendInput {Blind}{Shift Down}{Alt Down}{g Down}{g Up}{Alt Up}{Shift Up}
   +!y::SendInput {Blind}{Shift Down}{Alt Down}{j Down}{j Up}{Alt Up}{Shift Up}
   +!u::SendInput {Blind}{Shift Down}{Alt Down}{l Down}{l Up}{Alt Up}{Shift Up}
   +!i::SendInput {Blind}{Shift Down}{Alt Down}{u Down}{u Up}{Alt Up}{Shift Up}
   +!o::SendInput {Blind}{Shift Down}{Alt Down}{y Down}{y Up}{Alt Up}{Shift Up}
   +!p::SendInput {Blind}{Shift Down}{Alt Down}{; Down}{; Up}{Alt Up}{Shift Up}
   +!s::SendInput {Blind}{Shift Down}{Alt Down}{r Down}{r Up}{Alt Up}{Shift Up}
   +!d::SendInput {Blind}{Shift Down}{Alt Down}{s Down}{s Up}{Alt Up}{Shift Up}
   +!f::SendInput {Blind}{Shift Down}{Alt Down}{t Down}{t Up}{Alt Up}{Shift Up}
   +!g::SendInput {Blind}{Shift Down}{Alt Down}{d Down}{d Up}{Alt Up}{Shift Up}
   +!j::SendInput {Blind}{Shift Down}{Alt Down}{n Down}{n Up}{Alt Up}{Shift Up}
   +!k::SendInput {Blind}{Shift Down}{Alt Down}{e Down}{e Up}{Alt Up}{Shift Up}
   +!l::SendInput {Blind}{Shift Down}{Alt Down}{i Down}{i Up}{Alt Up}{Shift Up}
   +!;::SendInput {Blind}{Shift Down}{Alt Down}{o Down}{o Up}{Alt Up}{Shift Up}
   +!n::SendInput {Blind}{Shift Down}{Alt Down}{k Down}{k Up}{Alt Up}{Shift Up}

   // Shift + Alt + Ctrl
   +!^e::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{f Down}{f Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^r::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{p Down}{p Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^t::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{g Down}{g Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^y::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{j Down}{j Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^u::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{l Down}{l Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^i::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{u Down}{u Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^o::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{y Down}{y Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^p::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{; Down}{; Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^s::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{r Down}{r Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^d::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{s Down}{s Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^f::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{t Down}{t Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^g::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{d Down}{d Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^j::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{n Down}{n Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^k::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{e Down}{e Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^l::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{i Down}{i Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^;::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{o Down}{o Up}{Ctrl Up}{Alt Up}{Shift Up}
   +!^n::SendInput  {Blind}{Shift Down}{Alt Down}{Ctrl Down}{k Down}{k Up}{Ctrl Up}{Alt Up}{Shift Up}
   
   // Shift + Ctrl
   +^e::SendInput {Blind}{Shift Down}{Ctrl Down}{f Down}{f Up}{Ctrl Up}{Shift Up}
   +^r::SendInput {Blind}{Shift Down}{Ctrl Down}{p Down}{p Up}{Ctrl Up}{Shift Up}
   +^t::SendInput {Blind}{Shift Down}{Ctrl Down}{g Down}{g Up}{Ctrl Up}{Shift Up}
   +^y::SendInput {Blind}{Shift Down}{Ctrl Down}{j Down}{j Up}{Ctrl Up}{Shift Up}
   +^u::SendInput {Blind}{Shift Down}{Ctrl Down}{l Down}{l Up}{Ctrl Up}{Shift Up}
   +^i::SendInput {Blind}{Shift Down}{Ctrl Down}{u Down}{u Up}{Ctrl Up}{Shift Up}
   +^o::SendInput {Blind}{Shift Down}{Ctrl Down}{y Down}{y Up}{Ctrl Up}{Shift Up}
   +^p::SendInput {Blind}{Shift Down}{Ctrl Down}{; Down}{; Up}{Ctrl Up}{Shift Up}
   +^s::SendInput {Blind}{Shift Down}{Ctrl Down}{r Down}{r Up}{Ctrl Up}{Shift Up}
   +^d::SendInput {Blind}{Shift Down}{Ctrl Down}{s Down}{s Up}{Ctrl Up}{Shift Up}
   +^f::SendInput {Blind}{Shift Down}{Ctrl Down}{t Down}{t Up}{Ctrl Up}{Shift Up}
   +^g::SendInput {Blind}{Shift Down}{Ctrl Down}{d Down}{d Up}{Ctrl Up}{Shift Up}
   +^j::SendInput {Blind}{Shift Down}{Ctrl Down}{n Down}{n Up}{Ctrl Up}{Shift Up}
   +^k::SendInput {Blind}{Shift Down}{Ctrl Down}{e Down}{e Up}{Ctrl Up}{Shift Up}
   +^l::SendInput {Blind}{Shift Down}{Ctrl Down}{i Down}{i Up}{Ctrl Up}{Shift Up}
   +^;::SendInput {Blind}{Shift Down}{Ctrl Down}{o Down}{o Up}{Ctrl Up}{Shift Up}
   +^n::SendInput {Blind}{Shift Down}{Ctrl Down}{k Down}{k Up}{Ctrl Up}{Shift Up}

   // Alt
   !e::SendInput {Blind}{Alt Down}{f Down}{f Up}{Alt Up}
   !r::SendInput {Blind}{Alt Down}{p Down}{p Up}{Alt Up}
   !t::SendInput {Blind}{Alt Down}{g Down}{g Up}{Alt Up}
   !y::SendInput {Blind}{Alt Down}{j Down}{j Up}{Alt Up}
   !u::SendInput {Blind}{Alt Down}{l Down}{l Up}{Alt Up}
   !i::SendInput {Blind}{Alt Down}{u Down}{u Up}{Alt Up}
   !o::SendInput {Blind}{Alt Down}{y Down}{y Up}{Alt Up}
   !p::SendInput {Blind}{Alt Down}{; Down}{; Up}{Alt Up}
   !s::SendInput {Blind}{Alt Down}{r Down}{r Up}{Alt Up}
   !d::SendInput {Blind}{Alt Down}{s Down}{s Up}{Alt Up}
   !f::SendInput {Blind}{Alt Down}{t Down}{t Up}{Alt Up}
   !g::SendInput {Blind}{Alt Down}{d Down}{d Up}{Alt Up}
   !j::SendInput {Blind}{Alt Down}{n Down}{n Up}{Alt Up}
   !k::SendInput {Blind}{Alt Down}{e Down}{e Up}{Alt Up}
   !l::SendInput {Blind}{Alt Down}{i Down}{i Up}{Alt Up}
   !;::SendInput {Blind}{Alt Down}{o Down}{o Up}{Alt Up}
   !n::SendInput {Blind}{Alt Down}{k Down}{k Up}{Alt Up}

   // Alt + Ctrl
   !^e::SendInput {Blind}{Alt Down}{Ctrl Down}{f Down}{f Up}{Ctrl Up}{Alt Up}
   !^r::SendInput {Blind}{Alt Down}{Ctrl Down}{p Down}{p Up}{Ctrl Up}{Alt Up}
   !^t::SendInput {Blind}{Alt Down}{Ctrl Down}{g Down}{g Up}{Ctrl Up}{Alt Up}
   !^y::SendInput {Blind}{Alt Down}{Ctrl Down}{j Down}{j Up}{Ctrl Up}{Alt Up}
   !^u::SendInput {Blind}{Alt Down}{Ctrl Down}{l Down}{l Up}{Ctrl Up}{Alt Up}
   !^i::SendInput {Blind}{Alt Down}{Ctrl Down}{u Down}{u Up}{Ctrl Up}{Alt Up}
   !^o::SendInput {Blind}{Alt Down}{Ctrl Down}{y Down}{y Up}{Ctrl Up}{Alt Up}
   !^p::SendInput {Blind}{Alt Down}{Ctrl Down}{; Down}{; Up}{Ctrl Up}{Alt Up}
   !^s::SendInput {Blind}{Alt Down}{Ctrl Down}{r Down}{r Up}{Ctrl Up}{Alt Up}
   !^d::SendInput {Blind}{Alt Down}{Ctrl Down}{s Down}{s Up}{Ctrl Up}{Alt Up}
   !^f::SendInput {Blind}{Alt Down}{Ctrl Down}{t Down}{t Up}{Ctrl Up}{Alt Up}
   !^g::SendInput {Blind}{Alt Down}{Ctrl Down}{d Down}{d Up}{Ctrl Up}{Alt Up}
   !^j::SendInput {Blind}{Alt Down}{Ctrl Down}{n Down}{n Up}{Ctrl Up}{Alt Up}
   !^k::SendInput {Blind}{Alt Down}{Ctrl Down}{e Down}{e Up}{Ctrl Up}{Alt Up}
   !^l::SendInput {Blind}{Alt Down}{Ctrl Down}{i Down}{i Up}{Ctrl Up}{Alt Up}
   !^;::SendInput {Blind}{Alt Down}{Ctrl Down}{o Down}{o Up}{Ctrl Up}{Alt Up}
   !^n::SendInput {Blind}{Alt Down}{Ctrl Down}{k Down}{k Up}{Ctrl Up}{Alt Up}

   // Ctrl
   ^e::SendInput {Blind}{Ctrl Down}{f Down}{f Up}{Ctrl Up}
   ^r::SendInput {Blind}{Ctrl Down}{p Down}{p Up}{Ctrl Up}
   ^t::SendInput {Blind}{Ctrl Down}{g Down}{g Up}{Ctrl Up}
   ^y::SendInput {Blind}{Ctrl Down}{j Down}{j Up}{Ctrl Up}
   ^u::SendInput {Blind}{Ctrl Down}{l Down}{l Up}{Ctrl Up}
   ^i::SendInput {Blind}{Ctrl Down}{u Down}{u Up}{Ctrl Up}
   ^o::SendInput {Blind}{Ctrl Down}{y Down}{y Up}{Ctrl Up}
   ^p::SendInput {Blind}{Ctrl Down}{; Down}{; Up}{Ctrl Up}
   ^s::SendInput {Blind}{Ctrl Down}{r Down}{r Up}{Ctrl Up}
   ^d::SendInput {Blind}{Ctrl Down}{s Down}{s Up}{Ctrl Up}
   ^f::SendInput {Blind}{Ctrl Down}{t Down}{t Up}{Ctrl Up}
   ^g::SendInput {Blind}{Ctrl Down}{d Down}{d Up}{Ctrl Up}
   ^j::SendInput {Blind}{Ctrl Down}{n Down}{n Up}{Ctrl Up}
   ^k::SendInput {Blind}{Ctrl Down}{e Down}{e Up}{Ctrl Up}
   ^l::SendInput {Blind}{Ctrl Down}{i Down}{i Up}{Ctrl Up}
   ^;::SendInput {Blind}{Ctrl Down}{o Down}{o Up}{Ctrl Up}
   ^n::SendInput {Blind}{Ctrl Down}{k Down}{k Up}{Ctrl Up}

   // Left Win
   <#e::SendInput {Blind}{Win Down}{f Down}{f Up}{Win Up}
   <#r::SendInput {Blind}{Win Down}{p Down}{p Up}{Win Up}
   <#t::SendInput {Blind}{Win Down}{g Down}{g Up}{Win Up}
   <#y::SendInput {Blind}{Win Down}{j Down}{j Up}{Win Up}
   <#u::SendInput {Blind}{Win Down}{l Down}{l Up}{Win Up}
   <#i::SendInput {Blind}{Win Down}{u Down}{u Up}{Win Up}
   <#o::SendInput {Blind}{Win Down}{y Down}{y Up}{Win Up}
   <#p::SendInput {Blind}{Win Down}{; Down}{; Up}{Win Up}
   <#s::SendInput {Blind}{Win Down}{r Down}{r Up}{Win Up}
   <#d::SendInput {Blind}{Win Down}{s Down}{s Up}{Win Up}
   <#f::SendInput {Blind}{Win Down}{t Down}{t Up}{Win Up}
   <#g::SendInput {Blind}{Win Down}{d Down}{d Up}{Win Up}
   <#j::SendInput {Blind}{Win Down}{n Down}{n Up}{Win Up}
   <#k::SendInput {Blind}{Win Down}{e Down}{e Up}{Win Up}
   <#l::SendInput {Blind}{Win Down}{i Down}{i Up}{Win Up}
   <#;::SendInput {Blind}{Win Down}{o Down}{o Up}{Win Up}
   <#n::SendInput {Blind}{Win Down}{k Down}{k Up}{Win Up}

   // Right Win
   >#e::
   >#r::
   >#t::
   >#y::
   >#u::
   >#i::
   >#o::
   >#p::
   >#s::
   >#d::
   >#f::
   >#g::
   >#j::
   >#k::
   >#l::
   >#;::
   >#n::
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
