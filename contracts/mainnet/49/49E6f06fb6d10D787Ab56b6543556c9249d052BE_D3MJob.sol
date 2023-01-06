/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
pragma solidity 0.8.13;

/// @title Maker Keeper Network Job
/// @notice A job represents an independant unit of work that can be done by a keeper
interface IJob {

    /// @notice Executes this unit of work
    /// @dev Should revert iff workable() returns canWork of false
    /// @param network The name of the external keeper network
    /// @param args Custom arguments supplied to the job, should be copied from workable response
    function work(bytes32 network, bytes calldata args) external;

    /// @notice Ask this job if it has a unit of work available
    /// @dev This should never revert, only return false if nothing is available
    /// @dev This should normally be a view, but sometimes that's not possible
    /// @param network The name of the external keeper network
    /// @return canWork Returns true if a unit of work is available
    /// @return args The custom arguments to be provided to work() or an error string if canWork is false
    function workable(bytes32 network) external returns (bool canWork, bytes memory args);

}

interface SequencerLike {
    function isMaster(bytes32 network) external view returns (bool);
}

interface IlkRegistryLike {
    function list() external view returns (bytes32[] memory);
}

interface VatLike {
    function urns(bytes32, address) external view returns (uint256, uint256);
}

interface D3MHubLike {
    function vat() external view returns (VatLike);
    function pool(bytes32) external view returns (address);
    function exec(bytes32) external;
}

/// @title Trigger D3M updates based on threshold
contract D3MJob is IJob {

    uint256 constant internal BPS = 10 ** 4;
    
    SequencerLike public immutable sequencer;
    IlkRegistryLike public immutable ilkRegistry;
    D3MHubLike public immutable hub;
    VatLike public immutable vat;
    uint256 public immutable threshold;             // Threshold deviation to kick off exec [BPS]
    uint256 public immutable ttl;                   // Cooldown before you can call exec again [seconds]

    mapping (bytes32 => uint256) public expiry;     // Timestamp of when exec is allowed again

    // --- Errors ---
    error NotMaster(bytes32 network);
    error Cooldown(bytes32 ilk, uint256 expiry);
    error ShouldNotTrigger(bytes32 ilk, uint256 part, uint256 nart);

    // --- Events ---
    event Work(bytes32 indexed network);

    constructor(address _sequencer, address _ilkRegistry, address _hub, uint256 _threshold, uint256 _ttl) {
        sequencer = SequencerLike(_sequencer);
        ilkRegistry = IlkRegistryLike(_ilkRegistry);
        hub = D3MHubLike(_hub);
        vat = hub.vat();
        threshold = _threshold;
        ttl = _ttl;
    }

    function shouldTrigger(uint256 part, uint256 nart) internal view returns (bool) {
        if (part == 0 && nart != 0) return true;    // From zero to non-zero
        if (part != 0 && nart == 0) return true;    // From non-zero to zero

        // Check if the delta is above the threshold
        uint256 delta = nart * BPS / part;
        if (delta < BPS) delta = BPS * BPS / delta; // Flip decreases to increase

        return delta >= (BPS + threshold);
    }

    function work(bytes32 network, bytes calldata args) external override {
        if (!sequencer.isMaster(network)) revert NotMaster(network);

        bytes32 ilk = abi.decode(args, (bytes32));
        uint256 _expiry = expiry[ilk];
        if (block.timestamp < _expiry) revert Cooldown(ilk, _expiry);
        address pool = hub.pool(ilk);
        (, uint256 part) = vat.urns(ilk, pool);

        hub.exec(ilk);

        (, uint256 nart) = vat.urns(ilk, pool);
        if (!shouldTrigger(part, nart)) revert ShouldNotTrigger(ilk, part, nart);
        
        expiry[ilk] = block.timestamp + ttl;

        emit Work(network);
    }

    function workable(bytes32 network) external override returns (bool, bytes memory) {
        if (!sequencer.isMaster(network)) return (false, bytes("Network is not master"));

        bytes32[] memory ilks = ilkRegistry.list();
        for (uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];
            address pool = hub.pool(ilk);

            if (pool == address(0)) continue;     // Is this a D3M?

            // Execute the D3M and see if the assets deployed change enough to warrant an update
            (, uint256 part) = vat.urns(ilk, pool);
            try hub.exec(ilk) {
                (, uint256 nart) = vat.urns(ilk, pool);
                if (block.timestamp < expiry[ilk]) continue;
                if (!shouldTrigger(part, nart)) continue;

                // Found a valid execution
                return (true, abi.encode(ilk));
            } catch {
                // For some reason this errored -- carry on
            }
        }

        return (false, bytes("No ilks ready"));
    }

}