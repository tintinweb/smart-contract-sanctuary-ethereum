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

pragma solidity =0.8.14;

/**
 * @title Master Whitelist Interface
 * @notice Interface for contract that manages the whitelists for: Lawyers, Market Makers, Users, Vaults, and Assets
 */
interface IMasterWhitelist {
    /**
     * @notice Checks if a Market Maker is in the Whitelist
     * @param _mm is the Market Maker address
     */
    function isMMWhitelisted(address _mm) external view returns (bool);

    /**
     * @notice Checks if a Vault is in the Whitelist
     * @param _vault is the Vault address
     */
    function isVaultWhitelisted(address _vault) external view returns (bool);

    /**
     * @notice Checks if a User is in the Whitelist
     * @param _user is the User address
     */
    function isUserWhitelisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a User is in the Blacklist
     * @param _user is the User address
     */
    function isUserBlacklisted(address _user) external view returns (bool);

    /**
     * @notice Checks if a Swap Manager is in the Whitelist
     * @param _sm is the Swap Manager address
     */
    function isSwapManagerWhitelisted(address _sm) external view returns (bool);

    /**
     * @notice Checks if an Asset is in the Whitelist
     * @param _asset is the Asset address
     */
    function isAssetWhitelisted(address _asset) external view returns (bool);

    /**
     * @notice Returns id of a market maker address
     * @param _mm is the market maker address
     */
    function getIdMM(address _mm) external view returns (bytes32);

    function isLawyer(address _lawyer) external view returns (bool);

    /**
     * @notice Checks if a user is whitelisted for the Gnosis auction, returns "0x19a05a7e" if it is
     * @param _user is the User address
     * @param _auctionId is not needed for now
     * @param _callData is not needed for now
     */
    function isAllowed(
        address _user,
        uint256 _auctionId,
        bytes calldata _callData
    ) external view returns (bytes4);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

interface IValidatorShare {
    function buyVoucher(uint256 _amount, uint256 _minSharesToMint) external returns (uint256 amountToDeposit);
    
    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn) external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;
    // https://goerli.etherscan.io/tx/0xa92befb3c1bca72e9492eb846c58168fc6511ad580a2703e8abf94e0c3682e26
    // https://goerli.etherscan.io/tx/0x452d26ed9d0fa2e634d26302fab71d0f00401690c79ca8c0c998fdefd2fdb9e8

    function getLiquidRewards(address user) external view returns (uint256);
    
    function restake() external returns (uint256 amountRestaked, uint256 liquidReward);

    function unbondNonces(address) external view returns (uint256); // automatically generated getter of a public mapping

    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external;
    
    function transferFrom(address, address, uint256) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;


import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import { IValidatorShare } from "../interfaces/IValidatorShare.sol";
import { IMasterWhitelist } from "../interfaces/IMasterWhitelist.sol";

import { StakerStorage } from "./StakerStorage.sol";
import { SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

uint256 constant phiPrecision = 10_000;

contract Staker is StakerStorage, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _stakingTokenAddress,
        address _stakeManagerContractAddress,
        address _validatorShareContractAddress,
        address _whitelistAddress,
        address _treasuryAddress,
        uint256 _phi,
        uint256 _cap
    ) external initializer {
        // Put BaseContract.initialize() here if parent contracts are present
        // (using onlyInitializing modifier in parent initialize() fn)
        
        // OZ setup

        __ReentrancyGuard_init();
        __Ownable_init(); // set owner to msg.sender

        // set initial values for global variables

        stakingTokenAddress = _stakingTokenAddress;
        stakeManagerContractAddress = _stakeManagerContractAddress;
        validatorShareContractAddress = _validatorShareContractAddress;
        
        whitelistAddress = _whitelistAddress;

        treasuryAddress = _treasuryAddress;

        phi = _phi;
        cap = _cap;

        emit StakerInitialized(_stakingTokenAddress, _stakeManagerContractAddress, _validatorShareContractAddress, _treasuryAddress, _phi, _cap);
    }

    // --- Events ---

    event StakerInitialized(address _stakingTokenAddress, address _stakeManagerContractAddress, address _validatorShareContractAddress, address _treasuryAddress, uint256 _phi, uint256 _cap);

    // user tracking

    event Deposited(address _user, uint256 _amount, uint256 _shares);
    
    event WithdrawalRequested(address _user, uint256 _amount, uint256 _shares);

    event WithdrawalClaimed(address _user, uint256 _amount);

    // global tracking

    event RewardsCompounded(uint256 _amount);

    event WithdrawalUnbondingInitiated(uint256 _unbondNonce, uint256 _amount);

    event WithdrawalUnbondingClaimed(uint256 _unbondNonce);

    // --- Setters ---

    function setWhitelist(address _whitelistAddress) external onlyOwner {
        whitelistAddress = _whitelistAddress;
    }

    function setTreasury(address _treasuryAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
    }

    function setCap(uint256 _cap) external onlyOwner {
        cap = _cap;
    }

    function setPhi(uint256 _phi) external onlyOwner {
        phi = _phi;
    }

    // --- Helpers ---

    function totalStaked() public view returns (uint256) {
        return IValidatorShare(validatorShareContractAddress).balanceOf(address(this));
    }

    function totalCapital() public view returns (uint256) {
        return totalStaked() - totalPendingWithdrawals;
    }

    function totalRewards() public view returns (uint256) {
        return IValidatorShare(validatorShareContractAddress).getLiquidRewards(address(this));
    }
    
    function sharesFromAmount(uint256 _amount) public view returns (uint256 shares) {
        // this may introduce rounding errors
        // might have to replace the sharePrice function with something more integer-y
       
        return (_amount * 10**18) / sharePrice();
    }

    function amountFromShares(uint256 _shares) public view returns (uint256 amount) {
        return (_shares * sharePrice()) / 10**18;
    }

    function sharePrice() public view returns (uint256 price) {
        // precision used to avoid rounding errors (default 10**18)

        if (totalShares == 0) return 10**18;

        price = ((totalCapital() * phiPrecision + (phiPrecision - phi) * totalRewards()) * 10**18) / (totalShares * phiPrecision);

        return price; // divide `price` by 10**18 to get actual floating point share price
    }

    function getDust() external view returns (uint256 dust) {
        // dust is phis that havent yet been turned into shares
        // it's the failure of total number of shares * share price to add up to total amount in stake + reward
        // return totalAmount + totalRewards() - amountFromShares(totalShares);
        return (totalRewards() * phi) / phiPrecision;
    }

    modifier onlyWhitelist {
        require(
            IMasterWhitelist(whitelistAddress).isUserWhitelisted(msg.sender),
            "Whitelist: user not whitelisted"
        );
        _;
    }

    // --- Users Functions ---

    function deposit(uint256 _amount) external onlyWhitelist nonReentrant {
        require(
            totalStaked() + _amount <= cap,
            "Staker: deposit surpasses vault cap"
        );
        require(
            _amount > 0,
            "Staker: withdrawal amount must be greater than zero"
        );

        // calculate share increase
        uint256 shareIncrease = sharesFromAmount(_amount);

        // adjust global variables
        // totalAmount += _amount;
        userShares[msg.sender] += shareIncrease;
        totalShares += shareIncrease;

        // transfer staking token from user to Staker
        // IERC20(stakingTokenAddress).transferFrom(msg.sender, address(this), _amount);
        IERC20Upgradeable(stakingTokenAddress).safeTransferFrom(msg.sender, address(this), _amount);

        // approve funds to Stake Manager
        // IERC20(stakingTokenAddress).approve(stakeManagerContractAddress, _amount);
        IERC20Upgradeable(stakingTokenAddress).safeIncreaseAllowance(stakeManagerContractAddress, _amount);

        // interact with Validator Share contract to stake
        _stake(_amount);

        emit Deposited(msg.sender, _amount, shareIncrease);
    }

    // user shares goes down
    // user pending withdrawal amount goes up
    // total shares goes down
    // total pending withdrawal amount goes up
    function withdrawRequest(uint256 _amount) external onlyWhitelist nonReentrant {
        // funds stop accruing straight away, so decrease shares straight away and separate
        // unbonding funds into a different pool (in the form of a withdrawal request)
        require(
            amountFromShares(userShares[msg.sender]) >= _amount,
            "Staker: withdrawal amount requested too large"
        );
        require(
            _amount > 0,
            "Staker: withdrawal amount must be greater than zero"
        );

        // calculate share decrease
        uint256 shareDecrease = sharesFromAmount(_amount);

        // adjust global variables
        // totalAmount -= _amount;
        totalPendingWithdrawals += _amount;
        userShares[msg.sender] -= shareDecrease;
        totalShares -= shareDecrease;

        userPendingWithdrawals[withdrawIDCounter][msg.sender] += _amount;

        emit WithdrawalRequested(msg.sender, _amount, shareDecrease);
    }

    function claimWithdrawal(uint256 _withdrawID) external onlyWhitelist nonReentrant {
        require(
            withdrawIDClaimable[_withdrawID],
            "Staker: unbonding not complete or claim has not been called on withdrawal"
        );

        uint256 amount = userPendingWithdrawals[_withdrawID][msg.sender];
        userPendingWithdrawals[_withdrawID][msg.sender] = 0;

        // IERC20(stakingTokenAddress).transfer(msg.sender, amount);
        IERC20Upgradeable(stakingTokenAddress).safeTransfer(msg.sender, amount);

        emit WithdrawalClaimed(msg.sender, amount);
    }

    // Withdrawals:
    // get epoch from stakeManager.epoch()
    // only once 80 epochs have passed can you

    // Incomplete withdrawal period:
    // unbond.withdrawEpoch + stakeManager.withdrawalDelay() <= stakeManager.epoch()
    // unbond.shares > 0

    // --- Interaction with Polygon staking contract (Staker) ---
    // buyVoucher example: https://goerli.etherscan.io/address/0x0b764b080a67f9019677ae2c9279f52485fd4525#writeProxyContract

    function _stake(uint256 _amount) private {
        IValidatorShare(validatorShareContractAddress).buyVoucher(_amount, 2423);
        // (uint256 amountToDeposit)

        // currently assuming the entire amount was used to stake -- apparently may not always be the case?
        // see https://goerli.etherscan.io/address/0x41a9c376ec9089e91d453d3ac6b0ff4f4fd7ccec#code _buyVoucher() fn
    }

    function _unbond(uint256 _amount) private returns (uint256 unbondNonce) {
        // Takes 3 days, rewards stop accruing immediately
        IValidatorShare(validatorShareContractAddress).sellVoucher_new(_amount, _amount);

        return IValidatorShare(validatorShareContractAddress).unbondNonces(address(this));
    }

    function _claimStake( uint256 _unbondNonce) private {
        // transfer all unstaked MATIC to vault in original unbonding call
        IValidatorShare(validatorShareContractAddress).unstakeClaimTokens_new(_unbondNonce);
    }

    function _restake() private {
        // no longer returning amoutnRestaked because order of compoundRewards() fn was changed_
        IValidatorShare(validatorShareContractAddress).restake();
        // ^^^ this actually returns (uint256 amountRestaked, uint256 liquidReward)
        // is it possible not everything is restaked? look into this, might have to change compoundRewards() fn
    }

    // --- Compounding Rewards ---

    function compoundRewards() external nonReentrant {
        // global fn: This function can be called by anyone.  Caller pays the gas.
        // We will have a cron-job that checks if rewards are above a threshold and call restake ourselves if so.
        _restakeRewards();
        if (totalPendingWithdrawals > 0) _processPendingWithdrawals();
    }

    // this will now be two things - restake then initiate unbonding of all pending withdrawals
    // total pending withdrawal amount goes down
    function _restakeRewards() private {
        uint256 amountRestaked = totalRewards();

        // to keep share price constant when rewards are staked, new shares need to be minted
        uint256 shareIncrease = ((totalCapital() + amountRestaked) * 10**18) / sharePrice() - totalShares;
        // calculating shareIncrease before calling _restake() because restaking sets unstaked rewards
        // to zero, messing up the share price function

        // restake as many rewards as possible
        // uint256 amountRestaked = _restake();
        _restake();
        // is this open to reentrancy? might be good to add reentrancy guard

        // these are given to the treasury to effectively take a phi
        // totalShares also increases, zeroing the dust balance by definition
        userShares[treasuryAddress] += shareIncrease;
        totalShares += shareIncrease; // share value decrease

        // rewards are added to the totalAmount
        // totalAmount += amountRestaked; // share value increase
        
        // totalRewards() should now return previous totalRewards() - (liquidReward - amountRestaked)

        emit RewardsCompounded(amountRestaked);
    }

    function _processPendingWithdrawals() private {
        // interact with staking contract to initiate unbonding
        uint256 unbondNonce = _unbond(totalPendingWithdrawals);
        uint256 amountUnbonded = totalPendingWithdrawals;
        totalPendingWithdrawals = 0;

        // adds current pending withdrawals to past withdrawals mapping
        unbondNonceToWithdrawID[unbondNonce] = withdrawIDCounter;
        withdrawIDCounter++;

        emit WithdrawalUnbondingInitiated(unbondNonce, amountUnbonded);
    }

    function claimUnbond(uint256 _unbondNonce) external nonReentrant {
        // global fn: claim stake for given unbond nonce, will revert if unbonding not complete
        _claimStake(_unbondNonce);

        // make that withdraw id claimable to users
        withdrawIDClaimable[unbondNonceToWithdrawID[_unbondNonce]] = true;

        emit WithdrawalUnbondingClaimed(_unbondNonce);
    }
 
    // TODO: add a minimum restake amount to the public restaking function, to avoid attackers from spamming unbonds and
    // forcing us to pay for the unclaim transaction gas fee

    // TODO: have an admin restake function for any amount so that we can withdraw the treasury amounts
    
    // --- Temp debug functions ---

    function artificialDepositNotice(uint256 _amount) external {
        require(
            totalShares == 0,
            "Staker: (DEBUG) total shares must equal zero to artificial deposit"
        );
        
        // adjust global variables
        userShares[msg.sender] += _amount;
        totalShares += _amount;

        emit Deposited(msg.sender, _amount, _amount);
    }

    function rescueFunds() external {
        payable(msg.sender).transfer(address(this).balance);
        // IERC20(stakingTokenAddress).transfer(msg.sender, IERC20(stakingTokenAddress).balanceOf(address(this)));
        IERC20Upgradeable(stakingTokenAddress).safeTransfer(msg.sender, IERC20Upgradeable(stakingTokenAddress).balanceOf(address(this)));
    }

    function transferStake(address _receiver) external {
        uint256 amount = IValidatorShare(validatorShareContractAddress).balanceOf(address(this));
    
        IValidatorShare(validatorShareContractAddress).transfer(_receiver, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.8.14;

abstract contract StakerStorage {
    // Staker constants

    address public stakingTokenAddress;
    address public stakeManagerContractAddress;
    address public validatorShareContractAddress;

    address public whitelistAddress;
    
    address public treasuryAddress;
    
    // Shares, withdrawals, & amounts

    uint256 public totalShares;
    uint256 public totalPendingWithdrawals;
    uint256 public phi; // basis points
    uint256 public cap;
    uint256 public withdrawIDCounter;

    mapping(address => uint256) public userShares;
    mapping(uint256 => mapping(address => uint256)) public userPendingWithdrawals; // maps withdraw ids to users to amounts
    mapping(uint256 => bool) public withdrawIDClaimable; // tracks what nonces the global claim fn has been called on
    mapping(uint256 => uint256) public unbondNonceToWithdrawID;

    // Gap for upgradeability
    uint256[50] private __gap;
}