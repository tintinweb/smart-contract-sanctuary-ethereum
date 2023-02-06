/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HashlipsNameSetter {

    string public name;

    function setName(string memory newName) public {
        name = newName;
    }

}