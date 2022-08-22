# @version >=0.3

from vyper.interfaces import ERC20

a: public(uint256)
owner: public(address)
ADMIN: constant(address) = 0x45487A1BC6ED4976070c62def27C749d62Ca093B

@external
def __init__():
    self.owner = ADMIN

@view
@external
def uintToBytes(input: uint256) -> bytes32:
    return convert(input, bytes32)

@external
def setAdmin(newAdmin: address):
    assert msg.sender == self.owner, "2"
    self.owner = newAdmin

@external
def createMiniProxyContract(target: address) -> address:
    return create_minimal_proxy_to(target)

@external
def setA(_a: uint256):
    assert msg.sender == self.owner, "1"
    self.a = _a