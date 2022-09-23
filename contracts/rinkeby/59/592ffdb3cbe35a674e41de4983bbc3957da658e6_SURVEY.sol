/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract SURVEY {

    int pizza = 0; int pizza_h = 0;
    int burger = 0; int burger_h = 0;

    function like_pizza() public returns(int) {
        pizza = pizza + 1;
        return pizza;
    }

    function not_like_pizza() public returns(int){
        pizza_h = pizza_h + 1;
        return pizza_h;
    }

    function like_burger() public returns(int){
        burger = burger + 1;
        return burger;
    }

    function not_like_burger() public returns(int){
        burger_h = burger_h + 1;
        return burger_h;
    }

    function viewer() public view returns (int, int, int, int) {
        return (pizza, pizza_h, burger, burger_h);
    }

}