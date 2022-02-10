// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Test {
    address[] public addresses;

    function len() public view returns (uint256) {
        return addresses.length;
    }

    function add(address addr) public {
        addresses.push(addr);
    }
}