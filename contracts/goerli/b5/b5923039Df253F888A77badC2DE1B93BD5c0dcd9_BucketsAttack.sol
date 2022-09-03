// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BucketsAttack {
    function totalSupply() external pure {
        revert();
    }
}