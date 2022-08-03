# @version 0.3.3
from vyper.interfaces import ERC20

USDC: constant(address) = 0x5FfbaC75EFc9547FBc822166feD19B05Cd5890bb
WETH: constant(address) = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6

NonfungiblePositionManagerAddress: constant(address) = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88
SwapRouterAddress: constant(address) = 0xE592427A0AEce92De3Edee1F18E0157C05861564

poolFee: constant(uint256) = 3000

struct MintParams:
  token0: address
  token1: address
  fee: uint256
  tickLower: int24
  tickUpper: int24
  amount0Desired: uint256
  amount1Desired: uint256
  amount0Min: uint256
  amount1Min: uint256
  recipient: address
  deadline: uint256

struct MintReturnParams:
  tokenId: uint256
  liquidity: uint128
  amount0: uint256
  amount: uint256

struct ExactInputSingleParams:
  tokenIn: address
  tokenOut: address
  fee: uint24
  recipient: address
  deadline: uint256
  amountIn: uint256
  amountOutMinimum: uint256
  sqrtPriceLimitX96: uint160

interface INonfungiblePositionManager:
  def mint(params: MintParams) -> MintReturnParams: nonpayable

interface ISwapRouter:
 def exactInputSingle(params: ExactInputSingleParams) -> uint256: payable


@payable
@external
def deposit(tickLower: int24, tickUpper: int24) -> MintReturnParams:

  assert msg.value > 0

  deadline: uint256 = block.timestamp + 15

  amount0ToMint: uint256 = ISwapRouter(SwapRouterAddress).exactInputSingle(ExactInputSingleParams({tokenIn: WETH, tokenOut: USDC, fee: 3000, recipient: msg.sender, deadline: deadline, amountIn: msg.value / 2, amountOutMinimum: 0, sqrtPriceLimitX96: 0}))
  amount1ToMint: uint256 = ISwapRouter(SwapRouterAddress).exactInputSingle(ExactInputSingleParams({tokenIn: WETH, tokenOut: WETH, fee: 3000, recipient: msg.sender, deadline: deadline, amountIn: msg.value / 2, amountOutMinimum: 0, sqrtPriceLimitX96: 0}))

  ERC20(USDC).approve(NonfungiblePositionManagerAddress, amount0ToMint)
  ERC20(WETH).approve(NonfungiblePositionManagerAddress, amount1ToMint)

  params: MintParams = MintParams({token0: USDC, token1: WETH, fee: poolFee, tickLower: tickLower, tickUpper: tickUpper, amount0Desired: amount0ToMint, amount1Desired: amount1ToMint, amount0Min: 0, amount1Min: 0, recipient: msg.sender, deadline: block.timestamp})
  result: MintReturnParams = INonfungiblePositionManager(NonfungiblePositionManagerAddress).mint(params)

  return result