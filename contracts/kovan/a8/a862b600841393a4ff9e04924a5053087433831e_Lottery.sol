/**
 *Submitted for verification at Etherscan.io on 2022-07-13
*/

pragma solidity ^0.8.15;
// SPDX-License-Identifier: MIT


contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function lotteryEther() public view returns(uint){
        return address(this).balance / 0.001 ether;
    }
    function enter() public payable {
        require(msg.value > 1 ether);

        players.push(msg.sender);
    }

    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function We_Have_A_Winner() public restricted{
        uint index = random() % players.length;
        payable (players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    modifier restricted(){
        require(msg.sender == manager);
        _;
    }
    function getPlayer() public view returns(address [] memory){
        return players;
    }
}