/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract v1 {
    uint256 public test = 0;

    function settest(uint256 _newtest) public {
        test = _newtest;
    }
}