/**
 *Submitted for verification at Etherscan.io on 2023-02-03
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @title Stores common interface names used throughout Spire contracts by registration in the ConfigStore.
 */
library ConfigStoreInterfaces {
    // Receives staked treasure from Contest winners and ETH from minting losing entries.
    bytes32 public constant BENEFICIARY = "BENEFICIARY";
    // Creates new Contests
    bytes32 public constant CONTEST_FACTORY = "CONTEST_FACTORY";
    // Creates new ToggleGovernors
    bytes32 public constant TOGGLE_GOVERNOR_FACTORY = "TOGGLE_GOVERNOR_FACTORY";
}

/**
 * @title Global constants used throughout Spire contracts.
 *
 */
library GlobalConstants {
    uint256 public constant GENESIS_TEXT_COUNT = 8;
    uint256 public constant CONTEST_REWARD_AMOUNT = 100;
    uint256 public constant INITIAL_ECHO_COUNT = 5;
    uint256 public constant DEFAULT_CONTEST_MINIMUM_TIME = 7 days;
    uint256 public constant DEFAULT_CONTEST_MINIMUM_APPROVED_ENTRIES = 8;
}