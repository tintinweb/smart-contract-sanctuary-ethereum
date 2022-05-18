/**
 *Submitted for verification at Etherscan.io on 2022-05-18
*/

// File: homework2.sol


pragma solidity ^0.8.10; 
 
contract SimpleBank { 
mapping( address => uint ) private bank; 
 
    function withdraw(uint amount) external payable { 
        require(bank[msg.sender] >= amount,"Not enough money in the amount"); 
        (bool success, ) = payable(msg.sender).call{value : amount} (""); 
        require(success, "send fail"); 
        bank[msg.sender] -= amount; 
        // Implement withdraw function……  
    } 
 
    function deposit() external payable { 
        bank[msg.sender] += msg.value; 
        // Implement deposit function…… 
    } 
 
    function getBalance() public view returns (uint) { 
         
        return bank[msg.sender]; 
        // Implement getBalance function…… 
    } 
}