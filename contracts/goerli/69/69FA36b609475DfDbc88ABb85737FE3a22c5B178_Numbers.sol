// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Numbers {
    uint256 public number1;

    function setNumber(uint256 _number) external {
        number1 = _number;
    }

    function getNumber() external view returns (uint256) {
        return number1;
    }
}