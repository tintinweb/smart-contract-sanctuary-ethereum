// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.7.0;

contract SolidityStorage {
    uint256 storedData = 5;

    function set(uint256 _x) public {
        storedData = _x;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}