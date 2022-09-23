/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract foodPreference {
    uint pizza;
    uint Hambuger;
    function likePza() public returns(uint) {
        pizza = pizza + 1;
        return pizza;

    }

    function likeHbr() public returns(uint) {
        Hambuger = Hambuger + 1;
        return Hambuger;
    }

}