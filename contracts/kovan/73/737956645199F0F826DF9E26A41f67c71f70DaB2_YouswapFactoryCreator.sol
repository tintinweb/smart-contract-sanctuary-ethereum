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

// File: contracts/implement/YouswapFactory.sol


pragma solidity 0.7.4;

// import "hardhat/console.sol";




contract YouswapFactory is IYouswapFactory {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    bool initialized;
    address private constant ZERO = address(0);

    address public owner; //????????????
    address internal platform; //?????????addPool??????

    IYouswapFactoryCore public core; //core??????
    mapping(address => bool) public operateOwner; //????????????
    mapping(uint256 => uint256) public lastSetRewardPerBlockTime; //??????????????????????????????????????????poolid->timestamp

    uint256 public changeRewardPerBlockRateMax; //???????????????????????????default: 30%
    uint256 public changeRewardPerBlockIntervalMin; //?????????????????????????????????default: 7 days
    uint256 public benefitRate; //??????????????????

    //??????owner??????
    modifier onlyOwner() {
        require(owner == msg.sender, "YouSwap:FORBIDDEN_NOT_OWNER");
        _;
    }

    //??????platform??????
    modifier onlyPlatform() {
        require(platform == msg.sender, "YouSwap:FORBIDFORBIDDEN_NOT_PLATFORM");
        _;
    }

    //??????????????????
    modifier onlyOperater() {
        require(operateOwner[msg.sender], "YouSwap:FORBIDDEN_NOT_OPERATER");
        _;
    }

    /**
    @notice clone YouSwapFactory?????????
    @param _owner ?????????
    @param _platform FactoryCreator??????
    @param _benefitRate ????????????
    @param _invite ???????????????????????????
    @param _core clone????????????
    */
    function initialize(address _owner, address _platform, uint256 _benefitRate, address _invite, address _core) external {
        require(!initialized,  "YouSwap:ALREADY_INITIALIZED!");
        initialized = true;
        core = IYouswapFactoryCore(_core);
        core.initialize(address(this), _platform, _invite);

        owner = _owner; //owner??????
        platform = _platform; //????????????
        benefitRate = _benefitRate;

        changeRewardPerBlockRateMax = DefaultSettings.CHANGE_RATE_MAX; //???????????????
        changeRewardPerBlockIntervalMin = DefaultSettings.DAY_INTERVAL_MIN;
        _setOperateOwner(_owner, true); 
    }

    /**
     @notice ??????owner??????
     @param oldOwner??????Owner
     @param newOwner??????Owner
     */
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /**
    @notice ?????????????????????????????????
    @param poolId ??????id
    @param isAllowed ??????????????????
     */
    event WithdrawRewardAllowedEvent(uint256 poolId, bool isAllowed);

    /**
    @notice ??????????????????????????????
    @param poolId ??????id
    @param increaseFlag ????????????
    @param percent ????????????
     */
    event UpdateRewardPerBlockEvent(uint256 poolId, bool increaseFlag, uint256 percent);

    /**
    @notice ?????????APR
    @param poolId ??????id
    @param tokens ??????????????????
    @param addRewardTotals ????????????????????????
    @param addRewardPerBlocks ????????????????????????
     */
    event AddRewardThroughAPREvent(uint256 poolId, address[] tokens, uint256[] addRewardTotals, uint256[]addRewardPerBlocks);

    /**
    @notice ?????????APR
    @param poolId ??????id
    @param tokens ??????????????????
    @param addRewardTotals ????????????????????????
     */
    event AddRewardThroughTimeEvent(uint256 poolId, address[] tokens, uint256[] addRewardTotals);

    /**
     @notice ??????OWNER
     @param _owner??????Owner
     */
    function transferOwnership(address _owner) external override onlyOwner {
        require(ZERO != _owner, "YouSwap:INVALID_ADDRESSES");
        emit TransferOwnership(owner, _owner);
        owner = _owner;
    }

    /**
    ??????????????????
     */
    function setOperateOwner(address user, bool state) external override onlyOwner {
        _setOperateOwner(user, state);
    }

    /**
     @notice ??????????????????
     @param user ????????????
     @param state ????????????
     */
    function _setOperateOwner(address user, bool state) internal {
        operateOwner[user] = state; //??????????????????
    }

    ////////////////////////////////////////////////////////////////////////////////////
    /**
    @notice ??????
    @param poolId ????????????
    @param amount ????????????
    */
    function stake(uint256 poolId, uint256 amount) external override {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        // console.log("poolStakeInfo.startTime:", poolStakeInfo.startTime, block.timestamp);
        require((ZERO != poolStakeInfo.token) && (poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_EXIST_OR_MINT_NOT_START"); //??????????????????
        require((poolStakeInfo.powerRatio <= amount) && (poolStakeInfo.amount.add(amount) <= poolStakeInfo.maxStakeAmount), "YouSwap:STAKE_AMOUNT_TOO_SMALL_OR_TOO_LARGE");

        IERC20(poolStakeInfo.token).safeTransferFrom(msg.sender, address(core), amount); //??????sender??????????????????this
        core.stake(poolId, amount, msg.sender);
    }

    /**
    @notice ?????????
    @param poolId ???????????????
    @param amount ???????????????
     */
    function unStake(uint256 poolId, uint256 amount) external override {
        checkOperationValidation(poolId);
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
        require((amount > 0) && (userStakeInfo.amount >= amount), "YouSwap:BALANCE_INSUFFICIENT");
        core._unStake(poolId, amount, msg.sender);
    }

    /**
    @notice ??????????????????????????????
    @param _poolIds ???????????????
     */
    function unStakes(uint256[] memory _poolIds) external override {
        require((0 < _poolIds.length) && (50 >= _poolIds.length), "YouSwap:PARAMETER_ERROR_TOO_SHORT_OR_LONG");
        uint256 amount;
        uint256 poolId;
        BaseStruct.UserStakeInfo memory userStakeInfo;

        for (uint256 i = 0; i < _poolIds.length; i++) {
            poolId = _poolIds[i];
            checkOperationValidation(poolId);
            userStakeInfo = core.getUserStakeInfo(poolId, msg.sender);
            amount = userStakeInfo.amount; //sender???????????????

            if (0 < amount) {
                core._unStake(poolId, amount, msg.sender);
            }
        }
    }

    /**
    @notice ????????????
    @param poolId ??????id
     */
    function withdrawReward(uint256 poolId) public override {
        // core.checkPIDValidation(poolId);
        checkOperationValidation(poolId);
        core._withdrawReward(poolId, msg.sender);
    }

    /**
    ????????????????????????????????????
     */
    function withdrawRewards2(uint256[] memory _poolIds, address user) external onlyPlatform override {
        for (uint256 i = 0; i < _poolIds.length; i++) {
            BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(_poolIds[i]);
            if (poolStakeInfo.startTime > block.timestamp && !poolStakeInfo.isReopen) {
                continue;
            }
            core._withdrawReward(_poolIds[i], user);
        }
    }

    /**
    ?????????&&??????????????????
     */
     function checkOperationValidation(uint256 poolId) internal view {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require((ZERO != poolStakeInfo.token), "YouSwap:POOL_NOT_EXIST"); //??????????????????
        if (!poolStakeInfo.isReopen) {
            require((poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number), "YouSwap:POOL_NOT_START"); //??????????????????
            if (poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED) {
                require(block.timestamp >= poolStakeInfo.lockUntil, "YouSwap:POOL_NONE_REOPEN_LOCKED_DENIED!");
            }
        } else {
            //??????
            if ((poolStakeInfo.startTime <= block.timestamp) && (poolStakeInfo.startBlock <= block.number)) {
                if (poolStakeInfo.poolType == PoolLockType.SINGLE_TOKEN_FIXED || poolStakeInfo.poolType == PoolLockType.LP_TOKEN_FIXED) {
                    require(block.timestamp >= poolStakeInfo.lockUntil, "YouSwap:POOL_REOPEN_LOCKED_DENIED!");
                }
            }
        }
     }

    struct PendingLocalVars {
        uint256 poolId;
        address user;
        uint256 inviteReward;
        uint256 stakeReward;
        uint256 rewardPre;
    }

    /**
    ??????????????????: tokens???invite??????????????????????????????invite???????????????????????????
     */
    function pendingRewardV3(uint256 poolId, address user) external view override returns (
                            address[] memory tokens, 
                            uint256[] memory invitePendingRewardsRet, 
                            uint256[] memory stakePendingRewardsRet, 
                            uint256[] memory inviteClaimedRewardsRet, 
                            uint256[] memory stakeClaimedRewardsRet) {
        PendingLocalVars memory vars;
        vars.poolId = poolId;
        vars.user = user;
        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(vars.poolId);
        tokens = new address[](_poolRewardInfos.length);
        invitePendingRewardsRet = new uint256[](_poolRewardInfos.length);
        stakePendingRewardsRet = new uint256[](_poolRewardInfos.length);
        inviteClaimedRewardsRet = new uint256[](_poolRewardInfos.length);
        stakeClaimedRewardsRet = new uint256[](_poolRewardInfos.length);

        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(vars.poolId);
        if (ZERO != poolStakeInfo.token) {
            BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(vars.poolId,vars.user);

            uint256 i = userStakeInfo.invitePendingRewards.length;
            for (uint256 j = 0; j < _poolRewardInfos.length; j++) {
                BaseStruct.PoolRewardInfo memory poolRewardInfo = _poolRewardInfos[j];
                // if (poolStakeInfo.startBlock <= block.number && poolStakeInfo.startTime <= block.timestamp) {
                    vars.inviteReward = 0;
                    vars.stakeReward = 0;

                    if (0 < poolStakeInfo.totalPower) {
                        if (block.number > poolStakeInfo.lastRewardBlock) {
                            vars.rewardPre = block.number.sub(poolStakeInfo.lastRewardBlock).mul(poolRewardInfo.rewardPerBlock); //???????????????
                            if (poolRewardInfo.rewardProvide.add(vars.rewardPre) >= poolRewardInfo.rewardTotal) {
                                vars.rewardPre = poolRewardInfo.rewardTotal.sub(poolRewardInfo.rewardProvide); //??????????????????
                            }
                            poolRewardInfo.rewardPerShare = poolRewardInfo.rewardPerShare.add(vars.rewardPre.mul(1e24).div(poolStakeInfo.totalPower)); //????????????????????????????????????
                        }
                    }

                    if (i > j) {
                        //?????????????????????
                        vars.inviteReward = userStakeInfo.invitePendingRewards[j]; //???????????????
                        vars.stakeReward = userStakeInfo.stakePendingRewards[j]; //???????????????
                        vars.inviteReward = vars.inviteReward.add(userStakeInfo.invitePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.inviteRewardDebts[j]).div(1e24)); //????????????????????????
                        vars.stakeReward = vars.stakeReward.add(userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).sub(userStakeInfo.stakeRewardDebts[j]).div(1e24)); //????????????????????????
                        inviteClaimedRewardsRet[j] = userStakeInfo.inviteClaimedRewards[j]; //?????????????????????(??????)
                        stakeClaimedRewardsRet[j] = userStakeInfo.stakeClaimedRewards[j]; //?????????????????????(??????)
                    } else {
                        // ?????????????????????
                        vars.inviteReward = userStakeInfo.invitePower.mul(poolRewardInfo.rewardPerShare).div(1e24); //????????????????????????
                        vars.stakeReward = userStakeInfo.stakePower.mul(poolRewardInfo.rewardPerShare).div(1e24); //????????????????????????
                    }

                    invitePendingRewardsRet[j] = vars.inviteReward;
                    stakePendingRewardsRet[j] = vars.stakeReward;
                // }
                tokens[j] = poolRewardInfo.token;
            }
        }
    }

    /**
    ??????ID
     */
    function poolIds() external view override returns (uint256[] memory poolIDs) {
        poolIDs = core.getPoolIds();
    }

    /**
    ??????????????????
     */
    function stakeRange(uint256 poolId) external view override returns (uint256 powerRatio, uint256 maxStakeAmount) {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        if (ZERO == poolStakeInfo.token) {
            return (0, 0);
        }
        powerRatio = poolStakeInfo.powerRatio;
        maxStakeAmount = poolStakeInfo.maxStakeAmount.sub(poolStakeInfo.amount);
    }

    /*
    ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????
    */
    function getPoolStakeDetail(uint256 poolId) external view override returns (
                        string memory name, 
                        address token, 
                        bool enableInvite, 
                        uint256 stakeAmount, 
                        uint256 participantCounts, 
                        uint256 poolType, 
                        uint256 lockSeconds, 
                        uint256 maxStakeAmount, 
                        uint256 startTime, 
                        uint256 endTime) {
        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        BaseStruct.PoolViewInfo memory poolViewInfo = core.getPoolViewInfo(poolId);

        name = poolViewInfo.name;
        token = poolStakeInfo.token;
        enableInvite = poolStakeInfo.enableInvite;
        stakeAmount = poolStakeInfo.amount;
        participantCounts = poolStakeInfo.participantCounts;
        poolType = uint256(poolStakeInfo.poolType); 
        lockSeconds = poolStakeInfo.lockSeconds;
        maxStakeAmount = poolStakeInfo.maxStakeAmount;
        startTime = poolStakeInfo.startTime;
        endTime = poolStakeInfo.endTime;
    }

    /**?????????????????? */
    function getUserStakeInfo(uint256 poolId, address user) external view override returns (
                        uint256 startBlock, 
                        uint256 stakeAmount, 
                        uint256 invitePower,
                        uint256 stakePower) {
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        startBlock = userStakeInfo.startBlock;
        stakeAmount = userStakeInfo.amount;
        invitePower = userStakeInfo.invitePower;
        stakePower = userStakeInfo.stakePower;
    }

    /*
    ??????????????????
    */
    function getUserRewardInfo(uint256 poolId, address user, uint256 index) external view override returns (
                        uint256 invitePendingReward,
                        uint256 stakePendingReward, 
                        uint256 inviteRewardDebt, 
                        uint256 stakeRewardDebt) {
        BaseStruct.UserStakeInfo memory userStakeInfo = core.getUserStakeInfo(poolId,user);
        invitePendingReward = userStakeInfo.invitePendingRewards[index];
        stakePendingReward = userStakeInfo.stakePendingRewards[index];
        inviteRewardDebt = userStakeInfo.inviteRewardDebts[index];
        stakeRewardDebt = userStakeInfo.stakeRewardDebts[index];
    }

    /**
    ???????????????????????? 
    */
    function getPoolRewardInfo(uint poolId) external view override returns (PoolRewardInfo[] memory) {
        return core.getPoolRewardInfo(poolId);
    }

    /* 
    ?????????????????????????????? 
    */
    function getPoolRewardInfoDetail(uint256 poolId) external view override returns (
                        address[] memory tokens, 
                        uint256[] memory rewardTotals, 
                        uint256[] memory rewardProvides, 
                        uint256[] memory rewardPerBlocks,
                        uint256[] memory rewardPerShares) {
        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(poolId);
        tokens = new address[](_poolRewardInfos.length);
        rewardTotals = new uint256[](_poolRewardInfos.length);
        rewardProvides = new uint256[](_poolRewardInfos.length);
        rewardPerBlocks = new uint256[](_poolRewardInfos.length);
        rewardPerShares = new uint256[](_poolRewardInfos.length);

        BaseStruct.PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        uint256 newRewards;
        uint256 blockCount;
        if(block.number > poolStakeInfo.lastRewardBlock) { //?????????????????????
            blockCount = block.number.sub(poolStakeInfo.lastRewardBlock); //????????????????????????
        }

        for (uint256 i = 0; i < _poolRewardInfos.length; i++) {
            newRewards = blockCount.mul(_poolRewardInfos[i].rewardPerBlock); //???????????????????????????
            tokens[i] = _poolRewardInfos[i].token;
            rewardTotals[i] = _poolRewardInfos[i].rewardTotal;

            if (_poolRewardInfos[i].rewardProvide.add(newRewards) > rewardTotals[i]) {
                rewardProvides[i] = rewardTotals[i];
            } else {
                rewardProvides[i] = _poolRewardInfos[i].rewardProvide.add(newRewards);
            }

            rewardPerBlocks[i] = _poolRewardInfos[i].rewardPerBlock;
            rewardPerShares[i] = _poolRewardInfos[i].rewardPerShare;
        }
    }

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
    ) external override onlyPlatform {
        require((0 < tokens.length) && (DefaultSettings.REWARD_TOKENTYPE_MAX >= tokens.length) && (tokens.length == rewardTotals.length) && (tokens.length == rewardPerBlocks.length), "YouSwap:PARAMETER_ERROR_REWARD");
        require(core.getPoolIds().length < DefaultSettings.EACH_FACTORY_POOL_MAX, "YouSwap:FACTORY_CREATE_MINING_POOL_MAX_REACHED");
        core.addPool(prePoolId, range, name, token, enableInvite, poolParams, tokens, rewardTotals, rewardPerBlocks); 
    }

    /**
    @notice ??????????????????????????????7?????????????????????????????????
    @param poolId ??????ID
    @param increaseFlag ????????????
    @param percent ????????????
     */
    function updateRewardPerBlock(uint256 poolId, bool increaseFlag, uint256 percent) external override onlyOperater {
        require(percent <= changeRewardPerBlockRateMax, "YouSwap:CHANGE_RATE_INPUT_TOO_BIG");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        uint256 lastTime = lastSetRewardPerBlockTime[poolId];
        require(block.timestamp >= lastTime.add(DefaultSettings.SECONDS_PER_DAY.mul(changeRewardPerBlockIntervalMin)), "YouSwap:SET_REWARD_PER_BLOCK_NOT_READY!");
        lastSetRewardPerBlockTime[poolId] = block.timestamp;

        BaseStruct.PoolRewardInfo[] memory _poolRewardInfos = core.getPoolRewardInfo(poolId);
        for (uint i = 0; i < _poolRewardInfos.length; i++) {
            uint256 preRewardPerBlock = _poolRewardInfos[i].rewardPerBlock;
            uint256 newRewardPerBlock;

            if (increaseFlag) {
                newRewardPerBlock = preRewardPerBlock.add(preRewardPerBlock.mul(percent).div(100));
            } else {
                newRewardPerBlock = preRewardPerBlock.sub(preRewardPerBlock.mul(percent).div(100));
            }

            core.setRewardPerBlock(poolId, _poolRewardInfos[i].token, newRewardPerBlock);
        }
        emit UpdateRewardPerBlockEvent(poolId, increaseFlag, percent);
    }

    /** 
    ???????????????????????????????????? 
    */
    function setChangeRPBRateMax(uint256 _rateMax) external override onlyPlatform {
        require(_rateMax <= 100, "YouSwap:SET_CHANGE_REWARD_PER_BLOCK_RATE_MAX_TOO_BIG");
        changeRewardPerBlockRateMax = _rateMax;
    }

    /** 
    ?????????????????????????????? 
    */
    function setChangeRPBIntervalMin(uint256 _interval) external override onlyPlatform {
        changeRewardPerBlockIntervalMin = _interval;
    }

    /**
    ?????????????????????????????????
     */
    function setMaxStakeAmount(uint256 poolId, uint256 maxStakeAmount) external override onlyOperater {
        core.checkPIDValidation(poolId);
        core.setMaxStakeAmount(poolId, maxStakeAmount);
    }

    /** 
    @notice ????????????APR ???????????????1. ???????????? 2. ????????????
    @param poolId uint256, ??????ID
    @param tokens address[] ????????????
    @param addRewardTotals uint256[] ??????????????????total??????????????????
    @param addRewardPerBlocks uint256[] ?????????????????????rewardPerBlock???????????????
    */
    function addRewardThroughAPR(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals, uint256[] memory addRewardPerBlocks) external override onlyOperater {
        require((0 < tokens.length) && (DefaultSettings.REWARD_TOKENTYPE_MAX >= tokens.length) && (tokens.length == addRewardTotals.length) && (tokens.length == addRewardPerBlocks.length), "YouSwap:PARAMETER_ERROR_REWARD");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        BaseStruct.PoolRewardInfo[] memory poolRewardInfos = core.getPoolRewardInfo(poolId);
        uint256 _newRewardTotal;
        uint256 _newRewardPerBlock;
        bool _existFlag;

        uint256[] memory newTotals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ZERO != tokens[i], "YouSwap:INVALID_TOKEN_ADDRESS");
            _newRewardTotal = 0;
            _newRewardPerBlock = 0;
            _existFlag = false;

            uint256 benefitAmount = addRewardTotals[i].div(DefaultSettings.TEN_THOUSAND).mul(benefitRate);
            if (benefitAmount > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(platform), benefitAmount);
            }
            newTotals[i] = addRewardTotals[i].sub(benefitAmount);
            if (newTotals[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(core), newTotals[i]);
            }

            for (uint256 j = 0; j < poolRewardInfos.length; j++) {
                if (tokens[i] == poolRewardInfos[j].token) {
                    _newRewardTotal = poolRewardInfos[j].rewardTotal.add(newTotals[i]);
                    _newRewardPerBlock = poolRewardInfos[j].rewardPerBlock.add(addRewardPerBlocks[i]);
                    _existFlag = true;
                    //break; ?????????break
                }
            }

            if (!_existFlag) {
               _newRewardTotal = newTotals[i];
               _newRewardPerBlock = addRewardPerBlocks[i];
            }

            core.setRewardTotal(poolId, tokens[i], _newRewardTotal);
            core.setRewardPerBlock(poolId, tokens[i], _newRewardPerBlock);
        }
        emit AddRewardThroughAPREvent(poolId, tokens, addRewardTotals, addRewardPerBlocks);
    }

    /** 
    @notice ?????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????????Totals
    @param poolId uint256, ??????ID
    @param tokens address[] ????????????
    @param addRewardTotals uint256[] ???????????????
    */
    function addRewardThroughTime(uint256 poolId, address[] memory tokens, uint256[] memory addRewardTotals) external override onlyOperater {
        require((0 < tokens.length) && (10 >= tokens.length) && (tokens.length == addRewardTotals.length), "YouSwap:PARAMETER_ERROR_REWARD");
        core.checkPIDValidation(poolId);
        core.refresh(poolId);
        PoolStakeInfo memory poolStakeInfo = core.getPoolStakeInfo(poolId);
        require(0 == poolStakeInfo.endBlock, "YouSwapCore:POOL_END_OF_MINING");

        BaseStruct.PoolRewardInfo[] memory poolRewardInfos = core.getPoolRewardInfo(poolId);
        uint256 _newRewardTotal;
        bool _existFlag;

        uint256[] memory newTotals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require(ZERO != tokens[i], "YouSwap:INVALID_TOKEN_ADDRESS");
            require(addRewardTotals[i] > 0, "YouSwap:ADD_REWARD_AMOUNT_SHOULD_GT_ZERO");
            _newRewardTotal = 0;
            _existFlag = false;

            uint256 benefitAmount = addRewardTotals[i].div(DefaultSettings.TEN_THOUSAND).mul(benefitRate);
            if (benefitAmount > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(platform), benefitAmount);
            }
            newTotals[i] = addRewardTotals[i].sub(benefitAmount);
            if (newTotals[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(core), newTotals[i]);
            }

            for (uint256 j = 0; j < poolRewardInfos.length; j++) {
                if (tokens[i] == poolRewardInfos[j].token) {
                    _newRewardTotal = poolRewardInfos[j].rewardTotal.add(newTotals[i]);
                    _existFlag = true;
                    //break; ?????????break
                }
            }

            require(_existFlag, "YouSwap:REWARD_TOKEN_NOT_EXIST");
            core.setRewardTotal(poolId, tokens[i], _newRewardTotal);
        }
        emit AddRewardThroughTimeEvent(poolId, tokens, addRewardTotals);
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

// File: contracts/implement/YouswapFactoryCreator.sol


pragma solidity 0.7.4;


// import "hardhat/console.sol";

contract YouswapFactoryCreator {

    /// @notice ??????????????????: ??????????????????????????????????????????????????????core??????????????? invite??????????????? ?????????????????????
    event YouswapFactoryCreatorEvent(address indexed owner, address indexed factory, address indexed core, bool isVisible);

    /// @notice oldOwner??????Owner??? newOwner??????Owner
    event TransferOwnership(address indexed oldOwner, address indexed newOwner);

    /// @notice clone????????????
    event CloneEvent(address indexed clone);

    /// @notice ???????????????????????????????????????????????????????????????????????????
    event CommissionEvent(address indexed token, uint256 poolCommAmount, uint256 inviteCommAmount, bool state);

    /// @notice ??????factory??????
    event PoolFactoryTemplateEvent(address indexed oldTemplate, address indexed newTemplate);

    /// @notice ??????core??????
    event CoreTemplateEvent(address indexed oldTemplate, address indexed newTemplate);

    /// @notice ??????????????????
    event OperateOwnerEvent(address indexed user, bool state);

    /// @notice ??????????????????
    event FinanceOwnerEvent(address indexed user, bool state);

    /// @notice ????????????
    event withdrawCommissionEvent(address indexed dst);

    /// @notice ??????????????????
    event BenefitRateEvent(uint256 oldBenefitRate, uint256 newBenefitRate);

    /// @notice ????????????????????????
    event ReopenPeriodEvent(uint256 oldReopenPeriod, uint256 newReopenPeriod);

    /// @notice ????????????????????????????????????
    event ChangeRPBRateMaxEvent(address indexed creator, address indexed factory, uint256 rateMax);

    /// @notice ??????????????????????????????
    event ChangeRPBIntervalEvent(address indexed creator, address indexed factory, uint256 interval);

    /// @notice ??????????????????????????????
    event WithdrawAllowedEvent(address indexed creator, uint256 poolId, bool state);

    /// @notice ?????????????????????
    event WhiteListEvent(address indexed superAddr, bool state);

    /// @notice ????????????token
    event SafeWithdrawEvent(address indexed creator, address indexed token, address indexed to, uint256 amount);

    address public admin; // ???????????????
    mapping(address => bool) public operateOwner; //????????????
    mapping(address => bool) public financeOwner; //????????????
    mapping(address => bool) public whiteList; //??????????????????????????????????????????

    struct Commission { //????????????
        uint256 poolCommAmount; //??????????????????
        uint256 inviteCommAmount; //????????????????????????
        bool isSupported; //????????????
    }

    mapping(address => Commission) supportCommissions; //????????????
    address[] supportCommTokenArr; //???????????????Tokens

    ITokenYou public you; //????????????you
    IYouswapInviteV1 public invite; //????????????

    address public poolFactoryTemplate; //factory????????????
    address public coreTemplate; //core????????????

    mapping(address=> address) creatorFactories; //?????????=>????????????
    mapping(address=> address) factoryCore; //????????????=>Core??????
    mapping(address=> uint256) poolIDRange; //?????????-> ??????ID range??????
    uint256 public rangeGlobal; //??????range??????

    address[] internal allFactories; //??????????????????
    address internal constant ZERO = address(0);

    uint256 public benefitRate; //???????????????10: 0.1%, 100: 1%, 1000: 10%, 10000: 100%????????????0)
    uint256 public reopenPeriod = 3; //????????????????????????????????????3???)

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    constructor(ITokenYou _you, IYouswapInviteV1 _invite, uint256 _poolCommAmount, uint256 _inviteCommAmount) {
        you = _you;
        invite = _invite;
        admin = msg.sender;
        _setOperateOwner(admin, true); 
        setSupportCommTokens(address(_you), _poolCommAmount, _inviteCommAmount, true);
    }

    ////////////////////////////////////////////////////////////////////////////////////
    // ??????admin??????
    modifier onlyAdmin() {
        require(admin == msg.sender, "YouSwap:FORBIDDEN_NOT_PLATFORM_ADMIN");
        _;
    }

    // ??????????????????
    modifier onlyOperater() {
        require(operateOwner[msg.sender], "YouSwap:FORBIDDEN_NOT_OPERATER");
        _;
    }

    // ??????????????????
    modifier onlyFinanceOwner() {
        require(financeOwner[msg.sender], "YouSwap:FORBIDDEN_NOT_FINANCE_OWNER");
        _;
    }

    // ??????owner
    function transferOwnership(address _admin) external onlyAdmin {
        require(ZERO != _admin, "YouSwap:INVALID_ADDRESSES");
        emit TransferOwnership(admin, _admin);
        admin = _admin;
    }

    function _setOperateOwner(address user, bool state) internal {
        operateOwner[user] = state; //??????????????????
        emit OperateOwnerEvent(user, state);
    }

    // ??????????????????
    function setOperateOwner(address user, bool state) external onlyAdmin {
        _setOperateOwner(user, state);
    }

    // ??????????????????
    function setFinanceOwner(address user, bool state) external onlyAdmin {
        financeOwner[user] = state;
        emit FinanceOwnerEvent(user, state);
    }

    ////////////////////////////////////////////////////////////////////////////////////

    // ????????????????????? ???clone??????
    function setPoolFactoryTemplate(YouswapFactory _newTemplate) external onlyAdmin {
        require(ZERO != address(_newTemplate), "YouSwap:INVALID_ADDRESSES");
        address oldFactoryTemp = poolFactoryTemplate;
        poolFactoryTemplate = address(_newTemplate);
        emit PoolFactoryTemplateEvent(oldFactoryTemp, poolFactoryTemplate);
    }

    // ??????????????????????????? ???clone??????
    function setCoreTemplate(address _newCore) external onlyAdmin {
        require(ZERO != _newCore, "YouSwap:INVALID_ADDRESSES");
        address oldCoreTemp = coreTemplate;
        coreTemplate = _newCore;
        emit CoreTemplateEvent(oldCoreTemp, _newCore);
    }

    struct FactoryCreatorLocalVars {
        uint256 prePoolId;
        string name;
        address token;
        address commissionToken;
        address pFactory;
        address core;
        uint256 commissionTotal;
        uint256 benefitAmount;
        uint256 newTotal;
    }
    
    /**
        @notice ????????????
        @param prePoolId ?????????Id
        @param name ????????????
        @param token ??????????????????
        @param commissionToken ??????????????????
        @param enableInvite ????????????????????????
        @param poolParams poolType: 0????????????
            powerRatio: 1?????????????????????
            startTimeDelay: 2????????????????????????
            priority: 3?????????
            maxStakeAmount: 4??????????????????
            lockSeconds: 5????????????
            multiple: 6????????????
            selfReward: 7????????????
            uppper1Reward: 8????????????
            upper2Reward: 9????????????
        @param tokens ??????????????????
        @param rewardTotals ????????????????????????
        @param rewardPerBlocks ????????????????????????
    */
    function createPool(
        uint256 prePoolId,
        string memory name,
        address token,
        address commissionToken,
        bool enableInvite,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) public {
        FactoryCreatorLocalVars memory vars;
        vars.prePoolId = prePoolId;
        vars.name = name;
        vars.token = token;
        vars.commissionToken = commissionToken;
        Commission memory commTmp = supportCommissions[vars.commissionToken];
        require(commTmp.isSupported, "YouSwap:COMMISSION_TOKEN_NOT_SUPPORTED");

        require(poolParams[0] < 4, "YouSwap:INVALID_POOL_TYPE"); //poolType
        require(poolParams[1] > 0, "YouSwap:POWERRATIO_MUST_GREATER_THAN_ZERO"); //powerRatio
        require(poolParams[4] > 0, "YouSwap:MAX_STAKE_AMOUNT_MUST_GREATER_THAN_ZERO"); //maxStakeAmount

        vars.pFactory = creatorFactories[msg.sender];
        vars.commissionTotal = commTmp.poolCommAmount;

        if (vars.pFactory == ZERO) {
            vars.pFactory = createClone(poolFactoryTemplate);
            vars.core = createClone(coreTemplate);
            require(ZERO != vars.pFactory && ZERO != vars.core, "YouSwap:CLONE_FACTORY_OR_CORE_FAILED");

            rangeGlobal = rangeGlobal.add(1);
            poolIDRange[msg.sender] = rangeGlobal;

            YouswapFactory(vars.pFactory).initialize(msg.sender, address(this), benefitRate, address(invite), vars.core);
            creatorFactories[msg.sender] = vars.pFactory;
            factoryCore[vars.pFactory] = vars.core;
            allFactories.push(vars.pFactory);
            vars.prePoolId = 0;
            emit YouswapFactoryCreatorEvent(msg.sender, vars.pFactory, vars.core, true);
        }

        if (enableInvite) {
            vars.commissionTotal = vars.commissionTotal.add(commTmp.inviteCommAmount);
        }

        if (!whiteList[msg.sender]) {
            if (vars.commissionTotal > 0) {
                IERC20(address(vars.commissionToken)).safeTransferFrom(msg.sender, address(this), vars.commissionTotal);
            }
        }

        vars.core = factoryCore[vars.pFactory];
        uint256[] memory newTotals = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            require((ZERO != tokens[i]) && (address(this) != tokens[i]), "YouSwap:PARAMETER_ERROR_TOKEN");
            require(0 < rewardTotals[i], "YouSwap:PARAMETER_ERROR_REWARD_TOTAL");
            require(0 < rewardPerBlocks[i], "YouSwap:PARAMETER_ERROR_REWARD_PER_BLOCK");

            vars.benefitAmount = rewardTotals[i].div(DefaultSettings.TEN_THOUSAND).mul(benefitRate);
            if (vars.benefitAmount > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, address(this), vars.benefitAmount);
            }
            newTotals[i] = rewardTotals[i].sub(vars.benefitAmount);
            if (newTotals[i] > 0) {
                IERC20(tokens[i]).safeTransferFrom(msg.sender, vars.core, newTotals[i]);
            }
        }

        require((ZERO != vars.token) && (address(this) != vars.token) && (vars.pFactory != vars.token), "YouSwap:PARAMETER_ERROR_TOKEN");
        uint256 range = poolIDRange[msg.sender].mul(DefaultSettings.EACH_FACTORY_POOL_MAX);
        YouswapFactory(vars.pFactory).addPool(
            vars.prePoolId,
            range,
            vars.name,
            vars.token,
            enableInvite,
            poolParams,
            tokens,
            newTotals,
            rewardPerBlocks);
    }

    struct ReopenLocalVars {
        string name;
        address token;
        uint256 tvl;
        uint256 poolType;
        uint256 lockSeconds;
        uint256 maxStakeAmount;
        bool enableInvite;
        uint256 endTime;
    }

    /**
        @notice ????????????
        @param prePoolId ?????????Id
        @param commissionToken ??????????????????
        @param poolParams poolType: 0????????????
            powerRatio: 1?????????????????????
            startTimeDelay: 2??????????????????
            priority: 3?????????
            maxStakeAmount: 4??????????????????
            lockSeconds: 5????????????
            multiple: 6????????????
            selfReward: 7????????????
            uppper1Reward: 8????????????
            upper2Reward: 9????????????
        @param tokens ??????????????????
        @param rewardTotals ????????????????????????
        @param rewardPerBlocks ????????????????????????
    */
    function reopen(
        uint256 prePoolId,
        address commissionToken,
        uint256[] memory poolParams,
        address[] memory tokens,
        uint256[] memory rewardTotals,
        uint256[] memory rewardPerBlocks
    ) external {
        IYouswapFactoryCore core = IYouswapFactoryCore(getCore(msg.sender));
        core.checkPIDValidation(prePoolId);
        core.refresh(prePoolId);

        ReopenLocalVars memory vars;
        (vars.name, 
            vars.token, 
            vars.enableInvite,
            vars.tvl,, 
            vars.poolType, 
            vars.lockSeconds, 
            vars.maxStakeAmount,,
            vars.endTime) = YouswapFactory(creatorFactories[msg.sender]).getPoolStakeDetail(prePoolId);

        require(vars.endTime != 0, "YouSwap:MINING_POOL_IS_IN_PROCESS");

        uint256 poolType = poolParams[0];
        uint256 startTimeDelay = poolParams[2];
        uint256 maxStakeAmount = poolParams[4];
        uint256 lockSeconds = poolParams[5];

        if (maxStakeAmount < vars.tvl) {
            poolParams[4] = vars.tvl;
        }

        //??????????????????????????????????????????????????????3????????????????????????????????????????????????????????????
        if (uint256(BaseStruct.PoolLockType.SINGLE_TOKEN_FIXED) == vars.poolType || 
            uint256(BaseStruct.PoolLockType.LP_TOKEN_FIXED) == vars.poolType) {
            if (startTimeDelay < DefaultSettings.SECONDS_PER_DAY.mul(reopenPeriod)) {
               poolParams[2] = DefaultSettings.SECONDS_PER_DAY.mul(reopenPeriod);
            }
            require(vars.lockSeconds == lockSeconds, "YouSwap:LOCKSECONDS_SHOULD_NOT_CHANGED!");
        } 

        require(vars.poolType == poolType, "YouSwap:POOLTYPE_SHOULD_NOT_CHANGED!");
        createPool(prePoolId, vars.name, vars.token, commissionToken, vars.enableInvite, poolParams, tokens, rewardTotals, rewardPerBlocks);
    }

    /**
        @notice ??????????????????
        @param factoryArr ??????????????????
     */
    function withdrawAllRewards(YouswapFactory[] memory factoryArr) external {
        for (uint256 i = 0; i < factoryArr.length; i++) {
            YouswapFactory factory = factoryArr[i];
            factory.withdrawRewards2(factory.poolIds(), msg.sender);
        }
    }

    /**
      * ???????????????????????????
      * (tokens, amounts) ???????????????????????????????????????
     */
    function getBalance() external view returns (address[] memory tokens, uint256[] memory amounts) {
        uint256[] memory balances = new uint256[](supportCommTokenArr.length);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            uint256 b = IERC20(address(supportCommTokenArr[i])).balanceOf(address(this));
            balances[i] = b;
        }

        tokens = supportCommTokenArr;
        amounts = balances;
    }

    /**
        @notice ????????????????????????
        @return ??????????????????
     */
    function getAllFactories() external view returns (address[] memory) {
        return allFactories;
    }

    /**
        @notice ???????????????????????????????????????
        @param user ????????????
        @return ?????????????????????????????????
     */
    function getMyFactory(address user) external view returns (address) {
        return creatorFactories[user];
    }

    /**
        @notice ????????????????????????????????????
        @return (address[] memory, bool[] memory) ???????????????????????????????????????
     */
    function getSupportCommTokens() external view returns (address[] memory, bool[] memory) {
        bool[] memory states = new bool[](supportCommTokenArr.length);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            states[i] = supportCommissions[supportCommTokenArr[i]].isSupported;
        }
        return (supportCommTokenArr, states);
    }

    /**
        @notice ????????????????????????
        @return ????????????????????????
     */
    function getFactoryCounts() external view returns(uint256) {
        return allFactories.length;
    }

    /**
        @notice ???????????????????????????
        @param _token ??????????????????
        @param _poolCommAmount ??????????????????
        @param _inviteCommAmount ????????????????????????
        @param _state ??????????????????
     */
    function setSupportCommTokens(address _token, uint256 _poolCommAmount, uint256 _inviteCommAmount, bool _state) public onlyOperater {
        require(ZERO != _token, "YouSwap:INVALID_ADDRESS");
        Commission memory comm;
        comm.poolCommAmount = _poolCommAmount;
        comm.inviteCommAmount = _inviteCommAmount;
        comm.isSupported = _state;
        supportCommissions[_token] = comm;

        emit CommissionEvent(_token, _poolCommAmount, _inviteCommAmount, _state);
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            if (_token == supportCommTokenArr[i]) {
                return;
            }
        }
        supportCommTokenArr.push(_token);
    }

    /**
        @notice ????????????????????????
        @param _dst ??????????????????
     */
    function withdrawCommission(address _dst) external onlyFinanceOwner {
        require(ZERO != _dst, "YouSwap:INVALID_ADDRESS");
        for (uint256 i = 0; i < supportCommTokenArr.length; i++) {
            uint256 b = IERC20(supportCommTokenArr[i]).balanceOf(address(this));
            if (b > 0) {
                IERC20(supportCommTokenArr[i]).safeTransfer(_dst, b);
            }
        }
        emit withdrawCommissionEvent(_dst);
    }

    /**
        @notice ????????????????????????????????????
        @param _newBenefitRate ??????????????????
     */
    function setBenefitRate(uint256 _newBenefitRate) external onlyOperater {
        require(_newBenefitRate >= DefaultSettings.BENEFIT_RATE_MIN && _newBenefitRate <= DefaultSettings.BENEFIT_RATE_MAX, "YouSwap:PARAMETER_ERROR_INPUT");
        uint256 oldBenefitRate = benefitRate;
        benefitRate = _newBenefitRate;
        emit BenefitRateEvent(oldBenefitRate, benefitRate);
    }

    /**
        @notice ????????????????????????
        @param _period ????????????
     */
    function setReopenPeriod(uint256 _period) external onlyOperater {
        uint256 oldPeriod = reopenPeriod;
        reopenPeriod = _period;
        emit ReopenPeriodEvent(oldPeriod, reopenPeriod);
    }

    /** 
        @notice ????????????????????????????????????
        @param _creator ???????????????
        @param _rateMax ????????????
    */
    function setChangeRPBRateMax(address _creator, uint256 _rateMax) external onlyOperater {
        address factory = creatorFactories[_creator];
        require(ZERO != factory, "YouSwap:CREATOR_FACTORY_NOT_FOUND");
        YouswapFactory(factory).setChangeRPBRateMax(_rateMax);
        emit ChangeRPBRateMaxEvent(_creator, factory, _rateMax);
    }

    /** 
        @notice ???????????????????????????????????????7???
        @param _interval ??????
    */
    function setChangeRPBIntervalMin(address _creator, uint256 _interval) external onlyOperater {
        address factory = creatorFactories[_creator];
        require(ZERO != factory, "YouSwap:CREATOR_FACTORY_NOT_FOUND");
        YouswapFactory(factory).setChangeRPBIntervalMin(_interval);
        emit ChangeRPBIntervalEvent(_creator, factory, _interval);
    }

    /** 
        @notice ??????????????????????????????
        @param _creator ?????????
        @param _poolId ??????ID
        @param _allowedState ??????????????????
    */
    function setWithdrawAllowed(address _creator, uint256 _poolId, bool _allowedState) external onlyOperater {
        IYouswapFactoryCore core = IYouswapFactoryCore(getCore(_creator));
        core.checkPIDValidation(_poolId);
        core.setWithdrawAllowed(_poolId, _allowedState);
        emit WithdrawAllowedEvent(_creator, _poolId, _allowedState);
    }

    /**
        @notice ??????????????????
        @param _creator ?????????
        @param _poolId ??????id
        @param _name ???????????????
     */
    function setName(address _creator, uint256 _poolId, string memory _name) external onlyOperater {
        IYouswapFactoryCore core = IYouswapFactoryCore(getCore(_creator));
        core.setName(_poolId, _name);
    }

    /**
        @notice ??????????????????
        @param _creator ?????????
        @param _poolId ??????id
        @param _multiple ?????????
     */
    function setMultiple(address _creator, uint256 _poolId, uint256 _multiple) external onlyOperater {
        IYouswapFactoryCore core = IYouswapFactoryCore(getCore(_creator));
        core.setMultiple(_poolId, _multiple);
    }

    /**
        @notice ??????????????????
        @param _creator ?????????
        @param _poolId ??????id
        @param _priority ????????????
     */
    function setPriority(address _creator, uint256 _poolId, uint256 _priority) external onlyOperater {
        IYouswapFactoryCore core = IYouswapFactoryCore(getCore(_creator));
        core.setPriority(_poolId, _priority);
    }

    function getCore(address _creator) internal view returns(address) {
        address factory = creatorFactories[_creator];
        require(ZERO != factory, "YouSwap:CREATOR_FACTORY_NOT_FOUND");
        return factoryCore[factory];
    }

    /**
        @notice ?????????????????????
        @param _super ?????????
        @param _state ?????????????????????
     */
    function setWhiteList(address _super, bool _state) external onlyOperater {
        require(ZERO != _super, "YouSwap:INVALID_ADDRESS");
        whiteList[_super] = _state;
        emit WhiteListEvent(_super, _state);
    }

    /** 
        @notice ????????????token 
        @param _creator ?????????
        @param _token ??????
        @param _to ????????????
        @param _amount ????????????
    */
    function safeWithdraw(address _creator, address _token, address _to, uint256 _amount) external onlyAdmin {
        require((ZERO != _token) && (ZERO != _to) && (0 < _amount), "YouSwap:ZERO_ADDRESS_OR_ZERO_AMOUNT");
        IYouswapFactoryCore core = IYouswapFactoryCore(getCore(_creator));
        core.safeWithdraw(_token, _to, _amount);
        emit SafeWithdrawEvent(_creator, _token, _to, _amount);
    }

    /**
        @notice ??????????????????
        @param _prototype ????????????
        @return proxy ?????????
     */
    function createClone(address _prototype) internal returns (address proxy) {
        bytes20 targetBytes = bytes20(_prototype);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(
            add(clone, 0x28),
            0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            proxy := create(0, clone, 0x37)
        }

        emit CloneEvent(proxy);
        return proxy;
    }
}