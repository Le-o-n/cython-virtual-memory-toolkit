# python setup.py build_ext --inplace

from distutils.core import setup, Extension
from Cython.Build import cythonize

include_libs = [
    "user32",
    "kernel32",
]


B = Extension(
    "VirtualMemoryToolkit.b",
    [
        "VirtualMemoryToolkit/b.pyx"
    ],
    language="c++",
    libraries=include_libs
)

setup(
    name='test',
    ext_modules=cythonize([B])


)
