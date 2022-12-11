# @version ^0.3.3

from vyper.interfaces import ERC20

implements: ERC20

#EVENTS
event OwnershipTransferred:
    previousOwner: indexed(address)
    newOwner: indexed(address)

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address) #delegrated spender on behalf of owner
    _value: uint256

#METADATA
NAME: constant(String[10]) = "Test Token"
SYMBOL: constant(String[5]) = "TEST"
DECIMALS: constant(uint256) = 18

_totalSupply: uint256
_balances: HashMap[address,uint256]
_allowances: HashMap[address, HashMap[address,uint256]]
_minted: bool
_minter: address
owner: public(address)

#FUNCTIONS
# @dev Throws if called by any account other than the owner.
@internal
def onlyOwner():
    assert msg.sender == self.owner, "Only owner allowed."

@internal
def _transferOwnership(newOwner: address):
    oldOwner: address = self.owner
    self.owner = newOwner
    log OwnershipTransferred(oldOwner, newOwner)

@external
def __init__(name: String[10], symbol: String[5], decimals: uint8, supply: uint256):
    init_supply: uint256 = supply * 10 ** convert(decimals, uint256)
    self._balances[msg.sender] = init_supply
    self._totalSupply = init_supply
    self._minter = msg.sender
    log Transfer(empty(address), msg.sender, init_supply)

# @dev Leaves the contract without owner. Methods with onlyOwner will not be callable anymore.
@external
def renounceOwnership() -> bool:
    # Check if the caller is the contract owner
    self.onlyOwner()
    return True

@external
@view
def balanceOf(_address: address) -> uint256:
    return self._balances[_address]

@external
@view
def name() -> String[10]:
    return NAME

@external
@view
def totalSupply() -> uint256:
    return self._totalSupply

@external
@view
def allowance(_owner: address, _spender: address) -> uint256:
    return self._allowances[_owner][_spender]
    #checks state of allowances

@external
@view
def decimals() -> uint256:
    return DECIMALS


@internal
def _transfer(_from: address, _to: address, _amount: uint256):
    assert self._balances[_from] >= _amount, "The balance is not enough"
    assert _from != empty(address)
    assert _to != empty(address)
    self._balances[_from] -= _amount
    self._balances[_to] += _amount
    log Transfer(_from, _to, _amount)


@internal
def _approve(_owner: address, _spender: address, _amount: uint256):
    assert _owner != empty(address)
    assert _spender != empty(address)
    self._allowances[_owner][_spender] = _amount
    log Approval(_owner, _spender, _amount)

@external
def mint(_to: address, _tSupply: uint256) -> bool:
    assert msg.sender == self._minter, 'only owner can mint and only once'
    assert self._minted == False, 'This token has already been minted'
    self._totalSupply = 10 ** (_tSupply + DECIMALS)
    self._balances[_to] = self._totalSupply
    self._minted = True
    log Transfer(empty(address), _to, self._totalSupply)
    return True

@external
def approve(_spender: address, _amount_increased: uint256) -> bool:
    self._approve(msg.sender, _spender, self._allowances[msg.sender][_spender] + _amount_increased)
    return True

@external
def increaseAllowance(_spender: address, _amount_increased: uint256) -> bool:
    self._approve(msg.sender, _spender, self._allowances[msg.sender][_spender] + _amount_increased)
    return True

@external
def decreaseAllowance(_spender: address, _amount_decreased: uint256) -> bool:
    assert self._allowances[msg.sender][_spender] >= _amount_decreased, "negative allowance not allowed"
    self._approve(msg.sender, _spender, self._allowances[msg.sender][_spender] - _amount_decreased)
    return True

@external
def transfer(_to: address, _amount: uint256) -> bool:
    self._transfer(msg.sender, _to ,_amount)
    return True

@external
def burn(_to: address, _value: uint256):
    assert msg.sender == self._minter
    assert _to != empty(address)
    self._totalSupply += _value
    self._balances[_to] += _value
    log Transfer(empty(address), _to, _value)

@external
def transferFrom(_owner:address, _to: address, _amount: uint256) -> bool:
    assert self._allowances[_owner][msg.sender] >= _amount, "the allowance is not enough for this operation" #also ensures, by the values existence that the owner gave approval
    assert self._balances[_owner] >= _amount, "the balance is not enough for this operation"
    self._balances[_owner] -= _amount
    self._balances[_to] += _amount
    self._allowances[_owner][msg.sender] -= _amount
    return True