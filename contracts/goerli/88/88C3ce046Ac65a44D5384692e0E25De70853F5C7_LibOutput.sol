// Copyright 2021 Cartesi Pte. Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

/// @title Output library
pragma solidity ^0.8.0;

library LibOutput {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("Output.diamond.storage");

    struct DiamondStorage {
        mapping(uint256 => uint256) voucherBitmask;
        bytes32[] epochHashes;
        bool lock; //reentrancy lock
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice to be called when an epoch is finalized
    /// @param ds diamond storage pointer
    /// @param epochHash hash of finalized epoch
    /// @dev an epoch being finalized means that its vouchers can be called
    function onNewEpoch(DiamondStorage storage ds, bytes32 epochHash) internal {
        ds.epochHashes.push(epochHash);
    }

    /// @notice get number of finalized epochs
    /// @param ds diamond storage pointer
    function getNumberOfFinalizedEpochs(DiamondStorage storage ds)
        internal
        view
        returns (uint256)
    {
        return ds.epochHashes.length;
    }
}