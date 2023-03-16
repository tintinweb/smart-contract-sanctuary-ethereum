// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== Timelock2Step ===========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

/// @title Timelock2Step
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @dev Inspired by the OpenZeppelin's Ownable2Step contract
/// @notice  An abstract contract which contains 2-step transfer and renounce logic for a timelock address
abstract contract Timelock2Step {
    /// @notice The pending timelock address
    address public pendingTimelockAddress;

    /// @notice The current timelock address
    address public timelockAddress;

    constructor() {
        timelockAddress = msg.sender;
    }

    /// @notice Emitted when timelock is transferred
    error OnlyTimelock();

    /// @notice Emitted when pending timelock is transferred
    error OnlyPendingTimelock();

    /// @notice The ```TimelockTransferStarted``` event is emitted when the timelock transfer is initiated
    /// @param previousTimelock The address of the previous timelock
    /// @param newTimelock The address of the new timelock
    event TimelockTransferStarted(address indexed previousTimelock, address indexed newTimelock);

    /// @notice The ```TimelockTransferred``` event is emitted when the timelock transfer is completed
    /// @param previousTimelock The address of the previous timelock
    /// @param newTimelock The address of the new timelock
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);

    /// @notice The ```_isSenderTimelock``` function checks if msg.sender is current timelock address
    /// @return Whether or not msg.sender is current timelock address
    function _isSenderTimelock() internal view returns (bool) {
        return msg.sender == timelockAddress;
    }

    /// @notice The ```_requireTimelock``` function reverts if msg.sender is not current timelock address
    function _requireTimelock() internal view {
        if (msg.sender != timelockAddress) revert OnlyTimelock();
    }

    /// @notice The ```_isSenderPendingTimelock``` function checks if msg.sender is pending timelock address
    /// @return Whether or not msg.sender is pending timelock address
    function _isSenderPendingTimelock() internal view returns (bool) {
        return msg.sender == pendingTimelockAddress;
    }

    /// @notice The ```_requirePendingTimelock``` function reverts if msg.sender is not pending timelock address
    function _requirePendingTimelock() internal view {
        if (msg.sender != pendingTimelockAddress) revert OnlyPendingTimelock();
    }

    /// @notice The ```_transferTimelock``` function initiates the timelock transfer
    /// @dev This function is to be implemented by a public function
    /// @param _newTimelock The address of the nominated (pending) timelock
    function _transferTimelock(address _newTimelock) internal {
        pendingTimelockAddress = _newTimelock;
        emit TimelockTransferStarted(timelockAddress, _newTimelock);
    }

    /// @notice The ```_acceptTransferTimelock``` function completes the timelock transfer
    /// @dev This function is to be implemented by a public function
    function _acceptTransferTimelock() internal {
        pendingTimelockAddress = address(0);
        _setTimelock(msg.sender);
    }

    /// @notice The ```_setTimelock``` function sets the timelock address
    /// @dev This function is to be implemented by a public function
    /// @param _newTimelock The address of the new timelock
    function _setTimelock(address _newTimelock) internal {
        emit TimelockTransferred(timelockAddress, _newTimelock);
        timelockAddress = _newTimelock;
    }

    /// @notice The ```transferTimelock``` function initiates the timelock transfer
    /// @dev Must be called by the current timelock
    /// @param _newTimelock The address of the nominated (pending) timelock
    function transferTimelock(address _newTimelock) external virtual {
        _requireTimelock();
        _transferTimelock(_newTimelock);
    }

    /// @notice The ```acceptTransferTimelock``` function completes the timelock transfer
    /// @dev Must be called by the pending timelock
    function acceptTransferTimelock() external virtual {
        _requirePendingTimelock();
        _acceptTransferTimelock();
    }

    /// @notice The ```renounceTimelock``` function renounces the timelock after setting pending timelock to current timelock
    /// @dev Pending timelock must be set to current timelock before renouncing, creating a 2-step renounce process
    function renounceTimelock() external virtual {
        _requireTimelock();
        _requirePendingTimelock();
        _transferTimelock(address(0));
        _setTimelock(address(0));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

interface ITimelock2Step {
    event TimelockTransferStarted(address indexed previousTimelock, address indexed newTimelock);
    event TimelockTransferred(address indexed previousTimelock, address indexed newTimelock);

    function acceptTransferTimelock() external;

    function pendingTimelockAddress() external view returns (address);

    function renounceTimelock() external;

    function timelockAddress() external view returns (address);

    function transferTimelock(address _newTimelock) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.7.6 <0.9.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

/// @title Uniswap V3 Static Oracle
/// @notice Oracle contract for calculating price quoting against Uniswap V3
interface IStaticOracle {
  /// @notice Returns the address of the Uniswap V3 factory
  /// @dev This value is assigned during deployment and cannot be changed
  /// @return The address of the Uniswap V3 factory
  function UNISWAP_V3_FACTORY() external view returns (IUniswapV3Factory);

  /// @notice Returns how many observations are needed per minute in Uniswap V3 oracles, on the deployed chain
  /// @dev This value is assigned during deployment and cannot be changed
  /// @return Number of observation that are needed per minute
  function CARDINALITY_PER_MINUTE() external view returns (uint8);

  /// @notice Returns all supported fee tiers
  /// @return The supported fee tiers
  function supportedFeeTiers() external view returns (uint24[] memory);

  /// @notice Returns whether a specific pair can be supported by the oracle
  /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
  /// @return Whether the given pair can be supported by the oracle
  function isPairSupported(address tokenA, address tokenB) external view returns (bool);

  /// @notice Returns all existing pools for the given pair
  /// @dev The pair can be provided in tokenA/tokenB or tokenB/tokenA order
  /// @return All existing pools for the given pair
  function getAllPoolsForPair(address tokenA, address tokenB) external view returns (address[] memory);

  /// @notice Returns a quote, based on the given tokens and amount, by querying all of the pair's pools
  /// @dev If some pools are not configured correctly for the given period, then they will be ignored
  /// @dev Will revert if there are no pools available/configured for the pair and period combination
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  /// @return queriedPools The pools that were queried to calculate the quote
  function quoteAllAvailablePoolsWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint32 period
  ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

  /// @notice Returns a quote, based on the given tokens and amount, by querying only the specified fee tiers
  /// @dev Will revert if the pair does not have a pool for one of the given fee tiers, or if one of the pools
  /// is not prepared/configured correctly for the given period
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param feeTiers The fee tiers to consider when calculating the quote
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  /// @return queriedPools The pools that were queried to calculate the quote
  function quoteSpecificFeeTiersWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    uint24[] calldata feeTiers,
    uint32 period
  ) external view returns (uint256 quoteAmount, address[] memory queriedPools);

  /// @notice Returns a quote, based on the given tokens and amount, by querying only the specified pools
  /// @dev Will revert if one of the pools is not prepared/configured correctly for the given period
  /// @param baseAmount Amount of token to be converted
  /// @param baseToken Address of an ERC20 token contract used as the baseAmount denomination
  /// @param quoteToken Address of an ERC20 token contract used as the quoteAmount denomination
  /// @param pools The pools to consider when calculating the quote
  /// @param period Number of seconds from which to calculate the TWAP
  /// @return quoteAmount Amount of quoteToken received for baseAmount of baseToken
  function quoteSpecificPoolsWithTimePeriod(
    uint128 baseAmount,
    address baseToken,
    address quoteToken,
    address[] calldata pools,
    uint32 period
  ) external view returns (uint256 quoteAmount);

  /// @notice Will initialize all existing pools for the given pair, so that they can be queried with the given period in the future
  /// @dev Will revert if there are no pools available for the pair and period combination
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param period The period that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareAllAvailablePoolsWithTimePeriod(
    address tokenA,
    address tokenB,
    uint32 period
  ) external returns (address[] memory preparedPools);

  /// @notice Will initialize the pair's pools with the specified fee tiers, so that they can be queried with the given period in the future
  /// @dev Will revert if the pair does not have a pool for a given fee tier
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param feeTiers The fee tiers to consider when searching for the pair's pools
  /// @param period The period that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareSpecificFeeTiersWithTimePeriod(
    address tokenA,
    address tokenB,
    uint24[] calldata feeTiers,
    uint32 period
  ) external returns (address[] memory preparedPools);

  /// @notice Will initialize all given pools, so that they can be queried with the given period in the future
  /// @param pools The pools to initialize
  /// @param period The period that will be guaranteed when quoting
  function prepareSpecificPoolsWithTimePeriod(address[] calldata pools, uint32 period) external;

  /// @notice Will increase observations for all existing pools for the given pair, so they start accruing information for twap calculations
  /// @dev Will revert if there are no pools available for the pair and period combination
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param cardinality The cardinality that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareAllAvailablePoolsWithCardinality(
    address tokenA,
    address tokenB,
    uint16 cardinality
  ) external returns (address[] memory preparedPools);

  /// @notice Will increase the pair's pools with the specified fee tiers observations, so they start accruing information for twap calculations
  /// @dev Will revert if the pair does not have a pool for a given fee tier
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  /// @param feeTiers The fee tiers to consider when searching for the pair's pools
  /// @param cardinality The cardinality that will be guaranteed when quoting
  /// @return preparedPools The pools that were prepared
  function prepareSpecificFeeTiersWithCardinality(
    address tokenA,
    address tokenB,
    uint24[] calldata feeTiers,
    uint16 cardinality
  ) external returns (address[] memory preparedPools);

  /// @notice Will increase all given pools observations, so they start accruing information for twap calculations
  /// @param pools The pools to initialize
  /// @param cardinality The cardinality that will be guaranteed when quoting
  function prepareSpecificPoolsWithCardinality(address[] calldata pools, uint16 cardinality) external;

  /// @notice Adds support for a new fee tier
  /// @dev Will revert if the given tier is invalid, or already supported
  /// @param feeTier The new fee tier to add
  function addNewFeeTier(uint24 feeTier) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IDualOracle is IERC165 {
    function ORACLE_PRECISION() external view returns (uint256);

    function BASE_TOKEN_0() external view returns (address);

    function BASE_TOKEN_0_DECIMALS() external view returns (uint256);

    function BASE_TOKEN_1() external view returns (address);

    function BASE_TOKEN_1_DECIMALS() external view returns (uint256);

    function decimals() external view returns (uint8);

    function getPricesNormalized() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh);

    function name() external view returns (string memory);

    function NORMALIZATION_0() external view returns (int256);

    function NORMALIZATION_1() external view returns (int256);

    function QUOTE_TOKEN_0() external view returns (address);

    function QUOTE_TOKEN_0_DECIMALS() external view returns (uint256);

    function QUOTE_TOKEN_1() external view returns (address);

    function QUOTE_TOKEN_1_DECIMALS() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IChainlinkOracleWithMaxDelay is IERC165 {
    event SetMaximumOracleDelay(address oracle, uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    function CHAINLINK_FEED_ADDRESS() external view returns (address);

    function CHAINLINK_FEED_DECIMALS() external view returns (uint8);

    function CHAINLINK_FEED_PRECISION() external view returns (uint256);

    function getChainlinkPrice() external view returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth);

    function maximumOracleDelay() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IEthUsdChainlinkOracleWithMaxDelay is IERC165 {
    event SetMaximumEthUsdOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    function ETH_USD_CHAINLINK_FEED_ADDRESS() external view returns (address);

    function ETH_USD_CHAINLINK_FEED_DECIMALS() external view returns (uint8);

    function ETH_USD_CHAINLINK_FEED_PRECISION() external view returns (uint256);

    function maximumEthUsdOracleDelay() external view returns (uint256);

    function getEthUsdChainlinkPrice() external view returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IUniswapV3SingleTwapOracle is IERC165 {
    event SetTwapDuration(uint256 oldTwapDuration, uint256 newTwapDuration);

    function UNISWAP_V3_TWAP_BASE_TOKEN() external view returns (address);

    function UNISWAP_V3_TWAP_QUOTE_TOKEN() external view returns (address);

    function TWAP_PRECISION() external view returns (uint128);

    function UNI_V3_PAIR_ADDRESS() external view returns (address);

    function getUniswapV3Twap() external view returns (uint256 _twap);

    function twapDuration() external view returns (uint32);
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================== DualOracleBase ==========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// ====================================================================

import "../../interfaces/IDualOracle.sol";

struct ConstructorParams {
    address baseToken0;
    uint8 baseToken0Decimals;
    address quoteToken0;
    uint8 quoteToken0Decimals;
    address baseToken1;
    uint8 baseToken1Decimals;
    address quoteToken1;
    uint8 quoteToken1Decimals;
}

/// @title DualOracleBase
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  Base Contract for Frax Dual Oracles
abstract contract DualOracleBase is IDualOracle {
    /// @notice The precision of the oracle
    uint256 public constant ORACLE_PRECISION = 1e18;

    /// @notice The first quote token
    address public immutable QUOTE_TOKEN_0;

    /// @notice The first quote token decimals
    uint256 public immutable QUOTE_TOKEN_0_DECIMALS;

    /// @notice The second quote token
    address public immutable QUOTE_TOKEN_1;

    /// @notice The second quote token decimals
    uint256 public immutable QUOTE_TOKEN_1_DECIMALS;

    /// @notice The first base token
    address public immutable BASE_TOKEN_0;

    /// @notice The first base token decimals
    uint256 public immutable BASE_TOKEN_0_DECIMALS;

    /// @notice The second base token
    address public immutable BASE_TOKEN_1;

    /// @notice The second base token decimals
    uint256 public immutable BASE_TOKEN_1_DECIMALS;

    /// @notice The first normalization factor which accounts for different decimals across ERC20s
    /// @dev Normalization = quoteTokenDecimals - baseTokenDecimals
    int256 public immutable NORMALIZATION_0;

    /// @notice The second normalization factor which accounts for different decimals across ERC20s
    /// @dev Normalization = quoteTokenDecimals - baseTokenDecimals
    int256 public immutable NORMALIZATION_1;

    constructor(ConstructorParams memory _params) {
        QUOTE_TOKEN_0 = _params.quoteToken0;
        QUOTE_TOKEN_0_DECIMALS = _params.quoteToken0Decimals;
        QUOTE_TOKEN_1 = _params.quoteToken1;
        QUOTE_TOKEN_1_DECIMALS = _params.quoteToken1Decimals;
        BASE_TOKEN_0 = _params.baseToken0;
        BASE_TOKEN_0_DECIMALS = _params.baseToken0Decimals;
        BASE_TOKEN_1 = _params.baseToken1;
        BASE_TOKEN_1_DECIMALS = _params.baseToken1Decimals;
        NORMALIZATION_0 = int256(QUOTE_TOKEN_0_DECIMALS) - int256(BASE_TOKEN_0_DECIMALS);
        NORMALIZATION_1 = int256(QUOTE_TOKEN_1_DECIMALS) - int256(BASE_TOKEN_1_DECIMALS);
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    function decimals() external pure returns (uint8) {
        return 18;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ======================== UniswapDualOracle =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// ====================================================================

import { Timelock2Step } from "frax-std/access-control/Timelock2Step.sol";
import { ITimelock2Step } from "frax-std/access-control/interfaces/ITimelock2Step.sol";
import {
    UniswapV3SingleTwapOracle,
    ConstructorParams as UniswapV3SingleTwapOracleParams
} from "./abstracts/UniswapV3SingleTwapOracle.sol";
import {
    ChainlinkOracleWithMaxDelay,
    ConstructorParams as ChainlinkOracleWithMaxDelayParams
} from "./abstracts/ChainlinkOracleWithMaxDelay.sol";
import {
    EthUsdChainlinkOracleWithMaxDelay,
    ConstructorParams as EthUsdChainlinkOracleWithMaxDelayParams
} from "./abstracts/EthUsdChainlinkOracleWithMaxDelay.sol";
import { DualOracleBase, ConstructorParams as DualOracleBaseParams } from "./DualOracleBase.sol";
import "../../interfaces/IDualOracle.sol";

struct ConstructorParams {
    address uniErc20;
    address wethErc20;
    address uniUsdChainlinkFeed;
    uint256 maximumOracleDelay;
    address ethUsdChainlinkFeed;
    uint256 maxEthUsdOracleDelay;
    address uniV3PairAddress;
    uint32 twapDuration;
    address timelockAddress;
}

/// @title UniswapDualOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for Uniswap in Frax units
contract UniswapDualOracle is
    DualOracleBase,
    Timelock2Step,
    UniswapV3SingleTwapOracle,
    ChainlinkOracleWithMaxDelay,
    EthUsdChainlinkOracleWithMaxDelay
{
    address public immutable UNI_ERC20;

    constructor(
        ConstructorParams memory _params
    )
        DualOracleBase(
            DualOracleBaseParams({
                baseToken0: address(840),
                baseToken0Decimals: 18,
                quoteToken0: _params.uniErc20,
                quoteToken0Decimals: 18,
                baseToken1: _params.uniErc20,
                baseToken1Decimals: 18,
                quoteToken1: address(840),
                quoteToken1Decimals: 18
            })
        )
        Timelock2Step()
        UniswapV3SingleTwapOracle(
            UniswapV3SingleTwapOracleParams({
                uniswapV3PairAddress: _params.uniV3PairAddress,
                twapDuration: _params.twapDuration,
                baseToken: _params.wethErc20,
                quoteToken: _params.uniErc20
            })
        )
        ChainlinkOracleWithMaxDelay(
            ChainlinkOracleWithMaxDelayParams({
                chainlinkFeedAddress: _params.uniUsdChainlinkFeed,
                maximumOracleDelay: _params.maximumOracleDelay
            })
        )
        EthUsdChainlinkOracleWithMaxDelay(
            EthUsdChainlinkOracleWithMaxDelayParams({
                ethUsdChainlinkFeedAddress: _params.ethUsdChainlinkFeed,
                maxEthUsdOracleDelay: _params.maxEthUsdOracleDelay
            })
        )
    {
        _setTimelock({ _newTimelock: _params.timelockAddress });
        _registerInterface({ interfaceId: type(IDualOracle).interfaceId });
        _registerInterface({ interfaceId: type(ITimelock2Step).interfaceId });

        UNI_ERC20 = _params.uniErc20;
    }

    // ====================================================================
    // View Helpers
    // ====================================================================

    function name() external pure returns (string memory) {
        return "Uniswap Dual Oracle Chainlink with Staleness Check and Uniswap V3 TWAP";
    }

    // ====================================================================
    // Configuration Setters
    // ====================================================================

    /// @notice The ```setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    /// @notice The ```setMaximumEthUsdOracleDelay``` function set the max oracle delay for the Eth/USD Chainlink oracle
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newMaxOracleDelay The new max oracle delay
    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external override {
        _requireTimelock();
        _setMaximumEthUsdOracleDelay({ _newMaxOracleDelay: _newMaxOracleDelay });
    }

    /// @notice The ```setTwapDuration``` function sets the twap duration for the Uniswap V3 TWAP oracle
    /// @dev Requires msg.sender to be the timelock address
    /// @param _newTwapDuration The new twap duration
    function setTwapDuration(uint32 _newTwapDuration) external override {
        _requireTimelock();
        _setTwapDuration({ _newTwapDuration: _newTwapDuration });
    }

    // ====================================================================
    // Price Functions
    // ====================================================================

    /// @notice The ```getMkrPerUsdTwap``` function returns Mkr per USD using the Uniswap V3 TWAP oracle & Chainlink
    /// @return _isBadData If the Chainlink oracle is stale
    /// @return _uniPerUsd The Mkr per USD price
    function getMkrPerUsdTwap() public view returns (bool _isBadData, uint256 _uniPerUsd) {
        uint256 _uniPerWeth = _getUniswapV3Twap();
        uint256 _usdPerEth;
        (_isBadData, , _usdPerEth) = _getEthUsdChainlinkPrice();
        _uniPerUsd = (_uniPerWeth * ETH_USD_CHAINLINK_FEED_PRECISION) / _usdPerEth;
    }

    /// @notice The ```getMkrPerUsdChainlink``` function returns Mkr per USD using the Chainlink oracle
    /// @return _isBadData If the Chainlink oracle is stale
    /// @return _uniPerUsd The Mkr per USD price
    function getMkrPerUsdChainlink() public view returns (bool _isBadData, uint256 _uniPerUsd) {
        uint256 _usdPerMkrChainlinkRaw;
        (_isBadData, , _usdPerMkrChainlinkRaw) = _getChainlinkPrice();
        _uniPerUsd = (ORACLE_PRECISION * CHAINLINK_FEED_PRECISION) / _usdPerMkrChainlinkRaw;
    }

    /// @notice The ```getPricesNormalized``` function returns the normalized prices in human readable form
    /// @return _isBadDataNormal If the Chainlink oracle is stale
    /// @return _priceLowNormal The normalized low price
    /// @return _priceHighNormal The normalized high price
    function getPricesNormalized()
        external
        view
        returns (bool _isBadDataNormal, uint256 _priceLowNormal, uint256 _priceHighNormal)
    {
        (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) = _getPrices();
        _isBadDataNormal = _isBadData;

        _priceLowNormal = NORMALIZATION_0 > 0
            ? _priceLow * 10 ** uint256(NORMALIZATION_0)
            : _priceLow / 10 ** (uint256(-NORMALIZATION_0));

        _priceHighNormal = NORMALIZATION_1 > 0
            ? _priceHigh * 10 ** uint256(NORMALIZATION_1)
            : _priceHigh / 10 ** (uint256(-NORMALIZATION_1));
    }

    function _getPrices() internal view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        (bool _isBadDataChainlink, uint256 _uniPerUsdChainlink) = getMkrPerUsdChainlink();

        (bool _isBadDataTwap, uint256 _uniPerUsdTwap) = getMkrPerUsdTwap();
        if (_isBadDataChainlink && _isBadDataTwap) {
            revert("Both Chainlink and TWAP are bad");
        }

        _isBadData = _isBadDataChainlink || _isBadDataTwap;
        _priceLow = _uniPerUsdTwap < _uniPerUsdChainlink ? _uniPerUsdTwap : _uniPerUsdChainlink;
        _priceHigh = _uniPerUsdChainlink > _uniPerUsdTwap ? _uniPerUsdChainlink : _uniPerUsdTwap;
    }

    /// @notice The ```getPrices``` function is intended to return two prices from different oracles
    /// @return _isBadData is true when data is stale or otherwise bad
    /// @return _priceLow is the lower of the two prices
    /// @return _priceHigh is the higher of the two prices
    function getPrices() external view returns (bool _isBadData, uint256 _priceLow, uint256 _priceHigh) {
        return _getPrices();
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// =================== ChainlinkOracleWithMaxDelay ====================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../../../interfaces/oracles/abstracts/IChainlinkOracleWithMaxDelay.sol";

struct ConstructorParams {
    address chainlinkFeedAddress;
    uint256 maximumOracleDelay;
}

/// @title ChainlinkOracleWithMaxDelay
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract oracle for getting prices from Chainlink
abstract contract ChainlinkOracleWithMaxDelay is ERC165Storage, IChainlinkOracleWithMaxDelay {
    /// @notice Chainlink aggregator
    address public immutable CHAINLINK_FEED_ADDRESS;

    /// @notice Decimals of ETH/USD chainlink feed
    uint8 public immutable CHAINLINK_FEED_DECIMALS;

    /// @notice Precision of ETH/USD chainlink feed
    uint256 public immutable CHAINLINK_FEED_PRECISION;

    /// @notice Maximum delay of Chainlink data, after which it is considered stale
    uint256 public maximumOracleDelay;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IChainlinkOracleWithMaxDelay).interfaceId });

        CHAINLINK_FEED_ADDRESS = _params.chainlinkFeedAddress;
        CHAINLINK_FEED_DECIMALS = AggregatorV3Interface(CHAINLINK_FEED_ADDRESS).decimals();
        CHAINLINK_FEED_PRECISION = 10 ** uint256(CHAINLINK_FEED_DECIMALS);
        maximumOracleDelay = _params.maximumOracleDelay;
    }

    /// @notice The ```SetMaximumOracleDelay``` event is emitted when the max oracle delay is set
    /// @param oldMaxOracleDelay The old max oracle delay
    /// @param newMaxOracleDelay The new max oracle delay
    event SetMaximumOracleDelay(uint256 oldMaxOracleDelay, uint256 newMaxOracleDelay);

    /// @notice The ```_setMaximumOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @param _newMaxOracleDelay The new max oracle delay
    function _setMaximumOracleDelay(uint256 _newMaxOracleDelay) internal {
        emit SetMaximumOracleDelay({ oldMaxOracleDelay: maximumOracleDelay, newMaxOracleDelay: _newMaxOracleDelay });
        maximumOracleDelay = _newMaxOracleDelay;
    }

    function setMaximumOracleDelay(uint256 _newMaxOracleDelay) external virtual;

    function _getChainlinkPrice() internal view returns (bool _isBadData, uint256 _updatedAt, uint256 _price) {
        int256 _answer;
        (, _answer, , _updatedAt, ) = AggregatorV3Interface(CHAINLINK_FEED_ADDRESS).latestRoundData();

        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > maximumOracleDelay)) {
            _isBadData = true;
        }

        _price = uint256(_answer);
    }

    /// @notice The ```getChainlinkPrice``` function returns the chainlink price and the timestamp of the last update
    /// @dev Uses the same prevision as the chainlink feed, virtual so it can be overridden
    /// @return _isBadData True if the data is stale or negative
    /// @return _updatedAt The timestamp of the last update
    /// @return _price The price
    function getChainlinkPrice() external view virtual returns (bool _isBadData, uint256 _updatedAt, uint256 _price) {
        return _getChainlinkPrice();
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ================ EthUsdChainlinkOracleWithMaxDelay =================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "../../../interfaces/oracles/abstracts/IEthUsdChainlinkOracleWithMaxDelay.sol";

struct ConstructorParams {
    address ethUsdChainlinkFeedAddress;
    uint256 maxEthUsdOracleDelay;
}

/// @title EthUsdChainlinkOracleWithMaxDelay
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An abstract oracle for getting eth/usd prices from Chainlink
abstract contract EthUsdChainlinkOracleWithMaxDelay is ERC165Storage, IEthUsdChainlinkOracleWithMaxDelay {
    /// @notice Chainlink aggregator
    address public immutable ETH_USD_CHAINLINK_FEED_ADDRESS;

    /// @notice Decimals of ETH/USD chainlink feed
    uint8 public immutable ETH_USD_CHAINLINK_FEED_DECIMALS;

    /// @notice Precision of ETH/USD chainlink feed
    uint256 public immutable ETH_USD_CHAINLINK_FEED_PRECISION;

    /// @notice Maximum delay of Chainlink data, after which it is considered stale
    uint256 public maximumEthUsdOracleDelay;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IEthUsdChainlinkOracleWithMaxDelay).interfaceId });

        ETH_USD_CHAINLINK_FEED_ADDRESS = _params.ethUsdChainlinkFeedAddress;
        ETH_USD_CHAINLINK_FEED_DECIMALS = AggregatorV3Interface(ETH_USD_CHAINLINK_FEED_ADDRESS).decimals();
        ETH_USD_CHAINLINK_FEED_PRECISION = 10 ** uint256(ETH_USD_CHAINLINK_FEED_DECIMALS);
        maximumEthUsdOracleDelay = _params.maxEthUsdOracleDelay;
    }

    /// @notice The ```_setMaximumEthUsdOracleDelay``` function sets the max oracle delay to determine if Chainlink data is stale
    /// @param _newMaxOracleDelay The new max oracle delay
    function _setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) internal {
        emit SetMaximumEthUsdOracleDelay({
            oldMaxOracleDelay: maximumEthUsdOracleDelay,
            newMaxOracleDelay: _newMaxOracleDelay
        });
        maximumEthUsdOracleDelay = _newMaxOracleDelay;
    }

    function setMaximumEthUsdOracleDelay(uint256 _newMaxOracleDelay) external virtual;

    /// @notice The ```_getEthUsdChainlinkPrice``` function is called to get the eth/usd price from Chainlink
    /// @dev If data is stale or negative, set bad data to true and return
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerEth The eth/usd price
    function _getEthUsdChainlinkPrice()
        internal
        view
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth)
    {
        int256 _answer;
        (, _answer, , _updatedAt, ) = AggregatorV3Interface(ETH_USD_CHAINLINK_FEED_ADDRESS).latestRoundData();

        // If data is stale or negative, set bad data to true and return
        if (_answer <= 0 || (block.timestamp - _updatedAt > maximumEthUsdOracleDelay)) {
            _isBadData = true;
        }

        _usdPerEth = uint256(_answer);
    }

    /// @notice The ```getEthUsdChainlinkPrice``` function is called to get the eth/usd price from Chainlink
    /// @return _isBadData If the data is stale
    /// @return _updatedAt The timestamp of the last update
    /// @return _usdPerEth The eth/usd price
    function getEthUsdChainlinkPrice()
        external
        view
        virtual
        returns (bool _isBadData, uint256 _updatedAt, uint256 _usdPerEth)
    {
        return _getEthUsdChainlinkPrice();
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ==================== UniswapV3SingleTwapOracle =====================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Author
// Drake Evans: https://github.com/DrakeEvans

// Reviewers
// Dennis: https://github.com/denett

// ====================================================================

import "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";
import "../../../interfaces/oracles/abstracts/IUniswapV3SingleTwapOracle.sol";

struct ConstructorParams {
    address uniswapV3PairAddress;
    uint32 twapDuration;
    address baseToken;
    address quoteToken;
}

/// @title UniswapV3SingleTwapOracle
/// @author Drake Evans (Frax Finance) https://github.com/drakeevans
/// @notice  An oracle for UniV3 Twap prices
abstract contract UniswapV3SingleTwapOracle is ERC165Storage, IUniswapV3SingleTwapOracle {
    /// @notice address of the Uniswap V3 pair
    address public immutable UNI_V3_PAIR_ADDRESS;

    /// @notice The precision of the twap
    uint128 public constant TWAP_PRECISION = 1e18;

    /// @notice The base token of the twap
    address public immutable UNISWAP_V3_TWAP_BASE_TOKEN;

    /// @notice The quote token of the twap
    address public immutable UNISWAP_V3_TWAP_QUOTE_TOKEN;

    /// @notice The duration of the twap
    uint32 public twapDuration;

    constructor(ConstructorParams memory _params) {
        _registerInterface({ interfaceId: type(IUniswapV3SingleTwapOracle).interfaceId });

        UNI_V3_PAIR_ADDRESS = _params.uniswapV3PairAddress;
        twapDuration = _params.twapDuration;
        UNISWAP_V3_TWAP_BASE_TOKEN = _params.baseToken;
        UNISWAP_V3_TWAP_QUOTE_TOKEN = _params.quoteToken;
    }

    /// @notice The ```_setTwapDuration``` function sets duration of the twap
    /// @param _newTwapDuration The new twap duration
    function _setTwapDuration(uint32 _newTwapDuration) internal {
        emit SetTwapDuration({ oldTwapDuration: twapDuration, newTwapDuration: _newTwapDuration });
        twapDuration = _newTwapDuration;
    }

    function setTwapDuration(uint32 _newTwapDuration) external virtual;

    /// @notice The ```_getUniswapV3Twap``` function is called to get the twap
    /// @return _twap The twap price
    function _getUniswapV3Twap() internal view returns (uint256 _twap) {
        address[] memory _pools = new address[](1);
        _pools[0] = UNI_V3_PAIR_ADDRESS;
        _twap = IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438).quoteSpecificPoolsWithTimePeriod({
            baseAmount: TWAP_PRECISION,
            baseToken: UNISWAP_V3_TWAP_BASE_TOKEN,
            quoteToken: UNISWAP_V3_TWAP_QUOTE_TOKEN,
            pools: _pools,
            period: twapDuration
        });
    }

    /// @notice The ```getUniswapV3Twap``` function is called to get the twap
    /// @return _twap The twap price
    function getUniswapV3Twap() external view virtual returns (uint256 _twap) {
        return _getUniswapV3Twap();
    }
}