
from VirtualMemoryToolkit.handle import AppHandle  # type: ignore
from VirtualMemoryToolkit.utils.errors import UnableToAcquireHandle
import time

app: AppHandle | None = None
while not app:
    try:
        app = AppHandle.from_window_name(b"Step")
    except UnableToAcquireHandle:
        print("Unable to find window!")
        app = None
        time.sleep(1)
    except Exception as e:
        print(f"Unknown exception! {str(e)}")
        exit(-1)

print(app)
