/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract G {
    uint likeBurger;
    uint hateBurger;
    uint likePizza;
    uint hatePizza;

    function burgerYes() public returns(uint) {
        likeBurger += 1;
        return likeBurger;
    }

    function burgerNo() public returns(uint) {
        hateBurger += 1;
        return hateBurger;
    }

    function pizzaYes() public returns(uint) {
        likePizza += 1;
        return likePizza;
    }

    function pizzaNo() public returns(uint) {
        hatePizza += 1;
        return hatePizza;
    }
}