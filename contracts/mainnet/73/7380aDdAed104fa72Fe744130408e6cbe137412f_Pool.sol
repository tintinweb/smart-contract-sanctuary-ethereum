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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../libraries/ExceptionsLibrary.sol";
import "../interfaces/IService.sol";
import "../interfaces/IPool.sol";
import "../interfaces/IDispatcher.sol";

/// @dev Proposal module for Pool's Governance Token
abstract contract Governor {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @dev Proposal structure
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param target Target
     * @param value ETH value
     * @param callData Call data to pass in .call() to target
     * @param startBlock Start block
     * @param endBlock End block
     * @param forVotes For votes
     * @param againstVotes Against votes
     * @param executed Is executed
     * @param state Proposal state
     * @param description Description
     * @param totalSupply Total supply
     * @param lastVoteBlock Block when last vote was cast
     * @param proposalType Proposal type
     * @param execDelay Execution delay for the proposal, blocks
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     */
    struct Proposal {
        uint256 ballotQuorumThreshold;
        uint256 ballotDecisionThreshold;
        address[] targets;
        uint256[] values;
        bytes callData;
        uint256 startBlock;
        uint256 endBlock; // startBlock + ballotLifespan
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        ProposalExecutionState state;
        string description;
        uint256 totalSupply;
        uint256 lastVoteBlock;
        IDispatcher.ProposalType proposalType;
        uint256 execDelay;
        string metaHash;
        address token;
    }

    /// @dev Proposals
    mapping(uint256 => Proposal) private _proposals;

    /// @dev For votes
    mapping(address => mapping(uint256 => uint256)) private _forVotes;

    /// @dev Against votes
    mapping(address => mapping(uint256 => uint256)) private _againstVotes;

    /// @dev Last proposal ID
    uint256 public lastProposalId;

    /// @dev Proposal state, Cancelled, Executed - unused
    enum ProposalState {
        None,
        Active,
        Failed,
        Successful,
        Executed,
        Cancelled
    }

    /// @dev Proposal execution state
    /// @dev unused - to refactor
    enum ProposalExecutionState {
        Initialized,
        Rejected,
        Accomplished,
        Cancelled
    }

    // EVENTS

    /**
     * @dev Event emitted on proposal creation
     * @param proposalId Proposal ID
     * @param quorum Quorum
     * @param targets Targets
     * @param values Values
     * @param calldatas Calldata
     * @param description Description
     */
    event ProposalCreated(
        uint256 proposalId,
        uint256 quorum,
        address[] targets,
        uint256[] values,
        bytes calldatas,
        string description
    );

    /**
     * @dev Event emitted on proposal vote cast
     * @param voter Voter address
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param support Against or for
     */
    event VoteCast(
        address voter,
        uint256 proposalId,
        uint256 votes,
        bool support
    );

    /**
     * @dev Event emitted on proposal execution
     * @param proposalId Proposal ID
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Event emitted on proposal cancellation
     * @param proposalId Proposal ID
     */
    event ProposalCancelled(uint256 proposalId);

    /**
     * @dev Event emitted on error in try/catch block
     * @param data Error data
     */
    event ErrorCaugth(bytes data);

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return proposal state
     * @param proposalId Proposal ID
     * @return ProposalState
     */
    function proposalState(uint256 proposalId)
        public
        view
        returns (ProposalState)
    {
        Proposal memory proposal = _proposals[proposalId];
        if (proposal.executed) {
            return ProposalState.Executed;
        }
        if (proposal.startBlock == 0) {
            return ProposalState.None;
        }

        if (proposal.state == ProposalExecutionState.Cancelled) {
            return ProposalState.Cancelled;
        }

        uint256 totalAvailableVotes = _getTotalSupply() -
            _getTotalTGEVestedTokens();
        uint256 quorumVotes = (totalAvailableVotes *
            proposal.ballotQuorumThreshold);
        uint256 totalCastVotes = proposal.forVotes + proposal.againstVotes;

        ProposalState aheadOfTimeBallotResult = aheadOfTimeBallot(totalCastVotes, quorumVotes,
                                proposal, totalAvailableVotes);
        if (aheadOfTimeBallotResult != ProposalState.None)
            return aheadOfTimeBallotResult;

        if (block.number > proposal.endBlock) {
            if (
                totalCastVotes >= quorumVotes &&
                proposal.forVotes * 10000 >=
                totalCastVotes * proposal.ballotDecisionThreshold
            ) {
                return ProposalState.Successful;
            } else return ProposalState.Failed;
        }
        return ProposalState.Active;

    }

    function aheadOfTimeBallot(
        uint256 totalCastVotes, 
        uint256 quorumVotes, 
        Proposal memory proposal, 
        uint256 totalAvailableVotes
    ) public pure returns (ProposalState) {
        uint256 decisionVotes = totalCastVotes * proposal.ballotDecisionThreshold;
        uint256 minForVotes = totalAvailableVotes * proposal.ballotDecisionThreshold;

        if (
            totalCastVotes * 10000 >= quorumVotes && // /10000 because 10000 = 100%
            proposal.forVotes * 10000 >= decisionVotes && // * 10000 because 10000 = 100%
            proposal.forVotes * 10000 >= minForVotes
        ) {
            return ProposalState.Successful;
        }
        if (
            proposal.forVotes * 10000 < decisionVotes && // * 10000 because 10000 = 100%
            (totalAvailableVotes - proposal.againstVotes) * 10000 < minForVotes
        ) {
            return ProposalState.Failed;
        }

        return ProposalState.None;
    }

    /**
     * @dev Return proposal
     * @param proposalId Proposal ID
     * @return Proposal
     */
    function getProposal(uint256 proposalId)
        public
        view
        returns (Proposal memory)
    {
        return _proposals[proposalId];
    }

    /**
     * @dev Return proposal for votes for a given user
     * @param user User address
     * @param proposalId Proposal ID
     * @return For votes
     */
    function getForVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _forVotes[user][proposalId];
    }

    /**
     * @dev Return proposal against votes for a given user
     * @param user User address
     * @param proposalId Proposal ID
     * @return Against votes
     */
    function getAgainstVotes(address user, uint256 proposalId)
        public
        view
        returns (uint256)
    {
        return _againstVotes[user][proposalId];
    }

    // INTERNAL FUNCTIONS

    /**
     * @dev Create proposal
     * @param ballotLifespan Ballot lifespan
     * @param ballotQuorumThreshold Ballot quorum threshold
     * @param ballotDecisionThreshold Ballot decision threshold
     * @param targets Targets
     * @param values Values
     * @param callData Calldata
     * @param description Description
     * @param totalSupply Total supply
     * @param execDelay Execution delay
     * @param proposalType Proposal type
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     * @return proposalId Proposal ID
     */
    function _propose(
        uint256 ballotLifespan,
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        address[] memory targets,
        uint256[] memory values,
        bytes memory callData,
        string memory description,
        uint256 totalSupply,
        uint256 execDelay,
        IDispatcher.ProposalType proposalType,
        string memory metaHash,
        address token_
    ) internal returns (uint256 proposalId) {
        proposalId = ++lastProposalId;
        _proposals[proposalId] = Proposal({
            ballotQuorumThreshold: ballotQuorumThreshold,
            ballotDecisionThreshold: ballotDecisionThreshold,
            targets: targets,
            values: values,
            callData: callData,
            startBlock: block.number,
            endBlock: block.number + ballotLifespan,
            forVotes: 0,
            againstVotes: 0,
            executed: false,
            state: ProposalExecutionState.Initialized,
            description: description,
            totalSupply: totalSupply,
            lastVoteBlock: 0,
            proposalType: proposalType,
            execDelay: execDelay,
            metaHash: metaHash,
            token: token_
        });
        _afterProposalCreated(proposalId);

        emit ProposalCreated(
            proposalId,
            ballotQuorumThreshold,
            targets,
            values,
            callData,
            description
        );
    }

    /**
     * @dev Cast vote for a proposal
     * @param proposalId Proposal ID
     * @param votes Amount of votes
     * @param support Against or for
     */
    function _castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) internal {
        require(
            _proposals[proposalId].endBlock > block.number,
            ExceptionsLibrary.VOTING_FINISHED
        );

        if (support) {
            _proposals[proposalId].forVotes += votes;
            _forVotes[msg.sender][proposalId] += votes;
        } else {
            _proposals[proposalId].againstVotes += votes;
            _againstVotes[msg.sender][proposalId] += votes;
        }

        _proposals[proposalId].lastVoteBlock = block.number;
        _proposals[proposalId].totalSupply = _getTotalSupply() -
            _getTotalTGEVestedTokens();

        emit VoteCast(msg.sender, proposalId, votes, support);
    }

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     * @param service Service address
     */
    function _executeBallot(
        uint256 proposalId,
        IService service
    ) internal {
        Proposal memory proposal = _proposals[proposalId];

        if (
            proposal.proposalType == IDispatcher.ProposalType.TransferETH || 
            proposal.proposalType == IDispatcher.ProposalType.TransferERC20
        ) {
            require(service.isExecutorWhitelisted(msg.sender), ExceptionsLibrary.INVALID_USER);
        }

        require(
            proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );
        require(
            _proposals[proposalId].state == ProposalExecutionState.Initialized,
            ExceptionsLibrary.ALREADY_EXECUTED
        );

        if (block.number >= proposal.endBlock) {
            require(block.number >= proposal.endBlock + proposal.execDelay, ExceptionsLibrary.BLOCK_DELAY);
        } else {
            require(block.number >= proposal.lastVoteBlock + proposal.execDelay, ExceptionsLibrary.BLOCK_DELAY);
        }

        _proposals[proposalId].executed = true;
        bool success = false;
        for (uint256 i = 0; i < proposal.targets.length; i++) {
             // Give pool shareholders time to cancel bugged/hacked ballot execution
            require(
                isDelayCleared(IPool(address(this)), proposalId, i),
                ExceptionsLibrary.BLOCK_DELAY
            );
            if (proposal.proposalType != IDispatcher.ProposalType.TransferERC20) {
                (success, ) = proposal.targets[i].call{
                    value: proposal.values[i]
                }(proposal.callData);
                require(success, ExceptionsLibrary.EXECUTION_FAILED);
            } else {
                IERC20Upgradeable(proposal.token).safeTransfer(proposal.targets[i], proposal.values[i]);
            }
        }

        if (
            proposal.proposalType == IDispatcher.ProposalType.TransferETH
        ) {
            service.addEvent(
                IDispatcher.EventType.TransferETH,
                proposalId,
                proposal.metaHash
            );
        }

        if (
            proposal.proposalType == IDispatcher.ProposalType.TransferERC20
        ) {
            service.addEvent(
                IDispatcher.EventType.TransferERC20,
                proposalId,
                proposal.metaHash
            );
        }

        if (proposal.proposalType == IDispatcher.ProposalType.TGE) {
            service.addEvent(IDispatcher.EventType.TGE, proposalId, proposal.metaHash);
        }

        if (
            proposal.proposalType ==
            IDispatcher.ProposalType.GovernanceSettings
        ) {
            service.addEvent(
                IDispatcher.EventType.GovernanceSettings,
                proposalId,
                proposal.metaHash
            );
        }

        emit ProposalExecuted(proposalId);
    }

    /**
     * @dev Return: is proposal block delay cleared. Block delay is applied based on proposal type and pool governance settings.
     * @param pool Pool address
     * @param proposalId Proposal ID
     * @return Is delay cleared
     */
    function isDelayCleared(IPool pool, uint256 proposalId, uint256 index)
        public
        returns (bool)
    {
        Proposal memory proposal = _proposals[proposalId];
        uint256 assetValue = 0;

        // proposal type based delay
        uint256 delay = pool.ballotExecDelay(
            uint256(proposal.proposalType) + 1
        );

        // delay for transfer type proposals
        if (
            proposal.proposalType ==
            IDispatcher.ProposalType.TransferETH ||
            proposal.proposalType == IDispatcher.ProposalType.TransferERC20
        ) {
            address from = pool.service().secondaryAsset();
            uint256 amount = proposal.values[index];

            if (
                proposal.proposalType ==
                IDispatcher.ProposalType.TransferERC20
            ) {
                from = proposal.targets[index];
                amount = proposal.values[index];
            }

            // calculate USDT value of transfer tokens
            // Uniswap reverts if tokens are not supported.
            // In order to allow transfer of ERC20 tokens that are not supported on uniswap, we catch the revert
            // And allow the proposal token transfer to pass through
            // This is kinda vulnerable to Uniswap token/pool price/listing manipulation, perhaps this needs to be refactored some time later
            // In order to prevent executing proposals by temporary making token pair/pool not supported by uniswap (which would cause revert and allow proposal to be executed)
            try
                pool.service().uniswapQuoter().quoteExactInput(
                    abi.encodePacked(from, uint24(3000), pool.service().primaryAsset()),
                    amount
                )
            returns (uint256 v) {
                assetValue = v;
            } catch (
                bytes memory data /*lowLevelData*/
            ) {
                emit ErrorCaugth(data);
            }

            if (
                assetValue >= pool.ballotExecDelay(0) &&
                block.number <= delay + proposal.lastVoteBlock
            ) {
                return false;
            }
        }

        // delay for non transfer type proposals
        if (
            proposal.proposalType == IDispatcher.ProposalType.TGE ||
            proposal.proposalType ==
            IDispatcher.ProposalType.GovernanceSettings
        ) {
            if (block.number <= delay + proposal.lastVoteBlock) {
                return false;
            }
        }

        return true;
    }

    /**
     * @dev Cancel proposal
     * @param proposalId Proposal ID
     */
    function _cancelBallot(uint256 proposalId) internal {
        require(
            proposalState(proposalId) == ProposalState.Active ||
                proposalState(proposalId) == ProposalState.Successful,
            ExceptionsLibrary.WRONG_STATE
        );

        _proposals[proposalId].state = ProposalExecutionState.Cancelled;

        emit ProposalCancelled(proposalId);
    }

    function _afterProposalCreated(uint256 proposalId) internal virtual;

    function _getTotalSupply() internal view virtual returns (uint256);

    function _getTotalTGEVestedTokens() internal view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./ITGE.sol";
import "./IToken.sol";

interface IDispatcher {
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
        TransferETH,
        TransferERC20,
        TGE,
        GovernanceSettings
    }

    function addContractRecord(address addr, ContractType contractType, string memory description)
        external
        returns (uint256 index);

    function addProposalRecord(address pool, uint256 proposalId)
        external
        returns (uint256 index);

    function addEventRecord(address pool, EventType eventType, uint256 proposalId, string calldata metaHash)
        external
        returns (uint256 index);

    function typeOf(address addr) external view returns (ContractType);

    // Metadata
    enum Status {
        NotUsed,
        Used
    }

    struct QueueInfo {
        uint256 jurisdiction;
        string EIN;
        string dateOfIncorporation;
        uint256 entityType;
        Status status;
        address pool;
        uint256 fee;
    }

    function initialize() external;

    function service() external view returns (address);

    function lockRecord(uint256 jurisdiction, uint256 entityType) external returns (address, uint256);

    // WhitelistedTokens
    function tokenWhitelist() external view returns (address[] memory);

    function isTokenWhitelisted(address token) external view returns (bool);

    function tokenSwapPath(address) external view returns (bytes memory);

    function tokenSwapReversePath(address) external view returns (bytes memory);

    // ProposalGateway
    enum ProposalType {
        None,
        TransferETH,
        TransferERC20,
        TGE,
        GovernanceSettings
    }

    function validateTGEInfo(
        ITGE.TGEInfo calldata info, 
        IToken.TokenType tokenType, 
        uint256 cap, 
        uint256 totalSupply
    ) external view returns (bool);

    function validateBallotParams(
        uint256 ballotQuorumThreshold,
        uint256 ballotDecisionThreshold,
        uint256 ballotLifespan,
        uint256[10] calldata ballotExecDelay
    ) external pure returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IService.sol";
import "./IToken.sol";
import "./IDispatcher.sol";

interface IPool {
    function initialize(
        uint256 jurisdiction_,
        string memory EIN_,
        string memory dateOfIncorporation,
        uint256 entityType,
        uint256 metadataIndex
    ) external;

    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] calldata ballotExecDelay
    ) external;

    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IDispatcher.ProposalType proposalType,
        string memory metaHash
    ) external returns (uint256 proposalId);

    function proposeTransfer(
        address[] memory targets,
        uint256[] memory values,
        string memory description,
        IDispatcher.ProposalType proposalType,
        string memory metaHash,
        address token_
    ) external returns (uint256 proposalId);

    function setLastProposalIdForAccount(address creator, uint256 proposalId) external;

    function serviceCancelBallot(uint256 proposalId) external;

    function getTVL() external returns (uint256);

    function owner() external view returns (address);

    function service() external view returns (IService);

    function maxProposalId() external view returns (uint256);

    function isDAO() external view returns (bool);

    function trademark() external view returns (string memory);

    function ballotExecDelay(uint256 _index) external view returns (uint256);

    function paused() external view returns (bool);

    function launch(
        address owner_,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay_,
        string memory trademark
    ) external;

    function setToken(address token_, IToken.TokenType tokenType_) external;

    function tokens(IToken.TokenType tokenType_) external view returns (IToken);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import "./ITGE.sol";
import "./IDispatcher.sol";
import "./IToken.sol";

interface IService {
    function initialize(
        IDispatcher dispatcher_,
        address poolBeacon_,
        address tokenBeacon_,
        address tgeBeacon_,
        address proposalGateway_,
        uint256[13] calldata ballotParams,
        ISwapRouter uniswapRouter_,
        IQuoter uniswapQuoter_,
        uint256 protocolTokenFee_
    ) external;

    function createSecondaryTGE(
        ITGE.TGEInfo calldata tgeInfo, 
        string memory metadataURI, 
        IToken.TokenType tokenType, 
        string memory tokenDescription,
        uint256 preferenceTokenCap
    ) external;

    function addProposal(uint256 proposalId) external;

    function addEvent(IDispatcher.EventType eventType, uint256 proposalId, string calldata metaHash)
        external;

    function isManagerWhitelisted(address account) external view returns (bool);

    function isExecutorWhitelisted(address account) external view returns (bool);

    function owner() external view returns (address);

    function uniswapRouter() external view returns (ISwapRouter);

    function uniswapQuoter() external view returns (IQuoter);

    function dispatcher() external view returns (IDispatcher);

    function proposalGateway() external view returns (address);

    function protocolTreasury() external view returns (address);

    function protocolTokenFee() external view returns (uint256);

    function getMinSoftCap() external view returns (uint256);

    function getProtocolTokenFee(uint256 amount)
        external
        view
        returns (uint256);

    function ballotExecDelay(uint256 _index) external view returns (uint256);

    function primaryAsset() external view returns (address);

    function secondaryAsset() external view returns (address);

    function poolBeacon() external view returns (address);

    function tgeBeacon() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IToken.sol";

interface ITGE {
    struct TGEInfo {
        uint256 price;
        uint256 hardcap;
        uint256 softcap;
        uint256 minPurchase;
        uint256 maxPurchase;
        uint256 vestingPercent;
        uint256 vestingDuration;
        uint256 vestingTVL;
        uint256 duration;
        address[] userWhitelist;
        address unitOfAccount;
        uint256 lockupDuration;
        uint256 lockupTVL;
    }

    function initialize(
        IToken token_,
        TGEInfo calldata info
    ) external;

    enum State {
        Active,
        Failed,
        Successful
    }

    function state() external view returns (State);

    function transferUnlocked() external view returns (bool);

    function getTotalVested() external view returns (uint256);

    function purchaseOf(address user) external view returns (uint256);

    function vestedBalanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IService.sol";

interface IToken is IERC20Upgradeable {
    struct TokenInfo {
        string symbol;
        uint256 cap;
    }

    enum TokenType {
        None,
        Governance,
        Preference
    }

    function initialize(
        address pool_, 
        string memory symbol_, 
        uint256 cap_, 
        TokenType tokenType_, 
        address primaryTGE_, 
        string memory description_
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function lock(
        address account,
        uint256 amount,
        uint256 deadline,
        uint256 proposalId
    ) external;

    function cap() external view returns (uint256);

    function minUnlockedBalanceOf(address from) external view returns (uint256);

    function unlockedBalanceOf(address account, uint256 proposalId)
        external
        view
        returns (uint256);

    function pool() external view returns (address);

    function service() external view returns (IService);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function tokenType() external view returns (TokenType);

    function lastTGE() external view returns (address);

    function getTGEList() external view returns (address[] memory);

    function isPrimaryTGESuccessful() external view returns (bool);

    function addTGE(address tge_) external;

    function getTotalTGEVestedTokens() external view returns (uint256);
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
    string public constant NOT_DISPATCHER = "NOT_DISPATCHER";
    string public constant NOT_POOL_OWNER = "NOT_POOL_OWNER";
    string public constant NOT_SERVICE_OWNER = "NOT_SERVICE_OWNER";
    string public constant IS_DAO = "IS_DAO";
    string public constant NOT_DAO = "NOT_DAO";
    string public constant NOT_SHAREHOLDER = "NOT_SHAREHOLDER";
    string public constant NOT_WHITELISTED = "NOT_WHITELISTED";
    string public constant ALREADY_WHITELISTED = "ALREADY_WHITELISTED";
    string public constant ALREADY_NOT_WHITELISTED = "ALREADY_NOT_WHITELISTED";
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
    string public constant BLOCK_DELAY = "BLOCK_DELAY";
    string public constant SERVICE_PAUSED = "SERVICE_PAUSED";
    string public constant INVALID_PROPOSAL_TYPE = "INVALID_PROPOSAL_TYPE";
    string public constant EXECUTION_FAILED = "EXECUTION_FAILED";
    string public constant INVALID_USER = "INVALID_USER";
    string public constant NOT_LAUNCHED = "NOT_LAUNCHED";
    string public constant LAUNCHED = "LAUNCHED";
    string public constant VESTING_TVL_REACHED = "VESTING_TVL_REACHED";
    string public constant PREFERENCE_TOKEN_EXISTS = "PREFERENCE_TOKEN_EXISTS";
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./components/Governor.sol";
import "./interfaces/IService.sol";
import "./interfaces/IPool.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITGE.sol";
import "./interfaces/IDispatcher.sol";
import "./libraries/ExceptionsLibrary.sol";

/// @dev Company Entry Point
contract Pool is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable,
    IPool,
    Governor
{
    /// @dev Service address
    IService public service;

    /// @dev Minimum amount of votes that ballot must receive
    uint256 public ballotQuorumThreshold;

    /// @dev Minimum amount of votes that ballot's choice must receive in order to pass
    uint256 public ballotDecisionThreshold;

    /// @dev Ballot voting duration, blocks
    uint256 public ballotLifespan;

    /// @dev Pool trademark
    string public trademark;

    /// @dev Pool jurisdiction
    uint256 public jurisdiction;

    /// @dev Pool EIN
    string public EIN;

    /// @dev Metadata pool record index
    uint256 public metadataIndex;

    /// @dev Pool entity type
    uint256 public entityType;

    /// @dev Pool date of incorporatio
    string public dateOfIncorporation;

    /**
     * @dev block delay for executeBallot
     * [0] - ballot value in USDT after which delay kicks in
     * [1] - base delay applied to all ballots to mitigate FlashLoan attacks.
     * [2] - delay for TransferETH proposals
     * [3] - delay for TransferERC20 proposals
     * [4] - delay for TGE proposals
     * [5] - delay for GovernanceSettings proposals
     */
    uint256[10] public ballotExecDelay;

    /// @dev last proposal id created by account
    mapping(address => uint256) public lastProposalIdForAccount;

    /// @dev Is pool launched or not
    bool public poolLaunched;

    /// @dev Pool tokens addresses
    mapping(IToken.TokenType => IToken) public tokens;

    // INITIALIZER AND CONFIGURATOR

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Create TransferETH proposal
     * @param jurisdiction_ Jurisdiction
     * @param EIN_ EIN
     * @param dateOfIncorporation_ Date of incorporation
     * @param entityType_ Entity type
     * @param metadataIndex_ Metadata index
     */
    function initialize(
        uint256 jurisdiction_,
        string memory EIN_,
        string memory dateOfIncorporation_,
        uint256 entityType_,
        uint256 metadataIndex_
    ) external initializer {
        __Ownable_init();

        service = IService(IDispatcher(msg.sender).service());
        _transferOwnership(address(service));
        jurisdiction = jurisdiction_;
        EIN = EIN_;
        dateOfIncorporation = dateOfIncorporation_;
        entityType = entityType_;
        metadataIndex = metadataIndex_;
    }

    /**
     * @dev Create TransferETH proposal
     * @param owner_ Pool owner
     * @param ballotQuorumThreshold_ Ballot quorum threshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     * @param trademark_ Trademark
     */
    function launch(
        address owner_,
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] memory ballotExecDelay_,
        string memory trademark_
    ) external onlyService unlaunched {
        poolLaunched = true;
        _transferOwnership(owner_);

        service.dispatcher().validateBallotParams(
            ballotQuorumThreshold_,
            ballotDecisionThreshold_,
            ballotLifespan_, 
            ballotExecDelay_
        );

        trademark = trademark_;
        ballotQuorumThreshold = ballotQuorumThreshold_;
        ballotDecisionThreshold = ballotDecisionThreshold_;
        ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
    }

    /**
     * @dev Set pool preference token
     * @param token_ Token address
     * @param tokenType_ Token type
     */
    function setToken(address token_, IToken.TokenType tokenType_) external onlyService launched {
        require(token_ != address(0), ExceptionsLibrary.ADDRESS_ZERO);

        tokens[tokenType_] = IToken(token_);
    }

    /**
     * @dev Set Service governance settings
     * @param ballotQuorumThreshold_ Ballot quorum threshold
     * @param ballotDecisionThreshold_ Ballot decision threshold
     * @param ballotLifespan_ Ballot lifespan
     * @param ballotExecDelay_ Ballot execution delay parameters
     */
    function setGovernanceSettings(
        uint256 ballotQuorumThreshold_,
        uint256 ballotDecisionThreshold_,
        uint256 ballotLifespan_,
        uint256[10] calldata ballotExecDelay_
    ) external onlyPool whenNotPaused launched {
        service.dispatcher().validateBallotParams(
            ballotQuorumThreshold_,
            ballotDecisionThreshold_,
            ballotLifespan_, 
            ballotExecDelay_
        );

        ballotQuorumThreshold = ballotQuorumThreshold_;
        ballotDecisionThreshold = ballotDecisionThreshold_;
        ballotLifespan = ballotLifespan_;
        ballotExecDelay = ballotExecDelay_;
    }

    // PUBLIC FUNCTIONS

    /**
     * @dev Cast ballot vote
     * @param proposalId Pool proposal ID
     * @param votes Amount of tokens
     * @param support Against or for
     */
    function castVote(
        uint256 proposalId,
        uint256 votes,
        bool support
    ) external nonReentrant whenNotPaused launched {
        if (votes == type(uint256).max) {
            votes = tokens[IToken.TokenType.Governance].unlockedBalanceOf(msg.sender, proposalId);
        } else {
            require(
                votes <= tokens[IToken.TokenType.Governance].unlockedBalanceOf(msg.sender, proposalId),
                ExceptionsLibrary.LOW_UNLOCKED_BALANCE
            );
        }
        require(votes > 0, ExceptionsLibrary.VALUE_ZERO);

        _castVote(proposalId, votes, support);
        tokens[IToken.TokenType.Governance].lock(
            msg.sender,
            votes,
            getProposal(proposalId).endBlock,
            proposalId
        );
    }

    /**
     * @dev Create pool proposal
     * @param target Proposal transaction recipient
     * @param value Amount of ETH token
     * @param cd Calldata to pass on in .call() to transaction recipient
     * @param description Proposal description
     * @param proposalType Type
     * @param metaHash Hash value of proposal metadata
     * @return proposalId Created proposal ID
     */
    function proposeSingleAction(
        address target,
        uint256 value,
        bytes memory cd,
        string memory description,
        IDispatcher.ProposalType proposalType,
        string memory metaHash
    )
        external
        onlyProposalGateway
        whenNotPaused
        launched
        returns (uint256 proposalId)
    {
        address[] memory targets = new address[](1);
        targets[0] = target;
        uint256[] memory values = new uint256[](1);
        values[0] = value;

        proposalId = _propose(
            ballotLifespan,
            ballotQuorumThreshold,
            ballotDecisionThreshold,
            targets,
            values,
            cd,
            description,
            _getTotalSupply() -
                _getTotalTGEVestedTokens() -
                tokens[IToken.TokenType.Governance].balanceOf(service.protocolTreasury()),
            service.ballotExecDelay(1), // --> ballotExecDelay(1)
            proposalType,
            metaHash,
            address(0)
        );
    }

    /**
     * @dev Create pool proposal
     * @param targets Proposal transaction recipients
     * @param values Amounts of ETH token
     * @param description Proposal description
     * @param proposalType Type
     * @param metaHash Hash value of proposal metadata
     * @param token_ token for payment proposal
     * @return proposalId Created proposal ID
     */
    function proposeTransfer(
        address[] memory targets,
        uint256[] memory values,
        string memory description,
        IDispatcher.ProposalType proposalType,
        string memory metaHash,
        address token_
    )
        external
        onlyProposalGateway
        whenNotPaused
        launched
        returns (uint256 proposalId)
    {
        proposalId = _propose(
            ballotLifespan,
            ballotQuorumThreshold,
            ballotDecisionThreshold,
            targets,
            values,
            "",
            description,
            _getTotalSupply() -
                _getTotalTGEVestedTokens() -
                tokens[IToken.TokenType.Governance].balanceOf(service.protocolTreasury()),
            service.ballotExecDelay(1), // --> ballotExecDelay(1)
            proposalType,
            metaHash,
            token_
        );
    }

    function setLastProposalIdForAccount(address creator, uint256 proposalId) external onlyProposalGateway launched {
        lastProposalIdForAccount[creator] = proposalId;
    }

    /**
     * @dev Calculate pool TVL
     * @return Pool TVL
     */
    function getTVL() public returns (uint256) {
        IQuoter quoter = service.uniswapQuoter();
        IDispatcher dispatcher = service.dispatcher();
        address[] memory tokenWhitelist = dispatcher.tokenWhitelist();
        uint256 tvl = 0;

        for (uint256 i = 0; i < tokenWhitelist.length; i++) {
            if (tokenWhitelist[i] == address(0)) {
                tvl += address(this).balance;
            } else {
                uint256 balance = IERC20Upgradeable(tokenWhitelist[i])
                    .balanceOf(address(this));
                if (balance > 0) {
                    tvl += quoter.quoteExactInput(
                        dispatcher.tokenSwapPath(tokenWhitelist[i]),
                        balance
                    );
                }
            }
        }
        return tvl;
    }

    /**
     * @dev Execute proposal
     * @param proposalId Proposal ID
     */
    function executeBallot(uint256 proposalId) external whenNotPaused launched {
        _executeBallot(proposalId, service);
    }

    /**
     * @dev Cancel proposal, callable only by Service
     * @param proposalId Proposal ID
     */
    function serviceCancelBallot(uint256 proposalId) external onlyService launched {
        _cancelBallot(proposalId);
    }

    /**
     * @dev Pause pool and corresponding TGEs and GovernanceToken
     */
    function pause() public onlyServiceOwner {
        _pause();
    }

    /**
     * @dev Pause pool and corresponding TGEs and GovernanceToken
     */
    function unpause() public onlyServiceOwner {
        _unpause();
    }

    // RECEIVE

    receive() external payable {
        // Supposed to be empty
    }

    // PUBLIC VIEW FUNCTIONS

    /**
     * @dev Return maximum proposal ID
     * @return Maximum proposal ID
     */
    function maxProposalId() external view returns (uint256) {
        return lastProposalId;
    }

    /**
     * @dev Return if pool had a successful governance TGE
     * @return Is any governance TGE successful
     */
    function isDAO() external view returns (bool) {
        return tokens[IToken.TokenType.Governance].isPrimaryTGESuccessful();
    }

    /**
     * @dev Return pool owner
     * @return Owner address
     */
    function owner()
        public
        view
        override(IPool, OwnableUpgradeable)
        returns (address)
    {
        return super.owner();
    }

    function getBallotExecDelay() external view returns(uint256[10] memory) {
        return ballotExecDelay;
    }

    // INTERNAL FUNCTIONS

    function _afterProposalCreated(uint256 proposalId) internal override {
        service.addProposal(proposalId);
    }

    /**
     * @dev Return token total supply
     * @return Total pool token supply
     */
    function _getTotalSupply() internal view override returns (uint256) {
        return tokens[IToken.TokenType.Governance].totalSupply();
    }

    /**
     * @dev Return amount of tokens currently vested in TGE vesting contract(s)
     * @return Total pool vesting tokens
     */
    function _getTotalTGEVestedTokens()
        internal
        view
        override
        returns (uint256)
    {
        return tokens[IToken.TokenType.Governance].getTotalTGEVestedTokens();
    }

    /**
     * @dev Return pool paused status
     * @return Is pool paused
     */
    function paused()
        public
        view
        override(IPool, PausableUpgradeable)
        returns (bool)
    {
        // Pausable
        return super.paused();
    }

    // MODIFIER

    modifier onlyService() {
        require(msg.sender == address(service), ExceptionsLibrary.NOT_SERVICE);
        _;
    }

    modifier launched() {
        require(poolLaunched, ExceptionsLibrary.NOT_LAUNCHED);
        _;
    }

    modifier unlaunched() {
        require(!poolLaunched, ExceptionsLibrary.LAUNCHED);
        _;
    }

    modifier onlyServiceOwner() {
        require(
            msg.sender == service.owner(),
            ExceptionsLibrary.NOT_SERVICE_OWNER
        );
        _;
    }

    modifier onlyProposalGateway() {
        require(
            msg.sender == service.proposalGateway(),
            ExceptionsLibrary.NOT_DISPATCHER
        );
        _;
    }

    modifier onlyPool() {
        require(msg.sender == address(this), ExceptionsLibrary.NOT_POOL);
        _;
    }

    // function test83212() external pure returns (uint256) {
    //     return 3;
    // }
}