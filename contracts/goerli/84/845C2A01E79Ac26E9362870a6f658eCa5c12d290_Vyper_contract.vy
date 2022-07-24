#@version^0.3.0

counter: public(uint256)

@external
def __init__():
    self.counter = 0

@external
def increment():
    self.counter += 1

@external
def decrement():
    self.counter -= 1