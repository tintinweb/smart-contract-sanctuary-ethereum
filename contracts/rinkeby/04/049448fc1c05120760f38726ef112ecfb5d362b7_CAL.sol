/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220923
pragma solidity 0.8.0;

contract CAL {

    uint h1;
    uint p1;
    uint h2;
    uint p2;

    function pizzalike() public returns(uint) {
        h1=h1+1;
        return h1;
    }

    function pizzaunlike() public returns(uint) {
        p1=p1+1;
        return p1;
    }
    
    function hambergerlike() public returns(uint) {
        h2=h2+1;
        return h2;
    }
    
    function hambergerunlike() public returns(uint) {
        p2=p2+1;
        return p2;
    }
}