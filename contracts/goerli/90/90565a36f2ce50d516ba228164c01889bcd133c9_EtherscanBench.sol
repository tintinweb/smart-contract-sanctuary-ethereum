// SPDX-License-Identifier: UNLICENSED
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