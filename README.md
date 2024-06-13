# Cython Virtual Memory Toolkit

The Cython Virtual Memory Toolkit is designed to provide Cython header files (`*.pxd`) for various functionalities, enabling Cython to interact with the virtual memory of a target process. This toolkit includes features for reading, writing, allocating, and freeing virtual memory, along with Windows API bindings and custom functions for memory management.

# Features

- **Reading Memory**: Supports array of bytes, int8, int16, int32, int64, float32, and float64.
- **Writing Memory**: Supports array of bytes, int8, int16, int32, int64, float32, and float64.
- **Memory Management**: Allocate and free virtual memory, with automatic tracking of allocated memory using a simple garbage collection doubly linked list.
- **Memory Scanning**: Array-of-byte scans, static addressing (fixed address) and dynamic addressing (offsets from modules)
- **Indexing Memory**: Memory labelled with an address can be indexed with an offset in the virtual memory.
- **Module Information**: Retrieve module virtual addresses and sizes.
- **Windows API Bindings**: Bindings to Windows API functions that can be called directly via Cython.
- **Custom Windows API Functions**: Custom functions to read and write to some protected virtual pages (excluding pages with `PAGE_GUARD` protection).

# Installation
This section will outline the different ways of installing this package, there are three distinct ways of doing this: installing using pip, installing from the github repo and simply just including the files into your project.

## Installing using pip

To install via pip:

```bash
pip install cython-virtual-memory-toolkit
```

## Installing from the repo

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
## Copy files into your project
A final way of including this package in your project simply involves just copying and pasting the `./src/virtual_memory_toolkit/` folder into your project and making sure that you include this directory when compiling your Cython code.

# Requirements
- Cython
- Python 3.10+

# Examples
This section will outline the key structures used within this project and provide minimalistic examples for each one. For a variety of sample projects using this package, refer to the ./examples/ folder - this folder contains several self-contained projects that illustrate how to include this package and how to build the project. 

## CAppHandle
This is a generic handle that wraps around both a maximum privilage process handle (HANDLE) and a window handle (HWND), this struct abstracts the need to micromanage these handles.

### Definition
```c
typedef struct{
    HANDLE process_handle;
    HWND window_handle;
    DWORD pid;
    char* window_title;
} CAppHandle;
```

### Initialising the CAppHandle
We can initialise a `CAppHandle` struct within Cython using `CAppHandle_from_title_substring` which will match a substring of a window title then collect then initialise the CAppHandle using the process and window handle of this matched window.
```cython
# main.pyx


from virtual_memory_toolkit.handles.handle cimport CAppHandle
from virtual_memory_toolkit.handles.handle cimport CAppHandle_from_title_substring
from virtual_memory_toolkit.handles.handle cimport CAppHandle_free

cdef int main()
  # Get a handle to an untitled notepad process
  cdef CAppHandle* handle = CAppHandle_from_title_substring("Untitled - Notepad")

  ...

  CAppHandle_free(handle)
  return 0

```

## CProcess
This is an abstraction for the actual process itself, this allows for extracting meaningful information about the process such as the addresses for the loaded modules.

### Definition
```c
typedef struct
{
    CAppHandle *app_handle;
    MODULEENTRY32 *loaded_modules;
    char *image_filename;
} CProcess;
```

### Initialising the CProcess
We can initialise the `CProcess` struct using the function `CProcess_init` which will extract the relevant information from the process using just a `CAppHandle`.
```cython
# main.pyx


from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.process.process cimport CProcess, CProcess_init, CProcess_free

cpdef int main():
    cdef CAppHandle* app_handle = CAppHandle_from_title_substring("Notepad")
    cdef CProcess* process = CProcess_init(app_handle)
    ...

    CProcess_free(process)
    CAppHandle_free(app_handle)
    return 0

```

## CModule
This is an abstraction around the loaded modules, this structure contains information about the base address ofthe module and the size in bytes of this module.

### Definition
```c
typedef struct
{
    CAppHandle *app_handle;
    char *name;
    void *base_address;
    size_t size;
} CModule;
```

### Initialising a CModule
We can initialise a `CModule` by using `CModule_from_process` which will enumerate all of the loaded modules within the target process and only return the module that matches the substring provided.

```cython
# main.pyx


from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_structures cimport CModule, CModule_free, CModule_from_process
from virtual_memory_toolkit.process.process cimport CProcess, CProcess_init, CProcess_free

cpdef int main():
    cdef char* module_substring = "USER32"
    cdef CAppHandle* app_handle = CAppHandle_from_title_substring("Notepad")
    cdef CProcess* process = CProcess_init(app_handle)
    cdef CModule* module = CModule_from_process(process, <const char*>module_substring)

    ...

    CModule_free(module)
    CProcess_free(process)
    CAppHandle_free(app_handle)
    return 0

```

## CVirtualAddress
This struct allows the persistant definition of a virtual address using various initialisations.

### Definition
```c
typedef struct
{
    CAppHandle *app_handle;
    void *address;
} CVirtualAddress;
```

### Initialisation via static address 
This involves initialising the address as the virtual memory address directly. This can be done using the `CVirtualAddress_init`.
```cython
# main.pyx


from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress, CVirtualAddress_free

cdef int main():
  cdef void* address = 100000
  cdef CAppHandle* app_handle = CAppHandle_from_title_substring("Notepad")
  cdef CVirtualAddress* address = CVirtualAddress_init(app_handle, address)

  ...

  CVirtualAddress_free(address)
  CAppHandle_free(app_handle)
  return 0

```

### Initialisation via dynamic address 
This involves assigning the address as an offset to a loaded module, this gets resolved on initialisation and assigned to the appropriate address attribute of the struct. 

```cython
# main.pyx


from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_structures cimport CModule, CModule_from_process, CModule_free
from virtual_memory_toolkit.process.process cimport CProcess, CProcess_init, CProcess_free
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress, CVirtualAddress_from_dynamic, CVirtualAddress_free

cdef int main():
  cdef CAppHandle* app_handle = CAppHandle_from_title_substring("Notepad")
  cdef CProcess* process = CProcess_init(app_handle)
  cdef CModule* module = CModule_from_process(process, <const char*>"User32")
  cdef void* offset = 100
  cdef CVirtualAddress* address = CVirtualAddress_from_dynamic(app_handle, module, offset)

  ...

  CVirtualAddress_free(address)
  CModule_free(module)
  CProcess_free(process)
  CAppHandle_free(app_handle)
  return 0

```

### Initialisation via Array-Of-Byte scan 
This involves having an address be the first location in memory that matches the scanned array of bytes. This can be useful for creating more reliable addressing that could still work after an executable is updated by the original developers. This is useful for matching code blocks. this can be implemented using `CVirtual_from_dynamic`. 

```cython
# main.pyx


from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress, CVirtualAddress_from_dynamic, CVirtualAddress_free
from libc.stdlib cimport malloc, free 

cdef int main():

  cdef CAppHandle* app_handle = CAppHandle_from_title_substring("Notepad")

  py_array_of_bytes = [0x10, 0x30, ...]
  cdef unsigned char[10] array_of_bytes

  for i, b in enumerate(py_array_of_bytes):
    array_of_bytes[i] = <unsigned char>b
      
  cdef CVirtualAddress* address = CVirtualAddress_from_aob(
      app_handle,
      <const void*>0,
      <const void*>500000,
      <unsigned char*>&array_of_bytes,
      <size_t>10
  )

  ...

  CVirtualAddress_free(address)
  CAppHandle_free(app_handle)
  return 0

```


## CMemoryManager
This is used to allocate virtual memory within the target process, this memory will be tracked using this structure and can be freed individually or all at once.

### Definition
```c
typedef struct
{
    void *address;
    size_t size;
    struct CMemoryRegionNode *next;
    struct CMemoryRegionNode *prev;
} CMemoryRegionNode;

typedef struct
{
    CAppHandle *app_handle;
    CMemoryRegionNode *memory_regions_head;
    CMemoryRegionNode *memory_regions_tail;

} CMemoryManager;
```

### Initialisation
To have this `CMemoryManager` struct initialised, we can simply call the `CMemoryManager_init` function.

```cython
from virtual_memory_toolkit.handles.handle cimport CAppHandle, CAppHandle_from_title_substring, CAppHandle_free
from virtual_memory_toolkit.memory.memory_manager cimport CMemoryManager, CMemoryManager_free, CMemoryManager_init, CMemoryManager_virtual_alloc, CMemoryManager_virtual_free_address, CMemoryManager_virtual_free, CMemoryManager_virtual_free_all
from virtual_memory_toolkit.memory.memory_structures cimport CVirtualAddress, CVirtualAddress_write_int32, CVirtualAddress_write_int32_offset, CVirtualAddress_read_int32, CVirtualAddress_read_int32_offset, CVirtualAddress_free

from libc.string cimport strdup
from libc.stdlib cimport free

cpdef int main():
    cdef CAppHandle* app_handle = get_handle()
    cdef CMemoryManager* mem_manager = CMemoryManager_init(app_handle)

    cdef CVirtualAddress* int32_array = CMemoryManager_virtual_alloc(mem_manager, <size_t>10*sizeof(int))

    CVirtualAddress_write_int32(int32_array, 0)
    CVirtualAddress_write_int32_offset(int32_array, 1, 1*sizeof(int))
    CVirtualAddress_write_int32_offset(int32_array, 2, 2*sizeof(int))

    CMemoryManager_virtual_free_address(mem_manager, int32_array)
    CMemoryManager_virtual_free_all(mem_manager) 

    CMemoryManager_free(mem_manager)
    CAppHandle_free(app_handle)
    return 0

```

# License

