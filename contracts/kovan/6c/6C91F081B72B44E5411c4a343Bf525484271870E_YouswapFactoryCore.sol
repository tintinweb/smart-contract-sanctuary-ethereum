/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

// File: @openzeppelin/contracts/math/SafeMath.sol


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol


pragma solidity >=0.6.0 <0.8.0;




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

// File: contracts/interface/IYouswapInviteV1.sol


pragma solidity 0.7.4;

interface IYouswapInviteV1 {

    struct UserInfo {
        address upper;//??????
        address[] lowers;//??????
        uint256 startBlock;//????????????
    }

    event InviteV1(address indexed owner, address indexed upper, uint256 indexed height);//?????????????????????????????????????????????????????????

    function inviteCount() external view returns (uint256);//????????????

    function inviteUpper1(address) external view returns (address);//????????????

    function inviteUpper2(address) external view returns (address, address);//????????????

    function inviteLower1(address) external view returns (address[] memory);//????????????

    function inviteLower2(address) external view returns (address[] memory, address[] memory);//????????????

    function inviteLower2Count(address) external view returns (uint256, uint256);//????????????
    
    function register() external returns (bool);//??????????????????

    function acceptInvitation(address) external returns (bool);//??????????????????
    
    // function inviteBatch(address[] memory) external returns (uint, uint);//????????????????????????????????????????????????
}

// File: contracts/utils/constant.sol


pragma solidity 0.7.4;

library ErrorCode {

    string constant FORBIDDEN = 'YouSwap:FORBIDDEN';
    string constant IDENTICAL_ADDRESSES = 'YouSwap:IDENTICAL_ADDRESSES';
    string constant ZERO_ADDRESS = 'YouSwap:ZERO_ADDRESS';
    string constant INVALID_ADDRESSES = 'YouSwap:INVALID_ADDRESSES';
    string constant BALANCE_INSUFFICIENT = 'YouSwap:BALANCE_INSUFFICIENT';
    string constant REWARDTOTAL_LESS_THAN_REWARDPROVIDE = 'YouSwap:REWARDTOTAL_LESS_THAN_REWARDPROVIDE';
    string constant PARAMETER_TOO_LONG = 'YouSwap:PARAMETER_TOO_LONG';
    string constant REGISTERED = 'YouSwap:REGISTERED';
    string constant MINING_NOT_STARTED = 'YouSwap:MINING_NOT_STARTED';
    string constant END_OF_MINING = 'YouSwap:END_OF_MINING';
    string constant POOL_NOT_EXIST_OR_END_OF_MINING = 'YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING';
    
}

library DefaultSettings {
    uint256 constant BENEFIT_RATE_MIN = 0; // 0% ????????????????????????, 10: 0.1%, 100: 1%, 1000: 10%, 10000: 100%
    uint256 constant BENEFIT_RATE_MAX = 10000; //100% ????????????????????????
    uint256 constant TEN_THOUSAND = 10000; //100% ????????????????????????
    uint256 constant EACH_FACTORY_POOL_MAX = 10000; //????????????????????????????????????
    uint256 constant CHANGE_RATE_MAX = 30; //??????????????????????????????????????????30%
    uint256 constant DAY_INTERVAL_MIN = 7; //????????????????????????????????????
    uint256 constant SECONDS_PER_DAY = 86400; //????????????
    uint256 constant REWARD_TOKENTYPE_MAX = 10; //????????????????????????
}

// File: contracts/implement/YouswapInviteV1.sol


pragma solidity 0.7.4;



contract YouswapInviteV1 is IYouswapInviteV1 {
    address public constant ZERO = address(0);
    uint256 public startBlock;
    address[] public inviteUserInfoV1;
    mapping(address => UserInfo) public inviteUserInfoV2;

    constructor() {
        startBlock = block.number;
    }

    function inviteCount() external view override returns (uint256) {
        return inviteUserInfoV1.length;
    }

    function inviteUpper1(address _owner) external view override returns (address) {
        return inviteUserInfoV2[_owner].upper;
    }

    function inviteUpper2(address _owner) external view override returns (address, address) {
        address upper1 = inviteUserInfoV2[_owner].upper;
        address upper2 = address(0);
        if (address(0) != upper1) {
            upper2 = inviteUserInfoV2[upper1].upper;
        }

        return (upper1, upper2);
    }

    function inviteLower1(address _owner) external view override returns (address[] memory) {
        return inviteUserInfoV2[_owner].lowers;
    }

    function inviteLower2(address _owner) external view override returns (address[] memory, address[] memory) {
        address[] memory lowers1 = inviteUserInfoV2[_owner].lowers;
        uint256 count = 0;
        uint256 lowers1Len = lowers1.length;
        for (uint256 i = 0; i < lowers1Len; i++) {
            count += inviteUserInfoV2[lowers1[i]].lowers.length;
        }
        address[] memory lowers;
        address[] memory lowers2 = new address[](count);
        count = 0;
        for (uint256 i = 0; i < lowers1Len; i++) {
            lowers = inviteUserInfoV2[lowers1[i]].lowers;
            for (uint256 j = 0; j < lowers.length; j++) {
                lowers2[count] = lowers[j];
                count++;
            }
        }

        return (lowers1, lowers2);
    }

    function inviteLower2Count(address _owner) external view override returns (uint256, uint256) {
        address[] memory lowers1 = inviteUserInfoV2[_owner].lowers;
        uint256 lowers2Len = 0;
        uint256 len = lowers1.length;
        for (uint256 i = 0; i < len; i++) {
            lowers2Len += inviteUserInfoV2[lowers1[i]].lowers.length;
        }

        return (lowers1.length, lowers2Len);
    }

    function register() external override returns (bool) {
        UserInfo storage user = inviteUserInfoV2[tx.origin];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        user.upper = ZERO;
        user.startBlock = block.number;
        inviteUserInfoV1.push(tx.origin);

        emit InviteV1(tx.origin, user.upper, user.startBlock);

        return true;
    }

    function acceptInvitation(address _inviter) external override returns (bool) {
        require(msg.sender != _inviter, ErrorCode.FORBIDDEN);
        UserInfo storage user = inviteUserInfoV2[msg.sender];
        require(0 == user.startBlock, ErrorCode.REGISTERED);
        UserInfo storage upper = inviteUserInfoV2[_inviter];
        if (0 == upper.startBlock) {
            upper.upper = ZERO;
            upper.startBlock = block.number;
            inviteUserInfoV1.push(_inviter);

            emit InviteV1(_inviter, upper.upper, upper.startBlock);
        }
        user.upper = _inviter;
        upper.lowers.push(msg.sender);
        user.startBlock = block.number;
        inviteUserInfoV1.push(msg.sender);

        emit InviteV1(msg.sender, user.upper, user.startBlock);

        return true;
    }

    // function inviteBatch(address[] memory _invitees) external override returns (uint256, uint256) {
    //     uint256 len = _invitees.length;
    //     require(len <= 100, ErrorCode.PARAMETER_TOO_LONG);
    //     UserInfo storage user = inviteUserInfoV2[msg.sender];
    //     if (0 == user.startBlock) {
    //         user.upper = ZERO;
    //         user.startBlock = block.number;
    //         inviteUserInfoV1.push(msg.sender);

    //         emit InviteV1(msg.sender, user.upper, user.startBlock);
    //     }
    //     uint256 count = 0;
    //     for (uint256 i = 0; i < len; i++) {
    //         if ((address(0) != _invitees[i]) && (msg.sender != _invitees[i])) {
    //             UserInfo storage lower = inviteUserInfoV2[_invitees[i]];
    //             if (0 == lower.startBlock) {
    //                 lower.upper = msg.sender;
    //                 lower.startBlock = block.number;
    //                 user.lowers.push(_invitees[i]);
    //                 inviteUserInfoV1.push(_invitees[i]);
    //                 count++;

    //                 emit InviteV1(_invitees[i], msg.sender, lower.startBlock);
    //             }
    //         }
    //     }

    //     return (len, count);
    // }
}

// File: contracts/interface/ITokenYou.sol


pragma solidity 0.7.4;

interface ITokenYou {
    
    function mint(address recipient, uint256 amount) external;
    
    function decimals() external view returns (uint8);
    
}

// File: contracts/interface/IYouswapFactory.sol


pragma solidity 0.7.4;
pragma experimental ABIEncoderV2;


interface BaseStruct {

    /** ?????????????????? */
     enum PoolLockType {
        SINGLE_TOKEN, //????????????
        LP_TOKEN, //lp??????
        SINGLE_TOKEN_FIXED, //??????????????????
        LP_TOKEN_FIXED //lp????????????
    }

    /** ????????????????????? */
    struct PoolViewInfo {
        address token; //token????????????
        string name; //??????????????????
        uint256 multiple; //????????????
        uint256 priority; //??????
    }

    /** ?????????????????? */
    struct PoolStakeInfo {
        uint256 startBlock; //??????????????????
        uint256 startTime; //??????????????????
        bool enableInvite; //????????????????????????
        address token; //token????????????????????????lp????????????
        uint256 amount; //???????????????????????????TVL
        uint256 participantCounts; //????????????????????????
        PoolLockType poolType; //???????????????lp????????????????????????lp??????
        uint256 lockSeconds; //??????????????????
        uint256 lockUntil; //?????????????????????????????????
        uint256 lastRewardBlock; //????????????????????????
        uint256 totalPower; //?????????
        uint256 powerRatio; //???????????????????????????????????????????????????
        uint256 maxStakeAmount; //??????????????????
        uint256 endBlock; //??????????????????
        uint256 endTime; //??????????????????
        uint256 selfReward; //???????????????
        uint256 invite1Reward; //1???????????????
        uint256 invite2Reward; //2???????????????
        bool isReopen; //?????????????????????
    }

    /** ?????????????????? */
    struct PoolRewardInfo {
        address token; //??????????????????:A/B/C
        uint256 rewardTotal; //???????????????
        uint256 rewardPerBlock; //??????????????????
        uint256 rewardProvide; //?????????????????????
        uint256 rewardPerShare; //??????????????????
    }

    /** ?????????????????? */
    struct UserStakeInfo {
        uint256 startBlock; //??????????????????
        uint256 amount; //????????????
        uint256 invitePower; //????????????
        uint256 stakePower; //????????????
        uint256[] invitePendingRewards; //???????????????
        uint256[] stakePendingRewards; //???????????????
        uint256[] inviteRewardDebts; //????????????
        uint256[] stakeRewardDebts; //????????????
        uint256[] inviteClaimedRewards; //?????????????????????
        uint256[] stakeClaimedRewards; //?????????????????????
    }
}

////////////////////////////////// ??????Core?????? //////////////////////////////////////////////////
interface IYouswapFactoryCore is BaseStruct {
    function initialize(address _owner, address _platform, address _invite) external;

    function getPoolRewardInfo(uint256 poolId) external view returns (PoolRewardInfo[] memory);

    function getUserStakeInfo(uint256 poolId, address user) external view returns (UserStakeInfo memory);

    function getPoolStakeInfo(uint256 poolId) external view returns (PoolStakeInfo memory);

    function getPoolViewInfo(uint256 poolId) external view returns (PoolViewInfo memory);

    function stake(uint256 poolId, uint256 amount, address user) external;

    function _unStake(uint256 poolId, uint256 amount, address user) external;

    function _withdrawReward(uint256 poolId, address user) external;

    function getPoolIds() external view returns (uint256[] memory);

    function addPool(
        uint256 prePoolId,
        uint256 range,
        string memory name,
        address token,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external;

    /** 
    ?????????????????????
    */
    function setRewardTotal(uint256 poolId, address token, uint256 rewardTotal) external;

    /**
    ????????????????????????
     */
    function setRewardPerBlock(uint256 poolId, address token, uint256 rewardPerBlock) external;

    /**
    ?????????????????????????????? 
    */
    function setWithdrawAllowed(uint256 _poolId, bool _allowedState) external;

    /**
    ??????????????????
     */
    function setName(uint256 poolId, string memory name) external;

    /**
    ??????????????????
     */
    function setMultiple(uint256 poolId, uint256 multiple) external;

    /**
    ??????????????????
     */
    function setPriority(uint256 poolId, uint256 priority) external;

    /**
    ?????????????????????????????????
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external;

    /**
    ??????ID???????????????
     */
    function checkPIDValidation(uint256 poolId) external view;

    /**
    ??????????????????????????????????????????
     */
    function refresh(uint256 _poolId) external;

    /** ????????????token */
    function safeWithdraw(address token, address to, uint256 amount) external;
}

////////////////////////////////// ?????????????????? //////////////////////////////////////////////////
interface IYouswapFactory is BaseStruct {
    /**
    ??????OWNER
     */
    function transferOwnership(address owner) external;

    /**
    ??????
    */
    function stake(uint256 poolId, uint256 amount) external;

    /**
    ????????????????????????
     */
    function unStake(uint256 poolId, uint256 amount) external;

    /**
    ??????????????????????????????
     */
    function unStakes(uint256[] memory _poolIds) external;

    /**
    ????????????
     */
    function withdrawReward(uint256 poolId) external;

    /**
    ????????????????????????????????????
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external;

    /**
    ??????????????????
     */
    function pendingRewardV3(uint256 poolId, address user) external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    ??????ID
     */
    function poolIds() external view returns (uint256[] memory);

    /**
    ??????????????????
     */
    function stakeRange(uint256 poolId) external view returns (uint256, uint256);

    /**
    ??????RewardPerBlock??????????????????
     */
    function setChangeRPBRateMax(uint256 _rateMax) external;

    /** 
    ?????????????????????????????? 
    */
    function setChangeRPBIntervalMin(uint256 _interval) external;

    /*
    ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
    */
    function getPoolStakeDetail(uint256 poolId) external view returns (string memory, address, bool, uint256, uint256, uint256, uint256, uint256, uint256, uint256);

    /**
    ?????????????????? 
    */
    function getUserStakeInfo(uint256 poolId, address user) external view returns (uint256, uint256, uint256, uint256);

    /**
    ?????????????????? 
    */
    function getUserRewardInfo(uint256 poolId, address user, uint256 index) external view returns ( uint256, uint256, uint256, uint256);

    /**
    ???????????????????????? 
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory);

    /**
    ?????????????????? 
    */
    function getPoolRewardInfo(uint poolId) external view returns (PoolRewardInfo[] memory);

    /**
    ????????????APR 
    */
    function addRewardThroughAPR(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals, uint256[] memory addRewardPerBlocks) external;
    
    /**
    ???????????????????????? 
    */
    function addRewardThroughTime(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals) external;

    /** 
    ?????????????????? 
    */
    function setOperateOwner(address user, bool state) external;

    /** 
    ???????????? 
    */
    function addPool(
        uint256 prePoolId,
        uint256 range,
        string memory name,
        address token,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external;

    /**
    ????????????????????????
     */
    function updateRewardPerBlock(uint256 poolId, bool increaseFlag, uint256 percent) external;

    /**
    ?????????????????????????????????
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external;
}

// File: contracts/implement/YouswapFactoryCore.sol


pragma solidity 0.7.4;

// import "hardhat/console.sol";




contract YouswapFactoryCore is IYouswapFactoryCore {
    /**
    ?????????
    self???Sender??????
     */
    event InviteRegister(address indexed self);

    /**
    ??????????????????

    action???true(????????????)???false(????????????)
    factory???factory??????
    poolId?????????ID
    name???????????????
    token?????????token????????????
    startBlock???????????????????????????
    tokens???????????????token????????????
    rewardTotal????????????????????????
    rewardPerBlock?????????????????????
    enableInvite???????????????????????????
    poolBasicInfos: uint256[] ???????????????
        multiple?????????????????????
        priority???????????????
        powerRatio??????????????????????????????=??????????????????
        maxStakeAmount?????????????????????
        poolType???????????????(???????????????): 0,1,2,3
        lockSeconds?????????????????????: 60s
        selfReward????????????????????????: 5
        invite1Reward?????????1???????????????: 15
        invite2Reward?????????2???????????????: 10
     */
    event UpdatePool(
        bool action,
        address factory,
        uint256 poolId,
        string name,
        address indexed token,
        uint256 startBlock,
        address[] tokens,
        uint256[] _rewardTotals,
        uint256[] rewardPerBlocks,
        bool enableInvite,
        uint256[] poolBasicInfos
    );

    /**
    ??????????????????
    
    factory???factory??????
    poolId?????????ID
     */
    event EndPool(address factory, uint256 poolId);

    /**
    ??????

    factory???factory??????
    poolId?????????ID
    token???token????????????
    from?????????????????????
    amount???????????????
     */
    event Stake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed from,
        uint256 amount
    );

    /**
    ??????

    factory???factory??????
    poolId?????????ID
    token???token????????????
    totalPower??????????????????
    owner???????????????
    ownerInvitePower?????????????????????
    ownerStakePower?????????????????????
    upper1??????1?????????
    upper1InvitePower??????1???????????????
    upper2??????2?????????
    upper2InvitePower??????2???????????????
     */
    event UpdatePower(
        address factory,
        uint256 poolId,
        address token,
        uint256 totalPower,
        address indexed owner,
        uint256 ownerInvitePower,
        uint256 ownerStakePower,
        address indexed upper1,
        uint256 upper1InvitePower,
        address indexed upper2,
        uint256 upper2InvitePower
    );

    /**
    ?????????
    
    factory???factory??????
    poolId?????????ID
    token???token????????????
    to????????????????????????
    amount??????????????????
     */
    event UnStake(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 amount
    );

    /**
    ????????????

    factory???factory??????
    poolId?????????ID
    token???token????????????
    to?????????????????????
    inviteAmount???????????????
    stakeAmount???????????????
    benefitAmount: ????????????
     */
    event WithdrawReward(
        address factory,
        uint256 poolId,
        address indexed token,
        address indexed to,
        uint256 inviteAmount,
        uint256 stakeAmount,
        uint256 benefitAmount
    );

    /**
    ??????

    factory???factory??????
    poolId?????????ID
    token???token????????????
    amount???????????????
     */
    event Mint(address factory, uint256 poolId, address indexed token, uint256 amount);

    /**
    ??????????????????????????????0?????????
    factory???factory??????
    poolId?????????ID
    rewardTokens?????????????????????
    rewardPerShares?????????????????????????????????
     */
    event RewardPerShareEvent(address factory, uint256 poolId, address[] indexed rewardTokens, uint256[] rewardPerShares);

    /**
    ????????????????????????
    token?????????token????????????
    to???????????????
    amount?????????token??????
     */
    event SafeWithdraw(address indexed token, address indexed to, uint256 amount);

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool initialized;
    address internal constant ZERO = address(0);
    address public owner; //????????????
    YouswapInviteV1 public invite; // contract

    uint256 poolCount; //????????????
    uint256[] poolIds; //??????ID
    address internal platform; //?????????addPool??????
    mapping(uint256 => PoolViewInfo) internal poolViewInfos; //????????????????????????poolID->PoolViewInfo
    mapping(uint256 => PoolStakeInfo) internal poolStakeInfos; //?????????????????????poolID->PoolStakeInfo
    mapping(uint256 => PoolRewardInfo[]) internal poolRewardInfos; //?????????????????????poolID->PoolRewardInfo[]
    mapping(uint256 => mapping(address => UserStakeInfo)) internal userStakeInfos; //?????????????????????poolID->user-UserStakeInfo

    mapping(address => uint256) public tokenPendingRewards; //??????token???????????????token-amount
    mapping(address => mapping(address => uint256)) internal userReceiveRewards; //????????????????????????token->user->amount
    mapping(uint256 => bool) public withdrawAllowed; //?????????????????????????????????default: false
    // mapping(uint256 => mapping(address => uint256)) public platformBenefits; //??????????????????

    //??????owner??????
    modifier onlyOwner() {
        require(owner == msg.sender, "YouSwapCore:FORBIDDEN_NOT_OWNER");
        _;
    }

    //??????platform??????
    modifier onlyPlatform() {
        require(platform == msg.sender, "YouSwap:FORBIDFORBIDDEN_NOT_PLATFORM");
        _;
    }

    /**
    @notice clone YouswapFactoryCore?????????
    @param _owner YouSwapFactory??????
    @param _platform FactoryCreator??????
    @param _invite clone????????????
    */
    function initialize(address _owner, address _platform, address _invite) external override {
        require(!initialized,  "YouSwapCore:ALREADY_INITIALIZED!");
        initialized = true;
        // deployBlock = block.number;
        owner = _owner;
        platform = _platform;
        invite = YouswapInviteV1(_invite);
    }

    /** ???????????????????????? */
    function getPoolRewardInfo(uint256 poolId) external view override returns (PoolRewardInfo[] memory) {
        return poolRewardInfos[poolId];
    }

    /** ???????????????????????? */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (UserStakeInfo memory) {
        return userStakeInfos[poolId][user];
    }

    /** ?????????????????? */
    function getPoolStakeInfo(uint256 poolId) external view override returns (PoolStakeInfo memory) {
        return poolStakeInfos[poolId];
    }

    /** ???????????????????????? */
    function getPoolViewInfo(uint256 poolId) external view override returns (PoolViewInfo memory) {
        return poolViewInfos[poolId];
    }

    /** ?????? */
    function stake(uint256 poolId, uint256 amount, address user) external onlyOwner override {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.stakePower) {
            poolStakeInfo.participantCounts = poolStakeInfo.participantCounts.add(1);
        }

        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (, uint256 startBlock) = invite.inviteUserInfoV2(user); //sender????????????????????????
            if (0 == startBlock) {
                invite.register(); //sender??????????????????
                emit InviteRegister(user);
            }
            (upper1, upper2) = invite.inviteUpper2(user); //?????????2???????????????
        }

        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //????????????????????????
        provideReward(poolId, rewardPerShares, user, upper1, upper2); //???sender??????????????????upper1???upper2?????????????????????

        addPower(poolId, user, amount, poolStakeInfo.powerRatio, upper1, upper2); //??????sender???upper1???upper2??????
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //??????sender???upper1???upper2??????
        emit Stake(owner, poolId, poolStakeInfo.token, user, amount);
    }

    /** ??????ID */
    function getPoolIds() external view override returns (uint256[] memory) {
        return poolIds;
    }

    ////////////////////////////////////////////////////////////////////////////////////

    struct addPoolLocalVars {
        uint256 prePoolId;
        uint256 range;
        uint256 poolId;
        // bool action;
        uint256 startBlock;
        string name;
        bool enableInvite;
        address token;
        uint256 poolType;
        uint256 powerRatio;
        uint256 startTimeDelay;
        uint256 startTime;
        uint256 currentTime;
        uint256 priority;
        uint256 maxStakeAmount;
        uint256 lockSeconds;
        uint256 multiple;
        uint256 selfReward;
        uint256 invite1Reward;
        uint256 invite2Reward;
        bool isReopen;
    }

    /**
    ????????????(prePoolId ???0) 
    ????????????(prePoolId ???0)
     */
    function addPool(
        uint256 prePoolId,
        uint256 range,
        string memory name,
        address token,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external override onlyOwner {
        addPoolLocalVars memory vars;
        vars.currentTime = block.timestamp;
        vars.prePoolId = prePoolId;
        vars.range = range;
        vars.name = name;
        vars.token = token;
        vars.enableInvite = enableInvite;
        vars.poolType = poolParams[0];
        vars.powerRatio = poolParams[1];
        vars.startTimeDelay = poolParams[2];
        vars.startTime = vars.startTimeDelay.add(vars.currentTime);
        vars.priority = poolParams[3];
        vars.maxStakeAmount = poolParams[4];
        vars.lockSeconds = poolParams[5];
        vars.multiple = poolParams[6];
        vars.selfReward = poolParams[7];
        vars.invite1Reward = poolParams[8];
        vars.invite2Reward = poolParams[9];

        if (vars.startTime <= vars.currentTime) { //?????????????????????
            vars.startTime  = vars.currentTime;
            vars.startBlock = block.number;
        } else { //?????????????????????
            vars.startBlock =  block.number.add(vars.startTimeDelay.div(3)); //???????????????????????????: heco: 3s???eth???13s
        }

        if (vars.prePoolId != 0) { //????????????
            vars.poolId = vars.prePoolId;
            vars.isReopen = true;
        } else { //????????????
            vars.poolId = poolCount.add(vars.range); //???1w??????
            poolIds.push(vars.poolId); //????????????ID
            poolCount = poolCount.add(1); //???????????????
            vars.isReopen = false;
        }

        PoolViewInfo storage poolViewInfo = poolViewInfos[vars.poolId]; //?????????????????????
        poolViewInfo.token = vars.token; //????????????token
        poolViewInfo.name = vars.name; //????????????
        poolViewInfo.multiple = vars.multiple; //????????????
        if (0 < vars.priority) {
            poolViewInfo.priority = vars.priority; //???????????????
        } else {
            poolViewInfo.priority = poolIds.length.mul(100).add(75); //??????????????? //TODO
        }

        /********** ???????????????????????? *********/
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[vars.poolId];
        poolStakeInfo.startBlock = vars.startBlock; //????????????
        poolStakeInfo.startTime = vars.startTime; //????????????
        poolStakeInfo.enableInvite = vars.enableInvite; //????????????????????????
        poolStakeInfo.token = vars.token; //????????????token
        // poolStakeInfo.amount; //?????????????????????????????????!!!
        // poolStakeInfo.participantCounts; //???????????????????????????????????????!!!
        poolStakeInfo.poolType = BaseStruct.PoolLockType(vars.poolType); //????????????
        poolStakeInfo.lockSeconds = vars.lockSeconds; //??????????????????
        poolStakeInfo.lockUntil = vars.startTime.add(vars.lockSeconds); //??????????????????
        poolStakeInfo.lastRewardBlock = vars.startBlock - 1;
        // poolStakeInfo.totalPower = 0; //??????????????????????????????!!!
        poolStakeInfo.powerRatio = vars.powerRatio; //???????????????????????????
        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount; //??????????????????
        poolStakeInfo.endBlock = 0; //??????????????????
        poolStakeInfo.endTime = 0; //??????????????????
        poolStakeInfo.selfReward = vars.selfReward; //???????????????
        poolStakeInfo.invite1Reward = vars.invite1Reward; //1???????????????
        poolStakeInfo.invite2Reward = vars.invite2Reward; //2???????????????
        poolStakeInfo.isReopen = vars.isReopen; //?????????????????????
        uint256 minRewardPerBlock = uint256(0) - uint256(1); //??????????????????

        bool existFlag;
        PoolRewardInfo[] storage _poolRewardInfosStorage = poolRewardInfos[vars.poolId];//?????????????????????
        PoolRewardInfo[] memory _poolRewardInfosMemory = poolRewardInfos[vars.poolId]; //?????????????????????

        for (uint256 i = 0; i < tokens.length; i++) {
            existFlag = false;
            tokenPendingRewards[tokens[i]] = tokenPendingRewards[tokens[i]].add(rewardTotals[i]);
            require(IERC20(tokens[i]).balanceOf(address(this)) >= tokenPendingRewards[tokens[i]], "YouSwapCore:BALANCE_INSUFFICIENT"); //????????????????????????

            //????????????????????????????????????
            for (uint256 j = 0; j < _poolRewardInfosMemory.length; j++) {
                if (tokens[i] == _poolRewardInfosMemory[j].token) {
                    existFlag = true;
                    _poolRewardInfosStorage[j].rewardTotal = rewardTotals[i];
                    _poolRewardInfosStorage[j].rewardPerBlock = rewardPerBlocks[i];
                    _poolRewardInfosMemory[j].rewardPerBlock = rewardPerBlocks[i]; //????????????????????????
                    _poolRewardInfosStorage[j].rewardProvide = 0; //?????????????????????
                    // _poolRewardInfosStorage[j].rewardPerShare; //????????????!!!
                }

                if (minRewardPerBlock > _poolRewardInfosMemory[j].rewardPerBlock) {
                    minRewardPerBlock = _poolRewardInfosMemory[j].rewardPerBlock;
                    poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
                    if (vars.maxStakeAmount < poolStakeInfo.maxStakeAmount) {
                        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount;
                    }
                }
            }

            //??????????????????????????????
            if (!existFlag) {
                PoolRewardInfo memory poolRewardInfo; //??????????????????
                poolRewardInfo.token = tokens[i]; //??????token
                poolRewardInfo.rewardTotal = rewardTotals[i]; //?????????
                poolRewardInfo.rewardPerBlock = rewardPerBlocks[i]; //???????????????????????????????????????????????????
                // poolRewardInfo.rewardProvide //????????????
                // poolRewardInfo.rewardPerShare //????????????
                poolRewardInfos[vars.poolId].push(poolRewardInfo);

                if (minRewardPerBlock > poolRewardInfo.rewardPerBlock) {
                    minRewardPerBlock = poolRewardInfo.rewardPerBlock;
                    poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
                    if (vars.maxStakeAmount < poolStakeInfo.maxStakeAmount) {
                        poolStakeInfo.maxStakeAmount = vars.maxStakeAmount;
                    }
                }
            }
        }

        require(_poolRewardInfosStorage.length <= DefaultSettings.REWARD_TOKENTYPE_MAX, "YouSwap:REWARD_TOKEN_TYPE_REACH_MAX");
        sendUpdatePoolEvent(true, vars.poolId);
    }

    /**?????????????????????????????? */
    function setWithdrawAllowed(uint256 _poolId, bool _allowedState) external override onlyPlatform {
        withdrawAllowed[_poolId] = _allowedState;        
        sendUpdatePoolEvent(false, _poolId);//????????????????????????
    }

    /**
    ??????????????????
     */
    function setName(uint256 poolId, string memory name) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//??????????????????
        poolViewInfo.name = name;//??????????????????
        sendUpdatePoolEvent(false, poolId);//????????????????????????
    }

    /** ?????????????????? */
    function setMultiple(uint256 poolId, uint256 multiple) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//??????????????????
        poolViewInfo.multiple = multiple;//??????????????????
        sendUpdatePoolEvent(false, poolId);//????????????????????????
    }

    /** ?????????????????? */
    function setPriority(uint256 poolId, uint256 priority) external override onlyPlatform {
        PoolViewInfo storage poolViewInfo = poolViewInfos[poolId];
        require(ZERO != poolViewInfo.token, "YouSwap:POOL_NOT_EXIST_OR_END_OF_MINING");//??????????????????
        poolViewInfo.priority = priority;//??????????????????
        sendUpdatePoolEvent(false, poolId);//????????????????????????
    }

    /**
    ????????????????????????
     */
    function setRewardPerBlock(
        uint256 poolId,
        address token,
        uint256 rewardPerBlock
    ) external override onlyOwner {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        bool existFlag;
        // computeReward(poolId); //????????????????????????
        uint256 minRewardPerBlock = uint256(0) - uint256(1); //??????????????????

        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            if (_poolRewardInfos[i].token == token) {
                _poolRewardInfos[i].rewardPerBlock = rewardPerBlock; //????????????????????????
                sendUpdatePoolEvent(false, poolId); //????????????????????????
                existFlag = true;
            } 
            if (minRewardPerBlock > _poolRewardInfos[i].rewardPerBlock) {
                minRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
                poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }

        if (!existFlag) {
            // ??????????????????
            PoolRewardInfo memory poolRewardInfo; //??????????????????
            poolRewardInfo.token = token; //??????token
            poolRewardInfo.rewardPerBlock = rewardPerBlock; //????????????
            _poolRewardInfos.push(poolRewardInfo);
            sendUpdatePoolEvent(false, poolId); //????????????????????????

            if (minRewardPerBlock > rewardPerBlock) {
                minRewardPerBlock = rewardPerBlock;
                poolStakeInfo.maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }
    }

    /** ?????????????????????: ????????????????????????????????????(rewardTotal???rewardPerBlock???????????????????????????) */
    function setRewardTotal(
        uint256 poolId,
        address token,
        uint256 rewardTotal
    ) external override onlyOwner {
        // computeReward(poolId);//????????????????????????
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        bool existFlag = false;

        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (_poolRewardInfos[i].token == token) {
                existFlag = true;
                require(_poolRewardInfos[i].rewardProvide <= rewardTotal, "YouSwapCore:REWARDTOTAL_LESS_THAN_REWARDPROVIDE");//???????????????????????????????????????
                tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal.sub(_poolRewardInfos[i].rewardTotal));//?????????????????????????????????????????????????????????
                _poolRewardInfos[i].rewardTotal = rewardTotal;//?????????????????????
            } 
        }

        if (!existFlag) {
            //?????????
            tokenPendingRewards[token] = tokenPendingRewards[token].add(rewardTotal);
            PoolRewardInfo memory newPoolRewardInfo;
            newPoolRewardInfo.token = token;
            newPoolRewardInfo.rewardProvide = 0;
            newPoolRewardInfo.rewardPerShare = 0;
            newPoolRewardInfo.rewardTotal = rewardTotal;
            _poolRewardInfos.push(newPoolRewardInfo);
        }

        require(_poolRewardInfos.length <= DefaultSettings.REWARD_TOKENTYPE_MAX, "YouSwap:REWARD_TOKEN_TYPE_REACH_MAX");
        require(IERC20(token).balanceOf(address(this)) >= tokenPendingRewards[token], "YouSwapCore:BALANCE_INSUFFICIENT");//????????????????????????
        sendUpdatePoolEvent(false, poolId);//????????????????????????
    }

    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external override onlyOwner {
        uint256 _maxStakeAmount;
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        uint256 minRewardPerBlock = uint256(0) - uint256(1);//??????????????????

        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        for(uint i = 0; i < _poolRewardInfos.length; i++) {
            if (minRewardPerBlock > _poolRewardInfos[i].rewardPerBlock) {
                minRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
                _maxStakeAmount = minRewardPerBlock.mul(1e24).mul(poolStakeInfo.powerRatio).div(13);
            }
        }
        require(poolStakeInfo.powerRatio <= maxStakeAmount && poolStakeInfo.amount <= maxStakeAmount && maxStakeAmount <= _maxStakeAmount, "YouSwapCore:MAX_STAKE_AMOUNT_INVALID");
        poolStakeInfo.maxStakeAmount = maxStakeAmount;
        sendUpdatePoolEvent(false, poolId);//????????????????????????
    }

    ////////////////////////////////////////////////////////////////////////////////////
    /** ???????????????????????? */
    function computeReward(uint256 poolId) internal returns (uint256[] memory) {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo[] storage _poolRewardInfos = poolRewardInfos[poolId];
        uint256[] memory rewardPerShares = new uint256[](_poolRewardInfos.length);
        address[] memory rewardTokens = new address[](_poolRewardInfos.length);
        bool rewardPerShareZero;

        if (0 < poolStakeInfo.totalPower) {
            uint256 finishRewardCount;
            uint256 reward;
            uint256 blockCount;
            bool poolFinished;

            //???????????????????????????????????????
            if (block.number < poolStakeInfo.lastRewardBlock) {
                poolFinished = true;
            } else {
                blockCount = block.number.sub(poolStakeInfo.lastRewardBlock); //????????????????????????
            }
            for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
                PoolRewardInfo storage poolRewardInfo = _poolRewardInfos[i]; //??????????????????
                reward = blockCount.mul(poolRewardInfo.rewardPerBlock); //???????????????????????????

                if (poolRewardInfo.rewardProvide.add(reward) >= poolRewardInfo.rewardTotal) {
                    reward = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide); //??????????????????
                    finishRewardCount = finishRewardCount.add(1); //????????????token??????
                }
                poolRewardInfo.rewardProvide = poolRewardInfo.rewardProvide.add(reward); //???????????????????????????  
                poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(reward.mul(1e24).div(poolStakeInfo.totalPower)); //????????????????????????
                if (0 == poolRewardInfo.rewardPerShare) {
                    rewardPerShareZero = true;
                }
                rewardPerShares[i] = poolRewardInfo.rewardPerShare;
                rewardTokens[i] = poolRewardInfo.token;
                if (0 < reward) {
                    emit Mint(owner, poolId, poolRewardInfo.token, reward); //????????????
                }
            }

            if (!poolFinished) {
                poolStakeInfo.lastRewardBlock = block.number; //??????????????????
            }

            if (finishRewardCount == _poolRewardInfos.length && !poolFinished) {
                poolStakeInfo.endBlock = block.number; //??????????????????
                poolStakeInfo.endTime = block.timestamp; //????????????
                emit EndPool(owner, poolId); //??????????????????
            }
        } else {
            //??????????????????
            for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
                rewardPerShares[i] = _poolRewardInfos[i].rewardPerShare;
            }
        }

        if (rewardPerShareZero) {
            emit RewardPerShareEvent(owner, poolId, rewardTokens, rewardPerShares);
        }
        return rewardPerShares;
    }    

    /** ???????????? */
    function addPower(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 powerRatio,
        address upper1,
        address upper2
    ) internal {
        uint256 power = amount.div(powerRatio);
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId]; //??????????????????
        poolStakeInfo.amount = poolStakeInfo.amount.add(amount); //????????????????????????
        poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(power); //?????????????????????
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user]; //sender????????????
        userStakeInfo.amount = userStakeInfo.amount.add(amount); //??????sender????????????
        userStakeInfo.stakePower = userStakeInfo.stakePower.add(power); //??????sender????????????
        if (0 == userStakeInfo.startBlock) {
            userStakeInfo.startBlock = block.number; //??????????????????
        }
        uint256 upper1InvitePower = 0; //upper1????????????
        uint256 upper2InvitePower = 0; //upper2????????????
        if (ZERO != upper1) {
            uint256 inviteSelfPower = power.mul(poolStakeInfo.selfReward).div(100); //??????sender???????????????
            userStakeInfo.invitePower = userStakeInfo.invitePower.add(inviteSelfPower); //??????sender????????????
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(inviteSelfPower); //?????????????????????
            uint256 invite1Power = power.mul(poolStakeInfo.invite1Reward).div(100); //??????upper1????????????
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1]; //upper1????????????
            upper1StakeInfo.invitePower = upper1StakeInfo.invitePower.add(invite1Power); //??????upper1????????????
            upper1InvitePower = upper1StakeInfo.invitePower;
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(invite1Power); //?????????????????????
            if (0 == upper1StakeInfo.startBlock) {
                upper1StakeInfo.startBlock = block.number; //??????????????????
            }
        }
        if (ZERO != upper2) {
            uint256 invite2Power = power.mul(poolStakeInfo.invite2Reward).div(100); //??????upper2????????????
            UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2]; //upper2????????????
            upper2StakeInfo.invitePower = upper2StakeInfo.invitePower.add(invite2Power); //??????upper2????????????
            upper2InvitePower = upper2StakeInfo.invitePower;
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.add(invite2Power); //?????????????????????
            if (0 == upper2StakeInfo.startBlock) {
                upper2StakeInfo.startBlock = block.number; //??????????????????
            }
        }
        emit UpdatePower(owner, poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.invitePower, userStakeInfo.stakePower, upper1, upper1InvitePower, upper2, upper2InvitePower); //??????????????????
    }

    /** ???????????? */
    function subPower(
        uint256 poolId,
        address user,
        uint256 amount,
        uint256 powerRatio,
        address upper1,
        address upper2
    ) internal {
        uint256 power = amount.div(powerRatio);
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId]; //??????????????????
        if (poolStakeInfo.amount <= amount) {
            poolStakeInfo.amount = 0; //???????????????????????????
        } else {
            poolStakeInfo.amount = poolStakeInfo.amount.sub(amount); //???????????????????????????
        }
        if (poolStakeInfo.totalPower <= power) {
            poolStakeInfo.totalPower = 0; //?????????????????????
        } else {
            poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(power); //?????????????????????
        }
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user]; //sender????????????
        userStakeInfo.amount = userStakeInfo.amount.sub(amount); //??????sender????????????
        if (userStakeInfo.stakePower <= power) {
            userStakeInfo.stakePower = 0; //??????sender????????????
        } else {
            userStakeInfo.stakePower = userStakeInfo.stakePower.sub(power); //??????sender????????????
        }
        uint256 upper1InvitePower = 0;
        uint256 upper2InvitePower = 0;
        if (ZERO != upper1) {
            uint256 inviteSelfPower = power.mul(poolStakeInfo.selfReward).div(100); //sender???????????????
            if (poolStakeInfo.totalPower <= inviteSelfPower) {
                poolStakeInfo.totalPower = 0; //????????????sender???????????????
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(inviteSelfPower); //????????????sender???????????????
            }
            if (userStakeInfo.invitePower <= inviteSelfPower) {
                userStakeInfo.invitePower = 0; //??????sender???????????????
            } else {
                userStakeInfo.invitePower = userStakeInfo.invitePower.sub(inviteSelfPower); //??????sender???????????????
            }
            uint256 invite1Power = power.mul(poolStakeInfo.invite1Reward).div(100); //upper1????????????
            if (poolStakeInfo.totalPower <= invite1Power) {
                poolStakeInfo.totalPower = 0; //????????????upper1????????????
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(invite1Power); //????????????upper1????????????
            }
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
            if (upper1StakeInfo.invitePower <= invite1Power) {
                upper1StakeInfo.invitePower = 0; //??????upper1????????????
            } else {
                upper1StakeInfo.invitePower = upper1StakeInfo.invitePower.sub(invite1Power); //??????upper1????????????
            }
            upper1InvitePower = upper1StakeInfo.invitePower;
        }
        if (ZERO != upper2) {
            uint256 invite2Power = power.mul(poolStakeInfo.invite2Reward).div(100); //upper2????????????
            if (poolStakeInfo.totalPower <= invite2Power) {
                poolStakeInfo.totalPower = 0; //????????????upper2????????????
            } else {
                poolStakeInfo.totalPower = poolStakeInfo.totalPower.sub(invite2Power); //????????????upper2????????????
            }
            UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
            if (upper2StakeInfo.invitePower <= invite2Power) {
                upper2StakeInfo.invitePower = 0; //??????upper2????????????
            } else {
                upper2StakeInfo.invitePower = upper2StakeInfo.invitePower.sub(invite2Power); //??????upper2????????????
            }
            upper2InvitePower = upper2StakeInfo.invitePower;
        }
        emit UpdatePower(owner, poolId, poolStakeInfo.token, poolStakeInfo.totalPower, user, userStakeInfo.invitePower, userStakeInfo.stakePower, upper1, upper1InvitePower, upper2, upper2InvitePower);
    }

    struct baseLocalVars {
        uint256 poolId;
        address user;
        address upper1;
        address upper2;
        uint256 reward;
        uint256 benefitAmount;
        uint256 remainAmount;
        uint256 newBenefit;
    }

    /** ???sender??????????????????upper1???upper2????????????????????? */
    function provideReward(
        uint256 poolId,
        uint256[] memory rewardPerShares,
        address user,
        address upper1,
        address upper2
    ) internal {
        baseLocalVars memory vars;
        vars.poolId = poolId;
        vars.user = user;
        vars.upper1 = upper1;
        vars.upper2 = upper2;
        uint256 inviteReward = 0;
        uint256 stakeReward = 0;
        uint256 rewardPerShare = 0;
        address token;

        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[vars.poolId];
        UserStakeInfo storage userStakeInfo = userStakeInfos[vars.poolId][vars.user];
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[vars.poolId];

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            token = _poolRewardInfos[i].token; //????????????token
            rewardPerShare = rewardPerShares[i]; //????????????????????????

            inviteReward = userStakeInfo.invitePower.mul(rewardPerShare).sub(userStakeInfo.inviteRewardDebts[i]).div(1e24); //????????????
            stakeReward = userStakeInfo.stakePower.mul(rewardPerShare).sub(userStakeInfo.stakeRewardDebts[i]).div(1e24); //????????????

            inviteReward = userStakeInfo.invitePendingRewards[i].add(inviteReward); //???????????????
            stakeReward = userStakeInfo.stakePendingRewards[i].add(stakeReward); //???????????????
            vars.reward = inviteReward.add(stakeReward);

            if (0 < vars.reward) {
                userStakeInfo.invitePendingRewards[i] = 0; //?????????????????????
                userStakeInfo.stakePendingRewards[i] = 0; //?????????????????????
                userReceiveRewards[token][vars.user] = userReceiveRewards[token][vars.user].add(vars.reward); //?????????????????????

                if ((poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED)
                    && (block.timestamp >= poolStakeInfo.startTime && block.timestamp <= poolStakeInfo.lockUntil && !withdrawAllowed[vars.poolId])) {
                        userStakeInfo.invitePendingRewards[i] = inviteReward; //?????????????????????????????????????????????????????????
                        userStakeInfo.stakePendingRewards[i] = stakeReward; //?????????????????????????????????????????????????????????
                } else {
                    userStakeInfo.inviteClaimedRewards[i] = userStakeInfo.inviteClaimedRewards[i].add(inviteReward);
                    userStakeInfo.stakeClaimedRewards[i] = userStakeInfo.stakeClaimedRewards[i].add(stakeReward);
                    tokenPendingRewards[token] = tokenPendingRewards[token].sub(vars.reward); //??????????????????
                    IERC20(token).safeTransfer(vars.user, vars.reward); //????????????
                    emit WithdrawReward(owner, vars.poolId, token, vars.user, inviteReward, stakeReward, 0);
                }
            }

            if (ZERO != vars.upper1) {
                UserStakeInfo storage upper1StakeInfo = userStakeInfos[vars.poolId][vars.upper1];
                if ((0 < upper1StakeInfo.invitePower) || (0 < upper1StakeInfo.stakePower)) {
                    inviteReward = upper1StakeInfo.invitePower.mul(rewardPerShare).sub(upper1StakeInfo.inviteRewardDebts[i]).div(1e24); //????????????
                    stakeReward = upper1StakeInfo.stakePower.mul(rewardPerShare).sub(upper1StakeInfo.stakeRewardDebts[i]).div(1e24); //????????????
                    upper1StakeInfo.invitePendingRewards[i] = upper1StakeInfo.invitePendingRewards[i].add(inviteReward); //???????????????
                    upper1StakeInfo.stakePendingRewards[i] = upper1StakeInfo.stakePendingRewards[i].add(stakeReward); //???????????????
                }
            }
            if (ZERO != vars.upper2) {
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[vars.poolId][vars.upper2];
                if ((0 < upper2StakeInfo.invitePower) || (0 < upper2StakeInfo.stakePower)) {
                    inviteReward = upper2StakeInfo.invitePower.mul(rewardPerShare).sub(upper2StakeInfo.inviteRewardDebts[i]).div(1e24); //????????????
                    stakeReward = upper2StakeInfo.stakePower.mul(rewardPerShare).sub(upper2StakeInfo.stakeRewardDebts[i]).div(1e24); //????????????
                    upper2StakeInfo.invitePendingRewards[i] = upper2StakeInfo.invitePendingRewards[i].add(inviteReward); //???????????????
                    upper2StakeInfo.stakePendingRewards[i] = upper2StakeInfo.stakePendingRewards[i].add(stakeReward); //???????????????
                }
            }
        }
    }

    /** ???????????? */
    function setRewardDebt(
        uint256 poolId,
        uint256[] memory rewardPerShares,
        address user,
        address upper1,
        address upper2
    ) internal {
        uint256 rewardPerShare;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];

        for (uint256 i = 0; i < rewardPerShares.length; i++) {
            rewardPerShare = rewardPerShares[i]; //????????????????????????
            userStakeInfo.inviteRewardDebts[i] = userStakeInfo.invitePower.mul(rewardPerShare); //??????sender????????????
            userStakeInfo.stakeRewardDebts[i] = userStakeInfo.stakePower.mul(rewardPerShare); //??????sender????????????

            if (ZERO != upper1) {
                UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
                upper1StakeInfo.inviteRewardDebts[i] = upper1StakeInfo.invitePower.mul(rewardPerShare); //??????upper1????????????
                upper1StakeInfo.stakeRewardDebts[i] = upper1StakeInfo.stakePower.mul(rewardPerShare); //??????upper1????????????
                if (ZERO != upper2) {
                    UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                    upper2StakeInfo.inviteRewardDebts[i] = upper2StakeInfo.invitePower.mul(rewardPerShare); //??????upper2????????????
                    upper2StakeInfo.stakeRewardDebts[i] = upper2StakeInfo.stakePower.mul(rewardPerShare); //??????upper2????????????
                }
            }
        }
    }

    /** ???????????????????????? */
    function sendUpdatePoolEvent(bool action, uint256 poolId) internal {
        PoolViewInfo memory poolViewInfo = poolViewInfos[poolId];
        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        PoolRewardInfo[] memory _poolRewardInfos = poolRewardInfos[poolId];
        address[] memory tokens = new address[](_poolRewardInfos.length);
        uint256[] memory _rewardTotals = new uint256[](_poolRewardInfos.length);
        uint256[] memory rewardPerBlocks = new uint256[](_poolRewardInfos.length);

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            tokens[i] = _poolRewardInfos[i].token;
            _rewardTotals[i] = _poolRewardInfos[i].rewardTotal;
            rewardPerBlocks[i] = _poolRewardInfos[i].rewardPerBlock;
        }

        uint256[] memory poolBasicInfos = new uint256[](11);
        poolBasicInfos[0] = poolViewInfo.multiple;
        poolBasicInfos[1] = poolViewInfo.priority;
        poolBasicInfos[2] = poolStakeInfo.powerRatio;
        poolBasicInfos[3] = poolStakeInfo.maxStakeAmount;
        poolBasicInfos[4] = uint256(poolStakeInfo.poolType);
        poolBasicInfos[5] = poolStakeInfo.lockSeconds;
        poolBasicInfos[6] = poolStakeInfo.selfReward;
        poolBasicInfos[7] = poolStakeInfo.invite1Reward;
        poolBasicInfos[8] = poolStakeInfo.invite2Reward;
        poolBasicInfos[9] = poolStakeInfo.startTime;
        poolBasicInfos[10] = withdrawAllowed[poolId] ? 1: 0; //????????????????????????

        emit UpdatePool(
            action,
            owner,
            poolId,
            poolViewInfo.name,
            poolStakeInfo.token,
            poolStakeInfo.startBlock,
            tokens,
            _rewardTotals,
            rewardPerBlocks,
            poolStakeInfo.enableInvite,
            poolBasicInfos
        );
    }

    /**
    ?????????
     */
    function _unStake(uint256 poolId, uint256 amount, address user) override onlyOwner external {
        PoolStakeInfo storage poolStakeInfo = poolStakeInfos[poolId];
        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (upper1, upper2) = invite.inviteUpper2(user);
        }
        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //??????????????????????????????
        provideReward(poolId, rewardPerShares, user, upper1, upper2); //???sender??????????????????upper1???upper2?????????????????????
        subPower(poolId, user, amount, poolStakeInfo.powerRatio, upper1, upper2); //????????????

        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 != poolStakeInfo.startBlock && 0 == userStakeInfo.stakePower) {
            poolStakeInfo.participantCounts = poolStakeInfo.participantCounts.sub(1);
        }
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //??????sender???upper1???upper2??????
        IERC20(poolStakeInfo.token).safeTransfer(user, amount); //?????????token
        emit UnStake(owner, poolId, poolStakeInfo.token, user, amount);
    }

    function _withdrawReward(uint256 poolId, address user) override onlyOwner external {
        UserStakeInfo memory userStakeInfo = userStakeInfos[poolId][user];
        if (0 == userStakeInfo.startBlock) {
            return; //user?????????????????????
        }

        PoolStakeInfo memory poolStakeInfo = poolStakeInfos[poolId];
        // if (poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED) { //????????????
        //     if (block.timestamp <= poolStakeInfo.lockUntil && block.timestamp >= poolStakeInfo.startTime) { //?????????????????????????????????????????????????????????
        //         if (!withdrawAllowed[poolId]) {
        //             return;
        //         }
        //     }
        // }

        address upper1;
        address upper2;
        if (poolStakeInfo.enableInvite) {
            (upper1, upper2) = invite.inviteUpper2(user);
        }

        initRewardInfo(poolId, user, upper1, upper2);
        uint256[] memory rewardPerShares = computeReward(poolId); //??????????????????????????????
        provideReward(poolId, rewardPerShares, user, upper1, upper2); //???sender??????????????????upper1???upper2?????????????????????
        setRewardDebt(poolId, rewardPerShares, user, upper1, upper2); //??????sender???upper1???upper2??????
    }

    function initRewardInfo(
        uint256 poolId,
        address user,
        address upper1,
        address upper2
    ) internal {
        uint256 count = poolRewardInfos[poolId].length;
        UserStakeInfo storage userStakeInfo = userStakeInfos[poolId][user];

        if (userStakeInfo.invitePendingRewards.length != count) {
            require(count >= userStakeInfo.invitePendingRewards.length, "YouSwap:INITREWARD_INFO_COUNT_ERROR");
            uint256 offset = count.sub(userStakeInfo.invitePendingRewards.length);
            for (uint256 i = 0; i < offset; i++) {
                userStakeInfo.invitePendingRewards.push(0); //????????????????????????
                userStakeInfo.stakePendingRewards.push(0); //????????????????????????
                userStakeInfo.inviteRewardDebts.push(0); //?????????????????????
                userStakeInfo.stakeRewardDebts.push(0); //?????????????????????
                userStakeInfo.inviteClaimedRewards.push(0); //?????????????????????
                userStakeInfo.stakeClaimedRewards.push(0); //?????????????????????
            }
        }
        if (ZERO != upper1) {
            UserStakeInfo storage upper1StakeInfo = userStakeInfos[poolId][upper1];
            if (upper1StakeInfo.invitePendingRewards.length != count) {
                uint256 offset = count.sub(upper1StakeInfo.invitePendingRewards.length);
                for (uint256 i = 0; i < offset; i++) {
                    upper1StakeInfo.invitePendingRewards.push(0); //????????????????????????
                    upper1StakeInfo.stakePendingRewards.push(0); //????????????????????????
                    upper1StakeInfo.inviteRewardDebts.push(0); //?????????????????????
                    upper1StakeInfo.stakeRewardDebts.push(0); //?????????????????????
                    upper1StakeInfo.inviteClaimedRewards.push(0); //?????????????????????
                    upper1StakeInfo.stakeClaimedRewards.push(0); //?????????????????????
                }
            }
            if (ZERO != upper2) {
                UserStakeInfo storage upper2StakeInfo = userStakeInfos[poolId][upper2];
                if (upper2StakeInfo.invitePendingRewards.length != count) {
                    uint256 offset = count.sub(upper2StakeInfo.invitePendingRewards.length);
                    for (uint256 i = 0; i < offset; i++) {
                        upper2StakeInfo.invitePendingRewards.push(0); //????????????????????????
                        upper2StakeInfo.stakePendingRewards.push(0); //????????????????????????
                        upper2StakeInfo.inviteRewardDebts.push(0); //?????????????????????
                        upper2StakeInfo.stakeRewardDebts.push(0); //?????????????????????
                        upper2StakeInfo.inviteClaimedRewards.push(0); //?????????????????????
                        upper2StakeInfo.stakeClaimedRewards.push(0); //?????????????????????
                    }
                }
            }
        }
    }

    /**????????????id????????? */
    function checkPIDValidation(uint256 _poolId) external view override {
        PoolStakeInfo memory poolStakeInfo = this.getPoolStakeInfo(_poolId);
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINT_NOT_START"); //??????????????????
    }

    /** ?????????????????? */
    function refresh(uint256 _poolId) external override {
        computeReward(_poolId);
    }

    /** ????????????token */
    function safeWithdraw(address token, address to, uint256 amount) override external onlyPlatform {
        require(IERC20(token).balanceOf(address(this)) >= amount, "YouSwap:BALANCE_INSUFFICIENT");
        IERC20(token).safeTransfer(to, amount);//?????????????????????to??????
        emit SafeWithdraw(token, to, amount);
    }
}