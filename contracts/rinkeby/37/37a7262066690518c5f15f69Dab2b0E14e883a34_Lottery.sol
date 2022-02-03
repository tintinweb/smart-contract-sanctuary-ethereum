/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
// linter warnings (red underline) about pragma version can igonored!

contract Lottery{

    address public manager;
    address payable[] public players;
    constructor() {
        manager = msg.sender;
    }

    function enter() public payable{
        require(msg.value > 0.01 ether, "You should pay greater than 0.01 Ether to enter");
        players.push(payable(msg.sender));
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
    }
    
    function random() private view returns(uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    modifier onlyManager{
        require(msg.sender == manager, "You are not the manager");
        _;
    }
    function pickWinner() public onlyManager{
        // require(players.length>0, "There are no players");
        uint index = random()%(players.length);
        players[index].transfer(address(this).balance); //0x123456bfsacgh235677
        players = new address payable[](0);
    }

    function getPlayers() public view returns(address payable[] memory){
        return players;
    }


}