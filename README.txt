清理步骤：
1. 安装 AutoHotkey（建议 v1.1 或 v2）。
2. 运行 clear-claude-login.ahk（可直接双击）。
3. 按 Shift + Win + C 即可触发清理。

说明：
- 触发会关闭当前用户下 Chrome/Edge/Brave 进程后清理 claude.ai/anthropic 相关的
  历史、Cookies、登录信息和本地存储。
- 脚本路径：F:\code\ahk_scripts\clear-claude-login.ps1
- 默认会清理所有浏览器（Chrome/Edge/Brave），如需仅某一项可在命令行加 -Browsers。

例如（仅清理 Chrome）：
  powershell -NoProfile -ExecutionPolicy Bypass -File clear-claude-login.ps1 -Browsers Chrome -CloseBrowsers
