#CommentFlag //
#InstallKeybdHook
#NoEnv 
SendMode Input 
SetTitleMatchMode, 2
SetTitleMatchMode, slow


^!p::
   ppmNumber := Trim(clipboard)
   if !(isValidPpmLog(ppmNumber)) {
      InputBox, ppmNumber, Enter PPM Log Number, Please enter your seven digit PPM Log number.
      ppmNumber := Trim(ppmNumber)
   }
   if (isValidPpmLog(ppmNumber)) {
      Run, "https://portal.insurity.com/itg/web/knta/crt/RequestDetail.jsp?REQUEST_ID=%ppmNumber%"
   } else {
      MsgBox, Bad input "%ppmNumber%"
   }
Return

+!p::
   ppmNumber := Trim(clipboard)
   if !(isValidPpmLog(ppmNumber)) {
      InputBox, ppmNumber, Enter PPM Log Number, Please enter your seven digit PPM Log number.
      ppmNumber := Trim(ppmNumber)
   }
   if (isValidPpmLog(ppmNumber)) {
      Run, "http://HFDKTIMINSW7D/PPMRequestAPI/api/RequestValues/%ppmNumber%"
   } else {
      MsgBox, Bad input "%ppmNumber%"
   }
Return

isValidPpmLog(logNum) {
   if (isVarType(logNum, "integer") && StrLen(logNum) = 7)
      return True
}

isVarType(var, type) {
   if var is %type%
      return True
}
