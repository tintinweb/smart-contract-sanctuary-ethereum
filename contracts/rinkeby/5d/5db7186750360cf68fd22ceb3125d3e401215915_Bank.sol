/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

//SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 < 0.9.0;

contract Bank
{
    mapping(address=>uint) public depositors;
    mapping(address=>uint) public requestCreationTime;
    
    
    function request() public
    {
        requestCreationTime[msg.sender]=block.timestamp;
    
    }

    
    function depositETH() public payable
    {
        depositors[msg.sender]+=msg.value;
    }

    function withdraw(uint amount) public
    {
        require(requestCreationTime[msg.sender]!=0, 'First make a request call');     
        require(block.timestamp>=(requestCreationTime[msg.sender]+ 30 seconds), 'Duration not completed');     
        require(amount<=depositors[msg.sender], 'Users cannot withdraw more than what they have deposited.');
        
        payable(msg.sender).transfer(amount);
        depositors[msg.sender]-=amount;
        requestCreationTime[msg.sender]=0;
    
    }

 function getBalance() public view returns (uint256)
    {
        return address(this).balance;
    }
    
}