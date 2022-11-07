/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GameItem {
    uint256 number = 10;

    function store(uint256 _number) public {
        number = _number;
    }

    function retrieve() public view returns (uint256 magic_number) {
        return number;
    }
}