# @version 0.3.7

# Mapping from address to balance
balances: public(HashMap[address, uint256])

# Mapping from address to allowance
allowed: public(HashMap[address, HashMap[address, uint256]])

# Total supply
totalSupply: public(uint256)

# Token name
name: public(String[32])

# Token symbol
symbol: public(String[32])

# Token decimals
decimals: public(uint256)

# Event for Transfer events
event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

# Initializes the contract
@external
def __init__():
    init_supply: uint256 = 1000000000 * 10 ** convert(18, uint256)
    self.name = "ShibAi"
    self.symbol = "SHIBAI"
    self.decimals = 18
    self.totalSupply = init_supply
    
    # Set the initial balance of the deployment wallet to the total supply
    self.balances[msg.sender] = self.totalSupply

# Returns the balance of the specified address
@external
def balanceOf(
    account: address
) -> uint256:
    return self.balances[account]

# Transfers the specified value from
@external
def transfer(
    to: address,
    _value: uint256
) -> bool:
    # Check if the sender has enough balance to cover the transfer
    assert self.balances[msg.sender] >= _value

    # Transfer the value from the sender to the recipient
    self.balances[msg.sender] -= _value
    self.balances[to] += _value

    # Emit a Transfer event
    log Transfer(msg.sender, to, _value)

    return True

# Approves the specified address to transfer the specified value from the sender
@external
def approve(
    spender: address,
    _value: uint256
) -> bool:
    self.allowed[msg.sender][spender] = _value

    return True

# Returns the allowance for the specified address
@external
def allowance(
    owner: address,
    spender: address
) -> uint256:
    return self.allowed[owner][spender]

# Transfers the specified value from the sender to the recipient using the allowance mechanism
@external
def transferFrom(
    _from: address,
    _to: address,
    _value: uint256
) -> bool:
    # Check if the sender has enough balance to cover the transfer
    assert self.balances[_from] >= _value

    # Check if the spender has enough allowance to cover the transfer
    assert self.allowed[_from][msg.sender] >= _value

    # Transfer the value from the sender to the recipient
    self.balances[_from] -= _value
    self.balances[_to] += _value

    # Deduct the amount from the allowance
    self.allowed[_from][msg.sender] -= _value

    # Emit a Transfer event
    log Transfer(_from, _to, _value)

    return True