/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract ElderShadeling {
    bytes32 prediction;
    uint256 blockNumber;

    bool public isPredicted;

    function commitPrediction(bytes32 x) external {
        prediction = x;
        blockNumber = block.number;
    }

    function checkPrediction() external {
        // Ensure prediction is checked at a later block.
        require(block.number > blockNumber + 1);

        require(prediction == blockhash(blockNumber + 1));
        isPredicted = true;
    }
    
}