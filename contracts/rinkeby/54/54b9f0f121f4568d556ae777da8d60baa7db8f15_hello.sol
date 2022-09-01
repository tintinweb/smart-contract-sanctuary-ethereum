/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract hello {
    string public Msg;

    constructor() {
        Msg = "Hello! Solidity";
    }

    function setMsg(string memory _msg) public {
        Msg = _msg;
    }

    function getMsg() view public returns (string memory) {
        return Msg;
    }
}