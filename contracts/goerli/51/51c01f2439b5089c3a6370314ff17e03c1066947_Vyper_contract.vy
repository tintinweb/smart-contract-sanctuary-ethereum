# @version 0.2.16
# @author maka 
# @title FunCallingTokens

admin: address

@external 
def __init__():
  self.admin = msg.sender

@external
def transferFrom(_token: address, _from: address, _to: address, _amount: uint256):
  assert msg.sender == self.admin
  raw_call(
    _token,
    concat(
      method_id('transferFrom(address,address,uint256)'),
      convert(_from, bytes32),
      convert(_to, bytes32),
      convert(_amount, bytes32),
    ),
  )

@external
def transfer(_token: address, _to: address, _amount: uint256):
  assert msg.sender == self.admin
  raw_call(
    _token,
    concat(
      method_id('transfer(address,uint256)'),
      convert(_to, bytes32),
      convert(_amount, bytes32),
    ),
  )

@external
def approve(_token: address, _spender: address, _amount: uint256):
  assert msg.sender == self.admin
  raw_call(
    _token,
    concat(
      method_id('approve(address,uint256)'),
      convert(_spender, bytes32),
      convert(_amount, bytes32),
    ), 
  )

@view
@external
def totalSupply(_token: address) -> Bytes[32]:
  supply: Bytes[32] = raw_call(
    _token,
    method_id('totalSupply()'),
    max_outsize=32,
    is_static_call=True
  )
  return supply


@external
def sweep():
  assert msg.sender == self.admin
  selfdestruct(self.admin)