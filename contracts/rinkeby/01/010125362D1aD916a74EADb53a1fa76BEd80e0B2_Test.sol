// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract Test {
    uint public num;

    constructor(uint startingNum) {
        num = startingNum;
    }

    function increaseNum(uint amount) external {
        num += amount;
    }
}