from CythonVirtualMemoryToolkit import process


app = process.Application(b"Noita", True)

app.write_memory_int16(0x43e792cc, 256)
