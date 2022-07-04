/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// File: stakingpk.sol

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
     //Giving token address for staking
    IERC20 public stakeToken;
    //Giving reward token address
    IERC20 public rewardToken;
    //total reward for calculating the rewardFunds
    uint public totalRewardFunds;
    //total supply to calculate the supply of the token
    uint private _totalSupply;
    //the reward balance is equals to the totalrewardfunds
    uint public rewardBalance=totalRewardFunds;
    //the calculation of the days for staking period
    uint day=60;
    //accuracy factor is to calculate to get out from the wei format
    uint accuracyFactor=10**10;
    //mapping for toatal stake records
    mapping(address=>uint)public totalStakeRecords;
    //this line belongs to toal info of a staker
    mapping(address=>stakerDetails[])public stakers;
    //event is to geting transaction history as logs
    event staked(address indexed user,uint amount,uint noOfDay);
    event Unstaked(address indexed user,uint amount);
       event RecoverToken(address indexed token, uint256 indexed amount);
    struct stakerDetails{
        //The staker id
        uint id;
        //The staker balance
        uint balance;
         //The staker totalrewards 
        uint totalRewards;
         //The staker locking period of the sstaker
        uint lockingPeriod;
         //The staker lastupdated time belongs to the last staking time
        uint lastUpdatedTime;
        //maxtime is the calculation of ending period of that staking
        uint maxtime;
         //The staker enarned reward from that stake will be calculated in reward earned
        uint rewardEarned;
        //The rewardPaidout is belongs to the withdraw of the reward.
        uint rewardPaidOut;
        //the apr of that staking
        uint apr;

    }
    modifier updateReward(address account,uint id){
        //for giving updation for reward
        stakers[account][id].rewardEarned=earned(account,id);
        _;
    }
constructor(IERC20 _stakeToken,IERC20 _rewardToken){
    //giving stake token for this contract
    stakeToken=IERC20(_stakeToken);
    //reward token is giving for this contract
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
       return  getRewardRate(account,id)*(block.timestamp-(stakers[account][id].lastUpdatedTime));

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
    //the staker amount want to be greater than 0 for staking
require(amount>0,"cannont stake");
//Calculating daysInTimestamp with staking days and static day calculation
uint daysInTimestamp=noOfDays*day;
//storing stakerdetails to staker
stakerDetails memory staker;
// showing the reward of the user 
uint rewardforUser=rewardForPeriod(amount,noOfDays);
//increasing the staker records
totalStakeRecords[msg.sender]+=1;
//staker id to track the staking record
staker.id=totalStakeRecords[msg.sender];
//how many days the staker locked
staker.lockingPeriod=noOfDays;
//total reward of that user
staker.totalRewards=rewardforUser;
//stakers last updated time by block.timestamp
staker.lastUpdatedTime=block.timestamp;
//the max time calculation for the staker
staker.maxtime=block.timestamp+(daysInTimestamp);
//The balance of the staker
staker.balance =amount;
//staker can read the apr calculation by giving the days.
staker.apr=getApr(noOfDays);
//push into staker
stakers[msg.sender].push(staker);
//if the staker stakes means the rewardbalance will be reduced.
rewardBalance -=rewardforUser;
_totalSupply=_totalSupply+amount;
//the staker stakes the token the amount will be send to the application contract
stakeToken.transferFrom(msg.sender,address(this),amount);
emit staked(msg.sender,amount,noOfDays);
}
function unstake(uint id)public{
    //unstake will require to completye the maxtime of the user
    require(block.timestamp>=stakers[msg.sender][id].maxtime,"tokens are locked,try after locking period");
    //the amount of the staker 
    uint amount=stakers[msg.sender][id].balance;
    //the amount of the user will be subtracted from the totalsupply
    _totalSupply=_totalSupply-amount;
    //the staker balance will be as 0
    stakers[msg.sender][id].balance=0;
    //the staketoken will be transfered to the staker
    stakeToken.transfer(msg.sender,amount);
    getReward(id);

    emit Unstaked(msg.sender,amount);
}
function getReward(uint id) public updateReward(msg.sender,id){
    //the reward will be shown for the staker
    uint reward=earned(msg.sender,id);
    stakers[msg.sender][id].lastUpdatedTime=block.timestamp;
    //if the reward is greater than 0 the function goes in
    if(reward>0){
        stakers[msg.sender][id].rewardEarned=0;
        stakers[msg.sender][id].rewardPaidOut +=reward;
        rewardToken.transfer(msg.sender,reward);
        emit Unstaked(msg.sender,reward);
    }

}


function totalValueLocked()public view returns(uint){
    //the totalsupply will be showwn
    return _totalSupply;
}
function balanceOf(address account,uint id)public view returns(uint){
    //balance of the staker
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
    //it is to depositing the reward into contract itself
    stakeToken.transferFrom(msg.sender,address(this),amount);
    //the totalreward will be added
    totalRewardFunds +=amount;
    //the rewardbalance also added
    rewardBalance +=amount;
}
function TotalRewards()public view returns(uint){
    uint tRewards=totalRewardFunds-rewardBalance;
    return tRewards;
}
}