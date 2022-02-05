/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract Crowd {
    address owner;
    uint256 tmm;
    uint256 goal;
    mapping(address => uint256) public summ;

    function CreateCrowdfunding(uint256 day, uint256 _goal) public payable{
        owner = msg.sender;
        tmm = block.timestamp + (day * 1 days);
        goal = _goal;
    }

    function donate(uint256 amount) public payable{
        require(block.timestamp < tmm);
        require(msg.value == amount);
        summ[msg.sender] += amount;
    }

    function claim() public{
        require(address(this).balance >= goal);
        require(block.timestamp >= tmm);
        require(msg.sender == owner);
        payable(msg.sender).transfer(address(this).balance);
    }

    function getRefund() public{
        require(address(this).balance < goal); 
        require(block.timestamp >= tmm);
        uint256 amount = summ[msg.sender];
        payable(msg.sender).transfer(amount);
        summ[msg.sender] = 0;
    }
}