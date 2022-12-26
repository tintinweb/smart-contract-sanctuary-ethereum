// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Error {
    error Tst();

    function err() external {
        revert Tst();
    }
}