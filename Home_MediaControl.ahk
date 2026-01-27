; ============================================================
; Home_MediaControl.ahk
; ============================================================
; Description: Home key enhancement - hold to pause media and switch focus to PowerShell, release to restore
;
; Usage:
;   - Hold Home: pause media and switch focus to PowerShell window
;   - Release Home: resume media and return to previous window
;   - Original Home functions are preserved
;
; Smart Detection:
;   - Only pauses when media is actively playing
;   - Won't accidentally start playback if media is stopped
;   - Prevents unintended playback triggering
;
; Dependencies:
;   - Python + winsdk library (pip install winsdk)
;   - check_media.py for detecting media playback status
;
; Key Features:
;   - Hold Home: pause media + switch focus to PowerShell
;   - Release Home: resume media + restore previous window focus
;
; ============================================================

#Requires AutoHotkey v2.0
#SingleInstance Force

; ===== Logging Configuration =====
global logFile := A_ScriptDir "\Home_debug.log"

; Write log entry with timestamp
Log(msg) {
    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    text := timestamp . " | " . msg . "`n"
    FileAppend(text, logFile)
}

; Clear old log file
if FileExist(logFile)
    FileDelete(logFile)
Log("=== Script Started ===")

; State flag: tracks whether media was paused by this script
; Used to determine whether to resume playback on release
global pausedByScript := false

; ===== Tray Menu Configuration =====
A_TrayMenu.Delete()
A_TrayMenu.Add("Home Media Control", (*) => "")
A_TrayMenu.Disable("Home Media Control")
A_TrayMenu.Add()
A_TrayMenu.Add("Pause Script", TrayPauseScript)      ; Temporarily disable hotkeys
A_TrayMenu.Add("Remove from Startup", TrayRemoveAutoStart)
A_TrayMenu.Add()
A_TrayMenu.Add("Exit", (*) => ExitApp())

; Pause/Resume script functionality
TrayPauseScript(*) {
    Suspend(-1)  ; Toggle suspend state
    if A_IsSuspended
        A_TrayMenu.Check("Pause Script")
    else
        A_TrayMenu.Uncheck("Pause Script")
}

; Remove from startup
TrayRemoveAutoStart(*) {
    shortcutPath := A_Startup "\Home_MediaControl.lnk"
    if FileExist(shortcutPath) {
        FileDelete(shortcutPath)
        MsgBox("Removed from startup", "Home MediaControl", "Iconi T2")
    }
}

; Startup notification
TrayTip("Home Media Control", "Started - Hold Home to pause, release to resume", 1)

; ===== Auto-Startup Configuration =====
; Automatically create startup shortcut on first run
shortcutPath := A_Startup "\Home_MediaControl.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}

; ===== Media Status Detection =====
; Call Python script to detect if media is currently playing
; Returns: true if playing, false if not playing or detection failed
IsMediaPlaying() {
    pyFile := A_ScriptDir "\check_media.py"
    if !FileExist(pyFile)
        return false

    ; Run pythonw silently, check status via exit code
    ; Exit code 0 = playing
    ; Exit code 1 = not playing
    exitCode := RunWait("pythonw `"" . pyFile . "`"",, "Hide")
    return exitCode = 0
}

; ===== Main Hotkey Logic =====
; * prefix: allows combination with other modifiers (e.g., Ctrl+Shift+Home)
*Home:: {
    global pausedByScript

    Log("--- Home Pressed ---")

    ; Preserve Home original function
    Send "{Home Down}"

    ; [Immediately] Save current window and switch focus to PowerShell
    prevWindow := WinExist("A")
    Log("Current window handle: " . prevWindow)

    if WinExist("ahk_exe pwsh.exe") {
        WinActivate("ahk_exe pwsh.exe")
        Log("Switched to PowerShell 7")
    } else if WinExist("ahk_exe powershell.exe") {
        WinActivate("ahk_exe powershell.exe")
        Log("Switched to Windows PowerShell")
    } else {
        Log("PowerShell window not found")
    }

    ; Detect media status, only pause if actively playing
    if IsMediaPlaying() {
        Send "{Media_Play_Pause}"
        pausedByScript := true   ; Mark as paused by this script
        Log("Media paused")
    } else {
        pausedByScript := false  ; Media not playing, do nothing
        Log("Media not playing, skip pause")
    }

    ; Block wait for key release
    KeyWait "Home"
    Log("--- Home Released ---")

    ; On release, only resume if paused by this script
    if pausedByScript {
        Send "{Media_Play_Pause}"
        pausedByScript := false
        Log("Media resumed")
    }

    ; Release Home
    Send "{Home Up}"

    ; Get PowerShell window handle for focus detection
    pwshWindow := WinExist("A")

    ; Wait 4 seconds, check if focus remains on PowerShell
    startTime := A_TickCount
    Log("Starting 4s wait, PowerShell handle=" . pwshWindow)

    loopCount := 0
    Loop {
        loopCount++
        Sleep 50
        ; Check if focus left PowerShell (user clicked other window)
        if (WinExist("A") != pwshWindow) {
            Log("Focus left PowerShell! Current window=" . WinExist("A"))
            break
        }
        ; After 4s with focus on PowerShell, send Enter then switch back
        if (A_TickCount - startTime >= 4000) {
            Log("4s timeout, sending Enter to PowerShell")
            ; Activate window then send
            WinActivate("ahk_id " . pwshWindow)
            WinWaitActive("ahk_id " . pwshWindow, "", 0.5)
            SendInput "{Enter}"
            break
        }
        ; Log status every second
        if (Mod(loopCount, 20) = 0) {
            Log("Waiting... elapsed=" . ((A_TickCount - startTime) / 1000) . "s")
        }
    }

    Log("Preparing to switch back to original window, handle: " . prevWindow)
    ; Restore previous window focus
    try WinActivate("ahk_id " . prevWindow)
    Log("--- Hotkey handling complete ---")
}
