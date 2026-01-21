<#
.SYNOPSIS
    后台监控剪贴板，自动将截图转换为文件引用
.DESCRIPTION
    运行此脚本后，当你使用 Win+Shift+S 截图，剪贴板会自动转换为文件引用，
    这样就可以直接 Ctrl+V 粘贴到 Claude Code
.EXAMPLE
    Start-ClipboardMonitor
    # 或后台运行
    Start-Job { C:\Users\七道易\ClipboardMonitor.ps1 }
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$screenshotDir = "$env:TEMP\Screenshots"
if (-not (Test-Path $screenshotDir)) {
    New-Item -ItemType Directory -Path $screenshotDir -Force | Out-Null
}

Write-Host "剪贴板监控已启动..." -ForegroundColor Green
Write-Host "截图保存目录: $screenshotDir" -ForegroundColor Cyan
Write-Host "按 Ctrl+C 停止" -ForegroundColor Yellow
Write-Host ""

$lastImageHash = $null

while ($true) {
    try {
        $clipboard = [System.Windows.Forms.Clipboard]::GetDataObject()

        # 检查是否有图片且不是文件引用
        $hasBitmap = $clipboard.GetDataPresent([System.Windows.Forms.DataFormats]::Bitmap)
        $hasFileDrop = $clipboard.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)

        if ($hasBitmap -and -not $hasFileDrop) {
            $image = $clipboard.GetData([System.Windows.Forms.DataFormats]::Bitmap)

            if ($image) {
                # 计算简单哈希避免重复处理
                $currentHash = "$($image.Width)x$($image.Height)"

                if ($currentHash -ne $lastImageHash) {
                    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                    $filepath = Join-Path $screenshotDir "screenshot_${timestamp}.png"

                    $image.Save($filepath, [System.Drawing.Imaging.ImageFormat]::Png)

                    # 转换为文件引用
                    $fileCollection = New-Object System.Collections.Specialized.StringCollection
                    $fileCollection.Add($filepath)
                    [System.Windows.Forms.Clipboard]::SetFileDropList($fileCollection)

                    $lastImageHash = $currentHash

                    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 已转换: $filepath" -ForegroundColor Green
                }
            }
        }
    }
    catch {
        # 忽略剪贴板访问错误
    }

    Start-Sleep -Milliseconds 300
}
