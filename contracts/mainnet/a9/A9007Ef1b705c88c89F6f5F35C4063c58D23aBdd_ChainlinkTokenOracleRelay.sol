/**
 *Submitted for verification at Etherscan.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title OracleRelay Interface
/// @notice Interface for interacting with OracleRelay
interface IOracleRelay {
  /// @notice Emited when the underlyings are different in the anchored view
  error OracleRelay_DifferentUnderlyings();

  enum OracleType {
    Chainlink,
    Uniswap,
    Price
  }

  /// @notice returns the price with 18 decimals
  /// @return _currentValue the current price
  function currentValue() external returns (uint256 _currentValue);

  /// @notice returns the price with 18 decimals without any state changes
  /// @dev some oracles require a state change to get the exact current price.
  ///      This is updated when calling other state changing functions that query the price
  /// @return _price the current price
  function peekValue() external view returns (uint256 _price);

  /// @notice returns the type of the oracle
  /// @return _type the type (Chainlink/Uniswap/Price)
  function oracleType() external view returns (OracleType _type);

  /// @notice returns the underlying asset the oracle is pricing
  /// @return _underlying the address of the underlying asset
  function underlying() external view returns (address _underlying);
}

abstract contract OracleRelay is IOracleRelay {
  /// @notice The WETH address
  address public constant wETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  /// @notice The type of oracle
  OracleType public oracleType;
  /// @notice The underlying asset
  address public underlying;

  constructor(OracleType _oracleType) {
    oracleType = _oracleType;
  }

  /// @notice set the underlying address
  function _setUnderlying(address _underlying) internal {
    underlying = _underlying;
  }

  /// @dev Most oracles don't require a state change for pricing, for those who do, override this function
  function currentValue() external virtual returns (uint256 _currentValue) {
    _currentValue = peekValue();
  }

  /// @notice The current reported value of the oracle
  /// @dev Implementation in _get()
  /// @return _price The current value
  function peekValue() public view virtual override returns (uint256 _price);
}

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

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

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

library ChainlinkStalePriceLib {
  // @notice Thrown when the price received is negative
  error Chainlink_NegativePrice();

  /// @notice Returns the current price from the aggregator
  function getCurrentPrice(AggregatorV2V3Interface _aggregator) internal view returns (uint256 _price) {
    (, int256 _answer,,,) = _aggregator.latestRoundData();
    if (_answer <= 0) revert Chainlink_NegativePrice();
    _price = uint256(_answer);
  }
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @notice Oracle that wraps a chainlink oracle.
///         The oracle returns (chainlinkPrice) * mul / div
contract ChainlinkOracleRelay is OracleRelay, Ownable {
  /// @notice Emitted when the amount is zero
  error ChainlinkOracle_ZeroAmount();

  /// @notice The chainlink aggregator
  AggregatorV2V3Interface private immutable _AGGREGATOR;

  /// @notice multiply number used to scale the price
  uint256 public immutable MULTIPLY;

  /// @notice divide number used to scale the price
  uint256 public immutable DIVIDE;

  /// @notice The delay before the price is considered stale
  uint256 public stalePriceDelay;

  /// @notice All values set at construction time
  /// @param _underlying The underlying address
  /// @param _feedAddress The address of chainlink feed
  /// @param _mul The numerator of scalar
  /// @param _div The denominator of scalar
  /// @param _stalePriceDelay The delay before the price is considered stale
  constructor(
    address _underlying,
    address _feedAddress,
    uint256 _mul,
    uint256 _div,
    uint256 _stalePriceDelay
  ) OracleRelay(OracleType.Chainlink) {
    _AGGREGATOR = AggregatorV2V3Interface(_feedAddress);
    MULTIPLY = _mul;
    DIVIDE = _div;
    stalePriceDelay = _stalePriceDelay;

    _setUnderlying(_underlying);
  }

  /// @notice The current reported value of the oracle
  /// @dev Implementation in getLastSecond
  /// @return _value The current value
  function peekValue() public view override returns (uint256 _value) {
    _value = _getLastSecond();
  }

  /// @notice Returns true if the price is stale
  /// @return _stale True if the price is stale
  function isStale() external view returns (bool _stale) {
    (,,, uint256 _updatedAt,) = _AGGREGATOR.latestRoundData();
    if (block.timestamp > _updatedAt + stalePriceDelay) _stale = true;
  }

  /// @notice Sets the stale price delay
  /// @param _stalePriceDelay The new stale price delay
  /// @dev Only the owner can call this function
  function setStalePriceDelay(uint256 _stalePriceDelay) external onlyOwner {
    if (_stalePriceDelay == 0) revert ChainlinkOracle_ZeroAmount();
    stalePriceDelay = _stalePriceDelay;
  }

  /// @notice Returns last second value of the oracle
  /// @dev    It does not revert if price is stale
  /// @return _value The last second value of the oracle
  function _getLastSecond() private view returns (uint256 _value) {
    uint256 _latest = ChainlinkStalePriceLib.getCurrentPrice(_AGGREGATOR);
    _value = (uint256(_latest) * MULTIPLY) / DIVIDE;
  }
}

/// @notice This oracle is for tokens that don't have a USD pair but do have a wETH/ETH pair
/// @dev Oracle that wraps a chainlink oracle
///      The oracle returns (chainlinkPrice) * mul / div
contract ChainlinkTokenOracleRelay is OracleRelay {
  /// @notice The chainlink aggregator
  ChainlinkOracleRelay public immutable AGGREGATOR;

  /// @notice The chainlink aggregator for the base token
  ChainlinkOracleRelay public immutable BASE_AGGREGATOR;

  /// @notice All values set at construction time
  /// @param  _feedAddress The address of chainlink feed
  /// @param  _baseFeedAddress The address of chainlink feed for the base token
  constructor(
    ChainlinkOracleRelay _feedAddress,
    ChainlinkOracleRelay _baseFeedAddress
  ) OracleRelay(OracleType.Chainlink) {
    AGGREGATOR = ChainlinkOracleRelay(_feedAddress);
    BASE_AGGREGATOR = ChainlinkOracleRelay(_baseFeedAddress);

    _setUnderlying(_feedAddress.underlying());
  }

  /// @notice returns the price with 18 decimals without any state changes
  /// @dev some oracles require a state change to get the exact current price.
  ///      This is updated when calling other state changing functions that query the price
  /// @return _price the current price
  function peekValue() public view override returns (uint256 _price) {
    _price = _get();
  }

  /// @notice Returns true if the price is stale
  /// @return _stale True if the price is stale
  function isStale() external view returns (bool _stale) {
    _stale = AGGREGATOR.isStale() || BASE_AGGREGATOR.isStale();
  }

  /// @notice The current reported value of the oracle
  /// @dev Implementation in getLastSecond
  /// @return _value The current value
  function _get() internal view returns (uint256 _value) {
    uint256 _aggregatorPrice = AGGREGATOR.peekValue();
    uint256 _baseAggregatorPrice = BASE_AGGREGATOR.peekValue();

    _value = (_aggregatorPrice * _baseAggregatorPrice) / 1e18;
  }
}