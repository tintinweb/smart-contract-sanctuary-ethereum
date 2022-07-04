/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager;
    address[] public players;
    address public lastWinner;

    constructor() { 
       manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value >= .01 ether);
        players.push(msg.sender);
    }

    function random() private view returns (uint) {
        // keccak256 is a global function
        // block is a global variable
        // keccak256 returns a hex. we make it to a uint.
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {
        require(players.length > 0);

        uint index = random() % players.length;
        address payable winner = payable(players[index]);
        lastWinner = winner;
        winner.transfer(address(this).balance);
        players = new address[](0);
    }
    
    // we don't use public/private to enforce security.
    // we use require or modifiers       
    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns(address[] memory){
        return players;
    }
}