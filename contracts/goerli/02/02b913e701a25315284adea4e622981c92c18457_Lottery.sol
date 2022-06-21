/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function getCurrentBalance() public view returns(uint256) { 
        return address(this).balance;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether, "No enough minimum value!");
        require(msg.sender != manager, "Creator can not join the game!");
        players.push(msg.sender);
    }

    function randomWinner() public returns (uint256) {
        players.push(msg.sender);
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    
}