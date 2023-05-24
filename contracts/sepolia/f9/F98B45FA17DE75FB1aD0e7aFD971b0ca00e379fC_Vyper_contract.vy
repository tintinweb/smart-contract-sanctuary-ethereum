# @version 0.3.7

a: public(uint256)

@external
def __init__():
    self.a = 1000
    assert self.a < MAX_UINT256