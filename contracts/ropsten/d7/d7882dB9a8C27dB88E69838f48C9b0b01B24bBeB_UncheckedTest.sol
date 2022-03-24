// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

contract UncheckedTest {
    uint256[] public numbers;

    constructor() {
        for(uint256 i; i < 100; i++) {
            numbers.push(i);
        }
    }

    // 560762 gas
    function addNumbersCheckedPost() external {
        for(uint256 i; i < 100; i++) {
            numbers[i] = i + block.timestamp;
        }
    }

    // 560218 gas
    function addNumbersCheckedPre() external {
        for(uint256 i; i < 100; ++i) {
            numbers[i] = i + block.timestamp;
        }
    }

    // 553384 gas
    function addNumbersUncheckedPost() external {
        for(uint256 i; i < 100;) {
            numbers[i] = i + block.timestamp;
            unchecked{
                i++;
            }
        }
    }

    // 553340 gas
    function addNumbersUncheckedPre() external {
        for(uint256 i; i < 100;) {
            numbers[i] = i + block.timestamp;
            unchecked{
                ++i;
            }
        }
    }
}