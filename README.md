# AHK Scripts

Windows 自动化脚本集合，基于 AutoHotkey v2。默认只启动一个常驻入口：`UnifiedHotkeys.ahk`。

## 目录

| 路径 | 说明 |
|------|------|
| `StartAll.ahk` | 启动 `UnifiedHotkeys.ahk` 和媒体监听服务后退出 |
| `UnifiedHotkeys.ahk` | 单托盘组合入口，include `lib/` 模块 |
| `lib/` | 常驻热键模块 |
| `services/media_listener.py` | pycaw TCP 媒体监听服务，监听 `127.0.0.1:5001` |
| `tools/` | 按需工具：翻译、Claude 登录痕迹清理 |
| `legacy/` | 已归档旧脚本，不参与默认运行 |

## 默认热键

| 热键 | 行为 |
|------|------|
| `Ctrl+V` | 检测剪贴板图片，必要时转成 PNG 文件引用后粘贴 |
| `Ctrl+Shift+V` | 仅终端窗口：上传剪贴板截图/文件到 `node-99:/Users/ok/Desktop/tmp/`，设置 node-99 macOS 图片剪贴板，并触发 Codex 图片粘贴；同一剪贴板文件重复按只复用上次上传结果 |
| `Shift+Enter` | 仅终端窗口中发送 `\` + 回车 |
| `Home` | 媒体播放/暂停，可在托盘菜单关闭后恢复普通 Home |
| `Win+H` | 若正在播放则暂停媒体，2 分钟后恢复，再打开语音输入 |
| `F1` | 非 Smart Player 窗口中拦截帮助键 |
| `Win+Shift+C` | 清理 claude.ai/anthropic 浏览器痕迹 |

### 终端截图粘贴

`Ctrl+Shift+V` 用于 Windows Terminal SSH 到 `node-99` 后，在远端 Codex TUI 里粘贴截图图片。它不是粘贴路径文本：

1. 读取当前 Windows 剪贴板截图或截图文件。
2. 上传到 `node-99:/Users/ok/Desktop/tmp/`。
3. 通过 `osascript` 把 node-99 的 macOS 剪贴板设置为该 PNG。
4. 向终端发送原始 `Ctrl+V` 控制字符，让 Codex TUI 走图片粘贴入口。

不要改成粘贴 `@文件名`、绝对路径或 `Use view_image...` 文本。`@` 只会触发 Codex 文件 mention 搜索，可能显示 `no matches`，不会稳定变成图片附件。

翻译工具不随开机启动。需要时运行 `tools/translator.ahk`：

| 热键 | 行为 |
|------|------|
| `Ctrl+Shift+T` | 翻译为英文并粘贴 |
| `Ctrl+Alt+Shift+T` | 翻译为中文并粘贴 |
| `Ctrl+Shift+Y` | 仅翻译到剪贴板 |

## 使用

1. 安装 AutoHotkey v2。
2. 安装 Python 依赖到本地 `.venv`。
3. 运行：

```powershell
start "" ".\StartAll.ahk"
```

`StartAll.ahk` 会注册自身到 Windows 启动目录，并在每次启动前清理本仓库旧的 `media_listener.py --tcp` 进程，避免重复占用端口。

## 常用检查

```powershell
.venv\Scripts\python.exe services\media_listener.py --check
.venv\Scripts\python.exe services\media_listener.py --tcp
ssh node-99 "osascript -e 'clipboard info'"
.venv\Scripts\python.exe tools\translator.py --help
start "" ".\tools\translator.ahk"
```

翻译功能需要环境变量 `DEEPL_API_KEY`。媒体监听依赖 `pycaw` 和 `comtypes`。

## 归档脚本

旧的独立功能脚本已移入 `legacy/`。默认启动链路不再使用它们；热键行为以 `UnifiedHotkeys.ahk` 和 `lib/` 模块为准。
