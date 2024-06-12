from distutils.core import setup, Extension
from Cython.Build import cythonize
import os

include_libs = [
    "user32",
    "kernel32",
]

test_dir = os.path.dirname(os.path.abspath(__file__))
root_dir = os.path.abspath(os.path.join(test_dir, os.pardir))
src_dir = os.path.join(root_dir, "src")
virtual_memory_toolkit_dir = os.path.join(src_dir, "virtual_memory_toolkit")


include_dirs = [
    test_dir,
    src_dir,
    virtual_memory_toolkit_dir
]

handles_ext = Extension(
    "test.test_handles",
    [
        "test/test_handles.pyx"
    ],
    language="c++",
    libraries=include_libs,
    include_dirs=include_dirs
)

process_ext = Extension(
    "test.test_process",
    [
        "test/test_process.pyx"
    ],
    language="c++",
    libraries=include_libs,
    include_dirs=include_dirs
)

memory_ext = Extension(
    "test.test_memory",
    [
        "test/test_memory.pyx"
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
