/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TelemetrySigner {
    address private owner;

    event TelemetrySigned(
        bytes16 indexed scopeId,
        uint64 indexed observationMonth,
        bytes32 indexed telemetryHash
    );

    constructor() {
        owner = msg.sender;
    }

    /**
     * Raises the 'TelemetrySigned' event which contains information about
     * scope (building/sensor) and it's telemetry hash for the specified period (month)
     */
    function signTelemetry(
        bytes16 scopeId,
        uint64 observationMonth,
        bytes32 telemetryHash
    ) external {
        require(msg.sender == owner, "Access denied");

        emit TelemetrySigned(scopeId, observationMonth, telemetryHash);
    }
}