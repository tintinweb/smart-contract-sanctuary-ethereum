# @version 0.3.7

"""
@title Vyper Token
@license GNU AGPLv3
"""

interface IERC20:
    def totalSupply() -> uint256: view
    def decimals() -> uint256: view
    def symbol() -> String[20]: view
    def name() -> String[100]: view
    def getOwner() -> address: view
    def balanceOf(account: address) -> uint256: view
    def transfer(recipient: address, amount: uint256) -> bool: nonpayable
    def allowance(_owner: address, spender: address) -> uint256: view
    def approve(spender: address, amount: uint256): nonpayable
    def transferFrom(
        sender: address, 
        recipient: address, 
        amount: uint256
    ) -> bool: nonpayable

event Transfer:
    sender: indexed(address)
    recipient: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

implements: IERC20
        
_name: constant(String[100]) = "Vyper"
_symbol: constant(String[20]) = "VY"
_decimals: constant(uint256) = 18
_balances: (HashMap[address, uint256])
_allowances: (HashMap[address, HashMap[address, uint256]])
InitialSupply: constant(uint256) = 1_000_000_000 * 10**_decimals
LaunchTimestamp: uint256
deadWallet: constant(address) = 0x000000000000000000000000000000000000dEaD
owner: address

@external
def __init__():
    deployerBalance: uint256 = InitialSupply
    sender: address = msg.sender
    self._balances[sender] = deployerBalance
    self.owner = sender
    log Transfer(empty(address), sender, deployerBalance)

@view
@external
def getBurnedTokens() -> uint256:
    return self._balances[deadWallet]

@view
@external
def getCirculatingSupply() -> uint256:
    return InitialSupply - self._balances[deadWallet]

@external
def SetupEnableTrading():
    sender: address = msg.sender
    assert sender == self.owner, "Ownable: caller is not the owner"
    assert self.LaunchTimestamp == 0, "AlreadyLaunched"
    self.LaunchTimestamp = block.timestamp

@view
@external
def getOwner() -> address:
    return self.owner

@view
@external
def name() -> String[100]:
    return _name

@view
@external
def symbol() -> String[20]:
    return _symbol

@view
@external
def decimals() -> uint256:
    return _decimals

@view
@external
def totalSupply() -> uint256:
    return InitialSupply

@view
@external
def balanceOf(account: address) -> uint256:
    return self._balances[account]

@nonpayable
@external
def transfer(
    recipient: address,
    amount: uint256
) -> bool:
    self._transfer(msg.sender, recipient, amount)
    return True

@view
@external
def allowance(
    _owner: address,
    spender: address
) -> uint256:
    return self._allowances[_owner][spender]

@nonpayable
@external
def approve(
    spender: address,
    amount: uint256
):
    self._approve(msg.sender, spender, amount)

@external
def transferFrom(
    sender: address,
    recipient: address,
    amount: uint256
) -> bool:
    self._transfer(sender, recipient, amount)
    currentAllowance: uint256 = self._allowances[sender][msg.sender]
    assert currentAllowance >= amount, "Transfer > allowance"
    self._approve(sender, msg.sender, currentAllowance - amount)
    return True

@external
def increaseAllowance(
    spender: address,
    addedValue: uint256
) -> bool:
    self._approve(msg.sender, spender, self._allowances[msg.sender][spender] + addedValue)
    return True

@external
def decreaseAllowance(
    spender: address,
    subtractedValue: uint256
) -> bool:
    currentAllowance: uint256 = self._allowances[msg.sender][spender]
    assert currentAllowance >= subtractedValue, "<0 allowance"
    self._approve(msg.sender, spender, currentAllowance - subtractedValue)
    return True

@external
@payable
def __default__(): pass

@internal
def _transfer(
    sender: address,
    recipient: address,
    amount: uint256
):
    assert sender != empty(address), "Transfer from zero"
    assert recipient != empty(address), "Transfer to zero"
    assert self.LaunchTimestamp > 0, "trading not yet enabled"
    self._feelessTransfer(sender, recipient, amount)

@internal
def _feelessTransfer(
    sender: address,
    recipient: address,
    amount: uint256
):
    senderBalance: uint256 = self._balances[sender]
    assert senderBalance >= amount, "Transfer exceeds balance"
    self._balances[sender] -= amount
    self._balances[recipient] += amount
    log Transfer(sender, recipient, amount)

@internal
def _approve(
    owner: address,
    spender: address,
    amount: uint256
) -> bool:
    assert owner != empty(address), "Approve from zero"
    assert spender != empty(address), "Approve from zero"
    self._allowances[owner][spender] = amount
    log Approval(owner, spender, amount)
    return True