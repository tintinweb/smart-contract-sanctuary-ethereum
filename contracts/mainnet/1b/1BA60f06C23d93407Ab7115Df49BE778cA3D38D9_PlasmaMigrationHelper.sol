/**
 *Submitted for verification at Etherscan.io on 2022-03-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface iPlasma {
    function migrateRewardsFor(address address_) external;
}

contract PlasmaMigrationHelper {
    function migrateMany(address contract_, address[] calldata addresses_) external {
        for (uint256 i = 0; i < addresses_.length; i++) {
            iPlasma(contract_).migrateRewardsFor(addresses_[i]);
        }
    }
}