// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
library Counters {
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

pragma solidity ^0.8.10;

abstract contract BaseMath {
	uint256 public constant DECIMAL_PRECISION = 1 ether;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ERC20Decimals {
	function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IERC2612Permit {
	/**
	 * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
	 * given `owner`'s signed approval.
	 *
	 * IMPORTANT: The same issues {IERC20-approve} has related to transaction
	 * ordering also apply here.
	 *
	 * Emits an {Approval} event.
	 *
	 * Requirements:
	 *
	 * - `owner` cannot be the zero address.
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
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external;

	/**
	 * @dev Returns the current ERC2612 nonce for `owner`. This value must be
	 * included whenever a signature is generated for {permit}.
	 *
	 * Every successful call to {permit} increases ``owner``'s nonce by one. This
	 * prevents a signature from being used multiple times.
	 */
	function nonces(address owner) external view returns (uint256);
}

abstract contract ERC20Permit is ERC20, IERC2612Permit {
	using Counters for Counters.Counter;

	mapping(address => Counters.Counter) private _nonces;

	// keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
	bytes32 public constant PERMIT_TYPEHASH =
		0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	bytes32 public DOMAIN_SEPARATOR;

	constructor() {
		uint256 chainID;
		assembly {
			chainID := chainid()
		}

		DOMAIN_SEPARATOR = keccak256(
			abi.encode(
				keccak256(
					"EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
				),
				keccak256(bytes(name())),
				keccak256(bytes("1")), // Version
				chainID,
				address(this)
			)
		);
	}

	/**
	 * @dev See {IERC2612Permit-permit}.
	 *
	 */
	function permit(
		address owner,
		address spender,
		uint256 amount,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual override {
		require(block.timestamp <= deadline, "Permit: expired deadline");

		bytes32 hashStruct = keccak256(
			abi.encode(PERMIT_TYPEHASH, owner, spender, amount, _nonces[owner].current(), deadline)
		);

		bytes32 _hash = keccak256(abi.encodePacked(uint16(0x1901), DOMAIN_SEPARATOR, hashStruct));

		address signer = ecrecover(_hash, v, r, s);
		require(signer != address(0) && signer == owner, "ERC20Permit: Invalid signature");

		_nonces[owner].increment();
		_approve(owner, spender, amount);
	}

	/**
	 * @dev See {IERC2612Permit-nonces}.
	 */
	function nonces(address owner) public view override returns (uint256) {
		return _nonces[owner].current();
	}

	function chainId() public view returns (uint256 chainID) {
		assembly {
			chainID := chainid()
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./BaseMath.sol";
import "./GravitaMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IGravitaBase.sol";
import "../Interfaces/IAdminContract.sol";

/*
 * Base contract for VesselManager, BorrowerOperations and StabilityPool. Contains global system constants and
 * common functions.
 */
contract GravitaBase is IGravitaBase, BaseMath, OwnableUpgradeable {
	using SafeMathUpgradeable for uint256;

	struct Colls {
		// tokens and amounts should be the same length
		address[] tokens;
		uint256[] amounts;
	}

	IAdminContract public adminContract;
	IActivePool public activePool;
	IDefaultPool internal defaultPool;

	// --- Gas compensation functions ---

	// Returns the composite debt (drawn debt + gas compensation) of a vessel, for the purpose of ICR calculation
	function _getCompositeDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.add(adminContract.getDebtTokenGasCompensation(_asset));
	}

	function _getNetDebt(address _asset, uint256 _debt) internal view returns (uint256) {
		return _debt.sub(adminContract.getDebtTokenGasCompensation(_asset));
	}

	// Return the amount of ETH to be drawn from a vessel's collateral and sent as gas compensation.
	function _getCollGasCompensation(
		address _asset,
		uint256 _entireColl
	) internal view returns (uint256) {
		return _entireColl / adminContract.getPercentDivisor(_asset);
	}

	function getEntireSystemColl(address _asset) public view returns (uint256 entireSystemColl) {
		uint256 activeColl = adminContract.activePool().getAssetBalance(_asset);
		uint256 liquidatedColl = adminContract.defaultPool().getAssetBalance(_asset);

		return activeColl.add(liquidatedColl);
	}

	function getEntireSystemDebt(address _asset) public view returns (uint256 entireSystemDebt) {
		uint256 activeDebt = adminContract.activePool().getDebtTokenBalance(_asset);
		uint256 closedDebt = adminContract.defaultPool().getDebtTokenBalance(_asset);

		return activeDebt.add(closedDebt);
	}

	function _getTCR(address _asset, uint256 _price) internal view returns (uint256 TCR) {
		uint256 entireSystemColl = getEntireSystemColl(_asset);
		uint256 entireSystemDebt = getEntireSystemDebt(_asset);

		TCR = GravitaMath._computeCR(entireSystemColl, entireSystemDebt, _price);

		return TCR;
	}

	function _checkRecoveryMode(address _asset, uint256 _price) internal view returns (bool) {
		uint256 TCR = _getTCR(_asset, _price);

		return TCR < adminContract.getCcr(_asset);
	}

	function _requireUserAcceptsFee(
		uint256 _fee,
		uint256 _amount,
		uint256 _maxFeePercentage
	) internal view {
		uint256 feePercentage = _fee.mul(adminContract.DECIMAL_PRECISION()).div(_amount);
		require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
	}

	function _revertWrongFuncCaller() internal pure {
		revert("WFC");
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library GravitaMath {
	using SafeMathUpgradeable for uint256;

	uint256 internal constant DECIMAL_PRECISION = 1 ether;

	/* Precision for Nominal ICR (independent of price). Rationale for the value:
	 *
	 * - Making it “too high” could lead to overflows.
	 * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division.
	 *
	 * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
	 * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
	 *
	 */
	uint256 internal constant NICR_PRECISION = 1e20;

	function _min(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a < _b) ? _a : _b;
	}

	function _max(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a : _b;
	}

	/*
	 * Multiply two decimal numbers and use normal rounding rules:
	 * -round product up if 19'th mantissa digit >= 5
	 * -round product down if 19'th mantissa digit < 5
	 *
	 * Used only inside the exponentiation, _decPow().
	 */
	function decMul(uint256 x, uint256 y) internal pure returns (uint256 decProd) {
		uint256 prod_xy = x.mul(y);

		decProd = prod_xy.add(DECIMAL_PRECISION / 2).div(DECIMAL_PRECISION);
	}

	/*
	 * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
	 *
	 * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity.
	 *
	 * Called by two functions that represent time in units of minutes:
	 * 1) VesselManager._calcDecayedBaseRate
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
	function _decPow(uint256 _base, uint256 _minutes) internal pure returns (uint256) {
		if (_minutes > 525600000) {
			_minutes = 525600000;
		} // cap to avoid overflow

		if (_minutes == 0) {
			return DECIMAL_PRECISION;
		}

		uint256 y = DECIMAL_PRECISION;
		uint256 x = _base;
		uint256 n = _minutes;

		// Exponentiation-by-squaring
		while (n > 1) {
			if (n % 2 == 0) {
				x = decMul(x, x);
				n = n.div(2);
			} else {
				// if (n % 2 != 0)
				y = decMul(x, y);
				x = decMul(x, x);
				n = (n.sub(1)).div(2);
			}
		}

		return decMul(x, y);
	}

	function _getAbsoluteDifference(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
	}

	function _computeNominalCR(uint256 _coll, uint256 _debt) internal pure returns (uint256) {
		if (_debt > 0) {
			return _coll.mul(NICR_PRECISION).div(_debt);
		}
		// Return the maximal value for uint256 if the Vessel has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return 2 ** 256 - 1;
		}
	}

	function _computeCR(
		uint256 _coll,
		uint256 _debt,
		uint256 _price
	) internal pure returns (uint256) {
		if (_debt > 0) {
			uint256 newCollRatio = _coll.mul(_price).div(_debt);

			return newCollRatio;
		}
		// Return the maximal value for uint256 if the Vessel has a debt of 0. Represents "infinite" CR.
		else {
			// if (_debt == 0)
			return type(uint256).max;
		}
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// uint128 addition and subtraction, with overflow protection.

library GravitaSafeMath128 {
	function add(uint128 a, uint128 b) internal pure returns (uint128) {
		uint128 c = a + b;
		require(c >= a, "GravitaSafeMath128: addition overflow");

		return c;
	}

	function sub(uint128 a, uint128 b) internal pure returns (uint128) {
		require(b <= a, "GravitaSafeMath128: subtraction overflow");
		uint128 c = a - b;

		return c;
	}
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "./GravitaBase.sol";

/**
 * @notice Base contract for CollSurplusPool and StabilityPool. Inherits from LiquityBase
 * and contains additional array operation functions and _requireCallerIsYetiController()
 */
contract PoolBase is GravitaBase {
	using SafeMathUpgradeable for uint256;
	/**
	 * @dev This empty reserved space is put in place to allow future versions to add new
	 * variables without shifting down storage in the inheritance chain.
	 * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
	 */
	uint256[50] private __gap;

	error PoolBase__AdminOnly();

	/**
	 * @notice More efficient version of sumColls when dealing with all whitelisted tokens.
	 *    Used by pool accounting of tokens inside that pool.
	 * @dev Inspired by left join in relational databases, _coll1 is always taken while
	 *    _tokens and _amounts are just added to that side. _coll1 index is actually equal
	 *    always to the index in YetiController of that token. Time complexity depends
	 *    here on the number of whitelisted tokens = L since that it equals pool coll length.
	 *    Time complexity is therefore O(L)
	 */
	function _leftSumColls(
		Colls memory _coll1,
		address[] memory _tokens,
		uint256[] memory _amounts
	) internal pure returns (uint256[] memory) {
		// If nothing on the right side then return the original.
		if (_amounts.length == 0) {
			return _coll1.amounts;
		}

		uint256 coll1Len = _coll1.amounts.length;
		uint256 tokensLen = _tokens.length;
		// Result will always be coll1 len size.
		uint256[] memory sumAmounts = new uint256[](coll1Len);

		uint256 i = 0;
		uint256 j = 0;

		// Sum through all tokens until either left or right side reaches end.
		while (i < tokensLen && j < coll1Len) {
			// If tokens match up then sum them together.
			if (_tokens[i] == _coll1.tokens[j]) {
				sumAmounts[j] = _coll1.amounts[j].add(_amounts[i]);
				++i;
			}
			// Otherwise just take the left side.
			else {
				sumAmounts[j] = _coll1.amounts[j];
			}
			++j;
		}
		// If right side ran out add the remaining amounts in the left side.
		while (j < coll1Len) {
			sumAmounts[j] = _coll1.amounts[j];
			++j;
		}

		return sumAmounts;
	}

	/**
	 * @notice More efficient version of subColls when dealing with all whitelisted tokens.
	 *    Used by pool accounting of tokens inside that pool.
	 * @dev Inspired by left join in relational databases, _coll1 is always taken while
	 *    _tokens and _amounts are just subbed from that side. _coll1 index is actually equal
	 *    always to the index in YetiController of that token. Time complexity depends
	 *    here on the number of whitelisted tokens = L since that it equals pool coll length.
	 *    Time complexity is therefore O(L)
	 */
	function _leftSubColls(
		Colls memory _coll1,
		address[] memory _subTokens,
		uint256[] memory _subAmounts
	) internal pure returns (uint256[] memory) {
		// If nothing on the right side then return the original.
		if (_subTokens.length == 0) {
			return _coll1.amounts;
		}

		uint256 coll1Len = _coll1.amounts.length;
		uint256 tokensLen = _subTokens.length;
		// Result will always be coll1 len size.
		uint256[] memory diffAmounts = new uint256[](coll1Len);

		uint256 i = 0;
		uint256 j = 0;

		// Sub through all tokens until either left or right side reaches end.
		while (i < tokensLen && j < coll1Len) {
			// If tokens match up then subtract them
			if (_subTokens[i] == _coll1.tokens[j]) {
				diffAmounts[j] = _coll1.amounts[j].sub(_subAmounts[i]);
				++i;
			}
			// Otherwise just take the left side.
			else {
				diffAmounts[j] = _coll1.amounts[j];
			}
			++j;
		}
		// If right side ran out add the remaining amounts in the left side.
		while (j < coll1Len) {
			diffAmounts[j] = _coll1.amounts[j];
			++j;
		}

		return diffAmounts;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.10;

abstract contract ReentrancyGuardUpgradeable {
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

	function __ReentrancyGuard_init() internal {
		__ReentrancyGuard_init_unchained();
	}

	function __ReentrancyGuard_init_unchained() internal {
		require(_status == 0, "ReentrancyGuardUpgradeable: contract is already initialized");
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

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "./ERC20Decimals.sol";

library SafetyTransfer {
	using SafeMathUpgradeable for uint256;

	//_amount is in ether (1e18) and we want to convert it to the token decimal
	function decimalsCorrection(address _token, uint256 _amount)
		internal
		view
		returns (uint256)
	{
		if (_token == address(0)) return _amount;
		if (_amount == 0) return 0;

		uint8 decimals = ERC20Decimals(_token).decimals();
		if (decimals < 18) {
			return _amount.div(10**(18 - decimals));
		}

		return _amount;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./IPool.sol";

interface IActivePool is IPool {

	// --- Events ---

	event ActivePoolDebtUpdated(address _asset, uint256 _debtTokenAmount);
	event ActivePoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---

	function sendAsset(
		address _asset,
		address _account,
		uint256 _amount
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IActivePool.sol";
import "./IDefaultPool.sol";
import "./IPriceFeed.sol";

interface IAdminContract {
	error SafeCheckError(
		string parameter,
		uint256 valueEntered,
		uint256 minValue,
		uint256 maxValue
	);

	// --- Events ---
	event CollateralAdded(address _collateral);
	event MCRChanged(uint256 oldMCR, uint256 newMCR);
	event CCRChanged(uint256 oldCCR, uint256 newCCR);
	event GasCompensationChanged(uint256 oldGasComp, uint256 newGasComp);
	event MinNetDebtChanged(uint256 oldMinNet, uint256 newMinNet);
	event PercentDivisorChanged(uint256 oldPercentDiv, uint256 newPercentDiv);
	event BorrowingFeeChanged(uint256 oldBorrowingFee, uint256 newBorrowingFee);
	event MaxBorrowingFeeChanged(uint256 oldMaxBorrowingFee, uint256 newMaxBorrowingFee);
	event RedemptionFeeFloorChanged(
		uint256 oldRedemptionFeeFloor,
		uint256 newRedemptionFeeFloor
	);
	event MintCapChanged(uint256 oldMintCap, uint256 newMintCap);
	event RedemptionBlockChanged(address _collateral, uint256 _block);
	event PriceFeedChanged(address indexed addr);

	// --- Functions ---
	function DECIMAL_PRECISION() external view returns (uint256);

	function _100pct() external view returns (uint256);

	function activePool() external view returns (IActivePool);

	function defaultPool() external view returns (IDefaultPool);

	function priceFeed() external view returns (IPriceFeed);

	function addNewCollateral(
		address _collateral,
		uint256 _decimals,
		bool _isWrapped
	) external;

	function setAddresses(
		address _communityIssuanceAddress,
		address _activePoolAddress,
		address _defaultPoolAddress,
		address _stabilityPoolAddress,
		address _collSurplusPoolAddress,
		address _priceFeedAddress,
		address _shortTimelock,
		address _longTimelock
	) external;

	function setMCR(address _collateral, uint256 newMCR) external;

	function setCCR(address _collateral, uint256 newCCR) external;

	function sanitizeParameters(address _collateral) external;

	function setAsDefault(address _collateral) external;

	function setAsDefaultWithRemptionBlock(address _collateral, uint256 blockInDays) external;

	function setDebtTokenGasCompensation(address _collateral, uint256 gasCompensation) external;

	function setMinNetDebt(address _collateral, uint256 minNetDebt) external;

	function setPercentDivisor(address _collateral, uint256 precentDivisor) external;

	function setBorrowingFee(address _collateral, uint256 borrowingFee) external;

	function setRedemptionFeeFloor(address _collateral, uint256 redemptionFeeFloor) external;

	function setMintCap(address _collateral, uint256 mintCap) external;

	function setRedemptionBlock(address _collateral, uint256 _block) external;

	function getIndex(address _collateral) external view returns (uint256);

	function getValidCollateral() external view returns (address[] memory);

	function getMcr(address _collateral) external view returns (uint256);

	function getCcr(address _collateral) external view returns (uint256);

	function getDebtTokenGasCompensation(address _collateral) external view returns (uint256);

	function getMinNetDebt(address _collateral) external view returns (uint256);

	function getPercentDivisor(address _collateral) external view returns (uint256);

	function getBorrowingFee(address _collateral) external view returns (uint256);

	function getRedemptionFeeFloor(address _collateral) external view returns (uint256);

	function getRedemptionBlock(address _collateral) external view returns (uint256);

	function getMintCap(address _collateral) external view returns (uint256);

	function getTotalAssetDebt(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IBorrowerOperations {
	// --- Events ---

	event VesselCreated(address indexed _asset, address indexed _borrower, uint256 arrayIndex);
	event VesselUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 stake,
		uint8 operation
	);
	event BorrowingFeePaid(address indexed _asset, address indexed _borrower, uint256 _feeAmount);

	// --- Functions ---

	function setAddresses(
		address _vesselManagerAddress,
		address _stabilityPoolAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _sortedVesselsAddress,
		address _debtTokenAddress,
		address _feeCollectorAddress,
		address _adminContractAddress
	) external;

	function openVessel(
		address _asset,
		uint256 _assetAmount,
		uint256 _debtTokenAmount,
		address _upperHint,
		address _lowerHint
	) external;

	function addColl(
		address _asset,
		uint256 _assetSent,
		address _upperHint,
		address _lowerHint
	) external;

	function moveLiquidatedAssetToVessel(
		address _asset,
		uint256 _amountMoved,
		address _user,
		address _upperHint,
		address _lowerHint
	) external;

	function withdrawColl(
		address _asset,
		uint256 _assetAmount,
		address _upperHint,
		address _lowerHint
	) external;

	function withdrawDebtTokens(
		address _asset,
		uint256 _debtTokenAmount,
		address _upperHint,
		address _lowerHint
	) external;

	function repayDebtTokens(
		address _asset,
		uint256 _debtTokenAmount,
		address _upperHint,
		address _lowerHint
	) external;

	function closeVessel(address _asset) external;

	function adjustVessel(
		address _asset,
		uint256 _assetSent,
		uint256 _collWithdrawal,
		uint256 _debtChange,
		bool isDebtIncrease,
		address _upperHint,
		address _lowerHint
	) external;

	function claimCollateral(address _asset) external;

	function getCompositeDebt(address _asset, uint256 _debt) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IDeposit.sol";

interface ICollSurplusPool is IDeposit {

	// --- Events ---

	event CollBalanceUpdated(address indexed _account, uint256 _newBalance);
	event AssetSent(address _to, uint256 _amount);

	// --- Contract setters ---

	function setAddresses(
		address _activePoolAddress,
		address _borrowerOperationsAddress,
		address _vesselManagerAddress,
		address _vesselManagerOperationsAddress
	) external;

	function getAssetBalance(address _asset) external view returns (uint256);

	function getCollateral(address _asset, address _account) external view returns (uint256);

	function accountSurplus(
		address _asset,
		address _account,
		uint256 _amount
	) external;

	function claimColl(address _asset, address _account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface ICommunityIssuance {
	// --- Events ---

	event TotalGRVTIssuedUpdated(uint256 _totalGRVTIssued);

	// --- Functions ---

	function setAddresses(
		address _GRVTTokenAddress,
		address _stabilityPoolAddress,
		address _adminContract
	) external;

	function issueGRVT() external returns (uint256);

	function sendGRVT(address _account, uint256 _GRVTamount) external;

	function addFundToStabilityPool(uint256 _assignedSupply) external;

	function addFundToStabilityPoolFrom(uint256 _assignedSupply, address _spender) external;

	function setWeeklyGrvtDistribution(uint256 _weeklyReward) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "../Dependencies/ERC20Permit.sol";
import "../Interfaces/IStabilityPool.sol";

abstract contract IDebtToken is ERC20Permit {
	// --- Events ---

	event TokenBalanceUpdated(address _user, uint256 _amount);
	event EmergencyStopMintingCollateral(address _asset, bool state);

	function emergencyStopMinting(address _asset, bool status) external virtual;

	function mint(address _asset, address _account, uint256 _amount) external virtual;

	function mintFromWhitelistedContract(uint256 _amount) external virtual;

	function burnFromWhitelistedContract(uint256 _amount) external virtual;

	function burn(address _account, uint256 _amount) external virtual;

	function sendToPool(address _sender, address poolAddress, uint256 _amount) external virtual;

	function returnFromPool(address poolAddress, address user, uint256 _amount) external virtual;

	function addWhitelist(address _address) external virtual;

	function removeWhitelist(address _address) external virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;
import "./IPool.sol";

interface IDefaultPool is IPool {
	// --- Events ---
	event DefaultPoolDebtUpdated(address _asset, uint256 _debt);
	event DefaultPoolAssetBalanceUpdated(address _asset, uint256 _balance);

	// --- Functions ---
	function sendAssetToActivePool(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IDeposit {
	function receivedERC20(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IAdminContract.sol";

interface IGravitaBase {
	function adminContract() external view returns (IAdminContract);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IDeposit.sol";

interface IPool is IDeposit {

	// --- Events ---

	event AssetSent(address _to, address indexed _asset, uint256 _amount);

	// --- Functions ---

	function getAssetBalance(address _asset) external view returns (uint256);

	function getDebtTokenBalance(address _asset) external view returns (uint256);

	function increaseDebt(address _asset, uint256 _amount) external;

	function decreaseDebt(address _asset, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

pragma solidity ^0.8.10;

interface IPriceFeed {

	// Structs --------------------------------------------------------------------------------------------------------

	struct OracleRecord {
		AggregatorV3Interface chainLinkOracle;
		uint256 timelockRelease;
		bool exists;
		bool isFeedWorking;
		bool isEthIndexed;
	}

	struct FeedResponse {
		uint80 roundId;
		int256 answer;
		uint256 timestamp;
		bool success;
		uint8 decimals;
	}

	// Custom Errors --------------------------------------------------------------------------------------------------

	error UnknownOracleError(address _token);

	// Events ---------------------------------------------------------------------------------------------------------

	event LastGoodPriceUpdated(address indexed token, uint256 _lastGoodPrice);
	event NewOracleRegistered(address token, address chainlinkAggregator, bool isEthIndexed);
	event OracleDeleted(address token, address chainlinkAggregator);
	event PriceFeedStatusUpdated(address token, address oracle, bool isWorking);
	event PriceDeviationAlert(address _token, uint256 _currPrice, uint256 _prevPrice);

	// Functions ------------------------------------------------------------------------------------------------------

	function addOracle(address _token, address _chainlinkOracle, bool _isEthIndexed) external;

	function deleteQueuedOracle(address _token) external;

	function deleteOracle(address _token) external;

	function fetchPrice(address _token) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

// Common interface for the SortedVessels Doubly Linked List.
interface ISortedVessels {
	// --- Events ---

	event NodeAdded(address indexed _asset, address _id, uint256 _NICR);
	event NodeRemoved(address indexed _asset, address _id);

	// --- Functions ---

	function setParams(address _VesselManagerAddress, address _borrowerOperationsAddress)
		external;

	function insert(
		address _asset,
		address _id,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external;

	function remove(address _asset, address _id) external;

	function reInsert(
		address _asset,
		address _id,
		uint256 _newICR,
		address _prevId,
		address _nextId
	) external;

	function contains(address _asset, address _id) external view returns (bool);

	function isFull(address _asset) external view returns (bool);

	function isEmpty(address _asset) external view returns (bool);

	function getSize(address _asset) external view returns (uint256);

	function getMaxSize(address _asset) external view returns (uint256);

	function getFirst(address _asset) external view returns (address);

	function getLast(address _asset) external view returns (address);

	function getNext(address _asset, address _id) external view returns (address);

	function getPrev(address _asset, address _id) external view returns (address);

	function validInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (bool);

	function findInsertPosition(
		address _asset,
		uint256 _ICR,
		address _prevId,
		address _nextId
	) external view returns (address, address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IDeposit.sol";

interface IStabilityPool is IDeposit {
	// --- Events ---

	event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _G);
	event SystemSnapshotUpdated(uint256 _P, uint256 _G);

	event AssetSent(address _asset, address _to, uint256 _amount);
	event GainsWithdrawn(
		address indexed _depositor,
		address[] _collaterals,
		uint256[] _amounts,
		uint256 _debtTokenLoss
	);
	event GRVTPaidToDepositor(address indexed _depositor, uint256 _GRVT);
	event StabilityPoolAssetBalanceUpdated(address _asset, uint256 _newBalance);
	event StabilityPoolDebtTokenBalanceUpdated(uint256 _newBalance);
	event StakeChanged(uint256 _newSystemStake, address _depositor);
	event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);

	event P_Updated(uint256 _P);
	event S_Updated(address _asset, uint256 _S, uint128 _epoch, uint128 _scale);
	event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
	event EpochUpdated(uint128 _currentEpoch);
	event ScaleUpdated(uint128 _currentScale);

	// --- Functions ---

	/*
	 * Called only once on init, to set addresses of other Gravita contracts
	 * Callable only by owner, renounces ownership at the end
	 */
	function setAddresses(
		address _borrowerOperationsAddress,
		address _vesselManagerAddress,
		address _activePoolAddress,
		address _debtTokenAddress,
		address _sortedVesselsAddress,
		address _communityIssuanceAddress,
		address _adminContractAddress
	) external;

	/*
	 * Initial checks:
	 * - Frontend is registered or zero address
	 * - Sender is not a registered frontend
	 * - _amount is not zero
	 * ---
	 * - Triggers a GRVT issuance, based on time passed since the last issuance. The GRVT issuance is shared between *all* depositors and front ends
	 * - Tags the deposit with the provided front end tag param, if it's a new deposit
	 * - Sends depositor's accumulated gains (GRVT, ETH) to depositor
	 * - Sends the tagged front end's accumulated GRVT gains to the tagged front end
	 * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
	 */
	function provideToSP(uint256 _amount) external;

	/*
	 * Initial checks:
	 * - _amount is zero or there are no under collateralized vessels left in the system
	 * - User has a non zero deposit
	 * ---
	 * - Triggers a GRVT issuance, based on time passed since the last issuance. The GRVT issuance is shared between *all* depositors and front ends
	 * - Removes the deposit's front end tag if it is a full withdrawal
	 * - Sends all depositor's accumulated gains (GRVT, ETH) to depositor
	 * - Sends the tagged front end's accumulated GRVT gains to the tagged front end
	 * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
	 *
	 * If _amount > userDeposit, the user withdraws all of their compounded deposit.
	 */
	function withdrawFromSP(uint256 _amount) external;

	/*
	Initial checks:
	 * - Caller is VesselManager
	 * ---
	 * Cancels out the specified debt against the debt token contained in the Stability Pool (as far as possible)
	 * and transfers the Vessel's collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the VesselManager.
	 */
	function offset(uint256 _debt, address _asset, uint256 _coll) external;

	/*
	 * Returns debt tokens held in the pool. Changes when users deposit/withdraw, and when Vessel debt is offset.
	 */
	function getTotalDebtTokenDeposits() external view returns (uint256);

	/*
	 * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
	 */
	function getDepositorGains(
		address _depositor
	) external view returns (address[] memory, uint256[] memory);

	/*
	 * Calculate the GRVT gain earned by a deposit since its last snapshots were taken.
	 * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
	 * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
	 * which they made their deposit.
	 */
	function getDepositorGRVTGain(address _depositor) external view returns (uint256);

	/*
	 * Return the user's compounded deposits.
	 */
	function getCompoundedDebtTokenDeposits(address _depositor) external view returns (uint256);

	/*
	 * Fallback function
	 * Only callable by Active Pool, it just accounts for ETH received
	 * receive() external payable;
	 */

	function addCollateralType(address _collateral) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IActivePool.sol";
import "./ICollSurplusPool.sol";
import "./IDebtToken.sol";
import "./IDefaultPool.sol";
import "./IGravitaBase.sol";
import "./ISortedVessels.sol";
import "./IStabilityPool.sol";
import "./IVesselManagerOperations.sol";

interface IVesselManager is IGravitaBase {
	enum Status {
		nonExistent,
		active,
		closedByOwner,
		closedByLiquidation,
		closedByRedemption
	}

	enum VesselManagerOperation {
		applyPendingRewards,
		liquidateInNormalMode,
		liquidateInRecoveryMode,
		redeemCollateral
	}

	event BaseRateUpdated(address indexed _asset, uint256 _baseRate);
	event LastFeeOpTimeUpdated(address indexed _asset, uint256 _lastFeeOpTime);
	event TotalStakesUpdated(address indexed _asset, uint256 _newTotalStakes);
	event SystemSnapshotsUpdated(address indexed _asset, uint256 _totalStakesSnapshot, uint256 _totalCollateralSnapshot);
	event LTermsUpdated(address indexed _asset, uint256 _L_Coll, uint256 _L_Debt);
	event VesselSnapshotsUpdated(address indexed _asset, uint256 _L_Coll, uint256 _L_Debt);
	event VesselIndexUpdated(address indexed _asset, address _borrower, uint256 _newIndex);

	event VesselUpdated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		uint256 _stake,
		VesselManagerOperation _operation
	);

	error VesselManager__FeeBiggerThanAssetDraw();
	error VesselManager__OnlyOneVessel();

	error VesselManager__OnlyVesselManagerOperations();
	error VesselManager__OnlyBorrowerOperations();
	error VesselManager__OnlyVesselManagerOperationsOrBorrowerOperations();

	struct Vessel {
		address asset;
		uint256 debt;
		uint256 coll;
		uint256 stake;
		Status status;
		uint128 arrayIndex;
	}

	function setAddresses(
		address _borrowerOperationsAddress,
		address _stabilityPoolAddress,
		address _gasPoolAddress,
		address _collSurplusPoolAddress,
		address _debtTokenAddress,
		address _feeCollectorAddress,
		address _sortedVesselsAddress,
		address _vesselManagerOperations,
		address _adminContractAddress
	) external;

	function stabilityPool() external returns (IStabilityPool);

	function debtToken() external returns (IDebtToken);

	function vesselManagerOperations() external returns (IVesselManagerOperations);

	function executeFullRedemption(
		address _asset,
		address _borrower,
		uint256 _newColl
	) external;

	function executePartialRedemption(
		address _asset,
		address _borrower,
		uint256 _newDebt,
		uint256 _newColl,
		uint256 _newNICR,
		address _upperPartialRedemptionHint,
		address _lowerPartialRedemptionHint
	) external;

	function getVesselOwnersCount(address _asset) external view returns (uint256);

	function getVesselFromVesselOwnersArray(address _asset, uint256 _index) external view returns (address);

	function getNominalICR(address _asset, address _borrower) external view returns (uint256);

	function getCurrentICR(
		address _asset,
		address _borrower,
		uint256 _price
	) external view returns (uint256);

	function updateStakeAndTotalStakes(address _asset, address _borrower) external returns (uint256);

	function updateVesselRewardSnapshots(address _asset, address _borrower) external;

	function addVesselOwnerToArray(address _asset, address _borrower) external returns (uint256 index);

	function applyPendingRewards(address _asset, address _borrower) external;

	function getPendingAssetReward(address _asset, address _borrower) external view returns (uint256);

	function getPendingDebtTokenReward(address _asset, address _borrower) external view returns (uint256);

	function hasPendingRewards(address _asset, address _borrower) external view returns (bool);

	function getEntireDebtAndColl(address _asset, address _borrower)
		external
		view
		returns (
			uint256 debt,
			uint256 coll,
			uint256 pendingDebtTokenReward,
			uint256 pendingAssetReward
		);

	function closeVessel(address _asset, address _borrower) external;

	function closeVesselLiquidation(address _asset, address _borrower) external;

	function removeStake(address _asset, address _borrower) external;

	function getRedemptionRate(address _asset) external view returns (uint256);

	function getRedemptionRateWithDecay(address _asset) external view returns (uint256);

	function getRedemptionFeeWithDecay(address _asset, uint256 _assetDraw) external view returns (uint256);

	function getBorrowingRate(address _asset) external view returns (uint256);

	function getBorrowingFee(address _asset, uint256 _debtTokenAmount) external view returns (uint256);

	function getVesselStatus(address _asset, address _borrower) external view returns (uint256);

	function getVesselStake(address _asset, address _borrower) external view returns (uint256);

	function getVesselDebt(address _asset, address _borrower) external view returns (uint256);

	function getVesselColl(address _asset, address _borrower) external view returns (uint256);

	function setVesselStatus(
		address _asset,
		address _borrower,
		uint256 num
	) external;

	function increaseVesselColl(
		address _asset,
		address _borrower,
		uint256 _collIncrease
	) external returns (uint256);

	function decreaseVesselColl(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function increaseVesselDebt(
		address _asset,
		address _borrower,
		uint256 _debtIncrease
	) external returns (uint256);

	function decreaseVesselDebt(
		address _asset,
		address _borrower,
		uint256 _collDecrease
	) external returns (uint256);

	function getTCR(address _asset, uint256 _price) external view returns (uint256);

	function checkRecoveryMode(address _asset, uint256 _price) external returns (bool);

	function sortedVessels() external returns (ISortedVessels);

	function isValidFirstRedemptionHint(
		address _asset,
		address _firstRedemptionHint,
		uint256 _price
	) external returns (bool);

	function updateBaseRateFromRedemption(
		address _asset,
		uint256 _assetDrawn,
		uint256 _price,
		uint256 _totalDebtTokenSupply
	) external returns (uint256);

	function getRedemptionFee(address _asset, uint256 _assetDraw) external view returns (uint256);

	function finalizeRedemption(
		address _asset,
		address _receiver,
		uint256 _debtToRedeem,
		uint256 _fee,
		uint256 _totalRedemptionRewards
	) external;

	function redistributeDebtAndColl(
		address _asset,
		uint256 _debt,
		uint256 _coll,
		uint256 _debtToOffset,
		uint256 _collToSendToStabilityPool
	) external;

	function updateSystemSnapshots_excludeCollRemainder(address _asset, uint256 _collRemainder) external;

	function movePendingVesselRewardsToActivePool(
		address _asset,
		uint256 _debtTokenAmount,
		uint256 _assetAmount
	) external;

	function isVesselActive(address _asset, address _borrower) external view returns (bool);

	function sendGasCompensation(
		address _asset,
		address _liquidator,
		uint256 _debtTokenAmount,
		uint256 _assetAmount
	) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./IGravitaBase.sol";
import "./IVesselManager.sol";

interface IVesselManagerOperations is IGravitaBase {
	// Events -----------------------------------------------------------------------------------------------------------

	event Redemption(
		address indexed _asset,
		uint256 _attemptedDebtAmount,
		uint256 _actualDebtAmount,
		uint256 _collSent,
		uint256 _collFee
	);

	event Liquidation(
		address indexed _asset,
		uint256 _liquidatedDebt,
		uint256 _liquidatedColl,
		uint256 _collGasCompensation,
		uint256 _debtTokenGasCompensation
	);

	event VesselLiquidated(
		address indexed _asset,
		address indexed _borrower,
		uint256 _debt,
		uint256 _coll,
		IVesselManager.VesselManagerOperation _operation
	);

	// Custom Errors ----------------------------------------------------------------------------------------------------

	error VesselManagerOperations__CalldataEmptyArray();
	error VesselManagerOperations__EmptyAmount();
	error VesselManagerOperations__FeePercentOutOfBounds(uint256 lowerBoundary, uint256 upperBoundary);
	error VesselManagerOperations__InsufficientDebtTokenBalance(uint256 availableBalance);
	error VesselManagerOperations__NothingToLiquidate();
	error VesselManagerOperations__OnlyVesselManager();
	error VesselManagerOperations__RedemptionIsBlocked();
	error VesselManagerOperations__TCRMustBeAboveMCR(uint256 tcr, uint256 mcr);
	error VesselManagerOperations__UnableToRedeemAnyAmount();
	error VesselManagerOperations__VesselNotActive();

	// Structs ----------------------------------------------------------------------------------------------------------

	struct RedemptionTotals {
		uint256 remainingDebt;
		uint256 totalDebtToRedeem;
		uint256 totalCollDrawn;
		uint256 collFee;
		uint256 collToSendToRedeemer;
		uint256 decayedBaseRate;
		uint256 price;
		uint256 totalDebtTokenSupplyAtStart;
	}

	struct SingleRedemptionValues {
		uint256 debtLot;
		uint256 collLot;
		bool cancelledPartial;
	}

	struct LiquidationTotals {
		uint256 totalCollInSequence;
		uint256 totalDebtInSequence;
		uint256 totalCollGasCompensation;
		uint256 totalDebtTokenGasCompensation;
		uint256 totalDebtToOffset;
		uint256 totalCollToSendToSP;
		uint256 totalDebtToRedistribute;
		uint256 totalCollToRedistribute;
		uint256 totalCollSurplus;
	}

	struct LiquidationValues {
		uint256 entireVesselDebt;
		uint256 entireVesselColl;
		uint256 collGasCompensation;
		uint256 debtTokenGasCompensation;
		uint256 debtToOffset;
		uint256 collToSendToSP;
		uint256 debtToRedistribute;
		uint256 collToRedistribute;
		uint256 collSurplus;
	}

	struct LocalVariables_InnerSingleLiquidateFunction {
		uint256 collToLiquidate;
		uint256 pendingDebtReward;
		uint256 pendingCollReward;
	}

	struct LocalVariables_OuterLiquidationFunction {
		uint256 price;
		uint256 debtTokenInStabPool;
		bool recoveryModeAtStart;
		uint256 liquidatedDebt;
		uint256 liquidatedColl;
	}

	struct LocalVariables_LiquidationSequence {
		uint256 remainingDebtTokenInStabPool;
		uint256 i;
		uint256 ICR;
		address user;
		bool backToNormalMode;
		uint256 entireSystemDebt;
		uint256 entireSystemColl;
	}

	struct LocalVariables_AssetBorrowerPrice {
		address _asset;
		address _borrower;
		uint256 _price;
	}

	// Functions --------------------------------------------------------------------------------------------------------

	function setAddresses(
		address _vesselManagerAddress,
		address _sortedVesselsAddress,
		address _stabilityPoolAddress,
		address _collSurplusPoolAddress,
		address _debtToken,
		address _adminContractAddress
	) external;

	function liquidate(address _asset, address _borrower) external;

	function liquidateVessels(address _asset, uint256 _n) external;

	function batchLiquidateVessels(address _asset, address[] memory _vesselArray) external;

	function redeemCollateral(
		address _asset,
		uint256 _debtTokenAmount,
		address _upperPartialRedemptionHint,
		address _lowerPartialRedemptionHint,
		address _firstRedemptionHint,
		uint256 _partialRedemptionHintNICR,
		uint256 _maxIterations,
		uint256 _maxFeePercentage
	) external;

	function getRedemptionHints(
		address _asset,
		uint256 _debtTokenAmount,
		uint256 _price,
		uint256 _maxIterations
	)
		external
		returns (
			address firstRedemptionHint,
			uint256 partialRedemptionHintNICR,
			uint256 truncatedDebtTokenAmount
		);

	function getApproxHint(
		address _asset,
		uint256 _CR,
		uint256 _numTrials,
		uint256 _inputRandomSeed
	)
		external
		returns (
			address hintAddress,
			uint256 diff,
			uint256 latestRandomSeed
		);

	function computeNominalCR(uint256 _coll, uint256 _debt) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./Dependencies/GravitaBase.sol";
import "./Dependencies/GravitaSafeMath128.sol";
import "./Dependencies/PoolBase.sol";
import "./Dependencies/ReentrancyGuardUpgradeable.sol";
import "./Dependencies/SafetyTransfer.sol";

import "./Interfaces/IAdminContract.sol";
import "./Interfaces/IBorrowerOperations.sol";
import "./Interfaces/ICommunityIssuance.sol";
import "./Interfaces/IDebtToken.sol";
import "./Interfaces/ISortedVessels.sol";
import "./Interfaces/IStabilityPool.sol";
import "./Interfaces/IVesselManager.sol";

/**
 * @title The Stability Pool holds debt tokens deposited by Stability Pool depositors.
 * @dev When a vessel is liquidated, then depending on system conditions, some of its debt tokens debt gets offset with
 * debt tokens in the Stability Pool: that is, the offset debt evaporates, and an equal amount of debt tokens tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a debt tokens loss, in proportion to their deposit as a share of total deposits.
 * They also receive an Collateral gain, as the amount of collateral of the liquidated vessel is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total debt tokens in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 *
 * --- IMPLEMENTATION ---
 *
 * We use a highly scalable method of tracking deposits and Collateral gains that has O(1) complexity.
 *
 * When a liquidation occurs, rather than updating each depositor's deposit and Collateral gain, we simply update two state variables:
 * a product P, and a sum S. These are kept track for each type of collateral.
 *
 * A mathematical manipulation allows us to factor out the initial deposit, and accurately track all depositors' compounded deposits
 * and accumulated Collateral amount gains over time, as liquidations occur, using just these two variables P and S. When depositors join the
 * Stability Pool, they get a snapshot of the latest P and S: P_t and S_t, respectively.
 *
 * The formula for a depositor's accumulated Collateral amount gain is derived here:
 * https://github.com/liquity/dev/blob/main/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * For a given deposit d_t, the ratio P/P_t tells us the factor by which a deposit has decreased since it joined the Stability Pool,
 * and the term d_t * (S - S_t)/P_t gives us the deposit's total accumulated Collateral amount gain.
 *
 * Each liquidation updates the product P and sum S. After a series of liquidations, a compounded deposit and corresponding Collateral amount gain
 * can be calculated using the initial deposit, the depositor’s snapshots of P and S, and the latest values of P and S.
 *
 * Any time a depositor updates their deposit (withdrawal, top-up) their accumulated Collateral amount gain is paid out, their new deposit is recorded
 * (based on their latest compounded deposit and modified by the withdrawal/top-up), and they receive new snapshots of the latest P and S.
 * Essentially, they make a fresh deposit that overwrites the old one.
 *
 *
 * --- SCALE FACTOR ---
 *
 * Since P is a running product in range ]0,1] that is always-decreasing, it should never reach 0 when multiplied by a number in range ]0,1[.
 * Unfortunately, Solidity floor division always reaches 0, sooner or later.
 *
 * A series of liquidations that nearly empty the Pool (and thus each multiply P by a very small number in range ]0,1[ ) may push P
 * to its 18 digit decimal limit, and round it to 0, when in fact the Pool hasn't been emptied: this would break deposit tracking.
 *
 * So, to track P accurately, we use a scale factor: if a liquidation would cause P to decrease to <1e-9 (and be rounded to 0 by Solidity),
 * we first multiply P by 1e9, and increment a currentScale factor by 1.
 *
 * The added benefit of using 1e9 for the scale factor (rather than 1e18) is that it ensures negligible precision loss close to the
 * scale boundary: when P is at its minimum value of 1e9, the relative precision loss in P due to floor division is only on the
 * order of 1e-9.
 *
 * --- EPOCHS ---
 *
 * Whenever a liquidation fully empties the Stability Pool, all deposits should become 0. However, setting P to 0 would make P be 0
 * forever, and break all future reward calculations.
 *
 * So, every time the Stability Pool is emptied by a liquidation, we reset P = 1 and currentScale = 0, and increment the currentEpoch by 1.
 *
 * --- TRACKING DEPOSIT OVER SCALE CHANGES AND EPOCHS ---
 *
 * When a deposit is made, it gets snapshots of the currentEpoch and the currentScale.
 *
 * When calculating a compounded deposit, we compare the current epoch to the deposit's epoch snapshot. If the current epoch is newer,
 * then the deposit was present during a pool-emptying liquidation, and necessarily has been depleted to 0.
 *
 * Otherwise, we then compare the current scale to the deposit's scale snapshot. If they're equal, the compounded deposit is given by d_t * P/P_t.
 * If it spans one scale change, it is given by d_t * P/(P_t * 1e9). If it spans more than one scale change, we define the compounded deposit
 * as 0, since it is now less than 1e-9'th of its initial value (e.g. a deposit of 1 billion debt tokens has depleted to < 1 debt token).
 *
 *
 *  --- TRACKING DEPOSITOR'S COLLATERAL AMOUNT GAIN OVER SCALE CHANGES AND EPOCHS ---
 *
 * In the current epoch, the latest value of S is stored upon each scale change, and the mapping (scale -> S) is stored for each epoch.
 *
 * This allows us to calculate a deposit's accumulated Collateral amount gain, during the epoch in which the deposit was non-zero and earned Collateral amount.
 *
 * We calculate the depositor's accumulated Collateral amount gain for the scale at which they made the deposit, using the Collateral amount gain formula:
 * e_1 = d_t * (S - S_t) / P_t
 *
 * and also for scale after, taking care to divide the latter by a factor of 1e9:
 * e_2 = d_t * S / (P_t * 1e9)
 *
 * The gain in the second scale will be full, as the starting point was in the previous scale, thus no need to subtract anything.
 * The deposit therefore was present for reward events from the beginning of that second scale.
 *
 *        S_i-S_t + S_{i+1}
 *      .<--------.------------>
 *      .         .
 *      . S_i     .   S_{i+1}
 *   <--.-------->.<----------->
 *   S_t.         .
 *   <->.         .
 *      t         .
 *  |---+---------|-------------|-----...
 *         i            i+1
 *
 * The sum of (e_1 + e_2) captures the depositor's total accumulated Collateral amount gain, handling the case where their
 * deposit spanned one scale change. We only care about gains across one scale change, since the compounded
 * deposit is defined as being 0 once it has spanned more than one scale change.
 *
 *
 * --- UPDATING P WHEN A LIQUIDATION OCCURS ---
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / Collateral amount gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 *
 * --- Gravita ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An Gravita issuance event occurs at every deposit operation, and every liquidation.
 *
 * All deposits earn a share of the issued Gravita in proportion to the deposit as a share of total deposits.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#lqty-issuance-to-stability-providers
 *
 * We use the same mathematical product-sum approach to track Gravita gains for depositors, where 'G' is the sum corresponding to Gravita gains.
 * The product P (and snapshot P_t) is re-used, as the ratio P/P_t tracks a deposit's depletion due to liquidations.
 *
 */
contract StabilityPool is OwnableUpgradeable, ReentrancyGuardUpgradeable, PoolBase, IStabilityPool {
	using SafeMathUpgradeable for uint256;
	using GravitaSafeMath128 for uint128;
	using SafeERC20Upgradeable for IERC20Upgradeable;

	string public constant NAME = "StabilityPool";

	bool public isInitialized;

	IBorrowerOperations public borrowerOperations;
	IVesselManager public vesselManager;
	IDebtToken public debtToken;
	ISortedVessels public sortedVessels;
	ICommunityIssuance public communityIssuance;
	IAdminContract public controller;

	// Tracker for debtToken held in the pool. Changes when users deposit/withdraw, and when Vessel debt is offset.
	uint256 internal totalDebtTokenDeposits;

	// totalColl.tokens and totalColl.amounts should be the same length and
	// always be the same length as adminContract.validCollaterals().
	// Anytime a new collateral is added to AdminContract, both lists are lengthened
	Colls internal totalColl;

	// Mapping from user address => pending collaterals to claim still
	// Must always be sorted by whitelist to keep leftSumColls functionality
	mapping(address => Colls) pendingCollGains;

	// --- Data structures ---

	struct Snapshots {
		mapping(address => uint256) S;
		uint256 P;
		uint256 G;
		uint128 scale;
		uint128 epoch;
	}

	mapping(address => uint256) public deposits; // depositor address -> deposit amount

	/*
	 * depositSnapshots maintains an entry for each depositor
	 * that tracks P, S, G, scale, and epoch.
	 * depositor's snapshot is updated only when they
	 * deposit or withdraw from stability pool
	 * depositSnapshots are used to allocate GRVT rewards, calculate compoundedDepositAmount
	 * and to calculate how much Collateral amount the depositor is entitled to
	 */
	mapping(address => Snapshots) public depositSnapshots; // depositor address -> snapshots struct

	/*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
	 * after a series of liquidations have occurred, each of which cancel some debt tokens debt with the deposit.
	 *
	 * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
	 * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
	 */
	uint256 public P;

	uint256 public constant SCALE_FACTOR = 1e9;

	// Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
	uint128 public currentScale;

	// With each offset that fully empties the Pool, the epoch is incremented by 1
	uint128 public currentEpoch;

	/* Collateral amount Gain sum 'S': During its lifetime, each deposit d_t earns an Collateral amount gain of ( d_t * [S - S_t] )/P_t,
	 * where S_t is the depositor's snapshot of S taken at the time t when the deposit was made.
	 *
	 * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
	 *
	 * - The inner mapping records the (scale => sum)
	 * - The middle mapping records (epoch => (scale => sum))
	 * - The outer mapping records (collateralType => (epoch => (scale => sum)))
	 */
	mapping(address => mapping(uint128 => mapping(uint128 => uint256))) public epochToScaleToSum;

	/*
	 * Similarly, the sum 'G' is used to calculate GRVT gains. During it's lifetime, each deposit d_t earns a GRVT gain of
	 *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
	 *
	 *  GRVT reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
	 *  In each case, the GRVT reward is issued (i.e. G is updated), before other state changes are made.
	 */
	mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

	// Error tracker for the error correction in the GRVT issuance calculation
	uint256 public lastGRVTError;
	// Error trackers for the error correction in the offset calculation
	uint256[] public lastAssetError_Offset;
	uint256 public lastDebtTokenLossError_Offset;

	// --- Contract setters ---

	function setAddresses(
		address _borrowerOperationsAddress,
		address _vesselManagerAddress,
		address _activePoolAddress,
		address _debtTokenAddress,
		address _sortedVesselsAddress,
		address _communityIssuanceAddress,
		address _adminContractAddress
	) external initializer override {
		require(!isInitialized, "StabilityPool: Already initialized");

		isInitialized = true;
		__Ownable_init();
		__ReentrancyGuard_init();

		borrowerOperations = IBorrowerOperations(_borrowerOperationsAddress);
		vesselManager = IVesselManager(_vesselManagerAddress);
		activePool = IActivePool(_activePoolAddress);
		debtToken = IDebtToken(_debtTokenAddress);
		sortedVessels = ISortedVessels(_sortedVesselsAddress);
		communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
		adminContract = IAdminContract(_adminContractAddress);

		P = DECIMAL_PRECISION;

		renounceOwnership();
	}

	// --- Getters for public variables. Required by IPool interface ---

	/**
	 * @notice get collateral balance in the SP for a given collateral type
	 * @dev Not necessarily this contract's actual collateral balance;
	 * just what is stored in state
	 * @param _collateral address of the collateral to get amount of
	 * @return amount of this specific collateral
	 */
	function getCollateral(address _collateral) external view returns (uint256) {
		uint256 collateralIndex = adminContract.getIndex(_collateral);
		return totalColl.amounts[collateralIndex];
	}

	/**
	 * @notice getter function
	 * @dev gets collateral from totalColl
	 * This is not necessarily the contract's actual collateral balance;
	 * just what is stored in state
	 * @return tokens and amounts
	 */
	function getAllCollateral() external view returns (address[] memory, uint256[] memory) {
		return (totalColl.tokens, totalColl.amounts);
	}

	/**
	 * @notice getter function
	 * @dev gets total debtToken from deposits
	 * @return totalDebtTokenDeposits
	 */
	function getTotalDebtTokenDeposits() external view override returns (uint256) {
		return totalDebtTokenDeposits;
	}

	// --- External Depositor Functions ---

	/**
	 * @notice Used to provide debt tokens to the stability Pool
	 * @dev Triggers a GRVT issuance, based on time passed since the last issuance.
	 * The GRVT issuance is shared between *all* depositors
	 * - Sends depositor's accumulated gains (GRVT, collateral assets) to depositor
	 * - Increases deposit stake, and takes new snapshots for each.
	 * @param _amount amount of asset provided
	 */
	function provideToSP(uint256 _amount) external override nonReentrant {
		_requireNonZeroAmount(_amount);

		uint256 initialDeposit = deposits[msg.sender];

		ICommunityIssuance communityIssuanceCached = communityIssuance;

		_triggerGRVTIssuance(communityIssuanceCached);

		(address[] memory gainAssets, uint256[] memory gainAmounts) = getDepositorGains(msg.sender);
		uint256 compoundedDeposit = getCompoundedDebtTokenDeposits(msg.sender);
		uint256 loss = initialDeposit.sub(compoundedDeposit); // Needed only for event log

		// First pay out any GRVT gains
		_payOutGRVTGains(communityIssuanceCached, msg.sender);

		// just pulls debtTokens into the pool, updates totalDeposits variable for the stability pool and throws an event
		_sendToStabilityPool(msg.sender, _amount);

		uint256 newDeposit = compoundedDeposit.add(_amount);
		_updateDepositAndSnapshots(msg.sender, newDeposit);
		emit UserDepositChanged(msg.sender, newDeposit);

		emit GainsWithdrawn(msg.sender, gainAssets, gainAmounts, loss); // loss required for event log

		// send any collateral gains accrued to the depositor
		_sendGainsToDepositor(msg.sender, gainAssets, gainAmounts);
	}

	function withdrawFromSP(uint256 _amount) external {
		(address[] memory assets, uint256[] memory amounts) = _withdrawFromSP(_amount);
		_sendGainsToDepositor(msg.sender, assets, amounts);
	}

	/**
	 * @notice withdraw from the stability pool
	 * @dev see withdrawFromSPAndSwap
	 * @param _amount debtToken amount to withdraw
	 * @return assets , amounts address of assets withdrawn, amount of asset withdrawn
	 */
	function _withdrawFromSP(uint256 _amount) internal returns (address[] memory assets, uint256[] memory amounts) {
		if (_amount != 0) {
			_requireNoUnderCollateralizedVessels();
		}
		uint256 initialDeposit = deposits[msg.sender];
		_requireUserHasDeposit(initialDeposit);

		ICommunityIssuance communityIssuanceCached = communityIssuance;
		_triggerGRVTIssuance(communityIssuanceCached);

		(assets, amounts) = getDepositorGains(msg.sender);

		uint256 compoundedDeposit = getCompoundedDebtTokenDeposits(msg.sender);

		uint256 debtTokensToWithdraw = GravitaMath._min(_amount, compoundedDeposit);
		uint256 loss = initialDeposit.sub(compoundedDeposit); // Needed only for event log

		// First pay out any GRVT gains
		_payOutGRVTGains(communityIssuanceCached, msg.sender);
		_sendToDepositor(msg.sender, debtTokensToWithdraw);

		// Update deposit
		uint256 newDeposit = compoundedDeposit.sub(debtTokensToWithdraw);
		_updateDepositAndSnapshots(msg.sender, newDeposit);
		emit UserDepositChanged(msg.sender, newDeposit);

		emit GainsWithdrawn(msg.sender, assets, amounts, loss); // loss required for event log
	}

	// --- GRVT issuance functions ---

	function _triggerGRVTIssuance(ICommunityIssuance _communityIssuance) internal {
		if (address(_communityIssuance) != address(0)) {
			uint256 GRVTIssuance = _communityIssuance.issueGRVT();
			_updateG(GRVTIssuance);
		}
	}

	function _updateG(uint256 _GRVTIssuance) internal {
		uint256 cachedTotalDebtTokenDeposits = totalDebtTokenDeposits; // cached to save an SLOAD
		/*
		 * When total deposits is 0, G is not updated. In this case, the GRVT issued can not be obtained by later
		 * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
		 *
		 */
		if (cachedTotalDebtTokenDeposits == 0 || _GRVTIssuance == 0) {
			return;
		}
		uint256 GRVTPerUnitStaked = _computeGRVTPerUnitStaked(_GRVTIssuance, cachedTotalDebtTokenDeposits);
		uint256 marginalGRVTGain = GRVTPerUnitStaked.mul(P);
		epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[currentEpoch][currentScale].add(marginalGRVTGain);
		emit G_Updated(epochToScaleToG[currentEpoch][currentScale], currentEpoch, currentScale);
	}

	function _computeGRVTPerUnitStaked(uint256 _GRVTIssuance, uint256 _totalDeposits) internal returns (uint256) {
		/*
		 * Calculate the GRVT-per-unit staked.  Division uses a "feedback" error correction, to keep the
		 * cumulative error low in the running total G:
		 *
		 * 1) Form a numerator which compensates for the floor division error that occurred the last time this
		 * function was called.
		 * 2) Calculate "per-unit-staked" ratio.
		 * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
		 * 4) Store this error for use in the next correction when this function is called.
		 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
		 */
		uint256 GRVTNumerator = _GRVTIssuance.mul(DECIMAL_PRECISION).add(lastGRVTError);
		uint256 GRVTPerUnitStaked = GRVTNumerator.div(_totalDeposits);
		lastGRVTError = GRVTNumerator.sub(GRVTPerUnitStaked.mul(_totalDeposits));
		return GRVTPerUnitStaked;
	}

	// --- Liquidation functions ---

	/**
	 * @notice sets the offset for liquidation
	 * @dev Cancels out the specified debt against the debtTokens contained in the Stability Pool (as far as possible)
	 * and transfers the Vessel's collateral from ActivePool to StabilityPool.
	 * Only called by liquidation functions in the VesselManager.
	 * @param _debtToOffset how much debt to offset
	 * @param _asset token address
	 * @param _amountAdded token amount as uint256
	 */
	function offset(
		uint256 _debtToOffset,
		address _asset,
		uint256 _amountAdded
	) external {
		_requireCallerIsVesselManager();
		uint256 cachedTotalDebtTokenDeposits = totalDebtTokenDeposits; // cached to save an SLOAD
		if (cachedTotalDebtTokenDeposits == 0 || _debtToOffset == 0) {
			return;
		}
		_triggerGRVTIssuance(communityIssuance);
		(uint256 collGainPerUnitStaked, uint256 debtLossPerUnitStaked) = _computeRewardsPerUnitStaked(
			_asset,
			_amountAdded,
			_debtToOffset,
			cachedTotalDebtTokenDeposits
		);

		_updateRewardSumAndProduct(_asset, collGainPerUnitStaked, debtLossPerUnitStaked); // updates S and P
		_moveOffsetCollAndDebt(_asset, _amountAdded, _debtToOffset);
	}

	// --- Offset helper functions ---

	/**
	 * @notice Compute the debtToken and Collateral amount rewards. Uses a "feedback" error correction, to keep
	 * the cumulative error in the P and S state variables low:
	 *
	 * @dev 1) Form numerators which compensate for the floor division errors that occurred the last time this
	 * function was called.
	 * 2) Calculate "per-unit-staked" ratios.
	 * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
	 * 4) Store these errors for use in the next correction when this function is called.
	 * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
	 * @param _asset Address of token
	 * @param _amountAdded amount as uint256
	 * @param _debtToOffset amount of debt to offset
	 * @param _totalDeposits How much user has deposited
	 */
	function _computeRewardsPerUnitStaked(
		address _asset,
		uint256 _amountAdded,
		uint256 _debtToOffset,
		uint256 _totalDeposits
	) internal returns (uint256 collGainPerUnitStaked, uint256 debtLossPerUnitStaked) {
		uint256 currentP = P;
		uint256 index = adminContract.getIndex(_asset);
		uint256 collateralNumerator = _amountAdded.mul(DECIMAL_PRECISION).add(lastAssetError_Offset[index]);
		require(_debtToOffset <= _totalDeposits, "StabilityPool: Debt is larger than totalDeposits");
		if (_debtToOffset == _totalDeposits) {
			debtLossPerUnitStaked = DECIMAL_PRECISION; // When the Pool depletes to 0, so does each deposit
			lastDebtTokenLossError_Offset = 0;
		} else {
			uint256 lossNumerator = _debtToOffset.mul(DECIMAL_PRECISION).sub(lastDebtTokenLossError_Offset);
			/*
			 * Add 1 to make error in quotient positive. We want "slightly too much" loss,
			 * which ensures the error in any given compoundedDeposit favors the Stability Pool.
			 */
			debtLossPerUnitStaked = (lossNumerator.div(_totalDeposits)).add(1);
			lastDebtTokenLossError_Offset = (debtLossPerUnitStaked.mul(_totalDeposits)).sub(lossNumerator);
		}
		collGainPerUnitStaked = collateralNumerator.mul(currentP).div(_totalDeposits);
		lastAssetError_Offset[index] = collateralNumerator.sub(collGainPerUnitStaked.mul(_totalDeposits).div(currentP));
	}

	/**
	 * @notice add a collateral
	 * @dev should be called anytime a collateral is added to controller
	 * keeps all arrays the correct length
	 * @param _collateral address of collateral to add
	 */
	function addCollateralType(address _collateral) external {
		_requireCallerIsAdminContract();
		lastAssetError_Offset.push(0);
		totalColl.tokens.push(_collateral);
		totalColl.amounts.push(0);
	}

	// Update the Stability Pool reward sum S and product P
	function _updateRewardSumAndProduct(
		address _asset,
		uint256 _AssetGainPerUnitStaked,
		uint256 _lossPerUnitStaked
	) internal {
		require(_lossPerUnitStaked <= DECIMAL_PRECISION, "StabilityPool: Loss < 1");
		uint256 currentP = P;
		uint256 newP;
		/*
		 * The newProductFactor is the factor by which to change all deposits, due to the depletion of Stability Pool debt tokens in the liquidation.
		 * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - lossPerUnitStaked)
		 */
		uint256 newProductFactor = uint256(DECIMAL_PRECISION).sub(_lossPerUnitStaked);
		uint128 currentScaleCached = currentScale;
		uint128 currentEpochCached = currentEpoch;
		uint256 currentS = epochToScaleToSum[_asset][currentEpochCached][currentScaleCached];
		uint256 newS = currentS.add(_AssetGainPerUnitStaked);
		epochToScaleToSum[_asset][currentEpochCached][currentScaleCached] = newS;
		emit S_Updated(_asset, newS, currentEpochCached, currentScaleCached);

		// If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
		if (newProductFactor == 0) {
			currentEpoch = currentEpochCached.add(1);
			emit EpochUpdated(currentEpoch);
			currentScale = 0;
			emit ScaleUpdated(currentScale);
			newP = DECIMAL_PRECISION;

			// If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
		} else if (currentP.mul(newProductFactor).div(DECIMAL_PRECISION) < SCALE_FACTOR) {
			newP = currentP.mul(newProductFactor).mul(SCALE_FACTOR).div(DECIMAL_PRECISION);
			currentScale = currentScaleCached.add(1);
			emit ScaleUpdated(currentScale);
		} else {
			newP = currentP.mul(newProductFactor).div(DECIMAL_PRECISION);
		}

		require(newP != 0, "StabilityPool: P = 0");
		P = newP;
		emit P_Updated(newP);
	}

	/**
	 * @notice Internal function to move offset collateral and debt between pools.
	 * @dev Cancel the liquidated debtToken debt with the debtTokens in the stability pool,
	 * Burn the debt that was successfully offset. Collateral is moved from
	 * the ActivePool to this contract.
	 * @param _asset collateral address
	 * @param _amount amount as uint256
	 * @param _debtToOffset uint256
	 */
	function _moveOffsetCollAndDebt(
		address _asset,
		uint256 _amount,
		uint256 _debtToOffset
	) internal {
		IActivePool activePoolCached = activePool;
		activePoolCached.decreaseDebt(_asset, _debtToOffset);
		_decreaseDebtTokens(_debtToOffset);
		debtToken.burn(address(this), _debtToOffset);
		activePoolCached.sendAsset(_asset, address(this), _amount);
	}

	function _decreaseDebtTokens(uint256 _amount) internal {
		uint256 newTotalDeposits = totalDebtTokenDeposits.sub(_amount);
		totalDebtTokenDeposits = newTotalDeposits;
		emit StabilityPoolDebtTokenBalanceUpdated(newTotalDeposits);
	}

	// --- Reward calculator functions for depositor ---

	/**
	 * @notice Calculates the gains earned by the deposit since its last snapshots were taken.
	 * @dev Given by the formula:  E = d0 * (S - S(0))/P(0)
	 * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
	 * d0 is the last recorded deposit value.
	 * @param _depositor address of depositor in question
	 * @return assets, amounts
	 */
	function getDepositorGains(address _depositor) public view returns (address[] memory, uint256[] memory) {
		uint256 initialDeposit = deposits[_depositor];

		if (initialDeposit == 0) {
			address[] memory emptyAddress = new address[](0);
			uint256[] memory emptyUint = new uint256[](0);
			return (emptyAddress, emptyUint);
		}

		Snapshots storage snapshots = depositSnapshots[_depositor];

		(address[] memory collateralsFromNewGains, uint256[] memory amountsFromNewGains) = _calculateNewGains(
			initialDeposit,
			snapshots
		);
		// Add pending gains to the current gains
		return (
			collateralsFromNewGains,
			_leftSumColls(
				Colls(collateralsFromNewGains, amountsFromNewGains),
				pendingCollGains[_depositor].tokens,
				pendingCollGains[_depositor].amounts
			)
		);
	}

	/**
	 * @notice get gains on each possible asset by looping through
	 * @dev assets with _getGainFromSnapshots function
	 * @param initialDeposit Amount of initial deposit
	 * @param snapshots struct snapshots
	 */
	function _calculateNewGains(uint256 initialDeposit, Snapshots storage snapshots)
		internal
		view
		returns (address[] memory assets, uint256[] memory amounts)
	{
		assets = adminContract.getValidCollateral();
		uint256 assetsLen = assets.length;
		amounts = new uint256[](assetsLen);
		for (uint256 i = 0; i < assetsLen; ++i) {
			amounts[i] = _getGainFromSnapshots(initialDeposit, snapshots, assets[i]);
		}
	}

	/**
	 * @notice gets the gain in S for a given asset
	 * @dev for a user who deposited initialDeposit
	 * @param initialDeposit Amount of initialDeposit
	 * @param snapshots struct snapshots
	 * @param asset asset to gain snapshot
	 * @return uint256 the gain
	 */
	function _getGainFromSnapshots(
		uint256 initialDeposit,
		Snapshots storage snapshots,
		address asset
	) internal view returns (uint256) {
		/*
		 * Grab the sum 'S' from the epoch at which the stake was made. The Collateral amount gain may span up to one scale change.
		 * If it does, the second portion of the Collateral amount gain is scaled by 1e9.
		 * If the gain spans no scale change, the second portion will be 0.
		 */
		uint256 S_Snapshot = snapshots.S[asset];
		uint256 P_Snapshot = snapshots.P;

		uint256 firstPortion = epochToScaleToSum[asset][snapshots.epoch][snapshots.scale].sub(S_Snapshot);
		uint256 secondPortion = epochToScaleToSum[asset][snapshots.epoch][snapshots.scale.add(1)].div(SCALE_FACTOR);

		uint256 assetGain = initialDeposit.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(DECIMAL_PRECISION);

		return assetGain;
	}

	/*
	 * Calculate the GRVT gain earned by a deposit since its last snapshots were taken.
	 * Given by the formula:  GRVT = d0 * (G - G(0))/P(0)
	 * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
	 * d0 is the last recorded deposit value.
	 */
	function getDepositorGRVTGain(address _depositor) public view override returns (uint256) {
		uint256 initialDeposit = deposits[_depositor];
		if (initialDeposit == 0) {
			return 0;
		}

		Snapshots storage snapshots = depositSnapshots[_depositor];
		return _getGRVTGainFromSnapshots(initialDeposit, snapshots);
	}

	function _getGRVTGainFromSnapshots(uint256 initialStake, Snapshots storage snapshots)
		internal
		view
		returns (uint256)
	{
		/*
		 * Grab the sum 'G' from the epoch at which the stake was made. The GRVT gain may span up to one scale change.
		 * If it does, the second portion of the GRVT gain is scaled by 1e9.
		 * If the gain spans no scale change, the second portion will be 0.
		 */
		uint128 epochSnapshot = snapshots.epoch;
		uint128 scaleSnapshot = snapshots.scale;
		uint256 G_Snapshot = snapshots.G;
		uint256 P_Snapshot = snapshots.P;

		uint256 firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot].sub(G_Snapshot);
		uint256 secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot.add(1)].div(SCALE_FACTOR);

		uint256 GRVTGain = initialStake.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(DECIMAL_PRECISION);

		return GRVTGain;
	}

	// --- Compounded deposit and compounded System stake ---

	/*
	 * Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
	 * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
	 */
	function getCompoundedDebtTokenDeposits(address _depositor) public view override returns (uint256) {
		uint256 initialDeposit = deposits[_depositor];
		if (initialDeposit == 0) {
			return 0;
		}

		return _getCompoundedStakeFromSnapshots(initialDeposit, depositSnapshots[_depositor]);
	}

	// Internal function, used to calculcate compounded deposits and compounded stakes.
	function _getCompoundedStakeFromSnapshots(uint256 initialStake, Snapshots storage snapshots)
		internal
		view
		returns (uint256)
	{
		uint256 snapshot_P = snapshots.P;
		uint128 scaleSnapshot = snapshots.scale;
		uint128 epochSnapshot = snapshots.epoch;

		// If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
		if (epochSnapshot < currentEpoch) {
			return 0;
		}

		uint256 compoundedStake;
		uint128 scaleDiff = currentScale.sub(scaleSnapshot);

		/* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
		 * account for it. If more than one scale change was made, then the stake has decreased by a factor of
		 * at least 1e-9 -- so return 0.
		 */
		if (scaleDiff == 0) {
			compoundedStake = initialStake.mul(P).div(snapshot_P);
		} else if (scaleDiff == 1) {
			compoundedStake = initialStake.mul(P).div(snapshot_P).div(SCALE_FACTOR);
		} else {
			compoundedStake = 0;
		}

		/*
		 * If compounded deposit is less than a billionth of the initial deposit, return 0.
		 *
		 * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
		 * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
		 * than it's theoretical value.
		 *
		 * Thus it's unclear whether this line is still really needed.
		 */
		if (compoundedStake < initialStake.div(1e9)) {
			return 0;
		}

		return compoundedStake;
	}

	// --- Sender functions for debtToken deposits

	// Transfer the tokens from the user to the Stability Pool's address, and update its recorded deposits
	function _sendToStabilityPool(address _address, uint256 _amount) internal {
		debtToken.sendToPool(_address, address(this), _amount);
		uint256 newTotalDeposits = totalDebtTokenDeposits.add(_amount);
		totalDebtTokenDeposits = newTotalDeposits;
		emit StabilityPoolDebtTokenBalanceUpdated(newTotalDeposits);
	}

	/**
	 * @notice transfer collateral gains to the depositor
	 * @dev this function also unwraps wrapped assets
	 * before sending to depositor
	 * @param _to address
	 * @param assets array of address
	 * @param amounts array of uint256. Includes pending collaterals since that was added in previous steps
	 */
	function _sendGainsToDepositor(
		address _to,
		address[] memory assets,
		uint256[] memory amounts
	) internal {
		uint256 assetsLen = assets.length;
		require(assetsLen == amounts.length, "StabilityPool: Length mismatch");
		for (uint256 i = 0; i < assetsLen; ++i) {
			uint256 amount = amounts[i];
			if (amount == 0) {
				continue;
			}
			address asset = assets[i];
			// Assumes we're internally working only with the wrapped version of ERC20 tokens
			IERC20Upgradeable(asset).safeTransferFrom(address(this), _to, amount);
		}
		totalColl.amounts = _leftSubColls(totalColl, assets, amounts);

		// Reset pendingCollGains since those were all sent to the borrower
		Colls memory tempPendingCollGains;
		pendingCollGains[_to] = tempPendingCollGains;
	}

	// Send debt tokens to user and decrease deposits in Pool
	function _sendToDepositor(address _depositor, uint256 debtTokenWithdrawal) internal {
		if (debtTokenWithdrawal == 0) {
			return;
		}
		debtToken.returnFromPool(address(this), _depositor, debtTokenWithdrawal);
		_decreaseDebtTokens(debtTokenWithdrawal);
	}

	// --- Stability Pool Deposit Functionality ---

	/**
	 * @notice updates deposit and snapshots internally
	 * @dev if _newValue is zero, delete snapshot for given _depositor and emit event
	 * otherwise, add an entry or update existing entry for _depositor in the depositSnapshots
	 * with current values for P, S, G, scale and epoch and then emit event.
	 * @param _depositor address
	 * @param _newValue uint256
	 */
	function _updateDepositAndSnapshots(address _depositor, uint256 _newValue) internal {
		deposits[_depositor] = _newValue;
		address[] memory colls = adminContract.getValidCollateral();
		uint256 collsLen = colls.length;

		if (_newValue == 0) {
			for (uint256 i = 0; i < collsLen; ++i) {
				depositSnapshots[_depositor].S[colls[i]] = 0;
			}
			depositSnapshots[_depositor].P = 0;
			depositSnapshots[_depositor].G = 0;
			depositSnapshots[_depositor].epoch = 0;
			depositSnapshots[_depositor].scale = 0;
			emit DepositSnapshotUpdated(_depositor, 0, 0);
			return;
		}
		uint128 currentScaleCached = currentScale;
		uint128 currentEpochCached = currentEpoch;
		uint256 currentP = P;

		for (uint256 i = 0; i < collsLen; ++i) {
			address asset = colls[i];
			uint256 currentS = epochToScaleToSum[asset][currentEpochCached][currentScaleCached];
			depositSnapshots[_depositor].S[asset] = currentS;
		}

		uint256 currentG = epochToScaleToG[currentEpochCached][currentScaleCached];
		depositSnapshots[_depositor].P = currentP;
		depositSnapshots[_depositor].G = currentG;
		depositSnapshots[_depositor].scale = currentScaleCached;
		depositSnapshots[_depositor].epoch = currentEpochCached;

		emit DepositSnapshotUpdated(_depositor, currentP, currentG);
	}

	function S(address _depositor, address _asset) public view returns (uint256) {
		return depositSnapshots[_depositor].S[_asset];
	}

	function _payOutGRVTGains(ICommunityIssuance _communityIssuance, address _depositor) internal {
		if (address(_communityIssuance) != address(0)) {
			uint256 depositorGRVTGain = getDepositorGRVTGain(_depositor);
			_communityIssuance.sendGRVT(_depositor, depositorGRVTGain);
			emit GRVTPaidToDepositor(_depositor, depositorGRVTGain);
		}
	}

	// --- 'require' functions ---

	function _requireCallerIsActivePool() internal view {
		require(msg.sender == address(adminContract.activePool()), "StabilityPool: Caller is not ActivePool");
	}

	function _requireCallerIsVesselManager() internal view {
		require(msg.sender == address(vesselManager), "StabilityPool: Caller is not VesselManager");
	}

	function _requireCallerIsAdminContract() internal view {
		require(msg.sender == address(adminContract), "StabilityPool: Caller is not AdminContract");
	}

	/**
	 * @notice check ICR of bottom vessel (per asset) in SortedVessels
	 */
	function _requireNoUnderCollateralizedVessels() internal {
		address[] memory assets = adminContract.getValidCollateral();
		uint256 assetsLen = assets.length;
		for (uint256 i = 0; i < assetsLen; ++i) {
			address assetAddress = assets[i];
			address lowestVessel = sortedVessels.getLast(assetAddress);
			uint256 price = adminContract.priceFeed().fetchPrice(assetAddress);
			uint256 ICR = vesselManager.getCurrentICR(assetAddress, lowestVessel, price);
			require(
				ICR >= adminContract.getMcr(assetAddress),
				"StabilityPool: Cannot withdraw while there are vessels with ICR < MCR"
			);
		}
	}

	function _requireUserHasDeposit(uint256 _initialDeposit) internal pure {
		require(_initialDeposit > 0, "StabilityPool: User must have a non-zero deposit");
	}

	function _requireUserHasNoDeposit(address _address) internal view {
		uint256 initialDeposit = deposits[_address];
		require(initialDeposit == 0, "StabilityPool: User must have no deposit");
	}

	function _requireNonZeroAmount(uint256 _amount) internal pure {
		require(_amount > 0, "StabilityPool: Amount must be non-zero");
	}

	function _requireUserHasVessel(address _depositor) internal view {
		address[] memory assets = adminContract.getValidCollateral();
		uint256 assetsLen = assets.length;
		for (uint256 i; i < assetsLen; ++i) {
			if (vesselManager.getVesselStatus(assets[i], _depositor) == 1) {
				return;
			}
		}
		revert("StabilityPool: caller must have an active vessel to withdraw AssetGain to");
	}

	function _requireUserHasAssetGain(address _depositor) internal view {
		(address[] memory assets, uint256[] memory amounts) = getDepositorGains(_depositor);
		for (uint256 i = 0; i < assets.length; ++i) {
			if (amounts[i] > 0) {
				return;
			}
		}
		revert("StabilityPool: caller must have non-zero gains");
	}

	// --- Fallback function ---

	function receivedERC20(address _asset, uint256 _amount) external override {
		_requireCallerIsActivePool();
		uint256 collateralIndex = adminContract.getIndex(_asset);
		totalColl.amounts[collateralIndex] += _amount;
		uint256 newAssetBalance = totalColl.amounts[collateralIndex];
		emit StabilityPoolAssetBalanceUpdated(_asset, newAssetBalance);
	}
}