# Legacy Scripts

本目录保存旧实现，默认启动链路不使用这些文件。

| 文件 | 归档原因 |
|------|----------|
| `ClipboardImagePaste.ahk` | 已提取到 `lib/Clipboard.ahk`，由 `UnifiedHotkeys.ahk` 统一加载 |
| `Home_MediaControl.ahk` | 已提取到 `lib/Media.ahk` |
| `VoiceMediaControl.ahk` | 已提取到 `lib/Media.ahk` |
| `ClipboardMonitor.ps1` | 从未由 `StartAll.ahk` 启动；现只保留 AHK 粘贴兜底 |
| `check_media.py` | 未接入默认路径；生产媒体检测使用 `services/media_listener.py` |
| `CheckMediaPlaying.ps1` | 未接入默认路径；生产媒体检测使用 `services/media_listener.py` |
| `clear-claude-login.ahk` | AHK v1 遗留入口；当前热键在 `lib/SmartPlayer.ahk` 中调用 PowerShell 工具 |
| `clear-claude-login.bat` | 旧命令行包装入口；当前工具位于 `tools/clear-claude-login.ps1` |
| `README.txt` | 旧清理说明，已被根目录 `README.md` 和 `AGENTS.md` 取代 |
