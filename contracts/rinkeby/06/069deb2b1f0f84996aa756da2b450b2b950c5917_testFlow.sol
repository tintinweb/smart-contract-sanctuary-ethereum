pragma solidity ^0.4.18;

contract testFlow{
    
    string newName;
    uint256 newAge;
    
    function getDetails() public{
        newName = "hello";
        newAge = 34;
    }
    
}