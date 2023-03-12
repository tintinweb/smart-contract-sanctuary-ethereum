/**
 *Submitted for verification at Etherscan.io on 2023-03-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Ticket  {
    address public owner;
    mapping (address => uint) public countTickets;
    
    constructor(){
        owner = msg.sender;
        countTickets[address(this)] = 100;
    }

    function getCountTickets() public view returns (uint){
        return countTickets[address(this)];
    }

    function addTickets(uint extraTickets) public {
        require(msg.sender == owner, "Only owner can add more Tickets.");
        countTickets[address(this)] += extraTickets;
    }

    function purchaseTickets(uint requiredTickets) public payable{
        require(msg.value >= requiredTickets * 2 ether, "Cost of each ticket is 2 ethers.");
        require(countTickets[address(this)] >= requiredTickets, "Not enough tickets");
        countTickets[address(this)] -= requiredTickets;
        countTickets[msg.sender] += requiredTickets;
    }

    function useTickets(uint neededTickets) public {
        require(countTickets[msg.sender] >= neededTickets, "Not enough tickets");
        countTickets[msg.sender] -= neededTickets;
    }

}