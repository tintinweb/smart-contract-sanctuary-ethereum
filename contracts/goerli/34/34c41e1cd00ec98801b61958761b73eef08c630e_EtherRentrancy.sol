/**
 *Submitted for verification at Etherscan.io on 2022-10-28
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.10;
contract EtherRentrancy {
    
    mapping (address => uint256) public balances;
    address public owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function deposit() public payable{
        balances[msg.sender] += msg.value;
    }
    
    
    function withdraw(uint _amount) public {
        require (balances[msg.sender] >= _amount, "Insufficient funds");
        
        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send funds");
        
        balances[msg.sender] -= _amount;
    }
    
    function getBalance() public view returns(uint){
        return address(this).balance;
        
    }
    
}