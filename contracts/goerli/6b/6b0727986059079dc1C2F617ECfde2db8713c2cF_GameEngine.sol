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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
library SafeMathUpgradeable {
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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Random {
    function numberChosen(
        uint256 min,
        uint256 max,
        uint256 nonce
    ) internal view returns (uint256) {
        uint256 seed = (block.timestamp + block.difficulty) % 100;
        uint256 amount = uint(
            keccak256(
                abi.encodePacked(seed + block.timestamp + nonce, msg.sender, block.number)
            )
        ) % (max - min);
        amount = amount + min;
        return amount;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/Gameable.sol";
import "./interfaces/IPayment.sol";
import "../libraries/Random.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

abstract contract GameBase is
    Gameable,
    Initializable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;

    Game[] public games;
    Tier[] public tiers;

    uint8 public nbGhost;

    mapping(TierType => uint256) public currentTiers;
    mapping(uint256 => mapping(uint256 => NumberChosen)) public playersOf;
    mapping(address => Game[]) public gamesOf;
    mapping(uint256 => mapping(uint256 => NumberChosen)) public ghostsOf;

    IPayment public paymentHandle;

    uint256[2] internal rangeReaper;
    uint256 internal nonce;

    event PlayGame(
        uint256 indexed gameID,
        address indexed addr,
        TierType category
    );

    event NewGame(
        uint256 indexed gameID,
        address indexed addr,
        TierType category
    );

    function initialize() public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();
        Tier memory tier0 = Tier({
            category: TierType.SOUL,
            duration: 3 minutes,
            amount: 2 ether,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isActive: true
        });
        Tier memory tier1 = Tier({
            category: TierType.MUTANT,
            duration: 3 minutes,
            amount: 10 ether,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isActive: true
        });
        Tier memory tier2 = Tier({
            category: TierType.BORED,
            duration: 3 minutes,
            amount: 25 ether,
            createdAt: block.timestamp,
            updatedAt: block.timestamp,
            isActive: true
        });
        tiers.push(tier0);
        tiers.push(tier1);
        tiers.push(tier2);
        rangeReaper[0] = 0;
        rangeReaper[1] = 100;
        _init();
    }

    function _init() internal virtual {}

    function claimPrize(uint256 gameID) public virtual;

    function claimAllPrize() external virtual;

    function claimAllPrizeReaper() external virtual;

    function _claimPrizeReaper(uint256 gameID) internal virtual;

    function numberOfGames() external view returns (uint256) {
        return games.length - 1;
    }

    function getGame(
        uint256 gameID
    ) external view virtual override returns (Game memory) {
        require(gameID > 0, "The game not exist");
        return games[gameID];
    }

    function playerExistsIn(
        uint256 gameID,
        address account
    ) public view returns (bool) {
        for (uint i = 0; i < games[gameID].playersInGame; i++) {
            if (playersOf[gameID][i].id == account) {
                return true;
            }
        }
        return false;
    }

    function getGamesOf(
        address player
    ) external view virtual override returns (Game[] memory) {
        return gamesOf[player];
    }

    function getTier(
        TierType category
    ) public view virtual override returns (Tier memory) {
        for (uint256 i; i < tiers.length; i++) {
            Tier memory tier = tiers[i];
            if (tier.category == category) {
                return tier;
            }
        }
        revert("Not found");
    }

    function getTiers() external view virtual override returns (Tier[] memory) {
        return tiers;
    }

    function getCurrentGame(
        TierType categroy
    ) external view override returns (Game memory) {
        uint256 gameID = currentTiers[categroy];
        return games[gameID];
    }

    function setTier(Tier memory tier) external virtual onlyOwner {
        int256 indexOf = -1;
        for (uint256 i; i < tiers.length; i++) {
            if (tiers[i].category == tier.category) {
                indexOf = int256(i);
            }
        }
        if (indexOf >= 0) {
            Tier storage storedTier = tiers[uint256(indexOf)];
            storedTier.duration = tier.duration;
            storedTier.amount = tier.amount;
            storedTier.isActive = tier.isActive;
            storedTier.updatedAt = block.timestamp;
        }
    }

    function setRangeReaper(
        uint256[] calldata ranges
    ) external virtual onlyOwner {
        require(
            rangeReaper.length == ranges.length,
            "Array should be of same length"
        );
        for (uint i = 0; i < ranges.length; i++) {
            rangeReaper[i] = ranges[i];
        }
    }

    function setNbGhost(uint8 newNbGhost) external onlyOwner {
        nbGhost = newNbGhost;
    }

    function getRanges()
        external
        view
        virtual
        onlyOwner
        returns (uint256[2] memory)
    {
        return rangeReaper;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPaymentHandle(address newPaymentHandle) external onlyOwner {
        paymentHandle = IPayment(newPaymentHandle);
    }

    function _ghostsChosen(
        uint256 gameID,
        uint256 reaperChosen
    ) internal virtual {
        uint256 nonceTemp = nonce.add(block.timestamp).div(7);
        uint256 left = Random.numberChosen(0, 1, nonceTemp.add(reaperChosen));
        uint256 number;
        for (uint160 i = 0; i < nbGhost; i++) {
            nonceTemp++;
            if (left <= 0) {
                number = Random.numberChosen(0, reaperChosen, nonceTemp);
            } else {
                number = Random.numberChosen(reaperChosen, 100, nonceTemp);
            }
            ghostsOf[gameID][i] = NumberChosen({
                id: address(i),
                number: number,
                createdAt: block.timestamp
            });
        }
    }

    function _computeTarget(
        uint256 gameID,
        uint256 size
    ) internal view virtual returns (uint256) {
        uint256 sum = 0;
        uint256 percent = 80;
        for (uint i = 0; i < nbGhost; i++) {
            sum += ghostsOf[gameID][i].number;
        }
        for (uint256 i; i < size; i++) {
            sum += playersOf[gameID][i].number;
        }
        uint256 newSize = size.add(nbGhost);
        return sum.div(newSize).mul(percent).div(100);
    }

    function _getWinner(
        uint256 gameID,
        uint256 size,
        uint256 target
    ) internal view virtual returns (NumberChosen memory) {
        NumberChosen memory winner;
        uint256 closestDiff = type(uint256).max;
        for (uint256 i = 0; i < size; i++) {
            NumberChosen memory numberSelected = playersOf[gameID][i];
            uint256 diff = target > numberSelected.number
                ? target - numberSelected.number
                : numberSelected.number - target;
            if (diff < closestDiff) {
                winner = numberSelected;
                closestDiff = diff;
            }
        }
        return winner;
    }

    function getPlayersInGame(
        uint256 gameID
    ) external view override returns (NumberChosen[] memory) {
        NumberChosen[] memory players = new NumberChosen[](
            games[gameID].playersInGame
        );
        for (uint256 i = 0; i < games[gameID].playersInGame; i++) {
            players[i] = playersOf[gameID][i];
        }
        return players;
    }

    function getGhostsInGame(
        uint256 gameID
    ) external view virtual override returns (NumberChosen[] memory) {
        NumberChosen[] memory ghosts = new NumberChosen[](nbGhost);
        for (uint256 i = 0; i < nbGhost; i++) {
            ghosts[i] = ghostsOf[gameID][i];
        }
        return ghosts;
    }

    function getNbGhosts() external view virtual override returns (uint8) {
        return nbGhost;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./GameBase.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

contract GameEngine is GameBase {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    modifier canPlay(TierType category, uint8 numberChosen) {
        require(_msgSender() != address(0), "Cannot be zero address");
        require(
            numberChosen >= 0 && numberChosen <= 100,
            "The number must be between 0 and 100"
        );
        require(address(paymentHandle) != address(0), "Missing implementation");
        _;
    }

    modifier canClaim(uint256 gameID) {
        require(gameID > 0, "The game not start");
        Game memory game = games[gameID];
        require(block.timestamp >= game.endedAt, "The game is not over");
        require(game.winner == _msgSender(), "You are not the winner");
        require(!game.hasClaim, "The price has been claimed");
        _;
    }

    function _init() internal override {
        nonce = Random.numberChosen(0, 100, 0);
        nbGhost = 3;
    }

    function play(
        TierType category,
        uint8 numberChosen
    )
        external
        override
        whenNotPaused
        nonReentrant
        canPlay(category, numberChosen)
        returns (uint256)
    {
        Tier memory tier = getTier(category);
        paymentHandle.retrievePlayerBet(_msgSender(), tier.amount);
        uint256 lastTier = currentTiers[category];
        uint256 gameID;
        if (lastTier <= 0) {
            NumberChosen[] memory numbersChosen = _getNumbersChosen(
                numberChosen
            );
            gameID = _firstGame(numbersChosen, tier);
            emit NewGame(gameID, _msgSender(), category);
        } else {
            Game storage currentGame = games[lastTier];
            if (block.timestamp < currentGame.endedAt) {
                gameID = lastTier;
                if (!playerExistsIn(gameID, _msgSender())) {
                    _currentGame(
                        currentGame,
                        NumberChosen({
                            id: _msgSender(),
                            number: numberChosen,
                            createdAt: block.timestamp
                        })
                    );
                } else {
                    revert("The player has already played");
                }
            } else {
                _claimPrizeReaper(currentGame.id);
                NumberChosen[] memory numbersChosen = _getNumbersChosen(
                    numberChosen
                );
                gameID = _newGame(numbersChosen, tier);
                emit NewGame(gameID, _msgSender(), category);
            }
        }
        currentTiers[category] = gameID;
        gamesOf[_msgSender()].push(games[gameID]);
        if (playersOf[gameID][0].id == address(this)) {
            gamesOf[address(this)].push(games[gameID]);
        }
        emit PlayGame(gameID, _msgSender(), category);
        return gameID;
    }

    function claimPrize(
        uint256 gameID
    ) public virtual override canClaim(gameID) whenNotPaused {
        Game storage game = games[gameID];
        Tier memory tier = getTier(game.category);
        game.hasClaim = true;
        if (game.playersInGame > 2) {
            paymentHandle.payPVPWinner(
                game.winner,
                tier.amount.mul(game.playersInGame)
            );
        } else {
            if (game.winner == address(this)) {
                paymentHandle.payBotWinner(tier.amount);
            } else {
                paymentHandle.payPlayerWinner(game.winner, tier.amount);
            }
        }
    }

    function claimAllPrize() external virtual override {
        Game[] memory gamesOf = gamesOf[_msgSender()];
        for (uint i = 0; i < gamesOf.length; i++) {
            Game memory game = gamesOf[i];
            if (
                block.timestamp >= game.endedAt &&
                game.winner == _msgSender() &&
                !game.hasClaim
            ) {
                claimPrize(game.id);
            }
        }
    }

    function _claimPrizeReaper(uint256 gameID) internal virtual override {
        Game storage game = games[gameID];
        if (
            game.winner == address(this) &&
            block.timestamp >= game.endedAt &&
            !game.hasClaim
        ) {
            Tier memory tier = getTier(game.category);
            game.hasClaim = true;
            paymentHandle.payBotWinner(tier.amount);
        }
    }

    function claimAllPrizeReaper()
        external
        virtual
        override
        onlyOwner
        whenNotPaused
    {
        Game[] storage gamesOf = gamesOf[address(this)];
        for (uint i = 0; i < gamesOf.length; i++) {
            Game storage game = gamesOf[i];
            if (
                block.timestamp >= game.endedAt &&
                game.winner == address(this) &&
                !game.hasClaim
            ) {
                Tier memory tier = getTier(game.category);
                game.hasClaim = true;
                paymentHandle.payBotWinner(tier.amount);
            }
        }
    }

    function _getNumbersChosen(
        uint8 numberChosen
    ) internal virtual returns (NumberChosen[] memory) {
        nonce++;
        NumberChosen memory botA = NumberChosen({
            id: address(this),
            number: Random.numberChosen(rangeReaper[0], rangeReaper[1], nonce),
            createdAt: block.timestamp
        });
        nonce = nonce.add(block.timestamp).div(3);
        NumberChosen memory player = NumberChosen({
            id: _msgSender(),
            number: numberChosen,
            createdAt: block.timestamp
        });
        NumberChosen[] memory numbersChosen = new NumberChosen[](2);
        numbersChosen[0] = botA;
        numbersChosen[1] = player;
        return numbersChosen;
    }

    function _firstGame(
        NumberChosen[] memory numbersChosen,
        Tier memory tier
    ) internal virtual returns (uint256) {
        uint256 sizeGame = games.length;
        uint256 gameID;
        Game memory game = Game({
            id: 0,
            winner: address(0),
            playersInGame: numbersChosen.length,
            startedAt: block.timestamp,
            endedAt: block.timestamp + tier.duration,
            updatedAt: block.timestamp,
            category: tier.category,
            hasClaim: false
        });
        if (sizeGame <= 0) {
            games.push();
            games.push(game);
            gameID = 1;
        } else {
            gameID = sizeGame;
            games.push(game);
        }
        for (uint256 i = 0; i < numbersChosen.length; i++) {
            playersOf[gameID][i] = numbersChosen[i];
        }
        _ghostsChosen(gameID, numbersChosen[0].number);
        uint256 target = _computeTarget(gameID, numbersChosen.length);
        games[gameID].winner = _getWinner(gameID, numbersChosen.length, target)
            .id;
        games[gameID].id = gameID;
        return gameID;
    }

    function _currentGame(
        Game storage game,
        NumberChosen memory newPlayer
    ) internal virtual {
        if (playersOf[game.id][0].id == address(this)) {
            playersOf[game.id][0] = newPlayer;
            _removeGameOf(address(this), game.id);
        } else {
            playersOf[game.id][game.playersInGame] = newPlayer;
            game.playersInGame += 1;
        }
        _ghostsChosen(
            game.id,
            Random.numberChosen(0, 100, nonce.add(block.timestamp).add(1))
        );
        uint256 target = _computeTarget(game.id, game.playersInGame);
        NumberChosen memory winner = _getWinner(
            game.id,
            game.playersInGame,
            target
        );
        game.winner = winner.id;
        game.updatedAt = block.timestamp;
    }

    function _newGame(
        NumberChosen[] memory numbersChosen,
        Tier memory tier
    ) internal virtual returns (uint256) {
        uint256 gameID = games.length;
        Game memory game = Game({
            id: gameID,
            winner: address(0),
            playersInGame: numbersChosen.length,
            startedAt: block.timestamp,
            endedAt: block.timestamp + tier.duration,
            updatedAt: block.timestamp,
            category: tier.category,
            hasClaim: false
        });
        games.push(game);
        for (uint256 i = 0; i < numbersChosen.length; i++) {
            playersOf[gameID][i] = numbersChosen[i];
        }
        _ghostsChosen(gameID, numbersChosen[0].number);
        uint256 target = _computeTarget(
            gameID,
            numbersChosen.length
        );
        games[gameID].winner = _getWinner(gameID, numbersChosen.length, target)
            .id;
        games[gameID].id = gameID;
        return gameID;
    }

    function _removeGameOf(address account, uint256 gameID) internal virtual {
        int256 indexOf = -1;
        for (uint256 i = 0; i < gamesOf[account].length; i++) {
            if (gamesOf[account][i].id == gameID) {
                indexOf = int256(i);
            }
        }
        if (indexOf >= 0) {
            gamesOf[account][uint256(indexOf)] = gamesOf[account][
                gamesOf[account].length - 1
            ];
            gamesOf[account].pop();
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface Gameable {
    enum TierType {
        BORED,
        MUTANT,
        SOUL
    }

    struct Game {
        uint256 id;
        address winner;
        uint256 playersInGame;
        uint256 startedAt;
        uint256 endedAt;
        uint256 updatedAt;
        TierType category;
        bool hasClaim;
    }

    struct Player {
        address id;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 numberOfGames;
    }

    struct NumberChosen {
        address id;
        uint256 number;
        uint256 createdAt;
    }

    struct Tier {
        TierType category;
        uint256 duration;
        uint256 amount;
        uint256 createdAt;
        uint256 updatedAt;
        bool isActive;
    }

    function play(
        TierType category,
        uint8 numberChosen
    ) external returns (uint256);

    function getGamesOf(address player) external view returns (Game[] memory);

    function getTiers() external view returns (Tier[] memory);

    function getCurrentGame(
        TierType categroy
    ) external view returns (Game memory);

    function getPlayersInGame(
        uint256 gameID
    ) external view returns (NumberChosen[] memory);

    function getGhostsInGame(
        uint256 gameID
    ) external view returns (NumberChosen[] memory);

    function getTier(TierType category) external view returns (Tier memory);

    function getGame(uint256 gameID) external view returns (Game memory);

    function getNbGhosts() external view returns(uint8);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPayment {
    event PayPlayerWin(address winner, uint256 betAmount, uint256 payout);
    event PayBotWin(uint256 betAmount);
    event PlayerBet(address player, uint256 amount);
    event DispatchFunds(uint256 totalAmount, uint128 liquidity, uint256 amount0, uint256 amount1);

    /**
     * @notice Get the payment of the player betting on a game
     *
     * @param player The address of the player that bet
     * @param amount The amount of the player's bet
     */
    function retrievePlayerBet(address player, uint256 amount) external;

    /**
     * @notice Pay the winner of the game after fees deduction
     *
     * @param winner The address of the winner of the game
     * @param amount The amount of the bet
     */
    function payPVPWinner(address winner, uint256 amount) external;

    /**
     * @notice Called when bot has won a game
     *
     * @param amount Amount the player has bet
     */
    function payBotWinner(uint256 amount) external;

    /**
     * @notice Called when player won and bot has played
     *
     * @param winner The address of the winner
     * @param betAmount Amount the player has bet
     */
    function payPlayerWinner(address winner, uint256 betAmount) external;

    function getPayoutMultiplier() external view returns(uint256);
}