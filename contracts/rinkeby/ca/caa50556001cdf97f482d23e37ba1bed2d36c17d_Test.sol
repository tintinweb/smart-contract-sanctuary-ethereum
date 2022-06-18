/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    uint public totalNames;
    
    mapping(uint => string) public name;
    
    event NewGreeting(
        uint indexed id, 
        string name 
    );

    function get(uint _id) public view returns (string memory) {
        return name[_id];
    }
    
    function set(string calldata _name) public {
        uint newName = totalNames;
        name[newName] = _name;
        totalNames += 1;

        emit NewGreeting(newName, _name);
    }

    
}