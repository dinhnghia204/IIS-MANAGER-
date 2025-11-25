# ============================================================
#  SUPER IIS MANAGER v4.0 - ERROR HANDLING EDITION
# ============================================================

# --- 1. KIỂM TRA QUYỀN ADMIN ---
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host " [CRITICAL ERROR] VUI LONG CHAY SCRIPT VOI QUYEN ADMIN (Run as Administrator)!" -ForegroundColor Red
    Write-Host " Chuot phai vao file -> Chon 'Run with PowerShell'" -ForegroundColor Yellow
    Start-Sleep 5; Break
}
Import-Module WebAdministration

# ============================================================
#  CÁC HÀM XỬ LÝ (FUNCTIONS)
# ============================================================

# --- HÀM TẠO SITE (NÂNG CẤP BẮT LỖI) ---
function Setup-IISSite {
    param ([string]$Name, [int]$Port, [string]$Path)
    
    # [CHECK 1] Validate tên Site
    if ([string]::IsNullOrWhiteSpace($Name)) {
        Write-Host "   [!] TEN SITE KHONG HOP LE (Bi trong)" -ForegroundColor Red; return
    }

    # [CHECK 2] Validate Ổ đĩa (Fix lỗi DriveNotFound)
    try {
        $Drive = [System.IO.Path]::GetPathRoot($Path)
        if (!(Test-Path $Drive)) {
            Write-Host "   [!] LOI DUONG DAN: O dia '$Drive' khong ton tai tren may nay!" -ForegroundColor Red
            return # Dừng hàm ngay
        }
    } catch {
        Write-Host "   [!] DUONG DAN KHONG HOP LE: $Path" -ForegroundColor Red; return
    }

    try {
        Write-Host " [+] Dang xu ly: $Name (Port: $Port)..." -NoNewline
        
        # 1. Tạo Folder
        if (!(Test-Path $Path)) { 
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null 
        }
        if (!(Test-Path "$Path\index.html")) { 
            Set-Content -Path "$Path\index.html" -Value "<h1>$Name - Port $Port</h1>" 
        }

        # 2. Cấp quyền (Security)
        $Acl = Get-Acl $Path
        $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule("IIS_IUSRS", "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")
        $Acl.SetAccessRule($Ar); Set-Acl $Path $Acl

        # 3. IIS Config
        if (Get-Website | Where-Object { $_.Name -eq $Name }) { 
            Remove-Website -Name $Name -ErrorAction SilentlyContinue 
        }
        
        # Bắt lỗi khi tạo site (Ví dụ trùng Port với phần mềm khác)
        try {
            New-Website -Name $Name -Port $Port -PhysicalPath $Path -Force -ErrorAction Stop | Out-Null
        } catch {
             Write-Host "`n     [X] LOI TAO IIS: Port $Port co the dang bi phan mem khac chiem dung." -ForegroundColor Red
             Write-Host "     Chi tiet: $($_.Exception.Message)" -ForegroundColor Gray
             return
        }

        # 4. Firewall
        $RuleName = "IIS_AutoRule_$Port"
        Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue
        New-NetFirewallRule -DisplayName $RuleName -Direction Inbound -LocalPort $Port -Protocol TCP -Action Allow | Out-Null

        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        # Catch các lỗi không xác định khác
        Write-Host "`n   [X] LOI HE THONG: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- HÀM XÓA SITE ---
function Remove-IISSite {
    param ([string]$Name)
    $Site = Get-Website | Where-Object { $_.Name -eq $Name }
    if (!$Site) {
        Write-Host " [!] Khong tim thay Website nao ten: '$Name'" -ForegroundColor Yellow; return
    }

    $SitePath = $Site.physicalPath
    $BindingInfo = $Site.bindings.Collection.bindingInformation
    $Port = ($BindingInfo -split ":")[1] 

    Write-Host " [-] Dang xoa: $Name (Port: $Port)..." -ForegroundColor Cyan
    try {
        Remove-Website -Name $Name -ErrorAction Stop
        if (Test-Path "IIS:\AppPools\$Name") { Remove-WebAppPool -Name $Name -ErrorAction SilentlyContinue }
        
        $RuleName = "IIS_AutoRule_$Port"
        Remove-NetFirewallRule -DisplayName $RuleName -ErrorAction SilentlyContinue

        Write-Host " [?] XOA LUON thu muc source code ($SitePath)?" -ForegroundColor Yellow
        $Confirm = Read-Host "     (Go 'Y' de Xoa / Enter de Giu lai)"
        if ($Confirm -eq "Y" -or $Confirm -eq "y") {
            if (Test-Path $SitePath) {
                Remove-Item -Path $SitePath -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "     -> Da xoa thu muc vat ly." -ForegroundColor Red
            } else {
                 Write-Host "     -> Thu muc khong ton tai." -ForegroundColor Gray
            }
        } else {
            Write-Host "     -> Da giu lai thu muc." -ForegroundColor Green
        }
        Write-Host " [OK] Xoa xong $Name." -ForegroundColor Green
    } catch {
        Write-Host " [LOI KHI XOA] $($_.Exception.Message)" -ForegroundColor Red
    }
}

# --- HÀM ĐỌC JSON AN TOÀN ---
function Get-SafeJson {
    param ($Path)
    if (!(Test-Path $Path)) {
        Write-Host " [LOI FILE] Khong tim thay file '$Path'" -ForegroundColor Red
        return $null
    }
    try {
        $Content = Get-Content $Path -Raw | ConvertFrom-Json
        return $Content
    } catch {
        Write-Host " [LOI CU PHAP JSON] File '$Path' bi loi dinh dang!" -ForegroundColor Red
        Write-Host " -> Kiem tra lai dau phay (,), dau ngoac {} [] trong file." -ForegroundColor Yellow
        return $null
    }
}

# ============================================================
#  MENU CHÍNH
# ============================================================

Do {
    Clear-Host
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "  SUPER IIS MANAGER v4.0 (SAFE MODE)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host " 1. Tao Site (Nhap tay)"
    Write-Host " 2. Tao Site (Tu file JSON)"
    Write-Host " 3. Xoa Site (Nhap tay)"
    Write-Host " 4. Xoa Site (Tu file JSON)"
    Write-Host " 5. Kiem tra Site & Port"
    Write-Host " 0. Thoat"
    Write-Host "=========================================="
    $Choice = Read-Host " [?] Chon chuc nang"

    Switch ($Choice) {
        "1" { 
            $Name = Read-Host " Site Name"; 
            try { $P = Read-Host " Port" ; $IntPort = [int]$P } catch { Write-Host " [!] Port phai la so nguyen!" -ForegroundColor Red; Pause; Break }
            $Path = Read-Host " Folder Path"
            Setup-IISSite -Name $Name -Port $IntPort -Path $Path
            Pause
        }
        "2" { 
            Write-Host " [+] Nhap duong dan file JSON (Enter='config.json'): " -ForegroundColor Yellow -NoNewline
            $InputPath = Read-Host
            if ([string]::IsNullOrWhiteSpace($InputPath)) { $InputPath = ".\config.json" }
            
            $Arr = Get-SafeJson -Path $InputPath
            if ($Arr) { foreach ($S in $Arr) { Setup-IISSite -Name $S.SiteName -Port $S.Port -Path $S.Folder } }
            Pause
        }
        "3" { 
            $Name = Read-Host " Nhap ten Site muon XOA"
            Remove-IISSite -Name $Name
            Pause
        }
        "4" { 
            Write-Host " [+] Nhap duong dan file JSON (Enter='config.json'): " -ForegroundColor Yellow -NoNewline
            $InputPath = Read-Host
            if ([string]::IsNullOrWhiteSpace($InputPath)) { $InputPath = ".\config.json" }

            $Arr = Get-SafeJson -Path $InputPath
            if ($Arr) {
                Write-Host " [CANH BAO] Xoa TAT CA site trong file '$InputPath'?" -ForegroundColor Red
                $Sure = Read-Host " Go 'OK' de xac nhan"
                if ($Sure -eq "OK") { foreach ($S in $Arr) { Remove-IISSite -Name $S.SiteName } }
            }
            Pause
        }
        "5" { Get-Website | Select-Object Name, State, PhysicalPath; Pause }
        "0" { Write-Host "Bye!"; Start-Sleep 1 }
    }
} While ($Choice -ne "0")