# @version ^0.2.8
# @title MiniVZoo scrap router
# @notice Doesn't really route anything
#  just handles some low level calls in an atomic way
# @author Maka

interface IERC20:
  def balanceOf(account: address) -> uint256: view
  def approve(spender: address, amount: uint256) -> bool: nonpayable
  def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable

interface IFactory:
  def getPair(tokenA: address, tokenB: address) -> address: view
  def createPair(tokenA: address, tokenB: address) -> address: nonpayable

interface ISLP:
  def mint(to: address) -> uint256: nonpayable
  def burn(to: address) -> (uint256, uint256): nonpayable
  def swap(amount0Out: uint256, amount1Out: uint256, to: address): nonpayable
  def token0() -> address: view
  def token1() -> address: view
  def getReserves() -> (uint256, uint256): view
  
factory: public(address)
weth: public(address)
admin: address
isActive: public(bool)

@external
def __init__(_factory: address, _weth: address, _admin: address):
  self.factory = _factory
  self.weth = _weth
  self.admin = _admin
  self.isActive = False

@internal
def _getPair(_tokenIn: address, _tokenOut: address) -> (address):
  pair: address = IFactory(self.factory).getPair(_tokenIn, _tokenOut)
  return pair

@internal
def _sortTokens(_pair: address) -> (address, address):
  # if we are here it is a pair and will return tokens
  token0: address = ISLP(_pair).token0()
  token1: address = ISLP(_pair).token1()
  return token0, token1

@external
def enter(_tokenA: address, _tokenB: address, _amountA: uint256, _amountB: uint256):
  assert self.isActive == True
  pair: address = self._getPair(_tokenA, _tokenB)
  if pair == ZERO_ADDRESS:
    pair = IFactory(self.factory).createPair(_tokenA, _tokenB)
  assert pair != ZERO_ADDRESS
  tokens: address[2] = [_tokenA, _tokenB] 
  amounts: uint256[2] = [_amountA, _amountB]
  for i in range(2):
    IERC20(tokens[i]).transferFrom(msg.sender, pair, amounts[i])
  ISLP(pair).mint(msg.sender)

@external
def exit(_pair: address, _amount: uint256):
  assert self.isActive == True
  IERC20(_pair).transferFrom(msg.sender, _pair, _amount)
  ISLP(_pair).burn(msg.sender)

@external
def swap(_tokenIn: address, _tokenOut: address, _amountIn: uint256):
  assert self.isActive == True
  # let our extensive routing commence /s
  pair: address = self._getPair(_tokenIn, _tokenOut)
  assert pair != ZERO_ADDRESS
  token0: address = ZERO_ADDRESS 
  token1: address = ZERO_ADDRESS 
  token0, token1 = self._sortTokens(pair)
  # (reserveIn, reserveOut) = token == token0 ? (reserveA, reserveB) : (reserveB, reserveA)
  # (reserveIn, reserveOut) = (reserveA, reserveB) if _tokenIn == token0 else (reserveB, reserveA)
  reserveIn: uint256 = 0
  reserveOut: uint256 = 0
  if _tokenIn == token0:
    reserveIn, reserveOut = ISLP(pair).getReserves()
  else:
    reserveOut, reserveIn = ISLP(pair).getReserves()
  assert reserveIn != reserveOut
  # do the math
  amountInWithFee: uint256 = _amountIn * 997
  numerator: uint256 = amountInWithFee * reserveOut
  denominator:uint256 = (reserveIn * 1000) + amountInWithFee
  amountOut: uint256 = numerator / denominator

  # enforced slippage *remove*
  slippage: uint256 = (amountOut / 100) * 10
  amountOut = amountOut - slippage
  assert amountOut != 0
  
  # swap
  amount0Out: uint256 = 0
  amount1Out: uint256 = 0
  #(amount1Out = amountOut) if tokenIn == token0 else (amount0Out = amountOut)
  if _tokenIn == token0:
    amount1Out = amountOut
  else:
    amount0Out = amountOut

  IERC20(_tokenIn).transferFrom(msg.sender, pair, _amountIn)
  ISLP(pair).swap(amount0Out, amount1Out, msg.sender)
  # issue?
#  data: bytes32 = EMPTY_BYTES32
#  raw_call(
#    pair,
#    concat(
#      method_id("swap(uint256,uint256,address,bytes32)"),
#      convert(amount0Out, bytes32),     # amount of token0 out
#      convert(amount1Out, bytes32),     # amount of token1 out
#      convert(msg.sender, bytes32),     # destination
#      data),                            # empty when paying in advance
#    is_delegate_call=False,
#    max_outsize=0
#  )

@external
def set(_setting: bool):
  assert msg.sender == self.admin
  self.isActive = _setting

# 1 love