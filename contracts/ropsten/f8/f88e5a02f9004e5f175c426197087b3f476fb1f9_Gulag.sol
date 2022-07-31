// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./SafeMath.sol";

contract Gulag {

    using SafeMath for uint256;

    struct BattleTiming {
        uint startTime;
        bool battleStarted;
        bool wagerPeriodOver;
        bool votingPeriodOver;
    }

    struct BattleCreator {
        address battleCreator;
        uint battleCreatorNFTTokenId;
        string battleCreatorNFTChain;
        address battleCreatorNFTAddress;
    }

    struct BattleChallenger {
        address challenger;
        uint challengerNFTTokenId;
        string challengerNFTChain;
        address challengerNFTAddress;
    }

    struct Battle {
        uint battleNumber; //  index of gulag battle
        BattleCreator battleCreator;
        BattleChallenger battleChallenger;
        uint creatorVoteCount;
        BattleTiming battleTiming;
        uint challengerVoteCount;
        uint winnerOfGulag;
    }


    event Redeem(string desc, uint256 amount);
        mapping(address=> mapping(uint256=> mapping(uint256=> uint256))) public wagerByAddressForEachBattleByFighter;
        mapping(address=> mapping(uint256=> uint256)) public redemptionsByAddressForEachBattle;
        mapping(address=> mapping(uint256=> uint256)) public voteGetterByAddressForEachBattle;
        mapping(address=> mapping(uint256=> uint256)) public wagerByAdressForEachBattle;
        mapping(uint256=>uint256) public mappedTotalWagerAmountByBattleForCreator;
        mapping(uint256=>uint256) public mappedTotalWagerAmountByBattleForChallenger;

    mapping(uint => Battle) public battlesMapping;
    mapping(address => Battle) public battlesAddressMapping;
    Battle[] public battles;

    


    uint256 public stateBattleNumber;
    address payable owner;
    address public ownerAddress;
    bool public readyForBattle;
    address public newOwner;
    uint public votingTimeSeconds;
    uint public wagerPeriodTimeInSeconds = 604800;
    uint public votingPeriodTimeInSeconds = 1209600;
    uint public contractBalance=(address(this).balance);
    
    
    constructor(address _contractCaller) payable {
    owner = payable(msg.sender);
    ownerAddress = address(msg.sender);
    newOwner = _contractCaller;
    stateBattleNumber=0;
    }
    

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    
    
    function createGulag(address NftAddress,string memory NftChain,uint NftTokenId) public payable {
        require(msg.value>0,"Sorry you can't create a battle without a wager");
        require(wagerByAddressForEachBattleByFighter[msg.sender][stateBattleNumber][0]==0,"You've already deposited money for this battle");
        Battle memory newBattle = battlesMapping[stateBattleNumber];
        newBattle.battleCreator.battleCreator=msg.sender;
        newBattle.battleCreator.battleCreatorNFTAddress=NftAddress;
        newBattle.battleCreator.battleCreatorNFTChain=NftChain;
        newBattle.battleCreator.battleCreatorNFTTokenId=NftTokenId;
        newBattle.battleNumber=stateBattleNumber;
        newBattle.battleTiming.battleStarted=false;
        newBattle.battleTiming.wagerPeriodOver=false;
        newBattle.battleTiming.votingPeriodOver=false;
        wagerByAddressForEachBattleByFighter[msg.sender][stateBattleNumber][0]=msg.value;
        mappedTotalWagerAmountByBattleForCreator[stateBattleNumber]=msg.value;
        stateBattleNumber++;
        battles.push(newBattle);
    }
    
    uint256 public mult1;
    uint256 public div1;
    uint256 public devFee;
    uint256 public totalBattleWagerByCreatorAndChallenger;

    function redeemEarnings(uint _battleNumber) public payable {
        Battle memory indBattle = battles[_battleNumber];
        require(indBattle.battleTiming.startTime>0,"Battle hasn't started yet");
        require ((block.timestamp-indBattle.battleTiming.startTime)>wagerPeriodTimeInSeconds,"Wager period hasn't finished yet");
        require ((block.timestamp-indBattle.battleTiming.startTime)>(votingPeriodTimeInSeconds),"voting period hasn't finished yet");
        if (indBattle.creatorVoteCount==indBattle.challengerVoteCount) {
            // battle was a tie - send original wager back
            require((wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]>0)||(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][1]>0),"Sorry, you didn't wager on either participant in this gulag");
            require(redemptionsByAddressForEachBattle[msg.sender][_battleNumber]==0,"You've already redeemed your winnings for this battle");
            if (wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]>0) {
                // if redeemer wagered on creator
                redemptionsByAddressForEachBattle[msg.sender][_battleNumber]=wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0];
                payable(msg.sender).transfer(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]);
            }
            else {
                // if redeemer wagered on challenger
                redemptionsByAddressForEachBattle[msg.sender][_battleNumber]=wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][1];
                payable(msg.sender).transfer(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][1]);
            }
        }
            else if (indBattle.creatorVoteCount>indBattle.challengerVoteCount) {
                // creator received more votes than challenger
                if (indBattle.battleCreator.battleCreator==msg.sender) {
                    // send battle creator original bet and losing bet from challenger minus 5% (side pot)
                    mult1 = (wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]+wagerByAddressForEachBattleByFighter[indBattle.battleChallenger.challenger][_battleNumber][1]);
                    mult1 = mult1.mul(95);
                    div1 = mult1.div(100);
                    redemptionsByAddressForEachBattle[msg.sender][_battleNumber]=div1;
                    payable(msg.sender).transfer(div1);
                }
                else if (msg.sender==ownerAddress) {
                    // dev fee
                    mult1 = ((mappedTotalWagerAmountByBattleForChallenger[_battleNumber]-wagerByAddressForEachBattleByFighter[indBattle.battleChallenger.challenger][_battleNumber][1]));
                    mult1 = mult1.mul(1);
                    div1 = mult1.div(100);
                    redemptionsByAddressForEachBattle[msg.sender][_battleNumber]=div1;
                    payable(msg.sender).transfer(div1);
                }
                else {
                // give wagerer percent of losing pot + percent of side pot
                require(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]>0,"Sorry, you didn't wager on the winner (creator) of this gulag");
                require(redemptionsByAddressForEachBattle[msg.sender][_battleNumber]==0,"You've already redeemed your winnings for this battle");
                mult1 = (wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]);
                totalBattleWagerByCreatorAndChallenger=mappedTotalWagerAmountByBattleForChallenger[_battleNumber]+mappedTotalWagerAmountByBattleForCreator[_battleNumber];
                totalBattleWagerByCreatorAndChallenger=totalBattleWagerByCreatorAndChallenger.mul(5).div(100);
                mult1 = mult1.mul((mappedTotalWagerAmountByBattleForChallenger[_battleNumber]-wagerByAddressForEachBattleByFighter[indBattle.battleChallenger.challenger][_battleNumber][1]+totalBattleWagerByCreatorAndChallenger));
                div1 = mult1.div((mappedTotalWagerAmountByBattleForCreator[_battleNumber]-wagerByAddressForEachBattleByFighter[indBattle.battleCreator.battleCreator][_battleNumber][0]));
                devFee = (wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]-wagerByAddressForEachBattleByFighter[indBattle.battleCreator.battleCreator][_battleNumber][0]);
                devFee = devFee.div(100);
                redemptionsByAddressForEachBattle[msg.sender][_battleNumber]=(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]+div1-devFee);
                payable(msg.sender).transfer(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][0]+div1-devFee);
                }
            }
            else if (indBattle.creatorVoteCount<indBattle.challengerVoteCount) {
                if (indBattle.battleChallenger.challenger==msg.sender) {
                    // send battle creator original bet and losing bet from challenger
                    mult1 = (wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][1]+wagerByAddressForEachBattleByFighter[indBattle.battleCreator.battleCreator][_battleNumber][0]);
                    mult1 = mult1.mul(95);
                    div1 = mult1.div(100);
                    redemptionsByAddressForEachBattle[msg.sender][_battleNumber]=div1;
                    payable(msg.sender).transfer(div1);
                }
                else if (msg.sender==ownerAddress) {
                    // dev fee
                    mult1 = ((mappedTotalWagerAmountByBattleForCreator[_battleNumber]-wagerByAddressForEachBattleByFighter[indBattle.battleChallenger.challenger][_battleNumber][0]));
                    devFee = mult1.div(100);
                    redemptionsByAddressForEachBattle[msg.sender][_battleNumber]=devFee;
                    payable(msg.sender).transfer(devFee);
                }
                else {
                // give wagerer percent of losing pot + percent of side pot
                require(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][1]>0,"Sorry, you didn't wager on the winner (challenger) of this gulag");
                require(redemptionsByAddressForEachBattle[msg.sender][_battleNumber]==0,"You've already redeemed your winnings for this battle");
                mult1 = (wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][1]);
                totalBattleWagerByCreatorAndChallenger=mappedTotalWagerAmountByBattleForChallenger[_battleNumber]+mappedTotalWagerAmountByBattleForCreator[_battleNumber];
                totalBattleWagerByCreatorAndChallenger=totalBattleWagerByCreatorAndChallenger.mul(5).div(100);
                mult1 = mult1.mul((mappedTotalWagerAmountByBattleForCreator[_battleNumber]-wagerByAddressForEachBattleByFighter[indBattle.battleCreator.battleCreator][_battleNumber][0]+totalBattleWagerByCreatorAndChallenger));
                div1 = mult1.div((mappedTotalWagerAmountByBattleForChallenger[_battleNumber]-wagerByAddressForEachBattleByFighter[indBattle.battleChallenger.challenger][_battleNumber][0]));
                redemptionsByAddressForEachBattle[msg.sender][_battleNumber]=(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][1]+div1);
                payable(msg.sender).transfer(wagerByAddressForEachBattleByFighter[msg.sender][_battleNumber][1]+div1);
                }
        }
        }

    function joinGulag(uint battleNumber, string memory NftChain,address NftAddress,uint NftTokenId) public payable{
        require(msg.value>0,"sorry - you need to send a wager greater than zero");
        BattleCreator storage indBattleCreator = battles[battleNumber].battleCreator;
        BattleChallenger storage indBattleChallenger = battles[battleNumber].battleChallenger;
        BattleTiming storage indBattleTiming = battles[battleNumber].battleTiming;
        require(msg.value>=wagerByAddressForEachBattleByFighter[indBattleCreator.battleCreator][battleNumber][0],"Your bet doesn't at least match the person who created this battle");
        require(indBattleTiming.battleStarted== false,"Sorry, this gulag is full!");
        require(indBattleCreator.battleCreator!=msg.sender,"Sorry, you can't join the battle - you created it!");
        indBattleChallenger.challenger=msg.sender;
        indBattleTiming.startTime=block.timestamp;
        indBattleChallenger.challengerNFTAddress=NftAddress;
        indBattleChallenger.challengerNFTTokenId=NftTokenId;
        indBattleChallenger.challengerNFTChain=NftChain;
        mappedTotalWagerAmountByBattleForChallenger[battleNumber]=msg.value;
        wagerByAddressForEachBattleByFighter[msg.sender][battleNumber][1]=msg.value;
        indBattleTiming.battleStarted=true;
    }

    function voteForNFT(uint battleNumber, uint voteGetter) public {
        require(voteGetter==1 || voteGetter==2,"Invalid vote");
        require(voteGetterByAddressForEachBattle[msg.sender][battleNumber]==0,"Sorry, you've already voted");
        Battle storage indBattle = battles[battleNumber];
        require(indBattle.battleTiming.startTime>0,"sorry - this battle hasn't started yet");
        require((block.timestamp-indBattle.battleTiming.startTime)>wagerPeriodTimeInSeconds,"Wager period hasn't finished yet - you can't vote!");
        require((block.timestamp-indBattle.battleTiming.startTime)<(votingPeriodTimeInSeconds),"Voting period is over");
        require(indBattle.battleTiming.battleStarted==true,"Battle hasn't even started yet");
        voteGetterByAddressForEachBattle[msg.sender][battleNumber]=voteGetter;
        if (voteGetter==1) {
            indBattle.creatorVoteCount++;
            voteGetterByAddressForEachBattle[msg.sender][battleNumber]=1;
        }
        else if (voteGetter==2) {
            indBattle.challengerVoteCount++;
            voteGetterByAddressForEachBattle[msg.sender][battleNumber]=2;
        }
        }

    function wagerOnNFT(uint battleNumber, uint wagerGetter) public payable {
        require(msg.value>0,"sorry - you need to send a wager greater than zero");
        require(wagerGetter==1 || wagerGetter==2,"Invalid vote");
        require(wagerByAddressForEachBattleByFighter[msg.sender][battleNumber][0]==0&&wagerByAddressForEachBattleByFighter[msg.sender][battleNumber][1]==0,"Sorry, you've already wagered");
        Battle memory indBattle = battles[battleNumber];
        require(indBattle.battleTiming.battleStarted==true,"Battle hasn't even started yet");
        require(indBattle.battleTiming.startTime>0,"sorry - this battle hasn't started yet");
        require((block.timestamp-indBattle.battleTiming.startTime)<wagerPeriodTimeInSeconds,"Sorry - the wager period for this battle is over");
        voteGetterByAddressForEachBattle[msg.sender][battleNumber]=wagerGetter;
        if (wagerGetter==1) {
            wagerByAddressForEachBattleByFighter[msg.sender][battleNumber][0]=msg.value;
            uint valueHere = mappedTotalWagerAmountByBattleForCreator[battleNumber];
            mappedTotalWagerAmountByBattleForCreator[battleNumber]=(msg.value+valueHere);
        }
        else if (wagerGetter==2) {
            wagerByAddressForEachBattleByFighter[msg.sender][battleNumber][1]=msg.value;
            uint valueHere = mappedTotalWagerAmountByBattleForChallenger[battleNumber];
            mappedTotalWagerAmountByBattleForChallenger[battleNumber]=(msg.value+valueHere);
        }
        }

    fallback() external payable {}

    receive() external payable {}
  }