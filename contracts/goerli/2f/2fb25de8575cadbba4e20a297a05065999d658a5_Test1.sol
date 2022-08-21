/**
 *Submitted for verification at Etherscan.io on 2022-08-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

contract Test1 {
    uint256 public intg = 0;

    function get() public view returns (uint) {
        return intg;
    }


    function set() public {
        intg += 1;
    }
}