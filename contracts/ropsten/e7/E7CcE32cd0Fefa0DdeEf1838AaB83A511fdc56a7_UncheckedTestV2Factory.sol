// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./UncheckedTestV2.sol";

contract UncheckedTestV2Factory {
    event Deployed(address contractAddress);

    function deployContract(uint256 magicNum) external {
        address addr = address(new UncheckedTestV2(magicNum));
        emit Deployed(addr);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract UncheckedTestV2 {
    uint256 public immutable magicNumber;
    uint256[] public numbers;

    constructor(uint256 magicNum) {
        magicNumber = magicNum;
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