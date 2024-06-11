@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="./src/setup.py"

cd /D "%~dp0"
cd ..

%PYTHON_EXECUTABLE% %SETUP% clean --all
%PYTHON_EXECUTABLE% %SETUP% sdist


