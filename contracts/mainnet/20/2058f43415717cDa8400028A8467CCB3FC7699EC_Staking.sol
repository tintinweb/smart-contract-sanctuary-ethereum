/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
}

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

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
 */
library EnumerableSet {
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
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
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

        assembly {
            result := store
        }

        return result;
    }
}

contract Staking is Ownable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    struct UserInfo {
        bool planChosen;
        bool withdrawn;
        uint256 lockPlan;
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
        uint256 lastDeposit;
        uint256 claimedAt;
        uint256 lockUpEnd;
    }
    struct AutoCompounder {
        EnumerableSet.AddressSet autoCompounding;
    }
    struct NftInfo {
        uint256 nftAmount;
        uint256 nftLevel;
        EnumerableSet.UintSet userNfts;
    }
    struct PoolInfo {
        IERC20 stakingToken;
        uint256 collectedPenalty;
        uint256 rewardRate;
        uint256 lastUpdateTime;
        uint256 totalStaked;
        uint256 totalReward;
        uint256 accPerShare;
        uint256 penaltyFee;
        uint256 currentIndex;
        uint256[4] lockDurations;
        uint256[4] lockBonus;
        uint256[4] stakersInLockup;
        bool active;
    }

    IERC20 public immutable rewardToken;
    address public feeRecipient;
    uint256 lockBonusDivider = 100;
    uint256 public constant MAX_FEE = 100;
    uint256 public constant FEE_LIMIT = 20; // 20%
    uint256 public totalPools;
    uint256 public rewardCycle = 24 hours;
    uint256 compoundGas = 500000;
    uint256 public endTime;
    uint256 public totalSupply;
    uint256 public dividendsDistributed;
    mapping(uint256 => PoolInfo) public poolInfo;
    mapping(uint256 => mapping(address => UserInfo)) public usersInfo;
    mapping(uint256 => AutoCompounder) compoundInfo;
    mapping(address => uint256) public usersDividends;
    bool withdrawingProcess;
    EnumerableSet.AddressSet users;

    event NftBatchDeposit(address user, uint256[] NftIds);
    event NftDeposit(address user, uint256 NftId);
    event NftBatchWithdrawl(address user, uint256[] NftIds);
    event NftWithdrawl(address user, uint256 NftId);
    event Deposit(address user, uint256 amount, uint256 poolId);
    event Withdraw(address user, uint256 amount, uint256 poolId);
    event Claim(address user, uint256 amount);
    event Compounded(address user, uint256 amount);
    event CompoundingProcessed(uint iterations, uint count);
    event PoolAdded(IERC20 Token);
    modifier updateUserList(uint256 poolId) {
        _;
        if (usersInfo[poolId][_msgSender()].amount > 0 || usersInfo[poolId][_msgSender()].pendingRewards > 0) _checkOrAddUser(_msgSender());
        else _removeUser(_msgSender());
    }
    modifier withdrawing{
        withdrawingProcess = true;
        _;
        withdrawingProcess = false;
    }
    modifier updateReward(uint256 poolId) {
        UserInfo storage user = usersInfo[poolId][_msgSender()];
        PoolInfo storage pools = poolInfo[poolId];
        if (block.timestamp <= pools.lastUpdateTime) {
            return;
        }
        uint256 totalStaked = pools.totalStaked;
        if (totalStaked == 0) {
            pools.lastUpdateTime = block.timestamp;
        }
        if(totalSupply > 0) {
            uint256 multiplier = Math.min(block.timestamp, endTime).sub(pools.lastUpdateTime);
            uint256 reward = multiplier.mul(pools.rewardRate);
            pools.accPerShare = pools.accPerShare.add(reward.mul(1e12).div(totalSupply));
            pools.totalReward = pools.totalReward.add(multiplier.mul(pools.rewardRate));
        }

        pools.lastUpdateTime = Math.min(block.timestamp, endTime);

        if(!withdrawingProcess){
            uint256 pending = user.amount.mul(pools.accPerShare).div(1e12).sub(user.rewardDebt);
            user.pendingRewards = user.pendingRewards.add(pending);
        }
        _;
        
        user.rewardDebt = user.amount.mul(pools.accPerShare).div(1e12);
        if (user.claimedAt == 0) user.claimedAt = block.timestamp;
    }

    constructor(IERC20 _rewardToken, uint256 rewardRate) {
        rewardToken = _rewardToken;
        feeRecipient = _msgSender();
        totalPools++;
        PoolInfo storage pools = poolInfo[1];
        pools.stakingToken = _rewardToken;
        pools.rewardRate = rewardRate;
        pools.active = true;
        pools.lockDurations[0] = 30 days;
        pools.lockDurations[1] = 90 days;
        pools.lockDurations[2] = 180 days;
        pools.lockDurations[3] = 360 days;
        pools.lockBonus[0] = 5;
        pools.lockBonus[1] = 15;
        pools.lockBonus[2] = 30;
        pools.lockBonus[3] = 60;
        pools.penaltyFee = 20;
        endTime = block.timestamp.add(1826.25 days); // In default, 5 years
    }

    receive() external payable {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setPool(IERC20 _token, uint256 _rewardRate, uint256[4] memory lockTimes) external onlyOwner {
        uint256 newPool = ++totalPools;
        PoolInfo storage pools = poolInfo[newPool];
        pools.stakingToken = _token;
        pools.rewardRate = _rewardRate;
        pools.active = true;
        setLockUpDurations(newPool, lockTimes[0], lockTimes[1], lockTimes[2], lockTimes[3]);
        emit PoolAdded(_token);
    }

    function updatePool(uint256 poolId, uint256 _rewardRate, bool active, uint256 penaltyFees) external onlyOwner {
        require(poolId <= totalPools);
        PoolInfo storage pools = poolInfo[poolId];
        setRewardRate(_rewardRate, poolId);
        pools.active = active;
        setPenaltyFee(poolId, penaltyFees);
    }

    function ownerDeposit(uint256 amount) external onlyOwner {
        rewardToken.safeTransferFrom(_msgSender(), address(this), amount);
        totalSupply = totalSupply.add(amount);
    }

    function setEndTime(uint256 _time) external onlyOwner {
        require (block.timestamp < _time, "!available");
        endTime = _time;
    }

    function restartPeriod(uint256 _minutes) external onlyOwner {
        require (block.timestamp > endTime, "!expired");
        endTime = block.timestamp.add(_minutes.mul(1 minutes));
    }

    function setRewardCycle(uint256 _cycleMinutes) external onlyOwner {
        rewardCycle = _cycleMinutes.mul(1 minutes);
    }

    function withdrawPenalty(uint256 poolId) external onlyOwner {
        PoolInfo storage pools = poolInfo[poolId];
        uint sendAmount = pools.collectedPenalty;
        uint curBal = pools.stakingToken.balanceOf(address(this));
        
        if (pools.collectedPenalty > curBal) sendAmount = curBal;
        pools.stakingToken.safeTransfer(feeRecipient, sendAmount);
        pools.collectedPenalty -= sendAmount;
    }

    function setPenaltyFee(uint256 poolId, uint256 _fee) internal onlyOwner {
        require(_fee <= FEE_LIMIT, "invalid fee");
        PoolInfo storage pools = poolInfo[poolId];

        pools.penaltyFee = _fee;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function setLockUpDurations(uint256 poolId, uint256 first, uint256 second, uint256 third, uint256 fourth) public onlyOwner {
        PoolInfo storage pools = poolInfo[poolId];
        pools.lockDurations[0] = first * 1 days;
        pools.lockDurations[1] = second * 1 days;
        pools.lockDurations[2] = third * 1 days;
        pools.lockDurations[3] = fourth * 1 days;
    }

    function setLockUpBonus(uint256 poolId, uint256 first, uint256 second, uint256 third, uint256 fourth) public onlyOwner {
        PoolInfo storage pools = poolInfo[poolId];
        pools.lockBonus[0] = first;
        pools.lockBonus[1] = second;
        pools.lockBonus[2] = third;
        pools.lockBonus[3] = fourth;        
    }

    function claimable(uint256 poolId, address _user) external view returns (uint256, uint256) {
        UserInfo storage user = usersInfo[poolId][_user];
        PoolInfo storage pools = poolInfo[poolId];
        if (user.amount == 0) return (user.pendingRewards, 0);
        uint256 curAccPerShare = pools.accPerShare;
        uint256 curTotalReward = pools.totalReward;
        if (totalSupply > 0) {
            uint256 multiplier = Math.min(block.timestamp, endTime).sub(pools.lastUpdateTime);
            uint256 reward = multiplier.mul(pools.rewardRate);
            curTotalReward += reward;
            curAccPerShare = pools.accPerShare.add(reward.mul(1e12).div(totalSupply));
        }
        uint amount = user.amount;
        uint available = amount.mul(curAccPerShare).div(1e12).sub(user.rewardDebt).add(user.pendingRewards);
        uint reflectedAmount = address(this).balance;
        uint dividendAmount = 0;
        if (curTotalReward > 0) {
            dividendAmount = reflectedAmount.mul(available).div(curTotalReward);
        }

        return (available, dividendAmount);
    }

    function setCompound(uint256 poolId) public {
        require(poolInfo[poolId].active, "This is not an active pool");
        require(!Address.isContract(_msgSender()), "Message sender cannot be a contract");
        require(usersInfo[1][_msgSender()].planChosen, "You must have a lock up plan for the main pool");
        AutoCompounder storage compounding = compoundInfo[poolId];
        if (!compounding.autoCompounding.contains(_msgSender())) {
            compounding.autoCompounding.add(_msgSender());
        } else {
            compounding.autoCompounding.remove(_msgSender());      
        }
    }

    function updateCompoundRewards(uint256 poolId, address compounder) internal {
        UserInfo storage user = usersInfo[poolId][compounder];
        PoolInfo storage pools = poolInfo[poolId];

        if (totalSupply > 0) {
            uint256 multiplier = Math.min(block.timestamp, endTime).sub(pools.lastUpdateTime);
            uint256 reward = multiplier.mul(pools.rewardRate);
            pools.totalReward = pools.totalReward.add(multiplier.mul(pools.rewardRate));
            pools.accPerShare = pools.accPerShare.add(reward.mul(1e12).div(totalSupply));
        }
        pools.lastUpdateTime = Math.min(block.timestamp, endTime);
        
        uint256 pending = user.amount.mul(pools.accPerShare).div(1e12).sub(user.rewardDebt);
        user.pendingRewards = user.pendingRewards.add(pending);
    }

    function compoundGains(uint256 poolId, uint256 index) internal {
        address compounder = compoundList(poolId, index);
        UserInfo storage user = usersInfo[poolId][compounder];
        PoolInfo storage pools = poolInfo[poolId];
        updateCompoundRewards(poolId, compounder);
        uint256 compoundAmount = user.pendingRewards;
        if(poolId == 1){
            _safeTransferDividends(compoundList(1, index), compoundAmount);
        }
        usersInfo[1][compounder].amount = usersInfo[1][compounder].amount.add(compoundAmount);
        poolInfo[1].totalStaked = poolInfo[1].totalStaked.add(compoundAmount);
        totalSupply = totalSupply.sub(compoundAmount);
        emit Compounded(compounder, compoundAmount);
        user.pendingRewards = 0;
        user.claimedAt = block.timestamp;
        user.rewardDebt = user.amount.mul(pools.accPerShare).div(1e12);
    }

    function processGains(uint256 poolId, uint256 gas) internal {
        PoolInfo storage pools = poolInfo[poolId];
        if(compoundCount(poolId) == 0){return;}
        uint256 gasUsed;
        uint256 gasLeft = gasleft();
        uint256 iterations;
        uint256 count;
        while(gasUsed < gas && iterations < compoundCount(poolId)){
            if(pools.currentIndex >= compoundCount(poolId)) {
                pools.currentIndex = 0;
            }
            if(shouldAutoCompound(poolId, pools.currentIndex)) {
                compoundGains(poolId, pools.currentIndex);
                count++;
            }
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            pools.currentIndex++;
            iterations++;
        }
        emit CompoundingProcessed(iterations, count);
    }

    function depositToPool(uint256 amount, uint256 planIndex, uint256 poolId) external nonReentrant whenNotPaused updateReward(poolId) updateUserList(poolId) {
        require (block.timestamp < endTime, "expired");
        require(!Address.isContract(_msgSender()), "Message sender cannot be a contact");
        require(planIndex >= 0 && planIndex < 4, "You must choose a plan index between 0-3");
        UserInfo storage user = usersInfo[poolId][_msgSender()];            
        PoolInfo storage pools = poolInfo[poolId];
        require(pools.active, "This is not an active pool");
        if(user.withdrawn){
            user.withdrawn = false;
        }
        require(!user.withdrawn);
        pools.stakingToken.transferFrom(_msgSender(), address(this), amount);

        if(user.planChosen){
            user.amount = user.amount.add(amount);
            user.lastDeposit = block.timestamp;
            pools.totalStaked.add(amount);
        } else {
            user.planChosen = true;
            user.lockPlan = planIndex;            
            user.lockUpEnd = block.timestamp + pools.lockDurations[planIndex];
            pools.stakersInLockup[planIndex]++;
            user.amount = user.amount.add(amount);
            user.lastDeposit = block.timestamp;
            pools.totalStaked = pools.totalStaked.add(amount);
        }
        emit Deposit(_msgSender(), amount, poolId);
        if (user.claimedAt == 0) user.claimedAt = block.timestamp;
    }

    function withdrawBeforeLockUp(uint256 poolId, uint256 amount) internal returns(uint256) {
        PoolInfo storage pools = poolInfo[poolId];
        uint256 feeAmount;
        uint256 withdrawAmount;
        feeAmount = (amount * pools.penaltyFee) / MAX_FEE;
        pools.collectedPenalty += feeAmount;
        withdrawAmount = amount.sub(feeAmount);
        return(withdrawAmount);
    }

    function withdrawFromMainPool(uint256 amount) public nonReentrant withdrawing updateReward(1) updateUserList(1) {
        require(!Address.isContract(_msgSender()), "Message sender cannot be a contract");
        UserInfo storage user = usersInfo[1][_msgSender()];
        require(!user.withdrawn && user.planChosen, "User has withdrawn and must choose another lock up period");
        PoolInfo storage pools = poolInfo[1];
        if(block.timestamp < user.lockUpEnd) {
            require(amount > 0 && amount <= user.amount, "You cannot withdraw 0 tokens or withdraw more than your user amount");
            (uint256 withdrawAmount) = withdrawBeforeLockUp(1, amount);
            if(amount == user.amount){
                rewardToken.safeTransfer(_msgSender(), withdrawAmount);
                emit Withdraw(_msgSender(), withdrawAmount, 1);
                user.amount = 0;
                pools.totalStaked = pools.totalStaked.sub(amount);
                user.planChosen = false;
                user.withdrawn = true;
                pools.stakersInLockup[user.lockPlan]--;
            } else {
                rewardToken.safeTransfer(_msgSender(), withdrawAmount);
                user.amount = user.amount.sub(amount);
                pools.totalStaked = pools.totalStaked.sub(amount);        
                emit Withdraw(_msgSender(), withdrawAmount, 1);
                if(user.amount == 0){
                    user.amount = 0;
                    user.planChosen = false;
                    user.withdrawn = true;
                    pools.stakersInLockup[user.lockPlan]--;
                }
            }
        } else {
            require(amount == user.amount, "Your lock up has ended, you must withdraw all tokens");
            uint256 withdrawAmount = user.amount + ((user.amount * pools.lockBonus[user.lockPlan]) / lockBonusDivider);
            if(withdrawAmount > totalSupply.add(user.amount)){
                rewardToken.safeTransfer(_msgSender(), totalSupply.add(user.amount));
                emit Withdraw(_msgSender(), totalSupply.add(user.amount), 1);
                if(totalSupply != 0){
                    totalSupply = 0;
                }          
                pools.totalStaked = pools.totalStaked.sub(user.amount);
            } else {
                rewardToken.safeTransfer(_msgSender(), withdrawAmount);
                totalSupply = totalSupply.sub(withdrawAmount.sub(user.amount));    
                pools.totalStaked = pools.totalStaked.sub(user.amount);
                emit Withdraw(_msgSender(), withdrawAmount, 1);
            }
            pools.stakersInLockup[user.lockPlan]--;
            user.amount = 0;
            user.withdrawn = true;
            user.planChosen = false;
        }
    }

    function withdrawFromOtherPools(uint256 poolId, uint256 amount) public nonReentrant withdrawing updateReward(poolId) updateUserList(poolId) {
        require(!Address.isContract(_msgSender()), "Message sender cannot be a contract");
        require(poolId > 1, "You cannot withdraw from the main pool using this function");
        UserInfo storage user = usersInfo[poolId][_msgSender()];
        require(!user.withdrawn && user.planChosen, "User has withdrawn and must choose another lock up period");
        PoolInfo storage pools = poolInfo[poolId];  
        if(block.timestamp < user.lockUpEnd){
            require(amount > 0 && amount <= user.amount, "You cannot withdraw 0 tokens or withdraw more than your user balance");
            uint256 withdrawAmount = withdrawBeforeLockUp(poolId, amount);
            if(amount == user.amount){
                pools.stakingToken.safeTransfer(_msgSender(), withdrawAmount);
                pools.totalStaked = pools.totalStaked.sub(amount);
                emit Withdraw(_msgSender(), withdrawAmount, poolId);
                pools.stakersInLockup[user.lockPlan]--;
                user.withdrawn = true;
                user.planChosen = false;
                user.amount = 0;
            } else {
                pools.stakingToken.safeTransfer(_msgSender(), withdrawAmount);
                pools.totalStaked = pools.totalStaked.sub(amount);
                emit Withdraw(_msgSender(), withdrawAmount, poolId);
                user.amount = user.amount.sub(amount);
                if(user.amount == 0){
                    user.amount = 0;
                    user.planChosen = false;
                    user.withdrawn = true;
                    pools.stakersInLockup[user.lockPlan]--;
                }
            }
        } else {
            require(amount == user.amount, "Your lock up has ended, you must withdraw all tokens");
            pools.stakingToken.safeTransfer(_msgSender(), amount);
            pools.totalStaked = pools.totalStaked.sub(amount);
            emit Withdraw(_msgSender(), amount, poolId);
            pools.stakersInLockup[user.lockPlan]--;
            user.withdrawn = true;
            user.planChosen = false;
            user.amount = 0;
        }
    }

    function withdrawAll(uint256 poolId) external {
        UserInfo storage user = usersInfo[poolId][_msgSender()];
        if(poolId == 1)
        withdrawFromMainPool(user.amount);
        else 
        withdrawFromOtherPools(poolId, user.amount);
    }

    function withdrawPercent(uint256 poolId, uint256 percent) external {
        UserInfo storage user = usersInfo[poolId][_msgSender()];
        require(percent <= 100);
        uint256 amountToWithdraw = (user.amount * percent) / 100;
        if(poolId == 1)
        withdrawFromMainPool(amountToWithdraw);
        else 
        withdrawFromOtherPools(poolId, amountToWithdraw);
    }

    function claim(uint256 poolId) public nonReentrant updateReward(poolId) updateUserList(poolId) {
        require(!Address.isContract(_msgSender()), "Message sender cannot be a contract");
        UserInfo storage user = usersInfo[poolId][_msgSender()];
        AutoCompounder storage compounding = compoundInfo[poolId];
        require(!user.withdrawn, "You have already withdrawn from this pool");
        uint256 claimAmount = user.pendingRewards;
        if(!compounding.autoCompounding.contains(_msgSender())){
            require (block.timestamp.sub(user.claimedAt) >= rewardCycle, "Your reward cycle is not over yet");
            rewardToken.safeTransfer(_msgSender(), claimAmount);
            if(poolId == 1){
                _safeTransferDividends(_msgSender(), claimAmount);
            }
            emit Claim(_msgSender(), claimAmount);       
            totalSupply = totalSupply.sub(claimAmount);     
            user.pendingRewards = 0;
            user.claimedAt = block.timestamp;
            processGains(poolId, compoundGas);
        } else {
            require(block.timestamp.sub(user.claimedAt) >= rewardCycle, "Your reward cycle is not over yet");
            require(usersInfo[1][_msgSender()].planChosen, "You must choose a lock plan for the main pool");
            if(poolId == 1){
                _safeTransferDividends(_msgSender(), claimAmount);
            }
            user.claimedAt = block.timestamp;
            usersInfo[1][_msgSender()].amount = usersInfo[1][_msgSender()].amount.add(claimAmount);
            poolInfo[1].totalStaked = poolInfo[1].totalStaked.add(claimAmount);
            emit Compounded(_msgSender(), claimAmount);  
            totalSupply = totalSupply.sub(claimAmount);   
            user.pendingRewards = 0;
            processGains(poolId, compoundGas);
        }
    }

    function _safeTransferDividends(address _to, uint256 _rewardAmount) internal returns (uint256) {
        PoolInfo storage pools = poolInfo[1];
        uint reflectedAmount = address(this).balance;
        if (reflectedAmount == 0 || pools.totalReward == 0) return 0;
        uint dividendAmount;
        if(_rewardAmount <= pools.totalReward) {

            dividendAmount = reflectedAmount.mul(_rewardAmount).div(pools.totalReward);
            if (dividendAmount > 0) {
                payable(_to).transfer(dividendAmount);
            }
            pools.totalReward = pools.totalReward.sub(_rewardAmount);
            dividendsDistributed = dividendsDistributed.add(dividendAmount);
            usersDividends[_to] = usersDividends[_to].add(dividendAmount);
        }
        return dividendAmount;
    }

    function setRewardRate(uint256 _rewardRate, uint256 poolId) internal {
        PoolInfo storage pools = poolInfo[poolId];
        require (endTime > block.timestamp, "expired");
        require (_rewardRate > 0, "Rewards per second should be greater than 0!");

        // Update pool infos with old reward rate before setting new one first
        if (totalSupply > 0) {
            uint256 multiplier = block.timestamp.sub(pools.lastUpdateTime);
            uint256 reward = multiplier.mul(pools.rewardRate);
            pools.totalReward = pools.totalReward.add(reward);
            pools.accPerShare = pools.accPerShare.add(reward.mul(1e12).div(totalSupply));    
        }
        pools.lastUpdateTime = block.timestamp;
        pools.rewardRate = _rewardRate;
    }

    function _removeUser(address _user) internal {
        if (users.contains(_user)) {
            users.remove(_user);
        }
    }

    function _checkOrAddUser(address _user) internal {
        if (!users.contains(_user)) {
            users.add(_user);
        }
    }

    function shouldAutoCompound(uint256 poolId, uint256 index) internal view returns(bool cycleDone) {
        return block.timestamp - usersInfo[poolId][compoundList(poolId, index)].claimedAt >= rewardCycle
        && usersInfo[1][compoundList(poolId, index)].planChosen;
    }

    function isCompounder(uint256 poolId) public view returns(bool){
        AutoCompounder storage compounding = compoundInfo[poolId];
        return compounding.autoCompounding.contains(_msgSender());
    }

    function compoundCount(uint256 poolId) public view returns (uint) {
        AutoCompounder storage compounding = compoundInfo[poolId];
        return compounding.autoCompounding.length();
    }

    function compoundList(uint256 poolId, uint256 index) internal view returns (address indexedAddress) {
        AutoCompounder storage compounding = compoundInfo[poolId];
        indexedAddress = compounding.autoCompounding.at(index);
        return indexedAddress;
    }    

    function compoundingList(uint256 poolId) external view  onlyOwner returns (address[] memory Addresses) {
        AutoCompounder storage compounding = compoundInfo[poolId];
        Addresses = compounding.autoCompounding.values();
        return Addresses;
    }

    function lockUpTimes(uint256 poolId) external view returns(uint256[4] memory lockDurations, uint256[4] memory lockUpBonus) {
        PoolInfo storage pools = poolInfo[poolId];
        lockDurations = pools.lockDurations;
        lockUpBonus = pools.lockBonus;
    }    

    function stakersInPlan(uint256 poolId) external view returns(uint256[4] memory) {
        PoolInfo storage pools = poolInfo[poolId];
        return pools.stakersInLockup;
    }

    function userCount() external view returns (uint) {
        return users.length();
    }

    function userList() external view onlyOwner returns (address[] memory Addresses) {
        Addresses = users.values();
        return Addresses;
    }

    function userStakedAmount(uint256 poolId) public view returns(uint) {
        return usersInfo[poolId][_msgSender()].amount;
    }

    function currentTime() external view returns(uint time) {
        time = block.timestamp;
    }
}