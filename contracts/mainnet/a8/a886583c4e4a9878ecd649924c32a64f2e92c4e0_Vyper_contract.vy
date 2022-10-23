# @version ^0.2.16

# Name: FukMEMES
# Website: https://fukmemes.fun/ 
# Twitter: https://twitter.com/FI_IkMEMES

# Supporting useless tokens is only delaying the future where great projects can thrive
# Every cent wasted on a useless token could've been spent to support a useful token
# FukMEMES wants to encourage users to focus on useful tokens and ignore the trash as it's only holding us back
# Share the message of FukMEMES, by talking/messaging those in your community about supporting positive real use case projects
# Send a FukMEMES token as an optional step to get the message out there
# FukMEMES is the ironic token to be shared to help bring an end to useless tokens
# Be apart of the movement and get involved however you can

# Tokenomics
# Maximum token supply from one time only mint: 42,000,000FukMEMES
# Buy/Sell/Transfer fees/taxes: 0% zero
# No Admin Keys

NAME: constant(String[8]) = "FukMEMES"
SYMBOL: constant(String[8]) = "FukMEMES"
DECIMALS: constant(uint256) = 18

event Transfers:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approve:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

_totalSupply: uint256
_balances: HashMap[address, uint256]
_allowances: HashMap[address,HashMap[address, uint256]]
_minted: bool
_minter: address

@external
def __init__():
    self._minter = msg.sender
    self._minted = False

@external
@view
def name() -> String[8]:
    return NAME

@external
@view
def symbol() -> String[8]:
    return SYMBOL

@external
@view
def totalSupply() -> uint256:
    return self._totalSupply

@external
@view
def allowance(_owner:address, _spender:address) -> uint256:
    return self._allowances[_owner][_spender]

@external
@view
def decimals() -> uint256:
    return DECIMALS

@external
@view
def balanceOf(_address:address) -> uint256:
    return self._balances[_address]

@internal
def _transfer(_from:address, _to:address, _value:uint256):
    assert self._balances[_from] >= _value, "Insufficient balance to complete transaction"
    assert _from != ZERO_ADDRESS
    assert _to != ZERO_ADDRESS
    self._balances[_from] -= _value
    self._balances[_to] += _value
    log Transfers(_from, _to, _value)

@internal
def _approve(_owner:address, _spender:address, _value:uint256):
    assert _owner != ZERO_ADDRESS # owner cannot be the zero address
    assert _spender != ZERO_ADDRESS # spender cannot be the zero address
    self._allowances[_owner][_spender] = _value
    log Approve(_owner, _spender, _value)

@external
def mint(_to:address, _tSupply:uint256) -> bool:
    assert msg.sender == self._minter, "Only the deployer can perform the mint and just once"
    assert self._minted == False, "The total supply has already been minted"
    self._totalSupply = _tSupply * 10 ** DECIMALS
    self._balances[_to] = self._totalSupply
    self._minted = True
    log Transfers(ZERO_ADDRESS, _to, self._totalSupply)  
    return True

@external
def increaseAllowance(_spender:address, _value_increased:uint256) -> bool:
    self._approve(msg.sender, _spender, self._allowances[msg.sender][_spender] + _value_increased)
    return True

@external
def decreaseAllowance(_spender:address, _value_decreased:uint256) -> bool:
    assert self._allowances[msg.sender][_spender] >= _value_decreased, "Negative allowance is not allowed"
    self._approve(msg.sender, _spender, self._allowances[msg.sender][_spender] - _value_decreased)
    return True

@external
def transfer(_to:address, _value:uint256) -> bool:
    self._transfer(msg.sender, _to, _value)
    return True

@external
def approve(_spender:address, _value:uint256) -> bool:
    self._approve(msg.sender, _spender, _value)
    return True

@external
def transferFrom(_owner:address, _to:address, _value:uint256) ->bool:
    assert self._allowances[_owner][msg.sender] >= _value, "The allowance is not enough to complete the transaction"
    assert self._balances[_owner] >= _value, "The balance is not enough to complete the transaction"
    self._balances[_owner] -= _value
    self._balances[_to] += _value
    self._allowances[_owner][msg.sender] -= _value
    return True