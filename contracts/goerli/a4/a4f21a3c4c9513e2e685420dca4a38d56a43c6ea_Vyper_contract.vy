# @version 0.2.16
# @author maka
# @title interFaceStation
# @notice fun with interfaces

interface IERC20:
  def totalSupply() -> uint256: view
  def balanceOf(account: address) -> uint256: view
  def transfer(recipient: address, amount: uint256) -> bool: nonpayable
  def allowance(owner: address, spender: address) -> uint256: view
  def approve(spender: address, amount: uint256) -> bool: nonpayable
  def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable


event Withdraw:
  token: address
  amount: uint256

event Exchange:
  tokenIn: address
  tokenOut: address
  skimmed: bool


admin: address
weth: public(address)
router: public(address)

@external
def __init__(_weth: address, _router: address):
  self.admin = msg.sender 
  self.weth = _weth
  self.router = _router


# @notice you can deposit eth via direct transfer
#  fallback will be called, and any eth will be auto wrapped ready to swap 
@external
@payable
def __default__():
  raw_call(
    self.weth,
    method_id('deposit()'),
    value = msg.value,
    max_outsize=0,
    is_delegate_call=False
  )


# just playing around
@view
@external
def getSupply(_token: address) -> uint256:
  return IERC20(_token).totalSupply()

@view
@external
def getBalance(_token: address, _account: address) -> uint256:
  return IERC20(_token).balanceOf(_account)


# @notice can only be called by a function that does do a check on caller
@internal
def transfer(_token: address, _recipient: address, _amount: uint256) -> bool:
  return IERC20(_token).transfer(_recipient, _amount)

@external
def withdrawAll(_token: address):
  assert msg.sender == self.admin
  amount: uint256 = IERC20(_token).balanceOf(self)
  self.transfer(_token, self.admin, amount)
  log Withdraw(_token, amount)


# @params
# tokenIn: address of token to swap from
# tokenOut: address of token to swap to
# amountIn: exact amount of input token to be swapped
# amountOutMin: minimum amount of output token willing to receive
# skim: bento style from wallet toggle, false if from contracts balance
#
@external
def swap(_tokenIn: address, _tokenOut: address, _amountIn: uint256, _amountOutMin: uint256, 
  _skim: bool)-> Bytes[128]:
  assert msg.sender == self.admin

  if _skim == True:
    assert IERC20(_tokenIn).balanceOf(msg.sender) >= _amountIn
    IERC20(_tokenIn).transferFrom(msg.sender, self, _amountIn)

  approved: bool = IERC20(_tokenIn).approve(self.router, _amountIn)
  assert approved == True

  # @notice we raw_call the routers swap function as it needs a dynamic array of addresses
  #  the value passed will be the number of args (including offset) multiplied by 32
  # @dev pass offset in place of dynamic array, then at offset pass length of the array
  #  arguments of the array will be the final bytes
  response: Bytes[128] = raw_call(
    self.router,
    concat(
      method_id("swapExactTokensForTokens(uint256,uint256,address[],address,uint256)"),
      convert(_amountIn, bytes32),       # exact amount to swap
      convert(_amountOutMin, bytes32),   # minimum amount to receieve (max slippage)
      convert(160, bytes32),             # offset for path is number of arguments*bytes32
      convert(self, bytes32),            # destination for tokens
      convert(block.timestamp, bytes32), # deadline
      convert(2, bytes32),               # number of args in the path
      convert(_tokenIn, bytes32),        # args in the path...
      convert(_tokenOut, bytes32)        # ...
    ),
    is_delegate_call=False,
    max_outsize=128
  )
  log Exchange(_tokenIn, _tokenOut, _skim)
  return response


@external
def sweep():
  assert msg.sender == self.admin
  selfdestruct(self.admin)


# 1 love