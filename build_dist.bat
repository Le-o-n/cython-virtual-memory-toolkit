@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="setup.py"

%PYTHON_EXECUTABLE% %SETUP% clean --all
%PYTHON_EXECUTABLE% %SETUP% sdist bdist_wheel



