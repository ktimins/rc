^!p::
   InputBox, ppmNumber, Enter PPM Log Number, Please enter your seven digit PPM Log number.
   if (isVarType(ppmNumber, "integer") && StrLen(ppmNumber) = 7) {
      Run, "https://portal.insurity.com/itg/web/knta/crt/RequestDetail.jsp?REQUEST_ID=%ppmNumber%"
   } else {
      MsgBox, Bad input "%ppmNumber%"
   }
Return

isVarType(var, type) {
   if var is %type%
      return True
}
