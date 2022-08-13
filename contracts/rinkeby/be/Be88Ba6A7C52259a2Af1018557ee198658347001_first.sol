/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.10;

contract first {
    string public name = "Apurva Goenka";

    function updateName(string memory _newName) public {
        name = _newName;
    }
}