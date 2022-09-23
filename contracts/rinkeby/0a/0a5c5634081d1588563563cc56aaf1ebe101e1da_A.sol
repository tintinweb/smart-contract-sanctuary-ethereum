/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
// 20220922
pragma solidity 0.8.0;

contract A {
    
    uint pizza = 0;
    uint burger = 0;
    function likePizza() public returns(uint){    
        pizza = pizza+1;
        return pizza;
    }

    function disLikePizza() public returns(uint){
        pizza = pizza-1;
        return pizza;
    }

    function likeBurger() public returns(uint){
        burger = burger+1;
        return burger;
    }

    function disLikeBurger() public returns(uint){
        burger = burger-1;
        return burger;
    }


}