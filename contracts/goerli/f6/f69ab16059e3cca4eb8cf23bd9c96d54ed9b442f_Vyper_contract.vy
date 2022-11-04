# @version ^0.3.0

counter: public(uint256)
# test: public(mapping(uint256, uint256))

@external
def __init__() :
    self.counter = 1


@external
def increment(num: uint256) -> uint256 :
    self.counter += num
    return self.counter


@external
def decrement(num: uint256) -> uint256 :
    assert self.counter >= num, "Number is greater than counter"
    self.counter -= num
    return self.counter