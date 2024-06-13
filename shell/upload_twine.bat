@echo off
setlocal enabledelayedexpansion

cd /D "%~dp0"
cd ..

call ./cleanup_sdist_build.bat
call ./build_sdist.bat
python -m twine upload dist/*
call ./cleanup_sdist_build.bat