/**
 *Submitted for verification at Etherscan.io on 2022-07-15
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

        function balanceOf(address account) external view returns (uint256);
        function transfer(address recipient, uint256 amount) external returns (bool);
        function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
        function sell(uint256 amount) external;
    }


contract StakingContract {

    using SafeMath for uint256;
    
    IBEP20 public genToken;
    IBEP20 public arenaToken;
    IBEP20 public busdToken;

    struct Stake {

        bool refered;
        uint256 amount;
        uint256 genBonus;
        uint256 areenaBonus;
        uint256 referalAmount;
        address referalPerson;
        uint256 playerstartingTime;
    }
        
    struct Player {
        
        uint256 battleCount;
        uint256 walletLimit;
        uint256 activeBattles;
        uint256 winingBattles;
        uint256 losingBattles;
        uint256 totalGenBonus;
        uint256 referalAmount;
        uint256 totalArenaTokens;
        uint256 totalAmountStaked;
        uint256 genAmountPlusBonus;
        mapping(uint256 => Stake) battleRecord;
    }

    struct Battle {
        
        bool active;
        bool joined;
        bool leaved;
        bool completed;
        address loser;
        address winner;
        address joiner;
        address creator;
        uint256 battleTime;
        uint256 endingTime;
        uint256 stakeAmount;
        uint256 startingTime;
        uint256 riskPercentage;
    }

    address public owner;
    uint256 public battleId;
    uint256 public afterPrice = 15;
    uint256 public initialPrice = 10;
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
    address private areenaWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address private busdWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
 

    event createBattle(address indexed battleCreator, uint256 stakeAmount, uint256 indexed battleId);
    event joinBattle(address indexed battleJoiner, uint256 stakeAmount, uint256 indexed battleId);
    event referalInfo(address joinerRefaralPerson, address creatorReferalPerson, uint256 joinerReferalAmount, uint256 creatorReferalAmount);
    
    constructor(address _genToken, address _arenaToken, address _busdToken) {
        owner = msg.sender;
        genToken = IBEP20(_genToken);
        busdToken = IBEP20(_busdToken);
        arenaToken = IBEP20(_arenaToken);
        genRewardPercentage = 41666700; //0.000416667%
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
            
            player.battleRecord[player.battleCount].refered = true;
            player.battleRecord[player.battleCount].referalPerson = _referalPerson;

        }

        battle.stakeAmount = stakeAmount;
        battle.creator = msg.sender;
        battle.riskPercentage = _riskPercentage;

        player.activeBattles++;
        player.battleRecord[player.battleCount].playerstartingTime = block.timestamp;

        emit createBattle(msg.sender,stakeAmount,battleId);
        
    }

    
    function JoinBattle(uint256 _amount, uint256 _battleId, address joinerReferalPerson) public {

        Battle storage battle = battles[_battleId];
        Player storage player = players[msg.sender];

        uint256 stakeAmount = _amount.mul(1e18);
        
        require(!battle.joined && !battle.leaved, "You can not join this battle. This battle may be already joined or completed.");      
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
           
            player.battleRecord[player.battleCount].refered = true;
            
            player.battleRecord[player.battleCount].referalPerson =joinerReferalPerson;
            
            uint256 joinerReferalAmount = calculateReferalPercentage(joinerDeductedAmount);
            player.battleRecord[player.battleCount].referalAmount = joinerReferalAmount;
           
            genToken.transfer(joinerReferalPerson,joinerReferalAmount);

            uint256 sendJoinerDeductionAmount = joinerDeductedAmount - joinerReferalAmount;
            genToken.transfer(treasuryWallet, sendJoinerDeductionAmount);

            player.referalAmount += joinerReferalAmount;
        }
        else{
            genToken.transfer(treasuryWallet, joinerDeductedAmount);
        }

        if(players[battle.creator].battleRecord[players[battle.creator].battleCount].refered){
            
            uint256 creatorReferalAmount = calculateReferalPercentage(creatorDeductedAmount);
            players[battle.creator].battleRecord[players[battle.creator].battleCount].referalAmount = creatorReferalAmount;


            address creatorReferalPerson;
            creatorReferalPerson = players[battle.creator].battleRecord[players[battle.creator].battleCount].referalPerson;
           
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
        players[battle.creator].battleRecord[players[battle.creator].battleCount].amount = creatorAfterDeductedAmount;
        players[battle.joiner].battleRecord[players[battle.joiner].battleCount].amount = joinerAfterDeductedAmount;

        emit joinBattle(msg.sender,stakeAmount,battleId);

        emit referalInfo(
            joinerReferalPerson, 
            players[battle.creator].battleRecord[players[battle.creator].battleCount].referalPerson,
            player.battleRecord[player.battleCount].referalAmount,
            players[battle.creator].battleRecord[players[battle.creator].battleCount].referalAmount
        );
    }


    function LeaveBattle(uint256 count) public {

       Battle storage battle = battles[count];

        require(msg.sender == battle.creator || msg.sender == battle.joiner, "You must be a part of a battle before leaving it.");
        require(!battle.leaved, "You canot join this battle because battle creator Already leaved.");
        require(msg.sender != address(0), "Player address canot be zero.");
        require(owner != address(0), "Owner address canot be zero.");

        if(!battle.joined){
                //48hours
            require(block.timestamp > (players[msg.sender].battleRecord[players[msg.sender].battleCount].playerstartingTime + 1 minutes),"You have to wait atleast 3 minutes to leave battle if no one join the battle.");

            uint256 tokenAmount = battle.stakeAmount;
            
            uint256 deductedAmount = calculateSendBackPercentage(tokenAmount);
            
            tokenAmount = tokenAmount - deductedAmount;

            genToken.transfer(msg.sender, tokenAmount); 
            genToken.transfer(treasuryWallet, deductedAmount); 
           
            battle.leaved = true; 

        }
        else{

            require( !battle.completed,"This battle is already ended.");
            
            if(msg.sender == battle.creator){
                battle.loser = battle.creator;
                battle.winner = battle.joiner;
            }
            else{
                battle.loser = battle.joiner;
                battle.winner = battle.creator; 
            }

           
            uint256 losertokenAmount = players[battle.loser].battleRecord[players[battle.loser].battleCount].amount;
            uint256 winnertokenAmount = players[battle.winner].battleRecord[players[battle.winner].battleCount].amount;

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
            battle.battleTime = totalDays;
            battle.completed = true;
            battle.active = false;

            players[battle.winner].winingBattles++;
            players[battle.winner].genAmountPlusBonus += sendWinnerGenReward;
            players[battle.winner].totalArenaTokens += winnerAreenaReward;
            players[battle.loser].losingBattles++;
            players[battle.loser].genAmountPlusBonus += sendLoserGenReward;
            players[battle.winner].totalGenBonus += winnerGenReward;
            players[battle.loser].totalGenBonus += loserFinalGenReward;

            players[battle.winner].battleRecord[players[battle.winner].battleCount].genBonus = sendWinnerGenReward;
            players[battle.winner].battleRecord[players[battle.winner].battleCount].areenaBonus = winnerAreenaReward;
            players[battle.loser].battleRecord[players[battle.loser].battleCount].genBonus = sendLoserGenReward;

            if(battle.creator != battle.joiner){
                players[battle.winner].activeBattles--;
            }
            
            players[battle.loser].activeBattles--;

        }
    }

    function GenWithdraw(uint256 _percentage) external {

        Player storage player = players[msg.sender];
        
        require(player.genAmountPlusBonus > 0, "You do not have sufficent amount of tokens to withdraw.");

        if(_percentage == 3){
            
            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 24 hours");
            genLastTransaction[msg.sender] = block.timestamp + 2 minutes; //hours/////////////////////////

            uint256 sendgenReward = calculateWithdrawThreePercentage(player.genAmountPlusBonus);

            genToken.transfer(msg.sender,sendgenReward);
            player.genAmountPlusBonus -= sendgenReward;
        }
        else if(_percentage == 5){
            
            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 24 hours");
            genLastTransaction[msg.sender] = block.timestamp + 3 minutes; //hours//////////////////////

            uint256 sendgenReward = calculateWithdrawFivePercentage(player.genAmountPlusBonus);

            genToken.transfer(msg.sender,sendgenReward);
            player.genAmountPlusBonus -= sendgenReward;
        }
        else if(_percentage == 7){

            require(genLastTransaction[msg.sender] < block.timestamp,"You canot withdraw amount before 24 hours");
            genLastTransaction[msg.sender] = block.timestamp + 4 minutes; //hours/////////////////

            uint256 sendgenReward = calculateWithdrawSevenPercentage(player.genAmountPlusBonus);

            genToken.transfer(msg.sender,sendgenReward);
            player.genAmountPlusBonus -= sendgenReward;
        }
        else{

            require(_percentage == 3 || _percentage == 5 || _percentage == 7, "Enter the right amount of percentage.");
        }

    }

    function BuyAreenaBoster() external {

        Player storage player = players[msg.sender];

        uint256 areenaBosterPrice = 200*1e18;

        require(busdToken.balanceOf(msg.sender) >= areenaBosterPrice, "You didnt have enough amount of USD to buy Areena Boster.");
        busdToken.transferFrom(msg.sender, busdWallet, areenaBosterPrice);

        player.walletLimit += 25*1e18;
    }

    function getAreenaReward(uint256 _tokenAmount) external {
        
        Player storage player = players[msg.sender];

        if(player.walletLimit == 0){
            player.walletLimit = 10*1e18;
        }

        uint256 _walletLimit = player.walletLimit;
        _tokenAmount = _tokenAmount.mul(1e18);
        
        uint256 walletBalance = arenaToken.balanceOf(msg.sender);
        uint256 contractBalance = player.totalArenaTokens;

        require(_tokenAmount <= contractBalance,"You did not have sufficient amount of Reward tokens.");
        require((walletBalance + _tokenAmount) < _walletLimit,"Please Buy Areena Boster To get All of your reward.");

        arenaToken.transferFrom(areenaWallet, msg.sender, _tokenAmount);

        player.totalArenaTokens -= _tokenAmount;

    }


    bool private onceGreater;
    
    
    function sell(uint256 amount) external {
        
        amount = amount.mul(1e18);
        
        require(amount <= (3*1e18), "You can sell only three areena Token per day.");
        require(owner != address(0), "ERC20: approve from the zero address");
        require(msg.sender != address(0), "ERC20: approve to the zero address");
        require(arenaToken.balanceOf(msg.sender) >= amount, "You do not have sufficient amount of balance.");
        
        if(!onceGreater){
            require(busdToken.balanceOf(busdWallet) >= (102000*1e18) ,"Selling of Areena token will start when areena wallet reaches 102000.");
            onceGreater = true;
        }
        
        uint256 lowerMileStone = 101000*1e18;
        uint256 uppermileStone = 102999*1e18;
        uint256 lowerSetMileStone = 999*1e18;
        uint256 upperSetMileStone = 1000*1e18;
        
        require(busdToken.balanceOf(busdWallet) > lowerMileStone,"lowerMileStone");
        require(busdToken.balanceOf(busdWallet) <= uppermileStone,"uppermileStone");

        if(busdToken.balanceOf(busdWallet) > lowerMileStone && busdToken.balanceOf(busdWallet) <= uppermileStone){

            if(busdToken.balanceOf(owner) > (200000*1e18)){

                require(block.timestamp > areenaLastTransaction[msg.sender],"You canot sell areena token again before 24 hours.");
                
                uint256 sendAmount = amount.mul(afterPrice);
                busdToken.transferFrom(busdWallet,msg.sender, sendAmount);   
                
                areenaLastTransaction[msg.sender] = block.timestamp + 4 minutes;//////////hours////////////////

            }
            else{

                require(block.timestamp > areenaLastTransaction[msg.sender],"You canot sell areena token again before 24 hours");

                uint256 sendAmount = amount.mul(initialPrice);
                busdToken.transferFrom(busdWallet,msg.sender, sendAmount);   
                
                areenaLastTransaction[msg.sender] = block.timestamp + 4 minutes;//////////////////////hours//////////////
            }
            
        }

        uint256 walletSize = busdToken.balanceOf(busdWallet);

        if(walletSize >= uppermileStone){
            lowerMileStone = uppermileStone.sub(lowerSetMileStone);
            uppermileStone = uppermileStone.add(upperSetMileStone);
        }

    }


    function calculateReferalPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 2500; // 25 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateWithdrawThreePercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 300; // 3 %
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateWithdrawFivePercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 500; // 5 %
        return _amount.mul(_initialPercentage).div(10000);
    }
    
    function calculateWithdrawSevenPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 700; // 7 %
        return _amount.mul(_initialPercentage).div(10000);
    }
    
    function calculateRewardInGen(uint256 _amount, uint256 _totalMinutes) public view returns(uint256){
 
        uint256 _initialPercentage = genRewardPercentage;
        _initialPercentage = (_initialPercentage * _totalMinutes).div(1000000000);
       
        uint256 value =  (_amount.mul(_initialPercentage).div(10000));
        return value;
    }
    
    function calculateTotaldays(uint256 _endingTime, uint256 _startingTime) public pure returns(uint256 _totalMinutes){

        _totalMinutes = ((_endingTime - _startingTime) / 60); // in minutes!
        return _totalMinutes;
    } 

    function calculateJoinerPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 3000; // 30 %
        return _amount.mul(_initialPercentage).div(10000);
    }
    
    
    function calculateCreatorPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 2000; // 20 % 
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateRiskPercentage(uint256 _amount, uint256 _riskPercentage ) public pure returns(uint256){

        uint256 _initialPercentage =_riskPercentage.mul(100) ;
        return _amount.mul(_initialPercentage).div(10000);
    }

    function calculateSendBackPercentage(uint256 _amount) public pure returns(uint256){

        uint256 _initialPercentage = 100; // 1 %
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
        return player.battleRecord[battleCount];
    }

    function setGenRewardPercentage(uint256 _percentage) external  onlyOwner {
        genRewardPercentage = _percentage;
    }

    function plateformeEarning () public view returns(uint256){
        return genToken.balanceOf(treasuryWallet);
    }

    function AreenaInTreasury() external view returns(uint256){
        return arenaToken.balanceOf(treasuryWallet);
    }

    function GenInTreasury() external view returns(uint256){
        return arenaToken.balanceOf(areenaWallet);
    }
     
    function BusdInTreasury() external view returns(uint256){
        return arenaToken.balanceOf(busdWallet);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    
}