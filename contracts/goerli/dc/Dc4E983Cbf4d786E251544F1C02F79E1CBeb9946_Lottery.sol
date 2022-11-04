// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Lottery {
    address public owner;
    address payable[] public players;
    address[] public winners;
    uint public lotteryId;

    constructor() {
        owner = msg.sender;
        lotteryId = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You are the owner");
        _;
    }

    modifier notOwner() {
        require(msg.sender != owner, "Owner is not allowed");
        _;
    }

    function enter() public payable notOwner {
        require(msg.value >= 1 ether, "Incorrect Eth amount");
        players.push(payable(msg.sender));
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getLotteryId() public view returns (uint) {
        return lotteryId;
    }

    function getRandomNumber() public view returns (uint) {
        return uint(keccak256(abi.encodePacked(owner, block.timestamp)));
    }

    function pickWinner() public onlyOwner {
        uint randomIndex = getRandomNumber() % players.length;
        (bool sent, ) = players[randomIndex].call{value: address(this).balance}("");
        require(sent, "Transfer Failed");

        winners.push(players[randomIndex]);
        lotteryId++;

        // Clear the players array
        players = new address payable[](0);
    } 

    function getWinners() public view returns (address[] memory) {
        return winners;
    }
}