/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// File: SetGet.sol

contract SetGet {
    string value;

    constructor() public {
        value = "myValue";
    }

    function get() public view returns (string memory) {
        return value;
    }

    function set(string memory _value) public {
        value = _value;
    }
}