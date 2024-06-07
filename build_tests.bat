@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python
set SETUP="setup_tests.py"

%PYTHON_EXECUTABLE% %SETUP% build_ext --inplace --force