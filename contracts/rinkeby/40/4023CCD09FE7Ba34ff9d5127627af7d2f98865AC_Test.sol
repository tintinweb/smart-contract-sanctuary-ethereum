// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Test{

    uint256 public count;

    function add(uint256 value) external {
        value = value + 1;
        count = count + value;
    }

    function sub(uint256 value) external {
        value = value - 1;
        count = count - value;
    }
}