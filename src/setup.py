from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
import os

file_dir = os.path.dirname(os.path.abspath(__file__))

# Gather all the .pxd files for inclusion in the package
pxd_files = [
    os.path.join(file_dir, 'handles/handle.pxd'),
    os.path.join(file_dir, 'memory/memory_manager.pxd'),
    os.path.join(file_dir, 'memory/memory_structures.pxd'),
    os.path.join(file_dir, 'process/process.pxd'),
    os.path.join(file_dir, 'windows/windows_defs.pxd'),
    os.path.join(file_dir, 'windows/windows_types.pxd')
]

# Gather all the .h files for inclusion in the package
h_files = [
    os.path.join(file_dir, 'handles/handle.h'),
    os.path.join(file_dir, 'memory/memory_manager.h'),
    os.path.join(file_dir, 'memory/memory_structures.h'),
    os.path.join(file_dir, 'process/process.h'),
    os.path.join(file_dir, 'windows/windows_defs.h'),
    os.path.join(file_dir, 'windows/windows_types.h')
]

setup(
    package_dir={"VirtualMemoryToolkit": file_dir},
    package_data={
        'VirtualMemoryToolkit': pxd_files + h_files
    },
    include_package_data=True,

)
