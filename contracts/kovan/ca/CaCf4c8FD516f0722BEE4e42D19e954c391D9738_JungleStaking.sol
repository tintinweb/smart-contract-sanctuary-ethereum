// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./interfaces/IBEP20.sol";
import "./utils/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./interfaces/IJUP.sol";
// Farm distributes the BEP20 rewards based on staked LP to each user.
// Farm is fund based to support fixed supply non-mint tokens
// farm also supports deflationery tokens 
// farm supports optional admin fee on both the staked token and the acc-rewards

contract JungleStaking is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 claimedRewards; // historical claimed 
    }

    struct StakeingInfo {
        uint256 totalStakedAmount;
        uint256 rewardsPerSecond;
        uint256 lastRewardTime;
        uint256 accPerShare;
    }

    StakeingInfo public pool = StakeingInfo(
        0,0,0,0
    );

    // Address of the BEP20 Token contract.
    IBEP20 public immutable jungleProtocolToken;

    // pool details 
    IBEP20 public immutable lpToken;

    // total amount of BEP20 rewards that this contract will distributed from start to endBlock
    uint256 public totalBEP20Rewards;
    // The total amount of BEP20 that's paid out as reward.
    uint256 public totalPaidOut = 0;


    // all pending rewards before from last rewards change
    uint256 public rewardsAmountBeforeLastChange;
    uint256 public lastRewardsPerSecondsChange;

    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    uint256 public stakers;

    // Total allocation points. Must be the sum of all allocation points in all pools.

    // The block number when farming starts.
    uint256 public startTime;
    // The block number when farming ends.
    uint256 public endTime;

    event Deposit(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user,uint256 amount);

    constructor(IBEP20 jungleProtocolToken_) {
        jungleProtocolToken = jungleProtocolToken_;
        lpToken = IBEP20( IJUP(address(jungleProtocolToken_)).wbnbPair() );
    }

    /**
        @dev Pauses the contract stoping deposits and widrawals 
     */
    function pause() external onlyOwner{
        _pause();
    }


    /**
        @dev unpause the contracts
     */
    function unPause() external onlyOwner{
        _unpause();
    }

    /**
        @dev Fund the farm, increase the end time
     */
    function fund(uint256 _amount) external onlyOwner {
        require(startTime > 0, "please set a start time first");
        require(block.timestamp < endTime || endTime == startTime, "fund: too late, the farm is closed");
    
        uint256 rewardsPerSecond = pool.rewardsPerSecond;

        uint256 leftOver = rewardsPerSecond > 0 ? _amount.mod(rewardsPerSecond) : 0;
        
        uint256 balanceBefore = jungleProtocolToken.balanceOf(address(this));

        jungleProtocolToken.transferFrom(address(msg.sender), address(this), _amount.sub(leftOver));

        uint256 diff = jungleProtocolToken.balanceOf(address(this)) - balanceBefore;
        require(_amount.sub(leftOver) == diff,"Farm: detected fee on tx" );

        // if no one is staked yet the rewardsPerSeconds = 0;
        if(rewardsPerSecond > 0)
         endTime += diff.div(rewardsPerSecond);
        else 
          endTime = type(uint256).max;
        
        totalBEP20Rewards += diff;
    }

    /**
        sets the start time of the staking
     */
    function setStartingTime(uint256 startTime_) external onlyOwner {
        require(endTime == startTime, "startTime: Already set");
        require(startTime_ >= block.timestamp, "startTime: can't set a past time");
        startTime = startTime_;
        pool.lastRewardTime = startTime;
        lastRewardsPerSecondsChange = startTime;
        endTime = startTime_;
    }

    // View function to see deposited LP for a user.
    function deposited(address _user) external view returns (uint256) {
        return userInfo[_user].amount;
    }

    // View function to see pending BEP20s for a user.
    function pending(address user_) external view returns (uint256) {
        UserInfo storage user = userInfo[user_];
        uint256 accPerShare = pool.accPerShare;
        uint256 lpSupply = pool.totalStakedAmount;

        if (block.timestamp > pool.lastRewardTime && lpSupply != 0) {
            uint256 lastTime = block.timestamp < endTime ? block.timestamp : endTime;
            uint256 nrOfSeconds = lastTime.sub(pool.lastRewardTime);
            uint256 bep20Reward = nrOfSeconds.mul(pool.rewardsPerSecond);
            accPerShare = accPerShare.add(bep20Reward.mul(1e36).div(lpSupply));
        }

        return user.amount.mul(accPerShare).div(1e36).sub(user.rewardDebt);
    }

    // View function for total reward the farm has yet to pay out.
    function totalPending() external view returns (uint256) {
        if (block.timestamp <= startTime) {
            return 0;
        }
        return _totalPastRewards().sub(totalPaidOut);
    }

    function updateRewardsPerSecond() external {
        _UpdateRewardsPerSecond();
        _updatePool();
    }

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool() internal {
        
        uint256 lastTime = block.timestamp < endTime ? block.timestamp : endTime;

        if (lastTime <= pool.lastRewardTime) {
            return;
        }
        uint256 lpSupply = pool.totalStakedAmount;
        if (lpSupply == 0) {
            pool.lastRewardTime = lastTime;
            return;
        }

        uint256 nrOfSeconds = lastTime.sub(pool.lastRewardTime);
        uint256 bep20Reward = nrOfSeconds.mul(pool.rewardsPerSecond);

        pool.accPerShare = pool.accPerShare.add(bep20Reward.mul(1e36).div(lpSupply));
        pool.lastRewardTime = lastTime;
    }

    // Deposit LP tokens to Farm for BEP20 allocation.
    function deposit(uint256 _amount) external whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];
        _updatePool();

        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accPerShare).div(1e36).sub(user.rewardDebt);
            _transferRewards(msg.sender, pendingAmount);
        }
        
        lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
        pool.totalStakedAmount += _amount;
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e36);
        emit Deposit(msg.sender, _amount);
        _UpdateRewardsPerSecond();
    }

    // Withdraw LP tokens from Farm.
    function withdraw(uint256 _amount) external whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount >= _amount, "withdraw: can't withdraw more than deposit");

        _updatePool();

        uint256 pendingAmount = user.amount.mul(pool.accPerShare).div(1e36).sub(user.rewardDebt);
        _transferRewards(msg.sender, pendingAmount);

        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accPerShare).div(1e36);

        lpToken.safeTransfer(address(msg.sender), _amount);
        pool.totalStakedAmount -= _amount;
        emit Withdraw(msg.sender, _amount);
        _UpdateRewardsPerSecond();
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external whenPaused {
        UserInfo storage user = userInfo[msg.sender];
        lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, user.amount);
        pool.totalStakedAmount -= user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Transfer BEP20 and update the required BEP20 to payout all rewards
    function _transferRewards(address to_, uint256 amount_) internal {
        jungleProtocolToken.transfer(to_, amount_);
        totalPaidOut += amount_;
        userInfo[to_].claimedRewards += amount_;
        emit RewardsClaimed(to_, amount_);
    }

    /* 
        recover any BEP20 tokens sent by mistake or recover rewards 
        after all farms have ended and all users have unstaked
        technically can be called while farming is still active
        owner can in no way take users staked token or rewards
    */
    function recoverTokens(IBEP20 tokenAddress_, address to_) onlyOwner external {
        uint256 userStakeLeft = pool.totalStakedAmount;
        uint256 amount;
       

        // only transfer the amount not belonging to users
        if(tokenAddress_ == jungleProtocolToken) {
            require(userStakeLeft == 0, "users still staking");
        } else if(tokenAddress_ == lpToken) {
            amount = tokenAddress_.balanceOf(address(this)) - userStakeLeft;
        } else {
            amount = tokenAddress_.balanceOf(address(this));
        }

        if (amount > 0)
            tokenAddress_.transfer(to_, amount);
    }


    function _totalPastRewards() internal view returns (uint256) {
        if (block.timestamp < startTime)
            return 0;

        uint256 lastTime = block.timestamp < endTime ? block.timestamp : endTime;
        return rewardsAmountBeforeLastChange.add(pool.rewardsPerSecond.mul(lastTime - lastRewardsPerSecondsChange));
    }

    function _getLPStakeInJUPValue() internal view returns (uint256) {
        uint256 lpBalanceOfJUP = jungleProtocolToken.balanceOf(address(lpToken));
        uint256 totalLpSupply = lpToken.totalSupply();
        return lpBalanceOfJUP.mul(pool.totalStakedAmount).div(totalLpSupply);

    }

    // Change the rewardPerBlock
    function _UpdateRewardsPerSecond() internal {
        if(block.timestamp > endTime) return;

        uint256 newRewardsPerSeconds = _getLPStakeInJUPValue().mul(9).div(100).div(24).div(60).div(60);

        uint256 totalRewardsTillNow = _totalPastRewards();
        uint256 leftRewards = totalBEP20Rewards - totalRewardsTillNow;
        uint256 newLeftSeconds = newRewardsPerSeconds > 0 ? leftRewards.div(newRewardsPerSeconds) : type(uint256).max;
        uint256 newEndTime = block.timestamp > startTime ? block.timestamp + newLeftSeconds : startTime + newLeftSeconds;

        // push this change into history
        if (block.timestamp >= startTime) {
            lastRewardsPerSecondsChange = block.timestamp;
            rewardsAmountBeforeLastChange = totalRewardsTillNow;
        } else {
            lastRewardsPerSecondsChange = startTime;
            rewardsAmountBeforeLastChange = 0;
        }

        endTime = newEndTime;
        pool.rewardsPerSecond = newRewardsPerSeconds;
    }

    /**
     * @dev to prevent accidentale renounce ownership.
     */
    function renounceOwnership() public virtual override onlyOwner {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IBEP20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeBEP20: decreased allowance below zero");
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
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IJUP  {
    function wbnbPair() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(
        address account
    ) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(
        address spender,
         uint256 amount
    ) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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