/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract daps10 {
    string public name = "Hack the planet!";

    function updateName(string memory _newName) public {
        name = _newName;
    }
}