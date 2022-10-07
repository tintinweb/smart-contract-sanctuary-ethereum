// Contract B 
pragma solidity ^0.8.13;

contract B {
    
    address public sender;
    uint256 public balance;
    
    function setBalance(uint256 _balance) external {
        sender = msg.sender;
        balance = _balance;
    }
}