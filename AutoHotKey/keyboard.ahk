#CommentFlag // 

#InstallKeybdHook
#NoEnv 
#MaxHotkeysPerInterval 1000
SendMode Input 
SetTitleMatchMode, 2
SetTitleMatchMode, slow

//////////////////////////////
//         Includes         //
//////////////////////////////

//////////////////////////////
//      Set Variables       //
//////////////////////////////

colemak        := false
colemakAllTime := false
wasdKeyboard   := false
confKeyboard   := false
normKeyboard   := false
pok3r          := false
pok3rcolemak   := false
ModifierStates := ""
printScreen    := false
changeCapslock := false
montsinger     := false
montsingerVol  := false

//////////////////////////////
//       Run Scripts        //
//////////////////////////////


//////////////////////////////
//          LEDs            //
//////////////////////////////
if (colemak or colemakAllTIme) {
   KeyboardLED(4, "on",  3)
} Else {
   KeyboardLED(4, "off", 3)
}

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

//+Pause::
   //Suspend
   //Pause,,1
//Return

//<!Pause::
   //Reload
//Return

!/::
   colemak:=not colemak
   if (colemak) {
      colemakAllTime := false
   }
   if (colemak or colemakAllTIme) {
      KeyboardLED(4, "on",  3)
   } Else {
      KeyboardLED(4, "off", 3)
   }
Return

!.::
   if (colemak or colemakAllTime) {
       pok3rcolemak := not pok3rcolemak
       pok3r := false
   } Else {
       pok3r := not pok3r
       pok3rcolemak := false
   }
Return

!?::
   colemakAllTime := not colemakAllTime
   if (colemakAllTime) {
      colemak := false
   }
   if (colemak or colemakAllTIme) {
      KeyboardLED(4, "on",  3)
   } Else {
      KeyboardLED(4, "off", 3)
   }
Return

#If (colemak or colemakAllTime) 
   #!r::
      printScreen := not printScreen
   return
   #!+r::
      printScreen := false
   return
#If

#If (not (colemak or colemakAllTime))
   #!p::
      printScreen := not printScreen
   return
   #!+p::
      printScreen := false
   return
#If

#If (printScreen) 
   <+Space::SendInput {PrintScreen}
#If

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

//+Right::+Insert{{

<#Space:: Send, ^``

//<!j::AltTab
//<!k::ShiftAltTab


//////////////////////////////
//        Mulitmedia        //
//////////////////////////////

^Volume_Mute::
   Send {Media_Play_Pause}
Return

^Volume_Down::
   Send {Media_Prev}
Return

^Volume_Up::
   Send {Media_Next}
Return


//////////////////////////////
//      Mouse Simulate      //
//////////////////////////////

F24::
   MouseClick, Left
Return

>+F24::
   MouseClick, Right
Return


//////////////////////////////
//    Montsinger Rebound    //
//////////////////////////////

<^<!F24::
   montsinger:=not montsinger
Return

<+<!F24::
   montsingerVol:=not montsingerVol
Return

#If (montsinger)
   !Esc::
      Return

   #If (montsingerVol)
      F14::
         Send {Volume_Down}
      Return

      F15::
         Send {Volume_Up}
      Return
   #If
#If

//////////////////////////////
//    Swap LCtrl & LWin     //
//////////////////////////////

//#If (wasdKeyboard or normKeyboard)
//   LWin::LCtrl
//   LCtrl::LWin
//   Rwin::Appskey
//   Appskey::RWin
//#If


//#if (confKeyboard)
//   LWin::LCtrl
//   LCtrl::LWIn
   
//#if

//////////////////////////////
//        Capslock          //
//////////////////////////////

^!+F12::
   changeCapslock := not changeCapslock
Return

#If  (changeCapslock)
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
#If

   

//   <#+Backspace:: 
//      SendInput {Blind}{Capslock}
//      Loop, 20 {
//         KeyboardLED(4, "on",  3)
//         Sleep 100
//         KeyboardLED(4, "off",  3)
//         Sleep 100
//      }
//      Loop, 20 {
//         KeyboardLED(4, "switch",  3)
//         Sleep 250
//      }
//      Return


//////////////////////////////
//         Win Lock         //
//////////////////////////////
#If (true)

   #,::RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 0
   
   #.::RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 1
   
   #l::
      Return

   <#+q:: 
      {
         RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 0
         DllCall("LockWorkStation")
         sleep, 1000
         RegWrite, REG_DWORD, HKEY_CURRENT_USER, Software\Microsoft\Windows\CurrentVersion\Policies\System, DisableLockWorkstation, 1
      }
      Return

#If


//////////////////////////////
//           Plex           //
//////////////////////////////

#IfWinActive Plex
{

   ^Left::^B
   ^Right::^F

}

//////////////////////////////
//         pok3r            //
//////////////////////////////

#If (pok3rColemak and not pok3r) 
   !Space::!Space
   !#Space::#Space
   !^Space::^Space
   !+Space::+Space
   +Space::+Space
   ^Space::^Space
   ^+Space::+Space

   $Space::
      KeyWait, Space, T0.5
      If ErrorLevel {
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
	 Space & }::SendInput {Break}
         

         // Random
         Space & Enter::SendInput {Ctrl down}{Enter}{Ctrl up}

         Space & y::Run calc.exe

         Space & z::
            If GetKeyState("Shift","p")
               SendInput {Shift Down}{AppsKey}{Shift Up}
            Else
               SendInput {AppsKey}
            Return
      } Else {
         sendModifierStates(" ")
      }
   Return

#If

#If (pok3r and not pok3rColemak) 
   !Space::!Space
   !#Space::#Space
   !^Space::^Space
   !+Space::+Space
   +Space::+Space
   ^Space::^Space
   ^+Space::+Space

   $Space::
      KeyWait, Space, T0.5
      If ErrorLevel {
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

         Space & z::
            If GetKeyState("Shift","p")
               SendInput {Shift Down}{AppsKey}{Shift Up}
            Else
               SendInput {AppsKey}
            Return
      } Else {
         sendModifierStates(" ")
      }
   Return

#If

#If (WinActive("ahk_exe devenv.exe"))
  +F8::
      SendInput {Blind}{Ctrl down}{Shift down}{B}{Shift up}{Ctrl up}
      Return
#If

//////////////////////////////
//         Colemak          //
//////////////////////////////

If (colemak or colemakAllTime) {
   <!<+f::
      SendInput {Blind}{Alt down}{F4}{Alt up}
      Return
} else {
   <!<+t::
      SendInput {Blind}{Alt down}{F4}{Alt up}
      Return
}

#If ((WinActive("ahk_exe devenv.exe") or WinActive("ahk_Class Vim") or WinActive("ahk_Class VIM") or WinActive("VIM")) and not colemakAllTime)
   *q::
      sendModifierStates("q")
      Return
   *w::
      sendModifierStates("w")
      Return
   *e::
      sendModifierStates("e")
      Return
   *r::
      sendModifierStates("r")
      Return
   *t::
      sendModifierStates("t")
      Return
   *y::
      sendModifierStates("y")
      Return
   *u::
      sendModifierStates("u")
      Return
   *i::
      sendModifierStates("i")
      Return
   *o::
      sendModifierStates("o")
      Return
   *p::
      sendModifierStates("p")
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
      sendModifierStates("s")
      Return
   *d::
      sendModifierStates("d")
      Return
   *f::
      sendModifierStates("f")
      Return
   *g::
      sendModifierStates("g")
      Return
   *h::
      sendModifierStates("h")
      Return
   *j::
      sendModifierStates("j")
      Return
   *k::
      sendModifierStates("k")
      Return
   *l::
      sendModifierStates("l")
      Return
   *;::
      sendModifierStates(";")
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
      sendModifierStates("n")
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

#If


/////////////////////////////
//       Sub-Routines      //
/////////////////////////////

getModifierStates(ByRef AlphaForm := "")
{
   AlphaForm := ""
   
   //if (confKeyboard) {
//
  //    if GetKeyState("LWin", "P") || GetKeyState("RWin", "P")
    //  {
      //   ReturnValue .= "^"
        // AlphaForm .= "C"
     // }

//      if GetKeyState("LCtrl", "P")
  //    {
    //     ReturnValue .= "#"
      //   AlphaForm .= "W"
      //}

//      if GetkeyState("RCtrl", "P")
  //    {
    //     ReturnValue .= "^"
      //      AlphaForm .= "C"
      //}

//   } Else {

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
//   }

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
      //MsgBox, The active key is "%ModifierStates% - %Key%"
      If (Key = " ")
         Send, %ModifierStates%{Space}
      Else
         Send, %ModifierStates%{%Key%}
      sleep 50
}


KeyboardLED(LEDvalue, Cmd, Kbd=3)
{
  SetUnicodeStr(fn,"\Device\KeyBoardClass" Kbd)
  h_device:=NtCreateFile(fn,0+0x00000100+0x00000080+0x00100000,1,1,0x00000040+0x00000020,0)

  If Cmd= switch  //;switches every LED according to LEDvalue
   KeyLED:= LEDvalue
  If Cmd= on  //;forces all choosen LED's to ON (LEDvalue= 0 ->LED's according to keystate)
   KeyLED:= LEDvalue | (GetKeyState("ScrollLock", "T") + 2*GetKeyState("NumLock", "T") + 4*GetKeyState("CapsLock", "T"))
  If Cmd= off  //;forces all choosen LED's to OFF (LEDvalue= 0 ->LED's according to keystate)
    {
    LEDvalue:= LEDvalue ^ 7
    KeyLED:= LEDvalue & (GetKeyState("ScrollLock", "T") + 2*GetKeyState("NumLock", "T") + 4*GetKeyState("CapsLock", "T"))
    }

  success := DllCall( "DeviceIoControl"
              ,  "ptr", h_device
              , "uint", CTL_CODE( 0x0000000b     //; FILE_DEVICE_KEYBOARD
                        , 2
                        , 0             //; METHOD_BUFFERED
                        , 0  )          //; FILE_ANY_ACCESS
              , "int*", KeyLED << 16
              , "uint", 4
              ,  "ptr", 0
              , "uint", 0
              ,  "ptr*", output_actual
              ,  "ptr", 0 )

  NtCloseFile(h_device)
  return success
}

CTL_CODE( p_device_type, p_function, p_method, p_access )
{
  Return, ( p_device_type << 16 ) | ( p_access << 14 ) | ( p_function << 2 ) | p_method
}


NtCreateFile(ByRef wfilename,desiredaccess,sharemode,createdist,flags,fattribs)
{
  VarSetCapacity(objattrib,6*A_PtrSize,0)
  VarSetCapacity(io,2*A_PtrSize,0)
  VarSetCapacity(pus,2*A_PtrSize)
  DllCall("ntdll\RtlInitUnicodeString","ptr",&pus,"ptr",&wfilename)
  NumPut(6*A_PtrSize,objattrib,0)
  NumPut(&pus,objattrib,2*A_PtrSize)
  status:=DllCall("ntdll\ZwCreateFile","ptr*",fh,"UInt",desiredaccess,"ptr",&objattrib
                  ,"ptr",&io,"ptr",0,"UInt",fattribs,"UInt",sharemode,"UInt",createdist
                  ,"UInt",flags,"ptr",0,"UInt",0, "UInt")
  return % fh
}

NtCloseFile(handle)
{
  return DllCall("ntdll\ZwClose","ptr",handle)
}


SetUnicodeStr(ByRef out, str_)
{
  VarSetCapacity(out,2*StrPut(str_,"utf-16"))
  StrPut(str_,&out,"utf-16")
}
