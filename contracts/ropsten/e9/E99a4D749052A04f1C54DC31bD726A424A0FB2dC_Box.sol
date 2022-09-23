//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Box {
    uint256 public val;

    //cant have constructor for upgradeable contracts

    function initialize(uint256 _val) public {
        val = _val;
    }
}