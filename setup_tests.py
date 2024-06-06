from distutils.core import setup, Extension
from Cython.Build import cythonize
import os

include_libs = [
    "user32",
    "kernel32",
]

# Specify the base directory where your Cython modules are located
base_dir = os.path.dirname(os.path.abspath(__file__))
virtual_memory_toolkit_dir = os.path.join(base_dir, "VirtualMemoryToolkit")

include_dirs = [
    virtual_memory_toolkit_dir,
]

# Define the extensions
process_ext = Extension(
    "VirtualMemoryToolkit.tests.test_process",
    [
        "VirtualMemoryToolkit/tests/test_process.pyx"
    ],
    language="c++",
    libraries=include_libs,
    include_dirs=include_dirs
)

handles_ext = Extension(
    "VirtualMemoryToolkit.tests.test_handles",
    [
        "VirtualMemoryToolkit/tests/test_handles.pyx"
    ],
    language="c++",
    libraries=include_libs,
    include_dirs=include_dirs
)

# Setup script
setup(
    name='VirtualMemoryToolkit',
    ext_modules=cythonize(
        [
            process_ext,
            handles_ext
        ]
    ),
    include_dirs=include_dirs,
)
