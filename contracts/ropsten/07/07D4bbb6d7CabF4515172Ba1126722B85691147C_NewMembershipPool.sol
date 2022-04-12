/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// File: @openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// File: @openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// File: @openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;



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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/Ohm.sol


pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;







interface ControlledToken is IERC20Upgradeable {
    function controllerMint(address _user, uint256 _amount) external;

    function controllerBurn(address _user, uint256 _amount) external;
}

contract Authorizable is OwnableUpgradeable {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(
            authorized[_msgSender()] || owner() == _msgSender(),
            "Authorizable: caller is not the SuperAdmin or Admin"
        );
        _;
    }

    function addAuthorized(address _toAdd) external onlyOwner {
        require(
            _toAdd != address(0),
            "Authorizable: _toAdd isn't vaild address"
        );
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) external onlyOwner {
        require(
            _toRemove != address(0),
            "Authorizable: _toRemove isn't vaild address"
        );
        authorized[_toRemove] = false;
    }
}

interface MedalNFT {
    function mint(
        address _to,
        uint256 _id,
        uint256 _quantity
    ) external;
}

contract NewMembershipPool is ReentrancyGuardUpgradeable, Authorizable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== STATE VARIABLES ========== */

    uint128 public poolPart;
    uint128 public lock_period;
    uint128 public rewardsDuration;
    uint128 public medalRewardDuration;

    uint256 constant N_COINS = 4; // DAI / BUSD / USDC /USDT
    uint256 public constant POOLS_INDEX = 5;

    uint256 public lastUpdateTime;
    uint256 public rewardTokenAmount;
    uint256 public periodFinish;
    uint256 public medalDistributeAt;
    uint256 public greenLevelLimit;
    uint256 public sliverLevelLimit;
    uint256 public goldLevelLimit;
    uint256 public viplevelLimit;
    uint256 constant PRECISION = 10**18;
    uint256 constant DENOMINATOR = 10000;
    uint256 public withdrawFees;

    uint256 public selfBalance;
    uint256 public withdrawalBettingAmount;

    uint256[N_COINS] public reserveAmount;

    address public sportBettingAddress;

    address payable public feeReciverTreasuryAddress;

    struct Member {
        uint256[N_COINS] tokensAmount;
        uint256 totalAmount;
        uint256 userPool;
        uint256 rewards;
        uint256[POOLS_INDEX] userRewardMedal;
        uint256[POOLS_INDEX] userMedalRewardPoolTokenPaid;
        uint256[POOLS_INDEX] userRewardPerPoolTokenPaid;
    }
    struct Pool {
        uint256 poolSize;
        uint256 rewardRate;
        uint256 rewardPerPoolTokenStored;
        uint256 rewardMedalPoolTokenStored;
    }

    Pool[POOLS_INDEX] public pools;

    mapping(address => Member) public members;
    mapping(address => uint256[N_COINS]) public requestedTime;
    mapping(address => uint256[N_COINS]) public amountWithdraw;

    MedalNFT public medalContract;

    IERC20Upgradeable public rewardToken;
    IERC20Upgradeable[N_COINS] public tokens;

    ControlledToken public controlledToken; //Ticket Token
    address public treasuryAddress;

    /* ========== EVENTS ========== */
    event userSupplied(address user, uint256 amount, uint256 index);
    event ImmediatelyWithdraw(address user, uint256 amount, uint256 index);
    event RequestWithdraw(address user, uint256 amount, uint256 index);
    event WithdrawalRequestedAmount(
        address user,
        uint256 amount,
        uint256 index
    );
    event CancelWithdrawRequest(address user, uint256 amount, uint256 index);
    event RewardPaid(address indexed user, uint256 reward);
    event ClaimMedal(address user, uint256 id, uint256 amount);

    /* ========== initializer ========== */
    function initialize(
        address[N_COINS] memory _tokens,
        address _rewardToken,
        address _sportBettingAddress,
        address _medalContract,
        address _controlledToken,
        address payable _feeReciverTreasuryAddress,
        address payable _treasuryAddress
    ) external initializer {
        __Ownable_init();
        for (uint8 i = 0; i < N_COINS; i++) {
            require(
                _tokens[i] != address(0),
                "Membership Pool: address should not be zero"
            );
            tokens[i] = IERC20Upgradeable(_tokens[i]);
        }
        sportBettingAddress = _sportBettingAddress;
        controlledToken = ControlledToken(_controlledToken);
        rewardToken = IERC20Upgradeable(_rewardToken);
        medalContract = MedalNFT(_medalContract);
        feeReciverTreasuryAddress = _feeReciverTreasuryAddress;
        treasuryAddress = _treasuryAddress;
        medalDistributeAt = block.timestamp;
        greenLevelLimit = 25 * PRECISION;
        sliverLevelLimit = 150 * PRECISION;
        goldLevelLimit = 500 * PRECISION;
        viplevelLimit = 5000 * PRECISION;
        lock_period = 7 days;
        rewardsDuration = 7 days;
        medalRewardDuration = 7 days;
        withdrawFees = 700;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        for (uint8 i = 1; i < POOLS_INDEX; i++) {
            pools[i].rewardPerPoolTokenStored = rewardPerPoolToken(i);
            pools[i].rewardMedalPoolTokenStored = rewardMedalPerPool(i);
        }
        lastUpdateTime = lastTimeRewardApplicable();
        if (medalDistributeAt.add(medalRewardDuration) < block.timestamp) {
            uint256 timeRatio = (block.timestamp.sub(medalDistributeAt)).div(
                medalRewardDuration
            );
            medalDistributeAt = medalDistributeAt.add(
                timeRatio.mul(medalRewardDuration)
            );
        }
        if (account != address(0)) {
            Member storage member = members[account];
            uint256 _pool = getPool(account);
            member.rewards = earned(account, _pool);
            member.userRewardPerPoolTokenPaid[_pool] = pools[_pool]
                .rewardPerPoolTokenStored;
            member.userRewardMedal[_pool] = earnedMedal(
                account,
                _pool
            );
            for (uint8 i = 1; i < POOLS_INDEX; i++) {
                member.userMedalRewardPoolTokenPaid[i] = pools[i]
                    .rewardMedalPoolTokenStored;
            }
        }
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount > 0, "MembershipPool: amount must be greater then zero");
        _;
    }

    /* ========== VIEWS ========== */

    function balanceOf(address account) public view returns (uint256) {
        return members[account].totalAmount;
    }

    function userBalance(address _address, uint256 _index)
        external
        view
        returns (uint256)
    {
        return members[_address].tokensAmount[_index];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return MathUpgradeable.min(block.timestamp, periodFinish);
    }

    function rewardMedalPerPool(uint256 _pool) public view returns (uint256) {
        if (pools[_pool].poolSize == 0) {
            return pools[_pool].rewardMedalPoolTokenStored;
        }
        if (pools[_pool].poolSize > 0) {
            return
                pools[_pool].rewardMedalPoolTokenStored.add(
                    (
                        (block.timestamp.sub(medalDistributeAt)).div(
                            medalRewardDuration
                        )
                    )
                );
        }
        return 0;
    }

    function rewardPerPoolToken(uint256 pool) public view returns (uint256) {
        if (pool == 0) {
            return 0;
        }
        if (pools[pool].poolSize == 0) {
            return pools[pool].rewardPerPoolTokenStored;
        }
        return
            pools[pool].rewardPerPoolTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(pools[pool].rewardRate)
                    .mul(1e18)
                    .div(pools[pool].poolSize)
            );
    }

    function earned(address account, uint256 pool)
        public
        view
        returns (uint256)
    {
        if (pool == 0) {
            return 0;
        }
        if (pool == getPool(account)) {
            return
                members[account]
                    .totalAmount
                    .mul(
                        rewardPerPoolToken(pool).sub(
                            members[account].userRewardPerPoolTokenPaid[pool]
                        )
                    )
                    .div(1e18)
                    .add(members[account].rewards);
        }
        return members[account].rewards;
    }

    function earnedMedal(address account, uint256 pool)
        public
        view
        returns (uint256)
    {
        if (pool == 0) {
            return 0;
        }
        if (balanceOf(account) == 0) {
            return members[account].userRewardMedal[pool];
        }
        if (pool == getPool(account)) {
            return
                (
                    rewardMedalPerPool(pool).sub(
                        members[account].userMedalRewardPoolTokenPaid[pool]
                    )
                ).add(members[account].userRewardMedal[pool]);
        }
        return members[account].userRewardMedal[pool];
    }

    function getRewardForDuration(uint256 pool)
        external
        view
        returns (uint256)
    {
        return pools[pool].rewardRate.mul(rewardsDuration);
    }

    function getBalances(uint256 _index) external view returns (uint256) {
        if (address(tokens[_index]) == address(rewardToken)) {
            return
                tokens[_index].balanceOf(address(this)).sub(rewardTokenAmount);
        }
        return tokens[_index].balanceOf(address(this));
    }

    function getPool(address _address) public view returns (uint256) {
        uint amount = members[_address].totalAmount;
        if (amount >= viplevelLimit) {
            return 4;
        } else if (amount >= goldLevelLimit) {
            return 3;
        } else if (amount >= sliverLevelLimit) {
            return 2;
        } else if (amount >= greenLevelLimit) {
            return 1;
        } else {
            return 0;
        }
    }

    function checkTerminat(address _add, uint256 _amount)
        public
        view
        returns (bool)
    {
        uint256 availableAmount = members[_add].totalAmount.sub(_amount);
        if (availableAmount < greenLevelLimit) {
            return true;
        }
        return false;
    }

    function isClaimable(address _add) public view returns (bool) {
        for (uint8 i = 0; i < N_COINS; i++) {
            if (
                block.timestamp > requestedTime[_add][i].add(lock_period) &&
                amountWithdraw[_add][i] > 0
            ) {
                return true;
            }
        }
        return false;
    }

    /* ========== INTERNAL ========== */

    //For checking whether array contains any non zero elements or not.
    function _checkValidArray(uint256[N_COINS] memory amounts)
        internal
        pure
        returns (bool)
    {
        for (uint8 i = 0; i < N_COINS; i++) {
            if (amounts[i] > 0) {
                return true;
            }
        }
        return false;
    }

    // this will add unfulfilled withdraw requests to the withdrawl queue
    function _takeBackQ(uint256 amount, uint256 _index) internal {
        amountWithdraw[_msgSender()][_index] = amountWithdraw[_msgSender()][_index]
            .add(amount);
        requestedTime[_msgSender()][_index] = block.timestamp;
    }

    function _updatePool(
        uint256 _pool,
        address _address,
        uint256 _amount,
        bool _status
    ) internal {
        Pool storage pool = pools[_pool];
        Member storage member = members[_address];
        if (_status) {
            if (member.userPool == 0) {
                member.userPool = _pool;
            }
            if (_pool == member.userPool) {
                pool.poolSize = pool.poolSize.add(_amount);
            } else {
                pools[member.userPool].poolSize = pools[
                    member.userPool
                ].poolSize.sub((member.totalAmount.sub(_amount)));
                pool.poolSize = pool.poolSize.add(
                    member.totalAmount
                );
                member.userPool = _pool;
            }
        } else {
            if (_pool == member.userPool) {
                pool.poolSize = pool.poolSize.sub(_amount);
            } else {
                pools[member.userPool].poolSize = pools[
                    member.userPool
                ].poolSize.sub((member.totalAmount.add(_amount)));
                pool.poolSize = pool.poolSize.add(
                    member.totalAmount
                );
                member.userPool = _pool;
            }
        }
    }

    function _stake(address _address, uint256 amount) internal {
        uint256 pool = getPool(_address);
        _updatePool(pool, _address, amount, true);
        if(pool != 0){
            members[_address].userRewardPerPoolTokenPaid[pool] = pools[pool]
                .rewardPerPoolTokenStored;

        }
    }

    function _withdraw(address _address, uint256 amount) internal {
        require(amount > 0, "Membership Pool: Cannot withdraw zero amount");
        uint256 pool = getPool(_address);
        _updatePool(pool, _address, amount, false);
    }

    function _getReward(address _address) internal updateReward(_address) {
        uint256 reward = members[_address].rewards;
        require(
            reward <= rewardTokenAmount,
            "MembershipPool: reward amount is not available"
        );
        if (reward > 0) {
            members[_address].rewards = 0;
            rewardToken.safeTransfer(_address, reward);
        }
        rewardTokenAmount = rewardTokenAmount.sub(reward);
        emit RewardPaid(_address, reward);
    }

    function exit(address _address,uint _amount) internal {
        _withdraw(_address,_amount);
        uint256 reward = members[_address].rewards;
        require(
            reward <= rewardTokenAmount,
            "MembershipPool: reward amount is not available"
        );
        if (reward > 0) {
            members[_address].rewards = 0;
            rewardToken.safeTransfer(_address, reward);
        }
        rewardTokenAmount = rewardTokenAmount.sub(reward);
        emit RewardPaid(_address, reward);
    }

    function _transferToken(
        IERC20Upgradeable _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            _tokenAddress.safeTransferFrom(_from, _to, _amount);
        }
    }

    /* USER FUNCTIONS (exposed to frontend) */

    //For depositing liquidity to the pool.

    //_index will be 0/1/2    0-DAI  , 1-BUSD , 2-USDC,3-USDT


    /**
     * @dev User deposit fund in membership pool 
     * @param amount amount want to deposite
     * @param _index token array index
    */
    function userDeposit(uint256 amount, uint256 _index)
        external
        nonReentrant
        updateReward(_msgSender())
        validAmount(amount)
    {
        require(
            _index >= 0 && _index < N_COINS,
            "MembershipPool: use valid tokens index"
        );
        if (members[_msgSender()].totalAmount == 0) {
            require(
                amount >= greenLevelLimit,
                "MembershipPool: amount is less for membership"
            );
        }
        members[_msgSender()].tokensAmount[_index] = members[_msgSender()]
            .tokensAmount[_index]
            .add(amount);
        members[_msgSender()].totalAmount = members[_msgSender()].totalAmount.add(
            amount
        );
        uint256 temp = amount.mul(poolPart).div(DENOMINATOR);
        uint256 _amount = amount.sub(temp);
        _transferToken(tokens[_index], _msgSender(), treasuryAddress, _amount);
        _transferToken(tokens[_index], _msgSender(), address(this), temp);
        reserveAmount[_index] = reserveAmount[_index].add(temp);
        ControlledToken(controlledToken).controllerMint(_msgSender(), amount);
        _stake(_msgSender(), amount);
        selfBalance = selfBalance.add(amount);
        emit userSupplied(_msgSender(), amount, _index);
    }

    /**
     * @dev User withdraw fund from membership pool 
     * @param amount amount want to deposite
     * @param _index token array index
     * @param _payFee true if user want to withdraw immediately
    */
    function userWithdraw(
        uint256 amount,
        uint256 _index,
        bool _payFee
    ) external nonReentrant updateReward(_msgSender()) validAmount(amount) {
        require(
            _index >= 0 && _index < 4,
            "MembershipPool: use valid tokens index"
        );
        require(
            members[_msgSender()].tokensAmount[_index] >= amount,
            "MembershipPool: member balance is low"
        );
        bool terminate = checkTerminat(_msgSender(), amount);
        uint256 _total;
        require(
            !terminate,
            "MembershipPool: user amount fall from minimum level"
        );
        if (_payFee) {
            uint256 feeAmount = amount.mul(withdrawFees).div(DENOMINATOR);
            require(
                reserveAmount[_index] >= amount,
                "MembershipPool: fund not available for withdraw"
            );
            tokens[_index].safeTransfer(feeReciverTreasuryAddress, feeAmount);
            tokens[_index].safeTransfer(_msgSender(), amount.sub(feeAmount));
            members[_msgSender()].totalAmount = members[_msgSender()]
                .totalAmount
                .sub(amount);
            members[_msgSender()].tokensAmount[_index] = members[_msgSender()]
                .tokensAmount[_index]
                .sub(amount);
            _total = _total.add(amount);
            reserveAmount[_index] = reserveAmount[_index].sub(amount);
            emit ImmediatelyWithdraw(_msgSender(), amount, _index);
            ControlledToken(controlledToken).controllerBurn(_msgSender(), _total);
            _withdraw(_msgSender(), _total);
            selfBalance = selfBalance.sub(_total);
        } else {
            _takeBackQ(amount, _index);
            _total = _total.add(amount);
            members[_msgSender()].totalAmount = members[_msgSender()]
                .totalAmount
                .sub(amount);
            members[_msgSender()].tokensAmount[_index] = members[_msgSender()]
                .tokensAmount[_index]
                .sub(amount);
            emit RequestWithdraw(_msgSender(), amount, _index);
            ControlledToken(controlledToken).controllerBurn(_msgSender(), _total);
            _withdraw(_msgSender(), _total);
        }
    }

    /**
     * @dev User withdraw all his fund from membership pool 
     * @param _payFee true if user want to withdraw immediately
    */
    function terminateMembership(bool _payFee) external updateReward(_msgSender()) nonReentrant {
        uint256[N_COINS] memory _amounts;
        uint256 _total;
        _amounts = members[_msgSender()].tokensAmount;
        require(
            _checkValidArray(_amounts),
            "Membership Pool: user amount is zero"
        );
        if (_payFee) {
            for (uint8 i = 0; i < N_COINS; i++) {
                if (_amounts[i] > 0) {
                    require(
                        reserveAmount[i] >= _amounts[i],
                        "MembershipPool: fund not available for withdraw"
                    );
                    uint256 temp = _amounts[i].mul(withdrawFees).div(
                        DENOMINATOR
                    );
                    tokens[i].safeTransfer(feeReciverTreasuryAddress, temp);
                    tokens[i].safeTransfer(_msgSender(), _amounts[i].sub(temp));
                    reserveAmount[i] = reserveAmount[i].sub(_amounts[i]);
                    members[_msgSender()].tokensAmount[i] = 0;
                    _total = _total.add(_amounts[i]);
                    emit ImmediatelyWithdraw(_msgSender(), _amounts[i], i);
                }
            }
            selfBalance = selfBalance.sub(_total);
        } else {
            for (uint8 i = 0; i < N_COINS; i++) {
                if (_amounts[i] > 0) {
                    _takeBackQ(_amounts[i], i);
                    members[_msgSender()].tokensAmount[i] = 0;
                    _total = _total.add(_amounts[i]);
                    emit RequestWithdraw(_msgSender(), _amounts[i], i);
                }
            }
        }
        members[_msgSender()].totalAmount = 0;
        ControlledToken(controlledToken).controllerBurn(_msgSender(), _total);
        exit(msg.sender,_total); 
    }

    /**
     * @dev User withdraw all his requested amount from membership pool 
    */
    function withdrawalRequestedAmount() external nonReentrant {
        require(isClaimable(_msgSender()), "MembershipPool: unable to claim");
        uint256 _total;
        for (uint8 i = 0; i < N_COINS; i++) {
            if (
                block.timestamp >
                requestedTime[_msgSender()][i].add(lock_period) &&
                amountWithdraw[_msgSender()][i] > 0
            ) {
                require(
                    reserveAmount[i] >= amountWithdraw[_msgSender()][i],
                    "MembershipPool: fund not available for withdraw"
                );
                tokens[i].safeTransfer(
                    _msgSender(),
                    amountWithdraw[_msgSender()][i]
                );
                _total = _total.add(amountWithdraw[_msgSender()][i]);
                reserveAmount[i] = reserveAmount[i].sub(
                    amountWithdraw[_msgSender()][i]
                );
                emit WithdrawalRequestedAmount(
                    _msgSender(),
                    amountWithdraw[_msgSender()][i],
                    i
                );
                requestedTime[_msgSender()][i] = 0;
                amountWithdraw[_msgSender()][i] = 0;
            }
        }
        selfBalance = selfBalance.sub(_total);
    }

    /**
     * @dev cancel all his requested amount to withdraw
    */
    function cancelWithdrawRequest() external updateReward(_msgSender()) nonReentrant {
        uint256 _total;
        for (uint8 i = 0; i < N_COINS; i++) {
            if (amountWithdraw[_msgSender()][i] > 0) {
                members[_msgSender()].tokensAmount[i] = members[_msgSender()]
                    .tokensAmount[i]
                    .add(amountWithdraw[_msgSender()][i]);
                _total = _total.add(amountWithdraw[_msgSender()][i]);
                emit CancelWithdrawRequest(
                    _msgSender(),
                    amountWithdraw[_msgSender()][i],
                    i
                );
                amountWithdraw[_msgSender()][i] = 0;
                requestedTime[_msgSender()][i] = 0;
            }
        }
        members[_msgSender()].totalAmount = members[_msgSender()].totalAmount.add(
            _total
        );
        _stake(_msgSender(), _total);
        ControlledToken(controlledToken).controllerMint(_msgSender(), _total);
    }

    /**
     * @dev claim all reward amount from pool 
    */
    function getReward() external nonReentrant {
        _getReward(_msgSender());
    }

    /**
     * @dev claim all medal reward amount from pool 
    */
    function claimMedal() external nonReentrant updateReward(_msgSender()) {
        for (uint8 i = 1; i < POOLS_INDEX; i++) {
            uint256 nftAmount = members[_msgSender()].userRewardMedal[i];
            if (nftAmount > 0) {
                medalContract.mint(_msgSender(), i, nftAmount);
                members[_msgSender()].userRewardMedal[i] = 0;
                emit ClaimMedal(_msgSender(), i, nftAmount);
            }
        }
    }

    /* CORE FUNCTIONS (called by owner only) */

    /**
     * @dev  Admin function admin add reserve amount for user withdraw 
     * @param _amounts pass all four token amount
    */
    function increaseReserveAmount(uint256[N_COINS] memory _amounts)
        external
        onlyAuthorized
    {
        for (uint8 i = 0; i < N_COINS; i++) {
            if (_amounts[i] > 0) {
                tokens[i].safeTransferFrom(
                    _msgSender(),
                    address(this),
                    _amounts[i]
                );
                reserveAmount[i] = reserveAmount[i].add(_amounts[i]);
            }
        }
    }


    /**
     * @dev  Admin function admin withdraw reserve amount from the pool 
     * @param _amounts pass all four token amount
    */
    function withdrawalReserveAmount(uint256[N_COINS] memory _amounts)
        external
        onlyAuthorized
    {
        for (uint8 i = 0; i < N_COINS; i++) {
            require(
                reserveAmount[i] >= _amounts[i],
                "MembershipPool: amount is not available for withdraw"
            );
            if (_amounts[i] > 0) {
                tokens[i].safeTransfer(treasuryAddress, _amounts[i]);
                reserveAmount[i] = reserveAmount[i].sub(_amounts[i]);
            }
        }
    }


    /**
     * @dev  Admin function admin deposit betting amount 
     * @param amounts pass all four token amount
    */
    function depositBettingFund(uint256[N_COINS] memory amounts)
        external
        onlyAuthorized
    {
        require(
            _checkValidArray(amounts),
            "MembershipPool: amount can't be zero"
        );
        uint256 _total;
        for (uint8 i = 0; i < N_COINS; i++) {
            _total = _total.add(amounts[i]);
        }
        require(
            withdrawalBettingAmount >= _total,
            "MembershipPool: deposit amount must be less than withdrawalBettingAmount"
        );
        for (uint8 i = 0; i < N_COINS; i++) {
            if (amounts[i] > 0) {
                withdrawalBettingAmount = withdrawalBettingAmount.sub(amounts[i]);
                tokens[i].safeTransferFrom(
                    _msgSender(),
                    address(this),
                    amounts[i]
                );
                reserveAmount[i] = reserveAmount[i].add(amounts[i]);
                
            }
        }
    }

    /**
     * @dev Admin function admin withdraw betting amount from the pool 
     * @param amounts pass all four token amount
    */
    function withdrawBettingFund(uint256[N_COINS] memory amounts)
        external
        onlyAuthorized
    {
        require(
            _checkValidArray(amounts),
            "Membership Pool: amount can not zero"
        );
        uint256 _total;
        for (uint8 i = 0; i < N_COINS; i++) {
            _total = _total.add(amounts[i]);
        }
        for (uint8 i = 0; i < N_COINS; i++) {
            require(
                amounts[i] <= reserveAmount[i],
                "Membership Pool: token amount not avialable in pool"
            );
            if (amounts[i] > 0) {
                tokens[i].safeTransfer(sportBettingAddress, amounts[i]);
                reserveAmount[i] = reserveAmount[i].sub(amounts[i]);
            }
        }
        withdrawalBettingAmount = withdrawalBettingAmount.add(_total);
    }


    /**
     * @dev Admin function change and set ticket token address 
    */
    function setControlToken(address _controlledToken) external onlyAuthorized {
        require(
            _controlledToken != address(0),
            "Membership Pool: not a valid address"
        );
        require(
            address(controlledToken) != _controlledToken,
            "Membership Pool: address is same"
        );
        controlledToken = ControlledToken(_controlledToken);
    }

    function _notifyRewardAmount(
        uint256 reward,
        uint256[POOLS_INDEX] memory poolShare
    ) internal updateReward(address(0)) {
        uint256[POOLS_INDEX] memory _reward;
        uint256 _total;
        for (uint8 i = 1; i < POOLS_INDEX; i++) {
            _total = _total.add(poolShare[i]);
        }
        require(_total == DENOMINATOR, "Membership Pool: not valid pool share");
        for (uint8 i = 1; i < POOLS_INDEX; i++) {
            _reward[i] = reward.mul(poolShare[i]).div(DENOMINATOR);
            if (_reward[i] > 0) {
                if (block.timestamp >= periodFinish) {
                    pools[i].rewardRate = _reward[i].div(rewardsDuration);
                } else {
                    uint256 remaining = periodFinish.sub(block.timestamp);
                    uint256 leftover = remaining.mul(pools[i].rewardRate);
                    pools[i].rewardRate = _reward[i].add(leftover).div(
                        rewardsDuration
                    );
                }
                // Ensure the provided reward amount is not more than the balance in the contract.
                // This keeps the reward rate in the right range, preventing overflows due to
                // very high values of rewardRate in the earned and rewardsPerToken functions;
                // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
                uint256 balance = IERC20Upgradeable(rewardToken).balanceOf(address(this));
                require(
                    pools[i].rewardRate <= balance.div(rewardsDuration),
                    "Membership Pool: Provided reward too high"
                );
            }
        }
        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
    }


    /**
     * @dev Admin function add reward token amount 
    */
    function notifyRewardAmount(
        uint256 reward,
        uint256[POOLS_INDEX] memory poolShare
    ) external onlyAuthorized  {
        require(reward > 0, "No reward");
        // handle the transfer of reward tokens via `transferFrom` to reduce the number
        // of transactions required and ensure correctness of the reward amount
        IERC20Upgradeable(rewardToken).safeTransferFrom(
            _msgSender(),
            address(this),
            reward
        );
        _notifyRewardAmount(reward, poolShare);
        rewardTokenAmount = rewardTokenAmount.add(reward);
    }

    /**
     * @dev Owner function Owner set/change token reward duration  
    */
    function setRewardsDuration(uint128 _rewardsDuration) external onlyOwner {
        require(
            periodFinish == 0 || block.timestamp > periodFinish,
            "Membership Pool: Previous rewards period must be complete "
        );
        rewardsDuration = _rewardsDuration;
    }

    /**
     * @dev Owner function Owner set/change medal reward duration  
    */
    function setMedalRewardsDuration(uint128 _rewardsDuration)
        external
        onlyAuthorized
        updateReward(address(0))
    {
        require(
            _rewardsDuration != 0,
            "Membership Pool: _rewardsDuration is not be zero "
        );
        medalRewardDuration = _rewardsDuration;
        medalDistributeAt = block.timestamp;
    }

    /**
     * @dev Owner function Owner change lock_period   
    */
    function changeLockPeriod(uint128 _lockPeriod) external onlyOwner {
        require(
            _lockPeriod != 0,
            "Membership Pool: _lockPeriod is not be zero "
        );
        lock_period = _lockPeriod;
    }

    /**
     * @dev Owner function change pool part   
    */
    function changePoolPart(uint128 _newPoolPart) external onlyOwner {
        require(_newPoolPart != poolPart, "MembershipPool : pool part is same");
        poolPart = _newPoolPart;
    }

    /**
     * @dev Owner function Owner change level limits   
    */
    function changeMembershipLimit(
        uint256 _greenLevelLimit,
        uint256 _sliverLevelLimit,
        uint256 _goldLevelLimit,
        uint256 _viplevelLimit
    ) external onlyOwner updateReward(address(0)) {
        greenLevelLimit = _greenLevelLimit;
        sliverLevelLimit = _sliverLevelLimit;
        goldLevelLimit = _goldLevelLimit;
        viplevelLimit = _viplevelLimit;
    }

    /**
     * @dev Owner function Owner change medalContract address  
    */
    function changeMedalContract(address _medalContract) external onlyOwner {
        require(
            _medalContract != address(0) &&
                _medalContract != address(medalContract),
            "Membership Pool: address is not valid "
        );
        medalContract = MedalNFT(_medalContract);
    }

    /**
     * @dev Owner function Owner change rewardToken address  
    */
    function changeRewardToken(address _rewardToken) external onlyOwner {
        require(rewardTokenAmount == 0,"Membershi pool : privious reward must be distributed");
        require(
            _rewardToken != address(0) && _rewardToken != address(rewardToken),
            "Membership Pool: address is not valid "
        );
        rewardToken = IERC20Upgradeable(_rewardToken);
    }

    /**
     * @dev Owner function Owner change sportBettingAddress address  
    */
    function changeBettingFundsReciverAddress(
        address _sportBettingAddress
    ) external onlyOwner {
        require(
            _sportBettingAddress != address(0),
            "Membership Pool: address is not valid "
        );
        sportBettingAddress = _sportBettingAddress;
    }

    /**
     * @dev Owner function Owner change feeReciverTreasuryAddress address  
    */
    function setfeeReciverTreasuryAddress(
        address payable _feeReciverTreasuryAddress
    ) external onlyOwner {
        require(
            _feeReciverTreasuryAddress != address(0),
            "Membership Pool: _feeReciverTreasuryAddress not be zero address"
        );
        feeReciverTreasuryAddress = _feeReciverTreasuryAddress;
    }

    /**
     * @dev Owner function Owner change treasury address  
    */
    function setTreasuryAddress(address payable _treasuryAddress)
        external
        onlyOwner
    {
        require(
            _treasuryAddress != address(0),
            "Membership Pool: _treasuryAddress not be zero address"
        );
        treasuryAddress = _treasuryAddress;
    }

    
}