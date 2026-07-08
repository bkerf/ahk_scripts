; lib/Clipboard.ahk
; Ctrl+V 剪贴板图片转文件，以及终端 Shift+Enter 换行。

InitializeClipboardModule() {
    global ScreenshotDir, MaxScreenshots

    ScreenshotDir := A_Temp "\Screenshots"
    MaxScreenshots := 50

    if !DirExist(ScreenshotDir)
        DirCreate(ScreenshotDir)

    CleanupOldScreenshots()
}

IsTerminalWindowActive() {
    return WinActive("ahk_exe WindowsTerminal.exe")
        || WinActive("ahk_exe powershell.exe")
        || WinActive("ahk_exe pwsh.exe")
        || WinActive("ahk_exe cmd.exe")
        || WinActive("ahk_class CASCADIA_HOSTING_WINDOW_CLASS")
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

#HotIf IsTerminalWindowActive()
+Enter:: {
    SendInput("\{Enter}")
}
#HotIf
