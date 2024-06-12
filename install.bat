@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="setup.py"

cd /D "%~dp0"

call shell\\build_sdist.bat
call shell\\install_build_globally.bat
call shell\\cleanup_sdist_build.bat
