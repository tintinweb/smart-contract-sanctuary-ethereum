/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleStorage {
    uint256 number;

    function getNumber() public view returns (uint256 _number) {
        return number;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }
}