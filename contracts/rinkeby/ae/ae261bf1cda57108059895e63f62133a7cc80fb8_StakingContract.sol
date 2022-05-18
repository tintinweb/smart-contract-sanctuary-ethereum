/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-25
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


/////////// CONSTRUCTOR ////////////

    constructor(address _stakingToken, address _rewardToken) {
       owner = msg.sender;   // Owner of this Contract
       stakingToken = IBEP20(_stakingToken);    // Address of Staking Token
       rewardToken = IBEP20(_rewardToken);      // Address of Reward Token
    }
    

/////////// GLOBAL VARIABLES  &  ARRAYS  /////////////


//// PUBLIC VARIABLES /////

    IBEP20 public stakingToken;
    IBEP20 public rewardToken;

    address public owner;
    uint256 public balanceOfUser;


    uint256 public feeOfUnstake;     // To deduct 15 % (15 percent) of total amount when user use/call EmergencyUnstake  
    uint256 public feeOfUnstakeAll;        // To deduct 15 % (15 percent) of total amount when user use/call EmergencyUnstakeAll

    bool public isLocked = false;    



    uint256 public minimumStake = 2000000000000000000; // 2 TOKEN WITH 18 ZEROS ( 2 + 18 ZEROS)
    uint256[] public durations = [1 minutes, 2 minutes, 15 minutes];        // Time/Plan index when user can Unstake & Withdraw


    // Measure or Calcule reward based on this Amount [] 
    // Amount index to calcule APY formula of reward
    // Amount must be in 18 decimals to avoid Overflow
    uint256[] internal rewardcalculatebasedamount = [1000000000000000000, 5000000000000000000, 10000000000000000000];



///// INTERNAL VARIABLES /////


    uint256 internal userBalance;       

    uint256 internal toStaker;      // To transfer the emergencyUnstake amount to user. Used in "emergencyUnstake" function.
    uint256 internal toStakerAll;       // To transfer the emergencyUnstakeAll amount to user. Used in "emergencyUnstakeAll" function.




////////// STRUCTS /////////////



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
        uint256 allStakeTime;       // Total accumulated Time of stakes. 
        uint256 userTotalBonus;     // Total Bonus accumulated.
        bool userWithdrawAll; 
        mapping(uint256 => Stake) stakerecord;      // Keeps Record of Stake struct of each user
    }



//////////// MAPPINGS //////////////

    mapping(address => User) public users;      // Keep track of users. And give information about their stakes.



////////////// SMALL FUNCTIONS ///////////


    // Lock contract. ( No function will run except "emergencyUnstake" or "emergencyUnstakeAll" function.
    function lock() public {
        require(msg.sender == owner, "only owner can lock"); 
        isLocked = true; 
    }

    function unlock() public {
        require(msg.sender == owner, "only owner can unlock"); 

        isLocked = false; 
    }


    function stakeDetails(address add, uint256 count)public view returns ( Stake memory ){
       return (users[add].stakerecord[count]);
    }
    

    function setMinimumStake(uint256 amount) public {
        require(isLocked == false, "Contract is lock.");

        require(msg.sender == owner, "only owner can set");   
        minimumStake = amount;  

    }



//////////// PLAN RELEATED FUNCTIONS ///////////


//  Add new Plan with duration (IN SECONDS OF MINUTES) & based rewardCalculate amount.
    function addNewPlan(uint256 timeInSeconds, uint256 tokenAmount) public {
        require(isLocked == false, "Contract is lock.");      

        require(msg.sender == owner, "only owner can add");   
        durations.push(timeInSeconds);       // push duration at the end of Durations array 
        rewardcalculatebasedamount.push(tokenAmount);       // push tokenAmount (to Measure amount of reward) at the end of rewardcalculatebasedamount array
    }


    function upgradePlan(uint256 count, uint256 plan) public returns(uint256) {
        require(isLocked == false, "Contract is lock.");        


       User storage user = users[msg.sender];

        require(user.userWithdrawAll == false," withdraw completed ");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        
        require(count  < user.stakeCount, "Invalid Stake index");
        require(plan <= durations.length ,"Enter Valid Plan"); 
        require(user.stakerecord[count].plan < plan, "Can not extend to lower plan"); 


        user.stakerecord[count].plan = plan; 
        user.stakerecord[count].withdrawTime = block.timestamp.add(durations[plan]);

        user.stakerecord[count].bonus = rewardCalculate(plan, count); 


       return user.stakerecord[count].plan;

    }



////////////  MAIN STAKING FUNCTIONS ///////////




    function stake(uint256 amount, uint256 plan) public {
        require(isLocked == false, "Contract is lock."); 
       
       require(plan <= durations.length, "put valid plan details");  
       require(amount >= minimumStake,"can't deposit need to stake more than minimum amount");
       require(msg.sender != address(0), "User address canot be zero.");        
       require(owner != address(0), "Owner address canot be zero.");
        
       User storage user = users[msg.sender];
        
        
        stakingToken.transferFrom(msg.sender, owner, amount); 


        balanceOfUser = stakingToken.balanceOf(msg.sender); 


        user.userTotalStaked += amount;
        user.stakerecord[user.stakeCount].plan = plan;
        user.stakerecord[user.stakeCount].stakeTime = block.timestamp;
        user.stakerecord[user.stakeCount].amount = amount;
        user.stakerecord[user.stakeCount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakeCount].bonus = rewardCalculate(plan,user.stakeCount);


        user.userTotalBonus = user.userTotalBonus + rewardCalculate(plan,user.stakeCount);
        user.allStakeTime = user.allStakeTime + durations[plan];
        user.userWithdrawAll = false;

        user.stakeCount++;

    }



    function unStake(uint256 count) public {


        User storage user = users[msg.sender];
        require(user.userWithdrawAll == false," withdraw completed ");

        require(count  < user.stakeCount, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        require(stakingToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance");

        feeOfUnstake = user.stakerecord[count].amount.mul(1500).div(10000);        // deduct 15 % fee from user amount
        toStaker = user.stakerecord[count].amount - feeOfUnstake;      // sends amount to user with deduction

        stakingToken.transferFrom(owner,msg.sender,toStaker);
        user.stakerecord[count].withdrawan = true;

        user.userTotalStaked -= user.stakerecord[count].amount;
       
                
    }


    function withdraw(uint256 count) public {
        require(isLocked == false, "Contract is lock.");

        
        User storage user = users[msg.sender];

        require(user.userWithdrawAll == false," withdraw completed ");

        require(count  < user.stakeCount, "Invalid Stake index");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
        
        
        require(block.timestamp >= user.stakerecord[count].withdrawTime,"You cannot withdraw amount before time");
        require(rewardToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance");


        rewardToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
        rewardToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
       
        user.stakerecord[count].withdrawan = true;

        user.userTotalStaked -= user.stakerecord[count].amount;

    }




/////////// "ALL" STAKING FUNCTIONS ///////////////




function stakeAll(uint256 plan) public {
        require(isLocked == false, "Contract is lock.");

        userBalance = stakingToken.balanceOf(msg.sender);

       require(plan <= durations.length, "put valid plan details");
       require(userBalance >= minimumStake,"can't deposit need to stake more than minimum amount");
       require(msg.sender != address(0), "User address canot be zero.");
       require(owner != address(0), "Owner address canot be zero.");

       User storage user = users[msg.sender];


       

        stakingToken.transferFrom(msg.sender, owner, userBalance);

        user.userTotalStaked += userBalance;
        user.stakerecord[user.stakeCount].plan = plan;
        user.stakerecord[user.stakeCount].stakeTime = block.timestamp;
        user.stakerecord[user.stakeCount].amount = userBalance;
        user.stakerecord[user.stakeCount].withdrawTime = block.timestamp.add(durations[plan]);        

        user.stakerecord[user.stakeCount].bonus = rewardCalculate(plan,user.stakeCount);
        user.userTotalBonus = user.userTotalBonus + rewardCalculate(plan,user.stakeCount);


        user.allStakeTime = user.allStakeTime + durations[plan];        // plus the total time of stakes
       
        user.stakeCount++;


    }




    function unStakeAll() public {

        User storage user = users[msg.sender];

        require(user.userWithdrawAll == false," withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        
        require(stakingToken.balanceOf(owner) >= user.userTotalStaked,"owner doesnt have enough balance");

        feeOfUnstakeAll = user.userTotalStaked.mul(1500).div(10000);         // deduct 15 % fee from user amount
        toStakerAll = user.userTotalStaked - feeOfUnstakeAll;      // sends amount to user with deduction


        stakingToken.transferFrom(owner,msg.sender, toStakerAll);
        user.userWithdrawAll = true;

        user.userTotalStaked -= user.userTotalStaked;

    }



    function withdrawAll() public {
        require(isLocked == false, "Contract is lock.");

        User storage user = users[msg.sender];


        require(user.userWithdrawAll == false," withdraw completed ");
        require(msg.sender != address(0), "User address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");


        uint256 userTotalTime = block.timestamp + user.allStakeTime;        

        require(block.timestamp >= userTotalTime,"You cannot withdraw before time");      
        require(rewardToken.balanceOf(owner) >= user.userTotalStaked,"owner doesnt have enough balance");  

        rewardToken.transferFrom(owner,msg.sender,user.userTotalStaked);
        rewardToken.transferFrom(owner,msg.sender,user.userTotalBonus);

        user.userWithdrawAll = true;

        user.userTotalStaked -= user.userTotalStaked;

    }




//////////  REWARD / APY CALCULATE FUNCTIONS ///////////
     

    function rewardCalculate(uint256 plan,uint256 count) public view returns(uint256){


        uint256 earned = 0;
        uint256 reqa = 0;

        require(plan <= durations[plan], "Invalid plan details");

        
        User storage user = users[msg.sender];

        require(count <= user.stakeCount, "Invalid Stake index");


//      reqa = ( measured in eth to hand out rewards[eth index from array] * (time of unstake - time of stake) / 1 year
        reqa = (rewardcalculatebasedamount[plan] * ( user.stakerecord[count].withdrawTime - user.stakerecord[count].stakeTime)) / 527040 minutes;
        earned = reqa / 100;        // convert reqa in finneys with 18 decimals
        return earned;      // hence reward calculated with APY

   }


}