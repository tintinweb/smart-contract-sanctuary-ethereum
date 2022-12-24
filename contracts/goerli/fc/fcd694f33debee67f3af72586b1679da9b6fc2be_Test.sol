/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract Test {
    string public message;

    constructor() {
        message = "Hello, World!";
    }

    function updateMessage(string memory _updatedMsg) public {
        message = _updatedMsg;
    }
}