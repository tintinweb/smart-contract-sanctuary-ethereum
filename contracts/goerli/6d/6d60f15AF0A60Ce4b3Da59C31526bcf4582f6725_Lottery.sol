// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

// Lottery contract 
// to subscribe entrance fee is 0.1 ether
// store subscribed players
// pick a winner randomly on specified date
// send 90% of the contract balance to the winner
// send 10% of the contract balance to the manager
// reset the contract for the next lottery


contract Lottery {
    address public manager;
    address payable[] public players;
    address public winner;
    uint public balance;
    uint public playersCount;
    uint public lotteryDate;
    uint public lotteryDuration;
    uint public lotteryFee;
    uint public lotteryFeePercentage;
    uint public lotteryFeeAmount;
    uint public lotteryPrize;
    uint public lotteryPrizePercentage;
    uint public lotteryPrizeAmount;


    constructor() {
        manager = msg.sender;
        lotteryDate = block.timestamp + 1 days;
        lotteryDuration = 1 days;
        lotteryFeePercentage = 20;
        lotteryPrizePercentage = 80;
        lotteryFee = lotteryFeePercentage * 1 ether;
        lotteryPrize = lotteryPrizePercentage * 1 ether;
        lotteryFeeAmount = lotteryFee / 100;
        lotteryPrizeAmount = lotteryPrize / 100;
        playersCount = 0;
        balance = 0;
        winner = address(0);
    }
   

    /**
     * @dev Function to enter the lottery
     */
    function enter() public payable {
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
        playersCount++;
    }

    /**
     * @dev Function to pick a winner
     * */
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {
        require(block.timestamp >= lotteryDate);
        require(playersCount > 0);
        uint r = random();
        uint index = r % players.length;
        winner = players[index];
        lotteryFeeAmount = address(this).balance * lotteryFeePercentage / 100;
        lotteryPrizeAmount = address(this).balance * lotteryPrizePercentage / 100;
        players[index].transfer(lotteryPrizeAmount);
        payable(manager).transfer(lotteryFeeAmount);
        players = new address payable[](0);
        playersCount = 0;
        lotteryDate = block.timestamp + lotteryDuration;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getLotteryDate() public view returns (uint) {
        return lotteryDate;
    }

    function getLotteryDuration() public view returns (uint) {
        return lotteryDuration;
    }

    function getLotteryFee() public view returns (uint) {
        return lotteryFee;
    }

    function getLotteryFeePercentage() public view returns (uint) {
        return lotteryFeePercentage;
    }

    function getLotteryFeeAmount() public view returns (uint) {
        return lotteryFeeAmount;
    }

    function getLotteryPrize() public view returns (uint) {
        return lotteryPrize;
    }

    function getLotteryPrizePercentage() public view returns (uint) {
        return lotteryPrizePercentage;
    }

    function getLotteryPrizeAmount() public view returns (uint) {
        return lotteryPrizeAmount;
    }

    function getWinner() public view returns (address) {
        return winner;
    }

    function getPlayersCount() public view returns (uint) {
        return playersCount;
    }

    function getManager() public view returns (address) {
        return manager;
    }

}