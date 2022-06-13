/**
 *Submitted for verification at Etherscan.io on 2022-06-13
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
    
    IBEP20 public genToken;
    IBEP20 public arenaToken;

    struct Stake {
        uint256 stakeTime;
        uint256 withdrawTime;
        uint256 amount;
        uint256 bonus;
        bool withdrawan;
    }
        
    struct Player {
        
        uint256 playerBattleId;
        uint256 winingBattles;
        uint256 losingBattles;
        uint256 totalAmountStaked;
        uint256 stakeCount;
        uint256 totalArenaTokens;
        mapping(uint256 => Stake) stakerecord;
    }

    struct Battle {
        bool active;
        bool joined;
        bool leaved;
        address loser;
        address winner;
        address creator;
        address joiner;
        uint256 riskPercentage;
        uint256 stakeAmount;
        uint256 startingTime;
        uint256 endingTime;
        uint256 battletotaltimeIndays;
        mapping(address => Player) players;
       
    }

    address public owner;
    uint256 public battleId;

    uint256 private minimumStake = 25 * 1e18;
    uint256[5] public stakeOptions = [25 * 1e18, 100 * 1e18, 250 * 1e18, 500 * 1e18, 1000 * 1e18];
    uint256[5] public riskOptions = [25, 50, 75];

    mapping(uint256 => Battle) public battles;

    address private treasuryWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address private areenaWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    
    constructor(address _genToken, address _arenaToken) {
       owner = msg.sender;
       genToken = IBEP20(_genToken);
       arenaToken = IBEP20(_arenaToken);
    }

    
    
    function checkOption (uint256 amount) internal view returns(uint256){
        uint256 value;
        for(uint256 i =0; i < 5; i++){
            if(amount == stakeOptions[i]){
                value = stakeOptions[i];
                break;
            }
        }
        if (value !=0){
            return value;
        }
        else{
            return amount;
        }
    }
    
    function CreateBattle(uint256 _amount, uint256 _riskPercentage) public {

        uint256 stakeAmount = checkOption (_amount);
       
        require(stakeAmount >= minimumStake, "You must stake atleast 25 Gen tokens to enter into the battle.");
        require(_riskPercentage == riskOptions[0] || _riskPercentage == riskOptions[1] || _riskPercentage == riskOptions[2], "Please chose the valid risk percentage.");
        require(genToken.balanceOf(msg.sender) >= stakeAmount,"You does not have sufficent amount of gen Token.");
        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
        
        battleId++;
        
        Battle storage battle = battles[battleId];
        
        genToken.transferFrom(msg.sender, address(this), stakeAmount);
        
        battle.stakeAmount = stakeAmount;
        battle.creator = msg.sender;
        battle.riskPercentage = _riskPercentage;

        battle.players[battle.creator].stakeCount++;
        battle.players[battle.creator].playerBattleId++;

        battle.players[battle.creator].stakerecord[battle.players[battle.creator].stakeCount].stakeTime = block.timestamp;
    }

    
    function JoinBattle(uint256 _amount, uint256 _battleId) public {

        Battle storage battle = battles[_battleId];
       
        require(!battle.joined && !battle.leaved, "YOu can not join this battle.");      
        require(_amount == battle.stakeAmount,"Enter the exact amount of tokens to be a part of this battle.");
        require(genToken.balanceOf(msg.sender) >= _amount,"You does not have sufficent amount of gen Token.");
        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
        

        uint256 creatorDeductedAmount = calculateCreatorPercentage(_amount);
        uint256 creatorAfterDeductedAmount = _amount - creatorDeductedAmount;
 
        uint256 joinerDeductedAmount = calculateJoinerPercentage(_amount);
        uint256 joinerAfterDeductedAmount = _amount - joinerDeductedAmount;
        
        genToken.transferFrom(msg.sender, address(this), _amount);
    
        genToken.transfer(treasuryWallet, joinerDeductedAmount);

        genToken.transfer(treasuryWallet, creatorDeductedAmount);

        battle.joiner = msg.sender;
        battle.startingTime = block.timestamp;
        battle.active = true;
        battle.joined = true;


        battle.players[battle.joiner].stakeCount++;
        battle.players[battle.joiner].playerBattleId++;
        battle.players[battle.joiner].totalAmountStaked += joinerAfterDeductedAmount;
        
        battle.players[battle.creator].totalAmountStaked +=  creatorAfterDeductedAmount;
        battle.players[battle.creator].stakerecord[battle.players[battle.creator].stakeCount].amount = creatorAfterDeductedAmount;

        battle.players[battle.joiner].stakerecord[battle.players[battle.joiner].stakeCount].stakeTime = block.timestamp;
        battle.players[battle.joiner].stakerecord[battle.players[battle.joiner].stakeCount].amount = joinerAfterDeductedAmount;

    }


    function LeaveBattle(uint256 count) public {

       Battle storage battle = battles[count];


        require(msg.sender == battle.creator || msg.sender == battle.joiner, "You must be a part of a battle before leaving it.");
        require(!battle.leaved, "You canot join this battle because battle creator Already leaved.");
        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        if(!battle.joined){

            require(block.timestamp > (battle.startingTime + 2 minutes),"You haveto wait atleast 48 hours to leave battle if no one join the battle.");

            uint256 tokenAmount = battle.stakeAmount;
            
            uint256 deductedAmount = calculateSendBackPercentage(tokenAmount);
            
            tokenAmount = tokenAmount - deductedAmount;

            genToken.transfer(msg.sender, tokenAmount); 
            genToken.transfer(treasuryWallet, deductedAmount); 
           
            battle.leaved = true;
           

        }
        else{

            require( !battle.players[battle.loser].stakerecord[battle.players[battle.loser].stakeCount].withdrawan &&
            !battle.players[battle.winner].stakerecord[battle.players[battle.winner].stakeCount].withdrawan,
            "This battle is already ended.");
            
            if(msg.sender == battle.creator){
                battle.loser = battle.creator;
                battle.winner = battle.joiner;
            }
            else{
                battle.loser = battle.joiner;
                battle.winner = battle.creator; 
            }

           
            uint256 losertokenAmount = battle.players[battle.loser].stakerecord[battle.players[battle.loser].stakeCount].amount;
            uint256 winnertokenAmount = battle.players[battle.winner].stakerecord[battle.players[battle.winner].stakeCount].amount;
 
            uint256 totalDays =  calculateTotaldays(block.timestamp, battle.startingTime);
 
            uint256 loserGenReward = calculateRewardInGen(losertokenAmount, totalDays);
            uint256 winnerGenReward = calculateRewardInGen(winnertokenAmount, totalDays);
     
            uint256 riskDeductionFromLoser = calculateRiskPercentage(loserGenReward, battle.riskPercentage);
             
            uint256 loserFinalGenReward = loserGenReward - riskDeductionFromLoser;

            uint256 winnerAreenaReward = calculateRewardInAreena(winnertokenAmount, totalDays);
 
            uint256 sendWinnerGenReward =  winnerGenReward + riskDeductionFromLoser + winnertokenAmount;
            uint256 sendLoserGenReward =  losertokenAmount + loserFinalGenReward;

            
            
            genToken.transfer(battle.loser, sendLoserGenReward);
            genToken.transfer(battle.winner, sendWinnerGenReward);
            
            arenaToken.transferFrom(areenaWallet, battle.winner, winnerAreenaReward);
            

            battle.endingTime = block.timestamp;
            battle.battletotaltimeIndays = totalDays;

            battle.players[battle.winner].winingBattles++;
            battle.players[battle.winner].totalArenaTokens += winnerAreenaReward;
            battle.players[battle.loser].losingBattles++;

            battle.players[battle.winner].stakerecord[battle.players[battle.winner].stakeCount].withdrawTime = block.timestamp;
            battle.players[battle.winner].stakerecord[battle.players[battle.winner].stakeCount].bonus = winnerAreenaReward;
            battle.players[battle.winner].stakerecord[battle.players[battle.winner].stakeCount].withdrawan = true;

            battle.players[battle.loser].stakerecord[battle.players[battle.loser].stakeCount].withdrawTime = block.timestamp;
            battle.players[battle.loser].stakerecord[battle.players[battle.loser].stakeCount].bonus = loserFinalGenReward;
            battle.players[battle.loser].stakerecord[battle.players[battle.loser].stakeCount].withdrawan = true;


        }
    }

    function calculateRewardInGen(uint256 _amount, uint256 _totalDays) public pure returns(uint256){
 
        uint256 _initialPercentage = 100; // 1%
        _initialPercentage = _initialPercentage * _totalDays;

        require(_initialPercentage <= 10000, "_initialPercentage fee will exceed Gen token staked amount");
        uint256 value =  _amount.mul(_initialPercentage).div(10000);
        
        return value;

    }

    function calculateTotaldays(uint256 _endingTime, uint256 _startingTime) public pure returns(uint256 _totaldays){

       // _totaldays = ((((_endingTime - _startingTime) / 60) / 60) /24); // in days!
         _totaldays = ((_endingTime - _startingTime) / 60); // in minutes!
        return _totaldays;
    } 

    function calculateJoinerPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 1000; // 10 %
        require(_initialPercentage <= 10000, "_initialPercentage fee will exceed Gen token staked amount");
        
        return _amount.mul(_initialPercentage).div(10000);
    }
    
    function calculateCreatorPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 500; // 5 % 
        require(_initialPercentage <= 10000, "_initialPercentage fee will exceed Gen token staked amount");
        
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateRiskPercentage(uint256 _amount, uint256 _riskPercentage ) public pure returns(uint256){

        uint256 _initialPercentage =_riskPercentage.mul(100) ;
        require(_initialPercentage <= 10000, "_initialPercentageCreator fee will exceed Gen token staked amount");
        
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateSendBackPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 100; // 1 %
        require(_initialPercentage <= 10000, "_initialPercentage fee will exceed Gen token staked amount");
        
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateRewardInAreena (uint256 _amount, uint256 _battleLength) public view  returns(uint256){
    
        if( arenaToken.balanceOf(areenaWallet) <= 10000 || arenaToken.balanceOf(areenaWallet) >= 9000){
            return (((1 *_amount).div(525600)).mul(_battleLength));  
        }

        else if( arenaToken.balanceOf(areenaWallet) <= 8999 || arenaToken.balanceOf(areenaWallet) >= 8000){
            return (((9 *_amount).div(525600)).mul(_battleLength)).div(10);  
        }

        else if( arenaToken.balanceOf(areenaWallet) <= 7999 || arenaToken.balanceOf(areenaWallet) >= 7000){
            return (((8 *_amount).div(525600)).mul(_battleLength)).div(10);  
        }

        else if( arenaToken.balanceOf(areenaWallet) >= 6999 || arenaToken.balanceOf(areenaWallet) >= 6000){
            return (((7 *_amount).div(525600)).mul(_battleLength)).div(10);
        }

        else if( arenaToken.balanceOf(areenaWallet) <= 5999 || arenaToken.balanceOf(areenaWallet) >= 5000){
            return (((6 *_amount).div(525600)).mul(_battleLength)).div(10);
        }

        else if( arenaToken.balanceOf(areenaWallet) <= 4999 || arenaToken.balanceOf(areenaWallet) >= 4000){
            return (((5 *_amount).div(525600)).mul(_battleLength)).div(10);
        }

        else if( arenaToken.balanceOf(areenaWallet) <= 3999 || arenaToken.balanceOf(areenaWallet) >= 3000){
            return (((4 *_amount).div(525600)).mul(_battleLength)).div(10);
        }

        else if( arenaToken.balanceOf(areenaWallet) <= 2999 || arenaToken.balanceOf(areenaWallet) >= 2000){
           return (((3 *_amount).div(525600)).mul(_battleLength)).div(10);
        }

        else if( arenaToken.balanceOf(areenaWallet) <= 1999 || arenaToken.balanceOf(areenaWallet) >= 1000){
           return (((2 *_amount).div(525600)).mul(_battleLength)).div(10);
        }

        else if( arenaToken.balanceOf(areenaWallet) <= 999 || arenaToken.balanceOf(areenaWallet) >= 1){
           return (((1 *_amount).div(525600)).mul(_battleLength)).div(10);
        }
        else{
            return 0;
        } 
    }

    function joinerDetails(uint256 _count)public view returns (uint256 playerBattleId, uint256 winingBattles, uint256 losingBattles, uint256 totalAmountStaked, uint256 stakeCount, uint256 totalArenaTokens){
        
        Battle storage battle = battles[_count];
        
        playerBattleId =  battle.players[battle.joiner].playerBattleId;
        winingBattles  = battle.players[battle.joiner].winingBattles;
        losingBattles = battle.players[battle.joiner].losingBattles;
        totalAmountStaked = battle.players[battle.joiner].totalAmountStaked;
        stakeCount = battle.players[battle.joiner].stakeCount;
        totalArenaTokens = battle.players[battle.joiner].totalArenaTokens;
        
        return (playerBattleId, winingBattles, losingBattles , totalAmountStaked, stakeCount, totalArenaTokens);
    }

    function creatorDetails(uint256 _count)public view returns (uint256 playerBattleId, uint256 winingBattles, uint256 losingBattles, uint256 totalAmountStaked, uint256 stakeCount, uint256 totalArenaTokens){
       
       Battle storage battle = battles[_count];
        
        playerBattleId =  battle.players[battle.creator].playerBattleId;
        winingBattles  = battle.players[battle.creator].winingBattles;
        losingBattles = battle.players[battle.creator].losingBattles;
        totalAmountStaked = battle.players[battle.creator].totalAmountStaked;
        stakeCount = battle.players[battle.creator].stakeCount;
        totalArenaTokens = battle.players[battle.creator].totalArenaTokens;
        
        return (playerBattleId, winingBattles, losingBattles , totalAmountStaked, stakeCount, totalArenaTokens);
    }

    function creatorStakeDetails(uint _count) public view returns(Stake memory){

        Battle storage battle = battles[_count];
        return battle.players[battle.creator].stakerecord[battle.players[battle.creator].stakeCount];
    }

    function joinerStakeDetails(uint _count) public view returns(Stake memory){

        Battle storage battle = battles[_count];
        return battle.players[battle.joiner].stakerecord[battle.players[battle.joiner].stakeCount];
    }
    
}