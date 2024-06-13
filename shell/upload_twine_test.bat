@echo off
setlocal enabledelayedexpansion

cd /D "%~dp0"
cd ..

call ./shell/cleanup_sdist_build.bat
call ./shell/build_sdist.bat
python -m twine upload --repository testpypi ./dist/*
call ./shell/cleanup_sdist_build.bat