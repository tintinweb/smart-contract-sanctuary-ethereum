// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract implementation_v1
{
    uint i;

    function initialize(uint _i) public
    {
        i = _i;
    }

    function inc1() public
    {
        i++;
    }
}