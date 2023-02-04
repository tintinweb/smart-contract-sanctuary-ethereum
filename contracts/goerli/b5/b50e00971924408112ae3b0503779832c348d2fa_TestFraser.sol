/**
 *Submitted for verification at Etherscan.io on 2023-02-04
*/

pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT


contract TestFraser {

    string public something;

    function writeSomething(string memory s) public {
        something = s;
    }

    function readSomething() public view returns (string memory s) {
        return something;
    }

}