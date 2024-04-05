from CythonVirtualMemoryToolkit import process

app = process.Application(b"Step")
TUTORIAL_EXE_MODULE: bytes = b"Tutorial-x86_64.exe"
TUTORIAL_EXE_ADDR: int = app.modules[TUTORIAL_EXE_MODULE]


hook_addr: int = TUTORIAL_EXE_ADDR + 0x2b4bc

print(str(app))

addr1: int = app.alloc_memory(8)
addr2: int = app.alloc_memory(8)
addr3: int = app.alloc_memory(8)
addr4: int = app.alloc_memory(8)

print(hex(addr1))
print(hex(addr2))
print(hex(addr3))
print(hex(addr4))
input()

app.dealloc_memory(addr2)

input()
