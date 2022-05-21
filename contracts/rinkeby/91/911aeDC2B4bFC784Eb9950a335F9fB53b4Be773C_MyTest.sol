// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract MyTest {
    bool public solved = false;

    function setSolve(bool _newValue) external {
        solved = _newValue;
    }
}