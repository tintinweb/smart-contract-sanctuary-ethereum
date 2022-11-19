// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract Test {
    uint256 private sum;

    constructor(uint256 initialValue) {
        sum = initialValue;
    }

    function getSum() public view returns (uint256) {
        return sum;
    }

    function setSum(uint256 s) public {
        sum = s;
    }

    function add(uint256 value) external {
        sum = sum + value;
    }

    function sub(uint256 value) external {
        sum = sum - value;
    }
}