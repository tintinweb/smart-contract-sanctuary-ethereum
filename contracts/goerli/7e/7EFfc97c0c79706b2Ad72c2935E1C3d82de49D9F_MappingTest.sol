/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: NONE
// Author: @SoulChen;
pragma solidity ^0.8.9;

contract MappingTest {
    mapping(address => uint) addressMapping;
    mapping(uint => string) nameMapping;
    uint public sum = 0;

    function regeister(address account, string memory name) public {
        if (addressMapping[account] == 0) {
            sum += 1;
            addressMapping[account] = sum;
            nameMapping[sum] = name;
        }
    }

    function getAddress(address account) public view returns (uint) {
        return addressMapping[account];
    }

    function getName(uint id) public view returns (string memory) {
        return nameMapping[id];
    }
}