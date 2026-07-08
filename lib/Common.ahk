; lib/Common.ahk
; 统一初始化与共享工具。必须最先 include。

global HomeLogFile := A_ScriptDir "\Home_debug.log"

InitializeUnifiedHotkeys() {
    InitializeCommonModule()
    InitializeClipboardModule()
    InitializeMediaModule()
    InitializeSmartPlayerModule()
    BuildTrayMenu()

    TrayTip("AHK Scripts", "已启动：剪贴板、媒体控制", 1)
}

InitializeCommonModule() {
    global HomeLogFile

    if FileExist(HomeLogFile)
        FileDelete(HomeLogFile)
    Log("=== Unified script started ===")
}

BuildTrayMenu() {
    global ScreenshotDir, HomeMediaEnabled

    A_TrayMenu.Delete()
    A_TrayMenu.Add("AHK Scripts", (*) => "")
    A_TrayMenu.Disable("AHK Scripts")
    A_TrayMenu.Add()
    A_TrayMenu.Add("Home Media Control", ToggleHomeMediaControl)
    if HomeMediaEnabled
        A_TrayMenu.Check("Home Media Control")
    A_TrayMenu.Add("打开截图目录", (*) => Run(ScreenshotDir))
    A_TrayMenu.Add()
    A_TrayMenu.Add("退出", (*) => ExitApp())
}

Log(msg) {
    global HomeLogFile

    timestamp := FormatTime(, "yyyy-MM-dd HH:mm:ss")
    FileAppend(timestamp " | " msg "`n", HomeLogFile)
}
