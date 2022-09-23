/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.0;

contract Test {
    uint pizzaLike = 0;
    uint pizzaDislike = 0;
    uint hamburgerLike = 0;
    uint hamburgerDislike = 0;

    function likePizza() public returns(uint) {
        return ++pizzaLike;
    }

    function dislikePizza() public returns(uint) {
        return ++pizzaDislike;
    }

    function likeHamburger() public returns(uint) {
        return ++hamburgerLike;
    }

    function dislikeHamburger() public returns(uint) {
        return ++hamburgerDislike;
    }
}