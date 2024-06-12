@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="./test/setup_tests.py"

cd /D "%~dp0"
cd ..

%PYTHON_EXECUTABLE% %SETUP% build_ext --inplace --force