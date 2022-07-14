/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// this is test error
/// @param num test num
/// @param owner test owner
error Unavailable(uint256 num, address owner);

contract ErrorTest {
    uint256 public num;

    function setNum(uint256 _num) external {
        num = _num;
    }

    function tmp(uint256 _num) external view {
        if (num == _num) {
            revert Unavailable(1, msg.sender);
        }
    }
}