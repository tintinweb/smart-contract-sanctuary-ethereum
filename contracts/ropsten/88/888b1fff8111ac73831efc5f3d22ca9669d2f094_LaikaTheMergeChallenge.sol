/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @title Laika the merge challenge contract
/// @notice A simple contract to store address of Laika The Merge Challenge participants.
/// Inspiration from https://gist.github.com/m1guelpf/6d09b85d70a1dfd00d394b2acf789eeb
contract LaikaTheMergeChallenge {
    address[] public participants;

    /// @notice Get name of the contract
    function signMeUp() public {
        if (haveWeMergedYet()) {
            participants.push(msg.sender);
        }
    }

    /// @notice Determine whether we're running in Proof of Work or Proof of Stake
    /// @dev Post-merge, the DIFFICULTY opcode gets renamed to PREVRANDAO, and stores the prevRandao field from the beacon chain state.
    function haveWeMergedYet() public view returns (bool) {
        return block.difficulty > 2**64;
    }
}