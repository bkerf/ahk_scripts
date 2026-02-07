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
# 剪贴板刚发生变化时的冷却计数，避免读到截图工具的中间状态
$cooldown = 0

# 用像素采样生成内容哈希，区分同尺寸但不同内容的截图
function Get-ImageContentHash {
    param([System.Drawing.Bitmap]$bmp)
    try {
        $w = $bmp.Width; $h = $bmp.Height
        $sb = [System.Text.StringBuilder]::new(256)
        [void]$sb.Append("${w}x${h}|")
        # 采样 16 个均匀分布的像素点
        $stepsX = [Math]::Max(1, [int]($w / 4))
        $stepsY = [Math]::Max(1, [int]($h / 4))
        for ($y = 0; $y -lt $h; $y += $stepsY) {
            for ($x = 0; $x -lt $w; $x += $stepsX) {
                $px = $bmp.GetPixel($x, $y)
                [void]$sb.Append("$($px.R),$($px.G),$($px.B);")
            }
        }
        return $sb.ToString()
    }
    catch {
        return $null
    }
}

# 带重试的剪贴板写入
function Set-ClipboardFileDropListSafe {
    param([string]$filepath)
    for ($attempt = 1; $attempt -le 3; $attempt++) {
        try {
            $fileCollection = New-Object System.Collections.Specialized.StringCollection
            $fileCollection.Add($filepath) | Out-Null
            [System.Windows.Forms.Clipboard]::SetFileDropList($fileCollection)

            # 验证写入成功
            Start-Sleep -Milliseconds 50
            $verify = [System.Windows.Forms.Clipboard]::GetDataObject()
            if ($verify -and $verify.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
                $files = $verify.GetData([System.Windows.Forms.DataFormats]::FileDrop)
                if ($files -and $files.Count -gt 0 -and $files[0] -eq $filepath) {
                    return $true
                }
            }
            Write-Host "  [重试 $attempt/3] 验证失败，重新写入..." -ForegroundColor Yellow
            Start-Sleep -Milliseconds 100
        }
        catch {
            Write-Host "  [重试 $attempt/3] 写入异常: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Milliseconds 200
        }
    }
    return $false
}

while ($true) {
    try {
        $clipboard = [System.Windows.Forms.Clipboard]::GetDataObject()

        if (-not $clipboard) {
            Start-Sleep -Milliseconds 500
            continue
        }

        # 检查是否有图片且不是文件引用
        $hasBitmap = $clipboard.GetDataPresent([System.Windows.Forms.DataFormats]::Bitmap)
        $hasFileDrop = $clipboard.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)

        if ($hasBitmap -and -not $hasFileDrop) {
            # 首次检测到新图片，等待截图工具写入完成再处理
            if ($cooldown -lt 2) {
                $cooldown++
                Start-Sleep -Milliseconds 300
                continue
            }

            $image = $null
            try {
                $image = [System.Windows.Forms.Clipboard]::GetImage()

                if ($image -and $image.Width -gt 1 -and $image.Height -gt 1) {
                    $currentHash = Get-ImageContentHash -bmp $image

                    if ($currentHash -and $currentHash -ne $lastImageHash) {
                        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss_fff"
                        $filepath = Join-Path $screenshotDir "screenshot_${timestamp}.png"

                        $image.Save($filepath, [System.Drawing.Imaging.ImageFormat]::Png)

                        if (Test-Path $filepath) {
                            $ok = Set-ClipboardFileDropListSafe -filepath $filepath
                            if ($ok) {
                                $lastImageHash = $currentHash
                                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 已转换: $filepath" -ForegroundColor Green
                            }
                            else {
                                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 写入剪贴板失败，文件已保存: $filepath" -ForegroundColor Red
                            }
                        }
                    }
                }
            }
            finally {
                # 释放 GDI+ 资源
                if ($image) { $image.Dispose() }
            }

            $cooldown = 0
        }
        else {
            $cooldown = 0
        }
    }
    catch {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] 错误: $($_.Exception.Message)" -ForegroundColor DarkYellow
        $cooldown = 0
    }

    Start-Sleep -Milliseconds 500
}
