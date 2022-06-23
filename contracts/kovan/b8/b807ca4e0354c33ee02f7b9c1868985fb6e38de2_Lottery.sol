/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Lottery {
    address public manager;
    address[] public  players;

    constructor() {
        manager = msg.sender;
    }

    function getCurrentBalance() public view returns(uint256) { 
        return address(this).balance;
    }

    function countMembers() public view returns(uint128){
        return uint128(players.length);
    }

    function enter() public payable {
        require(msg.value > 0.01 ether, "No enough minimum value!");
        require(msg.sender != manager, "Creator can not join the game!");
        players.push(msg.sender);
    }

    function randomWinner() public returns (address) {
        require(manager == msg.sender, "Only owner can pick winner!");
        uint256 randomWinnerIndex = uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players))) % players.length;
        address winner = players[randomWinnerIndex];
        payable(winner).transfer(address(this).balance);
        return winner;
    }


    
}