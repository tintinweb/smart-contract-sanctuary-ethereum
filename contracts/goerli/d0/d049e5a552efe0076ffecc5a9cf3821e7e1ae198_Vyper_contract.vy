# @version 0.2.8
# @auther maka 
# @title basicSwapFun (non delegate)

admin: address
router: public(address)

@external 
def __init__(_router: address):
  self.admin = msg.sender
  self.router = _router

@internal
def transferFrom(_token: address, _from: address, _to: address, _amount: uint256):
  raw_call(
    _token,
    concat(
      method_id('transferFrom(address,address,uint256)'),
      convert(_from, bytes32),
      convert(_to, bytes32),
      convert(_amount, bytes32),
    ),
  )

@internal
def approve(_token: address, _spender: address, _amount: uint256):
  raw_call(
    _token,
    concat(
      method_id('approve(address,uint256)'),
      convert(_spender, bytes32),
      convert(_amount, bytes32),
    ), 
  )
 
@external
def swap(_tokenIn: address, _tokenOut: address, _amountIn: uint256, _amountOutMin: uint256)-> Bytes[128]:
  assert msg.sender == self.admin

  self.transferFrom(_tokenIn, msg.sender, self, _amountIn)
  self.approve(_tokenIn, self.router, _amountIn)

  result: Bytes[128] = raw_call(
    self.router,
    concat(
      method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"),
      convert(_amountIn, bytes32),
      convert(_amountOutMin, bytes32),
      convert(160, bytes32),
      convert(msg.sender, bytes32),
      convert(block.timestamp, bytes32),
      convert(2, bytes32),
      convert(_tokenIn, bytes32),
      convert(_tokenOut, bytes32)
    ),
    is_delegate_call=False,
    max_outsize=128
  )
  return result

@external
def sweep():
  assert msg.sender == self.admin
  selfdestruct(self.admin)