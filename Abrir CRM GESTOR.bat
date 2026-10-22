@echo off
setlocal enabledelayedexpansion
title CRM GESTOR - iniciando

rem ============================================================
rem  Abre o CRM GESTOR por um servidor local (http://localhost).
rem
rem  Por que isto existe: aberto por duplo-clique no arquivo, o
rem  Chrome bloqueia o banco de dados (IndexedDB) e o sistema cai
rem  no modo compativel, com teto de ~5 MB. Servido por localhost,
rem  o banco completo fica disponivel.
rem
rem  Desde 12/10/2026 o servidor e o servidor\servidor_crm_gestor.py
rem  (antes, python -m http.server): ele tambem atende os outros
rem  aparelhos da rede da loja, que so entram depois de liberados em
rem  http://localhost:4590/aparelhos. O banco do servidor (SQLite) fica
rem  em DADOS, fora do OneDrive. Ver "LEIA-ME - servidor local.txt".
rem
rem  Desde 14/10/2026 a pasta inteira pode ser copiada para um pen
rem  drive ou HD externo e aberta em qualquer computador: ver "PEN
rem  DRIVE" logo abaixo.
rem ============================================================

set "PORTA=4590"
set "PASTA=%~dp0"
rem Desde a v8.13 o sistema e o index.html (antes CRM_GESTOR.html). O
rem servidor entrega o index.html na raiz, por isso o endereco e so a porta.
set "ARQUIVO=index.html"
set "URL=http://localhost:%PORTA%/"
rem Servidor e pasta do banco do servidor. A pasta fica FORA do OneDrive:
rem a sincronizacao pode corromper um banco SQLite aberto.
set "SERVIDOR=servidor\servidor_crm_gestor.py"
set "DADOS=C:\CRM GESTOR\dados"

rem --- PEN DRIVE OU HD EXTERNO ---
rem Pasta num disco removivel (pen drive, cartao) ou ligado por USB (HD
rem externo): o banco do servidor fica DENTRO da pasta (pasta "dados", ao
rem lado do index.html) para andar junto com ela, o servidor so atende este
rem computador (sem a rede da loja) e o Python que vem junto
rem (servidor\python) vale mais que o do computador. Na primeira vez, o
rem servidor\pen_drive.py oferece levar os dados deste computador (DADOS_PC)
rem ou comecar vazio. Disco do Windows (C:) nunca e pen drive, e nem
rem pergunta. A variavel CRM_GESTOR_PEN_DRIVE=1 (ou 0) forca um ou outro.
set "PEN="
set "DADOS_PC=%DADOS%"
set "PY_PEN=%PASTA%servidor\python"
if "%CRM_GESTOR_PEN_DRIVE%"=="1" set "PEN=1"
if defined CRM_GESTOR_PEN_DRIVE goto pen_decidido
if /i "%PASTA:~0,2%"=="%SystemDrive%" goto pen_decidido
powershell -NoProfile -ExecutionPolicy Bypass -Command "$l=[IO.Path]::GetPathRoot($env:PASTA).TrimEnd('\'); if ($l -notmatch '^[A-Za-z]:$') { exit 1 }; $d=Get-CimInstance Win32_LogicalDisk -Filter ('DeviceID='''+$l+''''); if ($d -and $d.DriveType -eq 2) { exit 0 }; try { $b=[string](Get-Partition -DriveLetter $l[0] -ErrorAction Stop | Get-Disk -ErrorAction Stop).BusType; if (@('USB','SD','MMC') -contains $b) { exit 0 } } catch {}; exit 1"
if not errorlevel 1 set "PEN=1"
:pen_decidido
if defined PEN set "DADOS=%PASTA%dados"
if defined PEN title CRM GESTOR - iniciando pelo pen drive

rem --- o arquivo do sistema esta aqui? ---
if not exist "%PASTA%%ARQUIVO%" (
  echo.
  echo   Nao encontrei o arquivo %ARQUIVO% nesta pasta:
  echo   %PASTA%
  echo.
  echo   Este atalho precisa ficar na mesma pasta do sistema.
  echo.
  pause
  exit /b 1
)
if not exist "%PASTA%%SERVIDOR%" (
  echo.
  echo   Nao encontrei o servidor %SERVIDOR% nesta pasta:
  echo   %PASTA%
  echo.
  echo   A pasta "servidor" precisa ficar junto do index.html.
  echo.
  pause
  exit /b 1
)

rem --- o servidor ja esta no ar? ---
rem ":4590 " pega a porta em qualquer endereco: o servidor novo escuta na
rem rede toda (0.0.0.0), o http.server antigo so em 127.0.0.1.
netstat -an | findstr /c:":%PORTA% " | findstr /i "LISTENING" >nul
if errorlevel 1 goto python

rem Tem servidor na porta, mas ele pode ser de OUTRA pasta: todas as
rem versoes (v.05, v.06, v.07...) usam a mesma porta de proposito, para
rem enxergarem o mesmo banco de dados no navegador. Se o index.html
rem entregue pelo servidor tem tamanho e data iguais aos do desta pasta,
rem e o servidor no ar e o servidor_crm_gestor.py desta pasta na versao
rem atual (cabecalho X-CRM-Gestor-Servidor = data do arquivo .py), so
rem abre o navegador. Versao antiga, que so tem o CRM_GESTOR.html,
rem responde 404 aqui; o http.server antigo nao manda o cabecalho; os dois
rem sao trocados. O banco do servidor no ar tambem tem de ser o DADOS
rem daqui: a copia da pasta no pen drive e igual a do computador, mas os
rem dados de uma e de outra moram em lugares diferentes.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f=Get-Item -LiteralPath ($env:PASTA+$env:ARQUIVO); $s=Get-Item -LiteralPath ($env:PASTA+$env:SERVIDOR); try { $r=Invoke-WebRequest -UseBasicParsing -Method Head -TimeoutSec 4 -Uri ('http://127.0.0.1:'+$env:PORTA+'/'+$env:ARQUIVO); $dt=[datetime]::ParseExact($r.Headers['Last-Modified'],'r',[Globalization.CultureInfo]::InvariantCulture); $sv=[int64]$r.Headers['X-CRM-Gestor-Servidor']; $sd=[DateTimeOffset]::new($s.LastWriteTimeUtc).ToUnixTimeSeconds(); $e=Invoke-RestMethod -UseBasicParsing -TimeoutSec 4 -Uri ('http://127.0.0.1:'+$env:PORTA+'/api/estado'); $b=[IO.Path]::GetFullPath([IO.Path]::Combine($env:DADOS,'crm_gestor.db')); if ([int64]$r.Headers['Content-Length'] -eq $f.Length -and [math]::Abs(($dt-$f.LastWriteTimeUtc).TotalSeconds) -lt 2 -and [math]::Abs($sv-$sd) -lt 2 -and $e.banco -eq $b) { exit 0 } } catch {}; exit 1"
if not errorlevel 1 goto abrir

rem Servidor de outra versao: sai ele, entra o desta pasta. So derruba
rem se for mesmo um servidor do CRM GESTOR (servidor_crm_gestor.py, ou o
rem http.server das versoes antigas) - qualquer outro
rem programa na porta fica intacto e o atalho avisa. Fecha junto a janela
rem "CRM GESTOR - servidor" que o hospedava, para nao sobrar janela vazia.
echo.
echo   Havia um servidor de outra versao do CRM GESTOR na porta %PORTA%.
echo   Trocando pelo desta pasta...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ids=@(Get-NetTCPConnection -State Listen -LocalPort ([int]$env:PORTA) -ErrorAction SilentlyContinue | Select-Object -ExpandProperty OwningProcess -Unique); foreach ($id in $ids) { $p=Get-CimInstance Win32_Process -Filter ('ProcessId='+$id); if (-not $p -or ($p.CommandLine -notlike '*http.server*' -and $p.CommandLine -notlike '*servidor_crm_gestor*')) { exit 2 } }; foreach ($id in $ids) { $p=Get-CimInstance Win32_Process -Filter ('ProcessId='+$id); $pai=Get-CimInstance Win32_Process -Filter ('ProcessId='+$p.ParentProcessId); Stop-Process -Id $id -Force -ErrorAction SilentlyContinue; if ($pai -and $pai.Name -eq 'cmd.exe' -and ($pai.CommandLine -like '*http.server*' -or $pai.CommandLine -like '*servidor_crm_gestor*')) { Stop-Process -Id $pai.ProcessId -Force -ErrorAction SilentlyContinue } }; exit 0"
if errorlevel 2 goto porta_ocupada

rem esperar a porta liberar (ate 5 segundos)
set /a TENTATIVAS=0
:liberar
ping -n 2 127.0.0.1 >nul 2>&1
netstat -an | findstr /c:":%PORTA% " | findstr /i "LISTENING" >nul
if errorlevel 1 goto python
set /a TENTATIVAS+=1
if !TENTATIVAS! lss 5 goto liberar
goto porta_ocupada

:python
rem --- localizar o Python ---
rem No pen drive, o Python que vem junto (servidor\python) vale mais: o
rem computador pode nao ter Python, ou ter um antigo. Fora dele, o Python
rem instalado (as regras do firewall da rede da loja sao para ele); o que
rem vem junto so entra se nao houver outro. O Python instalado e testado
rem rodando: num Windows sem Python, "python" pode ser so o atalho que abre
rem a Microsoft Store, e com ele o servidor nao sobe.
set "PY="
if defined PEN call :py_junto
if not defined PY python -c "import sqlite3" >nul 2>&1 && set "PY=python"
if not defined PY py -c "import sqlite3" >nul 2>&1 && set "PY=py"
if not defined PY call :py_junto
if not defined PY (
  echo.
  echo   O Python nao foi encontrado neste computador, nem o que vem
  echo   junto com o sistema ^(pasta servidor\python^).
  echo   O servidor local precisa dele para funcionar.
  echo.
  echo   Duas saidas:
  echo   1^) Instalar o Python em https://python.org
  echo      ^(marque "Add Python to PATH" durante a instalacao^)
  echo   2^) Continuar abrindo o sistema pelo arquivo, como antes
  echo      ^- funciona igual, so com o teto de 5 MB.
  echo.
  pause
  exit /b 1
)

rem --- pen drive: os dados vao junto ---
rem Pen drive ainda sem dados: o pen_drive.py pergunta se leva os deste
rem computador ou se comeca vazio. Cancelado (ou com erro), nao abre.
if not defined PEN goto subir
%PY% "%PASTA%servidor\pen_drive.py" preparar "%DADOS%" "%DADOS_PC%"
if errorlevel 1 (
  pause
  exit /b 1
)

:subir
rem --- subir o servidor em janela propria e minimizada ---
rem Escuta na rede da loja (0.0.0.0). Aparelho desconhecido so ve a tela
rem de liberacao; a regra do firewall (arquivo "Liberar rede da loja") so
rem abre a porta para a rede privada local. No pen drive (--portatil), so
rem neste computador (127.0.0.1).
set "EXTRA="
set "TITULO=CRM GESTOR - servidor (nao feche esta janela)"
if defined PEN set "EXTRA= --portatil"
if defined PEN set "TITULO=CRM GESTOR - servidor PEN DRIVE (nao feche esta janela)"
start "%TITULO%" /min /d "%PASTA%" cmd /k %PY% %SERVIDOR% --porta %PORTA% --dados "%DADOS%"%EXTRA%

rem --- esperar ele responder (ate 10 segundos) ---
set /a TENTATIVAS=0
:esperar
rem ping em vez de timeout: timeout falha quando a entrada esta redirecionada
ping -n 2 127.0.0.1 >nul 2>&1
netstat -an | findstr /c:":%PORTA% " | findstr /i "LISTENING" >nul
if not errorlevel 1 goto abrir
set /a TENTATIVAS+=1
if !TENTATIVAS! lss 10 goto esperar

echo.
echo   O servidor nao respondeu a tempo.
echo   Verifique a janela "CRM GESTOR - servidor" para ver o erro.
echo.
pause
exit /b 1

:abrir
rem ?v= muda a cada abertura: sem ele o Chrome pode reaproveitar do cache
rem o sistema de outra versao. Os dados nao mudam - o banco e do
rem endereco (localhost:%PORTA%), nao do ?v=. Carregada a pagina, o
rem proprio sistema tira o ?v= da barra de endereco.
set "URL=%URL%?v=%RANDOM%%RANDOM%"
set "CHROME="
if exist "%ProgramFiles%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe" set "CHROME=%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
if not defined CHROME if exist "%LocalAppData%\Google\Chrome\Application\chrome.exe" set "CHROME=%LocalAppData%\Google\Chrome\Application\chrome.exe"

if not defined CHROME (
  rem sem Chrome: abre no navegador padrao
  start "" "%URL%"
  exit /b 0
)

rem Janela maximizada. Com o Chrome ja aberto, a janela nova copia o
rem tamanho da ultima usada (que pode estar baixinha) e --start-maximized
rem e ignorado. Entao: anota as janelas do Chrome que ja existem, abre o
rem Chrome e maximiza a janela nova do CRM GESTOR assim que ela aparece
rem (ate 10 segundos). Se o PowerShell nao conseguir abrir o Chrome, abre
rem do jeito simples, sem maximizar.
powershell -NoProfile -ExecutionPolicy Bypass -Command "$A=$null; $antes=@(); try { Add-Type -AssemblyName UIAutomationClient,UIAutomationTypes; $A=[Windows.Automation.AutomationElement]; $c=New-Object Windows.Automation.PropertyCondition($A::ClassNameProperty,'Chrome_WidgetWin_1'); $antes=@($A::RootElement.FindAll('Children',$c) | ForEach-Object { $_.Current.NativeWindowHandle }) } catch { $A=$null }; try { Start-Process -FilePath $env:CHROME -ArgumentList @('--new-window',$env:URL) -ErrorAction Stop } catch { exit 1 }; if ($A) { for ($i=0; $i -lt 50; $i++) { Start-Sleep -Milliseconds 200; foreach ($j in $A::RootElement.FindAll('Children',$c)) { if ($antes -notcontains $j.Current.NativeWindowHandle -and $j.Current.Name -like '*CRM GESTOR*') { try { $j.GetCurrentPattern([Windows.Automation.WindowPattern]::Pattern).SetWindowVisualState('Maximized'); exit 0 } catch {} } } } }; exit 0"
if errorlevel 1 start "" "%CHROME%" --new-window "%URL%"
exit /b 0

:porta_ocupada
echo.
echo   A porta %PORTA% esta ocupada por outro programa, que nao e o
echo   servidor do CRM GESTOR. Feche esse programa e tente de novo.
echo.
pause
exit /b 1

:py_junto
rem O Python que vem junto (pen drive): entra na frente no PATH, e a
rem janela do servidor (que herda o PATH) roda "python" igual a antes.
if not exist "%PY_PEN%\python.exe" exit /b 0
set "PATH=%PY_PEN%;%PATH%"
set "PY=python"
exit /b 0
