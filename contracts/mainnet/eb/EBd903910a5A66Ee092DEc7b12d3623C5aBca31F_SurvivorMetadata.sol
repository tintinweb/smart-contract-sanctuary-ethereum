// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title SurvivorMetadata
/// @author Gordon
/// @notice Provides metadata information for survivors


contract SurvivorMetadata {
    function getHead() public pure returns (string[44] memory) {
        return ["Hat 1","Hat 2","Hat 3","Hat 4","Hat 5","Hat 6","Hat 7","Hat 8","Sunglasses 1","Sunglasses 2","Face Marking 1","Face Marking 2","Face Marking 3","Hat 9","Sunglasses 3","Sunglasses 4","Sunglasses 5","Sunglasses 6","Sunglasses 7","Sunglasses 8","Sunglasses 9","Sunglasses 10","Face Marking 4","Sunglasses 11","Sunglasses 12","Sunglasses 13","Sunglasses 14","Sunglasses 15","Sunglasses 16","Sunglasses 17","Sunglasses 18","Hat 10","Hat 11","Hat 12","Hat 13","Hat 14","Hat 15","Hat 16","Hat 17","Hat 18","None","None","None","None"];
    }
}