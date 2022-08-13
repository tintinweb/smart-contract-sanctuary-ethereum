/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract dasp10 {
    string public name = "n3krosis";

    function updateName(string memory _newName) public {
        name = _newName;
    }
}