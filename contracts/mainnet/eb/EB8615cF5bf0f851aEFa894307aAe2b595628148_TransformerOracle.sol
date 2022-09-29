// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.7 <0.9.0;

import '@openzeppelin/contracts/access/AccessControl.sol';
import './libraries/TokenSorting.sol';
import './base/BaseOracle.sol';
import '../interfaces/ITransformerOracle.sol';

/**
 * @notice This implementation of `ITransformerOracle` assumes that all tokens being transformed only have one underlying token.
 *         This is true when this implementation was written, but it may not be true in the future. If that happens, then another
 *         implementation will be needed
 */
contract TransformerOracle is BaseOracle, AccessControl, ITransformerOracle {
  bytes32 public constant SUPER_ADMIN_ROLE = keccak256('SUPER_ADMIN_ROLE');
  bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');

  /// @inheritdoc ITransformerOracle
  ITransformerRegistry public immutable REGISTRY;

  /// @inheritdoc ITransformerOracle
  ITokenPriceOracle public immutable UNDERLYING_ORACLE;

  /// @inheritdoc ITransformerOracle
  mapping(address => bool) public willAvoidMappingToUnderlying;
  mapping(bytes32 => PairSpecificMappingConfig) internal _pairSpecificMappingConfig;

  constructor(
    ITransformerRegistry _registry,
    ITokenPriceOracle _underlyingOracle,
    address _superAdmin,
    address[] memory _initialAdmins
  ) {
    if (address(_registry) == address(0) || address(_underlyingOracle) == address(0) || _superAdmin == address(0)) revert ZeroAddress();
    REGISTRY = _registry;
    UNDERLYING_ORACLE = _underlyingOracle;
    // We are setting the super admin role as its own admin so we can transfer it
    _setRoleAdmin(SUPER_ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setRoleAdmin(ADMIN_ROLE, SUPER_ADMIN_ROLE);
    _setupRole(SUPER_ADMIN_ROLE, _superAdmin);
    for (uint256 i; i < _initialAdmins.length; i++) {
      _setupRole(ADMIN_ROLE, _initialAdmins[i]);
    }
  }

  /// @inheritdoc ITransformerOracle
  function getMappingForPair(address _tokenA, address _tokenB) public view virtual returns (address _mappedTokenA, address _mappedTokenB) {
    (ITransformer _transformerTokenA, ITransformer _transformerTokenB) = _getTransformers(_tokenA, _tokenB);
    _mappedTokenA = _mapToUnderlyingIfExists(_tokenA, _transformerTokenA);
    _mappedTokenB = _mapToUnderlyingIfExists(_tokenB, _transformerTokenB);
  }

  /// @inheritdoc ITransformerOracle
  function pairSpecificMappingConfig(address _tokenA, address _tokenB) public view virtual returns (PairSpecificMappingConfig memory) {
    return _pairSpecificMappingConfig[_keyForPair(_tokenA, _tokenB)];
  }

  /// @inheritdoc ITransformerOracle
  function shouldMapToUnderlying(address[] calldata _dependents) external onlyRole(ADMIN_ROLE) {
    for (uint256 i; i < _dependents.length; i++) {
      willAvoidMappingToUnderlying[_dependents[i]] = false;
    }
    emit DependentsWillMapToUnderlying(_dependents);
  }

  /// @inheritdoc ITransformerOracle
  function avoidMappingToUnderlying(address[] calldata _dependents) external onlyRole(ADMIN_ROLE) {
    for (uint256 i; i < _dependents.length; i++) {
      willAvoidMappingToUnderlying[_dependents[i]] = true;
    }
    emit DependentsWillAvoidMappingToUnderlying(_dependents);
  }

  /// @inheritdoc ITransformerOracle
  function setPairSpecificMappingConfig(PairSpecificMappingConfigToSet[] calldata _config) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _config.length; ) {
      PairSpecificMappingConfigToSet memory _pairConfigToSet = _config[i];
      // We make sure that the tokens are sorted correctly, or we reverse the config so that it ends up sorted
      (bytes32 _key, bool _mapTokenAToUnderlying, bool _mapTokenBToUnderlying) = _pairConfigToSet.tokenA < _pairConfigToSet.tokenB
        ? (
          _keyForSortedPair(_pairConfigToSet.tokenA, _pairConfigToSet.tokenB),
          _pairConfigToSet.mapTokenAToUnderlying,
          _pairConfigToSet.mapTokenBToUnderlying
        )
        : (
          _keyForSortedPair(_pairConfigToSet.tokenB, _pairConfigToSet.tokenA),
          _pairConfigToSet.mapTokenBToUnderlying,
          _pairConfigToSet.mapTokenAToUnderlying
        );
      _pairSpecificMappingConfig[_key] = PairSpecificMappingConfig(_mapTokenAToUnderlying, _mapTokenBToUnderlying, true);
      unchecked {
        i++;
      }
    }
    emit PairSpecificConfigSet(_config);
  }

  /// @inheritdoc ITransformerOracle
  function clearPairSpecificMappingConfig(Pair[] calldata _pairs) external onlyRole(ADMIN_ROLE) {
    for (uint256 i = 0; i < _pairs.length; ) {
      delete _pairSpecificMappingConfig[_keyForPair(_pairs[i].tokenA, _pairs[i].tokenB)];
      unchecked {
        i++;
      }
    }
    emit PairSpecificConfigCleared(_pairs);
  }

  /// @inheritdoc ITokenPriceOracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool) {
    (address _mappedTokenA, address _mappedTokenB) = getMappingForPair(_tokenA, _tokenB);
    return UNDERLYING_ORACLE.canSupportPair(_mappedTokenA, _mappedTokenB);
  }

  /// @inheritdoc ITokenPriceOracle
  function isPairAlreadySupported(address _tokenA, address _tokenB) external view returns (bool) {
    (address _mappedTokenA, address _mappedTokenB) = getMappingForPair(_tokenA, _tokenB);
    return UNDERLYING_ORACLE.isPairAlreadySupported(_mappedTokenA, _mappedTokenB);
  }

  /// @inheritdoc ITokenPriceOracle
  function quote(
    address _tokenIn,
    uint256 _amountIn,
    address _tokenOut,
    bytes calldata _data
  ) external view returns (uint256 _amountOut) {
    (ITransformer _transformerTokenIn, ITransformer _transformerTokenOut) = _getTransformers(_tokenIn, _tokenOut);

    if (address(_transformerTokenIn) != address(0)) {
      // If token in has a transformer, then calculate how much amount it would be in underlying, and calculate the quote for that
      ITransformer.UnderlyingAmount[] memory _transformedIn = _transformerTokenIn.calculateTransformToUnderlying(_tokenIn, _amountIn);
      _tokenIn = _transformedIn[0].underlying;
      _amountIn = _transformedIn[0].amount;
    }

    if (address(_transformerTokenOut) != address(0)) {
      // If token out has a transformer, then calculate the quote for the underlying and then transform the result
      address[] memory _underlyingOut = _transformerTokenOut.getUnderlying(_tokenOut);
      uint256 _amountOutUnderlying = UNDERLYING_ORACLE.quote(_tokenIn, _amountIn, _underlyingOut[0], _data);
      return _transformerTokenOut.calculateTransformToDependent(_tokenOut, _toUnderlyingAmount(_underlyingOut[0], _amountOutUnderlying));
    }

    return UNDERLYING_ORACLE.quote(_tokenIn, _amountIn, _tokenOut, _data);
  }

  /// @inheritdoc ITokenPriceOracle
  function addOrModifySupportForPair(
    address _tokenA,
    address _tokenB,
    bytes calldata _data
  ) external {
    (address _mappedTokenA, address _mappedTokenB) = getMappingForPair(_tokenA, _tokenB);
    UNDERLYING_ORACLE.addOrModifySupportForPair(_mappedTokenA, _mappedTokenB, _data);
  }

  /// @inheritdoc ITokenPriceOracle
  function addSupportForPairIfNeeded(
    address _tokenA,
    address _tokenB,
    bytes calldata _data
  ) external {
    (address _mappedTokenA, address _mappedTokenB) = getMappingForPair(_tokenA, _tokenB);
    UNDERLYING_ORACLE.addSupportForPairIfNeeded(_mappedTokenA, _mappedTokenB, _data);
  }

  /// @inheritdoc IERC165
  function supportsInterface(bytes4 _interfaceId) public view override(AccessControl, BaseOracle) returns (bool) {
    return
      _interfaceId == type(ITransformerOracle).interfaceId ||
      AccessControl.supportsInterface(_interfaceId) ||
      BaseOracle.supportsInterface(_interfaceId);
  }

  /**
   * @notice Takes a token and a associated transformer (could not exist). If the transformer exists, this
   *         function will return the underlying token. If it doesn't exist, then it will return the given token
   */
  function _mapToUnderlyingIfExists(address _token, ITransformer _transformer) internal view returns (address) {
    if (address(_transformer) == address(0)) {
      return _token;
    }
    address[] memory _underlying = _transformer.getUnderlying(_token);
    return _underlying[0];
  }

  function _getTransformers(address _tokenA, address _tokenB)
    internal
    view
    virtual
    returns (ITransformer _transformerTokenA, ITransformer _transformerTokenB)
  {
    address[] memory _tokens = new address[](2);
    _tokens[0] = _tokenA;
    _tokens[1] = _tokenB;
    ITransformer[] memory _transformers = REGISTRY.transformers(_tokens);
    _transformerTokenA = _transformers[0];
    _transformerTokenB = _transformers[1];

    bool _tokenAHasTransformer = address(_transformerTokenA) != address(0);
    bool _tokenBHasTransformer = address(_transformerTokenB) != address(0);

    if (_tokenAHasTransformer || _tokenBHasTransformer) {
      bool _avoidMappingTokenA = false;
      bool _avoidMappingTokenB = false;

      PairSpecificMappingConfig memory _config = pairSpecificMappingConfig(_tokenA, _tokenB);
      if (_config.isSet) {
        _avoidMappingTokenA = _tokenAHasTransformer && (_tokenA < _tokenB ? !_config.mapTokenAToUnderlying : !_config.mapTokenBToUnderlying);
        _avoidMappingTokenB = _tokenBHasTransformer && (_tokenA < _tokenB ? !_config.mapTokenBToUnderlying : !_config.mapTokenAToUnderlying);
      } else {
        _avoidMappingTokenA = _tokenAHasTransformer && willAvoidMappingToUnderlying[_tokenA];
        _avoidMappingTokenB = _tokenBHasTransformer && willAvoidMappingToUnderlying[_tokenB];
      }

      if (_avoidMappingTokenA) {
        _transformerTokenA = ITransformer(address(0));
      }

      if (_avoidMappingTokenB) {
        _transformerTokenB = ITransformer(address(0));
      }
    }
  }

  function _toUnderlyingAmount(address _underlying, uint256 _amount)
    internal
    pure
    returns (ITransformer.UnderlyingAmount[] memory _underlyingAmount)
  {
    _underlyingAmount = new ITransformer.UnderlyingAmount[](1);
    _underlyingAmount[0].underlying = _underlying;
    _underlyingAmount[0].amount = _amount;
  }

  function _keyForPair(address _tokenA, address _tokenB) internal pure returns (bytes32) {
    (address __tokenA, address __tokenB) = TokenSorting.sortTokens(_tokenA, _tokenB);
    return _keyForSortedPair(__tokenA, __tokenB);
  }

  function _keyForSortedPair(address _tokenA, address _tokenB) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_tokenA, _tokenB));
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@mean-finance/transformers/solidity/interfaces/ITransformerRegistry.sol';
import './ITokenPriceOracle.sol';

/**
 * @title An implementation of `ITokenPriceOracle` that handles transformations between tokens
 * @notice This oracle takes the transformer registry, and will transform some dependent tokens into their underlying
 *         tokens before quoting. We do this because it's hard to quote `yield-bearing(USDC) => yield-bearing(ETH)`.
 *         But we can easily do something like `yield-bearing(USDC) => USDC => ETH => yield-bearing(ETH)`. So the
 *         idea is to use the transformer registry to transform between dependent and their underlying, and then
 *         quote the underlyings.
 */
interface ITransformerOracle is ITokenPriceOracle {
  /// @notice How a specific pair will be mapped to their underlying tokens
  struct PairSpecificMappingConfig {
    // Whether tokenA will be mapped to its underlying (tokenA < tokenB)
    bool mapTokenAToUnderlying;
    // Whether tokenB will be mapped to its underlying (tokenA < tokenB)
    bool mapTokenBToUnderlying;
    // Whether the config is set
    bool isSet;
  }

  /// @notice Pair-specifig mapping configuration to set
  struct PairSpecificMappingConfigToSet {
    // One of the pair's tokens
    address tokenA;
    // The other of the pair's tokens
    address tokenB;
    // Whether to map tokenA to its underlying
    bool mapTokenAToUnderlying;
    // Whether to map tokenB to its underlying
    bool mapTokenBToUnderlying;
  }

  /// @notice A pair of tokens
  struct Pair {
    // One of the pair's tokens
    address tokenA;
    // The other of the pair's tokens
    address tokenB;
  }

  /// @notice Thrown when a parameter is the zero address
  error ZeroAddress();

  /**
   * @notice Emitted when new dependents are set to avoid mapping to their underlying counterparts
   * @param dependents The tokens that will avoid mapping
   */
  event DependentsWillAvoidMappingToUnderlying(address[] dependents);

  /**
   * @notice Emitted when dependents are set to map to their underlying counterparts
   * @param dependents The tokens that will map to underlying
   */
  event DependentsWillMapToUnderlying(address[] dependents);

  /**
   * @notice Emitted when dependents pair-specific mapping config is set
   * @param config The config that was set
   */
  event PairSpecificConfigSet(PairSpecificMappingConfigToSet[] config);

  /**
   * @notice Emitted when dependents pair-specific mapping config is cleared
   * @param pairs The pairs that had their config cleared
   */
  event PairSpecificConfigCleared(Pair[] pairs);

  /**
   * @notice Returns the address of the transformer registry
   * @dev Cannot be modified
   * @return The address of the transformer registry
   */
  function REGISTRY() external view returns (ITransformerRegistry);

  /**
   * @notice Returns the address of the underlying oracle
   * @dev Cannot be modified
   * @return The address of the underlying oracle
   */
  function UNDERLYING_ORACLE() external view returns (ITokenPriceOracle);

  /**
   * @notice Returns whether the given dependent will avoid mapping to their underlying counterparts
   * @param dependent The dependent token to check
   * @return Whether the given dependent will avoid mapping to their underlying counterparts
   */
  function willAvoidMappingToUnderlying(address dependent) external view returns (bool);

  /**
   * @notice Takes a pair of tokens, and maps them to their underlying counterparts if they exist, and if they
   *         haven't been configured to avoid mapping. Pair-specific config will be prioritized, but if it isn't
   *         set, then global config will be used.
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   * @return mappedTokenA tokenA's underlying token, if exists and isn't configured to avoid mapping.
   *                      Otherwise tokenA
   * @return mappedTokenB tokenB's underlying token, if exists and isn't configured to avoid mapping.
   *                      Otherwise tokenB
   */
  function getMappingForPair(address tokenA, address tokenB) external view returns (address mappedTokenA, address mappedTokenB);

  /**
   * @notice Returns any pair-specific mapping configuration for the given tokens
   * @dev tokenA and tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
   * @param tokenA One of the pair's tokens
   * @param tokenB The other of the pair's tokens
   */
  function pairSpecificMappingConfig(address tokenA, address tokenB) external view returns (PairSpecificMappingConfig memory);

  /**
   * @notice Determines that the given dependents will avoid mapping to their underlying counterparts, and
   *         instead perform quotes with their own addreses. This comes in handy with situations such as
   *         ETH/WETH, where some oracles use WETH instead of ETH
   * @param dependents The dependent tokens that should avoid mapping to underlying
   */
  function avoidMappingToUnderlying(address[] calldata dependents) external;

  /**
   * @notice Determines that the given dependents go back to mapping to their underlying counterparts (the
   *         default behaviour)
   * @param dependents The dependent tokens that should go back to mapping to underlying
   */
  function shouldMapToUnderlying(address[] calldata dependents) external;

  /**
   * @notice Determines how the given pairs should be mapped to their underlying tokens
   * @param config A list of pairs to configure
   */
  function setPairSpecificMappingConfig(PairSpecificMappingConfigToSet[] calldata config) external;

  /**
   * @notice Cleares any pair-specific mapping config for the given list of pairs
   * @param pairs The pairs that will have their config cleared
   */
  function clearPairSpecificMappingConfig(Pair[] calldata pairs) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import './ITransformer.sol';

/**
 * @title A registry for all existing transformers
 * @notice This contract will contain all registered transformers and act as proxy. When called
 *         the registry will find the corresponding transformer and delegate the call to it. If no
 *         transformer is found, then it will fail
 */
interface ITransformerRegistry is ITransformer {
  /// @notice An association between a transformer, and some of its dependentes
  struct TransformerRegistration {
    address transformer;
    address[] dependents;
  }

  /**
   * @notice Thrown when trying to register a dependent to an address that is not a transformer
   * @param account The account that was not a transformer
   */
  error AddressIsNotTransformer(address account);

  /**
   * @notice Thrown when trying to execute an action with a dependent that has no transformer
   *          associated
   * @param dependent The dependent that didn't have a transformer
   */
  error NoTransformerRegistered(address dependent);

  /**
   * @notice Emitted when new dependents are registered
   * @param registrations The dependents that were registered
   */
  event TransformersRegistered(TransformerRegistration[] registrations);

  /**
   * @notice Emitted when dependents are removed from the registry
   * @param dependents The dependents that were removed
   */
  event TransformersRemoved(address[] dependents);

  /**
   * @notice Returns the registered transformer for the given dependents
   * @param dependents The dependents to get the transformer for
   * @return The registered transformers, or the zero address if there isn't any
   */
  function transformers(address[] calldata dependents) external view returns (ITransformer[] memory);

  /**
   * @notice Sets a new registration for the given dependents
   * @dev Can only be called by admin
   * @param registrations The associations to register
   */
  function registerTransformers(TransformerRegistration[] calldata registrations) external;

  /**
   * @notice Removes registration for the given dependents
   * @dev Can only be called by admin
   * @param dependents The associations to remove
   */
  function removeTransformers(address[] calldata dependents) external;

  /**
   * @notice Executes a transformation to the underlying tokens, by taking the caller's entire
   *         dependent balance. This is meant to be used as part of a multi-hop swap
   * @dev This function was made payable, so that it could be multicalled when msg.value > 0
   * @param dependent The address of the dependent token
   * @param recipient The address that would receive the underlying tokens
   * @param minAmountOut The minimum amount of underlying that the caller expects to get. Will fail
   *                     if less is received. As a general rule, the underlying tokens should
   *                     be provided in the same order as `getUnderlying` returns them
   * @param deadline A deadline when the transaction becomes invalid
   * @return The transformed amount in each of the underlying tokens
   */
  function transformAllToUnderlying(
    address dependent,
    address recipient,
    UnderlyingAmount[] calldata minAmountOut,
    uint256 deadline
  ) external payable returns (UnderlyingAmount[] memory);

  /**
   * @notice Executes a transformation to the dependent token, by taking the caller's entire
   *         underlying balance. This is meant to be used as part of a multi-hop swap
   * @dev This function will not work when the underlying token is ETH/MATIC/BNB, since it can't be taken from the caller
   *      This function was made payable, so that it could be multicalled when msg.value > 0
   * @param dependent The address of the dependent token
   * @param recipient The address that would receive the dependent tokens
   * @param minAmountOut The minimum amount of dependent that the caller expects to get. Will fail
   *                     if less is received
   * @param deadline A deadline when the transaction becomes invalid
   * @return amountDependent The transformed amount in the dependent token
   */
  function transformAllToDependent(
    address dependent,
    address recipient,
    uint256 minAmountOut,
    uint256 deadline
  ) external payable returns (uint256 amountDependent);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/**
 * @title A contract that can map between one token and their underlying counterparts, and vice-versa
 * @notice This contract defines the concept of dependent tokens. These are tokens that depend on one or more underlying tokens,
 *         they can't exist on their own. This concept can apply to some known types of tokens, such as:
 *           - Wrappers (WETH/WMATIC/WBNB)
 *           - ERC-4626 tokens
 *           - LP tokens
 *         Now, transformers are smart contract that knows how to map dependent tokens into their underlying counterparts,
 *         and vice-versa. We are doing this so that we can abstract the way tokens can be transformed between each other
 * @dev All non-view functions were made payable, so that they could be multicalled when msg.value > 0
 */
interface ITransformer {
  /// @notice An amount of an underlying token
  struct UnderlyingAmount {
    address underlying;
    uint256 amount;
  }

  /// @notice Thrown when the underlying input is not valid for the used transformer
  error InvalidUnderlyingInput();

  /// @notice Thrown when the transformation provides less output than expected
  error ReceivedLessThanExpected(uint256 received);

  /// @notice Thrown when the transformation needs more input than expected
  error NeededMoreThanExpected(uint256 needed);

  /// @notice Thrown when a transaction is executed after the deadline has passed
  error TransactionExpired();

  /**
   * @notice Returns the addresses of all the underlying tokens, for the given dependent
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @return The addresses of all the underlying tokens
   */
  function getUnderlying(address dependent) external view returns (address[] memory);

  /**
   * @notice Calculates how much would the transformation to the underlying tokens return
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @param amountDependent The amount to transform
   * @return The transformed amount in each of the underlying tokens
   */
  function calculateTransformToUnderlying(address dependent, uint256 amountDependent) external view returns (UnderlyingAmount[] memory);

  /**
   * @notice Calculates how much would the transformation to the dependent token return
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @param underlying The amounts of underlying tokens to transform
   * @return amountDependent The transformed amount in the dependent token
   */
  function calculateTransformToDependent(address dependent, UnderlyingAmount[] calldata underlying)
    external
    view
    returns (uint256 amountDependent);

  /**
   * @notice Calculates how many dependent tokens are needed to transform to the expected
   *         amount of underlying
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @param expectedUnderlying The expected amounts of underlying tokens
   * @return neededDependent The amount of dependent needed
   */
  function calculateNeededToTransformToUnderlying(address dependent, UnderlyingAmount[] calldata expectedUnderlying)
    external
    view
    returns (uint256 neededDependent);

  /**
   * @notice Calculates how many underlying tokens are needed to transform to the expected
   *         amount of dependent
   * @dev This function must be unaware of context. The returned values must be the same,
   *      regardless of who the caller is
   * @param dependent The address of the dependent token
   * @param expectedDependent The expected amount of dependent tokens
   * @return neededUnderlying The amount of underlying tokens needed
   */
  function calculateNeededToTransformToDependent(address dependent, uint256 expectedDependent)
    external
    view
    returns (UnderlyingAmount[] memory neededUnderlying);

  /**
   * @notice Executes the transformation to the underlying tokens
   * @param dependent The address of the dependent token
   * @param amountDependent The amount to transform
   * @param recipient The address that would receive the underlying tokens
   * @param minAmountOut The minimum amount of underlying that the caller expects to get. Will fail
   *                     if less is received. As a general rule, the underlying tokens should
   *                     be provided in the same order as `getUnderlying` returns them
   * @param deadline A deadline when the transaction becomes invalid
   * @return The transformed amount in each of the underlying tokens
   */
  function transformToUnderlying(
    address dependent,
    uint256 amountDependent,
    address recipient,
    UnderlyingAmount[] calldata minAmountOut,
    uint256 deadline
  ) external payable returns (UnderlyingAmount[] memory);

  /**
   * @notice Executes the transformation to the dependent token
   * @param dependent The address of the dependent token
   * @param underlying The amounts of underlying tokens to transform
   * @param recipient The address that would receive the dependent tokens
   * @param minAmountOut The minimum amount of dependent that the caller expects to get. Will fail
   *                     if less is received
   * @param deadline A deadline when the transaction becomes invalid
   * @return amountDependent The transformed amount in the dependent token
   */
  function transformToDependent(
    address dependent,
    UnderlyingAmount[] calldata underlying,
    address recipient,
    uint256 minAmountOut,
    uint256 deadline
  ) external payable returns (uint256 amountDependent);

  /**
   * @notice Transforms dependent tokens to an expected amount of underlying tokens
   * @param dependent The address of the dependent token
   * @param expectedUnderlying The expected amounts of underlying tokens
   * @param recipient The address that would receive the underlying tokens
   * @param maxAmountIn The maximum amount of dependent that the caller is willing to spend.
   *                    Will fail more is needed
   * @param deadline A deadline when the transaction becomes invalid
   * @return spentDependent The amount of spent dependent tokens
   */
  function transformToExpectedUnderlying(
    address dependent,
    UnderlyingAmount[] calldata expectedUnderlying,
    address recipient,
    uint256 maxAmountIn,
    uint256 deadline
  ) external payable returns (uint256 spentDependent);

  /**
   * @notice Transforms underlying tokens to an expected amount of dependent tokens
   * @param dependent The address of the dependent token
   * @param expectedDependent The expected amounts of dependent tokens
   * @param recipient The address that would receive the underlying tokens
   * @param maxAmountIn The maximum amount of underlying that the caller is willing to spend.
   *                    Will fail more is needed. As a general rule, the underlying tokens should
   *                    be provided in the same order as `getUnderlying` returns them
   * @param deadline A deadline when the transaction becomes invalid
   * @return spentUnderlying The amount of spent underlying tokens
   */
  function transformToExpectedDependent(
    address dependent,
    uint256 expectedDependent,
    address recipient,
    UnderlyingAmount[] calldata maxAmountIn,
    uint256 deadline
  ) external payable returns (UnderlyingAmount[] memory spentUnderlying);
}