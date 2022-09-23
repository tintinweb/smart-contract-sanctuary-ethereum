/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract Cal {

    uint a;
    uint b;
    uint c;
    uint d;

    function pizzalove0 () public returns (uint) {
        a = a+1;
        return a;
    }

    function pizzalove () public view returns (uint) {
        return a;
    }

    function pizzahate0 () public returns (uint) {
        b = b+1;
        return b;
    }

    function pizzahate () public view returns (uint) {
        return b;
    }

    function hamlove0 () public returns (uint) {
        c = c+1;
        return c;
    }

    function hamlove () public view returns (uint) {
        return c;
    }

    function hamhate0 () public returns (uint) {
        d = d+1;
        return d;
    }
        
    function hamhate () public view returns (uint) {
        return d;
    }
}