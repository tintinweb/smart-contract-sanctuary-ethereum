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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IBorrowerOperations.sol";
import "./depend/LiquityBase.sol";
import "./interfaces/ITroveManager.sol";
import "./interfaces/ICollateralManager.sol";
import "./interfaces/ICollSurplusPool.sol";
import "./interfaces/IConcaveStaking.sol";
import "./interfaces/ICUSDToken.sol";
import "./interfaces/ISortedTroves.sol";
import "./depend/CheckContract.sol";


contract BorrowerOperations is IBorrowerOperations,LiquityBase, OwnableUpgradeable {

    using SafeMathUpgradeable for uint;

    // --- Connected contract declarations ---

    ITroveManager public troveManager;

    ICollateralManager collateralManager;

    address gasPoolAddress;

    ICollSurplusPool collSurplusPool;

    IConcaveStaking public concaveStaking;
    address public concaveStakingAddress;

    ICUSDToken public cusdToken;

    // A doubly linked list of Troves, sorted by their collateral ratios
    ISortedTroves public sortedTroves;


    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

     struct LocalVariables_adjustTrove {
        ICollateralManager.CollateralData collateral;
        uint price;
        uint collChange;
        uint netDebtChange;
        bool isCollIncrease;
        uint debt;
        uint coll;
        uint oldICR;
        uint newICR;
        uint newTCR;
        uint CUSDFee;
        uint newDebt;
        uint newColl;
        uint stake;
    }

    struct LocalVariables_openTrove {
        uint price;
        uint CUSDFee;
        uint netDebt;
        uint compositeDebt;
        uint ICR;
        uint NICR;
        uint stake;
        uint arrayIndex;
    }

    struct ContractsCache {
        ICollateralManager collateralManager;
        ITroveManager troveManager;
        IActivePool activePool;
        ICUSDToken cusdToken;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }

    function initialize() public initializer {
        __Ownable_init();
    }

    // --- Dependency setters ---

    function setAddresses(
        address _collateralManagerAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceStrategyAddress,
        address _sortedTrovesAddress,
        address _cusdTokenAddress,
        address _concaveStakingAddress
    )
        external
        override
        onlyOwner
    {   
        CheckContract.isContract(_collateralManagerAddress);
        CheckContract.isContract(_troveManagerAddress);
        CheckContract.isContract(_activePoolAddress);
        CheckContract.isContract(_defaultPoolAddress);
        CheckContract.isContract(_gasPoolAddress);
        CheckContract.isContract(_collSurplusPoolAddress);
        CheckContract.isContract(_priceStrategyAddress);
        CheckContract.isContract(_sortedTrovesAddress);
        CheckContract.isContract(_cusdTokenAddress);
        CheckContract.isContract(_concaveStakingAddress);

        collateralManager = ICollateralManager(_collateralManagerAddress);
        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        // stabilityPoolAddress = _stabilityPoolAddress;
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        priceStrategy = IPriceStrategyFactory(_priceStrategyAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        cusdToken = ICUSDToken(_cusdTokenAddress);
        concaveStakingAddress = _concaveStakingAddress;
        concaveStaking = IConcaveStaking(_concaveStakingAddress);

        emit TroveManagerAddressChanged(_troveManagerAddress);
        emit ActivePoolAddressChanged(_activePoolAddress);
        emit DefaultPoolAddressChanged(_defaultPoolAddress);
        // emit StabilityPoolAddressChanged(_stabilityPoolAddress);
        emit GasPoolAddressChanged(_gasPoolAddress);
        emit CollSurplusPoolAddressChanged(_collSurplusPoolAddress);
        emit PriceFeedAddressChanged(_priceStrategyAddress);
        emit SortedTrovesAddressChanged(_sortedTrovesAddress);
        emit CUSDTokenAddressChanged(_cusdTokenAddress);
        emit ConcaveStakingAddressChanged(_concaveStakingAddress);

    }

    // --- Borrower Trove Operations ---

    function openTrove(address _lpTokenAddr, uint _lpTokenAmount, uint _maxFeePercentage, uint _CUSDAmount, address _upperHint, address _lowerHint) external payable override {
        ContractsCache memory contractsCache = ContractsCache(collateralManager, troveManager, activePool, cusdToken);
        LocalVariables_openTrove memory vars;

        require(contractsCache.collateralManager.isActive(_lpTokenAddr), "collateral is not active");
        require(IERC20Upgradeable(_lpTokenAddr).balanceOf(msg.sender) >= _lpTokenAmount, "insufficient balance");

        ICollateralManager.CollateralData memory collateral = contractsCache.collateralManager.find(_lpTokenAddr);

        vars.price = priceStrategy.fetchPrice(_lpTokenAddr);
        bool isRecoveryMode = _checkRecoveryMode(_lpTokenAddr, vars.price, collateral.CCR);

        _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
        _requireTroveisNotActive(_lpTokenAddr, contractsCache.troveManager, msg.sender);

        vars.CUSDFee;
        vars.netDebt = _CUSDAmount;

        if (!isRecoveryMode) {
            vars.CUSDFee = _triggerBorrowingFee(contractsCache.troveManager, contractsCache.cusdToken, _CUSDAmount, _maxFeePercentage);
            vars.netDebt = vars.netDebt.add(vars.CUSDFee);
        }
        _requireAtLeastMinNetDebt(vars.netDebt, collateral.MIN_NET_DEBT);

        // ICR is based on the composite debt, i.e. the requested CUSD amount + CUSD borrowing fee + CUSD gas comp.
        vars.compositeDebt = _getCompositeDebt(vars.netDebt, collateral.CUSD_GAS_COMPENSATION);
        assert(vars.compositeDebt > 0);
        
        vars.ICR = LiquityMath._computeCR(_lpTokenAmount, vars.compositeDebt, vars.price);
        vars.NICR = LiquityMath._computeNominalCR(_lpTokenAmount, vars.compositeDebt);

        if (isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR, collateral.CCR);
        } else {
            _requireICRisAboveMCR(vars.ICR, collateral.MCR);
            uint newTCR = _getNewTCRFromTroveChange(_lpTokenAddr, _lpTokenAmount, true, vars.compositeDebt, true, vars.price);  // bools: coll increase, debt increase
            _requireNewTCRisAboveCCR(newTCR, collateral.CCR);
        }

        // Set the trove struct's properties
        contractsCache.troveManager.setTroveStatus(_lpTokenAddr, msg.sender, 1);
        contractsCache.troveManager.increaseTroveColl(_lpTokenAddr, msg.sender, _lpTokenAmount);
        contractsCache.troveManager.increaseTroveDebt(_lpTokenAddr, msg.sender, vars.compositeDebt);

        contractsCache.troveManager.updateTroveRewardSnapshots(_lpTokenAddr, msg.sender);
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(_lpTokenAddr, msg.sender);

        sortedTroves.insert(_lpTokenAddr, msg.sender, vars.NICR, _upperHint, _lowerHint);
        vars.arrayIndex = contractsCache.troveManager.addTroveOwnerToArray(_lpTokenAddr, msg.sender);
        emit TroveCreated(_lpTokenAddr, msg.sender, vars.arrayIndex);

        // Move the ether to the Active Pool, and mint the CUSDAmount to the borrower
        _activePoolAddColl(_lpTokenAddr, contractsCache.activePool, _lpTokenAmount);
        _withdrawCUSD(_lpTokenAddr, contractsCache.activePool, contractsCache.cusdToken, msg.sender, _CUSDAmount, vars.netDebt);
        // Move the CUSD gas compensation to the Gas Pool
        _withdrawCUSD(_lpTokenAddr, contractsCache.activePool, contractsCache.cusdToken, gasPoolAddress, collateral.CUSD_GAS_COMPENSATION, collateral.CUSD_GAS_COMPENSATION);

        emit TroveUpdated(_lpTokenAddr, msg.sender, vars.compositeDebt, _lpTokenAmount, vars.stake, uint8(BorrowerOperation.openTrove));
        emit CUSDBorrowingFeePaid(_lpTokenAddr, msg.sender, vars.CUSDFee);
    }

    // Send ETH as collateral to a trove
    function addColl(address _lpTokenAddr, uint _lpTokenAmount, address _upperHint, address _lowerHint) public override payable {
        _adjustTrove(_lpTokenAddr, _lpTokenAmount, msg.sender, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Send ETH as collateral to a trove. Called by only the Stability Pool.
    function moveETHGainToTrove(address _lpTokenAddr, uint _lpTokenAmount, address _borrower, address _upperHint, address _lowerHint) external payable override {
        ICollateralManager.CollateralData memory collateral = collateralManager.find(_lpTokenAddr);
        address lpStabilityPoolAddr = collateral.stabilityPoolAddr;
        _requireCallerIsStabilityPool(lpStabilityPoolAddr);
        _adjustTrove(_lpTokenAddr, _lpTokenAmount, _borrower, 0, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw ETH collateral from a trove
    function withdrawColl(address _lpTokenAddr, uint _collWithdrawal, address _upperHint, address _lowerHint) external override {
        _adjustTrove(_lpTokenAddr, 0, msg.sender, _collWithdrawal, 0, false, _upperHint, _lowerHint, 0);
    }

    // Withdraw CUSD tokens from a trove: mint new CUSD tokens to the owner, and increase the trove's debt accordingly
    function withdrawCUSD(address _lpTokenAddr, uint _lpTokenAmount, uint _maxFeePercentage, uint _CUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustTrove(_lpTokenAddr, _lpTokenAmount, msg.sender, 0, _CUSDAmount, true, _upperHint, _lowerHint, _maxFeePercentage);
    }

    // Repay CUSD tokens to a Trove: Burn the repaid CUSD tokens, and reduce the trove's debt accordingly
    function repayCUSD(address _lpTokenAddr, uint _lpTokenAmount, uint _CUSDAmount, address _upperHint, address _lowerHint) external override {
        _adjustTrove(_lpTokenAddr, _lpTokenAmount, msg.sender, 0, _CUSDAmount, false, _upperHint, _lowerHint, 0);
    }

    function adjustTrove(address _lpTokenAddr, uint _lpTokenAmount, uint _maxFeePercentage, uint _collWithdrawal, uint _CUSDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint) external payable override {
        _adjustTrove(_lpTokenAddr, _lpTokenAmount, msg.sender, _collWithdrawal, _CUSDChange, _isDebtIncrease, _upperHint, _lowerHint, _maxFeePercentage);
    }

    /*
    * _adjustTrove(): Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal. 
    *
    * It therefore expects either a positive msg.value, or a positive _collWithdrawal argument.
    *
    * If both are positive, it will revert.
    */
    function _adjustTrove(address _lpTokenAddr, uint _lpTokenAmount, address _borrower, uint _collWithdrawal, uint _CUSDChange, bool _isDebtIncrease, address _upperHint, address _lowerHint, uint _maxFeePercentage) internal {
        ContractsCache memory contractsCache = ContractsCache(collateralManager, troveManager, activePool, cusdToken);
        LocalVariables_adjustTrove memory vars;

        vars.collateral = contractsCache.collateralManager.find(_lpTokenAddr);

        vars.price = priceStrategy.fetchPrice(_lpTokenAddr);
        bool isRecoveryMode = _checkRecoveryMode(_lpTokenAddr, vars.price, vars.collateral.CCR);

        if (_isDebtIncrease) {
            _requireValidMaxFeePercentage(_maxFeePercentage, isRecoveryMode);
            _requireNonZeroDebtChange(_CUSDChange);
        }
        _requireSingularCollChange(_lpTokenAmount, _collWithdrawal);
        _requireNonZeroAdjustment(_lpTokenAmount, _collWithdrawal, _CUSDChange);
        _requireTroveisActive(_lpTokenAddr, contractsCache.troveManager, _borrower);

        // Confirm the operation is either a borrower adjusting their own trove, or a pure ETH transfer from the Stability Pool to a trove
        assert(msg.sender == _borrower || (msg.sender == vars.collateral.stabilityPoolAddr && _lpTokenAmount > 0 && _CUSDChange == 0));//&& msg.value > 0

        contractsCache.troveManager.applyPendingRewards(_lpTokenAddr, _borrower);

        // Get the collChange based on whether or not ETH was sent in the transaction
        (vars.collChange, vars.isCollIncrease) = _getCollChange(_lpTokenAmount, _collWithdrawal);

        vars.netDebtChange = _CUSDChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (_isDebtIncrease && !isRecoveryMode) { 
            vars.CUSDFee = _triggerBorrowingFee(contractsCache.troveManager, contractsCache.cusdToken, _CUSDChange, _maxFeePercentage);
            vars.netDebtChange = vars.netDebtChange.add(vars.CUSDFee); // The raw debt change includes the fee
        }

        vars.debt = contractsCache.troveManager.getTroveDebt(_lpTokenAddr, _borrower);
        vars.coll = contractsCache.troveManager.getTroveColl(_lpTokenAddr, _borrower);
        
        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = LiquityMath._computeCR(vars.coll, vars.debt, vars.price);
        vars.newICR = _getNewICRFromTroveChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease, vars.price);
        assert(_collWithdrawal <= vars.coll); 

        // Check the adjustment satisfies all conditions for the current system mode
        _requireValidAdjustmentInCurrentMode(_lpTokenAddr, isRecoveryMode, _collWithdrawal, _isDebtIncrease, vars, vars.collateral.CCR, vars.collateral.MCR);
            
        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough CUSD
        if (!_isDebtIncrease && _CUSDChange > 0) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt, vars.collateral.CUSD_GAS_COMPENSATION).sub(vars.netDebtChange), vars.collateral.MIN_NET_DEBT);
            _requireValidCUSDRepayment(vars.debt, vars.netDebtChange, vars.collateral.CUSD_GAS_COMPENSATION);
            _requireSufficientCUSDBalance(contractsCache.cusdToken, _borrower, vars.netDebtChange);
        }

        (vars.newColl, vars.newDebt) = _updateTroveFromAdjustment(_lpTokenAddr, contractsCache.troveManager, _borrower, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        vars.stake = contractsCache.troveManager.updateStakeAndTotalStakes(_lpTokenAddr, _borrower);

        // Re-insert trove in to the sorted list
        uint newNICR = _getNewNominalICRFromTroveChange(vars.coll, vars.debt, vars.collChange, vars.isCollIncrease, vars.netDebtChange, _isDebtIncrease);
        sortedTroves.reInsert(_lpTokenAddr, _borrower, newNICR, _upperHint, _lowerHint);

        emit TroveUpdated(_lpTokenAddr, _borrower, vars.newDebt, vars.newColl, vars.stake, uint8(BorrowerOperation.adjustTrove));
        emit CUSDBorrowingFeePaid(_lpTokenAddr, msg.sender,  vars.CUSDFee);

        // Use the unmodified _CUSDChange here, as we don't send the fee to the user
        _moveTokensAndETHfromAdjustment(
            _lpTokenAddr,
            contractsCache.activePool,
            contractsCache.cusdToken,
            msg.sender,
            vars.collChange,
            vars.isCollIncrease,
            _CUSDChange,
            _isDebtIncrease,
            vars.netDebtChange
        );
    }

    function closeTrove(address _lpTokenAddr) external override {
        ITroveManager troveManagerCached = troveManager;
        IActivePool activePoolCached = activePool;
        ICUSDToken cusdTokenCached = cusdToken;

        ICollateralManager.CollateralData memory collateral = collateralManager.find(_lpTokenAddr);

        _requireTroveisActive(_lpTokenAddr, troveManagerCached, msg.sender);
        uint price = priceStrategy.fetchPrice(_lpTokenAddr);
        _requireNotInRecoveryMode(_lpTokenAddr, price, collateral.CCR);

        troveManagerCached.applyPendingRewards(_lpTokenAddr, msg.sender);

        uint coll = troveManagerCached.getTroveColl(_lpTokenAddr, msg.sender);
        uint debt = troveManagerCached.getTroveDebt(_lpTokenAddr, msg.sender);

        _requireSufficientCUSDBalance(cusdTokenCached, msg.sender, debt.sub(collateral.CUSD_GAS_COMPENSATION));

        uint newTCR = _getNewTCRFromTroveChange(_lpTokenAddr, coll, false, debt, false, price);
        _requireNewTCRisAboveCCR(newTCR, collateral.CCR);

        troveManagerCached.removeStake(_lpTokenAddr, msg.sender);
        troveManagerCached.closeTrove(_lpTokenAddr, msg.sender);

        emit TroveUpdated(_lpTokenAddr, msg.sender, 0, 0, 0, uint8(BorrowerOperation.closeTrove));

        // Burn the repaid CUSD from the user's balance and the gas compensation from the Gas Pool
        _repayCUSD(_lpTokenAddr, activePoolCached, cusdTokenCached, msg.sender, debt.sub(collateral.CUSD_GAS_COMPENSATION));
        _repayCUSD(_lpTokenAddr, activePoolCached, cusdTokenCached, gasPoolAddress, collateral.CUSD_GAS_COMPENSATION);

        // Send the collateral back to the user
        activePoolCached.sendLPToken(_lpTokenAddr, msg.sender, coll);
    }

    /**
     * Claim remaining collateral from a redemption or from a liquidation with ICR > MCR in Recovery Mode
     */
    function claimCollateral(address _lpTokenAddr) external override {
        // send ETH from CollSurplus Pool to owner
        collSurplusPool.claimColl(_lpTokenAddr, msg.sender);
    }


    // --- Helper functions ---

    function _triggerBorrowingFee(ITroveManager _troveManager, ICUSDToken _cusdToken, uint _CUSDAmount, uint _maxFeePercentage) internal returns (uint) {
        _troveManager.decayBaseRateFromBorrowing(); // decay the baseRate state variable
        uint CUSDFee = _troveManager.getBorrowingFee(_CUSDAmount);

        _requireUserAcceptsFee(CUSDFee, _CUSDAmount, _maxFeePercentage);
        
        // Send fee to LQTY staking contract
        concaveStaking.increaseF_CUSD(CUSDFee);
        _cusdToken.mint(concaveStakingAddress, CUSDFee);

        return CUSDFee;
    }

    function _getCollChange(
        uint _collReceived,
        uint _requestedCollWithdrawal
    )
        internal
        pure
        returns(uint collChange, bool isCollIncrease)
    {
        if (_collReceived != 0) {
            collChange = _collReceived;
            isCollIncrease = true;
        } else {
            collChange = _requestedCollWithdrawal;
        }
    }

    // Update trove's coll and debt based on whether they increase or decrease
    function _updateTroveFromAdjustment
    (
        address _lpTokenAddr,
        ITroveManager _troveManager,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        returns (uint, uint)
    {
        uint newColl = (_isCollIncrease) ? _troveManager.increaseTroveColl(_lpTokenAddr, _borrower, _collChange)
                                        : _troveManager.decreaseTroveColl(_lpTokenAddr, _borrower, _collChange);
        uint newDebt = (_isDebtIncrease) ? _troveManager.increaseTroveDebt(_lpTokenAddr, _borrower, _debtChange)
                                        : _troveManager.decreaseTroveDebt(_lpTokenAddr, _borrower, _debtChange);

        return (newColl, newDebt);
    }

    function _moveTokensAndETHfromAdjustment
    (
        address _lpTokenAddr,
        IActivePool _activePool,
        ICUSDToken _cusdToken,
        address _borrower,
        uint _collChange,
        bool _isCollIncrease,
        uint _CUSDChange,
        bool _isDebtIncrease,
        uint _netDebtChange
    )
        internal
    {
        if (_isDebtIncrease) {
            _withdrawCUSD(_lpTokenAddr, _activePool, _cusdToken, _borrower, _CUSDChange, _netDebtChange);
        } else {
            _repayCUSD(_lpTokenAddr, _activePool, _cusdToken, _borrower, _CUSDChange);
        }

        if (_isCollIncrease) {
            _activePoolAddColl(_lpTokenAddr, _activePool, _collChange);
        } else {
            _activePool.sendLPToken(_lpTokenAddr, _borrower, _collChange);
        }
    }

    // Send ETH to Active Pool and increase its recorded ETH balance
    function _activePoolAddColl(address _lpTokenAddr, IActivePool _activePool, uint _amount) internal {
        // (bool success, ) = address(_activePool).call{value: _amount}("");
        // require(success, "BorrowerOps: Sending ETH to ActivePool failed");
        // SafeERC20Upgradeable.safeTransfer(IERC20Upgradeable(_lpTokenAddr), address(_activePool), _amount);
        SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(_lpTokenAddr), msg.sender, address(_activePool), _amount);
        _activePool.increaseLPToken(_lpTokenAddr, _amount);
    }

    function _mintCDLPTokenAndStake(address _lpTokenAddr, address _user, uint _amount) internal {
        // convexOperations.stake(_lpTokenAddr, _user, _amount);
    }

    // Issue the specified amount of CUSD to _account and increases the total active debt (_netDebtIncrease potentially includes a CUSDFee)
    function _withdrawCUSD(address _lpTokenAddr, IActivePool _activePool, ICUSDToken _cusdToken, address _account, uint _CUSDAmount, uint _netDebtIncrease) internal {
        _activePool.increaseCUSDDebt(_lpTokenAddr, _netDebtIncrease);
        _cusdToken.mint(_account, _CUSDAmount);
    }

    // Burn the specified amount of CUSD from _account and decreases the total active debt
    function _repayCUSD(address _lpTokenAddr, IActivePool _activePool, ICUSDToken _cusdToken, address _account, uint _CUSD) internal {
        _activePool.decreaseCUSDDebt(_lpTokenAddr, _CUSD);
        _cusdToken.burn(_lpTokenAddr, _account, _CUSD);
    }


    // --- 'Require' wrapper functions ---

    function _requireSingularCollChange(uint _lpTokenAmount, uint _collWithdrawal) internal view {
        require(_lpTokenAmount == 0 || _collWithdrawal == 0, "BorrowerOperations: Cannot withdraw and add coll");
    }

    function _requireNonZeroAdjustment(uint _lpTokenAmount, uint _collWithdrawal, uint _CUSDChange) internal view {
        require(_lpTokenAmount != 0 || _collWithdrawal != 0 || _CUSDChange != 0, "BorrowerOps: There must be either a collateral change or a debt change");
    }

    function _requireTroveisActive(address _lpTokenAddr, ITroveManager _troveManager, address _borrower) internal view {
        uint status = _troveManager.getTroveStatus(_lpTokenAddr, _borrower);
        require(status == 1, "BorrowerOps: Trove does not exist or is closed");
    }

    function _requireTroveisNotActive(address _lpTokenAddr, ITroveManager _troveManager, address _borrower) internal view {
        uint status = _troveManager.getTroveStatus(_lpTokenAddr, _borrower);
        require(status != 1, "BorrowerOps: Trove is active");
    }

    function _requireNonZeroDebtChange(uint _CUSDChange) internal pure {
        require(_CUSDChange > 0, "BorrowerOps: Debt increase requires non-zero debtChange");
    }

    function _requireNotInRecoveryMode(address _lpTokenAddr, uint _price, uint _CCR) internal view {
        require(!_checkRecoveryMode(_lpTokenAddr, _price, _CCR), "BorrowerOps: Operation not permitted during Recovery Mode");
    }

    function _requireNoCollWithdrawal(uint _collWithdrawal) internal pure {
        require(_collWithdrawal == 0, "BorrowerOps: Collateral withdrawal not permitted Recovery Mode");
    }


    function _requireValidAdjustmentInCurrentMode 
    (
        address _lpTokenAddr,
        bool _isRecoveryMode,
        uint _collWithdrawal,
        bool _isDebtIncrease, 
        LocalVariables_adjustTrove memory _vars,
        uint _CCR,
        uint _MCR
    ) 
        internal 
        view 
    {
        /* 
        *In Recovery Mode, only allow:
        *
        * - Pure collateral top-up
        * - Pure debt repayment
        * - Collateral top-up with debt repayment
        * - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
        *
        * In Normal Mode, ensure:
        *
        * - The new ICR is above MCR
        * - The adjustment won't pull the TCR below CCR
        */
        if (_isRecoveryMode) {
            _requireNoCollWithdrawal(_collWithdrawal);
            if (_isDebtIncrease) {
                _requireICRisAboveCCR(_vars.newICR, _CCR);
                _requireNewICRisAboveOldICR(_vars.newICR, _vars.oldICR);
            }       
        } else { // if Normal Mode
            _requireICRisAboveMCR(_vars.newICR, _MCR);
            _vars.newTCR = _getNewTCRFromTroveChange(_lpTokenAddr, _vars.collChange, _vars.isCollIncrease, _vars.netDebtChange, _isDebtIncrease, _vars.price);
            _requireNewTCRisAboveCCR(_vars.newTCR, _CCR);  
        }
    }

    function _requireICRisAboveMCR(uint _newICR, uint _MCR) internal pure {
        require(_newICR >= _MCR, "BorrowerOps: An operation that would result in ICR < MCR is not permitted");
    }

    function _requireICRisAboveCCR(uint _newICR, uint _CCR) internal pure {
        require(_newICR >= _CCR, "BorrowerOps: Operation must leave trove with ICR >= CCR");
    }


    function _requireNewICRisAboveOldICR(uint _newICR, uint _oldICR) internal pure {
        require(_newICR >= _oldICR, "BorrowerOps: Cannot decrease your Trove's ICR in Recovery Mode");
    }

    function _requireNewTCRisAboveCCR(uint _newTCR, uint _CCR) internal pure {
        require(_newTCR >= _CCR, "BorrowerOps: An operation that would result in TCR < CCR is not permitted");
    }

    function _requireAtLeastMinNetDebt(uint _netDebt, uint _min_net_debt) internal pure {
        require (_netDebt >= _min_net_debt, "BorrowerOps: Trove's net debt must be greater than minimum");
    }

    function _requireValidCUSDRepayment(uint _currentDebt, uint _debtRepayment, uint _cusd_gas_compensation) internal pure {
        require(_debtRepayment <= _currentDebt.sub(_cusd_gas_compensation), "BorrowerOps: Amount repaid must not be larger than the Trove's debt");
    }

    function _requireCallerIsStabilityPool(address _lpStabilityPoolAddr) internal view {
        require(msg.sender == _lpStabilityPoolAddr, "BorrowerOps: Caller is not Stability Pool");
    }

    function _requireSufficientCUSDBalance(ICUSDToken _cusdToken, address _borrower, uint _debtRepayment) internal view {
        require(_cusdToken.balanceOf(_borrower) >= _debtRepayment, "BorrowerOps: Caller doesnt have enough CUSD to make repayment");
    }

    function _requireValidMaxFeePercentage(uint _maxFeePercentage, bool _isRecoveryMode) internal pure {
        if (_isRecoveryMode) {
            require(_maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must less than or equal to 100%");
        } else {
            require(_maxFeePercentage >= BORROWING_FEE_FLOOR && _maxFeePercentage <= DECIMAL_PRECISION,
                "Max fee percentage must be between 0.5% and 100%");
        }
    }


    // --- ICR and TCR getters ---

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewNominalICRFromTroveChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newNICR = LiquityMath._computeNominalCR(newColl, newDebt);
        return newNICR;
    }

    // Compute the new collateral ratio, considering the change in coll and debt. Assumes 0 pending rewards.
    function _getNewICRFromTroveChange
    (
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        pure
        internal
        returns (uint)
    {
        (uint newColl, uint newDebt) = _getNewTroveAmounts(_coll, _debt, _collChange, _isCollIncrease, _debtChange, _isDebtIncrease);

        uint newICR = LiquityMath._computeCR(newColl, newDebt, _price);
        return newICR;
    }

    function _getNewTroveAmounts(
        uint _coll,
        uint _debt,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease
    )
        internal
        pure
        returns (uint, uint)
    {
        uint newColl = _coll;
        uint newDebt = _debt;

        newColl = _isCollIncrease ? _coll.add(_collChange) :  _coll.sub(_collChange);
        newDebt = _isDebtIncrease ? _debt.add(_debtChange) : _debt.sub(_debtChange);

        return (newColl, newDebt);
    }

    function _getNewTCRFromTroveChange
    (
        address _lpTokenAddr,
        uint _collChange,
        bool _isCollIncrease,
        uint _debtChange,
        bool _isDebtIncrease,
        uint _price
    )
        internal
        view
        returns (uint)
    {
        uint totalColl = getEntireSystemColl(_lpTokenAddr);
        uint totalDebt = getEntireSystemDebt(_lpTokenAddr);

        totalColl = _isCollIncrease ? totalColl.add(_collChange) : totalColl.sub(_collChange);
        totalDebt = _isDebtIncrease ? totalDebt.add(_debtChange) : totalDebt.sub(_debtChange);

        uint newTCR = LiquityMath._computeCR(totalColl, totalDebt, _price);
        return newTCR;
    }


    function getCompositeDebt(address _lpTokenAddr, uint _debt) public override view returns (uint256) {
        ICollateralManager.CollateralData memory collateral = collateralManager.find(_lpTokenAddr);
        return _getCompositeDebt(_debt, collateral.CUSD_GAS_COMPENSATION);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract BaseMath {
    uint constant public DECIMAL_PRECISION = 1e18;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

library CheckContract {
	
    function isContract(address account) public view {
        bool b = AddressUpgradeable.isContract(account);
        require(b, "account is not contract");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "../price/IPriceStrategyFactory.sol";
import "../interfaces/ILiquityBase.sol";
import "../depend/BaseMath.sol";
import "../interfaces/IActivePool.sol";
import "../interfaces/IDefaultPool.sol";
import "./LiquityMath.sol";

contract LiquityBase is BaseMath, ILiquityBase {

    using SafeMathUpgradeable for uint;

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Amount of CUSD to be locked in gas pool on opening troves
    // uint constant public CUSD_GAS_COMPENSATION = 200e18;

    uint constant public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint constant public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    IActivePool public activePool;

    IDefaultPool public defaultPool;


    IPriceStrategyFactory public override priceStrategy;


    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a trove, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt, uint _cusd_gas_compensation) internal pure returns (uint) {
        return _debt.add(_cusd_gas_compensation);
    }

    function _getNetDebt(uint _debt, uint _cusd_gas_compensation) internal pure returns (uint) {
        return _debt.sub(_cusd_gas_compensation);
    }


    // Return the amount of ETH to be drawn from a trove's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal pure returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }


    function getEntireSystemColl(address _lpTokenAddress) public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getLPTokenAmount(_lpTokenAddress);
        uint liquidatedColl = defaultPool.getLPTokenAmount(_lpTokenAddress);

        return activeColl.add(liquidatedColl);
    }

    function getEntireSystemDebt(address _lpTokenAddress) public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getCUSDDebt(_lpTokenAddress);
        uint closedDebt = defaultPool.getCUSDDebt(_lpTokenAddress);

        return activeDebt.add(closedDebt);
    }

    function _getTCR(address _lpTokenAddress, uint _price) internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl(_lpTokenAddress);
        uint entireSystemDebt = getEntireSystemDebt(_lpTokenAddress);

        TCR = LiquityMath._computeCR(entireSystemColl, entireSystemDebt, _price);

        return TCR;
    }

    function _checkRecoveryMode(address _lpTokenAddress, uint _price, uint _CCR) internal view returns (bool) {
        uint TCR = _getTCR(_lpTokenAddress, _price);

        return TCR < _CCR;
    }


    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }
	
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";


library LiquityMath {

    using SafeMathUpgradeable for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division. 
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }


    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt);
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }


    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
    }


    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) TroveManager._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IPool.sol";


interface IActivePool is IPool {
    // --- Events ---
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolCUSDDebtUpdated(address indexed _lpTokenAddress, uint _CUSDDebt);
    event ActivePoolLPTokenBalanceUpdated(address indexed _lpTokenAddres, uint _ETH);

    // --- Functions ---
    function sendLPToken(address _lpTokenAddress, address _account, uint _amount) external;

    function increaseLPToken(address _lpTokenAddress, uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IBorrowerOperations {

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    // event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event CUSDTokenAddressChanged(address _cusdTokenAddress);
    event ConcaveStakingAddressChanged(address _concaveStakingAddress);

    event TroveCreated(address indexed _lpTokenAddr, address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _lpTokenAddr, address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event CUSDBorrowingFeePaid(address indexed _lpTokenAddr, address indexed _borrower, uint _LUSDFee);

    // --- Functions ---

    function setAddresses(
        address _collateralManagerAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        // address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _sortedTrovesAddress,
        address _cusdTokenAddress,
        address _concaveStakingAddress
    ) external;
    
    function openTrove(address _lpTokenAddr, uint _lpTokenAmount, uint _maxFee, uint _CUSDAmount, address _upperHint, address _lowerHint) external payable;

    function addColl(address _lpTokenAddr, uint _lpTokenAmount, address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(address _lpTokenAddr, uint _lpTokenAmount, address _user, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(address _lpTokenAddr, uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawCUSD(address _lpTokenAddr, uint _lpTokenAmount, uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayCUSD(address _lpTokenAddr, uint _lpTokenAmount, uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove(address _lpTokenAddr) external;

    function adjustTrove(address _lpTokenAddr, uint _lpTokenAmount, uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;

    function claimCollateral(address _lpTokenAddr) external;

    function getCompositeDebt(address _lpTokenAddr, uint _debt) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICCVToken is IERC20Upgradeable {

    
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ICollateralManager {

    struct CollateralData {
        address lpTokenAddr;
        address stabilityPoolAddr;
        address cdlpTokenAddr;
        uint256 MCR; // Minimum collateral ratio for individual troves
        uint256 CCR; // Critical system collateral ratio.If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
        uint256 CUSD_GAS_COMPENSATION; // Amount of LUSD to be locked in gas pool on opening troves
        uint256 MIN_NET_DEBT; //Minimum amount of net LUSD debt a trove must have
        bool paused;
    }

    function addCollateral(address _lpTokenAddr, address _stabilityPoolAddr, address _cdlpTokenAddr) external;

    function removeCollateral(address _lpTokenAddr) external;


    function pauseCollateral(address _lpTokenAddr) external;

    function unpauseCollateral(address _lpTokenAddr) external;

    function updateCollateralStabilityPoolAddr(address _lpTokenAddr, address _stabilityPoolAddr) external;

    function getCollateralStabilityPoolAddr(address _lpTokenAddr) external view returns (address);

    function getCollateralList() external view returns (address[] memory);

    function getActiveCollateralList() external view returns (address[] memory);

    function exists(address _lpTokenAddr) external view returns(bool);

    function isActive(address _lpTokenAddr) external view returns(bool);

    function find(address _lpTokenAddr) external view returns(CollateralData memory);
    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ICollSurplusPool {


	// --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _lpTokenAddress, address indexed _account, uint _newBalance);
    event lpTokenSent(address _lpTokenAddress, address _to, uint _amount);


    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getLPTokenAmount(address _lpTokenAddress) external view returns (uint);

    function getCollateral(address _lpTokenAddress, address _account) external view returns (uint);

    function accountSurplus(address _lpTokenAddress, address _account, uint _amount) external;

    function claimColl(address _lpTokenAddress, address _account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IConcaveStaking {

    function stake(uint256 amount) external;

    function unstake(uint256 amount) external;

    function increaseF_CUSD(uint256 cusdFee) external;

    function getPendingCUSDGain(address user) external view returns(uint256); 
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface ICUSDToken is IERC20Upgradeable {

    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);

    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    function mint(address _account, uint256 _amount) external;

    function burn(address _lpTokenAddr, address _account, uint256 _amount) external;

    function sendToPool(address _lpTokenAddr, address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address _lpTokenAddr, address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IPool.sol";


interface IDefaultPool is IPool {

    // --- Events ---
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event DefaultPoolCUSDDebtUpdated(address _lpTokenAddress, uint _CUSDDebt);
    event DefaultPoolETHBalanceUpdated(address _lpTokenAddress, uint _lpTokenAmount);
    event lpTokenSent(address _lpTokenAddress, address _to, uint _amount);

    // --- Functions ---
    function sendLPTokenToActivePool(address _lpTokenAddress, uint _amount) external;
	
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../price/IPriceStrategyFactory.sol";


interface ILiquityBase {
    function priceStrategy() external view returns (IPriceStrategyFactory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

// Common interface for the Pools.
interface IPool {
    
    // --- Events ---
    
    event ETHBalanceUpdated(uint _newBalance);
    event LUSDBalanceUpdated(uint _newBalance);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event LPTokenSent(address indexed _lpTokenAddress, address _to, uint _amount);

    // --- Functions ---
    
    function getLPTokenAmount(address _lpTokenAddress) external view returns (uint);

    function getCUSDDebt(address _lpTokenAddress) external view returns (uint);

    function increaseCUSDDebt(address _lpTokenAddress, uint _amount) external;

    function decreaseCUSDDebt(address _lpTokenAddress, uint _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _lpTokenAddress, address _id, uint _NICR);
    event NodeRemoved(address _lpTokenAddress, address _id);


    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(address _lpTokenAddress, address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _lpTokenAddress, address _id) external;

    function reInsert(address _lpTokenAddress, address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _lpTokenAddress, address _id) external view returns (bool);

    function isFull(address _lpTokenAddress) external view returns (bool);

    function isEmpty(address _lpTokenAddress) external view returns (bool);

    function getSize(address _lpTokenAddress) external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst(address _lpTokenAddress) external view returns (address);

    function getLast(address _lpTokenAddress) external view returns (address);

    function getNext(address _lpTokenAddress, address _id) external view returns (address);

    function getPrev(address _lpTokenAddress, address _id) external view returns (address);

    function validInsertPosition(address _lpTokenAddress, uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(address _lpTokenAddress, uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IStabilityPool {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolCUSDBalanceUpdated(uint _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event CUSDTokenAddressChanged(address _newCUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _CUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint _LQTY);
    event LQTYPaidToFrontEnd(address indexed _frontEnd, uint _LQTY);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _lpTokenAddress,
        address _collateralManager,
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _cusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount) external;


    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;


    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;


    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the CUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, uint _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint);

    /*
     * Returns CUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalCUSDDeposits() external view returns (uint);


    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint);
    

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedCUSDDeposit(address _depositor) external view returns (uint);



	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./ICUSDToken.sol";
import "./IConcaveStaking.sol";
import "./ICCVToken.sol";

interface ITroveManager is ILiquityBase {

    function setAddresses(
        address _collateralManagerAddress,
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        // address _stabilityPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _priceFeedAddress,
        address _cusdTokenAddress,
        address _sortedTrovesAddress,
        address _ccvTokenAddress,
        address _concaveStakingAddress
    ) external;


    // function stabilityPool() external view returns (IStabilityPool);
    function cusdToken() external view returns (ICUSDToken);
    function ccvToken() external view returns (ICCVToken);
    function concaveStaking() external view returns (IConcaveStaking);

    function getTroveOwnersCount(address _lpTokenAddress) external view returns (uint);

    function getTroveFromTroveOwnersArray(address _lpTokenAddress, uint _index) external view returns (address);


    function getNominalICR(address _lpTokenAddress, address _borrower) external view returns (uint);
    function getCurrentICR(address _lpTokenAddress, address _borrower, uint _price) external view returns (uint);


    function liquidate(address _lpTokenAddress, address _borrower) external;

    function liquidateTroves(address _lpTokenAddress, uint _n) external;

    function batchLiquidateTroves(address _lpTokenAddress, address[] calldata _troveArray) external;


    function getPendingETHReward(address _lpTokenAddress, address _borrower) external view returns (uint);

    function getPendingCUSDDebtReward(address _lpTokenAddress, address _borrower) external view returns (uint);

    function getEntireDebtAndColl(address _lpTokenAddress, address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingLUSDDebtReward, 
        uint pendingETHReward
    );

    function closeTrove(address _lpTokenAddress, address _borrower) external;

    function removeStake(address _lpTokenAddress, address _borrower) external;

    function applyPendingRewards(address _lpTokenAddress, address _borrower) external;

    function updateTroveRewardSnapshots(address _lpTokenAddress, address _borrower) external;

    function hasPendingRewards(address _lpTokenAddress, address _borrower) external view returns (bool);

    function updateStakeAndTotalStakes(address _lpTokenAddress, address _borrower) external returns (uint);


    function addTroveOwnerToArray(address _lpTokenAddress, address _borrower) external returns (uint index);


    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);
    function getBorrowingFee(uint CUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _CUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _lpTokenAddress, address _borrower) external view returns (uint);
    
    function getTroveStake(address _lpTokenAddress, address _borrower) external view returns (uint);

    function getTroveDebt(address _lpTokenAddress, address _borrower) external view returns (uint);

    function getTroveColl(address _lpTokenAddress, address _borrower) external view returns (uint);

    
    function setTroveStatus(address _lpTokenAddress, address _borrower, uint num) external;

    function increaseTroveColl(address _lpTokenAddress, address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _lpTokenAddress, address _borrower, uint _collDecrease) external returns (uint); 

    function increaseTroveDebt(address _lpTokenAddress, address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseTroveDebt(address _lpTokenAddress, address _borrower, uint _collDecrease) external returns (uint);


    function getTCR(address _lpTokenAddress, uint _price) external view returns (uint);

    function checkRecoveryMode(address _lpTokenAddress, uint _price, uint _CCR) external view returns (bool);
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


interface IPriceFeed {

    // --- Events ---
    // event LastGoodPriceUpdated(uint _lastGoodPrice);

    // --- Function: Calculate the LP token price---
    function fetchPrice() external returns (uint);
	
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./IPriceFeed.sol";

interface IPriceStrategyFactory {

    function register(address _lpTokenAddr, IPriceFeed _priceFeed) external;

    function updateRegister(address _lpTokenAddr, IPriceFeed _priceFeed) external;

    function unRegister(address _lpTokenAddr) external;

    function get(address _lpTokenAddr) external view returns(IPriceFeed);

    function fetchPrice(address _lpTokenAddr) external returns(uint);
	
}