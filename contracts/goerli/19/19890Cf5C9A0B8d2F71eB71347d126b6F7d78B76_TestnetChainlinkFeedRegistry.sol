// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

contract TestnetChainlinkFeedRegistry {
    mapping(address => mapping(address => uint8)) public decimals;

    function registerFeed(address base, address quote, uint8 newDecimals) external {
        decimals[base][quote] = newDecimals;
    }
}