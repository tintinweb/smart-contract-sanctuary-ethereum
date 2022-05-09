/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract CoinFlip {
    function consecutiveWins() public pure returns (uint256) {}
    function flip(bool _guess) public returns (bool) {}
}

contract My {
    CoinFlip cf;
    function run(address addr) public{
        cf = CoinFlip(addr);
        for (uint i=0; i<10; i++) {
            cf.flip(true);
        }
    }
}