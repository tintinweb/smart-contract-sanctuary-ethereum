/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract H {
    
    uint a = 0;
    uint b = 0;
    uint c = 0;
    uint d = 1;

    
    function PizzaLike() public returns(uint) {
        a = a+1;
        return a;
    }

    function PizzaHate() public returns(uint) {
        b = b+1;
        return b;
    }

    function BugerLike() public returns(uint) {
        c = c+1;
        return c;
    }

    function BugerHate() public returns(uint) {
        d = b+1;
        return d;
    }


}