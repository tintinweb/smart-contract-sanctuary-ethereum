/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract foodpick {
    uint hamGood;
    uint hamBad;
    uint pizGood;
    uint pizBad;

    function unlikeHam() public returns(uint) {
        return hamBad++;
    }

    function likeHam() public returns(uint) {
        return hamGood++;
    }
    function unlikePiz() public returns(uint) {
        return pizBad++;
    }
    function likePiz() public returns(uint) {
        return pizGood++;
    }

    function getLikeUnlike() public view returns(uint, uint, uint, uint) {
        return (hamGood, hamBad, pizGood, pizBad);
    }
}