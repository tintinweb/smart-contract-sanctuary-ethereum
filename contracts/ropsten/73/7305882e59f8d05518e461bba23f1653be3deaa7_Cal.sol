/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Cal {
    string internal name = "";

    function setName(string memory _name) public {
        name = _name;
    }
}