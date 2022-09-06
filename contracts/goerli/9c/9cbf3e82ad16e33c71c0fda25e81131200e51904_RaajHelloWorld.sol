/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
contract RaajHelloWorld {
    string DisplayString = "Hello World";
    function display() public view returns (string memory) {
        return DisplayString;
    }
}