// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract Lesson9Solver {
    address private constant LESSON_NINE_ADDRESS =
        0x33e1fD270599188BB1489a169dF1f0be08b83509;

    function calculateSolution() private view returns (uint256) {
        uint256 correctAnswer = uint256(
            keccak256(
                abi.encodePacked(msg.sender, block.prevrandao, block.timestamp)
            )
        ) % 100000;
        return correctAnswer;
    }

    function solveChallenge() external {
        address lessonNineContract = LESSON_NINE_ADDRESS;
        uint256 solution = calculateSolution();
        string memory twitterHandle = "@PurpleFortress_"; // Add your Twitter handle here if desired

        (bool success, ) = lessonNineContract.call(
            abi.encodeWithSignature(
                "solveChallenge(uint256,string)",
                solution,
                twitterHandle
            )
        );
        require(success, "Challenge solution failed");
    }
}