/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;


contract FoodsLikesHates {
    uint pizzaLikes=0;
    uint pizzaHates=0;
    uint hamburgerLikes=0;
    uint hamburgerHates=0;

    //write
    function addPizzaLikes() public returns(uint) {
        pizzaLikes = pizzaLikes+1;
        return pizzaLikes;
    }
    function addPizzaHates() public returns(uint) {
        pizzaHates = pizzaHates+1;
        return pizzaHates;
    }
    function addHamburgerLikes() public returns(uint) {
        hamburgerLikes = hamburgerLikes+1;
        return hamburgerLikes;
    }
    function HamburgerHates() public returns(uint) {
        hamburgerHates = hamburgerHates+1;
        return hamburgerHates;
    }

    //view
    function viewPizzaLikes() public view returns(uint) {
        return pizzaLikes;
    }
    function viewPizzaHates() public view returns(uint) {
        return pizzaHates;
    }
    function viewHamburgerLikes() public view returns(uint) {
        return hamburgerLikes;
    }
    function viewHamburgerHates() public view returns(uint) {
        return hamburgerHates;
    }

}