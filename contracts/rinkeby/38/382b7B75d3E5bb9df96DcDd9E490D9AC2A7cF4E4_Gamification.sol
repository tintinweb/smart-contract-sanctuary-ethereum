// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract Gamification{

address public owner;
 mapping(address => uint256) public pointsBalance;


constructor() {
    owner = msg.sender;
}

function addPoints(address user, uint256 points) public{
    pointsBalance[user] += points;

}

}