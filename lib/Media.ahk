; lib/Media.ahk
; Home 媒体控制与 Win+H 语音输入前暂停媒体。

InitializeMediaModule() {
    global HomeMediaEnabled

    HomeMediaEnabled := true
}

ToggleHomeMediaControl(*) {
    global HomeMediaEnabled

    HomeMediaEnabled := !HomeMediaEnabled
    if HomeMediaEnabled
        A_TrayMenu.Check("Home Media Control")
    else
        A_TrayMenu.Uncheck("Home Media Control")
}

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

Home:: {
    global HomeMediaEnabled

    if !HomeMediaEnabled {
        Send "{Home}"
        return
    }

    Send "{Media_Play_Pause}"
    Log("HOME pressed - Media Play/Pause toggled")
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
