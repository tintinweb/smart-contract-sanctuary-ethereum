// SPDX-License-Identifier: (CC-BY-NC-ND-3.0)
// Code and docs are CC-BY-NC-ND-3.0

pragma solidity ^0.8.0;

contract Simple {
    uint256 data;

    function increase() external {
        data++;
    }

    function getValue() external view returns (uint256) {
        return data;
    }
}