from distutils.core import setup, Extension
from Cython.Build import cythonize

include_libs = [
    "user32",
    "kernel32",
]

process_ext = Extension(
    "VirtualMemoryToolkit.process",
    [
        "VirtualMemoryToolkit/process.pyx"
    ],
    language="c++",
    libraries=include_libs
)

setup(
    name='VirtualMemoryToolkit',
    ext_modules=cythonize([process_ext])

)
