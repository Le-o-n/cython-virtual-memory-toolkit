@echo off
cd /D "%~dp0"
cd ..

rem Path to the build dir that contains the .tar.gz package to be installed
set path_to_build=./dist

rem Initialize a variable to store the first .tar.gz file path
set tar_gz_package=

rem Loop through .tar.gz files and break after the first match
for %%f in (%path_to_build%/*.tar.gz) do (
    set tar_gz_package=%%~f
    goto :found
)

:found
if defined tar_gz_package (
    echo First .tar.gz file found: %tar_gz_package%
    rem Use %tar_gz_package% for further processing
    rem Example: echo %tar_gz_package% >> output.txt
) else (
    echo No .tar.gz file found
)

python -m pip install %path_to_build%/%tar_gz_package%

endlocal

