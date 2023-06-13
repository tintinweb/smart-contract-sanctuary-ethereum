/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface LessonNine {
    function solveChallenge(
        uint256 randomGuess,
        string memory yourTwitterHandle
    ) external;
}

contract Chall {
    function solve(string memory name) external {
        uint256 correctAnswer = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.prevrandao, block.timestamp)
            )
        ) % 100000;
        LessonNine chall = LessonNine(
            0x33e1fD270599188BB1489a169dF1f0be08b83509
        );
        chall.solveChallenge(correctAnswer, name);
    }
}