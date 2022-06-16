//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

contract NUM1 {
    uint256 private number;

    function update (uint256 _number) public {
        number = _number;
    }

    function get() public view returns(uint256 _number) {
        return number;
    }
}