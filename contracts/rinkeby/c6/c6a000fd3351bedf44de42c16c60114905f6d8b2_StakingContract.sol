/**
 *Submitted for verification at Etherscan.io on 2022-06-29
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
        bool refered;
        uint256 amount;
        uint256 genBonus;
        uint256 areenaBonus;
        uint256 playerstartingTime;
        uint256 referalAmount;
        address referalPerson;
    }
        
    struct Player {

        uint256 activeBattles;
        uint256 winingBattles;
        uint256 losingBattles;
        uint256 totalAmountStaked;
        uint256 genAmountPlusBonus;
        uint256 referalAmount;
        uint256 battleCount;
        uint256 totalArenaTokens;
        mapping(uint256 => Stake) stakerecord;
    }

    struct Battle {
        bool active;
        bool joined;
        bool leaved;
        bool completed;
        address loser;
        address winner;
        address creator;
        address joiner;
        uint256 riskPercentage;
        uint256 stakeAmount;
        uint256 startingTime;
        uint256 endingTime;
        uint256 battletotaltimeIndays;
         
    }

    // struct PlayerDetail{
    //     uint256[] playerBattleIds;
    // }

    address public owner;
    uint256 public battleId;
    uint256 public genRewardPercentage;
    uint256 public areenaInCirculation;


    uint256 private minimumStake = 25;
    uint256[5] public stakeOptions = [25, 100, 250, 500, 1000];
    uint256[5] public riskOptions = [25, 50, 75];

    mapping(uint256 => Battle) public battles;
    mapping(address => Player) public players;
    mapping(address => uint256) public genLastTransaction;
    mapping(address => uint256) public areenaLastTransaction;

    address private treasuryWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    address private areenaWallet = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;


    event createBattle(address indexed battleCreator, uint256 stakeAmount, uint256 indexed battleId);
    event joinBattle(address indexed battleJoiner, uint256 stakeAmount, uint256 indexed battleId);
    event referalInfo(address joinerRefaralPerson, address creatorReferalPerson, uint256 joinerReferalAmount, uint256 creatorReferalAmount);
    
    constructor(address _genToken, address _arenaToken) {
        owner = msg.sender;
        genToken = IBEP20(_genToken);
        arenaToken = IBEP20(_arenaToken);
        genRewardPercentage = 60; //0.6%
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

    //create will be either one(1) or two(2);
    address public AAaddress;
    
    function CreateBattle(uint256 _amount, uint256 _riskPercentage, address _referalPerson) external {

        uint256 stakeAmount = checkOption (_amount);
        stakeAmount = stakeAmount.mul(1e18);

        Player storage player = players[msg.sender];

        require(stakeAmount >= minimumStake, "You must stake atleast 25 Gen tokens to enter into the battle.");
        require((genToken.balanceOf(msg.sender) + players[msg.sender].genAmountPlusBonus) >= stakeAmount,"You does not have sufficent amount of gen Token.");

        require(_riskPercentage == riskOptions[0] || _riskPercentage == riskOptions[1] || _riskPercentage == riskOptions[2], "Please chose the valid risk percentage.");
        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
         
        battleId++;
            
        Battle storage battle = battles[battleId];
        player.battleCount++;

        if(genToken.balanceOf(msg.sender) < stakeAmount){

            uint256 amountFromAddress = genToken.balanceOf(msg.sender);
            
            genToken.transferFrom(msg.sender, address(this), amountFromAddress);
        }
        else{
            genToken.transferFrom(msg.sender, address(this), stakeAmount);
        }

        if(_referalPerson != 0x0000000000000000000000000000000000000000){
            
            player.stakerecord[player.battleCount].refered = true;
            player.stakerecord[player.battleCount].referalPerson = _referalPerson;
            AAaddress = _referalPerson;
        }

        battle.stakeAmount = stakeAmount;
        battle.creator = msg.sender;
        battle.riskPercentage = _riskPercentage;

        player.activeBattles++;
        player.stakerecord[player.battleCount].playerstartingTime = block.timestamp;

        emit createBattle(msg.sender,stakeAmount,battleId);
        
    }

    
    function JoinBattle(uint256 _amount, uint256 _battleId, address joinerReferalPerson) public {

        Battle storage battle = battles[_battleId];
        Player storage player = players[msg.sender];

        uint256 stakeAmount = _amount.mul(1e18);
        
       
        require(!battle.joined && !battle.leaved, "YOu can not join this battle.");      
        require(stakeAmount == battle.stakeAmount,"Enter the exact amount of tokens to be a part of this battle.");
        require((genToken.balanceOf(msg.sender) + players[msg.sender].genAmountPlusBonus) >= stakeAmount,"You does not have sufficent amount of gen Token.");

        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");
        

        uint256 creatorDeductedAmount = calculateCreatorPercentage(stakeAmount);
        uint256 creatorAfterDeductedAmount = stakeAmount - creatorDeductedAmount;
 
        uint256 joinerDeductedAmount = calculateJoinerPercentage(stakeAmount);
        uint256 joinerAfterDeductedAmount = stakeAmount - joinerDeductedAmount;

        battle.joiner = msg.sender;

        if(battle.creator != battle.joiner){
            player.battleCount++;
        }

        if(genToken.balanceOf(msg.sender) < stakeAmount){

            uint256 amountFromAddress = genToken.balanceOf(msg.sender); 
            genToken.transferFrom(msg.sender, address(this), amountFromAddress);
        }
        else{

            genToken.transferFrom(msg.sender, address(this), stakeAmount);
        }

        if(joinerReferalPerson != 0x0000000000000000000000000000000000000000){
           
            player.stakerecord[player.battleCount].refered = true;
            
            player.stakerecord[player.battleCount].referalPerson =joinerReferalPerson;
            
            uint256 joinerReferalAmount = calculateReferalPercentage(joinerDeductedAmount);
            player.stakerecord[player.battleCount].referalAmount = joinerReferalAmount;
           
            genToken.transfer(joinerReferalPerson,joinerReferalAmount);

            uint256 sendJoinerDeductionAmount = joinerDeductedAmount - joinerReferalAmount;
            genToken.transfer(treasuryWallet, sendJoinerDeductionAmount);

            player.referalAmount += joinerReferalAmount;
        }
        else{
            genToken.transfer(treasuryWallet, joinerDeductedAmount);
        }

        if(player.stakerecord[player.battleCount].refered){
            
            uint256 creatorReferalAmount = calculateReferalPercentage(creatorDeductedAmount);
            players[battle.creator].stakerecord[players[battle.creator].battleCount].referalAmount = creatorReferalAmount;


            address creatorReferalPerson;
            creatorReferalPerson = players[battle.creator].stakerecord[players[battle.creator].battleCount].referalPerson;
           
            genToken.transfer(creatorReferalPerson,creatorReferalAmount);

            uint256 sendCreatorDeductionAmount = creatorDeductedAmount - creatorReferalAmount;
            genToken.transfer(treasuryWallet, sendCreatorDeductionAmount);
            players[battle.creator].referalAmount += creatorReferalAmount;
        }
        else{

            genToken.transfer(treasuryWallet, creatorDeductedAmount);
        }

        battle.startingTime = block.timestamp;
        battle.active = true;
        battle.joined = true;
        
        if(battle.creator != battle.joiner){
            player.activeBattles++;
        }
       
        player.totalAmountStaked += joinerAfterDeductedAmount;
        players[battle.creator].totalAmountStaked +=  creatorAfterDeductedAmount;
        players[battle.creator].stakerecord[players[battle.creator].battleCount].amount = creatorAfterDeductedAmount;
        player.stakerecord[player.battleCount].amount = joinerAfterDeductedAmount;

        emit joinBattle(msg.sender,stakeAmount,battleId);

        emit referalInfo(
            joinerReferalPerson, 
            players[battle.creator].stakerecord[players[battle.creator].battleCount].referalPerson,
            player.stakerecord[player.battleCount].referalAmount,
            players[battle.creator].stakerecord[players[battle.creator].battleCount].referalAmount
        );
    }


    function LeaveBattle(uint256 count) public {

       Battle storage battle = battles[count];

        require(msg.sender == battle.creator || msg.sender == battle.joiner, "You must be a part of a battle before leaving it.");
        require(!battle.leaved, "You canot join this battle because battle creator Already leaved.");
        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        if(!battle.joined){

            require(block.timestamp > (players[msg.sender].stakerecord[players[msg.sender].battleCount].playerstartingTime + 3 minutes),"You haveto wait atleast 3 minutes to leave battle if no one join the battle.");

            uint256 tokenAmount = battle.stakeAmount;
            
            uint256 deductedAmount = calculateSendBackPercentage(tokenAmount);
            
            tokenAmount = tokenAmount - deductedAmount;

            genToken.transfer(msg.sender, tokenAmount); 
            genToken.transfer(treasuryWallet, deductedAmount); 
           
            battle.leaved = true; 

        }
        else{

            require( !battle.completed,"This battle is already ended.");
            require(block.timestamp > (battle.startingTime + 3 minutes),"You canot leave battle before 3 minutes.");
            
            if(msg.sender == battle.creator){
                battle.loser = battle.creator;
                battle.winner = battle.joiner;
            }
            else{
                battle.loser = battle.joiner;
                battle.winner = battle.creator; 
            }

           
            uint256 losertokenAmount = players[battle.loser].stakerecord[players[battle.loser].battleCount].amount;
            uint256 winnertokenAmount = players[battle.winner].stakerecord[players[battle.winner].battleCount].amount;

            uint256 totalDays =  calculateTotaldays(block.timestamp, battle.startingTime);
 
            uint256 loserGenReward = calculateRewardInGen(losertokenAmount, totalDays);
            uint256 winnerGenReward = calculateRewardInGen(winnertokenAmount, totalDays);
     
            uint256 riskDeductionFromLoser = calculateRiskPercentage(loserGenReward, battle.riskPercentage);
             
            uint256 loserFinalGenReward = loserGenReward - riskDeductionFromLoser;

            uint256 winnerAreenaReward = calculateRewardInAreena(winnertokenAmount, totalDays);
 
            uint256 sendWinnerGenReward =  winnerGenReward + riskDeductionFromLoser + winnertokenAmount;
            uint256 sendLoserGenReward =  losertokenAmount + loserFinalGenReward;
            
            areenaInCirculation += winnerAreenaReward;
            battle.endingTime = block.timestamp;
            battle.battletotaltimeIndays = totalDays;
            battle.completed = true;
            battle.active = false;

            players[battle.winner].winingBattles++;
            players[battle.winner].genAmountPlusBonus += sendWinnerGenReward;
            players[battle.winner].totalArenaTokens += winnerAreenaReward;
            players[battle.loser].losingBattles++;
            players[battle.loser].genAmountPlusBonus += sendLoserGenReward;

            players[battle.winner].stakerecord[players[battle.winner].battleCount].genBonus = sendWinnerGenReward;
            players[battle.winner].stakerecord[players[battle.winner].battleCount].areenaBonus = winnerAreenaReward;
            players[battle.loser].stakerecord[players[battle.loser].battleCount].genBonus = sendLoserGenReward;

            if(battle.creator != battle.joiner){
                players[battle.winner].activeBattles--;
            }
            
            players[battle.loser].activeBattles--;


        }
    }

    function GenWithdraw() external {

        Player storage player = players[msg.sender];

        require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 24 hours");
        require(player.genAmountPlusBonus >= 0, "You do not have sufficent amount of tokens to withdraw.");

        uint256 sendgenReward = calculateWithdrawPercentage(player.genAmountPlusBonus);

        genToken.transfer(msg.sender,sendgenReward);
        player.genAmountPlusBonus -= sendgenReward;
        
       // genLastTransaction[msg.sender] = block.timestamp + 24 hours;
        genLastTransaction[msg.sender] = block.timestamp + 4 minutes;

    }

    function AreenaWithdraw(uint256 tokenLimit) external {

        Player storage player = players[msg.sender];

        require(areenaLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 24 hours");
        require(player.totalArenaTokens >= 0, "You do not have sufficent amount of tokens to withdraw.");
        
        uint256 sendAreenaReward = calculateWithdrawPercentage(player.totalArenaTokens);
        
        require((arenaToken.balanceOf(msg.sender) + sendAreenaReward)  <= tokenLimit, "You do not have sufficent amount of tokens to withdraw.");
        
        arenaToken.transferFrom(areenaWallet,msg.sender,sendAreenaReward);
        player.totalArenaTokens -= sendAreenaReward;
        
        // areenaLastTransaction[msg.sender] = block.timestamp + 24 hours;
        areenaLastTransaction[msg.sender] = block.timestamp + 4 minutes;

    }

    function calculateReferalPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 2500; // 25 %
        require(_initialPercentage <= 10000, "_initialPercentage fee will exceed Gen token staked amount");
        
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateWithdrawPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 500; // 5 %
        require(_initialPercentage <= 10000, "_initialPercentage fee will exceed Gen token staked amount");
        
        return _amount.mul(_initialPercentage).div(10000);
    }


    function calculateRewardInGen(uint256 _amount, uint256 _totalDays) public view returns(uint256){
 
        uint256 _initialPercentage = genRewardPercentage;
        _initialPercentage = (_initialPercentage * _totalDays);

        require(_initialPercentage <= 10000, "_initialPercentage fee will exceed Gen token staked amount");
        uint256 value =  (_amount.mul(_initialPercentage).div(10000));

        return value;
    }

    function calculateTotaldays(uint256 _endingTime, uint256 _startingTime) public pure returns(uint256 _totaldays){

       // _totaldays = ((((_endingTime - _startingTime) / 60) / 60) /24); // in days!
         _totaldays = ((_endingTime - _startingTime) / 60); // in minutes!
        return _totaldays;
    } 

    function calculateJoinerPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 3000; // 30 %
        require(_initialPercentage <= 10000, "_initialPercentage fee will exceed Gen token staked amount");
        
        return _amount.mul(_initialPercentage).div(10000);
    }
    
    
    function calculateCreatorPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 2000; // 20 % 
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

    function playerStakeDetails(address _playerAddress,uint battleCount) public view returns(Stake memory){
        
        Player storage player = players[_playerAddress];

        return player.stakerecord[battleCount];
    }

    function setGenRewardPercentage(uint256 _percentage) external  onlyOwner {

        genRewardPercentage = _percentage;
    }

    function AreenaInTreasury() external view returns(uint256){
        return arenaToken.balanceOf(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    
}