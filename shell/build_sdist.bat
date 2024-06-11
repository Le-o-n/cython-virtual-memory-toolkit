@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="setup.py"

cd /D "%~dp0"
cd ..

%PYTHON_EXECUTABLE% %SETUP% clean --all
%PYTHON_EXECUTABLE% %SETUP% sdist


