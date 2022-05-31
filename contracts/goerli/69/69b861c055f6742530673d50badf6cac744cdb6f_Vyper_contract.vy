# @version ^0.3.3
# @title CrudeRescue
#
# @notice This is a simple implementation of a rescue contract in vy
# Can test by sending your usdc to the sushi router on goerli and deploying this with a bit of eth.
#
# Usually don't have time to use these as bots will back run a users mistake, but sometimes you will, 
#  and they have saved significant sums.
#
# Can add more calls to be precise with amounts, unwrap the dust, self destruct or have a withdraw function.
# But for simplicity this is a relatively stripped down example to test the new dynamic arrays in vyper.
# 
# @author Maka

interface IERC20:
  def balanceOf(account: address) -> uint256: view
  def approve(spender: address, amount: uint256) -> bool: nonpayable

interface SushiRouter:
  def removeLiquidityETHSupportingFeeOnTransferTokens(
      token: address,
      liquidity: uint256,
      amountTokenMin: uint256,
      amountETHMin: uint256,
      to:address,
      deadline: uint256
  ) -> uint256: nonpayable

  def addLiquidity(
      tokenA: address,
      tokenB: address,
      amountADesired: uint256,
      amountBDesired: uint256,
      amountAMin: uint256,
      amountBMin: uint256,
      to: address,
      deadline: uint256
  ) -> (uint256, uint256, uint256): nonpayable

  def swapExactTokensForTokens(
    amountIn: uint256,
    amountOutMin: uint256,
    path: DynArray[address, 2],
    to: address,
    deadline: uint256
  ): nonpayable

usdc: constant(address) = 0xD87Ba7A50B2E7E660f678A895E4B72E7CB4CCd9C
weth: constant(address) = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
router: constant(address) = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506
slp: constant(address) = 0x19DA2E185dB2842710FDed575E9da96c66cc4025

guardian: public(address)

@external
@payable
def __init__():
  self.guardian = msg.sender 
  raw_call(weth, method_id('deposit()'), value = msg.value, max_outsize=0)

  amountIn: uint256 = (IERC20(weth).balanceOf(self) / 2)
  # This is what we are testing today
  path: DynArray[address, 2] = [weth, usdc]
  
  # Approve weth and swap for stranded token
  IERC20(weth).approve(router, IERC20(weth).balanceOf(self))
  SushiRouter(router).swapExactTokensForTokens(amountIn, 0, path, self, block.timestamp)

  # Approve the token we just swapped for, then add liquidity to the pool for eth and the stranded token   
  IERC20(usdc).approve(router, IERC20(usdc).balanceOf(self))
  SushiRouter(router).addLiquidity(usdc, weth, IERC20(usdc).balanceOf(self), amountIn, 0, 0, self, block.timestamp)

  # Approve the lp then remove liquidity and the stranded token to the specified destination
  IERC20(slp).approve(router, IERC20(slp).balanceOf(self))
  SushiRouter(router).removeLiquidityETHSupportingFeeOnTransferTokens(
    usdc, 
    IERC20(slp).balanceOf(self), 
    0, 
    0, 
    self.guardian, 
    block.timestamp
  )

  # 1love