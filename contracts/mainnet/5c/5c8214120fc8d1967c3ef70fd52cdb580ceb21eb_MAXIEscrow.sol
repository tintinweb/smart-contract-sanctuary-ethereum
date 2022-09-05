/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// File: @openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;



/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// File: contracts/PerpetualPool.sol


pragma solidity ^0.8.2;








contract HedronToken {
  function approve(address spender, uint256 amount) external returns (bool) {}
  function transfer(address recipient, uint256 amount) external returns (bool) {}
  function mintNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256) {}
  function claimNative(uint256 stakeIndex, uint40 stakeId) external returns (uint256) {}
  function currentDay() external view returns (uint256) {}
}

contract HEXToken {
  function currentDay() external view returns (uint256){}
  function stakeStart(uint256 newStakedHearts, uint256 newStakedDays) external {}
  function approve(address spender, uint256 amount) external returns (bool) {}
  function transfer(address recipient, uint256 amount) public returns (bool) {}
  function stakeEnd(uint256 stakeIndex, uint40 stakeIdParam) public {}
  function stakeCount(address stakerAddr) external view returns (uint256) {}
}
/*
 /$$      /$$                     /$$                                         /$$$$$$$$ /$$$$$$$$  /$$$$$$  /$$      /$$
| $$$    /$$$                    |__/                                        |__  $$__/| $$_____/ /$$__  $$| $$$    /$$$
| $$$$  /$$$$  /$$$$$$  /$$   /$$ /$$ /$$$$$$/$$$$  /$$   /$$  /$$$$$$$         | $$   | $$      | $$  \ $$| $$$$  /$$$$
| $$ $$/$$ $$ |____  $$|  $$ /$$/| $$| $$_  $$_  $$| $$  | $$ /$$_____/         | $$   | $$$$$   | $$$$$$$$| $$ $$/$$ $$
| $$  $$$| $$  /$$$$$$$ \  $$$$/ | $$| $$ \ $$ \ $$| $$  | $$|  $$$$$$          | $$   | $$__/   | $$__  $$| $$  $$$| $$
| $$\  $ | $$ /$$__  $$  >$$  $$ | $$| $$ | $$ | $$| $$  | $$ \____  $$         | $$   | $$      | $$  | $$| $$\  $ | $$
| $$ \/  | $$|  $$$$$$$ /$$/\  $$| $$| $$ | $$ | $$|  $$$$$$/ /$$$$$$$/         | $$   | $$$$$$$$| $$  | $$| $$ \/  | $$
|__/     |__/ \_______/|__/  \__/|__/|__/ |__/ |__/ \______/ |_______/          |__/   |________/|__/  |__/|__/     |__/
                                                                                                                        
                                                                                                                        
                                                                                                                        
                           /$$         /$$     /$$                                                                      
                          | $$        | $$    | $$                                                                      
  /$$$$$$  /$$$$$$$   /$$$$$$$       /$$$$$$  | $$$$$$$   /$$$$$$                                                       
 |____  $$| $$__  $$ /$$__  $$      |_  $$_/  | $$__  $$ /$$__  $$                                                      
  /$$$$$$$| $$  \ $$| $$  | $$        | $$    | $$  \ $$| $$$$$$$$                                                      
 /$$__  $$| $$  | $$| $$  | $$        | $$ /$$| $$  | $$| $$_____/                                                      
|  $$$$$$$| $$  | $$|  $$$$$$$        |  $$$$/| $$  | $$|  $$$$$$$                                                      
 \_______/|__/  |__/ \_______/         \___/  |__/  |__/ \_______/                                                      
                                                                                                                        
                                                                                                                        
                                                                                                                        
 /$$$$$$$                                           /$$                         /$$                                     
| $$__  $$                                         | $$                        | $$                                     
| $$  \ $$ /$$$$$$   /$$$$$$   /$$$$$$   /$$$$$$  /$$$$$$   /$$   /$$  /$$$$$$ | $$  /$$$$$$$                           
| $$$$$$$//$$__  $$ /$$__  $$ /$$__  $$ /$$__  $$|_  $$_/  | $$  | $$ |____  $$| $$ /$$_____/                           
| $$____/| $$$$$$$$| $$  \__/| $$  \ $$| $$$$$$$$  | $$    | $$  | $$  /$$$$$$$| $$|  $$$$$$                            
| $$     | $$_____/| $$      | $$  | $$| $$_____/  | $$ /$$| $$  | $$ /$$__  $$| $$ \____  $$                           
| $$     |  $$$$$$$| $$      | $$$$$$$/|  $$$$$$$  |  $$$$/|  $$$$$$/|  $$$$$$$| $$ /$$$$$$$/                           
|__/      \_______/|__/      | $$____/  \_______/   \___/   \______/  \_______/|__/|_______/                            
                             | $$                                                                                       
                             | $$                                                                                       
                             |__/                                                                                      


// Anyone may choose to mint 1 Perpetual Pool Token per HEX pledged to the Perpetual Pool Contract during the minting phase.
// Pool Tokens are a standard ERC20 token, only minted upon HEX deposit and burnt upon HEX redemption with no pre-mine.
// Pool Token holders may choose to burn their Pool Tokens to redeem HEX principal and yield pro-rata from the Pool Token Contract Address during the reload phase.
// The Perpetual Pools start with an initial minting phase, followed by a stake phase. Then once the HEX stake has ended they enter a reload phase where HEX may be redeemed with Pool Tokens or Pool Tokens may be minted with HEX - all at the same redemption rate.
// Then after the reload phase ends another Stake Phase begins and the cycle repeats forever.


// PHASES:        |----- Minting Phase ----|------ Stake Phase -----...-----|---- Reload Phase ----->|----- Stake Phase ------|----> REPEAT FOREVER
// WHAT HAPPENS?  |       Mint and redeem  |    No Minting or Redeeming     |   Mint and redeem      | No Minting or Redeeming|---->
// FUNCTIONS USED:| pledgeHEX(),redeemHEX()|      mintHedron()              | pledgeHEX(),redeemHEX()|      mintHedron().     |
// TRANSITION FUNCTION:       stakeStart() ^                  endStakeHex() ^           stakeStart() ^          endStakeHex() ^ 

// The Pool Contracts send half of it's Bigger Pays Better Bonus HEX Yield and all of the HDRN the stake accumulated to the Maximus TEAM Contract as a thank you for deploying the pools and an incentive to grow the stake pooling economy.



THE PERPETUAL POOLS CONTRACTS, SUPPORTING WEBSITES, AND ALL OTHER INTERFACES (THE SOFTWARE) IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM
LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

BY INTERACTING WITH THE SOFTWARE YOU ARE ASSERTING THAT YOU BEAR ALL THE RISKS ASSOCIATED WITH DOING SO. AN INFINITE NUMBER OF UNPREDICTABLE THINGS MAY GO WRONG WHICH COULD POTENTIALLY RESULT IN CRITICAL FAILURE AND FINANCIAL LOSS. BY INTERACTING WITH THE SOFTWARE YOU ARE ASSERTING THAT YOU AGREE THERE IS NO RECOURSE AVAILABLE AND YOU WILL NOT SEEK IT.

INTERACTING WITH THE SOFTWARE SHALL NOT BE CONSIDERED AN INVESTMENT OR A COMMON ENTERPRISE. INSTEAD, INTERACTING WITH THE SOFTWARE IS EQUIVALENT TO CARPOOLING WITH FRIENDS TO SAVE ON GAS AND EXPERIENCE THE BENEFITS OF THE H.O.V. LANE. 

YOU SHALL HAVE NO EXPECTATION OF PROFIT OR ANY TYPE OF GAIN FROM THE WORK OF OTHER PEOPLE.

*/


contract PerpetualPool is ERC20, ERC20Burnable, ReentrancyGuard {
    // all days are measured in terms of the HEX contract day number
    uint256 public RELOAD_PHASE_DURATION; // How many days are between each stake
    uint256 public RELOAD_PHASE_START; // the day when the current reload phase starts, is updated as each stake ends
    uint256 public RELOAD_PHASE_END; // the day when the current reload phase ends, is updated as each stake ends
    uint256 public STAKE_START_DAY; // the day when the current stake starts, is updated as each stake starts
    uint256 public STAKE_END_DAY; // the day when the current stake ends, is updated as each stake starts
    uint256 public STAKE_LENGTH; // length of the stake
    uint256 public HEX_REDEMPTION_RATE; // Number of HEX units redeemable per Perpetual Pool Token and the number of HEX required to mint a new Perpetual Pool Token after a stake ends
    bool public STAKE_IS_ACTIVE; // Used to keep track of whether or not the HEX stake is active. Is TRUE during stake phases and FALSE during reload ohases
    address public END_STAKER; // Address who paid the gas to end the stake
    address public TEAM_CONTRACT_ADDRESS;
    uint256 public CURRENT_STAKE_PRINCIPAL; // Principal of current stake, updated whenever a stake starts and reset to zero when a stake ends.
    uint256 public CURRENT_PERIOD; // even numbers are Reload Period, odd numbers are staking periods.

    
    constructor(uint256 initial_mint_duration, uint256 stake_duration, uint256 reload_duration,address team_address, string memory name, string memory ticker) ERC20(name, ticker) ReentrancyGuard() {
        RELOAD_PHASE_DURATION=reload_duration;
        uint256 start_day=hex_token.currentDay();
        RELOAD_PHASE_START = start_day;
        RELOAD_PHASE_END = start_day+initial_mint_duration; // The initial RELOAD PHASE may be set to be different than the ongoing reload phases.
        STAKE_LENGTH=stake_duration; 
        STAKE_IS_ACTIVE=false;
        TEAM_CONTRACT_ADDRESS=team_address;
        HEX_REDEMPTION_RATE=100000000; // HEX and MINI are 1:1 convertible during first minting/redemption phase. Then this will scale based on treasury value.
        CURRENT_STAKE_PRINCIPAL=0;
        CURRENT_PERIOD=0;
    }
    
    address POOL_ADDRESS =address(this);
    address constant HEX_ADDRESS = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39; // "2b, 5 9 1e? that is the question..."
    address constant HEDRON_ADDRESS=0x3819f64f282bf135d62168C1e513280dAF905e06; 

    IERC20 hex_contract = IERC20(HEX_ADDRESS);
    IERC20 hedron_contract=IERC20(HEDRON_ADDRESS);
    HEXToken hex_token = HEXToken(HEX_ADDRESS);
    HedronToken hedron_token = HedronToken(HEDRON_ADDRESS);
    
    /**
    * @dev View number of decimal places the Pool Token is divisible to. Manually overwritten from default 18 to 8 to match that of HEX. 1 Pool Token = 10^8 mini
    */
    function decimals() public view virtual override returns (uint8) {return 8;}

    /**
    * @dev Returns the current Period. Even numbers are Reload Phases, Odd numbers are staking phases."
    * @return Current Period
    */
    function getCurrentPeriod() external view returns (uint256){
        return CURRENT_PERIOD;
    }
    // @dev Returns the current day from the hex contract.
    function getHexDay() external view returns (uint256){
        uint256 day = hex_token.currentDay();
        return day;
    }

     /**
    * @dev Returns the address of the person who ends stake. May be used by external gas pooling contracts. If stake has not been ended yet will return 0x000...000"
    * @return end_staker_address This person should be honored and celebrated as a hero.
    */
    function getEndStaker() external view returns (address end_staker_address) {return END_STAKER;}

    // Pool Token Issuance and Redemption Functions
    /**
     * @dev Mints Pool Token.
     * @param amount of Pool Tokens to mint, measured in minis
     */
    function mint(uint256 amount) private {
        _mint(msg.sender, amount);
    }
     /**
     * @dev Ensures that Pool Token Minting Phase is ongoing and that the user has allowed the Perpetual Pool Contract address to spend the amount of HEX the user intends to pledge to The Perpetual Pool. Then sends the designated HEX from the user to the Perpetual Pool Contract address and mints 1 Pool Token per HEX pledged.
     * @param amount of HEX user chose to pledge, measured in hearts
     */
    function pledgeHEX(uint256 amount) nonReentrant external {
        require(STAKE_IS_ACTIVE==false, "Minting may only be done if a stake is not active");
        require(hex_token.currentDay()<=RELOAD_PHASE_END, "Minting Phase is Done");
        require(hex_contract.allowance(msg.sender, POOL_ADDRESS)>=amount, "Please approve contract address as allowed spender in the hex contract.");
        address from = msg.sender;
        hex_contract.transferFrom(from, POOL_ADDRESS, amount);
        uint256 mintable_amount = (10**8)*amount/HEX_REDEMPTION_RATE;
        mint(mintable_amount);
    }
     /**
     * @dev Ensures that it is currently a redemption period (before stake starts or after stake ends) and that the user has at least the number of Pool Tokens they entered. Then it calculates how much hex may be redeemed, burns the Pool Token, and transfers them the hex.
     * @param amount number of Pool Tokens that the user is redeeming, measured in mini
     */
    function redeemHEX(uint256 amount) nonReentrant external {
        require(STAKE_IS_ACTIVE==false, "Redemption can not happen while stake is active");
        uint256 your_balance = balanceOf(msg.sender);
        require(your_balance>=amount, "You do not have that much of the Pool Token.");
        uint256 raw_redeemable_amount = amount*HEX_REDEMPTION_RATE;
        uint256 redeemable_amount = raw_redeemable_amount/(10**8); //scaled back down to handle integer rounding
        burn(amount);
        hex_token.transfer(msg.sender, redeemable_amount);
        
    }
    //Staking Functions
    // Anyone may run these functions during the allowed time, so long as they pay the gas.
    // While nothing is forcing you to, gracious Perpetual Pool members will tip the sender some ETH for paying gas to end your stake.

    /**
     * @dev Ensures that the stake has not started yet and that the minting phase is over. Then it stakes all the hex in the contract and schedules the STAKE_END_DAY.
     * @notice This will trigger the start of the HEX stake. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement.
     
     */
    function stakeHEX() nonReentrant external {
        require(STAKE_IS_ACTIVE==false, "Stake has already started.");
        uint256 current_day = hex_token.currentDay();
        require(current_day>RELOAD_PHASE_END, "Minting Phase is still ongoing - see RELOAD_PHASE_END day.");
        uint256 amount = hex_contract.balanceOf(address(this));
        _stakeHEX(amount);
        CURRENT_STAKE_PRINCIPAL=amount;
        STAKE_START_DAY=current_day;
        STAKE_END_DAY=current_day+STAKE_LENGTH;
        STAKE_IS_ACTIVE=true;
        CURRENT_PERIOD = CURRENT_PERIOD+1;
    }
    function _stakeHEX(uint256 amount) private  {
        hex_token.stakeStart(amount,STAKE_LENGTH);
        }
    
    function _endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam ) private  {
        hex_token.stakeEnd(stakeIndex, stakeIdParam);
        }
    /**
     * @dev Ensures that the stake is fully complete and that it has not already been ended. Then it ends the hex stake and updates the redemption rate.
     * @notice This will trigger the ending of the HEX stake and calculate the new redemption rate. This may be very expensive. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeIdParam stake identifier found in stakeLists[contract_address] in hex contract.
     */
    function endStakeHEX(uint256 stakeIndex,uint40 stakeIdParam ) nonReentrant external {
        require(hex_token.currentDay()>STAKE_END_DAY, "Stake is not complete yet.");
        require(STAKE_IS_ACTIVE==true, "Stake must be active.");
        _endStakeHEX(stakeIndex, stakeIdParam);
        uint256 hex_balance = hex_contract.balanceOf(address(this));
        uint256 bpb_bonus_sharing_amount = get_bonus_sharing_amount(CURRENT_STAKE_PRINCIPAL, hex_balance,STAKE_LENGTH);
        hex_token.transfer(TEAM_CONTRACT_ADDRESS, bpb_bonus_sharing_amount);
        hedron_token.transfer(TEAM_CONTRACT_ADDRESS,hedron_contract.balanceOf(address(this)));
        uint256 total_supply = IERC20(address(this)).totalSupply();
        HEX_REDEMPTION_RATE  = calculate_redemption_rate(hex_contract.balanceOf(address(this)), total_supply);
        END_STAKER=msg.sender;
        CURRENT_STAKE_PRINCIPAL=0;
        STAKE_IS_ACTIVE=false;
        RELOAD_PHASE_START=hex_token.currentDay();
        RELOAD_PHASE_END=RELOAD_PHASE_START+RELOAD_PHASE_DURATION;
        CURRENT_PERIOD = CURRENT_PERIOD+1;
         
        
    }

    //@dev This calculates the amount of HEX to send to the Maximus TEAM Contract. See HEX Staking Bonuses for Details about BPB and LPB Bonuses
    function get_bonus_sharing_amount(uint256 principal,uint256 end_value, uint256 stake_length) private pure returns(uint256) {
        
        
        uint256 bpb_effective_hex;
        
        uint256 bpb_threshold = 150000000*(10**8);
        if (principal>bpb_threshold) {
            bpb_effective_hex = principal/10;
        }
        else {
            uint256 scaled_bpb_multiplier = (((10**8)*(principal))/(10*bpb_threshold));
            bpb_effective_hex = principal * (scaled_bpb_multiplier)/(10**8);
        }   
        uint256 lpb_effective_hex;
        uint256 scaled_lpb_multiplier;
        uint256 lpb_threshold = 3650;
        if (stake_length>lpb_threshold) {
            scaled_lpb_multiplier = 2*(10**8);
        }
        else {
            scaled_lpb_multiplier = 2*((10**8)*(stake_length))/lpb_threshold;
            
        }   
        lpb_effective_hex = principal * (scaled_lpb_multiplier)/(10**8);
        uint256 scalar = 10**8;
        uint256 earnings = end_value-principal;
        uint256 bpb_makeup_scaled = (scalar * bpb_effective_hex)/(bpb_effective_hex+principal+lpb_effective_hex);
        uint256 bpb_earnings_scaled = earnings *bpb_makeup_scaled;
        uint256 bpb_earnings = bpb_earnings_scaled/scalar;
        return bpb_earnings/2;

    }
    /**
     * @dev Calculates the pro-rata redemption rate of any coin per Pool Token. Scales value by 10^8 to handle integer rounding.
     * @param treasury_balance The balance of coins in contract address (either HEX or HEDRON)
     * @param token_supply total Pool Token supply
     * @return redemption_rate Number of units redeemable per 10^8 decimal units of Pool Tokens. Is scaled back down by 10^8 on redemption transaction.
     */
    function calculate_redemption_rate(uint treasury_balance, uint token_supply) private pure returns (uint redemption_rate) {
        uint256 scalar = 10**8;
        uint256 scaled = (treasury_balance * scalar) / token_supply; // scale value to calculate redemption amount per Pool Token and then divide by same scalar after multiplication
        return scaled;
    }
    
    /**
     * @dev Public function which calls the private function which is used for minting available HDRN accumulated by the contract stake. 
     * @notice This will trigger the minting of the mintable Hedron earned by the stake. If you run this, you will pay the gas on behalf of the contract and you should not expect reimbursement. If check to make sure this has not been run yet already or the transaction will fail.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeId stake identifier found in stakeLists[contract_address] in hex contract.
     */
  function mintHedron(uint256 stakeIndex,uint40 stakeId ) external  {
      _mintHedron(stakeIndex, stakeId);
        }
   /**
     * @dev Private function used for minting available HDRN accumulated by the contract stake.
     * @param stakeIndex index of stake found in stakeLists[contract_address] in hex contract.
     * @param stakeId stake identifier found in stakeLists[contract_address] in hex contract.
     */
  function _mintHedron(uint256 stakeIndex,uint40 stakeId ) private  {
        hedron_token.mintNative(stakeIndex, stakeId);
        }
}
// File: contracts/Team.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;








/// @title Maximus DAO TEAM Contract
/// @author Dip Catcher @TantoNomini
/// @notice Contract for Minting and Staking TEAM.
/// @dev Deploys Perpetual HEX Stake Pool Contracts, Mystery Box Contract, 369 MAXI Escrow contract, Stake Rewards Claiming Contract. It also governs the minting and staking of TEAM.
contract Team is ERC20, ERC20Burnable, ReentrancyGuard {
/// Initialization
    // Events - used for analysis and offchain UI
    event Mint(
        address indexed minter,
        uint256 amount);
    event Stake(
        address indexed staker,
        uint256 amount, 
        uint256 current_period,
        uint256 stakeID, 
        bool is_initial);
    event ExtendStake(
        address indexed staker,
        uint256 amount, 
        uint256 staking_period, 
        uint256 stakeID);
    event EarlyEndStake(address indexed staker,
        uint256 amount, 
        uint256 staking_period, 
        uint256 stakeID);
    event EndExpiredStake(address indexed staker,
        uint256 amount, 
        uint256 staking_period, 
        uint256 stakeID);
    event RestakeExpiredStake(address indexed staker,
        uint256 amount, 
        uint256 staking_period, 
        uint256 stakeID);
    
    // Global Variables Setup
    address TEAM_ADDRESS = address(this);
    address constant MAXI_ADDRESS = 0x0d86EB9f43C57f6FF3BC9E23D8F9d82503f0e84b;
    address constant HEX_ADDRESS  = 0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39; // "2b, 5 9 1e? that is the question..."
    address constant HEDRON_ADDRESS = 0x3819f64f282bf135d62168C1e513280dAF905e06; 
    
    // Token Interfaces
    IERC20 hex_contract = IERC20(HEX_ADDRESS);  //things like TransferFrom
    IERC20 hedron_contract=IERC20(HEDRON_ADDRESS);
    HEXToken hex_token = HEXToken(HEX_ADDRESS); //things like stakeStart
    HedronToken hedron_token = HedronToken(HEDRON_ADDRESS);
    IERC20 maxi_contract = IERC20(MAXI_ADDRESS);
    MAXIToken maxi_token = MAXIToken(MAXI_ADDRESS);

    // Initialization Variables
    uint256 public MINTING_PHASE_START; // hex day that TEAM Minting Begins
    uint256 public MINTING_PHASE_END; // hex day that TEAM Minting Ends
    bool public IS_MINTING_ONGOING;
    address public ESCROW_ADDRESS; // Contract where the MAXI is held and distributed from
    address public MYSTERY_BOX_ADDRESS;
    address public STAKE_REWARD_DISTRIBUTION_ADDRESS;
    bool HAVE_POOLS_DEPLOYED;
    
    constructor() ERC20("Maximus Team", "TEAM") ReentrancyGuard() {
        IS_MINTING_ONGOING=true;
        uint256 start_day=hex_token.currentDay();
        uint256 mint_duration=21;
        MINTING_PHASE_START = start_day;
        MINTING_PHASE_END = start_day+mint_duration;
        HAVE_POOLS_DEPLOYED = false;
        GLOBAL_AMOUNT_STAKED=0;
        deployPools(); // deploy the perpetual pools
        declareSupportedTokens();  // designate the tokens supported by the staking reward distribution contract.
        deployStakeRewardDistributionContract(); // activate the staking reward distribution contract.
        deployMAXIEscrow();
        deployMysteryBox();
    }
/// Pool Deployment 
    mapping (string =>address) public poolAddresses; // poolAddresses[ticker] = address
    /*
    @notice Deploys the Perpetual Stake Pools.
    */
    function deployPools() private {
        require(HAVE_POOLS_DEPLOYED==false);
        deployPool("Maximus Base", "BASE", 369, 21, 7);
        deployPool("Maximus Trio", "TRIO", 1111, 21, 7);
        deployPool("Maximus Lucky", "LUCKY", 2555, 21, 14);
        deployPool("Maximus Decimus", "DECI", 3696, 21, 14);
        HAVE_POOLS_DEPLOYED=true;
    }  
    /*
    @dev Deploys the Perpetual Pool contract and saves the address to the poolAddresses mapping
    @param name Full contract name
    @param ticker Contract ticker symbol
    @param stake_length length of stake cycle in days
    @param mint_length length of period between stakes
    */
    function deployPool(string memory name, string memory ticker, uint stake_length, uint256 initial_mint_length, uint256 reload_length) private {
        PerpetualPool pool = new PerpetualPool(initial_mint_length, stake_length, reload_length, address(this) ,name,  ticker);
        poolAddresses[ticker] =address(pool);
    }

/// Declaring Supported Tokens
    // Income received by the TEAM Contract in tokens from the below declared supported tokens list are split up and claimable
    mapping (string => address) supportedTokens;
    /*
    @dev Declares which tokens that will be supported by the reward distribution contract.
    */
    function declareSupportedTokens() private {
        supportedTokens["HEX"] = HEX_ADDRESS;
        supportedTokens["MAXI"]=MAXI_ADDRESS;
        supportedTokens["HDRN"]=HEDRON_ADDRESS;
        supportedTokens["BASE"]=poolAddresses["BASE"];
        supportedTokens["TRIO"]=poolAddresses["TRIO"];
        supportedTokens["LUCKY"]=poolAddresses["LUCKY"];
        supportedTokens["DECI"]=poolAddresses["DECI"];
        supportedTokens["TEAM"]=address(this);
        supportedTokens["ICSA"]=0xfc4913214444aF5c715cc9F7b52655e788A569ed;
        
    }
    /*
    @dev Alternative way to get the address of a supported token. If token is not declared via declareSupportedTokens() it will return 0x0000...00000
    @return token_address of supported token.
    */
    function getSupportedTokens(string memory ticker) public view returns(address) {
            return supportedTokens[ticker];
        }
/// Activating Stake Reward Distribution Contract
    /*
    @dev deploys StakeRewardDistribution contract, detailed below. Saves STAKE_REWARD_DISTRIBUTION_CONTRACT which is used to hold and distribute staker rewards.
    */
    function deployStakeRewardDistributionContract() private {
        StakeRewardDistribution srd = new StakeRewardDistribution(address(this));
        STAKE_REWARD_DISTRIBUTION_ADDRESS = address(srd);
    }

    // MINTING
    /**
     * @dev Ensures that TEAM Minting Phase is ongoing and that the user has allowed the Team Contract address to spend the amount of MAXI the user intends to pledge to Maximus Team. 
     ** Then sends the designated MAXI from the user to the Maximus Team Contract address and mints 1 TEAM per MAXI pledged.
     * @param amount of MAXI user chose to mint with, measured in mini (minimum divisible unit of MAXI 10^-8)
     */
    function mintTEAM(uint256 amount) nonReentrant external {
        require(IS_MINTING_ONGOING==true);
        maxi_contract.transferFrom(msg.sender, TEAM_ADDRESS, amount);
        mint(amount);
        emit Mint(msg.sender, amount);
    }

    /**
     * @dev When the minting period ends:
     **   20% of the MAXI is burnt
     **   30% of the MAXI is held in a trustless escrow contract to be redistributed to stakers during designated years
     **   50% goes to the Mystery Box
     ** Deploys the 369 MAXI escrow contract, deploys the mystery box contract, completes the burn, sends the correct amount to the Escrow address and Mystery Box. Also, mints a copy of TEAM into the mystery box. Schedules the 369 MAXI Rebate.
     */
    function finalizeMinting() nonReentrant external {
        require(hex_token.currentDay()>MINTING_PHASE_END);
        require(IS_MINTING_ONGOING==true);
        uint256 total_MAXI = maxi_contract.balanceOf(address(this)); 
        uint256 burn_factor = 20; // 20% of the MAXI used to mint TEAM is burnt.
        uint256 rebate_factor = 30; // 30% of the MAXI used to mint TEAM is redistributed to TEAM stakers during years 3, 6, and 9.
        uint256 mb_factor = 50; // 50% of the MAXI used to mint TEAM is allocated to the Mystery Box.
        maxi_token.burn(burn_factor*total_MAXI/100); // burn 20% of the MAXI in the TEAM contract
        maxi_contract.transfer(ESCROW_ADDRESS, rebate_factor*total_MAXI/100); // transfer 30% of the MAXI to the 369 ESCROW address
        maxi_contract.transfer(MYSTERY_BOX_ADDRESS, mb_factor*total_MAXI/100); // Transfer 50% of the MAXI to the Mystery Box
        uint256 current_TEAM_supply = IERC20(address(this)).totalSupply();
        _mint(MYSTERY_BOX_ADDRESS,current_TEAM_supply+GLOBAL_AMOUNT_STAKED); // mint a copy of all TEAM into the Mystery Box. Include Liquid and Staked TEAM.
        IS_MINTING_ONGOING=false;
        MAXIEscrow(ESCROW_ADDRESS).scheduleRebates();
    }
    

    function deployMAXIEscrow() private {
        MAXIEscrow newEscrow = new MAXIEscrow(address(this), MAXI_ADDRESS);
        ESCROW_ADDRESS = address(newEscrow);
    }

    function deployMysteryBox() private {
        MysteryBox newMB = new MysteryBox(address(this), MAXI_ADDRESS);
        MYSTERY_BOX_ADDRESS = address(newMB);
    } 

/// Staking
    // A StakeRecord is created for each user when they stake into a new period.
    // If a stake record for a user has already been created for a particular period, the existing one will be updated.
    struct StakeRecord {
        address staker; // staker
        uint256 balance; // the remaining balance of the stake.
        uint stakeID; // how a user identifies their stakes. Each period stake increments stakeID.
        uint256 stake_expiry_period; // what period this stake is scheduled to serve through. May be extended to the next staking period during the stake_expiry_period.
        mapping(uint => uint256) stakedTeamPerPeriod; // A record of the number of TEAM that successfully served each staking period during this stake. This number crystallizes as each staking period ends and is used to claim rewards.
        bool initiated;
    }
    uint256 public GLOBAL_AMOUNT_STAKED; // Running total number of TEAM staked by all users. Incremented when any user stakes TEAM and decremented when any user end-stakes TEAM.
    mapping (address=> uint256) public USER_AMOUNT_STAKED;// Running total number of TEAM staked per user. Incremented when user stakes TEAM and decremented when user end-stakes TEAM.
    mapping (uint => uint256) public globalStakedTeamPerPeriod; // A record of the number of TEAM that are successfully staked for each stake period. Value crystallizes in each period as period ends.
    mapping (address =>mapping(uint => StakeRecord)) public stakes; // Mapping of all users stake records.
    
    /*
    @notice stakeTeam(amount) User facing function for staking TEAM. 
    @dev 1) Checks if user balance exceeds input stake amount. 2) Saves stake data via newStakeRecord(). 3) Burns the staked TEAM. 4) Update global and user stake tally.
    @param amount number of TEAM staked, include enough zeros to support 8 decimal units. to stake 1 TEAM, enter amount = 100000000
    */
    function stakeTeam(uint256 amount) external nonReentrant {
        require(amount>0);
        newStakeRecord(amount); // updates the stake record
        burn(amount); //when TEAM is staked, it is burnt and then is reminted when it is unstaked.
        GLOBAL_AMOUNT_STAKED = GLOBAL_AMOUNT_STAKED + amount;
        USER_AMOUNT_STAKED[msg.sender]=USER_AMOUNT_STAKED[msg.sender] + amount;
    }
        /*
        @dev Function that determines which is the next staking period, and creates or updates the users stake record for that period.
        */
        function newStakeRecord(uint256 amount) private {
            uint256 next_staking_period = getNextStakingPeriod(); // the contract period number for each staking period is used as a unique identifier for a stake. 
            StakeRecord storage stake = stakes[msg.sender][next_staking_period]; // retrieves the existing stake record for this upcoming staking period, or render a new one if this is the first time.
            bool is_initial;
            if (stake.initiated==false){ // first time setup. values that should not change if this user stakes again in this period.
                stake.stakeID = next_staking_period;
                stake.initiated = true;
                stake.staker = msg.sender;
                stake.stake_expiry_period = next_staking_period;
                is_initial = true;
            }
            stake.balance = amount + stake.balance;
            stake.stakedTeamPerPeriod[next_staking_period] = amount + stake.stakedTeamPerPeriod[next_staking_period];
            globalStakedTeamPerPeriod[next_staking_period] = amount + globalStakedTeamPerPeriod[next_staking_period];
            emit Stake(msg.sender, amount, getCurrentPeriod(), stake.stakeID, is_initial);
        }
    /*
    @notice earlyEndStakeTeam(stakeID, amount) User facing function for ending a part or all of a stake either before or during its expiry period. A 3.69% penalty is applied to the amount reminted to the user.
    @dev checks that they have this stake, updates the stake record via earlyEndStakeRecord() function, updates the global tallies, calculates the early end stake penalty, and remints back into existance the amount requested minus penalty.
    @param stakeID the ID of the stake the user wants to early end stake
    @param amount number of TEAM early end staked, include enough zeros to support 8 decimal units. to end stake 1 TEAM, enter amount = 100000000
    */
    function earlyEndStakeTeam(uint256 stakeID, uint256 amount) external nonReentrant {
        earlyEndStakeRecord(stakeID, amount); // update the stake record
        uint256 current_potential_penalty_scaled = 369*(10**4)*amount; // scaled up before division 
        uint256 penalty = current_potential_penalty_scaled/(10**8); 
        GLOBAL_AMOUNT_STAKED = GLOBAL_AMOUNT_STAKED - amount;
        USER_AMOUNT_STAKED[msg.sender]=USER_AMOUNT_STAKED[msg.sender] - amount;
        mint(amount-penalty);
    }
         /*
        @dev Determines if stake is pending, or in progress and updates the record to reflect the amount of TEAM that remains actively staked from that particular stake.
        @param stakeID the ID of the stake the user wants to early end stake
        @param amount number of TEAM early end staked, include enough zeros to support 8 decimal units. to end stake 1 TEAM, enter amount = 100000000
        */
        function earlyEndStakeRecord(uint256 stakeID, uint256 amount) private {
            uint256 current_period = getCurrentPeriod();
            uint256 next_staking_period = getNextStakingPeriod();
            StakeRecord storage stake = stakes[msg.sender][stakeID];
            require(stake.initiated==true);
            require(stake.stake_expiry_period>=current_period); // must be before the stake has expired
            require(stake.balance>=amount);
            stake.balance = stake.balance - amount;
            // Decrement staked TEAM from next staking period
            if (stake.stakedTeamPerPeriod[next_staking_period]>0){
                globalStakedTeamPerPeriod[next_staking_period]=globalStakedTeamPerPeriod[next_staking_period]-amount;
                stake.stakedTeamPerPeriod[next_staking_period]=stake.stakedTeamPerPeriod[next_staking_period]-amount;
            }
            // Decrement staked TEAM from current staking period.
            if (stake.stakedTeamPerPeriod[current_period]>0) {
                globalStakedTeamPerPeriod[current_period]=globalStakedTeamPerPeriod[current_period]-amount;
                stake.stakedTeamPerPeriod[current_period]=stake.stakedTeamPerPeriod[current_period]-amount;
            }
            emit EarlyEndStake(msg.sender, amount, stake.stake_expiry_period, stakeID);
        }
    /*
    @notice End a stake which has already served its full staking period. This function updates your stake record and remints your staked TEAM back into your address.
    @param stakeID the ID of the stake the user wants to end stake
    @param amount number of TEAM end staked, include enough zeros to support 8 decimal units. to end stake 1 TEAM, enter amount = 100000000
            
    */
    function endCompletedStake(uint256 stakeID, uint256 amount) external nonReentrant {
        endExpiredStake(stakeID, amount);
        GLOBAL_AMOUNT_STAKED = GLOBAL_AMOUNT_STAKED - amount;
        USER_AMOUNT_STAKED[msg.sender]=USER_AMOUNT_STAKED[msg.sender] - amount;
        mint(amount);
    }
        function endExpiredStake(uint256 stakeID, uint256 amount) private {
            uint256 current_period=getCurrentPeriod();
            StakeRecord storage stake = stakes[msg.sender][stakeID];
            require(stake.stake_expiry_period<current_period);
            require(stake.balance>=amount);
            stake.balance = stake.balance-amount;
            emit EndExpiredStake(msg.sender, amount, stake.stake_expiry_period, stakeID);
        }

    /*
    @notice This function extends a currently active stake into the next staking period. It can only be run during the expiry period of a stake. This extends the entire stake into the next period.
    @param stakeID the ID of the stake the user wants to extend into the next staking period.
*/
        function extendStake(uint256 stakeID) external nonReentrant {
            uint256 current_period=getCurrentPeriod();
            uint256 next_staking_period = getNextStakingPeriod();
            StakeRecord storage stake = stakes[msg.sender][stakeID];
            require(isStakingPeriod());
            require(stake.stake_expiry_period==current_period);
            stake.stake_expiry_period=next_staking_period;
            stake.stakedTeamPerPeriod[next_staking_period] = stake.stakedTeamPerPeriod[next_staking_period] + stake.balance;
            globalStakedTeamPerPeriod[next_staking_period] = globalStakedTeamPerPeriod[next_staking_period] + stake.balance;
            emit ExtendStake(msg.sender, stake.balance, next_staking_period, stakeID);
        }
    /*
    @notice This function ends and restakes a stake which has been completed (if current period is greater than stake expiry period). It ends the stake but does not remint your TEAM, instead it rolls those team into a brand new stake record starting in the next staking period.
    @param stakeID the ID of the stake the user wants to extend into the next staking period.
    */
    function restakeExpiredStake(uint256 stakeID) public nonReentrant {
        uint256 current_period=getCurrentPeriod();
        StakeRecord storage stake = stakes[msg.sender][stakeID];
        require(stake.stake_expiry_period<current_period);
        require(stake.balance > 0);
        newStakeRecord(stake.balance);
        uint256 amount = stake.balance;
        stake.balance = 0;
        emit RestakeExpiredStake(msg.sender, amount, stake.stake_expiry_period, stakeID);
    }
  
/// Rewards Allocation   
    mapping (string => mapping (uint => bool)) didRecordPeriodEndBalance; // didRecordPeriodEndBalance[TICKER][period]
    mapping (string =>mapping (uint => uint256)) periodEndBalance; //periodEndBalance[TICKER][period]
    mapping (string => mapping (uint => uint256)) public periodRedemptionRates; //periodRedemptionRates[TICKER][period] Number of coins claimable per team staked 

    /*
    @notice This function checks to make sure that a staking period just ended, and then measures and saves the TEAM Contracts balance of the designated token.
    @param ticker is the ticker that is to be 
    */ 
    function prepareClaim(string memory ticker) external nonReentrant {
        require(isStakingPeriod()==false);
        uint256 latest_staking_period = getCurrentPeriod()-1;
        require(didRecordPeriodEndBalance[ticker][latest_staking_period]==false);
        periodEndBalance[ticker][latest_staking_period] = IERC20(supportedTokens[ticker]).balanceOf(address(this)); //measures how many of the designated token are in the TEAM contract address
        IERC20(supportedTokens[ticker]).transfer(STAKE_REWARD_DISTRIBUTION_ADDRESS, periodEndBalance[ticker][latest_staking_period]);
        didRecordPeriodEndBalance[ticker][latest_staking_period]=true;
        uint256 scaled_rate = periodEndBalance[ticker][latest_staking_period] *(10**8)/globalStakedTeamPerPeriod[latest_staking_period];
        periodRedemptionRates[ticker][latest_staking_period] = scaled_rate;
    }
    

    function getAddressPeriodEndTotal(address staker_address, uint256 period, uint stakeID) public view returns (uint256) {
        StakeRecord storage stake = stakes[staker_address][stakeID];
        return stake.stakedTeamPerPeriod[period]; 
    }
    function getPeriodRedemptionRates(string memory ticker, uint256 period) public view returns (uint256) {
        return periodRedemptionRates[ticker][period];
    }
    
    function getPoolAddresses(string memory ticker) public view returns (address) {
        return poolAddresses[ticker];
    }


    function getClaimableAmount(address user, uint256 period, string memory ticker, uint stakeID) public view returns (uint256, address) {
        uint256 total_amount_succesfully_staked = getAddressPeriodEndTotal(user, period, stakeID);
        uint256 redeemable_amount = getPeriodRedemptionRates(ticker,period) * total_amount_succesfully_staked / (10**8);
        return (redeemable_amount, getSupportedTokens(ticker));
    }

    
/// Utilities
    /*
    @notice The current period of the TEAM Contract is the current period of the BASE Contract.
    */
    function getCurrentPeriod() public view returns (uint current_period){
        
        return PerpetualPool(poolAddresses["BASE"]).getCurrentPeriod(); 
    }
    
    
    function isStakingPeriod() public view returns (bool) {
        uint remainder = getCurrentPeriod()%2;
        if(remainder==0){
            return false;
        }
        else {
            return true;
        }
    }

    function getNextStakingPeriod() private view returns(uint256) {
        uint256 current_period=getCurrentPeriod();
        uint256 next_staking_period;
        if (isStakingPeriod()==true) {
            next_staking_period = current_period+2;
        }
        else {
            next_staking_period=current_period+1;
        }
        return next_staking_period;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 8;
	}
    
    // TEAM Issuance and Redemption Functions
    /**
     * @dev Mints TEAM.
     * @param amount of TEAM to mint, measured in meat
     */
    function mint(uint256 amount) private {
        _mint(msg.sender, amount);
    }
}

/// @title Team Stake Reward Distribution Contract
/// @author Dip Catcher @TantoNomini
/// @notice Contract for Collecting and Distributing TEAM staker reward.
contract StakeRewardDistribution is ReentrancyGuard {
    address public TEAM_ADDRESS;
    TEAMToken team_token;
    mapping (string => address) public supportedTokens;
    mapping (address => mapping(uint => mapping(uint => mapping (string => bool)))) public didUserStakeClaimFromPeriod; // log which periods and which tokens a user's stake has claimed rewards from
    constructor(address team_address) ReentrancyGuard(){
      TEAM_ADDRESS=team_address;
      team_token = TEAMToken(TEAM_ADDRESS); 
    }
    /*
    @notice Claim Rewards in the designated ticker for a period served by a stake record designated by stake ID. You can only run this function if you have not already claimed and if you have redeemable rewards for that coin from that period.
    @param period is the period you want to claim rewards from
    @param ticker is the ticker symbol for the token you want to claim
    @param stakeID is the stakeID of the stake record that contains TEAM that was succesfully staked during the period you input.
    */
    function claimRewards(uint256 period, string memory ticker, uint stakeID) nonReentrant external {
        (uint256 redeemable_amount, address token_address) = team_token.getClaimableAmount(msg.sender,period, ticker, stakeID);
        require(didUserStakeClaimFromPeriod[msg.sender][stakeID][period][ticker]==false, "You must not have already claimed from this stake on this period.");
        require(redeemable_amount>0, "No rewards from this period.");
        IERC20(token_address).transfer(msg.sender, redeemable_amount);
        didUserStakeClaimFromPeriod[msg.sender][stakeID][period][ticker]=true;
    }

    function collectSupportedTokenAddress(string memory ticker) private {
        require(supportedTokens[ticker]==address(0));
        supportedTokens[ticker]=team_token.getSupportedTokens(ticker);
    }
    /*
    @notice Run this function to retrieve and save all of the supported token addresses from the TEAM contract into the Stake Reward Distribution contract. This should be run once after the supported tokens are declared in the team contract.
    */
    function prepareSupportedTokens() nonReentrant public {
        collectSupportedTokenAddress("HEX");
        collectSupportedTokenAddress("MAXI");
        collectSupportedTokenAddress("HDRN");
        collectSupportedTokenAddress("BASE");
        collectSupportedTokenAddress("TRIO");
        collectSupportedTokenAddress("LUCKY");
        collectSupportedTokenAddress("DECI");
        collectSupportedTokenAddress("TEAM");
        collectSupportedTokenAddress("ICSA");
    }
}
/// @title 369 MAXI Escrow Contract
/// @author Dip Catcher @TantoNomini
/// @notice Contract for scheduling and releasing the MAXI rebates in years 3,6, and 9 to the TEAM Contract.
contract  MAXIEscrow is ReentrancyGuard{
  mapping (uint => uint256) public rebateSchedule;
  address MAXI_ADDRESS;
  IERC20 maxi_contract; 
  TEAMToken team_token;
  address TEAM_ADDRESS;
  bool IS_SCHEDULED;
  constructor(address team_address, address maxi_address) ReentrancyGuard(){
      TEAM_ADDRESS=team_address;
      MAXI_ADDRESS = maxi_address;
      IS_SCHEDULED=false;
      team_token = TEAMToken(TEAM_ADDRESS);  
      maxi_contract = IERC20(MAXI_ADDRESS);
  }
  /**
     * @dev Schedules the 369 MAXI Rebate by calculating amount of MAXI to send to TEAM during years 3, 6, and 9. 
  **/
  function scheduleRebates() public {
      require(IS_SCHEDULED==false, "Rebates have already been scheduled.");
      require(team_token.getCurrentPeriod()>0, "TEAM minting must be complete in order to schedule rebates.");
      uint256 total_maxi = maxi_contract.balanceOf(address(this)); // total amount of MAXI that is in the escrow contract
      uint256 scalar = 10**8;
      uint256 scaled_rebate_3 = total_maxi * 3 * scalar;
      rebateSchedule[3] = scaled_rebate_3 / (18 * scalar);
      uint256 scaled_rebate_6 = total_maxi * 6 * scalar;
      rebateSchedule[6] = scaled_rebate_6 / (18 * scalar);


      
      uint256 remaining = total_maxi - (rebateSchedule[3]+rebateSchedule[6]);
      rebateSchedule[9] = remaining;
      IS_SCHEDULED=true;
  }
  /**
     * @dev Uses current period to determine if it is year 3, 6, or 9. Then Sends the MAXI to the TEAM contract address.
  **/
  function releaseMAXI() external {
      require(IS_SCHEDULED==true, "Rebates must be scheduled before release.");
      uint256 period=team_token.getCurrentPeriod();
      require((period==5 || period==11 || period==17), "Rebates may only happen in years 3, 6, or 9.");
      uint year = (period+1)/2;
      require(rebateSchedule[year]>0, "Rebate cant be zero.");
      maxi_contract.transfer(TEAM_ADDRESS,rebateSchedule[year]);
      rebateSchedule[year]=0;

  }
}
/// @title Mystery Box
/// @author Dip Catcher @TantoNomini
/// @notice The Mystery Box is and always will be a mystery. You can't possibly have any expectations of profit resulting from the Mystery Box because it is a mystery. how could you expect anything of a mystery? you cant! Please do not run these functions because they are expensive to run and you do not benefit in any way from running them. 
contract MysteryBox is ReentrancyGuard{
    address MAXI_ADDRESS;
    IERC20 maxi_contract;
    IERC20 team_contract;
    address constant public MYSTERY_BOX_HOT_ADDRESS=0x00C055Ee792B5bC9AeB06ced73bB71ce7E5773Ce;
    address TEAM_ADDRESS;
    constructor(address team_address, address maxi_address) ReentrancyGuard() {
        TEAM_ADDRESS=team_address;
        MAXI_ADDRESS = maxi_address;
        
        team_contract = IERC20(TEAM_ADDRESS);
        maxi_contract= IERC20(MAXI_ADDRESS);
    }
    
    /**
     * @dev Sends TEAM to the MYSTERY_BOX_HOT_ADDRESS
     * ALTHOUGH ANYONE CAN RUN THSEE PUBLIC FUNCTIONS YOU ABSOLUTELY SHOULD NOT DO IT BECAUSE IT WILL COST YOU A NON-REFUNDABLE MAXI TRANSFER TO THE MYSTERY BOX HOT ADDRESS.
     * THE CONTENTS OF THE MYSTERY BOX ARE NOT YOURS. 
     * THERE IS OBVIOUSLY NO BENEFIT FOR ANYONE TO RUN THIS.
     * SERIOUSLY DON'T RUN IT, THERE ARE NO REFUNDS SO DO NOT EVEN ASK IF YOU MESS THIS UP - THERE IS NO ONE TO EVEN ASK.
     * IT IS DELIBERATELY DIFFICULT TO RUN TO PREVENT PEOPLE FROM ACCIDENTALLY RUNNING IT.
     * @param amount of MAXI SEND TO THE MYSTERY_BOX_HOT_ADDRESS
     *@param confirmation the message you have to deliberately type and broadcast stating that you know this function costs a non refundable MAXI equal to the amount you are flushing to run.
     */
    function flushTEAM(uint256 amount, string memory confirmation) nonReentrant public {
        require(amount < 1000000*(10**8), "No more than 1M TEAM may be flushed in any one transaction.");
        require(keccak256(bytes(confirmation)) == keccak256(bytes("I UNDERSTAND I WILL NOT GET THIS MAXI BACK")));
        maxi_contract.transferFrom(msg.sender, MYSTERY_BOX_HOT_ADDRESS, amount);
        team_contract.transfer(MYSTERY_BOX_HOT_ADDRESS, amount);
    }

    function flushMAXI(uint256 amount, string memory confirmation) nonReentrant public {
        require(amount < 1000000*(10**8), "No more than 1M MAXI may be flushed in any one transaction.");
        require(keccak256(bytes(confirmation)) == keccak256(bytes("I UNDERSTAND I WILL NOT GET THIS MAXI BACK")));
        maxi_contract.transferFrom(msg.sender, MYSTERY_BOX_HOT_ADDRESS, amount);
        maxi_contract.transfer(MYSTERY_BOX_HOT_ADDRESS, amount);
    }
}

contract MAXIToken {
  function approve(address spender, uint256 amount) external returns (bool) {}
  function transfer(address recipient, uint256 amount) public returns (bool) {}
  function burn(uint256 amount) public {}
  
}
contract TEAMToken {
    function getCurrentPeriod() public view returns (uint) {}
    function getAddressPeriodEndTotal(address staker_address, uint256 period, uint stakeID) public view returns (uint256) {}
    function getSupportedTokens(string memory ticker) public view returns(address) {}
    
    function getClaimableAmount(address user, uint256 period, string memory ticker, uint stakeID) public view returns (uint256, address){}
}