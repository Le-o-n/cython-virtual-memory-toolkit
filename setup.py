from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize

# Gather all the .pxd files for inclusion in the package
pxd_files = [
    './VirtualMemoryToolkit/handles/handle.pxd',
    './VirtualMemoryToolkit/memory/memory_manager.pxd',
    './VirtualMemoryToolkit/memory/memory_structures.pxd',
    './VirtualMemoryToolkit/process/process.pxd',
    './VirtualMemoryToolkit/windows/windows_defs.pxd',
    './VirtualMemoryToolkit/windows/windows_types.pxd'
]

# Gather all the .h files for inclusion in the package
h_files = [
    './VirtualMemoryToolkit/handles/handle.h',
    './VirtualMemoryToolkit/memory/memory_manager.h',
    './VirtualMemoryToolkit/memory/memory_structures.h',
    './VirtualMemoryToolkit/process/process.h',
    './VirtualMemoryToolkit/windows/windows_defs.h',
    './VirtualMemoryToolkit/windows/windows_types.h'
]


setup(
    package_dir={"VirtualMemoryToolkit": "./VirtualMemoryToolkit"},
    package_data={
        'VirtualMemoryToolkit': pxd_files + h_files
    },
    include_package_data=True,

)
