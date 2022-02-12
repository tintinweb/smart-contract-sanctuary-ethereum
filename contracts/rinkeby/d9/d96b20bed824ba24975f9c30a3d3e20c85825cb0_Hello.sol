/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// SPDX License-Identifier: MIT
pragma solidity 0.8.11;

contract Hello {
    string public msg;

    function setMsg(string memory _msg) public {
        msg = _msg;
    } 
}