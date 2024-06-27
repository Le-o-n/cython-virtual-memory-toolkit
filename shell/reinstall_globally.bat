@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="setup.py"

cd /D "%~dp0"
call ./uninstall_build_globally.bat
call ./build_sdist.bat
call ./install_build_globally.bat