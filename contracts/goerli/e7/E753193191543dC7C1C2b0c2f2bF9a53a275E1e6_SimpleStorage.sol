// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

contract SimpleStorage {
    uint256 public x;
    uint256 public y;

    function initialize(uint256 initVal) public {
        x = initVal;
    }

    function setx(uint256 x_) public {
        x = x_;
    }

    function getx() public view returns (uint256 retval) {
        return x;
    }

    function sety(uint256 y_) public {
        y = y_;
    }

    function gety() public view returns (uint256 retval) {
        return y;
    }
}