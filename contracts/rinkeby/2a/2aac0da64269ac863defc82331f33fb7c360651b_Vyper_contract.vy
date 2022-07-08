# @version ^0.2.7

NAME: constant(String[25]) = 'Vanilla'
DECIMALS: constant(uint256) = 18
_totalSupply: uint256
_minted: bool
_minter: address
_balances: HashMap[address, uint256]
_allowances: HashMap[address, HashMap[address, uint256]]

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approve:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

@external
def __init__():
    self._minter = msg.sender
    self._minted = False

@external
@view
def name() -> String[25]:
    return NAME

@external
@view
def totalSupply() -> uint256:
    return self._totalSupply

@external
@view
def balanceOf(_address:address) -> uint256:
    return self._balances[_address]

@internal
def _transfer(_from: address,_to: address, _amount: uint256):
    assert _from != ZERO_ADDRESS
    assert _to != ZERO_ADDRESS
    assert self._balances[_from] >= _amount, "Insufficient balance"
    self._balances[_from] -= _amount
    self._balances[_to] += _amount
    log Transfer(_from, _to, _amount)

@internal
def _approve(_owner: address, _spender: address, _amount: uint256):
    assert _owner != ZERO_ADDRESS
    assert _spender != ZERO_ADDRESS
    self._allowances[_owner][_spender] = _amount
    log Approve(_owner, _spender, _amount)

@external
def mint(_to: address, _tSupply: uint256) -> bool:
    assert msg.sender == self._minter, "Only creator can mint"
    assert self._minted == False, "Token has already been minted"
    self._totalSupply = _tSupply * 10 ** DECIMALS
    self._balances[_to] = self._totalSupply
    self._minted = True
    log Transfer(ZERO_ADDRESS, _to, self._totalSupply)
    return True

@external
def increaseAllowance(_spender: address, _amountIncreased: uint256) -> bool:
    self._approve(msg.sender, _spender, self._allowances[msg.sender][_spender] + _amountIncreased)
    return True

@external
def decreaseAllowance(_spender: address, _amountDecreased: uint256) -> bool:
    assert self._allowances[msg.sender][_spender] <= _amountDecreased, "Negative allowance not allowed"
    self._approve(msg.sender, _spender, self._allowances[msg.sender][_spender] - _amountDecreased)
    return True

@external
def trasfer(_to:address, _amount:uint256) -> bool:
    self._transfer(msg.sender, _to, _amount)
    return True

@external
def approve(_spender: address, _amount: uint256) -> bool:
    self._approve(msg.sender, _spender, _amount)
    return True

@external
def transferFrom(_owner: address, _to: address, _amount: uint256) -> bool:
    assert self._allowances[_owner][msg.sender] >= _amount, "Insufficient allowance"
    assert self._balances[_owner] >= _amount, "Insufficient balance"
    self._balances[_owner] -= _amount
    self._balances[_to] += _amount
    self._allowances[_owner][msg.sender] -= _amount
    return True

@external
@view
def allowance(_owner: address, _spender: address) -> uint256:
    return self._allowances[_owner][_spender]

@external
@view
def decimals() -> uint256:
    return DECIMALS