/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract dasp10 {
    string public name = "roman zaikin";
    
    function updateName(string memory _newName) public {
        name = _newName;
    }
}