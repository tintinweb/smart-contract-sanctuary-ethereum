/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// Root file: contracts/MultiWithdrawalController/DummyContract.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract DummyContract {
    uint256 public value;

    constructor(uint256 _value) {
        value = _value;
    }

    function increaseValue(uint256 increaseAmount) external {
        value += increaseAmount;
    }
}