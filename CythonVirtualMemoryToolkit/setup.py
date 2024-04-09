from setuptools import find_packages, setup, Extension
from Cython.Build import cythonize
import os

directory_path: str = os.path.abspath(".")


def remove_file_extensions(
    dir_path: str,
    extensions: list[str] = []
):
    for file_name in os.listdir(dir_path):
        ext = file_name.split(".")[-1]
        if ext in extensions:
            full_path: str = os.path.join(directory_path, file_name)
            if os.path.exists(full_path):
                os.remove(full_path)
                print(f"Removed: {file_name}")


remove_file_extensions(directory_path, ["c", "pyd"])

include_libs = [
    "user32",
    "kernel32",
]

process_extension: Extension = Extension(
    "cython_virtual_memory_toolkit.process",
    [
        "process.pyx",
    ],
    libraries=include_libs,
    language="c++",
    depends=[
        "windows_externs.pxd"
    ]

)
hooks_extension: Extension = Extension(
    "cython_virtual_memory_toolkit.hooks",
    [
        "hooks.pyx"
    ],
    libraries=include_libs,
    language="c++"
)
datatypes_extension: Extension = Extension(
    "cython_virtual_memory_toolkit.datatypes",
    [
        "datatypes.pyx"
    ],
    libraries=include_libs,
    language="c++"
)
addressing_extension: Extension = Extension(
    "cython_virtual_memory_toolkit.addressing",
    [
        "addressing.pyx"
    ],
    libraries=include_libs,
    language="c++"
)
errors_extension: Extension = Extension(
    "cython_virtual_memory_toolkit.errors",
    [
        "errors.py"
    ],
    libraries=None,
)
windows_externs_extension: Extension = Extension(
    "cython_virtual_memory_toolkit.windows_externs",
    [
        "windows_externs.pyx"
    ],
    libraries=None,
)


extensions = [
    process_extension,
    hooks_extension,
    datatypes_extension,
    addressing_extension,
    errors_extension,
    windows_externs_extension
]

setup(
    name='cython-virtual-memory-toolkit',
    version='5.0.0',
    url='https://github.com/Le-o-n/cython-virtual-memory-toolkit',
    description='Cython virtual memory toolkit',
    license='MIT',
    author='Leon Bass',
    packages=['cython_virtual_memory_toolkit'],
    package_dir={'cython_virtual_memory_toolkit': '.'},
    package_data={
        'cython_virtual_memory_toolkit': [
            '*.pyx',
            '*.pxd',
            '*.pyi',
            '*.py'
        ],

    },
    exclude_package_data={
        'cython_virtual_memory_toolkit': [
            'main.py'
        ],
    },
    ext_modules=cythonize(
        extensions,
        language_level="3",
    ),


)

remove_file_extensions(directory_path, ["c"])
