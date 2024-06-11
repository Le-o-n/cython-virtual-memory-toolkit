from distutils.core import setup, Extension
from Cython.Build import cythonize
import os

include_libs = [
    "user32",
    "kernel32",
]

# Specify the base directory where your Cython modules are located
file_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.abspath(os.path.join(file_dir, os.pardir))
virtual_memory_toolkit_dir = os.path.join(root_dir, "VirtualMemoryToolkit")

include_dirs = [
    root_dir,
    virtual_memory_toolkit_dir,
]


handles_ext = Extension(
    "Tests.test_handles",
    [
        "test_handles.pyx"
    ],
    language="c++",
    libraries=include_libs,
    include_dirs=include_dirs
)

process_ext = Extension(
    "Tests.test_process",
    [
        "test_process.pyx"
    ],
    language="c++",
    libraries=include_libs,
    include_dirs=include_dirs
)


memory_ext = Extension(
    "Tests.test_memory",
    [
        "test_memory.pyx"
    ],
    language="c++",
    libraries=include_libs,
    include_dirs=include_dirs
)
# Setup script
setup(
    name='Tests',
    ext_modules=cythonize(
        [   
            handles_ext,
            process_ext,
            memory_ext
            
            
        ]
    ),
    include_dirs=include_dirs,
)
