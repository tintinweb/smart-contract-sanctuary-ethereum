/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 2022.09.23 public view
pragma solidity 0.8.0;

contract pretest {

    uint piz;
    uint ham;


    function likepizza() public returns(uint){
        piz = piz+1;
        return piz;
    }

    function dislikepizza() public returns(uint){
        piz = piz+1;
        return piz;
    }

    function likehamburger() public returns(uint){
        ham = ham+1;
        return ham;
    }

    function dislikehamburger() public returns(uint){
        ham = ham+1;
        return ham;
    }

}