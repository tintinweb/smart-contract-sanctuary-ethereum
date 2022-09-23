/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract CAL {

    uint o1;
    uint x1;
    uint o2;
    uint x2;

    function pizzaThumbsUp() public returns(uint) {
        o1=o1+1;
        return o1;
    }

    function pizzaThumbsDown() public returns(uint) {
        x1=x1+1;
        return x1;
    }
    
    function HambergerThumbsUp() public returns(uint) {
        o2=o2+1;
        return o2;
    }
    
    function HambergerThumbsDown() public returns(uint) {
        x2=x2+1;
        return x2;
    }
}