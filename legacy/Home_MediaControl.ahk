; ============================================================
; Home_MediaControl.ahk
; ============================================================
; Description: Press HOME key to toggle media play/pause
;
; Usage:
;   - Press HOME key: toggle media play/pause
;
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== Logging Configuration =====
global logFile := A_ScriptDir "\Home_debug.log"

Log(msg) {
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    text := timestamp . " | " . msg . "`n"
    FileAppend(text, logFile)
}

if FileExist(logFile)
    FileDelete(logFile)
Log("=== Script Started ===")

; ===== Tray Menu Configuration =====
A_TrayMenu.Delete()
A_TrayMenu.Add("Home Media Control", (*) => "")
A_TrayMenu.Disable("Home Media Control")
A_TrayMenu.Add()
A_TrayMenu.Add("Pause Script", TrayPauseScript)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())

TrayPauseScript(*) {
    Suspend(-1)
    if A_IsSuspended
        A_TrayMenu.Check("Pause Script")
    else
        A_TrayMenu.Uncheck("Pause Script")
}

TrayTip("Home Media Control", "HOME key = Media Play/Pause", 1)

; 自启动已由 StartAll.ahk 统一管理

; ===== HOME Key Hotkey =====
Home:: {
    Send "{Media_Play_Pause}"
    Log("HOME pressed - Media Play/Pause toggled")
}
