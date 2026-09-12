; AutoHotkey v1 Script: Clipboard Number Summer
; Hotkey: Windows + F24 = Copy then sum numbers
; Additional hotkey: Windows + Alt + F24 = Sum numbers in clipboard
; This script sums all numbers found in the clipboard and shows the result

#F24::  ; Windows + F24 hotkey - Copy then sum
    ; First copy the selected text
    Send, ^c
    ; Wait a moment for clipboard to update
    Sleep, 100
    ; Fall through to sum the numbers
    Gosub, SumClipboardNumbers
return

; Additional hotkey: Windows + Alt + F24 = Sum numbers in clipboard only
#!F24::  ; Windows + Alt + F24
    Gosub, SumClipboardNumbers
return

SumClipboardNumbers:
    ; Get clipboard content
    ClipboardText := Clipboard
    
    ; Check if clipboard is empty
    if (ClipboardText = "") {
        MsgBox, 64, Clipboard Summer, Clipboard is empty!
        return
    }
    
    ; Initialize sum and number list
    Total := 0
    NumberCount := 0
    NumberList := ""
    
    ; Find all numbers in the clipboard using regex
    ; This pattern matches decimal numbers with 0-2 decimal places (including negative)
    NumberPattern := "-?\d+(\.\d{1,2})?"
    
    Pos := 1
    while (Pos := RegExMatch(ClipboardText, NumberPattern, Match, Pos)) {
        ; Convert to float and add to total
        Total += Match
        NumberCount++
        ; Store the number in our list (format to exactly 2 decimal places)
        NumValue := Match + 0  ; Convert to number
        RoundedValue := Round(NumValue, 2)
        
        ; Format to always show exactly 2 decimal places
        FormattedNumber := RoundedValue
        if (InStr(FormattedNumber, ".") = 0) {
            FormattedNumber := FormattedNumber . ".00"
        } else {
            DecimalPos := InStr(FormattedNumber, ".")
            DecimalsAfter := StrLen(FormattedNumber) - DecimalPos
            if (DecimalsAfter = 1) {
                FormattedNumber := FormattedNumber . "0"
            }
        }
        NumberList .= FormattedNumber . "`n"
        ; Move position past this match
        Pos += StrLen(Match)
    }
    
    ; Format the total to exactly 2 decimal places
    FormattedTotal := Round(Total, 2)
    if (InStr(FormattedTotal, ".") = 0) {
        FormattedTotal := FormattedTotal . ".00"
    } else {
        DecimalPos := InStr(FormattedTotal, ".")
        DecimalsAfter := StrLen(FormattedTotal) - DecimalPos
        if (DecimalsAfter = 1) {
            FormattedTotal := FormattedTotal . "0"
        }
    }
    
    ; Create the message
    if (NumberCount = 0) {
        Message := "No numbers found in clipboard!"
    } else {
        ; Remove the last newline from NumberList
        NumberList := RTrim(NumberList, "`n")
        
        if (NumberCount = 1) {
            Message := "Total: " . FormattedTotal . "`nFound 1 number:`n" . NumberList
        } else {
            Message := "Total: " . FormattedTotal . "`nFound " . NumberCount . " numbers:`n" . NumberList
        }
    }
    
    ; Show popup with result
    MsgBox, 64, Clipboard Summer Result, %Message%
    
return
