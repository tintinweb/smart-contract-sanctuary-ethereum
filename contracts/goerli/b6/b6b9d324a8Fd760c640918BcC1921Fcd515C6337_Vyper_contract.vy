# @version >=0.3

from vyper.interfaces import ERC20

a: public(uint256)
owner: public(address)

@external
def __init__():
    self.owner = msg.sender

@view
@external
def uintToBytes(input: uint256) -> bytes32:
    return convert(input, bytes32)

@external
def setAdmin(newAdmin: address):
    assert msg.sender == self.owner, "2"
    self.owner = newAdmin

@external
def setA(_a: uint256):
    assert msg.sender == self.owner, "1"
    self.a = _a