@echo off

cd /D "%~dp0"
cd ..

set PYTHON=python
set REQUIREMENTS="./requirements.txt"

%PYTHON% -m pip install -r %REQUIREMENTS%