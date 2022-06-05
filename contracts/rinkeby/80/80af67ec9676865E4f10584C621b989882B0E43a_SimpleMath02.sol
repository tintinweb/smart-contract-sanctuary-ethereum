// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleMath02
{
    function Add(int a, int b) external pure returns(int)
    {
        return a + b;
    }

    function Sub(int a, int b) external pure returns(int)
    {
        return a - b;
    }

    function Mul(int a, int b) external pure returns(int)
    {
        return a * b;
    }
}