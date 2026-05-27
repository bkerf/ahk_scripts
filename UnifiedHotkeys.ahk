; UnifiedHotkeys.ahk
; 单进程统一托管常用热键，避免多个托盘图标
; AutoHotkey v2.0

#Requires AutoHotkey v2.0
#SingleInstance Force

global ScreenshotDir := A_Temp "\Screenshots"
global MaxScreenshots := 50
global HomeLogFile := A_ScriptDir "\Home_debug.log"
global HomeMediaEnabled := true

if !DirExist(ScreenshotDir)
    DirCreate(ScreenshotDir)

CleanupOldScreenshots()

if FileExist(HomeLogFile)
    FileDelete(HomeLogFile)
Log("=== Unified script started ===")

A_TrayMenu.Delete()
A_TrayMenu.Add("AHK Scripts", (*) => "")
A_TrayMenu.Disable("AHK Scripts")
A_TrayMenu.Add()
A_TrayMenu.Add("Home Media Control", ToggleHomeMediaControl)
A_TrayMenu.Check("Home Media Control")
A_TrayMenu.Add("打开截图目录", (*) => Run(ScreenshotDir))
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

TrayTip("AHK Scripts", "已启动：剪贴板、媒体控制", 1)

; Win + Shift + C 清理 claude.ai/anthropic 浏览器记录
#+c:: {
    claudeCleaner := A_ScriptDir "\clear-claude-login.ps1"
    Run('powershell -NoProfile -ExecutionPolicy Bypass -File "' claudeCleaner '" -CloseBrowsers -VerboseOutput', , "Hide")
}

ToggleHomeMediaControl(*) {
    global HomeMediaEnabled

    HomeMediaEnabled := !HomeMediaEnabled
    if HomeMediaEnabled
        A_TrayMenu.Check("Home Media Control")
    else
        A_TrayMenu.Uncheck("Home Media Control")
}

Log(msg) {
    global HomeLogFile

    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(timestamp " | " msg "`n", HomeLogFile)
}

; ========================================
; ClipboardImagePaste
; ========================================
$^v:: {
    if ClipboardHasImage() && !ClipboardHasFiles() {
        waited := 0
        while (ClipboardHasImage() && !ClipboardHasFiles() && waited < 1500) {
            Sleep(200)
            waited += 200
        }

        if ClipboardHasImage() && !ClipboardHasFiles() {
            filepath := SaveClipboardImage()
            if filepath {
                SetClipboardToFile(filepath)
                Sleep(100)
            }
        }
    }

    SendInput("^v")
}

ClipboardHasImage() {
    return DllCall("IsClipboardFormatAvailable", "uint", 2)
        || DllCall("IsClipboardFormatAvailable", "uint", 8)
        || DllCall("IsClipboardFormatAvailable", "uint", 17)
}

ClipboardHasFiles() {
    return DllCall("IsClipboardFormatAvailable", "uint", 15)
}

SaveClipboardImage() {
    global ScreenshotDir

    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    filepath := ScreenshotDir "\screenshot_" timestamp ".png"
    psCommand := 'Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $img = [System.Windows.Forms.Clipboard]::GetImage(); if ($img) { $img.Save(\"' filepath '\", [System.Drawing.Imaging.ImageFormat]::Png) }'

    RunWait('powershell -NoProfile -Command "' psCommand '"',, "Hide")

    if FileExist(filepath)
        return filepath
    return ""
}

SetClipboardToFile(filepath) {
    psCommand := 'Add-Type -AssemblyName System.Windows.Forms; for ($i=0; $i -lt 3; $i++) { try { $fc = New-Object System.Collections.Specialized.StringCollection; $fc.Add(\"' filepath '\"); [System.Windows.Forms.Clipboard]::SetFileDropList($fc); break } catch { Start-Sleep -Milliseconds 100 } }'
    RunWait('powershell -NoProfile -Command "' psCommand '"',, "Hide")
}

CleanupOldScreenshots() {
    global ScreenshotDir, MaxScreenshots

    files := []
    loop files ScreenshotDir "\screenshot_*.png" {
        files.Push({path: A_LoopFileFullPath, time: A_LoopFileTimeModified})
    }

    if files.Length > MaxScreenshots {
        files := SortByTime(files)
        deleteCount := files.Length - MaxScreenshots
        loop deleteCount {
            try FileDelete(files[A_Index].path)
        }
    }
}

SortByTime(arr) {
    n := arr.Length
    loop n - 1 {
        i := A_Index
        loop n - i {
            j := A_Index
            if arr[j].time > arr[j + 1].time {
                temp := arr[j]
                arr[j] := arr[j + 1]
                arr[j + 1] := temp
            }
        }
    }
    return arr
}

#HotIf WinActive("ahk_exe WindowsTerminal.exe") || WinActive("ahk_exe powershell.exe") || WinActive("ahk_exe pwsh.exe") || WinActive("ahk_exe cmd.exe") || WinActive("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")
+Enter:: {
    SendInput("\{Enter}")
}
#HotIf

; ========================================
; Home_MediaControl
; ========================================
Home:: {
    global HomeMediaEnabled

    if !HomeMediaEnabled {
        Send "{Home}"
        return
    }

    Send "{Media_Play_Pause}"
    Log("HOME pressed - Media Play/Pause toggled")
}

; ========================================
; VoiceMediaControl
; ========================================
WSAStartup() {
    static started := false

    if started
        return true

    wsadata := Buffer(400)
    if DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsadata) = 0 {
        started := true
        return true
    }
    return false
}

TCP_QUERY(host := "127.0.0.1", port := 5001) {
    if !WSAStartup()
        return ""

    socket := DllCall("Ws2_32\socket", "Int", 2, "Int", 1, "Int", 6, "Ptr")
    if (socket = -1 || socket = 0)
        return ""

    sockaddr := Buffer(16)
    NumPut("UShort", 2, sockaddr)
    NumPut("UShort", DllCall("Ws2_32\htons", "UShort", port), sockaddr, 2)
    NumPut("UInt", DllCall("Ws2_32\inet_addr", "AStr", host), sockaddr, 4)

    if (DllCall("Ws2_32\connect", "Ptr", socket, "Ptr", sockaddr, "Int", 16, "Int") != 0) {
        DllCall("Ws2_32\closesocket", "Ptr", socket)
        return ""
    }

    buf := Buffer(64)
    received := DllCall("Ws2_32\recv", "Ptr", socket, "Ptr", buf, "Int", 64, "Int", 0)
    DllCall("Ws2_32\closesocket", "Ptr", socket)

    return received > 0 ? StrGet(buf, received, "UTF-8") : ""
}

ResumeMedia(*) {
    PostMessage(0x0319, 0, 14 << 16,, "ahk_class Shell_TrayWnd")
}

$#h:: {
    if (TCP_QUERY() = "playing") {
        SetTimer(ResumeMedia, 0)
        PostMessage(0x0319, 0, 14 << 16,, "ahk_class Shell_TrayWnd")
        SetTimer(ResumeMedia, -120000)
    }

    Sleep(200)
    Send("#h")
}
