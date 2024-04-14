# python setup.py build_ext --inplace

from distutils.core import setup, Extension
from Cython.Build import cythonize


win_defs_ext = Extension(
    "VirtualMemoryToolkit.windows.windows_defs",
    [
        "VirtualMemoryToolkit/windows/windows_defs.pyx"
    ]
)

win_types_ext = Extension(
    "VirtualMemoryToolkit.windows.windows_types",
    [
        "VirtualMemoryToolkit/windows/windows_types.pyx"
    ]
)

B = Extension(
    "VirtualMemoryToolkit.b",
    [
        "VirtualMemoryToolkit/b.pyx"
    ]
)

setup(
    name='test',
    ext_modules=cythonize([win_defs_ext, win_types_ext, B]),
    package_data={
        'VirtualMemoryToolkit': [
            "VirtualMemoryToolkit/windows/windows_types.pyx"


        ],

    },

)
