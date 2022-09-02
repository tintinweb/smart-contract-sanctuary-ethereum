/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

contract SolidityBasics {
    uint256 storedData; // since this value isn't specified it gets initialized to 0
    function set(uint x) public {
        storedData = x;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
    
}