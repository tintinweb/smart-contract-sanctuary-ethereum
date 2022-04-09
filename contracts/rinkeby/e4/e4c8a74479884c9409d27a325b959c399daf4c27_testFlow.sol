pragma solidity ^0.4.18;

contract testFlow{
    
    string newName;
    uint256 newAge;
    
    function getDetails() public returns (string){
        newName = "hello";
        newAge = 34;
        return newName;
    }
    
}