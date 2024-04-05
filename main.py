from CythonVirtualMemoryToolkit import process

app = process.Application(b"Step")
TUTORIAL_EXE_MODULE: bytes = b"Tutorial-x86_64.exe"
TUTORIAL_EXE_ADDR: int = app.modules[TUTORIAL_EXE_MODULE]


hook_addr: int = TUTORIAL_EXE_ADDR + 0x2b4bc

print(str(app))

addr1: int = app.alloc_memory(100, 0x1900000)

print(hex(addr1))

x = 0
while x < 100000:
    x += 1
    app.write_memory_uint32(addr1, x)
    x = app.read_memory_uint32(addr1)

input()
