# @version ^0.3.3
# @title Jaguchiv02
# @notice stores faucet funds in bento, 
#  earning additional reserves when idle.
#  can top up operators balance if too low.
# @author Maka
#--

#-- interface -- 
interface SukoshiBento:
  def deposit(
    token: address,  # token to push
    from_: address,  # address to pull from
    to: address,     # account to push to
    amount: uint256, # amount to push
    share: uint256   # 0 if amount not 0
  ) -> (uint256, uint256): payable

  def withdraw(
    token: address,  # token to push        
    from_: address,  # account to pull from
    to:   address,   # address to push to
    amount: uint256, # amount to push
    share: uint256   # 0 if amount not 0
  ) -> (uint256, uint256): nonpayable

  def balanceOf(
    token: address,  # token to enquire on
    account: address # account to enquire of
  ) -> uint256: view
#--

#-- events --
# log listings
event Whitelist:
  entity: indexed(address)
  is_whitelisted: bool
# rely on bento to log deposit/withdraw
#--

#-- defines --
#
# hardcode bento address to save some gas
BENTOBOX: constant(address) = 0xF5BCE5077908a1b7370B9ae04AdC565EBd643966
# contract controller
admin: public(address)
# admin only toggle for additional functionality
admin_only: bool
# contract operator (an eoa that can call the contract)
operator: public(address) # can leave unset
# max amount to withdraw on each request
max_disperse: public(uint256)
# min amount to hold at 'operator' for gas
min_reserve: uint256 # can be 0
# mapping of addresses with restricted access to functionality
whitelisted: HashMap[address, bool]
# weth used only to view reserves
weth: address # check constuctor if needed
#--

#-- functions --
#
#- on initialisation
@external
def __init__(_weth: address):
  self.admin = msg.sender
  self.admin_only = True
  self.whitelisted[msg.sender] = True
  self.max_disperse = 0
  self.min_reserve = 0
  self.weth = _weth
  log Whitelist(msg.sender, True)
#--

#- core functionality of 'littlebento'
#
# deposits msg.value of 'eth' to this contracts account
@internal
@payable
def _deposit(_val: uint256):
  SukoshiBento(BENTOBOX).deposit(
    ZERO_ADDRESS,
    self,
    self,
    _val,
    0,
    value=_val
  )

# withdraws _val of 'eth' from this contracts account
@internal
def _withdraw(_des: address, _val: uint256):
  SukoshiBento(BENTOBOX).withdraw(
    ZERO_ADDRESS,
    self,
    _des,
    _val,
    0
  )

# returns balance of 'weth' for this contracts account
@internal
@view
def _balance() -> uint256:
  return SukoshiBento(BENTOBOX).balanceOf(self.weth, self)
#--

#- core functionality of self
#
# the fallback function and intended way to deposit
@external
@payable
def __default__():
  assert len(msg.data) == 0
  self._deposit(msg.value)

# set a new admin
@external
def set_admin(_new_admin: address):
  assert msg.sender == self.admin
  self.whitelisted[_new_admin] = True
  self.admin = _new_admin
  log Whitelist(_new_admin, True)

# set a new operator
@external
def set_operator(_new_operator: address):
  assert msg.sender == self.admin
  self.whitelisted[_new_operator] = True
  self.operator = _new_operator
  log Whitelist(_new_operator, True)

# add/remove address from whitelist
@external
def set_whitelist(_address: address, _bool: bool):
  assert msg.sender == self.admin 
  self.whitelisted[_address] = _bool
  log Whitelist(_address, _bool)

# toggle admin only
@external
def set_admin_only(_bool: bool):
  assert msg.sender == self.admin
  self.admin_only = _bool

# set max to grant on a request
@external
def set_disperse(_amount: uint256):  
  assert msg.sender == self.admin 
  self.max_disperse = _amount

# set min to retain for expenses
@external
def set_reserve(_amount: uint256):  
  assert msg.sender == self.admin 
  self.min_reserve = _amount

# returns the faucets bento balance
@external
@view
def get_reserves() -> uint256:
  return self._balance()

# grant faucet funds to an address
@external
def drip(_beneficiary: address):
  if (self.admin_only == False): # check who can call
    assert self.whitelisted[msg.sender] == True
    if ( # only if more than 0 then check ops balance
      self.min_reserve > 0 and
      self.operator.balance < self.min_reserve
    ): # if both True then first fund ops *expensive
      self._withdraw(self.operator, self.min_reserve)
  else: # else just check it is admin *cheap
    assert msg.sender == self.admin 
  # then we can disperse funds
  self._withdraw(_beneficiary, self.max_disperse)
#--
#
# - 1love