/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface IE {}

contract Caller {
    function callTest(IE ie) public returns (bool) {
        (bool success,) = address(ie).call(abi.encodeWithSignature("nonExistingFunction()"));
        require(success);

        return true;
    }
}