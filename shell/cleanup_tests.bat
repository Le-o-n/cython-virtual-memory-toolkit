@echo off
setlocal enabledelayedexpansion

set PYTHON_EXECUTABLE=python

cd /D "%~dp0"
cd ../test/

rem Delete all .cpp files
for %%f in (*.cpp) do (
    del "%%f"
)

rem Delete all .pyd files
for %%f in (*.pyd) do (
    del "%%f"
)

echo Cleanup complete!
