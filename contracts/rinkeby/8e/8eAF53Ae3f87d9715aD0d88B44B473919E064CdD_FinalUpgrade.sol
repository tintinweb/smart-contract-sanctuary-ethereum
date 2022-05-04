// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.17;

contract FinalUpgrade {

    uint storedData;
    bool isNice;

    event Change(string message, uint newVal);

    function set(uint x) public {
        require(x < 5000, "Should be less than 5000");
        storedData = x;
        emit Change("set", x);
    }

    function get() public view returns (uint) {
        return storedData;
    }

    function toggleNice() external {
        isNice = !isNice;
    }

    function getNice() external view returns (bool) {
        return isNice;
    }
}