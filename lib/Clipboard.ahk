; lib/Clipboard.ahk
; Ctrl+V 剪贴板图片转文件，终端截图上传，以及终端 Shift+Enter 换行。

InitializeClipboardModule() {
    global ScreenshotDir, MaxScreenshots, SshScreenshotHost, SshScreenshotDir
    global LastSshUploadLocalPath, LastSshUploadSignature, LastSshUploadRemotePath
    global LastSshPasteTriggerTick

    ScreenshotDir := A_Temp "\Screenshots"
    MaxScreenshots := 50
    SshScreenshotHost := "node-99"
    SshScreenshotDir := "/Users/ok/Desktop/tmp"
    LastSshUploadLocalPath := ""
    LastSshUploadSignature := ""
    LastSshUploadRemotePath := ""
    LastSshPasteTriggerTick := 0

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

GetClipboardFilePath() {
    outFile := A_Temp "\ahk_clipboard_file_" A_TickCount ".txt"
    psCommand := "Add-Type -AssemblyName System.Windows.Forms; $files = [System.Windows.Forms.Clipboard]::GetFileDropList(); if ($files.Count -gt 0) { Set-Content -LiteralPath '" outFile "' -Value $files[0] -NoNewline -Encoding UTF8 }"
    RunWait('powershell -NoProfile -Command "' psCommand '"',, "Hide")

    filepath := ""
    if FileExist(outFile) {
        filepath := Trim(FileRead(outFile, "UTF-8"), " `t`r`n")
        try FileDelete(outFile)
    }

    return filepath
}

GetClipboardTextFilePath() {
    text := Trim(A_Clipboard, " `t`r`n")
    if !text
        return ""

    firstLine := Trim(StrSplit(text, "`n")[1], " `t`r`n")
    if StrLen(firstLine) >= 2
        && SubStr(firstLine, 1, 1) = '"'
        && SubStr(firstLine, StrLen(firstLine), 1) = '"'
        firstLine := SubStr(firstLine, 2, StrLen(firstLine) - 2)

    if FileExist(firstLine)
        return firstLine
    return ""
}

ResolveClipboardScreenshotFile() {
    if ClipboardHasFiles() {
        filepath := GetClipboardFilePath()
        if filepath && FileExist(filepath)
            return filepath
    }

    if ClipboardHasImage() {
        filepath := SaveClipboardImage()
        if filepath {
            SetClipboardToFile(filepath)
            Sleep(100)
            return filepath
        }
    }

    return GetClipboardTextFilePath()
}

GetFileSignature(filepath) {
    if !FileExist(filepath)
        return ""

    try {
        return FileGetSize(filepath, "B") ":" FileGetTime(filepath, "M")
    } catch {
        return ""
    }
}

GetCachedSshRemotePath(localPath) {
    global LastSshUploadLocalPath, LastSshUploadSignature, LastSshUploadRemotePath

    signature := GetFileSignature(localPath)
    if signature
        && localPath = LastSshUploadLocalPath
        && signature = LastSshUploadSignature
        && LastSshUploadRemotePath
        return LastSshUploadRemotePath
    return ""
}

RememberSshUpload(localPath, remotePath) {
    global LastSshUploadLocalPath, LastSshUploadSignature, LastSshUploadRemotePath

    signature := GetFileSignature(localPath)
    if !signature
        return

    LastSshUploadLocalPath := localPath
    LastSshUploadSignature := signature
    LastSshUploadRemotePath := remotePath
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

UploadFileToSshHost(localPath) {
    global SshScreenshotHost, SshScreenshotDir

    SplitPath(localPath, &filename)
    if !filename
        return ""

    command := Format(
        'cmd /c ssh -o BatchMode=yes -o ConnectTimeout=10 {1} "mkdir -p {2}" && scp -o BatchMode=yes -o ConnectTimeout=10 "{3}" "{1}:{2}/"',
        SshScreenshotHost,
        SshScreenshotDir,
        localPath
    )

    if RunWait(command,, "Hide") != 0
        return ""

    return SshScreenshotDir "/" filename
}

PasteText(text) {
    SendText(text)
}

EscapeAppleScriptString(text) {
    text := StrReplace(text, "\", "\\")
    return StrReplace(text, '"', '\"')
}

SetRemoteMacClipboardToImage(remotePath) {
    global SshScreenshotHost

    scriptFile := A_Temp "\ahk_remote_image_clipboard_" A_TickCount ".scpt"
    script := 'set imageFile to POSIX file "' EscapeAppleScriptString(remotePath) '"' "`n"
    script .= 'set the clipboard to (read imageFile as «class PNGf»)' "`n"

    try {
        FileAppend(script, scriptFile, "UTF-8")
        command := Format(
            'cmd /c ssh -o BatchMode=yes -o ConnectTimeout=10 {1} osascript < "{2}"',
            SshScreenshotHost,
            scriptFile
        )
        return RunWait(command,, "Hide") = 0
    } catch {
        return false
    } finally {
        try FileDelete(scriptFile)
    }
}

TriggerCodexImagePaste() {
    global LastSshPasteTriggerTick

    if A_TickCount - LastSshPasteTriggerTick < 1500
        return

    ; Codex TUI binds Ctrl+V to fixed.paste_image. Send the control byte,
    ; not Windows Terminal's local paste command.
    SendText(Chr(22))
    LastSshPasteTriggerTick := A_TickCount
}

UploadClipboardScreenshotToSsh(*) {
    filepath := ResolveClipboardScreenshotFile()
    if !filepath {
        TrayTip("AHK Scripts", "剪贴板里没有可上传的截图文件", 2)
        return
    }

    remotePath := GetCachedSshRemotePath(filepath)
    if !remotePath {
        remotePath := UploadFileToSshHost(filepath)
        if !remotePath {
            TrayTip("AHK Scripts", "上传到 node-99 失败", 3)
            return
        }

        RememberSshUpload(filepath, remotePath)
    }

    if !SetRemoteMacClipboardToImage(remotePath) {
        TrayTip("AHK Scripts", "设置 node-99 图片剪贴板失败", 3)
        return
    }

    TriggerCodexImagePaste()
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
$^+v:: UploadClipboardScreenshotToSsh()

+Enter:: {
    SendInput("\{Enter}")
}
#HotIf
