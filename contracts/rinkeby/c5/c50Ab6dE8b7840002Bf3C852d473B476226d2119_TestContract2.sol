// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract2
{
    uint stateVar;

    constructor(uint initVal)
    {
        stateVar = initVal;
    }

    function GetValue() external view returns(uint)
    {
        return stateVar;
    }

    function SetValue(uint val) external
    {
        stateVar = val;
    }
}