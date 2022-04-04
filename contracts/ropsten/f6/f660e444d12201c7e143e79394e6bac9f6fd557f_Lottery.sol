/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @title A lottery that accepts Ether and issues a lottery ticket in return.
/// @author Viacheslav
/// @notice This contract was written only for studing purpose and passing test task.

contract Lottery {
address public owner;
address payable[] public players;
uint public lotteryId;
uint deployDate;

constructor() {
owner = msg.sender;
lotteryId = 1;
deployDate = block.timestamp;
}

modifier onlyOwner() {
    require(msg.sender == owner, "You are not the Owner");
    _;
}

modifier drawConditions() {
    require(players.length >= 3 || block.timestamp >= deployDate + 10 seconds, "Not enough players participating in a lottery or it's not yet time for the draw");
    _;
}

function getBalance() public view returns (uint) {
    return address(this).balance;
}

function getPlayers() public view returns (address payable[] memory) {
    return players;
}

function enter() public payable {
require(msg.value == 0.1 ether, "Should be exact 0.1 ether");
require(msg.sender != owner, "Owner cann't play");

/// @notice address of player entering lottery
players.push(payable (msg.sender));
}

function getRandomNumber() internal view returns (uint) {
    return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));    
}

function pickWinner() public onlyOwner drawConditions {
    address payable winner;
    winner = players[getRandomNumber() % players.length];

    winner.transfer(getBalance() * 9 / 10);

    address payable _to = payable(owner);
    _to.transfer(getBalance() / 10);

    lotteryId++;

    /// @notice reset the state of the contract
    players = new address payable[](0);
}
}