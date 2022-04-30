// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@chainlink/contracts/src/v0.8/Denominations.sol';
import '../interfaces/oracles/IChainlinkOracle.sol';
import '../libraries/TokenSorting.sol';
import '../utils/Governable.sol';

contract ChainlinkOracle is Governable, IChainlinkOracle {
  /// @inheritdoc IChainlinkOracle
  mapping(address => mapping(address => PricingPlan)) public planForPair;
  /// @inheritdoc IChainlinkOracle
  FeedRegistryInterface public immutable registry;
  /// @inheritdoc IChainlinkOracle
  // solhint-disable-next-line var-name-mixedcase
  address public immutable WETH;
  /// @inheritdoc IChainlinkOracle
  uint32 public maxDelay;

  // solhint-disable private-vars-leading-underscore
  // Addresses in Ethereum Mainnet
  address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address private constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address private constant RENBTC = 0xEB4C2781e4ebA804CE9a9803C67d0893436bB27D;
  address private constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
  int8 private constant USD_DECIMALS = 8;
  int8 private constant ETH_DECIMALS = 18;
  // solhint-enable private-vars-leading-underscore

  mapping(address => bool) internal _shouldBeConsideredUSD;
  mapping(address => address) internal _tokenMappings;

  constructor(
    // solhint-disable-next-line var-name-mixedcase
    address _WETH,
    FeedRegistryInterface _registry,
    uint32 _maxDelay,
    address _governor
  ) Governable(_governor) {
    if (_WETH == address(0) || address(_registry) == address(0)) revert ZeroAddress();
    if (_maxDelay == 0) revert ZeroMaxDelay();
    registry = _registry;
    maxDelay = _maxDelay;
    WETH = _WETH;
  }

  /// @inheritdoc IPriceOracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    PricingPlan _plan = _determinePricingPlan(__tokenA, __tokenB);
    return _plan != PricingPlan.NONE;
  }

  /// @inheritdoc IPriceOracle
  function quote(
    address _tokenIn,
    uint128 _amountIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut) {
    (address _tokenA, address _tokenB) = TokenSorting.sortTokens(_tokenIn, _tokenOut);
    PricingPlan _plan = planForPair[_tokenA][_tokenB];
    if (_plan == PricingPlan.NONE) revert PairNotSupported();

    int8 _inDecimals = _getDecimals(_tokenIn);
    int8 _outDecimals = _getDecimals(_tokenOut);

    if (_plan <= PricingPlan.TOKEN_ETH_PAIR) {
      return _getDirectPrice(_tokenIn, _tokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    } else if (_plan <= PricingPlan.TOKEN_TO_ETH_TO_TOKEN_PAIR) {
      return _getPriceSameBase(_tokenIn, _tokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    } else {
      return _getPriceDifferentBases(_tokenIn, _tokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    }
  }

  /// @inheritdoc IPriceOracle
  function reconfigureSupportForPair(address _tokenA, address _tokenB) external {
    _addSupportForPair(_tokenA, _tokenB);
  }

  /// @inheritdoc IPriceOracle
  function addSupportForPairIfNeeded(address _tokenA, address _tokenB) external {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    if (planForPair[__tokenA][__tokenB] == PricingPlan.NONE) {
      _addSupportForPair(_tokenA, _tokenB);
    }
  }

  function _addSupportForPair(address _tokenA, address _tokenB) internal virtual {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    PricingPlan _plan = _determinePricingPlan(__tokenA, __tokenB);
    if (_plan == PricingPlan.NONE) revert PairNotSupported();
    planForPair[__tokenA][__tokenB] = _plan;
    emit AddedSupportForPairInChainlinkOracle(__tokenA, __tokenB);
  }

  /// @inheritdoc IChainlinkOracle
  function addUSDStablecoins(address[] calldata _addresses) external onlyGovernor {
    for (uint256 i; i < _addresses.length; i++) {
      _shouldBeConsideredUSD[_addresses[i]] = true;
    }
    emit TokensConsideredUSD(_addresses);
  }

  /// @inheritdoc IChainlinkOracle
  function addMappings(address[] calldata _addresses, address[] calldata _mappings) external onlyGovernor {
    if (_addresses.length != _mappings.length) revert InvalidMappingsInput();
    for (uint256 i; i < _addresses.length; i++) {
      _tokenMappings[_addresses[i]] = _mappings[i];
    }
    emit MappingsAdded(_addresses, _mappings);
  }

  /// @inheritdoc IChainlinkOracle
  function setMaxDelay(uint32 _maxDelay) external onlyGovernor {
    maxDelay = _maxDelay;
    emit MaxDelaySet(_maxDelay);
  }

  /// @inheritdoc IChainlinkOracle
  function mappedToken(address _token) public view returns (address) {
    if (block.chainid == 1 && (_token == RENBTC || _token == WBTC)) {
      return Denominations.BTC;
    } else {
      address _mapping = _tokenMappings[_token];
      return _mapping != address(0) ? _mapping : _token;
    }
  }

  /** Handles prices when the pair is either ETH/USD, token/ETH or token/USD */
  function _getDirectPrice(
    address _tokenIn,
    address _tokenOut,
    int8 _inDecimals,
    int8 _outDecimals,
    uint256 _amountIn,
    PricingPlan _plan
  ) internal view returns (uint256) {
    uint256 _price;
    int8 _resultDecimals = _plan == PricingPlan.TOKEN_ETH_PAIR ? ETH_DECIMALS : USD_DECIMALS;
    bool _needsInverting = _isUSD(_tokenIn) || (_plan == PricingPlan.TOKEN_ETH_PAIR && _tokenIn == WETH);

    if (_plan == PricingPlan.ETH_USD_PAIR) {
      _price = _getETHUSD();
    } else if (_plan == PricingPlan.TOKEN_USD_PAIR) {
      _price = _getPriceAgainstUSD(_isUSD(_tokenOut) ? _tokenIn : _tokenOut);
    } else if (_plan == PricingPlan.TOKEN_ETH_PAIR) {
      _price = _getPriceAgainstETH(_tokenOut == WETH ? _tokenIn : _tokenOut);
    }
    if (!_needsInverting) {
      return _adjustDecimals(_price * _amountIn, _outDecimals - _resultDecimals - _inDecimals);
    } else {
      return _adjustDecimals(_adjustDecimals(_amountIn, _resultDecimals + _outDecimals) / _price, -_inDecimals);
    }
  }

  /** Handles prices when both tokens share the same base (either ETH or USD) */
  function _getPriceSameBase(
    address _tokenIn,
    address _tokenOut,
    int8 _inDecimals,
    int8 _outDecimals,
    uint256 _amountIn,
    PricingPlan _plan
  ) internal view returns (uint256) {
    address _base = _plan == PricingPlan.TOKEN_TO_USD_TO_TOKEN_PAIR ? Denominations.USD : Denominations.ETH;
    uint256 _tokenInToBase = _callRegistry(mappedToken(_tokenIn), _base);
    uint256 _tokenOutToBase = _callRegistry(mappedToken(_tokenOut), _base);
    return _adjustDecimals((_amountIn * _tokenInToBase) / _tokenOutToBase, _outDecimals - _inDecimals);
  }

  /** Handles prices when one of the tokens uses ETH as the base, and the other USD */
  function _getPriceDifferentBases(
    address _tokenIn,
    address _tokenOut,
    int8 _inDecimals,
    int8 _outDecimals,
    uint256 _amountIn,
    PricingPlan _plan
  ) internal view returns (uint256) {
    bool _isTokenInUSD = (_plan == PricingPlan.TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B && _tokenIn < _tokenOut) ||
      (_plan == PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B && _tokenIn > _tokenOut);
    uint256 _ethToUSDPrice = _getETHUSD();
    if (_isTokenInUSD) {
      uint256 _tokenInToUSD = _getPriceAgainstUSD(_tokenIn);
      uint256 _tokenOutToETH = _getPriceAgainstETH(_tokenOut);
      uint256 _adjustedInUSDValue = _adjustDecimals(_amountIn * _tokenInToUSD, _outDecimals - _inDecimals + ETH_DECIMALS);
      return _adjustedInUSDValue / _ethToUSDPrice / _tokenOutToETH;
    } else {
      uint256 _tokenInToETH = _getPriceAgainstETH(_tokenIn);
      uint256 _tokenOutToUSD = _getPriceAgainstUSD(_tokenOut);
      return _adjustDecimals((_amountIn * _tokenInToETH * _ethToUSDPrice) / _tokenOutToUSD, _outDecimals - _inDecimals - ETH_DECIMALS);
    }
  }

  function _getPriceAgainstUSD(address _token) internal view returns (uint256) {
    return _isUSD(_token) ? 1e8 : _callRegistry(mappedToken(_token), Denominations.USD);
  }

  function _getPriceAgainstETH(address _token) internal view returns (uint256) {
    return _token == WETH ? 1e18 : _callRegistry(mappedToken(_token), Denominations.ETH);
  }

  function _determinePricingPlan(address _tokenA, address _tokenB) internal view virtual returns (PricingPlan) {
    bool _isTokenAUSD = _isUSD(_tokenA);
    bool _isTokenBUSD = _isUSD(_tokenB);
    bool _isTokenAETH = _tokenA == WETH;
    bool _isTokenBETH = _tokenB == WETH;
    if ((_isTokenAETH && _isTokenBUSD) || (_isTokenAUSD && _isTokenBETH)) {
      // Note: there are stablecoins/ETH pairs on Chainlink, but they are updated less often than the USD/ETH pair.
      // That's why we prefer to use the USD/ETH pair instead
      return PricingPlan.ETH_USD_PAIR;
    } else if (_isTokenBUSD && !_isTokenAUSD) {
      return _tryWithBases(_tokenA, PricingPlan.TOKEN_USD_PAIR, PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B);
    } else if (_isTokenAUSD && !_isTokenBUSD) {
      return _tryWithBases(_tokenB, PricingPlan.TOKEN_USD_PAIR, PricingPlan.TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B);
    } else if (_isTokenBETH) {
      return _tryWithBases(_tokenA, PricingPlan.TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B, PricingPlan.TOKEN_ETH_PAIR);
    } else if (_isTokenAETH) {
      return _tryWithBases(_tokenB, PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B, PricingPlan.TOKEN_ETH_PAIR);
    } else if (_exists(_tokenA, Denominations.USD)) {
      return _tryWithBases(_tokenB, PricingPlan.TOKEN_TO_USD_TO_TOKEN_PAIR, PricingPlan.TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B);
    } else if (_exists(_tokenA, Denominations.ETH)) {
      return _tryWithBases(_tokenB, PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B, PricingPlan.TOKEN_TO_ETH_TO_TOKEN_PAIR);
    }
    return PricingPlan.NONE;
  }

  function _tryWithBases(
    address _token,
    PricingPlan _ifUSD,
    PricingPlan _ifETH
  ) internal view returns (PricingPlan) {
    // Note: we are prioritizing plans that have fewer external calls
    (address _firstBase, PricingPlan _firstResult, address _secondBaseBase, PricingPlan _secondResult) = _ifUSD < _ifETH
      ? (Denominations.USD, _ifUSD, Denominations.ETH, _ifETH)
      : (Denominations.ETH, _ifETH, Denominations.USD, _ifUSD);
    if (_exists(_token, _firstBase)) {
      return _firstResult;
    } else if (_exists(_token, _secondBaseBase)) {
      return _secondResult;
    } else {
      return PricingPlan.NONE;
    }
  }

  function _exists(address _base, address _quote) internal view returns (bool) {
    try registry.latestRoundData(mappedToken(_base), _quote) returns (uint80, int256 _price, uint256, uint256, uint80) {
      return _price > 0;
    } catch {
      return false;
    }
  }

  function _adjustDecimals(uint256 _amount, int256 _factor) internal pure returns (uint256) {
    if (_factor < 0) {
      return _amount / (10**uint256(-_factor));
    } else {
      return _amount * (10**uint256(_factor));
    }
  }

  function _getDecimals(address _token) internal view returns (int8) {
    return int8(IERC20Metadata(_token).decimals());
  }

  function _callRegistry(address _base, address _quote) internal view returns (uint256) {
    (, int256 _price, , uint256 _updatedAt, ) = registry.latestRoundData(_base, _quote);
    if (_price <= 0) revert InvalidPrice();
    if (maxDelay < block.timestamp && _updatedAt < block.timestamp - maxDelay) revert LastUpdateIsTooOld();
    return uint256(_price);
  }

  function _getETHUSD() internal view returns (uint256) {
    return _callRegistry(Denominations.ETH, Denominations.USD);
  }

  function _isUSD(address _token) internal view returns (bool) {
    // We are doing this, to avoid expensive storage read
    bool _isHardcodedUSDInMainnet = block.chainid == 1 && (_token == DAI || _token == USDC || _token == USDT);
    return _isHardcodedUSDInMainnet || _shouldBeConsideredUSD[_token];
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

pragma solidity ^0.8.0;

library Denominations {
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
  address public constant BTC = 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB;

  // Fiat currencies follow https://en.wikipedia.org/wiki/ISO_4217
  address public constant USD = address(840);
  address public constant GBP = address(826);
  address public constant EUR = address(978);
  address public constant JPY = address(392);
  address public constant KRW = address(410);
  address public constant CNY = address(156);
  address public constant AUD = address(36);
  address public constant CAD = address(124);
  address public constant CHF = address(756);
  address public constant ARS = address(32);
  address public constant PHP = address(608);
  address public constant NZD = address(554);
  address public constant SGD = address(702);
  address public constant NGN = address(566);
  address public constant ZAR = address(710);
  address public constant RUB = address(643);
  address public constant INR = address(356);
  address public constant BRL = address(986);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol';
import './IPriceOracle.sol';

/// @title An implementation of IPriceOracle that uses Chainlink feeds
/// @notice This oracle will attempt to use all available feeds to determine prices between pairs
interface IChainlinkOracle is IPriceOracle {
  /// @notice The plan that will be used to calculate quotes for a given pair
  enum PricingPlan {
    // There is no plan calculated
    NONE,
    // Will use the ETH/USD feed
    ETH_USD_PAIR,
    // Will use a token/USD feed
    TOKEN_USD_PAIR,
    // Will use a token/ETH feed
    TOKEN_ETH_PAIR,
    // Will use tokenIn/USD and tokenOut/USD feeds
    TOKEN_TO_USD_TO_TOKEN_PAIR,
    // Will use tokenIn/ETH and tokenOut/ETH feeds
    TOKEN_TO_ETH_TO_TOKEN_PAIR,
    // Will use tokenA/USD, tokenB/ETH and ETH/USD feeds
    TOKEN_A_TO_USD_TO_ETH_TO_TOKEN_B,
    // Will use tokenA/ETH, tokenB/USD and ETH/USD feeds
    TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B
  }

  /// @notice Emitted when the oracle add supports for a new pair
  /// @param tokenA One of the pair's tokens
  /// @param tokenB The other of the pair's tokens
  event AddedSupportForPairInChainlinkOracle(address tokenA, address tokenB);

  /// @notice Emitted when new tokens are considered USD
  /// @param tokens The new tokens
  event TokensConsideredUSD(address[] tokens);

  /// @notice Emitted when new mappings are added
  /// @param tokens The tokens
  /// @param mappings Their new mappings
  event MappingsAdded(address[] tokens, address[] mappings);

  /// @notice Emitted when a new max delay is set
  /// @param newMaxDelay The new max delay
  event MaxDelaySet(uint32 newMaxDelay);

  /// @notice Thrown when the price is non-positive
  error InvalidPrice();

  /// @notice Thrown when the last price update was too long ago
  error LastUpdateIsTooOld();

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when the given max delay is zero
  error ZeroMaxDelay();

  /// @notice Thrown when trying to configure a pair that is not supported
  error PairNotSupported();

  /// @notice Thrown when the input for adding mappings in invalid
  error InvalidMappingsInput();

  /// @notice Returns the Chainlink feed registry
  /// @return The Chainlink registry
  function registry() external view returns (FeedRegistryInterface);

  /// @notice Returns how old the last price update can be before the oracle reverts by considering it too old
  /// @return How old the last price update can be in seconds
  function maxDelay() external view returns (uint32);

  /// @notice Returns the address of the WETH ERC-20 token
  /// @return The address of the token
  // solhint-disable-next-line func-name-mixedcase
  function WETH() external view returns (address);

  /// @notice Returns the pricing plan that will be used when quoting the given pair
  /// @dev It is expected that _tokenA < _tokenB
  /// @return The pricing plan that will be used
  function planForPair(address _tokenA, address _tokenB) external view returns (PricingPlan);

  /// @notice Returns the mapping of the given token, if it exists. If it doesn't, then the original token is returned
  /// @return If it exists, the mapping is returned. Otherwise, the original token is returned
  function mappedToken(address _token) external view returns (address);

  /// @notice Adds new tokens that should be considered USD stablecoins
  /// @param _addresses The addresses of the tokens
  function addUSDStablecoins(address[] calldata _addresses) external;

  /// @notice Adds new token mappings
  /// @param _addresses The addresses of the tokens
  /// @param _mappings The addresses of their mappings
  function addMappings(address[] calldata _addresses, address[] calldata _mappings) external;

  /// @notice Sets a new max delay
  /// @param _maxDelay The new max delay
  function setMaxDelay(uint32 _maxDelay) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >0.6;

/// @title TokenSorting library
/// @notice Provides functions to sort tokens easily
library TokenSorting {
  /// @notice Takes two tokens, and returns them sorted
  /// @param _tokenA One of the tokens
  /// @param _tokenB The other token
  /// @return __tokenA The first of the tokens
  /// @return __tokenB The second of the tokens
  function sortTokens(address _tokenA, address _tokenB) internal pure returns (address __tokenA, address __tokenB) {
    (__tokenA, __tokenB) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.7.0;

interface IGovernable {
  event PendingGovernorSet(address pendingGovernor);
  event PendingGovernorAccepted();

  function setPendingGovernor(address _pendingGovernor) external;

  function acceptPendingGovernor() external;

  function governor() external view returns (address);

  function pendingGovernor() external view returns (address);

  function isGovernor(address _account) external view returns (bool _isGovernor);

  function isPendingGovernor(address _account) external view returns (bool _isPendingGovernor);
}

abstract contract Governable is IGovernable {
  address private _governor;
  address private _pendingGovernor;

  constructor(address __governor) {
    require(__governor != address(0), 'Governable: zero address');
    _governor = __governor;
  }

  function governor() external view override returns (address) {
    return _governor;
  }

  function pendingGovernor() external view override returns (address) {
    return _pendingGovernor;
  }

  function setPendingGovernor(address __pendingGovernor) external virtual override onlyGovernor {
    _setPendingGovernor(__pendingGovernor);
  }

  function _setPendingGovernor(address __pendingGovernor) internal {
    require(__pendingGovernor != address(0), 'Governable: zero address');
    _pendingGovernor = __pendingGovernor;
    emit PendingGovernorSet(__pendingGovernor);
  }

  function acceptPendingGovernor() external virtual override onlyPendingGovernor {
    _acceptPendingGovernor();
  }

  function _acceptPendingGovernor() internal {
    require(_pendingGovernor != address(0), 'Governable: no pending governor');
    _governor = _pendingGovernor;
    _pendingGovernor = address(0);
    emit PendingGovernorAccepted();
  }

  function isGovernor(address _account) public view override returns (bool _isGovernor) {
    return _account == _governor;
  }

  function isPendingGovernor(address _account) public view override returns (bool _isPendingGovernor) {
    return _account == _pendingGovernor;
  }

  modifier onlyGovernor() {
    require(isGovernor(msg.sender), 'Governable: only governor');
    _;
  }

  modifier onlyPendingGovernor() {
    require(isPendingGovernor(msg.sender), 'Governable: only pending governor');
    _;
  }
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
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./AggregatorV2V3Interface.sol";

interface FeedRegistryInterface {
  struct Phase {
    uint16 phaseId;
    uint80 startingAggregatorRoundId;
    uint80 endingAggregatorRoundId;
  }

  event FeedProposed(
    address indexed asset,
    address indexed denomination,
    address indexed proposedAggregator,
    address currentAggregator,
    address sender
  );
  event FeedConfirmed(
    address indexed asset,
    address indexed denomination,
    address indexed latestAggregator,
    address previousAggregator,
    uint16 nextPhaseId,
    address sender
  );

  // V3 AggregatorV3Interface

  function decimals(
    address base,
    address quote
  )
    external
    view
    returns (
      uint8
    );

  function description(
    address base,
    address quote
  )
    external
    view
    returns (
      string memory
    );

  function version(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256
    );

  function latestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function getRoundData(
    address base,
    address quote,
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // V2 AggregatorInterface

  function latestAnswer(
    address base,
    address quote
  )
    external
    view
    returns (
      int256 answer
    );

  function latestTimestamp(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 timestamp
    );

  function latestRound(
    address base,
    address quote
  )
    external
    view
    returns (
      uint256 roundId
    );

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      int256 answer
    );

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  )
    external
    view
    returns (
      uint256 timestamp
    );

  // Registry getters

  function getFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function isFeedEnabled(
    address aggregator
  )
    external
    view
    returns (
      bool
    );

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      Phase memory phase
    );

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      AggregatorV2V3Interface aggregator
    );

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  )
    external
    view
    returns (
      uint80 startingRoundId,
      uint80 endingRoundId
    );

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 previousRoundId
    );

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external
    view
    returns (
      uint80 nextRoundId
    );

  // Feed management

  function proposeFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  function confirmFeed(
    address base,
    address quote,
    address aggregator
  ) external;

  // Proposed aggregator

  function getProposedFeed(
    address base,
    address quote
  )
    external
    view
    returns (
      AggregatorV2V3Interface proposedAggregator
    );

  function proposedGetRoundData(
    address base,
    address quote,
    uint80 roundId
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function proposedLatestRoundData(
    address base,
    address quote
  )
    external
    view
    returns (
      uint80 id,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  // Phases
  function getCurrentPhaseId(
    address base,
    address quote
  )
    external
    view
    returns (
      uint16 currentPhaseId
    );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for an oracle that provides price quotes
/// @notice These methods allow users to add support for pairs, and then ask for quotes
interface IPriceOracle {
  /// @notice Returns whether this oracle can support this pair of tokens
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  /// @return Whether the given pair of tokens can be supported by the oracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool);

  /// @notice Returns a quote, based on the given tokens and amount
  /// @param _tokenIn The token that will be provided
  /// @param _amountIn The amount that will be provided
  /// @param _tokenOut The token we would like to quote
  /// @return _amountOut How much _tokenOut will be returned in exchange for _amountIn amount of _tokenIn
  function quote(
    address _tokenIn,
    uint128 _amountIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut);

  /// @notice Reconfigures support for a given pair. This function will let the oracle take some actions to configure the pair, in
  /// preparation for future quotes. Can be called many times in order to let the oracle re-configure for a new context.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function reconfigureSupportForPair(address _tokenA, address _tokenB) external;

  /// @notice Adds support for a given pair if the oracle didn't support it already. If called for a pair that is already supported,
  /// then nothing will happen. This function will let the oracle take some actions to configure the pair, in preparation for future quotes.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function addSupportForPairIfNeeded(address _tokenA, address _tokenB) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface
{
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer()
    external
    view
    returns (
      int256
    );
  
  function latestTimestamp()
    external
    view
    returns (
      uint256
    );

  function latestRound()
    external
    view
    returns (
      uint256
    );

  function getAnswer(
    uint256 roundId
  )
    external
    view
    returns (
      int256
    );

  function getTimestamp(
    uint256 roundId
  )
    external
    view
    returns (
      uint256
    );

  event AnswerUpdated(
    int256 indexed current,
    uint256 indexed roundId,
    uint256 updatedAt
  );

  event NewRound(
    uint256 indexed roundId,
    address indexed startedBy,
    uint256 startedAt
  );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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