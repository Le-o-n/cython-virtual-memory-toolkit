@echo off
setlocal enabledelayedexpansion

cd /D "%~dp0"
cd ..

python -m pip install --index-url https://test.pypi.org/simple/ --no-deps virtual-memory-toolkit
