/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract PayAndPlay {
    address owner;
    uint64 public endTime;
    uint256 public delta;
    uint256 public prize;
    uint256 public currentBet;
    bool public isPrizeTaken;
    mapping(address => uint256) public bets;

    modifier isEnded() {
        require(block.timestamp > endTime, "Game is not over!");
        _;
    }

    modifier isNotEnded() {
        require(block.timestamp < endTime, "Game is over!");
        _;
    }

    constructor(uint64 _endTime, uint256 _delta) payable {
        endTime = _endTime;
        delta = _delta;
        owner = msg.sender;
        prize = msg.value;
    }

    function withdraw() public isEnded {
        require(msg.sender == owner, "You are not an owner!");
        payable(msg.sender).transfer(
            isPrizeTaken ? address(this).balance : address(this).balance - prize
        );
    }

    function needToBet() public view isNotEnded returns (uint256) {
        if (bets[msg.sender] == currentBet && currentBet > 0) {
            return 0;
        }
        return currentBet - bets[msg.sender] + delta;
    }

    function bet() public payable isNotEnded {
        require(msg.value >= needToBet(), "Too little bet!");
        currentBet = currentBet + delta;
        bets[msg.sender] = currentBet;
    }

    function getPrize() public isEnded {
        require(bets[msg.sender] == currentBet, "You are not a winner!");
        require(!isPrizeTaken, "Prize already taken!");
        payable(msg.sender).transfer(prize);
        isPrizeTaken = true;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}