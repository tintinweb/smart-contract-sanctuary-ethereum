//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Demo {
    uint256 private number = 10;
    uint256 private updateNumber;

    function setNumber(uint256 _number) external {
        updateNumber = number + _number;
    }

    function getNumber() external view returns (uint256) {
        return updateNumber;
    }
}