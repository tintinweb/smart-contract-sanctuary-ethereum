// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MockGlpManager {
    function getPrice(bool _maximise) external returns (uint256 price) {
        return 10 ** 30; // For now this contract will always say that the price of GLP is $1.
    }
}