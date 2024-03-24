from CythonVirtualMemoryToolkit import process


app = process.Application(b"Noita", True)
x = app.read_memory_uint32(0x3fa2b320)  # Read 1 byte from memory

print(x)
