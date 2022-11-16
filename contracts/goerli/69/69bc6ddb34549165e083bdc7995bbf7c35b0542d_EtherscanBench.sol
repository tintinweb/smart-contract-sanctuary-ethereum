// SPDX-License-Identifier: UNLICENSED
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

contract EtherscanBench {
    function run(uint256 num) public view returns (uint256) {
        uint256 gasStart = gasleft();

        for (uint256 i; i < num; ) {
            i += 1;
        }

        uint256 gasEnd = gasleft();
        return gasStart - gasEnd;
    }
}