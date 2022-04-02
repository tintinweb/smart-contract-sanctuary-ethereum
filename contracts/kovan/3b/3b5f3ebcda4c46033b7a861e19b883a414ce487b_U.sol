/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.13;

contract U {
    uint8 public a;

    function R() public view returns (uint8) {
        return a;
    }

    function S(uint8 _n) external{
        a = _n;
    }
}