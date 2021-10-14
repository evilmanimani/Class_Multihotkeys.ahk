# Class_Multihotkeys.ahk
Easily configure double, triple, or longer hotkeys in AHK

Easily set up double, triple, or more hotkeys, and more for pseudo hotstrings, with a configurable timeout
Can go functions with parameters, labels, or just send characters if it doesn't match a function/label
If two input strings are similar i.e. (!aa, !aaa, !aaaa), it will trigger the shorter ones after the timeout
, the longest will be triggered immediately.

To start: `mh := new MultiHotkeys()`

The only public method is Add, see examples for details:

`mh.Add(keys, options:="", function :="", params*)`

- Keys
        
    String of letter keys, optionally starting with modifiers the modifier only needs to be held for the first key should support ~, but not really tested.
- Options

  At the moment, only supports a timeout in milliseconds, this is the timeout period between each keypress of the full input string, entered as t400, t1000, etc; defaults to 400ms; the timeout applies to any configured
                   input string that shares the same starting hotkey (the modifiers and first character)
- Function
     
  Either a function or label name, any other text not matching a function onr label will be sent as-is
- Params

  If passing a Function, any amount of associated params are supported
