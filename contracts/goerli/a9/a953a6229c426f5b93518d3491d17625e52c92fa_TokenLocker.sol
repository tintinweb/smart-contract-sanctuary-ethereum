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
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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

pragma solidity 0.8.16;

import {IERC20} from "@oz/token/ERC20/IERC20.sol";

interface IERC20MintableBurnable is IERC20 {
    function mint(address from, uint256 quantity) external;
    function burn(address from, uint256 quantity) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

abstract contract IncentiveCurve {
    uint256 internal constant AVG_SECONDS_MONTH = 2628000;

    /**
     * @notice incentivises longer lock times with higher rewards
     * @dev Mapping of coefficient for the staking curve y=x/k*log(x)
     *      - where `x` is the staking time in months
     *      - `k` is a constant 56.0268900276223
     *      - Converges on 1e18
     * @dev do not initialize non-constants in upgradeable contracts, use the initializer below
     */
    uint256[37] public maxRatioArray;

    /**
     * @dev in theory this should be restricted to 'onlyInitializing' but all it will do is set
     *      the same array, so it's not an issue.
     */
    function __IncentiveCurve_init() internal {
        maxRatioArray = [
            1,
            2,
            3,
            4,
            5,
            6,
            83333333333300000, // 6
            105586554548800000, // 7
            128950935744800000, // 8
            153286798191400000, // 9
            178485723463700000, // 10
            204461099502300000, // 11
            231142134539100000, // 12
            258469880674300000, // 13
            286394488282000000, // 14
            314873248847800000, // 15
            343869161986300000, // 16
            373349862059400000, // 17
            403286798191400000, // 18
            433654597035900000, // 19
            464430560048100000, // 20
            495594261536300000, // 21
            527127223437300000, // 22
            559012649336100000, // 23
            591235204823000000, // 24
            623780834516600000, // 25
            656636608405400000, // 26
            689790591861100000, // 27
            723231734933100000, // 28
            756949777475800000, // 29
            790935167376600000, // 30
            825178989697100000, // 31
            859672904965600000, // 32
            894409095191000000, // 33
            929380216424000000, // 34
            964579356905500000, // 35
            1000000000000000000 // 36
        ];
    }

    function getDuration(uint256 months) public pure returns (uint32) {
        return uint32(months * AVG_SECONDS_MONTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {OwnableUpgradeable as Ownable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";

interface IMigrateableEvents {
    event MigratorUpdated(address indexed newMigrator);
    event MigrationEnabledChanged(bool enabled);
    /**
     * @notice should be emitted within the override
     * @param amountDepositMigrated quantity of tokens locked in the contract that were moved
     */
    event Migrated(address indexed account, uint256 amountDepositMigrated);
}

/**
 * @notice a minimal set of state variables and methods to enable users to extract tokens from one contract implementation to another
 *         without relying on upgradeability.
 * @dev override the `migrate` function in the inheriting contract
 */
abstract contract Migrateable is Ownable, IMigrateableEvents {
    /// @notice the contract that will receive tokens during the migration
    address public migrator;

    /// @notice once enabled, users can call the `migrate` function
    bool public migrationEnabled;

    /**
     * @notice when set to 'true' by the owner, activates the migration process and allows early exit of locks
     */
    function setMigrationEnabled(bool _migratonEnabled) external onlyOwner {
        migrationEnabled = _migratonEnabled;
        emit MigrationEnabledChanged(_migratonEnabled);
    }

    /**
     * @notice sets the destination for deposit tokens when the `migrate` function is invoked
     */
    function setMigrator(address _migrator) external onlyOwner {
        migrator = _migrator;
        emit MigratorUpdated(_migrator);
    }

    /**
     * @notice contract must override this to determine the migrate logic
     */
    function migrate() external virtual {
        emit Migrated(msg.sender, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {OwnableUpgradeable as Ownable} from "@oz-upgradeable/access/OwnableUpgradeable.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";
import {IERC20Permit} from "@oz/token/ERC20/extensions/draft-IERC20Permit.sol";
import {SafeERC20} from "@oz/token/ERC20/utils/SafeERC20.sol";
import {IncentiveCurve} from "@governance/IncentiveCurve.sol";
import "@interfaces/IERC20MintableBurnable.sol";
import "./Migrator.sol";

interface ITokenLockerEvents {
    event MinLockAmountChanged(uint192 newLockAmount);
    event WhitelistedChanged(address indexed account, bool indexed whitelisted);
    event Deposited(uint192 amount, uint32 lockDuration, address indexed owner);
    event Withdrawn(uint192 amount, address indexed owner);
    event BoostedToMax(uint192 amount, address indexed owner);
    event IncreasedLock(uint192 amount, uint32 lockDuration, address indexed owner);
    event Ejected(uint192 amount, address indexed owner);
    event EjectBufferUpdated(uint32 newEjectBuffer);
}

contract TokenLocker is IncentiveCurve, ITokenLockerEvents, Ownable, Migrateable {
    using SafeERC20 for IERC20;

    /// ======== Public Variables ========

    /// @notice token locked in the contract in exchange for reward tokens
    IERC20 public depositToken;

    /// @notice the token that will be returned to the user in exchange for depositToken
    IERC20MintableBurnable public veToken;

    /// @notice minimum timestamp for tokens to be locked (i.e. block.timestamp + 6 months)
    uint32 public minLockDuration;

    /// @notice maximum timetamp for tokens to be locked (i.e. block.timestamp + 36 months)
    uint32 public maxLockDuration;

    /// @notice minimum quantity of deposit tokens that must be locked in the contract
    uint192 public minLockAmount;

    /// @notice additional time period after lock has expired after which anyone can remove timelocked tokens on behalf of another user
    uint32 public ejectBuffer;

    /// @notice callable by the admin to allow early release of locked tokens
    bool public emergencyUnlockTriggered;

    struct Lock {
        uint192 amount;
        uint32 lockedAt;
        uint32 lockDuration;
    }

    /// @notice lock details by address
    mapping(address => Lock) public lockOf;

    /// @notice whitelisted addresses can deposit on behalf of other accounts and be sent reward tokens if not EOAs
    mapping(address => bool) public whitelisted;

    /// ======== Gap ========

    /// @dev reserved storage slots for upgrades + inheritance
    uint256[50] private __gap;

    /// ======== Initializer ========

    function initialize(
        IERC20 _depositToken,
        IERC20MintableBurnable _veToken,
        uint32 _minLockDuration,
        uint32 _maxLockDuration,
        uint192 _minLockAmount
    ) public initializer {
        __Ownable_init();
        __IncentiveCurve_init();
        veToken = _veToken;
        depositToken = _depositToken;
        require(_minLockDuration < _maxLockDuration, "Initialze: min>=max");
        minLockDuration = _minLockDuration;
        maxLockDuration = _maxLockDuration;
        minLockAmount = _minLockAmount;
        ejectBuffer = 7 days;
    }

    /// ======== Admin Setters ========

    /**
     * @notice updates the minimum duration in which tokens can be locked
     */
    function setMinLockAmount(uint192 minLockAmount_) external onlyOwner {
        minLockAmount = minLockAmount_;
        emit MinLockAmountChanged(minLockAmount_);
    }

    /**
     * @notice allows a contract address to receieve tokens OR allows depositing on behalf of another user
     * @param _user address of the account to whitelist
     */
    function setWhitelisted(address _user, bool _isWhitelisted) external onlyOwner {
        whitelisted[_user] = _isWhitelisted;
        emit WhitelistedChanged(_user, _isWhitelisted);
    }

    /**
     * @notice if triggered, existing timelocks can be exited before the lockDuration has passed
     */
    function triggerEmergencyUnlock() external onlyOwner {
        require(!emergencyUnlockTriggered, "EU: already triggered");
        emergencyUnlockTriggered = true;
    }

    /**
     * @notice sets the time allowed after a lock expires before anyone can exit a lock on behalf of a user
     */
    function setEjectBuffer(uint32 _buffer) external onlyOwner {
        ejectBuffer = _buffer;
        emit EjectBufferUpdated(_buffer);
    }

    /// ======== Public Functions ========

    /**
     * @notice allows user to exit if their timelock has expired, transferring deposit tokens back to them and burning rewardTokens
     */
    function withdraw() external {
        Lock memory lock = lockOf[_msgSender()];
        require(lock.amount > 0, "Withdraw: empty");
        require(
            block.timestamp > lock.lockedAt + lock.lockDuration || emergencyUnlockTriggered, "Withdraw: lock !expired"
        );

        // we can burn all shares since only one lock exists
        delete lockOf[_msgSender()];
        veToken.burn(_msgSender(), veToken.balanceOf(_msgSender()));
        depositToken.safeTransfer(_msgSender(), lock.amount);

        emit Withdrawn(lock.amount, _msgSender());
    }

    /**
     * @notice Any user can remove another from staking by calling the eject function, after the eject buffer has passed.
     * @dev Other stakers are incentivised to do so to because it gives them a bigger share of the voting and reward weight.
     * @param _lockAccounts array of addresses corresponding to the lockId we want to eject
     */
    function eject(address[] calldata _lockAccounts) external {
        for (uint256 i = 0; i < _lockAccounts.length; i++) {
            address account = _lockAccounts[i];
            Lock memory lock = lockOf[account];

            // skip if lockId is invalid or not expired
            if (lock.amount == 0 || lock.lockedAt + lock.lockDuration + ejectBuffer > uint32(block.timestamp)) {
                continue;
            }

            // remove the lock and exit the position
            delete lockOf[account];
            veToken.burn(account, veToken.balanceOf(_msgSender()));
            depositToken.safeTransfer(account, lock.amount);

            emit Ejected(lock.amount, account);
        }
    }

    /**
     * @notice depositing requires prior approval of this contract to spend the user's depositToken
     *         This method encodes the approval signature into the deposit call, allowing an offchain approval.
     * @param _deadline the latest timestamp the signature is valid
     * @dev params v,r,s are the ECDSA signature slices from signing the EIP-712 Permit message with the user's pk
     */
    function depositByMonthsWithSignature(
        uint192 _amount,
        uint256 _months,
        address _receiver,
        uint256 _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        IERC20Permit(address(depositToken)).permit(msg.sender, address(this), _amount, _deadline, v, r, s);
        depositByMonths(_amount, _months, _receiver);
    }

    /**
     * @notice locks depositTokens into the contract on behalf of a receiver
     * @dev unless whitelisted, the receiver MUST be the caller and an EOA
     * @param _amount the number of tokens to deposit
     * @param _months the number of whole months to deposit for
     * @param _receiver address where reward tokens will be sent
     */
    function depositByMonths(uint192 _amount, uint256 _months, address _receiver) public {
        require(!emergencyUnlockTriggered, "Deposit: emergency unlocked");
        require(_amount >= minLockAmount, "Deposit: too low");
        // only one lock per address
        require(lockOf[_msgSender()].amount == 0, "DBM: Lock exists - use increaseLock");

        // only allow whitelisted contracts or EOAS
        require(tx.origin == _msgSender() || whitelisted[_msgSender()], "DBM: Not EOA or WL");
        // only allow whitelisted addresses to deposit to another address
        require(_msgSender() == _receiver || whitelisted[_msgSender()], "DBM: sender != receiver or WL");

        _deposit(_amount, getDuration(_months), _receiver);
    }

    /**
     * @dev actions the deposit for a numerical duration
     * @param _duration timestamp in seconds to lock for
     */
    function _deposit(uint192 _amount, uint32 _duration, address _receiver) internal {
        uint256 multiplier = getLockMultiplier(_duration);
        uint256 veShares = (_amount * multiplier) / 1e18;

        lockOf[_receiver] = Lock({amount: _amount, lockedAt: uint32(block.timestamp), lockDuration: _duration});

        depositToken.safeTransferFrom(_msgSender(), address(this), _amount);
        veToken.mint(_receiver, veShares);

        emit Deposited(_amount, _duration, _receiver);
    }

    /**
     * @notice depositing requires prior approval of this contract to spend the user's depositToken
     *         This method encodes the approval signature into the deposit call, allowing an offchain approval.
     * @param _deadline the latest timestamp the signature is valid
     * @dev params v,r,s are the ECDSA signature slices from signing the EIP-712 Permit message with the user's pk
     */
    function increaseAmountWithSignature(uint192 _amount, uint256 _deadline, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit(address(depositToken)).permit(msg.sender, address(this), _amount, _deadline, v, r, s);
        increaseAmount(_amount);
    }

    /**
     * @notice takes the user's existing lock and replaces it with a new lock for the maximum duration, starting now.
     * @dev In the event that the new lock duration longer than the old, additional reward tokens are minted
     */
    function boostToMax() external {
        require(!emergencyUnlockTriggered, "BTM: emergency unlocked");
        require(hasLock(_msgSender()), "BTM: Lock not found");

        // cache the lock for calculations
        Lock memory lock = lockOf[_msgSender()];

        // remove the old lock, we will reset
        delete lockOf[_msgSender()];

        // calculate the multiplier and shares on the cached lock
        uint256 multiplier = getLockMultiplier(lock.lockDuration);
        uint256 rewardShares = lock.amount * multiplier / 1e18;
        require(veToken.balanceOf(_msgSender()) == rewardShares, "BTM: Wrong shares number");

        // now get rewards with the max duration
        uint256 newMultiplier = getLockMultiplier(maxLockDuration);
        uint256 newRewardShares = lock.amount * newMultiplier / 1e18;

        // mint the difference
        veToken.mint(_msgSender(), newRewardShares - rewardShares);

        // set a fresh lock with the new params
        lockOf[_msgSender()] =
            Lock({amount: lock.amount, lockedAt: uint32(block.timestamp), lockDuration: maxLockDuration});

        emit BoostedToMax(lock.amount, _msgSender());
    }

    /**
     * @notice adds new tokens to an existing lock. Duration is unchanged.
     * @param _amountNewTokens the number of new deposit tokens to add to the user's lock
     */
    function increaseAmount(uint192 _amountNewTokens) public {
        require(!emergencyUnlockTriggered, "IA: emergency unlocked");
        require(_amountNewTokens > 0, "IA: amount == 0");
        require(hasLock(_msgSender()), "IA: Lock not found");

        _increaseAmount(_amountNewTokens);
    }

    /**
     * @dev Deposit additional tokens for `msg.sender` without modifying the unlock time
     * @param _amountNewTokens how many new tokens to deposit
     * @dev for extremely small increases, rounding can result in no new rewards
     */
    function _increaseAmount(uint192 _amountNewTokens) internal {
        Lock memory lock = lockOf[_msgSender()];
        require(isLockExpired(lock) == false, "IA: Lock Expired");

        // compute the new veTokens to mint based on the current lock duration && increment the lock amount
        lockOf[_msgSender()].amount += _amountNewTokens;
        uint256 newVeShares = uint256(_amountNewTokens) * getLockMultiplier(lock.lockDuration) / 1e18;

        // TODO check rewards make sense
        // uint256 existingShares = veToken.balanceOf(msg.sender);
        // uint256 valueOfLockedTokens = uint256(lock.amount) * getLockMultiplier(lock.lockDuration) / 1e18;
        // require(newVeShares - existingShares == valueOfLockedTokens, "IA: Incorrect Minted");

        // transfer deposit tokens and mint more veTokens
        depositToken.safeTransferFrom(_msgSender(), address(this), _amountNewTokens);
        veToken.mint(_msgSender(), newVeShares);
    }

    /**
     * @notice sets a new number of months to lock deposits for, up to the max lock duration.
     * @param _months months to increase lock by
     */
    function increaseByMonths(uint256 _months) external {
        require(!emergencyUnlockTriggered, "IBM: emergency unlocked");
        require(_months > 0, "IBM: 0 Months");
        require(hasLock(_msgSender()), "IBM: Lock not found");

        _increaseUnlockDuration(getDuration(_months));
    }

    /**
     * @dev checks the passed duration is valid and mints new tokens in compensation.
     */
    function _increaseUnlockDuration(uint32 _duration) internal {
        Lock memory lock = lockOf[_msgSender()];
        require(isLockExpired(lock) == false, "IUT: Lock Expired");

        uint32 newDuration = _duration + lock.lockDuration;
        require(newDuration <= maxLockDuration, "IUT: Duration > Max");

        uint256 oldMultiplier = getLockMultiplier(lock.lockDuration);
        uint256 newMultiplier = getLockMultiplier(newDuration);

        // tokens are non-transferrable so the user must this many in their account
        uint256 veShares = (lock.amount * oldMultiplier) / 1e18;
        require(veToken.balanceOf(_msgSender()) == veShares, "IL: Wrong veToken qty");

        uint256 newVeShares = uint256(lock.amount * newMultiplier) / 1e18;

        // Restart the lock by overriding
        lockOf[_msgSender()].lockDuration = newDuration;

        // send the user the difference in tokens
        veToken.mint(_msgSender(), newVeShares - veShares);
    }

    /// ======== Getters ========

    /**
     * @notice checks if the passed account has an existing timelock
     * @dev depositByMonths should only be called if this returns false, else use increaseLock
     */
    function hasLock(address _account) public view returns (bool) {
        return lockOf[_account].amount > 0;
    }

    /**
     * @notice fetches the reward token multiplier for a timelock duration
     * @param _duration in seconds of the timelock, will be converted to the nearest whole month
     * @return multiplier the %age (0 - 100%) of veToken per depositToken earned for a given duration
     */
    function getLockMultiplier(uint32 _duration) public view returns (uint256 multiplier) {
        require(_duration >= minLockDuration && _duration <= maxLockDuration, "GML: Duration incorrect");
        uint256 month = uint256(_duration) / AVG_SECONDS_MONTH;
        multiplier = maxRatioArray[month];
        return multiplier;
    }

    /**
     * @return if current timestamp has passed the lock expiry date
     */
    function isLockExpired(Lock memory lock) public view returns (bool) {
        // upcasting is safer than downcasting
        return uint256(lock.lockedAt + lock.lockDuration) < block.timestamp;
    }

    /**
     * @notice checks if it's possible to exit a lock on behalf of another user
     * @param _account to check locks for
     * @dev there is an additional `ejectBuffer` that must have passed beyond the lockDuration before ejection is possible
     */
    function canEject(address _account) external view returns (bool) {
        Lock memory lock = lockOf[_account];

        // cannot eject non existing locks
        if (lock.amount == 0) {
            return false;
        }
        return lock.lockedAt + lock.lockDuration + ejectBuffer <= uint32(block.timestamp);
    }

    /**
     * @notice user can to transfer funds to a migrator contract once migration is enabled
     * @dev the migrator contract must handle the reinstantiation of locks
     */
    function migrate() external override {
        require(migrationEnabled, "TokenLocker: !migrationEnabled");
        Lock memory lock = lockOf[msg.sender];
        require(lock.amount > 0, "tokenLocker: nothing to migrate");
        delete lockOf[msg.sender];
        veToken.burn(msg.sender, veToken.balanceOf(_msgSender()));
        depositToken.safeTransfer(migrator, lock.amount);
        emit Migrated(msg.sender, lock.amount);
    }
}