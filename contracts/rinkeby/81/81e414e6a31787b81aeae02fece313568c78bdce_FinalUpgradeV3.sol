// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.17;

contract FinalUpgradeV3 {

    uint storedData;
    bool isNice;
    uint height;
    uint age;

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

    function setHeight(uint _height) public {
        height = _height;
    }

    function getHeight() view public returns (uint) {
        return height;
    }

    function setAge(uint _age) public {
        age = _age;
    }

    function getAge() public view returns (uint) {
        return age;
    }
}