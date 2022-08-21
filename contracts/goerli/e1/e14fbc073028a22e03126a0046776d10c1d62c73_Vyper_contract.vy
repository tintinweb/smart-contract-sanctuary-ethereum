# @version 0.3.6
# @title timelock
# @notice example timelock contract
# @author Maka

# mapping for balances and durations
balances: public(HashMap[address, uint256])
lock_time: public(HashMap[address, uint256])

# initial lock time defined in seconds
DURATION: constant(uint256) = 3600  # 1hr

# events for tracking
event Deposit:
  account: indexed(address)
  amount: uint256
event Withdraw:
  account: indexed(address)
  amount: uint256

# function to deposit. Returns lock time
@external
@payable
def deposit() -> uint256:
  self.balances[msg.sender] += msg.value
  self.lock_time[msg.sender] = block.timestamp + DURATION
  log Deposit(msg.sender, msg.value)
  return self.lock_time[msg.sender]
  
# fn to add time if a lock is present.
# takes time to increase, in seconds. Returns new lock time
@external
def increase_lock_time(_time_to_increase: uint256) -> uint256:
  current_lock: uint256 = self.lock_time[msg.sender] 
  if current_lock > 0:
    self.lock_time[msg.sender] = current_lock + _time_to_increase
  return self.lock_time[msg.sender]

# fn to withdraw once lock time has passed.
# transfers account share to account holder
@external
def withdraw():
  assert self.balances[msg.sender] > 0
  assert block.timestamp > self.lock_time[msg.sender]
  amount: uint256 = self.balances[msg.sender]
  self.balances[msg.sender] = 0
  send(msg.sender, amount)
  log Withdraw(msg.sender, amount)

# fn to have constant be publicly viewable. Returns time in seconds
@external
@view
def get_duration() -> uint256:
  return DURATION

# fn to work out time remaining. Returns time left in seconds
@external
@view
def fetch_remaining(_account: address) -> uint256:
  return self.lock_time[_account] - block.timestamp

# 1 love