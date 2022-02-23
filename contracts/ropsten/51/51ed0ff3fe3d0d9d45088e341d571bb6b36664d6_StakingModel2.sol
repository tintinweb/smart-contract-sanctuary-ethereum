/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// File: contracts/OpenZeppelin/IERC20.sol



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



pragma solidity ^0.8.0;

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
// File: contracts/Staking/StakingCalc.sol


pragma solidity >=0.8.0;


contract StakingCalculations{
    using SafeMath for uint256;
    // @notice Calculate number of days from unix timestamp
    // @dev Remove 1 from return statement which is used only for testing purpose
    // @param timestamp The unix timestamp from which number of days have too be calculated
    // @return number of days calculated
    function getNumberOfDays(uint256 timestamp) internal pure returns(uint256){
        uint diff = (timestamp) / 60 / 60 / 24;
        return diff+1;
    }

    // @notice Calculate early withdraw reward tokens for separate reward model
    // @param timestamp of staked tokens
    // @param Amount of staked tokens
    // @return early withdraw reward tokens for separate staking model
    function calculateEarlyWithdrawRewardSeparate(uint256 timeStaked, uint256 amount, uint daysOfMaturity, uint earlyRewardAPY) _positive(amount) internal pure returns(uint256){
        uint256 denom =  daysOfMaturity.mul(100);
        uint256 rewards =  amount.mul(earlyRewardAPY.mul(timeStaked));
        return rewards.div(denom);
    }

    // @notice Calculate early withdraw reward tokens for combined reward model
    // @param timestamp of staked tokens
    // @param Amount of staked tokens
    // @return early withdraw reward tokens for separate staking model
    function calculateEarlyWithdrawRewardCombined(uint256 timeStaked, uint256 amount, uint daysOfMaturity, uint earlyRewardAPY) _positive(amount) internal pure returns(uint256){
        uint256 denom =  daysOfMaturity.mul(100);
        uint256 rewards =  amount.mul(earlyRewardAPY.mul(timeStaked));
        return rewards.div(denom);
    }

    // @notice Calculate maturity reward tokens for combined reward model
    // @param address of staker
    // @param timestamp of staked tokens
    // @param Amount of staked tokens
    // @return maturity reward tokens for separate staking model
    function calculateMaturityRewardCombined(uint256 oldStakeAmount, uint256 timeStaked, uint daysOfMaturity) internal pure returns(uint256){
        return ((oldStakeAmount).mul(timeStaked)).div(daysOfMaturity);
    }

    // @notice Calculate maturity reward tokens for separate reward model
    // @param address of the staker
    // @return maturity reward tokens for separate staking model
    function calculateMaturityRewardSeparate(uint256 staker, uint maturityRewardAPY) internal pure returns(uint256){
        // uint256 len = stakerDetailsSep[staker].endValue;
        // uint256 amountTotal;
        // amountTotal = stakerDetailsSep[staker].stakeAmount[len-1];
        uint256 rewards = (staker.mul(maturityRewardAPY)).div(100);
        return rewards;
    }

    // @notice Modifier to check whether amount is not equal to 0
    // @param Amount in uint
    modifier _positive(uint256 amount){
        require(amount != 0, "Negative Amount");
        _;
    }

}
// File: contracts/Staking/StakingModel.sol


pragma solidity >=0.8.0;

// import "./Tokens.sol";




contract StakingModel2 is StakingCalculations{
    using SafeMath for uint256;
    IERC20 private ERC20Interface; //ERC20 interface

    string projectName; //Name of the project
    string tokenName; //Name of ERC20 token
    address tokenAddress; //Address of ERC20 token
    string stakingName; //Name of staking pool
    uint256 cap; //Limit on no of tokens that can be staked
    uint256 startDate; // Date of starting staking
    uint256 private constant MAX = ~uint256(0); //Max value to return when index is not matched to any index value
    uint256 daysOpenForStake; //No of days for which staking will be open
    uint256 daysOfMandatoryLock; //No of days for which stakes cannot be withdrawn
    uint256 daysOfMaturity; //Total no of days after which stakes are matured
    uint256 maturityRewardAPY; //APY %age for maturity reward
    uint256 earlyRewardAPY;  // APY %age for early reward
    uint256 stakingStarts; //staking start timestamp
    uint256 stakingEnds; //staking end timestamp
    uint256 earlyWithdrawStarts; //early withdraw start timestamp
    uint256 earlyWithdrawEnds; //early withdraw end timestamp

    // Stake state is maintained throughout the contract to capture stake tokens and pool size
    struct StakeState {
        uint256 stakedTotal; //Total staked tokens in contract
        uint256 poolSize; // Number of tokens that can be staked
        uint256 stakedBalance; //Current number of tokens that can be staked by all accounts
    }

    // Stake reward state is maintained throughout the contract to capture maturity reward and early reward
    struct StakeRewardState {
        uint256 earlyRewardsTotal; //Total early rewards claimed by all accounts
        uint256 maturityRewardsBalance; //Current maturity rewards that can be claimed by accounts
        uint256 maturityRewardsTotal; //Total maturity rewards in contract
        address rewardSetter;
    }

    StakeRewardState public rewardState; 
    StakeState public stakeState;

    uint256 public stakerDetailsId; //Auto increment id for staker
    
    // Staker details for each staked id  
    struct StakerDetails {
        uint256 stakeAmount; //Separate model stake amount
        uint256 maturityTime; //Separate model maturity time
        uint256 maturityRewardSep; //Separate model after Maturity reward
    }

    // Staker details common to all staked ids of a staker
    struct Details {
        uint256 maturityTimeCombined; //Maturity time for combined staking
        uint256 totalStakeAmount; //Total amount of tokens staked
        uint256 totalClaimedEarlyReward; // Total early rewards withdrawan
        uint256 totalClaimedMaturityReward; // Total after maturity rewards withdrawn
    }

    mapping(address => uint256[]) private stakerIDs; //Maps all staked token ids to a staker
    mapping(uint256 => StakerDetails) public stakerDetails; //Maps staked id to the staker details
    mapping(address => Details) public details; //Maps a staker to staker details common to all staked ids

    event Staked(address indexed token, address indexed staker_, uint256 requestedAmount_);
    event PaidOut(address indexed token, address indexed staker_, uint256 amount_, uint256 reward_);

    
    constructor (
        address _tokenAddress
        ) _realAddress(_tokenAddress) {
        tokenAddress = _tokenAddress;
        stakeState.poolSize = 10000;
        daysOpenForStake = 5;
        daysOfMandatoryLock = 1;
        daysOfMaturity = 10;
        rewardState.maturityRewardsTotal = 4000;
        rewardState.maturityRewardsBalance = 4000;
        maturityRewardAPY = 40;
        earlyRewardAPY = 30;
        
        stakingStarts = block.timestamp;
        startDate = block.timestamp;
        stakingEnds = block.timestamp + (daysOpenForStake*86400); //(10*24*60*60);
        earlyWithdrawStarts = block.timestamp + (daysOfMandatoryLock*86400); //(10*24*60*60);
        earlyWithdrawEnds = earlyWithdrawStarts + 259200;//(3*24*60*60);

        rewardState.rewardSetter = msg.sender;
        ERC20Interface = IERC20(_tokenAddress);
    }

    // @notice Stake function to stake any amount from the token balance by a staker
    // @param _amount (uint256): amount of tokens to be staked
    // @return Returns true if stake successful
    function stake(uint256 _amount) _positive(_amount) public returns (bool _success) {
        address staker = msg.sender;

        // Check if staker has sufficient token balance
        uint256 tokenBalance = IERC20(tokenAddress).balanceOf(staker);
        require(tokenBalance >= _amount, "Insufficient balance");
        
        // Check if adding the amount doesnt exceed pool size
        require(_amount.add(stakeState.stakedBalance) <= stakeState.poolSize, "Amount greater than pool size left");
        
        // Incrementing total no of stakers to be used for id
        stakerDetailsId++;

        // calculating new maturity time by adding 10 days to current time
        uint256 newMaturityTime = block.timestamp + (864000);
        
        // calculate maturity reward amount for separate reward model
        uint256 rewardAmountCalc = StakingCalculations.calculateMaturityRewardSeparate(_amount, maturityRewardAPY);
        
        // Push staker details to the staker details id
        stakerDetails[stakerDetailsId] = StakerDetails(
            _amount,
            newMaturityTime,
            rewardAmountCalc
        );
        
        //Push the staking id 
        stakerIDs[staker].push(stakerDetailsId);

        // Transfer the amount of staked token to contract address and emit event Staked
        _payTo( address(this), _amount);
        emit Staked(tokenAddress, staker, _amount);

        // Total amount staked by an account
        details[staker].totalStakeAmount = (details[staker].totalStakeAmount).add(_amount);
        
        // Set maturity time combined
        details[staker].maturityTimeCombined = (block.timestamp).add(864000);//10*24*60*60

        // Update staked balance and total staked for contract
        stakeState.stakedTotal = stakeState.stakedTotal.add(_amount);
        stakeState.stakedBalance = stakeState.stakedBalance.add(_amount);
        return true;
    }

    // @notice Withdraw after maturity for separate reward model
    // @param _id(uint256): _id of amount staked for the account
    // @return Returns true if withdraw successful
    function withdrawAfterMaturitySeparate(uint256 _id) public returns(bool){
        address staker = msg.sender;
        
        // Check if id contains stake amount and total stake amount is positive
        require(details[staker].totalStakeAmount > 0, "No amount is staked");
        require(stakerDetails[_id].stakeAmount > 0, "Id not present");
        require(search(staker, _id) != MAX, "Id doesnt belong to this account");

        // Check if stake for the id is matured
        require(stakerDetails[_id].maturityTime <= block.timestamp , "Maturity time still left");
        
        // add the stakes and maturity reward for the id
        uint256 calcStakes  = stakerDetails[_id].stakeAmount;
        uint256 rewardBalance = stakerDetails[_id].maturityRewardSep;
        
        // Transfer stake and reward from contract to staker account and emit event
        _payDirect(staker, (calcStakes).add(rewardBalance));
        emit PaidOut(tokenAddress, msg.sender, calcStakes, rewardBalance);
        
        // Delete the id and details regarding the staked id
        delete stakerDetails[_id];

        // Update (early reward total, total staked balance and claimed rewards) of all accounts and of given account
        stakeState.stakedBalance = (stakeState.stakedBalance).sub(calcStakes);
        rewardState.maturityRewardsBalance = (rewardState.maturityRewardsBalance).sub(rewardBalance);
        details[staker].totalClaimedMaturityReward = (details[staker].totalClaimedMaturityReward).add(rewardBalance);
        details[staker].totalStakeAmount = (details[staker].totalStakeAmount).sub(calcStakes);
        
        // Update account id array and sort the id array
        updateStakerIDs(staker, _id);

        // Set maturity time combined incase last staked id is removed
        if(stakerIDs[staker].length == 0){
            details[staker].maturityTimeCombined = 0;
        } else{
            uint256 lastStakeID = stakerIDs[staker][stakerIDs[staker].length-1];
            details[staker].maturityTimeCombined = stakerDetails[lastStakeID].maturityTime;
        }

        return true;
    }
    
    // @notice Withdraw after maturity for combined reward model
    // @return Returns true if withdraw successful
    function withdrawAfterMaturityCombined() public returns(bool){
        address staker = msg.sender;

        // Check if staker has staked tokens and stakes are matured 
        require(details[staker].totalStakeAmount > 0, "No amount is staked");
        require(details[staker].maturityTimeCombined <= block.timestamp , "Maturity time still left");
        
        uint256 id;
        uint256 maturityReward;
        uint256 noOfDays;

        // Add the stakes to be withdrawn
        uint256 calcStakes = details[staker].totalStakeAmount;
        uint256 lenArray = stakerIDs[staker].length;

        // Calculate all rewards of the staker
        for(uint256 i = 0; i<lenArray; i++){
            id = stakerIDs[staker][i];

            // Calculate number of days of maturity difference
            if(i == lenArray-1){
                noOfDays = 0;
            }
            else{
                noOfDays = stakerDetails[stakerIDs[staker][i+1]].maturityTime.sub(stakerDetails[stakerIDs[staker][i]].maturityTime);
            }

            // calculate and add additional reward for extra days staked
            uint256 additionalReward = StakingCalculations.calculateMaturityRewardCombined(stakerDetails[id].maturityRewardSep, noOfDays, daysOfMaturity);
            maturityReward = (maturityReward).add(stakerDetails[id].maturityRewardSep);
            maturityReward = (maturityReward).add(additionalReward);
            
            // Delete the id
            delete stakerDetails[id];
        }

        // Update account id array and sort the id array
        delete stakerIDs[staker];
        
        // Transfer stakes and maturity reward from contract to staker
        _payDirect(staker, (calcStakes).add(maturityReward));
        emit PaidOut(tokenAddress, staker, calcStakes, maturityReward);
        
        // Update staked balance and maturity reward balance
        stakeState.stakedBalance = (stakeState.stakedBalance).sub(calcStakes);
        rewardState.maturityRewardsBalance = (rewardState.maturityRewardsBalance).sub(maturityReward);
        
        // Update staker details for total staked and claimed maturity reward tokens
        details[staker].totalStakeAmount = 0;
        details[staker].totalClaimedMaturityReward = (details[staker].totalClaimedMaturityReward).add(maturityReward);
        
        // Set maturity time combined
        details[staker].maturityTimeCombined = 0;
        return true;
    }

    // @notice Withdraw early for separate reward model
    // @param _id(uint256): _id of amount staked for the account
    // @return Returns true if withdraw successful
    function withdrawEarlySeparate(uint256 _id) _after(earlyWithdrawStarts) _before(earlyWithdrawEnds) public returns(bool){
        address staker = msg.sender;

        // Check if id contains stake amount and total stake amount is positive
        require(details[staker].totalStakeAmount > 0, "No amount is staked");
        require(stakerDetails[_id].stakeAmount > 0, "Id not present");
        require(search(staker, _id) != MAX, "Id doesnt belong to this account");

        // Staked tokens to be withdrawn
        uint256 calcStakes = stakerDetails[_id].stakeAmount;

        // Total days staked and calculate early reward
        uint256 noOfDays = block.timestamp + (864000);
        noOfDays = StakingCalculations.getNumberOfDays(noOfDays.sub(stakerDetails[_id].maturityTime));
        uint256 earlyReward = StakingCalculations.calculateEarlyWithdrawRewardSeparate(noOfDays, calcStakes, daysOfMaturity, earlyRewardAPY);

        // Transfer stake amount and early reward for the id from contract to staker
        _payDirect(staker, (calcStakes).add(earlyReward));
        emit PaidOut(tokenAddress, staker, calcStakes, earlyReward );

        // Update (early reward total, total staked balance) of all accounts and (staked amount, total claimed reward) of given account
        rewardState.earlyRewardsTotal = (rewardState.earlyRewardsTotal).add(earlyReward);
        stakeState.stakedBalance = (stakeState.stakedBalance).sub(calcStakes);
        details[staker].totalClaimedEarlyReward = (details[staker].totalClaimedEarlyReward).add(earlyReward);
        details[staker].totalStakeAmount = (details[staker].totalStakeAmount).sub(calcStakes);

        // Delete the id
        delete stakerDetails[_id];  

        // Update account id array
        updateStakerIDs(staker, _id);

        // Set maturity time combined
        if(stakerIDs[staker].length == 0){
            details[staker].maturityTimeCombined = 0;
        } else{
            uint256 lastStakeID = stakerIDs[staker][stakerIDs[staker].length-1];
            details[staker].maturityTimeCombined = stakerDetails[lastStakeID].maturityTime;
        }
        return true;
    }

    // @notice Withdraw early for combined reward model
    // @param _id(uint256): _id of amount staked for the account
    // @return Returns true if withdraw successful
    function withdrawEarlyCombined(uint _id) _after(earlyWithdrawStarts) _before(earlyWithdrawEnds) public returns(bool){
        address staker = msg.sender;

        // Check if id contains stake amount and total stake amount is positive
        require(details[staker].totalStakeAmount > 0, "No amount is staked");
        require(stakerDetails[_id].stakeAmount > 0, "Id not present");
        uint256 id;
        uint256 earlyReward;
        uint256 calcStakes;
        uint256 noOfDays;
        
        uint256 searchId = search(staker, _id);
        require(searchId != MAX, "Id doesnt belong to this account");

        for(uint256 i = 0; i<=searchId; i++){
            id = stakerIDs[staker][i];

            // Calculate number of days of maturity difference
            if(i == stakerIDs[staker].length - 1){
                noOfDays = (details[staker].maturityTimeCombined).sub(stakerDetails[stakerIDs[staker][i]].maturityTime);
            }
            else{
                noOfDays = stakerDetails[stakerIDs[staker][i+1]].maturityTime.sub(stakerDetails[stakerIDs[staker][i]].maturityTime);
            }

            // Calculate and add the early reward and stakes for the account 
            uint256 reward = StakingCalculations.calculateEarlyWithdrawRewardCombined(noOfDays, stakerDetails[id].stakeAmount, daysOfMaturity, earlyRewardAPY);
            earlyReward = (earlyReward).add(reward);
            calcStakes = calcStakes.add(stakerDetails[id].stakeAmount);
            // Delete the id
            delete stakerDetails[id];
        }

        // Delete and update the ids for the staker account 
        uint256 j=0;
        for (uint256 i= searchId; i<stakerIDs[staker].length-1; i++){
            stakerIDs[staker][j] = stakerIDs[staker][i+1];
            j +=1; 
        }
        for (uint256 i= 0; i<=searchId; i++){
            stakerIDs[staker].pop();
        }

        // Transfer stake amount and early reward for the id from contract to staker
        _payDirect(staker, (calcStakes).add(earlyReward));
        emit PaidOut(tokenAddress, staker, calcStakes, earlyReward);
        
        // Update (early reward total, total staked balance) of all accounts and (staked amount, total claimed reward)of given account
        stakeState.stakedBalance = (stakeState.stakedBalance).sub(calcStakes);
        rewardState.maturityRewardsBalance = (rewardState.maturityRewardsBalance).sub(earlyReward);
        details[staker].totalStakeAmount = (details[staker].totalStakeAmount).sub(calcStakes);
        details[staker].totalClaimedMaturityReward = (details[staker].totalClaimedEarlyReward).add(earlyReward);
        
        // Set maturity time combined
        if(stakerIDs[staker].length == 0){
            details[staker].maturityTimeCombined = 0;
        } else{
            uint256 lastStakeID = stakerIDs[staker][stakerIDs[staker].length-1];
            details[staker].maturityTimeCombined = stakerDetails[lastStakeID].maturityTime;
        }
        
        
        return true;
    }

    // @notice Withdraw early for separate reward model
    // @param staker(address): address of staker
    // @param _id(uint256): _id of amount staked for the account
    // @return Returns true if withdraw successful
    function updateStakerIDs(address staker, uint256 _id) private{
        uint256 index = search(staker, _id);
        for (uint256 i= index; i<stakerIDs[staker].length-1; i++){
            stakerIDs[staker][i] = stakerIDs[staker][i+1]; 
        }
        delete stakerIDs[staker][stakerIDs[staker].length-1];
        stakerIDs[staker].pop();
    }
    // @notice Search the index of id in stakerIDs
    // @param staker(address): address of staker 
    // @param id(uint256): _id of amount staked for the account
    // @return Returns true if withdraw successful
    function search(address staker, uint256 id) private view returns(uint256){
        uint256 i;
        for (i= 0; i< stakerIDs[staker].length; i++){
            if (stakerIDs[staker][i] == id){
                return i;
            }   
        }
        return MAX;
    }

    // @notice Gets all ids of staked tokens for an account
    // @param staker(address): address of staker
    // @return Array containing all ids of staked tokens
    function getStakerIDs(address staker) _realAddress(staker) public view returns (uint256[] memory){
        return stakerIDs[staker];
    }

    // @notice Sets Maturity time as current time for separate reward model
    // @dev Used only for testing. To be removed when in production
    // @param staker(address): staker address
    function setMaturityTimeSeparate(address staker) public{
        uint256 id;
        for (uint256 i= 0; i< stakerIDs[staker].length; i++){
            id = stakerIDs[staker][i];
            stakerDetails[id].maturityTime = block.timestamp.sub((stakerIDs[staker].length-i));
        }
    }

    // @notice Sets Maturity time as current time for combined reward model
    // @dev Used only for testing. To be removed when in production
    // @param staker(address): staker address
    function setMaturityTimeCombined(address staker) public{
        details[staker].maturityTimeCombined = block.timestamp;
    }

    // @notice Sets early withdraw start time as current time
    // @dev Used only for testing. To be removed when in production
    function setEarlyWithdrawStartTime() public{
        earlyWithdrawStarts = block.timestamp;
    }

    // @notice Sets early withdraw end time as current time
    // @dev Used only for testing. To be removed when in production
    function setEarlyWithdrawEndTime() public{
        earlyWithdrawEnds = block.timestamp;
    }

    // @notice Sets staking end time as current time
    // @dev Used only for testing. To be removed when in production
    function setStakingEndTime() public{
        stakingEnds = block.timestamp;
    }

    // @notice Returns Total tokens staked
    // @return Total staked tokens 
    function getTotalStakeAmount() public view returns(uint256){
        return details[msg.sender].totalStakeAmount;
    }

    // @notice Total maturity reward tokens for separate staking model
    // @return Total maturity reward tokens for separate staking model
    function getRewardsMaturityAmountSeparate() public view returns(uint256){
        uint256 value;
        address staker = msg.sender;
        uint256 id;
        for (uint256 i= 0; i< stakerIDs[staker].length; i++){
            id = stakerIDs[staker][i];
            value = value.add(stakerDetails[id].maturityRewardSep);
        }
        return value;
    }

    // @notice Function to transferFrom tokens to receiver
    // @param receiver(address): Address of receiver
    // @param amount(uint256): Amount of tokens to be transferred
    // @return Amount of tokens transferred
    function _payTo(address receiver, uint256 amount) private returns(uint256){
        uint256 preBalance = IERC20(tokenAddress).balanceOf(receiver);
        ERC20Interface.transferFrom(msg.sender, receiver, amount);
        uint256 postBalance = IERC20(tokenAddress).balanceOf(receiver);
        return postBalance.sub(preBalance);
    }
    
    // @notice Function to transfer tokens to receiver
    // @param to(address): Address of receiver
    // @param amount(uint256): Amount of tokens to be transferred
    // @return Amount of tokens transferred
    function _payDirect(address to, uint256 amount) private returns(bool){
        ERC20Interface.transfer(to, amount);
        return true;
    }
    
    // @notice Modifier to check whether an address is a real address
    // @param addr(address): address which has to be checked 
    modifier _realAddress(address addr){
        require(addr != address(0), "Zero Address");
        _;
    }

    // @notice Modifier to check if event time is less than or equal to current time
    // @param eventTime(uint256): event Time. e.g. Staking start time
    modifier _after(uint eventTime){
        require(block.timestamp >= eventTime, "Time to execute function has not started");
        _;
    }

    // @notice Modifier to check if event time is greater than or equal to current time
    // @param eventTime(uint256): event Time. e.g. Staking start time
    modifier _before(uint eventTime){
        require(block.timestamp < eventTime, "Time to execute function has ended before");
        _;
    }
}