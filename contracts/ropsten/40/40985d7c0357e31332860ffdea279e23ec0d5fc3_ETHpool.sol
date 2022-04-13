/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;
// >0.8 to avoid use of SafeMath functions
//But, if you want it...
//import "github.com/OpenZeppelin/zeppelin-solidity/contracts/math/SafeMath.sol";
//using SafeMath for uint; // 
//Better use Pausable Library, but it's only for fun

/*
Summary
ETHPool provides a service where people can deposit ETH and they will receive weekly rewards. 
Users must be able to take out their deposits along with their portion of rewards at any time. 
New rewards are deposited manually into the pool by the ETHPool team each week using a contract function.

Requirements
Only the team can deposit rewards.
Deposited rewards go to the pool of users, not to individual users.
Users should be able to withdraw their deposits along with their share of rewards considering the time when they deposited.
Example:

Let say we have user A and B and team T.

A deposits 100, and B deposits 300 for a total of 400 in the pool.
Now A has 25% of the pool and B has 75%. 
When T deposits 200 rewards, A should be able to withdraw 150 and B 450.

What if the following happens? 
A deposits then T deposits then B deposits then A withdraws and finally B withdraws. 
A should get their deposit + all the rewards. 
B should only get their deposit because rewards were sent to the pool before they participated.
*/

/* 
    How it works?
    First of all, we need to understand that the reward mechanism cannot be automatic. (No FOR or WHILE allowed!)
    So, the stakeholders by themselves need to calculate their own reward (Don't worry, a function will do for us)

    Because the staking cannot be negative, we will save the accumulation of rewards proportional to the pool at the time of deposit.
    For each stakeholder, we will save the composition of the pool at the time of staking.
    To calculate the reward, we will substract the sum of rewards at the current time minus the composition of the pool at the time of staking for each user.
    This is the explanation of why cannot be automatic at the time of deposit rewards.

    Some assumptions has been taken:
    - Users withdrawn all of the staking and rewards. No partial withdraw allowed (Well, in fact, can be a full withdraw with a new deposit of the diff)
    - Users cannot add funds to their staking (As above, we can consider a full withdraw, and a new staking)
    - Some constants will be multiplied for an arbitrary big constant (10^18), to reduce rounding errors in division.
    - Can be optimized for gas consumption. But for this challenge and for educational purposes, we can take the risk. And testnet is "free".
    - Bugs? Everywhere. Not ready for production or resale.

    Credits: https://explorer.callisto.network/address/0xE2E4Cf144F4365AAa023da04918A64072C284201/contracts
    (Thanks Erik!)
*/

contract ETHpool {
    string public constant name = "ETHpool";
    enum State {Running, Paused, Ended } //staking can be done only if it state is running.
    uint constant ROUNDING_CONSTANT = 10e18; //To minimize rounding errors at divisions

    struct TeamMember { //there are no specifications for TEAM, so, I understand that can be a lot of people.
        string _name; //It's not necessary
        bool _role; // True for active Team Members
    }

    struct Stakeholder {
        uint _currentBalance;
        uint _compositionAtStartStaking;
        uint _timeStaking;
    }

    struct Pool {
        uint poolBalance;
        uint rewardsBalance;
        uint lastRewardMultiplied;
        uint rewardsCount;
        uint lastRewardTime;
        State status;
    }

    mapping( address => Stakeholder) public UserList;
    mapping( address => TeamMember) public Team;
    Pool public poolStatus;

    //Some events to get data outside of the blockchain
    event StakeEvent(address indexed _from, uint _value);
    event WithdrawEvent(address indexed _to, uint _value);
    event DepositRewardsEvent(uint _poolBalance, uint _rewards);



    constructor(){
        Team[msg.sender]._role = true; // Team member role assigned.
        poolStatus.status = State.Running;
        poolStatus.poolBalance = 0; // Do not transfer at construction time!
        poolStatus.rewardsBalance = 0; // Do not transfer at construction time
        poolStatus.lastRewardMultiplied = 0;
        poolStatus.rewardsCount = 0;
    }


    // The main functions: Stake() , DepositRewards() , Withdraw()

    // DepositRewards: The team can call this function to deposit rewards to the pool.
    // It will update the last reward of the pool, as rewards*ROUNDING_CONSTANT/PoolBalance
    function DepositRewards() external payable onlyTeam notPaused notEnded returns(uint poolbalance) {
        require( msg.value > 0, "Rewards must be greater than 0." );
        if( poolStatus.poolBalance != 0) {
            poolStatus.lastRewardTime = block.timestamp;
            poolStatus.lastRewardMultiplied += (msg.value * ROUNDING_CONSTANT) / poolStatus.poolBalance;
            poolStatus.rewardsBalance += msg.value;
            poolStatus.rewardsCount += 1;
        }
        else{
            revert("Pool is empty!");
        }
        emit DepositRewardsEvent(poolStatus.poolBalance, poolStatus.rewardsBalance);
        return poolStatus.poolBalance;
    }
    
    // Stake: The users can call "Stake" to stake some ETH (or your network coin of value)
    // All network users can perform this function, to become "USERS"
    // TODO: We need to check if the user already exists, and **need to perform first a withdrawal next to a new deposit**.
    // In V2, it will be an automatic claim.

    function Stake() external notPaused notEnded payable {
        require(msg.value > 0, "Stake must be greater than 0.");
        if( UserList[msg.sender]._currentBalance == 0 ) { //first staking
            UserList[msg.sender]._currentBalance = msg.value;
            UserList[msg.sender]._compositionAtStartStaking = poolStatus.lastRewardMultiplied;
            UserList[msg.sender]._timeStaking = block.timestamp;
            poolStatus.poolBalance += msg.value;
        }
        else { //User add more funds to their stake
            uint newStaking = computeRewards()+msg.value; //Add old rewards plus new funds
            UserList[msg.sender]._currentBalance += newStaking;
            UserList[msg.sender]._compositionAtStartStaking = poolStatus.lastRewardMultiplied; //compute from now
            UserList[msg.sender]._timeStaking = block.timestamp;
            poolStatus.poolBalance += newStaking; //do not forget old funds!
        }
        emit StakeEvent(msg.sender, UserList[msg.sender]._currentBalance);
    }

    // Withdraw: Allows users to withdraw their deposits and rewards proportional at the time being.
    // FIXME: At now, only allows full withdrawals.
    function Withdraw() external onlyUsers notPaused returns(uint sent){
        uint balanceFromPool = UserList[msg.sender]._currentBalance; //deposit
        uint balanceFromRewards = computeRewards();                 // rewards
        uint allowedToWithdraw =  balanceFromPool+balanceFromRewards ;
        poolStatus.poolBalance -= balanceFromPool; // From pool
        poolStatus.rewardsBalance -= balanceFromRewards; // From rewards
        UserList[msg.sender]._currentBalance = 0;

        // Did you reentrant? (yes) what did it cost? (everything)
        if (payable(msg.sender).send(allowedToWithdraw)) {        
            delete UserList[msg.sender];
            emit WithdrawEvent(msg.sender,allowedToWithdraw);
            return allowedToWithdraw;
        } else {
            UserList[msg.sender]._currentBalance = balanceFromPool;
            return 0;
        }
    }

    // Viewer functions: Allows users and team to see some computations.
    function computeRewards() public view onlyUsers returns(uint withdrawable){
        return (UserList[msg.sender]._currentBalance * ( poolStatus.lastRewardMultiplied - UserList[msg.sender]._compositionAtStartStaking)) / ROUNDING_CONSTANT ;
    }

    //Pool Administration functions
    function pausePool() external onlyTeam { //If something went wrong, and we need time to proceed.
        poolStatus.status = State.Paused;
    }

    function endPool() external onlyTeam {
        poolStatus.status = State.Ended; //If the pool dies. Only allow users to withdraw their funds.
    }

    function resumePool() external onlyTeam {
        poolStatus.status = State.Running; //Everything is up and running.
    }

    function modifyTeam(address teamAddress , bool role) external onlyTeam {
        Team[teamAddress]._role = role;
    }

    //Modifiers section
    modifier onlyUsers() {
        require( UserList[msg.sender]._currentBalance > 0 , "Only stakeholders can use this function.");
        _;
    }

    modifier onlyTeam() {
        require(Team[msg.sender]._role == true, "Only the Team can call this function.");
        _;
    }

    modifier notPaused() {
        require( poolStatus.status != State.Paused, "ETHpool is paused. This operation is not allowed.");
        _;
    }

    modifier notEnded() {
        require( poolStatus.status != State.Ended, "ETHpool is ended. Only withdrawals allowed.");
        _;  
    }
}