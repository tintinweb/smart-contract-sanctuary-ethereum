// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.6.6;

contract Lottery {
    address payable[] public players;
    address payable public recentWinner;
    address payable public contractOwner;
    address payable public contractWallet;
    uint256 public resultRandomness;
    uint256 public numberOfEntries;
    uint256 private entryFee;

    enum LOTTERY_STATE {
        CLOSED,
        OPEN,
        CALCULATE
    }
    LOTTERY_STATE public lotteryState;

    constructor(uint256 entry, address wallet) public {
        entryFee = entry;
        numberOfEntries = 0;
        lotteryState = LOTTERY_STATE.CLOSED;

        contractWallet = payable(wallet);
        contractOwner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == contractWallet);
        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner);
        _;
    }

    function enterLottery() public payable {
        require(lotteryState == LOTTERY_STATE.OPEN);
        require(msg.value >= getEntranceFee(), "Not Enough ETH");
        players.push(msg.sender);
        numberOfEntries++;
    }

    function getEntranceFee() public view returns (uint256) {
        return entryFee;
    }

    function changeWallet(address payable newWallet) public onlyContractOwner {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery is Running");
        contractWallet = newWallet;
    }

    function changeContractOwner(address payable newOwner)
        public
        onlyContractOwner
    {
        require(lotteryState == LOTTERY_STATE.CLOSED, "Lottery is Running");
        contractWallet = newOwner;
    }

    function StartUpLottery() public onlyOwner {
        require(
            lotteryState == LOTTERY_STATE.CLOSED,
            "Lottery already Started"
        );
        lotteryState = LOTTERY_STATE.OPEN;
    }

    function ShutDownLottery() public onlyOwner {
        lotteryState = LOTTERY_STATE.CALCULATE;
    }

    function CancelLottery() public onlyOwner {
        contractWallet.transfer(address(this).balance);
        players = new address payable[](0);
        lotteryState = LOTTERY_STATE.CLOSED;
    }

    function PickWinner(uint256 randomness) public onlyOwner {
        require(
            lotteryState == LOTTERY_STATE.CALCULATE,
            "Not looking for a winner yet"
        );
        require(randomness > 0, "random number not generated");
        require(
            randomness != resultRandomness,
            "random number has not changed"
        );
        uint256 indexOfWinner = randomness % (players.length);
        recentWinner = players[indexOfWinner];
        contractWallet.transfer(address(this).balance / 3);
        recentWinner.transfer(address(this).balance);
        players = new address payable[](0);
        numberOfEntries = 0;
        lotteryState = LOTTERY_STATE.CLOSED;
        resultRandomness = randomness;
    }
}