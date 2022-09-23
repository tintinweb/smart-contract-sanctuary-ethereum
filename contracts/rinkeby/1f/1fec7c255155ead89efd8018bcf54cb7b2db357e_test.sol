/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract test{
    uint p1;
    uint p2;
    uint p3;
    uint p4;

    function like_pizza_w() public returns(uint){
        p1 = p1 + 1;
        return p1;
    }

    function like_pizza() public view returns(uint){
        return p1;
    }

    function hate_pizza_w() public returns(uint){
        p2 = p2 + 1;
        return p2;
    }

    function hate_pizza() public view returns(uint){
        return p2;
    }

    function like_burger_w() public returns(uint){
        p3 = p3 + 1;
        return p3;
    }
    function like_burger() public view returns(uint){
        return p3;
    }

    function hate_burger_w() public returns(uint){
        p4 = p4 + 1;
        return p4;
    }

    function hate_burger() public view returns(uint){
        return p4;
    }
}