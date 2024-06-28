@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="./test/setup_tests.py"

cd /D "%~dp0"

call ./reinstall_globally.bat
call ./build_tests.bat
call ./run_tests.bat
