from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
import os


root_dir = os.path.dirname(os.path.abspath(__file__))
src_dir = "./src"
virtual_memory_toolkit_dir = os.path.join(src_dir, "virtual_memory_toolkit")

# Gather all the .pxd files for inclusion in the package
pxd_files = [
    os.path.join('handles', 'handle.pxd'),
    os.path.join('memory', 'memory_manager.pxd'),
    os.path.join('memory', 'memory_structures.pxd'),
    os.path.join('process', 'process.pxd'),
    os.path.join('windows', 'windows_defs.pxd'),
    os.path.join('windows', 'windows_types.pxd')
]

# Gather all the .h files for inclusion in the package
h_files = [
    os.path.join('handles', 'handle.h'),
    os.path.join('memory', 'memory_manager.h'),
    os.path.join('memory', 'memory_structures.h'),
    os.path.join('process', 'process.h'),
    os.path.join('windows', 'windows_defs.h'),
    os.path.join('windows', 'windows_types.h')
]

os.chdir(root_dir)
setup(
    package_dir={"virtual_memory_toolkit": virtual_memory_toolkit_dir},
    package_data={
        'virtual_memory_toolkit': pxd_files + h_files
    },
    include_package_data=True,

)
