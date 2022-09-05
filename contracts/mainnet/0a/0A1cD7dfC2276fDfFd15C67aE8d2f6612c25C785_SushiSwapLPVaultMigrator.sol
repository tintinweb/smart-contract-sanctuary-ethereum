// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IV3SwapRouter.sol";

import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./IUniswapV2Router02.sol";
import "./IQuoter.sol";
import "./IMigrator.sol";
import "./ILp.sol";
import "./IWETH9.sol";

contract SushiSwapLPVaultMigrator is IMigrator, ReentrancyGuard, Ownable {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /* ========== CONSTANT ========== */
  address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /* ========== STATE VARIABLES ========== */
  uint256 public govLPTokenVaultFeeRate;
  uint256 public treasuryFeeRate;
  uint256 public controllerFeeRate;

  address public treasury;
  address public govLPTokenVault;
  address public controller;

  IUniswapV2Router02 public sushiSwapRouter;
  IV3SwapRouter public uniswapRouter;

  IQuoter public quoter;

  mapping(address => bool) public tokenVaultOK;

  /* ========== EVENTS ========== */
  event WhitelistTokenVault(address tokenVault, bool whitelisted);
  event Execute(
    uint256 vaultReward,
    uint256 treasuryReward,
    uint256 controllerReward,
    uint256 govLPTokenVaultReward
  );

  /* ========== ERRORS ========== */
  error SushiSwapLPVaultMigrator_OnlyWhitelistedTokenVault();
  error SushiSwapLPVaultMigrator_InvalidFeeRate();

  /* ========== CONSTRUCTOR ========== */
  constructor(
    address _treasury,
    address _controller,
    address _govLPTokenVault,
    uint256 _treasuryFeeRate,
    uint256 _controllerFeeRate,
    uint256 _govLPTokenVaultFeeRate,
    IUniswapV2Router02 _sushiSwapRouter,
    IV3SwapRouter _uniswapRouter,
    IQuoter _quoter
  ) {
    if (
      _govLPTokenVaultFeeRate + _treasuryFeeRate + _controllerFeeRate >= 1e18
    ) {
      revert SushiSwapLPVaultMigrator_InvalidFeeRate();
    }

    treasury = _treasury;
    controller = _controller;
    govLPTokenVault = _govLPTokenVault;
    treasuryFeeRate = _treasuryFeeRate;
    controllerFeeRate = _controllerFeeRate;
    govLPTokenVaultFeeRate = _govLPTokenVaultFeeRate;

    sushiSwapRouter = _sushiSwapRouter;
    uniswapRouter = _uniswapRouter;

    quoter = _quoter;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyWhitelistedTokenVault(address caller) {
    if (!tokenVaultOK[caller]) {
      revert SushiSwapLPVaultMigrator_OnlyWhitelistedTokenVault();
    }
    _;
  }

  /* ========== ADMIN FUNCTIONS ========== */
  function whitelistTokenVault(address _tokenVault, bool _isOk)
    external
    onlyOwner
  {
    tokenVaultOK[_tokenVault] = _isOk;

    emit WhitelistTokenVault(_tokenVault, _isOk);
  }

  /* ========== EXTERNAL FUNCTIONS ========== */
  function execute(bytes calldata _data)
    external
    onlyWhitelistedTokenVault(msg.sender)
    nonReentrant
  {
    (address lpToken, uint24 poolFee) = abi.decode(_data, (address, uint24));
    address baseToken = address(ILp(lpToken).token0()) != address(WETH9)
      ? address(ILp(lpToken).token0())
      : address(ILp(lpToken).token1());

    uint256 liquidity = IERC20(lpToken).balanceOf(address(this));
    IERC20(lpToken).safeApprove(address(sushiSwapRouter), liquidity);
    sushiSwapRouter.removeLiquidityETH(
      baseToken,
      liquidity,
      0,
      0,
      address(this),
      block.timestamp
    );

    uint256 swapAmount = IERC20(baseToken).balanceOf(address(this));
    IERC20(baseToken).safeApprove(address(uniswapRouter), swapAmount);
    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
      .ExactInputSingleParams({
        tokenIn: baseToken,
        tokenOut: WETH9,
        fee: poolFee,
        recipient: address(this),
        amountIn: swapAmount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });
    uniswapRouter.exactInputSingle(params);
    _unwrapWETH(address(this));
    uint256 govLPTokenVaultFee = govLPTokenVaultFeeRate.mulWadDown(
      address(this).balance
    );
    uint256 treasuryFee = treasuryFeeRate.mulWadDown(address(this).balance);
    uint256 controllerFee = controllerFeeRate.mulWadDown(address(this).balance);
    uint256 vaultReward = address(this).balance -
      govLPTokenVaultFee -
      treasuryFee -
      controllerFee;

    treasury.safeTransferETH(treasuryFee);
    govLPTokenVault.safeTransferETH(govLPTokenVaultFee);
    controller.safeTransferETH(controllerFee);
    msg.sender.safeTransferETH(vaultReward);

    emit Execute(vaultReward, treasuryFee, controllerFee, govLPTokenVaultFee);
  }

  function _unwrapWETH(address _recipient) private {
    uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));

    if (balanceWETH9 > 0) {
      IWETH9(WETH9).withdraw(balanceWETH9);
      _recipient.safeTransferETH(balanceWETH9);
    }
  }

  function getAmountOut(bytes calldata _data) public returns (uint256) {
    (address lpToken, uint24 poolFee, uint256 stakeAmount) = abi.decode(
      _data,
      (address, uint24, uint256)
    );
    address baseToken = address(ILp(lpToken).token0()) != address(WETH9)
      ? address(ILp(lpToken).token0())
      : address(ILp(lpToken).token1());

    (uint112 reserve0, uint112 reserve1, ) = ILp(lpToken).getReserves();
    (uint112 baseTokenReserve, uint112 ethReserve) = address(
      ILp(lpToken).token0()
    ) != address(WETH9)
      ? (reserve0, reserve1)
      : (reserve1, reserve0);

    uint256 ratio = stakeAmount.divWadDown(ILp(lpToken).totalSupply());
    uint256 baseTokenLiquidity = uint256(baseTokenReserve).mulWadDown(ratio);
    uint256 ethLiquidity = uint256(ethReserve).mulWadDown(ratio);

    uint256 amountOut = quoter.quoteExactInputSingle(
      baseToken,
      WETH9,
      poolFee,
      baseTokenLiquidity,
      0
    );

    uint256 totalEth = amountOut.add(ethLiquidity);
    return totalEth;
  }

  function getApproximatedExecutionRewards(bytes calldata _data)
    external
    returns (uint256)
  {
    uint256 totalEth = getAmountOut(_data);
    return controllerFeeRate.mulWadDown(totalEth);
  }

  /// @dev Fallback function to accept ETH.
  receive() external payable {}
}