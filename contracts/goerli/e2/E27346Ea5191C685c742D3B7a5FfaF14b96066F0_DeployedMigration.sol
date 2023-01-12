// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DeployedMigration {
    event Deployed(address addr);

    function manualCreate(address[] calldata addresses) external {
        for (uint i = 0; i < addresses.length; i++) {
            emit Deployed(addresses[i]);
        }
    }
}