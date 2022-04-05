/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.4.24;

contract Calculator{

    uint result=0;


    function getResult() public view returns (uint)
    {
        return result;
    }

    function addition(uint num) public
    {
        result=result+num;

    }

    function sub(uint num) public
    {
        result = result - num;
    }

    function mult(uint num) public
    {
        result =result*num;
    }

    function div(uint num) public
    {
        result = result/num;
    }

    }