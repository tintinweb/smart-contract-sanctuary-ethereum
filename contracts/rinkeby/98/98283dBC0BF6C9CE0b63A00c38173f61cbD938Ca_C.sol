pragma solidity ^0.8.13;

contract C {
    
    address public sender;
    uint256 public balance;
    
    function setBalance(uint256 _balance) external {
        sender = msg.sender;
        balance = balance + _balance * 2;
    }
}