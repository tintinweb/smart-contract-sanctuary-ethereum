# @version ^0.2.8
# 
# @notice Test token
# voting shares in the worlds best text editor
# @author Maka
# @title VIM

name: public(String[14])  
symbol: public(String[4]) 
decimals: public(uint256) 

event Approval:
  src: indexed(address) 
  spender: indexed(address) 
  amount: uint256

event Transfer:
  src: indexed(address)
  dst: indexed(address)
  amount: uint256 

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

@external
def __init__():
  self.name = 'Vim hjkl'
  self.symbol = 'VIM' 
  self.decimals = 18
  supply: uint256 = 100000*10**18
  self.balanceOf[msg.sender] = supply
  self.totalSupply = supply
  log Transfer(ZERO_ADDRESS, msg.sender, supply)

@external
def approve(spender: address, amount: uint256) -> bool:
  self.allowance[msg.sender][spender] = amount
  log Approval(msg.sender, spender, amount)
  return True

@external
def transfer(dst: address, amount: uint256) -> bool:
  self.balanceOf[msg.sender] -= amount
  self.balanceOf[dst] += amount
  log Transfer(msg.sender, dst, amount)
  return True

@external
def transferFrom(src: address, dst: address, amount: uint256) -> bool:
  self.balanceOf[src] -= amount
  self.balanceOf[dst] += amount
  self.allowance[src][msg.sender] -= amount
  log Transfer(src, dst, amount)
  return True

# 1love