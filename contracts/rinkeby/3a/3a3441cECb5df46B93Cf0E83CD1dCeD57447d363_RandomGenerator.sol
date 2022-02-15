/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract RandomGenerator {
    address public owner;
    address[] public users;
    address[] public managers;
    uint256 public PRICE = 0.01 ether;
    uint256 public maximumRandomValue;
    uint256 public total;
    uint256 public lotteryTime;
    uint256 public betCooldown;
    uint256 private betDelay;
    uint256 private initialTime;

    struct BetValue {
        uint256 value;
        uint256 bestBet;
        bool hasValue;
    }

    mapping(address => BetValue) public bets;

    constructor(uint maximumRandom, uint initialLoteryTime, uint initialBetCooldown) {
        maximumRandomValue = maximumRandom;
        owner = msg.sender;
        initialTime = block.timestamp;
        lotteryTime = initialLoteryTime;
        betCooldown = initialBetCooldown;
    }

    function PlaceBet() public payable {
        require(msg.value == PRICE, "Not Enough ETH");
        require(block.timestamp >= betDelay, "System is in cooldown. Try again later.");
        require(block.timestamp < initialTime + lotteryTime, "The Day has already finished. Wait while we crown the winner.");
        if(!bets[msg.sender].hasValue) users.push(msg.sender);
        bets[msg.sender].value += msg.value;
        bets[msg.sender].hasValue = true;
        uint256 newBet = GetRandomNumber();
        if (bets[msg.sender].bestBet < newBet) bets[msg.sender].bestBet = newBet;
        total += msg.value;
        betDelay = block.timestamp + betCooldown;
    }

    function CrownWinners() public payable {
        require(msg.sender != owner && !IsManager(msg.sender), "Only the owner or managers can crown the winners.");
        require(IsDayFinished(), "Lottery day didn't finish yet.");
        if (users.length > 0){
            address[] memory winners = GetCurrentWinners();
            uint256 totalValueToSend = total / 5 * 4;
            total -= totalValueToSend;
            uint256 dividedValue = total / winners.length;
            for (uint i=0; i < winners.length; i++){
                (bool sent, ) = winners[i].call{value: dividedValue}("");
                require(sent, "Failed to send Ether");
            }
            ClearBets();
        }
        else ClearBets();
    }

    function GetCurrentWinners() public view returns(address[] memory) {
        uint256 bestBet = GetBestBetOfToday();
        uint totalWinners = 0;
        for (uint i=0; i < users.length; i++) if (bets[users[i]].bestBet == bestBet) totalWinners++;
        address[] memory winners = new address[](totalWinners);
        uint256 bestUsersCounter = 0;
        for (uint i=0; i < users.length; i++){ 
            if (bets[users[i]].bestBet == bestBet){ 
                winners[bestUsersCounter] = users[i];
                bestUsersCounter++;
            }
        }
        return winners;
    }

    function GetBestBetOfToday() public view returns(uint256) {
        uint256 bestBet = 0;
        for (uint i=0; i < users.length; i++){
            if (bets[users[i]].bestBet > bestBet) bestBet = bets[users[i]].bestBet;
        }
        return bestBet;
    }

    function GetRandomNumber() private view returns(uint) {
        uint result = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender))) % maximumRandomValue;
        return result;
    }

    function ClearBets() private {
        betDelay = block.timestamp;
        for (uint256 i=0; i < users.length; i++) delete bets[users[i]];
        delete users;
        initialTime = block.timestamp;
    }

    function SetMaximumRandomValue(uint256 newMaximum) public {
        require(msg.sender != owner && !IsManager(msg.sender), "Only the owner or managers can change the maximum random value.");
        require(IsDayFinished(), "Can only be changed at the end of the day, before crowning the winners.");
        maximumRandomValue = newMaximum;
    }

    function IsDayFinished() public view returns(bool) {
        return block.timestamp >= initialTime + lotteryTime;
    }

    function SetLotteryTime(uint256 timeInSeconds) public {
        require(msg.sender != owner && !IsManager(msg.sender), "Only the owner or managers can change the lottery time.");
        require(IsDayFinished(), "Can only be changed at the end of the day, before crowning the winners.");
        lotteryTime = timeInSeconds;
    }

    function IsManager(address manager) private view returns(bool) {
        for (uint i=0; i<managers.length; i++){
            if(manager == managers[i]) return true;
        }
        return false;
    }

    function AddManager(address manager) public {
        require(msg.sender != owner, "Only the owner is allowed to add new managers.");
        if (!IsManager(manager)) managers.push(manager);
    }

    function RemoveManager(address manager) public {
        require(msg.sender != owner, "Only the owner is allowed to remove managers.");
        for (uint i=0; i<managers.length; i++) {
            if (managers[i] == manager) delete managers[i];
        }
    }
}