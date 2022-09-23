/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
//20220922
pragma solidity 0.8.0;

contract SURVEY {
    uint b;

    function pizzaLike() public returns(uint){
        b = b + 1;
        return b;
    }

    function pizzaDislike() public returns(uint){
        b = b + 1;
        return b;
    }

    function burgerLike() public returns(uint){
        b = b + 1;
        return b;
    }

    function burgerDislike() public returns(uint){
        b = b + 1;
        return b;
    }
}