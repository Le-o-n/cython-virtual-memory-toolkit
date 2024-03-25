from CythonVirtualMemoryToolkit import process


app = process.Application(b"Step", True)

app.write_memory_int(0x015DE5F8, 69, 3)
