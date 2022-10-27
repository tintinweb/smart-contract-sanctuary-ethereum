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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/*
    Copyright 2022 Index Cooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { IUniswapV2Router02 } from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";

import { ICurveCalculator } from "../interfaces/external/ICurveCalculator.sol";
import { ICurveAddressProvider } from "../interfaces/external/ICurveAddressProvider.sol";
import { ICurvePoolRegistry } from "../interfaces/external/ICurvePoolRegistry.sol";
import { ICurvePool } from "../interfaces/external/ICurvePool.sol";
import { ISwapRouter} from "../interfaces/external/ISwapRouter.sol";
import { IQuoter } from "../interfaces/IQuoter.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";


/**
 * @title DEXAdapter
 * @author Index Coop
 *
 * Adapter to execute swaps on different DEXes
 */
library DEXAdapter {
    using SafeERC20 for IERC20;
    using PreciseUnitMath for uint256;
    using SafeMath for uint256;

    /* ============ Constants ============= */

    uint256 constant private MAX_UINT256 = type(uint256).max;
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 public constant ROUNDING_ERROR_MARGIN = 2;

    /* ============ Enums ============ */

    enum Exchange { None, Quickswap, Sushiswap, UniV3, Curve }

    /* ============ Structs ============ */

    struct Addresses {
        address quickRouter;
        address sushiRouter;
        address uniV3Router;
        address uniV3Quoter;
        address curveAddressProvider;
        address curveCalculator;
        // Wrapped native token (WMATIC on polygon)
        address weth;
    }

    struct SwapData {
        address[] path;
        uint24[] fees;
        address pool;
        Exchange exchange;
    }

    struct CurvePoolData {
        int128 nCoins;
        uint256[8] balances;
        uint256 A;
        uint256 fee;
        uint256[8] rates;
        uint256[8] decimals;
    }

    /**
     * Swap exact tokens for another token on a given DEX.
     *
     * @param _addresses    Struct containing relevant smart contract addresses.
     * @param _amountIn     The amount of input token to be spent
     * @param _minAmountOut Minimum amount of output token to receive
     * @param _swapData     Swap data containing the path and fee levels (latter only used for uniV3)
     *
     * @return amountOut    The amount of output tokens
     */
    function swapExactTokensForTokens(
        Addresses memory _addresses,
        uint256 _amountIn,
        uint256 _minAmountOut,
        SwapData memory _swapData
    )
        external
        returns (uint256)
    {
        if (_swapData.path[0] == _swapData.path[_swapData.path.length -1]) {
            return _amountIn;
        }

        if(_swapData.exchange == Exchange.Curve){
            return _swapExactTokensForTokensCurve(
                _swapData.path,
                _swapData.pool,
                _amountIn,
                _minAmountOut,
                _addresses
            );
        }
        if(_swapData.exchange== Exchange.UniV3){
            return _swapExactTokensForTokensUniV3(
                _swapData.path,
                _swapData.fees,
                _amountIn,
                _minAmountOut,
                ISwapRouter(_addresses.uniV3Router)
            );
        } else {
            return _swapExactTokensForTokensUniV2(
                _swapData.path,
                _amountIn,
                _minAmountOut,
                _getRouter(_swapData.exchange, _addresses)
            );
        }
    }


    /**
     * Swap tokens for exact amount of output tokens on a given DEX.
     *
     * @param _addresses    Struct containing relevant smart contract addresses.
     * @param _amountOut    The amount of output token required
     * @param _maxAmountIn  Maximum amount of input token to be spent
     * @param _swapData     Swap data containing the path and fee levels (latter only used for uniV3)
     *
     * @return amountIn     The amount of input tokens spent
     */
    function swapTokensForExactTokens(
        Addresses memory _addresses,
        uint256 _amountOut,
        uint256 _maxAmountIn,
        SwapData memory _swapData
    )
        external
        returns (uint256 amountIn)
    {
        if (_swapData.path[0] == _swapData.path[_swapData.path.length -1]) {
            return _amountOut;
        }

        if(_swapData.exchange == Exchange.Curve){
            return _swapTokensForExactTokensCurve(
                _swapData.path,
                _swapData.pool,
                _amountOut,
                _maxAmountIn,
                _addresses
            );
        }
        if(_swapData.exchange == Exchange.UniV3){
            return _swapTokensForExactTokensUniV3(
                _swapData.path,
                _swapData.fees,
                _amountOut,
                _maxAmountIn,
                ISwapRouter(_addresses.uniV3Router)
            );
        } else {
            return _swapTokensForExactTokensUniV2(
                _swapData.path,
                _amountOut,
                _maxAmountIn,
                _getRouter(_swapData.exchange, _addresses)
            );
        }
    }

    /**
     * Gets the output amount of a token swap.
     *
     * @param _swapData     the swap parameters
     * @param _addresses    Struct containing relevant smart contract addresses.
     * @param _amountIn     the input amount of the trade
     *
     * @return              the output amount of the swap
     */
    function getAmountOut(
        Addresses memory _addresses,
        SwapData memory _swapData,
        uint256 _amountIn
    )
        external
        returns (uint256)
    {
        if (_swapData.path.length == 0 || _swapData.path[0] == _swapData.path[_swapData.path.length-1]) {
            return _amountIn;
        }

        if (_swapData.exchange == Exchange.UniV3) {
            return _getAmountOutUniV3(_swapData, _addresses.uniV3Quoter, _amountIn);
        } else if (_swapData.exchange == Exchange.Curve) {
            (int128 i, int128 j) = _getCoinIndices(
                _swapData.pool,
                _swapData.path[0],
                _swapData.path[1],
                ICurveAddressProvider(_addresses.curveAddressProvider)
            );
            return _getAmountOutCurve(_swapData.pool, i, j, _amountIn, _addresses);
        } else {
            return _getAmountOutUniV2(
                _swapData,
                _getRouter(_swapData.exchange, _addresses),
                _amountIn
            );
        }
    }
    
    /**
     * Gets the input amount of a fixed output swap.
     *
     * @param _swapData     the swap parameters
     * @param _addresses    Struct containing relevant smart contract addresses.
     * @param _amountOut    the output amount of the swap
     *
     * @return              the input amount of the swap
     */
    function getAmountIn(
        Addresses memory _addresses,
        SwapData memory _swapData,
        uint256 _amountOut
    )
        external
        returns (uint256)
    {
        if (_swapData.path.length == 0 || _swapData.path[0] == _swapData.path[_swapData.path.length-1]) {
            return _amountOut;
        }

        if (_swapData.exchange == Exchange.UniV3) {
            return _getAmountInUniV3(_swapData, _addresses.uniV3Quoter, _amountOut);
        } else if (_swapData.exchange == Exchange.Curve) {
            (int128 i, int128 j) = _getCoinIndices(
                _swapData.pool,
                _swapData.path[0],
                _swapData.path[1],
                ICurveAddressProvider(_addresses.curveAddressProvider)
            );
            return _getAmountInCurve(_swapData.pool, i, j, _amountOut, _addresses);
        } else {
            return _getAmountInUniV2(
                _swapData,
                _getRouter(_swapData.exchange, _addresses),
                _amountOut
            );
        }
    }

    /**
     * Sets a max approval limit for an ERC20 token, provided the current allowance
     * is less than the required allownce.
     *
     * @param _token              Token to approve
     * @param _spender            Spender address to approve
     * @param _requiredAllowance  Target allowance to set
     */
    function _safeApprove(
        IERC20 _token,
        address _spender,
        uint256 _requiredAllowance
    )
        internal
    {
        uint256 allowance = _token.allowance(address(this), _spender);
        if (allowance < _requiredAllowance) {
            _token.safeIncreaseAllowance(_spender, MAX_UINT256 - allowance);
        }
    }

    /* ============ Private Methods ============ */

    /**
     *  Execute exact output swap via a UniV2 based DEX. (such as sushiswap);
     *
     * @param _path         List of token address to swap via. 
     * @param _amountOut    The amount of output token required
     * @param _maxAmountIn  Maximum amount of input token to be spent
     * @param _router       Address of the uniV2 router to use
     *
     * @return amountIn    The amount of input tokens spent
     */
    function _swapTokensForExactTokensUniV2(
        address[] memory _path,
        uint256 _amountOut,
        uint256 _maxAmountIn,
        IUniswapV2Router02 _router
    )
        private
        returns (uint256)
    {
        _safeApprove(IERC20(_path[0]), address(_router), _maxAmountIn);
        return _router.swapTokensForExactTokens(_amountOut, _maxAmountIn, _path, address(this), block.timestamp)[0];
    }

    /**
     *  Execute exact output swap via UniswapV3
     *
     * @param _path         List of token address to swap via. (In the order as
     *                      expected by uniV2, the first element being the input toen)
     * @param _fees         List of fee levels identifying the pools to swap via.
     *                      (_fees[0] refers to pool between _path[0] and _path[1])
     * @param _amountOut    The amount of output token required
     * @param _maxAmountIn  Maximum amount of input token to be spent
     * @param _uniV3Router  Address of the uniswapV3 router
     *
     * @return amountIn    The amount of input tokens spent
     */
    function _swapTokensForExactTokensUniV3(
        address[] memory _path,
        uint24[] memory _fees,
        uint256 _amountOut,
        uint256 _maxAmountIn,
        ISwapRouter _uniV3Router
    )
        private
        returns(uint256)
    {

        require(_path.length == _fees.length + 1, "ExchangeIssuance: PATHS_FEES_MISMATCH");
        _safeApprove(IERC20(_path[0]), address(_uniV3Router), _maxAmountIn);
        if(_path.length == 2){
            ISwapRouter.ExactOutputSingleParams memory params =
                ISwapRouter.ExactOutputSingleParams({
                    tokenIn: _path[0],
                    tokenOut: _path[1],
                    fee: _fees[0],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: _amountOut,
                    amountInMaximum: _maxAmountIn,
                    sqrtPriceLimitX96: 0
                });
            return _uniV3Router.exactOutputSingle(params);
        } else {
            bytes memory pathV3 = _encodePathV3(_path, _fees, true);
            ISwapRouter.ExactOutputParams memory params =
                ISwapRouter.ExactOutputParams({
                    path: pathV3,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountOut: _amountOut,
                    amountInMaximum: _maxAmountIn
                });
            return _uniV3Router.exactOutput(params);
        }
    }

    /**
     *  Execute exact input swap via Curve
     *
     * @param _path         Path (has to be of length 2)
     * @param _pool         Address of curve pool to use
     * @param _amountIn     The amount of input token to be spent
     * @param _minAmountOut Minimum amount of output token to receive
     * @param _addresses    Struct containing relevant smart contract addresses.
     *
     * @return amountOut    The amount of output token obtained
     */
    function _swapExactTokensForTokensCurve(
        address[] memory _path,
        address _pool,
        uint256 _amountIn,
        uint256 _minAmountOut,
        Addresses memory _addresses
    )
        private
        returns (uint256 amountOut)
    {
        require(_path.length == 2, "ExchangeIssuance: CURVE_WRONG_PATH_LENGTH");
        (int128 i, int128 j) = _getCoinIndices(_pool, _path[0], _path[1], ICurveAddressProvider(_addresses.curveAddressProvider));

        if(_path[0] == ETH_ADDRESS){
            IWETH(_addresses.weth).withdraw(_amountIn);
        }

        amountOut = _exchangeCurve(i, j, _pool, _amountIn, _minAmountOut, _path[0]);

        if(_path[_path.length-1] == ETH_ADDRESS){
            IWETH(_addresses.weth).deposit{value: amountOut}();
        }

    }

    /**
     *  Execute exact output swap via Curve
     *
     * @param _path         Path (has to be of length 2)
     * @param _pool         Address of curve pool to use
     * @param _amountOut    The amount of output token required
     * @param _maxAmountIn  Maximum amount of input token to be spent
     *
     * @return amountOut    The amount of output token obtained
     */
    function _swapTokensForExactTokensCurve(
        address[] memory _path,
        address _pool,
        uint256 _amountOut,
        uint256 _maxAmountIn,
        Addresses memory _addresses
    )
        private
        returns (uint256)
    {
        require(_path.length == 2, "ExchangeIssuance: CURVE_WRONG_PATH_LENGTH");
        (int128 i, int128 j) = _getCoinIndices(_pool, _path[0], _path[1], ICurveAddressProvider(_addresses.curveAddressProvider));

        uint256 amountIn = _getAmountInCurve(
            _pool,
            i,
            j,
            _amountOut,
            _addresses
        );
        require(amountIn <= _maxAmountIn, "ExchangeIssuance: CURVE_OVERSPENT");

        if(_path[0] == ETH_ADDRESS){
            IWETH(_addresses.weth).withdraw(amountIn);
        }

        uint256 returnedAmountOut = _exchangeCurve(i, j, _pool, amountIn, _amountOut, _path[0]);
        require(_amountOut <= returnedAmountOut, "ExchangeIssuance: CURVE_UNDERBOUGHT");

        if(_path[_path.length-1] == ETH_ADDRESS){
            IWETH(_addresses.weth).deposit{ value: returnedAmountOut }();
        }

        return amountIn;
    }
    
    function _exchangeCurve(
        int128 _i,
        int128 _j,
        address _pool,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _from
    )
        private
        returns (uint256 amountOut)
    {
        ICurvePool pool = ICurvePool(_pool);
        if(_from == ETH_ADDRESS){
            amountOut = pool.exchange{value: _amountIn}(
                _i,
                _j,
                _amountIn,
                _minAmountOut
            );
        }
        else {
            IERC20(_from).approve(_pool, _amountIn);
            amountOut = pool.exchange(
                _i,
                _j,
                _amountIn,
                _minAmountOut
            );
        }
    }

    /**
     *  Calculate required input amount to get a given output amount via Curve swap
     *
     * @param _i            Index of input token as per the ordering of the pools tokens
     * @param _j            Index of output token as per the ordering of the pools tokens
     * @param _pool         Address of curve pool to use
     * @param _amountOut    The amount of output token to be received
     * @param _addresses    Struct containing relevant smart contract addresses.
     *
     * @return amountOut    The amount of output token obtained
     */
    function _getAmountInCurve(
        address _pool,
        int128 _i,
        int128 _j,
        uint256 _amountOut,
        Addresses memory _addresses
    )
        private
        view
        returns (uint256)
    {
        CurvePoolData memory poolData = _getCurvePoolData(_pool, ICurveAddressProvider(_addresses.curveAddressProvider));

        return ICurveCalculator(_addresses.curveCalculator).get_dx(
            poolData.nCoins,
            poolData.balances,
            poolData.A,
            poolData.fee,
            poolData.rates,
            poolData.decimals,
            false,
            _i,
            _j,
            _amountOut
        ) + ROUNDING_ERROR_MARGIN;
    }

    /**
     *  Calculate output amount of a Curve swap
     *
     * @param _i            Index of input token as per the ordering of the pools tokens
     * @param _j            Index of output token as per the ordering of the pools tokens
     * @param _pool         Address of curve pool to use
     * @param _amountIn     The amount of output token to be received
     * @param _addresses    Struct containing relevant smart contract addresses.
     *
     * @return amountOut    The amount of output token obtained
     */
    function _getAmountOutCurve(
        address _pool,
        int128 _i,
        int128 _j,
        uint256 _amountIn,
        Addresses memory _addresses
    )
        private
        view
        returns (uint256)
    {
        return ICurvePool(_pool).get_dy(_i, _j, _amountIn);
    }

    /**
     *  Get metadata on curve pool required to calculate input amount from output amount
     *
     * @param _pool                    Address of curve pool to use
     * @param _curveAddressProvider    Address of curve address provider
     *
     * @return Struct containing all required data to perform getAmountInCurve calculation
     */
    function _getCurvePoolData(
        address _pool,
        ICurveAddressProvider _curveAddressProvider
    ) private view returns(CurvePoolData memory)
    {
        ICurvePoolRegistry registry = ICurvePoolRegistry(_curveAddressProvider.get_registry());

        return CurvePoolData(
            int128(registry.get_n_coins(_pool)[0]),
            registry.get_balances(_pool),
            registry.get_A(_pool),
            registry.get_fees(_pool)[0],
            registry.get_rates(_pool),
            registry.get_decimals(_pool)
        );
    }
    
    /**
     *  Get token indices for given pool
     *  NOTE: This was necessary sine the get_coin_indices function of the CurvePoolRegistry did not work for StEth/ETH pool
     *
     * @param _pool                    Address of curve pool to use
     * @param _from                    Address of input token
     * @param _to                      Address of output token
     * @param _curveAddressProvider    Address of curve address provider
     *
     * @return i Index of input token
     * @return j Index of output token
     */
    function _getCoinIndices(
        address _pool,
        address _from,
        address _to,
        ICurveAddressProvider _curveAddressProvider
    )
        private
        view
        returns (int128 i, int128 j)
    {
        ICurvePoolRegistry registry = ICurvePoolRegistry(_curveAddressProvider.get_registry());

        // Set to out of range index to signal the coin is not found yet
        i = 9;
        j = 9;
        address[8] memory poolCoins = registry.get_coins(_pool);

        for(uint256 k = 0; k < 8; k++){
            if(poolCoins[k] == _from){
                i = int128(k);
            }
            else if(poolCoins[k] == _to){
                j = int128(k);
            }
            // ZeroAddress signals end of list
            if(poolCoins[k] == address(0) || (i != 9 && j != 9)){
                break;
            }
        }

        require(i != 9, "ExchangeIssuance: CURVE_FROM_NOT_FOUND");
        require(j != 9, "ExchangeIssuance: CURVE_TO_NOT_FOUND");

        return (i, j);
    }

    /**
     *  Execute exact input swap via UniswapV3
     *
     * @param _path         List of token address to swap via. 
     * @param _fees         List of fee levels identifying the pools to swap via.
     *                      (_fees[0] refers to pool between _path[0] and _path[1])
     * @param _amountIn     The amount of input token to be spent
     * @param _minAmountOut Minimum amount of output token to receive
     * @param _uniV3Router  Address of the uniswapV3 router
     *
     * @return amountOut    The amount of output token obtained
     */
    function _swapExactTokensForTokensUniV3(
        address[] memory _path,
        uint24[] memory _fees,
        uint256 _amountIn,
        uint256 _minAmountOut,
        ISwapRouter _uniV3Router
    )
        private
        returns (uint256)
    {
        require(_path.length == _fees.length + 1, "ExchangeIssuance: PATHS_FEES_MISMATCH");
        _safeApprove(IERC20(_path[0]), address(_uniV3Router), _amountIn);
        if(_path.length == 2){
            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams({
                    tokenIn: _path[0],
                    tokenOut: _path[1],
                    fee: _fees[0],
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: _amountIn,
                    amountOutMinimum: _minAmountOut,
                    sqrtPriceLimitX96: 0
                });
            return _uniV3Router.exactInputSingle(params);
        } else {
            bytes memory pathV3 = _encodePathV3(_path, _fees, false);
            ISwapRouter.ExactInputParams memory params =
                ISwapRouter.ExactInputParams({
                    path: pathV3,
                    recipient: address(this),
                    deadline: block.timestamp,
                    amountIn: _amountIn,
                    amountOutMinimum: _minAmountOut
                });
            uint amountOut = _uniV3Router.exactInput(params);
            return amountOut;
        }
    }

    /**
     *  Execute exact input swap via UniswapV2
     *
     * @param _path         List of token address to swap via. 
     * @param _amountIn     The amount of input token to be spent
     * @param _minAmountOut Minimum amount of output token to receive
     * @param _router       Address of uniV2 router to use
     *
     * @return amountOut    The amount of output token obtained
     */
    function _swapExactTokensForTokensUniV2(
        address[] memory _path,
        uint256 _amountIn,
        uint256 _minAmountOut,
        IUniswapV2Router02 _router
    )
        private
        returns (uint256)
    {
        _safeApprove(IERC20(_path[0]), address(_router), _amountIn);
        // NOTE: The following was changed from always returning result at position [1] to returning the last element of the result array
        // With this change, the actual output is correctly returned also for multi-hop swaps
        // See https://github.com/IndexCoop/index-coop-smart-contracts/pull/116 
        uint256[] memory result = _router.swapExactTokensForTokens(_amountIn, _minAmountOut, _path, address(this), block.timestamp);
        // result = uint[] memory	The input token amount and all subsequent output token amounts.
        // we are usually only interested in the actual amount of the output token (so result element at the last place)
        return result[result.length-1];
    }

    /**
     * Gets the output amount of a token swap on Uniswap V2
     *
     * @param _swapData     the swap parameters
     * @param _router       the uniswap v2 router address
     * @param _amountIn     the input amount of the trade
     *
     * @return              the output amount of the swap
     */
    function _getAmountOutUniV2(
        SwapData memory _swapData,
        IUniswapV2Router02 _router,
        uint256 _amountIn
    )
        private
        view
        returns (uint256)
    {
        return _router.getAmountsOut(_amountIn, _swapData.path)[_swapData.path.length-1];
    }

    /**
     * Gets the input amount of a fixed output swap on Uniswap V2.
     *
     * @param _swapData     the swap parameters
     * @param _router       the uniswap v2 router address
     * @param _amountOut    the output amount of the swap
     *
     * @return              the input amount of the swap
     */
    function _getAmountInUniV2(
        SwapData memory _swapData,
        IUniswapV2Router02 _router,
        uint256 _amountOut
    )
        private
        view
        returns (uint256)
    {
        return _router.getAmountsIn(_amountOut, _swapData.path)[0];
    }

    /**
     * Gets the output amount of a token swap on Uniswap V3.
     *
     * @param _swapData     the swap parameters
     * @param _quoter       the uniswap v3 quoter
     * @param _amountIn     the input amount of the trade
     *
     * @return              the output amount of the swap
     */

    function _getAmountOutUniV3(
        SwapData memory _swapData,
        address _quoter,
        uint256 _amountIn
    )
        private
        returns (uint256)
    {
        bytes memory path = _encodePathV3(_swapData.path, _swapData.fees, false);
        return IQuoter(_quoter).quoteExactInput(path, _amountIn);
    }

    /**
     * Gets the input amount of a fixed output swap on Uniswap V3.
     *
     * @param _swapData     the swap parameters
     * @param _quoter       uniswap v3 quoter
     * @param _amountOut    the output amount of the swap
     *
     * @return              the input amount of the swap
     */
    function _getAmountInUniV3(
        SwapData memory _swapData,
        address _quoter,
        uint256 _amountOut
    )
        private
        returns (uint256)
    {
        bytes memory path = _encodePathV3(_swapData.path, _swapData.fees, true);
        return IQuoter(_quoter).quoteExactOutput(path, _amountOut);
    }

    /**
     * Encode path / fees to bytes in the format expected by UniV3 router
     *
     * @param _path          List of token address to swap via (starting with input token)
     * @param _fees          List of fee levels identifying the pools to swap via.
     *                       (_fees[0] refers to pool between _path[0] and _path[1])
     * @param _reverseOrder  Boolean indicating if path needs to be reversed to start with output token.
     *                       (which is the case for exact output swap)
     *
     * @return encodedPath   Encoded path to be forwared to uniV3 router
     */
    function _encodePathV3(
        address[] memory _path,
        uint24[] memory _fees,
        bool _reverseOrder
    )
        private
        pure
        returns(bytes memory encodedPath)
    {
        if(_reverseOrder){
            encodedPath = abi.encodePacked(_path[_path.length-1]);
            for(uint i = 0; i < _fees.length; i++){
                uint index = _fees.length - i - 1;
                encodedPath = abi.encodePacked(encodedPath, _fees[index], _path[index]);
            }
        } else {
            encodedPath = abi.encodePacked(_path[0]);
            for(uint i = 0; i < _fees.length; i++){
                encodedPath = abi.encodePacked(encodedPath, _fees[i], _path[i+1]);
            }
        }
    }

    function _getRouter(
        Exchange _exchange,
        Addresses memory _addresses
    )
        private
        pure
        returns (IUniswapV2Router02)
    {
        return IUniswapV2Router02(
            (_exchange == Exchange.Quickswap) ? _addresses.quickRouter : _addresses.sushiRouter
        );
    }
}

/*
    Copyright 2022 Index Cooperative
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/math/Math.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IBasicIssuanceModule } from "../interfaces/IBasicIssuanceModule.sol";
import { IDebtIssuanceModule } from "../interfaces/IDebtIssuanceModule.sol";
import { INotionalTradeModule } from "../interfaces/INotionalTradeModule.sol";
import { IController } from "../interfaces/IController.sol";
import { ISetToken } from "../interfaces/ISetToken.sol";
import { IWrappedfCash } from "../interfaces/IWrappedfCash.sol";
import { IWrappedfCashFactory } from "../interfaces/IWrappedfCashFactory.sol";
import { IWETH } from "../interfaces/IWETH.sol";
import { PreciseUnitMath } from "../lib/PreciseUnitMath.sol";
import { DEXAdapter } from "./DEXAdapter.sol";





/**
 * @title FlashMintNotional
 * @author Index Coop
 *
 * Contract for issuing and redeeming a Set Token that contains wrappedfCash position
 * Includes (in the issuance case):
 *    - Matching fCash components to their underlying asset
 *    - Swapping input token to underlying asset
 *    - Minting fCash positions from underlying asset
 *    - Issuing set token   
 */
contract FlashMintNotional is Ownable, ReentrancyGuard {

    using Address for address payable;
    using Address for address;
    using SafeMath for uint256;
    using PreciseUnitMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ISetToken;
    using DEXAdapter for DEXAdapter.Addresses;

    struct TradeData {
        ISetToken setToken;
        uint256 amountSetToken;
        IERC20 paymentToken;
        uint256 limitAmount;
        address issuanceModule;
        bool isDebtIssuance;
        uint256 slippage;
        bool redeemMaturedPositions;
    }

    /* ============ Constants ============== */

    // Placeholder address to identify ETH where it is treated as if it was an ERC20 token
    address constant public ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /* ============ State Variables ============ */

    IController public immutable setController;
    IWrappedfCashFactory public immutable wrappedfCashFactory;
    INotionalTradeModule public immutable notionalTradeModule;
    DEXAdapter.Addresses public addresses;
    uint256 public decodedIdGasLimit;

    /* ============ Events ============ */

    event FlashMint(
        address indexed _recipient,     // The recipient address of the issued SetTokens
        ISetToken indexed _setToken,    // The issued SetToken
        IERC20 indexed _inputToken,     // The address of the input asset(ERC20/ETH) used to issue the SetTokens
        uint256 _amountInputToken,      // The amount of input tokens used for issuance
        uint256 _amountSetIssued        // The amount of SetTokens received by the recipient
    );

    event FlashRedeem(
        address indexed _recipient,     // The recipient adress of the output tokens obtained for redemption
        ISetToken indexed _setToken,    // The redeemed SetToken
        IERC20 indexed _outputToken,    // The address of output asset(ERC20/ETH) received by the recipient
        uint256 _amountSetRedeemed,     // The amount of SetTokens redeemed for output tokens
        uint256 _amountOutputToken      // The amount of output tokens received by the recipient
    );

    /* ============ Modifiers ============ */

    modifier isValidModule(address _issuanceModule) {
        require(setController.isModule(_issuanceModule), "FlashMint: INVALID ISSUANCE MODULE");
         _;
    }

    /**
    * Sets various contract addresses and gas limit for getDecodedId call
    * 
    * @param _weth                  Address of wrapped native token
    * @param _setController         SetToken controller used to verify a given token is a set
    * @param _wrappedfCashFactory   Factory contract creating new fCash wrappers
    * @param _notionalTradeModule   Module used to make sure matured positions are redeemed
    * @param _quickRouter           Address of quickswap router
    * @param _sushiRouter           Address of sushiswap router
    * @param _uniV3Router           Address of uniswap v3 router
    * @param _uniV3Quoter           Address of uniswap v3 quoter
    * @param _curveAddressProvider  Contract to get current implementation address of curve registry
    * @param _curveCalculator       Contract to calculate required input to receive given output in curve (for exact output swaps)
    * @param _decodedIdGasLimit     Gas limit for call to getDecodedID
    */
    constructor(
        address _weth,
        IController _setController,
        IWrappedfCashFactory _wrappedfCashFactory,
        INotionalTradeModule _notionalTradeModule,
        address _quickRouter,
        address _sushiRouter,
        address _uniV3Router,
        address _uniV3Quoter,
        address _curveAddressProvider,
        address _curveCalculator,
        uint256 _decodedIdGasLimit
    )
        public
    {
        setController = _setController;

        wrappedfCashFactory = _wrappedfCashFactory;
        notionalTradeModule = _notionalTradeModule;

        addresses.weth = _weth;
        addresses.quickRouter = _quickRouter;
        addresses.sushiRouter = _sushiRouter;
        addresses.uniV3Router = _uniV3Router;
        addresses.uniV3Quoter = _uniV3Quoter;
        addresses.curveAddressProvider = _curveAddressProvider;
        addresses.curveCalculator = _curveCalculator;

        decodedIdGasLimit = _decodedIdGasLimit;
    }

    /* ============ Public Functions ============ */


    /**
     * Returns component positions required for issuance 
     *
     * @param _issuanceModule    Address of issuance Module to use 
     * @param _isDebtIssuance    Flag indicating wether given issuance module is a debt issuance module
     * @param _setToken          Set token to issue
     * @param _amountSetToken    Amount of set token to issue
     */
    function getRequiredIssuanceComponents(address _issuanceModule, bool _isDebtIssuance, ISetToken _setToken, uint256 _amountSetToken) public view returns(address[] memory components, uint256[] memory positions) {
        if(_isDebtIssuance) { 
            (components, positions, ) = IDebtIssuanceModule(_issuanceModule).getRequiredComponentIssuanceUnits(_setToken, _amountSetToken);
        }
        else {
            (components, positions) = IBasicIssuanceModule(_issuanceModule).getRequiredComponentUnitsForIssue(_setToken, _amountSetToken);
        }
    }

    /**
     * Returns component positions required for Redemption 
     *
     * @param _issuanceModule    Address of issuance Module to use 
     * @param _isDebtIssuance    Flag indicating wether given issuance module is a debt issuance module
     * @param _setToken          Set token to issue
     * @param _amountSetToken    Amount of set token to issue
     */
    function getRequiredRedemptionComponents(address _issuanceModule, bool _isDebtIssuance, ISetToken _setToken, uint256 _amountSetToken) public view returns(address[] memory components, uint256[] memory positions) {
        if(_isDebtIssuance) { 
            (components, positions, ) = IDebtIssuanceModule(_issuanceModule).getRequiredComponentRedemptionUnits(_setToken, _amountSetToken);
        }
        else {
            components = _setToken.getComponents();
            positions = new uint256[](components.length);
            for(uint256 i = 0; i < components.length; i++) {
                uint256 unit = uint256(_setToken.getDefaultPositionRealUnit(components[i]));
                positions[i] = unit.preciseMul(_amountSetToken);
            }
        }
    }

    /* ============ External Functions ============ */

    /**
     * @dev Update gas limit of call to getDecodedID in _isWrappedFCash
     * @param _decodedIdGasLimit   New gas limit for call to getDecodedID
     */
    function updateDecodedIdGasLimit(uint256 _decodedIdGasLimit) external onlyOwner {
        require(_decodedIdGasLimit != 0, "DecodedIdGasLimit cannot be zero");
        decodedIdGasLimit = _decodedIdGasLimit;
    }

    /**
     * Withdraw slippage to selected address
     *
     * @param _tokens    Addresses of tokens to withdraw, specifiy ETH_ADDRESS to withdraw ETH
     * @param _to        Address to send the tokens to
     */
    function withdrawTokens(IERC20[] calldata _tokens, address payable _to) external onlyOwner payable {
        for(uint256 i = 0; i < _tokens.length; i++) {
            if(address(_tokens[i]) == ETH_ADDRESS){
                _to.sendValue(address(this).balance);
            }
            else{
                _tokens[i].safeTransfer(_to, _tokens[i].balanceOf(address(this)));
            }
        }
    }


    /**
     * Returns components and units but replaces wrappefCash positions with the corresponding amount of underlying token needed to mint 
     *
     * @param _setToken          Address of the set token to redeem
     * @param _amountSetToken    Amount of set token to redeem
     * @param _issuanceModule    Address of the issuance module to use for getting raw list of components and units
     * @param _isDebtIssuance    Boolean indicating wether given issuance module is an instance of Debt- or BasicIssuanceModule
     * @param _slippage          Relative slippage (with 18 decimals) to subtract from wrappedfCash's estimated redemption amount to allow for approximation error
     */
    function getFilteredComponentsRedemption(
        ISetToken _setToken,
        uint256 _amountSetToken,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage

    )
        external
        view
        returns (address[] memory filteredComponents, uint[] memory filteredUnits)
    {
        return _getFilteredComponentsRedemption(_setToken, _amountSetToken, _issuanceModule, _isDebtIssuance, _slippage);
    }

    /**
     * Returns filtered components after redeeming matured positions
     * THIS METHOD SHOULD ONLY BE CALLED WITH STATICCALL
     *
     * @param _setToken          Address of the set token to redeem
     * @param _amountSetToken    Amount of set token to redeem
     * @param _issuanceModule    Address of the issuance module to use for getting raw list of components and units
     * @param _isDebtIssuance    Boolean indicating wether given issuance module is an instance of Debt- or BasicIssuanceModule
     * @param _slippage          Relative slippage (with 18 decimals) to subtract from wrappedfCash's estimated redemption amount to allow for approximation error
     */
    function getFilteredComponentsRedemptionAfterMaturityRedemption(
        ISetToken _setToken,
        uint256 _amountSetToken,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage
    )
        external
        returns (address[] memory filteredComponents, uint[] memory filteredUnits)
    {
        notionalTradeModule.redeemMaturedPositions(_setToken);
        return _getFilteredComponentsRedemption(_setToken, _amountSetToken, _issuanceModule, _isDebtIssuance, _slippage);
    }


    /**
     * Returns components and units but replaces wrappefCash positions with the corresponding amount of underlying token needed to mint 
     *
     * @param _setToken          Address of the set token to issue
     * @param _amountSetToken    Amount of set token to issue
     * @param _issuanceModule    Address of the issuance module to use for getting raw list of components and units
     * @param _isDebtIssuance    Boolean indicating wether given issuance module is an instance of Debt- or BasicIssuanceModule
     * @param _slippage          Relative slippage (with 18 decimals) to add to wrappedfCash's estimated issuance cost to allow for approximation error
     */
    function getFilteredComponentsIssuance(
        ISetToken _setToken,
        uint256 _amountSetToken,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage
    )
        external
        view
        returns (address[] memory filteredComponents, uint[] memory filteredUnits)
    {
        (filteredComponents, filteredUnits, ) = _getFilteredComponentsIssuance(_setToken, _amountSetToken, _issuanceModule, _isDebtIssuance, _slippage);
    }

    /**
     * Returns filtered components after redeeming matured positions
     * THIS METHOD SHOULD ONLY BE CALLED WITH STATICCALL
     *
     * @param _setToken          Address of the set token to issue
     * @param _amountSetToken    Amount of set token to issue
     * @param _issuanceModule    Address of the issuance module to use for getting raw list of components and units
     * @param _isDebtIssuance    Boolean indicating wether given issuance module is an instance of Debt- or BasicIssuanceModule
     * @param _slippage          Relative slippage (with 18 decimals) to add to wrappedfCash's estimated issuance cost to allow for approximation error
     */
    function getFilteredComponentsIssuanceAfterMaturityRedemption(
        ISetToken _setToken,
        uint256 _amountSetToken,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage

    )
        external
        returns (address[] memory filteredComponents, uint[] memory filteredUnits)
    {
        notionalTradeModule.redeemMaturedPositions(_setToken);
        (filteredComponents, filteredUnits, ) =  _getFilteredComponentsIssuance(_setToken, _amountSetToken, _issuanceModule, _isDebtIssuance, _slippage);

    }

    /**
     * Issue set token for ETH
     *
     * @param _setToken                  Address of the set token to issue
     * @param _amountSetToken            Amount of set token to issue
     * @param _swapData                  Swap data for each element of the filtered components in the same order as returned by getFilteredComponentsIssuance
     * @param _issuanceModule            Address of the issuance module to use for getting raw list of components and units
     * @param _isDebtIssuance            Boolean indicating wether given issuance module is an instance of Debt- or BasicIssuanceModule
     * @param _slippage                  Relative slippage (with 18 decimals) to add to wrappedfCash's estimated issuance cost to allow for approximation error
     * @param _redeemMaturedPositions    Set to false to skip redeeming matured positions and save gas, wich will fail if there are any matured positions
     */
    function issueExactSetFromETH(
        ISetToken _setToken,
        uint256 _amountSetToken,
        DEXAdapter.SwapData[] memory _swapData,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage,
        bool _redeemMaturedPositions
    )
        isValidModule(_issuanceModule)
        external
        payable
        nonReentrant
        returns (uint256)
    {

        IWETH(addresses.weth).deposit{value: msg.value}();
        TradeData memory tradeData = TradeData(
            _setToken,
            _amountSetToken,
            IERC20(addresses.weth),
            msg.value,
            _issuanceModule,
            _isDebtIssuance,
            _slippage,
            _redeemMaturedPositions
        );
        uint256 totalInputTokenSpent = _issueExactSetFromToken(tradeData,  _swapData);
        uint256 amountTokenReturn = msg.value.sub(totalInputTokenSpent);
        if (amountTokenReturn > 0) {
            IWETH(addresses.weth).withdraw(amountTokenReturn);
            payable(msg.sender).transfer(amountTokenReturn);
        }
        return totalInputTokenSpent;
    }

    /**
     * Issue set token for ERC20 Token
     *
     * @param _setToken                  Address of the set token to issue
     * @param _amountSetToken            Amount of set token to issue
     * @param _inputToken                Address of the input token to spent
     * @param _maxAmountInputToken       Maximum amount of input token to spent
     * @param _swapData                  Configuration of swaps from input token to each element of the filtered components in the same order as returned by getFilteredComponentsIssuance
     * @param _issuanceModule            Address of the issuance module to use for getting raw list of components and units
     * @param _isDebtIssuance            Boolean indicating wether given issuance module is an instance of Debt- or BasicIssuanceModule
     * @param _slippage                  Relative slippage (with 18 decimals) to add to wrappedfCash's estimated issuance cost to allow for approximation error
     * @param _redeemMaturedPositions    Set to false to skip redeeming matured positions and save gas, wich will fail if there are any matured positions
     */
    function issueExactSetFromToken(
        ISetToken _setToken,
        IERC20 _inputToken,
        uint256 _amountSetToken,
        uint256 _maxAmountInputToken,
        DEXAdapter.SwapData[] memory _swapData,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage,
        bool _redeemMaturedPositions
    )
        isValidModule(_issuanceModule)
        external
        nonReentrant
        returns (uint256)
    {

        _inputToken.safeTransferFrom(msg.sender, address(this), _maxAmountInputToken);
        TradeData memory tradeData = TradeData(
            _setToken,
            _amountSetToken,
            _inputToken,
            _maxAmountInputToken,
            _issuanceModule,
            _isDebtIssuance,
            _slippage,
            _redeemMaturedPositions
        );
        uint256 totalInputTokenSpent = _issueExactSetFromToken(tradeData, _swapData);
        _returnExcessInputToken(_inputToken, _maxAmountInputToken, totalInputTokenSpent);
        return totalInputTokenSpent;
    }

    /**
     * Redeem set token for selected output token
     *
     * @param _setToken                  Address of the set token to redeem
     * @param _amountSetToken            Amount of set token to redeem
     * @param _outputToken               Address of the output token to spent
     * @param _minOutputReceive          Minimum amount of output token to receive
     * @param _swapData                  Configuration of swaps from each element of the filtered components to the output token in the same order as returned by getFilteredComponentsIssuance
     * @param _issuanceModule            Address of the issuance module to use for getting raw list of components and units
     * @param _isDebtIssuance            Boolean indicating wether given issuance module is an instance of Debt- or BasicIssuanceModule
     * @param _slippage                  Relative slippage (with 18 decimals) to subtract from wrappedfCash's estimated redemption amount to allow for approximation error
     * @param _redeemMaturedPositions    Set to false to skip redeeming matured positions and save gas, wich will fail if there are any matured positions
     */
    function redeemExactSetForToken(
        ISetToken _setToken,
        IERC20 _outputToken,
        uint256 _amountSetToken,
        uint256 _minOutputReceive,
        DEXAdapter.SwapData[] memory _swapData,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage,
        bool _redeemMaturedPositions
    )
        isValidModule(_issuanceModule)
        external
        nonReentrant
        returns (uint256)
    {

        TradeData memory tradeData = TradeData(
            _setToken,
            _amountSetToken,
            _outputToken,
            _minOutputReceive,
            _issuanceModule,
            _isDebtIssuance,
            _slippage,
            _redeemMaturedPositions
        );
        uint256 outputAmount = _redeemExactSetForToken(tradeData, _swapData);
        _outputToken.safeTransfer(msg.sender, outputAmount);
        return outputAmount;
    }

    /**
     * Redeem set token for eth
     *
     * @param _setToken                  Address of the set token to redeem
     * @param _amountSetToken            Amount of set token to redeem
     * @param _minOutputReceive          Minimum amount of output token to receive
     * @param _swapData                  Configuration of swaps from each element of the filtered components to the output token in the same order as returned by getFilteredComponentsIssuance
     * @param _issuanceModule            Address of the issuance module to use for getting raw list of components and units
     * @param _isDebtIssuance            Boolean indicating wether given issuance module is an instance of Debt- or BasicIssuanceModule
     * @param _slippage                  Relative slippage (with 18 decimals) to subtract from wrappedfCash's estimated redemption amount to allow for approximation error
     * @param _redeemMaturedPositions    Set to false to skip redeeming matured positions and save gas, wich will fail if there are any matured positions
     */
    function redeemExactSetForETH(
        ISetToken _setToken,
        uint256 _amountSetToken,
        uint256 _minOutputReceive,
        DEXAdapter.SwapData[] memory _swapData,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage,
        bool _redeemMaturedPositions
    )
        isValidModule(_issuanceModule)
        external
        nonReentrant
        returns (uint256)
    {

        
        TradeData memory tradeData = TradeData(
            _setToken,
            _amountSetToken,
            IERC20(addresses.weth),
            _minOutputReceive,
            _issuanceModule,
            _isDebtIssuance,
            _slippage,
            _redeemMaturedPositions
        );
        uint256 outputAmount = _redeemExactSetForToken(tradeData, _swapData);
        IWETH(addresses.weth).withdraw(outputAmount);
        payable(msg.sender).transfer(outputAmount);
        return outputAmount;
    }

    /* ============ Internal Functions ============ */


    /**
     * Transfer in input token, swap for components, mint fCash positions and issue set
     */
    function _issueExactSetFromToken(
        TradeData memory _tradeData,
        DEXAdapter.SwapData[] memory _swapData
    )
        internal
        returns (uint256)
    {

        uint256 inputTokenBalanceBefore = _tradeData.paymentToken.balanceOf(address(this));
        if(_tradeData.redeemMaturedPositions) {
            notionalTradeModule.redeemMaturedPositions(_tradeData.setToken);
        }

        (address[] memory componentsBought, uint256[] memory amountsBought, uint256[] memory mappingToFilteredComponents) =  _buyComponentsForInputToken(
            _tradeData,
            _swapData
        );

        _mintWrappedFCashPositions(
            _tradeData,
            componentsBought,
            amountsBought,
            mappingToFilteredComponents
        );

        IBasicIssuanceModule(_tradeData.issuanceModule).issue(_tradeData.setToken, _tradeData.amountSetToken, msg.sender);

        require(inputTokenBalanceBefore.sub(_tradeData.paymentToken.balanceOf(address(this))) <= _tradeData.limitAmount, "FlashMint: OVERSPENT");

        emit FlashMint(msg.sender, _tradeData.setToken, _tradeData.paymentToken, _tradeData.limitAmount, _tradeData.amountSetToken);
        return inputTokenBalanceBefore.sub(_tradeData.paymentToken.balanceOf(address(this)));
    }

    /**
     * Redeem set, redeem fCash components, sell received tokens for output token and transfer proceds to the caller
     */
    function _redeemExactSetForToken(
        TradeData memory _tradeData,
        DEXAdapter.SwapData[] memory _swapData
    )
        internal
        returns (uint256)
    {

        uint256 outputTokenBalanceBefore = _tradeData.paymentToken.balanceOf(address(this));
        if(_tradeData.redeemMaturedPositions) {
            notionalTradeModule.redeemMaturedPositions(_tradeData.setToken);
        }
        _redeemExactSet(_tradeData.setToken, _tradeData.amountSetToken, _tradeData.issuanceModule);

        _redeemWrappedFCashPositions(_tradeData);
        _sellComponentsForOutputToken(_tradeData, _swapData);

        uint256 outputAmount = _tradeData.paymentToken.balanceOf(address(this)).sub(outputTokenBalanceBefore);

        require(outputAmount >= _tradeData.limitAmount, "FlashMint: UNDERBOUGHT");
        // Emit event
        emit FlashRedeem(msg.sender, _tradeData.setToken, _tradeData.paymentToken, _tradeData.amountSetToken, outputAmount);
        // Return output amount
        return outputAmount;
    }


    /**
     * Sells all components (after redemption of fCash positions) for the output token
     */
    function _sellComponentsForOutputToken(
        TradeData memory _tradeData,
        DEXAdapter.SwapData[] memory _swapData
    )
        internal
    {
        (address[] memory components, uint256[] memory componentUnits) = _getFilteredComponentsRedemption(
            _tradeData.setToken,
            _tradeData.amountSetToken,
            _tradeData.issuanceModule,
            _tradeData.isDebtIssuance,
            _tradeData.slippage
        );

        require(components.length == _swapData.length, "Components / Swapdata mismatch");

        for (uint256 i = 0; i < components.length; i++) {
            uint256 maxAmountSell = componentUnits[i];
            address component = components[i];
            // Component Address being zero means the filtered list is finished and all remaining components are 0 as well
            if(component == address(0)){
                break;
            }

            // If the component is equal to the output token we don't have to trade
            if(component != address(_tradeData.paymentToken)) {
                addresses.swapExactTokensForTokens(maxAmountSell, 0, _swapData[i]);
            }

        }
    }

    /**
     * Redeem all fCash positions for the underlying token
     */
    function _redeemWrappedFCashPositions(
        TradeData memory _tradeData
    ) 
    internal
    {
        (address[] memory components, uint256[] memory componentUnits) = getRequiredRedemptionComponents(
            _tradeData.issuanceModule,
            _tradeData.isDebtIssuance,
            _tradeData.setToken,
            _tradeData.amountSetToken
        );

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            uint256 units = componentUnits[i];

            if(_isWrappedFCash(component)) {
                IWrappedfCash(component).redeemToUnderlying(units, address(this), 0);
            }
        }
    }

    /**
     * Mint all fCash positions from the underlying token
     */
    function _mintWrappedFCashPositions(
        TradeData memory _tradeData,
        address[] memory componentsBought,
        uint256[] memory amountsAvailable,
        uint256[] memory mappingToFilteredComponents
    ) 
    internal
    {
        (address[] memory components, uint256[] memory componentUnits) = getRequiredIssuanceComponents(
            _tradeData.issuanceModule,
            _tradeData.isDebtIssuance,
            _tradeData.setToken,
            _tradeData.amountSetToken
        );

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            uint256 units = componentUnits[i];
            if(_isWrappedFCash(component)) {
                IERC20 underlyingToken = _getUnderlyingToken(IWrappedfCash(component));
                uint256 componentIndex = mappingToFilteredComponents[i];
                uint256 amountAvailable = amountsAvailable[componentIndex];
                underlyingToken.safeApprove(component, amountAvailable);
                uint256 underlyingBalanceBefore = underlyingToken.balanceOf(address(this));

                IWrappedfCash(component).mintViaUnderlying(amountAvailable, uint88(units), address(this), 0);

                uint256 amountSpent = underlyingBalanceBefore.sub(underlyingToken.balanceOf(address(this)));
                amountsAvailable[componentIndex] = amountsAvailable[componentIndex].sub(amountSpent);
            }
            IERC20(component).safeApprove(_tradeData.issuanceModule, units);
        }
    }

    /**
     * Get underlying token of fCash positions returning weth address in case underlying is eth
     */
    function _getUnderlyingToken(
        IWrappedfCash _wrappedfCash
    ) 
    internal
    view 
    returns(IERC20)
    {
        (IERC20 underlyingToken, bool isEth) = _wrappedfCash.getToken(true);
        if(isEth) {
            underlyingToken = IERC20(addresses.weth);
        }
        return underlyingToken;
    }



    /**
     * Transfers given amount of set token from the sender and redeems it for underlying components.
     * Obtained component tokens are sent to this contract. 
     *
     * @param _setToken     Address of the SetToken to be redeemed
     * @param _amount       Amount of SetToken to be redeemed
     */
    function _redeemExactSet(ISetToken _setToken, uint256 _amount, address _issuanceModule) internal returns (uint256) {
        _setToken.safeTransferFrom(msg.sender, address(this), _amount);
        _setToken.safeApprove(_issuanceModule, _amount);
        IBasicIssuanceModule(_issuanceModule).redeem(_setToken, _amount, address(this));
    }

    /**
     * Returns excess input token
     *
     * @param _inputToken         Address of the input token to return
     * @param _receivedAmount     Amount received by the caller
     * @param _spentAmount        Amount spent for issuance
     */
    function _returnExcessInputToken(IERC20 _inputToken, uint256 _receivedAmount, uint256 _spentAmount) internal {
        uint256 amountTokenReturn = _receivedAmount.sub(_spentAmount);
        if (amountTokenReturn > 0) {
            _inputToken.safeTransfer(msg.sender,  amountTokenReturn);
        }
    }

    /**
     * @dev Checks if a given address is an fCash position that was deployed from the factory
     */
    function _isWrappedFCash(address _fCashPosition) internal view returns(bool){
        if(!_fCashPosition.isContract()) {
            return false;
        }

        //Had to add this gas limit since this call wasted all the gas when directed to WETH in unittests
        try IWrappedfCash(_fCashPosition).getDecodedID{gas: decodedIdGasLimit}() returns(uint16 _currencyId, uint40 _maturity){
            try wrappedfCashFactory.computeAddress(_currencyId, _maturity) returns(address _computedAddress){
                return _fCashPosition == _computedAddress;
            } catch {
                return false;
            }
        } catch {
            return false;
        }
    }

    /**
     * @dev Returns estimated amount of underlying tokens spent on minting given amount of fCash, adding given slippage percentage
     */
    function _getUnderlyingTokensForMint(IWrappedfCash _fCashPosition, uint256 _fCashAmount, uint256 _slippage)
    internal
    view
    returns(uint256)
    {
        return _fCashPosition.previewMint(_fCashAmount).mul(1 ether + _slippage).div(1 ether);
    }

    /**
     * @dev Returns estimated amount of underlying tokens returned on redeeming given amount of fCash, subtracting given slippage percentage
     */
    function _getUnderlyingTokensForRedeem(IWrappedfCash _fCashPosition, uint256 _fCashAmount, uint256 _slippage)
    internal
    view
    returns(uint256)
    {
        return _fCashPosition.previewRedeem(_fCashAmount).mul(1 ether - _slippage).div(1 ether);
    }

    /**
     * @dev Helper method to find a given address in the list. Returns index+1 if found, 0 if not found.
     */
    function _findComponent(address[] memory _components, address _toFind)
    internal
    pure
    returns(uint256)
    {
        for(uint256 i = 0; i < _components.length; i++) {
            if(_components[i] == _toFind){
                return i + 1;
            }
        }
        return 0;
    }

    /**
     * @dev Swaps input token for required amounts of filtered components
     */
    function _buyComponentsForInputToken(
        TradeData memory _tradeData,
        DEXAdapter.SwapData[] memory _swapData
    ) 
    internal
    returns(address[] memory, uint256[] memory, uint256[] memory)
    {
        (address[] memory components, uint256[] memory componentUnits, uint256[] memory mappingToFilteredComponents) = _getFilteredComponentsIssuance(
            _tradeData.setToken,
            _tradeData.amountSetToken,
            _tradeData.issuanceModule,
            _tradeData.isDebtIssuance,
            _tradeData.slippage
        );

        require(components.length == _swapData.length, "Components / Swapdata mismatch");

        uint256[] memory boughtAmounts = new uint256[](components.length);

        for (uint256 i = 0; i < components.length; i++) {
            if(components[i] == address(0)){
                break;
            }

            // If the component is equal to the input token we don't have to trade
            if(components[i] != address(_tradeData.paymentToken)) {
                uint256 componentBalanceBefore = IERC20(components[i]).balanceOf(address(this));
                addresses.swapTokensForExactTokens(componentUnits[i], _tradeData.limitAmount, _swapData[i]);
                boughtAmounts[i] = IERC20(components[i]).balanceOf(address(this)).sub(componentBalanceBefore);
            } else {
                boughtAmounts[i] = componentUnits[i];
            }
        }

        return(components, boughtAmounts, mappingToFilteredComponents);
    }

    /**
     * @dev Returns expected of components received upon set tokens redemption, replacing fCash position with equivalent amount of underlying token
     */
    function _getFilteredComponentsRedemption(
        ISetToken _setToken,
        uint256 _amountSetToken,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage
    )
        internal
        view
        returns (address[] memory filteredComponents, uint[] memory filteredUnits)
    {
        (address[] memory components, uint256[] memory componentUnits) = getRequiredRedemptionComponents(_issuanceModule, _isDebtIssuance, _setToken, _amountSetToken);

        filteredComponents = new address[](components.length);
        filteredUnits = new uint256[](components.length);
        uint j = 0;

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            uint256 units;

            if(_isWrappedFCash(component)) {
                units = _getUnderlyingTokensForRedeem(IWrappedfCash(component), componentUnits[i], _slippage);
                IERC20 underlyingToken = _getUnderlyingToken(IWrappedfCash(component));
                component = address(underlyingToken);
            }
            else {
                units = componentUnits[i];
            }

            uint256 componentIndex = _findComponent(filteredComponents, component);
            if(componentIndex > 0){
                filteredUnits[componentIndex - 1] = filteredUnits[componentIndex - 1].add(units);
            } else {
                filteredComponents[j] = component;
                filteredUnits[j] = units;
                j++;
            }
        }
    }

    /**
     * @dev Returns expected of components spent upon set tokens issuance, replacing fCash position with equivalent amount of underlying token
     */
    function _getFilteredComponentsIssuance(
        ISetToken _setToken,
        uint256 _amountSetToken,
        address _issuanceModule,
        bool _isDebtIssuance,
        uint256 _slippage
    )
        internal
        view
        returns (address[] memory filteredComponents, uint[] memory filteredUnits, uint256[] memory mappingToFilteredComponent)
    {
        (address[] memory components, uint256[] memory componentUnits) = getRequiredIssuanceComponents(_issuanceModule, _isDebtIssuance, _setToken, _amountSetToken);

        filteredComponents = new address[](components.length);
        filteredUnits = new uint256[](components.length);
        mappingToFilteredComponent = new uint256[](components.length);
        uint j = 0;

        for (uint256 i = 0; i < components.length; i++) {
            address component = components[i];
            uint256 units;

            if(_isWrappedFCash(component)) {
                units = _getUnderlyingTokensForMint(IWrappedfCash(component), componentUnits[i], _slippage);
                IERC20 underlyingToken = _getUnderlyingToken(IWrappedfCash(component));
                component = address(underlyingToken);
            }
            else {
                units = componentUnits[i];
            }

            uint256 componentIndex = _findComponent(filteredComponents, component);
            if(componentIndex > 0){
                filteredUnits[componentIndex - 1] = filteredUnits[componentIndex - 1].add(units);
                mappingToFilteredComponent[i] = componentIndex - 1;
            } else {
                filteredComponents[j] = component;
                filteredUnits[j] = units;
                mappingToFilteredComponent[i] = j;
                j++;
            }
        }
    }

    /**
     * @dev Fallback method to enable receiving eth when withrdawing from weth contract
     */
    receive() external payable {
        // required for weth.withdraw() to work properly
        require(msg.sender == addresses.weth, "FlashMint: Direct deposits not allowed");
    }

}

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity >=0.6.10;

import { ISetToken } from "./ISetToken.sol";

interface IBasicIssuanceModule {
    function getRequiredComponentUnitsForIssue(
        ISetToken _setToken,
        uint256 _quantity
    ) external view returns(address[] memory, uint256[] memory);
    function issue(ISetToken _setToken, uint256 _quantity, address _to) external;
    function redeem(ISetToken _token, uint256 _quantity, address _to) external;
}

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

interface IController {
    function addSet(address _setToken) external;
    function feeRecipient() external view returns(address);
    function getModuleFee(address _module, uint256 _feeType) external view returns(uint256);
    function isModule(address _module) external view returns(bool);
    function isSet(address _setToken) external view returns(bool);
    function isSystemContract(address _contractAddress) external view returns (bool);
    function resourceId(uint256 _id) external view returns(address);
    function owner() external view returns(address);
    function addFactory(address _factory) external;
    function addModule(address _module) external;
}

/*
    Copyright 2020 Set Labs Inc.
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity >=0.6.10;

import { ISetToken } from "./ISetToken.sol";
import { IManagerIssuanceHook } from "./IManagerIssuanceHook.sol";

interface IDebtIssuanceModule {
    function getRequiredComponentIssuanceUnits(
        ISetToken _setToken,
        uint256 _quantity
    ) external view returns (address[] memory, uint256[] memory, uint256[] memory);
    function getRequiredComponentRedemptionUnits(
        ISetToken _setToken,
        uint256 _quantity
    ) external view returns (address[] memory, uint256[] memory, uint256[] memory);
    function issue(ISetToken _setToken, uint256 _quantity, address _to) external;
    function redeem(ISetToken _token, uint256 _quantity, address _to) external;
    function initialize(
        ISetToken _setToken,
        uint256 _maxManagerFee,
        uint256 _managerIssueFee,
        uint256 _managerRedeemFee,
        address _feeRecipient,
        IManagerIssuanceHook _managerIssuanceHook
    ) external;
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;

import { ISetToken } from "./ISetToken.sol";

interface IManagerIssuanceHook {
    function invokePreIssueHook(ISetToken _setToken, uint256 _issueQuantity, address _sender, address _to) external;
    function invokePreRedeemHook(ISetToken _setToken, uint256 _redeemQuantity, address _sender, address _to) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.10;
import { ISetToken } from "../interfaces/ISetToken.sol";

interface INotionalTradeModule {
    function redeemMaturedPositions(ISetToken) external;
    function initialize(ISetToken) external;
    function updateAllowedSetToken(ISetToken, bool) external;
    function owner() external view returns(address);
    function settleAccount(address) external;
    function setRedeemToUnderlying(ISetToken, bool) external;

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

/// @title Quoter Interface
/// @notice Supports quoting the calculated amounts from exact input or exact output swaps
/// @dev These functions are not marked view because they rely on calling non-view functions and reverting
/// to compute the result. They are also not gas efficient and should not be called on-chain.
interface IQuoter {
    /// @notice Returns the amount out received for a given exact input swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee
    /// @param amountIn The amount of the first token to swap
    /// @return amountOut The amount of the last token that would be received
    function quoteExactInput(bytes memory path, uint256 amountIn) external returns (uint256 amountOut);

    /// @notice Returns the amount out received for a given exact input but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountIn The desired input amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountOut The amount of `tokenOut` that would be received
    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    /// @notice Returns the amount in required for a given exact output swap without executing the swap
    /// @param path The path of the swap, i.e. each token pair and the pool fee. Path must be provided in reverse order
    /// @param amountOut The amount of the last token to receive
    /// @return amountIn The amount of first token required to be paid
    function quoteExactOutput(bytes memory path, uint256 amountOut) external returns (uint256 amountIn);

    /// @notice Returns the amount in required to receive the given exact output amount but for a swap of a single pool
    /// @param tokenIn The token being swapped in
    /// @param tokenOut The token being swapped out
    /// @param fee The fee of the token pool to consider for the pair
    /// @param amountOut The desired output amount
    /// @param sqrtPriceLimitX96 The price limit of the pool that cannot be exceeded by the swap
    /// @return amountIn The amount required as the input for the swap in order to receive `amountOut`
    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: Apache License, Version 2.0
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ISetToken
 * @author Set Protocol
 *
 * Interface for operating with SetTokens.
 */
interface ISetToken is IERC20 {

    /* ============ Enums ============ */

    enum ModuleState {
        NONE,
        PENDING,
        INITIALIZED
    }

    /* ============ Structs ============ */
    /**
     * The base definition of a SetToken Position
     *
     * @param component           Address of token in the Position
     * @param module              If not in default state, the address of associated module
     * @param unit                Each unit is the # of components per 10^18 of a SetToken
     * @param positionState       Position ENUM. Default is 0; External is 1
     * @param data                Arbitrary data
     */
    struct Position {
        address component;
        address module;
        int256 unit;
        uint8 positionState;
        bytes data;
    }

    /**
     * A struct that stores a component's cash position details and external positions
     * This data structure allows O(1) access to a component's cash position units and
     * virtual units.
     *
     * @param virtualUnit               Virtual value of a component's DEFAULT position. Stored as virtual for efficiency
     *                                  updating all units at once via the position multiplier. Virtual units are achieved
     *                                  by dividing a "real" value by the "positionMultiplier"
     * @param componentIndex
     * @param externalPositionModules   List of external modules attached to each external position. Each module
     *                                  maps to an external position
     * @param externalPositions         Mapping of module => ExternalPosition struct for a given component
     */
    struct ComponentPosition {
      int256 virtualUnit;
      address[] externalPositionModules;
      mapping(address => ExternalPosition) externalPositions;
    }

    /**
     * A struct that stores a component's external position details including virtual unit and any
     * auxiliary data.
     *
     * @param virtualUnit       Virtual value of a component's EXTERNAL position.
     * @param data              Arbitrary data
     */
    struct ExternalPosition {
      int256 virtualUnit;
      bytes data;
    }


    /* ============ Functions ============ */

    function addComponent(address _component) external;
    function removeComponent(address _component) external;
    function editDefaultPositionUnit(address _component, int256 _realUnit) external;
    function addExternalPositionModule(address _component, address _positionModule) external;
    function removeExternalPositionModule(address _component, address _positionModule) external;
    function editExternalPositionUnit(address _component, address _positionModule, int256 _realUnit) external;
    function editExternalPositionData(address _component, address _positionModule, bytes calldata _data) external;

    function invoke(address _target, uint256 _value, bytes calldata _data) external returns(bytes memory);

    function editPositionMultiplier(int256 _newMultiplier) external;

    function mint(address _account, uint256 _quantity) external;
    function burn(address _account, uint256 _quantity) external;

    function lock() external;
    function unlock() external;

    function addModule(address _module) external;
    function removeModule(address _module) external;
    function initializeModule() external;

    function setManager(address _manager) external;

    function manager() external view returns (address);
    function moduleStates(address _module) external view returns (ModuleState);
    function getModules() external view returns (address[] memory);

    function getDefaultPositionRealUnit(address _component) external view returns(int256);
    function getExternalPositionRealUnit(address _component, address _positionModule) external view returns(int256);
    function getComponents() external view returns(address[] memory);
    function getExternalPositionModules(address _component) external view returns(address[] memory);
    function getExternalPositionData(address _component, address _positionModule) external view returns(bytes memory);
    function isExternalPositionModule(address _component, address _module) external view returns(bool);
    function isComponent(address _component) external view returns(bool);

    function positionMultiplier() external view returns (int256);
    function getPositions() external view returns (Position[] memory);
    function getTotalComponentRealUnits(address _component) external view returns(int256);

    function isInitializedModule(address _module) external view returns(bool);
    function isPendingModule(address _module) external view returns(bool);
    function isLocked() external view returns (bool);
}

// SPDX-License-Identifier: Apache License, Version 2.0
pragma solidity >=0.6.10;
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.10;
pragma experimental "ABIEncoderV2";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Different types of internal tokens
///  - UnderlyingToken: underlying asset for a cToken (except for Ether)
///  - cToken: Compound interest bearing token
///  - cETH: Special handling for cETH tokens
///  - Ether: the one and only
///  - NonMintable: tokens that do not have an underlying (therefore not cTokens)
enum TokenType {
    UnderlyingToken,
    cToken,
    cETH,
    Ether,
    NonMintable
}

interface IWrappedfCash {
    function initialize(uint16 currencyId, uint40 maturity) external;

    /// @notice Mints wrapped fCash ERC20 tokens
    function mintViaAsset(
        uint256 depositAmountExternal,
        uint88 fCashAmount,
        address receiver,
        uint32 minImpliedRate
    ) external;

    function mintViaUnderlying(
        uint256 depositAmountExternal,
        uint88 fCashAmount,
        address receiver,
        uint32 minImpliedRate
    ) external;

    function redeemToAsset(uint256 amount, address receiver, uint32 maxImpliedRate) external;
    function redeemToUnderlying(uint256 amount, address receiver, uint32 maxImpliedRate) external;

    /// @notice Returns the underlying fCash ID of the token
    function getfCashId() external view returns (uint256);

    /// @notice True if the fCash has matured, assets mature exactly on the block time
    function hasMatured() external view returns (bool);

    /// @notice Returns the components of the fCash idd
    function getDecodedID() external view returns (uint16 currencyId, uint40 maturity);

    /// @notice Returns the current market index for this fCash asset. If this returns
    /// zero that means it is idiosyncratic and cannot be traded.
    function getMarketIndex() external view returns (uint8);

    /// @notice Returns the token and precision of the token that this token settles
    /// to. For example, fUSDC will return the USDC token address and 1e6. The zero
    /// address will represent ETH.
    function getUnderlyingToken() external view returns (IERC20 underlyingToken, int256 underlyingPrecision);

    /// @notice Returns the asset token which the fCash settles to. This will be an interest
    /// bearing token like a cToken or aToken.
    function getAssetToken() external view returns (IERC20 assetToken, int256 assetPrecision, TokenType tokenType);

    function getToken(bool useUnderlying) external view returns (IERC20 token, bool isETH);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);
}


interface IWrappedfCashComplete is IWrappedfCash, IERC20 {}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.10;

interface IWrappedfCashFactory {
    function deployWrapper(uint16 currencyId, uint40 maturity) external returns(address);
    function computeAddress(uint16 currencyId, uint40 maturity) external view returns(address);
}

/*
    Copyright 2022 Index Cooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

// Implementation: https://etherscan.io/address/0x0000000022d53366457f9d5e68ec105046fc4383#readContract
interface ICurveAddressProvider {
    function get_registry() external view returns(address);
    function get_address(uint256 _id) external view returns(address);
}

/*
    Copyright 2022 Index Cooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

// Implementation: https://etherscan.io/address/0xc1DB00a8E5Ef7bfa476395cdbcc98235477cDE4E#readContract
interface ICurveCalculator {
    function get_dx(
        int128 n_coins,
        uint256[8] memory balances,
        uint256 amp,
        uint256 fee,
        uint256[8] memory rates,
        uint256[8] memory precisions,
        bool underlying,
        int128 i,
        int128 j,
        uint256 dy
    ) external view returns(uint256);

    function get_dy(
        int128 n_coins,
        uint256[8] memory balances,
        uint256 amp,
        uint256 fee,
        uint256[8] memory rates,
        uint256[8] memory precisions,
        bool underlying,
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns(uint256);
}

/*
    Copyright 2022 Index Cooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

// Implementation: https://etherscan.io/address/0x8e764bE4288B842791989DB5b8ec067279829809#writeContract
interface ICurvePool {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external payable returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

/*
    Copyright 2022 Index Cooperative

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

// Implementation: https://etherscan.io/address/0x90E00ACe148ca3b23Ac1bC8C240C2a7Dd9c2d7f5#readContract
interface ICurvePoolRegistry {
    // amplification factor
    function get_A(address _pool) external view returns(uint256);
    function get_balances(address _pool) external view returns(uint256[8] memory);
    function get_coins(address _pool) external view returns(address[8] memory);
    function get_coin_indices(address _pool, address _from, address _to) external view returns(int128, int128, bool);
    function get_decimals(address _pool) external view returns(uint256[8] memory);
    function get_n_coins(address _pool) external view returns(uint256[2] memory);
    function get_fees(address _pool) external view returns(uint256[2] memory);
    function get_rates(address _pool) external view returns(uint256[8] memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;


/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInpuSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.6.10;
pragma experimental ABIEncoderV2;

import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
import { SignedSafeMath } from "@openzeppelin/contracts/math/SignedSafeMath.sol";


/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using SafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 constant internal PRECISE_UNIT = 10 ** 18;
    int256 constant internal PRECISE_UNIT_INT = 10 ** 18;

    // Max unsigned integer value
    uint256 constant internal MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 constant internal MAX_INT_256 = type(int256).max;
    int256 constant internal MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }


    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "Cant divide by 0");

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Cant divide by 0");
        require(a != MIN_INT_256 || b != -1, "Invalid input");

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number. 
     * (positive values are rounded towards zero and negative values are rounded away from 0). 
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number. 
     * (positive values are rounded towards zero and negative values are rounded away from 0). 
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
    * @dev Performs the power on a specified value, reverts on overflow.
    */
    function safePower(
        uint256 a,
        uint256 pow
    )
        internal
        pure
        returns (uint256)
    {
        require(a > 0, "Value must be positive");

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++){
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }
}