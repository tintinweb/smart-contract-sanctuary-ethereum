/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract foodPreference {
    uint likePizza = 0;
    uint likeHamburger = 0;
    uint dislikePizza = 0;
    uint dislikeHamburger = 0;

    function likePza() public returns(uint) {
        likePizza = likePizza + 1;
        return likePizza;

    }

    function likeHbr() public returns(uint) {
        likeHamburger = likeHamburger + 1;
        return likeHamburger;
    }

    function dislikePza() public returns(uint) {
        dislikePizza = dislikePizza + 1;
        return dislikePizza;

    }
    function dislikeHbr() public returns(uint) {
        dislikeHamburger = dislikeHamburger + 1;
        return dislikeHamburger;
    }

    function likePizzaV() public view returns(uint) {
        return likePizza;
    }
    function likeHamburgerV() public view returns(uint) {
        return likeHamburger;
    }
    function dislikePizzaV() public view returns(uint) {
        return dislikePizza;
    }
    function dislikeHamburgerV() public view returns(uint) {
        return dislikeHamburger;
    }



}