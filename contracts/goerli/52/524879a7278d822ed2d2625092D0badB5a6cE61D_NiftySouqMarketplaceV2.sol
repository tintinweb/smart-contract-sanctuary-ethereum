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
library SafeMath {
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

pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./interface/NiftySouq-IMarketplaceManager.sol";
import "./interface/NiftySouq-IERC721.sol";
import "./interface/NiftySouq-IERC1155.sol";
import "./interface/NiftySouq-IFixedPrice.sol";
import "./interface/NiftySouq-IAuction.sol";
import "./interface/BezelClub-IERC721.sol";


enum OfferState {
    OPEN,
    CANCELLED,
    ENDED
}

enum OfferType {
    SALE,
    AUCTION
}

struct MintData {
    address minter;
    address tokenAddress;
    string uri;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 quantity;
}

struct Offer {
    uint256 tokenId;
    OfferType offerType;
    OfferState status;
    ContractType contractType;
}

struct MakeOffer {
    address tokenAddress;
    uint256 tokenId;
    bool isERC1155;
    address offeredBy;
    uint256 quantity;
    uint256 price;
    string currency;
    bool isCancelled;
}

struct MakeOfferData {
    address tokenAddress;
    uint256 tokenId;
    uint256 quantity;
    uint256 price;
    string currency;
}

struct Payout {
    address currency;
    address[] refundAddresses;
    uint256[] refundAmounts;
}

/**
 *@title Marketplace contract.
 *@dev Marketplace is an implementation contract of initializable contract.
 */
contract NiftySouqMarketplaceV2 is Initializable {
    error GeneralError(string errorCode);

    //*********************** Attaching libraries ***********************//
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    //*********************** Declarations ***********************//
    address private _admin;

    NiftySouqIMarketplaceManager private _niftySouqMarketplaceManager;
    NiftySouqIERC721V2 private _niftySouqErc721;
    NiftySouqIERC1155V2 private _niftySouqErc1155;
    NiftySouqIFixedPrice private _niftySouqFixedPrice;
    NiftySouqIAuction private _niftySouqAuction;

    Counters.Counter private _offerId;
    mapping(uint256 => Offer) private _offers;

    uint256 public constant PERCENT_UNIT = 1e4;
    address private _bezelNftContractAddress;

    Counters.Counter private _makeOfferId;
    mapping(uint256 => MakeOffer) private _makeOffers;
    mapping(address => mapping(uint256 => uint256[])) private _makeOffersList;


    //*********************** Events ***********************//
    event eMint(
        uint256 tokenId,
        address contractAddress,
        bool isERC1155,
        address owner,
        uint256 quantity
    );

    event eMakeOffer(
        uint256 makeOfferId,
        address tokenAddress,
        uint256 tokenId,
        address offeredBy,
        uint256 quantity,
        uint256 price,
        string currency
    );
    event eCancelOffer(uint256 makeOfferId);

    event eAcceptOffer(uint256 makeOfferId);

    event ePayoutTransfer(
        address indexed withdrawer,
        uint256 indexed amount,
        address indexed currency
    );

    //*********************** Modifiers ***********************//
    modifier isNiftyAdmin() {
        if (
            (_admin != msg.sender) &&
            (!_niftySouqMarketplaceManager.isAdmin(msg.sender))
        ) revert GeneralError("NS:102");
        _;
    }

    //*********************** Admin Functions ***********************//
    /**
     *@notice Initializes the contract.
     *@dev used instead of constructor.
     */
    function initialize() external initializer {
        _admin = msg.sender;
    }

    /**
     *@notice sets addresses of contracts.
     *@param marketplaceManager_ address of marketplaceManager contract.
     *@param erc721_ address of ERC721 contract
     *@param erc1155_ address of ERC1155 contract.
     *@param fixedPrice_ address of fixed price contract.
     *@param auction_ address of auction contract.
     */
    function setContractAddresses(
        address marketplaceManager_,
        address erc721_,
        address erc1155_,
        address fixedPrice_,
        address auction_
    ) external isNiftyAdmin {
        if (marketplaceManager_ != address(0))
            _niftySouqMarketplaceManager = NiftySouqIMarketplaceManager(
                marketplaceManager_
            );
        if (erc721_ != address(0))
            _niftySouqErc721 = NiftySouqIERC721V2(erc721_);
        if (erc1155_ != address(0))
            _niftySouqErc1155 = NiftySouqIERC1155V2(erc1155_);
        if (fixedPrice_ != address(0))
            _niftySouqFixedPrice = NiftySouqIFixedPrice(fixedPrice_);
        if (auction_ != address(0))
            _niftySouqAuction = NiftySouqIAuction(auction_);
    }

    /**
     *@notice sets contract address of bezel club.
     *@param bezelAddress_ address of bezel.
     */
    function setBezelContractAddress(address bezelAddress_)
        external
        isNiftyAdmin
    {
        _bezelNftContractAddress = bezelAddress_;
    }

    //*********************** Getter Functions ***********************//

    function getConfiguration()
        external
        view
        returns (
            address marketplaceManager_,
            address erc721_,
            address erc1155_,
            address fixedPrice_,
            address auction_,
            address bezelAddress_
        )
    {
        marketplaceManager_ = address(_niftySouqMarketplaceManager);
        erc721_ = address(_niftySouqErc721);
        erc1155_ = address(_niftySouqErc1155);
        fixedPrice_ = address(_niftySouqFixedPrice);
        auction_ = address(_niftySouqAuction);
        bezelAddress_ = _bezelNftContractAddress;
    }

    /**
     *@notice get offer details of NFT.
     *@param offerId_ offerId of NFT.
     *@return offerDetails_ offer details of NFT.
     */
    function getOfferStatus(uint256 offerId_)
        external
        view
        returns (Offer memory offerDetails_)
    {
        if (offerId_ > _offerId.current()) revert GeneralError("NS:125");
        offerDetails_ = _offers[offerId_];
    }

    /**
     *@notice gets details of offer made for NFT.
     *@param makeOfferId_ offerId of NFT.
     *@return makeOfferData_  contains token address,tokenId,quantiy of nfts,price of nft,currency used.
     */
    function getMakeOfferDetails(uint256 makeOfferId_)
        external
        view
        returns (MakeOffer memory makeOfferData_)
    {
        return _makeOffers[makeOfferId_];
    }

    //*********************** Setter Functions ***********************//

    /**
     *@notice for creating sale.
     *@param tokenId_ Id of token.
     *@param contractType_ Type of contract.
     *@param offerType_ Type of offer such as sale or auction.
     *@return offerId_ OfferId of NFT.
     */
    function createSale(
        uint256 tokenId_,
        ContractType contractType_,
        OfferType offerType_
    ) external returns (uint256 offerId_) {
        if (
            msg.sender != address(_niftySouqFixedPrice) &&
            msg.sender != address(_niftySouqAuction)
        ) revert GeneralError("NS:109");
        if (
            (_niftySouqMarketplaceManager.isBlocked(msg.sender) == true)
        ) revert GeneralError("NS:126");
        if (_niftySouqMarketplaceManager.isPaused() == true)
            revert GeneralError("NS:128");
        _offerId.increment();
        offerId_ = _offerId.current();

        _offers[offerId_] = Offer(
            tokenId_,
            offerType_,
            OfferState.OPEN,
            contractType_
        );
    }

    /**
     *@notice ends sale.
     *@param offerId_ offerId of NFT
     *@param offerState_ state of offer such as open ,cancelled, ended.
     */
    function endSale(uint256 offerId_, OfferState offerState_) external {
        if (
            msg.sender != address(_niftySouqFixedPrice) &&
            msg.sender != address(_niftySouqAuction)
        ) revert GeneralError("NS:109");
        
        _offers[offerId_].status = offerState_;
    }

    /**
     *@notice mints NFT .
     *@param mintData_ contains uri, creater addresses, royalties percentage, investors addresses, revenue percentage,minter address.
     *@return tokenId_ Id of NFT.
     */
    function mintNft(MintData memory mintData_)
        public
        returns (uint256 tokenId_)
    {
        if (mintData_.quantity <= 0) revert GeneralError("NS:303");
        if (
            (_niftySouqMarketplaceManager.isBlocked(msg.sender) == true)
        ) revert GeneralError("NS:126");
        if (_niftySouqMarketplaceManager.isPaused() == true)
            revert GeneralError("NS:128");

        (
            ContractType contractType,
            bool isERC1155
        ) = _niftySouqMarketplaceManager.getContractDetails(
                mintData_.tokenAddress
            );
        address minter;
        if (
            msg.sender == address(_niftySouqFixedPrice) ||
            msg.sender == address(_niftySouqAuction)
        ) minter = mintData_.minter;
        else minter = msg.sender;
        if (isERC1155 && contractType == ContractType.NIFTY_V2) {
            NiftySouqIERC1155V2.MintData
                memory mintData1155_ = NiftySouqIERC1155V2.MintData(
                    mintData_.uri,
                    minter,
                    mintData_.creators,
                    mintData_.royalties,
                    mintData_.investors,
                    mintData_.revenues,
                    mintData_.quantity
                );
            tokenId_ = NiftySouqIERC1155V2(mintData_.tokenAddress).mint(
                mintData1155_
            );
        } else if (
            !isERC1155 &&
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR)
        ) {
            NiftySouqIERC721V2.MintData memory mintData721_ = NiftySouqIERC721V2
                .MintData(
                    mintData_.uri,
                    minter,
                    mintData_.creators,
                    mintData_.royalties,
                    mintData_.investors,
                    mintData_.revenues,
                    true
                );
            tokenId_ = NiftySouqIERC721V2(mintData_.tokenAddress).mint(
                mintData721_
            );
        } else revert();
        emit eMint(
            tokenId_,
            mintData_.tokenAddress,
            (mintData_.quantity > 1) ? true : false,
            minter,
            mintData_.quantity
        );
    }

    /**
     *@notice mints the NFT while purchasing .
     *@dev this NFT will be minted to the buyer and the purchase amount will be transferred to the owner.
     *@param purchaseQuantity quantity of nfts during purchase.
     *@param lazyMintSellData_  contains uri,seller address,creater addresses, royalties percentage, investors addresses, revenue percentage,purchase quantity.
     *@return offerId_ offerId of nft.
     *@return tokenId_ Id of token.
     */
    function lazyMintSellNft(
        uint256 purchaseQuantity,
        LazyMintSellData calldata lazyMintSellData_
    )
        external
        payable
        returns (uint256 offerId_, uint256 tokenId_)
    {
        if (lazyMintSellData_.seller == msg.sender)
            revert GeneralError("NS:305");
        if (
            (_niftySouqMarketplaceManager.isBlocked(msg.sender) == true)
        ) revert GeneralError("NS:126");
        if (_niftySouqMarketplaceManager.isPaused() == true)
            revert GeneralError("NS:128");

        address signerV2 = _niftySouqMarketplaceManager
            .verifyFixedPriceLazyMintV2(lazyMintSellData_);
        if (lazyMintSellData_.seller != signerV2) {
            address signerV1 = _niftySouqMarketplaceManager
                .verifyFixedPriceLazyMintV1(lazyMintSellData_);
            if (lazyMintSellData_.seller != signerV1)
                revert GeneralError("NS:306");
        }

        (offerId_, tokenId_) = _lazyMint(
            purchaseQuantity,
            msg.value,
            lazyMintSellData_
        );
    }

    /**
     *@notice for selling bezel NFTs.
     *@dev includes minting nfts,create offer,calculation of payments functionalities.
     *@param lazyData_  includes seller address, buyer address,type of cuurency,price of NFT,signature.
     *@return tokenId_ Id of NFT.
     *@return offerId_ offerId of NFT.
     */
    function sellBezelNft(BezelClubIERC721.LazyMintData memory lazyData_)
        external
        payable
        returns (uint256 tokenId_, uint256 offerId_)
    {

        // mint nft
        tokenId_ = BezelClubIERC721(_bezelNftContractAddress).lazyMint(
            lazyData_
        );
        emit eMint(
            tokenId_,
            _bezelNftContractAddress,
            false,
            lazyData_.seller,
            1
        );

        // create offer
        _offerId.increment();
        offerId_ = _offerId.current();

        NiftySouqIFixedPrice(_niftySouqFixedPrice).lazyMint(
            LazyMintData(
                offerId_,
                tokenId_,
                _bezelNftContractAddress,
                false,
                1,
                lazyData_.price,
                lazyData_.seller,
                lazyData_.buyer,
                1,
                new address[](0),
                new uint256[](0),
                lazyData_.currency
            )
        );
        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            OfferState.ENDED,
            ContractType.EXTERNAL
        );

        // payout calculation
        address[] memory recipientAddresses = new address[](2);
        uint256[] memory paymentAmount = new uint256[](2);
        uint256 serviceFee = _percent(
            lazyData_.price,
            _niftySouqMarketplaceManager.serviceFeePercent()
        );
        recipientAddresses[0] = _niftySouqMarketplaceManager.serviceFeeWallet();
        paymentAmount[0] = serviceFee;

        recipientAddresses[1] = lazyData_.seller;
        paymentAmount[1] = lazyData_.price;
        if (
            keccak256(abi.encodePacked(lazyData_.currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            if (msg.value != lazyData_.price.add(serviceFee))
                revert GeneralError("NS:304");
            _payout(Payout(address(0), recipientAddresses, paymentAmount));
        } else {
            if (!_niftySouqFixedPrice.isSaleSupportedTokens(lazyData_.currency))
                revert GeneralError("NS:118");
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .getTokenDetail(lazyData_.currency);
            {
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                if (allowance < (lazyData_.price).add(serviceFee))
                    revert GeneralError("NS:124");
            }
            IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                msg.sender,
                address(this),
                (lazyData_.price).add(serviceFee)
            );
            _payout(
                Payout(
                    tokenDetails.tokenAddress,
                    recipientAddresses,
                    paymentAmount
                )
            );
        }
    }

    /**
     *@notice Make offer for sale
     *@param makeOfferData_ contains token address,tokenId,quantiy of nfts,price of nft,currency used.
     */

    function makeOffer(MakeOfferData calldata makeOfferData_) external payable {
        (
            ContractType contractType,
            bool isERC1155,
            ,

        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                msg.sender,
                makeOfferData_.tokenId,
                makeOfferData_.tokenAddress
            );
        if (contractType == ContractType.UNSUPPORTED)
            revert GeneralError("NS:307");

        if (
            keccak256(abi.encodePacked(makeOfferData_.currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            if (msg.value != makeOfferData_.price.mul(makeOfferData_.quantity))
                revert GeneralError("NS:304");
        } else {
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .getTokenDetail(makeOfferData_.currency);
            uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                .allowance(msg.sender, address(this));
            if (allowance < makeOfferData_.price) revert GeneralError("NS:124");
            IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                msg.sender,
                address(this),
                makeOfferData_.price
            );
        }

        _makeOfferId.increment();
        _makeOffers[_makeOfferId.current()] = MakeOffer(
            makeOfferData_.tokenAddress,
            makeOfferData_.tokenId,
            isERC1155,
            msg.sender,
            makeOfferData_.quantity,
            makeOfferData_.price,
            makeOfferData_.currency,
            false
        );

        _makeOffersList[makeOfferData_.tokenAddress][makeOfferData_.tokenId]
            .push(_makeOfferId.current());

        emit eMakeOffer(
            _makeOfferId.current(),
            makeOfferData_.tokenAddress,
            makeOfferData_.tokenId,
            msg.sender,
            makeOfferData_.quantity,
            makeOfferData_.price,
            makeOfferData_.currency
        );
    }

    /**
     *@notice edit  offer for sale.
     *@param makeOfferId_ offerId of NFT.
     *@param price_ offer price of NFT.
     */
    function editOffer(uint256 makeOfferId_, uint256 price_) external payable {
        if (makeOfferId_ > _makeOfferId.current())
            revert GeneralError("NS:501");
        if (_makeOffers[makeOfferId_].offeredBy != msg.sender)
            revert GeneralError("NS:502");
        if (_makeOffers[makeOfferId_].isCancelled)
            revert GeneralError("NS:503");

        if (price_ > _makeOffers[makeOfferId_].price) {
            uint256 priceDiff = price_.sub(_makeOffers[makeOfferId_].price);
            if (
                keccak256(
                    abi.encodePacked(_makeOffers[makeOfferId_].currency)
                ) == keccak256(abi.encodePacked(""))
            ) {
                if (msg.value != priceDiff) revert GeneralError("NS:504");
            } else {
                CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                    .getTokenDetail(_makeOffers[makeOfferId_].currency);
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                if (allowance < priceDiff) revert GeneralError("NS:124");
                IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                    msg.sender,
                    address(this),
                    priceDiff
                );
            }
        } else if (price_ < _makeOffers[makeOfferId_].price) {
            uint256 priceDiff = _makeOffers[makeOfferId_].price.sub(price_);
            address[] memory refundAddresses;
            refundAddresses[0] = _makeOffers[makeOfferId_].offeredBy;
            uint256[] memory refundAmount;
            refundAmount[0] = priceDiff;
            if (
                keccak256(
                    abi.encodePacked(_makeOffers[makeOfferId_].currency)
                ) == keccak256(abi.encodePacked(""))
            ) {
                _payout(Payout(address(0), refundAddresses, refundAmount));
            } else {
                CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                    .getTokenDetail(_makeOffers[makeOfferId_].currency);
                _payout(
                    Payout(
                        tokenDetails.tokenAddress,
                        refundAddresses,
                        refundAmount
                    )
                );
            }
        } else {
            revert("already same price");
        }

        _makeOffers[makeOfferId_].price = price_;
    }

    /**
     *@notice cancel offer for sale.
     *@param makeOfferId_ OfferId of NFT.
     */
    function cancelOffer(uint256 makeOfferId_) external {
        if (makeOfferId_ > _makeOfferId.current())
            revert GeneralError("NS:501");
        if (_makeOffers[makeOfferId_].offeredBy != msg.sender)
            revert GeneralError("NS:502");
        if (_makeOffers[makeOfferId_].isCancelled)
            revert GeneralError("NS:503");

        _makeOffers[makeOfferId_].isCancelled = true;
        address[] memory refundAddresses = new address[](1);
        refundAddresses[0] = _makeOffers[makeOfferId_].offeredBy;
        uint256[] memory refundAmount = new uint256[](1);
        refundAmount[0] = _makeOffers[makeOfferId_].price;
        if (
            keccak256(abi.encodePacked(_makeOffers[makeOfferId_].currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            _payout(Payout(address(0), refundAddresses, refundAmount));
        } else {
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .getTokenDetail(_makeOffers[makeOfferId_].currency);
            _payout(
                Payout(tokenDetails.tokenAddress, refundAddresses, refundAmount)
            );
        }
    }

    /**
     *@notice accepts offer
     *@param makeOfferId_ makeofferId of NFT.
     *@return offerId_ OfferId.
     */
    function acceptOffer(uint256 makeOfferId_)
        external
        payable
        returns (uint256 offerId_)
    {
        if (makeOfferId_ > _makeOfferId.current())
            revert GeneralError("NS:501");

        if (_makeOffers[makeOfferId_].isCancelled)
            revert GeneralError("NS:503");

        (, bool isERC1155) = _niftySouqMarketplaceManager.getContractDetails(
            _makeOffers[makeOfferId_].tokenAddress
        );

        _offerId.increment();
        offerId_ = _offerId.current();

        NiftySouqIFixedPrice.Payout memory payoutData = NiftySouqIFixedPrice(
            _niftySouqFixedPrice
        ).acceptOffer(
                AcceptOfferData(
                    offerId_,
                    _makeOffers[makeOfferId_].tokenId,
                    _makeOffers[makeOfferId_].tokenAddress,
                    isERC1155,
                    _makeOffers[makeOfferId_].quantity,
                    _makeOffers[makeOfferId_].price,
                    msg.sender,
                    block.timestamp,
                    _makeOffers[makeOfferId_].offeredBy,
                    block.timestamp,
                    _makeOffers[makeOfferId_].currency
                )
            );
        payoutData.refundAmount[
            payoutData.refundAmount.length.sub(1)
        ] = payoutData.refundAmount[payoutData.refundAmount.length.sub(1)].sub(
            payoutData.refundAmount[payoutData.refundAmount.length.sub(2)]
        );
        if (
            keccak256(abi.encodePacked(_makeOffers[makeOfferId_].currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            _payout(
                Payout(
                    address(0),
                    payoutData.refundAddresses,
                    payoutData.refundAmount
                )
            );
        } else {
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .getTokenDetail(_makeOffers[makeOfferId_].currency);
            _payout(
                Payout(
                    tokenDetails.tokenAddress,
                    payoutData.refundAddresses,
                    payoutData.refundAmount
                )
            );
        }
        _makeOffers[makeOfferId_].isCancelled == true;

        _transferNFT(
            msg.sender,
            _makeOffers[makeOfferId_].offeredBy,
            _makeOffers[makeOfferId_].tokenId,
            _makeOffers[makeOfferId_].tokenAddress,
            _makeOffers[makeOfferId_].quantity
        );
        emit eAcceptOffer(makeOfferId_);

        for (
            uint256 i = 0;
            i <
            _makeOffersList[_makeOffers[makeOfferId_].tokenAddress][
                _makeOffers[makeOfferId_].tokenId
            ].length;
            i++
        ) {
            uint256 makeOfferId = _makeOffersList[
                _makeOffers[makeOfferId_].tokenAddress
            ][_makeOffers[makeOfferId_].tokenId][i];
            if (
                _makeOffers[makeOfferId].isCancelled == false &&
                makeOfferId_ != makeOfferId
            ) {
                if (
                    keccak256(
                        abi.encodePacked(_makeOffers[makeOfferId_].currency)
                    ) == keccak256(abi.encodePacked(""))
                ) {
                    payable(_makeOffers[makeOfferId].offeredBy).transfer(
                        _makeOffers[makeOfferId].price
                    );
                    emit ePayoutTransfer(
                        _makeOffers[makeOfferId].offeredBy,
                        _makeOffers[makeOfferId].price,
                        address(0)
                    );
                } else {
                    CryptoTokens
                        memory tokenDetails = _niftySouqMarketplaceManager
                            .getTokenDetail(_makeOffers[makeOfferId_].currency);
                    IERC20Upgradeable(tokenDetails.tokenAddress).safeTransfer(
                        _makeOffers[makeOfferId].offeredBy,
                        _makeOffers[makeOfferId].price
                    );
                    emit ePayoutTransfer(
                        _makeOffers[makeOfferId].offeredBy,
                        _makeOffers[makeOfferId].price,
                        tokenDetails.tokenAddress
                    );
                }
                _makeOffers[makeOfferId].isCancelled == true;
            }
        }
        uint256[] memory initArr = new uint256[](0);
        _makeOffersList[_makeOffers[makeOfferId_].tokenAddress][
            _makeOffers[makeOfferId_].tokenId
        ] = initArr;
    }

    function transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) external {
        if (
            msg.sender != address(_niftySouqFixedPrice) &&
            msg.sender != address(_niftySouqAuction)
        ) revert GeneralError("NS:109");
        _transferNFT(from_, to_, tokenId_, tokenAddress_, quantity_);
    }

    //*********************** Internal Functions ***********************//

    /**
     *@notice mints the NFT while purchasing.
     *@dev this NFT will be minted to the buyer and the purchase amount will be transferred to the owner.
     *@param purchaseQuantity quantity of nft during purchase.
     *@param payment payment of purchase.
     *@param lazyMintSellData_  contains uri,seller address,creater addresses, royalties percentage, investors addresses, revenue percentage,purchase quantity.
     *@return offerId_ offerId of nft.
     *@return tokenId_ Id of token.
     */
    function _lazyMint(
        uint256 purchaseQuantity,
        uint256 payment,
        LazyMintSellData calldata lazyMintSellData_
    ) private returns (uint256 offerId_, uint256 tokenId_) {
        (
            ContractType contractType,
            bool isERC1155
        ) = _niftySouqMarketplaceManager.getContractDetails(
                lazyMintSellData_.tokenAddress
            );
        if (isERC1155 && contractType == ContractType.NIFTY_V2) {
            // NiftySouqIERC1155V2.LazyMintData
            //     memory lazyMintData_ =
            tokenId_ = _niftySouqErc1155.lazyMint(
                NiftySouqIERC1155V2.LazyMintData(
                    lazyMintSellData_.uri,
                    lazyMintSellData_.seller,
                    msg.sender,
                    lazyMintSellData_.creators,
                    lazyMintSellData_.royalties,
                    lazyMintSellData_.investors,
                    lazyMintSellData_.revenues,
                    lazyMintSellData_.quantity,
                    purchaseQuantity
                )
            );
            emit eMint(
                tokenId_,
                address(_niftySouqErc1155),
                isERC1155,
                lazyMintSellData_.seller,
                lazyMintSellData_.quantity.sub(purchaseQuantity)
            );
            emit eMint(
                tokenId_,
                address(_niftySouqErc1155),
                isERC1155,
                msg.sender,
                purchaseQuantity
            );
        } else if (
            !isERC1155 &&
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR)
        ) {
            uint256 tokenId__ = mintNft(
                MintData(
                    msg.sender,
                    lazyMintSellData_.tokenAddress,
                    lazyMintSellData_.uri,
                    lazyMintSellData_.creators,
                    lazyMintSellData_.royalties,
                    lazyMintSellData_.investors,
                    lazyMintSellData_.revenues,
                    lazyMintSellData_.quantity
                )
            );
            tokenId_ = tokenId__;
        }
        _offerId.increment();
        offerId_ = _offerId.current();

        _offers[offerId_] = Offer(
            tokenId_,
            OfferType.SALE,
            purchaseQuantity < lazyMintSellData_.quantity
                ? OfferState.OPEN
                : OfferState.ENDED,
            ContractType.NIFTY_V2
        );

        NiftySouqIFixedPrice(_niftySouqFixedPrice).lazyMint(
            LazyMintData(
                offerId_,
                tokenId_,
                lazyMintSellData_.tokenAddress,
                isERC1155,
                lazyMintSellData_.quantity,
                lazyMintSellData_.minPrice,
                lazyMintSellData_.seller,
                msg.sender,
                purchaseQuantity,
                lazyMintSellData_.investors,
                lazyMintSellData_.revenues,
                lazyMintSellData_.currency
            )
        );

        address[] memory recipientAddresses = new address[](
            lazyMintSellData_.investors.length.add(2)
        );
        uint256[] memory paymentAmount = new uint256[](
            lazyMintSellData_.revenues.length.add(2)
        );
        uint256 serviceFee = _percent(
            (lazyMintSellData_.minPrice).mul(purchaseQuantity),
            _niftySouqMarketplaceManager.serviceFeePercent()
        );
        {
            uint256 i;
            uint256 revenueSum = 0;
            for (i = 0; i < lazyMintSellData_.revenues.length; i++) {
                uint256 revenue = _percent(
                    lazyMintSellData_.minPrice.mul(purchaseQuantity),
                    lazyMintSellData_.revenues[i]
                );
                recipientAddresses[i] = lazyMintSellData_.investors[i];
                paymentAmount[i] = revenue;
                revenueSum = revenueSum.add(revenue);
            }

            recipientAddresses[i] = _niftySouqMarketplaceManager
                .serviceFeeWallet();
            paymentAmount[i] = serviceFee;
            i = i + 1;

            recipientAddresses[i] = lazyMintSellData_.seller;
            paymentAmount[i] = (
                lazyMintSellData_.minPrice.mul(purchaseQuantity)
            ).sub(revenueSum);
            i = i + 1;
        }
        // CryptoTokens memory tokenDetails;

        if (
            keccak256(abi.encodePacked(lazyMintSellData_.currency)) ==
            keccak256(abi.encodePacked(""))
        ) {
            if (
                payment <
                (
                    serviceFee.add(
                        (lazyMintSellData_.minPrice).mul(purchaseQuantity)
                    )
                )
            ) revert GeneralError("NS:304");
            _payout(Payout(address(0), recipientAddresses, paymentAmount));
        } else {
            uint256 totalPayment = serviceFee.add(
                (lazyMintSellData_.minPrice).mul(purchaseQuantity)
            );
            if (
                !_niftySouqFixedPrice.isSaleSupportedTokens(
                    lazyMintSellData_.currency
                )
            ) revert GeneralError("NS:118");
            CryptoTokens memory tokenDetails = _niftySouqMarketplaceManager
                .getTokenDetail(lazyMintSellData_.currency);
            {
                uint256 allowance = IERC20Upgradeable(tokenDetails.tokenAddress)
                    .allowance(msg.sender, address(this));
                if (allowance < totalPayment) revert GeneralError("NS:124");
            }
            IERC20Upgradeable(tokenDetails.tokenAddress).transferFrom(
                msg.sender,
                address(this),
                totalPayment
            );
            _payout(
                Payout(
                    tokenDetails.tokenAddress,
                    recipientAddresses,
                    paymentAmount
                )
            );
        }
    }

    /**
     *@notice calulates the amount during NFT purchase.
     *@param payoutData_ contains currency,refundAddresses,refundAmounts.
     */
    function _payout(Payout memory payoutData_) internal {
        for (uint256 i = 0; i < payoutData_.refundAddresses.length; i++) {
            if (payoutData_.refundAddresses[i] != address(0)) {
                if (address(0) == payoutData_.currency) {
                    payable(payoutData_.refundAddresses[i]).transfer(
                        payoutData_.refundAmounts[i]
                    );
                } else {
                    IERC20Upgradeable(payoutData_.currency).safeTransfer(
                        payoutData_.refundAddresses[i],
                        payoutData_.refundAmounts[i]
                    );
                }
                emit ePayoutTransfer(
                    payoutData_.refundAddresses[i],
                    payoutData_.refundAmounts[i],
                    payoutData_.currency
                );
            }
        }
    }

    /**
     *@notice Transfers 'tokenId' token from 'from' to 'to'.
     *@param from_ address of seller.
     *@param to_ address of buyer.
     *@param tokenId_ tokenId of NfT.
     *@param tokenAddress_ address of token.
     *@param quantity_ quantity of NFT.
     */
    function _transferNFT(
        address from_,
        address to_,
        uint256 tokenId_,
        address tokenAddress_,
        uint256 quantity_
    ) internal {
        (
            ContractType contractType,
            bool isERC1155,
            bool isOwner,
            uint256 quantity
        ) = _niftySouqMarketplaceManager.isOwnerOfNFT(
                from_,
                tokenId_,
                tokenAddress_
            );
        if (!isOwner) revert GeneralError("NS:103");
        if (quantity < quantity_) revert GeneralError("NS:119");
        if (
            (contractType == ContractType.NIFTY_V2 ||
                contractType == ContractType.COLLECTOR) && !isERC1155
        ) {
            NiftySouqIERC721V2(tokenAddress_).transferNft(from_, to_, tokenId_);
        } else if (contractType == ContractType.NIFTY_V2 && isERC1155) {
            NiftySouqIERC1155V2(tokenAddress_).transferNft(
                from_,
                to_,
                tokenId_,
                quantity_
            );
        } else if (!isERC1155) {
            NiftySouqIERC721V2(tokenAddress_).transferFrom(
                from_,
                to_,
                tokenId_
            );
        } else if (isERC1155) {
            NiftySouqIERC1155V2(tokenAddress_).safeTransferFrom(
                from_,
                to_,
                tokenId_,
                quantity_,
                ""
            );
        }
    }

    function _percent(uint256 value_, uint256 percentage_)
        internal
        pure
        virtual
        returns (uint256)
    {
        uint256 result = value_.mul(percentage_).div(PERCENT_UNIT);
        return (result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface BezelClubIERC721 {
    struct LazyMintData {
        address seller;
        address buyer;
        string currency;
        uint256 price;
        string uid;
        bytes signature;
    }

    function lazyMint(LazyMintData calldata _lazyData)
        external
        returns (uint256 tokenId_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct Bid {
    address bidder;
    uint256 price;
    uint256 bidAt;
    bool canceled;
}

struct Auction {
    uint256 tokenId;
    address tokenContract;
    uint256 startTime;
    uint256 endTime;
    address seller;
    uint256 startBidPrice;
    uint256 reservePrice;
    uint256 highestBidIdx;
    uint256 selectedBid;
    Bid[] bids;
}

interface NiftySouqIAuction {
    function getAuctionDetails(uint256 offerId_)
        external
        view
        returns (Auction memory auction_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface NiftySouqIERC1155V2 {
    struct NftData {
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        address minter;
        uint256 firstSaleQuantity;
    }

    struct MintData {
        string uri;
        address minter;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
    }

    struct LazyMintData {
        string uri;
        address minter;
        address buyer;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        uint256 quantity;
        uint256 soldQuantity;
    }

    function getNftInfo(uint256 tokenId_)
        external
        view
        returns (NftData memory nfts_);

    function totalSupply(uint256 tokenId)
        external
        view
        returns (uint256 totalSupply_);

    function mint(MintData calldata mintData_)
        external
        returns (uint256 tokenId_);

    function lazyMint(LazyMintData calldata lazyMintData_)
        external
        returns (uint256 tokenId_);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_,
        uint256 quantity_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface NiftySouqIERC721V2 {
    struct NftData {
        string uri;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        bool isFirstSale;
    }

    struct MintData {
        string uri;
        address minter;
        address[] creators;
        uint256[] royalties;
        address[] investors;
        uint256[] revenues;
        bool isFirstSale;
    }

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function getNftInfo(uint256 tokenId_)
        external
        view
        returns (NftData memory nfts_);

    function mint(MintData calldata mintData_)
        external
        returns (uint256 tokenId_);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferNft(
        address from_,
        address to_,
        uint256 tokenId_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct LazyMintData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    address buyer;
    uint256 purchaseQuantity;
    address[] investors;
    uint256[] revenues;
    string currency;
}

struct AcceptOfferData {
    uint256 offerId;
    uint256 tokenId;
    address tokenContract;
    bool isERC1155;
    uint256 quantity;
    uint256 price;
    address seller;
    uint256 createdAt;
    address buyer;
    uint256 soldAt;
    string currency;
}

interface NiftySouqIFixedPrice {
    struct Payout {
        address currency;
        address seller;
        address buyer;
        uint256 tokenId;
        address tokenAddress;
        uint256 quantity;
        address[] refundAddresses;
        uint256[] refundAmount;
        bool soldout;
    }

    function isSaleSupportedTokens(string memory tokenName_)
        external
        view
        returns (bool tokenExist_);

    function lazyMint(LazyMintData calldata lazyMintData_) external;

    function acceptOffer(AcceptOfferData calldata acceptOfferData_)
        external
        returns (Payout memory payout_);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum ContractType {
    NIFTY_V1,
    NIFTY_V2,
    COLLECTOR,
    EXTERNAL,
    UNSUPPORTED
}
struct CalculatePayout {
    uint256 tokenId;
    address contractAddress;
    address seller;
    uint256 price;
    uint256 quantity;
}

struct LazyMintSellData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 minPrice;
    uint256 quantity;
    bytes signature;
    string currency;
}

struct LazyMintAuctionData {
    address tokenAddress;
    string uri;
    address seller;
    address[] creators;
    uint256[] royalties;
    address[] investors;
    uint256[] revenues;
    uint256 startTime;
    uint256 duration;
    uint256 startBidPrice;
    uint256 reservePrice;
    bytes signature;
}

struct CryptoTokens {
    address tokenAddress;
    uint256 tokenValue;
    bool isEnabled;
}

interface NiftySouqIMarketplaceManager {
    function isAdmin(address caller_) external view returns (bool);

    function isPauser(address caller_) external view returns (bool);

    function isBlocked(address caller_) external view returns (bool);

    function isPaused() external view returns (bool);

    function serviceFeeWallet() external view returns (address);

    function serviceFeePercent() external view returns (uint256);

    function getTokenDetail(string memory tokenName_)
        external
        view
        returns (CryptoTokens memory cryptoToken_);

    function tokenExist(string memory tokenName_)
        external
        view
        returns (bool tokenExist_);

    function verifyFixedPriceLazyMintV1(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyFixedPriceLazyMintV2(LazyMintSellData calldata lazyData_)
        external
        returns (address);

    function verifyAuctionLazyMint(LazyMintAuctionData calldata lazyData_)
        external
        returns (address);

    function getContractDetails(address contractAddress_)
        external
        returns (ContractType contractType_, bool isERC1155_);

    function isOwnerOfNFT(
        address address_,
        uint256 tokenId_,
        address contractAddress_
    )
        external
        returns (
            ContractType contractType_,
            bool isERC1155_,
            bool isOwner_,
            uint256 quantity_
        );

    function calculatePayout(CalculatePayout memory calculatePayout_)
        external
        returns (
            address[] memory recepientAddresses_,
            uint256[] memory paymentAmount_,
            bool isTokenTransferable_,
            bool isOwner_
        );
}