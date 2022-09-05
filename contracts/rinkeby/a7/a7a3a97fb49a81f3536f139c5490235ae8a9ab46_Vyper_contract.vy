# @version >=0.2.11 <=0.3.6

from vyper.interfaces import ERC20
implements: ERC20
MAX_SUPPLY: constant(uint256) = 100000000
INIT_SUPPLY: constant(uint256) = 1000000
founder: address
totalSupply: public(uint256)
name: public(String[32])
symbol: public(String[5])
balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]

event Transfer:
	sender: indexed(address)
	receiver: indexed(address)
	amount: uint256
event Approval:
	owner: indexed(address)
	spender: indexed(address)
	value: uint256

@external
def __init__(founder: address, name: String[32], symbol: String[5]):
	self.totalSupply = INIT_SUPPLY
	self.name = name
	self.symbol = symbol
	self.founder = founder
	self.balances[self.founder] = self.totalSupply

@view
@external
def get_max_supply() -> uint256:
	return MAX_SUPPLY

@internal
def _transferCoins(_src: address, _dst: address, _amount: uint256):
	assert _src != empty(address), "_transferCoins: cannot transfer from the zero address"
	assert _dst != empty(address), "_transfersCoins: cannot transfer to the zero address"
	self.balances[_src] -= _amount
	self.balances[_dst] += _amount

@external
def transfer(_to: address, _value: uint256) -> bool:
	assert self.balances[msg.sender] >= _value, "transfer: Not enough coins"
	self._transferCoins(msg.sender, _to, _value)
	log Transfer(msg.sender, _to, _value)
	return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
	allowance: uint256 = self.allowances[_from][msg.sender]
	assert self.balances[_from] >= _value and allowance >= _value
	self._transferCoins(_from, _to, _value)
	self.allowances[_from][msg.sender] -= _value
	log Transfer(_from, _to, _value)
	return True

@view
@external
def balanceOf(_owner: address) -> uint256:
	return self.balances[_owner]
@view
@external
def allowance(_owner: address, _spender: address) -> uint256:
	return self.allowances[_owner][_spender]

@external
def approve(_spender: address, _value: uint256) -> bool:
	self.allowances[msg.sender][_spender] = _value
	log Approval(msg.sender, _spender, _value)
	return True

@external
def increaseAllowance(spender: address, _value: uint256) -> bool:
    assert spender != empty(address)
    self.allowances[msg.sender][spender] += _value
    log Approval(msg.sender, spender, self.allowances[msg.sender][spender])
    return True

@external
def decreaseAllowance(spender: address, _value: uint256) -> bool:
    assert spender != empty(address)
    self.allowances[msg.sender][spender] -= _value
    log Approval(msg.sender, spender, self.allowances[msg.sender][spender])
    return True

@external
def mint(_account: address, _value: uint256) -> bool:
    # just contract owner can mint
    assert _account != empty(address), "_account can not be zero address"
    assert _account == self.founder, "just contract creater can mint token"
    if self.totalSupply + _value <= MAX_SUPPLY:
	    self.totalSupply += _value
	    self.balances[_account] += _value
    log Transfer(empty(address), _account, _value)
    return True