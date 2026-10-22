@echo off
setlocal
title CRM GESTOR - pen drive: levar ou trazer os dados

rem ============================================================
rem  Pen drive / HD externo: copia os dados do CRM GESTOR entre a
rem  pasta do sistema NO PEN DRIVE e ESTE computador, num sentido
rem  so. O destino fica igual a origem (substitui, nao soma); o que
rem  ele tinha fica guardado na pasta "anteriores" dele.
rem
rem  Rode este arquivo de dentro da pasta do sistema no pen drive.
rem  O servidor do CRM GESTOR e fechado antes: o banco nao pode
rem  estar aberto durante a copia. Ver "LEIA-ME - servidor local.txt".
rem ============================================================

set "PORTA=4590"
set "PASTA=%~dp0"
rem O mesmo DADOS do "Abrir CRM GESTOR.bat" (o banco deste computador).
set "DADOS_PC=C:\CRM GESTOR\dados"
set "DADOS_PEN=%PASTA%dados"
set "PY_PEN=%PASTA%servidor\python"

if not exist "%PASTA%servidor\pen_drive.py" (
  echo.
  echo   Nao encontrei servidor\pen_drive.py nesta pasta:
  echo   %PASTA%
  echo.
  pause
  exit /b 1
)

rem --- esta pasta esta mesmo num pen drive / HD externo? ---
rem A mesma conferencia do "Abrir CRM GESTOR.bat".
set "PEN="
if "%CRM_GESTOR_PEN_DRIVE%"=="1" set "PEN=1"
if defined CRM_GESTOR_PEN_DRIVE goto pen_decidido
if /i "%PASTA:~0,2%"=="%SystemDrive%" goto pen_decidido
powershell -NoProfile -ExecutionPolicy Bypass -Command "$l=[IO.Path]::GetPathRoot($env:PASTA).TrimEnd('\'); if ($l -notmatch '^[A-Za-z]:$') { exit 1 }; $d=Get-CimInstance Win32_LogicalDisk -Filter ('DeviceID='''+$l+''''); if ($d -and $d.DriveType -eq 2) { exit 0 }; try { $b=[string](Get-Partition -DriveLetter $l[0] -ErrorAction Stop | Get-Disk -ErrorAction Stop).BusType; if (@('USB','SD','MMC') -contains $b) { exit 0 } } catch {}; exit 1"
if not errorlevel 1 set "PEN=1"
:pen_decidido
if not defined PEN (
  echo.
  echo   Esta pasta nao esta num pen drive nem num HD externo:
  echo   %PASTA%
  echo.
  echo   Para levar o CRM GESTOR: copie a pasta inteira do sistema para o
  echo   pen drive e rode este arquivo de dentro da pasta, no pen drive.
  echo.
  pause
  exit /b 1
)

rem --- Python: o que vem junto primeiro (como no "Abrir CRM GESTOR.bat") ---
set "PY="
if exist "%PY_PEN%\python.exe" set "PATH=%PY_PEN%;%PATH%"
python -c "import sqlite3" >nul 2>&1 && set "PY=python"
if not defined PY py -c "import sqlite3" >nul 2>&1 && set "PY=py"
if not defined PY (
  echo.
  echo   O Python nao foi encontrado, nem o que vem junto com o sistema
  echo   ^(pasta servidor\python^). Copie a pasta inteira de novo.
  echo.
  pause
  exit /b 1
)

rem --- fechar o servidor do CRM GESTOR, se estiver no ar ---
rem So derruba o servidor do CRM GESTOR; outro programa na porta fica
rem intacto (o pen_drive.py avisa e nao copia).
netstat -an | findstr /c:":%PORTA% " | findstr /i "LISTENING" >nul
if errorlevel 1 goto copiar
echo.
echo   O CRM GESTOR esta aberto. Para copiar os dados, o servidor sera
echo   fechado agora: salve o que estiver fazendo no sistema.
echo.
pause
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ids=@(Get-NetTCPConnection -State Listen -LocalPort ([int]$env:PORTA) -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique); foreach ($id in $ids) { $p=Get-CimInstance Win32_Process -Filter ('ProcessId='+$id); if (-not $p -or ($p.CommandLine -notlike '*http.server*' -and $p.CommandLine -notlike '*servidor_crm_gestor*')) { exit 2 } }; foreach ($id in $ids) { $p=Get-CimInstance Win32_Process -Filter ('ProcessId='+$id); $pai=Get-CimInstance Win32_Process -Filter ('ProcessId='+$p.ParentProcessId); Stop-Process -Id $id -Force -ErrorAction SilentlyContinue; if ($pai -and $pai.Name -eq 'cmd.exe' -and ($pai.CommandLine -like '*http.server*' -or $pai.CommandLine -like '*servidor_crm_gestor*')) { Stop-Process -Id $pai.ProcessId -Force -ErrorAction SilentlyContinue } }; exit 0"
rem esperar a porta liberar (ate 5 segundos)
set /a TENTATIVAS=0
:liberar
ping -n 2 127.0.0.1 >nul 2>&1
netstat -an | findstr /c:":%PORTA% " | findstr /i "LISTENING" >nul
if errorlevel 1 goto copiar
set /a TENTATIVAS+=1
if %TENTATIVAS% lss 5 goto liberar

:copiar
%PY% "%PASTA%servidor\pen_drive.py" trocar "%DADOS_PEN%" "%DADOS_PC%"
echo   Para abrir o sistema: "Abrir CRM GESTOR.bat" (pelo pen drive) ou o
echo   atalho de sempre (com os dados deste computador).
echo.
pause
exit /b 0
