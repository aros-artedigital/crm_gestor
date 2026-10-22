@echo off
setlocal
title CRM GESTOR - parando o servidor

rem ============================================================
rem  Encerra o servidor local do CRM GESTOR.
rem  So e necessario se voce quiser liberar a porta ou fechar
rem  tudo; fechar a janela "CRM GESTOR - servidor" faz o mesmo.
rem ============================================================

set "PORTA=4590"
set "ACHOU="

rem ":4590 " pega a porta em qualquer endereco (o servidor escuta na rede
rem da loja desde 12/10/2026; antes, so em 127.0.0.1).
for /f "tokens=5" %%P in ('netstat -ano ^| findstr /c:":%PORTA% " ^| findstr /i "LISTENING"') do (
  set "ACHOU=1"
  taskkill /F /PID %%P >nul 2>&1
)

if defined ACHOU (
  echo.
  echo   Servidor do CRM GESTOR encerrado.
  echo.
) else (
  echo.
  echo   Nenhum servidor do CRM GESTOR estava rodando na porta %PORTA%.
  echo.
)

rem ping em vez de timeout: timeout falha quando a entrada esta redirecionada
ping -n 4 127.0.0.1 >nul 2>&1
exit /b 0
