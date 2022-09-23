/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract A {

    uint pizzaLike = 0;
    uint pizzaHate = 0;

    uint hamburgerLike = 0;
    uint hamburgerHate = 0;
    
    function PizzaLike () public view returns (uint) {
        return pizzaLike+1;
    }

    function PizzaHate () public view returns (uint) {
        return pizzaHate+1;
    }

    function HamburgerLike () public view returns (uint) {
        return hamburgerLike+1;
    }

    function HamburgerHate () public view returns (uint) {
        return hamburgerHate+1;
    }

    function Result () public view returns (uint, uint, uint, uint) {
        return (pizzaLike, pizzaHate, hamburgerLike, hamburgerHate);
    }

  

    }