

class UnableToAcquireHandle(Exception):
    """
    Exception raised when unable to acquire a necessary resource handle.
    """

    def __init__(self, message="Unable to acquire the resource handle"):
        super().__init__(message)
