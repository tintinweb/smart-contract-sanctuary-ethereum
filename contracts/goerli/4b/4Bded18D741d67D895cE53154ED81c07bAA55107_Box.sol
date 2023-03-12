//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Box {
    uint public a;

    function setA(uint256 amount) external {
        a = amount;
    }
}