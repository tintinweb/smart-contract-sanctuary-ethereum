// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev Used in SqrtPriceMath.sol
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { IPerpdexExchange } from "./interface/IPerpdexExchange.sol";
import { IPerpdexMarketMinimum } from "./interface/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./lib/PerpdexStructs.sol";
import { AccountLibrary } from "./lib/AccountLibrary.sol";
import { MakerLibrary } from "./lib/MakerLibrary.sol";
import { TakerLibrary } from "./lib/TakerLibrary.sol";
import { VaultLibrary } from "./lib/VaultLibrary.sol";
import { PerpMath } from "./lib/PerpMath.sol";

contract PerpdexExchange is IPerpdexExchange, ReentrancyGuard, Ownable {
    using Address for address;
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;

    // states
    // trader
    mapping(address => PerpdexStructs.AccountInfo) public override accountInfos;
    PerpdexStructs.InsuranceFundInfo public override insuranceFundInfo;
    PerpdexStructs.ProtocolInfo public override protocolInfo;

    // config
    address public immutable override settlementToken;
    uint8 public constant override quoteDecimals = 18;
    uint8 public override maxMarketsPerAccount = 16;
    uint24 public override imRatio = 10e4;
    uint24 public override mmRatio = 5e4;
    uint24 public override protocolFeeRatio = 0;
    PerpdexStructs.LiquidationRewardConfig public override liquidationRewardConfig =
        PerpdexStructs.LiquidationRewardConfig({ rewardRatio: 20e4, smoothEmaTime: 100 });
    mapping(address => bool) public override isMarketAllowed;

    modifier checkDeadline(uint256 deadline) {
        require(block.timestamp <= deadline, "PE_CD: too late");
        _;
    }

    modifier checkMarketAllowed(address market) {
        require(isMarketAllowed[market], "PE_CMA: market not allowed");
        _;
    }

    constructor(address settlementTokenArg) {
        require(settlementTokenArg == address(0) || settlementTokenArg.isContract(), "PE_C: token address invalid");

        settlementToken = settlementTokenArg;
    }

    function deposit(uint256 amount) external payable override nonReentrant {
        address trader = _msgSender();

        if (settlementToken == address(0)) {
            require(amount == 0, "PE_D: amount not zero");
            VaultLibrary.depositEth(accountInfos[trader], msg.value);
            emit Deposited(trader, msg.value);
        } else {
            require(msg.value == 0, "PE_D: msg.value not zero");
            VaultLibrary.deposit(
                accountInfos[trader],
                VaultLibrary.DepositParams({ settlementToken: settlementToken, amount: amount, from: trader })
            );
            emit Deposited(trader, amount);
        }
    }

    function withdraw(uint256 amount) external override nonReentrant {
        address payable trader = _msgSender();

        VaultLibrary.withdraw(
            accountInfos[trader],
            VaultLibrary.WithdrawParams({
                settlementToken: settlementToken,
                amount: amount,
                to: trader,
                imRatio: imRatio
            })
        );
        emit Withdrawn(trader, amount);
    }

    function transferInsuranceFund(uint256 amount) external override onlyOwner nonReentrant {
        address trader = _msgSender();
        VaultLibrary.transferInsuranceFund(accountInfos[trader], insuranceFundInfo, amount);
        emit InsuranceFundTransferred(trader, amount);
    }

    function transferProtocolFee(uint256 amount) external override onlyOwner nonReentrant {
        address trader = _msgSender();
        VaultLibrary.transferProtocolFee(accountInfos[trader], protocolInfo, amount);
        emit ProtocolFeeTransferred(trader, amount);
    }

    function trade(TradeParams calldata params)
        external
        override
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketAllowed(params.market)
        returns (uint256 oppositeAmount)
    {
        TakerLibrary.TradeResponse memory response = _doTrade(params);

        uint256 baseBalancePerShareX96 = IPerpdexMarketMinimum(params.market).baseBalancePerShareX96();
        uint256 shareMarkPriceAfterX96 = IPerpdexMarketMinimum(params.market).getShareMarkPriceX96();

        if (response.isLiquidation) {
            emit PositionLiquidated(
                params.trader,
                params.market,
                _msgSender(),
                response.base,
                response.quote,
                response.realizedPnl,
                response.protocolFee,
                baseBalancePerShareX96,
                shareMarkPriceAfterX96,
                response.liquidationPenalty,
                response.liquidationReward,
                response.insuranceFundReward
            );
        } else {
            emit PositionChanged(
                params.trader,
                params.market,
                response.base,
                response.quote,
                response.realizedPnl,
                response.protocolFee,
                baseBalancePerShareX96,
                shareMarkPriceAfterX96
            );
        }

        oppositeAmount = params.isExactInput == params.isBaseToQuote ? response.quote.abs() : response.base.abs();
    }

    function addLiquidity(AddLiquidityParams calldata params)
        external
        override
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketAllowed(params.market)
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        )
    {
        address trader = _msgSender();

        MakerLibrary.AddLiquidityResponse memory response =
            MakerLibrary.addLiquidity(
                accountInfos[trader],
                MakerLibrary.AddLiquidityParams({
                    market: params.market,
                    base: params.base,
                    quote: params.quote,
                    minBase: params.minBase,
                    minQuote: params.minQuote,
                    imRatio: imRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount
                })
            );

        uint256 baseBalancePerShareX96 = IPerpdexMarketMinimum(params.market).baseBalancePerShareX96();
        uint256 shareMarkPriceAfterX96 = IPerpdexMarketMinimum(params.market).getShareMarkPriceX96();

        PerpdexStructs.MakerInfo storage makerInfo = accountInfos[trader].makerInfos[params.market];
        emit LiquidityAdded(
            trader,
            params.market,
            response.base,
            response.quote,
            response.liquidity,
            makerInfo.cumBaseSharePerLiquidityX96,
            makerInfo.cumQuotePerLiquidityX96,
            baseBalancePerShareX96,
            shareMarkPriceAfterX96
        );

        return (response.base, response.quote, response.liquidity);
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        override
        nonReentrant
        checkDeadline(params.deadline)
        checkMarketAllowed(params.market)
        returns (uint256 base, uint256 quote)
    {
        MakerLibrary.RemoveLiquidityResponse memory response =
            MakerLibrary.removeLiquidity(
                accountInfos[params.trader],
                MakerLibrary.RemoveLiquidityParams({
                    market: params.market,
                    liquidity: params.liquidity,
                    minBase: params.minBase,
                    minQuote: params.minQuote,
                    isSelf: params.trader == _msgSender(),
                    mmRatio: mmRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount
                })
            );

        uint256 baseBalancePerShareX96 = IPerpdexMarketMinimum(params.market).baseBalancePerShareX96();
        uint256 shareMarkPriceAfterX96 = IPerpdexMarketMinimum(params.market).getShareMarkPriceX96();

        emit LiquidityRemoved(
            params.trader,
            params.market,
            response.isLiquidation ? _msgSender() : address(0),
            response.base,
            response.quote,
            params.liquidity,
            response.takerBase,
            response.takerQuote,
            response.realizedPnl,
            baseBalancePerShareX96,
            shareMarkPriceAfterX96
        );

        return (response.base, response.quote);
    }

    function setMaxMarketsPerAccount(uint8 value) external override onlyOwner nonReentrant {
        maxMarketsPerAccount = value;
        emit MaxMarketsPerAccountChanged(value);
    }

    function setImRatio(uint24 value) external override onlyOwner nonReentrant {
        require(value < 1e6, "PE_SIR: too large");
        require(value >= mmRatio, "PE_SIR: smaller than mmRatio");
        imRatio = value;
        emit ImRatioChanged(value);
    }

    function setMmRatio(uint24 value) external override onlyOwner nonReentrant {
        require(value <= imRatio, "PE_SMR: bigger than imRatio");
        require(value > 0, "PE_SMR: zero");
        mmRatio = value;
        emit MmRatioChanged(value);
    }

    function setLiquidationRewardConfig(PerpdexStructs.LiquidationRewardConfig calldata value)
        external
        override
        onlyOwner
        nonReentrant
    {
        require(value.rewardRatio < 1e6, "PE_SLRC: too large reward ratio");
        require(value.smoothEmaTime > 0, "PE_SLRC: ema time is zero");
        liquidationRewardConfig = value;
        emit LiquidationRewardConfigChanged(value.rewardRatio, value.smoothEmaTime);
    }

    function setProtocolFeeRatio(uint24 value) external override onlyOwner nonReentrant {
        require(value <= 1e4, "PE_SPFR: too large");
        protocolFeeRatio = value;
        emit ProtocolFeeRatioChanged(value);
    }

    function setIsMarketAllowed(address market, bool value) external override onlyOwner nonReentrant {
        require(market.isContract(), "PE_SIMA: market address invalid");
        isMarketAllowed[market] = value;
        emit IsMarketAllowedChanged(market, value);
    }

    // all raw information can be retrieved through getters (including default getters)

    function getTakerInfo(address trader, address market)
        external
        view
        override
        returns (PerpdexStructs.TakerInfo memory)
    {
        return accountInfos[trader].takerInfos[market];
    }

    function getMakerInfo(address trader, address market)
        external
        view
        override
        returns (PerpdexStructs.MakerInfo memory)
    {
        return accountInfos[trader].makerInfos[market];
    }

    function getAccountMarkets(address trader) external view override returns (address[] memory) {
        return accountInfos[trader].markets;
    }

    // dry run

    function previewTrade(PreviewTradeParams calldata params)
        external
        view
        override
        checkMarketAllowed(params.market)
        returns (uint256 oppositeAmount)
    {
        address trader = params.trader;
        address caller = params.caller;

        return
            TakerLibrary.previewTrade(
                accountInfos[trader],
                TakerLibrary.PreviewTradeParams({
                    market: params.market,
                    isBaseToQuote: params.isBaseToQuote,
                    isExactInput: params.isExactInput,
                    amount: params.amount,
                    oppositeAmountBound: params.oppositeAmountBound,
                    mmRatio: mmRatio,
                    protocolFeeRatio: protocolFeeRatio,
                    isSelf: trader == caller
                })
            );
    }

    function maxTrade(MaxTradeParams calldata params) external view override returns (uint256 amount) {
        if (!isMarketAllowed[params.market]) return 0;

        address trader = params.trader;
        address caller = params.caller;

        return
            TakerLibrary.maxTrade({
                accountInfo: accountInfos[trader],
                market: params.market,
                isBaseToQuote: params.isBaseToQuote,
                isExactInput: params.isExactInput,
                mmRatio: mmRatio,
                protocolFeeRatio: protocolFeeRatio,
                isSelf: trader == caller
            });
    }

    // convenient getters

    function getTotalAccountValue(address trader) external view override returns (int256) {
        return AccountLibrary.getTotalAccountValue(accountInfos[trader]);
    }

    function getPositionShare(address trader, address market) external view override returns (int256) {
        return AccountLibrary.getPositionShare(accountInfos[trader], market);
    }

    function getPositionNotional(address trader, address market) external view override returns (int256) {
        return AccountLibrary.getPositionNotional(accountInfos[trader], market);
    }

    function getTotalPositionNotional(address trader) external view override returns (uint256) {
        return AccountLibrary.getTotalPositionNotional(accountInfos[trader]);
    }

    function getOpenPositionShare(address trader, address market) external view override returns (uint256) {
        return AccountLibrary.getOpenPositionShare(accountInfos[trader], market);
    }

    function getOpenPositionNotional(address trader, address market) external view override returns (uint256) {
        return AccountLibrary.getOpenPositionNotional(accountInfos[trader], market);
    }

    function getTotalOpenPositionNotional(address trader) external view override returns (uint256) {
        return AccountLibrary.getTotalOpenPositionNotional(accountInfos[trader]);
    }

    function hasEnoughMaintenanceMargin(address trader) external view override returns (bool) {
        return AccountLibrary.hasEnoughMaintenanceMargin(accountInfos[trader], mmRatio);
    }

    function hasEnoughInitialMargin(address trader) external view override returns (bool) {
        return AccountLibrary.hasEnoughInitialMargin(accountInfos[trader], imRatio);
    }

    // for avoiding stack too deep error
    function _doTrade(TradeParams calldata params) private returns (TakerLibrary.TradeResponse memory) {
        return
            TakerLibrary.trade(
                accountInfos[params.trader],
                accountInfos[_msgSender()].vaultInfo,
                insuranceFundInfo,
                protocolInfo,
                TakerLibrary.TradeParams({
                    market: params.market,
                    isBaseToQuote: params.isBaseToQuote,
                    isExactInput: params.isExactInput,
                    amount: params.amount,
                    oppositeAmountBound: params.oppositeAmountBound,
                    mmRatio: mmRatio,
                    imRatio: imRatio,
                    maxMarketsPerAccount: maxMarketsPerAccount,
                    protocolFeeRatio: protocolFeeRatio,
                    liquidationRewardConfig: liquidationRewardConfig,
                    isSelf: params.trader == _msgSender()
                })
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.7.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

import { PerpdexStructs } from "../lib/PerpdexStructs.sol";

interface IPerpdexExchange {
    struct AddLiquidityParams {
        address market;
        uint256 base;
        uint256 quote;
        uint256 minBase;
        uint256 minQuote;
        uint256 deadline;
    }

    struct RemoveLiquidityParams {
        address trader;
        address market;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
        uint256 deadline;
    }

    struct TradeParams {
        address trader;
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint256 deadline;
    }

    struct PreviewTradeParams {
        address trader;
        address market;
        address caller;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
    }

    struct MaxTradeParams {
        address trader;
        address market;
        address caller;
        bool isBaseToQuote;
        bool isExactInput;
    }

    event Deposited(address indexed trader, uint256 amount);
    event Withdrawn(address indexed trader, uint256 amount);
    event InsuranceFundTransferred(address indexed trader, uint256 amount);
    event ProtocolFeeTransferred(address indexed trader, uint256 amount);

    event LiquidityAdded(
        address indexed trader,
        address indexed market,
        uint256 base,
        uint256 quote,
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96,
        uint256 baseBalancePerShareX96,
        uint256 sharePriceAfterX96
    );

    event LiquidityRemoved(
        address indexed trader,
        address indexed market,
        address liquidator,
        uint256 base,
        uint256 quote,
        uint256 liquidity,
        int256 takerBase,
        int256 takerQuote,
        int256 realizedPnl,
        uint256 baseBalancePerShareX96,
        uint256 sharePriceAfterX96
    );

    event PositionLiquidated(
        address indexed trader,
        address indexed market,
        address indexed liquidator,
        int256 base,
        int256 quote,
        int256 realizedPnl,
        uint256 protocolFee,
        uint256 baseBalancePerShareX96,
        uint256 sharePriceAfterX96,
        uint256 liquidationPenalty,
        uint256 liquidationReward,
        uint256 insuranceFundReward
    );

    event PositionChanged(
        address indexed trader,
        address indexed market,
        int256 base,
        int256 quote,
        int256 realizedPnl,
        uint256 protocolFee,
        uint256 baseBalancePerShareX96,
        uint256 sharePriceAfterX96
    );

    event MaxMarketsPerAccountChanged(uint8 value);
    event ImRatioChanged(uint24 value);
    event MmRatioChanged(uint24 value);
    event LiquidationRewardConfigChanged(uint24 rewardRatio, uint16 smoothEmaTime);
    event ProtocolFeeRatioChanged(uint24 value);
    event IsMarketAllowedChanged(address indexed market, bool isMarketAllowed);

    function deposit(uint256 amount) external payable;

    function withdraw(uint256 amount) external;

    function transferInsuranceFund(uint256 amount) external;

    function transferProtocolFee(uint256 amount) external;

    function addLiquidity(AddLiquidityParams calldata params)
        external
        returns (
            uint256 base,
            uint256 quote,
            uint256 liquidity
        );

    function removeLiquidity(RemoveLiquidityParams calldata params) external returns (uint256 base, uint256 quote);

    function trade(TradeParams calldata params) external returns (uint256 oppositeAmount);

    // setters

    function setMaxMarketsPerAccount(uint8 value) external;

    function setImRatio(uint24 value) external;

    function setMmRatio(uint24 value) external;

    function setLiquidationRewardConfig(PerpdexStructs.LiquidationRewardConfig calldata value) external;

    function setProtocolFeeRatio(uint24 value) external;

    function setIsMarketAllowed(address market, bool value) external;

    // dry run getters

    function previewTrade(PreviewTradeParams calldata params) external view returns (uint256 oppositeAmount);

    function maxTrade(MaxTradeParams calldata params) external view returns (uint256 amount);

    // default getters

    function accountInfos(address trader) external view returns (PerpdexStructs.VaultInfo memory);

    function insuranceFundInfo() external view returns (int256 balance, uint256 liquidationRewardBalance);

    function protocolInfo() external view returns (uint256 protocolFee);

    function settlementToken() external view returns (address);

    function quoteDecimals() external view returns (uint8);

    function maxMarketsPerAccount() external view returns (uint8);

    function imRatio() external view returns (uint24);

    function mmRatio() external view returns (uint24);

    function liquidationRewardConfig() external view returns (uint24 rewardRatio, uint16 smoothEmaTime);

    function protocolFeeRatio() external view returns (uint24);

    function isMarketAllowed(address market) external view returns (bool);

    // getters not covered by default getters

    function getTakerInfo(address trader, address market) external view returns (PerpdexStructs.TakerInfo memory);

    function getMakerInfo(address trader, address market) external view returns (PerpdexStructs.MakerInfo memory);

    function getAccountMarkets(address trader) external view returns (address[] memory);

    // convenient getters

    function getTotalAccountValue(address trader) external view returns (int256);

    function getPositionShare(address trader, address market) external view returns (int256);

    function getPositionNotional(address trader, address market) external view returns (int256);

    function getTotalPositionNotional(address trader) external view returns (uint256);

    function getOpenPositionShare(address trader, address market) external view returns (uint256);

    function getOpenPositionNotional(address trader, address market) external view returns (uint256);

    function getTotalOpenPositionNotional(address trader) external view returns (uint256);

    function hasEnoughMaintenanceMargin(address trader) external view returns (bool);

    function hasEnoughInitialMargin(address trader) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;
pragma abicoder v2;

interface IPerpdexMarketMinimum {
    function swap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external returns (uint256);

    function addLiquidity(uint256 baseShare, uint256 quoteBalance)
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function removeLiquidity(uint256 liquidity) external returns (uint256 baseShare, uint256 quoteBalance);

    // getters

    function previewSwap(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        bool isLiquidation
    ) external view returns (uint256);

    function maxSwap(
        bool isBaseToQuote,
        bool isExactInput,
        bool isLiquidation
    ) external view returns (uint256 amount);

    function getShareMarkPriceX96() external view returns (uint256);

    function getLiquidityValue(uint256 liquidity) external view returns (uint256 baseShare, uint256 quoteBalance);

    function getLiquidityDeleveraged(
        uint256 liquidity,
        uint256 cumBasePerLiquidityX96,
        uint256 cumQuotePerLiquidityX96
    ) external view returns (int256, int256);

    function getCumDeleveragedPerLiquidityX96() external view returns (uint256, uint256);

    function baseBalancePerShareX96() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { IPerpdexMarketMinimum } from "../interface/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";

// https://help.ftx.com/hc/en-us/articles/360024780511-Complete-Futures-Specs
library AccountLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    function updateMarkets(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        uint8 maxMarketsPerAccount
    ) internal {
        bool enabled =
            accountInfo.takerInfos[market].baseBalanceShare != 0 || accountInfo.makerInfos[market].liquidity != 0;
        address[] storage markets = accountInfo.markets;
        uint256 length = markets.length;

        for (uint256 i = 0; i < length; ++i) {
            if (markets[i] == market) {
                if (!enabled) {
                    markets[i] = markets[length - 1];
                    markets.pop();
                }
                return;
            }
        }

        if (!enabled) return;

        require(length + 1 <= maxMarketsPerAccount, "AL_UP: too many markets");
        markets.push(market);
    }

    function getTotalAccountValue(PerpdexStructs.AccountInfo storage accountInfo) internal view returns (int256) {
        address[] storage markets = accountInfo.markets;
        int256 accountValue = accountInfo.vaultInfo.collateralBalance;
        uint256 length = markets.length;
        for (uint256 i = 0; i < length; ++i) {
            address market = markets[i];

            PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[market];
            int256 baseShare = accountInfo.takerInfos[market].baseBalanceShare;
            int256 quoteBalance = accountInfo.takerInfos[market].quoteBalance;

            if (makerInfo.liquidity != 0) {
                (uint256 poolBaseShare, uint256 poolQuoteBalance) =
                    IPerpdexMarketMinimum(market).getLiquidityValue(makerInfo.liquidity);
                (int256 deleveragedBaseShare, int256 deleveragedQuoteBalance) =
                    IPerpdexMarketMinimum(market).getLiquidityDeleveraged(
                        makerInfo.liquidity,
                        makerInfo.cumBaseSharePerLiquidityX96,
                        makerInfo.cumQuotePerLiquidityX96
                    );
                baseShare = baseShare.add(poolBaseShare.toInt256()).add(deleveragedBaseShare);
                quoteBalance = quoteBalance.add(poolQuoteBalance.toInt256()).add(deleveragedQuoteBalance);
            }

            if (baseShare != 0) {
                uint256 sharePriceX96 = IPerpdexMarketMinimum(market).getShareMarkPriceX96();
                accountValue = accountValue.add(baseShare.mulDiv(sharePriceX96.toInt256(), FixedPoint96.Q96));
            }
            accountValue = accountValue.add(quoteBalance);
        }
        return accountValue;
    }

    function getPositionShare(PerpdexStructs.AccountInfo storage accountInfo, address market)
        internal
        view
        returns (int256 baseShare)
    {
        PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[market];
        baseShare = accountInfo.takerInfos[market].baseBalanceShare;
        if (makerInfo.liquidity != 0) {
            (uint256 poolBaseShare, ) = IPerpdexMarketMinimum(market).getLiquidityValue(makerInfo.liquidity);
            (int256 deleveragedBaseShare, ) =
                IPerpdexMarketMinimum(market).getLiquidityDeleveraged(
                    makerInfo.liquidity,
                    makerInfo.cumBaseSharePerLiquidityX96,
                    makerInfo.cumQuotePerLiquidityX96
                );
            baseShare = baseShare.add(poolBaseShare.toInt256()).add(deleveragedBaseShare);
        }
    }

    function getPositionNotional(PerpdexStructs.AccountInfo storage accountInfo, address market)
        internal
        view
        returns (int256)
    {
        int256 positionShare = getPositionShare(accountInfo, market);
        if (positionShare == 0) return 0;
        uint256 sharePriceX96 = IPerpdexMarketMinimum(market).getShareMarkPriceX96();
        return positionShare.mulDiv(sharePriceX96.toInt256(), FixedPoint96.Q96);
    }

    function getTotalPositionNotional(PerpdexStructs.AccountInfo storage accountInfo) internal view returns (uint256) {
        address[] storage markets = accountInfo.markets;
        uint256 totalPositionNotional;
        uint256 length = markets.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 positionNotional = getPositionNotional(accountInfo, markets[i]).abs();
            totalPositionNotional = totalPositionNotional.add(positionNotional);
        }
        return totalPositionNotional;
    }

    function getOpenPositionShare(PerpdexStructs.AccountInfo storage accountInfo, address market)
        internal
        view
        returns (uint256 result)
    {
        PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[market];
        result = getPositionShare(accountInfo, market).abs();
        if (makerInfo.liquidity != 0) {
            (uint256 poolBaseShare, ) = IPerpdexMarketMinimum(market).getLiquidityValue(makerInfo.liquidity);
            result = result.add(poolBaseShare);
        }
    }

    function getOpenPositionNotional(PerpdexStructs.AccountInfo storage accountInfo, address market)
        internal
        view
        returns (uint256)
    {
        uint256 positionShare = getOpenPositionShare(accountInfo, market);
        if (positionShare == 0) return 0;
        uint256 sharePriceX96 = IPerpdexMarketMinimum(market).getShareMarkPriceX96();
        return FullMath.mulDiv(positionShare, sharePriceX96, FixedPoint96.Q96);
    }

    function getTotalOpenPositionNotional(PerpdexStructs.AccountInfo storage accountInfo)
        internal
        view
        returns (uint256)
    {
        address[] storage markets = accountInfo.markets;
        uint256 totalOpenPositionNotional;
        uint256 length = markets.length;
        for (uint256 i = 0; i < length; ++i) {
            uint256 positionNotional = getOpenPositionNotional(accountInfo, markets[i]);
            totalOpenPositionNotional = totalOpenPositionNotional.add(positionNotional);
        }
        return totalOpenPositionNotional;
    }

    // always true when hasEnoughMaintenanceMargin is true
    function hasEnoughMaintenanceMargin(PerpdexStructs.AccountInfo storage accountInfo, uint24 mmRatio)
        internal
        view
        returns (bool)
    {
        int256 accountValue = getTotalAccountValue(accountInfo);
        uint256 totalPositionNotional = getTotalPositionNotional(accountInfo);
        return accountValue >= totalPositionNotional.mulRatio(mmRatio).toInt256();
    }

    function hasEnoughInitialMargin(PerpdexStructs.AccountInfo storage accountInfo, uint24 imRatio)
        internal
        view
        returns (bool)
    {
        int256 accountValue = getTotalAccountValue(accountInfo);
        uint256 totalOpenPositionNotional = getTotalOpenPositionNotional(accountInfo);
        return
            accountValue.min(accountInfo.vaultInfo.collateralBalance) >=
            totalOpenPositionNotional.mulRatio(imRatio).toInt256() ||
            isLiquidationFree(accountInfo);
    }

    function isLiquidationFree(PerpdexStructs.AccountInfo storage accountInfo) internal view returns (bool) {
        address[] storage markets = accountInfo.markets;
        int256 quoteBalance = accountInfo.vaultInfo.collateralBalance;
        uint256 length = markets.length;
        for (uint256 i = 0; i < length; ++i) {
            address market = markets[i];

            PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[market];
            int256 baseShare = accountInfo.takerInfos[market].baseBalanceShare;
            quoteBalance = quoteBalance.add(accountInfo.takerInfos[market].quoteBalance);

            if (makerInfo.liquidity != 0) {
                (int256 deleveragedBaseShare, int256 deleveragedQuoteBalance) =
                    IPerpdexMarketMinimum(market).getLiquidityDeleveraged(
                        makerInfo.liquidity,
                        makerInfo.cumBaseSharePerLiquidityX96,
                        makerInfo.cumQuotePerLiquidityX96
                    );
                baseShare = baseShare.add(deleveragedBaseShare);
                quoteBalance = quoteBalance.add(deleveragedQuoteBalance);
            }

            if (baseShare < 0) return false;
        }
        return quoteBalance >= 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import { PerpMath } from "./PerpMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { IPerpdexMarketMinimum } from "../interface/IPerpdexMarketMinimum.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { TakerLibrary } from "./TakerLibrary.sol";

library MakerLibrary {
    using PerpMath for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct AddLiquidityParams {
        address market;
        uint256 base;
        uint256 quote;
        uint256 minBase;
        uint256 minQuote;
        uint24 imRatio;
        uint8 maxMarketsPerAccount;
    }

    struct AddLiquidityResponse {
        uint256 base;
        uint256 quote;
        uint256 liquidity;
    }

    struct RemoveLiquidityParams {
        address market;
        uint256 liquidity;
        uint256 minBase;
        uint256 minQuote;
        uint24 mmRatio;
        uint8 maxMarketsPerAccount;
        bool isSelf;
    }

    struct RemoveLiquidityResponse {
        uint256 base;
        uint256 quote;
        int256 takerBase;
        int256 takerQuote;
        int256 realizedPnl;
        bool isLiquidation;
    }

    function addLiquidity(PerpdexStructs.AccountInfo storage accountInfo, AddLiquidityParams memory params)
        internal
        returns (AddLiquidityResponse memory response)
    {
        PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];

        // retrieve before addLiquidity
        (uint256 cumBasePerLiquidityX96, uint256 cumQuotePerLiquidityX96) =
            IPerpdexMarketMinimum(params.market).getCumDeleveragedPerLiquidityX96();

        (response.base, response.quote, response.liquidity) = IPerpdexMarketMinimum(params.market).addLiquidity(
            params.base,
            params.quote
        );

        require(response.base >= params.minBase, "ML_AL: too small output base");
        require(response.quote >= params.minQuote, "ML_AL: too small output quote");

        uint256 liquidityBefore = makerInfo.liquidity;
        makerInfo.liquidity = liquidityBefore.add(response.liquidity);
        {
            makerInfo.cumBaseSharePerLiquidityX96 = blendCumPerLiquidity(
                liquidityBefore,
                response.liquidity,
                response.base,
                makerInfo.cumBaseSharePerLiquidityX96,
                cumBasePerLiquidityX96
            );
            makerInfo.cumQuotePerLiquidityX96 = blendCumPerLiquidity(
                liquidityBefore,
                response.liquidity,
                response.quote,
                makerInfo.cumQuotePerLiquidityX96,
                cumQuotePerLiquidityX96
            );
        }

        AccountLibrary.updateMarkets(accountInfo, params.market, params.maxMarketsPerAccount);

        require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "ML_AL: not enough im");
    }

    // difficult to calculate without error
    // underestimate the value to maintain the liquidation free condition
    // the error will be a burden to the insurance fund
    // the error is much smaller than the gas fee, so it is impossible to attack
    function blendCumPerLiquidity(
        uint256 liquidityBefore,
        uint256 addedLiquidity,
        uint256 addedToken,
        uint256 cumBefore,
        uint256 cumAfter
    ) internal pure returns (uint256) {
        uint256 liquidityAfter = liquidityBefore.add(addedLiquidity);
        cumAfter = cumAfter.add(FullMath.mulDiv(addedToken, FixedPoint96.Q96, addedLiquidity));

        return
            FullMath.mulDiv(cumBefore, liquidityBefore, liquidityAfter).add(
                FullMath.mulDiv(cumAfter, addedLiquidity, liquidityAfter)
            );
    }

    function removeLiquidity(PerpdexStructs.AccountInfo storage accountInfo, RemoveLiquidityParams memory params)
        internal
        returns (RemoveLiquidityResponse memory response)
    {
        response.isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, params.mmRatio);

        if (!params.isSelf) {
            require(response.isLiquidation, "ML_RL: enough mm");
        }

        uint256 shareMarkPriceBeforeX96;
        {
            PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];
            // retrieve before removeLiquidity
            (response.takerBase, response.takerQuote) = IPerpdexMarketMinimum(params.market).getLiquidityDeleveraged(
                params.liquidity,
                makerInfo.cumBaseSharePerLiquidityX96,
                makerInfo.cumQuotePerLiquidityX96
            );

            shareMarkPriceBeforeX96 = IPerpdexMarketMinimum(params.market).getShareMarkPriceX96();
        }

        {
            (response.base, response.quote) = IPerpdexMarketMinimum(params.market).removeLiquidity(params.liquidity);

            require(response.base >= params.minBase, "ML_RL: too small output base");
            require(response.quote >= params.minQuote, "ML_RL: too small output base");

            response.takerBase = response.takerBase.add(response.base.toInt256());
            response.takerQuote = response.takerQuote.add(response.quote.toInt256());

            PerpdexStructs.MakerInfo storage makerInfo = accountInfo.makerInfos[params.market];
            makerInfo.liquidity = makerInfo.liquidity.sub(params.liquidity);
        }

        {
            int256 takerQuoteCalculatedAtCurrentPrice =
                -response.takerBase.mulDiv(shareMarkPriceBeforeX96.toInt256(), FixedPoint96.Q96);

            // AccountLibrary.updateMarkets called
            response.realizedPnl = TakerLibrary.addToTakerBalance(
                accountInfo,
                params.market,
                response.takerBase,
                takerQuoteCalculatedAtCurrentPrice,
                response.takerQuote.sub(takerQuoteCalculatedAtCurrentPrice),
                params.maxMarketsPerAccount
            );
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";

library PerpMath {
    using SafeCast for int256;
    using SignedSafeMath for int256;
    using SafeMath for uint256;

    function formatSqrtPriceX96ToPriceX96(uint160 sqrtPriceX96) internal pure returns (uint256) {
        return FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, FixedPoint96.Q96);
    }

    function formatX10_18ToX96(uint256 valueX10_18) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX10_18, FixedPoint96.Q96, 1 ether);
    }

    function formatX96ToX10_18(uint256 valueX96) internal pure returns (uint256) {
        return FullMath.mulDiv(valueX96, 1 ether, FixedPoint96.Q96);
    }

    function max(int256 a, int256 b) internal pure returns (int256) {
        return a >= b ? a : b;
    }

    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    function abs(int256 value) internal pure returns (uint256) {
        return value >= 0 ? value.toUint256() : neg256(value).toUint256();
    }

    function neg256(int256 a) internal pure returns (int256) {
        require(a > -2**255, "PerpMath: inversion overflow");
        return -a;
    }

    function neg256(uint256 a) internal pure returns (int256) {
        return -SafeCast.toInt256(a);
    }

    function divBy10_18(int256 value) internal pure returns (int256) {
        // no overflow here
        return value / (1 ether);
    }

    function divBy10_18(uint256 value) internal pure returns (uint256) {
        // no overflow here
        return value / (1 ether);
    }

    function subRatio(uint24 a, uint24 b) internal pure returns (uint24) {
        require(b <= a, "PerpMath: subtraction overflow");
        return a - b;
    }

    function mulRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, ratio, 1e6);
    }

    function divRatio(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDiv(value, 1e6, ratio);
    }

    function divRatioRoundingUp(uint256 value, uint24 ratio) internal pure returns (uint256) {
        return FullMath.mulDivRoundingUp(value, 1e6, ratio);
    }

    /// @param denominator cannot be 0 and is checked in FullMath.mulDiv()
    function mulDiv(
        int256 a,
        int256 b,
        uint256 denominator
    ) internal pure returns (int256 result) {
        uint256 unsignedA = a < 0 ? uint256(neg256(a)) : uint256(a);
        uint256 unsignedB = b < 0 ? uint256(neg256(b)) : uint256(b);
        bool negative = ((a < 0 && b > 0) || (a > 0 && b < 0)) ? true : false;

        uint256 unsignedResult = FullMath.mulDiv(unsignedA, unsignedB, denominator);

        result = negative ? neg256(unsignedResult) : SafeCast.toInt256(unsignedResult);

        return result;
    }

    function sign(int256 value) internal pure returns (int256) {
        return value > 0 ? 1 : (value < 0 ? -1 : int256(0));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.7.6;

library PerpdexStructs {
    struct TakerInfo {
        int256 baseBalanceShare;
        int256 quoteBalance;
    }

    struct MakerInfo {
        uint256 liquidity;
        uint256 cumBaseSharePerLiquidityX96;
        uint256 cumQuotePerLiquidityX96;
    }

    struct VaultInfo {
        int256 collateralBalance;
    }

    struct AccountInfo {
        // market
        mapping(address => TakerInfo) takerInfos;
        // market
        mapping(address => MakerInfo) makerInfos;
        VaultInfo vaultInfo;
        address[] markets;
    }

    struct InsuranceFundInfo {
        int256 balance;
        uint256 liquidationRewardBalance;
    }

    struct ProtocolInfo {
        uint256 protocolFee;
    }

    struct LiquidationRewardConfig {
        uint24 rewardRatio;
        uint16 smoothEmaTime;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import { FixedPoint96 } from "@uniswap/v3-core/contracts/libraries/FixedPoint96.sol";
import { IPerpdexMarketMinimum } from "../interface/IPerpdexMarketMinimum.sol";
import { PerpMath } from "./PerpMath.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";
import { AccountLibrary } from "./AccountLibrary.sol";

library TakerLibrary {
    using PerpMath for int256;
    using PerpMath for uint256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct TradeParams {
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint24 mmRatio;
        uint24 imRatio;
        uint8 maxMarketsPerAccount;
        uint24 protocolFeeRatio;
        bool isSelf;
        PerpdexStructs.LiquidationRewardConfig liquidationRewardConfig;
    }

    struct PreviewTradeParams {
        address market;
        bool isBaseToQuote;
        bool isExactInput;
        uint256 amount;
        uint256 oppositeAmountBound;
        uint24 mmRatio;
        uint24 protocolFeeRatio;
        bool isSelf;
    }

    struct TradeResponse {
        int256 base;
        int256 quote;
        int256 realizedPnl;
        uint256 protocolFee;
        uint256 liquidationPenalty;
        uint256 liquidationReward;
        uint256 insuranceFundReward;
        bool isLiquidation;
    }

    function trade(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.VaultInfo storage liquidatorVaultInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        TradeParams memory params
    ) internal returns (TradeResponse memory response) {
        response.isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, params.mmRatio);

        if (!params.isSelf) {
            require(response.isLiquidation, "TL_OP: enough mm");
        }

        int256 takerBaseBefore = accountInfo.takerInfos[params.market].baseBalanceShare;

        (response.base, response.quote, response.realizedPnl, response.protocolFee) = _doSwap(
            accountInfo,
            protocolInfo,
            params.market,
            params.isBaseToQuote,
            params.isExactInput,
            params.amount,
            params.oppositeAmountBound,
            params.maxMarketsPerAccount,
            params.protocolFeeRatio,
            response.isLiquidation
        );

        bool isOpen = (takerBaseBefore.add(response.base)).sign() * response.base.sign() > 0;

        if (response.isLiquidation) {
            require(!isOpen, "TL_OP: no open when liquidation");

            (
                response.liquidationPenalty,
                response.liquidationReward,
                response.insuranceFundReward
            ) = processLiquidationReward(
                accountInfo.vaultInfo,
                liquidatorVaultInfo,
                insuranceFundInfo,
                params.mmRatio,
                params.liquidationRewardConfig,
                response.quote.abs()
            );
        }

        if (isOpen) {
            require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "TL_OP: not enough im");
        }
    }

    function addToTakerBalance(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        int256 baseShare,
        int256 quoteBalance,
        int256 quoteFee,
        uint8 maxMarketsPerAccount
    ) internal returns (int256 realizedPnl) {
        PerpdexStructs.TakerInfo storage takerInfo = accountInfo.takerInfos[market];

        if (baseShare != 0 || quoteBalance != 0) {
            require(baseShare.sign() * quoteBalance.sign() == -1, "TL_ATTB: invalid input");

            if (takerInfo.baseBalanceShare.sign() * baseShare.sign() == -1) {
                uint256 baseAbs = baseShare.abs();
                uint256 takerBaseAbs = takerInfo.baseBalanceShare.abs();

                if (baseAbs <= takerBaseAbs) {
                    int256 reducedOpenNotional = takerInfo.quoteBalance.mulDiv(baseAbs.toInt256(), takerBaseAbs);
                    realizedPnl = quoteBalance.add(reducedOpenNotional);
                } else {
                    int256 closedPositionNotional = quoteBalance.mulDiv(takerBaseAbs.toInt256(), baseAbs);
                    realizedPnl = takerInfo.quoteBalance.add(closedPositionNotional);
                }
            }
        }
        realizedPnl = realizedPnl.add(quoteFee);

        int256 newBaseBalanceShare = takerInfo.baseBalanceShare.add(baseShare);
        int256 newQuoteBalance = takerInfo.quoteBalance.add(quoteBalance).add(quoteFee).sub(realizedPnl);
        require(
            (newBaseBalanceShare == 0 && newQuoteBalance == 0) ||
                newBaseBalanceShare.sign() * newQuoteBalance.sign() == -1,
            "TL_ATTB: never occur"
        );

        takerInfo.baseBalanceShare = newBaseBalanceShare;
        takerInfo.quoteBalance = newQuoteBalance;
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(realizedPnl);

        AccountLibrary.updateMarkets(accountInfo, market, maxMarketsPerAccount);
    }

    // Even if trade reverts, it may not revert.
    // Attempting to match reverts makes the implementation too complicated
    // ignore initial margin check and close only check when liquidation
    function previewTrade(PerpdexStructs.AccountInfo storage accountInfo, PreviewTradeParams memory params)
        internal
        view
        returns (uint256 oppositeAmount)
    {
        bool isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, params.mmRatio);

        if (!params.isSelf) {
            require(isLiquidation, "TL_OPD: enough mm");
        }

        oppositeAmount;
        if (params.protocolFeeRatio == 0) {
            oppositeAmount = IPerpdexMarketMinimum(params.market).previewSwap(
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                isLiquidation
            );
        } else {
            (oppositeAmount, ) = previewSwapWithProtocolFee(
                params.market,
                params.isBaseToQuote,
                params.isExactInput,
                params.amount,
                params.protocolFeeRatio,
                isLiquidation
            );
        }
        validateSlippage(params.isExactInput, oppositeAmount, params.oppositeAmountBound);
    }

    // ignore initial margin check and close only check when liquidation
    function maxTrade(
        PerpdexStructs.AccountInfo storage accountInfo,
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 mmRatio,
        uint24 protocolFeeRatio,
        bool isSelf
    ) internal view returns (uint256 amount) {
        bool isLiquidation = !AccountLibrary.hasEnoughMaintenanceMargin(accountInfo, mmRatio);

        if (!isSelf && !isLiquidation) {
            return 0;
        }

        if (protocolFeeRatio == 0) {
            amount = IPerpdexMarketMinimum(market).maxSwap(isBaseToQuote, isExactInput, isLiquidation);
        } else {
            amount = maxSwapWithProtocolFee(market, isBaseToQuote, isExactInput, protocolFeeRatio, isLiquidation);
        }
    }

    function _doSwap(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint256 oppositeAmountBound,
        uint8 maxMarketsPerAccount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    )
        private
        returns (
            int256 base,
            int256 quote,
            int256 realizedPnl,
            uint256 protocolFee
        )
    {
        uint256 oppositeAmount;

        if (protocolFeeRatio > 0) {
            (oppositeAmount, protocolFee) = swapWithProtocolFee(
                protocolInfo,
                market,
                isBaseToQuote,
                isExactInput,
                amount,
                protocolFeeRatio,
                isLiquidation
            );
        } else {
            oppositeAmount = IPerpdexMarketMinimum(market).swap(isBaseToQuote, isExactInput, amount, isLiquidation);
        }
        validateSlippage(isExactInput, oppositeAmount, oppositeAmountBound);

        (base, quote) = swapResponseToBaseQuote(isBaseToQuote, isExactInput, amount, oppositeAmount);
        realizedPnl = addToTakerBalance(accountInfo, market, base, quote, 0, maxMarketsPerAccount);
    }

    function swapWithProtocolFee(
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) internal returns (uint256 oppositeAmount, uint256 protocolFee) {
        if (isExactInput) {
            if (isBaseToQuote) {
                oppositeAmount = IPerpdexMarketMinimum(market).swap(isBaseToQuote, isExactInput, amount, isLiquidation);
                protocolFee = oppositeAmount.mulRatio(protocolFeeRatio);
                oppositeAmount = oppositeAmount.sub(protocolFee);
            } else {
                protocolFee = amount.mulRatio(protocolFeeRatio);
                oppositeAmount = IPerpdexMarketMinimum(market).swap(
                    isBaseToQuote,
                    isExactInput,
                    amount.sub(protocolFee),
                    isLiquidation
                );
            }
        } else {
            if (isBaseToQuote) {
                protocolFee = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio)).sub(amount);
                oppositeAmount = IPerpdexMarketMinimum(market).swap(
                    isBaseToQuote,
                    isExactInput,
                    amount.add(protocolFee),
                    isLiquidation
                );
            } else {
                uint256 oppositeAmountWithoutFee =
                    IPerpdexMarketMinimum(market).swap(isBaseToQuote, isExactInput, amount, isLiquidation);
                oppositeAmount = oppositeAmountWithoutFee.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
                protocolFee = oppositeAmount.sub(oppositeAmountWithoutFee);
            }
        }

        protocolInfo.protocolFee = protocolInfo.protocolFee.add(protocolFee);
    }

    function processLiquidationReward(
        PerpdexStructs.VaultInfo storage vaultInfo,
        PerpdexStructs.VaultInfo storage liquidatorVaultInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo,
        uint24 mmRatio,
        PerpdexStructs.LiquidationRewardConfig memory liquidationRewardConfig,
        uint256 exchangedQuote
    )
        internal
        returns (
            uint256 penalty,
            uint256 liquidationReward,
            uint256 insuranceFundReward
        )
    {
        penalty = exchangedQuote.mulRatio(mmRatio);
        liquidationReward = penalty.mulRatio(liquidationRewardConfig.rewardRatio);
        insuranceFundReward = penalty.sub(liquidationReward);

        (insuranceFundInfo.liquidationRewardBalance, liquidationReward) = _smoothLiquidationReward(
            insuranceFundInfo.liquidationRewardBalance,
            liquidationReward,
            liquidationRewardConfig.smoothEmaTime
        );

        vaultInfo.collateralBalance = vaultInfo.collateralBalance.sub(penalty.toInt256());
        liquidatorVaultInfo.collateralBalance = liquidatorVaultInfo.collateralBalance.add(liquidationReward.toInt256());
        insuranceFundInfo.balance = insuranceFundInfo.balance.add(insuranceFundReward.toInt256());
    }

    function _smoothLiquidationReward(
        uint256 rewardBalance,
        uint256 reward,
        uint24 emaTime
    ) private pure returns (uint256 outputRewardBalance, uint256 outputReward) {
        rewardBalance = rewardBalance.add(reward);
        outputReward = rewardBalance.div(emaTime);
        outputRewardBalance = rewardBalance.sub(outputReward);
    }

    function previewSwapWithProtocolFee(
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) internal view returns (uint256 oppositeAmount, uint256 protocolFee) {
        if (isExactInput) {
            if (isBaseToQuote) {
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount,
                    isLiquidation
                );
                protocolFee = oppositeAmount.mulRatio(protocolFeeRatio);
                oppositeAmount = oppositeAmount.sub(protocolFee);
            } else {
                protocolFee = amount.mulRatio(protocolFeeRatio);
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount.sub(protocolFee),
                    isLiquidation
                );
            }
        } else {
            if (isBaseToQuote) {
                protocolFee = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio)).sub(amount);
                oppositeAmount = IPerpdexMarketMinimum(market).previewSwap(
                    isBaseToQuote,
                    isExactInput,
                    amount.add(protocolFee),
                    isLiquidation
                );
            } else {
                uint256 oppositeAmountWithoutFee =
                    IPerpdexMarketMinimum(market).previewSwap(isBaseToQuote, isExactInput, amount, isLiquidation);
                oppositeAmount = oppositeAmountWithoutFee.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
                protocolFee = oppositeAmount.sub(oppositeAmountWithoutFee);
            }
        }
    }

    function maxSwapWithProtocolFee(
        address market,
        bool isBaseToQuote,
        bool isExactInput,
        uint24 protocolFeeRatio,
        bool isLiquidation
    ) internal view returns (uint256 amount) {
        amount = IPerpdexMarketMinimum(market).maxSwap(isBaseToQuote, isExactInput, isLiquidation);

        if (isExactInput) {
            if (isBaseToQuote) {} else {
                amount = amount.divRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
            }
        } else {
            if (isBaseToQuote) {
                amount = amount.mulRatio(PerpMath.subRatio(1e6, protocolFeeRatio));
            } else {}
        }
    }

    function validateSlippage(
        bool isExactInput,
        uint256 oppositeAmount,
        uint256 oppositeAmountBound
    ) internal pure {
        if (isExactInput) {
            require(oppositeAmount >= oppositeAmountBound, "TL_VS: too small opposite amount");
        } else {
            require(oppositeAmount <= oppositeAmountBound, "TL_VS: too large opposite amount");
        }
    }

    function swapResponseToBaseQuote(
        bool isBaseToQuote,
        bool isExactInput,
        uint256 amount,
        uint256 oppositeAmount
    ) internal pure returns (int256, int256) {
        if (isExactInput) {
            if (isBaseToQuote) {
                return (amount.neg256(), oppositeAmount.toInt256());
            } else {
                return (oppositeAmount.toInt256(), amount.neg256());
            }
        } else {
            if (isBaseToQuote) {
                return (oppositeAmount.neg256(), amount.toInt256());
            } else {
                return (amount.toInt256(), oppositeAmount.neg256());
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/SafeCast.sol";
import { PerpMath } from "./PerpMath.sol";
import { IERC20Metadata } from "../interface/IERC20Metadata.sol";
import { AccountLibrary } from "./AccountLibrary.sol";
import { PerpdexStructs } from "./PerpdexStructs.sol";

library VaultLibrary {
    using PerpMath for int256;
    using SafeCast for uint256;
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    struct DepositParams {
        address settlementToken;
        uint256 amount;
        address from;
    }

    struct WithdrawParams {
        address settlementToken;
        uint256 amount;
        address payable to;
        uint24 imRatio;
    }

    function deposit(PerpdexStructs.AccountInfo storage accountInfo, DepositParams memory params) internal {
        require(params.amount > 0, "VL_D: zero amount");
        _transferTokenIn(params.settlementToken, params.from, params.amount);
        uint256 collateralAmount =
            _toCollateralAmount(params.amount, IERC20Metadata(params.settlementToken).decimals());
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(
            collateralAmount.toInt256()
        );
    }

    function depositEth(PerpdexStructs.AccountInfo storage accountInfo, uint256 amount) internal {
        require(amount > 0, "VL_DE: zero amount");
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(amount.toInt256());
    }

    function withdraw(PerpdexStructs.AccountInfo storage accountInfo, WithdrawParams memory params) internal {
        require(params.amount > 0, "VL_W: zero amount");

        uint256 collateralAmount =
            params.settlementToken == address(0)
                ? params.amount
                : _toCollateralAmount(params.amount, IERC20Metadata(params.settlementToken).decimals());
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.sub(
            collateralAmount.toInt256()
        );

        require(AccountLibrary.hasEnoughInitialMargin(accountInfo, params.imRatio), "VL_W: not enough initial margin");

        if (params.settlementToken == address(0)) {
            params.to.transfer(params.amount);
        } else {
            SafeERC20.safeTransfer(IERC20(params.settlementToken), params.to, params.amount);
        }
    }

    function transferInsuranceFund(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.InsuranceFundInfo storage insuranceFundInfo,
        uint256 amount
    ) internal {
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(amount.toInt256());
        insuranceFundInfo.balance = insuranceFundInfo.balance.sub(amount.toInt256());
        require(insuranceFundInfo.balance >= 0, "VL_TIF: negative balance");
    }

    function transferProtocolFee(
        PerpdexStructs.AccountInfo storage accountInfo,
        PerpdexStructs.ProtocolInfo storage protocolInfo,
        uint256 amount
    ) internal {
        accountInfo.vaultInfo.collateralBalance = accountInfo.vaultInfo.collateralBalance.add(amount.toInt256());
        protocolInfo.protocolFee = protocolInfo.protocolFee.sub(amount);
    }

    function _transferTokenIn(
        address token,
        address from,
        uint256 amount
    ) private {
        // check for deflationary tokens by assuring balances before and after transferring to be the same
        uint256 balanceBefore = IERC20Metadata(token).balanceOf(address(this));
        SafeERC20.safeTransferFrom(IERC20(token), from, address(this), amount);
        require(
            (IERC20Metadata(token).balanceOf(address(this)).sub(balanceBefore)) == amount,
            "VL_TTI: inconsistent balance"
        );
    }

    function _toCollateralAmount(uint256 amount, uint8 tokenDecimals) private view returns (uint256) {
        int256 decimalsDiff = 18 - tokenDecimals;
        uint256 decimalsDiffAbs = decimalsDiff.abs();
        require(decimalsDiffAbs <= 77, "VL_TCA: too large decimals diff");
        return decimalsDiff >= 0 ? amount.mul(10**decimalsDiffAbs) : amount.div(10**decimalsDiffAbs);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

import { PerpdexExchange } from "../PerpdexExchange.sol";

contract DebugPerpdexExchange is PerpdexExchange {
    uint private constant _RINKEBY_CHAIN_ID = 4;
    uint private constant _SHIBUYA_CHAIN_ID = 81;

    constructor(address settlementTokenArg) PerpdexExchange(settlementTokenArg) {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        require(chainId == _RINKEBY_CHAIN_ID || chainId == _SHIBUYA_CHAIN_ID, 'DPE_C: testnet only');
    }

    function setCollateralBalance(address trader, int balance) external {
        accountInfos[trader].vaultInfo.collateralBalance = balance;
    }
}