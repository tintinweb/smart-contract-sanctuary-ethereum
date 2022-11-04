# @version ^0.3.0

# Metadata

name: public(String[16])
symbol: public(String[16])
decimals: public(uint256)
totalSupply: public(uint256)

# Mappings

balanceOf: public(HashMap[address, uint256])
allowances: public(HashMap[address, HashMap[address, uint256]])

# Events

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256


# Constructor

@external
def __init__(_name: String[16], _symbol: String[16], _decimals: uint256, _totalSupply: uint256) :
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.totalSupply = _totalSupply * (10 ** _decimals)
    self.balanceOf[msg.sender] = self.totalSupply

    log Transfer(empty(address), msg.sender, self.totalSupply)

@external
def approve(spender: address, val: uint256) -> bool :
    assert spender != empty(address), "Zero address"
    self.allowances[msg.sender][spender] = val
    log Approval(msg.sender, spender, val)
    return True

@external
def transfer(receiver: address, val: uint256) -> bool :
    return self._transfer(msg.sender, receiver, val)
    

@internal
def _transfer(sender: address, receiver: address, val: uint256) -> bool :
    assert receiver != empty(address), "Zero address"
    assert self.balanceOf[sender] >= val, "Not enough balance for the sender"
    self.balanceOf[sender] -= val
    self.balanceOf[receiver] += val
    log Transfer(sender, receiver, val)
    return True

@external
def transferFrom(owner: address, spender: address, val: uint256) -> bool :
    assert self.allowances[owner][msg.sender] >= val, "Not enough allowance"
    self.allowances[owner][msg.sender] -= val
    return self._transfer(owner, spender, val)