# Repository Guidelines

## 项目结构与模块边界

本仓库是 Windows 自动化脚本集合，主入口仍在根目录：

- `StartAll.ahk`：开机/手动启动引导脚本；启动 `services/media_listener.py --tcp` 和 `UnifiedHotkeys.ahk` 后立即退出。
- `UnifiedHotkeys.ahk`：唯一常驻 AHK 入口；负责 include `lib/` 模块、初始化托盘菜单和统一热键。
- `lib/`：AutoHotkey v2 功能模块。新增常驻热键功能时，新建 `lib/Xxx.ahk` 并在 `UnifiedHotkeys.ahk` 增加一行 `#Include`。
- `services/`：常驻后台服务，目前只有 `media_listener.py`。
- `tools/`：按需手动工具，例如 `translator.ahk`、`translator.py`、`clear-claude-login.ps1`。
- `legacy/`：归档脚本，不参与默认运行路径；只保留作查阅或临时对照。

启动权责必须保持分离：`StartAll.ahk` 只能做引导、清理旧媒体监听进程、注册启动项和退出。任何热键、托盘项或长时间自动化都必须放在 `UnifiedHotkeys.ahk` 或 `lib/` 模块里，不能加到 `StartAll.ahk`。

## 当前热键

以 `UnifiedHotkeys.ahk` + `lib/` 为准：

| 热键 | 行为 | 所属模块 |
|------|------|----------|
| `Ctrl+V` | 剪贴板图片自动转 PNG 文件引用后粘贴 | `lib/Clipboard.ahk` |
| `Ctrl+Shift+V` | 仅终端窗口：将剪贴板截图/文件上传到 `node-99:/Users/ok/Desktop/tmp/`，设置 node-99 macOS 图片剪贴板，并触发 Codex 图片粘贴；同一剪贴板文件重复按只复用上次上传结果 | `lib/Clipboard.ahk` |
| `Shift+Enter` | 终端窗口中发送 `\` + 回车 | `lib/Clipboard.ahk` |
| `Home` | 媒体播放/暂停，受托盘菜单开关控制 | `lib/Media.ahk` |
| `Win+H` | 播放中先暂停媒体，2 分钟后恢复，再透传语音输入 | `lib/Media.ahk` |
| `F1` | 非 Smart Player 窗口中拦截帮助键 | `lib/SmartPlayer.ahk` |
| `Win+Shift+C` | 调用 `tools/clear-claude-login.ps1 -CloseBrowsers` | `lib/SmartPlayer.ahk` |

`Ctrl+Shift+V` 的目标是让远端 Codex TUI 收到真实图片粘贴，不是文本路径。实现必须保持为：上传 PNG 到 `node-99:/Users/ok/Desktop/tmp/` → 用 `osascript` 设置 node-99 macOS 图片剪贴板 → 发送原始 `Ctrl+V` 控制字符。不要退回到 `@文件名`、绝对路径或 `Use view_image...` 文本；这些只会触发文件搜索或普通文本，不是 Codex 图片附件。

翻译工具不随开机启动。需要时手动运行 `tools/translator.ahk`，其热键为 `Ctrl+Shift+T`、`Ctrl+Alt+Shift+T`、`Ctrl+Shift+Y`。

## 常用命令

无构建步骤。涉及 Python 时优先使用本地虚拟环境：

```powershell
start "" ".\StartAll.ahk"
.venv\Scripts\python.exe services\media_listener.py --check
.venv\Scripts\python.exe services\media_listener.py --tcp
.venv\Scripts\python.exe tools\translator.py --help
start "" ".\tools\translator.ahk"
```

`StartAll.ahk` 是正常本地运行路径，预期结果是只有一个 `UnifiedHotkeys.ahk` 托盘图标。`services/media_listener.py --tcp` 会占用 `127.0.0.1:5001`。

## 编码风格

- 新增或修改生产 AHK 脚本必须使用 AutoHotkey v2，保留 `#Requires AutoHotkey v2.0` 和必要的 `#SingleInstance Force`。
- `legacy/clear-claude-login.ahk` 是历史 AHK v1 脚本，仅归档；不要把它当作新代码模板。
- AHK 保持现有风格：热键/函数使用花括号块，缩进 4 空格，复杂行为才写短中文注释。
- Python 使用 4 空格缩进和 `snake_case.py` 命名；PowerShell 文件使用描述性 PascalCase 或既有名称。
- 不引入构建系统或新依赖，除非用户明确要求且确实解决当前问题。

## 验证要求

本仓库没有自动化测试。行为改动后做最接近范围的验证：

- 启动改动：运行 `start "" ".\StartAll.ahk"`，确认只有一个托盘图标，且媒体 TCP 服务能响应。
- 媒体改动：运行 `.venv\Scripts\python.exe services\media_listener.py --check`，再手动验证 `Home` 和 `Win+H`。
- 剪贴板改动：手动验证截图后 `Ctrl+V` 能粘贴文件引用；终端 `Ctrl+Shift+V` 能上传到 `node-99:/Users/ok/Desktop/tmp/`、`ssh node-99 "osascript -e 'clipboard info'"` 可看到 PNG 类型，并在远端 Codex TUI 中触发图片附件，重复按同一剪贴板文件不重复上传；终端 `Shift+Enter` 行为不变。
- 翻译改动：运行 `.venv\Scripts\python.exe tools\translator.py --help`，再手动启动 `tools/translator.ahk` 验证剪贴板和 `DEEPL_API_KEY`。
- 遗留脚本只在明确维护 legacy 行为时验证，不应进入默认启动链路。

## 提交与安全

提交信息遵循 Conventional Commits：`feat:`、`fix:`、`refactor:`、`docs:`。一次提交只覆盖一个脚本或一组紧密相关行为。

不要硬编码密钥。`DEEPL_API_KEY` 必须来自环境变量。`.venv/`、日志、截图目录和机器启动项都属于本机产物，不应提交。
