/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Bank{
    address public owner;
    mapping(address => uint256) public balance;

    event deposit(address indexed sender,uint256 indexed amount);

    constructor(){
        owner = msg.sender;
    }

    modifier mustOwner{
        require(owner == msg.sender, "You are not owner!");
        _;
    }

    function withdraw() external payable mustOwner{
        payable(owner).transfer(address(this).balance);
    }

    receive() external payable{
        balance[msg.sender] += msg.value;
        emit deposit(msg.sender, msg.value);
    }
}