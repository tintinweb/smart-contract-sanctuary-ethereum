//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Storage {
    uint256 number;

    function put(uint256 num) public {
        number = num;
    }

    function get() public view returns (uint256) {
        return number;
    }
}