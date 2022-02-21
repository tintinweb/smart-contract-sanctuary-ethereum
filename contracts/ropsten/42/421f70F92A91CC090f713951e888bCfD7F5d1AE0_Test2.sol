// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract Test2 {
    uint data;

    function set(uint x) public {
        data = x*2;
    }

    function get() public view returns (uint) {
        return data;
    }
}