<#
.SYNOPSIS
  Draws the BVM icon (chat bubble with a keyhole on teal) as PNG files:
  the legacy launcher icons in android\app\src\main\res\mipmap-*, plus the
  Google Play listing graphics in docs\store\ (512x512 app icon, 1024x500
  feature graphic). Same artwork as res\drawable\ic_launcher_foreground.xml.
#>
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$repo = Split-Path -Parent $PSScriptRoot
$teal = [System.Drawing.Color]::FromArgb(255, 0x2F, 0x5D, 0x62)

# The 108-unit adaptive-icon artwork as a GDI+ path (keyhole as a hole).
function New-IconPath([float] $scale, [float] $dx, [float] $dy) {
    $p = New-Object System.Drawing.Drawing2D.GraphicsPath
    $p.FillMode = [System.Drawing.Drawing2D.FillMode]::Alternate
    $r = 20  # corner diameter (radius 10)
    $p.StartFigure()
    $p.AddArc(30, 32, $r, $r, 180, 90)
    $p.AddArc(58, 32, $r, $r, 270, 90)
    $p.AddArc(58, 48, $r, $r, 0, 90)
    $p.AddLine(58, 68, 48, 68)
    $p.AddLine(48, 68, 38, 76)
    $p.AddLine(38, 76, 38, 68)
    $p.AddArc(30, 48, $r, $r, 90, 90)
    $p.CloseFigure()
    $p.StartFigure()
    # Keyhole: circle centre (54, 45.5), r 5.5, joined to the stem.
    $p.AddArc(48.5, 40, 11, 11, 116.1, 307.8)
    $p.AddLine(56.4, 50.45, 58, 60)
    $p.AddLine(58, 60, 50, 60)
    $p.CloseFigure()
    $m = New-Object System.Drawing.Drawing2D.Matrix
    $m.Translate($dx, $dy)
    $m.Scale($scale, $scale)
    $p.Transform($m)
    return $p
}

function New-Canvas([int] $w, [int] $h) {
    $bmp = New-Object System.Drawing.Bitmap($w, $h, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    return $bmp, $g
}

# Square icon: teal background, artwork scaled so the 108 canvas fills it.
function Save-Icon([int] $size, [string] $path, [bool] $round) {
    $bmp, $g = New-Canvas $size $size
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush($teal)
    if ($round) { $g.FillEllipse($brush, 0, 0, $size, $size) } else { $g.FillRectangle($brush, 0, 0, $size, $size) }
    # The artwork spans x 30..78 / y 32..76 of 108; enlarge for a legacy icon.
    $scale = $size / 108.0 * 1.35
    $off = ($size - 108 * $scale) / 2
    $g.FillPath([System.Drawing.Brushes]::White, (New-IconPath $scale $off $off))
    New-Item -ItemType Directory -Force -Path (Split-Path $path) | Out-Null
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
}

$densities = @{ 'mdpi' = 48; 'hdpi' = 72; 'xhdpi' = 96; 'xxhdpi' = 144; 'xxxhdpi' = 192 }
foreach ($d in $densities.Keys) {
    Save-Icon $densities[$d] (Join-Path $repo "android\app\src\main\res\mipmap-$d\ic_launcher.png") $false
}

$store = Join-Path $repo 'docs\store'
Save-Icon 512 (Join-Path $store 'icon-512.png') $false

# Feature graphic 1024x500: icon on the left, name and tagline on the right.
$bmp, $g = New-Canvas 1024 500
$g.Clear($teal)
$scale = 4.6
$g.FillPath([System.Drawing.Brushes]::White, (New-IconPath $scale (40 - 30 * $scale + 60) (250 - 54 * $scale)))
$title = New-Object System.Drawing.Font('Segoe UI Semibold', 96, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$sub = New-Object System.Drawing.Font('Segoe UI', 38, [System.Drawing.FontStyle]::Regular, [System.Drawing.GraphicsUnit]::Pixel)
$g.DrawString('BVM', $title, [System.Drawing.Brushes]::White, 440, 140)
$g.DrawString('Private 1-to-1 messenger', $sub, [System.Drawing.Brushes]::White, 446, 265)
$g.DrawString('End-to-end encrypted', $sub, [System.Drawing.Brushes]::White, 446, 315)
$bmp.Save((Join-Path $store 'feature-graphic-1024x500.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()

Write-Host "Launcher PNGs updated; Play graphics in $store"
