// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "../interfaces/curve/ICurveDeposit.sol";
import "../interfaces/curve/ICurveGauge.sol";
import "../interfaces/curve/ICurveMinter.sol";
import "../interfaces/sushiswap/IUniswapV2Router.sol";
import "./CurveBase.sol";

/// @notice Implements the strategy using the usdn/3Crv(DAI/USDC/USDT) pool.
///  There is a zap depositor available, however, we came across an error when we tried to use it, and can't figure out a fix, that's why it's not used.
///  So the strategy will deploy the input token (USDC) to the 3Crv pool first, and then deploy the 3Crv LP token to the meta pool.
///  Finally, the strategy will deposit the meta pool LP tokens into the gauge.
///  Input token: USDC
///  Base pool: 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7 (3Crv pool)
///  Meta pool: 0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1
///  Gauge: 0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4
contract CurveStable is CurveBase {
  using SafeERC20 for IERC20;
  using Address for address;

  // the address of the meta pool
  address internal constant USDN_METAPOOL = address(0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1);
  // the address of the gauge
  address internal constant CURVE_GAUGE = address(0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4);
  // the address of the 3Crv pool LP token
  IERC20 internal constant THREE_CRV = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
  // the address of the usdn/3Crv meta pool LP token
  IERC20 internal constant USDN_3CRV = IERC20(0x4f3E8F405CF5aFC05D68142F3783bDfE13811522);

  ICurveDeposit internal usdnMetaPool;
  IERC20 internal triPoolLpToken;
  // the index of the want token in the 3Crv pool
  int128 internal immutable wantThreepoolIndex;
  uint256 internal constant N_POOL_COINS = 3;

  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool
  ) CurveBase(_vault, _proposer, _developer, _keeper, _pool) {
    // threePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    // usdnMetaPool = 0x0f9cb53Ebe405d49A0bbdBD291A65Ff571bC83e1;
    // curveGauge = address(0xF98450B5602fa59CC66e1379DFfB6FDDc724CfC4);
    // curveMinter = address(0xd061D61a4d941c39E5453435B6345Dc261C2fcE0);

    usdnMetaPool = ICurveDeposit(_getMetaPool());
    triPoolLpToken = _getTriPoolLpToken();
    wantThreepoolIndex = _getWantIndexInCurvePool(_pool);
    _approveCurveExtra();
  }

  function name() external view virtual override returns (string memory) {
    return string(abi.encodePacked("CurveStable_", IERC20Metadata(address(want)).symbol()));
  }

  function _getMetaPool() internal view virtual returns (address) {
    return USDN_METAPOOL;
  }

  function _getTriPoolLpToken() internal view virtual returns (IERC20) {
    return THREE_CRV;
  }

  function _getMetaPoolLpToken() internal view virtual returns (IERC20) {
    return USDN_3CRV;
  }

  function _getWantTokenIndex() internal view override returns (uint256) {
    return uint128(wantThreepoolIndex);
  }

  function _getCoinsCount() internal pure override returns (uint256) {
    return N_POOL_COINS;
  }

  function _getWantIndexInCurvePool(address _pool) internal view returns (int128) {
    address _candidate;
    for (uint256 i = 0; i < N_POOL_COINS; i++) {
      _candidate = ICurveDeposit(_pool).coins(uint256(i));
      if (address(want) == _candidate) {
        return int128(uint128(i));
      }
    }
    revert("Want token doesnt match any tokens in the curve pool");
  }

  function _balanceOfPool() internal view virtual override returns (uint256) {
    uint256 lpTokenAmount = curveGauge.balanceOf(address(this));
    // we will get the eth amount, which is the same as weth
    if (lpTokenAmount > 0) {
      uint256 outputAmount = _quoteWantInMetapoolLp(lpTokenAmount);
      return outputAmount;
    }
    return 0;
  }

  /// @dev The input is the LP token of the meta pool. To get the value of the original liquidity in the base pool,
  ///  we need to use `calc_withdraw_one_coin` from meta pool and base pool to see how much `want` we will get if we withdraw, without actually doing the withdraw.
  function _quoteWantInMetapoolLp(uint256 _metaPoolLpTokens) public view returns (uint256) {
    uint256 _3crvInUsdn3crv = usdnMetaPool.calc_withdraw_one_coin(_metaPoolLpTokens, 1);
    uint256 _wantIn3crv = curvePool.calc_withdraw_one_coin(_3crvInUsdn3crv, wantThreepoolIndex);
    return _wantIn3crv;
  }

  function _approveCurveExtra() internal virtual {
    want.safeApprove(address(curvePool), type(uint256).max);
    _getTriPoolLpToken().safeApprove(address(usdnMetaPool), type(uint256).max);
  }

  function _addLiquidityToCurvePool() internal virtual override {
    uint256 _wantBalance = _balanceOfWant();
    if (_wantBalance > 0) {
      uint256[3] memory _tokens = _buildDepositArray(_wantBalance);
      curvePool.add_liquidity(_tokens, 0);
    }

    // stake 3crv and recevice usdnMetaPool LP tokens - _getMetaPoolLpToken()
    uint256 _3crv = _getTriPoolLpToken().balanceOf(address(this));
    if (_3crv > 0) {
      // uint256 _usdn3crvLPs2 = usdnMetaPool.add_liquidity([uint256(0), _3crv], uint256(0));
      usdnMetaPool.add_liquidity([uint256(0), _3crv], uint256(0));
    }
  }

  function _depositLPTokens() internal virtual override {
    uint256 _usdn3crvLPs = _getMetaPoolLpToken().balanceOf(address(this));
    if (_usdn3crvLPs > 0) {
      // add usdn3crvLp tokens to curvegauge, this allow to call mint to receive CRV tokens
      curveGauge.deposit(_usdn3crvLPs);
      curveGauge.balanceOf(address(this));
    }
  }

  function _buildDepositArray(uint256 _amount) public view returns (uint256[3] memory) {
    uint256[3] memory _tokenBins;
    _tokenBins[uint128(wantThreepoolIndex)] = _amount;
    return _tokenBins;
  }

  /// @dev The `_amount` is in want token, so we need to convert that to LP tokens first.
  ///  We use the `calc_token_amount` to calculate how many LP tokens we will get with the `_amount` of want tokens without actually doing the deposit.
  ///  Then we add a bit more (2%) for padding.
  function _withdrawSome(uint256 _amount) internal override returns (uint256) {
    uint256 requiredTriPoollLpTokens = curvePool.calc_token_amount(_buildDepositArray(_amount), true);
    uint256 requiredMetaPoollLpTokens = (usdnMetaPool.calc_token_amount([0, requiredTriPoollLpTokens], true) * 10200) /
      10000; // adding 2% for fees
    uint256 liquidated = _removeLiquidity(requiredMetaPoollLpTokens);
    return liquidated;
  }

  function _getCurvePoolGaugeAddress() internal view virtual override returns (address) {
    return CURVE_GAUGE;
  }

  /// @dev Remove the liquidity by the LP token amount
  /// @param _amount The amount of LP token (not want token)
  function _removeLiquidity(uint256 _amount) internal override returns (uint256) {
    uint256 _before = _balanceOfWant();
    uint256 lpBalance = _getLpTokenBalance();
    // need to make sure we don't withdraw more than what we have
    uint256 withdrawAmount = Math.min(lpBalance, _amount);
    // withdraw this amount of lp tokens first
    _removeLpToken(withdrawAmount);
    // then remove the liqudity from the pool, will get want back
    uint256 usdn3crv = _getMetaPoolLpToken().balanceOf(address(this));
    usdnMetaPool.remove_liquidity_one_coin(usdn3crv, 1, uint256(0));
    uint256 _3crv = _getTriPoolLpToken().balanceOf(address(this));
    ICurveDepositTrio(address(curvePool)).remove_liquidity_one_coin(_3crv, wantThreepoolIndex, 0);
    return _balanceOfWant() - _before;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ICurveDeposit {
  // 3 coin
  function add_liquidity(uint256[1] memory amounts, uint256 min_mint_amount) external;

  function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable returns (uint256);

  function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

  function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

  function add_liquidity(
    uint256[3] memory amounts,
    uint256 min_mint_amount,
    bool _use_underlying
  ) external;

  function coins(uint256 arg0) external view returns (address);

  function calc_withdraw_one_coin(uint256 _token_amount, int128 i) external view returns (uint256);

  function calc_token_amount(uint256[4] memory amounts, bool is_deposit) external view returns (uint256);

  function calc_token_amount(uint256[3] memory amounts, bool is_deposit) external view returns (uint256);

  function calc_token_amount(uint256[2] memory amounts, bool is_deposit) external view returns (uint256);

  /// @notice Withdraw and unwrap a single coin from the pool
  /// @param _token_amount Amount of LP tokens to burn in the withdrawal
  /// @param i Index value of the coin to withdraw, 0-Dai, 1-USDC, 2-USDT
  /// @param _min_amount Minimum amount of underlying coin to receive
  //
  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount
  ) external returns (uint256);
}

interface ICurveDepositTrio {
  function remove_liquidity_one_coin(
    uint256 _token_amount,
    int128 i,
    uint256 _min_amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ICurveGauge {
  function deposit(uint256 _value) external;

  function integrate_fraction(address arg0) external view returns (uint256);

  function balanceOf(address arg0) external view returns (uint256);

  function claimable_tokens(address arg0) external returns (uint256);

  function withdraw(uint256 _value) external;

  /// @dev The address of the LP token that may be deposited into the gauge.
  function lp_token() external view returns (address);

  function user_checkpoint(address _user) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

// so
interface ICurveMinter {
  function mint(address gauge_addr) external;

  function minted(address arg0, address arg1) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface IUniswapV2Router {
  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] calldata path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

// interface GeneratedInterface {
//   function WETH() external view returns (address);

//   function addLiquidity(
//     address tokenA,
//     address tokenB,
//     uint256 amountADesired,
//     uint256 amountBDesired,
//     uint256 amountAMin,
//     uint256 amountBMin,
//     address to,
//     uint256 deadline
//   )
//     external
//     returns (
//       uint256 amountA,
//       uint256 amountB,
//       uint256 liquidity
//     );

//   function addLiquidityETH(
//     address token,
//     uint256 amountTokenDesired,
//     uint256 amountTokenMin,
//     uint256 amountETHMin,
//     address to,
//     uint256 deadline
//   )
//     external
//     returns (
//       uint256 amountToken,
//       uint256 amountETH,
//       uint256 liquidity
//     );

//   function factory() external view returns (address);

//   function getAmountIn(
//     uint256 amountOut,
//     uint256 reserveIn,
//     uint256 reserveOut
//   ) external pure returns (uint256 amountIn);

//   function getAmountOut(
//     uint256 amountIn,
//     uint256 reserveIn,
//     uint256 reserveOut
//   ) external pure returns (uint256 amountOut);

//   function getAmountsIn(uint256 amountOut, address[] path) external view returns (uint256[] amounts);

//   function getAmountsOut(uint256 amountIn, address[] path) external view returns (uint256[] amounts);

//   function quote(
//     uint256 amountA,
//     uint256 reserveA,
//     uint256 reserveB
//   ) external pure returns (uint256 amountB);

//   function removeLiquidity(
//     address tokenA,
//     address tokenB,
//     uint256 liquidity,
//     uint256 amountAMin,
//     uint256 amountBMin,
//     address to,
//     uint256 deadline
//   ) external returns (uint256 amountA, uint256 amountB);

//   function removeLiquidityETH(
//     address token,
//     uint256 liquidity,
//     uint256 amountTokenMin,
//     uint256 amountETHMin,
//     address to,
//     uint256 deadline
//   ) external returns (uint256 amountToken, uint256 amountETH);

//   function removeLiquidityETHSupportingFeeOnTransferTokens(
//     address token,
//     uint256 liquidity,
//     uint256 amountTokenMin,
//     uint256 amountETHMin,
//     address to,
//     uint256 deadline
//   ) external returns (uint256 amountETH);

//   function removeLiquidityETHWithPermit(
//     address token,
//     uint256 liquidity,
//     uint256 amountTokenMin,
//     uint256 amountETHMin,
//     address to,
//     uint256 deadline,
//     bool approveMax,
//     uint8 v,
//     bytes32 r,
//     bytes32 s
//   ) external returns (uint256 amountToken, uint256 amountETH);

//   function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
//     address token,
//     uint256 liquidity,
//     uint256 amountTokenMin,
//     uint256 amountETHMin,
//     address to,
//     uint256 deadline,
//     bool approveMax,
//     uint8 v,
//     bytes32 r,
//     bytes32 s
//   ) external returns (uint256 amountETH);

//   function removeLiquidityWithPermit(
//     address tokenA,
//     address tokenB,
//     uint256 liquidity,
//     uint256 amountAMin,
//     uint256 amountBMin,
//     address to,
//     uint256 deadline,
//     bool approveMax,
//     uint8 v,
//     bytes32 r,
//     bytes32 s
//   ) external returns (uint256 amountA, uint256 amountB);

//   function swapETHForExactTokens(
//     uint256 amountOut,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external returns (uint256[] amounts);

//   function swapExactETHForTokens(
//     uint256 amountOutMin,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external returns (uint256[] amounts);

//   function swapExactETHForTokensSupportingFeeOnTransferTokens(
//     uint256 amountOutMin,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external;

//   function swapExactTokensForETH(
//     uint256 amountIn,
//     uint256 amountOutMin,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external returns (uint256[] amounts);

//   function swapExactTokensForETHSupportingFeeOnTransferTokens(
//     uint256 amountIn,
//     uint256 amountOutMin,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external;

//   function swapExactTokensForTokens(
//     uint256 amountIn,
//     uint256 amountOutMin,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external returns (uint256[] amounts);

//   function swapExactTokensForTokensSupportingFeeOnTransferTokens(
//     uint256 amountIn,
//     uint256 amountOutMin,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external;

//   function swapTokensForExactETH(
//     uint256 amountOut,
//     uint256 amountInMax,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external returns (uint256[] amounts);

//   function swapTokensForExactTokens(
//     uint256 amountOut,
//     uint256 amountInMax,
//     address[] path,
//     address to,
//     uint256 deadline
//   ) external returns (uint256[] amounts);
// }

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./BaseStrategy.sol";
import "../interfaces/curve/ICurveGauge.sol";
import "../interfaces/curve/ICurveMinter.sol";
import "../interfaces/curve/ICurveRegistry.sol";
import "../interfaces/curve/ICurveDeposit.sol";
import "../interfaces/curve/ICurveAddressProvider.sol";
import "../interfaces/sushiswap/IUniswapV2Router.sol";

/// @dev The base implementation for all Curve strategies. All strategies will add liquidity to a Curve pool (could be a plain or meta pool), and then deposit the LP tokens to the corresponding gauge to earn Curve tokens.
///  When it comes to harvest time, the Curve tokens will be minted and sold, and the profit will be reported and moved back to the vault.
///  The next time when harvest is called again, the profits from previous harvests will be invested again (if they haven't been withdrawn from the vault).
///  The Convex strategies are pretty much the same as the Curve ones, the only different is that the LP tokens are deposited into Convex instead, and it will take rewards from both Curve and Convex.
abstract contract CurveBase is BaseStrategy {
  using SafeERC20 for IERC20;
  using Address for address;

  // The address of the curve address provider. This address will never change is is the recommended way to get the address of their registry.
  // See https://curve.readthedocs.io/registry-address-provider.html#
  address private constant CURVE_ADDRESS_PROVIDER_ADDRESS = 0x0000000022D53366457F9d5E68Ec105046FC4383;
  // Minter contract address will never change either. See https://curve.readthedocs.io/dao-gauges.html#minter
  address private constant CURVE_MINTER_ADDRESS = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
  address private constant CRV_TOKEN_ADDRESS = 0xD533a949740bb3306d119CC777fa900bA034cd52;
  address private constant SUSHISWAP_ADDRESS = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
  address private constant UNISWAP_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  // Curve token minter
  ICurveMinter public curveMinter;
  // Curve address provider, where we can query for the address of the registry
  ICurveAddressProvider public curveAddressProvider;
  // Curve pool. Can be either a plain pool, or meta pool, or Curve zap depositor (automatically add liquidity to base pool and then meta pool).
  ICurveDeposit public curvePool;
  // The Curve gauge corresponding to the Curve pool
  ICurveGauge public curveGauge;
  // Dex address for token swaps.
  address public dex;
  // Store dex approval status to avoid excessive approvals
  mapping(address => bool) internal dexApprovals;

  /// @param _vault The address of the vault. The underlying token should match the `want` token of the strategy.
  /// @param _proposer The address of the strategy proposer
  /// @param _developer The address of the strategy developer
  /// @param _keeper The address of the keeper of the strategy.
  /// @param _pool The address of the Curve pool
  constructor(
    address _vault,
    address _proposer,
    address _developer,
    address _keeper,
    address _pool
  ) BaseStrategy(_vault, _proposer, _developer, _keeper) {
    require(_pool != address(0), "invalid pool address");
    minReportDelay = 43_200; // 12hr
    maxReportDelay = 259_200; // 72hr
    profitFactor = 1000;
    debtThreshold = 1e24;
    dex = SUSHISWAP_ADDRESS;
    _initCurvePool(_pool);
    _approveOnInit();
  }

  /// @notice Approves pools/dexes to be spenders of the tokens of this strategy
  function approveAll() external onlyAuthorized {
    _approveBasic();
    _approveDex();
  }

  /// @notice Changes the dex to use when swap tokens
  /// @param _isUniswap If true, uses Uniswap, otherwise uses Sushiswap
  function switchDex(bool _isUniswap) external onlyAuthorized {
    if (_isUniswap) {
      dex = UNISWAP_ADDRESS;
    } else {
      dex = SUSHISWAP_ADDRESS;
    }
    _approveDex();
  }

  /// @notice Returns the total value of assets in want tokens
  /// @dev it should include the current balance of want tokens, the assets that are deployed and value of rewards so far
  function estimatedTotalAssets() public view virtual override returns (uint256) {
    return _balanceOfWant() + _balanceOfPool() + _balanceOfRewards();
  }

  /// @dev Before migration, we will claim all rewards and remove all liquidity.
  function prepareMigration(address) internal override {
    // mint all the CRV tokens
    _claimRewards();
    _removeLiquidity(_getLpTokenBalance());
  }

  // solhint-disable-next-line no-unused-vars
  /// @dev This will perform the actual invest steps.
  ///   For both Curve & Convex, it will add liquidity to Curve pool(s) first, and then deposit the LP tokens to either Curve gauges or Convex booster.
  function adjustPosition(uint256) internal virtual override {
    if (emergencyExit) {
      return;
    }
    _addLiquidityToCurvePool();
    _depositLPTokens();
  }

  /// @dev This will claim the rewards from either Curve or Convex, swap them to want tokens and calculate the profit/loss.
  function prepareReturn(uint256 _debtOutstanding)
    internal
    virtual
    override
    returns (
      uint256 _profit,
      uint256 _loss,
      uint256 _debtPayment
    )
  {
    uint256 wantBefore = _balanceOfWant();
    _claimRewards();
    uint256 wantNow = _balanceOfWant();
    _profit = wantNow - wantBefore;

    uint256 _total = estimatedTotalAssets();
    uint256 _debt = IVault(vault).strategy(address(this)).totalDebt;

    if (_total < _debt) {
      _loss = _debt - _total;
      _profit = 0;
    }

    if (_debtOutstanding > 0) {
      _withdrawSome(_debtOutstanding);
      _debtPayment = Math.min(_debtOutstanding, _balanceOfWant() - _profit);
    }
  }

  /// @dev Liquidates the positions from either Curve or Convex.
  function liquidatePosition(uint256 _amountNeeded)
    internal
    virtual
    override
    returns (uint256 _liquidatedAmount, uint256 _loss)
  {
    // cash out all the rewards first
    _claimRewards();
    uint256 _balance = _balanceOfWant();
    if (_balance < _amountNeeded) {
      _liquidatedAmount = _withdrawSome(_amountNeeded - _balance);
      _liquidatedAmount = _liquidatedAmount + _balance;
      _loss = _amountNeeded - _liquidatedAmount; // this should be 0. o/w there must be an error
    } else {
      _liquidatedAmount = _amountNeeded;
    }
  }

  function protectedTokens() internal view virtual override returns (address[] memory) {
    address[] memory protected = new address[](2);
    protected[0] = _getCurveTokenAddress();
    protected[1] = curveGauge.lp_token();
    return protected;
  }

  /// @dev Can be used to perform some actions by the strategy, before the rewards are claimed (like call the checkpoint to update user rewards).
  function onHarvest() internal virtual override {
    // make sure the claimable rewards record is up to date
    curveGauge.user_checkpoint(address(this));
  }

  /// @dev Initialises the state variables. Put them in a function to allow for testing. Testing contracts can override these.
  function _initCurvePool(address _pool) internal virtual {
    curveAddressProvider = ICurveAddressProvider(CURVE_ADDRESS_PROVIDER_ADDRESS);
    curveMinter = ICurveMinter(CURVE_MINTER_ADDRESS);
    curvePool = ICurveDeposit(_pool);
    curveGauge = ICurveGauge(_getCurvePoolGaugeAddress());
  }

  function _approveOnInit() internal virtual {
    _approveBasic();
    _approveDex();
  }

  /// @dev Returns the balance of the `want` token.
  function _balanceOfWant() internal view returns (uint256) {
    return want.balanceOf(address(this));
  }

  /// @dev Returns total liquidity provided to Curve pools.
  ///  Can be overridden if the strategy has a different way to get the value of the pool.
  function _balanceOfPool() internal view virtual returns (uint256) {
    uint256 lpTokenAmount = _getLpTokenBalance();
    if (lpTokenAmount > 0) {
      uint256 outputAmount = curvePool.calc_withdraw_one_coin(lpTokenAmount, _int128(_getWantTokenIndex()));
      return outputAmount;
    }
    return 0;
  }

  /// @dev Returns the estimated value of the unclaimed rewards.
  function _balanceOfRewards() internal view virtual returns (uint256) {
    uint256 totalClaimableCRV = curveGauge.integrate_fraction(address(this));
    uint256 mintedCRV = curveMinter.minted(address(this), address(curveGauge));
    uint256 remainingCRV = totalClaimableCRV - mintedCRV;

    if (remainingCRV > 0) {
      return _getQuoteForTokenToWant(_getCurveTokenAddress(), remainingCRV);
    }
    return 0;
  }

  /// @dev Swaps the `_from` token to the want token using either Uniswap or Sushiswap
  function _swapToWant(address _from, uint256 _fromAmount) internal virtual returns (uint256) {
    if (_fromAmount > 0) {
      address[] memory path;
      if (address(want) == _getWETHTokenAddress()) {
        path = new address[](2);
        path[0] = _from;
        path[1] = address(want);
      } else {
        path = new address[](3);
        path[0] = _from;
        path[1] = address(_getWETHTokenAddress());
        path[2] = address(want);
      }
      /* solhint-disable  not-rely-on-time */
      uint256[] memory amountOut = IUniswapV2Router(dex).swapExactTokensForTokens(
        _fromAmount,
        uint256(0),
        path,
        address(this),
        block.timestamp
      );
      /* solhint-enable */
      return amountOut[path.length - 1];
    }
    return 0;
  }

  /// @dev Deposits the LP tokens to Curve gauge.
  function _depositLPTokens() internal virtual {
    address poolLPToken = curveGauge.lp_token();
    uint256 balance = IERC20(poolLPToken).balanceOf(address(this));
    if (balance > 0) {
      curveGauge.deposit(balance);
    }
  }

  /// @dev Withdraws the given amount of want tokens from the Curve pools.
  /// @param _amount The amount of *want* tokens (not LP token).
  function _withdrawSome(uint256 _amount) internal virtual returns (uint256) {
    uint256 requiredLPTokenAmount;
    // check how many LP tokens we will need for the given want _amount
    // not great, but can't find a better way to define the params dynamically based on the coins count
    if (_getCoinsCount() == 2) {
      uint256[2] memory params;
      params[_getWantTokenIndex()] = _amount;
      requiredLPTokenAmount = (curvePool.calc_token_amount(params, true) * 10200) / 10000; // adding 2% padding
    } else if (_getCoinsCount() == 3) {
      uint256[3] memory params;
      params[_getWantTokenIndex()] = _amount;
      requiredLPTokenAmount = (curvePool.calc_token_amount(params, true) * 10200) / 10000; // adding 2% padding
    } else if (_getCoinsCount() == 4) {
      uint256[4] memory params;
      params[_getWantTokenIndex()] = _amount;
      requiredLPTokenAmount = (curvePool.calc_token_amount(params, true) * 10200) / 10000; // adding 2% padding
    } else {
      revert("Invalid number of LP tokens");
    }
    // decide how many LP tokens we can actually withdraw
    return _removeLiquidity(requiredLPTokenAmount);
  }

  /// @dev Removes the liquidity by the LP token amount
  /// @param _amount The amount of LP token (not want token)
  function _removeLiquidity(uint256 _amount) internal virtual returns (uint256) {
    uint256 balance = _getLpTokenBalance();
    uint256 withdrawAmount = Math.min(_amount, balance);
    // withdraw this amount of token from the gauge first
    _removeLpToken(withdrawAmount);
    // then remove the liqudity from the pool, will get eth back
    uint256 amount = curvePool.remove_liquidity_one_coin(withdrawAmount, _int128(_getWantTokenIndex()), 0);
    return amount;
  }

  /// @dev Returns the total amount of Curve LP tokens the strategy has
  function _getLpTokenBalance() internal view virtual returns (uint256) {
    return curveGauge.balanceOf(address(this));
  }

  /// @dev Withdraws the given amount of LP tokens from Curve gauge
  /// @param _amount The amount of LP tokens to withdraw
  function _removeLpToken(uint256 _amount) internal virtual {
    curveGauge.withdraw(_amount);
  }

  /// @dev Claims the curve rewards tokens and swap them to want tokens
  function _claimRewards() internal virtual {
    curveMinter.mint(address(curveGauge));
    uint256 crvBalance = IERC20(_getCurveTokenAddress()).balanceOf(address(this));
    _swapToWant(_getCurveTokenAddress(), crvBalance);
  }

  /// @dev Returns the address of the pool LP token. Use a function to allow override in sub contracts to allow for unit testing.
  function _getPoolLPTokenAddress(address _pool) internal virtual returns (address) {
    require(_pool != address(0), "invalid pool address");
    address registry = curveAddressProvider.get_registry();
    return ICurveRegistry(registry).get_lp_token(address(_pool));
  }

  /// @dev Returns the address of the curve gauge. It will use the Curve registry to look up the gauge for a Curve pool.
  ///  Use a function to allow override in sub contracts to allow for unit testing.
  function _getCurvePoolGaugeAddress() internal view virtual returns (address) {
    address registry = curveAddressProvider.get_registry();
    (address[10] memory gauges, ) = ICurveRegistry(registry).get_gauges(address(curvePool));
    // This only usese the first gauge of the pool. Should be enough for most cases, however, if this is not the case, then this method should be overriden

    return gauges[0];
  }

  /// @dev Returns the address of the Curve token. Use a function to allow override in sub contracts to allow for unit testing.
  function _getCurveTokenAddress() internal view virtual returns (address) {
    return CRV_TOKEN_ADDRESS;
  }

  /// @dev Returns the address of the WETH token. Use a function to allow override in sub contracts to allow for unit testing.
  function _getWETHTokenAddress() internal view virtual returns (address) {
    return WETH_ADDRESS;
  }

  /// @dev Gets an estimate value in want token for the given amount of given token using the dex.
  function _getQuoteForTokenToWant(address _from, uint256 _fromAmount) internal view virtual returns (uint256) {
    if (_fromAmount > 0) {
      address[] memory path;
      if (address(want) == _getWETHTokenAddress()) {
        path = new address[](2);
        path[0] = _from;
        path[1] = address(want);
      } else {
        path = new address[](3);
        path[0] = _from;
        path[1] = address(_getWETHTokenAddress());
        path[2] = address(want);
      }
      uint256[] memory amountOut = IUniswapV2Router(dex).getAmountsOut(_fromAmount, path);
      return amountOut[path.length - 1];
    }
    return 0;
  }

  /// @dev Approves Curve pools/gauges/rewards contracts to access the tokens in the strategy
  function _approveBasic() internal virtual {
    IERC20(curveGauge.lp_token()).safeApprove(address(curveGauge), type(uint256).max);
  }

  /// @dev Approves dex to access tokens in the strategy for swaps
  function _approveDex() internal virtual {
    if (!dexApprovals[dex]) {
      dexApprovals[dex] = true;
      IERC20(_getCurveTokenAddress()).safeApprove(dex, type(uint256).max);
    }
  }

  // does not deal with over/under flow
  function _int128(uint256 _val) internal pure returns (int128) {
    return int128(uint128(_val));
  }

  /// @dev This needs to be overridden by the concrete strategyto implement how liquidity will be added to Curve pools
  function _addLiquidityToCurvePool() internal virtual;

  /// @dev Returns the index of the want token for a Curve pool
  function _getWantTokenIndex() internal view virtual returns (uint256);

  /// @dev Returns the total number of coins the Curve pool supports
  function _getCoinsCount() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../interfaces/IVault.sol";
import "../interfaces/IStrategy.sol";

/**
 *
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy is IStrategy, ERC165 {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  string public metadataURI;

  /**
   * @notice
   *  Used to track which version of `StrategyAPI` this Strategy
   *  implements.
   * @dev The Strategy's version must match the Vault's `API_VERSION`.
   * @return A string which holds the current API version of this contract.
   */
  function apiVersion() public pure returns (string memory) {
    return "0.0.1";
  }

  /**
   * @notice This Strategy's name.
   * @dev
   *  You can use this field to manage the "version" of this Strategy, e.g.
   *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
   *  `apiVersion()` function above.
   * @return This Strategy's name.
   */
  function name() external view virtual returns (string memory);

  /**
   * @notice
   *  The amount (priced in want) of the total assets managed by this strategy should not count
   *  towards Yearn's TVL calculations.
   * @dev
   *  You can override this field to set it to a non-zero value if some of the assets of this
   *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
   *  Note that this value must be strictly less than or equal to the amount provided by
   *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
   *  Also note that this value is used to determine the total assets under management by this
   *  strategy, for the purposes of computing the management fee in `Vault`
   * @return
   *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
   *  Locked (TVL) calculation across it's ecosystem.
   */
  function delegatedAssets() external view virtual returns (uint256) {
    return 0;
  }

  address public vault;
  address public strategyProposer;
  address public strategyDeveloper;
  address public rewards;
  address public harvester;
  IERC20 public want;

  // So indexers can keep track of this

  event UpdatedStrategyProposer(address strategyProposer);

  event UpdatedStrategyDeveloper(address strategyDeveloper);

  event UpdatedHarvester(address newHarvester);

  event UpdatedVault(address vault);

  event UpdatedMinReportDelay(uint256 delay);

  event UpdatedMaxReportDelay(uint256 delay);

  event UpdatedProfitFactor(uint256 profitFactor);

  event UpdatedDebtThreshold(uint256 debtThreshold);

  event UpdatedMetadataURI(string metadataURI);

  // The minimum number of seconds between harvest calls. See
  // `setMinReportDelay()` for more details.
  uint256 public minReportDelay;

  // The maximum number of seconds between harvest calls. See
  // `setMaxReportDelay()` for more details.
  uint256 public maxReportDelay;

  // The minimum multiple that `callCost` must be above the credit/profit to
  // be "justifiable". See `setProfitFactor()` for more details.
  uint256 public profitFactor;

  // Use this to adjust the threshold at which running a debt causes a
  // harvest trigger. See `setDebtThreshold()` for more details.
  uint256 public debtThreshold;

  // See note on `setEmergencyExit()`.
  bool public emergencyExit;

  // modifiers
  modifier onlyAuthorized() {
    require(
      msg.sender == strategyProposer || msg.sender == strategyDeveloper || msg.sender == governance(),
      "!authorized"
    );
    _;
  }

  modifier onlyStrategist() {
    require(msg.sender == strategyProposer || msg.sender == strategyDeveloper, "!strategist");
    _;
  }

  modifier onlyGovernance() {
    require(msg.sender == governance(), "!authorized");
    _;
  }

  modifier onlyKeepers() {
    require(
      msg.sender == harvester ||
        msg.sender == strategyProposer ||
        msg.sender == strategyDeveloper ||
        msg.sender == governance(),
      "!authorized"
    );
    _;
  }

  constructor(
    address _vault,
    address _strategyProposer,
    address _strategyDeveloper,
    address _harvester
  ) {
    _initialize(_vault, _strategyProposer, _strategyDeveloper, _harvester);
  }

  /**
   * @notice
   *  Initializes the Strategy, this is called only once, when the
   *  contract is deployed.
   * @dev `_vault` should implement `VaultAPI`.
   * @param _vault The address of the Vault responsible for this Strategy.
   */
  function _initialize(
    address _vault,
    address _strategyProposer,
    address _strategyDeveloper,
    address _harvester
  ) internal {
    require(address(want) == address(0), "Strategy already initialized");

    vault = _vault;
    want = IERC20(IVault(vault).token());
    checkWantToken();
    want.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
    strategyProposer = _strategyProposer;
    strategyDeveloper = _strategyDeveloper;
    harvester = _harvester;

    // initialize variables
    minReportDelay = 0;
    maxReportDelay = 86400;
    profitFactor = 100;
    debtThreshold = 0;
  }

  /**
   * @notice
   *  Used to change `_strategyProposer`.
   *
   *  This may only be called by governance or the existing strategist.
   * @param _strategyProposer The new address to assign as `strategist`.
   */
  function setStrategyProposer(address _strategyProposer) external onlyAuthorized {
    require(_strategyProposer != address(0), "! address 0");
    strategyProposer = _strategyProposer;
    emit UpdatedStrategyProposer(_strategyProposer);
  }

  function setStrategyDeveloper(address _strategyDeveloper) external onlyAuthorized {
    require(_strategyDeveloper != address(0), "! address 0");
    strategyDeveloper = _strategyDeveloper;
    emit UpdatedStrategyDeveloper(_strategyDeveloper);
  }

  /**
   * @notice
   *  Used to change `harvester`.
   *
   *  `harvester` is the only address that may call `tend()` or `harvest()`,
   *  other than `governance()` or `strategist`. However, unlike
   *  `governance()` or `strategist`, `harvester` may *only* call `tend()`
   *  and `harvest()`, and no other authorized functions, following the
   *  principle of least privilege.
   *
   *  This may only be called by governance or the strategist.
   * @param _harvester The new address to assign as `keeper`.
   */
  function setHarvester(address _harvester) external onlyAuthorized {
    require(_harvester != address(0), "! address 0");
    harvester = _harvester;
    emit UpdatedHarvester(_harvester);
  }

  function setVault(address _vault) external onlyAuthorized {
    require(_vault != address(0), "! address 0");
    vault = _vault;
    emit UpdatedVault(_vault);
  }

  /**
   * @notice
   *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
   *  of blocks that should pass for `harvest()` to be called.
   *
   *  For external keepers (such as the Keep3r network), this is the minimum
   *  time between jobs to wait. (see `harvestTrigger()`
   *  for more details.)
   *
   *  This may only be called by governance or the strategist.
   * @param _delay The minimum number of seconds to wait between harvests.
   */
  function setMinReportDelay(uint256 _delay) external onlyAuthorized {
    minReportDelay = _delay;
    emit UpdatedMinReportDelay(_delay);
  }

  /**
   * @notice
   *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
   *  of blocks that should pass for `harvest()` to be called.
   *
   *  For external keepers (such as the Keep3r network), this is the maximum
   *  time between jobs to wait. (see `harvestTrigger()`
   *  for more details.)
   *
   *  This may only be called by governance or the strategist.
   * @param _delay The maximum number of seconds to wait between harvests.
   */
  function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
    maxReportDelay = _delay;
    emit UpdatedMaxReportDelay(_delay);
  }

  /**
   * @notice
   *  Used to change `profitFactor`. `profitFactor` is used to determine
   *  if it's worthwhile to harvest, given gas costs. (See `harvestTrigger()`
   *  for more details.)
   *
   *  This may only be called by governance or the strategist.
   * @param _profitFactor A ratio to multiply anticipated
   * `harvest()` gas cost against.
   */
  function setProfitFactor(uint256 _profitFactor) external onlyAuthorized {
    profitFactor = _profitFactor;
    emit UpdatedProfitFactor(_profitFactor);
  }

  /**
   * @notice
   *  Sets how far the Strategy can go into loss without a harvest and report
   *  being required.
   *
   *  By default this is 0, meaning any losses would cause a harvest which
   *  will subsequently report the loss to the Vault for tracking. (See
   *  `harvestTrigger()` for more details.)
   *
   *  This may only be called by governance or the strategist.
   * @param _debtThreshold How big of a loss this Strategy may carry without
   * being required to report to the Vault.
   */
  function setDebtThreshold(uint256 _debtThreshold) external onlyAuthorized {
    debtThreshold = _debtThreshold;
    emit UpdatedDebtThreshold(_debtThreshold);
  }

  /**
   * @notice
   *  Used to change `metadataURI`. `metadataURI` is used to store the URI
   * of the file describing the strategy.
   *
   *  This may only be called by governance or the strategist.
   * @param _metadataURI The URI that describe the strategy.
   */
  function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
    metadataURI = _metadataURI;
    emit UpdatedMetadataURI(_metadataURI);
  }

  /**
   * Resolve governance address from Vault contract, used to make assertions
   * on protected functions in the Strategy.
   */
  function governance() internal view returns (address) {
    return IVault(vault).governance();
  }

  /**
   * @notice
   *  Provide an accurate estimate for the total amount of assets
   *  (principle + return) that this Strategy is currently managing,
   *  denominated in terms of `want` tokens.
   *
   *  This total should be "realizable" e.g. the total value that could
   *  *actually* be obtained from this Strategy if it were to divest its
   *  entire position based on current on-chain conditions.
   * @dev
   *  Care must be taken in using this function, since it relies on external
   *  systems, which could be manipulated by the attacker to give an inflated
   *  (or reduced) value produced by this function, based on current on-chain
   *  conditions (e.g. this function is possible to influence through
   *  flashloan attacks, oracle manipulations, or other DeFi attack
   *  mechanisms).
   *
   *  It is up to governance to use this function to correctly order this
   *  Strategy relative to its peers in the withdrawal queue to minimize
   *  losses for the Vault based on sudden withdrawals. This value should be
   *  higher than the total debt of the Strategy and higher than its expected
   *  value to be "safe".
   * @return The estimated total assets in this Strategy.
   */
  function estimatedTotalAssets() public view virtual returns (uint256);

  /*
   * @notice
   *  Provide an indication of whether this strategy is currently "active"
   *  in that it is managing an active position, or will manage a position in
   *  the future. This should correlate to `harvest()` activity, so that Harvest
   *  events can be tracked externally by indexing agents.
   * @return True if the strategy is actively managing a position.
   */
  function isActive() public view returns (bool) {
    return IVault(vault).strategyDebtRatio(address(this)) > 0 || estimatedTotalAssets() > 0;
  }

  /*
   * @notice
   *  Support ERC165 spec to allow other contracts to query if a strategy has implemented IStrategy interface
   */
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return _interfaceId == type(IStrategy).interfaceId || super.supportsInterface(_interfaceId);
  }

  /// @notice check the want token to make sure it is the token that the strategy is expecting
  // solhint-disable-next-line no-empty-blocks
  function checkWantToken() internal view virtual {
    // by default this will do nothing. But child strategies can override this and validate the want token
  }

  /**
   * Perform any Strategy unwinding or other calls necessary to capture the
   * "free return" this Strategy has generated since the last time its core
   * position(s) were adjusted. Examples include unwrapping extra rewards.
   * This call is only used during "normal operation" of a Strategy, and
   * should be optimized to minimize losses as much as possible.
   *
   * This method returns any realized profits and/or realized losses
   * incurred, and should return the total amounts of profits/losses/debt
   * payments (in `want` tokens) for the Vault's accounting (e.g.
   * `want.balanceOf(this) >= _debtPayment + _profit - _loss`).
   *
   * `_debtOutstanding` will be 0 if the Strategy is not past the configured
   * debt limit, otherwise its value will be how far past the debt limit
   * the Strategy is. The Strategy's debt limit is configured in the Vault.
   *
   * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
   *       It is okay for it to be less than `_debtOutstanding`, as that
   *       should only used as a guide for how much is left to pay back.
   *       Payments should be made to minimize loss from slippage, debt,
   *       withdrawal fees, etc.
   *
   * See `vault.debtOutstanding()`.
   */
  function prepareReturn(uint256 _debtOutstanding)
    internal
    virtual
    returns (
      uint256 _profit,
      uint256 _loss,
      uint256 _debtPayment
    );

  /**
   * Perform any adjustments to the core position(s) of this Strategy given
   * what change the Vault made in the "investable capital" available to the
   * Strategy. Note that all "free capital" in the Strategy after the report
   * was made is available for reinvestment. Also note that this number
   * could be 0, and you should handle that scenario accordingly.
   *
   * See comments regarding `_debtOutstanding` on `prepareReturn()`.
   */
  function adjustPosition(uint256 _debtOutstanding) internal virtual;

  /**
   * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
   * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
   * This function should return the amount of `want` tokens made available by the
   * liquidation. If there is a difference between them, `_loss` indicates whether the
   * difference is due to a realized loss, or if there is some other situation at play
   * (e.g. locked funds) where the amount made available is less than what is needed.
   * This function is used during emergency exit instead of `prepareReturn()` to
   * liquidate all of the Strategy's positions back to the Vault.
   *
   * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
   */
  function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _liquidatedAmount, uint256 _loss);

  /**
   * @notice
   *  Provide a signal to the keeper that `tend()` should be called. The
   *  keeper will provide the estimated gas cost that they would pay to call
   *  `tend()`, and this function should use that estimate to make a
   *  determination if calling it is "worth it" for the keeper. This is not
   *  the only consideration into issuing this trigger, for example if the
   *  position would be negatively affected if `tend()` is not called
   *  shortly, then this can return `true` even if the keeper might be
   *  "at a loss" (keepers are always reimbursed by Yearn).
   * @dev
   *  `callCost` must be priced in terms of `want`.
   *
   *  This call and `harvestTrigger()` should never return `true` at the same
   *  time.
   * @return `true` if `tend()` should be called, `false` otherwise.
   */
  // solhint-disable-next-line no-unused-vars
  function tendTrigger(uint256) public view virtual returns (bool) {
    // We usually don't need tend, but if there are positions that need
    // active maintenance, overriding this function is how you would
    // signal for that.
    return false;
  }

  /**
   * @notice
   *  Adjust the Strategy's position. The purpose of tending isn't to
   *  realize gains, but to maximize yield by reinvesting any returns.
   *
   *  See comments on `adjustPosition()`.
   *
   *  This may only be called by governance, the strategist, or the keeper.
   */
  function tend() external onlyKeepers {
    // Don't take profits with this call, but adjust for better gains
    adjustPosition(IVault(vault).debtOutstanding(address(this)));
  }

  /**
   * @notice
   *  Provide a signal to the keeper that `harvest()` should be called. The
   *  keeper will provide the estimated gas cost that they would pay to call
   *  `harvest()`, and this function should use that estimate to make a
   *  determination if calling it is "worth it" for the keeper. This is not
   *  the only consideration into issuing this trigger, for example if the
   *  position would be negatively affected if `harvest()` is not called
   *  shortly, then this can return `true` even if the keeper might be "at a
   *  loss" (keepers are always reimbursed by Yearn).
   * @dev
   *  `callCost` must be priced in terms of `want`.
   *
   *  This call and `tendTrigger` should never return `true` at the
   *  same time.
   *
   *  See `min/maxReportDelay`, `profitFactor`, `debtThreshold` to adjust the
   *  strategist-controlled parameters that will influence whether this call
   *  returns `true` or not. These parameters will be used in conjunction
   *  with the parameters reported to the Vault (see `params`) to determine
   *  if calling `harvest()` is merited.
   *
   *  It is expected that an external system will check `harvestTrigger()`.
   *  This could be a script run off a desktop or cloud bot (e.g.
   *  https://github.com/iearn-finance/yearn-vaults/blob/master/scripts/keep.py),
   *  or via an integration with the Keep3r network (e.g.
   *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
   * @param callCost The keeper's estimated cast cost to call `harvest()`.
   * @return `true` if `harvest()` should be called, `false` otherwise.
   */
  function harvestTrigger(uint256 callCost) public view virtual returns (bool) {
    StrategyInfo memory params = IVault(vault).strategy(address(this));

    // Should not trigger if Strategy is not activated
    if (params.activation == 0) return false;

    // Should not trigger if we haven't waited long enough since previous harvest
    if (timestamp().sub(params.lastReport) < minReportDelay) return false;

    // Should trigger if hasn't been called in a while
    if (timestamp().sub(params.lastReport) >= maxReportDelay) return true;

    // If some amount is owed, pay it back
    // NOTE: Since debt is based on deposits, it makes sense to guard against large
    //       changes to the value from triggering a harvest directly through user
    //       behavior. This should ensure reasonable resistance to manipulation
    //       from user-initiated withdrawals as the outstanding debt fluctuates.
    uint256 outstanding = IVault(vault).debtOutstanding(address(this));
    if (outstanding > debtThreshold) return true;

    // Check for profits and losses
    uint256 total = estimatedTotalAssets();
    // Trigger if we have a loss to report
    if (total.add(debtThreshold) < params.totalDebt) return true;

    uint256 profit = 0;
    if (total > params.totalDebt) profit = total.sub(params.totalDebt); // We've earned a profit!

    // Otherwise, only trigger if it "makes sense" economically (gas cost
    // is <N% of value moved)
    uint256 credit = IVault(vault).creditAvailable(address(this));
    return (profitFactor.mul(callCost) < credit.add(profit));
  }

  /**
   * @notice All the strategy to do something when harvest is called.
   */
  // solhint-disable-next-line no-empty-blocks
  function onHarvest() internal virtual {}

  /**
   * @notice
   *  Harvests the Strategy, recognizing any profits or losses and adjusting
   *  the Strategy's position.
   *
   *  In the rare case the Strategy is in emergency shutdown, this will exit
   *  the Strategy's position.
   *
   *  This may only be called by governance, the strategist, or the keeper.
   * @dev
   *  When `harvest()` is called, the Strategy reports to the Vault (via
   *  `vault.report()`), so in some cases `harvest()` must be called in order
   *  to take in profits, to borrow newly available funds from the Vault, or
   *  otherwise adjust its position. In other cases `harvest()` must be
   *  called to report to the Vault on the Strategy's position, especially if
   *  any losses have occurred.
   */
  function harvest() external onlyKeepers {
    uint256 profit = 0;
    uint256 loss = 0;
    uint256 debtOutstanding = IVault(vault).debtOutstanding(address(this));
    uint256 debtPayment = 0;
    onHarvest();
    if (emergencyExit) {
      // Free up as much capital as possible
      uint256 totalAssets = estimatedTotalAssets();
      // NOTE: use the larger of total assets or debt outstanding to book losses properly
      (debtPayment, loss) = liquidatePosition(totalAssets > debtOutstanding ? totalAssets : debtOutstanding);
      // NOTE: take up any remainder here as profit
      if (debtPayment > debtOutstanding) {
        profit = debtPayment.sub(debtOutstanding);
        debtPayment = debtOutstanding;
      }
    } else {
      // Free up returns for Vault to pull
      (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
    }

    // Allow Vault to take up to the "harvested" balance of this contract,
    // which is the amount it has earned since the last time it reported to
    // the Vault.
    debtOutstanding = IVault(vault).report(profit, loss, debtPayment);

    // Check if free returns are left, and re-invest them
    adjustPosition(debtOutstanding);

    emit Harvested(profit, loss, debtPayment, debtOutstanding);
  }

  /**
   * @notice
   *  Withdraws `_amountNeeded` to `vault`.
   *
   *  This may only be called by the Vault.
   * @param _amountNeeded How much `want` to withdraw.
   * @return _loss Any realized losses
   */
  function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
    require(msg.sender == address(vault), "!vault");
    // Liquidate as much as possible to `want`, up to `_amountNeeded`
    uint256 amountFreed;
    (amountFreed, _loss) = liquidatePosition(_amountNeeded);
    // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
    want.safeTransfer(msg.sender, amountFreed);
    // NOTE: Reinvest anything leftover on next `tend`/`harvest`
  }

  /**
   * Do anything necessary to prepare this Strategy for migration, such as
   * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
   * value.
   */
  function prepareMigration(address _newStrategy) internal virtual;

  /**
   * @notice
   *  Transfers all `want` from this Strategy to `_newStrategy`.
   *
   *  This may only be called by governance or the Vault.
   * @dev
   *  The new Strategy's Vault must be the same as this Strategy's Vault.
   * @param _newStrategy The Strategy to migrate to.
   */
  function migrate(address _newStrategy) external {
    require(msg.sender == address(vault) || msg.sender == governance(), "!authorised");
    require(BaseStrategy(_newStrategy).vault() == vault, "invalid vault");
    prepareMigration(_newStrategy);
    want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
  }

  /**
   * @notice
   *  Activates emergency exit. Once activated, the Strategy will exit its
   *  position upon the next harvest, depositing all funds into the Vault as
   *  quickly as is reasonable given on-chain conditions.
   *
   *  This may only be called by governance or the strategist.
   * @dev
   *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
   */
  function setEmergencyExit() external onlyAuthorized {
    emergencyExit = true;
    IVault(vault).revokeStrategy();

    emit EmergencyExitEnabled();
  }

  /**
   * Override this to add all tokens/tokenized positions this contract
   * manages on a *persistent* basis (e.g. not just for swapping back to
   * want ephemerally).
   *
   * NOTE: Do *not* include `want`, already included in `sweep` below.
   *
   * Example:
   *
   *    function protectedTokens() internal override view returns (address[] memory) {
   *      address[] memory protected = new address[](3);
   *      protected[0] = tokenA;
   *      protected[1] = tokenB;
   *      protected[2] = tokenC;
   *      return protected;
   *    }
   */
  function protectedTokens() internal view virtual returns (address[] memory);

  /**
   * @notice
   *  Removes tokens from this Strategy that are not the type of tokens
   *  managed by this Strategy. This may be used in case of accidentally
   *  sending the wrong kind of token to this Strategy.
   *
   *  Tokens will be sent to `governance()`.
   *
   *  This will fail if an attempt is made to sweep `want`, or any tokens
   *  that are protected by this Strategy.
   *
   *  This may only be called by governance.
   * @dev
   *  Implement `protectedTokens()` to specify any additional tokens that
   *  should be protected from sweeping in addition to `want`.
   * @param _token The token to transfer out of this vault.
   */
  function sweep(address _token) external onlyGovernance {
    require(_token != address(want), "!want");
    require(_token != address(vault), "!shares");

    address[] memory _protectedTokens = protectedTokens();
    for (uint256 i; i < _protectedTokens.length; i++) {
      require(_token != _protectedTokens[i], "!protected");
    }

    IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
  }

  function timestamp() internal view virtual returns (uint256) {
    // solhint-disable-next-line not-rely-on-time
    return block.timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ICurveRegistry {
  function get_lp_token(address _pool) external view returns (address);

  function get_gauges(address _pool) external view returns (address[10] memory, address[10] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

interface ICurveAddressProvider {
  function get_registry() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

struct StrategyInfo {
  uint256 activation;
  uint256 lastReport;
  uint256 totalDebt;
  uint256 totalGain;
  uint256 totalLoss;
}

interface IVault is IERC20, IERC20Permit {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint256);

  function activation() external view returns (uint256);

  function rewards() external view returns (address);

  function managementFee() external view returns (uint256);

  function gatekeeper() external view returns (address);

  function governance() external view returns (address);

  function creator() external view returns (address);

  function strategyDataStore() external view returns (address);

  function healthCheck() external view returns (address);

  function emergencyShutdown() external view returns (bool);

  function lockedProfitDegradation() external view returns (uint256);

  function depositLimit() external view returns (uint256);

  function lastReport() external view returns (uint256);

  function lockedProfit() external view returns (uint256);

  function totalDebt() external view returns (uint256);

  function token() external view returns (address);

  function totalAsset() external view returns (uint256);

  function availableDepositLimit() external view returns (uint256);

  function maxAvailableShares() external view returns (uint256);

  function pricePerShare() external view returns (uint256);

  function debtOutstanding(address _strategy) external view returns (uint256);

  function creditAvailable(address _strategy) external view returns (uint256);

  function expectedReturn(address _strategy) external view returns (uint256);

  function strategy(address _strategy) external view returns (StrategyInfo memory);

  function strategyDebtRatio(address _strategy) external view returns (uint256);

  function setRewards(address _rewards) external;

  function setManagementFee(uint256 _managementFee) external;

  function setGatekeeper(address _gatekeeper) external;

  function setStrategyDataStore(address _strategyDataStoreContract) external;

  function setHealthCheck(address _healthCheck) external;

  function setVaultEmergencyShutdown(bool _active) external;

  function setLockedProfileDegradation(uint256 _degradation) external;

  function setDepositLimit(uint256 _limit) external;

  function sweep(address _token, uint256 _amount) external;

  function addStrategy(address _strategy) external returns (bool);

  function migrateStrategy(address _oldVersion, address _newVersion) external returns (bool);

  function revokeStrategy() external;

  /// @notice deposit the given amount into the vault, and return the number of shares
  function deposit(uint256 _amount, address _recipient) external returns (uint256);

  /// @notice burn the given amount of shares from the vault, and return the number of underlying tokens recovered
  function withdraw(
    uint256 _shares,
    address _recipient,
    uint256 _maxLoss
  ) external returns (uint256);

  function report(
    uint256 _gain,
    uint256 _loss,
    uint256 _debtPayment
  ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStrategy {
  // *** Events *** //
  event Harvested(uint256 _profit, uint256 _loss, uint256 _debtPayment, uint256 _debtOutstanding);
  event StrategistUpdated(address _newStrategist);
  event KeeperUpdated(address _newKeeper);
  event MinReportDelayUpdated(uint256 _delay);
  event MaxReportDelayUpdated(uint256 _delay);
  event ProfitFactorUpdated(uint256 _profitFactor);
  event DebtThresholdUpdated(uint256 _debtThreshold);
  event EmergencyExitEnabled();

  // *** The following functions are used by the Vault *** //
  /// @notice returns the address of the token that the strategy wants
  function want() external view returns (IERC20);

  /// @notice the address of the Vault that the strategy belongs to
  function vault() external view returns (address);

  /// @notice if the strategy is active
  function isActive() external view returns (bool);

  /// @notice migrate the strategy to the new one
  function migrate(address _newStrategy) external;

  /// @notice withdraw the amount from the strategy
  function withdraw(uint256 _amount) external returns (uint256);

  /// @notice the amount of total assets managed by this strategy that should not account towards the TVL of the strategy
  function delegatedAssets() external view returns (uint256);

  /// @notice the total assets that the strategy is managing
  function estimatedTotalAssets() external view returns (uint256);

  // *** public read functions that can be called by anyone *** //
  function name() external view returns (string memory);

  function harvester() external view returns (address);

  function strategyProposer() external view returns (address);

  function strategyDeveloper() external view returns (address);

  function tendTrigger(uint256 _callCost) external view returns (bool);

  function harvestTrigger(uint256 _callCost) external view returns (bool);

  // *** write functions that can be called by the governance, the strategist or the keeper *** //
  function tend() external;

  function harvest() external;

  // *** write functions that can be called by the governance or the strategist ***//

  function setHarvester(address _havester) external;

  function setVault(address _vault) external;

  /// @notice `minReportDelay` is the minimum number of blocks that should pass for `harvest()` to be called.
  function setMinReportDelay(uint256 _delay) external;

  function setMaxReportDelay(uint256 _delay) external;

  /// @notice `profitFactor` is used to determine if it's worthwhile to harvest, given gas costs.
  function setProfitFactor(uint256 _profitFactor) external;

  /// @notice Sets how far the Strategy can go into loss without a harvest and report being required.
  function setDebtThreshold(uint256 _debtThreshold) external;

  // *** write functions that can be called by the governance, or the strategist, or the guardian, or the management *** //
  function setEmergencyExit() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}