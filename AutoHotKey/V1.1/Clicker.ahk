#CommentFlag //
#InstallKeybdHook
#NoEnv 
#MaxHotkeysPerInterval 1000
SendMode Input 
SetTitleMatchMode, 2
SetTitleMatchMode, slow

//////////////////////////////
//          Mouse           //
//////////////////////////////

count := 0
j := 412
time := 2500

<!Space::
   BlockInput, MouseMove
   Loop, %j% {
      if (BreakLoop = 1)
         break
      Click
      total := time * (j - count)

      count := count + 1

      minutes := Floor((total / 1000) / 60)
      seconds := Round(Mod((total / 1000), 60), 1)

      ToolTip, %count% / %j% -- %minutes%m %seconds%s
      SetTimer, RemoveToolTip, 2100
      Sleep, %time%
   }
   BreakLoop = 0
   BlockInput, MouseMoveOff
   Return

<^<!Space::
   BlockInput, MouseMoveOff
   Return

>^<!Space::
   BlockInput, MouseMove
   Return

^Esc::
   BreakLoop = 1
   Return

RemoveToolTip:
   SetTimer, RemoveToolTip, Off
   ToolTip
   Return

