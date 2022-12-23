// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IAdmin is IERC165Upgradeable {
    function isPermittedPaymentToken(address _paymentToken) external view returns (bool);

    function isAdmin(address _account) external view returns (bool);

    function owner() external view returns (address);

    function registerTreasury() external;

    function treasury() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/introspection/IERC165Upgradeable.sol";
import "./IProject.sol";

interface IClaimPool is IERC165Upgradeable {
    function initialize(address _owner, address _project, address _paymentToken, address _projectOwner) external;

    function updateBudget(address _collectionAddress, uint256 _budget) external;

    function remove(address _collectionAddress) external;

    function withdrawCollection(address _collectionAddress, address _to, uint256 _amount) external;

    function withdraw() external;

    function getReward(address _collectionAddress) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "./IProject.sol";

interface IClaimPoolFactory {
    function create(address _project, address _paymentToken, address _projectOwner) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IHLPClaimPool {
    function project() external view returns (address);

    function registerProject() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

interface IProject {
    function taskManager() external view returns (address);

    function rewardAddress() external view returns (address);

    function getProjectById(uint256 _projectId) external view returns (ProjectInfo memory);

    function isCollectionActive(address _collection) external view returns (bool);

    function getPaymentTokenOf(address collection) external view returns (address);

    function getClaimPoolOf(address collection) external view returns (address);

    function splitBudget(uint256 _projectId, uint256 _amount) external;

    function registerTaskManager() external;

    function setTaskManager(address _taskManager) external;

    function getProjectOwnerOf(address collection) external view returns (address);
}

struct ProjectInfo {
    uint256 projectId;
    uint256 budget;
    address paymentToken;
    address projectOwner;
    address claimPool;
    bool status;
}

struct CollectionInfo {
    address collectionAddress;
    uint256 rewardPercent;
    uint256[] rewardRarityPercents;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ITaskManager {
    function isValidTaskOf(address collection) external view returns (bool);
}

enum StatusTask {
    ACTIVE,
    DONE,
    CANCEL
}

struct TaskInfo {
    address collection;
    uint256 budget;
    uint256 startTime;
    uint256 endTime;
    StatusTask status;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library TransferHelper {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     *  @notice Transfer token
     */
    function _transferToken(address _paymentToken, uint256 _amount, address _from, address _to) internal {
        if (_to == address(this)) {
            if (_paymentToken == address(0)) {
                require(msg.value == _amount, "Invalid amount");
            } else {
                IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, _to, _amount);
            }
        } else {
            if (_paymentToken == address(0)) {
                _transferNativeToken(_to, _amount);
            } else {
                if (_from == address(this)) {
                    IERC20Upgradeable(_paymentToken).safeTransfer(_to, _amount);
                } else {
                    IERC20Upgradeable(_paymentToken).safeTransferFrom(msg.sender, _to, _amount);
                }
            }
        }
    }

    /**
     *  @notice Transfer native token
     */
    function _transferNativeToken(address _to, uint256 _amount) internal {
        // solhint-disable-next-line indent
        (bool success, ) = _to.call{ value: _amount }("");
        require(success, "Fail transfer native");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IProject.sol";
import "./interfaces/IClaimPool.sol";
import "./interfaces/IClaimPoolFactory.sol";
import "./interfaces/IHLPClaimPool.sol";
import "./interfaces/ITaskManager.sol";
import "./lib/TransferHelper.sol";
import "./Validatable.sol";

/**
 *  @title  Dev Project
 *
 *  @author IHeart Team
 *
 *  @notice This smart contract Project manager.
 */

contract Project is IProject, Validatable, ReentrancyGuardUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    uint256 public constant DENOMINATOR = 1e4;

    /**
     *  @notice _projectCounter uint256 (counter). This is the counter for store
     *          current project ID value in storage.
     */
    CountersUpgradeable.Counter private _projectCounter;

    /**
     *  @notice claimPoolFactory is address of ClaimPoolFactory contract
     */
    IClaimPoolFactory public claimPoolFactory;

    /**
     *  @notice hlpClaimPool is address of HLPClaimPool contract
     */
    IHLPClaimPool public hlpClaimPool;

    /**
     *  @notice rewardAddress is address of Reward contract
     */
    address public rewardAddress;

    /**
     *  @notice taskManager is address of TaskManager contract
     */
    address public taskManager;

    /**
     *  @notice maxCollectionInProject is max collection of project
     */
    uint256 public maxCollectionInProject;

    /**
     *  @notice mapping from project ID to ProjectInfo
     */
    mapping(uint256 => ProjectInfo) private projects;

    /**
     *  @notice mapping from project ID to list collection address
     */
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet) private collectionAddress;

    /**
     *  @notice mapping from collection address to project id
     */
    mapping(address => uint256) public collectionToProjects;

    /**
     *  @notice mapping from collection address to CollectionInfo
     */
    mapping(address => mapping(uint256 => CollectionInfo)) public collectionInfos;

    event RegisterTaskManager(address indexed taskManager);
    event SetClaimPoolFactory(IClaimPoolFactory indexed oldValue, IClaimPoolFactory indexed newValue);
    event SetHLPClaimPool(IHLPClaimPool indexed oldValue, IHLPClaimPool indexed newValue);
    event SetTaskManager(address indexed oldValue, address indexed newValue);
    event SetRewardAddress(address indexed oldValue, address indexed newValue);
    event SetMaxCollectionInProject(uint256 oldValue, uint256 newValue);
    event CreatedProject(uint256 indexed projectId, string indexed projectIdOffChain);
    event UpdatedProject(uint256 indexed projectId, address projectOwner);
    event RemovedProject(uint256 indexed projectId);
    event Deposited(uint256 indexed projectId, uint256 amount);
    event DepositedToCollection(uint256 indexed projectId, address collectionAddress, uint256 amount);
    event SplittedBudget(uint256 indexed projectId, uint256 amount);
    event AddedCollection(uint256 indexed projectId, address collectionAddress);
    event RemovedCollection(uint256 indexed projectId, address collectionAddress);
    event UpdatedPercent(uint256 indexed projectId, uint256[] percents);
    event UpdatedRewardRarityPercent(
        uint256 indexed projectId,
        address indexed collectionAddress,
        uint256[] rewardRarityPercents
    );
    event WithdrawnCollection(uint256 indexed projectId, address indexed collection, uint256 amount);

    /**
     * @notice Initialize new logic contract.
     * @dev    Replace for contructor function
     * @param _admin Address of admin contract
     * @param _claimPoolFactory Address of Claim Pool Factory contract
     * @param _hlpClaimPool Address of HLP Claim Pool contract
     * @param _reward Address of reward contract
     */
    function initialize(
        IAdmin _admin,
        address _claimPoolFactory,
        address _hlpClaimPool,
        address _reward
    ) public initializer {
        __Validatable_init(_admin);
        __ReentrancyGuard_init();
        claimPoolFactory = IClaimPoolFactory(_claimPoolFactory);
        hlpClaimPool = IHLPClaimPool(_hlpClaimPool);
        rewardAddress = _reward;
        maxCollectionInProject = 20;

        if (hlpClaimPool.project() == address(0)) {
            hlpClaimPool.registerProject();
        }
    }

    /**
     * Throw an exception if project id is not valid
     */
    modifier validProjectId(uint256 projectId) {
        require(projectId > 0 && projectId <= _projectCounter.current(), "Invalid projectId");
        _;
    }

    /**
     * Throw an exception if caller is not project owner
     */
    modifier onlyProjectOwner(uint256 _projectId) {
        require(projects[_projectId].projectOwner == _msgSender(), "Caller is not project owner");
        _;
    }

    /**
     * @notice Register Project to allow it order methods of this contract
     *
     * @dev    Register can only be called once
     *
     * emit {RegisterTaskManager} events
     */
    function registerTaskManager() external {
        require(taskManager == address(0), "Already register");
        taskManager = _msgSender();
        emit RegisterTaskManager(taskManager);
    }

    // Manager function
    /**
     * @notice Set address claim pool factory
     *
     * @dev    Only owner or admin can call this function.
     *
     * @param  _claimPoolFactory   Address of claim pool factory.
     *
     * emit {SetClaimPoolFactory} events
     */
    function setClaimPoolFactory(address _claimPoolFactory) external onlyAdmin notZeroAddress(_claimPoolFactory) {
        require(_claimPoolFactory != address(claimPoolFactory), "ClaimPoolFactory already exists");

        IClaimPoolFactory _oldValue = claimPoolFactory;
        claimPoolFactory = IClaimPoolFactory(_claimPoolFactory);
        emit SetClaimPoolFactory(_oldValue, claimPoolFactory);
    }

    /**
     * @notice Set address HLP claim pool
     *
     * @dev    Only owner or admin can call this function.
     *
     * @param  _hlpClaimPool   Address of HLP claim pool.
     *
     * emit {SetHLPClaimPool} events
     */
    function setHLPClaimPool(address _hlpClaimPool) external onlyAdmin notZeroAddress(_hlpClaimPool) {
        require(_hlpClaimPool != address(hlpClaimPool), "HLPClaimPool already exists");

        IHLPClaimPool _oldValue = hlpClaimPool;
        hlpClaimPool = IHLPClaimPool(_hlpClaimPool);
        emit SetHLPClaimPool(_oldValue, hlpClaimPool);
    }

    /**
     * @notice Set address task manager
     *
     * @dev    Only owner or admin can call this function.
     *
     * @param  _taskManager   Address of TaskManager contract.
     *
     * emit {setTaskManager} events
     */
    function setTaskManager(address _taskManager) external onlyAdmin notZeroAddress(_taskManager) {
        require(_taskManager != address(taskManager), "TaskManager already exists");

        address _oldValue = taskManager;
        taskManager = _taskManager;
        emit SetTaskManager(_oldValue, taskManager);
    }

    /**
     *  @notice Set address reward
     *
     *  @dev    Only owner or admin can call this function.
     *
     *  @param  _rewardAddress   Address of Reward contract.
     *
     *  emit {SetRewardAddress} events
     */
    function setRewardAddress(address _rewardAddress) external onlyAdmin notZeroAddress(_rewardAddress) {
        require(_rewardAddress != rewardAddress, "RewardAddress already exists");

        address _oldValue = rewardAddress;
        rewardAddress = _rewardAddress;
        emit SetRewardAddress(_oldValue, rewardAddress);
    }

    /**
     *  @notice Set max collection in a project
     *
     *  @dev    Only owner or admin can call this function.
     *
     *  @param  _maxCollectionInProject   max of collection in a project.
     *
     *  emit {SetMaxCollectionInProject} events
     */
    function setMaxCollectionInProject(
        uint256 _maxCollectionInProject
    ) external onlyAdmin notZero(_maxCollectionInProject) {
        require(_maxCollectionInProject != maxCollectionInProject, "MaxCollectionInProject already exists");

        uint256 _oldValue = maxCollectionInProject;
        maxCollectionInProject = _maxCollectionInProject;
        emit SetMaxCollectionInProject(_oldValue, maxCollectionInProject);
    }

    // Main function
    /**
     * @notice Create project.
     * @dev    Only admin can call this function.
     * @param _idOffChain id of chain
     * @param _paymentToken Address of payment token (address(0) for native token)
     * @param _collections List of nft
     *
     * emit {CreatedProject} events
     */
    function createProject(
        string memory _idOffChain,
        address _paymentToken,
        uint256 _budget,
        CollectionInfo[] memory _collections
    ) external payable nonReentrant {
        require(_collections.length > 0 && _collections.length <= maxCollectionInProject, "Invalid length");

        _projectCounter.increment();
        ProjectInfo storage projectInfo = projects[_projectCounter.current()];
        projectInfo.projectId = _projectCounter.current();
        projectInfo.paymentToken = _paymentToken;
        projectInfo.projectOwner = _msgSender();
        projectInfo.budget = _budget;
        projectInfo.status = true;

        uint256 _total = 0;
        for (uint256 i = 0; i < _collections.length; i++) {
            require(
                _collections[i].collectionAddress != address(0) &&
                    collectionToProjects[_collections[i].collectionAddress] == 0,
                "Invalid address collection"
            );
            _total += _collections[i].rewardPercent;
            if (_collections[i].rewardRarityPercents.length > 0) {
                checkValidPercent(_collections[i].rewardRarityPercents);
            }
            collectionInfos[_collections[i].collectionAddress][_projectCounter.current()] = _collections[i];
            //slither-disable-next-line unused-return
            collectionAddress[_projectCounter.current()].add(_collections[i].collectionAddress);
            collectionToProjects[_collections[i].collectionAddress] = _projectCounter.current();
        }
        require(_total == DENOMINATOR, "The total percentage must be equal to 100%");

        //slither-disable-next-line reentrancy-no-eth
        address _claimPool = claimPoolFactory.create(address(this), _paymentToken, _msgSender());
        projectInfo.claimPool = _claimPool;

        if (_budget > 0) {
            if (_paymentToken == address(0)) {
                require(msg.value == _budget, "Invalid amount");
            }
            _splitBudget(projectInfo, _budget);
            TransferHelper._transferToken(_paymentToken, _budget, _msgSender(), _claimPool);
        }

        emit CreatedProject(projectInfo.projectId, _idOffChain);
    }

    /**
     * @notice remove project while project is active.
     * @dev    Only admin can call this function.
     * @param _projectId Id of the project
     *
     * emit {RemovedProject} events
     */
    function removeProject(uint256 _projectId) external validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        for (uint256 i = 0; i < collectionAddress[_projectId].length(); i++) {
            require(
                !ITaskManager(taskManager).isValidTaskOf(collectionAddress[_projectId].at(i)),
                "Cannot remove collection"
            );
            delete collectionToProjects[collectionAddress[_projectId].at(i)];
            IClaimPool(projects[_projectId].claimPool).updateBudget(collectionAddress[_projectId].at(i), 0);
        }
        projects[_projectId].status = false;

        IClaimPool(projects[_projectId].claimPool).withdraw();

        emit RemovedProject(_projectId);
    }

    /**
     * @notice Add new collection to project
     * @dev    Only admin can call this function.
     * @param _projectId Id of project
     * @param _collection New collection will be added to project
     * @param percents List of percents of new list collections
     *
     * emit {AddedCollection} events
     */
    function addCollection(
        uint256 _projectId,
        CollectionInfo memory _collection,
        uint256[] calldata percents
    ) external validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        require(
            _collection.collectionAddress != address(0) && collectionToProjects[_collection.collectionAddress] == 0,
            "Invalid address collection"
        );
        require(collectionAddress[_projectId].length() + 1 == percents.length, "Invalid percents array");

        if (_collection.rewardRarityPercents.length > 0) {
            checkValidPercent(_collection.rewardRarityPercents);
        }
        collectionInfos[_collection.collectionAddress][_projectId] = _collection;
        //slither-disable-next-line unused-return
        collectionAddress[_projectId].add(_collection.collectionAddress);
        collectionToProjects[_collection.collectionAddress] = _projectId;

        updatePercent(_projectId, percents);

        emit AddedCollection(_projectId, _collection.collectionAddress);
    }

    /**
     * @notice Remove collection from project
     * @dev    Only admin can call this function.
     * @param _projectId Id of project
     * @param _collectionAddress Address of collection will be removed to project
     * @param percents List of percents of new list collections
     *
     * emit {RemovedCollection} events
     */
    function removeCollection(
        uint256 _projectId,
        address _collectionAddress,
        uint256[] calldata percents
    ) external validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        require(!ITaskManager(taskManager).isValidTaskOf(_collectionAddress), "Cannot remove collection");
        require(
            _collectionAddress != address(0) && collectionToProjects[_collectionAddress] == _projectId,
            "Invalid address collection"
        );
        require(collectionAddress[_projectId].length() - 1 == percents.length, "Invalid percents array");
        delete collectionInfos[_collectionAddress][_projectId];
        delete collectionToProjects[_collectionAddress];
        //slither-disable-next-line unused-return
        collectionAddress[_projectId].remove(_collectionAddress);
        if (percents.length > 0) {
            updatePercent(_projectId, percents);
        }
        IClaimPool(projects[_projectId].claimPool).remove(_collectionAddress);

        emit RemovedCollection(_projectId, _collectionAddress);
    }

    /**
     * @notice Deposit token into claim pool
     * @dev    Only project owner can call this function
     * @param _projectId id of project
     * @param _amount amount of token
     *
     * emit {Deposited} events
     */
    function deposit(
        uint256 _projectId,
        uint256 _amount
    ) external payable validProjectId(_projectId) onlyProjectOwner(_projectId) notZero(_amount) {
        ProjectInfo storage projectInfo = projects[_projectId];
        require(isProjectActive(_projectId), "Project deleted");
        projectInfo.budget += _amount;
        if (projectInfo.paymentToken == address(0)) {
            require(msg.value == _amount, "Invalid amount");
        }
        _splitBudget(projectInfo, _amount);
        TransferHelper._transferToken(projectInfo.paymentToken, _amount, _msgSender(), projectInfo.claimPool);

        emit Deposited(_projectId, _amount);
    }

    /**
     * @notice Deposit token into collection of claim pool
     * @dev    Only project owner can call this function
     * @param _projectId id of project
     * @param _collection address of collection
     * @param _amount amount of token
     * 
     * emit {DepositedToCollection} events
     */
    function depositToCollection(
        uint256 _projectId,
        address _collection,
        uint256 _amount
    )
        external
        payable
        validProjectId(_projectId)
        onlyProjectOwner(_projectId)
        notZeroAddress(_collection)
        notZero(_amount)
    {
        require(collectionToProjects[_collection] == _projectId, "Invalid collection address");
        ProjectInfo storage projectInfo = projects[_projectId];
        projectInfo.budget += _amount;

        uint256 rewardCollection = IClaimPool(projectInfo.claimPool).getReward(_collection);

        IClaimPool(projectInfo.claimPool).updateBudget(_collection, rewardCollection + _amount);

        if (projectInfo.paymentToken == address(0)) {
            require(msg.value == _amount, "Invalid amount");
        }
        TransferHelper._transferToken(projectInfo.paymentToken, _amount, _msgSender(), projectInfo.claimPool);

        emit DepositedToCollection(_projectId, _collection, _amount);
    }

   /**
     * @notice Withdraw token from collection of claim pool
     * @dev    Only project owner can call this function
     * @param _projectId id of project
     * @param _collection address of collection
     * @param _amount amount of token
     * 
     * emit {WithdrawnCollection} events
     */
    function withdrawCollection(
        uint256 _projectId,
        address _collection,
        uint256 _amount
    )
        external
        nonReentrant
        validProjectId(_projectId)
        onlyProjectOwner(_projectId)
        notZeroAddress(_collection)
        notZero(_amount)
    {
        require(collectionToProjects[_collection] == _projectId, "Invalid collection address");
        ProjectInfo storage projectInfo = projects[_projectId];
        require(projectInfo.budget >= _amount, "Invalid amount");
        projectInfo.budget -= _amount;

        IClaimPool(projectInfo.claimPool).withdrawCollection(_collection, projectInfo.projectOwner, _amount);

        emit WithdrawnCollection(_projectId, _collection, _amount);
    }

     /**
     * @notice Update percent of list collection in project
     * @dev    Only project owner can call this function
     * @param _projectId Id of project
     * @param percents List percents of collections
     * 
     * emit {UpdatedPercent} events
     */
    function updatePercent(
        uint256 _projectId,
        uint256[] calldata percents
    ) public nonReentrant validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        checkValidPercent(percents);
        require(percents.length == collectionAddress[_projectId].length(), "Invalid length");

        for (uint256 i = 0; i < collectionAddress[_projectId].length(); i++) {
            collectionInfos[collectionAddress[_projectId].at(i)][_projectId].rewardPercent = percents[i];
        }

        emit UpdatedPercent(_projectId, percents);
    }

    /**
     * @notice Update reward rarity of each collection
     * @dev    Only project owner can call this function
     * @param _projectId id of project
     * @param _collection list of new percent
     * @param rarityPercents list of new percent
     * 
     * emit {UpdatedRewardRarityPercent} events
     */
    function updateRewardRarityPercent(
        uint256 _projectId,
        address _collection,
        uint256[] calldata rarityPercents
    ) public validProjectId(_projectId) onlyProjectOwner(_projectId) {
        require(isProjectActive(_projectId), "Project deleted");
        checkValidPercent(rarityPercents);
        require(collectionToProjects[_collection] == _projectId, "Invalid collection address");
        collectionInfos[_collection][_projectId].rewardRarityPercents = rarityPercents;

        emit UpdatedRewardRarityPercent(_projectId, _collection, rarityPercents);
    }

    /**
     * @notice Split reward token in claim pool
     * @dev    Only hlp claim pool can call this function
     * @param _projectId id of project
     * @param _amount amount of token
     * 
     * emit {SplittedBudget} events
     */
    function splitBudget(uint256 _projectId, uint256 _amount) external validProjectId(_projectId) {
        require(address(hlpClaimPool) == _msgSender(), "Caller is not permitted");
        _splitBudget(projects[_projectId], _amount);

        emit SplittedBudget(_projectId, _amount);
    }

    /**
     * @notice Check valid collection
     * @dev    Everyone can call this function
     * @param _collection collection address
     */
    function isCollectionActive(address _collection) public view returns (bool) {
        return isProjectActive(collectionToProjects[_collection]);
    }

    /**
     * @notice Check valid project
     * @dev    Everyone can call this function
     * @param _projectId project id
     */
    function isProjectActive(uint256 _projectId) public view returns (bool) {
        return projects[_projectId].status;
    }

    // private function
    /**
     * @notice Check valid reward rarity percent
     * @dev    Everyone can call this function
     * @param _arrays list array rarity percent
     */
    function checkValidPercent(uint256[] memory _arrays) private pure {
        uint256 _totalRewardRarity = 0;
        for (uint256 i = 0; i < _arrays.length; i++) {
            _totalRewardRarity += _arrays[i];
        }
        require(_totalRewardRarity == DENOMINATOR, "The total percentage must be equal to 100%");
    }

    /**
     * @notice Split reward token in claim pool
     * @param _projectInfo object of ProjectInfo
     * @param _amount reward additional into claim pool
     */
    function _splitBudget(ProjectInfo storage _projectInfo, uint256 _amount) private {
        for (uint256 i = 0; i < collectionAddress[_projectInfo.projectId].length(); i++) {
            uint256 rewardCollection = IClaimPool(_projectInfo.claimPool).getReward(
                collectionAddress[_projectInfo.projectId].at(i)
            );
            CollectionInfo memory collectionInfo = collectionInfos[collectionAddress[_projectInfo.projectId].at(i)][
                _projectInfo.projectId
            ];
            uint256 newReward = (_amount * collectionInfo.rewardPercent) / DENOMINATOR;
            IClaimPool(_projectInfo.claimPool).updateBudget(
                collectionAddress[_projectInfo.projectId].at(i),
                rewardCollection + newReward
            );
        }
    }

    // Get function
    /**
     *  @notice Get project counter
     *
     *  @dev    All caller can call this function.
     */
    function getProjectCounter() external view returns (uint256) {
        return _projectCounter.current();
    }

    /**
     *  @notice Get project by project id
     *
     *  @dev    All caller can call this function.
     */
    function getProjectById(uint256 _projectId) external view returns (ProjectInfo memory) {
        return projects[_projectId];
    }

    /**
     *  @notice Get project by project id
     *
     *  @dev    All caller can call this function.
     */
    function getLengthCollectionByProjectId(uint256 _projectId) external view returns (uint256) {
        return collectionAddress[_projectId].length();
    }

    /**
     *  @notice Get collection address by project id and index
     *
     *  @dev    All caller can call this function.
     */
    function getCollectionByIndex(uint256 _projectId, uint256 _index) external view returns (address) {
        return collectionAddress[_projectId].at(_index);
    }

    /**
     *  @notice Get all collection address by project id
     *
     *  @dev    All caller can call this function.
     */
    function getAllCollection(uint256 _projectId) external view returns (address[] memory) {
        return collectionAddress[_projectId].values();
    }

    /**
     *  @notice Get paymentToken address by collection address
     *
     *  @dev    All caller can call this function.
     */
    function getPaymentTokenOf(address collection) external view returns (address) {
        return projects[collectionToProjects[collection]].paymentToken;
    }

    /**
     *  @notice Get claimpool address by collection address
     *
     *  @dev    All caller can call this function.
     */
    function getClaimPoolOf(address collection) external view returns (address) {
        return projects[collectionToProjects[collection]].claimPool;
    }

    /**
     *  @notice Get get project owner by collection address
     *
     *  @dev    All caller can call this function.
     */
    function getProjectOwnerOf(address collection) external view returns (address) {
        uint256 projectId = collectionToProjects[collection];
        return projects[projectId].projectOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

import "./interfaces/IAdmin.sol";

/**
 *  @title  Dev Validatable
 *
 *  @author IHeart Team
 *
 *  @dev This contract is using as abstract smartcontract
 *  @notice This smart contract provide the validatable methods and modifier for the inheriting contract.
 */
contract Validatable is PausableUpgradeable {
    /**
     *  @notice paymentToken IAdmin is interface of Admin contract
     */
    IAdmin public admin;

    event SetPause(bool indexed isPause);

    /*------------------Check Admins------------------*/

    modifier onlyOwner() {
        require(admin.owner() != _msgSender(), "Caller is not owner");
        _;
    }

    modifier onlyAdmin() {
        require(admin.isAdmin(_msgSender()), "Caller is not owner or admin");
        _;
    }

    modifier validWallet(address _account) {
        require(isWallet(_account), "Invalid wallet");
        _;
    }

    /*------------------Common Checking------------------*/

    modifier notZeroAddress(address _account) {
        require(_account != address(0), "Invalid address");
        _;
    }

    modifier notZero(uint256 _amount) {
        require(_amount > 0, "Invalid amount");
        _;
    }

    /*------------------Initializer------------------*/

    function __Validatable_init(IAdmin _admin) internal onlyInitializing {
        __Context_init();
        __Pausable_init();

        admin = _admin;
    }

    /*------------------Contract Interupts------------------*/

    /**
     *  @notice Set pause action
     */
    function setPause(bool isPause) public onlyOwner {
        if (isPause) _pause();
        else _unpause();

        emit SetPause(isPause);
    }

    /**
     *  @notice Check contract is paused.
     */
    function isPaused() public view returns (bool) {
        return super.paused();
    }

    /*------------------Checking Functions------------------*/
    function isWallet(address _account) public view returns (bool) {
        return _account != address(0) && !AddressUpgradeable.isContract(_account) && tx.origin == _msgSender();
    }
}