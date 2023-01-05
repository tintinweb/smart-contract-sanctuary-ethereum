// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract HashCollector {
    constructor() {}

    function getHash(address _squadAddress) external view returns (bytes32 codeHash) {
        assembly { codeHash := extcodehash(_squadAddress) }
    }
}