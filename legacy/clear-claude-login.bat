@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\tools\clear-claude-login.ps1" %*
