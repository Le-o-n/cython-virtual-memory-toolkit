from distutils.core import setup, Extension
from Cython.Build import cythonize

include_libs = [
    "user32",
    "kernel32",
]

process_ext = Extension(
    "TESTMODULE.process",
    [
        "TESTMODULE/process.pyx"
    ],
    language="c++",
    libraries=include_libs
)


setup(
    name='TESTMODULE',
    ext_modules=cythonize([process_ext]),
    include_dirs=["."]
)
