# Cython Virtual Memory Toolkit

The Cython Virtual Memory Toolkit is designed to provide Cython header files (`*.pxd`) for various functionalities, enabling Cython to interact with the virtual memory of a target process. This toolkit includes features for reading, writing, allocating, and freeing virtual memory, along with Windows API bindings and custom functions for memory management.

## Features

- **Reading Memory**: Supports array of bytes, int8, int16, int32, int64, float32, and float64.
- **Writing Memory**: Supports array of bytes, int8, int16, int32, int64, float32, and float64.
- **Memory Management**: Allocate and free virtual memory, with automatic tracking of allocated memory using a simple garbage collection doubly linked list.
- **Memory Scanning**: Array-of-byte scans, static addressing (fixed address) and dynamic addressing (offsets from modules)
- **Indexing Memory**: Memory labelled with an address can be indexed with an offset in the virtual memory.
- **Module Information**: Retrieve module virtual addresses and sizes.
- **Windows API Bindings**: Bindings to Windows API functions that can be called directly via Cython.
- **Custom Windows API Functions**: Custom functions to read and write to some protected virtual pages (excluding pages with `PAGE_GUARD` protection).

## Installation

### From PyPi

To install via pip:

```bash
pip install cython-virtual-memory-toolkit
```

### From Source

To install from source, you can use the provided `install.bat` script:

```bash
install.bat
```

Alternatively, you can build the source using `setup.py`:

```bash
python setup.py sdist
```

Then install the package created in the `./dist/` folder:

```bash
python -m pip install ./dist/*.tar.gz
```
## Requirements
- Cython
- Python 3.10+

## Examples
For a variety of sample projects using this package, refer to the ./examples/ folder. This folder contains several self-contained projects that illustrate how to include this package and how to build the project. 
## License

