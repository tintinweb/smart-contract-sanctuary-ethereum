// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {Errors} from '../libraries/helpers/Errors.sol';
import {VersionedInitializable} from '../../protocol/libraries/sturdy-upgradeability/VersionedInitializable.sol';
import {ILendingPoolAddressesProvider} from '../../interfaces/ILendingPoolAddressesProvider.sol';
import {ILendingPool} from '../../interfaces/ILendingPool.sol';
import {IPriceOracleGetter} from '../../interfaces/IPriceOracleGetter.sol';
import {ISwapRouter} from '../../interfaces/ISwapRouter.sol';
import {IERC20} from '../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IERC20Detailed} from '../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';
import {PercentageMath} from '../libraries/math/PercentageMath.sol';
import {SafeERC20} from '../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {TransferHelper} from '../libraries/helpers/TransferHelper.sol';
import {UniswapAdapter} from '../libraries/swap/UniswapAdapter.sol';
import {CurveswapAdapter} from '../libraries/swap/CurveswapAdapter.sol';

/**
 * @title YieldManager
 * @notice yield distributor by swapping from assets to stable coin
 * @author Sturdy
 **/

contract YieldManager is VersionedInitializable, Ownable {
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;

  struct AssetYield {
    address asset;
    uint256 amount;
  }

  // the list of the available reserves, structured as a mapping for gas savings reasons
  mapping(uint256 => address) internal _assetsList;
  mapping(address => bool) internal _assetManaged;
  uint256 internal _assetsCount;

  ILendingPoolAddressesProvider internal _addressesProvider;

  uint256 private constant REVISION = 0x1;

  address public _exchangeToken;

  // tokenIn -> tokenOut -> Curve Pool Address
  mapping(address => mapping(address => address)) internal _curvePools;

  uint256 private constant UNISWAP_FEE = 10000; // 1%

  /**
   * @dev Emitted on setExchangeToken()
   * @param _token The address of token being used as an exchange token
   */
  event NewExchangeToken(address _token);

  /**
   * @dev Emitted on registerAsset()
   * @param _asset The address of reward asset
   */
  event RegisterAsset(address _asset);

  /**
   * @dev Emitted on unregisterAsset()
   * @param _asset The address of asset being removed from reward token list
   */
  event UnregisterAsset(address _asset);

  /**
   * @dev Emitted on setCurvePool()
   * @param _tokenIn The address of token being swapped
   * @param _tokenOut The address of token being received
   * @param _pool The address of Curve Pool being used for swapping
   */
  event AddCurveSwapPool(address _tokenIn, address _tokenOut, address _pool);

  modifier onlyAdmin() {
    require(_addressesProvider.getPoolAdmin() == msg.sender, Errors.CALLER_NOT_POOL_ADMIN);
    _;
  }

  modifier onlyYieldProcessor() {
    require(
      _addressesProvider.getAddress('YIELD_PROCESSOR') == msg.sender,
      Errors.CALLER_NOT_YIELD_PROCESSOR
    );
    _;
  }

  /**
   * @dev Function is invoked by the proxy contract when the Vault contract is deployed.
   * @param _provider The address of the provider
   **/
  function initialize(ILendingPoolAddressesProvider _provider) external initializer {
    _addressesProvider = _provider;
  }

  function setExchangeToken(address _token) external payable onlyAdmin {
    require(_token != address(0), Errors.VT_INVALID_CONFIGURATION);
    _exchangeToken = _token;

    emit NewExchangeToken(_token);
  }

  function getRevision() internal pure override returns (uint256) {
    return REVISION;
  }

  function registerAsset(address _asset) external payable onlyAdmin {
    require(_asset != address(0), Errors.VT_INVALID_CONFIGURATION);
    require(_assetManaged[_asset] != true, Errors.VT_INVALID_CONFIGURATION);

    _assetsList[_assetsCount] = _asset;
    _assetManaged[_asset] = true;
    _assetsCount += 1;

    emit RegisterAsset(_asset);
  }

  function unregisterAsset(uint256 _index) external payable onlyAdmin {
    uint256 count = _assetsCount;
    require(_index < count, Errors.VT_INVALID_CONFIGURATION);

    address _asset = _assetsList[_index];
    _assetManaged[_asset] = false;

    emit UnregisterAsset(_asset);

    count -= 1;
    if (_index == count) return;

    _assetsList[_index] = _assetsList[count];
    _assetsCount = count;
  }

  function getAssetCount() external view returns (uint256) {
    return _assetsCount;
  }

  function getAssetInfo(uint256 _index) external view returns (address) {
    return _assetsList[_index];
  }

  /**
   * @dev Function to set Curve Pool address for the swap
   * @param _tokenIn The address of token being exchanged
   * @param _tokenOut The address of token being received
   * @param _pool The address of the Curve pool to use for the swap
   */
  function setCurvePool(
    address _tokenIn,
    address _tokenOut,
    address _pool
  ) external payable onlyAdmin {
    require(_tokenIn != address(0), Errors.VT_INVALID_CONFIGURATION);
    require(_tokenOut != address(0), Errors.VT_INVALID_CONFIGURATION);
    require(_pool != address(0), Errors.VT_INVALID_CONFIGURATION);

    _curvePools[_tokenIn][_tokenOut] = _pool;

    emit AddCurveSwapPool(_tokenIn, _tokenOut, _pool);
  }

  /**
   * @dev Function to get Curve Pool address for the swap
   * @param _tokenIn The address of token being sent
   * @param _tokenOut The address of token being received
   */
  function getCurvePool(address _tokenIn, address _tokenOut) external view returns (address) {
    return _curvePools[_tokenIn][_tokenOut];
  }

  /**
   * @dev Distribute the yield of assets to suppliers.
   *      1. convert asset to exchange token(for now it's USDC) via Uniswap
   *      2. convert exchange token to other stables via Curve
   *      3. deposit to pool for suppliers
   * @param _offset assets array's start offset.
   * @param _count assets array's count when perform distribution.
   * @param _slippage The slippage of the swap 1% = 100
   * @param _paths The swapping path of uniswap
   **/
  function distributeYield(
    uint256 _offset,
    uint256 _count,
    uint256 _slippage,
    UniswapAdapter.Path[] calldata _paths
  ) external payable onlyYieldProcessor {
    require(_paths.length == _count, Errors.VT_SWAP_PATH_LENGTH_INVALID);

    address token = _exchangeToken;
    ILendingPoolAddressesProvider provider = _addressesProvider;

    // 1. convert from asset to exchange token via uniswap
    for (uint256 i; i < _count; ++i) {
      address asset = _assetsList[_offset + i];
      require(asset != address(0), Errors.UL_INVALID_INDEX);
      uint256 amount = IERC20Detailed(asset).balanceOf(address(this));
      UniswapAdapter.swapExactTokensForTokens(provider, asset, token, amount, _paths[i], _slippage);
    }
    uint256 exchangedAmount = IERC20Detailed(token).balanceOf(address(this));

    // 2. convert from exchange token to other stable assets via curve swap
    AssetYield[] memory assetYields = _getAssetYields(exchangedAmount, provider);

    _depositAssetYields(assetYields, provider, token, _slippage);
  }

  /**
   * @dev deposit Yields to pool for suppliers
   **/
  function _depositAssetYields(
    AssetYield[] memory _assetYields,
    ILendingPoolAddressesProvider _provider,
    address _token,
    uint256 _slippage
  ) internal {
    uint256 length = _assetYields.length;
    for (uint256 i; i < length; ++i) {
      if (_assetYields[i].amount > 0) {
        uint256 amount;

        if (_assetYields[i].asset == _token) {
          amount = _assetYields[i].amount;
        } else {
          address pool = _curvePools[_token][_assetYields[i].asset];
          require(pool != address(0), Errors.VT_INVALID_CONFIGURATION);
          amount = CurveswapAdapter.swapExactTokensForTokens(
            _provider,
            pool,
            _token,
            _assetYields[i].asset,
            _assetYields[i].amount,
            _slippage
          );
        }
        // 3. deposit Yield to pool for suppliers
        address lendingPool = _provider.getLendingPool();
        IERC20(_assetYields[i].asset).safeApprove(lendingPool, 0);
        IERC20(_assetYields[i].asset).safeApprove(lendingPool, amount);
        ILendingPool(lendingPool).depositYield(_assetYields[i].asset, amount);
      }
    }
  }

  /**
   * @dev Get the list of asset and asset's yield amount
   **/
  function _getAssetYields(uint256 _totalYieldAmount, ILendingPoolAddressesProvider provider)
    internal
    view
    returns (AssetYield[] memory)
  {
    // Get total borrowing asset volume and volumes and assets
    (
      uint256 totalVolume,
      uint256[] memory volumes,
      address[] memory assets,
      uint256 length
    ) = ILendingPool(provider.getLendingPool()).getBorrowingAssetAndVolumes();

    if (totalVolume == 0) return new AssetYield[](0);

    AssetYield[] memory assetYields = new AssetYield[](length);
    uint256 extraYieldAmount = _totalYieldAmount;

    for (uint256 i; i < length; ++i) {
      assetYields[i].asset = assets[i];
      if (i == length - 1) {
        // without calculation, set remained extra amount
        assetYields[i].amount = extraYieldAmount;
      } else {
        // Distribute yieldAmount based on percent of asset volume
        assetYields[i].amount = _totalYieldAmount.percentMul(
          (volumes[i] * PercentageMath.PERCENTAGE_FACTOR) / totalVolume
        );
        extraYieldAmount -= assetYields[i].amount;
      }
    }

    return assetYields;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Sturdy, inspiration from Aave
 * @notice Defines the error messages emitted by the different contracts of the Sturdy protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
  //common errors
  string internal constant CALLER_NOT_POOL_ADMIN = '33'; // 'The caller must be the pool admin'
  string internal constant BORROW_ALLOWANCE_NOT_ENOUGH = '59'; // User borrows on behalf, but allowance are too small

  //contract specific errors
  string internal constant VL_INVALID_AMOUNT = '1'; // 'Amount must be greater than 0'
  string internal constant VL_NO_ACTIVE_RESERVE = '2'; // 'Action requires an active reserve'
  string internal constant VL_RESERVE_FROZEN = '3'; // 'Action cannot be performed because the reserve is frozen'
  string internal constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = '4'; // 'The current liquidity is not enough'
  string internal constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = '5'; // 'User cannot withdraw more than the available balance'
  string internal constant VL_TRANSFER_NOT_ALLOWED = '6'; // 'Transfer cannot be allowed.'
  string internal constant VL_BORROWING_NOT_ENABLED = '7'; // 'Borrowing is not enabled'
  string internal constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = '8'; // 'Invalid interest rate mode selected'
  string internal constant VL_COLLATERAL_BALANCE_IS_0 = '9'; // 'The collateral balance is 0'
  string internal constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = '10'; // 'Health factor is lesser than the liquidation threshold'
  string internal constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = '11'; // 'There is not enough collateral to cover a new borrow'
  string internal constant VL_STABLE_BORROWING_NOT_ENABLED = '12'; // stable borrowing not enabled
  string internal constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = '13'; // collateral is (mostly) the same currency that is being borrowed
  string internal constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = '14'; // 'The requested amount is greater than the max loan size in stable rate mode
  string internal constant VL_NO_DEBT_OF_SELECTED_TYPE = '15'; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
  string internal constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = '16'; // 'To repay on behalf of an user an explicit amount to repay is needed'
  string internal constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = '17'; // 'User does not have a stable rate loan in progress on this reserve'
  string internal constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = '18'; // 'User does not have a variable rate loan in progress on this reserve'
  string internal constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = '19'; // 'The underlying balance needs to be greater than 0'
  string internal constant VL_DEPOSIT_ALREADY_IN_USE = '20'; // 'User deposit is already being used as collateral'
  string internal constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = '21'; // 'User does not have any stable rate loan for this reserve'
  string internal constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = '22'; // 'Interest rate rebalance conditions were not met'
  string internal constant LP_LIQUIDATION_CALL_FAILED = '23'; // 'Liquidation call failed'
  string internal constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = '24'; // 'There is not enough liquidity available to borrow'
  string internal constant LP_REQUESTED_AMOUNT_TOO_SMALL = '25'; // 'The requested amount is too small for a FlashLoan.'
  string internal constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = '26'; // 'The actual balance of the protocol is inconsistent'
  string internal constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = '27'; // 'The caller of the function is not the lending pool configurator'
  string internal constant LP_INCONSISTENT_FLASHLOAN_PARAMS = '28';
  string internal constant CT_CALLER_MUST_BE_LENDING_POOL = '29'; // 'The caller of this function must be a lending pool'
  string internal constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = '30'; // 'User cannot give allowance to himself'
  string internal constant CT_TRANSFER_AMOUNT_NOT_GT_0 = '31'; // 'Transferred amount needs to be greater than zero'
  string internal constant RL_RESERVE_ALREADY_INITIALIZED = '32'; // 'Reserve has already been initialized'
  string internal constant LPC_RESERVE_LIQUIDITY_NOT_0 = '34'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_ATOKEN_POOL_ADDRESS = '35'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = '36'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = '37'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '38'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = '39'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_ADDRESSES_PROVIDER_ID = '40'; // 'The liquidity of the reserve needs to be 0'
  string internal constant LPC_INVALID_CONFIGURATION = '75'; // 'Invalid risk parameters for the reserve'
  string internal constant LPC_CALLER_NOT_EMERGENCY_ADMIN = '76'; // 'The caller must be the emergency admin'
  string internal constant LPAPR_PROVIDER_NOT_REGISTERED = '41'; // 'Provider is not registered'
  string internal constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = '42'; // 'Health factor is not below the threshold'
  string internal constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = '43'; // 'The collateral chosen cannot be liquidated'
  string internal constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = '44'; // 'User did not borrow the specified currency'
  string internal constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = '45'; // "There isn't enough liquidity available to liquidate"
  string internal constant LPCM_NO_ERRORS = '46'; // 'No errors'
  string internal constant LP_INVALID_FLASHLOAN_MODE = '47'; //Invalid flashloan mode selected
  string internal constant MATH_MULTIPLICATION_OVERFLOW = '48';
  string internal constant MATH_ADDITION_OVERFLOW = '49';
  string internal constant MATH_DIVISION_BY_ZERO = '50';
  string internal constant RL_LIQUIDITY_INDEX_OVERFLOW = '51'; //  Liquidity index overflows uint128
  string internal constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = '52'; //  Variable borrow index overflows uint128
  string internal constant RL_LIQUIDITY_RATE_OVERFLOW = '53'; //  Liquidity rate overflows uint128
  string internal constant RL_VARIABLE_BORROW_RATE_OVERFLOW = '54'; //  Variable borrow rate overflows uint128
  string internal constant RL_STABLE_BORROW_RATE_OVERFLOW = '55'; //  Stable borrow rate overflows uint128
  string internal constant CT_INVALID_MINT_AMOUNT = '56'; //invalid amount to mint
  string internal constant LP_FAILED_REPAY_WITH_COLLATERAL = '57';
  string internal constant CT_INVALID_BURN_AMOUNT = '58'; //invalid amount to burn
  string internal constant LP_FAILED_COLLATERAL_SWAP = '60';
  string internal constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = '61';
  string internal constant LP_REENTRANCY_NOT_ALLOWED = '62';
  string internal constant LP_CALLER_MUST_BE_AN_ATOKEN = '63';
  string internal constant LP_IS_PAUSED = '64'; // 'Pool is paused'
  string internal constant LP_NO_MORE_RESERVES_ALLOWED = '65';
  string internal constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = '66';
  string internal constant RC_INVALID_LTV = '67';
  string internal constant RC_INVALID_LIQ_THRESHOLD = '68';
  string internal constant RC_INVALID_LIQ_BONUS = '69';
  string internal constant RC_INVALID_DECIMALS = '70';
  string internal constant RC_INVALID_RESERVE_FACTOR = '71';
  string internal constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = '72';
  string internal constant VL_INCONSISTENT_FLASHLOAN_PARAMS = '73';
  string internal constant LP_INCONSISTENT_PARAMS_LENGTH = '74';
  string internal constant UL_INVALID_INDEX = '77';
  string internal constant LP_NOT_CONTRACT = '78';
  string internal constant SDT_STABLE_DEBT_OVERFLOW = '79';
  string internal constant SDT_BURN_EXCEEDS_BALANCE = '80';
  string internal constant VT_COLLATERAL_DEPOSIT_REQUIRE_ETH = '81'; //Only accept ETH for collateral deposit
  string internal constant VT_COLLATERAL_DEPOSIT_INVALID = '82'; //Collateral deposit failed
  string internal constant VT_LIQUIDITY_DEPOSIT_INVALID = '83'; //Only accept USDC, USDT, DAI for liquidity deposit
  string internal constant VT_COLLATERAL_WITHDRAW_INVALID = '84'; //Collateral withdraw failed
  string internal constant VT_COLLATERAL_WITHDRAW_INVALID_AMOUNT = '85'; //Collateral withdraw has not enough amount
  string internal constant VT_CONVERT_ASSET_BY_CURVE_INVALID = '86'; //Convert asset by curve invalid
  string internal constant VT_PROCESS_YIELD_INVALID = '87'; //Processing yield is invalid
  string internal constant VT_TREASURY_INVALID = '88'; //Treasury is invalid
  string internal constant LP_ATOKEN_INIT_INVALID = '89'; //aToken invalid init
  string internal constant VT_FEE_TOO_BIG = '90'; //Fee is too big
  string internal constant VT_COLLATERAL_DEPOSIT_VAULT_UNAVAILABLE = '91';
  string internal constant LP_LIQUIDATION_CONVERT_FAILED = '92';
  string internal constant VT_DEPLOY_FAILED = '93'; // Vault deploy failed
  string internal constant VT_INVALID_CONFIGURATION = '94'; // Invalid vault configuration
  string internal constant VL_OVERFLOW_MAX_RESERVE_CAPACITY = '95'; // overflow max capacity of reserve
  string internal constant VT_WITHDRAW_AMOUNT_MISMATCH = '96'; // not performed withdraw 100%
  string internal constant VT_SWAP_MISMATCH_RETURNED_AMOUNT = '97'; //Returned amount is not enough
  string internal constant CALLER_NOT_YIELD_PROCESSOR = '98'; // 'The caller must be the pool admin'
  string internal constant VT_EXTRA_REWARDS_INDEX_INVALID = '99'; // Invalid extraRewards index
  string internal constant VT_SWAP_PATH_LENGTH_INVALID = '100'; // Invalid token or fee length
  string internal constant VT_SWAP_PATH_TOKEN_INVALID = '101'; // Invalid token information

  enum CollateralManagerErrors {
    NO_ERROR,
    NO_COLLATERAL_AVAILABLE,
    COLLATERAL_CANNOT_BE_LIQUIDATED,
    CURRRENCY_NOT_BORROWED,
    HEALTH_FACTOR_ABOVE_THRESHOLD,
    NOT_ENOUGH_LIQUIDITY,
    NO_ACTIVE_RESERVE,
    HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
    INVALID_EQUAL_ASSETS_TO_SWAP,
    FROZEN_RESERVE
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title VersionedInitializable
 *
 * @dev Helper contract to implement initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 * @author Sturdy, inspiration from Aave
 */
abstract contract VersionedInitializable {
  /**
   * @dev Indicates that the contract has been initialized.
   */
  uint256 private lastInitializedRevision;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    uint256 revision = getRevision();
    require(
      initializing || isConstructor() || revision > lastInitializedRevision,
      'Contract instance has already been initialized'
    );

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      lastInitializedRevision = revision;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /**
   * @dev returns the revision number of the contract
   * Needs to be defined in the inherited class as a constant.
   **/
  function getRevision() internal pure virtual returns (uint256);

  /**
   * @dev Returns true if and only if the function is running in the constructor
   **/
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    uint256 cs;
    //solium-disable-next-line
    assembly {
      cs := extcodesize(address())
    }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Sturdy Governance
 * @author Sturdy, inspiration from Aave
 **/
interface ILendingPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendingPoolUpdated(address indexed newAddress);
  event IncentiveControllerUpdated(address indexed newAddress);
  event IncentiveTokenUpdated(address indexed newAddress);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendingPoolConfiguratorUpdated(address indexed newAddress);
  event LendingPoolCollateralManagerUpdated(address indexed newAddress);
  event PriceOracleUpdated(address indexed newAddress);
  event LendingRateOracleUpdated(address indexed newAddress);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external payable;

  function setAddress(bytes32 id, address newAddress) external payable;

  function setAddressAsProxy(bytes32 id, address impl) external payable;

  function getAddress(bytes32 id) external view returns (address);

  function getLendingPool() external view returns (address);

  function setLendingPoolImpl(address pool) external payable;

  function getIncentiveController() external view returns (address);

  function setIncentiveControllerImpl(address incentiveController) external payable;

  function getIncentiveToken() external view returns (address);

  function setIncentiveTokenImpl(address incentiveToken) external payable;

  function getLendingPoolConfigurator() external view returns (address);

  function setLendingPoolConfiguratorImpl(address configurator) external payable;

  function getLendingPoolCollateralManager() external view returns (address);

  function setLendingPoolCollateralManager(address manager) external payable;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external payable;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external payable;

  function getPriceOracle() external view returns (address);

  function setPriceOracle(address priceOracle) external payable;

  function getLendingRateOracle() external view returns (address);

  function setLendingRateOracle(address lendingRateOracle) external payable;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from './ILendingPoolAddressesProvider.sol';
import {DataTypes} from '../protocol/libraries/types/DataTypes.sol';

interface ILendingPool {
  /**
   * @dev Emitted on deposit()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address initiating the deposit
   * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
   * @param amount The amount deposited
   * @param referral The referral code used
   **/
  event Deposit(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on withdraw()
   * @param reserve The address of the underlyng asset being withdrawn
   * @param user The address initiating the withdrawal, owner of aTokens
   * @param to Address that will receive the underlying
   * @param amount The amount to be withdrawn
   **/
  event Withdraw(address indexed reserve, address indexed user, address indexed to, uint256 amount);

  /**
   * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
   * @param reserve The address of the underlying asset being borrowed
   * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
   * initiator of the transaction on flashLoan()
   * @param onBehalfOf The address that will be getting the debt
   * @param amount The amount borrowed out
   * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
   * @param borrowRate The numeric rate at which the user has borrowed
   * @param referral The referral code used
   **/
  event Borrow(
    address indexed reserve,
    address user,
    address indexed onBehalfOf,
    uint256 amount,
    uint256 borrowRateMode,
    uint256 borrowRate,
    uint16 indexed referral
  );

  /**
   * @dev Emitted on repay()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The beneficiary of the repayment, getting his debt reduced
   * @param repayer The address of the user initiating the repay(), providing the funds
   * @param amount The amount repaid
   **/
  event Repay(
    address indexed reserve,
    address indexed user,
    address indexed repayer,
    uint256 amount
  );

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on setUserUseReserveAsCollateral()
   * @param reserve The address of the underlying asset of the reserve
   * @param user The address of the user enabling the usage as collateral
   **/
  event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

  /**
   * @dev Emitted on flashLoan()
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param asset The address of the asset being flash borrowed
   * @param amount The amount flash borrowed
   * @param premium The fee flash borrowed
   * @param referralCode The referral code used
   **/
  event FlashLoan(
    address indexed target,
    address indexed initiator,
    address indexed asset,
    uint256 amount,
    uint256 premium,
    uint16 referralCode
  );

  /**
   * @dev Emitted when the pause is triggered.
   */
  event Paused();

  /**
   * @dev Emitted when the pause is lifted.
   */
  event Unpaused();

  /**
   * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
   * LendingPoolCollateral manager using a DELEGATECALL
   * This allows to have the events in the generated ABI for LendingPool.
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
   * @param liquidator The address of the liquidator
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  event LiquidationCall(
    address indexed collateralAsset,
    address indexed debtAsset,
    address indexed user,
    uint256 debtToCover,
    uint256 liquidatedCollateralAmount,
    address liquidator,
    bool receiveAToken
  );

  /**
   * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
   * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
   * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
   * gets added to the LendingPool ABI
   * @param reserve The address of the underlying asset of the reserve
   * @param liquidityRate The new liquidity rate
   * @param stableBorrowRate The new stable borrow rate
   * @param variableBorrowRate The new variable borrow rate
   * @param liquidityIndex The new liquidity index
   * @param variableBorrowIndex The new variable borrow index
   **/
  event ReserveDataUpdated(
    address indexed reserve,
    uint256 liquidityRate,
    uint256 stableBorrowRate,
    uint256 variableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex
  );

  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  function depositYield(address asset, uint256 amount) external;

  function getYield(address asset, uint256 amount) external;

  function getTotalBalanceOfAssetPair(address asset) external view returns (uint256, uint256);

  function getBorrowingAssetAndVolumes()
    external
    view
    returns (
      uint256,
      uint256[] memory,
      address[] memory,
      uint256
    );

  function registerVault(address _vaultAddress) external payable;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);

  function withdrawFrom(
    address asset,
    uint256 amount,
    address from,
    address to
  ) external returns (uint256);

  /**
   * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
   * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
   * corresponding debt token (StableDebtToken or VariableDebtToken)
   * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
   *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
   * @param asset The address of the underlying asset to borrow
   * @param amount The amount to be borrowed
   * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
   * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
   * if he has been given credit delegation allowance
   **/
  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external;

  /**
   * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
   * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
   * @param asset The address of the borrowed underlying asset previously borrowed
   * @param amount The amount to repay
   * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
   * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
   * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
   * user calling the function if he wants to reduce/remove his own debt, or the address of any other
   * other borrower whose debt should be removed
   * @return The final amount repaid
   **/
  function repay(
    address asset,
    uint256 amount,
    uint256 rateMode,
    address onBehalfOf
  ) external returns (uint256);

  /**
   * @dev Allows depositors to enable/disable a specific deposited asset as collateral
   * @param asset The address of the underlying asset deposited
   * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
   **/
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

  /**
   * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
   * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
   *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
   * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
   * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
   * @param user The address of the borrower getting liquidated
   * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
   * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
   * to receive the underlying collateral asset directly
   **/
  function liquidationCall(
    address collateralAsset,
    address debtAsset,
    address user,
    uint256 debtToCover,
    bool receiveAToken
  ) external;

  /**
   * @dev Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateralETH the total collateral in ETH of the user
   * @return totalDebtETH the total debt in ETH of the user
   * @return availableBorrowsETH the borrowing power left of the user
   * @return currentLiquidationThreshold the liquidation threshold of the user
   * @return ltv the loan to value of the user
   * @return healthFactor the current health factor of the user
   **/
  function getUserAccountData(address user)
    external
    view
    returns (
      uint256 totalCollateralETH,
      uint256 totalDebtETH,
      uint256 availableBorrowsETH,
      uint256 currentLiquidationThreshold,
      uint256 ltv,
      uint256 healthFactor
    );

  function initReserve(
    address reserve,
    address yieldAddress,
    address aTokenAddress,
    address stableDebtAddress,
    address variableDebtAddress,
    address interestRateStrategyAddress
  ) external payable;

  function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
    external
    payable;

  function setConfiguration(address reserve, uint256 configuration) external payable;

  /**
   * @dev Returns the configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The configuration of the reserve
   **/
  function getConfiguration(address asset)
    external
    view
    returns (DataTypes.ReserveConfigurationMap memory);

  /**
   * @dev Returns the configuration of the user across all the reserves
   * @param user The user address
   * @return The configuration of the user
   **/
  function getUserConfiguration(address user)
    external
    view
    returns (DataTypes.UserConfigurationMap memory);

  /**
   * @dev Returns the normalized income normalized income of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve's normalized income
   */
  function getReserveNormalizedIncome(address asset) external view returns (uint256);

  /**
   * @dev Returns the normalized variable debt per unit of asset
   * @param asset The address of the underlying asset of the reserve
   * @return The reserve normalized variable debt
   */
  function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

  /**
   * @dev Returns the state and configuration of the reserve
   * @param asset The address of the underlying asset of the reserve
   * @return The state of the reserve
   **/
  function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

  function finalizeTransfer(
    address asset,
    address from,
    address to,
    uint256 amount,
    uint256 balanceFromAfter,
    uint256 balanceToBefore
  ) external;

  function getReservesList() external view returns (address[] memory);

  function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

  function setPause(bool val) external payable;

  function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title IPriceOracleGetter interface
 * @notice Interface for the Sturdy price oracle.
 **/

interface IPriceOracleGetter {
  /**
   * @dev returns the asset price in ETH
   * @param asset the address of the asset
   * @return the ETH price of the asset
   **/
  function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
  struct ExactInputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another token
  /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInputSingle(ExactInputSingleParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  struct ExactInputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
  }

  /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
  /// @return amountOut The amount of the received token
  function exactInput(ExactInputParams calldata params)
    external
    payable
    returns (uint256 amountOut);

  struct ExactOutputSingleParams {
    address tokenIn;
    address tokenOut;
    uint24 fee;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 sqrtPriceLimitX96;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another token
  /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutputSingle(ExactOutputSingleParams calldata params)
    external
    payable
    returns (uint256 amountIn);

  struct ExactOutputParams {
    bytes path;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
  }

  /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
  /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
  /// @return amountIn The amount of the input token
  function exactOutput(ExactOutputParams calldata params)
    external
    payable
    returns (uint256 amountIn);
}

// SPDX-License-Identifier: agpl-3.0
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';

interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public payable virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public payable virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {Errors} from '../helpers/Errors.sol';

/**
 * @title PercentageMath library
 * @author Sturdy, inspiration from Aave
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
  uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
  uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;

  /**
   * @dev Executes a percentage multiplication
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The percentage of value
   **/
  function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256) {
    if (value == 0 || percentage == 0) {
      return 0;
    }

    return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
  }

  /**
   * @dev Executes a percentage division
   * @param value The value of which the percentage needs to be calculated
   * @param percentage The percentage of the value to be calculated
   * @return The value divided the percentage
   **/
  function percentDiv(uint256 value, uint256 percentage) internal pure returns (uint256) {
    uint256 halfPercentage = percentage / 2;

    return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from './IERC20.sol';
import {Address} from './Address.sol';

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
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import '../../../dependencies/openzeppelin/contracts/IERC20.sol';

library TransferHelper {
  /// @notice Transfers tokens from the targeted address to the given destination
  /// @notice Errors with 'STF' if transfer fails
  /// @param token The contract address of the token to be transferred
  /// @param from The originating address from which the tokens will be transferred
  /// @param to The destination address of the transfer
  /// @param value The amount to be transferred
  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
  }

  /// @notice Transfers tokens from msg.sender to a recipient
  /// @dev Errors with ST if transfer fails
  /// @param token The contract address of the token which will be transferred
  /// @param to The recipient of the transfer
  /// @param value The value of the transfer
  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(IERC20.transfer.selector, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
  }

  /// @notice Approves the stipulated contract to spend the given allowance in the given token
  /// @dev Errors with 'SA' if transfer fails
  /// @param token The contract address of the token to be approved
  /// @param to The target of the approval
  /// @param value The amount of the given token the target will be allowed to spend
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    (bool success, bytes memory data) = token.call(
      abi.encodeWithSelector(IERC20.approve.selector, to, value)
    );
    require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
  }

  /// @notice Transfers ETH to the recipient address
  /// @dev Fails with `STE`
  /// @param to The destination of the transfer
  /// @param value The value to be transferred
  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'STE');
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20Detailed} from '../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {ISwapRouter} from '../../../interfaces/ISwapRouter.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {ILendingPoolAddressesProvider} from '../../../interfaces/ILendingPoolAddressesProvider.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {PercentageMath} from '../../libraries/math/PercentageMath.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';

library UniswapAdapter {
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;

  struct Path {
    address[] tokens;
    uint256[] fees;
  }

  function swapExactTokensForTokens(
    ILendingPoolAddressesProvider addressesProvider,
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    Path calldata path,
    uint256 slippage // 2% = 200
  ) external returns (uint256) {
    // Check path is valid
    uint256 length = path.tokens.length;
    require(length > 1 && length - 1 == path.fees.length, Errors.VT_SWAP_PATH_LENGTH_INVALID);
    require(
      path.tokens[0] == assetToSwapFrom && path.tokens[length - 1] == assetToSwapTo,
      Errors.VT_SWAP_PATH_TOKEN_INVALID
    );

    // Calculate expected amount of the outbound asset
    uint256 minAmountOut = _getMinAmount(
      addressesProvider,
      assetToSwapFrom,
      assetToSwapTo,
      amountToSwap,
      slippage
    );

    // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    address UNISWAP_ROUTER = addressesProvider.getAddress('uniswapRouter');
    IERC20(assetToSwapFrom).safeApprove(address(UNISWAP_ROUTER), 0);
    IERC20(assetToSwapFrom).safeApprove(address(UNISWAP_ROUTER), amountToSwap);

    uint256 receivedAmount;
    if (length > 2) {
      bytes memory _path;

      for (uint256 i; i < length - 1; ++i) {
        _path = abi.encodePacked(_path, path.tokens[i], uint24(path.fees[i]));
      }
      _path = abi.encodePacked(_path, assetToSwapTo);

      ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
        path: _path,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amountToSwap,
        amountOutMinimum: minAmountOut
      });

      // Executes the swap.
      receivedAmount = ISwapRouter(UNISWAP_ROUTER).exactInput(params);
    } else {
      ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
        tokenIn: assetToSwapFrom,
        tokenOut: assetToSwapTo,
        fee: uint24(path.fees[0]),
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: amountToSwap,
        amountOutMinimum: minAmountOut,
        sqrtPriceLimitX96: 0
      });

      // Executes the swap.
      receivedAmount = ISwapRouter(UNISWAP_ROUTER).exactInputSingle(params);
    }

    require(receivedAmount > 0, Errors.VT_SWAP_MISMATCH_RETURNED_AMOUNT);
    require(
      IERC20(assetToSwapTo).balanceOf(address(this)) >= receivedAmount,
      Errors.VT_SWAP_MISMATCH_RETURNED_AMOUNT
    );

    return receivedAmount;
  }

  function _getDecimals(address asset) internal view returns (uint256) {
    return IERC20Detailed(asset).decimals();
  }

  function _getPrice(ILendingPoolAddressesProvider addressesProvider, address asset)
    internal
    view
    returns (uint256)
  {
    return IPriceOracleGetter(addressesProvider.getPriceOracle()).getAssetPrice(asset);
  }

  function _getMinAmount(
    ILendingPoolAddressesProvider addressesProvider,
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    uint256 slippage
  ) internal view returns (uint256) {
    uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
    uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

    uint256 fromAssetPrice = _getPrice(addressesProvider, assetToSwapFrom);
    uint256 toAssetPrice = _getPrice(addressesProvider, assetToSwapTo);

    uint256 minAmountOut = ((amountToSwap * fromAssetPrice * 10**toAssetDecimals) /
      (toAssetPrice * 10**fromAssetDecimals)).percentMul(
        PercentageMath.PERCENTAGE_FACTOR - slippage
      );

    return minAmountOut;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {IERC20Detailed} from '../../../dependencies/openzeppelin/contracts/IERC20Detailed.sol';
import {IERC20} from '../../../dependencies/openzeppelin/contracts/IERC20.sol';
import {IPriceOracleGetter} from '../../../interfaces/IPriceOracleGetter.sol';
import {ICurveAddressProvider} from '../../../interfaces/ICurveAddressProvider.sol';
import {ICurveExchange} from '../../../interfaces/ICurveExchange.sol';
import {ILendingPoolAddressesProvider} from '../../../interfaces/ILendingPoolAddressesProvider.sol';
import {SafeERC20} from '../../../dependencies/openzeppelin/contracts/SafeERC20.sol';
import {PercentageMath} from '../../libraries/math/PercentageMath.sol';
import {Errors} from '../../libraries/helpers/Errors.sol';

library CurveswapAdapter {
  using PercentageMath for uint256;
  using SafeERC20 for IERC20;

  address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  function swapExactTokensForTokens(
    ILendingPoolAddressesProvider addressesProvider,
    address poolAddress,
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    uint256 slippage // 2% = 200
  ) external returns (uint256) {
    uint256 minAmountOut = _getMinAmount(
      addressesProvider,
      assetToSwapFrom,
      assetToSwapTo,
      amountToSwap,
      slippage
    );

    // Approves the transfer for the swap. Approves for 0 first to comply with tokens that implement the anti frontrunning approval fix.
    address curveAddressProvider = addressesProvider.getAddress('CURVE_ADDRESS_PROVIDER');
    address curveExchange = ICurveAddressProvider(curveAddressProvider).get_address(2);

    IERC20(assetToSwapFrom).safeApprove(address(curveExchange), 0);
    IERC20(assetToSwapFrom).safeApprove(address(curveExchange), amountToSwap);

    uint256 receivedAmount = ICurveExchange(curveExchange).exchange(
      poolAddress,
      assetToSwapFrom,
      assetToSwapTo,
      amountToSwap,
      minAmountOut,
      address(this)
    );

    require(receivedAmount > 0, Errors.VT_SWAP_MISMATCH_RETURNED_AMOUNT);
    uint256 balanceOfAsset;
    if (assetToSwapTo == ETH) {
      balanceOfAsset = address(this).balance;
    } else {
      balanceOfAsset = IERC20(assetToSwapTo).balanceOf(address(this));
    }
    require(balanceOfAsset >= receivedAmount, Errors.VT_SWAP_MISMATCH_RETURNED_AMOUNT);
    return receivedAmount;
  }

  function _getDecimals(address asset) internal view returns (uint256) {
    if (asset == ETH) {
      return 18;
    }
    return IERC20Detailed(asset).decimals();
  }

  function _getPrice(ILendingPoolAddressesProvider addressesProvider, address asset)
    internal
    view
    returns (uint256)
  {
    if (asset == ETH) {
      return 1e18;
    }
    return IPriceOracleGetter(addressesProvider.getPriceOracle()).getAssetPrice(asset);
  }

  function _getMinAmount(
    ILendingPoolAddressesProvider addressesProvider,
    address assetToSwapFrom,
    address assetToSwapTo,
    uint256 amountToSwap,
    uint256 slippage
  ) internal view returns (uint256) {
    uint256 fromAssetDecimals = _getDecimals(assetToSwapFrom);
    uint256 toAssetDecimals = _getDecimals(assetToSwapTo);

    uint256 fromAssetPrice = _getPrice(addressesProvider, assetToSwapFrom);
    uint256 toAssetPrice = _getPrice(addressesProvider, assetToSwapTo);

    uint256 minAmountOut = ((amountToSwap * fromAssetPrice * 10**toAssetDecimals) /
      (toAssetPrice * 10**fromAssetDecimals)).percentMul(
        PercentageMath.PERCENTAGE_FACTOR - slippage
      );

    return minAmountOut;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //address of the yield contract
    address yieldAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct UserConfigurationMap {
    uint256 data;
  }

  enum InterestRateMode {
    NONE,
    STABLE,
    VARIABLE
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
  /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
  /// @dev In the implementation you must pay the pool tokens owed for the swap.
  /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
  /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
  /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
  /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
  /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
  /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
  function uniswapV3SwapCallback(
    int256 amount0Delta,
    int256 amount1Delta,
    bytes calldata data
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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

// SPDX-License-Identifier: agpl-3.0
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
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'Address: unable to send value, recipient may have reverted');
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title ICurveAddressProvider interface
 * @notice Interface for the Curve Address Provider.
 **/

interface ICurveAddressProvider {
  function get_address(uint256 id) external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface ICurveExchange {
  function exchange(
    address _pool,
    address _from,
    address _to,
    uint256 _amount,
    uint256 _expected,
    address _receiver
  ) external payable returns (uint256);
}