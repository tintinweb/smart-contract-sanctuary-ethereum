//
pragma solidity ^0.8.13;

contract D{
    address public sender;
    uint256 public balance;
    
    event setbala(address oner, uint256 balance, uint when);
    
    constructor(uint256 _balance) {
        balance = _balance;
    }

    function setBalance(uint256 _balance) external {
        
        balance = balance + _balance * 2;
        emit setbala(msg.sender, _balance,block.timestamp );
    }

    function setBalance1(uint256 _balance) external {
        
        balance = balance + _balance;
        emit setbala(msg.sender, _balance,block.timestamp );
    }
    
}