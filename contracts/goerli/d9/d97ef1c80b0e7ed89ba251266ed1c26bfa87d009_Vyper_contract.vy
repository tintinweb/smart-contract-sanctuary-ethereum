# @version ^0.2.8
# @notice WETH implimentation in vy
# @author Maka
# @title vWETH

name: public(String[14])   # = 'Wrapped Ether'
symbol: public(String[4])  # = 'WETH'
decimals: public(uint256)  # = 18

event Approval:
  src: indexed(address) 
  guy: indexed(address) 
  wad: uint256

event Transfer:
  src: indexed(address)
  dst: indexed(address)
  wad: uint256 

event Deposit:
  dst: indexed(address) 
  wad: uint256

event Withdrawal:
  src: indexed(address) 
  wad: uint256

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])

@external
def __init__():
  self.name = 'Wrapped Ether'
  self.symbol = 'WETH' 
  self.decimals = 18

@external
@payable
def __default__(): 
  # can't call a function before it's defined
  # i.e. deposit() here
  # also can't call an external function internally
  # i.e swap functions and then call self.deposit()
  self.balanceOf[msg.sender] += msg.value
  log Deposit(msg.sender, msg.value)

@external
@payable
def deposit():
  self.balanceOf[msg.sender] += msg.value
  log Deposit(msg.sender, msg.value)

@external
def withdraw(wad: uint256):
  # @dev no need for assert?
  # @notice vyper doesn't allow underflows
  # @notice will revert on insufficient allowance
  self.balanceOf[msg.sender] -= wad
  send(msg.sender, wad)
  log Withdrawal(msg.sender, wad)

@external
@view
def totalSupply() -> uint256:
  return self.balance

@external
def approve(guy: address, wad: uint256) -> bool:
  self.allowance[msg.sender][guy] = wad
  log Approval(msg.sender, guy, wad)
  return True

@external
def transfer(dst: address, wad: uint256) -> bool:
  # @notice vyper does not allow underflows
  self.balanceOf[msg.sender] -= wad
  self.balanceOf[dst] += wad
  log Transfer(msg.sender, dst, wad)
  return True

@external
def transferFrom(src: address, dst: address, wad: uint256) -> bool:
  # @notice will revert on insufficient allowance
  self.balanceOf[src] -= wad
  self.balanceOf[dst] += wad
  self.allowance[src][msg.sender] -= wad
  log Transfer(src, dst, wad)
  return True 

# 1love