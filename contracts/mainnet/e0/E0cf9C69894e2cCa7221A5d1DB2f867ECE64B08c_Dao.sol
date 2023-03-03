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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
library CountersUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./libs/Pausable.sol";
import "./Supernova.sol";

contract Dao is Initializable, Pausable {
    Supernova _SupernovaBridge;
    uint256 CLASSIC_DEF;
    uint256 DOUBLE_DEF;
    uint256 CLASSIC_MIN;
    uint256 DOUBLE_MIN;
    uint256 CLASSIC_MAX;
    uint256 DOUBLE_MAX;
    uint256 FULLCYCLE_MAX;
    uint256 MINIMUM;
    uint256 VOTELIMIT;
    uint256 public _FULLCYCLE;
    uint64 QUEUE_CURRENT;
    uint64 QUEUE_INPROCESS;
    address private UNISWAP_V2_ROUTER;
    address private WETH;
    bytes32 _Hash;
    address private _M87;
    address private _supernova;
    uint256[] public executing_Ids;
    uint256[] public queue_Ids;

    address ORACLE;
    // Create a struct named Proposal containing all relevant information
    struct Proposal {
        // address of the token being used for a purchase, can be zero address in case of ETH
        address sellToken;
        //  address of the token being purchased, can be zero address in case of ETH
        address buyToken;
        // general params
        string proposalTitle;
        string proposalDescription;
        address creator;
        ProposalType proposalType;
        // state enum dedicates operations @dev see: enum
        State activeState;
        // signers[0] is creator powehi, others are signer powehi
        address[] signers;
        uint256 date;
        uint256 amount;
        // number of YES votes for this proposal
        uint256 yesVotes;
        // number of NO votes for this proposal
        uint256 noVotes;
        // voters - halo's voted on proposal
        mapping(address => bool) voters;
    }

    enum Vote {
        YES,
        NO
    }

    enum ProposalType {
        CLASSIC,
        DOUBLE_DOWN,
        CASH_OUT,
        STRUCTURE
    }

    enum State {
        CREATED, // submitted/created by powehi, waiting other powehi to sign
        QUEUED, // signed by required number of powehi, waiting for amount to collect
        VOTING,
        RUNNING, // voting opened and waiting for dao decision
        EXECUTED, // voting succeed and swap executed
        FAILED // voting failed
    }

    // events

    event ProposalCreated(
        address creator,
        uint256 proposalIndex,
        address sellToken,
        address buyToken,
        string title,
        string description
    );
    event ProposalStatus(
        address creator,
        uint256 proposalIndex,
        address sellToken,
        address buyToken,
        State st
    );
    // Create a mapping of ID to Proposal
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => bool)) public _stroreSigner;
    // index of array same as enum ProposalType
    uint8[] public signersRequired;

    // Number of proposals that have been created
    uint256 public numProposals;

    modifier OnlyOracle() {
        require(msg.sender == ORACLE, "Not a ORACLE");
        _;
    }

    function ff() public view returns (address, address) {
        return (msg.sender, ORACLE);
    }

    modifier notSigner(uint256 _proposalIndex) {
        require(
            _stroreSigner[msg.sender][_proposalIndex] == false,
            "Caller already signed this proposal"
        );
        _;
    }

    modifier atState(uint256 _proposalIndex, State _state) {
        require(
            proposals[_proposalIndex].activeState == _state,
            "Wrong state. Action not allowed."
        );
        _;
    }
    modifier stateQuorum(uint256 _proposalIndex) {
        require(
            proposals[_proposalIndex].signers.length >=
                signersRequired[uint8(proposals[_proposalIndex].proposalType)],
            "Wrong state. Action not allowed."
        );
        _;
    }

    modifier _IsHalo(address _index) {
        require(_SupernovaBridge.Halo_finder(_index), "Not a Halo");
        _;
    }
    modifier _IsPowehi(address _index) {
        require(_SupernovaBridge.Powehi_finder(_index), "Not a Powehi");
        _;
    }

    modifier Bridge(bytes32 hsh) {
        require(_Hash == hsh);
        _;
    }

    function setup(
        address _oracle,
        address _m87,
        bytes32 _has,
        uint8[] memory signers
    ) public initializer {
        // signersRequired[0] = 8;
        // signersRequired[1] = 7;
        // signersRequired[2] = 3;
        // signersRequired[3] = 11;
        signersRequired = signers;
        ORACLE = _oracle;
        _M87 = _m87;
        _Hash = _has;

        CLASSIC_DEF = 8700000000000000000; //wei 8.7
        DOUBLE_DEF = 17400000000000000000; //wei 17.4
        CLASSIC_MIN = 870000000000000000; //wei 0.87
        DOUBLE_MIN = 8700000000000000000; //wei 8.7
        CLASSIC_MAX = 87000000000000000000; //wei 8.7
        DOUBLE_MAX = 26100000000000000000; //wei 26.1
        FULLCYCLE_MAX = 87000000000000000000; //wei 87  ETH
        UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
        MINIMUM = 87 * 1e8 * 1e18;
        VOTELIMIT = 87 * 60 * 60; //87 Hours
        _FULLCYCLE = 87;
        QUEUE_CURRENT = 0;
        QUEUE_INPROCESS = 0;
        numProposals = 0;

        __Ownable_init();
    }

    function _Set_SupernovaBridgeBridge(address _fb)
        external
        onlyOwner
        returns (bool)
    {
        _supernova = _fb;
        _SupernovaBridge = Supernova(payable(_fb));
        return true;
    }

    function getBridge() public view returns (address) {
        return _supernova;
    }

    function getsignersRequired(uint256 inex) public view returns (uint8) {
        return signersRequired[inex];
    }

    /// @dev createProposal allows a Powehi to create a new proposal in the DAO
    /// @return Returns the proposal index for the newly created proposal
    function createCashOutProposal(
        address _sellToken,
        string memory _proposalTitle,
        string memory _proposalDescription,
        uint256 persentage
    ) external _IsPowehi(msg.sender) returns (uint256) {
        require(persentage <= 5000, "Buy and sell token can't be same");
        //50%
        (bool b, uint256 i) = _SupernovaBridge.isSupportedToken(_sellToken);
        require(b, "Buy token is not supported");

        Proposal storage proposal = proposals[numProposals];
        proposal.sellToken = _sellToken;
        proposal.buyToken = address(0xdead);
        proposal.proposalTitle = _proposalTitle;
        proposal.proposalDescription = _proposalDescription;
        proposal.signers = [msg.sender];
        proposal.activeState = State.CREATED;
        proposal.proposalType = ProposalType.CASH_OUT;
        proposal.date = VOTELIMIT + block.timestamp;
        proposal.amount = persentage;
        _stroreSigner[msg.sender][numProposals] = true;
        numProposals++;

        emit ProposalCreated(
            msg.sender,
            numProposals - 1,
            _sellToken,
            address(0xdead),
            _proposalTitle,
            _proposalDescription
        );

        return numProposals - 1;
    }

    function createDoubleClassicProposal(
        address _buyToken,
        string memory _proposalTitle,
        string memory _proposalDescription,
        uint256 amount,
        bool double
    ) external _IsPowehi(msg.sender) returns (uint256) {
        if (double) {
            if (amount >= DOUBLE_MIN && amount <= DOUBLE_MAX) {
                Proposal storage proposal = proposals[numProposals];
                proposal.sellToken = address(0xdead);
                proposal.buyToken = _buyToken;
                proposal.proposalTitle = _proposalTitle;
                proposal.proposalDescription = _proposalDescription;
                proposal.signers = [msg.sender];
                proposal.activeState = State.CREATED;
                proposal.date = block.timestamp;
                proposal.amount = amount;
                proposal.proposalType = ProposalType.DOUBLE_DOWN;
            } else {
                revert("MIN AND MAX LIMITION");
            }
        } else {
            if (amount >= CLASSIC_MIN && amount <= CLASSIC_MAX) {
                Proposal storage proposal = proposals[numProposals];
                proposal.sellToken = address(0xdead);
                proposal.buyToken = _buyToken;
                proposal.proposalTitle = _proposalTitle;
                proposal.proposalDescription = _proposalDescription;
                proposal.signers = [msg.sender];
                proposal.activeState = State.CREATED;
                proposal.date = block.timestamp;
                proposal.amount = amount;
                proposal.proposalType = ProposalType.CLASSIC;
            } else {
                revert("MIN AND MAX LIMITION CLASSIC");
            }
        }

        _stroreSigner[msg.sender][numProposals] = true;
        numProposals++;

        emit ProposalCreated(
            msg.sender,
            numProposals - 1,
            address(0xdead),
            _buyToken,
            _proposalTitle,
            _proposalDescription
        );

        return numProposals - 1;
    }

    function createStructureProposal(
        string memory _proposalTitle,
        string memory _proposalDescription
    ) external _IsPowehi(msg.sender) returns (uint256) {
        Proposal storage proposal = proposals[numProposals];
        proposal.sellToken = address(0xdead);
        proposal.buyToken = address(0xdead);
        proposal.proposalTitle = _proposalTitle;
        proposal.proposalDescription = _proposalDescription;
        proposal.signers = [msg.sender];
        proposal.activeState = State.CREATED;
        proposal.proposalType = ProposalType.STRUCTURE;
        proposal.date = block.timestamp;
        proposal.amount = 0;

        _stroreSigner[msg.sender][numProposals] = true;
        numProposals++;
        emit ProposalCreated(
            msg.sender,
            numProposals - 1,
            address(0xdead),
            address(0xdead),
            _proposalTitle,
            _proposalDescription
        );

        return numProposals - 1;
    }

    function signOnProposal(uint256 proposalIndex)
        external
        _IsPowehi(msg.sender)
        notSigner(proposalIndex)
        atState(proposalIndex, State.CREATED)
    {
        Proposal storage proposal = proposals[proposalIndex];

        uint8 signersNum = uint8(proposal.signers.length);

        proposal.signers.push(msg.sender);
        _stroreSigner[msg.sender][signersNum] = true;
    }

    function getCurrentStatus() public view returns (uint256 _c, uint256 _f) {
        return (numProposals, _FULLCYCLE);
    }

    
    function CheckOutsign(uint proposalsIndex) public view returns (uint _exsit, uint _require,uint _date) {
         Proposal storage proposal = proposals[proposalsIndex];
       
        return (proposal.signers.length, signersRequired[uint8(proposal.proposalType)],  proposal.date);
    }
    function VoteOnProposal(uint256 proposalIndex, uint8 vote)
        external
        _IsHalo(msg.sender)
    stateQuorum(proposalIndex)
    atState(proposalIndex, State.VOTING)
    {
        if (vote != 0 && vote != 1) {
            revert("You should send  0 or 1");
        }
        Proposal storage proposal = proposals[proposalIndex];

        if (proposal.voters[msg.sender]) {
            revert("You have already voted");
        }
        if (block.timestamp > proposal.date) {
            revert("You have already voted");
        }

        // uint8 signersNum = uint8(proposal.signers.length);

        if (vote == 0) {
            //yes
            proposal.yesVotes += 1;
        } else {
            //no
            proposal.noVotes += 1;
        }
        proposal.voters[msg.sender] = true;
    }

    function CloseProposal(uint256 _idQ)
        public
        atState(_idQ, State.VOTING)
        OnlyOracle
        returns (bool)
    {
        Proposal storage proposal = proposals[_idQ];
        proposal.activeState = State.FAILED;
        return true;
    }

    function ProposalCheckOut(uint256 _idQ, uint256[] memory x)
        private
        OnlyOracle
        returns (bool)
    {
        Proposal storage proposal = proposals[_idQ];
        //
        if(proposal.activeState ==State.QUEUED){

        uint256 _Index = getId(_idQ);
        if (proposal.proposalType == ProposalType.CLASSIC) {
            if (queue_Ids[_Index] == _idQ) {
                queue_Ids[_Index] = queue_Ids[_Index];
                queue_Ids.pop();

                sendToExecution(_idQ, x);
            } else {
                revert("You should chose First one");
            }
        } else if (proposal.proposalType == ProposalType.DOUBLE_DOWN) {
            if (queue_Ids[_Index] == _idQ) {
                queue_Ids[_Index] = queue_Ids[_Index];
                queue_Ids.pop();

                sendToExecution(_idQ, x);
            } else {
                revert("You should chose First one");
            }
        } else if (proposal.proposalType == ProposalType.CASH_OUT) {
            sendToExecution(_idQ, x);
        } else if (proposal.proposalType == ProposalType.STRUCTURE) {
            if (queue_Ids[_Index] == _idQ) {
                queue_Ids[_Index] = queue_Ids[_Index];
                queue_Ids.pop();

                sendToExecution(_idQ, x);
            } else {
                revert("You should chose First one");
            }
        }
        }else{
            revert("it's not in  QUEUED");
        }
    }

    function getId(uint256 _id) private view returns (uint256) {
        uint256 id = 0;

        for (uint256 i = 0; i < queue_Ids.length; i++) {
            if (queue_Ids[i] == _id) {
                id = i;
            }
        }

        return id;
    }

    function sendToExecution(uint256 proposalIndex, uint256[] memory datas)
        private
        returns (bool)
    {
        Proposal storage proposal = proposals[proposalIndex];

        if (
            proposal.buyToken == address(0xdead) &&
            proposal.sellToken != address(0xdead)
        ) {
            //sell

            execute_oneProposal(
                _Hash,
                proposal.amount,
                proposal.sellToken,
                true
            );
            proposal.activeState = State.EXECUTED;
        } else if (
            proposal.buyToken != address(0xdead) &&
            proposal.sellToken == address(0xdead)
        ) {
            //buy
            execute_oneProposal(
                _Hash,
                proposal.amount,
                proposal.buyToken,
                false
            );
            proposal.activeState = State.EXECUTED;
        } else {
            //struc
            if (datas.length == 3) {
                ReStructure(datas);
            } else {
                revert("more the 3 index");
            }
        }
    }

    function CheckOutVote(uint256 proposalIndex)
        public
        view
        returns (uint256, uint256)
    {
        Proposal storage proposal = proposals[proposalIndex];
        return (proposal.noVotes, proposal.yesVotes);
    }

    function OracleNext(uint256 proposalIndex, uint256[] memory x)
        public
        OnlyOracle
        returns (bool)
    {
        ProposalNext(proposalIndex, x);
        return true;
    }

    function ProposalNext(uint256 proposalIndex, uint256[] memory x)
        private
        returns (bool)
    {
        //voting
        //queue
        //excuteing

        Proposal storage proposal = proposals[proposalIndex];
        require(proposal.activeState != State.FAILED, "State is FAILED");
        require(proposal.activeState != State.RUNNING, "State is FAILED");
        require(proposal.activeState != State.EXECUTED, "State is FAILED");

        //store data mapping and array
        uint8 signersNum = uint8(proposal.signers.length);

        if (signersNum >= signersRequired[uint8(proposal.proposalType)]) {
            if (proposal.proposalType == ProposalType.CASH_OUT) {
                if (proposal.activeState == State.CREATED) {
                    proposal.activeState = State.VOTING;
                    return true;
                }

                //if create => voiting
                //if voiting =>  time & voit ok?=> exuting  sendToExecution
                if (block.timestamp < proposal.date) {
                    revert("There is still time for the proposal");
                }
                if (proposal.noVotes >= 1 || proposal.yesVotes >= 1) {
                    if (proposal.noVotes > proposal.yesVotes) {
                        proposal.activeState = State.FAILED;
                        emit ProposalStatus(
                            proposal.creator,
                            proposalIndex,
                            proposal.sellToken,
                            proposal.buyToken,
                            State.FAILED
                        );
                        return true;
                    } else {
                        //
                        proposal.activeState = State.RUNNING;
                        executing_Ids.push(proposalIndex);
                        ProposalCheckOut(proposalIndex, x);
                        proposal.activeState = State.EXECUTED;
                        //send to supernova for running
                        return true;
                    }
                } else {
                    return false;
                }
            } else if (proposal.proposalType == ProposalType.DOUBLE_DOWN) {
                //ProposalInQueue
                //if create => voiting
                //if voiting =>  time & QUEUED ok?=> exuting = >ProposalCheckOut
                if (proposal.activeState == State.CREATED) {
                    proposal.activeState = State.QUEUED;
                    queue_Ids.push(proposalIndex);
                    return true;
                }

                if (_SupernovaBridge.balanceTreasury() <= DOUBLE_DEF) {
                    revert("Treasury is not ready");
                }
                if (proposal.activeState == State.QUEUED) {
                    proposal.activeState = State.VOTING;
                    return true;
                }
                if (proposal.activeState == State.VOTING) {
                    if (block.timestamp < proposal.date) {
                        revert("There is still time for the proposal");
                    }
                    if (proposal.noVotes >= 1) {
                        if (proposal.noVotes > proposal.yesVotes) {
                            proposal.activeState = State.FAILED;
                            emit ProposalStatus(
                                proposal.creator,
                                proposalIndex,
                                proposal.sellToken,
                                proposal.buyToken,
                                State.FAILED
                            );
                            revert("FAILED");
                        } else {
                            proposal.activeState = State.RUNNING;
                            executing_Ids.push(proposalIndex);
                            ProposalCheckOut(proposalIndex, x);
                        }
                    } else {
                        return false;
                    }
                }

                return true;
            } else if (proposal.proposalType == ProposalType.CLASSIC) {
                if (proposal.activeState == State.CREATED) {
                    proposal.activeState = State.QUEUED;
                    queue_Ids.push(proposalIndex);
                    return true;
                }

                if (_SupernovaBridge.balanceTreasury() <= CLASSIC_MIN) {
                    revert("Treasury is not ready");
                }
                if (proposal.activeState == State.QUEUED) {
                    proposal.activeState = State.VOTING;
                    return true;
                }

                if (proposal.activeState == State.VOTING) {
                    if (block.timestamp < proposal.date) {
                        revert("There is still time for the proposal");
                    }
                    if (proposal.noVotes >= 1) {
                        if (proposal.noVotes > proposal.yesVotes) {
                            proposal.activeState = State.FAILED;
                            emit ProposalStatus(
                                proposal.creator,
                                proposalIndex,
                                proposal.sellToken,
                                proposal.buyToken,
                                State.FAILED
                            );
                            revert("FAILED");
                        } else {
                            proposal.activeState = State.RUNNING;
                            executing_Ids.push(proposalIndex);
                            ProposalCheckOut(proposalIndex, x);
                        }
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }
            } else if (proposal.proposalType == ProposalType.STRUCTURE) {
                //STRUCTURE
                if (proposal.activeState == State.CREATED) {
                    proposal.activeState = State.QUEUED;
                    queue_Ids.push(proposalIndex);
                    return true;
                }

                if (proposal.activeState == State.QUEUED) {
                    proposal.activeState = State.VOTING;
                    return true;
                }

                if (proposal.activeState == State.VOTING) {
                    if (block.timestamp < proposal.date) {
                        revert("There is still time for the proposal");
                    }
                    if (proposal.noVotes >= 1) {
                        if (proposal.noVotes > proposal.yesVotes) {
                            proposal.activeState = State.FAILED;
                            emit ProposalStatus(
                                proposal.creator,
                                proposalIndex,
                                proposal.sellToken,
                                proposal.buyToken,
                                State.FAILED
                            );
                            revert("FAILED");
                        } else {
                            proposal.activeState = State.RUNNING;
                            executing_Ids.push(proposalIndex);
                            ProposalCheckOut(proposalIndex, x);
                        }
                    } else {
                        return false;
                    }
                } else {
                    return false;
                }

                return true;
            }
        } else {
            revert("signers Required");
        }
    }

    function FullCycleToExecution() public OnlyOracle returns (bool) {
        if (_SupernovaBridge.balanceTreasury() < FULLCYCLE_MAX) {
            revert("The amount is insufficient");
        }
        uint256 amount = _SupernovaBridge.balanceTreasury() - FULLCYCLE_MAX;
        execute_Cycle(_Hash, amount, _M87);
        return true;
    }

    function ReStructure(uint256[] memory arr) private returns (bool) {
        _FULLCYCLE = arr[0];
        MINIMUM = arr[1];
        VOTELIMIT = arr[2];

        return true;
    }

    function TreasuryBalance() public view returns (uint256) {
        uint256 r = _SupernovaBridge.balanceTreasury();
        return r;
    }

    //DAO execute
    function execute_oneProposal(
        bytes32 _hsh,
        uint256 _amount,
        address _token,
        bool _q
    ) internal Bridge(_hsh) returns (bool) {
        //checks

        //persentages

        // divid
        if (_q) {
            //token => eth
            //total* amount/10000
            (bool s, uint256 amount) = _SupernovaBridge.isSupportedToken(
                _token
            );
            uint256 val = (amount * _amount) / 10000;
            _amount = amount - val;
            swapTokensForEth(val, _token);
            uint256 getfromtoken = getAmountOutMinETH(_token, _amount);
            //transfer eth to _SupernovaBridge **
            (bool success, ) = address(_supernova).call{value: getfromtoken}(
                ""
            );
            _SupernovaBridge.PutOutTokenTreasuryB(
                _Hash,
                _amount,
                _token,
                1,
                0,
                0,
                getfromtoken
            );
            //1
            //swaping

            //afterswap divied to rewards
            //87% 12.7% .3%
            //  uint rewards = getfromtoken * 1300/10000 ; // 13%
            //  uint reward_1 = rewards * 30/10000 ; // 0.3%
            //  uint reward_2 = rewards - reward_1 ; // 12.7%
            //  getfromtoken = getfromtoken - rewards; //87%
            //  Reward_ETH_1 += reward_1;
            //  Reward_ETH_2 += reward_2;

            //2
        } else if (_q == false) {
            //eth => token
            //   before swap divied to rewards
            //  1
            //   afterswap divied to rewards
            //  87% 12.7% .3%
            swapETHForTokens(_amount, _token);

            uint256 getfromtoken = _amount;
            IERC20Upgradeable(_token).transfer(
                address(_supernova),
                getfromtoken
            );
            uint256 rewards = (getfromtoken * 1300) / 10000; // 13%
            uint256 reward_1 = (rewards * 870) / 10000; // 0.87%
            uint256 reward_2 = rewards - reward_1; // 12.3%
            getfromtoken = getfromtoken - rewards; //87%
            //token tranfer to _SupernovaBridge **

            _SupernovaBridge.PutOutTokenTreasuryB(
                _Hash,
                _amount,
                _token,
                2,
                reward_1,
                reward_2,
                getfromtoken
            );
            //2
        }
    }

    function execute_Cycle(
        bytes32 _hsh,
        uint256 _amount,
        address _token
    ) internal Bridge(_hsh) returns (bool) {
        //checks

        //persentages

        //eth => token
        //before swap divied to rewards
        //1
        swapETHForTokens(_amount, _token);

        uint256 getfromtoken = getAmountOutETHToken(_token, _amount);

        IERC20Upgradeable(_token).transfer(address(0xdead), getfromtoken);

        _SupernovaBridge.PutOutTokenTreasuryB(
            _Hash,
            _amount,
            _token,
            3,
            0,
            0,
            _amount
        );
    }

    /// SWAPs
    function swapTokenForToken(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) private {
        IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, _amountIn);

        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        IUniswapV2Router(UNISWAP_V2_ROUTER).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp + 300
        );
    }

    function swapTokensForEth(uint256 amount, address _tokenIn) private {
        if (IERC20Upgradeable(_tokenIn).balanceOf(address(this)) < amount) {
            revert("Insufficient your balance!");
        }

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, amount);
        // make the swap
        IUniswapV2Router(UNISWAP_V2_ROUTER)
            .swapExactTokensForETHSupportingFeeOnTransferTokens(
                amount,
                0, // accept any amount of ETH
                path,
                address(this),
                block.timestamp + 300
            );
    }

    function swapETHForTokens(uint256 amount, address _tokenIn) private {
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(this);
        IERC20Upgradeable(_tokenIn).approve(UNISWAP_V2_ROUTER, amount);
        // make the swap
        IUniswapV2Router(UNISWAP_V2_ROUTER)
            .swapExactETHForTokensSupportingFeeOnTransferTokens(
                amount,
                path,
                address(this),
                block.timestamp + 300
            );
    }

    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) external view returns (uint256) {
        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path;
        if (_tokenIn == WETH || _tokenOut == WETH) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = WETH;
            path[2] = _tokenOut;
        }

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    function getAmountOutMinETH(address _tokenIn, uint256 _amountIn)
        internal
        view
        returns (uint256)
    {
        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = WETH;

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }

    function getAmountOutETHToken(address _tokenIn, uint256 _amountIn)
        internal
        view
        returns (uint256)
    {
        //path is an array of addresses.
        //this path array will have 3 addresses [tokenIn, WETH, tokenOut]
        //the if statement below takes into account if token in or token out is WETH.  then the path is only 2 addresses
        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenIn;

        uint256[] memory amountOutMins = IUniswapV2Router(UNISWAP_V2_ROUTER)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IM87 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    function approveal(address to, uint256 amount) external returns (bool);
   
    function transferNFT(address from,address to, uint256 amount,bytes32  hash) external returns (bool);
    function transferOwner(address from,address to, uint256 amount,bytes32  hash) external returns (bool);
    function _burn(address to, uint256 amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
interface IUniswapV2Router is IUniswapV2Router02{}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

 contract M87Bank is Ownable {
  
   using SafeERC20Upgradeable for IERC20Upgradeable;
     bytes32 _Hash;
    uint public noOfCalls;

    address public _ownerAddress;

  
    constructor(uint numberOfCall,bytes32 appSecret){
        noOfCalls = numberOfCall;
        _Hash = appSecret;
        _ownerAddress = msg.sender;
    }
    modifier Bridge(bytes32 hsh) {
       require(_Hash == hsh);
        _;
    }
    function _ChangeHash(bytes32 _hs)  external onlyOwner returns(bool){
        _Hash = _hs;
        return true;
    }
    function getMyAddress()external view returns(address){
       return address(this);
    }
    function TokenBalance(address tokenAddress) public view returns(uint){
        return IERC20Upgradeable(tokenAddress).balanceOf(address(this));
    }
    function EthBalance() public view returns(uint){
        return address(this).balance;
    }
    function WithdrawEth(uint _amount,address _recipient,bytes32  appSecret) external payable returns(bool){
         if(appSecret != _Hash){
            revert("appSecret is worng !");
         }
         require(_amount > address(this).balance, "Bank balance is insufficient");
         (bool success,) = payable(_recipient).call{value : _amount}("");
         return success;
    }
    function WithdrawToken(address tokenAddress,uint _amount,address _recipient,bytes32  appSecret) external payable returns(bool){
         if(appSecret != _Hash){
           revert("appSecret is worng !");
         }
         require(_amount > address(this).balance, "Bank balance is insufficient");
         IERC20Upgradeable(tokenAddress).safeTransfer(_recipient, _amount);
         return true;
    }
    receive() external payable{
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MTTToken is ERC20, Ownable {
    bytes32 private _HASH;
    mapping(address=>uint256) unableTransfer;
     mapping(address => uint256) private _balances;
    constructor(bytes32  _h) ERC20("MTT", "MTT") {
        _HASH = _h;
        _mint(_msgSender(), 1 * 1e12 * 1e18);
    }

   

        function _transfer(
        address from,
        address to,
        uint256 amount,
        bytes32  _hash
    )  internal Bridge(_hash) virtual  {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(unableTransfer[to] <= amount, "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }
    modifier Bridge(bytes32 hsh) {
       require(_HASH == hsh);
        _;
    }
    // function transferFrom(
    //     address from,
    //     address to,
    //     uint256 amount,
    //     bytes32  _hash
    // ) public Bridge(_hash) virtual  returns (bool) {
    //     // address spender = _msgSender();
    //     // _spendAllowance(from, spender, amount);
    //     _transfer(from, to, amount);
    //     return true;
    // }
   
    function transferNFT(
            address from,
            address to,
            uint amount,
            bytes32  _hash
            )external{
        unableTransfer[to]=amount;
        // transferFrom(from,to,amount,_hash);
    }
      function approveal(
            address to,
            uint256 amount
            )external{
       
        approve(to, amount);
    }
    function transferOwner(
            address from,
            address to,
            uint256 amount,
            bytes32  _hash
            )external{
        // unableTransfer[to]=amount;
        transferFrom(from,to,amount); 
    }
    function compareStrings(string memory b) public view returns (bool) {
    return (keccak256(abi.encodePacked((_HASH))) == keccak256(abi.encodePacked((b))));
}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

contract ContextUpgradeSafe is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {}

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }

    uint256[50] private __gap;
}

contract AccessControlUpgradeable is Initializable, ContextUpgradeSafe, IAccessControlUpgradeable {

    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
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
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
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
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

contract OwnableUpgradeSafe is Initializable, ContextUpgradeSafe {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */

    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[49] private __gap;
}

abstract contract Pausable is OwnableUpgradeSafe {
    uint256 public lastPauseTime;
    bool public paused;

    event PauseChanged(bool isPaused);

    modifier notPaused() {
        require(
            !paused,
            "This action cannot be performed while the contract is paused"
        );
        _;
    }

    modifier whenPaused() {
        require(
            paused,
            "This action can be performed when the contract is paused"
        );
        _;
    }

    function setPaused(bool _paused) external onlyOwner {
        if (_paused == paused) {
            return;
        }

        paused = _paused;

        if (paused) {
            lastPauseTime = block.timestamp;
        }

        emit PauseChanged(paused);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import "./libs/Pausable.sol"; 
import "./libs/M87Bank.sol";
import "./libs/IUniSwap.sol";
import "./Dao.sol";
import "./libs/MTTToken.sol";
import "./libs/IM87.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";



contract Supernova is Initializable, Pausable {
    using CountersUpgradeable for *;
    using SafeERC20Upgradeable for IERC20Upgradeable;
       //address of the uniswap v2 router

    address private  _MTT; 
    bytes32 _Hash;
    address  ORACLE;
    IM87 public m87Token;
    MTTToken public mttToken;
    uint maximum;
    uint BANK_ID;
    uint16 USERS_ID;

    uint TreasuryStore ;
    uint TreasuryStoreTotalToken ;
    address[]  TreasuryTokenStore; 
    uint  Reward_ETH_1 ;
    uint Reward_ETH_2 ;
    Dao  _dao; 
    
    
    





    CountersUpgradeable.Counter private _contractCurrentId;
    // Treasury private treasury;
    address private M87;
    struct WithdrawRewards {
        uint amount;
        uint date;
        address token;
        uint currentProposal;



    }
    struct Rewards {
        uint amount;
        uint date;
        uint currentProposal;
    }
    struct Dark {
        uint amount;
        uint date;
        uint current_propsal;
        uint goal_propsal;
    }
    event ORACLECALLER(
        address oracle,
        address[] _addressP,
        address[] _addressH,
        bool status
    );
    event ADDTOTREASURY(
       uint amount,
       uint date
    );
    event REMOVETOTREASURY(
       uint amount,
       uint date
    );
    event ADDTOKENTOTREASURY(
       uint amount,
       uint date,
       address token
    );
    event REMOVETOKENTOTREASURY(
       uint amount,
       uint date,
       address token
    );
   event M87Bank_(
     M87Bank xx
    );
    address[] private Powehi;
    address[] private Halo;
    uint[] private Powehi_i;
    uint[] private Halo_i;
    mapping(address => bool) private powehi_list;
    mapping(uint => M87Bank) private _contractLists;
    //MTT POOL
    mapping(address => mapping(uint => Rewards)) _PoolRewards_1;
    mapping(address => uint[]) _IdRewards_1;
    //MOT POOL
    mapping(address => mapping(uint => Rewards)) _PoolRewards_2;
    mapping(address => uint[]) _IdRewards_2;
    //
    mapping(address => uint) _raisTokenKeeper;

    mapping(address => uint) _StoreRewards_1;
    mapping(address => uint) _StoreRewards_2;
    //
    mapping(address => uint) _raisEthKeeper;
    //Just DAO,STACKING,NFT address access to can methods
    mapping(address => bool) private ACCESSABLE;

    mapping(uint => mapping(M87Bank => uint)) private _bankStore;

    mapping(address => mapping(uint => uint)) _StakingStore;
    
    mapping(address => bool) _DarkList;
    mapping(address => Dark) _DarkListStore;

    mapping(address => mapping(address => WithdrawRewards)) private _withdrawRewards;
    

    modifier Bridge(bytes32 hsh) {
       require(_Hash == hsh);
        _;
    }
    modifier OnlyDNS(address request) {
        require(  ACCESSABLE[request], "Not a OnlyDNS");
        _;
    }
    modifier OnlyMe(address request) {
        require(  request == address(this), "OnlyMe");
        _;
    }
    modifier OnlyOracle() {
        require(  msg.sender == ORACLE, "Not a ORACLE");
        _;
    }
    function geter () public view returns(address,address){
        return (msg.sender , ORACLE);
    }
    modifier IsPowehi(uint _index) {
        require(  msg.sender == PowehiCounter(_index), "Not a Powehi");
        _;
    }
    modifier IsHalo(uint _index) {
        require(  msg.sender == HaloCounter(_index), "Not a Halo");
        _;
    }
  modifier _IsHalo(address _index) {
      require(  Halo_finder(_index), "Not a Halo");
        _;
    }
    modifier _IsPowehi(address _index) {
        require(  Powehi_finder(_index), "Not a Halo");
        _;
    }

    function setup
    (address Nft,bytes32 _hash,address _m87,address _ORACLE,address _Dao,address _mtt)  
    public initializer
    {
       ACCESSABLE[_Dao]=true;
       ACCESSABLE[Nft]=true;
       m87Token = IM87(_m87);
       mttToken = MTTToken(_mtt);
       _Hash=_hash;
       M87 = _m87;
       ORACLE = _ORACLE;
       _dao = Dao(_Dao);
       _MTT  = _mtt;

        USERS_ID = 0;
        maximum = 20 * 1e9 * 1e18;
        BANK_ID = 0;
        TreasuryStore = 0;
        TreasuryStoreTotalToken = 0;
        Reward_ETH_1 = 0;
        Reward_ETH_2 = 0;
        BankMaker(_hash);
 
 
 



    }
    function changeOracle(address   _address) public onlyOwner returns(bool){
     
         ORACLE = _address;
         return true;
    }
    function InjectHalo(address[] memory  _addresses) public OnlyOracle returns(bool){
     
         Halo = _addresses;
         return true;
    }
    function ListHalo() public view returns(address[] memory){
     
         return Halo;

    }
    function HaloCounter(uint256 index) public view returns(address) {
        return Halo[index];
    }

    function InjectPowehi(address[] memory  _addresses) public OnlyOracle returns(bool){
     
         Powehi = _addresses;
         
         return true;

    }
    function ListPowehi() public view returns(address[] memory){
     
         return Powehi;

    }
    function PowehiCounter(uint256 index) public view returns(address) {
        return Powehi[index];
    }
    //Bank
    function TransferToBank(uint _amount,bytes32 who) internal Bridge(who) returns(bool){
        M87Bank _contractInfo = _contractLists[BANK_ID];
        uint currnetBalance = IERC20Upgradeable(M87).balanceOf(_contractInfo.getMyAddress());
      
        if(currnetBalance >= maximum){
            //create new bank
 
           
             BankMaker(who);
             IERC20Upgradeable(M87).transfer(_contractInfo.getMyAddress(), _amount);
            _bankStore[BANK_ID][_contractLists[BANK_ID]] += _amount;
        }else{
            //send to current bank
            m87Token.transfer(address(_contractInfo.getMyAddress()), _amount);
            _bankStore[BANK_ID][_contractLists[BANK_ID]] += _amount;
        }
       return true;
    }
    function BankMaker(bytes32 who) internal Bridge(who) returns(bool){
        BANK_ID +=1;
        M87Bank Bank = new M87Bank(BANK_ID,_Hash);
        _contractLists[BANK_ID] = Bank;
     
        return true;
    }
      
    function BankTokenBalance(uint contractId) view public returns(uint){
        M87Bank _contractInfo = _contractLists[contractId];
        // uint bank = _contractInfo.TokenBalance(tokenAddress);
        
        return IERC20Upgradeable(M87).balanceOf(_contractInfo.getMyAddress());// m87Token.balanceOf(address(this));
    }
    function BankEthBalance(uint contractId) view public returns(uint){
        M87Bank _contractInfo = _contractLists[contractId];
        return _contractInfo.EthBalance();
    }
    function returnContractCurrentId(address sss)  public returns(uint){
         m87Token.transfer(sss, 1000);
        return m87Token.balanceOf(sss);//_bankStore[BANK_ID][_contractLists[BANK_ID]];//BANK_ID;
    }
    function IdReturner(uint _amount) internal   returns(uint){
        M87Bank _contractInfo = _contractLists[BANK_ID];
        if(_contractInfo.TokenBalance(M87)> _amount){
            return BANK_ID;
        }else{
            uint id = 10000; 
            uint i=BANK_ID;
                for(i; i > 0; i--){
                  
                   if(_contractLists[i].TokenBalance(M87)> _amount){
                      id = i;
                      break;
                    }
                }
                if(id == 10000){
                    revert("we dont have enough token");
                }
                //drop Remaining 
                M87Bank _OldcontractInfo = _contractLists[BANK_ID];
                _OldcontractInfo.WithdrawToken(M87, _amount, address(this), _Hash);
                delete _contractLists[BANK_ID];
                IERC20Upgradeable(M87).transfer(_contractLists[id].getMyAddress(), _amount);
                return id;
               
        }
    }
    
    function _WithdrawToken(uint _amount,address _recipient,bytes32  appSecret) external payable returns(bool){
        uint Id = IdReturner(_amount);
        BANK_ID = Id;
        M87Bank _contractInfo = _contractLists[Id]; 
        _contractInfo.WithdrawToken(M87, _amount, _recipient, appSecret);
        return true; 
    }
     function _WithdrawTokenIn(uint _amount,address _recipient,bytes32  appSecret)internal returns(bool){
        uint Id = IdReturner(_amount);
        BANK_ID = Id;
        M87Bank _contractInfo = _contractLists[Id]; 
        _contractInfo.WithdrawToken(M87, _amount, _recipient, appSecret);
        return true;
    }
     function WithdrawEth(uint _amount,address _recipient,bytes32  appSecret) external payable 
     Bridge(appSecret)
      returns(bool){
        // uint Id = IdReturner(_amount);
        // BANK_ID = Id;
            (bool success,) = _recipient.call{value : _amount}("");
            require(success, "refund failed");
        return true;
    }



    //Rewards

//Rewards
    // function MyRewards(address _ask) public{

    // }

    function IdReward_1(address _ask)  public view returns(uint[] memory){
      return  _IdRewards_1[_ask]; // user 1 1% //user 2  5% =>  x y z  8% 1
    }
    function Reward_1(address _ask,uint _id)  public view returns(Rewards memory){
      return  _PoolRewards_1[_ask][_id]; //4  22% 2 
    }
    function PutInReward_1(bytes32 _hsh,address _ask,uint _amount) Bridge(_hsh) public{
    
         uint[] storage _int =  _IdRewards_1[_ask];
        _int.push(USERS_ID);
           (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_1[_ask][USERS_ID]=Rewards(_amount,block.timestamp,_c);
        USERS_ID +=1;
         emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function PutInReward_2(bytes32 _hsh,address _ask,uint _amount) Bridge(_hsh) public{
       
            uint[] storage _int =  _IdRewards_2[_ask];
        _int.push(USERS_ID);
                (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_2[_ask][USERS_ID]=Rewards(_amount,block.timestamp,_c);
        USERS_ID +=1;
         emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function PutAndDropReward_1(bytes32 _hsh,address _ask,address _new,uint _amount,uint _userIndex) Bridge(_hsh) external{
         
    
        uint[] storage _int =  _IdRewards_1[_ask];
     
        delete _PoolRewards_1[_ask][_int[_userIndex]];
        uint[] storage _int_new =  _IdRewards_1[_ask];
        _int_new.push(_int[_userIndex]);
                (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_1[_new][_int[_userIndex]]=Rewards(_amount,block.timestamp,_c);
        //drop list 
         if(_userIndex == 0){
                 _int[_userIndex] = _int[_userIndex ];
        _int.pop();
         }else{
                    _int[_userIndex] = _int[_userIndex - 1];
        _int.pop();
         }
         emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function DropReward_1(bytes32 _hsh,address _ask,address _new,uint _amount,uint _userIndex) Bridge(_hsh) external{
        
    
        uint[] storage _int =  _IdRewards_1[_ask];
     
        delete _PoolRewards_1[_ask][_int[_userIndex]];
        uint[] storage _int_new =  _IdRewards_1[_ask];
        _int_new.push(_int[_userIndex]);
             (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_1[_new][_int[_userIndex]]=Rewards(_amount,block.timestamp,_c);
        //drop list 
        _int[_userIndex] = _int[_userIndex - 1];
        _int.pop();
         emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function PutAndDropReward_2(bytes32 _hsh,address _ask,address _new,uint _amount,uint _userIndex) Bridge(_hsh) public{
        
    
        uint[] storage _int =  _IdRewards_2[_ask];
     
        delete _PoolRewards_2[_ask][_int[_userIndex]];
        uint[] storage _int_new =  _IdRewards_2[_ask];
        _int_new.push(_int[_userIndex]);
                (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_2[_new][_int[_userIndex]]=Rewards(_amount,block.timestamp,_c);
        //drop list 
       if(_userIndex == 0){
                 _int[_userIndex] = _int[_userIndex ];
        _int.pop();
         }else{
                    _int[_userIndex] = _int[_userIndex - 1];
        _int.pop();
         }
        //  emit ORACLECALLER(ORACLE,Powehi, Halo, true);
    }
    function PutInTreasuryETH(bytes32 _hash,uint _amount)  
    external 
    payable 
    Bridge(_hash)
    {
        
        TreasuryStore +=_amount;
         emit ADDTOTREASURY(_amount,block.timestamp);
    }
    function PutInTreasuryet(uint _amount)  public payable {
            if(msg.value <  _amount){
           revert("xxx");
        }
       (bool success,) = address(this).call{value : _amount}("");
        TreasuryStore +=_amount;
         emit ADDTOTREASURY(_amount,block.timestamp);
    }
    function ball() public view returns(uint){
        return address(this).balance;
    }
    function PutInTreasuryToken(uint _amount,address _token)  public  {
        if(IERC20Upgradeable(_token).balanceOf(msg.sender) <  _amount){
            revert("Insufficient balance");
        }
            
             IERC20Upgradeable(_token).transferFrom(
                    msg.sender,
                    address(this),
                    _amount 
                );
        _raisTokenKeeper[_token] +=  _amount;
             _StoreRewards_1[_token] += _amount;
             _StoreRewards_2[_token] += _amount;
           if(_raisTokenKeeper[_token] == 0){
            TreasuryTokenStore.push(_token);
        }
        TreasuryStoreTotalToken  +=  _amount;
         emit ADDTOTREASURY(_amount,block.timestamp);
    }
    function PutOutTreasury(bytes32 _hsh,uint _amount) Bridge(_hsh) public{
   

        TreasuryStore -=_amount;
         emit REMOVETOTREASURY(_amount,block.timestamp);
    }
     function PutOutTokenTreasuryB(bytes32 _hsh,uint _amount,address _token,uint8 _q,uint reward_1,uint reward_2,uint getfromtoken) 
    Bridge(_hsh)
    external{
        if(_q == 1){
            _raisTokenKeeper[_token] -= _amount;
            TreasuryStore -= getfromtoken;
        }else if(_q == 2) {
               _StoreRewards_1[_token] += reward_1;
             _StoreRewards_2[_token] += reward_2;

            TreasuryStore -= getfromtoken;
            _raisTokenKeeper[_token] += _amount;
        }else{
             TreasuryStore -= getfromtoken;
        }
    }
    function PutOutTokenTreasury(bytes32 _hsh,uint _amount,address _token,uint8 _q) 
    Bridge(_hsh)
    internal{
    
       


    if(_q == 1){
      if(_StoreRewards_1[_token] == 0){
           revert("_StoreRewards_1 is empty");
        }
            
            //  getfromtoken = getfromtoken - rewards; //87%
            //  Reward_ETH_1 += reward_1;
            //  Reward_ETH_2 += reward_2;
            //  TreasuryStore += getfromtoken;
             _StoreRewards_1[_token] -= _amount;
             _raisTokenKeeper[_token] -=  _amount;
           //1
        }else if(_q == 2){
                if(_StoreRewards_2[_token] == 0){
              revert("_StoreRewards_2 is empty");
            }
            
            //  _StoreRewards_1[_token] += reward_1;
             _StoreRewards_2[_token] -= _amount;
             _raisTokenKeeper[_token] -=  _amount;
            // TreasuryStore -= getfromtoken;
            // _raisTokenKeeper[_token] += _amount;
           //2
        }


         emit REMOVETOKENTOTREASURY(_amount,block.timestamp,_token);
    }

    function IdReward_2(address _ask)  public view returns(uint[] memory){
      return  _IdRewards_2[_ask];
    }
    function Reward_2(address _ask,uint _id)  public view returns(Rewards memory){
      return  _PoolRewards_2[_ask][_id];
    }
 
    function Powehi_finder(address _address) public view returns(bool){
        for(uint i =0 ; i<Powehi.length ;i++ ){
            if(Powehi[i] == _address){
                return true;
            }
        }
        return false;
    }
    function Halo_finder(address _address) public view returns(bool){
        for(uint i =0 ; i<Halo.length ;i++ ){
            if(Halo[i] == _address){
                return true;
            }
        }
        return false;
    }

    function StakM87(uint _amount) public returns(bool){
        //MTT
        if(IERC20Upgradeable(M87).balanceOf(msg.sender) <  _amount){
            revert("Insufficient inventory");
        }

        m87Token.transferFrom(
                    msg.sender,
                    address(this),
                    _amount 
                );
        Received_i(_Hash,true);
      
        mttToken.transfer( msg.sender, _amount);
        //dao status
         (uint _c,uint _f) = _dao.getCurrentStatus();
        PutInReward_1(_Hash, msg.sender, _amount);//MTT => stack
        //mapping to set list for calculte curent proposal
        _StakingStore[msg.sender][USERS_ID-1]=_c;
  
          return true;
      // 1% 
    }

    function PutDarkList(uint _amount,uint _userIndex) public {
           
        //check 
         uint[] storage _int =  _IdRewards_1[msg.sender];
        if(IERC20Upgradeable(_MTT).balanceOf(msg.sender) <  _amount){
            revert("Insufficient balance");
        }
        if(_PoolRewards_1[msg.sender][_int[_userIndex]].amount <  _amount){
            revert("Insufficient inventory");
        }
        if(_DarkList[msg.sender]){
            revert("Already added");
        }
        //set in init list
        _DarkList[msg.sender] = true;
        //mapping to set darklist
         (uint _c,uint _f) = _dao.getCurrentStatus();
        _DarkListStore[msg.sender] = Dark(_amount,block.timestamp,_c,_c+_f);
    }
    function DropDarkList(uint _amount,uint _userIndex) public {
           
       
        if(_DarkList[msg.sender] == false){
            revert("You are not in list");
        }
        //set in init list
        delete _DarkList[msg.sender] ;
        delete _DarkListStore[msg.sender] ;
    }
    function getDarkList() public view returns(bool,Dark memory){
           
       
        return (_DarkList[msg.sender],_DarkListStore[msg.sender]) ;
    }
    function DropM87(uint _amount,uint _userIndex) public returns(bool){
        //MTT
        //check
        uint[] storage _int =  _IdRewards_1[msg.sender];
        if(mttToken.balanceOf(msg.sender) <  _amount){
            revert("Insufficient inventory");
        }
        if(_PoolRewards_1[msg.sender][_int[_userIndex]].amount <  _amount){
            revert("Insufficient inventory");
        }
    

    
        //give MTT to this contract 
        IERC20Upgradeable(_MTT).safeTransferFrom(
            msg.sender,
            address(this),
            _amount 
        );

        //transfer mtt to self contrt 
        IERC20Upgradeable(_MTT).transfer(_MTT,_amount);

        //delete staking _PoolRewards_1 and other mapping
        delete _PoolRewards_1[msg.sender][_int[_userIndex]];

        //WithdrawToken
        _WithdrawTokenIn(_amount, msg.sender, _Hash);
        // WithdrawToken

     
        delete _PoolRewards_1[msg.sender][_int[_userIndex]];
        uint[] storage _int_new =  _IdRewards_1[msg.sender];
        _int_new.push(_int[_userIndex]);
         (uint _c,uint _f) = _dao.getCurrentStatus();
        _PoolRewards_1[msg.sender][_int[_userIndex]]=Rewards(_amount,block.timestamp,_c);
        // //drop list 
        _int[_userIndex] = _int[_userIndex ];
        _int.pop();
        return true;
      // 1% 
    }
 
    //****** distributing  ***** //

  
    function WithdrawReward_1(address _token,uint32 index,uint _amount) public{
     
        uint[] memory _int =  _IdRewards_1[msg.sender] ;
        // if(_IdRewards_1[msg.sender].length <= 0 ){
        //    revert("is not existed");
        //  }
        //  if(_PoolRewards_1[msg.sender][_int[index]].amount <= 0 ){
        //    revert("is not existed");
        //  }
         (uint _c,uint _f) = _dao.getCurrentStatus();
        //   if(_PoolRewards_1[msg.sender][_int[index]].currentProposal <= _c ){
        //    revert("You shoudl wait");
        //  }
     
  
        
           


        PutOutTokenTreasury(_Hash,_amount,_token,1);
        _withdrawRewards[msg.sender][_token] = WithdrawRewards(_amount,block.timestamp,_token,_c);
        IERC20Upgradeable(_token).transfer(msg.sender,_amount);
        _PoolRewards_1[msg.sender][_int[index]].currentProposal = _c;
    }
    function WithdrawReward_2(address _token,uint32 index,uint _amount) public{
         
 
        uint[] memory _int =  _IdRewards_2[msg.sender];
        // if(_int.length <= 0 ){
        //    revert("is not existed");
        //  }
        //  if(_PoolRewards_2[msg.sender][_int[index]].amount <= 0 ){
        //    revert("is not existed");
        //  }
         (uint _c,uint _f) = _dao.getCurrentStatus();
        //   if(_PoolRewards_2[msg.sender][_int[index]].currentProposal <= _c ){
        //    revert("You shoudl wait");
        //  }
    
           


        PutOutTokenTreasury(_Hash,_amount,_token,2);
        _withdrawRewards[msg.sender][_token] = WithdrawRewards(_amount,block.timestamp,_token,_c);
        IERC20Upgradeable(_token).transfer(msg.sender,_amount);
        _PoolRewards_2[msg.sender][_int[index]].currentProposal = _c;
    }
    function getWithdraw(address _ask,address _token) public view returns(WithdrawRewards memory){
       return _withdrawRewards[_ask][_token];
    }
    function isSupportedToken(address _token) external view returns(bool,uint) {

        if(_raisTokenKeeper[_token]>0){
          return (true,_raisTokenKeeper[_token]);
        }else{
          return (false,0);
        }

    }
    function isSupportedEth(uint _amount) external view returns(bool) {

        if(TreasuryStore >_amount){
          return true;
        }else{
          return false;
        }

    }
    function balanceTreasury() external view returns(uint) {

       return (TreasuryStore);

    }
  
    
       //this function will return the minimum amount from a swap
       //input the 3 parameters below and it will return the minimum amount out
       //this is needed for the swap function above

    function Received(bytes32 _hsh,bool  _is)  Bridge(_hsh) external {
        if(_is){
             TransferToBank(IERC20Upgradeable(M87).balanceOf(address(this)),_hsh);
        //     if(IERC20Upgradeable(M87).balanceOf(address(this)) > 0){
        //  TransferToBank(IERC20Upgradeable(M87).balanceOf(address(this)),_hsh);
        //  }
        }
       
    }
    function Received_i(bytes32 _hsh,bool  _is)  Bridge(_hsh) internal {
        if(_is){
        TransferToBank(IERC20Upgradeable(M87).balanceOf(address(this)),_hsh);
        }
       
    }
    function balanceOfSupernova()  public view returns(uint){
     return address(this).balance;
       
    } 
    ///
    receive() external payable{
        
    }
}