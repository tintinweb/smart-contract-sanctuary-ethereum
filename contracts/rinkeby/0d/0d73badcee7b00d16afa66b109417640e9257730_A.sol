/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract A {

    uint LikePizza = 0;
    uint DislikePizza = 0;
    uint LikeHamburger = 0;
    uint DislikeHamburger = 0;

    function LikesPizza() public returns(uint) {
        LikePizza = LikePizza + 1;
        return LikePizza;
    }

    function DislikesPizza() public returns(uint) {
        DislikePizza = DislikePizza + 1;
        return DislikePizza;
    }

    function LikesHamburger() public returns(uint) {
        LikeHamburger = LikeHamburger + 1;
        return LikeHamburger;
    }

    function DislikesHamburger() public returns(uint) {
        DislikeHamburger = DislikeHamburger + 1;
        return DislikeHamburger;
    }

}