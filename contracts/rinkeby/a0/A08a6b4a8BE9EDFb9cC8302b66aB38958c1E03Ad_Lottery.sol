/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Lottery {
    address public manager;
    address[] public players;

    constructor () {
       manager = msg.sender;
    }

    function enter() public payable {
        //condition to check if account is sending some value of ether.
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }

    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickNumber() public restricted {
        uint index = random() % players.length;
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    function getPlayers() public view returns (address[] memory){
        return players;
    }

    modifier restricted(){
        //make sure it's the manager who's calling the pickNumber
        require(msg.sender == manager);
        _;
    }
}