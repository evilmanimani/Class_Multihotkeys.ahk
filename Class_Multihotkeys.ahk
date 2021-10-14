; Example Script:
#Persistent
#NoEnv
#SingleInstance, force
SetBatchLines, -1

mk := new MultiHotkeys()
mk.Add("d"                  , "t200" , "d")      ; send d if the below times out
mk.Add("dd"                 ,        , "Test"    , "Double hotkey") ; Calling functions
mk.Add("ddd"                ,        , "Test"    , "Triple hotkey!")
mk.Add("dddd"               ,        , "Test"    , "Quadruple hotkey!!")
mk.Add("{F1}{F1}"           ,        , "Test2")  ; Calling a label
mk.Add("^{F1}{F1}"          ,        , "Test3")  ; Sending a string; Ctrl+F1 > F1
mk.Add("+t"                 ,        , "T")
mk.Add("+thisisatest"       , "t1000", "Test"    , "Hello,"  ,"World!") ; Sending 2 parameters ; Shift+
mk.Add("#{Capslock}{F2}{F3}", "t800" , "Test"    , "Wow, this is a long hotkey!") ; Win+Caps > F2 > F3
return

Test(param1:="",param2:="") {
    global mk
    str := mk.inputStr
    if param1
        str .= "`r`n" param1
    if param2
        str .= "`r`n" param2
    tooltip, % str
    SetTimer, Tooltipoff, -3000
    return
    TooltipOff:
    tooltip
    return
}

Test2:
msgbox, % A_ThisLabel "`r`n" mk.inputStr
return

;---------------------------------------------------------------------------------------------------------------------------------------
;
;   Class_Multihotkeys.ahk v0.1 by evilmanimani
;   https://github.com/evilmanimani/Class_Multihotkeys.ahk
;
;   Easily set up double, triple, or more hotkeys, and more for pseudo hotstrings, with a configurable timeout
;   Can go functions with parameters, labels, or just send characters if it doesn't match a function/label
;   If two input strings are similar i.e. (!aa, !aaa, !aaaa), it will trigger the shorter ones after the timeout
;   , the longest will be triggered immediately.
;
;   mh := new MultiHotkeys() to start
;   
;   The only public method is Add, see examples for details:
;   
;       keys -        string of letter keys, optionally starting with modifiers the modifier only needs to be held for the first key
;                     should support ~, but not really tested.
;       options -     at the moment, only supports a timeout in milliseconds, this is the timeout period between each keypress
;                     of the full input string, entered as t400, t1000, etc; defaults to 400ms; the timeout applies to any configured
;                     input string that shares the same starting hotkey (the modifiers and first character)
;       function -    either a function or label name, any other text not matching a function onr label will be sent as-is
;       params -      if passing a Function, any amount of associated params are supported
;
;
Class MultiHotkeys {

    __New(options:="") { ; not much for options here yet
        this.ih := InputHook(Options)
        this.KeyDict := {}
    }

    Add(keys, options:="", function :="", params*) {
        static optLookup := {"T":"timeout","t":"timeout"}
        for i, opt in StrSplit(options, A_Space) {
            if optLookup.HasKey(SubStr(opt,1,1)) {
                var := optLookup[SubStr(opt,1,1)]
                %var% := SubStr(opt,2)
            }
        }
        RegExMatch(keys, "O)^(?<mods>[!^+#]{1,4})?(?<keys>.*)", keys)
        mods := keys.mods
        keyStr := keys.keys
        If IsFunc(function) {
            if params
                func := Func(function).Bind(params*)
            else
                func := Func(function)
            
        }
        if IsObject(keyStr) {
            ; to-do: put in support for simple remaps via passing an array, i.e. mp.Add({"aa":"b","bb":"c","cc":"d"},,"Test")
        } else {
            hotkeyFunc := ObjBindMethod(this,"HotkeyHandler")
            pos := 1
            loop {
                pos := RegExMatch(keyStr,"({.*?})|(\w)",key,pos)
                if (A_Index = 1) {
                    pos += StrLen(key)
                    firstKey := key
                    hk := "$" . mods . RegExReplace(key, "[{}]")
                    HotKey, % hk, % hotkeyFunc
                } else {
                    this.ih.KeyOpt(key, "+E+S")
                    pos += StrLen(key)
                }
            } Until (!key)
            
            keyStr := StrReplace(keyStr, firstKey, , , 1)
            keyStr := RegExReplace(keyStr, "[{}]")
            for i, e in StrSplit(keys) {
                if (e = "{")
                this.ih.KeyOpt(e, "+E+S")
            }
            if !isObject(this.KeyDict[hk]) {
                this.KeyDict[hk] := {}
                this.KeyDict[hk].timeout := timeout ? Format("{:.1f}", timeout / 1000) : 0.4
            }
            this.KeyDict[hk][keyStr] := {}
            this.KeyDict[hk][keyStr].function := func
            this.KeyDict[hk][keyStr].funcName := function
            if mods
                this.KeyDict[hk][keyStr].mods := mods
        }
    }

    HotkeyHandler() {
        Suspend, On
        thisHotkey := A_ThisHotkey
        Mods := RegExReplace(thisHotkey, "i)^[~\$]*([!^+#]{0,4}).*$", "$1")
        timeout := this.KeyDict[thisHotkey].timeout
        loop {
            matched := []
            this.ih.Start()
            EndReason := this.ih.Wait(timeout)
            inputStr .= this.ih.EndKey
            for k, v in this.KeyDict[thisHotkey] {
                if IsObject(v) {
                    if InStr(k, inputStr)
                        matched.Push(k)
                    maxLen := StrLen(k) > maxLen ? StrLen(k) : maxLen
                }
            }
            if ((matched.MaxIndex() = 1 && this.KeyDict[thisHotkey].HasKey(inputStr))
            || !EndReason || StrLen(inputStr) >= maxLen)
                break
        }
        this.ih.Stop()
        matchConfirm := []
        for i, e in matched {
            if this.KeyDict[thisHotkey][e].HasKey("mods") {
                for _, char in StrSplit(mods) {
                    if InStr(this.KeyDict[thisHotkey][inputStr].mods,char) {
                        matchConfirm.Push(e)
                        continue 2
                    }
                }
            } else if !mods {
                matchConfirm.Push(e)
            }
        }
        if ((matched.MaxIndex() = 0 && this.KeyDict[thisHotkey].HasKey(""))
            || (this.KeyDict[thisHotkey].HasKey(matchConfirm.1) && (!Endreason || matchConfirm.MaxIndex() = 1))) {
            this.inputStr := SubStr(thisHotkey,2) . inputStr
            funcName := this.KeyDict[thisHotkey][inputStr].funcName
            if IsFunc(funcName) {
                this.KeyDict[thisHotkey][inputStr].function.Call()
            } else if IsLabel(funcName) {
                Gosub, % funcName
            } else {
                Send, % "{raw}" funcName
            }
        } else {
            this.inputStr := ""
        }
        Suspend, Off
    }
}
