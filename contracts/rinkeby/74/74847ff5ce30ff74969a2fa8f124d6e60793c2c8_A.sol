/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract A{

    uint pizzaGood =0;
    uint pizzaHate =0;
    uint hambGood =0;
    uint hambHate =0;

    function show() public view returns(uint,uint,uint,uint) {
        return (pizzaGood,hambGood,pizzaHate,hambHate);
    }

    function lovePizza() public returns(uint){
        pizzaGood++;
        return pizzaGood;
    }

    function loveHamb() public returns(uint){
        hambGood++;
        return hambGood;
    }

    function hatePizza() public returns(uint){
        pizzaHate--;
        return pizzaHate;
    }

    function hateHamb() public returns(uint){
        hambHate--;
        return hambHate;
    }


}