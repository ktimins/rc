enablePrintScreen := false

<^!Space::
   enablePrintScreen := not enablePrintScreen
   Return

#If (enablePrintScreen)
   +Space::SendInput {PrintScreen}
#If
