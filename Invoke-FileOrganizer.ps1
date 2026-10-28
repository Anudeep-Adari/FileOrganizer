# ==============================================================================
# Script: Invoke-FileOrganizer.ps1
# Description: Smart Desktop & Downloads Auto-Organizer & File Triage Engine
# Supports: -Preview (Dry-run), -Run (Execute), -Undo (Rollback), -Silent
# ==============================================================================

param(
    [switch]$Preview,
    [switch]$Run,
    [switch]$Undo,
    [switch]$Silent,
    [switch]$InstallAutoRun,
    [switch]$RemoveAutoRun,
    [switch]$Status
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$scriptPath = $MyInvocation.MyCommand.Definition
$enginePy = Join-Path $scriptDir "organizer_engine.py"
$startupDir = [System.IO.Path]::Combine($env:APPDATA, "Microsoft\Windows\Start Menu\Programs\Startup")
$autoRunVbs = Join-Path $startupDir "FileOrganizer_AutoRun.vbs"

function Show-ToastNotification {
    param(
        [string]$Title,
        [string]$Message,
        [string]$Subtext = ""
    )
    try {
        $appId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
        [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
        $template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
        $textNodes = $template.GetElementsByTagName("text")
        $textNodes.Item(0).AppendChild($template.CreateTextNode($Title)) | Out-Null
        $body = if ($Subtext) { "$Message`n$Subtext" } else { $Message }
        $textNodes.Item(1).AppendChild($template.CreateTextNode($body)) | Out-Null
        $toast = [Windows.UI.Notifications.ToastNotification]::new($template)
        $toast.Tag = "FileOrganizer"
        $toast.Group = "SystemHygiene"
        [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId).Show($toast)
    } catch {}
}

if ($Undo) {
    if (-not $Silent) {
        Write-Host "==========================================================" -ForegroundColor Yellow
        Write-Host "ROLLING BACK LAST FILE ORGANIZATION RUN..." -ForegroundColor Yellow
        Write-Host "==========================================================" -ForegroundColor Yellow
    }

    $raw = python $enginePy undo
    $res = $raw | ConvertFrom-Json

    if ($res.status -eq "SUCCESS") {
        if (-not $Silent) {
            Write-Host "SUCCESS: Restored $($res.restored_count) files ($($res.restored_mb) MB) to original locations!" -ForegroundColor Green
        }
        Show-ToastNotification -Title "File Organizer: Rollback Complete" `
            -Message "Restored $($res.restored_count) files ($($res.restored_mb) MB)." `
            -Subtext "All files returned to their original paths."
    } else {
        if (-not $Silent) {
            Write-Host "No previous completed organization runs to undo." -ForegroundColor DarkGray
        }
    }
    return
}

if ($Run) {
    if (-not $Silent) {
        Write-Host "==========================================================" -ForegroundColor Cyan
        Write-Host "EXECUTING SMART FILE TRIAGE & ORGANIZATION..." -ForegroundColor Cyan
        Write-Host "==========================================================" -ForegroundColor Cyan
    }

    $raw = python $enginePy organize
    $res = $raw | ConvertFrom-Json

    if ($res.status -eq "SUCCESS" -and $res.moved_count -gt 0) {
        if (-not $Silent) {
            Write-Host "SUCCESS: Organized $($res.moved_count) files ($($res.total_mb) MB) into D:\Organized!" -ForegroundColor Green
            Write-Host "Run ID: $($res.run_id) (Logged to journal for 1-click Undo)" -ForegroundColor Gray
        }
        Show-ToastNotification -Title "Downloads & Desktop Organized" `
            -Message "Triage completed: Moved $($res.moved_count) files ($($res.total_mb) MB)." `
            -Subtext "Saved to D:\Organized • 100% reversible via Undo"
    } else {
        if (-not $Silent) {
            Write-Host "Downloads and Desktop are already clean! (No files matched triage criteria)." -ForegroundColor Green
        }
    }
    return
}

if ($InstallAutoRun) {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "INSTALLING AUTORUN TO WINDOWS STARTUP..." -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan

    $vbsContent = @"
' FileOrganizer Silent Auto-Run Launcher
' Runs smart desktop and downloads organization silently on user logon
Set WshShell = CreateObject("WScript.Shell")
psCmd = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File ""$scriptPath"" -Run -Silent"
WshShell.Run psCmd, 0, False
"@

    Set-Content -Path $autoRunVbs -Value $vbsContent -Encoding ASCII
    Write-Host "SUCCESS: Auto-Run installed to Windows Startup!" -ForegroundColor Green
    Write-Host "Location: $autoRunVbs" -ForegroundColor Gray
    Write-Host "FileOrganizer will now run automatically on every system logon/startup." -ForegroundColor Green
    return
}

if ($RemoveAutoRun) {
    Write-Host "==========================================================" -ForegroundColor Yellow
    Write-Host "REMOVING AUTORUN FROM WINDOWS STARTUP..." -ForegroundColor Yellow
    Write-Host "==========================================================" -ForegroundColor Yellow

    if (Test-Path $autoRunVbs) {
        Remove-Item -Path $autoRunVbs -Force
        Write-Host "SUCCESS: Auto-Run script removed from Windows Startup." -ForegroundColor Green
    } else {
        Write-Host "Auto-Run was not configured in Windows Startup." -ForegroundColor Gray
    }
    return
}

$isAutoRunInstalled = Test-Path $autoRunVbs

if ($Status) {
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host "FILE ORGANIZER ENGINE STATUS" -ForegroundColor Cyan
    Write-Host "==========================================================" -ForegroundColor Cyan
    if ($isAutoRunInstalled) {
        Write-Host "AutoRun (Windows Startup) : ENABLED" -ForegroundColor Green
        Write-Host "Startup Script Location   : $autoRunVbs" -ForegroundColor Gray
    } else {
        Write-Host "AutoRun (Windows Startup) : NOT CONFIGURED" -ForegroundColor Yellow
        Write-Host "To enable AutoRun, execute: .\Invoke-FileOrganizer.ps1 -InstallAutoRun" -ForegroundColor Gray
    }

    $journalPath = Join-Path $scriptDir "journal.json"
    if (Test-Path $journalPath) {
        try {
            $j = Get-Content $journalPath | ConvertFrom-Json
            Write-Host "Total Recorded Runs       : $($j.Count)" -ForegroundColor White
            if ($j.Count -gt 0) {
                $last = $j[-1]
                Write-Host "Last Run ID               : $($last.run_id) ($($last.timestamp))" -ForegroundColor White
                Write-Host "Last Files Organized      : $($last.files.Count)" -ForegroundColor White
            }
        } catch {}
    }
    Write-Host "==========================================================" -ForegroundColor Cyan
    return
}

# Default: Preview Mode
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "SMART DESKTOP & DOWNLOADS AUTO-ORGANIZER PREVIEW (DRY-RUN)" -ForegroundColor Cyan
if ($isAutoRunInstalled) {
    Write-Host "AutoRun Status: [ENABLED (Active on logon)]" -ForegroundColor Green
} else {
    Write-Host "AutoRun Status: [NOT SET ON AUTORUN - Run with -InstallAutoRun to enable]" -ForegroundColor Yellow
}
Write-Host "==========================================================" -ForegroundColor Cyan

$raw = python $enginePy preview
$res = $raw | ConvertFrom-Json

if ($res.candidate_count -eq 0) {
    Write-Host "All clear! No loose files pending organization." -ForegroundColor Green
    Write-Host ""
    if (-not $isAutoRunInstalled) {
        Write-Host "Tip: To set FileOrganizer on autorun, run:" -ForegroundColor Cyan
        Write-Host "  .\Invoke-FileOrganizer.ps1 -InstallAutoRun" -ForegroundColor White
    }
    return
}

Write-Host "Found $($res.candidate_count) candidate files ($($res.total_mb) MB) eligible for triage:" -ForegroundColor Yellow
Write-Host ""
$res.items | Format-Table -Property @(
    @{Label="Filename"; Expression={$_.filename}; Width=45},
    @{Label="Category"; Expression={$_.category}; Width=22},
    @{Label="Age (hrs)"; Expression={$_.age_hours}; Width=10},
    @{Label="Size"; Expression={"{0:N2} MB" -f ($_.size_bytes / 1MB)}; Width=12}
)

Write-Host "----------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "To execute organization, run:" -ForegroundColor Cyan
Write-Host "  .\Invoke-FileOrganizer.ps1 -Run" -ForegroundColor White
Write-Host "To undo any organization, run:" -ForegroundColor Yellow
Write-Host "  .\Invoke-FileOrganizer.ps1 -Undo" -ForegroundColor White
if (-not $isAutoRunInstalled) {
    Write-Host "To enable AutoRun on boot, run:" -ForegroundColor Cyan
    Write-Host "  .\Invoke-FileOrganizer.ps1 -InstallAutoRun" -ForegroundColor White
}
Write-Host "==========================================================" -ForegroundColor Cyan
