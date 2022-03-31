// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
// @unsupported: ovm
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

pragma solidity >=0.7.6;

// Relay a message from L1 to L2GovernanceRelay

/// @notice Indicator that the operation can interact with Rollup and Porter trees, or only with Rollup
enum OpTree {
    Full,
    Rollup
}

enum QueueType {
    Deque,
    HeapBuffer,
    Heap
}

interface ZkSyncLike {
    function requestExecute(
        address _contractAddressL2,
        bytes memory _calldata,
        uint256 _ergsLimit,
        QueueType _queueType,
        OpTree _opTree
    ) external payable;
}

interface L2GovernanceRelayLike {
    function relay(address target, bytes calldata targetData) external payable;
}

contract L1GovernanceRelay {
    // --- Auth ---
    mapping(address => uint256) public wards;
    address public immutable zkSyncAddress;

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth() {
        require(wards[msg.sender] == 1, "L1GovernanceRelay/not-authorized");
        _;
    }

    address public immutable l2GovernanceRelay;

    event Rely(address indexed usr);
    event Deny(address indexed usr);

    constructor(address _l2GovernanceRelay, address _zkSyncAddress) {
        wards[msg.sender] = 1;
        emit Rely(msg.sender);

        l2GovernanceRelay = _l2GovernanceRelay;
        zkSyncAddress = _zkSyncAddress;
    }

    // Forward a call to be repeated on L2
    function relay(
        address target,
        bytes calldata targetData,
        uint256 ergsLimit
    ) external auth {
        bytes memory data = abi.encodeWithSelector(
            L2GovernanceRelayLike.relay.selector,
            target,
            targetData
        );

        _callZkSync(l2GovernanceRelay, data, ergsLimit);
    }

    function _callZkSync(
        address contractAddr,
        bytes memory data,
        uint256 ergsLimit
    ) internal {
        ZkSyncLike zksync = ZkSyncLike(zkSyncAddress);
        zksync.requestExecute{value: msg.value}(
            contractAddr,
            data,
            ergsLimit,
            QueueType.Deque,
            OpTree.Full
        );
    }
}