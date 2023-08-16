CapsLock::
   SendInput {Blind}{F23 down}
   Return

CapsLock up::
   SendInput {Blind}{F23 up}
   Return

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

getModifierStates(ByRef AlphaForm := "")
{
   AlphaForm := ""

   if GetKeyState("F23", "P")
   {
      ReturnValue .= "#"
      AlphaForm .= "W"
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
      MsgBox, The active key is "%ModifierStates% - %Key%"
      If (Key = " ")
         Send, %ModifierStates%{Space}
      Else
         Send, %ModifierStates%{%Key%}
      sleep 50
}
