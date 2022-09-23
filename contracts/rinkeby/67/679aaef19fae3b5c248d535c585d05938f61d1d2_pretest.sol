/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 2022.09.23 public view
pragma solidity 0.8.0;

contract pretest {

    uint pizl;
    uint haml;
    uint pizh;
    uint hamh;


    function likepizza() public returns(uint){
        pizl = pizl+1;
        return pizl;
    }

    function likepizza1 () public view returns (uint) {
        return pizl;
    }

    function dislikepizza() public returns(uint){
        pizh = pizh+1;
        return pizh;
    }
    function dislikepizza1 () public view returns (uint) {
        return pizh;
    }

    function likehamburger() public returns(uint){
        haml = haml+1;
        return haml;
    }
    function likehamburger1 () public view returns (uint) {
    return haml;
    }

    function dislikehamburger() public returns(uint){
        hamh = hamh+1;
        return hamh;
    }
    function dislikehamburger1 () public view returns (uint) {
        return hamh;
    }
}