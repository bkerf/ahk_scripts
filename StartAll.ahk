; StartAll.ahk
; 开机启动入口：启动统一热键脚本和后台媒体监听服务，然后退出自身。

#Requires AutoHotkey v2.0
#SingleInstance Force

scriptDir := A_ScriptDir
pythonwPath := scriptDir "\.venv\Scripts\pythonw.exe"
mediaService := scriptDir "\services\media_listener.py"

StopExistingMediaListeners(scriptDir)

if FileExist(pythonwPath) && FileExist(mediaService) {
    Run(Format('"{1}" "{2}" --tcp', pythonwPath, mediaService), , "Hide")
} else {
    TrayTip("AHK Scripts", "未找到 media listener 或 pythonw.exe", 3)
}

Run(Format('"{1}\UnifiedHotkeys.ahk"', scriptDir))

shortcutPath := A_Startup "\StartAll.lnk"
if !FileExist(shortcutPath) {
    try FileCreateShortcut(A_ScriptFullPath, shortcutPath, A_ScriptDir)
}

ExitApp()

StopExistingMediaListeners(scriptDir) {
    candidates := [
        StrLower(scriptDir "\media_listener.py"),
        StrLower(scriptDir "\services\media_listener.py")
    ]

    try {
        query := "SELECT ProcessId, CommandLine FROM Win32_Process WHERE Name='python.exe' OR Name='pythonw.exe'"
        processes := ComObjGet("winmgmts:").ExecQuery(query)
        for process in processes {
            commandLine := process.CommandLine
            if !commandLine
                continue

            lowerCommand := StrLower(commandLine)
            if !InStr(lowerCommand, "--tcp")
                continue

            for candidate in candidates {
                if InStr(lowerCommand, candidate) {
                    pid := process.ProcessId
                    try {
                        process.Terminate()
                        ProcessWaitClose(pid, 2)
                    }
                    break
                }
            }
        }
    } catch {
        ; 清理失败时不阻断启动；若端口被旧服务占用，新服务会自行退出。
    }
}
