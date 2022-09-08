// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Test {
    function helloWorld() external view returns (address) {
        return address(this);
    }
}