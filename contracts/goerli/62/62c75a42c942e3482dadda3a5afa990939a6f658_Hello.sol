/**
 *Submitted for verification at Etherscan.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.17;

contract Hello {
    mapping(address => string) names;

    function sendName(string memory name) public returns(string memory) {
        bytes memory nameString = bytes(names[msg.sender]);

        if(nameString.length == 0) {
            names[msg.sender] = name;
            return string(abi.encodePacked("Hello ", name, "!"));
        }
        else {
            if(keccak256(abi.encode(names[msg.sender])) == keccak256(abi.encode(name)))
                return string(abi.encodePacked("Hello again", name));
            
            string memory oldName = names[msg.sender];
            names[msg.sender] = name;
            return string(abi.encodePacked("Hello ", oldName, "! Your name is now updated to ", name));
        }    
    }
}