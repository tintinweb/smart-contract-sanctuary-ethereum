/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enterPlayer() public payable {
        require(msg.value == 0.01 ether);
        players.push(msg.sender);
    }

    function pickWinner() public payable owner {
        uint winningIndex = random() % players.length;
        payable(players[winningIndex]).transfer(address(this).balance);    
        players = new address[](0);   
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    modifier owner() {
        require(msg.sender == manager);
        _;
    }
}