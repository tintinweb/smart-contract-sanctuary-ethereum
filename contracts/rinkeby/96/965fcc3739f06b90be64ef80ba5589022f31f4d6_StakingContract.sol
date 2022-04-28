/**
 *Submitted for verification at Etherscan.io on 2022-04-28
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
pragma solidity ^0.8.0;


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

   constructor(address _stakingToken, address _rewardToken) {
       owner = msg.sender;
       stakingToken = IBEP20(_stakingToken);
       rewardToken = IBEP20(_rewardToken);
    }



    address public owner;
    
    uint256 public minimumStake = 2000000000000000000; // 200 TOKEN WITH 18 ZEROS ( 2 - 18 ZEROS)

    mapping(address => User) public users;

 

    struct Stake {
        uint256 stakeTime;
        uint256 amount;
        uint256 bonus;
        bool withdrawan;
    }
        
    struct User {
        uint256 userTotalStaked;
        uint256 stakeCount;
        uint256 totalRewardTokens;
        mapping(uint256 => Stake) stakerecord;
    }

    // mapping(uint256 => )

    

    function getStakingInfo(address userAddress, uint256 stakeCount) public view returns (Stake memory) {
         
        User storage user = users[userAddress];
        return user.stakerecord[stakeCount];
    }

    
    uint256 public userbalance;
    address public userbalance1;
    

    uint256 internal stakeAt;
    
    function stake(uint256 amount) public {
       
    //    require(plan >= 0 && plan < 3, "put valid plan details");
       require(amount >= minimumStake,"cant deposit need to stake more than minimum amount");
       require(msg.sender != address(0), "User address canot be zero.");
       require(owner != address(0), "Owner address canot be zero.");
        
       User storage user = users[msg.sender];
        
        userbalance = stakingToken.balanceOf(msg.sender);
        userbalance1 = msg.sender;
        
        
        stakingToken.transferFrom(msg.sender, owner, amount);
 

        user.userTotalStaked += amount;
        user.stakerecord[user.stakeCount].stakeTime = block.timestamp;
        user.stakerecord[user.stakeCount].amount = amount;

        user.stakeCount++;
        stakeAt = block.timestamp;
    }

    function returnStakeTimestamp() public view returns(uint256) {
        return stakeAt;
    }
    
    function withdraw(uint256 count) public {
        User storage user = users[msg.sender];
        
    
        require(user.stakeCount >= count, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");


        
        require(rewardToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance");
        
        user.stakerecord[user.stakeCount].bonus = rewardCalculate();

        rewardToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
        rewardToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
       
        user.stakerecord[count].withdrawan = true;
        user.totalRewardTokens += user.stakerecord[count].bonus;

    }

    function rewardCalculate() public view returns(uint256){
        
        uint256 earned = 0;
        uint256 reqa = 0;
            
        reqa = 1000000000000000000 * (block.timestamp - stakeAt) / 1 days;
        earned = reqa / 100;
        return earned;
   }

}