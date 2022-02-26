//  SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Counter {
    uint256 public counter;

    constructor(uint256 initialValue) {
        counter = initialValue;
    }

    // 计算两个数相除并四舍五入的结果
    function roundUp(uint256 a, uint256 b) public {
        counter = (a + b / 2) / b;
    }

    function count() public {
        counter = counter + 1;
    }

    function set(uint256 x) public {
        counter = counter + x;
    }

    function clear() public {
        delete counter;
    }
}