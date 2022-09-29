// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@chainlink/contracts/src/v0.8/Denominations.sol';
import './base/SimpleOracle.sol';
import './libraries/TokenSorting.sol';
import '../interfaces/IStatefulChainlinkOracle.sol';

contract StatefulChainlinkOracle is AccessControl, SimpleOracle, IStatefulChainlinkOracle {
  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  /// @inheritdoc IStatefulChainlinkOracle
  uint32 public constant MAX_DELAY = 24 hours;
  /// @inheritdoc IStatefulChainlinkOracle
  FeedRegistryInterface public immutable registry;

  // solhint-disable private-vars-leading-underscore
  int8 private constant FOREX_DECIMALS = 8;
  int8 private constant ETH_DECIMALS = 18;
  // solhint-enable private-vars-leading-underscore

  mapping(address => address) internal _tokenMappings;
  mapping(bytes32 => PricingPlan) internal _planForPair;

  constructor(
    FeedRegistryInterface _registry,
    address _superAdmin,
    address[] memory _initialAdmins
  ) {
    if (address(_registry) == address(0) || _superAdmin == address(0)) revert ZeroAddress();
    registry = _registry;
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i = 0; i < _initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
    }
  }

  /// @inheritdoc ITokenPriceOracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool) {
    (address __tokenA, address __tokenB) = _mapAndSort(_tokenA, _tokenB);
    PricingPlan _plan = _determinePricingPlan(__tokenA, __tokenB);
    return _plan != PricingPlan.NONE;
  }

  /// @inheritdoc ITokenPriceOracle
  function isPairAlreadySupported(address _tokenA, address _tokenB) public view override(ITokenPriceOracle, SimpleOracle) returns (bool) {
    return planForPair(_tokenA, _tokenB) != PricingPlan.NONE;
  }

  /// @inheritdoc ITokenPriceOracle
  function quote(
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    bytes calldata
  ) external view returns (uint256 _amountOut) {
    (address _mappedTokenIn, address _mappedTokenOut) = _mapPair(_tokenIn, _tokenOut);
    PricingPlan _plan = _planForPair[_keyForUnsortedPair(_mappedTokenIn, _mappedTokenOut)];
    if (_plan == PricingPlan.NONE) revert PairNotSupportedYet(_tokenIn, _tokenOut);
    if (_plan == PricingPlan.SAME_TOKENS) return _amountIn;

    int16 _inDecimals = _getDecimals(_tokenIn);
    int16 _outDecimals = _getDecimals(_tokenOut);

    if (_plan <= PricingPlan.TOKEN_ETH_PAIR) {
      return _getDirectPrice(_mappedTokenIn, _mappedTokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    } else if (_plan <= PricingPlan.TOKEN_TO_ETH_TO_TOKEN_PAIR) {
      return _getPriceSameBase(_mappedTokenIn, _mappedTokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    } else {
      return _getPriceDifferentBases(_mappedTokenIn, _mappedTokenOut, _inDecimals, _outDecimals, _amountIn, _plan);
    }
  }

  function _addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata
  ) internal virtual override {
    (address __tokenA, address __tokenB) = _mapAndSort(_tokenA, _tokenB);
    PricingPlan _plan = _determinePricingPlan(__tokenA, __tokenB);
    bytes32 _keyForPair = _keyForSortedPair(__tokenA, __tokenB);
    if (_plan == PricingPlan.NONE) {
      // Check if there is a current plan. If there is, it means that the pair was supported and it
      // lost support. In that case, we will remove the current plan and continue working as expected.
      // If there was no supported plan, and there still isn't, then we will fail
      PricingPlan _currentPlan = _planForPair[_keyForPair];
      if (_currentPlan == PricingPlan.NONE) {
        revert PairCannotBeSupported(_tokenA, _tokenB);
      }
    }
    _planForPair[_keyForPair] = _plan;
    emit UpdatedPlanForPair(__tokenA, __tokenB, _plan);
  }

  /// @inheritdoc IStatefulChainlinkOracle
  function planForPair(address _tokenA, address _tokenB) public view returns (PricingPlan) {
    (address __tokenA, address __tokenB) = _mapAndSort(_tokenA, _tokenB);
    return _planForPair[_keyForSortedPair(__tokenA, __tokenB)];
  }

  /// @inheritdoc IStatefulChainlinkOracle
  function addMappings(address[] calldata _addresses, address[] calldata _mappings) external onlyRole(ADMIN_ROLE) {
    if (_addresses.length != _mappings.length) revert InvalidMappingsInput();
    for (uint256 i = 0; i < _addresses.length; i++) {
      _tokenMappings[_addresses[i]] = _mappings[i];
    }
    emit MappingsAdded(_addresses, _mappings);
  }

  /// @inheritdoc IStatefulChainlinkOracle
  function mappedToken(address _token) public view returns (address) {
    address _mapping = _tokenMappings[_token];
    return _mapping != address(0) ? _mapping : _token;
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view override(AccessControl, BaseOracle) returns (bool) {
    return
      _interfaceId == type(IStatefulChainlinkOracle).interfaceId ||
      AccessControl.supportsInterface(_interfaceId) ||
      BaseOracle.supportsInterface(_interfaceId);
  }

  /** Handles prices when the pair is either ETH/USD, token/ETH or token/USD */
  function _getDirectPrice(
    address _tokenIn,
    address _tokenOut,
    int16 _inDecimals,
    int16 _outDecimals,
    uint256 _amountIn,
    PricingPlan _plan
  ) internal view returns (uint256) {
    uint256 _price;
    int8 _resultDecimals = _plan == PricingPlan.TOKEN_ETH_PAIR ? ETH_DECIMALS : FOREX_DECIMALS;
    bool _needsInverting = _isUSD(_tokenIn) || (_plan == PricingPlan.TOKEN_ETH_PAIR && _isETH(_tokenIn));

    if (_plan == PricingPlan.ETH_USD_PAIR) {
      _price = _getETHUSD();
    } else if (_plan == PricingPlan.TOKEN_USD_PAIR) {
      _price = _getPriceAgainstUSD(_isUSD(_tokenOut) ? _tokenIn : _tokenOut);
    } else if (_plan == PricingPlan.TOKEN_ETH_PAIR) {
      _price = _getPriceAgainstETH(_isETH(_tokenOut) ? _tokenIn : _tokenOut);
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
    int16 _inDecimals,
    int16 _outDecimals,
    uint256 _amountIn,
    PricingPlan _plan
  ) internal view returns (uint256) {
    address _base = _plan == PricingPlan.TOKEN_TO_USD_TO_TOKEN_PAIR ? Denominations.USD : Denominations.ETH;
    uint256 _tokenInToBase = _callRegistry(_tokenIn, _base);
    uint256 _tokenOutToBase = _callRegistry(_tokenOut, _base);
    return _adjustDecimals((_amountIn * _tokenInToBase) / _tokenOutToBase, _outDecimals - _inDecimals);
  }

  /** Handles prices when one of the tokens uses ETH as the base, and the other USD */
  function _getPriceDifferentBases(
    address _tokenIn,
    address _tokenOut,
    int16 _inDecimals,
    int16 _outDecimals,
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
    return _isUSD(_token) ? 1e8 : _callRegistry(_token, Denominations.USD);
  }

  function _getPriceAgainstETH(address _token) internal view returns (uint256) {
    return _isETH(_token) ? 1e18 : _callRegistry(_token, Denominations.ETH);
  }

  /// @dev Expects `_tokenA` and `_tokenB` to be sorted
  function _determinePricingPlan(address _tokenA, address _tokenB) internal view virtual returns (PricingPlan) {
    if (_tokenA == _tokenB) {
      return PricingPlan.SAME_TOKENS;
    }
    bool _isTokenAUSD = _isUSD(_tokenA);
    bool _isTokenBUSD = _isUSD(_tokenB);
    bool _isTokenAETH = _isETH(_tokenA);
    bool _isTokenBETH = _isETH(_tokenB);
    if ((_isTokenAETH && _isTokenBUSD) || (_isTokenAUSD && _isTokenBETH)) {
      return PricingPlan.ETH_USD_PAIR;
    } else if (_isTokenBUSD) {
      return _tryWithBases(_tokenA, PricingPlan.TOKEN_USD_PAIR, PricingPlan.TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B);
    } else if (_isTokenAUSD) {
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
    try registry.latestRoundData(_base, _quote) returns (uint80, int256 _price, uint256, uint256, uint80) {
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

  function _getDecimals(address _token) internal view returns (int16) {
    if (_isETH(_token)) {
      return ETH_DECIMALS;
    } else if (!Address.isContract(_token)) {
      return FOREX_DECIMALS;
    } else {
      return int16(uint16(IERC20Metadata(_token).decimals()));
    }
  }

  function _callRegistry(address _base, address _quote) internal view returns (uint256) {
    (, int256 _price, , uint256 _updatedAt, ) = registry.latestRoundData(_base, _quote);
    if (_price <= 0) revert InvalidPrice();
    if (block.timestamp > _updatedAt + MAX_DELAY) revert LastUpdateIsTooOld();
    return uint256(_price);
  }

  function _mapAndSort(address _tokenA, address _tokenB) internal view returns (address, address) {
    (address _mappedTokenA, address _mappedTokenB) = _mapPair(_tokenA, _tokenB);
    return TokenSorting.sortTokens(_mappedTokenA, _mappedTokenB);
  }

  function _mapPair(address _tokenA, address _tokenB) internal view returns (address _mappedTokenA, address _mappedTokenB) {
    _mappedTokenA = mappedToken(_tokenA);
    _mappedTokenB = mappedToken(_tokenB);
  }

  function _keyForUnsortedPair(address _tokenA, address _tokenB) internal pure returns (bytes32) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    return _keyForSortedPair(__tokenA, __tokenB);
  }

  /// @dev Expects `_tokenA` and `_tokenB` to be sorted
  function _keyForSortedPair(address _tokenA, address _tokenB) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_tokenA, _tokenB));
  }

  function _getETHUSD() internal view returns (uint256) {
    return _callRegistry(Denominations.ETH, Denominations.USD);
  }

  function _isUSD(address _token) internal pure returns (bool) {
    return _token == Denominations.USD;
  }

  function _isETH(address _token) internal pure returns (bool) {
    return _token == Denominations.ETH;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
                /// @solidity memory-safe-assembly
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
pragma solidity >=0.8.7 <0.9.0;

import './BaseOracle.sol';

/**
 * @title A simple implementation of `BaseOracle` that already implements functions to add support
 * @notice Most implementations of `ITokenPriceOracle` will have an internal function that is called in both
 *         `addSupportForPairIfNeeded` and `addOrModifySupportForPair`. This oracle is now making this explicit, and
 *         implementing these two functions. They remain virtual so that they can be overriden if needed.
 */
abstract contract SimpleOracle is BaseOracle {
  ///@inheritdoc ITokenPriceOracle
  function isPairAlreadySupported(address tokenA, address tokenB) public view virtual returns (bool);

  ///@inheritdoc ITokenPriceOracle
  function addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata _data
  ) external virtual {
    _addOrModifySupportForPair(_tokenA, _tokenB, _data);
  }

  ///@inheritdoc ITokenPriceOracle
  function addSupportForPairIfNeeded(
    address _tokenA,
    address _tokenB,
    bytes calldata _data
  ) external virtual {
    if (!isPairAlreadySupported(_tokenA, _tokenB)) {
      _addOrModifySupportForPair(_tokenA, _tokenB, _data);
    }
  }

  /**
   * @notice Add or reconfigures the support for a given pair. This function will let the oracle take some actions
   *         to configure the pair, in preparation for future quotes. Can be called many times in order to let the oracle
   *         re-configure for a new context
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function _addOrModifySupportForPair(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) internal virtual;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >0.6;

/**
 * @title TokenSorting library
 * @notice Provides functions to sort tokens easily
 */
library TokenSorting {
  /**
   * @notice Takes two tokens, and returns them sorted
   * @param _tokenA One of the tokens
   * @param _tokenB The other token
   * @return __tokenA The first of the tokens
   * @return __tokenB The second of the tokens
   */
  function sortTokens(address _tokenA, address _tokenB) internal pure returns (address __tokenA, address __tokenB) {
    (__tokenA, __tokenB) = _tokenA < _tokenB ? (_tokenA, _tokenB) : (_tokenB, _tokenA);
  }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol';
import './ITokenPriceOracle.sol';

/**
 * @title An implementation of IPriceOracle that uses Chainlink feeds
 * @notice This oracle will attempt to use all available feeds to determine prices between pairs
 */
interface IStatefulChainlinkOracle is ITokenPriceOracle {
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
    TOKEN_A_TO_ETH_TO_USD_TO_TOKEN_B,
    // Used then tokenA is the same as tokenB
    SAME_TOKENS
  }

  /**
   * @notice Emitted when the oracle updated the pricing plan for a pair
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param plan The new plan
   */
  event UpdatedPlanForPair(address tokenA, address tokenB, PricingPlan plan);

  /**
   * @notice Emitted when new tokens are considered USD
   * @param tokens The new tokens
   */
  event TokensConsideredUSD(address[] tokens);

  /**
   * @notice Emitted when tokens should no longer be considered USD
   * @param tokens The tokens to no longer consider USD
   */
  event TokensNoLongerConsideredUSD(address[] tokens);

  /**
   * @notice Emitted when new mappings are added
   * @param tokens The tokens
   * @param mappings Their new mappings
   */
  event MappingsAdded(address[] tokens, address[] mappings);

  /// @notice Thrown when the price is non-positive
  error InvalidPrice();

  /// @notice Thrown when the last price update was too long ago
  error LastUpdateIsTooOld();

  /// @notice Thrown when one of the parameters is a zero address
  error ZeroAddress();

  /// @notice Thrown when the input for adding mappings in invalid
  error InvalidMappingsInput();

  /**
   * @notice Returns how old the last price update can be before the oracle reverts by considering it too old
   * @dev Cannot be modified
   * @return How old the last price update can be in seconds
   */
  function MAX_DELAY() external view returns (uint32);

  /**
   * @notice Returns the Chainlink feed registry
   * @return The Chainlink registry
   */
  function registry() external view returns (FeedRegistryInterface);

  /**
   * @notice Returns the pricing plan that will be used when quoting the given pair
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @return The pricing plan that will be used
   */
  function planForPair(address tokenA, address tokenB) external view returns (PricingPlan);

  /**
   * @notice Returns the mapping of the given token, if it exists. If it doesn't, then the original token is returned
   * @return If it exists, the mapping is returned. Otherwise, the original token is returned
   */
  function mappedToken(address token) external view returns (address);

  /**
   * @notice Adds new token mappings
   * @param addresses The addresses of the tokens
   * @param mappings The addresses of their mappings
   */
  function addMappings(address[] calldata addresses, address[] calldata mappings) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/Multicall.sol';
import '../../interfaces/ITokenPriceOracle.sol';

/// @title A base implementation of `ITokenPriceOracle` that implements `ERC165` and `Multicall`
abstract contract BaseOracle is Multicall, ERC165, ITokenPriceOracle {
  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
    return
      _interfaceId == type(ITokenPriceOracle).interfaceId ||
      _interfaceId == type(Multicall).interfaceId ||
      super.supportsInterface(_interfaceId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title The interface for an oracle that provides price quotes
 * @notice These methods allow users to add support for pairs, and then ask for quotes
 */
interface ITokenPriceOracle {
  /// @notice Thrown when trying to add support for a pair that cannot be supported
  error PairCannotBeSupported(address tokenA, address tokenB);

  /// @notice Thrown when trying to execute a quote with a pair that isn't supported yet
  error PairNotSupportedYet(address tokenA, address tokenB);

  /**
   * @notice Returns whether this oracle can support the given pair of tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair of tokens can be supported by the oracle
   */
  function canSupportPair(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice Returns whether this oracle is already supporting the given pair of tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return Whether the given pair of tokens is already being supported by the oracle
   */
  function isPairAlreadySupported(address tokenA, address tokenB) external view returns (bool);

  /**
   * @notice Returns a quote, based on the given tokens and amount
   * @dev Will revert if pair isn't supported
   * @param tokenIn The token that will be provided
   * @param amountIn The amount that will be provided
   * @param tokenOut The token we would like to quote
   * @param data Custom data that the oracle might need to operate
   * @return amountOut How much `tokenOut` will be returned in exchange for `amountIn` amount of `tokenIn`
   */
  function quote(
    address tokenIn,
    uint256 amountIn,
    address tokenOut,
    bytes calldata data
  ) external view returns (uint256 amountOut);

  /**
   * @notice Add or reconfigures the support for a given pair. This function will let the oracle take some actions
   *         to configure the pair, in preparation for future quotes. Can be called many times in order to let the oracle
   *         re-configure for a new context
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function addOrModifySupportForPair(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external;

  /**
   * @notice Adds support for a given pair if the oracle didn't support it already. If called for a pair that is already supported,
   *         then nothing will happen. This function will let the oracle take some actions to configure the pair, in preparation
   *         for future quotes
   * @dev Will revert if pair cannot be supported. tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @param data Custom data that the oracle might need to operate
   */
  function addSupportForPairIfNeeded(
    address tokenA,
    address tokenB,
    bytes calldata data
  ) external;
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

  function decimals(address base, address quote) external view returns (uint8);

  function description(address base, address quote) external view returns (string memory);

  function version(address base, address quote) external view returns (uint256);

  function latestRoundData(address base, address quote)
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

  function latestAnswer(address base, address quote) external view returns (int256 answer);

  function latestTimestamp(address base, address quote) external view returns (uint256 timestamp);

  function latestRound(address base, address quote) external view returns (uint256 roundId);

  function getAnswer(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (int256 answer);

  function getTimestamp(
    address base,
    address quote,
    uint256 roundId
  ) external view returns (uint256 timestamp);

  // Registry getters

  function getFeed(address base, address quote) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseFeed(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function isFeedEnabled(address aggregator) external view returns (bool);

  function getPhase(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (Phase memory phase);

  // Round helpers

  function getRoundFeed(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (AggregatorV2V3Interface aggregator);

  function getPhaseRange(
    address base,
    address quote,
    uint16 phaseId
  ) external view returns (uint80 startingRoundId, uint80 endingRoundId);

  function getPreviousRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 previousRoundId);

  function getNextRoundId(
    address base,
    address quote,
    uint80 roundId
  ) external view returns (uint80 nextRoundId);

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

  function getProposedFeed(address base, address quote)
    external
    view
    returns (AggregatorV2V3Interface proposedAggregator);

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

  function proposedLatestRoundData(address base, address quote)
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
  function getCurrentPhaseId(address base, address quote) external view returns (uint16 currentPhaseId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AggregatorInterface.sol";
import "./AggregatorV3Interface.sol";

interface AggregatorV2V3Interface is AggregatorInterface, AggregatorV3Interface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
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