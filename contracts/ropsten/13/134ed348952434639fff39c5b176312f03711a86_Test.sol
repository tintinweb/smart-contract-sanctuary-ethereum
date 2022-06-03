/**
 *Submitted for verification at Etherscan.io on 2022-06-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Test {
    string public message;

    constructor() public {
        message  = "hello";
    }

    function setMessage(string memory _message) public {
        message = _message;
    }
}