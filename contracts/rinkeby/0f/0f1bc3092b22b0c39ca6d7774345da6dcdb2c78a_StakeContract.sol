/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT 
pragma solidity 0.8.9;

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
 
    interface ADAMSTAKE{
        function stakedetails(address, uint256) external view returns (uint256,uint256,uint256,uint256,bool); 
        function users(address)external returns(uint256,uint256,uint256);
    }
 
   contract StakeContract {
        using SafeMath for uint256;
        
        //Variables
        IBEP20 public wolveToken;
        IBEP20 public amdToken;
        ADAMSTAKE public stakeInstance;
 
        address payable public owner;
        bool public migrationCheck; 
        uint256 public totalUniqueStakers;
        uint256 public totalStakedTokens;
        uint256 public totalStaked;
        uint256 public minStake;
        uint256 public constant percentDivider = 100000;
        
        uint256 public newPercentage;
        uint256 public endingTime;
        uint256 public stakeTimeForEndind;

        //arrays
        uint256[4] public percentages = [0, 0, 0, 0];
        uint256[4] public APY = [8000,9000,10000,11000];
        uint256[4] public durations = [15 days, 30 days, 60 days, 90 days];

 
        //structures
        struct Stake {
            uint256 stakeTime;
            uint256 withdrawTime;
            uint256 amount;
            uint256 bonus;
            uint256 beforeExtendBonus;
            uint256 afterTimeBonus;
            uint256 plan;
            bool withdrawan;
            bool migrated;
            uint256 transactions;
            uint256 rewardToken;
            uint256 withdrawWith;
            uint256 deductedAmount;
        }
        
        struct User {
            uint256 totalstakeduser;
            uint256 stakecount;
            uint256 claimedstakeTokens;
            mapping(uint256 => Stake) stakerecord;
        }
        
        //mappings
        mapping(address => User) public users;
        mapping(address => bool) public uniqueStaker;
        uint256 public totalWolveStakeToken;
        uint256 public totalAmdStakeToken;
        uint256 public totalWolveRewardToken;
        uint256 public totalAmdRewardToken;
        
        
        //modifiers
        modifier onlyOwner() {
            require(msg.sender == owner, "Ownable: Not an owner");
            _;
        }
        
        //events
        event Staked(address indexed _user, uint256 indexed _amount, uint256 indexed _Time);
        event Withdrawn(address indexed _user, uint256 indexed _amount, uint256 indexed _Time);
        event ExtenderStake(address indexed _user, uint256 indexed _amount, uint256 indexed _Time);
        event UNIQUESTAKERS(address indexed _user);
 
   // constructor
   constructor(address wolve, address amd,address amdStaking) {
       owner = payable(msg.sender);
       wolveToken = IBEP20(wolve);
       amdToken = IBEP20(amd);
       stakeInstance=ADAMSTAKE(amdStaking);
       minStake = 45522400000000;

        for(uint256 i ; i < percentages.length;i++){
            percentages[i] = APYtoPercentage(APY[i], durations[i].div(1 days));
        }
   }


   // functions
   // StakeWithWolve
    function stakeWithWolve(uint256 amount, uint256 plan, uint rewardToken) public {
       require(plan >= 0 && plan < 4, "put valid plan details");
       require(amount >= minStake,"cant deposit need to stake more than minimum amount");
     
       if (!uniqueStaker[msg.sender]) {
           uniqueStaker[msg.sender] = true;
           totalUniqueStakers++;
           emit UNIQUESTAKERS(msg.sender);
       }
        
       User storage user = users[msg.sender];
       wolveToken.transferFrom(msg.sender, owner, amount);
 

        user.totalstakeduser += amount;
        user.stakerecord[user.stakecount].plan = plan;
        user.stakerecord[user.stakecount].stakeTime = block.timestamp;
        user.stakerecord[user.stakecount].amount = amount;
        user.stakerecord[user.stakecount].withdrawTime = block.timestamp.add(durations[plan]);
        user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).div(percentDivider);
        user.stakerecord[user.stakecount].transactions = 1;
        user.stakerecord[user.stakecount].withdrawWith = 1;
        user.stakerecord[user.stakecount].rewardToken = rewardToken;
 
        uint256 value1 = 10; // percentage that how much amount that was deducted in Wolvrine token
        uint256 deductedAmount1 = amount.mul(value1).div(100); //amount that was deducted in Wolvrine token
 
        user.stakerecord[user.stakecount].deductedAmount = deductedAmount1;

        user.stakecount++;
        totalStakedTokens += amount;
        totalWolveStakeToken+=amount;
        emit Staked(msg.sender, amount, block.timestamp);
   }
  
  //StakeWithAmd
   function stakeWithAmd(uint256 amount, uint256 plan, uint rewardToken) public {
       require(plan >= 0 && plan < 4, "put valid plan details");
       require(amount >= minStake,"cant deposit need to stake more than minimum amount");
      
       if (!uniqueStaker[msg.sender]) {
           uniqueStaker[msg.sender] = true;
           totalUniqueStakers++;
           emit UNIQUESTAKERS(msg.sender);
       }
      
       User storage user = users[msg.sender];
       amdToken.transferFrom(msg.sender, owner, amount);
 
      
       user.totalstakeduser += amount;
       user.stakerecord[user.stakecount].plan = plan;
       user.stakerecord[user.stakecount].stakeTime = block.timestamp;
       user.stakerecord[user.stakecount].amount = amount;
       user.stakerecord[user.stakecount].withdrawTime = block.timestamp.add(durations[plan]);
       user.stakerecord[user.stakecount].bonus = amount.mul(percentages[plan]).div(percentDivider);
       user.stakerecord[user.stakecount].transactions = 2;
       user.stakerecord[user.stakecount].withdrawWith = 2;
       user.stakerecord[user.stakecount].rewardToken = rewardToken;
 
       user.stakecount++;
       totalStakedTokens += amount;
       totalAmdStakeToken+=amount;
       emit Staked(msg.sender, amount, block.timestamp);
   }
 
   function withdrawInWolve(uint256 count) public {
        
        User storage user = users[msg.sender];
 
        require(user.stakecount >= count, "Invalid Stake index");
        require(user.stakerecord[count].migrated != true,"You canot withdraw migrated stake from volve.");
        require(user.stakerecord[count].withdrawWith == 1,"You canot withdraw Admantium staked token from  Wolverinu.");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(wolveToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance");
        require(user.stakerecord[count].amount != 0,"User stake amount must be greater then zero. ");
        
        checkEndingTime(msg.sender, count, user.stakerecord[count].plan); 
        require(endingTime > stakeTimeForEndind, "You cannot withdraw amount before Time.");
        
        checkAfterTimeBonus(msg.sender,count);

        wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
 
        if( user.stakerecord[count].rewardToken == 1 ){
           wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
        }else{
            require(amdToken.balanceOf(owner) >= user.stakerecord[count].bonus,"owner doesnt have enough balance in admantium token");
            amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
        }
        if(user.stakerecord[count].transactions == 1){
            require(wolveToken.balanceOf(owner) >= user.stakerecord[count].amount,"owner doesnt have enough balance for 10%");
           wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].deductedAmount);
        }
       
        if(user.stakerecord[count].beforeExtendBonus != 0){
            if(user.stakerecord[count].rewardToken == 1){
                wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].beforeExtendBonus);
            }else{
                amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].beforeExtendBonus);
            }
        }

        if(user.stakerecord[count].afterTimeBonus != 0){
            if(user.stakerecord[count].rewardToken == 1){
                wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].afterTimeBonus);
            }
            else{
                amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].afterTimeBonus);
            }
        }
        user.stakerecord[count].withdrawan = true;
        totalWolveRewardToken+= user.stakerecord[count].bonus;
        emit Withdrawn(msg.sender,user.stakerecord[count].amount,block.timestamp);
    }

    function withdrawInAmd(uint256 count) public {

       User storage user = users[msg.sender];

        require(user.stakecount >= count, "Invalid Stake index");
        require(user.stakerecord[count].withdrawWith == 2,"You canot withdraw Wolverinu staked token from Admantium.");
        require(!user.stakerecord[count].withdrawan," withdraw completed ");
        require(amdToken.balanceOf(owner) >= user.stakerecord[count].amount,"This owner doesnt have enough balance");
        
        
        if(!user.stakerecord[count].migrated){
            checkEndingTime(msg.sender, count, user.stakerecord[count].plan);
            require(endingTime > stakeTimeForEndind, "You cannot withdraw amount before Time.");
            checkAfterTimeBonus(msg.sender,count);
        }


        amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].amount);
 
        
        if( user.stakerecord[count].rewardToken == 1 ) {
     
           wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
        }
        else {
            amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].bonus);
        }
        
        if(user.stakerecord[count].transactions == 1){
            if(user.stakerecord[count].deductedAmount > 0){
                wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].deductedAmount);
            }
        }
        
        
        if(user.stakerecord[count].migrated){
            
            uint256 value1 = 10; // percentage that how much amount that was deducted in Wolvrine token
            uint256 deductedAmount2 = user.stakerecord[count].amount.mul(value1).div(100);
            amdToken.transferFrom(owner,msg.sender,deductedAmount2);   
        }
        
        if(!user.stakerecord[count].migrated){
            if(user.stakerecord[count].beforeExtendBonus != 0){
                if(user.stakerecord[count].rewardToken == 1){
                    wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].beforeExtendBonus);
                }
                else{
                    amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].beforeExtendBonus);
                }
            }

            if(user.stakerecord[count].afterTimeBonus != 0){
                if(user.stakerecord[count].rewardToken == 1){
                    wolveToken.transferFrom(owner,msg.sender,user.stakerecord[count].afterTimeBonus);
                }
                else{
                    amdToken.transferFrom(owner,msg.sender,user.stakerecord[count].afterTimeBonus);
                }
            }
        }
        
 
        user.claimedstakeTokens += user.stakerecord[count].amount;
        user.claimedstakeTokens += user.stakerecord[count].bonus;
        user.stakerecord[count].withdrawan = true;
        totalAmdRewardToken+= user.stakerecord[count].bonus;
     
       emit Withdrawn(msg.sender,user.stakerecord[count].amount,block.timestamp);
    }

    function extendStake(uint256 count,uint256 newplan) public {
       
       User storage user = users[msg.sender];
       
        require(user.stakerecord[count].withdrawan != true,"This stake is already withdrawn.");
        require(user.stakecount >= count, "Invalid Stake index");
        require(newplan >= 0 && newplan < 4 ,"Enter Valid Plan");
        require(user.stakerecord[count].plan < newplan, "Can not extend to lower plan");
        require(!user.stakerecord[count].migrated,"You canot extend migrated stake.");

        checkEndingTime(msg.sender, count, user.stakerecord[count].plan);
        
        require(endingTime < stakeTimeForEndind, "You cannot extend stake after Time is Over.");
      
        uint256 timeBefore = user.stakerecord[count].stakeTime;
        uint256 currentTime = block.timestamp;
        uint256 beforeDays = (currentTime  - timeBefore).div(1 days);
        
        calculateNewReward(msg.sender,count,user.stakerecord[count].amount, beforeDays,user.stakerecord[count].plan);

        user.stakerecord[count].plan = newplan;
        user.stakerecord[count].stakeTime = block.timestamp;
        user.stakerecord[count].withdrawTime = block.timestamp.add(durations[newplan]);
        user.stakerecord[count].bonus = user.stakerecord[count].amount.mul(percentages[newplan]).div(percentDivider);
        
        emit ExtenderStake(msg.sender,user.stakerecord[count].amount,block.timestamp);
    }


    function checkAfterTimeBonus(address userAddress,uint count) public {

        User storage user = users[userAddress];
       
        uint256 timeBefore = user.stakerecord[count].withdrawTime;
        uint256 currentTime = block.timestamp;
        uint256 nextDays = (currentTime  - timeBefore).div(1 days);
        
        calculateNextReward(userAddress, count, user.stakerecord[count].amount, nextDays, user.stakerecord[count].plan);
    }

    function checkEndingTime(address userAddress, uint256 count, uint plan) public returns(uint256){
       
        User storage user = users[userAddress];

        endingTime = (block.timestamp - user.stakerecord[count].stakeTime).div(1 days);
        stakeTimeForEndind = durations[plan].div(1 days);
        return endingTime;
    }
    
    function migrateV1(address[] memory userList) external onlyOwner returns (bool){
      
        require(!migrationCheck,"Owner  can not called this function again.");
      
       for (uint i=0; i< userList.length; i++){

            require(userList[i] != address(0),"This is not a valid address");
            
            User storage user = users[userList[i]];
            
            (uint256 _totalstakeduser, uint256 _stakecount, uint256 _claimedstakeTokens) = stakeInstance.users(userList[i]);
            require(_stakecount != 0,"He is not an old invester");
            
            uint256 count = user.stakecount;
            user.totalstakeduser += _totalstakeduser;
            user.stakecount +=  _stakecount;
            user.claimedstakeTokens += _claimedstakeTokens;
           
            for(uint256 j = 0; j < _stakecount; j++){
                
                (uint256 _withdrawTime/*,uint256 _stakeTime*/,uint256 _amount,uint256 _bonus,uint256 _plan,
                bool _withdrawan) = stakeInstance.stakedetails(userList[i],j);
                
                user.stakerecord[count].plan = _plan;
            //    user.stakerecord[j].stakeTime = _stakeTime;
                user.stakerecord[count].amount = _amount;
                user.stakerecord[count].withdrawTime = _withdrawTime;
                user.stakerecord[count].bonus = _bonus;
                user.stakerecord[count].withdrawan = _withdrawan;
                user.stakerecord[count].rewardToken = 2;
                user.stakerecord[count].transactions = 1;
                user.stakerecord[count].migrated = true;
                user.stakerecord[count].withdrawWith = 2;
                count++;
            }
        }
            migrationCheck = true;
            return migrationCheck;
    }
 
    function changeOwner(address payable _newOwner) external onlyOwner {
       owner = _newOwner;
    }
    
    function migrateStuckFunds() external onlyOwner {
       owner.transfer(address(this).balance);
    }
    
    function migratelostToken(address lostToken) external onlyOwner {
       IBEP20(lostToken).transfer(owner,IBEP20(lostToken).balanceOf(address(this)));
    }
   
    function setminimumtokens(uint256 amount) external onlyOwner {
        minStake = amount;
    }
    
    function setpercentages(uint256 amount1,uint256 amount2,uint256 amount3,uint256 amount4) external onlyOwner {
        percentages[0] = amount1;
        percentages[1] = amount2;
        percentages[2] = amount3;
        percentages[3] = amount4;
    }
    
    function stakedetails(address add, uint256 count)public view returns ( Stake memory ){
       return (users[add].stakerecord[count]);
    }

    function getAllStakeDetail(address add)public view returns (Stake[] memory ){
        
        Stake[] memory userStakingInfo = new Stake[](users[add].stakecount);
        
        for(uint counter = 0; counter < users[add].stakecount; counter++) {
            Stake storage member = users[add].stakerecord[counter];
            userStakingInfo[counter] = member;
        }
       return userStakingInfo;
    }

    function calculateRewards(uint256 amount, uint256 plan) external view returns (uint256){
       return amount.mul(percentages[plan]).div(percentDivider);
    }
    
    function calculaateNewPercentage(uint256 _newDuration,uint256 plan) public {
        
        uint256 newDuration = 1 days;
        newDuration = newDuration * _newDuration;
        newPercentage = APYtoPercentage(APY[plan], newDuration.div(1 days));

    }

    function calculateNewReward(address userAddress, uint256 userStakeCount, uint256 amount, uint256 _newDuration, uint256 plan) public{
        
        User storage user = users[userAddress]; 
        
        calculaateNewPercentage(_newDuration, plan);
        user.stakerecord[userStakeCount].beforeExtendBonus += amount.mul(newPercentage).div(percentDivider);
    }
    
    function calculateNextReward(address userAddress, uint256 userStakeCount, uint256 amount, uint256 _newDuration, uint256 plan) public {

        User storage user = users[userAddress]; 
        
        calculaateNewPercentage(_newDuration, plan);
        user.stakerecord[userStakeCount].afterTimeBonus = amount.mul(newPercentage).div(percentDivider);
    }
    
    function APYtoPercentage(uint256 apy, uint256 duration) public pure returns(uint256){
        return apy.mul(duration).div(365);
    }

    function currentStaked(address add) external view returns (uint256) {
        uint256 currentstaked;
        for (uint256 i; i < users[add].stakecount; i++) {
            if (!users[add].stakerecord[i].withdrawan) {
               currentstaked += users[add].stakerecord[i].amount;
            }
        }
        return currentstaked;
    }
    
    function getContractBalance() external view returns (uint256) {
       return address(this).balance;
    }
    
    function getContractstakeTokenBalanceOfWolve() external view returns (uint256) {
       return wolveToken.allowance(owner, address(this));
    }
    
    function getContractstakeTokenBalanceOfAmd() external view returns (uint256) {
       return amdToken.allowance(owner, address(this));
    }
    
    function getCurrentwithdrawTime() external view returns (uint256) {
       return block.timestamp;
    }
}