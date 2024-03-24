from CythonVirtualMemoryToolkit import process


app = process.Application(b"Noita", True)

app.write_memory_float32(0x3f4d54a0, 4.0)
