/**
 *Submitted for verification at Etherscan.io on 2022-08-22
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

pragma solidity 0.8.15;

// Standard Maker Teleport GUID
struct TeleportGUID {
    bytes32 sourceDomain;
    bytes32 targetDomain;
    bytes32 receiver;
    bytes32 operator;
    uint128 amount;
    uint80 nonce;
    uint48 timestamp;
}

// solhint-disable-next-line func-visibility
function bytes32ToAddress(bytes32 addr) pure returns (address) {
    return address(uint160(uint256(addr)));
}

// solhint-disable-next-line func-visibility
function addressToBytes32(address addr) pure returns (bytes32) {
    return bytes32(uint256(uint160(addr)));
}

// solhint-disable-next-line func-visibility
function getGUIDHash(TeleportGUID memory teleportGUID) pure returns (bytes32 guidHash) {
    guidHash = keccak256(abi.encode(
        teleportGUID.sourceDomain,
        teleportGUID.targetDomain,
        teleportGUID.receiver,
        teleportGUID.operator,
        teleportGUID.amount,
        teleportGUID.nonce,
        teleportGUID.timestamp
    ));
}

// Calculate fees for a given Teleport GUID
interface TeleportFees {
    /**
    * @dev Return fee for particular teleport. It should return 0 for teleports that are being slow withdrawn. 
    * note: We define slow withdrawal as teleport older than x. x has to be enough to finalize flush (not teleport itself).
    * @param teleportGUID Struct which contains the whole teleport data
    * @param line Debt ceiling
    * @param debt Current debt
    * @param pending Amount left to withdraw
    * @param amtToTake Amount to take. Can be less or equal to teleportGUID.amount b/c of debt ceiling or because it is pending
    * @return fees Fee amount [WAD]
    **/
    function getFee(
        TeleportGUID calldata teleportGUID, uint256 line, int256 debt, uint256 pending, uint256 amtToTake
    ) external view returns (uint256 fees);
}

contract TeleportLinearFee is TeleportFees {
    uint256 immutable public fee;
    uint256 immutable public ttl;

    uint256 constant public WAD = 10 ** 18;

    /**
    * @param _fee Fee percentage in WAD (e.g 1% fee = 0.01 * WAD)
    * @param _ttl Time in seconds to finalize flush (not teleport)
    **/
    constructor(uint256 _fee, uint256 _ttl) {
        fee = _fee;
        ttl = _ttl;
    }

    function getFee(TeleportGUID calldata guid, uint256, int256, uint256, uint256 amtToTake) override external view returns (uint256) {
        // is slow withdrawal?
        if (block.timestamp >= uint256(guid.timestamp) + ttl) {
            return 0;
        }

        return fee * amtToTake / WAD;
    }
}