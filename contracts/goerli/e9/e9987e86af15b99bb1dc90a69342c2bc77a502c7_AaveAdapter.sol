// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface IWETH {
  function deposit() external payable;

  function withdraw(uint256) external;

  function approve(address guy, uint256 wad) external returns (bool);

  function transferFrom(
    address src,
    address dst,
    uint256 wad
  ) external returns (bool);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Aave2DataTypes {
  // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../common/DataTypes.sol";
import "./Aave2DataTypes.sol";

interface IAaveProtocolDataProvider {
  function ADDRESSES_PROVIDER() external view returns (address);
  function getAllReservesTokens() external view returns (AaveDataTypes.TokenData[] memory);
  function getAllATokens() external view returns (AaveDataTypes.TokenData[] memory);
  function getReserveConfigurationData(address asset) external view returns (
    uint256 decimals,
    uint256 ltv,
    uint256 liquidationThreshold,
    uint256 liquidationBonus,
    uint256 reserveFactor,
    bool usageAsCollateralEnabled,
    bool borrowingEnabled,
    bool stableBorrowRateEnabled,
    bool isActive,
    bool isFrozen
  );
  function getReserveData(address asset) external view returns (
    uint256 availableLiquidity,
    uint256 totalStableDebt,
    uint256 totalVariableDebt,
    uint256 liquidityRate,
    uint256 variableBorrowRate,
    uint256 stableBorrowRate,
    uint256 averageStableBorrowRate,
    uint256 liquidityIndex,
    uint256 variableBorrowIndex,
    uint40 lastUpdateTimestamp
  );
  function getUserReserveData(address asset, address user) external view returns (
    uint256 currentATokenBalance,
    uint256 currentStableDebt,
    uint256 currentVariableDebt,
    uint256 principalStableDebt,
    uint256 scaledVariableDebt,
    uint256 stableBorrowRate,
    uint256 liquidityRate,
    uint40 stableRateLastUpdated,
    bool usageAsCollateralEnabled
  );
  function getReserveTokensAddresses(address asset) external view returns (
    address aTokenAddress,
    address stableDebtTokenAddress,
    address variableDebtTokenAddress
  );
}

interface ILendingPoolAddressesProvider {
  function getLendingPool() external view returns (address);
  function getPriceOracle() external view returns (address);
}

interface ILendingPool {
  function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
  function withdraw(address asset, uint256 amount, address to) external returns (uint256);
  function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
  function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);
  function swapBorrowRateMode(address asset, uint256 rateMode) external;
  function rebalanceStableBorrowRate(address asset, address user) external;
  function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
  function liquidationCall(address collateralAsset, address debtAsset, address user, uint256 debtToCover, bool receiveAToken) external;

  function getUserAccountData(address user) external view returns (
    uint256 totalCollateralETH,
    uint256 totalDebtETH,
    uint256 availableBorrowsETH,
    uint256 currentLiquidationThreshold,
    uint256 ltv,
    uint256 healthFactor
  );
  function getReserveData(address asset) external view returns (Aave2DataTypes.ReserveData memory);
  function getReservesList() external view returns (address[] memory);
}

interface V2_ICreditDelegationToken is IERC20Upgradeable {
    function approveDelegation(address delegatee, uint256 amount) external;
    function borrowAllowance(address fromUser, address toUser) external view returns (uint256);
}

interface V2_IAToken is IERC20Upgradeable {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
    function POOL() external view returns (address);
    function getIncentivesController() external view returns (address);
    function name() external view returns(string memory);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function _nonces(address owner) external view returns (uint256);
}

interface IAaveIncentivesController {
  function getAssetData(address asset) external view returns (uint256, uint256, uint256);
  function assets(address asset) external view returns (uint128, uint128, uint256);
  function getClaimer(address user) external view returns (address);
  function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

  function claimRewards(address[] calldata assets, uint256 amount, address to) external returns (uint256);
  function claimRewardsOnBehalf(address[] calldata assets, uint256 amount, address user, address to) external returns (uint256);

  function getUserUnclaimedRewards(address user) external view returns (uint256);
  function getUserAssetData(address user, address asset) external view returns (uint256);
  function REWARD_TOKEN() external view returns (address);
  function PRECISION() external view returns (uint8);
  function DISTRIBUTION_END() external view returns (uint256);
  function STAKE_TOKEN() external view returns (address);
}

interface IStakedTokenV2 {
  function STAKED_TOKEN() external view returns (address);
}

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Aave3DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    //the current stable borrow rate. Expressed in ray
    uint128 currentStableBorrowRate;
    //timestamp of last update
    uint40 lastUpdateTimestamp;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint16 id;
    //aToken address
    address aTokenAddress;
    //stableDebtToken address
    address stableDebtTokenAddress;
    //variableDebtToken address
    address variableDebtTokenAddress;
    //address of the interest rate strategy
    address interestRateStrategyAddress;
    //the current treasury balance, scaled
    uint128 accruedToTreasury;
    //the outstanding unbacked aTokens minted through the bridging feature
    uint128 unbacked;
    //the outstanding debt borrowed against this asset in isolation mode
    uint128 isolationModeTotalDebt;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60: asset is paused
    //bit 61: borrowing in isolation mode is enabled
    //bit 62-63: reserved
    //bit 64-79: reserve factor
    //bit 80-115 borrow cap in whole tokens, borrowCap == 0 => no cap
    //bit 116-151 supply cap in whole tokens, supplyCap == 0 => no cap
    //bit 152-167 liquidation protocol fee
    //bit 168-175 eMode category
    //bit 176-211 unbacked mint cap in whole tokens, unbackedMintCap == 0 => minting disabled
    //bit 212-251 debt ceiling for isolation mode with (ReserveConfiguration::DEBT_CEILING_DECIMALS) decimals
    //bit 252-255 unused

    uint256 data;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "../common/DataTypes.sol";
import "./Aave3DataTypes.sol";

interface IPoolAddressesProvider {
  function getPool() external view returns (address);
  function getPriceOracle() external view returns (address);
  function getPoolDataProvider() external view returns (address);
}

interface IPoolDataProvider {
    function ADDRESSES_PROVIDER() external view returns (IPoolAddressesProvider);
    function getAllReservesTokens() external view returns (AaveDataTypes.TokenData[] memory);
    function getAllATokens() external view returns (AaveDataTypes.TokenData[] memory);
    function getReserveConfigurationData(address asset) external view returns (
        uint256 decimals,
        uint256 ltv,
        uint256 liquidationThreshold,
        uint256 liquidationBonus,
        uint256 reserveFactor,
        bool usageAsCollateralEnabled,
        bool borrowingEnabled,
        bool stableBorrowRateEnabled,
        bool isActive,
        bool isFrozen
    );
    function getReserveEModeCategory(address asset) external view returns (uint256);
    function getReserveCaps(address asset) external view returns (uint256 borrowCap, uint256 supplyCap);
    function getPaused(address asset) external view returns (bool isPaused);
    function getSiloedBorrowing(address asset) external view returns (bool);
    function getLiquidationProtocolFee(address asset) external view returns (uint256);
    function getUnbackedMintCap(address asset) external view returns (uint256);
    function getDebtCeiling(address asset) external view returns (uint256);
    function getDebtCeilingDecimals() external pure returns (uint256);
    function getReserveData(address asset) external view returns (
        uint256 unbacked,
        uint256 accruedToTreasuryScaled,
        uint256 totalAToken,
        uint256 totalStableDebt,
        uint256 totalVariableDebt,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 stableBorrowRate,
        uint256 averageStableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex,
        uint40 lastUpdateTimestamp
    );
    function getATokenTotalSupply(address asset) external view returns (uint256);
    function getTotalDebt(address asset) external view returns (uint256);
    function getUserReserveData(address asset, address user) external view returns (
        uint256 currentATokenBalance,
        uint256 currentStableDebt,
        uint256 currentVariableDebt,
        uint256 principalStableDebt,
        uint256 scaledVariableDebt,
        uint256 stableBorrowRate,
        uint256 liquidityRate,
        uint40 stableRateLastUpdated,
        bool usageAsCollateralEnabled
    );
    function getReserveTokensAddresses(address asset) external view returns (
        address aTokenAddress,
        address stableDebtTokenAddress,
        address variableDebtTokenAddress
    );
    function getInterestRateStrategyAddress(address asset) external view returns (address irStrategyAddress);
    function getFlashLoanEnabled(address asset) external view returns (bool);
}

interface IPool {
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function supplyWithPermit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode, uint256 deadline, uint8 permitV, bytes32 permitR, bytes32 permitS) external;
    function withdraw(address asset, uint256 amount, address to ) external returns (uint256);
    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
    function repay(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf) external returns (uint256);
    function repayWithPermit(address asset, uint256 amount, uint256 interestRateMode, address onBehalfOf, uint256 deadline, uint8 permitV, bytes32 permitR, bytes32 permitS) external returns (uint256);
    function repayWithATokens(address asset, uint256 amount, uint256 interestRateMode) external returns (uint256);
    function swapBorrowRateMode(address asset, uint256 interestRateMode) external;
    function rebalanceStableBorrowRate(address asset, address user) external;
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;
    function liquidationCall(address collateralAsset, address debtAsset, address user, uint256 debtToCover, bool receiveAToken) external;

    function getUserAccountData(address user) external view returns (
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
    function getReserveData(address asset) external view returns (Aave3DataTypes.ReserveData memory);
    function getReservesList() external view returns (address[] memory);
}

interface V3_ICreditDelegationToken is IERC20Upgradeable {
    function approveDelegation(address delegatee, uint256 amount) external;
    function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

    function delegationWithSig(
        address delegator,
        address delegatee,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
    function name() external view returns(string memory);
    function nonces(address owner) external view returns (uint256);
}

interface V3_IAToken is IERC20Upgradeable {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
    function POOL() external view returns (address);
    function getIncentivesController() external view returns (address);
    function name() external view returns(string memory);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function nonces(address owner) external view returns (uint256);
}

interface IRewardsController {
    /// @dev asset The incentivized asset. It should be address of AToken or VariableDebtToken
    function getRewardsByAsset(address asset) external view returns (address[] memory);
    function getRewardsData(address asset, address reward) external view returns (
      uint256 index,
      uint256 emissionPerSecond,
      uint256 lastUpdateTimestamp,
      uint256 distributionEnd
    );
    function getAllUserRewards(address[] calldata assets, address user) external view returns (address[] memory, uint256[] memory);
    function getUserRewards(address[] calldata assets, address user, address reward) external view returns (uint256);
    function claimAllRewards(address[] calldata assets, address to) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
    function claimAllRewardsToSelf(address[] calldata assets) external returns (address[] memory rewardsList, uint256[] memory claimedAmounts);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {IWETH} from '@aave/core-v3/contracts/misc/interfaces/IWETH.sol';
import "../interfaces/IChainlinkAggregator.sol";
import "../interfaces/IERC20UpgradeableExt.sol";
import "../libs/BaseRelayRecipient.sol";
import "./aave2/Aave2DataTypes.sol";
import "./aave2/Aave2Interfaces.sol";
import "./aave3/Aave3DataTypes.sol";
import "./aave3/Aave3Interfaces.sol";
import "./common/DataTypes.sol";

contract AaveAdapter is OwnableUpgradeable, BaseRelayRecipient {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeERC20Upgradeable for V3_IAToken;

    struct Reward {
        address token; // reward token addresses
        string symbol; // reward token's symbol
        uint8 decimals; // reward token's decimals
        uint rewardAmount; // unclaimed reward amount
        uint rewardValueInUSD; // unclaimed reward values in USD. It scaled by 8
    }

    ILendingPoolAddressesProvider public immutable V2_ADDRESSES_PROVIDER;
    IAaveProtocolDataProvider public immutable V2_DATA_PROVIDER;
    ILendingPool public immutable V2_LENDING_POOL;
    IAaveIncentivesController public immutable V2_REWARDS_CONTROLLER;
    IAaveOracle public immutable V2_PRICE_ORACLE;
    IChainlinkAggregator public immutable V2_BASE_CURRENCY_PRICE_SOURCE;

    IPoolAddressesProvider public immutable V3_ADDRESSES_PROVIDER;
    IPoolDataProvider public immutable V3_DATA_PROVIDER;
    IPool public immutable V3_POOL;
    IRewardsController public immutable V3_REWARDS_CONTROLLER;
    IAaveOracle public immutable V3_PRICE_ORACLE;

    IWETH public immutable WNATIVE;
    address public immutable V2_aWNATIVE;
    address internal immutable V2_stableDebtWNATIVE;
    address internal immutable V2_variableDebtWNATIVE;
    address public immutable V3_aWNATIVE;
    address internal immutable V3_stableDebtWNATIVE;
    address internal immutable V3_variableDebtWNATIVE;

    uint internal constant IR_MODE_STABLE = 1;

    uint internal constant YEAR_IN_SEC = 365 * 1 days;

    event Supply(address indexed account, uint version, address indexed asset, uint indexed amount);
    event Withdraw(address indexed account, uint version, address indexed asset, uint indexed amount);
    event Borrow(address indexed account, uint version, address indexed asset, uint indexed amount, uint interestRateMode);
    event Repay(address indexed account, uint version, address indexed asset, uint indexed amount, uint interestRateMode);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(
        address _v2DataProvider,
        address _v3AddressesProvider,
        address _wnative,
        address _v2BaseCurrencyPriceSource
    ) {
        _disableInitializers();

        bool v2Supported = _v2DataProvider != address(0) ? true : false;
        V2_DATA_PROVIDER = IAaveProtocolDataProvider(_v2DataProvider);
        V2_ADDRESSES_PROVIDER = ILendingPoolAddressesProvider(v2Supported ? V2_DATA_PROVIDER.ADDRESSES_PROVIDER() : address(0));
        V2_LENDING_POOL = ILendingPool(v2Supported ? V2_ADDRESSES_PROVIDER.getLendingPool() : address(0));
        V2_PRICE_ORACLE = IAaveOracle(v2Supported ? V2_ADDRESSES_PROVIDER.getPriceOracle() : address(0));
        V2_BASE_CURRENCY_PRICE_SOURCE = IChainlinkAggregator(_v2BaseCurrencyPriceSource);

        bool v3Supported = _v3AddressesProvider != address(0) ? true : false;
        V3_ADDRESSES_PROVIDER = IPoolAddressesProvider(_v3AddressesProvider);
        V3_DATA_PROVIDER = IPoolDataProvider(v3Supported ? V3_ADDRESSES_PROVIDER.getPoolDataProvider() : address(0));
        V3_POOL = IPool(v3Supported ? V3_ADDRESSES_PROVIDER.getPool() : address(0));
        V3_PRICE_ORACLE = IAaveOracle(v3Supported ? V3_ADDRESSES_PROVIDER.getPriceOracle() : address(0));

        WNATIVE = IWETH(_wnative);
        (V2_aWNATIVE, V2_stableDebtWNATIVE, V2_variableDebtWNATIVE) = (address(V2_DATA_PROVIDER) != address(0))
            ? V2_DATA_PROVIDER.getReserveTokensAddresses(_wnative)
            : (address(0), address(0), address(0));
        (V3_aWNATIVE, V3_stableDebtWNATIVE, V3_variableDebtWNATIVE) = (address(V3_DATA_PROVIDER) != address(0))
            ? V3_DATA_PROVIDER.getReserveTokensAddresses(_wnative)
            : (address(0), address(0), address(0));

        V2_REWARDS_CONTROLLER = IAaveIncentivesController(V2_aWNATIVE != address(0)
            ? V2_IAToken(V2_aWNATIVE).getIncentivesController()
            : address(0));
        V3_REWARDS_CONTROLLER = IRewardsController(V3_aWNATIVE != address(0)
            ? V3_IAToken(V3_aWNATIVE).getIncentivesController()
            : address(0));
    }

    function initialize(address _biconomy) public initializer {
        __Ownable_init();

        trustedForwarder = _biconomy;

        _approvePool();
    }

    function setBiconomy(address _biconomy) external onlyOwner {
        trustedForwarder = _biconomy;
    }

    function _msgSender() internal override(ContextUpgradeable, BaseRelayRecipient) view returns (address) {
        return BaseRelayRecipient._msgSender();
    }

    function versionRecipient() external pure override returns (string memory) {
        return "1";
    }

    /// @notice If new assets are added into the pool, it needs to be called.
    function approvePool() external onlyOwner {
        _approvePool();
    }

    function _approvePool() internal {
        if (address(V2_LENDING_POOL) != address(0)) {
            address[] memory reserves = V2_LENDING_POOL.getReservesList();
            for (uint i = 0; i < reserves.length; i++) {
                IERC20Upgradeable reserve = IERC20Upgradeable(reserves[i]);
                if (reserve.allowance(address(this), address(V2_LENDING_POOL)) == 0) {
                    reserve.safeApprove(address(V2_LENDING_POOL), type(uint).max);
                }
            }
        }
        if (address(V3_POOL) != address(0)) {
            address[] memory reserves = V3_POOL.getReservesList();
            for (uint i = 0; i < reserves.length; i++) {
                IERC20Upgradeable reserve = IERC20Upgradeable(reserves[i]);
                if (reserve.allowance(address(this), address(V3_POOL)) == 0) {
                    reserve.safeApprove(address(V3_POOL), type(uint).max);
                }
            }
        }
    }

    function getAllReservesTokens() public view returns (TokenDataEx[] memory tokens) {
        AaveDataTypes.TokenData[] memory v2Tokens;
        uint v2TokensLength;
        AaveDataTypes.TokenData[] memory v3Tokens;
        uint v3TokensLength;

        if (address(V2_DATA_PROVIDER) != address(0)) {
            v2Tokens = V2_DATA_PROVIDER.getAllReservesTokens();
            v2TokensLength = v2Tokens.length;
        }
        if (address(V3_DATA_PROVIDER) != address(0)) {
            v3Tokens = V3_DATA_PROVIDER.getAllReservesTokens();
            v3TokensLength = v3Tokens.length;
        }

        tokens = new TokenDataEx[](v2TokensLength + v3TokensLength);
        for (uint i = 0; i < v2TokensLength; i ++) {
            tokens[i].version = VERSION.V2;
            tokens[i].symbol = v2Tokens[i].symbol;
            tokens[i].tokenAddress = v2Tokens[i].tokenAddress;
        }
        uint index;
        for (uint i = 0; i < v3TokensLength; i ++) {
            index = v2TokensLength + i;
            tokens[index].version = VERSION.V3;
            tokens[index].symbol = v3Tokens[i].symbol;
            tokens[index].tokenAddress = v3Tokens[i].tokenAddress;
        }
    }

    /**
   * @notice Returns the user account data across all the reserves
   * @param user The address of the user
   * @return totalCollateral The total collateral of the user in USD. The unit is 100000000
   * @return totalDebt The total debt of the user in USD
   * @return availableBorrows The borrowing power left of the user in USD
   * @return currentLiquidationThreshold The liquidation threshold of the user
   * @return ltv The loan to value of The user
   * @return healthFactor The current health factor of the user
   */
    function getUserAccountData(uint version, address user) external view returns (
        uint totalCollateral,
        uint totalDebt,
        uint availableBorrows,
        uint currentLiquidationThreshold,
        uint ltv,
        uint healthFactor
    ) {
        if (uint(VERSION.V2) == version) {
            // NOTE: It supports only Ethereum in V2 markets
            int256 ethPrice = V2_BASE_CURRENCY_PRICE_SOURCE.latestAnswer();
            (totalCollateral, totalDebt, availableBorrows, currentLiquidationThreshold, ltv, healthFactor) =  V2_LENDING_POOL.getUserAccountData(user);
            unchecked {
                totalCollateral = totalCollateral * uint(ethPrice) / 1e18;
                totalDebt = totalDebt * uint(ethPrice) / 1e18;
                availableBorrows = availableBorrows * uint(ethPrice) / 1e18;
            }
        } else {
            // The base currency on AAVE v3 is USD. The unit is 100000000.
            (totalCollateral, totalDebt, availableBorrows, currentLiquidationThreshold, ltv, healthFactor) =  V3_POOL.getUserAccountData(user);
        }
    }

    /// @notice The user must approve this SC for the asset.
    function supply(uint version, address asset, uint amount) public {
        address account = _msgSender();
        IERC20Upgradeable(asset).safeTransferFrom(account, address(this), amount);

        if (uint(VERSION.V2) == version) {
            V2_LENDING_POOL.deposit(asset, amount, account, 0);
        } else {
            V3_POOL.supply(asset, amount, account, 0);
        }
        emit Supply(account, version, asset, amount);
    }

    function supplyETH(uint version) payable public {
        address account = _msgSender();
        WNATIVE.deposit{value: msg.value}();

        if (uint(VERSION.V2) == version) {
            V2_LENDING_POOL.deposit(address(WNATIVE), msg.value, account, 0);
        } else {
            V3_POOL.supply(address(WNATIVE), msg.value, account, 0);
        }
        emit Supply(account, version, address(WNATIVE), msg.value);
    }

    /// @notice The user must approve this SC for the asset's aToken.
    function withdraw(uint version, address asset, uint amount) public {
        address account = _msgSender();
        address aToken;

        if (uint(VERSION.V2) == version) {
            (aToken,,) = V2_DATA_PROVIDER.getReserveTokensAddresses(asset);
        } else {
            (aToken,,) = V3_DATA_PROVIDER.getReserveTokensAddresses(asset);
        }
        _withdraw(version, asset, amount, account, aToken);
    }

    function withdrawWithPermit(
        uint version, address asset, uint amount,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) public {
        address account = _msgSender();
        address aToken;

        if (uint(VERSION.V2) == version) {
            (aToken,,) = V2_DATA_PROVIDER.getReserveTokensAddresses(asset);
        } else {
            (aToken,,) = V3_DATA_PROVIDER.getReserveTokensAddresses(asset);
        }
        V3_IAToken(aToken).permit(account, address(this), permitAmount, permitDeadline, permitV, permitR, permitS);

        _withdraw(version, asset, amount, account, aToken);
    }

    function _withdraw(uint version, address asset, uint amount, address account, address aToken) internal {
        uint amountToWithdraw = amount;
        if (amount == type(uint).max) {
            amountToWithdraw = IERC20Upgradeable(aToken).balanceOf(account);
        }

        IERC20Upgradeable(aToken).safeTransferFrom(account, address(this), amountToWithdraw);
        if (uint(VERSION.V2) == version) {
            V2_LENDING_POOL.withdraw(asset, amountToWithdraw, account);
        } else {
            V3_POOL.withdraw(asset, amountToWithdraw, account);
        }
        emit Withdraw(account, version, asset, amountToWithdraw);
    }

    function withdrawETH(uint version, uint amount) public {
        _withdrawETH(version, amount, _msgSender());
    }

    function withdrawETHWithPermit(
        uint version, uint amount,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) public {
        address account = _msgSender();
        address aWNATIVE = version == uint(VERSION.V2) ? V2_aWNATIVE : V3_aWNATIVE;
        V3_IAToken(aWNATIVE).permit(account, address(this), permitAmount, permitDeadline, permitV, permitR, permitS);
        _withdrawETH(version, amount, account);
    }

    function _withdrawETH(uint version, uint amount, address account) internal {
        address aWNATIVE = version == uint(VERSION.V2) ? V2_aWNATIVE : V3_aWNATIVE;
        uint amountToWithdraw = amount;
        if (amount == type(uint).max) {
            amountToWithdraw = IERC20Upgradeable(aWNATIVE).balanceOf(account);
        }

        IERC20Upgradeable(aWNATIVE).safeTransferFrom(account, address(this), amountToWithdraw);
        if (uint(VERSION.V2) == version) {
            V2_LENDING_POOL.withdraw(address(WNATIVE), amountToWithdraw, address(this));
        } else {
            V3_POOL.withdraw(address(WNATIVE), amountToWithdraw, address(this));
        }
        WNATIVE.withdraw(amountToWithdraw);
        _safeTransferETH(account, amountToWithdraw);
        emit Withdraw(account, version, address(WNATIVE), amountToWithdraw);
    }

    /// @notice The user must approve the delegation to this SC for the asset's debtToken.
    function borrow(uint version, address asset, uint amount, uint interestRateMode) public {
        address account = _msgSender();
        if (uint(VERSION.V2) == version) {
            V2_LENDING_POOL.borrow(asset, amount, interestRateMode, 0, account);
        } else {
            V3_POOL.borrow(asset, amount, interestRateMode, 0, account);
        }
        IERC20Upgradeable(asset).safeTransfer(account, amount);
        emit Borrow(account, version, asset, amount, interestRateMode);
    }

    /// @notice It works for only v3.
    function borrowWithPermit(
        address asset, uint amount, uint interestRateMode,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) public {
        address account = _msgSender();
        (, address stableDebtTokenAddress, address variableDebtTokenAddress) = V3_DATA_PROVIDER.getReserveTokensAddresses(asset);
        address debtToken = interestRateMode == 1 ? stableDebtTokenAddress : variableDebtTokenAddress;

        V3_ICreditDelegationToken(debtToken).delegationWithSig(
            account, address(this),
            permitAmount, permitDeadline, permitV, permitR, permitS);

        V3_POOL.borrow(asset, amount, interestRateMode, 0, account);
        IERC20Upgradeable(asset).safeTransfer(account, amount);
        emit Borrow(account, uint(VERSION.V3), asset, amount, interestRateMode);
    }

    function borrowETH(uint version, uint amount, uint interestRateMode) public {
        address account = _msgSender();
        if (uint(VERSION.V2) == version) {
            V2_LENDING_POOL.borrow(address(WNATIVE), amount, interestRateMode, 0, account);
        } else {
            V3_POOL.borrow(address(WNATIVE), amount, interestRateMode, 0, account);
        }
        WNATIVE.withdraw(amount);
        _safeTransferETH(account, amount);
        emit Borrow(account, version, address(WNATIVE), amount, interestRateMode);
    }

    /// @notice It works for only v3.
    function borrowETHWithPermit(
        uint amount, uint interestRateMode,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) public {
        address account = _msgSender();
        address debtToken = interestRateMode == IR_MODE_STABLE ? V3_stableDebtWNATIVE : V3_variableDebtWNATIVE;

        V3_ICreditDelegationToken(debtToken).delegationWithSig(
            account, address(this),
            permitAmount, permitDeadline, permitV, permitR, permitS);

        V3_POOL.borrow(address(WNATIVE), amount, interestRateMode, 0, account);
        WNATIVE.withdraw(amount);
        _safeTransferETH(account, amount);
        emit Borrow(account, uint(VERSION.V3), address(WNATIVE), amount, interestRateMode);
    }

    /// @notice The user must approve this SC for the asset.
    function repay(uint version, address asset, uint amount, uint interestRateMode) public {
        address account = _msgSender();

        uint paybackAmount = amount;
        if (amount == type(uint).max) {
            address stableDebtTokenAddress;
            address variableDebtTokenAddress;

            if (uint(VERSION.V2) == version) {
                (, stableDebtTokenAddress, variableDebtTokenAddress) = V2_DATA_PROVIDER.getReserveTokensAddresses(asset);
            } else {
                (, stableDebtTokenAddress, variableDebtTokenAddress) = V3_DATA_PROVIDER.getReserveTokensAddresses(asset);
            }
            paybackAmount = IERC20Upgradeable(interestRateMode == 1 ? stableDebtTokenAddress : variableDebtTokenAddress).balanceOf(account);
        }

        IERC20Upgradeable(asset).safeTransferFrom(account, address(this), paybackAmount);
        if (uint(VERSION.V2) == version) {
            V2_LENDING_POOL.repay(asset, paybackAmount, interestRateMode, account);
        } else {
            V3_POOL.repay(asset, paybackAmount, interestRateMode, account);
        }

        uint left = IERC20Upgradeable(asset).balanceOf(address(this));
        if (left > 0) IERC20Upgradeable(asset).safeTransfer(account, left);
        emit Repay(account, version, asset, paybackAmount-left, interestRateMode);
    }

    function repayETH(uint version, uint amount, uint interestRateMode) payable public {
        address account = _msgSender();

        uint paybackAmount;
        if (version == uint(VERSION.V2)) {
            paybackAmount = IERC20Upgradeable(interestRateMode == IR_MODE_STABLE ? V2_stableDebtWNATIVE : V2_variableDebtWNATIVE).balanceOf(account);
        } else {
            paybackAmount = IERC20Upgradeable(interestRateMode == IR_MODE_STABLE ? V3_stableDebtWNATIVE : V3_variableDebtWNATIVE).balanceOf(account);
        }

        if (amount < paybackAmount) {
            paybackAmount = amount;
        }

        require(msg.value >= paybackAmount, 'msg.value is less than repayment amount');
        WNATIVE.deposit{value: paybackAmount}();
        if (uint(VERSION.V2) == version) {
            V2_LENDING_POOL.repay(address(WNATIVE), paybackAmount, interestRateMode, account);
        } else {
            V3_POOL.repay(address(WNATIVE), paybackAmount, interestRateMode, account);
        }

        uint left = address(this).balance;
        if (left > 0) _safeTransferETH(account, left);
        emit Repay(account, version, address(WNATIVE), paybackAmount-left, interestRateMode);
    }

    function supplyAndBorrow(uint version,
        address supplyAsset, uint supplyAmount,
        address borrowAsset, uint borrowAmount, uint borrowInterestRateMode
    ) external {
        supply(version, supplyAsset, supplyAmount);
        borrow(version, borrowAsset, borrowAmount, borrowInterestRateMode);
    }

    /// @notice It works for only v3.
    function supplyAndBorrowWithPermit(
        address supplyAsset, uint supplyAmount,
        address borrowAsset, uint borrowAmount, uint borrowInterestRateMode,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) external {
        supply(3, supplyAsset, supplyAmount);
        borrowWithPermit(borrowAsset, borrowAmount, borrowInterestRateMode,
            permitAmount, permitDeadline, permitV, permitR, permitS
        );
    }

    function supplyETHAndBorrow(uint version,
        address borrowAsset, uint borrowAmount, uint borrowInterestRateMode
    ) payable external {
        supplyETH(version);
        borrow(version, borrowAsset, borrowAmount, borrowInterestRateMode);
    }

    function supplyAndBorrowETH(uint version,
        address supplyAsset, uint supplyAmount,
        uint borrowAmount, uint borrowInterestRateMode
    ) external {
        supply(version, supplyAsset, supplyAmount);
        borrowETH(version, borrowAmount, borrowInterestRateMode);
    }

    /// @notice It works for only v3.
    function supplyETHAndBorrowWithPermit(
        address borrowAsset, uint borrowAmount, uint borrowInterestRateMode,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) payable external {
        supplyETH(3);
        borrowWithPermit(borrowAsset, borrowAmount, borrowInterestRateMode,
            permitAmount, permitDeadline, permitV, permitR, permitS
        );
    }

    /// @notice It works for only v3.
    function supplyAndBorrowETHWithPermit(
        address supplyAsset, uint supplyAmount,
        uint borrowAmount, uint borrowInterestRateMode,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) external {
        supply(3, supplyAsset, supplyAmount);
        borrowETHWithPermit(borrowAmount, borrowInterestRateMode,
            permitAmount, permitDeadline, permitV, permitR, permitS
        );
    }

    function repayAndWithdraw(uint version,
        address repayAsset, uint repayAmount, uint repayInterestRateMode,
        address withdrawalAsset, uint withdrawalAmount
    ) external {
        repay(version, repayAsset, repayAmount, repayInterestRateMode);
        withdraw(version, withdrawalAsset, withdrawalAmount);
    }

    function repayAndWithdrawWithPermit(uint version,
        address repayAsset, uint repayAmount, uint repayInterestRateMode,
        address withdrawalAsset, uint withdrawalAmount,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) external {
        repay(version, repayAsset, repayAmount, repayInterestRateMode);
        withdrawWithPermit(version, withdrawalAsset, withdrawalAmount,
            permitAmount, permitDeadline, permitV, permitR, permitS
        );
    }

    function repayETHAndWithdraw(uint version,
        uint repayAmount, uint repayInterestRateMode,
        address withdrawalAsset, uint withdrawalAmount
    ) payable external {
        repayETH(version, repayAmount, repayInterestRateMode);
        withdraw(version, withdrawalAsset, withdrawalAmount);
    }

    function repayAndWithdrawETH(uint version,
        address repayAsset, uint repayAmount, uint repayInterestRateMode,
        uint withdrawalAmount
    ) external {
        repay(version, repayAsset, repayAmount, repayInterestRateMode);
        withdrawETH(version, withdrawalAmount);
    }

    function repayETHAndWithdrawWithPermit(uint version,
        uint repayAmount, uint repayInterestRateMode,
        address withdrawalAsset, uint withdrawalAmount,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) payable external {
        repayETH(version, repayAmount, repayInterestRateMode);
        withdrawWithPermit(version, withdrawalAsset, withdrawalAmount,
            permitAmount, permitDeadline, permitV, permitR, permitS
        );
    }

    function repayAndWithdrawETHWithPermit(uint version,
        address repayAsset, uint repayAmount, uint repayInterestRateMode,
        uint withdrawalAmount,
        uint permitAmount, uint permitDeadline, uint8 permitV, bytes32 permitR, bytes32 permitS
    ) external {
        repay(version, repayAsset, repayAmount, repayInterestRateMode);
        withdrawETHWithPermit(version, withdrawalAmount,
            permitAmount, permitDeadline, permitV, permitR, permitS
        );
    }

    /**
    * @dev Returns a list all rewards of a user, including already accrued and unrealized claimable rewards
    * @param scaledBalanceTokens List of incentivized assets to check eligible distributions. It's used only for v3. It should be address of AToken or VariableDebtToken
    * @param user The address of the user
    * @return The list of reward data
    **/
    function getAllUserRewards(uint version, address[] calldata scaledBalanceTokens, address user) external view returns (Reward[] memory) {
        if (version == uint(VERSION.V2)) {
            address rewardOriginalToken = getV2RewardOriginalToken();
            if (rewardOriginalToken != address(0)) {
                address rewardToken = V2_REWARDS_CONTROLLER.REWARD_TOKEN();
                uint rewardAmount = V2_REWARDS_CONTROLLER.getUserUnclaimedRewards(user);

                Reward[] memory rewards = new Reward[](1);
                rewards[0].token = rewardToken;
                rewards[0].symbol = IERC20UpgradeableExt(rewardToken).symbol();
                rewards[0].decimals = IERC20UpgradeableExt(rewardToken).decimals();
                rewards[0].rewardAmount = rewardAmount;

                // NOTE: It supports only Ethereum in V2 markets
                uint valueInETH = getValueInBaseCurrency(V2_PRICE_ORACLE, rewardOriginalToken, rewardAmount); // It scaled by 18
                int256 ethPrice = V2_BASE_CURRENCY_PRICE_SOURCE.latestAnswer(); // It scaled by 8
                rewards[0].rewardValueInUSD = valueInETH * uint(ethPrice) / 1e18;

                return rewards;
            }
        } else {
            if (address(V3_REWARDS_CONTROLLER) != address(0)) {
                (address[] memory rewardTokens, uint[] memory rewardAmounts) = V3_REWARDS_CONTROLLER.getAllUserRewards(scaledBalanceTokens, user);
                uint length = rewardAmounts.length;

                Reward[] memory rewards = new Reward[](length);
                for (uint i = 0; i < length; i ++) {
                    address rewardToken = rewardTokens[i];
                    uint rewardAmount = rewardAmounts[i];

                    rewards[i].token = rewardToken;
                    rewards[i].symbol = IERC20UpgradeableExt(rewardToken).symbol();
                    rewards[i].decimals = IERC20UpgradeableExt(rewardToken).decimals();
                    rewards[i].rewardAmount = rewardAmount;
                    rewards[i].rewardValueInUSD = getValueInBaseCurrency(V3_PRICE_ORACLE, rewardToken, rewardAmount);
                }
                return rewards;
            }
        }
        return (new Reward[](0));
    }

    /// @notice The returned APRs are scaneld by 18
    function getRewardAPRs(uint version, address asset) external view returns (uint supplyAPR, uint stableBorrowAPR, uint variableBorrowAPR) {
        if (version == uint(VERSION.V2)) {
            address rewardOriginalToken = getV2RewardOriginalToken();
            if (rewardOriginalToken != address(0)) {
                (address aToken, address stableDebtTokenAddress, address variableDebtTokenAddress) = V2_DATA_PROVIDER.getReserveTokensAddresses(asset);
                supplyAPR = getV2RewardAPR(asset, aToken, rewardOriginalToken);
                stableBorrowAPR = getV2RewardAPR(asset, stableDebtTokenAddress, rewardOriginalToken);
                variableBorrowAPR = getV2RewardAPR(asset, variableDebtTokenAddress, rewardOriginalToken);
            }
        } else {
            if (address(V3_REWARDS_CONTROLLER) != address(0)) {
                (address aToken,, address variableDebtTokenAddress) = V3_DATA_PROVIDER.getReserveTokensAddresses(asset);
                supplyAPR = getV3RewardAPR(asset, aToken);
                variableBorrowAPR = getV3RewardAPR(asset, variableDebtTokenAddress);
            }
        }
    }

    function getV2RewardOriginalToken() public view returns(address) {
        if (address(V2_REWARDS_CONTROLLER) == address(0)) return address(0);

        address rewardToken = V2_REWARDS_CONTROLLER.REWARD_TOKEN();
        if (rewardToken == V2_REWARDS_CONTROLLER.STAKE_TOKEN()) {
            return IStakedTokenV2(rewardToken).STAKED_TOKEN();
        }
        return rewardToken;
    }

    function getV2RewardAPR(address asset, address scaledBalanceToken, address reward) internal view returns(uint) {
        uint scaledBalanceTokenInBC = getValueInBaseCurrency(V2_PRICE_ORACLE, asset, IERC20Upgradeable(scaledBalanceToken).totalSupply());
        (, uint emissionPerSecond,) = V2_REWARDS_CONTROLLER.getAssetData(scaledBalanceToken);
        return getValueInBaseCurrency(V2_PRICE_ORACLE, reward, YEAR_IN_SEC * emissionPerSecond) * 1e18 / scaledBalanceTokenInBC;
    }

    function getV3RewardAPR(address asset, address scaledBalanceToken) internal view returns(uint) {
        address[] memory rewards = V3_REWARDS_CONTROLLER.getRewardsByAsset(scaledBalanceToken);
        uint scaledBalanceTokenInBC = getValueInBaseCurrency(V3_PRICE_ORACLE, asset, IERC20Upgradeable(scaledBalanceToken).totalSupply());
        uint rewardsApr;
        for (uint i = 0; i < rewards.length; i ++) {
            address reward = rewards[i];
            (, uint emissionPerSecond,,) = V3_REWARDS_CONTROLLER.getRewardsData(scaledBalanceToken, reward);
            rewardsApr += getValueInBaseCurrency(V3_PRICE_ORACLE, reward, YEAR_IN_SEC * emissionPerSecond) * 1e18 / scaledBalanceTokenInBC;
        }
        return rewardsApr;
    }

    /// @notice The returned price is scaneld by 18
    function getValueInBaseCurrency(IAaveOracle priceOracle, address asset, uint amount) internal view returns(uint) {
        uint priceInBC = priceOracle.getAssetPrice(asset); // The returned price is scaled by 8
        uint8 _decimals = IERC20UpgradeableExt(asset).decimals();
        return amount * priceInBC / (10 ** _decimals);
    }

    /**
    * @dev transfer ETH to an address, revert if it fails.
    * @param to recipient of the transfer
    * @param value the amount to send
    */
    function _safeTransferETH(address to, uint value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

enum VERSION {NONE, V1, V2, V3}

library AaveDataTypes {
  struct TokenData {
    string symbol;
    address tokenAddress;
  }
}

struct TokenDataEx {
  VERSION version;
  string symbol;
  address tokenAddress;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

interface IChainlinkAggregator {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId) external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );

    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20UpgradeableExt is IERC20Upgradeable {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    function versionRecipient() external virtual view returns (string memory);
}

// SPDX-License-Identifier:MIT
pragma solidity 0.8.9;

import "../interfaces/IRelayRecipient.sol";

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address public trustedForwarder;

    /*
     * require a function to be called through GSN only
     */
    modifier trustedForwarderOnly() {
        require(msg.sender == address(trustedForwarder), "Function can only be called through the trusted Forwarder");
        _;
    }

    function isTrustedForwarder(address forwarder) public override view returns(bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 24 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            return msg.sender;
        }
    }
}