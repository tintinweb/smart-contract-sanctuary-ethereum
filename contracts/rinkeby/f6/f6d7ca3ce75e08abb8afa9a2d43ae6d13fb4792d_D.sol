/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 < 0.9.0;

contract D{
    uint a;
    string b;
    string c = "a";

    function getC() public view returns(string memory) {
        return c;
    }

    function changeC() public returns(string memory)    {
        c = "abc";
        return c;
    }

    function plus() public returns(uint)    {
        a = a + 1;
        return a;
    }

    function minus() public returns(uint)   {
        a = a - 1;
        return a;
    }
    int d;
    function abc() public returns(int)  {
        d = -2;
        return d;
    }
}