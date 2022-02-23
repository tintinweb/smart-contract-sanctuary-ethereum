/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT
// File: contracts/OpenZeppelin/IERC20.sol
pragma solidity >=0.8.0;

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
// File: contracts/OpenZeppelin/SafeMath.sol



pragma solidity >=0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
// File: contracts/Staking/StakingNew.sol


pragma solidity >=0.8.0;



contract StakingNew{
    using SafeMath for uint256;
    IERC20 public ERC20Interface;
    mapping (address => uint256) internal _stakes;
    address  public tokenAddress;
    uint public stakingStarts;
    uint public stakingEnds;
    uint public withdrawStarts;
    uint public withdrawEnds;
    uint public stakingCap;
    address public rewardSetter;
    
    struct StakeState {
        uint256 stakedTotal;
        uint256 stakingCap;
        uint256 stakedBalance;
        uint256 withdrawnEarly;
        mapping(address => uint256) _stakes;
    }

    struct StakeRewardState {
        uint256 rewardBalance;
        uint256 rewardsTotal;
        uint256 earlyWithdrawReward;
    }

    StakeRewardState public rewardState;
    StakeState public stakeState;

    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_);
    event PaidOut(address indexed token, address indexed staker_, uint256 amount_, uint256 reward_);

    constructor (address tokenAddress_, uint256 stakingCap_){
        require(tokenAddress_ != address(0), "Zero Address");
        require(stakingCap_ > 0, "StakingCap must be positive");
        tokenAddress = tokenAddress_;
        stakingStarts = block.timestamp;
        stakingEnds = stakingStarts.add(86400); //1 day 
        withdrawStarts = stakingEnds.add(120); // 2 minutes
        withdrawEnds = withdrawStarts.add(86400); //1 day
        stakingCap = stakingCap_;
        stakeState.stakingCap = stakingCap_;
        ERC20Interface = IERC20(tokenAddress_);
        rewardSetter = msg.sender;
    }

    /*
    * @notice stake is a function to stake tokens of address tokenAddress by any account which owns tokens with balance>0
    * @params amount(uint256) - amount of tokens to be staked
    * @output - bool - true if tokens are staked
    */
    function stake(uint256 amount) public returns(bool){
        address from = msg.sender;
        return _stake(from, from, amount);
    }

    /*
    * @notice _stake is a private function to stake tokens and update the stakeState struct
    * @params payer(address) - address of the accout making the function call
    * staker(address) - address of thea account who will have the stakes
    * amount(uint256) - amount of tokens to be staked
    * @output bool - true if tokens are staked
    */
    function _stake(address payer, address staker, uint256 amount) private _after(stakingStarts) _before(stakingEnds) _positive(amount) returns(bool) {
        uint256 stakedBal = stakeState.stakedBalance;
        require(amount <= stakingCap.sub(stakedBal), "Staking cap is filled");
        _payTo(payer, address(this), amount);
        emit Staked(tokenAddress, staker, amount);
        stakeState.stakedBalance = stakeState.stakedBalance.add(amount);
        stakeState.stakedTotal = stakeState.stakedTotal.add(amount);
        stakeState._stakes[staker] = stakeState._stakes[staker].add(amount);
        return true;
    }

    /*
    * @notice _payTo is a function to transfer tokens from allower to receiver
    * @params allower - address of account from which amount of tokens will be deducted from the balance
    * receiver - address of account to which amount of tokens will be transferred to 
    * amount(uint256) - amount of tokens to be staked
    * @output uint256 - amount of tokens transferred
    */
    function _payTo(address allower, address receiver, uint256 amount) private returns(uint256){
        uint256 preBalance = IERC20(tokenAddress).balanceOf(receiver);
        ERC20Interface.transferFrom(allower, receiver, amount);
        uint256 postBalance = IERC20(tokenAddress).balanceOf(receiver);
        return postBalance.sub(preBalance);
    }

    /*
    * @notice _payDirect is a function to transfer tokens from msg.sender to receiver
    * @params to - address of account to which amount of tokens will be transferred to 
    * amount(uint256) - amount of tokens to be staked
    * @output bool - true if tokens are staked
    */
    function _payDirect(address to, uint256 amount) private returns(bool){
        if (amount == 0) {
            return true;
        }
        ERC20Interface.transfer(to, amount);
        return true;
    }

    /*
    * @notice addReward is a function to add rewards 
    * @params rewardAmount - amount of reward tokens to be added 
    * withdrawableAmount - amount of reward tokens that can be withdrawn
    * @output bool - true if rewards are addded
    */
    function addReward(uint256 rewardAmount, uint256 withdrawableAmount) external returns (bool) {
        require(rewardAmount > 0, "Reward must be positive");
        // require(withdrawableAmount >= 0, "Withdrawable amount cannot be negative");
        require(withdrawableAmount <= rewardAmount, "Withdrawable amount must be less than or equal to the reward amount");
        address from = msg.sender;
        rewardAmount = _payTo(from, address(this), rewardAmount); 
        rewardState.rewardsTotal = rewardState.rewardsTotal.add(rewardAmount);
        rewardState.rewardBalance = rewardState.rewardBalance.add(rewardAmount);
        rewardState.earlyWithdrawReward = rewardState.earlyWithdrawReward.add(withdrawableAmount);
        return true;
    }

    /*
    * @notice addMarginalReward is a function toadd rewards 
    * @params withdrawableAmount - amount of reward tokens that can be withdrawn
    * @output bool - true if rewards are addded
    */
    function addMarginalReward(uint256 withdrawableAmount) external returns(bool) {
        require(msg.sender == rewardSetter, "Not allowed");
        rewardState.earlyWithdrawReward = withdrawableAmount;
        uint256 stakedBal = stakedBalance();
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this)).sub(rewardState.rewardsTotal);
            amount = amount.sub(stakedBal.div(2));
        if (amount == 0) {
            return true;
        }
        rewardState.rewardsTotal = rewardState.rewardsTotal.add(amount);
        rewardState.rewardBalance = rewardState.rewardBalance.add(amount);
        return true;
    }

    /*
    * @notice withdraw is a function to withdraw staked tokens and update stake balance of account
    * @params amount(uint256) - amount of stakes to be withdrawn
    * @output bool - true if staked tokens are withdrawn
    */
    function withdraw(uint256 amount) public returns (bool) {
        address from = msg.sender;
        uint256 wdAmount = tryWithdraw(from, amount);
        stakeState.stakedBalance = stakeState.stakedBalance.sub(wdAmount);
        stakeState._stakes[from] = stakeState._stakes[from].sub(wdAmount);
        return true;
    }

    /*
    * @notice tryWithdraw is a private function to withdraw staked tokens based on whether withdraw time has ended 
    * @params from - address of account that wants to withdraw tokens
    * amount(uint256) - amount of staked tokens to be withdrawn
    * @output uint256 - amount of staked tokens withdrawn
    */
    function tryWithdraw(address from, uint256 amount) private _positive(amount) _realAddress(msg.sender) returns (uint256) {
        require(amount <= stakeState._stakes[from], "Not enough balance");
        if (block.timestamp < withdrawEnds) {
            return _withdrawEarly(from, amount);
        } else {
            return _withdrawAfterClose(from, amount);
        }
    }

    /*
    * @notice _withdrawEarly is a private function to withdraw staked tokens before withdraw time has ended
    * @params from - address of account that wants to withdraw tokens
    * amount(uint256) - amount of staked tokens to be withdrawn
    * @output uint256 - amount of staked tokens withdrawn
    */
    function _withdrawEarly(address from, uint256 amount) private _realAddress(from) returns (uint256) {
        uint256 denom = (withdrawEnds.sub(stakingEnds)).mul(stakeState.stakedTotal);
        uint256 reward = (
        ( stakingEnds.sub(block.timestamp).mul(rewardState.earlyWithdrawReward) ).mul(amount)
        ).div(denom);
        rewardState.rewardBalance = rewardState.rewardBalance.sub(reward);
        bool totalAmountPaid = _payDirect(from, amount);
        require(totalAmountPaid, "Payment Failed");
        emit PaidOut(tokenAddress, from, amount, amount.add(reward));
        return amount;
    }

    /*
    * @notice _withdrawAfterClose is a function to withdraw staked tokens after withdraw time has ended
    * @params from - address of account that wants to withdraw tokens
    * amount(uint256) - amount of staked tokens to be withdrawn
    * @output uint256 - amount of staked tokens withdrawn
    */
    function _withdrawAfterClose(address from, uint256 amount) private _realAddress(from) returns (uint256) {
        uint256 rewBal = rewardState.rewardBalance;
        uint256 reward = (rewBal.mul(amount)).div(stakeState.stakedBalance);
        rewardState.rewardBalance = rewBal.sub(reward);
        bool totalAmountPaid = _payDirect(from, amount.add(reward));
        require(totalAmountPaid, "Payment Failed");
        emit PaidOut(tokenAddress, from, amount, reward);
        return amount;
    }

    /*
    * @notice rewardsTotal is a function to fetch total reward tokens
    * @output uint256 - true if tokens are staked
    */
    function rewardsTotal() external view returns (uint256) {
        return rewardState.rewardsTotal;
    }

    /*
    * @notice earlyWithdrawReward is a function to check earlyWithdrawReward 
    * @output uint256 - value of earlyWithdrawReward
    */
    function earlyWithdrawReward() external view returns (uint256) {
        return rewardState.earlyWithdrawReward;
    }

    /*
    * @notice rewardBalance is a function to check reward tokens left
    * @output uint256 - total reward tokens left
    */
    function rewardBalance() external view returns (uint256) {
        return rewardState.rewardBalance;
    }
    
    /*
    * @notice stakedTotal is a function to check total staked tokens 
    * @output uint256 - total number of tokens staked
    */
    function stakedTotal() external view returns(uint256){
        return stakeState.stakedTotal;
    }

    /*
    * @notice stakedBalance is a function to check the total staked balance
    * @output uint256 - total number of stakes left
    */
    function stakedBalance() public view returns(uint256){
        return stakeState.stakedBalance;
    }

    /*
    * @notice stakeOf is a function to check total stakes of an account
    * @params account - address of account whose stakes are to be checked
    * @output uint256 - stake of the account
    */
    function stakeOf(address account) external view returns(uint256){
        return stakeState._stakes[account];
    }

    modifier _realAddress(address addr){
        require(addr != address(0), "Zero Address");
        _;
    }

    modifier _positive(uint256 amount){
        require(amount != 0, "Negative Amount");
        _;
    }

    modifier _after(uint eventTime){
        require(block.timestamp >= eventTime, "bad timing for the request- after");
        _;
    }

    modifier _before(uint eventTime){
        require(block.timestamp < eventTime, "bad timing for the request- before");
        _;
    }
}