// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

contract Sample {
    uint public val;

    function init(uint _val) external {
        val = _val;
    }
}