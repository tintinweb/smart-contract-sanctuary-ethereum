/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract food {

    uint aa;
    uint bb;
    uint cc;
    uint dd;
   

    function like_pizza() public returns(uint) {
       aa = aa+1;
        return aa;
    }

    function dislike_pizza() public returns(uint) {
        bb=bb+1;
        return bb;
    }
     function like_burger() public returns(uint) {
        cc=cc+1;
        return cc;
    } function dislik_burger() public returns(uint) {
        dd=dd+1;
        return dd;
    }

}