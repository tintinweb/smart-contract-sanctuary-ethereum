/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.8.13 >=0.8.0;

////// src/interfaces/IJob.sol
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
/* pragma solidity >=0.8.0; */

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

////// src/ClipperMomJob.sol
// Copyright (C) 2022 Dai Foundation
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
/* pragma solidity 0.8.13; */

/* import {IJob} from "./interfaces/IJob.sol"; */

interface SequencerLike_3 {
    function isMaster(bytes32 network) external view returns (bool);
}

interface IlkRegistryLike_2 {
    function list() external view returns (bytes32[] memory);
    function info(bytes32 ilk) external view returns (
        string memory name,
        string memory symbol,
        uint256 class,
        uint256 dec,
        address gem,
        address pip,
        address join,
        address xlip
    );
}

interface ClipperMomLike {
    function tripBreaker(address clip) external;
}

/// @title Will trigger a clipper to shutdown if oracle price drops too quickly
contract ClipperMomJob is IJob {
    
    SequencerLike_3 public immutable sequencer;
    IlkRegistryLike_2 public immutable ilkRegistry;
    ClipperMomLike public immutable clipperMom;

    // --- Errors ---
    error NotMaster(bytes32 network);

    // --- Events ---
    event Work(bytes32 indexed network, address indexed clip);

    constructor(address _sequencer, address _ilkRegistry, address _clipperMom) {
        sequencer = SequencerLike_3(_sequencer);
        ilkRegistry = IlkRegistryLike_2(_ilkRegistry);
        clipperMom = ClipperMomLike(_clipperMom);
    }

    function work(bytes32 network, bytes calldata args) external override {
        if (!sequencer.isMaster(network)) revert NotMaster(network);

        address clip = abi.decode(args, (address));
        clipperMom.tripBreaker(clip);

        emit Work(network, clip);
    }

    function workable(bytes32 network) external override returns (bool, bytes memory) {
        if (!sequencer.isMaster(network)) return (false, bytes("Network is not master"));
        
        bytes32[] memory ilks = ilkRegistry.list();
        for (uint256 i = 0; i < ilks.length; i++) {
            (,, uint256 class,,,,, address clip) = ilkRegistry.info(ilks[i]);
            if (class != 1) continue;
            if (clip == address(0)) continue;

            // We cannot retrieve oracle prices (whitelist-only), so we have to just try and run the trip breaker
            try clipperMom.tripBreaker(clip) {
                // Found a valid trip
                return (true, abi.encode(clip));
            } catch {
                // No valid trip -- carry on
            }
        }

        return (false, bytes("No ilks ready"));
    }

}