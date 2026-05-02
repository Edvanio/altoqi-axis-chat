@echo off
setlocal enabledelayedexpansion

REM ==========================================================
REM 0) Garante .gitignore para artefatos copiados do spec_to_code
REM 1) Garante que o submodulo spec_to_code exista (branch main)
REM 2) Sincroniza configuracao do submodulo
REM 3) Inicializa/atualiza submodulo
REM 4) Valida ausencia de mudancas locais
REM 5) Atualiza para o topo da branch main
REM 6) Copia prompts, agents e AGENTS.md
REM ==========================================================

cd /d "%~dp0"

echo [0/6] Garantindo .gitignore para .github do framework...
if not exist ".gitignore" type nul > ".gitignore"

findstr /C:".github/agents/" ".gitignore" >nul || echo .github/agents/>>".gitignore"
findstr /C:".github/prompts/" ".gitignore" >nul || echo .github/prompts/>>".gitignore"
findstr /C:".github/AGENTS.md" ".gitignore" >nul || echo .github/AGENTS.md>>".gitignore"


echo [1/6] Garantindo submodulo spec_to_code...

if not exist ".gitmodules" (
    echo Nenhum submodulo configurado ainda.
)

git config --file .gitmodules --get submodule.spec_to_code.url >nul 2>&1
if errorlevel 1 (
    echo Adicionando submodulo spec_to_code...
    git submodule add -b main https://github.com/AltoQiTec/spec_to_code.git spec_to_code
    if errorlevel 1 (
        echo ERRO: falha ao adicionar submodulo spec_to_code.
        goto :end
    )
) else (
    echo Submodulo spec_to_code ja configurado.
)


echo [2/6] Sincronizando configuracao...
git submodule sync spec_to_code
if errorlevel 1 (
  echo ERRO: falha no git submodule sync.
  goto :end
)


echo [3/6] Inicializando/atualizando submodulo...
git submodule update --init spec_to_code
if errorlevel 1 (
  echo ERRO: falha no git submodule update --init.
  goto :end
)


echo [4/6] Verificando mudancas locais no submodulo...
pushd spec_to_code
git diff --quiet
if errorlevel 1 (
  echo ERRO: mudancas locais detectadas em spec_to_code.
  popd
  goto :end
)
popd


echo [5/6] Atualizando para o topo da branch main...
git submodule update --remote spec_to_code
if errorlevel 1 (
  echo ERRO: falha no git submodule update --remote.
  goto :end
)

echo Status do submodulo:
git submodule status spec_to_code


echo [6/6] Copiando prompts, agents e AGENTS.md do spec_to_code...

if not exist ".github" mkdir ".github"
if not exist ".github\prompts" mkdir ".github\prompts"
if not exist ".github\agents"  mkdir ".github\agents"

robocopy "spec_to_code\.github\prompts" ".github\prompts" /E /NFL /NDL /NJH /NJS
set "RC_PROMPTS=%ERRORLEVEL%"

robocopy "spec_to_code\.github\agents" ".github\agents" /E /NFL /NDL /NJH /NJS
set "RC_AGENTS=%ERRORLEVEL%"

if exist "spec_to_code\.github\AGENTS.md" (
  robocopy "spec_to_code\.github" ".github" "AGENTS.md" /NFL /NDL /NJH /NJS
  set "RC_AGENTS_MD=%ERRORLEVEL%"
) else if exist "spec_to_code\AGENTS.md" (
  robocopy "spec_to_code" ".github" "AGENTS.md" /NFL /NDL /NJH /NJS
  set "RC_AGENTS_MD=%ERRORLEVEL%"
) else (
  echo AVISO: AGENTS.md nao encontrado.
  set "RC_AGENTS_MD=0"
)

if %RC_PROMPTS% GEQ 8 (
  echo ERRO: falha ao copiar prompts. Codigo=%RC_PROMPTS%
  goto :end
)

if %RC_AGENTS% GEQ 8 (
  echo ERRO: falha ao copiar agents. Codigo=%RC_AGENTS%
  goto :end
)

if %RC_AGENTS_MD% GEQ 8 (
  echo ERRO: falha ao copiar AGENTS.md. Codigo=%RC_AGENTS_MD%
  goto :end
)

echo.
echo ===========================================
echo Submodulo spec_to_code garantido e atualizado.
echo Se o SHA mudou, faca commit no repo principal.
echo ===========================================
echo.

:end
pause
endlocal