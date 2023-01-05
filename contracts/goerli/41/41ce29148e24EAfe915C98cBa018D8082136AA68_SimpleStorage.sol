// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract SimpleStorage {
    uint number;

    function set(uint _number) external {
        number = _number;
    }

    function get() external view returns (uint) {
        return number;
    }
}