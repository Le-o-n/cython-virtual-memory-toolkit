
import time
from CythonVirtualMemoryToolkit import process  # type: ignore
from CythonVirtualMemoryToolkit.errors import UnableToAcquireHandle


app: process.AppHandle | None = None
while not app:
    try:
        app = process.AppHandle.from_window_name(b"Steam")
    except UnableToAcquireHandle:
        print("Unable to find window!")
        app = None
        time.sleep(1)
    except Exception as e:
        print(f"Unknown exception! {str(e)}")
        exit(-1)

print(app)
