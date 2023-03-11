// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;


contract Sazmn{
    int private x;

    function getX() public view returns (int) {
        return x;
    }

    function setX(int _x) public {
        x = _x;
    }
}