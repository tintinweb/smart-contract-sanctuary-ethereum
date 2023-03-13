// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
interface IERC20PermitUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IVesting.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @title Token Generation Event
/// @dev A contract whose purpose is to distribute Governance and Preference tokens and ensure their blocking according to the settings. This contract has an active period, after which the sale of tokens stops, but additional rules related to this token - Lockup and Vesting - begin to apply.    Such a contract is considered successful if at least softcap tokens have been sold using it in the allotted time. Dependencies of TGE contracts on each other for one token - 1) before there is at least one successfully completed TGE, each subsequent created TGE is considered primary (including the very first for the token), 2) if there was at least one successful TGE for an existing token before the launch of a new TGE, then the created TGE is called secondary (and does not have a softcap, that is, any purchase makes it successful).

contract TGE is Initializable, ReentrancyGuardUpgradeable, ITGE {
    using AddressUpgradeable for address payable;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // CONSTANTS

    /// @notice Denominator for shares (such as thresholds)
    uint256 private constant DENOM = 100 * 10 ** 4;

    /// @dev Pool's ERC20 token
    IToken public token;

    /// @dev TGE info struct
    TGEInfo public info;

    /// @dev Mapping of user's address to whitelist status
    mapping(address => bool) private _isUserWhitelisted;

    /// @dev Block of TGE's creation
    uint256 public createdAt;

    /// @dev Mapping of an address to total amount of tokens purchased during TGE
    mapping(address => uint256) public purchaseOf;

    /// @dev Total amount of tokens purchased during TGE
    uint256 public totalPurchased;

    /// @dev Is vesting TVL reached. Users can claim their tokens only if vesting TVL was reached.
    bool public vestingTVLReached;

    /// @dev Is lockup TVL reached. Users can claim their tokens only if lockup TVL was reached.
    bool public lockupTVLReached;

    /// @dev Mapping of addresses to total amounts of tokens vested
    mapping(address => uint256) public vestedBalanceOf;

    /// @dev Total amount of tokens vested
    uint256 public totalVested;

    /// @dev Protocol fee
    uint256 public protocolFee;

    /// @dev Protocol token fee is a percentage of tokens sold during TGE. Returns true if fee was claimed by the governing DAO.
    bool public isProtocolTokenFeeClaimed;

    /// @dev Total amount of tokens reserved for protocolfee
    uint256 public totalProtocolFee;

    /// @dev Vesting contract
    IVesting public vesting;

    // EVENTS

    /**
     * @dev Event emitted on token purchase.
     * @param buyer buyer
     * @param amount amount of tokens
     */
    event Purchased(address buyer, uint256 amount);

    /**
     * @dev Event emitted on claim of protocol token fee.
     * @param token token
     * @param tokenFee amount of tokens
     */
    event ProtocolTokenFeeClaimed(address token, uint256 tokenFee);

    /**
     * @dev Event emitted on token claim.
     * @param account Redeemer address
     * @param refundValue Refund value
     */
    event Redeemed(address account, uint256 refundValue);

    /**
     * @dev Event emitted on transfer funds to pool.
     * @param amount Amount of transferred tokens/ETH
     */
    event FundsTransferred(uint256 amount);

    // INITIALIZER AND CONSTRUCTOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Constructor function, can only be called once. In this method, settings for the TGE event are assigned, such as the contract of the token implemented using TGE, as well as the TGEInfo structure, which includes the parameters of purchase, vesting and lockup. If no lockup or westing conditions were set for the TVL value when creating the TGE, then the TVL achievement flag is set to true from the very beginning.
     * @param service Service contract
     * @param token_ TGE's token
     * @param info_ TGE parameters
     * @param protocolFee_ Protocol's fee value
     */
    function initialize(
        address service,
        IToken token_,
        TGEInfo calldata info_,
        uint256 protocolFee_
    ) external initializer {
        __ReentrancyGuard_init();
        IService(service).validateTGEInfo(
            info_,
            token_.cap(),
            token_.totalSupplyWithReserves(),
            token_.tokenType()
        );

        vesting = IService(service).vesting();

        token = token_;
        info = info_;
        protocolFee = protocolFee_;
        lockupTVLReached = (info_.lockupTVL == 0);

        for (uint256 i = 0; i < info_.userWhitelist.length; i++) {
            _isUserWhitelisted[info_.userWhitelist[i]] = true;
        }

        createdAt = block.number;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Purchase pool's tokens during TGE. The method for users from the TGE whitelist (set in TGEInfo when initializing the TGE contract), if the list is not set, then the sale is carried out for any address. The contract, when using this method, exchanges info.unitofaccount tokens available to buyers (if the address of the info.unitofaccount contract is set as zero, then the native ETH is considered unitofaccount) at the info.price rate of info.unitofaccount tokens for one pool token being sold. The buyer specifies the purchase amount in pool tokens, not in Unitofaccount. After receiving the user's funds by the contract, part of the tokens are minted to the buyer's balance, part of the tokens are minted to the address of the TGE contract in vesting. The percentage of vesting is specified in info.vestingPercent, if it is equal to 0, then all tokens are transferred to the buyer's balance.
     * @param amount amount of tokens in wei (10**18 = 1 token)
     */
    function purchase(
        uint256 amount
    )
        external
        payable
        onlyWhitelistedUser
        onlyState(State.Active)
        nonReentrant
        whenPoolNotPaused
    {
        // Check purchase price transfer depending on unit of account
        address unitOfAccount = info.unitOfAccount;
        uint256 purchasePrice = (amount * info.price + (1 ether - 1)) /
            1 ether;
        if (unitOfAccount == address(0)) {
            require(
                msg.value >= purchasePrice,
                ExceptionsLibrary.INCORRECT_ETH_PASSED
            );
        } else {
            IERC20Upgradeable(unitOfAccount).safeTransferFrom(
                msg.sender,
                address(this),
                purchasePrice
            );
        }

        // Check purchase size
        require(
            amount >= info.minPurchase,
            ExceptionsLibrary.MIN_PURCHASE_UNDERFLOW
        );
        require(
            amount <= maxPurchaseOf(msg.sender),
            ExceptionsLibrary.MAX_PURCHASE_OVERFLOW
        );

        // Accrue TGE stats
        totalPurchased += amount;
        purchaseOf[msg.sender] += amount;

        // Mint tokens directly to user
        uint256 vestedAmount = (amount *
            info.vestingParams.vestedShare +
            (DENOM - 1)) / DENOM;
        IToken _token = token;
        if (amount - vestedAmount > 0) {
            _token.mint(msg.sender, amount - vestedAmount);
        }

        // Vest tokens
        if (vestedAmount > 0) {
            token.setTGEVestedTokens(
                token.getTotalTGEVestedTokens() + vestedAmount
            );
            vesting.vest(msg.sender, vestedAmount);
        }

        // Increase reserved protocol fee
        uint256 tokenFee = getProtocolTokenFee(amount);
        if (tokenFee > 0) {
            totalProtocolFee += tokenFee;
            token.setProtocolFeeReserved(
                token.getTotalProtocolFeeReserved() + tokenFee
            );
        }

        // Emit event
        emit Purchased(msg.sender, amount);
    }

    /**
     * @dev Return purchased tokens and get back tokens paid. This method allows buyers of TGE who have not collected softcap and are considered failed to return the funds spent by handing back the purchased tokens. The refund of funds for tokens from vesting, blocked within this TGE, is made first of all. The buyer cannot hand over more tokens than he acquired during this TGE. The tokens returned to the contract are sent for burning.
     */
    function redeem()
        external
        onlyState(State.Failed)
        nonReentrant
        whenPoolNotPaused
    {
        // User can't claim more than he bought in this event (in case somebody else has transferred him tokens)
        require(
            purchaseOf[msg.sender] > 0,
            ExceptionsLibrary.ZERO_PURCHASE_AMOUNT
        );

        uint256 refundAmount = 0;

        // Calculate redeem from vesting
        uint256 vestedBalance = vesting.vested(address(this), msg.sender);
        if (vestedBalance > 0) {
            // Account vested tokens
            purchaseOf[msg.sender] -= vestedBalance;
            refundAmount += vestedBalance;

            // Cancel vesting
            vesting.cancel(address(this), msg.sender);

            // Decrease reserved tokens
            token.setTGEVestedTokens(
                token.getTotalTGEVestedTokens() - vestedBalance
            );
        }

        // Calculate redeemed balance
        uint256 balanceToRedeem = MathUpgradeable.min(
            token.balanceOf(msg.sender),
            purchaseOf[msg.sender]
        );
        if (balanceToRedeem > 0) {
            purchaseOf[msg.sender] -= balanceToRedeem;
            refundAmount += balanceToRedeem;
            token.burn(msg.sender, balanceToRedeem);
        }

        // Check that there is anything to refund
        require(refundAmount > 0, ExceptionsLibrary.NOTHING_TO_REDEEM);

        // Transfer refund value
        uint256 refundValue = (refundAmount * info.price + (1 ether - 1)) /
            1 ether;
        if (info.unitOfAccount == address(0)) {
            payable(msg.sender).sendValue(refundValue);
        } else {
            IERC20Upgradeable(info.unitOfAccount).safeTransfer(
                msg.sender,
                refundValue
            );
        }

        // Decrease reserved protocol fee
        uint256 tokenFee = getProtocolTokenFee(refundAmount);
        if (tokenFee > 0) {
            totalProtocolFee -= tokenFee;
            token.setProtocolFeeReserved(
                token.getTotalProtocolFeeReserved() - tokenFee
            );
        }

        // Emit event
        emit Redeemed(msg.sender, refundValue);
    }

    /// @dev Set the flag that the condition for achieving the pool balance of the value specified in the lockup settings is met. The action is irreversible.
    function setLockupTVLReached()
        external
        whenPoolNotPaused
        onlyManager
        onlyState(State.Successful)
    {
        // Check that TVL has not been reached yet
        require(!lockupTVLReached, ExceptionsLibrary.LOCKUP_TVL_REACHED);

        // Mark as reached
        lockupTVLReached = true;
    }

    // RESTRICTED FUNCTIONS

    /**
     * @dev This method is used to perform the following actions for a successful TGE after its completion: transfer funds collected from buyers in the form of info.unitofaccount tokens or ETH to the address of the pool to which TGE belongs (if info.price is 0, then this action is not performed), as well as for Governance tokens make a minting of the percentage of the amount of all user purchases specified in the Service.sol protocolTokenFee contract and transfer it to the address specified in the Service.sol contract in the protocolTreasury() getter. Can be executed only once. Any address can call the method.
     */
    function transferFunds()
        external
        onlyState(State.Successful)
        whenPoolNotPaused
    {
        // Return if nothing to transfer
        if (totalPurchased == 0) {
            return;
        }

        // Claim protocol fee
        _claimProtocolTokenFee();

        // Transfer remaining funds to pool
        address unitOfAccount = info.unitOfAccount;
        address pool = token.pool();
        uint256 balance = 0;
        if (info.price != 0) {
            if (unitOfAccount == address(0)) {
                balance = address(this).balance;
                payable(pool).sendValue(balance);
            } else {
                balance = IERC20Upgradeable(unitOfAccount).balanceOf(
                    address(this)
                );
                IERC20Upgradeable(unitOfAccount).safeTransfer(pool, balance);
            }
        }

        // Emit event
        emit FundsTransferred(balance);
    }

    /// @dev Transfers protocol token fee in form of pool's governance tokens to protocol treasury
    function _claimProtocolTokenFee() private {
        // Return if already claimed
        if (isProtocolTokenFeeClaimed) {
            return;
        }

        // Retrun for preference token
        IToken _token = token;
        if (_token.tokenType() == IToken.TokenType.Preference) {
            return;
        }

        // Mark fee as claimed
        isProtocolTokenFeeClaimed = true;

        // Mint fee to treasury
        uint256 tokenFee = totalProtocolFee;
        if (totalProtocolFee > 0) {
            totalProtocolFee = 0;
            _token.mint(_token.service().protocolTreasury(), tokenFee);
            token.setProtocolFeeReserved(
                token.getTotalProtocolFeeReserved() - tokenFee
            );
        }

        // Emit event
        emit ProtocolTokenFeeClaimed(address(_token), tokenFee);
    }

    // VIEW FUNCTIONS

    /**
     * @dev Shows the maximum possible number of tokens to be purchased by a specific address, taking into account whether the user is on the white list and 0 what amount of purchases he made within this TGE.
     * @return Amount of tokens
     */
    function maxPurchaseOf(address account) public view returns (uint256) {
        if (!isUserWhitelisted(account)) {
            return 0;
        }
        return
            MathUpgradeable.min(
                info.maxPurchase - purchaseOf[account],
                info.hardcap - totalPurchased
            );
    }

    /**
     * @dev The Getter allows you to find out the status of the current TGE. Usually, the status necessarily changes to 1 - "failure" or 2 - "success" at the end of the TGE validity period, depending on whether the softcap failed or was collected. However, if the buyers purchased 100% of the tokens offered for purchase, the status changes ahead of time to 2 - "success". The active TGE (which has not expired and has not collected hardcap) has the status 0. Changing the status from 0 to 1 or 2 is irreversible.
     * @return State
     */
    function state() public view returns (State) {
        // If hardcap is reached TGE is successfull
        if (totalPurchased == info.hardcap) {
            return State.Successful;
        }

        // If deadline not reached TGE is active
        if (block.number < createdAt + info.duration) {
            return State.Active;
        }

        // If it's not primary TGE it's successfull (if anything is purchased)
        if (address(this) != token.getTGEList()[0] && totalPurchased > 0) {
            return State.Successful;
        }

        // If softcap is reached TGE is successfull
        if (totalPurchased >= info.softcap && totalPurchased > 0) {
            return State.Successful;
        }

        // Otherwise it's failed primary TGE
        return State.Failed;
    }

    /**
     * @dev The given getter shows whether the transfer method is available for tokens that were distributed using a specific TGE contract. If the lockup period is over or if the lockup was not provided for this TGE, the getter always returns true.
     * @return Is transfer available
     */
    function transferUnlocked() public view returns (bool) {
        return
            lockupTVLReached &&
            block.number >= createdAt + info.lockupDuration;
    }

    /**
     * @dev Shows the number of TGE tokens blocked in this contract. If the lockup is completed or has not been assigned, the method returns 0 (all tokens on the address balance are available for transfer). If the lockup period is still active, then the difference between the tokens purchased by the user and those in the vesting is shown (both parameters are only for this TGE).
     * @param account Account address
     * @return Locked balance
     */
    function lockedBalanceOf(address account) external view returns (uint256) {
        return
            transferUnlocked()
                ? 0
                : (purchaseOf[account] -
                    vesting.vestedBalanceOf(address(this), account));
    }

    /**
     * @dev Shows the number of TGE tokens available for redeem for `account`
     * @param account Account address
     * @return Redeemable balance of the address
     */
    function redeemableBalanceOf(
        address account
    ) external view returns (uint256) {
        if (purchaseOf[account] == 0) return 0;
        if (state() != State.Failed) return 0;

        return
            MathUpgradeable.min(
                token.balanceOf(account) +
                    vesting.vestedBalanceOf(address(this), account),
                purchaseOf[account]
            );
    }

    /**
     * @dev The given getter shows how much info.unitofaccount was collected within this TGE. To do this, the amount of tokens purchased by all buyers is multiplied by info.price.
     * @return Total value
     */
    function getTotalPurchasedValue() public view returns (uint256) {
        return (totalPurchased * info.price) / 10 ** 18;
    }

    /**
     * @dev This getter shows the total value of all tokens that are in the vesting. Tokens that were transferred to user’s wallet addresses upon request for successful TGEs and that were burned as a result of user funds refund for unsuccessful TGEs are not taken into account.
     * @return Total value
     */
    function getTotalVestedValue() public view returns (uint256) {
        return (vesting.totalVested(address(this)) * info.price) / 10 ** 18;
    }

    /**
     * @dev Get userwhitelist info
     * @return User whitelist
     */
    function getUserWhitelist() external view returns (address[] memory) {
        return info.userWhitelist;
    }

    /**
     * @dev Checks if user is whitelisted
     * @param account User address
     * @return Flag if user if whitelisted
     */
    function isUserWhitelisted(address account) public view returns (bool) {
        return info.userWhitelist.length == 0 || _isUserWhitelisted[account];
    }

    /**
     * @dev Get TGE end block
     * @return TGE end block
     */
    function getEnd() external view returns (uint256) {
        return createdAt + info.duration;
    }

    /**
     * @dev Get TGE info
     * @return TGE info
     */
    function getInfo() external view returns (TGEInfo memory) {
        return info;
    }

    /*
     * @dev Сalculates protocol token fee for given token amount
     * @param amount Token amount
     * @return tokenFee
     */
    function getProtocolTokenFee(uint256 amount) public view returns (uint256) {
        if (token.tokenType() == IToken.TokenType.Preference) {
            return 0;
        }
        return (amount * protocolFee + (DENOM - 1)) / DENOM;
    }

    // MODIFIER

    modifier onlyState(State state_) {
        require(state() == state_, ExceptionsLibrary.WRONG_STATE);
        _;
    }

    modifier onlyWhitelistedUser() {
        require(
            isUserWhitelisted(msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier onlyManager() {
        IService service = token.service();
        require(
            service.hasRole(service.SERVICE_MANAGER_ROLE(), msg.sender),
            ExceptionsLibrary.NOT_WHITELISTED
        );
        _;
    }

    modifier whenPoolNotPaused() {
        require(
            !IPool(token.pool()).paused(),
            ExceptionsLibrary.SERVICE_PAUSED
        );
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ICustomProposal {}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./registry/IRegistry.sol";
import "./governor/IGovernor.sol";
import "./governor/IGovernanceSettings.sol";
import "./governor/IGovernorProposals.sol";

interface IPool is IGovernorProposals {
    function initialize(IRegistry.CompanyInfo memory companyInfo_) external;

    function setNewOwnerWithSettings(
        address owner_,
        string memory trademark_,
        IGovernanceSettings.NewGovernanceSettings memory governanceSettings_
    ) external;

    function propose(
        address proposer,
        uint256 proposalType,
        IGovernor.ProposalCoreData memory core,
        IGovernor.ProposalMetaData memory meta
    ) external returns (uint256 proposalId);

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function setProposalIdToTGE(address tge) external;

    function cancelProposal(uint256 proposalId) external;

    function changePoolSecretary(
        address[] memory addSecretary,
        address[] memory removeSecretary
    ) external;

    function changePoolExecutor(
        address[] memory addExecutor,
        address[] memory removeExecutor
    ) external;

    function owner() external view returns (address);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function paused() external view returns (bool);

    function getGovernanceToken() external view returns (IToken);

    function tokenExists(IToken token_) external view returns (bool);

    function tokenTypeByAddress(
        address token_
    ) external view returns (IToken.TokenType);

    function isValidProposer(address account) external view returns (bool);

    function isLastProposalIdByTypeActive(
        uint256 type_
    ) external view returns (bool);

    function validateGovernanceSettings(
        IGovernanceSettings.NewGovernanceSettings memory settings
    ) external pure;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import "./ITGE.sol";
import "./ICustomProposal.sol";
import "./registry/IRecordsRegistry.sol";
import "./registry/ICompaniesRegistry.sol";
import "./registry/IRegistry.sol";
import "./IToken.sol";
import "./IVesting.sol";
import "./ITokenFactory.sol";
import "./ITGEFactory.sol";

interface IService is IAccessControlEnumerableUpgradeable {
    function ADMIN_ROLE() external view returns (bytes32);

    function WHITELISTED_USER_ROLE() external view returns (bytes32);

    function SERVICE_MANAGER_ROLE() external view returns (bytes32);

    function EXECUTOR_ROLE() external view returns (bytes32);

    function createPool(
        ICompaniesRegistry.CompanyInfo memory companyInfo
    ) external;

    function addProposal(uint256 proposalId) external;

    function addEvent(
        IRecordsRegistry.EventType eventType,
        uint256 proposalId,
        string calldata metaHash
    ) external;

    function setProtocolCollectedFee(
        address _token,
        uint256 _protocolTokenFee
    ) external;

    function registry() external view returns (IRegistry);

    function vesting() external view returns (IVesting);

    function tokenFactory() external view returns (ITokenFactory);

    function tgeFactory() external view returns (ITGEFactory);

    function protocolTreasury() external view returns (address);

    function protocolTokenFee() external view returns (uint256);

    function getMinSoftCap() external view returns (uint256);

    function getProtocolTokenFee(
        uint256 amount
    ) external view returns (uint256);

    function getProtocolCollectedFee(
        address token_
    ) external view returns (uint256);

    function poolBeacon() external view returns (address);

    function tgeBeacon() external view returns (address);

    function tokenBeacon() external view returns (address);

    function customProposal() external view returns (ICustomProposal);

    function validateTGEInfo(
        ITGE.TGEInfo calldata info,
        uint256 cap,
        uint256 totalSupply,
        IToken.TokenType tokenType
    ) external view;

    function getPoolAddress(
        ICompaniesRegistry.CompanyInfo memory info
    ) external view returns (address);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";
import "./IVesting.sol";

interface ITGE {

    struct TGEInfo {
        uint256 price;
        uint256 hardcap;
        uint256 softcap;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 duration;
        IVesting.VestingParams vestingParams;
        address[] userWhitelist;
        address unitOfAccount;
        uint256 lockupDuration;
        uint256 lockupTVL;
    }

    function initialize(
        address service,
        IToken token_,
        TGEInfo calldata info_,
        uint256 protocolFee_
    ) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function token() external view returns (IToken);

    function state() external view returns (State);

    function getInfo() external view returns (TGEInfo memory);

    function transferUnlocked() external view returns (bool);

    function purchaseOf(address user) external view returns (uint256);

    function redeemableBalanceOf(address user) external view returns (uint256);

    function lockedBalanceOf(address account) external view returns (uint256);

    function getEnd() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./IToken.sol";

interface ITGEFactory {
    function createSecondaryTGE(
        IToken token,
        ITGE.TGEInfo calldata tgeInfo,
        IToken.TokenInfo calldata tokenInfo,
        string memory metadataURI
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "./IService.sol";

interface IToken is IVotesUpgradeable, IERC20Upgradeable {
    struct TokenInfo {
        TokenType tokenType;
        string name;
        string symbol;
        string description;
        uint256 cap;
        uint8 decimals;
    }

    enum TokenType {
        None,
        Governance,
        Preference
    }

    function initialize(
        IService service_,
        address pool_,
        TokenInfo memory info,
        address primaryTGE_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function cap() external view returns (uint256);

    function unlockedBalanceOf(address account) external view returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (TokenType);

    function lastTGE() external view returns (address);

    function getTGEList() external view returns (address[] memory);

    function isPrimaryTGESuccessful() external view returns (bool);

    function addTGE(address tge) external;

    function setTGEVestedTokens(uint256 amount) external;

    function setProtocolFeeReserved(uint256 amount) external;

    function getTotalTGEVestedTokens() external view returns (uint256);

    function getTotalProtocolFeeReserved() external view returns (uint256);

    function totalSupplyWithReserves() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";

interface ITokenFactory {
    function createToken(
        address pool,
        IToken.TokenInfo memory info,
        address primaryTGE
    ) external returns (IToken token);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IVesting {
    struct VestingParams {
        uint256 vestedShare;
        uint256 cliff;
        uint256 cliffShare;
        uint256 spans;
        uint256 spanDuration;
        uint256 spanShare;
        uint256 claimTVL;
        address[] resolvers;
    }

    function vest(address to, uint256 amount) external;

    function cancel(address tge, address account) external;

    function validateParams(
        VestingParams memory params
    ) external pure returns (bool);

    function vested(
        address tge,
        address account
    ) external view returns (uint256);

    function totalVested(address tge) external view returns (uint256);

    function vestedBalanceOf(
        address tge,
        address account
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IGovernanceSettings {
    /**
     * @notice Governance settings
     * @param proposalThreshold_ Proposal threshold
     * @param quorumThreshold_ Quorum threshold
     * @param decisionThreshold_ Decision threshold
     * @param votingDuration_ Voting duration
     * @param transferValueForDelay_ Transfer value for delay
     * @param executionDelays_ List of execution delays for all proposal types
     */
    struct NewGovernanceSettings {
        uint256 proposalThreshold;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 votingDuration;
        uint256 transferValueForDelay;
        uint256[4] executionDelays;
        uint256 votingStartDelay;
    }

    function setGovernanceSettings(
        NewGovernanceSettings memory settings
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../interfaces/registry/IRegistry.sol";

interface IGovernor {
    /**
     * @dev Struct with proposal core data
     * @param targets Targets
     * @param values ETH values
     * @param callDatas Call datas to pass in .call() to target
     * @param quorumThreshold Quorum threshold (as percents)
     * @param decisionThreshold Decision threshold (as percents)
     * @param executionDelay Execution delay after successful voting (blocks)
     */
    struct ProposalCoreData {
        address[] targets;
        uint256[] values;
        bytes[] callDatas;
        uint256 quorumThreshold;
        uint256 decisionThreshold;
        uint256 executionDelay;
    }

    /**
     * @dev Struct with proposal metadata
     * @param proposalType Proposal type
     * @param description Description
     * @param metaHash Metadata hash
     */
    struct ProposalMetaData {
        IRegistry.EventType proposalType;
        string description;
        string metaHash;
    }

    function proposalState(uint256 proposalId)
        external
        view
        returns (uint256 state);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../IService.sol";

interface IGovernorProposals {
    function service() external view returns (IService);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../ITGE.sol";
import "../IToken.sol";

interface ICompaniesRegistry {
    struct CompanyInfo {
        uint256 jurisdiction;
        uint256 entityType;
        string ein;
        string dateOfIncorporation;
        uint256 fee;
    }

    function lockCompany(
        uint256 jurisdiction,
        uint256 entityType
    ) external returns (CompanyInfo memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IRecordsRegistry {
    // Directory
    enum ContractType {
        None,
        Pool,
        GovernanceToken,
        PreferenceToken,
        TGE
    }

    enum EventType {
        None,
        Transfer,
        TGE,
        GovernanceSettings
    }

    /**
     * @dev Contract information structure
     * @param addr Contract address
     * @param contractType Contract type
     * @param description Contract description
     */
    struct ContractInfo {
        address addr;
        ContractType contractType;
        string description;
    }

    /**
     * @dev Proposal information structure
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @param description Proposal description
     */
    struct ProposalInfo {
        address pool;
        uint256 proposalId;
        string description;
    }

    /**
     * @dev Event information structure
     * @param eventType Event type
     * @param pool Pool address
     * @param eventContract Address of the Event contract
     * @param proposalId Proposal ID
     * @param metaHash Hash value of event metadata
     */
    struct Event {
        EventType eventType;
        address pool;
        address eventContract;
        uint256 proposalId;
        string metaHash;
    }

    function addContractRecord(
        address addr,
        ContractType contractType,
        string memory description
    ) external returns (uint256 index);

    function addProposalRecord(
        address pool,
        uint256 proposalId
    ) external returns (uint256 index);

    function addEventRecord(
        address pool,
        EventType eventType,
        address eventContract,
        uint256 proposalId,
        string calldata metaHash
    ) external returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ICompaniesRegistry.sol";
import "./ITokensRegistry.sol";
import "./IRecordsRegistry.sol";
import "../IService.sol";

interface IRegistry is ITokensRegistry, ICompaniesRegistry, IRecordsRegistry {
    function service() external view returns (IService);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface ITokensRegistry {
    function isTokenWhitelisted(address token) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library ExceptionsLibrary {
    string public constant ADDRESS_ZERO = "ADDRESS_ZERO";
    string public constant INCORRECT_ETH_PASSED = "INCORRECT_ETH_PASSED";
    string public constant NO_COMPANY = "NO_COMPANY";
    string public constant INVALID_TOKEN = "INVALID_TOKEN";
    string public constant NOT_POOL = "NOT_POOL";
    string public constant NOT_TGE = "NOT_TGE";
    string public constant NOT_Registry = "NOT_Registry";
    string public constant NOT_POOL_OWNER = "NOT_POOL_OWNER";
    string public constant NOT_SERVICE_OWNER = "NOT_SERVICE_OWNER";
    string public constant IS_DAO = "IS_DAO";
    string public constant NOT_DAO = "NOT_DAO";
    string public constant NOT_WHITELISTED = "NOT_WHITELISTED";
    string public constant NOT_SERVICE = "NOT_SERVICE";
    string public constant WRONG_STATE = "WRONG_STATE";
    string public constant TRANSFER_FAILED = "TRANSFER_FAILED";
    string public constant CLAIM_NOT_AVAILABLE = "CLAIM_NOT_AVAILABLE";
    string public constant NO_LOCKED_BALANCE = "NO_LOCKED_BALANCE";
    string public constant LOCKUP_TVL_REACHED = "LOCKUP_TVL_REACHED";
    string public constant HARDCAP_OVERFLOW = "HARDCAP_OVERFLOW";
    string public constant MAX_PURCHASE_OVERFLOW = "MAX_PURCHASE_OVERFLOW";
    string public constant HARDCAP_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_OVERFLOW_REMAINING_SUPPLY";
    string public constant HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY =
        "HARDCAP_AND_PROTOCOL_FEE_OVERFLOW_REMAINING_SUPPLY";
    string public constant MIN_PURCHASE_UNDERFLOW = "MIN_PURCHASE_UNDERFLOW";
    string public constant LOW_UNLOCKED_BALANCE = "LOW_UNLOCKED_BALANCE";
    string public constant ZERO_PURCHASE_AMOUNT = "ZERO_PURCHASE_AMOUNTs";
    string public constant NOTHING_TO_REDEEM = "NOTHING_TO_REDEEM";
    string public constant RECORD_IN_USE = "RECORD_IN_USE";
    string public constant INVALID_EIN = "INVALID_EIN";
    string public constant VALUE_ZERO = "VALUE_ZERO";
    string public constant ALREADY_SET = "ALREADY_SET";
    string public constant VOTING_FINISHED = "VOTING_FINISHED";
    string public constant ALREADY_EXECUTED = "ALREADY_EXECUTED";
    string public constant ACTIVE_TGE_EXISTS = "ACTIVE_TGE_EXISTS";
    string public constant INVALID_VALUE = "INVALID_VALUE";
    string public constant INVALID_CAP = "INVALID_CAP";
    string public constant INVALID_HARDCAP = "INVALID_HARDCAP";
    string public constant ONLY_POOL = "ONLY_POOL";
    string public constant ETH_TRANSFER_FAIL = "ETH_TRANSFER_FAIL";
    string public constant TOKEN_TRANSFER_FAIL = "TOKEN_TRANSFER_FAIL";
    string public constant SERVICE_PAUSED = "SERVICE_PAUSED";
    string public constant INVALID_PROPOSAL_TYPE = "INVALID_PROPOSAL_TYPE";
    string public constant EXECUTION_FAILED = "EXECUTION_FAILED";
    string public constant INVALID_USER = "INVALID_USER";
    string public constant NOT_LAUNCHED = "NOT_LAUNCHED";
    string public constant LAUNCHED = "LAUNCHED";
    string public constant VESTING_TVL_REACHED = "VESTING_TVL_REACHED";
    string public constant WRONG_TOKEN_ADDRESS = "WRONG_TOKEN_ADDRESS";
    string public constant GOVERNANCE_TOKEN_EXISTS = "GOVERNANCE_TOKEN_EXISTS";
    string public constant THRESHOLD_NOT_REACHED = "THRESHOLD_NOT_REACHED";
    string public constant UNSUPPORTED_TOKEN_TYPE = "UNSUPPORTED_TOKEN_TYPE";
    string public constant ALREADY_VOTED = "ALREADY_VOTED";
    string public constant ZERO_VOTES = "ZERO_VOTES";
    string public constant ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS =
        "ACTIVE_GOVERNANCE_SETTINGS_PROPOSAL_EXISTS";
    string public constant EMPTY_ADDRESS = "EMPTY_ADDRESS";
    string public constant NOT_VALID_PROPOSER = "NOT_VALID_PROPOSER";
    string public constant SHARES_SUM_EXCEEDS_ONE = "SHARES_SUM_EXCEEDS_ONE";
    string public constant NOT_RESOLVER = "NOT_RESOLVER";
    string public constant NOT_REGISTRY = "NOT_REGISTRY";
    string public constant INVALID_TARGET = "INVALID_TARGET";
    string public constant NOT_TGE_FACTORY = "NOT_TGE_FACTORY";
    string public constant WRONG_AMOUNT = "WRONG_AMOUNT";
    string public constant WRONG_BLOCK_NUMBER = "WRONG_BLOCK_NUMBER";
    string public constant NOT_VALID_EXECUTOR = "NOT_VALID_EXECUTOR";
}