// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "../PriceProvider.sol";
import "../IERC20LikeV2.sol";

contract ChainlinkV3PriceProvider is PriceProvider {
    using SafeMath for uint256;

    struct AssetData {
        // Time threshold to invalidate stale prices
        uint256 heartbeat;
        // If true, we bypass the aggregator and consult the fallback provider directly
        bool forceFallback;
        // If true, the aggregator returns price in USD, so we need to convert to QUOTE
        bool convertToQuote;
        // Chainlink aggregator proxy
        AggregatorV3Interface aggregator;
        // Provider used if the aggregator's price is invalid or if it became disabled
        IPriceProvider fallbackProvider;
    }

    /// @dev Aggregator that converts from USD to quote token
    AggregatorV3Interface internal immutable _QUOTE_AGGREGATOR; // solhint-disable-line var-name-mixedcase

    /// @dev Decimals used by the _QUOTE_AGGREGATOR
    uint8 internal immutable _QUOTE_AGGREGATOR_DECIMALS; // solhint-disable-line var-name-mixedcase

    /// @dev Used to optimize calculations in emergency disable function
    // solhint-disable-next-line var-name-mixedcase
    uint256 internal immutable _MAX_PRICE_DIFF = type(uint256).max / (100 * EMERGENCY_PRECISION);
    
    // @dev Precision to use for the EMERGENCY_THRESHOLD
    uint256 public constant EMERGENCY_PRECISION = 1e6;

    /// @dev Disable the aggregator if the difference with the fallback is higher than this percentage (10%)
    uint256 public constant EMERGENCY_THRESHOLD = 10 * EMERGENCY_PRECISION; // solhint-disable-line var-name-mixedcase

    /// @dev this is basically `PriceProvider.quoteToken.decimals()`
    uint8 internal immutable _QUOTE_TOKEN_DECIMALS; // solhint-disable-line var-name-mixedcase

    /// @dev Address allowed to call the emergencyDisable function, can be set by the owner
    address public emergencyManager;

    /// @dev Threshold used to determine if the price returned by the _QUOTE_AGGREGATOR is valid
    uint256 public quoteAggregatorHeartbeat;

    /// @dev Data used for each asset
    mapping(address => AssetData) public assetData;

    event NewAggregator(address indexed asset, AggregatorV3Interface indexed aggregator, bool convertToQuote);
    event NewFallbackPriceProvider(address indexed asset, IPriceProvider indexed fallbackProvider);
    event NewHeartbeat(address indexed asset, uint256 heartbeat);
    event NewQuoteAggregatorHeartbeat(uint256 heartbeat);
    event NewEmergencyManager(address indexed emergencyManager);
    event AggregatorDisabled(address indexed asset, AggregatorV3Interface indexed aggregator);

    error AggregatorDidNotChange();
    error AggregatorPriceNotAvailable();
    error AssetNotSupported();
    error EmergencyManagerDidNotChange();
    error EmergencyThresholdNotReached();
    error FallbackProviderAlreadySet();
    error FallbackProviderDidNotChange();
    error FallbackProviderNotSet();
    error HeartbeatDidNotChange();
    error InvalidAggregator();
    error InvalidAggregatorDecimals();
    error InvalidFallbackPriceProvider();
    error InvalidHeartbeat();
    error OnlyEmergencyManager();
    error QuoteAggregatorHeartbeatDidNotChange();

    modifier onlyAssetSupported(address _asset) {
        if (!assetSupported(_asset)) {
            revert AssetNotSupported();
        }

        _;
    }

    constructor(
        IPriceProvidersRepository _priceProvidersRepository,
        address _emergencyManager,
        AggregatorV3Interface _quoteAggregator,
        uint256 _quoteAggregatorHeartbeat
    ) PriceProvider(_priceProvidersRepository) {
        _setEmergencyManager(_emergencyManager);
        _QUOTE_TOKEN_DECIMALS = IERC20LikeV2(quoteToken).decimals();
        _QUOTE_AGGREGATOR = _quoteAggregator;
        _QUOTE_AGGREGATOR_DECIMALS = _quoteAggregator.decimals();
        quoteAggregatorHeartbeat = _quoteAggregatorHeartbeat;
    }

    /// @inheritdoc IPriceProvider
    function assetSupported(address _asset) public view virtual override returns (bool) {
        AssetData storage data = assetData[_asset];

        // Asset is supported if:
        //     - the asset is the quote token
        //       OR
        //     - the aggregator address is defined AND
        //         - the aggregator is not disabled
        //           OR
        //         - the fallback is defined

        if (_asset == quoteToken) {
            return true;
        }

        if (address(data.aggregator) != address(0)) {
            return !data.forceFallback || address(data.fallbackProvider) != address(0);
        }

        return false;
    }

    /// @dev Returns price directly from aggregator using all internal settings except of fallback provider
    /// @param _asset Asset for which we want to get the price
    function getAggregatorPrice(address _asset) public view virtual returns (bool success, uint256 price) {
        (success, price) = _getAggregatorPrice(_asset);
    }
    
    /// @inheritdoc IPriceProvider
    function getPrice(address _asset) public view virtual override returns (uint256) {
        address quote = quoteToken;

        if (_asset == quote) {
            return 10 ** _QUOTE_TOKEN_DECIMALS;
        }

        (bool success, uint256 price) = _getAggregatorPrice(_asset);

        return success ? price : _getFallbackPrice(_asset);
    }

    /// @dev Sets the aggregator, fallbackProvider and heartbeat for an asset. Can only be called by the manager.
    /// @param _asset Asset to setup
    /// @param _aggregator Chainlink aggregator proxy
    /// @param _fallbackProvider Provider to use if the price is invalid or if the aggregator was disabled
    /// @param _heartbeat Threshold in seconds to invalidate a stale price
    function setupAsset(
        address _asset,
        AggregatorV3Interface _aggregator,
        IPriceProvider _fallbackProvider,
        uint256 _heartbeat,
        bool _convertToQuote
    ) external virtual onlyManager {
        // This has to be done first so that `_setAggregator` works
        _setHeartbeat(_asset, _heartbeat);

        if (!_setAggregator(_asset, _aggregator, _convertToQuote)) revert AggregatorDidNotChange();

        // We don't care if this doesn't change
        _setFallbackPriceProvider(_asset, _fallbackProvider);
    }

    /// @dev Sets the aggregator for an asset. Can only be called by the manager.
    /// @param _asset Asset for which to set the aggregator
    /// @param _aggregator Aggregator to set
    function setAggregator(address _asset, AggregatorV3Interface _aggregator, bool _convertToQuote)
        external
        virtual
        onlyManager
        onlyAssetSupported(_asset)
    {
        if (!_setAggregator(_asset, _aggregator, _convertToQuote)) revert AggregatorDidNotChange();
    }

    /// @dev Sets the fallback provider for an asset. Can only be called by the manager.
    /// @param _asset Asset for which to set the fallback provider
    /// @param _fallbackProvider Provider to set
    function setFallbackPriceProvider(address _asset, IPriceProvider _fallbackProvider)
        external
        virtual
        onlyManager
        onlyAssetSupported(_asset)
    {
        if (!_setFallbackPriceProvider(_asset, _fallbackProvider)) {
            revert FallbackProviderDidNotChange();
        }
    }

    /// @dev Sets the heartbeat threshold for an asset. Can only be called by the manager.
    /// @param _asset Asset for which to set the heartbeat threshold
    /// @param _heartbeat Threshold to set
    function setHeartbeat(address _asset, uint256 _heartbeat)
        external
        virtual
        onlyManager
        onlyAssetSupported(_asset)
    {
        if (!_setHeartbeat(_asset, _heartbeat)) revert HeartbeatDidNotChange();
    }

    /// @dev Sets the quote aggregator heartbeat threshold. Can only be called by the manager.
    /// @param _heartbeat Threshold to set
    function setQuoteAggregatorHeartbeat(uint256 _heartbeat)
        external
        virtual
        onlyManager
    {
        if (!_setQuoteAggregatorHeartbeat(_heartbeat)) revert QuoteAggregatorHeartbeatDidNotChange();
    }

    /// @dev Sets the emergencyManager. Can only be called by the manager.
    /// @param _emergencyManager Emergency manager to set
    function setEmergencyManager(address _emergencyManager) external virtual onlyManager {
        if (!_setEmergencyManager(_emergencyManager)) revert EmergencyManagerDidNotChange();
    }

    /// @dev Disables the aggregator for an asset if there is a big discrepancy between the aggregator and the
    /// fallback provider. The only way to reenable the asset is by calling setupAsset or setAggregator again.
    /// Can only be called by the emergencyManager.
    /// @param _asset Asset for which to disable the aggregator
    function emergencyDisable(address _asset) external virtual {
        if (msg.sender != emergencyManager) {
            revert OnlyEmergencyManager();
        }

        (bool success, uint256 price) = _getAggregatorPrice(_asset);

        if (!success) {
            revert AggregatorPriceNotAvailable();
        }

        uint256 fallbackPrice = _getFallbackPrice(_asset);

        uint256 diff;

        unchecked {
            // It is ok to uncheck because of the initial fallbackPrice >= price check
            diff = fallbackPrice >= price ? fallbackPrice - price : price - fallbackPrice;
        }

        if (diff > _MAX_PRICE_DIFF || (diff * 100 * EMERGENCY_PRECISION) / price < EMERGENCY_THRESHOLD) {
            revert EmergencyThresholdNotReached();
        }

        // Disable main aggregator, fallback stays enabled
        assetData[_asset].forceFallback = true;

        emit AggregatorDisabled(_asset, assetData[_asset].aggregator);
    }

    function getFallbackProvider(address _asset) external view virtual returns (IPriceProvider) {
        return assetData[_asset].fallbackProvider;
    }

    function _getAggregatorPrice(address _asset) internal view virtual returns (bool success, uint256 price) {
        AssetData storage data = assetData[_asset];

        uint256 heartbeat = data.heartbeat;
        bool forceFallback = data.forceFallback;
        AggregatorV3Interface aggregator = data.aggregator;

        if (address(aggregator) == address(0)) revert AssetNotSupported();

        (
            /*uint80 roundID*/,
            int256 aggregatorPrice,
            /*uint256 startedAt*/,
            uint256 timestamp,
            /*uint80 answeredInRound*/
        ) = aggregator.latestRoundData();

        // If a valid price is returned and it was updated recently
        if (!forceFallback && _isValidPrice(aggregatorPrice, timestamp, heartbeat)) {
            uint256 result;

            if (data.convertToQuote) {
                // _toQuote performs decimal normalization internally
                result = _toQuote(uint256(aggregatorPrice));
            } else {
                uint8 aggregatorDecimals = aggregator.decimals();
                result = _normalizeWithDecimals(uint256(aggregatorPrice), aggregatorDecimals);
            }

            return (true, result);
        }

        return (false, 0);
    }

    function _getFallbackPrice(address _asset) internal view virtual returns (uint256) {
        IPriceProvider fallbackProvider = assetData[_asset].fallbackProvider;

        if (address(fallbackProvider) == address(0)) revert FallbackProviderNotSet();

        return fallbackProvider.getPrice(_asset);
    }

    function _setEmergencyManager(address _emergencyManager) internal virtual returns (bool changed) {
        if (_emergencyManager == emergencyManager) {
            return false;
        }

        emergencyManager = _emergencyManager;

        emit NewEmergencyManager(_emergencyManager);

        return true;
    }

    function _setAggregator(
        address _asset,
        AggregatorV3Interface _aggregator,
        bool _convertToQuote
    ) internal virtual returns (bool changed) {
        if (address(_aggregator) == address(0)) revert InvalidAggregator();

        AssetData storage data = assetData[_asset];

        if (data.aggregator == _aggregator && data.forceFallback == false) {
            return false;
        }

        // There doesn't seem to be a way to verify if this is a "valid" aggregator (other than getting the price)
        data.forceFallback = false;
        data.aggregator = _aggregator;

        (bool success,) = _getAggregatorPrice(_asset);

        if (!success) revert AggregatorPriceNotAvailable();

        if (_convertToQuote && _aggregator.decimals() != _QUOTE_AGGREGATOR_DECIMALS) {
            revert InvalidAggregatorDecimals();
        }

        // We want to always update this
        assetData[_asset].convertToQuote = _convertToQuote;

        emit NewAggregator(_asset, _aggregator, _convertToQuote);

        return true;
    }

    function _setFallbackPriceProvider(address _asset, IPriceProvider _fallbackProvider)
        internal
        virtual
        returns (bool changed)
    {
        if (_fallbackProvider == assetData[_asset].fallbackProvider) {
            return false;
        }

        assetData[_asset].fallbackProvider = _fallbackProvider;

        if (address(_fallbackProvider) != address(0)) {
            if (
                !priceProvidersRepository.isPriceProvider(_fallbackProvider) ||
                !_fallbackProvider.assetSupported(_asset) ||
                _fallbackProvider.quoteToken() != quoteToken
            ) {
                revert InvalidFallbackPriceProvider();
            }

            // Make sure it doesn't revert
            _getFallbackPrice(_asset);
        }

        emit NewFallbackPriceProvider(_asset, _fallbackProvider);

        return true;
    }

    function _setHeartbeat(address _asset, uint256 _heartbeat) internal virtual returns (bool changed) {
        // Arbitrary limit, Chainlink's threshold is always less than a day
        if (_heartbeat > 2 days) revert InvalidHeartbeat();

        if (_heartbeat == assetData[_asset].heartbeat) {
            return false;
        }

        assetData[_asset].heartbeat = _heartbeat;

        emit NewHeartbeat(_asset, _heartbeat);

        return true;
    }

    function _setQuoteAggregatorHeartbeat(uint256 _heartbeat) internal virtual returns (bool changed) {
        // Arbitrary limit, Chainlink's threshold is always less than a day
        if (_heartbeat > 2 days) revert InvalidHeartbeat();

        if (_heartbeat == quoteAggregatorHeartbeat) {
            return false;
        }

        quoteAggregatorHeartbeat = _heartbeat;

        emit NewQuoteAggregatorHeartbeat(_heartbeat);

        return true;
    }

    /// @dev Adjusts the given price to use the same decimals as the quote token.
    /// @param _price Price to adjust decimals
    /// @param _decimals Decimals considered in `_price`
    function _normalizeWithDecimals(uint256 _price, uint8 _decimals) internal view virtual returns (uint256) {
        // We want to return the price of 1 asset token, but with the decimals of the quote token
        if (_QUOTE_TOKEN_DECIMALS == _decimals) {
            return _price;
        } else if (_QUOTE_TOKEN_DECIMALS < _decimals) {
            return _price / 10 ** (_decimals - _QUOTE_TOKEN_DECIMALS);
        } else {
            return _price * 10 ** (_QUOTE_TOKEN_DECIMALS - _decimals);
        }
    }

    /// @dev Converts a price returned by an aggregator to quote units
    function _toQuote(uint256 _price) internal view virtual returns (uint256) {
       (
            /*uint80 roundID*/,
            int256 aggregatorPrice,
            /*uint256 startedAt*/,
            uint256 timestamp,
            /*uint80 answeredInRound*/
        ) = _QUOTE_AGGREGATOR.latestRoundData();

        // If an invalid price is returned
        if (!_isValidPrice(aggregatorPrice, timestamp, quoteAggregatorHeartbeat)) {
            revert AggregatorPriceNotAvailable();
        }

        // _price and aggregatorPrice should both have the same decimals so we normalize here
        return _price * 10 ** _QUOTE_TOKEN_DECIMALS / uint256(aggregatorPrice);
    }

    function _isValidPrice(int256 _price, uint256 _timestamp, uint256 _heartbeat) internal view virtual returns (bool) {
        return _price > 0 && block.timestamp - _timestamp < _heartbeat;
    }
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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "../lib/Ping.sol";
import "../interfaces/IPriceProvider.sol";
import "../interfaces/IPriceProvidersRepository.sol";

/// @title PriceProvider
/// @notice Abstract PriceProvider contract, parent of all PriceProviders
/// @dev Price provider is a contract that directly integrates with a price source, ie. a DEX or alternative system
/// like Chainlink to calculate TWAP prices for assets. Each price provider should support a single price source
/// and multiple assets.
abstract contract PriceProvider is IPriceProvider {
    /// @notice PriceProvidersRepository address
    IPriceProvidersRepository public immutable priceProvidersRepository;

    /// @notice Token address which prices are quoted in. Must be the same as PriceProvidersRepository.quoteToken
    address public immutable override quoteToken;

    modifier onlyManager() {
        if (priceProvidersRepository.manager() != msg.sender) revert("OnlyManager");
        _;
    }

    /// @param _priceProvidersRepository address of PriceProvidersRepository
    constructor(IPriceProvidersRepository _priceProvidersRepository) {
        if (
            !Ping.pong(_priceProvidersRepository.priceProvidersRepositoryPing)            
        ) {
            revert("InvalidPriceProviderRepository");
        }

        priceProvidersRepository = _priceProvidersRepository;
        quoteToken = _priceProvidersRepository.quoteToken();
    }

    /// @inheritdoc IPriceProvider
    function priceProviderPing() external pure override returns (bytes4) {
        return this.priceProviderPing.selector;
    }

    function _revertBytes(bytes memory _errMsg, string memory _customErr) internal pure {
        if (_errMsg.length > 0) {
            assembly { // solhint-disable-line no-inline-assembly
                revert(add(32, _errMsg), mload(_errMsg))
            }
        }

        revert(_customErr);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6;

/// @dev This is only meant to be used by price providers, which use a different
/// Solidity version than the rest of the codebase. This way de won't need to include
/// an additional version of OpenZeppelin's library.
interface IERC20LikeV2 {
    function decimals() external view returns (uint8);
    function balanceOf(address) external view returns(uint256);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;


library Ping {
    function pong(function() external pure returns(bytes4) pingFunction) internal pure returns (bool) {
        return pingFunction.address != address(0) && pingFunction.selector == pingFunction();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

/// @title Common interface for Silo Price Providers
interface IPriceProvider {
    /// @notice Returns "Time-Weighted Average Price" for an asset. Calculates TWAP price for quote/asset.
    /// It unifies all tokens decimal to 18, examples:
    /// - if asses == quote it returns 1e18
    /// - if asset is USDC and quote is ETH and ETH costs ~$3300 then it returns ~0.0003e18 WETH per 1 USDC
    /// @param _asset address of an asset for which to read price
    /// @return price of asses with 18 decimals, throws when pool is not ready yet to provide price
    function getPrice(address _asset) external view returns (uint256 price);

    /// @dev Informs if PriceProvider is setup for asset. It does not means PriceProvider can provide price right away.
    /// Some providers implementations need time to "build" buffer for TWAP price,
    /// so price may not be available yet but this method will return true.
    /// @param _asset asset in question
    /// @return TRUE if asset has been setup, otherwise false
    function assetSupported(address _asset) external view returns (bool);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Helper method that allows easily detects, if contract is PriceProvider
    /// @dev this can save us from simple human errors, in case we use invalid address
    /// but this should NOT be treated as security check
    /// @return always true
    function priceProviderPing() external pure returns (bytes4);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.7.6 <0.9.0;

import "./IPriceProvider.sol";

interface IPriceProvidersRepository {
    /// @notice Emitted when price provider is added
    /// @param newPriceProvider new price provider address
    event NewPriceProvider(IPriceProvider indexed newPriceProvider);

    /// @notice Emitted when price provider is removed
    /// @param priceProvider removed price provider address
    event PriceProviderRemoved(IPriceProvider indexed priceProvider);

    /// @notice Emitted when asset is assigned to price provider
    /// @param asset assigned asset   address
    /// @param priceProvider price provider address
    event PriceProviderForAsset(address indexed asset, IPriceProvider indexed priceProvider);

    /// @notice Register new price provider
    /// @param _priceProvider address of price provider
    function addPriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Unregister price provider
    /// @param _priceProvider address of price provider to be removed
    function removePriceProvider(IPriceProvider _priceProvider) external;

    /// @notice Sets price provider for asset
    /// @dev Request for asset price is forwarded to the price provider assigned to that asset
    /// @param _asset address of an asset for which price provider will be used
    /// @param _priceProvider address of price provider
    function setPriceProviderForAsset(address _asset, IPriceProvider _priceProvider) external;

    /// @notice Returns "Time-Weighted Average Price" for an asset
    /// @param _asset address of an asset for which to read price
    /// @return price TWAP price of a token with 18 decimals
    function getPrice(address _asset) external view returns (uint256 price);

    /// @notice Gets price provider assigned to an asset
    /// @param _asset address of an asset for which to get price provider
    /// @return priceProvider address of price provider
    function priceProviders(address _asset) external view returns (IPriceProvider priceProvider);

    /// @notice Gets token address in which prices are quoted
    /// @return quoteToken address
    function quoteToken() external view returns (address);

    /// @notice Gets manager role address
    /// @return manager role address
    function manager() external view returns (address);

    /// @notice Checks if providers are available for an asset
    /// @param _asset asset address to check
    /// @return returns TRUE if price feed is ready, otherwise false
    function providersReadyForAsset(address _asset) external view returns (bool);

    /// @notice Returns true if address is a registered price provider
    /// @param _provider address of price provider to be removed
    /// @return true if address is a registered price provider, otherwise false
    function isPriceProvider(IPriceProvider _provider) external view returns (bool);

    /// @notice Gets number of price providers registered
    /// @return number of price providers registered
    function providersCount() external view returns (uint256);

    /// @notice Gets an array of price providers
    /// @return array of price providers
    function providerList() external view returns (address[] memory);

    /// @notice Sanity check function
    /// @return returns always TRUE
    function priceProvidersRepositoryPing() external pure returns (bytes4);
}