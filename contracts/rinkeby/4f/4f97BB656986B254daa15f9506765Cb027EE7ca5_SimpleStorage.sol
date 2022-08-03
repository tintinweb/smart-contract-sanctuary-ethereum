// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint256 public sid = 10;

    function retrieve() public view returns (uint256) {
        return sid;
    }
}