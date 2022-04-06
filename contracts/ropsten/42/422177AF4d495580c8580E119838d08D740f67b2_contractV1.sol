//SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract contractV1{
    uint val;
    function initialize(uint _val) external {
        val = _val;
    }
}