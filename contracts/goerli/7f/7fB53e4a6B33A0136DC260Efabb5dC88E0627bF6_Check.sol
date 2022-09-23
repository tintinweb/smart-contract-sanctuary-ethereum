/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Check {
    function check(address from) public payable returns (address) {
        return from;
    }

    function setContract(address from) public payable {
        check(from);
    }
}