// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

// Simplified StarkPerpetual contract to emit the monitored events.
contract StarkPerpetual {
    // Monitored events.
    event LogGlobalConfigurationRegistered(bytes32 configHash);
    event LogGlobalConfigurationApplied(bytes32 configHash);
    event LogGlobalConfigurationRemoved(bytes32 configHash);

    function registerGlobalConfigurationChange(bytes32 configHash) external {
        emit LogGlobalConfigurationRegistered(configHash);
    }

    function applyGlobalConfigurationChange(bytes32 configHash) external {
        emit LogGlobalConfigurationApplied(configHash);
    }

    function removeGlobalConfigurationChange(bytes32 configHash) external {
        emit LogGlobalConfigurationRemoved(configHash);
    }
}