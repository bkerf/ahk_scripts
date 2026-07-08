# ahk_scripts 结构重构实施计划

- 日期：2026-07-08
- 来源：`docs/superpowers/specs/2026-07-08-ahk-scripts-restructure-design.md`
- 状态：已实施，待最终人工热键冒烟

## 实施清单

- [x] 创建 `lib/`，将 `UnifiedHotkeys.ahk` 内联逻辑拆为 `Common.ahk`、`Clipboard.ahk`、`Media.ahk`、`SmartPlayer.ahk`。
- [x] 保持 `UnifiedHotkeys.ahk` 为唯一常驻组合入口，通过 `#Include` 加载模块。
- [x] 创建 `services/`，移动 `media_listener.py` 并更新 `StartAll.ahk`。
- [x] 创建 `tools/`，移动 `translator.ahk`、`translator.py`、`clear-claude-login.ps1`。
- [x] 创建 `legacy/`，归档旧独立脚本和未接入实现，并补充 `legacy/README.md`。
- [x] 收敛文档入口：`AGENTS.md` 为 canonical，`CLAUDE.md` 只指向 `AGENTS.md`。
- [x] 更新用户向 `README.md`。
- [x] 增加启动前精确清理旧媒体监听进程，避免重复占用 `127.0.0.1:5001`。

## 验证清单

- [x] `AutoHotkey64.exe /Validate .\UnifiedHotkeys.ahk` 通过。
- [x] `AutoHotkey64.exe /Validate .\StartAll.ahk` 通过。
- [x] `AutoHotkey64.exe /Validate .\tools\translator.ahk` 通过。
- [x] 临时 AHK 模块冒烟通过：初始化 `Common` / `Clipboard` / `Media` / `SmartPlayer`，并确认 `TCP_QUERY=playing`。
- [x] 受控剪贴板核心冒烟通过：临时放入测试图片，`SaveClipboardImage()` 生成 PNG，`SetClipboardToFile()` 写入文件引用，并恢复原剪贴板。
- [x] 受控热键依赖冒烟通过：`ToggleHomeMediaControl()` 可关闭/恢复，终端窗口条件返回有效窗口句柄，Smart Player 标题白名单可命中。
- [x] PowerShell AST 解析通过：`tools\clear-claude-login.ps1`、`legacy\ClipboardMonitor.ps1`、`legacy\CheckMediaPlaying.ps1`。
- [x] `.venv\Scripts\python.exe -m py_compile services\media_listener.py tools\translator.py legacy\check_media.py` 通过。
- [x] `.venv\Scripts\python.exe services\media_listener.py --check` 打印 `playing`。
- [x] `.venv\Scripts\python.exe tools\translator.py --help` 正常输出用法。
- [x] 实际运行 `StartAll.ahk` 后，旧媒体监听父子进程被替换，`UnifiedHotkeys.ahk` 单实例运行，`127.0.0.1:5001` 返回 `playing`。
- [ ] 手动按键冒烟：真实 `Ctrl+V` 粘贴到目标应用、`Shift+Enter`、`Home`、`Win+H`、`F1`。
- [ ] `Win+Shift+C` 会关闭浏览器并清理 claude.ai/anthropic 数据，需用户明确确认后再做破坏性冒烟。
- [ ] `start "" ".\tools\translator.ahk"` 后验证翻译剪贴板读写与真实 `DEEPL_API_KEY`。

## 未自动执行项

- `Ctrl+V` 的图片转文件核心逻辑已用受控剪贴板验证；真实粘贴仍会向当前活动应用发送按键，保留为人工冒烟。
- `Shift+Enter`、`Home`、`Win+H`、`F1` 都会向当前桌面会话发送真实按键或影响媒体状态，保留为人工冒烟。
- `Win+Shift+C` 会关闭 Chrome/Edge/Brave 并删除 claude.ai/anthropic 相关浏览器数据，未经用户确认不得自动执行。
- `tools/translator.ahk` 闭环会读取/覆盖剪贴板并调用真实 DeepL API，只做语法与 `translator.py --help` 验证；真实翻译需用户确认 `DEEPL_API_KEY` 和剪贴板内容。
