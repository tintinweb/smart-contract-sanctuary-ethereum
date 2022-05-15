# @version 0.2.16
# @author maka 
# @title newWethWhoDis

#interface Weth:
#  def deposit(): payable
#  def withdraw(_wad: uint256):

admin: address
weth: public(address)

@external
def __init__(_weth: address):
  self.admin = msg.sender
  self.weth = _weth

@external
@payable
def __default__():
  pass

@external
@payable
def deposit():
  assert msg.sender == self.admin
  raw_call(
    self.weth,
    method_id('deposit()'),
    value = msg.value,
    max_outsize=0,
    is_delegate_call=False
  )

@external
def withdraw(_wad: uint256):
  assert msg.sender == self.admin
  raw_call(
    self.weth,
    concat(
      method_id('withdraw(uint256)'),
      convert(_wad, bytes32)
    ),
    value = 0,
    max_outsize=0,
    is_delegate_call=False
  )

@external
def sweep():
  assert msg.sender == self.admin
  selfdestruct(msg.sender)


# 1 love