// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Example {
    uint256 num = 767;
    string name = "ABDULLAH MEHBOOB";

    function setNumber(uint256 _num) public {
        num = _num;
    }

    function setName(string memory _name) public {
        name = _name;
    }
}