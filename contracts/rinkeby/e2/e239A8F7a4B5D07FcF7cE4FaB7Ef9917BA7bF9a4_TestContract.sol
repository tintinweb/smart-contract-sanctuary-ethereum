// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract
{
    uint stateVar;

    constructor()
    {
        stateVar = 100;
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