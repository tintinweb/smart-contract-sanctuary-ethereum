/**
 *Submitted for verification at Etherscan.io on 2022-04-04
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
        mapping(uint256 => Stake) stakerecord;
    }

    address public owner;
    
    uint256 public minimumStake = 100000;
    uint256[3] public durations = [5 minutes, 10 minutes, 15 minutes];

    mapping(address => User) public users;

    constructor(address _stakingToken, address _rewardToken) {
       owner = msg.sender;
       stakingToken = IBEP20(_stakingToken);
       rewardToken = IBEP20(_rewardToken);
    }
    
    uint256 public userbalance;
    address public userbalance1;
    
    
    function stake(uint256 amount, uint256 plan) public {
       
       require(plan >= 0 && plan < 3, "put valid plan details");
       require(amount >= minimumStake,"cant deposit need to stake more than minimum amount");
       require(msg.sender != address(0), "User address canot be zero.");
       require(owner != address(0), "Owner address canot be zero.");
        
       User storage user = users[msg.sender];
        
        userbalance = stakingToken.balanceOf(msg.sender);
        userbalance1 = msg.sender;
        
        
         stakingToken.transferFrom(msg.sender, owner, amount);
 

        user.userTotalStaked += amount;
        user.stakerecord[user.stakeCount].plan = plan;
        user.stakerecord[user.stakeCount].stakeTime = block.timestamp;
        user.stakerecord[user.stakeCount].amount = amount;
        user.stakerecord[user.stakeCount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakeCount].bonus = rewardCalculate(plan);

        user.stakeCount++;
    }

    function withdraw(uint256 count) public {
        
        User storage user = users[msg.sender];
 
        require(user.stakeCount >= count, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
        
        require(block.timestamp >= user.stakerecord[count].withdrawTime,"You can not withdraw amount before time");
        require(rewardToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance");
        

        rewardToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
        rewardToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
       
        user.stakerecord[count].withdrawan = true;
        user.totalRewardTokens += user.stakerecord[count].bonus;

    }

    function rewardCalculate(uint256 plan) public pure returns(uint256){
        if (plan == 0){
            return 1000000000000000000 ;
        }else if (plan == 1){
            return 5000000000000000000;
        }else{
            return 10000000000000000000;
        }
   }


}