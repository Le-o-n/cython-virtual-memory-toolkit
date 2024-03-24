from CythonVirtualMemoryToolkit import process


app = process.Application(b"Noita", True)
x = app.read_memory_float32(0x3f4d5498)  # Read 1 byte from memory

print(x)
