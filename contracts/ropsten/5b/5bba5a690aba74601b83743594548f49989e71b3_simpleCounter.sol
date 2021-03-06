/*
LAB 1: Simple Counter contract

This contract creates a counter that can only
be incremented by address that deployed the contract
or another approved address.

Yanesh
*/

pragma solidity ^0.4.25;

contract simpleCounter {
    
    uint256 private counter;
    address public owner;
    address public approvedAddress;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function getCount() public view returns (uint256) {
        return counter;
    }
    
    function incCounter() public {
        require(msg.sender == owner || msg.sender == approvedAddress);
        counter++;
    }
    
    function setApprovedAddress(address _approvedAddress) public {
        require(msg.sender == owner);
        approvedAddress = _approvedAddress;
    }
    
}