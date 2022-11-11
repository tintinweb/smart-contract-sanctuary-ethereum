/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Helloworld {
    string text = "No message";
    address owner = 0x3F1d308983c2dD2A0f51875eab4A827ce22588cF;
    event test_value(address indexed value1);

    function getString() public view returns (string memory) {
        return text;
    }


// Set must be only accessible by the owner of the contract
    function setString(string memory _text) public {
        // Get the address of the owner of the contract
        emit test_value(msg.sender);
        emit test_value(owner);
        if (owner == msg.sender) {
            text = _text;
        }
        else {
            revert("You are not the owner of the contract");
        }
    }
}