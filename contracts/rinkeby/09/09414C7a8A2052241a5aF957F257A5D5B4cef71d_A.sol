/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract A {

    uint pizzaUp = 0;
    uint pizzaDown = 0;

    uint hamburgerUp = 0;
    uint hamburgerDown = 0;
    
    function PizzaLike () public returns (uint) {
        return pizzaUp++;
    }

    function PizzaUnLike () public returns (uint) {
        return pizzaDown++;
    }

    function HamburgerLike () public returns (uint) {
        return hamburgerUp++;
    }

    function HamburgerUnLike () public returns (uint) {
        return hamburgerDown++;
    }

    function Result () public returns (uint, uint, uint, uint) {
        return (pizzaUp, pizzaDown, hamburgerUp, hamburgerDown);
    }

  

    }