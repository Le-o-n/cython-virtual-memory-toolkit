@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="setup.py"

%PYTHON_EXECUTABLE% %SETUP% build_ext --inplace


