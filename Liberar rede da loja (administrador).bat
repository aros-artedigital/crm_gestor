@echo off
setlocal
title CRM GESTOR - liberar a rede da loja

rem ============================================================
rem  Libera a porta do CRM GESTOR para os aparelhos da loja.
rem  Rode UMA vez, no computador principal (o que abre o servidor).
rem  O Windows pede confirmacao de administrador.
rem
rem  O que faz (detalhes em servidor\liberar_rede_loja.ps1):
rem   1. Marca a rede deste computador como Privada.
rem   2. Cria a regra de firewall "CRM GESTOR - rede da loja (porta
rem      4590)": so a porta 4590, so o Python, so rede Privada e so
rem      aparelhos da mesma rede local.
rem   3. Desliga (nao apaga) as regras antigas "Python" da rede
rem      Publica, que liberavam qualquer porta do Python.
rem  Pode rodar de novo sem problema: a regra e refeita.
rem  Como desfazer: "LEIA-ME - servidor local.txt".
rem ============================================================

set "PORTA=4590"
set "ESTE=%~f0"

rem --- sem administrador: pede ao Windows e roda de novo como admin ---
net session >nul 2>&1
if not errorlevel 1 goto liberar
echo.
echo   Pedindo permissao de administrador ao Windows...
powershell -NoProfile -Command "try { Start-Process -FilePath $env:ESTE -Verb RunAs -ErrorAction Stop } catch { exit 1 }"
if not errorlevel 1 exit /b 0
echo.
echo   Sem a permissao de administrador, nada foi alterado.
echo.
pause
exit /b 1

:liberar
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0servidor\liberar_rede_loja.ps1" -Porta %PORTA%
echo.
pause
exit /b 0
