# ahk_on_screen_keyboard

A modular and customizable on-screen-keyboard for AutoHotkey projects.

![demonstration](./demonstration.gif)

To include in your script: `#Include osk.ahk`

To initialize object: `Global keyboard := new OSK("dark", "qwerty")`.

Main methods:
* keyboard.toggle() - show and hide keyboard on the current monitor
* keyboard.ChangeIndex(Direction) - "Up", "Down", "Left", "Right"; For dpad navigation
* keyboard.HandleOSKClick(keyboard.Layout[keyboard.RowIndex, keyboard.ColumnIndex].1) - Send the dpad highlighted key through the keyboard

If you want to use an object name other than `keyboard` you will have to change the calls in the `#If` statements and the `HandleOSKClick()` function to your object's name.

Features:
  * Displays physical and virtual keypresses
  * Can be controlled with dpad.
  * light and dark mode
  * easy to add or adjust layouts (in __New)

For an example implementation see [Controller_MKB](https://github.com/henrystern/controller_mkb).
