/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// File: @openzeppelin\contracts\utils\Context.sol

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

// File: @openzeppelin\contracts\access\Ownable.sol

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

// File: @openzeppelin\contracts\math\SafeMath.sol

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

// File: @openzeppelin\contracts\token\ERC20\IERC20.sol

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

// File: @openzeppelin\contracts\utils\Address.sol

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

// File: @openzeppelin\contracts\token\ERC20\SafeERC20.sol

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

// File: contracts\interfaces\IPool.sol

interface IPool {
}

// File: contracts\common\NonReentrancy.sol

contract NonReentrancy {

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, 'Tidal: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }
}

// File: contracts\Pool.sol

contract Pool is IPool, NonReentrancy, Ownable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;
 
    uint256 constant AMOUNT_PER_SHARE = 1e14;
    uint256 constant VOTE_EXPIRATION = 3 days;

    address public baseToken;
    address public tidalToken;

    uint256 public withdrawWaitWeeks1;
    uint256 public withdrawWaitWeeks2;
    uint256 public policyWeeks;
    uint256 public withdrawFee;
    uint256 public claimFee;
    uint256 public managementFee;
    bool public enabled;
    string public name;
    string public terms;

    bool public locked;

    struct Policy {
        uint256 collateralRatio;
        uint256 weeklyPremium;
        string name;
        string terms;
    }

    Policy[] public policyArray;

    // policy index => week => amount
    mapping(uint256 => mapping(uint256 => uint256)) public coveredMap;

    struct PoolInfo {
        // Base token amount
        uint256 totalShare;
        uint256 amountPerShare;

        // Pending withdraw amount
        uint256 pendingWithdrawAmount;

        // Tidal Rewards
        uint256 accTidalPerShare;
    }

    PoolInfo public poolInfo;

    struct UserInfo {
        // Base token amount
        uint256 share;

        // Pending withdraw amount
        uint256 pendingWithdrawAmount;

        // Tidal Rewards
        uint256 tidalPending;
        uint256 tidalDebt;
    }

    mapping(address => UserInfo) public userInfoMap;

    mapping(uint256 => uint256) public poolWithdrawMap;

    struct WithdrawRequest {
        uint256 amount;
        uint256 time;
        bool pending;
        bool executed;
        bool succeeded;
    }

    mapping(address => WithdrawRequest[]) public withdrawRequestMap;

    // policy index => week => Income
    mapping(uint256 => mapping(uint256 => uint256)) public incomeMap;

    struct Coverage {
        uint256 amount;
        uint256 premium;
        bool refunded;
    }

    // policy index => week => who => Coverage
    mapping(uint256 => mapping(uint256 => mapping(
        address => Coverage))) public coverageMap;

    mapping(uint256 => mapping(uint256 => uint256)) public refundMap;

    // Claiming related data.

    struct ClaimRequest {
        uint256 policyIndex;
        uint256 amount;
        address receipient;
        uint256 time;
        uint256 vote;
        bool executed;
    }

    ClaimRequest[] public claimRequestArray;

    function getClaimRequestLength() external view returns(uint256) {
        return claimRequestArray.length;
    }

    function getClaimRequestArray(
        uint256 limit_,
        uint256 offset_
    ) external view returns(ClaimRequest[] memory) {
        if (claimRequestArray.length <= offset_) {
            return new ClaimRequest[](0);
        }

        uint256 leftSideOffset = claimRequestArray.length.sub(offset_);
        ClaimRequest[] memory result = new ClaimRequest[](leftSideOffset < limit_ ? leftSideOffset : limit_);

        uint256 i = 0;
        while (i < limit_ && leftSideOffset > 0) {
            leftSideOffset = leftSideOffset.sub(1);
            result[i] = claimRequestArray[leftSideOffset];
            i = i.add(1);
        }

        return result;
    }

    mapping(address => mapping(uint256 => bool)) committeeVote;

    // Access control.

    address public admin;

    mapping(address => uint256) public committeeIndexPlusOne;
    address[] public committeeArray;
    uint256 public committeeThreshold = 2;

    // Time.

    uint256 public offset = 4 days;
    uint256 public timeExtra;

    function setTimeExtra(uint256 timeExtra_) external {
        timeExtra = timeExtra_;
    }

    function getCurrentWeek() public view returns(uint256) {
        return (now + offset + timeExtra) / (7 days);
    }

    function getNow() public view returns(uint256) {
        return now + timeExtra;
    }

    function getUnlockTime(uint256 time_, uint256 waitWeeks_) public view returns(uint256) {
        require(time_ + offset > (7 days), "Time not large enough");
        return ((time_ + offset) / (7 days) + waitWeeks_) * (7 days) - offset;
    }

    event Buy(
        address indexed who_,
        uint256 indexed policyIndex_,
        uint256 amount_,
        uint256 fromWeek_,
        uint256 toWeek_
    );

    event Deposit(
        address indexed who_,
        uint256 amount_
    );

    event Withdraw(
        address indexed who_,
        uint256 amount_
    );

    constructor(address baseToken_, address tidalToken_) public {
        baseToken = baseToken_;
        tidalToken = tidalToken_;
    }

    modifier onlyAdmin() {
        require(admin == _msgSender(), "Only admin");
        _;
    }

    function setAdmin(address admin_) public onlyOwner {
        admin = admin_;
    }

    modifier onlyCommittee() {
        require(committeeIndexPlusOne[_msgSender()] > 0, "Only committee");
        _;
    }

    function addToCommittee(address who_) external onlyOwner {
        require(committeeIndexPlusOne[who_] == 0, "Existing committee member");
        committeeArray.push(who_);
        committeeIndexPlusOne[who_] = committeeArray.length;
    }

    function removeFromCommittee(address who_) external onlyOwner {
        require(committeeIndexPlusOne[who_] > 0, "Non-existing committee member");
        if (committeeIndexPlusOne[who_] != committeeArray.length) {
            address lastOne = committeeArray[committeeArray.length.sub(1)];
            committeeIndexPlusOne[lastOne] = committeeIndexPlusOne[who_];
            committeeArray[committeeIndexPlusOne[who_].sub(1)] = lastOne;
            committeeIndexPlusOne[who_] = 0;
        }

        committeeArray.pop();
    }

    function setCommitteeThreshold(uint256 threshold_) external onlyOwner {
        committeeThreshold = threshold_;
    }

    function getPool() external view returns(
        uint256 withdrawWaitWeeks1_,
        uint256 withdrawWaitWeeks2_,
        uint256 policyWeeks_,
        uint256 withdrawFee_,
        uint256 claimFee_,
        uint256 managementFee_,
        bool enabled_,
        string memory name_,
        string memory terms_
    ) {
        withdrawWaitWeeks1_ = withdrawWaitWeeks1;
        withdrawWaitWeeks2_ = withdrawWaitWeeks2;
        policyWeeks_ = policyWeeks;
        withdrawFee_ = withdrawFee;
        claimFee_ = claimFee;
        managementFee_ = managementFee;
        enabled_ = enabled;
        name_ = name;
        terms_ = terms;
    }

    function setPool(
        uint256 withdrawWaitWeeks1_,
        uint256 withdrawWaitWeeks2_,
        uint256 policyWeeks_,
        uint256 withdrawFee_,
        uint256 claimFee_,
        uint256 managementFee_,
        bool enabled_,
        string calldata name_,
        string calldata terms_
    ) external onlyAdmin {
        withdrawWaitWeeks1 = withdrawWaitWeeks1_;
        withdrawWaitWeeks2 = withdrawWaitWeeks2_;
        policyWeeks = policyWeeks_;
        withdrawFee = withdrawFee_;
        claimFee = claimFee_;
        managementFee = managementFee_;
        enabled = enabled_;
        name = name_;
        terms = terms_;
    }

    function setPolicy(
        uint256 index_,
        uint256 collateralRatio_,
        uint256 weeklyPremium_,
        string calldata name_,
        string calldata terms_
    ) external onlyAdmin {
        Policy storage policy = policyArray[index_];
        policy.collateralRatio = collateralRatio_;
        policy.weeklyPremium = weeklyPremium_;
        policy.name = name_;
        policy.terms = terms_;
    }

    function addPolicy(
        uint256 collateralRatio_,
        uint256 weeklyPremium_,
        string calldata name_,
        string calldata terms_
    ) external onlyAdmin {
        policyArray.push(Policy({
            collateralRatio: collateralRatio_,
            weeklyPremium: weeklyPremium_,
            name: name_,
            terms: terms_
        }));
    }

    function getPolicyArrayLength() external view returns(uint256) {
        return policyArray.length;
    }

    function getCollateralAmount() external view returns(uint256) {
        return poolInfo.amountPerShare.mul(
            poolInfo.totalShare).sub(poolInfo.pendingWithdrawAmount);
    }

    function getAvailableCapacity(
        uint256 policyIndex_,
        uint256 w_
    ) public view returns(uint256) {
        uint256 currentWeek = getNow().div(1 weeks);
        uint256 amount = 0;
        uint256 w;

        if (w_ >= currentWeek.add(withdrawWaitWeeks1) || w_ < currentWeek) {
            return 0;
        } else {
            amount = poolInfo.amountPerShare.mul(poolInfo.totalShare).sub(poolInfo.pendingWithdrawAmount);

            for (w = currentWeek.sub(withdrawWaitWeeks1); w < w_.sub(withdrawWaitWeeks1); ++w) {
                amount = amount.sub(poolWithdrawMap[w]);
            }

            Policy storage policy = policyArray[policyIndex_];
            return amount.mul(1e6).div(policy.collateralRatio).sub(coveredMap[policyIndex_][w_]);
        }
    }

    function getCurrentAvailableCapacity(
        uint256 policyIndex_
    ) external view returns(uint256) {
        uint256 w = getNow().div(1 weeks);
        return getAvailableCapacity(policyIndex_, w);
    }

    function getTotalAvailableCapacity() external view returns(uint256) {
        uint256 w = getNow().div(1 weeks);

        uint256 total = 0;
        for (uint256 i = 0; i < policyArray.length; ++i) {
            total += getAvailableCapacity(i, w);
        }

        return total;
    }

    function getUserBaseAmount(address who_) external view returns(uint256) {
        UserInfo storage userInfo = userInfoMap[who_];
        return poolInfo.amountPerShare.mul(userInfo.share);
    }

    function buy(
        uint256 policyIndex_,
        uint256 amount_,
        uint256 fromWeek_,
        uint256 toWeek_
    ) external {
        require(enabled && !locked, "Not enabled or unlocked");

        require(toWeek_ > fromWeek_, "Not enough weeks");
        require(toWeek_.sub(fromWeek_) <= policyWeeks,
            "Too many weeks");
        require(fromWeek_ > getNow().div(1 weeks), "Buy next week");

        Policy storage policy = policyArray[policyIndex_];
        uint256 premium = amount_.mul(policy.weeklyPremium).div(1e6);
        uint256 allPremium = premium.mul(toWeek_.sub(fromWeek_));

        uint256 maximumToCover = poolInfo.amountPerShare.mul(
            poolInfo.totalShare).sub(poolInfo.pendingWithdrawAmount).mul(
                1e6).div(policy.collateralRatio);

        for (uint256 w = fromWeek_; w < toWeek_; ++w) {
            incomeMap[policyIndex_][w] =
                incomeMap[policyIndex_][w].add(premium);
            coveredMap[policyIndex_][w] =
                coveredMap[policyIndex_][w].add(amount_);

            require(coveredMap[policyIndex_][w] <= maximumToCover,
                "Not enough to buy");

            coverageMap[policyIndex_][w][_msgSender()] = Coverage({
                amount: amount_,
                premium: premium,
                refunded: false
            });
        }

        IERC20(baseToken).safeTransferFrom(
            _msgSender(), address(this), allPremium);

        emit Buy(
			_msgSender(),
		    policyIndex_,
		    amount_,
		    fromWeek_,
		    toWeek_
	    );
    }

    function refund(uint256 policyIndex_, uint256 week_, address who_) external {
        Coverage storage coverage = coverageMap[policyIndex_][week_][who_];

        require(!coverage.refunded, "Already refunded");

        uint256 allCovered = coveredMap[policyIndex_][week_];
        uint256 amountToRefund = refundMap[policyIndex_][week_].mul(
            coverage.amount).div(allCovered);
        coverage.amount = coverage.amount.mul(
            coverage.premium.sub(amountToRefund)).div(coverage.premium);
        coverage.refunded = true;

        IERC20(baseToken).safeTransfer(who_, amountToRefund);
    }

    // Anyone just call this function once per week for every policy.
    function addPremium(uint256 policyIndex_) external {
        require(enabled && !locked, "Not enabled or unlocked");

        uint256 week = getNow().div(1 weeks);

        Policy storage policy = policyArray[policyIndex_];

        uint256 maximumToCover = poolInfo.amountPerShare.mul(
            poolInfo.totalShare).sub(poolInfo.pendingWithdrawAmount).mul(
                1e6).div(policy.collateralRatio);

        uint256 allCovered = coveredMap[policyIndex_][week];
        if (allCovered > maximumToCover) {
            refundMap[policyIndex_][week] = incomeMap[policyIndex_][week].mul(
                allCovered.sub(maximumToCover)).div(allCovered);
            incomeMap[policyIndex_][week] = incomeMap[policyIndex_][week].sub(
                refundMap[policyIndex_][week]);
        }

        poolInfo.amountPerShare = poolInfo.amountPerShare.add(
            incomeMap[policyIndex_][week].div(poolInfo.totalShare));
        incomeMap[policyIndex_][week] = 0;
    }

    function deposit(
        uint256 amount_
    ) external {
        require(enabled && !locked, "Not enabled or unlocked");

        require(amount_ >= AMOUNT_PER_SHARE * 10000, "Less than minimum");

        IERC20(baseToken).safeTransferFrom(
            _msgSender(), address(this), amount_);

        _updateUserTidal(_msgSender());

        UserInfo storage userInfo = userInfoMap[_msgSender()];

        if (poolInfo.totalShare == 0) {          
            poolInfo.amountPerShare = AMOUNT_PER_SHARE;
            poolInfo.totalShare = amount_.div(AMOUNT_PER_SHARE);
            userInfo.share = poolInfo.totalShare;
        } else {
            uint256 shareToAdd = amount_.div(poolInfo.amountPerShare);
            poolInfo.totalShare = poolInfo.totalShare.add(shareToAdd);
            userInfo.share = userInfo.share.add(shareToAdd);
        }

		emit Deposit(_msgSender(), amount_);
    }

    function getUserAvailableWithdrawAmount(
        address who_
    ) external view returns(uint256) {
        UserInfo storage userInfo = userInfoMap[who_];
        uint256 userBaseAmount = poolInfo.amountPerShare.mul(userInfo.share);
        return userBaseAmount.sub(
                userInfo.pendingWithdrawAmount);
    }

    function withdraw(
        uint256 amount_
    ) external {
        require(enabled && !locked, "Not enabled or unlocked");

        UserInfo storage userInfo = userInfoMap[_msgSender()];
        uint256 userBaseAmount = poolInfo.amountPerShare.mul(userInfo.share);
        require(userBaseAmount >=
            userInfo.pendingWithdrawAmount.add(amount_), "Not enough");

        withdrawRequestMap[_msgSender()].push(WithdrawRequest({
            amount: amount_,
            time: getNow(),
            pending: false,
            executed: false,
            succeeded: false
        }));

        userInfo.pendingWithdrawAmount = userInfo.pendingWithdrawAmount.add(
            amount_);

        uint256 week = getNow().div(1 weeks);
        poolWithdrawMap[week] = poolWithdrawMap[week].add(amount_);

        emit Withdraw(_msgSender(), amount_);
    }

    // Called after withdrawWaitWeeks1
    function withdrawPending(
        address who_,
        uint256 index_
    ) external {
        require(enabled && !locked, "Not enabled or unlocked");

        require(index_ < withdrawRequestMap[who_].length, "No index");

        WithdrawRequest storage request = withdrawRequestMap[who_][index_];
        require(!request.pending, "Already pending");

        uint256 unlockTime = getUnlockTime(request.time, withdrawWaitWeeks1);
        require(getNow() > unlockTime, "Not ready yet");

        poolInfo.pendingWithdrawAmount = poolInfo.pendingWithdrawAmount.add(
            request.amount);

        uint256 week = request.time.div(1 weeks);
        poolWithdrawMap[week] = poolWithdrawMap[week].sub(request.amount);

        request.pending = true;
    }

    // Called after withdrawWaitWeeks2
    function withdrawReady(
        address who_,
        uint256 index_
    ) external {
        require(enabled && !locked, "Not enabled or unlocked");

        require(index_ < withdrawRequestMap[who_].length, "No index");

        WithdrawRequest storage request = withdrawRequestMap[who_][index_];
        require(!request.executed, "Already executed");
        require(request.pending, "Not pending yet");

        uint256 waitWeeks = withdrawWaitWeeks1.add(withdrawWaitWeeks2);
        uint256 unlockTime = getUnlockTime(request.time, waitWeeks);
        require(getNow() > unlockTime, "Not ready yet");

        UserInfo storage userInfo = userInfoMap[_msgSender()];
        if (poolInfo.amountPerShare.mul(userInfo.share) >= request.amount) {
            _updateUserTidal(who_);

            userInfo.share = poolInfo.amountPerShare.mul(
                userInfo.share).sub(request.amount).div(
                    poolInfo.amountPerShare);
            poolInfo.totalShare = poolInfo.amountPerShare.mul(
                poolInfo.totalShare).sub(request.amount).div(
                    poolInfo.amountPerShare);

            IERC20(baseToken).safeTransfer(
                who_, request.amount);

            request.succeeded = true;
        } else {
            request.succeeded = false;
        }

        request.executed = true;

        // Reduce pendingWithdrawAmount.
        userInfo.pendingWithdrawAmount = userInfo.pendingWithdrawAmount.sub(
            request.amount);
        poolInfo.pendingWithdrawAmount = poolInfo.pendingWithdrawAmount.sub(
            request.amount);
    }

    function withdrawRequestCount(
        address who_
    ) external view returns(uint256) {
        return withdrawRequestMap[who_].length;
    }

    // Anyone can add tidal to the pool as incentative any time.
    function addTidal(uint256 amount_) external {
        IERC20(tidalToken).safeTransferFrom(
            _msgSender(), address(this), amount_);

        poolInfo.accTidalPerShare = poolInfo.accTidalPerShare.add(
            amount_).div(poolInfo.totalShare);
    }

    function _updateUserTidal(address who_) private {
        UserInfo storage userInfo = userInfoMap[who_];
        uint256 accAmount = poolInfo.accTidalPerShare.add(userInfo.share);
        userInfo.tidalPending = userInfo.tidalPending.add(
            accAmount.sub(userInfo.tidalDebt));
        userInfo.tidalDebt = accAmount;
    }

    function getUserTidalAmount(address who_) external view returns(uint256) {
        UserInfo storage userInfo = userInfoMap[who_];
        return poolInfo.accTidalPerShare.mul(
            userInfo.share).add(userInfo.tidalPending).sub(userInfo.tidalDebt);
    }

    function withdrawTidal() external {
        require(enabled && !locked, "Not enabled or unlocked");

        UserInfo storage userInfo = userInfoMap[_msgSender()];
        uint256 accAmount = poolInfo.accTidalPerShare.add(userInfo.share);
        uint256 tidalAmount = userInfo.tidalPending.add(
            accAmount).sub(userInfo.tidalDebt);

        IERC20(tidalToken).safeTransfer(_msgSender(), tidalAmount);

        userInfo.tidalPending = 0;
        userInfo.tidalDebt = accAmount;
    }

    function lockPool() external onlyAdmin {
        locked = true;
    }

    function unlockPool() external onlyAdmin {
        locked = false;
    }

    function claim(
        uint256 policyIndex_,
        uint256 amount_,
        address receipient_
    ) external onlyAdmin {
        claimRequestArray.push(ClaimRequest({
            policyIndex: policyIndex_,
            amount: amount_,
            receipient: receipient_,
            time: getNow(),
            vote: 0,
            executed: false
        }));
    }

    function vote(
        uint256 claimIndex_,
        bool support_
    ) external onlyCommittee {
        if (!support_) {
            return;
        }

        require(claimIndex_ < claimRequestArray.length, "Invalid index");

        require(!committeeVote[_msgSender()][claimIndex_],
                "Already supported");
        committeeVote[_msgSender()][claimIndex_] = true;

        ClaimRequest storage cr = claimRequestArray[claimIndex_];

        require(getNow() < cr.time.add(VOTE_EXPIRATION),
                "Already expired");
        require(!cr.executed, "Already executed");
        cr.vote = cr.vote.add(1);
    }

    function execute(uint256 claimIndex_) external {
        require(claimIndex_ < claimRequestArray.length, "Invalid index");

        ClaimRequest storage cr = claimRequestArray[claimIndex_];

        require(cr.vote >= committeeThreshold, "Not enough votes");
        require(getNow() < cr.time.add(VOTE_EXPIRATION),
                "Already expired");
        cr.executed = true;

        IERC20(baseToken).safeTransfer(cr.receipient, cr.amount);

        poolInfo.amountPerShare = poolInfo.amountPerShare.sub(
            cr.amount.div(poolInfo.totalShare));
    }
}