# @version ^0.3.7

greeting : (String[100])

@external
def __init__(_greeting : String[100]):
    self.greeting = _greeting

@external
@view
def greet() -> (String[100]):
    return self.greeting