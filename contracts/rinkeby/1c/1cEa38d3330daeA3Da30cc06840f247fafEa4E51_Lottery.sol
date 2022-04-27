/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Lottery {
    address public manager;
    address payable[] private players;
   
   

    constructor() {
        // msg is a global variable like 'this'.. when function called.
        manager = msg.sender;
    }

// payable - when we require someone to make a payment
    function enter() public payable {
        // ether at the end determines number of ether.. does th econversion to wei.
        require(msg.value > 0.01 ether);
        players.push(payable(msg.sender));
        
    }

    function pickWinner() public payable  restricted{
        // require(msg.sender == manager);
        uint winner = random() % players.length;
        // current contract's balance.
        players[winner].transfer(address(this).balance);
        players = new address payable[](0);
    }

    function random() private view returns(uint) {
        // global method.
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function getPlayers() public view returns(address payable[] memory) {
        return players;
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

}