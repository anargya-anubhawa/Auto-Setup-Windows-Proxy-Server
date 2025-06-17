@echo off
setlocal enabledelayedexpansion

:: Menampilkan informasi awal
:menu
cls
echo ===============================================
echo.
echo    __    _  _    __    ____   ___  _  _   __   
echo   /__\  ( \( )  /__\  (  _ \ / __)( \/ ) /__\  
echo  /(__)\  )  (  /(__)\  )   /( (_-. \  / /(__)\ 
echo (__)(__)(_)\_)(__)(__)(_)\_) \___/ (__)(__)(__)
echo.
echo         Auto Set Proxy Server Advanced
echo             https://anargya.my.id
echo.
echo ===============================================
echo.

:: Mengecek status proxy
for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable 2^>nul ^| find "ProxyEnable"') do set /a proxyStatus=%%a
if "%proxyStatus%" EQU "1" (
    powershell -Command "Write-Host 'Status Proxy Server: ON' -ForegroundColor Green"
) else (
    powershell -Command "Write-Host 'Status Proxy Server: OFF' -ForegroundColor Red"
)

:: Mengecek port proxy
for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer 2^>nul ^| find "ProxyServer"') do set proxyPort=%%a
if defined proxyPort (
    powershell -Command "Write-Host 'Proxy berjalan pada: !proxyPort!' -ForegroundColor Yellow"
) else (
    echo Proxy belum dikonfigurasi atau nonaktif.
)

:: Menu pilihan
echo.
echo Pilih opsi:
echo 1. Enable and Auto Setup Proxy Server
echo 2. Disable Proxy and Clear Proxy Configuration
echo 3. Script Information.
echo 4. Exit.
set /p choice=Masukkan pilihan (1/2/3/4): 

if "%choice%"=="1" goto set_proxy
if "%choice%"=="2" goto disable_proxy
if "%choice%"=="3" goto info
if "%choice%"=="4" exit
if "%choice%"=="" goto menu

:: Opsi 1: Setel Proxy Server
:set_proxy
cls
echo ===============================================
echo.
powershell -Command "Write-Host 'Running Auto Set Proxy Server...' -ForegroundColor Yellow"
echo.
echo ===============================================
echo.

:: Mencari Default Gateway dari Wi-Fi
set gateway=
for /f "tokens=2 delims=:" %%a in ('netsh interface ip show config ^| find "Default Gateway"') do (
    set gateway=%%a
    set gateway=!gateway:~1!
)
set gateway=!gateway: =!

:: Mengecek apakah gateway ditemukan
if not defined gateway (
    echo Tidak ditemukan Default Gateway.
    pause
    goto menu
)

powershell -Command "Write-Host 'IP Gateway yang digunakan: !gateway!' -ForegroundColor Yellow"

:: Meminta input port dari user, jika kosong set port default ke 7071
set /p port=Masukkan port untuk proxy server (default: 7071): 
if not defined port (
    set port=7071
    echo Port tidak dimasukkan. Menggunakan port default 7071.
)

:: Simpan pengaturan registry
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 1 /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /t REG_SZ /d "!gateway!:!port!" /f
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyOverride /t REG_SZ /d "" /f

:: Trigger perubahan setting proxy
powershell -Command "Add-Type -MemberDefinition '[DllImport(\"wininet.dll\", SetLastError=true)] public static extern bool InternetSetOption(int hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);' -Namespace Win32Functions -Name WinInetOptions; [Win32Functions.WinInetOptions]::InternetSetOption(0, 39, [IntPtr]::Zero, 0); [Win32Functions.WinInetOptions]::InternetSetOption(0, 37, [IntPtr]::Zero, 0)"

pause
goto menu

:: Opsi 2: Nonaktifkan Proxy Server
:disable_proxy
cls
echo ===============================================
echo.
powershell -Command "Write-Host 'Stopping Proxy Server and Clearing IP Configuration' -ForegroundColor Yellow"
echo.
echo ===============================================
echo.

:: Nonaktifkan Proxy
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyServer /f

:: Trigger perubahan setting proxy
powershell -Command "Add-Type -MemberDefinition '[DllImport(\"wininet.dll\", SetLastError=true)] public static extern bool InternetSetOption(int hInternet, int dwOption, IntPtr lpBuffer, int dwBufferLength);' -Namespace Win32Functions -Name WinInetOptions; [Win32Functions.WinInetOptions]::InternetSetOption(0, 39, [IntPtr]::Zero, 0); [Win32Functions.WinInetOptions]::InternetSetOption(0, 37, [IntPtr]::Zero, 0)"

:: Reset IP ke DHCP
netsh interface ip set address name="Ethernet" source=dhcp
netsh interface ip set address name="Wi-Fi" source=dhcp

echo Proxy telah dimatikan dan pengaturan IP telah direset ke otomatis.
pause
goto menu

:: Opsi 3: Informasi
:info
cls
echo ===============================================
echo.
powershell -Command "Write-Host 'Script ini dibuat oleh Anargya [ https://anargya.my.id ]' -ForegroundColor Yellow"
echo Jika ada pertanyaan atau feedback, hubungi: anargya.dev@gmail.com
echo Script version 1.3
echo.
echo ===============================================
echo.
pause
goto menu
