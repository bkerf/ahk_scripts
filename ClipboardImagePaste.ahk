; ClipboardImagePaste.ahk
; 自动将剪贴板图片转换为文件，使 Ctrl+V 可以在终端粘贴
; AutoHotkey v2.0

#Requires AutoHotkey v2.0
#SingleInstance Force

; 截图保存目录
global ScreenshotDir := A_Temp "\Screenshots"
global MaxScreenshots := 50  ; 最多保存截图数量

if !DirExist(ScreenshotDir)
    DirCreate(ScreenshotDir)

; 启动时清理旧截图
CleanupOldScreenshots()

; 使用 $前缀 防止热键自触发
$^v:: {
    ; 检查剪贴板是否有图片（且不是文件）
    if ClipboardHasImage() && !ClipboardHasFiles() {
        ; 保存图片到文件
        filepath := SaveClipboardImage()
        if filepath {
            ; 将文件路径设置为剪贴板（作为文件引用）
            SetClipboardToFile(filepath)
            ; 短暂等待剪贴板更新
            Sleep(50)
        }
    }
    ; 使用 SendInput 发送原始按键，$ 前缀确保不会再次触发此热键
    SendInput("^v")
}

ClipboardHasImage() {
    ; CF_BITMAP = 2, CF_DIB = 8, CF_DIBV5 = 17
    return DllCall("IsClipboardFormatAvailable", "uint", 2)
        || DllCall("IsClipboardFormatAvailable", "uint", 8)
        || DllCall("IsClipboardFormatAvailable", "uint", 17)
}

ClipboardHasFiles() {
    ; CF_HDROP = 15
    return DllCall("IsClipboardFormatAvailable", "uint", 15)
}

SaveClipboardImage() {
    ; 使用 PowerShell 保存图片
    timestamp := FormatTime(, "yyyyMMdd_HHmmss")
    filepath := ScreenshotDir "\screenshot_" timestamp ".png"

    psCommand := 'Add-Type -AssemblyName System.Windows.Forms; Add-Type -AssemblyName System.Drawing; $img = [System.Windows.Forms.Clipboard]::GetImage(); if ($img) { $img.Save(\"' filepath '\", [System.Drawing.Imaging.ImageFormat]::Png) }'

    RunWait('powershell -NoProfile -Command "' psCommand '"',, "Hide")

    if FileExist(filepath)
        return filepath
    return ""
}

SetClipboardToFile(filepath) {
    ; 使用 PowerShell 设置剪贴板为文件引用
    psCommand := 'Add-Type -AssemblyName System.Windows.Forms; $fc = New-Object System.Collections.Specialized.StringCollection; $fc.Add(\"' filepath '\"); [System.Windows.Forms.Clipboard]::SetFileDropList($fc)'

    RunWait('powershell -NoProfile -Command "' psCommand '"',, "Hide")
}

CleanupOldScreenshots() {
    ; 获取所有截图文件，按修改时间排序
    files := []
    loop files ScreenshotDir "\screenshot_*.png" {
        files.Push({path: A_LoopFileFullPath, time: A_LoopFileTimeModified})
    }

    ; 如果超过限制，删除最旧的文件
    if files.Length > MaxScreenshots {
        ; 按时间排序（旧的在前）
        files := SortByTime(files)

        ; 删除多余的旧文件
        deleteCount := files.Length - MaxScreenshots
        loop deleteCount {
            try FileDelete(files[A_Index].path)
        }
    }
}

SortByTime(arr) {
    ; 简单冒泡排序，按时间升序
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

; 托盘菜单
A_TrayMenu.Delete()
A_TrayMenu.Add("打开截图目录", (*) => Run(ScreenshotDir))
A_TrayMenu.Add()
A_TrayMenu.Add("退出", (*) => ExitApp())

; 托盘提示
TrayTip("剪贴板图片转换", "已启动，Ctrl+V 自动转换截图", 1)

; ========================================
; Shift+Enter 换行（用于 Claude Code）
; ========================================
; 在终端中 Shift+Enter 发送反斜杠+回车实现换行
+Enter:: {
    SendInput("\{Enter}")
}
