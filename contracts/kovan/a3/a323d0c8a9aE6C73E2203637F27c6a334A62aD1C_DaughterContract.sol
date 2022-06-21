/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity ^0.5.0;

contract DaughterContract {
    
    string public name;
    uint public age;
    
    constructor() public {
 }

    function changeName(string memory newName) public {
        name = newName;
    }

    function changeAge(uint newAge) public {
        age = newAge;
    }
}