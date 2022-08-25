// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

contract TestingContract {
    function blockNumber() public view returns (uint256) {
        return block.number - 1;
    }

    function blockHashTest() public view returns (bytes32) {
        return blockhash(block.number - 1);
    }
}