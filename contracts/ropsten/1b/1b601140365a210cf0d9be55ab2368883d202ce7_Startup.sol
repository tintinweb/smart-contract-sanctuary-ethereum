/**
 *Submitted for verification at Etherscan.io on 2022-07-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Startup {

    string public name;

    constructor(string memory _name) {
        name = _name;
    }

    fallback () external payable {}

}