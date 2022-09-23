/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract foodPreference {
    uint pizza;
    uint Hamburger;
    function likePza() public returns(uint) {
        pizza = pizza + 1;
        return pizza;

    }

    function likeHbr() public returns(uint) {
        Hamburger = Hamburger + 1;
        return Hamburger;
    }

}