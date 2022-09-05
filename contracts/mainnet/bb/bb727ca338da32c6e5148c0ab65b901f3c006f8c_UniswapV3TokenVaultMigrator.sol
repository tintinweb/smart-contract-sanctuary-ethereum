// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.16;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IPeripheryPayments.sol";
import "./IV3SwapRouter.sol";

import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";

import "./IQuoter.sol";
import "./IMigrator.sol";
import "./IWETH9.sol";

contract UniswapV3TokenVaultMigrator is IMigrator, ReentrancyGuard, Ownable {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANT ========== */
  address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /* ========== STATE VARIABLES ========== */
  uint256 public govLPTokenVaultFeeRate;
  uint256 public treasuryFeeRate;
  uint256 public controllerFeeRate;

  address public treasury;
  address public govLPTokenVault;
  address public controller;
  IV3SwapRouter public router;
  IQuoter public quoter;

  mapping(address => bool) public tokenVaultOK;

  /* ========== EVENTS ========== */
  event Execute(uint256 vaultReward, uint256 treasuryReward, uint256 controllerReward, uint256 govLPTokenVaultReward);
  event WhitelistTokenVault(address tokenVault, bool whitelisted);

  /* ========== ERRORS ========== */
  error UniswapV3TokenVaultMigrator_OnlyWhitelistedTokenVault();
  error UniswapV3TokenVaultMigrator_InvalidFeeRate();

  /* ========== CONSTRUCTOR ========== */
  constructor(
    address _treasury,
    address _controller,
    address _govLPTokenVault,
    uint256 _treasuryFeeRate,
    uint256 _controllerFeeRate,
    uint256 _govLPTokenVaultFeeRate,
    IV3SwapRouter _router,
    IQuoter _quoter
  ) {
    if (_govLPTokenVaultFeeRate + _treasuryFeeRate + _controllerFeeRate >= 1e18) {
      revert UniswapV3TokenVaultMigrator_InvalidFeeRate();
    }

    treasury = _treasury;
    controller = _controller;
    govLPTokenVault = _govLPTokenVault;
    treasuryFeeRate = _treasuryFeeRate;
    controllerFeeRate = _controllerFeeRate;
    govLPTokenVaultFeeRate = _govLPTokenVaultFeeRate;
    router = _router;

    quoter = _quoter;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyWhitelistedTokenVault(address caller) {
    if (!tokenVaultOK[caller]) {
      revert UniswapV3TokenVaultMigrator_OnlyWhitelistedTokenVault();
    }
    _;
  }

  /* ========== ADMIN FUNCTIONS ========== */
  function whitelistTokenVault(address _tokenVault, bool _isOk) external onlyOwner {
    tokenVaultOK[_tokenVault] = _isOk;

    emit WhitelistTokenVault(_tokenVault, _isOk);
  }

  /* ========== EXTERNAL FUNCTIONS ========== */
  function _unwrapWETH(address _recipient) private {
    uint256 balanceWETH9 = IWETH9(WETH9).balanceOf(address(this));

    if (balanceWETH9 > 0) {
      IWETH9(WETH9).withdraw(balanceWETH9);
      _recipient.safeTransferETH(balanceWETH9);
    }
  }

  function execute(bytes calldata _data) external onlyWhitelistedTokenVault(msg.sender) nonReentrant {
    (address token, uint24 poolFee) = abi.decode(_data, (address, uint24));

    uint256 swapAmount = IERC20(token).balanceOf(address(this));

    IERC20(token).safeApprove(address(router), swapAmount);

    IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter.ExactInputSingleParams({
      tokenIn: token,
      tokenOut: WETH9,
      fee: poolFee,
      recipient: address(this),
      amountIn: swapAmount,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0
    });

    router.exactInputSingle(params);
    _unwrapWETH(address(this));

    uint256 govLPTokenVaultFee = govLPTokenVaultFeeRate.mulWadDown(address(this).balance);
    uint256 treasuryFee = treasuryFeeRate.mulWadDown(address(this).balance);
    uint256 controllerFee = controllerFeeRate.mulWadDown(address(this).balance);
    uint256 vaultReward = address(this).balance - govLPTokenVaultFee - treasuryFee - controllerFee;
    treasury.safeTransferETH(treasuryFee);
    govLPTokenVault.safeTransferETH(govLPTokenVaultFee);
    controller.safeTransferETH(controllerFee);
    msg.sender.safeTransferETH(vaultReward);

    emit Execute(vaultReward, treasuryFee, controllerFee, govLPTokenVaultFee);
  }

  function getAmountOut(bytes calldata _data) public returns (uint256) {
    (address token, uint24 poolFee, uint256 _amount) = abi.decode(_data, (address, uint24, uint256));

    uint256 amountOut = quoter.quoteExactInputSingle(token, WETH9, poolFee, _amount, 0);

    return amountOut;
  }

  function getApproximatedExecutionRewards(bytes calldata _data) external returns (uint256) {
    uint256 totalEth = getAmountOut(_data);
    return controllerFeeRate.mulWadDown(totalEth);
  }

  /// @dev Fallback function to accept ETH.
  receive() external payable {}
}