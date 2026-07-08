; lib/SmartPlayer.ahk
; Smart Player F1 白名单与 Claude 登录痕迹清理快捷键。

InitializeSmartPlayerModule() {
    global SmartPlayerAllowedTitleKeywords

    SmartPlayerAllowedTitleKeywords := [
        "智能玩家系统",
        "Smart Player",
        "任务编辑器",
        "智能节点配置中心"
    ]
}

IsSmartPlayerWindowActive() {
    global SmartPlayerAllowedTitleKeywords

    try {
        title := WinGetTitle("A")
    } catch {
        return false
    }

    for keyword in SmartPlayerAllowedTitleKeywords {
        if InStr(title, keyword)
            return true
    }

    return false
}

#HotIf !IsSmartPlayerWindowActive()
$F1:: {
    return
}
#HotIf

#+c:: {
    claudeCleaner := A_ScriptDir "\tools\clear-claude-login.ps1"
    Run('powershell -NoProfile -ExecutionPolicy Bypass -File "' claudeCleaner '" -CloseBrowsers -VerboseOutput', , "Hide")
}
