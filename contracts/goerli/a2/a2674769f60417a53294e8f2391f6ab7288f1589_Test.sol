/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0 <0.9.0;

contract Test {

    string public name;

    constructor() {
        name = "Godspower Eze";
    }

    function updateName(string calldata _name) external {
        name = _name;
    }
}