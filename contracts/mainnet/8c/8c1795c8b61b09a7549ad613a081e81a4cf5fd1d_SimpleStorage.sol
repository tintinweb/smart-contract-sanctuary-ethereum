// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.15;

contract SimpleStorage {
    //
    uint256 storedData;

    function set(uint256 x_) public {
        storedData = x_;
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}