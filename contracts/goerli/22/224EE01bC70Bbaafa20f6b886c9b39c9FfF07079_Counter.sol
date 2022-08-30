// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Counter {

    // Function to get the current count
    function get() public view returns (uint r) {
        assembly {
            r := difficulty()
        }
    }
}