#SingleInstance
SendMode Input

If (A_ScriptFullPath = A_LineFile) { ; if run as script rather than included elsewhere - for testing
    Global keyboard := new OSK("dark", "qwerty")

    toggle := ObjBindMethod(keyboard, "toggle")
    move_left := ObjBindMethod(keyboard, "changeIndex", "Left")
    move_up := ObjBindMethod(keyboard, "changeIndex", "Up")
    move_down := ObjBindMethod(keyboard, "changeIndex", "Down")
    move_right := ObjBindMethod(keyboard, "changeIndex", "Right")
    send_press := func("SendKeyboardPress").bind()

    Hotkey, ^Ins, % toggle

    Hotkey, If, keyboard.Enabled
    Hotkey, Left, % move_left
    Hotkey, Up, % move_up
    Hotkey, Down, % move_down
    Hotkey, Right, % move_right

    Hotkey, If, keyboard.Enabled && keyboard.IsDPadKeyboard()
    Hotkey, Enter, % send_press

    SendKeyboardPress() {
        keyboard.HandleOSKClick(keyboard.RetrieveDPadSelected())
        Return
    }
}

; for context sensitive hotkeys
#If, keyboard.Enabled
#If, keyboard.Enabled && keyboard.IsDPadKeyboard()
#If

; can't use method for gui onClick
HandleOSKClick() {
    keyboard.HandleOSKClick()
    return
}

Class OSK
; Adapted from feiyue's script: https://www.autohotkey.com/boards/viewtopic.php?t=58366 
{

    __New(theme:="dark", layout:="qwerty") {
        this.Enabled := False

        this.Keys := []
        this.Controls := []
        this.Modifiers := ["LShift", "LCtrl", "LWin", "LAlt", "RShift", "RCtrl", "RWin", "RAlt", "CapsLock", "ScrollLock"]

        if (theme = "light") {
            this.Background := "FDF6E3"
            this.ButtonColour := "EEE8D5" 
            this.ButtonOutlineColour := "8E846F" 
            this.ActiveButtonColour := "DDD6C1" 
            this.SentButtonColour := "AC9D57"
            this.ToggledButtonColour := "AC9D58" ; don't set exactly the same as SentButtonColour
            this.TextColour := "657B83"
        }
        else { ; default dark theme
            this.Background := "2A2A2E"
            this.ButtonColour := "010409" 
            this.ButtonOutlineColour := "010409" 
            this.ActiveButtonColour := "1b1a20" 
            this.SentButtonColour := "553b6b"
            this.ToggledButtonColour := "553b6a" ; don't set exactly the same as SentButtonColour
            this.TextColour := "8b949e"
        }

        this.MonitorKeyPresses := ObjBindMethod(this, "MonitorAllKeys") ; can choose between MonitorModifiers and MonitorAllKeys

        this.Layout := []
        ; layout format is ["Text", width:=45, x-offset:=2]
        ; "Text" is what is sent when the button is clicked.
        ; ` and ~ had getkeystate issues so I replaced them with scancode sc029
        if (layout = "colemak-dh") {
            this.Layout.Push([ ["Esc"],["F1",,23],["F2"],["F3"],["F4"],["F5",,15],["F6"],["F7"],["F8"],["F9",,15],["F10"],["F11"],["F12"],["PrintScreen",60,10],["ScrollLock",60],["Pause",60] ])
            this.Layout.Push([ ["sc029", 30],["1"],["2"],["3"],["4"],["5"],["6"],["7"],["8"],["9"],["0"],["-"],["="],["BS", 60],["Ins",60,10],["Home",60],["PgUp",60] ])
            this.Layout.Push([ ["Tab"],["q"],["w"],["f"],["p"],["b"],["j"],["l"],["u"],["y"],["`;"],["["],["]"],["\"],["Del",60,10],["End",60],["PgDn",60] ])
            this.Layout.Push([ ["CapsLock",60],["a"],["r"],["s"],["t"],["g"],["m"],["n"],["e"],["i"],["o"],["'"],["Enter",77] ])
            this.Layout.Push([ ["LShift",90],["x"],["c"],["d"],["v"],["z"],["k"],["h"],["`,"],["."],["/"],["RShift",94],["↑",60,72] ])
            this.Layout.Push([ ["LCtrl",60],["LWin",60],["LAlt",60],["Space",222],["RAlt",60],["RWin",60],["App",60],["RCtrl",60],["Left",60,10],["Down",60],["Right",60] ])
        }
        else { ; default qwerty
            this.Layout.Push([ ["Esc"],["F1",,23],["F2"],["F3"],["F4"],["F5",,15],["F6"],["F7"],["F8"],["F9",,15],["F10"],["F11"],["F12"],["PrintScreen",60,10],["ScrollLock",60],["Pause",60] ])
            this.Layout.Push([ ["sc029", 30],["1"],["2"],["3"],["4"],["5"],["6"],["7"],["8"],["9"],["0"],["-"],["="],["BS", 60],["Ins",60,10],["Home",60],["PgUp",60] ])
            this.Layout.Push([ ["Tab"],["q"],["w"],["e"],["r"],["t"],["y"],["u"],["i"],["o"],["p"],["["],["]"],["\"],["Del",60,10],["End",60],["PgDn",60] ])
            this.Layout.Push([ ["CapsLock",60],["a"],["s"],["d"],["f"],["g"],["h"],["j"],["k"],["l"],["`;"],["'"],["Enter",77] ])
            this.Layout.Push([ ["LShift",90],["z"],["x"],["c"],["v"],["b"],["n"],["m"],["`,"],["."],["/"],["RShift",94],["Up",60,72] ])
            this.Layout.Push([ ["LCtrl",60],["LWin",60],["LAlt",60],["Space",222],["RAlt",60],["RWin",60],["App",60],["RCtrl",60],["Left",60,10],["Down",60],["Right",60] ])
        }

        ; ; Optionally sets alternate text for the button actions named in this.Layout - doesn't have to be in same order as layout
        this.PrettyName := { "PrintScreen": "Prt Scr", "ScrollLock": "Scr Lk"
                                , "sc029": "~", 1: "1 !", 2: "2 @", 3: "3 #", 4: "4 $", 5: "5 `%", 6: "6 ^", 7: "7 &&", 8: "8 *", 9: "9 (", 0: "0 )", "-": "- _", "+": "= +", "BS": "←", "PgUp": "Pg Up", "PgDn": "Pg Dn"
                                , "q": "Q", "w": "W", "e": "E", "r": "R", "t": "T", "y": "Y", "u": "U", "i": "I", "o": "O", "p": "P", "[": "[ {", "]": "] }", "\": "\ |"
                                , "CapsLock": "Caps", "a": "A", "s": "S", "d": "D", "f": "F", "g": "G", "h": "H", "j": "J", "k": "K", "l": "L", "`;": "`; :", "'": "' """
                                , "LShift": "Shift", "z": "Z", "x": "X", "c": "C", "v": "V", "b": "B", "n": "N", "m": "M", "`,": "`, <", ".": ". >", "/": "/ ?", "RShift": "Shift"
                                , "LCtrl": "Ctrl", "LWin": "Win", "LAlt": "Alt", "Space": " ", "RAlt": "Alt", "RWin": "Win", "AppsKey": "App", "RCtrl": "Ctrl", "Up": "↑", "Down": "↓", "Left": "←", "Right": "→"}
        this.Make()
    }

    SetTimer(TimerID, Period) {
        Timer := this[TimerID]
        SetTimer % Timer, % Period
        return
    }

    Make() {
        Gui, OSK: +AlwaysOnTop -DPIScale +Owner -Caption +E0x08000000 
        Gui, OSK: Font, s12, Verdana
        Gui, OSK: Margin, 10, 10
        Gui, OSK: Color, % this.Background
        SS_CenterTextInBox := 0x200 ; styling adjustment
        For Index, Row in this.Layout {
            For i, Button in Row {
                Width := Button.2 ? Button.2 : 45 
                HorizontalOffset := Button.3 ? Button.3 : 2
                RelativePosition := Index <= 2 and i = 1 ? "xm" : i=1 ? "xm y+2" : "x+" HorizontalOffset
                ButtonText := this.PrettyName[Button.1] ? this.PrettyName[Button.1] : Button.1

                ; Control handling is from Hellbent's script: https://www.autohotkey.com/boards/viewtopic.php?t=87535
                Gui, OSK:Add, Text, % RelativePosition " c" this.TextColour " w" Width " h" 30 " -Wrap BackgroundTrans Center hwndbottomt gHandleOSKClick " SS_CenterTextInBox, % Button.1 ; handles the click
                Gui, OSK:Add, Progress, % "xp yp w" Width " h" 30 " Disabled Background" this.ButtonOutlineColour " c" this.ButtonColour " hwndp", 100
                Gui, OSK:Add, Text, % "xp yp c" this.TextColour " w" Width " h" 30 " -Wrap BackgroundTrans Center hwndtopt " SS_CenterTextInBox, % ButtonText ; displays the pretty name

                this.Keys[Button.1] := [Index, i]
                this.Controls[Index, i] := {Progress: p, Text: topt, Label: HandlePress, Colour: this.ButtonColour}
            }
        }	
        Return
    }

    Show() {
        this.Enabled := True

        ; reset active key
        this.UpdateGraphics(this.Controls[this.RowIndex, this.ColumnIndex], this.ButtonColour)
        this.ColumnIndex := 0
        this.RowIndex := 0

        CurrentMonitorIndex := this.GetCurrentMonitorIndex()
        DetectHiddenWindows On
        Gui, OSK: +LastFound
        Gui, OSK:Show, Hide
        GUI_Hwnd := WinExist()
        this.GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height)
        DetectHiddenWindows Off

        GUI_X := this.CoordXCenterScreen(GUI_Width,CurrentMonitorIndex)
        GUI_Y := this.CoordYCenterScreen(GUI_Height,CurrentMonitorIndex)

        Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", On-Screen Keyboard

        this.SetTimer("MonitorKeyPresses", 30)

        Return
    }

    Hide() {
        this.Enabled := False
        Gui, OSK: Hide
        this.SetTimer("MonitorKeyPresses", "off")
        return
    }

    Toggle() {
        If this.Enabled {
            this.Hide()
        }
        Else {
            this.Show()
        }
        Return
    }

    ; for centering keyboard on screen
    GetCurrentMonitorIndex() {
        CoordMode, Mouse, Screen
        MouseGetPos, mx, my
        SysGet, monitorsCount, 80

        Loop %monitorsCount%{
            SysGet, monitor, Monitor, %A_Index%
            if (monitorLeft <= mx && mx <= monitorRight && monitorTop <= my && my <= monitorBottom){
                Return A_Index
                }
            }
        Return 1
    }

    CoordXCenterScreen(WidthOfGUI,ScreenNumber) {
        SysGet, Mon1, Monitor, %ScreenNumber%
        return ((Mon1Right-Mon1Left - WidthOfGUI) / 2) + Mon1Left
    }

    CoordYCenterScreen(HeightofGUI,ScreenNumber) {
        SysGet, Mon1, Monitor, %ScreenNumber%
        return (Mon1Bottom - 80 - HeightofGUI)
    }

    GetClientSize(hwnd, ByRef w, ByRef h) {
        VarSetCapacity(rc, 16)
        DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
        w := NumGet(rc, 8, "int")
        h := NumGet(rc, 12, "int")
        Return
    }

    HandleOSKClick(Key:="") {
        if not Key {
            Key := A_GuiControl
        }
        if (this.IsModifier(Key)) {
            this.SendModifier(Key)
        }
        else {
            this.SendPress(Key)
        }
        return
    }

    IsModifier(Key) {
        if (Key = "LShift" 
            or Key = "LCtrl" 
            or Key = "LAlt" 
            or Key = "LWin" 
            or Key = "RShift" 
            or Key = "RCtrl" 
            or Key = "RAlt" 
            or Key = "RWin"
            or Key = "CapsLock"
            or Key = "ScrollLock")
            return True
        else
            return False
    }

    MonitorModifiers() {
        For _, Modifier in this.Modifiers {
            this.MonitorKey(Modifier)
        }
        Return
    }


    MonitorAllKeys() {
        For _, Row in this.Layout {
            For i, Button in Row {
                this.MonitorKey(Button.1)
            }
        }
        Return
    }

    MonitorKey(Key) {
        if (Key = "CapsLock" or Key = "ScrollLock" or Key = "Pause")
            KeyOn := GetKeyState(Key, "T")
        else
            KeyOn := GetKeyState(Key)
        KeyRow := this.Keys[Key][1]
        KeyColumn := this.Keys[Key][2]
        if (KeyOn and this.Controls[KeyRow, KeyColumn].Colour != this.ToggledButtonColour) {
            this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], this.ToggledButtonColour)
        }
        else if (not KeyOn and this.Controls[KeyRow, KeyColumn].Colour = this.ToggledButtonColour) {
            if (KeyRow = this.RowIndex and KeyColumn = this.ColumnIndex)
                this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], this.ActiveButtonColour)
            else
                this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], this.ButtonColour)
        }
        Return
    }

    SendPress(Key) {
        SentRow := this.Keys[Key][1]
        SentColumn := this.Keys[Key][2]
        OldColor := this.Controls[SentRow][SentColumn].Colour
        this.UpdateGraphics(this.Controls[SentRow, SentColumn], this.SentButtonColour)
        SendInput, % "{Blind}{" Key "}" 
        For _, Modifier in this.Modifiers {
            ModifierOn := GetKeyState(Modifier)
            if (ModifierOn)
                SendInput, % "{" Modifier " up}"
        }
        Sleep, 100
        if (SentRow = this.RowIndex and SentColumn = this.ColumnIndex)
            this.UpdateGraphics(this.Controls[SentRow, SentColumn], this.ActiveButtonColour)
        else
            this.UpdateGraphics(this.Controls[SentRow, SentColumn], this.ButtonColour)
        Return
    }

    SendModifier(Key) {
        ModifierRow := this.Keys[Key][1]
        ModifierColumn := this.Keys[Key][2]
        if (Key = "CapsLock")
            SetCapsLockState, % not GetKeyState(Key, "T")
        else if (Key = "ScrollLock")
            SetScrollLockState, % not GetKeyState(Key, "T")
        else {
            ModifierOn := GetKeyState(Key)
            if (ModifierOn)
                SendInput, % "{" Key " up}"
            else 
                SendInput, % "{" Key " down}"
        }
        return
    }


    ChangeIndex(Direction) {
        if (not this.RowIndex) {
            this.RowIndex := 4
            this.ColumnIndex := 7
        }

        if (this.Controls[this.RowIndex, this.ColumnIndex].Colour != this.ToggledButtonColour)
            this.UpdateGraphics(this.Controls[this.RowIndex, this.ColumnIndex], this.ButtonColour)

        this.HandleChangeIndex(Direction)

        if (Direction = "Up") {
            if this.RowIndex = 1
                this.RowIndex := this.Controls.Length()
            else
                this.RowIndex := this.RowIndex - 1
            this.ColumnIndex := min(this.ColumnIndex, this.Controls[this.RowIndex].Length())
        }
        if (Direction = "Down") {
            this.RowIndex := mod(this.RowIndex, this.Controls.Length()) + 1
            this.ColumnIndex := min(this.ColumnIndex, this.Controls[this.RowIndex].Length())
        }
        if (Direction = "Left") {
            if this.ColumnIndex = 1
                this.ColumnIndex := this.Controls[this.RowIndex].Length()
            else
                this.ColumnIndex := this.ColumnIndex - 1
        }
        if (Direction = "Right") {
            this.ColumnIndex := mod(this.ColumnIndex, this.Controls[this.RowIndex].Length()) + 1
        }

        if (this.Controls[this.RowIndex, this.ColumnIndex].Colour != this.ToggledButtonColour)
            this.UpdateGraphics(this.Controls[this.RowIndex, this.ColumnIndex], this.ActiveButtonColour)
        Return
    }

    HandleChangeIndex(Direction) {
        ; hardcoded logic to fix unusual index changes due to variable button widths
        if (this.RowIndex = 1) {
            if (this.ColumnIndex > 1 and Direction = "Down")
                this.ColumnIndex += 1
            else if (this.ColumnIndex > 12 and Direction = "Up")
                this.ColumnIndex -= 5
            else if (this.ColumnIndex > 8 and Direction = "Up")
                this.ColumnIndex -= 4
            else if (this.ColumnIndex > 3 and Direction = "Up")
                this.ColumnIndex := 4
        }
        else if (this.RowIndex = 2) {
            if (this.ColumnIndex > 1 and Direction = "Up")
                this.ColumnIndex -= 1
        }
        else if (this.RowIndex = 3) {
            if (this.ColumnIndex = 14 and Direction = "Down")
                this.ColumnIndex -= 1
            else if (this.ColumnIndex > 14 and Direction = "Down")
                this.RowIndex += 1

        }
        else if (this.RowIndex = 4) {
            if (this.ColumnIndex = 13 and Direction = "Up") 
                this.ColumnIndex += 1
            else if (this.ColumnIndex = 13 and Direction = "Down")
                this.ColumnIndex -= 1
        }
        else if (this.RowIndex = 5) {
            if (this.ColumnIndex = 13 and Direction = "Up") {
                this.RowIndex -= 1
                this.ColumnIndex += 3
            }
            else if (this.ColumnIndex = 13 and Direction = "Down")
                this.ColumnIndex -= 3
            else if (this.ColumnIndex = 12 and Direction = "Up")
                this.ColumnIndex += 1
            else if (this.ColumnIndex > 8 and Direction = "Down")
                this.ColumnIndex -= 4
            else if (this.ColumnIndex > 3 and Direction = "Down")
                this.ColumnIndex := 4
        }
        else if (this.RowIndex = 6) {
            if (this.ColumnIndex > 7 and Direction = "Down") {
                this.ColumnIndex += 5
            }
            else if (this.ColumnIndex > 4 and (Direction = "Up" or Direction = "Down")) {
                this.ColumnIndex += 4
            }
            else if (this.ColumnIndex = 4 and (Direction = "Up" or Direction = "Down")) {
                this.ColumnIndex := 6
            }
        }
        return
    }

    IsDPadKeyboard() {
        return this.RowIndex
    }

    RetrieveDPadSelected() {
        if this.IsDPadKeyboard() {
            return keyboard.Layout[keyboard.RowIndex, keyboard.ColumnIndex].1
        }
        return ""
    }

    UpdateGraphics(Obj, Colour){
        GuiControl, % "OSK: +C" Colour, % Obj.Progress
        GuiControl, OSK: +Redraw, % obj.Text
        Obj.Colour := Colour
        Return
    }
}