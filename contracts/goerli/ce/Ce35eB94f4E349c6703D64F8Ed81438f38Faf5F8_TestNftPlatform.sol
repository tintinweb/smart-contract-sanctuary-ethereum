// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

contract TestNftPlatform {
    uint256 public count;

    function allowedFunction() external {
        count += 1;
    }

    function notAllowedFunction() external {
        count += 1;
    }
}