# @version 0.3.1
"""
@notice Demo L1 ERC20 Token
"""
from vyper.interfaces import ERC20

implements: ERC20


event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event TransferOwnership:
    _old_owner: address
    _new_owner: address


allowance: public(HashMap[address, HashMap[address, uint256]])
balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)

owner: public(address)
future_owner: public(address)


@external
def __init__():
    self.owner = msg.sender
    log TransferOwnership(ZERO_ADDRESS, msg.sender)

    # initial transfer so block explorer registers this as a token contract
    log Transfer(ZERO_ADDRESS, msg.sender, 0)


@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    allowance: uint256 = self.allowance[_from][msg.sender]
    if allowance != MAX_UINT256:
        self.allowance[_from][msg.sender] = allowance - _value

    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value

    log Transfer(_from, _to, _value)
    return True


@external
def transfer(_to: address, _value: uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value

    log Transfer(msg.sender, _to, _value)
    return True


@external
def approve(_spender: address, _value: uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value

    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256) -> bool:
    assert msg.sender == self.owner  # dev: only owner

    self.balanceOf[_to] += _value
    self.totalSupply += _value

    log Transfer(ZERO_ADDRESS, _to, _value)
    return True


@external
def commit_transfer_ownership(_future_owner: address):
    assert msg.sender == self.owner  # dev: only owner

    self.future_owner = _future_owner


@external
def accept_transfer_ownership():
    assert msg.sender == self.future_owner  # dev: only future owner

    log TransferOwnership(self.owner, msg.sender)
    self.owner = msg.sender


@pure
@external
def name() -> String[32]:
    return "Demo L1 ERC20 Token"


@pure
@external
def symbol() -> String[8]:
    return "DEMO"


@pure
@external
def decimals() -> uint8:
    return 18