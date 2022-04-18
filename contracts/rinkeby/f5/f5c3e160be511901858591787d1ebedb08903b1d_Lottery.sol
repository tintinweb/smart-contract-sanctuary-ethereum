/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Lottery {
    address public manager1;
    address payable[] public players;
    
    constructor () {
        manager1 = msg.sender;
    }
    
    function enter() public payable{
        require(msg.value > .01 ether);
        players.push(payable(msg.sender));
    }

    function random() public view returns (uint) { 
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
    
    function pickWinner() public restricted {
        uint8 index = uint8(random() % players.length);
        players[index].transfer(address (this).balance);
        players = new address payable [](0);
    }

    modifier restricted {
        require(msg.sender == manager1);
        _;
    }

    function getPlayers() public view returns (address payable [] memory) {
        return players;
    }
}