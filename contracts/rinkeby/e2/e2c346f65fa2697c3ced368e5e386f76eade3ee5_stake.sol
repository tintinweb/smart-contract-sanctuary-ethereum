/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

// File: stake.sol

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)



pragma solidity ^0.8.0;
 contract stake{
    IERC20 public stakeToken;
    IERC20 public rewardToken;
    uint public totalRewardFunds;
    uint private _totalSupply;
    uint public rewardBalance=totalRewardFunds;
    uint day=60;
    uint accuracyFactor=10**10;
    mapping(address=>uint)public totalStakeRecords;
    mapping(address=>stakerDetails[])public stakers;
    event staked(address indexed user,uint amount,uint noOfDay);
    event Unstaked(address indexed user,uint amount);
     event RewardPaid(address indexed user, uint256 reward);
       event RecoverToken(address indexed token, uint256 indexed amount);
    struct stakerDetails{
        uint id;
        uint balance;
        uint totalRewards;
        uint lockingPeriod;
        uint lastUpdatedTime;
        uint maxtime;
        uint rewardEarned;
        uint rewardPaidOut;
        uint apr;
    }
    modifier updateReward(address account,uint id){
        stakers[account][id].rewardEarned=earned(account,id);
        _;
    }
constructor(IERC20 _stakeToken,IERC20 _rewardToken){
    stakeToken=IERC20(_stakeToken);
    rewardToken=IERC20(_rewardToken);
}
function getRewardRate(address account,uint id)public view returns(uint){

    //multiplying lockingPeriod of a current user with days and 
    //store it in daysInTimeStamp.
    uint daysInTimestamp=stakers[account][id].lockingPeriod*day; 
    uint amount=getAmountWithApr(account,id);//here we are calling getAmountWithApr function
    //returning the value as uint by this calculation.
    return amount/(365)*(stakers[account][id].lockingPeriod)/(daysInTimestamp);

}
function getAmountWithApr(address account,uint id)public view returns(uint){
    return stakers[account][id].balance*(stakers[account][id].apr)/(100)/(accuracyFactor);
}
function earned(address account,uint id)public view returns(uint){
    //here we are checking reward collected by the user is less than total reward
    if(stakers[account][id].rewardPaidOut<stakers[account][id].totalRewards){
//if it is true comes to this line to check the timestamp
        if(block.timestamp>=stakers[account][id].maxtime){
            //if its passes then sub the total reward
            return(stakers[account][id].totalRewards-(stakers[account][id].rewardPaidOut)); 
        }
        getRewardRate(account,id)*(block.timestamp-(stakers[account][id].lastUpdatedTime));
        }else{
            return 0;
        }   
}
function isRewardAvailable(uint rewardAmount)public view returns(bool){
    if(rewardBalance>=rewardAmount){
        return true;
    }
    return false;
}
// function getApr(uint noOfDays)public view returns(uint){
//     return((noOfDays*(1*(noOfDays*accuracyFactor))/(10000))+(50 *accuracyFactor));
//     // uint value= (noOfDays * 10**17)+50*10**17;
//     // return value/10**17;
// }
  function getApr(uint noOfDays) public view returns(uint) {
        return ((noOfDays * (2 * (noOfDays * accuracyFactor))/(10000)) + (50 * accuracyFactor));
    }
function rewardForPeriod(uint amount,uint noOfDays)public view returns(uint){  
        uint apr=getApr(noOfDays)/(accuracyFactor);
        // apr=510000000000(for 10days)/10000000000=51
        uint reward=(amount)*(apr)/100;
        //reward=1000*51/100=510
        uint totalRewardForPeriod=reward/(365)*(noOfDays);
        //total Reward=510/365*10=13.9
        return totalRewardForPeriod;  
}
function stakeTok(uint amount,uint noOfDays)public{
require(amount>0,"cannont stake");
uint daysInTimestamp=noOfDays*day;
stakerDetails memory staker;
uint rewardforUser=rewardForPeriod(amount,noOfDays);
totalStakeRecords[msg.sender]+=1;
staker.id=totalStakeRecords[msg.sender];
staker.lockingPeriod=noOfDays;
staker.totalRewards=rewardforUser;
staker.lastUpdatedTime=block.timestamp;
staker.maxtime=block.timestamp+(daysInTimestamp);
staker.balance =amount;
staker.apr=getApr(noOfDays);
stakers[msg.sender].push(staker);
rewardBalance -=rewardforUser;
_totalSupply=_totalSupply+amount;

stakeToken.transferFrom(msg.sender,address(this),amount);
emit staked(msg.sender,amount,noOfDays);
}
function unstake(uint id)public{
    require(block.timestamp>=stakers[msg.sender][id].maxtime,"tokens ar locked,try after locking period");
    uint amount=stakers[msg.sender][id].balance;
    _totalSupply=_totalSupply-amount;
    stakers[msg.sender][id].balance=0;
    stakeToken.transfer(msg.sender,amount);
    emit Unstaked(msg.sender,amount);
}
function getReward(uint id) public updateReward(msg.sender,id){
    uint reward=earned(msg.sender,id);
    stakers[msg.sender][id].lastUpdatedTime=block.timestamp;
    if(reward>0){
        stakers[msg.sender][id].rewardEarned=0;
        stakers[msg.sender][id].rewardPaidOut +=reward;
        rewardToken.transfer(msg.sender,reward);
        emit RewardPaid(msg.sender,reward);
    }

}

function exit(uint id)external{
    unstake(id);
    getReward(id);
}
function totalValueLocked()public view returns(uint){
    return _totalSupply;
}
function balanceOf(address account,uint id)public view returns(uint){
    return stakers[account][id].balance;
}
function recoverExcessToken(address token,uint amount)external{
    if(token==address(stakeToken)){
        require(amount<=rewardBalance,"Cannot remove more than remaining reward");

    }
    IERC20(token).transfer(msg.sender,amount);
    emit RecoverToken(token,amount);
}
function depositRewards(uint amount)public {
    stakeToken.transferFrom(msg.sender,address(this),amount);
    totalRewardFunds +=amount;
    rewardBalance +=amount;
}
function TotalRewards()public view returns(uint){
    uint tRewards=totalRewardFunds-rewardBalance;
    return tRewards;
}
}