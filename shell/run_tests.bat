@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set RUN_PATH=./test/run_tests.py

cd /D "%~dp0"
cd ..

python %RUN_PATH%