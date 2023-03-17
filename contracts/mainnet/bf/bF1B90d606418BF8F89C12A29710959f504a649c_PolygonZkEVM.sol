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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IBasePolygonZkEVMGlobalExitRoot {
    /**
     * @dev Thrown when the caller is not the allowed contracts
     */
    error OnlyAllowedContracts();

    function updateExitRoot(bytes32 newRollupExitRoot) external;

    function globalExitRootMap(
        bytes32 globalExitRootNum
    ) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IPolygonZkEVMBridge {
    /**
     * @dev Thrown when sender is not the PolygonZkEVM address
     */
    error OnlyPolygonZkEVM();

    /**
     * @dev Thrown when the destination network is invalid
     */
    error DestinationNetworkInvalid();

    /**
     * @dev Thrown when the amount does not match msg.value
     */
    error AmountDoesNotMatchMsgValue();

    /**
     * @dev Thrown when user is bridging tokens and is also sending a value
     */
    error MsgValueNotZero();

    /**
     * @dev Thrown when the Ether transfer on claimAsset fails
     */
    error EtherTransferFailed();

    /**
     * @dev Thrown when the message transaction on claimMessage fails
     */
    error MessageFailed();

    /**
     * @dev Thrown when the global exit root does not exist
     */
    error GlobalExitRootInvalid();

    /**
     * @dev Thrown when the smt proof does not match
     */
    error InvalidSmtProof();

    /**
     * @dev Thrown when an index is already claimed
     */
    error AlreadyClaimed();

    /**
     * @dev Thrown when the owner of permit does not match the sender
     */
    error NotValidOwner();

    /**
     * @dev Thrown when the spender of the permit does not match this contract address
     */
    error NotValidSpender();

    /**
     * @dev Thrown when the amount of the permit does not match
     */
    error NotValidAmount();

    /**
     * @dev Thrown when the permit data contains an invalid signature
     */
    error NotValidSignature();

    function bridgeAsset(
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        address token,
        bool forceUpdateGlobalExitRoot,
        bytes calldata permitData
    ) external payable;

    function bridgeMessage(
        uint32 destinationNetwork,
        address destinationAddress,
        bool forceUpdateGlobalExitRoot,
        bytes calldata metadata
    ) external payable;

    function claimAsset(
        bytes32[32] calldata smtProof,
        uint32 index,
        bytes32 mainnetExitRoot,
        bytes32 rollupExitRoot,
        uint32 originNetwork,
        address originTokenAddress,
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external;

    function claimMessage(
        bytes32[32] calldata smtProof,
        uint32 index,
        bytes32 mainnetExitRoot,
        bytes32 rollupExitRoot,
        uint32 originNetwork,
        address originAddress,
        uint32 destinationNetwork,
        address destinationAddress,
        uint256 amount,
        bytes calldata metadata
    ) external;

    function updateGlobalExitRoot() external;

    function activateEmergencyState() external;

    function deactivateEmergencyState() external;
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

interface IPolygonZkEVMErrors {
    /**
     * @dev Thrown when the pending state timeout exceeds the _HALT_AGGREGATION_TIMEOUT
     */
    error PendingStateTimeoutExceedHaltAggregationTimeout();

    /**
     * @dev Thrown when the trusted aggregator timeout exceeds the _HALT_AGGREGATION_TIMEOUT
     */
    error TrustedAggregatorTimeoutExceedHaltAggregationTimeout();

    /**
     * @dev Thrown when the caller is not the admin
     */
    error OnlyAdmin();

    /**
     * @dev Thrown when the caller is not the trusted sequencer
     */
    error OnlyTrustedSequencer();

    /**
     * @dev Thrown when the caller is not the trusted aggregator
     */
    error OnlyTrustedAggregator();

    /**
     * @dev Thrown when attempting to sequence 0 batches
     */
    error SequenceZeroBatches();

    /**
     * @dev Thrown when attempting to sequence or verify more batches than _MAX_VERIFY_BATCHES
     */
    error ExceedMaxVerifyBatches();

    /**
     * @dev Thrown when the forced data does not match
     */
    error ForcedDataDoesNotMatch();

    /**
     * @dev Thrown when the sequenced timestamp is below the forced minimum timestamp
     */
    error SequencedTimestampBelowForcedTimestamp();

    /**
     * @dev Thrown when a global exit root is not zero and does not exist
     */
    error GlobalExitRootNotExist();

    /**
     * @dev Thrown when transactions array length is above _MAX_TRANSACTIONS_BYTE_LENGTH.
     */
    error TransactionsLengthAboveMax();

    /**
     * @dev Thrown when a sequenced timestamp is not inside a correct range.
     */
    error SequencedTimestampInvalid();

    /**
     * @dev Thrown when there are more sequenced force batches than were actually submitted, should be unreachable
     */
    error ForceBatchesOverflow();

    /**
     * @dev Thrown when there are more sequenced force batches than were actually submitted
     */
    error TrustedAggregatorTimeoutNotExpired();

    /**
     * @dev Thrown when attempting to access a pending state that does not exist
     */
    error PendingStateDoesNotExist();

    /**
     * @dev Thrown when the init num batch does not match with the one in the pending state
     */
    error InitNumBatchDoesNotMatchPendingState();

    /**
     * @dev Thrown when the old state root of a certain batch does not exist
     */
    error OldStateRootDoesNotExist();

    /**
     * @dev Thrown when the init verification batch is above the last verification batch
     */
    error InitNumBatchAboveLastVerifiedBatch();

    /**
     * @dev Thrown when the final verification batch is below or equal the last verification batch
     */
    error FinalNumBatchBelowLastVerifiedBatch();

    /**
     * @dev Thrown when the zkproof is not valid
     */
    error InvalidProof();

    /**
     * @dev Thrown when attempting to consolidate a pending state not yet consolidable
     */
    error PendingStateNotConsolidable();

    /**
     * @dev Thrown when attempting to consolidate a pending state that is already consolidated or does not exist
     */
    error PendingStateInvalid();

    /**
     * @dev Thrown when the matic amount is below the necessary matic fee
     */
    error NotEnoughMaticAmount();

    /**
     * @dev Thrown when attempting to sequence a force batch using sequenceForceBatches and the
     * force timeout did not expire
     */
    error ForceBatchTimeoutNotExpired();

    /**
     * @dev Thrown when attempting to set a new trusted aggregator timeout equal or bigger than current one
     */
    error NewTrustedAggregatorTimeoutMustBeLower();

    /**
     * @dev Thrown when attempting to set a new pending state timeout equal or bigger than current one
     */
    error NewPendingStateTimeoutMustBeLower();

    /**
     * @dev Thrown when attempting to set a new multiplier batch fee in a invalid range of values
     */
    error InvalidRangeMultiplierBatchFee();

    /**
     * @dev Thrown when attempting to set a batch time target in an invalid range of values
     */
    error InvalidRangeBatchTimeTarget();

    /**
     * @dev Thrown when attempting to set a force batch timeout in an invalid range of values
     */
    error InvalidRangeForceBatchTimeout();

    /**
     * @dev Thrown when the caller is not the pending admin
     */
    error OnlyPendingAdmin();

    /**
     * @dev Thrown when the final pending state num is not in a valid range
     */
    error FinalPendingStateNumInvalid();

    /**
     * @dev Thrown when the final num batch does not match with the one in the pending state
     */
    error FinalNumBatchDoesNotMatchPendingState();

    /**
     * @dev Thrown when the stored root matches the new root proving a different state
     */
    error StoredRootMustBeDifferentThanNewRoot();

    /**
     * @dev Thrown when the batch is already verified when attempting to activate the emergency state
     */
    error BatchAlreadyVerified();

    /**
     * @dev Thrown when the batch is not sequenced or not at the end of a sequence when attempting to activate the emergency state
     */
    error BatchNotSequencedOrNotSequenceEnd();

    /**
     * @dev Thrown when the halt timeout is not expired when attempting to activate the emergency state
     */
    error HaltTimeoutNotExpired();

    /**
     * @dev Thrown when the old accumulate input hash does not exist
     */
    error OldAccInputHashDoesNotExist();

    /**
     * @dev Thrown when the new accumulate input hash does not exist
     */
    error NewAccInputHashDoesNotExist();

    /**
     * @dev Thrown when the new state root is not inside prime
     */
    error NewStateRootNotInsidePrime();

    /**
     * @dev Thrown when force batch is not allowed
     */
    error ForceBatchNotAllowed();

    /**
     * @dev Thrown when try to activate force batches when they are already active
     */
    error ForceBatchesAlreadyActive();
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;
import "./IBasePolygonZkEVMGlobalExitRoot.sol";

interface IPolygonZkEVMGlobalExitRoot is IBasePolygonZkEVMGlobalExitRoot {
    function getLastGlobalExitRoot() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

/**
 * @dev Define interface verifier
 */
interface IVerifierRollup {
    function verifyProof(
        bytes memory proof, 
        uint256[1] memory pubSignals
    ) external view returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.17;

/**
 * @dev Contract helper responsible to manage the emergency state
 */
contract EmergencyManager {
    /**
     * @dev Thrown when emergency state is active, and the function requires otherwise
     */
    error OnlyNotEmergencyState();

    /**
     * @dev Thrown when emergency state is not active, and the function requires otherwise
     */
    error OnlyEmergencyState();

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     */
    uint256[10] private _gap;

    // Indicates whether the emergency state is active or not
    bool public isEmergencyState;

    /**
     * @dev Emitted when emergency state is activated
     */
    event EmergencyStateActivated();

    /**
     * @dev Emitted when emergency state is deactivated
     */
    event EmergencyStateDeactivated();

    /**
     * @notice Only allows a function to be callable if emergency state is unactive
     */
    modifier ifNotEmergencyState() {
        if (isEmergencyState) {
            revert OnlyNotEmergencyState();
        }
        _;
    }

    /**
     * @notice Only allows a function to be callable if emergency state is active
     */
    modifier ifEmergencyState() {
        if (!isEmergencyState) {
            revert OnlyEmergencyState();
        }
        _;
    }

    /**
     * @notice Activate emergency state
     */
    function _activateEmergencyState() internal virtual ifNotEmergencyState {
        isEmergencyState = true;
        emit EmergencyStateActivated();
    }

    /**
     * @notice Deactivate emergency state
     */
    function _deactivateEmergencyState() internal virtual ifEmergencyState {
        isEmergencyState = false;
        emit EmergencyStateDeactivated();
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interfaces/IVerifierRollup.sol";
import "./interfaces/IPolygonZkEVMGlobalExitRoot.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./interfaces/IPolygonZkEVMBridge.sol";
import "./lib/EmergencyManager.sol";
import "./interfaces/IPolygonZkEVMErrors.sol";

/**
 * Contract responsible for managing the states and the updates of L2 network.
 * There will be a trusted sequencer, which is able to send transactions.
 * Any user can force some transaction and the sequencer will have a timeout to add them in the queue.
 * The sequenced state is deterministic and can be precalculated before it's actually verified by a zkProof.
 * The aggregators will be able to verify the sequenced state with zkProofs and therefore make available the withdrawals from L2 network.
 * To enter and exit of the L2 network will be used a PolygonZkEVMBridge smart contract that will be deployed in both networks.
 */
contract PolygonZkEVM is
    OwnableUpgradeable,
    EmergencyManager,
    IPolygonZkEVMErrors
{
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Struct which will be used to call sequenceBatches
     * @param transactions L2 ethereum transactions EIP-155 or pre-EIP-155 with signature:
     * EIP-155: rlp(nonce, gasprice, gasLimit, to, value, data, chainid, 0, 0,) || v || r || s
     * pre-EIP-155: rlp(nonce, gasprice, gasLimit, to, value, data) || v || r || s
     * @param globalExitRoot Global exit root of the batch
     * @param timestamp Sequenced timestamp of the batch
     * @param minForcedTimestamp Minimum timestamp of the force batch data, empty when non forced batch
     */
    struct BatchData {
        bytes transactions;
        bytes32 globalExitRoot;
        uint64 timestamp;
        uint64 minForcedTimestamp;
    }

    /**
     * @notice Struct which will be used to call sequenceForceBatches
     * @param transactions L2 ethereum transactions EIP-155 or pre-EIP-155 with signature:
     * EIP-155: rlp(nonce, gasprice, gasLimit, to, value, data, chainid, 0, 0,) || v || r || s
     * pre-EIP-155: rlp(nonce, gasprice, gasLimit, to, value, data) || v || r || s
     * @param globalExitRoot Global exit root of the batch
     * @param minForcedTimestamp Indicates the minimum sequenced timestamp of the batch
     */
    struct ForcedBatchData {
        bytes transactions;
        bytes32 globalExitRoot;
        uint64 minForcedTimestamp;
    }

    /**
     * @notice Struct which will be stored for every batch sequence
     * @param accInputHash Hash chain that contains all the information to process a batch:
     *  keccak256(bytes32 oldAccInputHash, keccak256(bytes transactions), bytes32 globalExitRoot, uint64 timestamp, address seqAddress)
     * @param sequencedTimestamp Sequenced timestamp
     * @param previousLastBatchSequenced Previous last batch sequenced before the current one, this is used to properly calculate the fees
     */
    struct SequencedBatchData {
        bytes32 accInputHash;
        uint64 sequencedTimestamp;
        uint64 previousLastBatchSequenced;
    }

    /**
     * @notice Struct to store the pending states
     * Pending state will be an intermediary state, that after a timeout can be consolidated, which means that will be added
     * to the state root mapping, and the global exit root will be updated
     * This is a protection mechanism against soundness attacks, that will be turned off in the future
     * @param timestamp Timestamp where the pending state is added to the queue
     * @param lastVerifiedBatch Last batch verified batch of this pending state
     * @param exitRoot Pending exit root
     * @param stateRoot Pending state root
     */
    struct PendingState {
        uint64 timestamp;
        uint64 lastVerifiedBatch;
        bytes32 exitRoot;
        bytes32 stateRoot;
    }

    /**
     * @notice Struct to call initialize, this saves gas because pack the parameters and avoid stack too deep errors.
     * @param admin Admin address
     * @param trustedSequencer Trusted sequencer address
     * @param pendingStateTimeout Pending state timeout
     * @param trustedAggregator Trusted aggregator
     * @param trustedAggregatorTimeout Trusted aggregator timeout
     */
    struct InitializePackedParameters {
        address admin;
        address trustedSequencer;
        uint64 pendingStateTimeout;
        address trustedAggregator;
        uint64 trustedAggregatorTimeout;
    }

    // Modulus zkSNARK
    uint256 internal constant _RFIELD =
        21888242871839275222246405745257275088548364400416034343698204186575808495617;

    // Max transactions bytes that can be added in a single batch
    // Max keccaks circuit = (2**23 / 155286) * 44 = 2376
    // Bytes per keccak = 136
    // Minimum Static keccaks batch = 2
    // Max bytes allowed = (2376 - 2) * 136 = 322864 bytes - 1 byte padding
    // Rounded to 300000 bytes
    uint256 internal constant _MAX_TRANSACTIONS_BYTE_LENGTH = 300000;

    // If a sequenced batch exceeds this timeout without being verified, the contract enters in emergency mode
    uint64 internal constant _HALT_AGGREGATION_TIMEOUT = 1 weeks;

    // Maximum batches that can be verified in one call. It depends on our current metrics
    // This should be a protection against someone that tries to generate huge chunk of invalid batches, and we can't prove otherwise before the pending timeout expires
    uint64 internal constant _MAX_VERIFY_BATCHES = 1000;

    // Max batch multiplier per verification
    uint256 internal constant _MAX_BATCH_MULTIPLIER = 12;

    // Max batch fee value
    uint256 internal constant _MAX_BATCH_FEE = 1000 ether;

    // Min value batch fee
    uint256 internal constant _MIN_BATCH_FEE = 1 gwei;

    // Goldilocks prime field
    uint256 internal constant _GOLDILOCKS_PRIME_FIELD = 0xFFFFFFFF00000001; // 2 ** 64 - 2 ** 32 + 1

    // Max uint64
    uint256 internal constant _MAX_UINT_64 = type(uint64).max; // 0xFFFFFFFFFFFFFFFF

    // MATIC token address
    IERC20Upgradeable public immutable matic;

    // Rollup verifier interface
    IVerifierRollup public immutable rollupVerifier;

    // Global Exit Root interface
    IPolygonZkEVMGlobalExitRoot public immutable globalExitRootManager;

    // PolygonZkEVM Bridge Address
    IPolygonZkEVMBridge public immutable bridgeAddress;

    // L2 chain identifier
    uint64 public immutable chainID;

    // L2 chain identifier
    uint64 public immutable forkID;

    // Time target of the verification of a batch
    // Adaptatly the batchFee will be updated to achieve this target
    uint64 public verifyBatchTimeTarget;

    // Batch fee multiplier with 3 decimals that goes from 1000 - 1023
    uint16 public multiplierBatchFee;

    // Trusted sequencer address
    address public trustedSequencer;

    // Current matic fee per batch sequenced
    uint256 public batchFee;

    // Queue of forced batches with their associated data
    // ForceBatchNum --> hashedForcedBatchData
    // hashedForcedBatchData: hash containing the necessary information to force a batch:
    // keccak256(keccak256(bytes transactions), bytes32 globalExitRoot, unint64 minForcedTimestamp)
    mapping(uint64 => bytes32) public forcedBatches;

    // Queue of batches that defines the virtual state
    // SequenceBatchNum --> SequencedBatchData
    mapping(uint64 => SequencedBatchData) public sequencedBatches;

    // Last sequenced timestamp
    uint64 public lastTimestamp;

    // Last batch sent by the sequencers
    uint64 public lastBatchSequenced;

    // Last forced batch included in the sequence
    uint64 public lastForceBatchSequenced;

    // Last forced batch
    uint64 public lastForceBatch;

    // Last batch verified by the aggregators
    uint64 public lastVerifiedBatch;

    // Trusted aggregator address
    address public trustedAggregator;

    // State root mapping
    // BatchNum --> state root
    mapping(uint64 => bytes32) public batchNumToStateRoot;

    // Trusted sequencer URL
    string public trustedSequencerURL;

    // L2 network name
    string public networkName;

    // Pending state mapping
    // pendingStateNumber --> PendingState
    mapping(uint256 => PendingState) public pendingStateTransitions;

    // Last pending state
    uint64 public lastPendingState;

    // Last pending state consolidated
    uint64 public lastPendingStateConsolidated;

    // Once a pending state exceeds this timeout it can be consolidated
    uint64 public pendingStateTimeout;

    // Trusted aggregator timeout, if a sequence is not verified in this time frame,
    // everyone can verify that sequence
    uint64 public trustedAggregatorTimeout;

    // Address that will be able to adjust contract parameters or stop the emergency state
    address public admin;

    // This account will be able to accept the admin role
    address public pendingAdmin;

    // Force batch timeout
    uint64 public forceBatchTimeout;

    // Indicates if forced batches are disallowed
    bool public isForcedBatchDisallowed;

    /**
     * @dev Emitted when the trusted sequencer sends a new batch of transactions
     */
    event SequenceBatches(uint64 indexed numBatch);

    /**
     * @dev Emitted when a batch is forced
     */
    event ForceBatch(
        uint64 indexed forceBatchNum,
        bytes32 lastGlobalExitRoot,
        address sequencer,
        bytes transactions
    );

    /**
     * @dev Emitted when forced batches are sequenced by not the trusted sequencer
     */
    event SequenceForceBatches(uint64 indexed numBatch);

    /**
     * @dev Emitted when a aggregator verifies batches
     */
    event VerifyBatches(
        uint64 indexed numBatch,
        bytes32 stateRoot,
        address indexed aggregator
    );

    /**
     * @dev Emitted when the trusted aggregator verifies batches
     */
    event VerifyBatchesTrustedAggregator(
        uint64 indexed numBatch,
        bytes32 stateRoot,
        address indexed aggregator
    );

    /**
     * @dev Emitted when pending state is consolidated
     */
    event ConsolidatePendingState(
        uint64 indexed numBatch,
        bytes32 stateRoot,
        uint64 indexed pendingStateNum
    );

    /**
     * @dev Emitted when the admin updates the trusted sequencer address
     */
    event SetTrustedSequencer(address newTrustedSequencer);

    /**
     * @dev Emitted when the admin updates the sequencer URL
     */
    event SetTrustedSequencerURL(string newTrustedSequencerURL);

    /**
     * @dev Emitted when the admin updates the trusted aggregator timeout
     */
    event SetTrustedAggregatorTimeout(uint64 newTrustedAggregatorTimeout);

    /**
     * @dev Emitted when the admin updates the pending state timeout
     */
    event SetPendingStateTimeout(uint64 newPendingStateTimeout);

    /**
     * @dev Emitted when the admin updates the trusted aggregator address
     */
    event SetTrustedAggregator(address newTrustedAggregator);

    /**
     * @dev Emitted when the admin updates the multiplier batch fee
     */
    event SetMultiplierBatchFee(uint16 newMultiplierBatchFee);

    /**
     * @dev Emitted when the admin updates the verify batch timeout
     */
    event SetVerifyBatchTimeTarget(uint64 newVerifyBatchTimeTarget);

    /**
     * @dev Emitted when the admin update the force batch timeout
     */
    event SetForceBatchTimeout(uint64 newforceBatchTimeout);

    /**
     * @dev Emitted when activate force batches
     */
    event ActivateForceBatches();

    /**
     * @dev Emitted when the admin starts the two-step transfer role setting a new pending admin
     */
    event TransferAdminRole(address newPendingAdmin);

    /**
     * @dev Emitted when the pending admin accepts the admin role
     */
    event AcceptAdminRole(address newAdmin);

    /**
     * @dev Emitted when is proved a different state given the same batches
     */
    event ProveNonDeterministicPendingState(
        bytes32 storedStateRoot,
        bytes32 provedStateRoot
    );

    /**
     * @dev Emitted when the trusted aggregator overrides pending state
     */
    event OverridePendingState(
        uint64 indexed numBatch,
        bytes32 stateRoot,
        address indexed aggregator
    );

    /**
     * @dev Emitted everytime the forkID is updated, this includes the first initialization of the contract
     * This event is intended to be emitted for every upgrade of the contract with relevant changes for the nodes
     */
    event UpdateZkEVMVersion(uint64 numBatch, uint64 forkID, string version);

    /**
     * @param _globalExitRootManager Global exit root manager address
     * @param _matic MATIC token address
     * @param _rollupVerifier Rollup verifier address
     * @param _bridgeAddress Bridge address
     * @param _chainID L2 chainID
     * @param _forkID Fork Id
     */
    constructor(
        IPolygonZkEVMGlobalExitRoot _globalExitRootManager,
        IERC20Upgradeable _matic,
        IVerifierRollup _rollupVerifier,
        IPolygonZkEVMBridge _bridgeAddress,
        uint64 _chainID,
        uint64 _forkID
    ) {
        globalExitRootManager = _globalExitRootManager;
        matic = _matic;
        rollupVerifier = _rollupVerifier;
        bridgeAddress = _bridgeAddress;
        chainID = _chainID;
        forkID = _forkID;
    }

    /**
     * @param initializePackedParameters Struct to save gas and avoid stack too deep errors
     * @param genesisRoot Rollup genesis root
     * @param _trustedSequencerURL Trusted sequencer URL
     * @param _networkName L2 network name
     */
    function initialize(
        InitializePackedParameters calldata initializePackedParameters,
        bytes32 genesisRoot,
        string memory _trustedSequencerURL,
        string memory _networkName,
        string calldata _version
    ) external initializer {
        admin = initializePackedParameters.admin;
        trustedSequencer = initializePackedParameters.trustedSequencer;
        trustedAggregator = initializePackedParameters.trustedAggregator;
        batchNumToStateRoot[0] = genesisRoot;
        trustedSequencerURL = _trustedSequencerURL;
        networkName = _networkName;

        // Check initialize parameters
        if (
            initializePackedParameters.pendingStateTimeout >
            _HALT_AGGREGATION_TIMEOUT
        ) {
            revert PendingStateTimeoutExceedHaltAggregationTimeout();
        }
        pendingStateTimeout = initializePackedParameters.pendingStateTimeout;

        if (
            initializePackedParameters.trustedAggregatorTimeout >
            _HALT_AGGREGATION_TIMEOUT
        ) {
            revert TrustedAggregatorTimeoutExceedHaltAggregationTimeout();
        }

        trustedAggregatorTimeout = initializePackedParameters
            .trustedAggregatorTimeout;

        // Constant deployment variables
        batchFee = 0.1 ether; // 0.1 Matic
        verifyBatchTimeTarget = 30 minutes;
        multiplierBatchFee = 1002;
        forceBatchTimeout = 5 days;
        isForcedBatchDisallowed = true;

        // Initialize OZ contracts
        __Ownable_init_unchained();

        // emit version event
        emit UpdateZkEVMVersion(0, forkID, _version);
    }

    modifier onlyAdmin() {
        if (admin != msg.sender) {
            revert OnlyAdmin();
        }
        _;
    }

    modifier onlyTrustedSequencer() {
        if (trustedSequencer != msg.sender) {
            revert OnlyTrustedSequencer();
        }
        _;
    }

    modifier onlyTrustedAggregator() {
        if (trustedAggregator != msg.sender) {
            revert OnlyTrustedAggregator();
        }
        _;
    }

    modifier isForceBatchAllowed() {
        if (isForcedBatchDisallowed) {
            revert ForceBatchNotAllowed();
        }
        _;
    }

    /////////////////////////////////////
    // Sequence/Verify batches functions
    ////////////////////////////////////

    /**
     * @notice Allows a sequencer to send multiple batches
     * @param batches Struct array which holds the necessary data to append new batches to the sequence
     * @param l2Coinbase Address that will receive the fees from L2
     */
    function sequenceBatches(
        BatchData[] calldata batches,
        address l2Coinbase
    ) external ifNotEmergencyState onlyTrustedSequencer {
        uint256 batchesNum = batches.length;
        if (batchesNum == 0) {
            revert SequenceZeroBatches();
        }

        if (batchesNum > _MAX_VERIFY_BATCHES) {
            revert ExceedMaxVerifyBatches();
        }

        // Store storage variables in memory, to save gas, because will be overrided multiple times
        uint64 currentTimestamp = lastTimestamp;
        uint64 currentBatchSequenced = lastBatchSequenced;
        uint64 currentLastForceBatchSequenced = lastForceBatchSequenced;
        bytes32 currentAccInputHash = sequencedBatches[currentBatchSequenced]
            .accInputHash;

        // Store in a temporal variable, for avoid access again the storage slot
        uint64 initLastForceBatchSequenced = currentLastForceBatchSequenced;

        for (uint256 i = 0; i < batchesNum; i++) {
            // Load current sequence
            BatchData memory currentBatch = batches[i];

            // Store the current transactions hash since can be used more than once for gas saving
            bytes32 currentTransactionsHash = keccak256(
                currentBatch.transactions
            );

            // Check if it's a forced batch
            if (currentBatch.minForcedTimestamp > 0) {
                currentLastForceBatchSequenced++;

                // Check forced data matches
                bytes32 hashedForcedBatchData = keccak256(
                    abi.encodePacked(
                        currentTransactionsHash,
                        currentBatch.globalExitRoot,
                        currentBatch.minForcedTimestamp
                    )
                );

                if (
                    hashedForcedBatchData !=
                    forcedBatches[currentLastForceBatchSequenced]
                ) {
                    revert ForcedDataDoesNotMatch();
                }

                // Delete forceBatch data since won't be used anymore
                delete forcedBatches[currentLastForceBatchSequenced];

                // Check timestamp is bigger than min timestamp
                if (currentBatch.timestamp < currentBatch.minForcedTimestamp) {
                    revert SequencedTimestampBelowForcedTimestamp();
                }
            } else {
                // Check global exit root exists with proper batch length. These checks are already done in the forceBatches call
                // Note that the sequencer can skip setting a global exit root putting zeros
                if (
                    currentBatch.globalExitRoot != bytes32(0) &&
                    globalExitRootManager.globalExitRootMap(
                        currentBatch.globalExitRoot
                    ) ==
                    0
                ) {
                    revert GlobalExitRootNotExist();
                }

                if (
                    currentBatch.transactions.length >
                    _MAX_TRANSACTIONS_BYTE_LENGTH
                ) {
                    revert TransactionsLengthAboveMax();
                }
            }

            // Check Batch timestamps are correct
            if (
                currentBatch.timestamp < currentTimestamp ||
                currentBatch.timestamp > block.timestamp
            ) {
                revert SequencedTimestampInvalid();
            }

            // Calculate next accumulated input hash
            currentAccInputHash = keccak256(
                abi.encodePacked(
                    currentAccInputHash,
                    currentTransactionsHash,
                    currentBatch.globalExitRoot,
                    currentBatch.timestamp,
                    l2Coinbase
                )
            );

            // Update timestamp
            currentTimestamp = currentBatch.timestamp;
        }
        // Update currentBatchSequenced
        currentBatchSequenced += uint64(batchesNum);

        // Sanity check, should be unreachable
        if (currentLastForceBatchSequenced > lastForceBatch) {
            revert ForceBatchesOverflow();
        }

        uint256 nonForcedBatchesSequenced = batchesNum -
            (currentLastForceBatchSequenced - initLastForceBatchSequenced);

        // Update sequencedBatches mapping
        sequencedBatches[currentBatchSequenced] = SequencedBatchData({
            accInputHash: currentAccInputHash,
            sequencedTimestamp: uint64(block.timestamp),
            previousLastBatchSequenced: lastBatchSequenced
        });

        // Store back the storage variables
        lastTimestamp = currentTimestamp;
        lastBatchSequenced = currentBatchSequenced;

        if (currentLastForceBatchSequenced != initLastForceBatchSequenced)
            lastForceBatchSequenced = currentLastForceBatchSequenced;

        // Pay collateral for every non-forced batch submitted
        matic.safeTransferFrom(
            msg.sender,
            address(this),
            getCurrentBatchFee() * nonForcedBatchesSequenced
        );

        // Consolidate pending state if possible
        _tryConsolidatePendingState();

        // Update global exit root if there are new deposits
        bridgeAddress.updateGlobalExitRoot();

        emit SequenceBatches(currentBatchSequenced);
    }

    /**
     * @notice Allows an aggregator to verify multiple batches
     * @param pendingStateNum Init pending state, 0 if consolidated state is used
     * @param initNumBatch Batch which the aggregator starts the verification
     * @param finalNewBatch Last batch aggregator intends to verify
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param newStateRoot New State root once the batch is processed
     * @param proof fflonk proof
     */
    function verifyBatches(
        uint64 pendingStateNum,
        uint64 initNumBatch,
        uint64 finalNewBatch,
        bytes32 newLocalExitRoot,
        bytes32 newStateRoot,
        bytes calldata proof
    ) external ifNotEmergencyState {
        // Check if the trusted aggregator timeout expired,
        // Note that the sequencedBatches struct must exists for this finalNewBatch, if not newAccInputHash will be 0
        if (
            sequencedBatches[finalNewBatch].sequencedTimestamp +
                trustedAggregatorTimeout >
            block.timestamp
        ) {
            revert TrustedAggregatorTimeoutNotExpired();
        }

        if (finalNewBatch - initNumBatch > _MAX_VERIFY_BATCHES) {
            revert ExceedMaxVerifyBatches();
        }

        _verifyAndRewardBatches(
            pendingStateNum,
            initNumBatch,
            finalNewBatch,
            newLocalExitRoot,
            newStateRoot,
            proof
        );

        // Update batch fees
        _updateBatchFee(finalNewBatch);

        if (pendingStateTimeout == 0) {
            // Consolidate state
            lastVerifiedBatch = finalNewBatch;
            batchNumToStateRoot[finalNewBatch] = newStateRoot;

            // Clean pending state if any
            if (lastPendingState > 0) {
                lastPendingState = 0;
                lastPendingStateConsolidated = 0;
            }

            // Interact with globalExitRootManager
            globalExitRootManager.updateExitRoot(newLocalExitRoot);
        } else {
            // Consolidate pending state if possible
            _tryConsolidatePendingState();

            // Update pending state
            lastPendingState++;
            pendingStateTransitions[lastPendingState] = PendingState({
                timestamp: uint64(block.timestamp),
                lastVerifiedBatch: finalNewBatch,
                exitRoot: newLocalExitRoot,
                stateRoot: newStateRoot
            });
        }

        emit VerifyBatches(finalNewBatch, newStateRoot, msg.sender);
    }

    /**
     * @notice Allows an aggregator to verify multiple batches
     * @param pendingStateNum Init pending state, 0 if consolidated state is used
     * @param initNumBatch Batch which the aggregator starts the verification
     * @param finalNewBatch Last batch aggregator intends to verify
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param newStateRoot New State root once the batch is processed
     * @param proof fflonk proof
     */
    function verifyBatchesTrustedAggregator(
        uint64 pendingStateNum,
        uint64 initNumBatch,
        uint64 finalNewBatch,
        bytes32 newLocalExitRoot,
        bytes32 newStateRoot,
        bytes calldata proof
    ) external onlyTrustedAggregator {
        _verifyAndRewardBatches(
            pendingStateNum,
            initNumBatch,
            finalNewBatch,
            newLocalExitRoot,
            newStateRoot,
            proof
        );

        // Consolidate state
        lastVerifiedBatch = finalNewBatch;
        batchNumToStateRoot[finalNewBatch] = newStateRoot;

        // Clean pending state if any
        if (lastPendingState > 0) {
            lastPendingState = 0;
            lastPendingStateConsolidated = 0;
        }

        // Interact with globalExitRootManager
        globalExitRootManager.updateExitRoot(newLocalExitRoot);

        emit VerifyBatchesTrustedAggregator(
            finalNewBatch,
            newStateRoot,
            msg.sender
        );
    }

    /**
     * @notice Verify and reward batches internal function
     * @param pendingStateNum Init pending state, 0 if consolidated state is used
     * @param initNumBatch Batch which the aggregator starts the verification
     * @param finalNewBatch Last batch aggregator intends to verify
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param newStateRoot New State root once the batch is processed
     * @param proof fflonk proof
     */
    function _verifyAndRewardBatches(
        uint64 pendingStateNum,
        uint64 initNumBatch,
        uint64 finalNewBatch,
        bytes32 newLocalExitRoot,
        bytes32 newStateRoot,
        bytes calldata proof
    ) internal {
        bytes32 oldStateRoot;
        uint64 currentLastVerifiedBatch = getLastVerifiedBatch();

        // Use pending state if specified, otherwise use consolidated state
        if (pendingStateNum != 0) {
            // Check that pending state exist
            // Already consolidated pending states can be used aswell
            if (pendingStateNum > lastPendingState) {
                revert PendingStateDoesNotExist();
            }

            // Check choosen pending state
            PendingState storage currentPendingState = pendingStateTransitions[
                pendingStateNum
            ];

            // Get oldStateRoot from pending batch
            oldStateRoot = currentPendingState.stateRoot;

            // Check initNumBatch matches the pending state
            if (initNumBatch != currentPendingState.lastVerifiedBatch) {
                revert InitNumBatchDoesNotMatchPendingState();
            }
        } else {
            // Use consolidated state
            oldStateRoot = batchNumToStateRoot[initNumBatch];

            if (oldStateRoot == bytes32(0)) {
                revert OldStateRootDoesNotExist();
            }

            // Check initNumBatch is inside the range, sanity check
            if (initNumBatch > currentLastVerifiedBatch) {
                revert InitNumBatchAboveLastVerifiedBatch();
            }
        }

        // Check final batch
        if (finalNewBatch <= currentLastVerifiedBatch) {
            revert FinalNumBatchBelowLastVerifiedBatch();
        }

        // Get snark bytes
        bytes memory snarkHashBytes = getInputSnarkBytes(
            initNumBatch,
            finalNewBatch,
            newLocalExitRoot,
            oldStateRoot,
            newStateRoot
        );

        // Calulate the snark input
        uint256 inputSnark = uint256(sha256(snarkHashBytes)) % _RFIELD;
        // Verify proof
        if (!rollupVerifier.verifyProof(proof, [inputSnark])) {
            revert InvalidProof();
        }

        // Get MATIC reward
        matic.safeTransfer(
            msg.sender,
            calculateRewardPerBatch() *
                (finalNewBatch - currentLastVerifiedBatch)
        );
    }

    /**
     * @notice Internal function to consolidate the state automatically once sequence or verify batches are called
     * It tries to consolidate the first and the middle pending state in the queue
     */
    function _tryConsolidatePendingState() internal {
        // Check if there's any state to consolidate
        if (lastPendingState > lastPendingStateConsolidated) {
            // Check if it's possible to consolidate the next pending state
            uint64 nextPendingState = lastPendingStateConsolidated + 1;
            if (isPendingStateConsolidable(nextPendingState)) {
                // Check middle pending state ( binary search of 1 step)
                uint64 middlePendingState = nextPendingState +
                    (lastPendingState - nextPendingState) /
                    2;

                // Try to consolidate it, and if not, consolidate the nextPendingState
                if (isPendingStateConsolidable(middlePendingState)) {
                    _consolidatePendingState(middlePendingState);
                } else {
                    _consolidatePendingState(nextPendingState);
                }
            }
        }
    }

    /**
     * @notice Allows to consolidate any pending state that has already exceed the pendingStateTimeout
     * Can be called by the trusted aggregator, which can consolidate any state without the timeout restrictions
     * @param pendingStateNum Pending state to consolidate
     */
    function consolidatePendingState(uint64 pendingStateNum) external {
        // Check if pending state can be consolidated
        // If trusted aggregator is the sender, do not check the timeout or the emergency state
        if (msg.sender != trustedAggregator) {
            if (isEmergencyState) {
                revert OnlyNotEmergencyState();
            }

            if (!isPendingStateConsolidable(pendingStateNum)) {
                revert PendingStateNotConsolidable();
            }
        }
        _consolidatePendingState(pendingStateNum);
    }

    /**
     * @notice Internal function to consolidate any pending state that has already exceed the pendingStateTimeout
     * @param pendingStateNum Pending state to consolidate
     */
    function _consolidatePendingState(uint64 pendingStateNum) internal {
        // Check if pendingStateNum is in correct range
        // - not consolidated (implicity checks that is not 0)
        // - exist ( has been added)
        if (
            pendingStateNum <= lastPendingStateConsolidated ||
            pendingStateNum > lastPendingState
        ) {
            revert PendingStateInvalid();
        }

        PendingState storage currentPendingState = pendingStateTransitions[
            pendingStateNum
        ];

        // Update state
        uint64 newLastVerifiedBatch = currentPendingState.lastVerifiedBatch;
        lastVerifiedBatch = newLastVerifiedBatch;
        batchNumToStateRoot[newLastVerifiedBatch] = currentPendingState
            .stateRoot;

        // Update pending state
        lastPendingStateConsolidated = pendingStateNum;

        // Interact with globalExitRootManager
        globalExitRootManager.updateExitRoot(currentPendingState.exitRoot);

        emit ConsolidatePendingState(
            newLastVerifiedBatch,
            currentPendingState.stateRoot,
            pendingStateNum
        );
    }

    /**
     * @notice Function to update the batch fee based on the new verified batches
     * The batch fee will not be updated when the trusted aggregator verifies batches
     * @param newLastVerifiedBatch New last verified batch
     */
    function _updateBatchFee(uint64 newLastVerifiedBatch) internal {
        uint64 currentLastVerifiedBatch = getLastVerifiedBatch();
        uint64 currentBatch = newLastVerifiedBatch;

        uint256 totalBatchesAboveTarget;
        uint256 newBatchesVerified = newLastVerifiedBatch -
            currentLastVerifiedBatch;

        uint256 targetTimestamp = block.timestamp - verifyBatchTimeTarget;

        while (currentBatch != currentLastVerifiedBatch) {
            // Load sequenced batchdata
            SequencedBatchData
                storage currentSequencedBatchData = sequencedBatches[
                    currentBatch
                ];

            // Check if timestamp is below the verifyBatchTimeTarget
            if (
                targetTimestamp < currentSequencedBatchData.sequencedTimestamp
            ) {
                // update currentBatch
                currentBatch = currentSequencedBatchData
                    .previousLastBatchSequenced;
            } else {
                // The rest of batches will be above
                totalBatchesAboveTarget =
                    currentBatch -
                    currentLastVerifiedBatch;
                break;
            }
        }

        uint256 totalBatchesBelowTarget = newBatchesVerified -
            totalBatchesAboveTarget;

        // _MAX_BATCH_FEE --> (< 70 bits)
        // multiplierBatchFee --> (< 10 bits)
        // _MAX_BATCH_MULTIPLIER = 12
        // multiplierBatchFee ** _MAX_BATCH_MULTIPLIER --> (< 128 bits)
        // batchFee * (multiplierBatchFee ** _MAX_BATCH_MULTIPLIER)-->
        // (< 70 bits) * (< 128 bits) = < 256 bits

        // Since all the following operations cannot overflow, we can optimize this operations with unchecked
        unchecked {
            if (totalBatchesBelowTarget < totalBatchesAboveTarget) {
                // There are more batches above target, fee is multiplied
                uint256 diffBatches = totalBatchesAboveTarget -
                    totalBatchesBelowTarget;

                diffBatches = diffBatches > _MAX_BATCH_MULTIPLIER
                    ? _MAX_BATCH_MULTIPLIER
                    : diffBatches;

                // For every multiplierBatchFee multiplication we must shift 3 zeroes since we have 3 decimals
                batchFee =
                    (batchFee * (uint256(multiplierBatchFee) ** diffBatches)) /
                    (uint256(1000) ** diffBatches);
            } else {
                // There are more batches below target, fee is divided
                uint256 diffBatches = totalBatchesBelowTarget -
                    totalBatchesAboveTarget;

                diffBatches = diffBatches > _MAX_BATCH_MULTIPLIER
                    ? _MAX_BATCH_MULTIPLIER
                    : diffBatches;

                // For every multiplierBatchFee multiplication we must shift 3 zeroes since we have 3 decimals
                uint256 accDivisor = (uint256(1 ether) *
                    (uint256(multiplierBatchFee) ** diffBatches)) /
                    (uint256(1000) ** diffBatches);

                // multiplyFactor = multiplierBatchFee ** diffBatches / 10 ** (diffBatches * 3)
                // accDivisor = 1E18 * multiplyFactor
                // 1E18 * batchFee / accDivisor = batchFee / multiplyFactor
                // < 60 bits * < 70 bits / ~60 bits --> overflow not possible
                batchFee = (uint256(1 ether) * batchFee) / accDivisor;
            }
        }

        // Batch fee must remain inside a range
        if (batchFee > _MAX_BATCH_FEE) {
            batchFee = _MAX_BATCH_FEE;
        } else if (batchFee < _MIN_BATCH_FEE) {
            batchFee = _MIN_BATCH_FEE;
        }
    }

    ////////////////////////////
    // Force batches functions
    ////////////////////////////

    /**
     * @notice Allows a sequencer/user to force a batch of L2 transactions.
     * This should be used only in extreme cases where the trusted sequencer does not work as expected
     * Note The sequencer has certain degree of control on how non-forced and forced batches are ordered
     * In order to assure that users force transactions will be processed properly, user must not sign any other transaction
     * with the same nonce
     * @param transactions L2 ethereum transactions EIP-155 or pre-EIP-155 with signature:
     * @param maticAmount Max amount of MATIC tokens that the sender is willing to pay
     */
    function forceBatch(
        bytes calldata transactions,
        uint256 maticAmount
    ) public isForceBatchAllowed ifNotEmergencyState {
        // Calculate matic collateral
        uint256 maticFee = getCurrentBatchFee();

        if (maticFee > maticAmount) {
            revert NotEnoughMaticAmount();
        }

        if (transactions.length > _MAX_TRANSACTIONS_BYTE_LENGTH) {
            revert TransactionsLengthAboveMax();
        }

        matic.safeTransferFrom(msg.sender, address(this), maticFee);

        // Get globalExitRoot global exit root
        bytes32 lastGlobalExitRoot = globalExitRootManager
            .getLastGlobalExitRoot();

        // Update forcedBatches mapping
        lastForceBatch++;

        forcedBatches[lastForceBatch] = keccak256(
            abi.encodePacked(
                keccak256(transactions),
                lastGlobalExitRoot,
                uint64(block.timestamp)
            )
        );

        if (msg.sender == tx.origin) {
            // Getting the calldata from an EOA is easy so no need to put the `transactions` in the event
            emit ForceBatch(lastForceBatch, lastGlobalExitRoot, msg.sender, "");
        } else {
            // Getting internal transaction calldata is complicated (because it requires an archive node)
            // Therefore it's worth it to put the `transactions` in the event, which is easy to query
            emit ForceBatch(
                lastForceBatch,
                lastGlobalExitRoot,
                msg.sender,
                transactions
            );
        }
    }

    /**
     * @notice Allows anyone to sequence forced Batches if the trusted sequencer has not done so in the timeout period
     * @param batches Struct array which holds the necessary data to append force batches
     */
    function sequenceForceBatches(
        ForcedBatchData[] calldata batches
    ) external isForceBatchAllowed ifNotEmergencyState {
        uint256 batchesNum = batches.length;

        if (batchesNum == 0) {
            revert SequenceZeroBatches();
        }

        if (batchesNum > _MAX_VERIFY_BATCHES) {
            revert ExceedMaxVerifyBatches();
        }

        if (
            uint256(lastForceBatchSequenced) + batchesNum >
            uint256(lastForceBatch)
        ) {
            revert ForceBatchesOverflow();
        }

        // Store storage variables in memory, to save gas, because will be overrided multiple times
        uint64 currentBatchSequenced = lastBatchSequenced;
        uint64 currentLastForceBatchSequenced = lastForceBatchSequenced;
        bytes32 currentAccInputHash = sequencedBatches[currentBatchSequenced]
            .accInputHash;

        // Sequence force batches
        for (uint256 i = 0; i < batchesNum; i++) {
            // Load current sequence
            ForcedBatchData memory currentBatch = batches[i];
            currentLastForceBatchSequenced++;

            // Store the current transactions hash since it's used more than once for gas saving
            bytes32 currentTransactionsHash = keccak256(
                currentBatch.transactions
            );

            // Check forced data matches
            bytes32 hashedForcedBatchData = keccak256(
                abi.encodePacked(
                    currentTransactionsHash,
                    currentBatch.globalExitRoot,
                    currentBatch.minForcedTimestamp
                )
            );

            if (
                hashedForcedBatchData !=
                forcedBatches[currentLastForceBatchSequenced]
            ) {
                revert ForcedDataDoesNotMatch();
            }

            // Delete forceBatch data since won't be used anymore
            delete forcedBatches[currentLastForceBatchSequenced];

            if (i == (batchesNum - 1)) {
                // The last batch will have the most restrictive timestamp
                if (
                    currentBatch.minForcedTimestamp + forceBatchTimeout >
                    block.timestamp
                ) {
                    revert ForceBatchTimeoutNotExpired();
                }
            }
            // Calculate next acc input hash
            currentAccInputHash = keccak256(
                abi.encodePacked(
                    currentAccInputHash,
                    currentTransactionsHash,
                    currentBatch.globalExitRoot,
                    uint64(block.timestamp),
                    msg.sender
                )
            );
        }
        // Update currentBatchSequenced
        currentBatchSequenced += uint64(batchesNum);

        lastTimestamp = uint64(block.timestamp);

        // Store back the storage variables
        sequencedBatches[currentBatchSequenced] = SequencedBatchData({
            accInputHash: currentAccInputHash,
            sequencedTimestamp: uint64(block.timestamp),
            previousLastBatchSequenced: lastBatchSequenced
        });
        lastBatchSequenced = currentBatchSequenced;
        lastForceBatchSequenced = currentLastForceBatchSequenced;

        emit SequenceForceBatches(currentBatchSequenced);
    }

    //////////////////
    // admin functions
    //////////////////

    /**
     * @notice Allow the admin to set a new trusted sequencer
     * @param newTrustedSequencer Address of the new trusted sequencer
     */
    function setTrustedSequencer(
        address newTrustedSequencer
    ) external onlyAdmin {
        trustedSequencer = newTrustedSequencer;

        emit SetTrustedSequencer(newTrustedSequencer);
    }

    /**
     * @notice Allow the admin to set the trusted sequencer URL
     * @param newTrustedSequencerURL URL of trusted sequencer
     */
    function setTrustedSequencerURL(
        string memory newTrustedSequencerURL
    ) external onlyAdmin {
        trustedSequencerURL = newTrustedSequencerURL;

        emit SetTrustedSequencerURL(newTrustedSequencerURL);
    }

    /**
     * @notice Allow the admin to set a new trusted aggregator address
     * @param newTrustedAggregator Address of the new trusted aggregator
     */
    function setTrustedAggregator(
        address newTrustedAggregator
    ) external onlyAdmin {
        trustedAggregator = newTrustedAggregator;

        emit SetTrustedAggregator(newTrustedAggregator);
    }

    /**
     * @notice Allow the admin to set a new pending state timeout
     * The timeout can only be lowered, except if emergency state is active
     * @param newTrustedAggregatorTimeout Trusted aggregator timeout
     */
    function setTrustedAggregatorTimeout(
        uint64 newTrustedAggregatorTimeout
    ) external onlyAdmin {
        if (newTrustedAggregatorTimeout > _HALT_AGGREGATION_TIMEOUT) {
            revert TrustedAggregatorTimeoutExceedHaltAggregationTimeout();
        }

        if (!isEmergencyState) {
            if (newTrustedAggregatorTimeout >= trustedAggregatorTimeout) {
                revert NewTrustedAggregatorTimeoutMustBeLower();
            }
        }

        trustedAggregatorTimeout = newTrustedAggregatorTimeout;
        emit SetTrustedAggregatorTimeout(newTrustedAggregatorTimeout);
    }

    /**
     * @notice Allow the admin to set a new trusted aggregator timeout
     * The timeout can only be lowered, except if emergency state is active
     * @param newPendingStateTimeout Trusted aggregator timeout
     */
    function setPendingStateTimeout(
        uint64 newPendingStateTimeout
    ) external onlyAdmin {
        if (newPendingStateTimeout > _HALT_AGGREGATION_TIMEOUT) {
            revert PendingStateTimeoutExceedHaltAggregationTimeout();
        }

        if (!isEmergencyState) {
            if (newPendingStateTimeout >= pendingStateTimeout) {
                revert NewPendingStateTimeoutMustBeLower();
            }
        }

        pendingStateTimeout = newPendingStateTimeout;
        emit SetPendingStateTimeout(newPendingStateTimeout);
    }

    /**
     * @notice Allow the admin to set a new multiplier batch fee
     * @param newMultiplierBatchFee multiplier batch fee
     */
    function setMultiplierBatchFee(
        uint16 newMultiplierBatchFee
    ) external onlyAdmin {
        if (newMultiplierBatchFee < 1000 || newMultiplierBatchFee > 1023) {
            revert InvalidRangeMultiplierBatchFee();
        }

        multiplierBatchFee = newMultiplierBatchFee;
        emit SetMultiplierBatchFee(newMultiplierBatchFee);
    }

    /**
     * @notice Allow the admin to set a new verify batch time target
     * This value will only be relevant once the aggregation is decentralized, so
     * the trustedAggregatorTimeout should be zero or very close to zero
     * @param newVerifyBatchTimeTarget Verify batch time target
     */
    function setVerifyBatchTimeTarget(
        uint64 newVerifyBatchTimeTarget
    ) external onlyAdmin {
        if (newVerifyBatchTimeTarget > 1 days) {
            revert InvalidRangeBatchTimeTarget();
        }
        verifyBatchTimeTarget = newVerifyBatchTimeTarget;
        emit SetVerifyBatchTimeTarget(newVerifyBatchTimeTarget);
    }

    /**
     * @notice Allow the admin to set the forcedBatchTimeout
     * The new value can only be lower, except if emergency state is active
     * @param newforceBatchTimeout New force batch timeout
     */
    function setForceBatchTimeout(
        uint64 newforceBatchTimeout
    ) external onlyAdmin {
        if (newforceBatchTimeout > _HALT_AGGREGATION_TIMEOUT) {
            revert InvalidRangeForceBatchTimeout();
        }

        if (!isEmergencyState) {
            if (newforceBatchTimeout >= forceBatchTimeout) {
                revert InvalidRangeForceBatchTimeout();
            }
        }

        forceBatchTimeout = newforceBatchTimeout;
        emit SetForceBatchTimeout(newforceBatchTimeout);
    }

    /**
     * @notice Allow the admin to turn on the force batches
     * This action is not reversible
     */
    function activateForceBatches() external onlyAdmin {
        if (!isForcedBatchDisallowed) {
            revert ForceBatchesAlreadyActive();
        }
        isForcedBatchDisallowed = false;
        emit ActivateForceBatches();
    }

    /**
     * @notice Starts the admin role transfer
     * This is a two step process, the pending admin must accepted to finalize the process
     * @param newPendingAdmin Address of the new pending admin
     */
    function transferAdminRole(address newPendingAdmin) external onlyAdmin {
        pendingAdmin = newPendingAdmin;
        emit TransferAdminRole(newPendingAdmin);
    }

    /**
     * @notice Allow the current pending admin to accept the admin role
     */
    function acceptAdminRole() external {
        if (pendingAdmin != msg.sender) {
            revert OnlyPendingAdmin();
        }

        admin = pendingAdmin;
        emit AcceptAdminRole(pendingAdmin);
    }

    /////////////////////////////////
    // Soundness protection functions
    /////////////////////////////////

    /**
     * @notice Allows the trusted aggregator to override the pending state
     * if it's possible to prove a different state root given the same batches
     * @param initPendingStateNum Init pending state, 0 if consolidated state is used
     * @param finalPendingStateNum Final pending state, that will be used to compare with the newStateRoot
     * @param initNumBatch Batch which the aggregator starts the verification
     * @param finalNewBatch Last batch aggregator intends to verify
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param newStateRoot New State root once the batch is processed
     * @param proof fflonk proof
     */
    function overridePendingState(
        uint64 initPendingStateNum,
        uint64 finalPendingStateNum,
        uint64 initNumBatch,
        uint64 finalNewBatch,
        bytes32 newLocalExitRoot,
        bytes32 newStateRoot,
        bytes calldata proof
    ) external onlyTrustedAggregator {
        _proveDistinctPendingState(
            initPendingStateNum,
            finalPendingStateNum,
            initNumBatch,
            finalNewBatch,
            newLocalExitRoot,
            newStateRoot,
            proof
        );

        // Consolidate state state
        lastVerifiedBatch = finalNewBatch;
        batchNumToStateRoot[finalNewBatch] = newStateRoot;

        // Clean pending state if any
        if (lastPendingState > 0) {
            lastPendingState = 0;
            lastPendingStateConsolidated = 0;
        }

        // Interact with globalExitRootManager
        globalExitRootManager.updateExitRoot(newLocalExitRoot);

        // Update trusted aggregator timeout to max
        trustedAggregatorTimeout = _HALT_AGGREGATION_TIMEOUT;

        emit OverridePendingState(finalNewBatch, newStateRoot, msg.sender);
    }

    /**
     * @notice Allows to halt the PolygonZkEVM if its possible to prove a different state root given the same batches
     * @param initPendingStateNum Init pending state, 0 if consolidated state is used
     * @param finalPendingStateNum Final pending state, that will be used to compare with the newStateRoot
     * @param initNumBatch Batch which the aggregator starts the verification
     * @param finalNewBatch Last batch aggregator intends to verify
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param newStateRoot New State root once the batch is processed
     * @param proof fflonk proof
     */
    function proveNonDeterministicPendingState(
        uint64 initPendingStateNum,
        uint64 finalPendingStateNum,
        uint64 initNumBatch,
        uint64 finalNewBatch,
        bytes32 newLocalExitRoot,
        bytes32 newStateRoot,
        bytes calldata proof
    ) external ifNotEmergencyState {
        _proveDistinctPendingState(
            initPendingStateNum,
            finalPendingStateNum,
            initNumBatch,
            finalNewBatch,
            newLocalExitRoot,
            newStateRoot,
            proof
        );

        emit ProveNonDeterministicPendingState(
            batchNumToStateRoot[finalNewBatch],
            newStateRoot
        );

        // Activate emergency state
        _activateEmergencyState();
    }

    /**
     * @notice Internal function that proves a different state root given the same batches to verify
     * @param initPendingStateNum Init pending state, 0 if consolidated state is used
     * @param finalPendingStateNum Final pending state, that will be used to compare with the newStateRoot
     * @param initNumBatch Batch which the aggregator starts the verification
     * @param finalNewBatch Last batch aggregator intends to verify
     * @param newLocalExitRoot  New local exit root once the batch is processed
     * @param newStateRoot New State root once the batch is processed
     * @param proof fflonk proof
     */
    function _proveDistinctPendingState(
        uint64 initPendingStateNum,
        uint64 finalPendingStateNum,
        uint64 initNumBatch,
        uint64 finalNewBatch,
        bytes32 newLocalExitRoot,
        bytes32 newStateRoot,
        bytes calldata proof
    ) internal view {
        bytes32 oldStateRoot;

        // Use pending state if specified, otherwise use consolidated state
        if (initPendingStateNum != 0) {
            // Check that pending state exist
            // Already consolidated pending states can be used aswell
            if (initPendingStateNum > lastPendingState) {
                revert PendingStateDoesNotExist();
            }

            // Check choosen pending state
            PendingState storage initPendingState = pendingStateTransitions[
                initPendingStateNum
            ];

            // Get oldStateRoot from init pending state
            oldStateRoot = initPendingState.stateRoot;

            // Check initNumBatch matches the init pending state
            if (initNumBatch != initPendingState.lastVerifiedBatch) {
                revert InitNumBatchDoesNotMatchPendingState();
            }
        } else {
            // Use consolidated state
            oldStateRoot = batchNumToStateRoot[initNumBatch];
            if (oldStateRoot == bytes32(0)) {
                revert OldStateRootDoesNotExist();
            }

            // Check initNumBatch is inside the range, sanity check
            if (initNumBatch > lastVerifiedBatch) {
                revert InitNumBatchAboveLastVerifiedBatch();
            }
        }

        // Assert final pending state num is in correct range
        // - exist ( has been added)
        // - bigger than the initPendingstate
        // - not consolidated
        if (
            finalPendingStateNum > lastPendingState ||
            finalPendingStateNum <= initPendingStateNum ||
            finalPendingStateNum <= lastPendingStateConsolidated
        ) {
            revert FinalPendingStateNumInvalid();
        }

        // Check final num batch
        if (
            finalNewBatch !=
            pendingStateTransitions[finalPendingStateNum].lastVerifiedBatch
        ) {
            revert FinalNumBatchDoesNotMatchPendingState();
        }

        // Get snark bytes
        bytes memory snarkHashBytes = getInputSnarkBytes(
            initNumBatch,
            finalNewBatch,
            newLocalExitRoot,
            oldStateRoot,
            newStateRoot
        );

        // Calulate the snark input
        uint256 inputSnark = uint256(sha256(snarkHashBytes)) % _RFIELD;

        // Verify proof
        if (!rollupVerifier.verifyProof(proof, [inputSnark])) {
            revert InvalidProof();
        }

        if (
            pendingStateTransitions[finalPendingStateNum].stateRoot ==
            newStateRoot
        ) {
            revert StoredRootMustBeDifferentThanNewRoot();
        }
    }

    /**
     * @notice Function to activate emergency state, which also enables the emergency mode on both PolygonZkEVM and PolygonZkEVMBridge contracts
     * If not called by the owner must be provided a batcnNum that does not have been aggregated in a _HALT_AGGREGATION_TIMEOUT period
     * @param sequencedBatchNum Sequenced batch number that has not been aggreagated in _HALT_AGGREGATION_TIMEOUT
     */
    function activateEmergencyState(uint64 sequencedBatchNum) external {
        if (msg.sender != owner()) {
            // Only check conditions if is not called by the owner
            uint64 currentLastVerifiedBatch = getLastVerifiedBatch();

            // Check that the batch has not been verified
            if (sequencedBatchNum <= currentLastVerifiedBatch) {
                revert BatchAlreadyVerified();
            }

            // Check that the batch has been sequenced and this was the end of a sequence
            if (
                sequencedBatchNum > lastBatchSequenced ||
                sequencedBatches[sequencedBatchNum].sequencedTimestamp == 0
            ) {
                revert BatchNotSequencedOrNotSequenceEnd();
            }

            // Check that has been passed _HALT_AGGREGATION_TIMEOUT since it was sequenced
            if (
                sequencedBatches[sequencedBatchNum].sequencedTimestamp +
                    _HALT_AGGREGATION_TIMEOUT >
                block.timestamp
            ) {
                revert HaltTimeoutNotExpired();
            }
        }
        _activateEmergencyState();
    }

    /**
     * @notice Function to deactivate emergency state on both PolygonZkEVM and PolygonZkEVMBridge contracts
     */
    function deactivateEmergencyState() external onlyAdmin {
        // Deactivate emergency state on PolygonZkEVMBridge
        bridgeAddress.deactivateEmergencyState();

        // Deactivate emergency state on this contract
        super._deactivateEmergencyState();
    }

    /**
     * @notice Internal function to activate emergency state on both PolygonZkEVM and PolygonZkEVMBridge contracts
     */
    function _activateEmergencyState() internal override {
        // Activate emergency state on PolygonZkEVM Bridge
        bridgeAddress.activateEmergencyState();

        // Activate emergency state on this contract
        super._activateEmergencyState();
    }

    ////////////////////////
    // public/view functions
    ////////////////////////

    /**
     * @notice Function to get the batch fee
     */
    function getCurrentBatchFee() public view returns (uint256) {
        return batchFee;
    }

    /**
     * @notice Get the last verified batch
     */
    function getLastVerifiedBatch() public view returns (uint64) {
        if (lastPendingState > 0) {
            return pendingStateTransitions[lastPendingState].lastVerifiedBatch;
        } else {
            return lastVerifiedBatch;
        }
    }

    /**
     * @notice Returns a boolean that indicates if the pendingStateNum is or not consolidable
     * Note that his function does not check if the pending state currently exists, or if it's consolidated already
     */
    function isPendingStateConsolidable(
        uint64 pendingStateNum
    ) public view returns (bool) {
        return (pendingStateTransitions[pendingStateNum].timestamp +
            pendingStateTimeout <=
            block.timestamp);
    }

    /**
     * @notice Function to calculate the reward to verify a single batch
     */
    function calculateRewardPerBatch() public view returns (uint256) {
        uint256 currentBalance = matic.balanceOf(address(this));

        // Total Sequenced Batches = forcedBatches to be sequenced (total forced Batches - sequenced Batches) + sequencedBatches
        // Total Batches to be verified = Total Sequenced Batches - verified Batches
        uint256 totalBatchesToVerify = ((lastForceBatch -
            lastForceBatchSequenced) + lastBatchSequenced) -
            getLastVerifiedBatch();

        if (totalBatchesToVerify == 0) return 0;
        return currentBalance / totalBatchesToVerify;
    }

    /**
     * @notice Function to calculate the input snark bytes
     * @param initNumBatch Batch which the aggregator starts the verification
     * @param finalNewBatch Last batch aggregator intends to verify
     * @param newLocalExitRoot New local exit root once the batch is processed
     * @param oldStateRoot State root before batch is processed
     * @param newStateRoot New State root once the batch is processed
     */
    function getInputSnarkBytes(
        uint64 initNumBatch,
        uint64 finalNewBatch,
        bytes32 newLocalExitRoot,
        bytes32 oldStateRoot,
        bytes32 newStateRoot
    ) public view returns (bytes memory) {
        // sanity checks
        bytes32 oldAccInputHash = sequencedBatches[initNumBatch].accInputHash;
        bytes32 newAccInputHash = sequencedBatches[finalNewBatch].accInputHash;

        if (initNumBatch != 0 && oldAccInputHash == bytes32(0)) {
            revert OldAccInputHashDoesNotExist();
        }

        if (newAccInputHash == bytes32(0)) {
            revert NewAccInputHashDoesNotExist();
        }

        // Check that new state root is inside goldilocks field
        if (!checkStateRootInsidePrime(uint256(newStateRoot))) {
            revert NewStateRootNotInsidePrime();
        }

        return
            abi.encodePacked(
                msg.sender,
                oldStateRoot,
                oldAccInputHash,
                initNumBatch,
                chainID,
                forkID,
                newStateRoot,
                newAccInputHash,
                newLocalExitRoot,
                finalNewBatch
            );
    }

    function checkStateRootInsidePrime(
        uint256 newStateRoot
    ) public pure returns (bool) {
        if (
            ((newStateRoot & _MAX_UINT_64) < _GOLDILOCKS_PRIME_FIELD) &&
            (((newStateRoot >> 64) & _MAX_UINT_64) < _GOLDILOCKS_PRIME_FIELD) &&
            (((newStateRoot >> 128) & _MAX_UINT_64) <
                _GOLDILOCKS_PRIME_FIELD) &&
            ((newStateRoot >> 192) < _GOLDILOCKS_PRIME_FIELD)
        ) {
            return true;
        } else {
            return false;
        }
    }
}