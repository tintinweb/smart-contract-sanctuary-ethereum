// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./IERC20.sol";
import "./IV3SwapRouter.sol";

import "./SafeTransferLib.sol";
import "./FixedPointMathLib.sol";
import "./IMigrator.sol";
import "./ICurveFiStableSwap.sol";
import "./IUniswapV2Router02.sol";
import "./IQuoter.sol";
import "./ILp.sol";
import "./IWETH9.sol";

contract CurveLPVaultMigrator is IMigrator, ReentrancyGuard, Ownable {
  using SafeTransferLib for address;
  using FixedPointMathLib for uint256;
  using SafeERC20 for IERC20;

  /* ========== CONSTANT ========== */

  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  /* ========== STATE VARIABLES ========== */
  uint256 public govLPTokenVaultFeeRate;
  uint256 public treasuryFeeRate;
  uint256 public controllerFeeRate;

  address public treasury;
  address public govLPTokenVault;
  address public controller;

  IV3SwapRouter public uniswapRouter;
  IQuoter public quoter;

  mapping(address => bool) public tokenVaultOK;
  mapping(address => ICurveFiStableSwap) public tokenVaultPoolRouter;
  mapping(address => uint24) public poolUnderlyingCount;

  struct StableSwapEthMetadata {
    int128 ethIndex;
    bool isUintParam;
  }

  mapping(address => bool) public stableSwapContainEth;
  mapping(address => StableSwapEthMetadata) public stableSwapEthMetadata;

  /* ========== EVENTS ========== */
  event Execute(
    uint256 vaultReward,
    uint256 treasuryReward,
    uint256 controllerReward,
    uint256 govLPTokenVaultReward
  );

  event WhitelistTokenVault(address tokenVault, bool whitelisted);
  event MapTokenVaultRouter(
    address tokenVault,
    address curveFinancePoolRouter,
    uint24 underlyingCount
  );
  event WhitelistRouterToRemoveLiquidityAsEth(
    address router,
    bool isSwapToEth,
    int128 ethIndex,
    bool isUintParam
  );

  /* ========== ERRORS ========== */
  error CurveLPVaultMigrator_OnlyWhitelistedTokenVault();
  error CurveLPVaultMigrator_InvalidFeeRate();

  /* ========== CONSTRUCTOR ========== */
  constructor(
    address _treasury,
    address _controller,
    address _govLPTokenVault,
    uint256 _treasuryFeeRate,
    uint256 _controllerFeeRate,
    uint256 _govLPTokenVaultFeeRate,
    IV3SwapRouter _uniswapRouter,
    IQuoter _quoter
  ) {
    if (govLPTokenVaultFeeRate + treasuryFeeRate >= 1e18) {
      revert CurveLPVaultMigrator_InvalidFeeRate();
    }

    treasury = _treasury;
    controller = _controller;
    govLPTokenVault = _govLPTokenVault;

    govLPTokenVaultFeeRate = _govLPTokenVaultFeeRate;
    controllerFeeRate = _controllerFeeRate;
    treasuryFeeRate = _treasuryFeeRate;

    uniswapRouter = _uniswapRouter;
    quoter = _quoter;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyWhitelistedTokenVault(address caller) {
    if (!tokenVaultOK[caller]) {
      revert CurveLPVaultMigrator_OnlyWhitelistedTokenVault();
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

  function mapTokenVaultRouter(
    address _tokenVault,
    address _curveFinancePoolRouter,
    uint24 _underlyingCount
  ) external onlyOwner {
    ICurveFiStableSwap router = ICurveFiStableSwap(_curveFinancePoolRouter);

    tokenVaultPoolRouter[_tokenVault] = router;
    poolUnderlyingCount[address(router)] = _underlyingCount;

    emit MapTokenVaultRouter(
      _tokenVault,
      _curveFinancePoolRouter,
      _underlyingCount
    );
  }

  function whitelistRouterToRemoveLiquidityAsEth(
    address _router,
    bool _isSwapToEth,
    int128 _ethIndex,
    bool _isUintParam
  ) external onlyOwner {
    stableSwapContainEth[_router] = _isSwapToEth;
    stableSwapEthMetadata[_router] = StableSwapEthMetadata({
      ethIndex: _ethIndex,
      isUintParam: _isUintParam
    });

    emit WhitelistRouterToRemoveLiquidityAsEth(
      _router,
      _isSwapToEth,
      _ethIndex,
      _isUintParam
    );
  }

  /* ========== EXTERNAL FUNCTIONS ========== */
  function execute(bytes calldata _data)
    external
    onlyWhitelistedTokenVault(msg.sender)
    nonReentrant
  {
    (address lpToken, uint24 poolFee) = abi.decode(_data, (address, uint24));
    ICurveFiStableSwap curveStableSwap = tokenVaultPoolRouter[msg.sender];

    uint256 liquidity = IERC20(lpToken).balanceOf(address(this));
    IERC20(lpToken).safeApprove(address(curveStableSwap), liquidity);

    uint24 underlyingCount = poolUnderlyingCount[address(curveStableSwap)];

    if (stableSwapContainEth[address(curveStableSwap)]) {
      StableSwapEthMetadata memory metadata = stableSwapEthMetadata[
        address(curveStableSwap)
      ];

      if (metadata.isUintParam) {
        curveStableSwap.remove_liquidity_one_coin(
          liquidity,
          uint256(int256(metadata.ethIndex)),
          uint256(0)
        );
      } else {
        curveStableSwap.remove_liquidity_one_coin(
          liquidity,
          metadata.ethIndex,
          uint256(0)
        );
      }
    } else {
      if (underlyingCount == 3) {
        curveStableSwap.remove_liquidity(
          liquidity,
          [uint256(0), uint256(0), uint256(0)]
        );
      } else {
        curveStableSwap.remove_liquidity(liquidity, [uint256(0), uint256(0)]);
      }

      uint256 i;
      for (i = 0; i < underlyingCount; i++) {
        address coinAddress = curveStableSwap.coins((i));

        // ETH is already counted in this address balance
        // swapping WETH is unnecessary
        if (coinAddress != ETH && coinAddress != WETH9) {
          uint256 swapAmount = IERC20(coinAddress).balanceOf(address(this));
          IERC20(coinAddress).safeApprove(address(uniswapRouter), swapAmount);

          IV3SwapRouter.ExactInputSingleParams memory params = IV3SwapRouter
            .ExactInputSingleParams({
              tokenIn: coinAddress,
              tokenOut: WETH9,
              fee: poolFee,
              recipient: address(this),
              amountIn: swapAmount,
              amountOutMinimum: 0,
              sqrtPriceLimitX96: 0
            });

          uniswapRouter.exactInputSingle(params);
        }
      }
    }

    _unwrapWETH(address(this));

    uint256 treasuryFee = treasuryFeeRate.mulWadDown(address(this).balance);
    uint256 controllerFee = controllerFeeRate.mulWadDown(address(this).balance);
    uint256 govLPTokenVaultFee = govLPTokenVaultFeeRate.mulWadDown(
      address(this).balance
    );
    uint256 vaultReward = address(this).balance -
      govLPTokenVaultFee -
      treasuryFee -
      controllerFee;

    treasury.safeTransferETH(treasuryFee);
    controller.safeTransferETH(controllerFee);
    govLPTokenVault.safeTransferETH(govLPTokenVaultFee);

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

    ICurveFiStableSwap curveStableSwap = tokenVaultPoolRouter[msg.sender];
    uint24 underlyingCount = poolUnderlyingCount[address(curveStableSwap)];

    if (stableSwapContainEth[address(curveStableSwap)]) {
      StableSwapEthMetadata memory metadata = stableSwapEthMetadata[
        address(curveStableSwap)
      ];

      uint256 approximatedEth;
      if (metadata.isUintParam) {
        approximatedEth = curveStableSwap.calc_withdraw_one_coin(
          stakeAmount,
          uint256(int256(metadata.ethIndex))
        );
      } else {
        approximatedEth = curveStableSwap.calc_withdraw_one_coin(
          stakeAmount,
          metadata.ethIndex
        );
      }

      return approximatedEth;
    }

    uint256 ratio = stakeAmount.divWadDown(IERC20(lpToken).totalSupply());
    uint256 amountOut = 0;
    uint256 i;
    for (i = 0; i < underlyingCount; i++) {
      address coinAddress = curveStableSwap.coins((i));

      uint256 reserve = curveStableSwap.balances(i);
      uint256 liquidity = uint256(reserve).mulWadDown(ratio);

      if (coinAddress == ETH || coinAddress == WETH9) {
        amountOut += liquidity;
      } else {
        amountOut += quoter.quoteExactInputSingle(
          coinAddress,
          WETH9,
          poolFee,
          liquidity,
          0
        );
      }
    }

    return amountOut;
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