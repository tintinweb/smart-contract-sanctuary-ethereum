/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract P {
    int pizza1 = 0;
    int pizza2 = 0;
    int ham1 = 0;
    int ham2 = 0;

    function likepizza() public returns(int) {
        pizza1 = pizza1 + 1;
        return pizza1;
    }

    function nopizza() public returns(int) {
        pizza2 = pizza2 + 1;
        return pizza2;
    }
    

    function likeham() public returns(int) {
        ham1 = ham1 + 1;
        return ham1;
    }

    function noham() public returns(int) {
        ham2 = ham2 + 1;
        return ham2;
    }

    function a() public view returns(int, int, int, int) {
        return (pizza1,pizza2,ham1,ham2);
    }

}