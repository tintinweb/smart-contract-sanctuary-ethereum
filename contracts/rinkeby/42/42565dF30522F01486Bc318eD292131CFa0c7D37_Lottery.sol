/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery {
    address manager;
    address payable[] players;

    constructor() {
        manager = msg.sender;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function buyLottery() public payable {
        require(msg.value == 1 ether, "Please buy Lottery 1 ETH only...");
        players.push(payable(msg.sender));
    }

    function numberOfPlayers() public view returns(uint) {
        return players.length;
    }

    function randomNumber() public view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }

    function selectWinner() public {
        require(msg.sender == manager, "Unauthorized...");
        require(numberOfPlayers() >= 2, "Need more than 2 Lottrey...");

        uint getWinner = randomNumber();
        address payable winner;
        uint playersIndex = getWinner % players.length;
        winner = players[playersIndex];
        winner.transfer(getBalance());

        players = new address payable[](0);
    }
}