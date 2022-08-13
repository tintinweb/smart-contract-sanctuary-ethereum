/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;


contract dasp10 {
    string public name2 = "roman zaikin";

    function updateName(string memory _newName) public {
        name2 = _newName;
    }
}