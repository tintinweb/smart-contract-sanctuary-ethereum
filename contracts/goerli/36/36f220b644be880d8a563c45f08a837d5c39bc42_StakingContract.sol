/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-30
*/

//library
library SafeMath {
   function add(uint256 a, uint256 b) internal pure returns (uint256) {
       uint256 c = a + b;
       require(c >= a, "SafeMath: addition overflow");
 
       return c;
   }
 
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
       return sub(a, b, "SafeMath: subtraction overflow");
   }
 
   function sub(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
       require(b <= a, errorMessage);
       uint256 c = a - b;
 
       return c;
   }
 
   function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
           return 0;
       }
 
       uint256 c = a * b;
       require(c / a == b, "SafeMath: multiplication overflow");
 
       return c;
   }
 
   function div(uint256 a, uint256 b) internal pure returns (uint256) {
       return div(a, b, "SafeMath: division by zero");
   }
 
   function div(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
       require(b > 0, errorMessage);
       uint256 c = a / b;
       return c;
   }
 
   function mod(uint256 a, uint256 b) internal pure returns (uint256) {
       return mod(a, b, "SafeMath: modulo by zero");
   }
 
   function mod(
       uint256 a,
       uint256 b,
       string memory errorMessage
   ) internal pure returns (uint256) {
       require(b != 0, errorMessage);
       return a % b;
   }
}

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.9;


interface IBEP20 {

        function totalSupply() external view returns (uint256);
        
        function decimals() external view returns (uint8);
        
        function symbol() external view returns (string memory);
        
        function name() external view returns (string memory);
        
        function balanceOf(address account) external view returns (uint256);
        
        function transfer(address recipient, uint256 amount) external returns (bool);
        
        function allowance(address _owner, address spender) external view returns (uint256);
        
        function approve(address spender, uint256 amount) external returns (bool);
        
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        
        event Transfer(address indexed from, address indexed to, uint256 value);
        event Approval(address indexed owner,address indexed spender,uint256 value);
    }
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
contract StakingContract {

    using SafeMath for uint256;
    
    IBEP20 public stakingToken;
    IBEP20 public rewardToken;

    struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 bonus;
        uint256 plan;
        bool withdrawan;
    }
        
    struct User {
        uint256 userTotalStaked;
        uint256 stakeCount;
        uint256 totalRewardTokens;
    }

    address public owner;
    
    uint256 public minimumStake = 2*1e18;
    uint256[3] public durations = [5 minutes, 10 minutes, 15 minutes];

    mapping(uint256 => Stake) public stakerecord;
    mapping(address => User) public users;

    event stakeEvent(address stakeHolder, uint256 stakeAmount, uint256 stakeHolderPlan, uint256 stakeHolderStakeCount);
    event unStakeEvent(address stakeHolder, uint256 stakeAmount, uint256 stakeBonus, bool stakewithdrawn);
    event rewardEvent(uint256 totalReward, uint256 stakeHolderPlan);

    constructor(address _stakingToken, address _rewardToken) {
       owner = msg.sender;
       stakingToken = IBEP20(_stakingToken);
       rewardToken = IBEP20(_rewardToken);
    }
    
    
    function stake(uint256 amount, uint256 plan) public {
       
        require(plan >= 0 && plan < 3, "put valid plan details");
        require(amount >= minimumStake,"cant deposit need to stake more than minimum amount");
            
        User storage user = users[msg.sender];
        user.stakeCount++;
            
        stakingToken.transferFrom(msg.sender, address(this), amount);
    

        user.userTotalStaked += amount;
        stakerecord[user.stakeCount].plan = plan;
        stakerecord[user.stakeCount].stakeTime = block.timestamp;
        stakerecord[user.stakeCount].amount = amount;
        stakerecord[user.stakeCount].withdrawTime = block.timestamp.add(durations[plan]);
        stakerecord[user.stakeCount].bonus = rewardCalculate(plan);

        emit stakeEvent(msg.sender, amount, plan, user.stakeCount);
    }

    function withdraw(uint256 count) public {
        
        User storage user = users[msg.sender];
 
        require(user.stakeCount >= count, "Invalid Stake index");
        require(!stakerecord[count].withdrawan," withdraw completed ");
        require(block.timestamp > stakerecord[count].withdrawTime,
            "You can not withdraw amount before time");
        require(rewardToken.balanceOf(address(this)) >= stakerecord[count].amount,
            "contract didnt have enough amout to give reward");
        

        rewardToken.transfer(msg.sender,stakerecord[count].amount);
        rewardToken.transfer(msg.sender,stakerecord[count].bonus);
       
        stakerecord[count].withdrawan = true;
        user.totalRewardTokens += stakerecord[count].bonus;

        emit unStakeEvent(msg.sender,stakerecord[count].amount,stakerecord[count].bonus, stakerecord[count].withdrawan);

    }

    function rewardCalculate(uint256 plan) public  returns(uint256){
        if (plan == 0){

            emit rewardEvent(1000000000000000000, plan);
            return 1000000000000000000 ;

        }else if (plan == 1){

            emit rewardEvent(5000000000000000000, plan);
            return 5000000000000000000;

        }else{

            emit rewardEvent(10000000000000000000, plan);
            return 10000000000000000000;
        }
   }


}