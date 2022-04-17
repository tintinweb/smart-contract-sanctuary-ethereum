// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.1;

contract C {
    mapping(uint256 => bool) public aa;


    function set(uint256 x) public {
        aa[x] = true;
    }

    function del(uint256 x) public {
        delete aa[x];
    }

}