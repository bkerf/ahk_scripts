# CheckMediaPlaying.ps1
# 检测当前媒体是否正在播放

try {
    Add-Type -AssemblyName System.Runtime.WindowsRuntime
    $null = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager, Windows.Media.Control, ContentType = WindowsRuntime]
    $asyncOp = [Windows.Media.Control.GlobalSystemMediaTransportControlsSessionManager]::RequestAsync()
    $taskGeneric = [System.WindowsRuntimeSystemExtensions]::AsTask($asyncOp)
    $taskGeneric.Wait()
    $sessionManager = $taskGeneric.Result
    $session = $sessionManager.GetCurrentSession()
    if ($session) {
        $playbackInfo = $session.GetPlaybackInfo()
        if ($playbackInfo.PlaybackStatus -eq 'Playing') {
            exit 0  # 正在播放
        }
    }
    exit 1  # 未播放
} catch {
    exit 1  # 出错，视为未播放
}
