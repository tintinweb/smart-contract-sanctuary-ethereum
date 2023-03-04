// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: Ridotto Core License

/*
.------..------..------..------..------..------.     .------..------..------.
|G.--. ||L.--. ||O.--. ||B.--. ||A.--. ||L.--. |.-.  |R.--. ||N.--. ||G.--. |
| :/\: || :/\: || :/\: || :(): || (\/) || :/\: ((5)) | :(): || :(): || :/\: |
| :\/: || (__) || :\/: || ()() || :\/: || (__) |'-.-.| ()() || ()() || :\/: |
| '--'G|| '--'L|| '--'O|| '--'B|| '--'A|| '--'L| ((1)) '--'R|| '--'N|| '--'G|
`------'`------'`------'`------'`------'`------'  '-'`------'`------'`------'
*/

pragma solidity ^0.8.9;

import "./IGlobalRngEvents.sol";

interface IGlobalRng is IGlobalRngEvents {
    struct provider {
        string name;
        bool isActive;
        address providerAddress;
        uint256 gasLimit;
        uint256[6] paramData;
    }

    function providerCounter() external view returns (uint256);

    function requestRandomWords(uint256 _pId, bytes memory _functionData) external returns (uint256);

    function viewRandomResult(uint256 _pId, uint256 _callCount) external view returns (uint256);

    fallback() external;

    function addProvider(provider memory _providerInfo) external returns (uint256);

    function chainlinkPId() external view returns (uint256);

    function randomizerId() external view returns (uint256);

    function configureProvider(uint256 _pId, provider memory _providerInfo) external;

    function providerId(address) external view returns (uint256);

    function providers(
        uint256
    ) external view returns (string memory name, bool isActive, address providerAddress, uint256 gasLimit);

    function rawFulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords) external;

    function randomizerCallback(uint256 _id, bytes32 _value) external;

    function reqIds(uint256) external view returns (uint256);

    function result(uint256, uint256) external view returns (uint256);

    function totalCallCount() external view returns (uint256);
}

// SPDX-License-Identifier: Ridotto Core License

/*
.------..------..------..------..------..------.     .------..------..------.
|G.--. ||L.--. ||O.--. ||B.--. ||A.--. ||L.--. |.-.  |R.--. ||N.--. ||G.--. |
| :/\: || :/\: || :/\: || :(): || (\/) || :/\: ((5)) | :(): || :(): || :/\: |
| :\/: || (__) || :\/: || ()() || :\/: || (__) |'-.-.| ()() || ()() || :\/: |
| '--'G|| '--'L|| '--'O|| '--'B|| '--'A|| '--'L| ((1)) '--'R|| '--'N|| '--'G|
`------'`------'`------'`------'`------'`------'  '-'`------'`------'`------'
*/

pragma solidity ^0.8.9;

interface IGlobalRngEvents {
    event Initialised();

    event newRngRequest(uint256 providerId, uint256 reqId, address requester);

    event setProvider(uint256 providerId, string providerName, bool providerStatus, address providerAddress);

    event createProvider(uint256 providerId);

    event newRngResult(uint256 pId, uint256 id, uint256 result);
}

// SPDX-License-Identifier: Ridotto Core License

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*#/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#(#####/&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*##########(*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//###############/,@@@@#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*####################((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@(/#########################//@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@*#############PLAY#############(*@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*(###############################/(@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&.###########################,@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(#####################/(@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@/(#/,@@@@@@@@@@*.#################*@@@@@@@@@@@%(#/(@@@@@@@@@@@@@@
@@@@@@@@@@@@%,#######/@@@@@@@@@@@((###########*#@@@@@@@@@@@/#######*@@@@@@@@@@@@
@@@@@@@@@@,(###########/,@@@@@@@@@@(.#######,&@@@@@@@@@@%(###########/#@@@@@@@@@
@@@@@@@&,################# @@@@@@@@@@@.(#/(@@@@@@@@@@@/#################*@@@@@@@
@@@@@*(#####################*,@@@@@@@@@@@@@@@@@@@@@/(#####################/*@@@@
@@&*##########################(,@@@@@@@@@@@@@@@@@/###########################*@@
.(#############BUILD#############,*@@@@@@@@@@@#(##############EARN#############/
@###############################(/@@@@@@@@@@@@@*################################
@@@/(#########################/@@@@@@@@@@@@@@@@@@//#########################//@@
@@@@@//####################(/@@@@@@@@@@@@@@@@@@@@@@@*##################### @@@@@
@@@@@@@@@(###############*@@@@@@@@@@@@(###(@@@@@@@@@@@/(###############/ @@@@@@@
@@@@@@@@@@%*##########(*%@@@@@@@@@@/########([email protected]@@@@@@@@@@.###########[email protected]@@@@@@@@@
@@@@@@@@@@@@@&/#####/&@@@@@@@@@@@(#############,(@@@@@@@@@@#*#####((@@@@@@@@@@@@
@@@@@@@@@@@@@@@**(/@@@@@@@@@@@/##################([email protected]@@@@@@@@@@,(,@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@(#######################,#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@#############################([email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@&(#################################,(@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@#######################################(,@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@.###########################################,@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Ridotto Lottery  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

pragma solidity ^0.8.9;

import "./IRidottoLotteryEvents.sol";

interface IRidottoLottery is IRidottoLotteryEvents {
    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }
    struct Lottery {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 priceTicketInToken;
        uint256 discountDivisor;
        uint256[6] rewardsBreakdown;
        uint256 treasuryFee;
        uint256[6] tokenPerBracket;
        uint256[6] countWinnersPerBracket;
        uint256 firstTicketId;
        uint256 firstTicketIdNextLottery;
        uint256 amountCollectedInLotteryToken;
        uint32 finalNumber;
        uint256 incentiveRewards;
    }

    function MAX_INCENTIVE_REWARD() external view returns (uint256);

    function MAX_TREASURY_FEE() external view returns (uint256);

    function MIN_DISCOUNT_DIVISOR() external view returns (uint256);

    function OPERATOR_ROLE() external view returns (bytes32);

    function autoInjection() external view returns (bool);

    function buyForOthers(
        uint256 _lotteryId,
        address[] memory _receivers
    ) external;

    function buyTickets(uint256 _lotteryId, uint8 _number) external;

    function calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) external pure returns (uint256);

    function changeIncentivePercent(uint256 _incentivePercent) external;

    function changeLotteryParams(
        uint256 _startTime,
        uint256 _priceTicketInLotteryToken,
        uint256 _discountDivisor,
        uint256[6] memory _rewardsBreakdown,
        uint256 _treasuryFee
    ) external;

    function changeLotteryPeriodicity(uint256 _lotteryPeriodicity) external;

    function claimTickets(
        uint256 _lotteryId,
        uint256[] memory _ticketIds,
        uint32[] memory _brackets
    ) external;

    function closeLottery(uint256 _lotteryId) external;

    function currentLotteryId() external view returns (uint256);

    function currentTicketId() external view returns (uint256);

    function drawFinalNumberAndMakeLotteryClaimable(
        uint256 _lotteryId
    ) external;

    function getTime() external view returns (uint256);

    function incentivePercent() external view returns (uint256);

    function init() external;

    function injectFunds(uint256 _lotteryId, uint256 _amount) external;

    function lotteryPeriodicity() external view returns (uint256);

    function maxNumberReceiversBuyForOthers() external view returns (uint256);

    function maxNumberTicketsPerBuy() external view returns (uint256);

    function maxNumberTicketsPerClaim() external view returns (uint256);

    function maxTicketPrice() external view returns (uint256);

    function minLotteryPeriodicity() external view returns (uint256);

    function minTicketPrice() external view returns (uint256);

    function nextLotteryParamchanged() external view returns (bool);

    function pause() external;

    function pendingInjectionNextLottery() external view returns (uint256);

    function providerCallParam() external view returns (bytes memory);

    function providerId() external view returns (uint256);

    function recoverWrongTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external;

    function reqIds(uint256) external view returns (uint256);

    function setAutoInjection(bool _autoInjection) external;

    function setLoterryMinPeriodicity(uint256 _minLotteryPeriodicity) external;

    function setMaxBuyForOthers(
        uint256 _maxNumberReceiversBuyForOthers
    ) external;

    function setMaxNumberTicketsPerBuy(
        uint256 _maxNumberTicketsPerBuy
    ) external;

    function setMaxNumberTicketsPerClaim(
        uint256 _maxNumberTicketsPerClaim
    ) external;

    function setMinAndMaxTicketPriceInLotteryToken(
        uint256 _minPriceTicketInLotteryToken,
        uint256 _maxPriceTicketInLotteryToken
    ) external;

    function setRngProvider(
        address _rng,
        uint256 _piD,
        bytes calldata _providerCallParam
    ) external;

    function setTreasuryAddress(address _treasuryAddress) external;

    function startInitialRound(
        address _TokenAddress,
        uint256 _lotteryPeriodicity,
        uint256 _incentivePercent,
        uint256 _priceTicketInLotteryToken,
        uint256 _discountDivisor,
        uint256[6] memory _rewardsBreakdown,
        uint256 _treasuryFee
    ) external;

    function startLottery() external;

    function treasuryAddress() external view returns (address);

    function unPause() external;

    function viewLottery(
        uint256 _lotteryId
    ) external view returns (Lottery memory);

    function viewNumbersAndStatusesForTicketIds(
        uint256[] memory _ticketIds
    ) external view returns (uint32[] memory, bool[] memory);

    function viewRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint32 _bracket
    ) external view returns (uint256);

    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (uint256[] memory, uint32[] memory, bool[] memory, uint256);
}

// SPDX-License-Identifier: Ridotto Core License

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*#/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#(#####/&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*##########(*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//###############/,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*####################((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@(/#########################//@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@*#############PLAY#############(*@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*(###############################/(@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&.###########################,@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(#####################/(@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@/(#/,@@@@@@@@@@*.#################*@@@@@@@@@@@%(#/(@@@@@@@@@@@@@@
@@@@@@@@@@@@%,#######/@@@@@@@@@@@((###########*#@@@@@@@@@@@/#######*@@@@@@@@@@@@
@@@@@@@@@@,(###########/,@@@@@@@@@@(.#######,&@@@@@@@@@@%(###########/#@@@@@@@@@
@@@@@@@&,################# @@@@@@@@@@@.(#/(@@@@@@@@@@@/#################*@@@@@@@
@@@@@*(#####################*,@@@@@@@@@@@@@@@@@@@@@/(#####################/*@@@@
@@&*##########################(,@@@@@@@@@@@@@@@@@/###########################*@@
.(#############BUILD#############,*@@@@@@@@@@@#(##############EARN#############/
@###############################(/@@@@@@@@@@@@@*################################
@@@/(#########################/@@@@@@@@@@@@@@@@@@//#########################//@@
@@@@@//####################(/@@@@@@@@@@@@@@@@@@@@@@@*##################### @@@@@
@@@@@@@@@(###############*@@@@@@@@@@@@(###(@@@@@@@@@@@/(###############/ @@@@@@@
@@@@@@@@@@%*##########(*%@@@@@@@@@@/########([email protected]@@@@@@@@@@.###########[email protected]@@@@@@@@@
@@@@@@@@@@@@@&/#####/&@@@@@@@@@@@(#############,(@@@@@@@@@@#*#####((@@@@@@@@@@@@
@@@@@@@@@@@@@@@**(/@@@@@@@@@@@/##################([email protected]@@@@@@@@@@,(,@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@(#######################,#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@#############################([email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@&(#################################,(@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@#######################################(,@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@.###########################################,@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Ridotto Lottery  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

pragma solidity ^0.8.9;

interface IRidottoLotteryEvents {
    event AdminTokenRecovery(address token, uint256 amount);
    event Initialised();
    event LotteryClose(
        uint256 indexed lotteryId,
        uint256 firstTicketIdNextLottery
    );
    event LotteryInjection(uint256 indexed lotteryId, uint256 injectedAmount);
    event LotteryNumberDrawn(
        uint256 indexed lotteryId,
        uint256 finalNumber,
        uint256 countWinningTickets
    );
    event LotteryOpen(
        uint256 indexed lotteryId,
        uint256 startTime,
        uint256 endTime,
        uint256 priceTicketInToken,
        uint256 firstTicketId,
        uint256 injectedAmount
    );
    event NewRandomGenerator(address indexed globalRng);
    event NewTreasuryAddresses(address treasury);
    event Subscription(
        address indexed user,
        uint256 round,
        uint32[] ticketNumbers
    );
    event TicketsClaim(
        address indexed claimer,
        uint256 amount,
        uint256 indexed lotteryId,
        uint256 numberTickets
    );
    event TicketsPurchase(
        address indexed buyer,
        uint256 indexed lotteryId,
        uint256 numberTickets,
        uint32[] ticketNumbers
    );
}

// SPDX-License-Identifier: Ridotto Core License

/*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*#/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#(#####/&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*##########(*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//###############/,@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@*####################((@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@(/#########################//@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@*#############PLAY#############(*@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@*(###############################/(@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@&.###########################,@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@%(#####################/(@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@/(#/,@@@@@@@@@@*.#################*@@@@@@@@@@@%(#/(@@@@@@@@@@@@@@
@@@@@@@@@@@@%,#######/@@@@@@@@@@@((###########*#@@@@@@@@@@@/#######*@@@@@@@@@@@@
@@@@@@@@@@,(###########/,@@@@@@@@@@(.#######,&@@@@@@@@@@%(###########/#@@@@@@@@@
@@@@@@@&,################# @@@@@@@@@@@.(#/(@@@@@@@@@@@/#################*@@@@@@@
@@@@@*(#####################*,@@@@@@@@@@@@@@@@@@@@@/(#####################/*@@@@
@@&*##########################(,@@@@@@@@@@@@@@@@@/###########################*@@
.(#############BUILD#############,*@@@@@@@@@@@#(##############EARN#############/
@###############################(/@@@@@@@@@@@@@*################################
@@@/(#########################/@@@@@@@@@@@@@@@@@@//#########################//@@
@@@@@//####################(/@@@@@@@@@@@@@@@@@@@@@@@*##################### @@@@@
@@@@@@@@@(###############*@@@@@@@@@@@@(###(@@@@@@@@@@@/(###############/ @@@@@@@
@@@@@@@@@@%*##########(*%@@@@@@@@@@/########([email protected]@@@@@@@@@@.###########[email protected]@@@@@@@@@
@@@@@@@@@@@@@&/#####/&@@@@@@@@@@@(#############,(@@@@@@@@@@#*#####((@@@@@@@@@@@@
@@@@@@@@@@@@@@@**(/@@@@@@@@@@@/##################([email protected]@@@@@@@@@@,(,@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@(#######################,#@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@#############################([email protected]@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@&(#################################,(@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@#######################################(,@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@.###########################################,@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Ridotto Lottery  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@*/

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "./interfaces/IRidottoLottery.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@ridotto-io/global-rng/contracts/interfaces/IGlobalRng.sol";

/** @title Ridotto Lottery.
 * @notice It is a contract for a lottery system using
 * PsuedoRandomness provided .
 */
contract RidottoLottery is
    Initializable,
    ReentrancyGuardUpgradeable,
    IRidottoLottery,
    PausableUpgradeable,
    AccessControlUpgradeable
{
    // Lottery RNG role
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address public treasuryAddress;

    uint256 public currentLotteryId;
    uint256 public currentTicketId;

    uint256 public maxNumberTicketsPerClaim;
    uint256 public maxNumberTicketsPerBuy;
    uint256 public incentivePercent;

    uint256 public minLotteryPeriodicity;
    uint256 public lotteryPeriodicity;

    uint256 public maxTicketPrice;
    uint256 public minTicketPrice;

    uint256 public maxNumberReceiversBuyForOthers;

    uint256 public pendingInjectionNextLottery;

    uint256 public constant MIN_DISCOUNT_DIVISOR = 100;
    uint256 public constant MAX_TREASURY_FEE = 3000; // 30%
    uint256 public constant MAX_INCENTIVE_REWARD = 500; // 5%

    bool public autoInjection;

    // Chainlink VRF parameters
    uint256 public providerId;
    bytes public providerCallParam;

    // Flag to check if the lottery parameters have been nextLotteryParamchanged
    bool public nextLotteryParamchanged;

    struct Ticket {
        uint32 number;
        address owner;
        uint256 roundId;
    }

    // Mapping are cheaper than arrays
    mapping(address => uint256) private nonces;
    mapping(uint256 => Lottery) private _lotteries;
    mapping(uint256 => Ticket) private _tickets;
    mapping(address => mapping(uint256 => bool)) isSubscribed;

    mapping(uint256 => uint256) public reqIds;

    // Bracket calculator is used for verifying claims for ticket prizes
    mapping(uint32 => uint32) private _bracketCalculator;

    // Keeps track of number of ticket per unique combination for each lotteryId
    mapping(uint256 => mapping(uint32 => uint256))
        private _numberTicketsPerLotteryId;

    // Keep track of user ticket ids for a given lotteryId
    mapping(address => mapping(uint256 => uint256[]))
        private _userTicketIdsPerLotteryId;

    // Token used for lottery & globalRng address
    IERC20 public lotteryToken;
    IGlobalRng public globalRng;

    uint256 nonce;

    /**
    @dev Modifier to check if the caller is not a contract or proxy contract.
    Reverts if the caller is a contract or proxy contract.
    */
    modifier notContract() {
        require(!_isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Proxy contract not allowed");
        _;
    }

    /**
    @notice Initializes the lottery smart contract with default values and sets up admin role
    */

    function init() external initializer {
        __AccessControl_init();
        __Pausable_init();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        // Initializes a mapping
        for (uint8 i = 0; i <= 5; i++) {
            _bracketCalculator[i] = (i == 0)
                ? 1
                : _bracketCalculator[i - 1] * 10 + 1;
        }

        // Set default lottery values
        providerId = 0;
        maxTicketPrice = 50 ether;
        minTicketPrice = 0.005 ether;
        maxNumberTicketsPerClaim = 100;
        maxNumberTicketsPerBuy = 6;
        maxNumberReceiversBuyForOthers = 6;
        minLotteryPeriodicity = 10 minutes;
        autoInjection = true;
        emit Initialised();
    }

    /**
    @notice Returns the current timestamp
    @return the current timestamp in seconds since the Unix Epoch
    */
    function getTime() public view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @notice Changes the minimum lottery periodicity
     * @param _lotteryPeriodicity: new value for minimum lottery periodicity
     */
    function changeLotteryPeriodicity(
        uint256 _lotteryPeriodicity
    ) public onlyRole(OPERATOR_ROLE) {
        require(
            _lotteryPeriodicity >= minLotteryPeriodicity,
            "RidottoLottery: Invalid lottery periodicity"
        );
        lotteryPeriodicity = _lotteryPeriodicity;
    }

    /**

    @notice Sets the minimum allowed lottery periodicity
    @param _minLotteryPeriodicity: new minimum lottery periodicity value in seconds
    @dev Only the operator can call this function
    @dev The minimum allowed lottery periodicity is 1 minute
    */
    function setLoterryMinPeriodicity(
        uint256 _minLotteryPeriodicity
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _minLotteryPeriodicity >= 1 minutes,
            "RidottoLottery: Invalid lottery periodicity"
        );
        minLotteryPeriodicity = _minLotteryPeriodicity;
    }

    /**
    @notice Sets the RNG provider and provider ID
    @param _rng: address of the RNG provider
    @param _piD: provider ID
    @param _providerCallParam: provider call parameters
    @dev Require operator role, valid address and current lottery status to be different than Close
    */
    function setRngProvider(
        address _rng,
        uint256 _piD,
        bytes calldata _providerCallParam
    ) external onlyRole(OPERATOR_ROLE) {
        require(_rng != address(0), "RidottoLottery: Invalid address");
        require(
            _lotteries[currentLotteryId].status != Status.Close,
            "RidottoLottery: Pending RNG call"
        );
        globalRng = IGlobalRng(_rng);
        providerId = _piD;
        providerCallParam = _providerCallParam;
    }

    /**
    @notice Sets the incentive percent for the lottery
    @param _incentivePercent: the new incentive percent to set
    @dev Only callable by the operator role
    */
    function changeIncentivePercent(
        uint256 _incentivePercent
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _incentivePercent < MAX_INCENTIVE_REWARD,
            "RidottoLottery: Incentive percent must be less than MAX_INCENTIVE_REWARD"
        );
        incentivePercent = _incentivePercent;
    }

    /**
    @notice Buy a bulk of lottery tickets for the specified lottery and adds them to the user's tickets.
    @param _lotteryId: Id of the lottery
    @param _number: Number of tickets to buy
    Requirements:
        The lottery must be open
        The lottery must not be over
        The maximum number of tickets that can be bought at once is 6
    Effects:
        Transfers the required amount of lottery token to this contract
        Increments the total amount collected for the lottery round
        Adds the tickets to the lottery
    Emits a TicketsPurchase event with details of the tickets purchased
    */

    function buyTickets(
        uint256 _lotteryId,
        uint8 _number
    ) external override notContract nonReentrant whenNotPaused {
        require(
            _lotteries[_lotteryId].status == Status.Open,
            "RidottoLottery: Lottery is not open"
        );
        require(
            block.timestamp < _lotteries[_lotteryId].endTime,
            "RidottoLottery: Lottery is over"
        );
        require(
            _number <= maxNumberTicketsPerBuy,
            "RidottoLottery: Can only buy 6 tickets at once"
        );

        // Calculate number of lottery token to this contract
        uint256 amountTokenToTransfer = _calculateTotalPriceForBulkTickets(
            _lotteries[_lotteryId].discountDivisor,
            _lotteries[_lotteryId].priceTicketInToken,
            _number
        );

        // Transfer lottery tokens to this contract
        lotteryToken.transferFrom(
            address(msg.sender),
            address(this),
            amountTokenToTransfer
        );

        // Increment the total amount collected for the lottery round
        _lotteries[_lotteryId]
            .amountCollectedInLotteryToken += amountTokenToTransfer;

        uint32[] memory _ticketNumbers = getRandomNumbers(msg.sender, _number);
        for (uint256 i = 0; i < _number; i++) {
            uint32 thisTicketNumber = _ticketNumbers[i];

            require(
                (thisTicketNumber >= 1000000) && (thisTicketNumber <= 1999999),
                "Outside range"
            );

            _numberTicketsPerLotteryId[_lotteryId][
                1 + (thisTicketNumber % 10)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                11 + (thisTicketNumber % 100)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                111 + (thisTicketNumber % 1000)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                1111 + (thisTicketNumber % 10000)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                11111 + (thisTicketNumber % 100000)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                111111 + (thisTicketNumber % 1000000)
            ]++;

            _userTicketIdsPerLotteryId[msg.sender][_lotteryId].push(
                currentTicketId
            );

            _tickets[currentTicketId] = Ticket({
                number: uint32(thisTicketNumber),
                owner: msg.sender,
                roundId: _lotteryId
            });

            // Increase lottery ticket number
            currentTicketId++;
        }

        emit TicketsPurchase(
            msg.sender,
            _lotteryId,
            _ticketNumbers.length,
            _ticketNumbers
        );
    }

    /**
    @notice Allows a player to buy lottery tickets for other players and add them to a lottery
    @param _lotteryId: lottery id
    @param _receivers: array of addresses of the players to buy tickets for
    */
    function buyForOthers(
        uint256 _lotteryId,
        address[] calldata _receivers
    ) external notContract nonReentrant whenNotPaused {
        require(
            _lotteries[_lotteryId].status == Status.Open,
            "RidottoLottery: Lottery is not open"
        );
        require(
            block.timestamp < _lotteries[_lotteryId].endTime,
            "RidottoLottery: Lottery is over"
        );

        require(
            _receivers.length <= maxNumberReceiversBuyForOthers,
            "RidottoLottery: Too many receivers"
        );

        uint256 amountTokenToTransfer = _calculateTotalPriceForBulkTickets(
            _lotteries[_lotteryId].discountDivisor,
            _lotteries[_lotteryId].priceTicketInToken,
            _receivers.length
        );

        lotteryToken.transferFrom(
            address(msg.sender),
            address(this),
            amountTokenToTransfer
        );

        _lotteries[_lotteryId]
            .amountCollectedInLotteryToken += amountTokenToTransfer;

        uint32[] memory _ticketNumbers = getRandomNumbers(
            msg.sender,
            _receivers.length
        );

        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            uint32 thisTicketNumber = _ticketNumbers[i];

            require(
                (thisTicketNumber >= 1000000) && (thisTicketNumber <= 1999999),
                "Outside range"
            );

            _numberTicketsPerLotteryId[_lotteryId][
                1 + (thisTicketNumber % 10)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                11 + (thisTicketNumber % 100)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                111 + (thisTicketNumber % 1000)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                1111 + (thisTicketNumber % 10000)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                11111 + (thisTicketNumber % 100000)
            ]++;
            _numberTicketsPerLotteryId[_lotteryId][
                111111 + (thisTicketNumber % 1000000)
            ]++;

            _userTicketIdsPerLotteryId[_receivers[i]][_lotteryId].push(
                currentTicketId
            );

            _tickets[currentTicketId] = Ticket({
                number: uint32(thisTicketNumber),
                owner: _receivers[i],
                roundId: _lotteryId
            });

            // Increase lottery ticket number
            currentTicketId++;

            // Emit event for each ticket
            uint32[] memory x = new uint32[](1);
            x[0] = _ticketNumbers[i];
            emit TicketsPurchase(_receivers[i], _lotteryId, 1, x);
        }
    }

    /**
    @notice Sets the maximum number of lottery tickets that can be bought by one account for others,
    as well as the maximum number of receivers that a player can buy tickets for.
    @param _maxNumberReceiversBuyForOthers: the maximum number of receivers that a player can buy tickets for
    */
    function setMaxBuyForOthers(
        uint256 _maxNumberReceiversBuyForOthers
    ) external onlyRole(OPERATOR_ROLE) {
        maxNumberReceiversBuyForOthers = _maxNumberReceiversBuyForOthers;
    }

    /**
    @notice Claims rewards for specified tickets and brackets, transfers the reward amount in LOT token to msg.sender
    @param _lotteryId: lottery id
    @param _ticketIds: array of ticket ids to claim rewards for
    @param _brackets: array of brackets corresponding to each ticket to claim rewards for
    */
    function claimTickets(
        uint256 _lotteryId,
        uint256[] calldata _ticketIds,
        uint32[] calldata _brackets
    ) external override notContract nonReentrant whenNotPaused {
        require(
            _ticketIds.length == _brackets.length,
            "RidottoLottery: Invalid inputs"
        );
        require(
            _ticketIds.length != 0,
            "RidottoLottery: _ticketIds.length must be >0"
        );
        require(
            _ticketIds.length <= maxNumberTicketsPerClaim,
            "RidottoLottery: Too many tickets to claim"
        );
        require(
            _lotteries[_lotteryId].status == Status.Claimable,
            "RidottoLottery: Lottery is not claimable"
        );

        // Initializes the rewardInLotteryTokenToTransfer
        uint256 rewardInLotteryTokenToTransfer;

        for (uint256 i = 0; i < _ticketIds.length; i++) {
            require(_brackets[i] < 6, "Bracket out of range"); // Must be between 0 and 5

            uint256 thisTicketId = _ticketIds[i];

            require(
                _tickets[thisTicketId].roundId == _lotteryId,
                "ticket doesnt belong to given lotteryId"
            );

            require(
                msg.sender == _tickets[thisTicketId].owner,
                "RidottoLottery: Caller isn't  the ticket owner"
            );

            // Update the lottery ticket owner to 0x address
            _tickets[thisTicketId].owner = address(0);

            uint256 rewardForTicketId = _calculateRewardsForTicketId(
                _lotteryId,
                thisTicketId,
                _brackets[i]
            );

            // Check user is claiming the correct bracket
            require(
                rewardForTicketId != 0,
                "RidottoLottery: No prize for this bracket"
            );

            if (_brackets[i] != 5) {
                require(
                    _calculateRewardsForTicketId(
                        _lotteryId,
                        thisTicketId,
                        _brackets[i] + 1
                    ) == 0,
                    "RidottoLottery: Bracket must be higher"
                );
            }

            // Increment the reward to transfer
            rewardInLotteryTokenToTransfer += rewardForTicketId;
        }

        // Transfer money to msg.sender
        lotteryToken.transfer(msg.sender, rewardInLotteryTokenToTransfer);

        emit TicketsClaim(
            msg.sender,
            rewardInLotteryTokenToTransfer,
            _lotteryId,
            _ticketIds.length
        );
    }

    /**
     * @dev Close a lottery by requesting a random number from the generator.
     * Distribute incentive rewards to the operators and transfer the remaining funds to the current owner.
     * @param _lotteryId uint256 ID of the lottery
     */
    function closeLottery(
        uint256 _lotteryId
    ) external override nonReentrant whenNotPaused {
        require(
            _lotteries[_lotteryId].status == Status.Open,
            "Lottery not open"
        );
        require(
            block.timestamp > _lotteries[_lotteryId].endTime,
            "Lottery not over"
        );
        _lotteries[_lotteryId].firstTicketIdNextLottery = currentTicketId;

        // Request a random number from the generator based on a seed
        reqIds[_lotteryId] = globalRng.requestRandomWords(
            providerId,
            providerCallParam
        );

        _lotteries[_lotteryId].status = Status.Close;

        uint256 incetiveRewards = (_lotteries[_lotteryId]
            .amountCollectedInLotteryToken *
            3 *
            incentivePercent) / 10000;

        _lotteries[_lotteryId].incentiveRewards = incetiveRewards;
        _lotteries[_lotteryId].amountCollectedInLotteryToken -= incetiveRewards;
        lotteryToken.transfer(_msgSender(), incetiveRewards / 3);

        emit LotteryClose(_lotteryId, currentTicketId);
    }

    /**
    @dev Draws the final number, calculates the rewards per bracket and updates the lottery's status to claimable
    @param _lotteryId The ID of the lottery to draw the final number for and make claimable
    */
    function drawFinalNumberAndMakeLotteryClaimable(
        uint256 _lotteryId
    ) external override nonReentrant whenNotPaused {
        require(
            _lotteries[_lotteryId].status == Status.Close,
            "Lottery not close"
        );
        require(
            globalRng.viewRandomResult(providerId, reqIds[_lotteryId]) != 0,
            "Numbers not drawn"
        );

        // Calculate the finalNumber based on the randomResult generated by GLOBAL RNG
        uint256 number = globalRng.viewRandomResult(
            providerId,
            reqIds[_lotteryId]
        );
        uint32 finalNumber = uint32(1000000 + (number % 1000000));

        // Initialize a number to count addresses in the previous bracket
        uint256 numberAddressesInPreviousBracket;

        // Calculate the amount to share post-treasury fee
        uint256 amountToShareToWinners = (
            ((_lotteries[_lotteryId].amountCollectedInLotteryToken) *
                (10000 - _lotteries[_lotteryId].treasuryFee))
        ) / 10000;

        // Initializes the amount to withdraw to treasury
        uint256 amountToWithdrawToTreasury;

        // Calculate prizes in lottery token for each bracket by starting from the highest one
        for (uint32 i = 0; i < 6; i++) {
            uint32 j = 5 - i;
            uint32 transformedWinningNumber = _bracketCalculator[j] +
                (finalNumber % (uint32(10) ** (j + 1)));

            _lotteries[_lotteryId].countWinnersPerBracket[j] =
                _numberTicketsPerLotteryId[_lotteryId][
                    transformedWinningNumber
                ] -
                numberAddressesInPreviousBracket;

            // A. If number of users for this _bracket number is superior to 0
            if (
                (_numberTicketsPerLotteryId[_lotteryId][
                    transformedWinningNumber
                ] - numberAddressesInPreviousBracket) != 0
            ) {
                // B. If rewards at this bracket are > 0, calculate, else, report the numberAddresses from previous bracket
                if (_lotteries[_lotteryId].rewardsBreakdown[j] != 0) {
                    _lotteries[_lotteryId].tokenPerBracket[j] = Math.ceilDiv(
                        ((_lotteries[_lotteryId].rewardsBreakdown[j] *
                            amountToShareToWinners) /
                            (_numberTicketsPerLotteryId[_lotteryId][
                                transformedWinningNumber
                            ] - numberAddressesInPreviousBracket)),
                        10000
                    );

                    // Update numberAddressesInPreviousBracket
                    numberAddressesInPreviousBracket = _numberTicketsPerLotteryId[
                        _lotteryId
                    ][transformedWinningNumber];
                }
                // A. No lottery token to distribute, they are added to the amount to withdraw to treasury address
            } else {
                _lotteries[_lotteryId].tokenPerBracket[j] = 0;
            }
        }

        //sum of all allocations rewards
        uint256 sumOfAllAllocations = 0;
        for (
            uint32 i = 0;
            i < _lotteries[_lotteryId].rewardsBreakdown.length;
            i++
        ) {
            sumOfAllAllocations += _lotteries[_lotteryId].tokenPerBracket[i];
        }

        amountToWithdrawToTreasury =
            amountToShareToWinners -
            sumOfAllAllocations;

        // Update internal statuses for lottery
        _lotteries[_lotteryId].finalNumber = finalNumber;
        _lotteries[_lotteryId].status = Status.Claimable;

        if (autoInjection) {
            // Update the amount to inject to the next lottery
            pendingInjectionNextLottery = amountToWithdrawToTreasury;
            amountToWithdrawToTreasury = 0;
        }

        amountToWithdrawToTreasury += (_lotteries[_lotteryId]
            .amountCollectedInLotteryToken - amountToShareToWinners);

        // Transfer RDT to treasury address
        lotteryToken.transfer(treasuryAddress, amountToWithdrawToTreasury);

        // Transfer the incentive to the operator
        lotteryToken.transfer(
            _msgSender(),
            _lotteries[_lotteryId].incentiveRewards / 3
        );

        emit LotteryNumberDrawn(
            currentLotteryId,
            finalNumber,
            numberAddressesInPreviousBracket
        );
    }

    /**
    @dev Inject funds into a specific lottery.
    @param _lotteryId uint256 ID of the lottery.
    @param _amount uint256 Amount of tokens to inject.
    */
    function injectFunds(
        uint256 _lotteryId,
        uint256 _amount
    ) external override whenNotPaused {
        require(
            _lotteries[_lotteryId].status == Status.Open,
            "RidottoLottery: Lottery is not open"
        );

        lotteryToken.transferFrom(address(msg.sender), address(this), _amount);
        _lotteries[_lotteryId].amountCollectedInLotteryToken += _amount;

        emit LotteryInjection(_lotteryId, _amount);
    }

    /**
     * @notice Set the auto injection status (Inject remaining funds to the next lottery)
     * @param _autoInjection: true if auto injection is enabled
     * @dev Callable only by the contract owner
     */

    /**
    @dev Set auto-injection status for the contract.
    @param _autoInjection Flag to enable/disable auto-injection.
    */
    function setAutoInjection(
        bool _autoInjection
    ) external onlyRole(OPERATOR_ROLE) {
        autoInjection = _autoInjection;
    }

    /**
    @notice Starts the initial round of lottery with the given parameters.
    @dev Can only be called by the operator.
    @param _TokenAddress The address of the token used to buy tickets.
    @param _lotteryPeriodicity The duration of each round in seconds.
    @param _incentivePercent The percentage of the prize pool to be given as an incentive.
    @param _priceTicketInLotteryToken The price of a ticket in the lottery token.
    @param _discountDivisor The discount divisor for early ticket purchases.
    @param _rewardsBreakdown The percentage of the prize pool to be distributed among the different brackets.
    @param _treasuryFee The percentage of the prize pool to be sent to the treasury.
    */
    function startInitialRound(
        address _TokenAddress,
        uint256 _lotteryPeriodicity,
        uint256 _incentivePercent,
        uint256 _priceTicketInLotteryToken,
        uint256 _discountDivisor,
        uint256[6] calldata _rewardsBreakdown,
        uint256 _treasuryFee
    ) external onlyRole(OPERATOR_ROLE) {
        require(providerId != 0, "RidottoLottery: RNG not set");
        require(
            treasuryAddress != address(0),
            "RidottoLottery: Treasury address not set"
        );
        require(
            currentLotteryId == 0,
            "RidottoLottery: Use startLottery() to start the lottery"
        );
        currentLotteryId++;

        require(
            (_priceTicketInLotteryToken >= minTicketPrice) &&
                (_priceTicketInLotteryToken <= maxTicketPrice),
            "RidottoLottery: Ticket price is outside the allowed limits"
        );
        require(
            _discountDivisor >= MIN_DISCOUNT_DIVISOR,
            "RidottoLottery: Discount divisor is too low"
        );

        require(
            _treasuryFee <= MAX_TREASURY_FEE,
            "RidottoLottery: Treasury fee is too high"
        );

        uint256 totalRewards;
        for (uint8 i = 0; i < _rewardsBreakdown.length; i++) {
            totalRewards += _rewardsBreakdown[i];
        }
        require(
            totalRewards == 10000,
            "RidottoLottery: Rewards distribution sum must equal 10000"
        );

        // Check that the incentive is not too high
        require(
            _incentivePercent < MAX_INCENTIVE_REWARD,
            "RidottoLottery: Incentive percent must be less than MAX_INCENTIVE_REWARD"
        );

        changeLotteryPeriodicity(_lotteryPeriodicity);
        lotteryToken = IERC20(_TokenAddress);
        incentivePercent = _incentivePercent;

        _lotteries[1] = Lottery({
            status: Status.Open,
            startTime: block.timestamp,
            endTime: block.timestamp + lotteryPeriodicity,
            priceTicketInToken: _priceTicketInLotteryToken,
            discountDivisor: _discountDivisor,
            rewardsBreakdown: _rewardsBreakdown,
            treasuryFee: _treasuryFee,
            tokenPerBracket: [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ],
            countWinnersPerBracket: [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ],
            firstTicketId: 0,
            firstTicketIdNextLottery: 0,
            amountCollectedInLotteryToken: 0,
            finalNumber: 0,
            incentiveRewards: 0
        });

        pendingInjectionNextLottery = 0;

        emit LotteryOpen(
            currentLotteryId,
            block.timestamp,
            _lotteries[currentLotteryId].endTime,
            _lotteries[currentLotteryId].priceTicketInToken,
            currentTicketId,
            pendingInjectionNextLottery
        );
    }

    /**
     * @dev Allows the operator to change the parameters of the next lottery round.
     * @param _startTime The start time of the next lottery round.
     * @param _priceTicketInLotteryToken The ticket price in lottery token for the next round.
     * @param _discountDivisor The discount divisor for the next round.
     * @param _rewardsBreakdown The rewards breakdown for the next round.
     * @param _treasuryFee The treasury fee for the next round.
     */
    function changeLotteryParams(
        uint256 _startTime,
        uint256 _priceTicketInLotteryToken,
        uint256 _discountDivisor,
        uint256[6] calldata _rewardsBreakdown,
        uint256 _treasuryFee
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            (_priceTicketInLotteryToken >= minTicketPrice) &&
                (_priceTicketInLotteryToken <= maxTicketPrice),
            "RidottoLottery: Ticket price is outside the allowed limits"
        );
        require(
            _discountDivisor >= MIN_DISCOUNT_DIVISOR,
            "RidottoLottery: Discount divisor is too low"
        );

        require(
            _treasuryFee <= MAX_TREASURY_FEE,
            "RidottoLottery: Treasury fee is too high"
        );

        uint256 totalRewards;
        for (uint8 i = 0; i < _rewardsBreakdown.length; i++) {
            totalRewards += _rewardsBreakdown[i];
        }
        require(
            totalRewards == 10000,
            "RidottoLottery: Rewards distribution sum must equal 10000"
        );

        require(
            _startTime > _lotteries[currentLotteryId].endTime,
            "RidottoLottery: Start time must be after the end of the current round"
        );

        require(
            _lotteries[currentLotteryId].status == Status.Open,
            "RidottoLottery: Lottery must be initialized"
        );

        _lotteries[currentLotteryId + 1] = Lottery({
            status: Status.Pending,
            startTime: _startTime,
            endTime: _startTime + lotteryPeriodicity,
            priceTicketInToken: _priceTicketInLotteryToken,
            discountDivisor: _discountDivisor,
            rewardsBreakdown: _rewardsBreakdown,
            treasuryFee: _treasuryFee,
            tokenPerBracket: [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ],
            countWinnersPerBracket: [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ],
            firstTicketId: 0,
            firstTicketIdNextLottery: 0,
            amountCollectedInLotteryToken: 0,
            finalNumber: 0,
            incentiveRewards: 0
        });

        nextLotteryParamchanged = true;
    }

    /**
     * @dev Starts the next round of the lottery, setting its parameters and status
     * @dev Transfers incentive rewards from previous round to the caller
     * @dev Emits a `LotteryOpen` event with information about the new round
     * @dev Reverts if it's not time to start the new round or if the initial round hasn't been started yet
     */
    function startLottery() external whenNotPaused {
        require(
            (_lotteries[currentLotteryId].status == Status.Claimable),
            "Not time to start lottery"
        );
        require(currentLotteryId != 0, "use startInitialRound function");
        require(
            _lotteries[currentLotteryId + 1].startTime <= block.timestamp,
            "Ridotto: Cannot start lottery yet"
        );

        Lottery memory previous = _lotteries[currentLotteryId];

        currentLotteryId++;

        Lottery memory newLottery = Lottery({
            status: Status.Open,
            startTime: block.timestamp,
            endTime: block.timestamp + lotteryPeriodicity,
            priceTicketInToken: previous.priceTicketInToken,
            discountDivisor: previous.discountDivisor,
            rewardsBreakdown: previous.rewardsBreakdown,
            treasuryFee: previous.treasuryFee,
            tokenPerBracket: [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ],
            countWinnersPerBracket: [
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0),
                uint256(0)
            ],
            firstTicketId: currentTicketId,
            firstTicketIdNextLottery: currentTicketId,
            amountCollectedInLotteryToken: pendingInjectionNextLottery,
            finalNumber: 0,
            incentiveRewards: 0
        });

        if (nextLotteryParamchanged == true) {
            _lotteries[currentLotteryId].status = Status.Open;
            _lotteries[currentLotteryId].firstTicketId = currentTicketId;
            _lotteries[currentLotteryId]
                .firstTicketIdNextLottery = currentTicketId;
            _lotteries[currentLotteryId]
                .amountCollectedInLotteryToken = pendingInjectionNextLottery;
            _lotteries[currentLotteryId].finalNumber = 0;
            nextLotteryParamchanged = false;
        } else {
            _lotteries[currentLotteryId] = newLottery;
        }

        lotteryToken.transfer(
            _msgSender(),
            _lotteries[currentLotteryId - 1].incentiveRewards / 3
        );

        emit LotteryOpen(
            currentLotteryId,
            block.timestamp,
            _lotteries[currentLotteryId].endTime,
            _lotteries[currentLotteryId].priceTicketInToken,
            currentTicketId,
            pendingInjectionNextLottery
        );

        pendingInjectionNextLottery = 0;
    }

    /**
    @dev Allows the operator to recover any ERC20 tokens that were sent to the contract by mistake.
    @param _tokenAddress The address of the token to be recovered.
    @param _tokenAmount The amount of tokens to be recovered.
    */
    function recoverWrongTokens(
        address _tokenAddress,
        uint256 _tokenAmount
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _tokenAddress != address(lotteryToken),
            "RidottoLottery: Cannot withdraw the lottery token"
        );

        IERC20(_tokenAddress).transfer(address(msg.sender), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /**
    @dev Sets the minimum and maximum ticket price in lottery token that can be used in the current lottery.
    @param _minPriceTicketInLotteryToken The minimum ticket price in lottery token.
    @param _maxPriceTicketInLotteryToken The maximum ticket price in lottery token.
    */
    function setMinAndMaxTicketPriceInLotteryToken(
        uint256 _minPriceTicketInLotteryToken,
        uint256 _maxPriceTicketInLotteryToken
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _minPriceTicketInLotteryToken <= _maxPriceTicketInLotteryToken,
            "RidottoLottery: The minimum price must be less than the maximum price"
        );

        minTicketPrice = _minPriceTicketInLotteryToken;
        maxTicketPrice = _maxPriceTicketInLotteryToken;
    }

    /**
    @dev Sets the maximum number of tickets per buy.
    @param _maxNumberTicketsPerBuy Maximum number of tickets per buy.
    */
    function setMaxNumberTicketsPerBuy(
        uint256 _maxNumberTicketsPerBuy
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _maxNumberTicketsPerBuy != 0,
            "RidottoLottery: The maximum number of tickets per buy must be greater than 0"
        );
        maxNumberTicketsPerBuy = _maxNumberTicketsPerBuy;
    }

    /**
    @dev Set the maximum number of tickets that can be claimed per claim.
    @param _maxNumberTicketsPerClaim The maximum number of tickets per claim.
    */
    function setMaxNumberTicketsPerClaim(
        uint256 _maxNumberTicketsPerClaim
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _maxNumberTicketsPerClaim != 0,
            "RidottoLottery: The maximum number of tickets per claim must be greater than 0"
        );
        maxNumberTicketsPerClaim = _maxNumberTicketsPerClaim;
    }

    /**
    @dev Set the treasury address where a percentage of the lottery earnings will be sent.
    Only the operator can call this function.
    @param _treasuryAddress The address of the new treasury wallet.
    */
    function setTreasuryAddress(
        address _treasuryAddress
    ) external onlyRole(OPERATOR_ROLE) {
        require(
            _treasuryAddress != address(0),
            "RidottoLottery: Treasury address cannot be the zero address"
        );

        treasuryAddress = _treasuryAddress;

        emit NewTreasuryAddresses(_treasuryAddress);
    }

    /**
    @dev Calculates the total price for a bulk purchase of tickets, including discounts.
    @param _discountDivisor The divisor for the discount. For example, a value of 1000 means a 10% discount.
    @param _priceTicket The price of a single ticket.
    @param _numberTickets The number of tickets being purchased.
    @return The total price for the bulk ticket purchase, including any discounts.
    */
    function calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) external pure returns (uint256) {
        require(
            _discountDivisor >= MIN_DISCOUNT_DIVISOR,
            "Must be >= MIN_DISCOUNT_DIVISOR"
        );
        require(_numberTickets != 0, "Number of tickets must be > 0");

        return
            _calculateTotalPriceForBulkTickets(
                _discountDivisor,
                _priceTicket,
                _numberTickets
            );
    }

    /**
    @dev View the information of a lottery by ID
    @param _lotteryId The ID of the lottery to view
    @return Lottery The lottery information, as a struct
    */
    function viewLottery(
        uint256 _lotteryId
    ) external view returns (Lottery memory) {
        return _lotteries[_lotteryId];
    }

    /**
    @dev View function that returns an array of ticket numbers and their statuses for an array of ticket IDs.
    @param _ticketIds An array of ticket IDs.
    @return A tuple of arrays containing the ticket numbers and their statuses, in the same order as the input array.
    */
    function viewNumbersAndStatusesForTicketIds(
        uint256[] calldata _ticketIds
    ) external view returns (uint32[] memory, bool[] memory) {
        uint256 length = _ticketIds.length;
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            ticketNumbers[i] = _tickets[_ticketIds[i]].number;
            if (_tickets[_ticketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }

        return (ticketNumbers, ticketStatuses);
    }

    /**
     * @dev View the rewards for a specific lottery ticket.
     * @param _lotteryId ID of the lottery.
     * @param _ticketId ID of the ticket.
     * @param _bracket Bracket to check the ticket against.
     * @return The reward amount for the ticket and bracket.
     */
    function viewRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint32 _bracket
    ) external view returns (uint256) {
        // Check lottery is in claimable status
        if (_lotteries[_lotteryId].status != Status.Claimable) {
            return 0;
        }

        // Check ticketId is within range
        if (
            (_lotteries[_lotteryId].firstTicketIdNextLottery < _ticketId) &&
            (_lotteries[_lotteryId].firstTicketId >= _ticketId)
        ) {
            return 0;
        }

        return _calculateRewardsForTicketId(_lotteryId, _ticketId, _bracket);
    }

    /**
     * @notice View user ticket ids, numbers, and statuses of user for a given lottery
     * @param _user: user address
     * @param _lotteryId: lottery id
     * @param _cursor: cursor to start where to retrieve the tickets
     * @param _size: the number of tickets to retrieve
     * @return lotteryTicketIds: array of ticket ids
     * @return ticketNumbers: array of ticket numbers
     * @return ticketStatuses: array of bools indicating if a ticket is claimed or not
     * @return _cursor + length: the cursor to use for next batch
     */
    function viewUserInfoForLotteryId(
        address _user,
        uint256 _lotteryId,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        returns (uint256[] memory, uint32[] memory, bool[] memory, uint256)
    {
        uint256 length = _size;
        uint256 numberTicketsBoughtAtLotteryId = _userTicketIdsPerLotteryId[
            _user
        ][_lotteryId].length;

        if (length > (numberTicketsBoughtAtLotteryId - _cursor)) {
            length = numberTicketsBoughtAtLotteryId - _cursor;
        }

        uint256[] memory lotteryTicketIds = new uint256[](length);
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            lotteryTicketIds[i] = _userTicketIdsPerLotteryId[_user][_lotteryId][
                i + _cursor
            ];
            ticketNumbers[i] = _tickets[lotteryTicketIds[i]].number;

            // True = ticket claimed
            if (_tickets[lotteryTicketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                // ticket not claimed (includes the ones that cannot be claimed)
                ticketStatuses[i] = false;
            }
        }

        return (
            lotteryTicketIds,
            ticketNumbers,
            ticketStatuses,
            _cursor + length
        );
    }

    /**
    @notice Calculate rewards for a ticket and bracket for a given lotteryId
    @param _lotteryId: lottery id
    @param _ticketId: ticket id to calculate rewards for
    @param _bracket: bracket number
    @return the rewards amount of the ticket and bracket
    */
    function _calculateRewardsForTicketId(
        uint256 _lotteryId,
        uint256 _ticketId,
        uint32 _bracket
    ) internal view returns (uint256) {
        // Retrieve the winning number combination
        uint32 userNumber = _lotteries[_lotteryId].finalNumber;

        // Retrieve the user number combination from the ticketId
        uint32 winningTicketNumber = _tickets[_ticketId].number;

        // Apply transformation to verify the claim provided by the user is true
        uint32 transformedWinningNumber = _bracketCalculator[_bracket] +
            (winningTicketNumber % (uint32(10) ** (_bracket + 1)));

        uint32 transformedUserNumber = _bracketCalculator[_bracket] +
            (userNumber % (uint32(10) ** (_bracket + 1)));

        // Confirm that the two transformed numbers are the same, if not throw
        if (transformedWinningNumber == transformedUserNumber) {
            return _lotteries[_lotteryId].tokenPerBracket[_bracket];
        } else {
            return 0;
        }
    }

    /**
    @notice Calculates the total price in lottery token for purchasing multiple tickets with a discount
    @param _discountDivisor: the discount divisor used for the calculation
    @param _priceTicket: the price for each ticket in lottery token
    @param _numberTickets: the number of tickets being purchased
    @return The total price in lottery token for purchasing multiple tickets with a discount
    */
    function _calculateTotalPriceForBulkTickets(
        uint256 _discountDivisor,
        uint256 _priceTicket,
        uint256 _numberTickets
    ) internal pure returns (uint256) {
        return
            (_priceTicket *
                _numberTickets *
                (_discountDivisor + 1 - _numberTickets)) / _discountDivisor;
    }

    /**
    @notice Internal function to check if an address is a contract
    @param _addr: Address to check
    @return bool: True if the address is a contract, false otherwise
    */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
    @notice Generate an array of random numbers for a user
    @param _from: address of user requesting random numbers
    @param _count: number of random numbers to generate
    @return an array of randomly generated numbers
    */
    function getRandomNumbers(
        address _from,
        uint256 _count
    ) internal returns (uint32[] memory) {
        uint32[] memory numbers = new uint32[](_count);
        uint n = nonce;
        for (uint256 i = 0; i < _count; i++) {
            uint32 randomNumber = uint32(
                uint256(keccak256(abi.encode(_from, n + i + 1))) % 1000000
            ) + 1000000;
            numbers[i] = randomNumber;
        }
        nonce += n + _count;
        return numbers;
    }

    /**
     * @notice Pause the contract
     * @dev Only callable by an operator
     * @dev Reverts if the contract is already paused
     */
    function pause() external onlyRole(OPERATOR_ROLE) {
        require(!paused(), "RidottoLottery: Contract already paused");
        _pause();
    }

    /**
     * @notice Unpauses the contract
     * @dev Can only be called by an address with the OPERATOR_ROLE
     * @dev Throws an error if the contract is not paused
     */
    function unPause() external onlyRole(OPERATOR_ROLE) {
        require(paused(), "RidottoLottery: Contract already Unpaused");
        _unpause();
    }
}