@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="setup.py"

cd /D "%~dp0"
cd ..

@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="setup.py"

cd /D "%~dp0"
cd ..

REM Delete all subfolders/files from ./dist/ folder and delete the folder
if exist dist (
    rmdir /S /Q dist
)

REM Find and delete the ./*.egg-info folder subfiles and then the folder
for /d %%i in (*.egg-info) do (
    rmdir /S /Q "%%i"
)

REM Run the other batch files
call shell\build_sdist.bat
call install_build_globally.bat
