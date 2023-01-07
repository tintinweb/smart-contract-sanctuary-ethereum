# @version 0.3.7
greeting: String[32]

@external
def __init__(_greeting: String[32]):
    self.greeting = _greeting


@view
@external
def greet() -> String[32]:
    return self.greeting


@external
def setGreeting(_greeting: String[32]):
    self.greeting = _greeting