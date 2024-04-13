# python setup.py build_ext --inplace

from distutils.core import setup, Extension
from Cython.Build import cythonize


B = Extension(
    "b", 
    [
        "b.pyx"
    ]
)

setup(
    name='test',
    ext_modules=cythonize([B]),
    
)