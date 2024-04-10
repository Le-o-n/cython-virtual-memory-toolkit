from setuptools import setup, Extension
from Cython.Build import cythonize


A_ext: Extension = Extension(
    "SomeModule.A",
    [
        "SomeModule/A.pyx"
    ],
    include_dirs=[
        "SomeModule/"
    ]

)
B_ext: Extension = Extension(
    "SomeModule.B",
    [
        "SomeModule/B.pyx"
    ],
    include_dirs=[
        "SomeModule/"
    ]

)

extensions: list[Extension] = [
    A_ext,
    B_ext
]

setup(
    name='YourModuleName',
    ext_modules=cythonize(
        extensions
    ),
    include_dirs=["SomeModule"]  # Add directories if you have any additional include directories
)
