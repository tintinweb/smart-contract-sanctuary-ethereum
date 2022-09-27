/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// hevm: flattened sources of src/truth/darwinia/DarwiniaMessageVerifier.sol
// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.7.6;
pragma abicoder v2;

////// src/interfaces/ILightClient.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */

interface ILightClient {
    function merkle_root() external view returns (bytes32);
}

////// src/interfaces/IVerifier.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */

interface IVerifier {
    function verify_messages_proof(
        bytes32 outlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool);

    function verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external view returns (bool);
}

////// src/spec/MessageProof.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */

struct MessageProof {
    MessageSingleProof chainProof;
    MessageSingleProof laneProof;
}

struct MessageSingleProof {
    bytes32 root;
    bytes32[] proof;
}

////// src/utils/SparseMerkleProof.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */

/// @title A verifier for sparse merkle tree.
/// @author echo
/// @notice Sparse Merkle Tree is constructed from 2^n-length leaves, where n is the tree depth
///  equal to log2(number of leafs) and it's initially hashed using the `keccak256` hash function as the inner nodes.
///  Inner nodes are created by concatenating child hashes and hashing again.
library SparseMerkleProof {

    function hash_node(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32 hash)
    {
        assembly {
            mstore(0x00, left)
            mstore(0x20, right)
            hash := keccak256(0x00, 0x40)
        }
    }

    /// @notice Verify that a specific leaf element is part of the Sparse Merkle Tree at a specific position in the tree.
    //
    /// @param root The root of the merkle tree
    /// @param leaf The leaf which needs to be proven
    /// @param pos The position of the leaf, index starting with 0
    /// @param proof The array of proofs to help verify the leaf's membership, ordered from leaf to root
    /// @return A boolean value representing the success or failure of the verification
    function singleVerify(
        bytes32 root,
        bytes32 leaf,
        uint256 pos,
        bytes32[] memory proof
    ) internal pure returns (bool) {
        uint256 depth = proof.length;
        uint256 index = (1 << depth) + pos;
        bytes32 value = leaf;
        for (uint256 i = 0; i < depth; ++i) {
            if (index & 1 == 0) {
                value = hash_node(value, proof[i]);
            } else {
                value = hash_node(proof[i], value);
            }
            index = index >> 1;
        }
        return value == root && index == 1;
    }

    /// @notice Verify that multi leafs in the Sparse Merkle Tree with generalized indices.
    /// @dev Indices are required to be sorted highest to lowest.
    /// @param root The root of the merkle tree
    /// @param depth Depth of the merkle tree. Equal to log2(number of leafs)
    /// @param indices The indices of the leafs, index starting whith 0
    /// @param leaves The leaves which need to be proven
    /// @param decommitments A list of decommitments required to reconstruct the merkle root
    /// @return A boolean value representing the success or failure of the verification
    function multiVerify(
        bytes32 root,
        uint256 depth,
        bytes32 indices,
        bytes32[] memory leaves,
        bytes32[] memory decommitments
    )
        internal
        pure
        returns (bool)
    {
        require(depth <= 8, "DEPTH_TOO_LARGE");
        uint256 n = leaves.length;
        uint256 n1 = n + 1;

        // Dynamically allocate index and hash queue
        uint256[] memory tree_indices = new uint256[](n1);
        bytes32[] memory hashes = new bytes32[](n1);
        uint256 head = 0;
        uint256 tail = 0;
        uint256 di = 0;

        // Queue the leafs
        uint256 offset = 1 << depth;
        for(; tail < n; ++tail) {
            tree_indices[tail] = offset + uint8(indices[tail]);
            hashes[tail] = leaves[tail];
        }

        // Itterate the queue until we hit the root
        while (true) {
            uint256 index = tree_indices[head];
            bytes32 hash = hashes[head];
            head = (head + 1) % n1;

            // Merkle root
            if (index == 1) {
                return hash == root;
            // Even node, take sibbling from decommitments
            } else if (index & 1 == 0) {
                hash = hash_node(hash, decommitments[di++]);
            // Odd node with sibbling in the queue
            } else if (head != tail && tree_indices[head] == index - 1) {
                hash = hash_node(hashes[head], hash);
                head = (head + 1) % n1;
            // Odd node with sibbling from decommitments
            } else {
                hash = hash_node(decommitments[di++], hash);
            }
            tree_indices[tail] = index >> 1;
            hashes[tail] = hash;
            tail = (tail + 1) % n1;
        }

        // resolve warning
        return false;
    }
}

////// src/truth/common/BEEFYMessageVerifier.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../../spec/MessageProof.sol"; */
/* import "../../interfaces/IVerifier.sol"; */
/* import "../../utils/SparseMerkleProof.sol"; */

abstract contract BEEFYMessageVerifier is IVerifier {

    function message_root() public view virtual returns (bytes32);

    function verify_messages_proof(
        bytes32 outlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external override view returns (bool) {
        return validate_lane_data_match_root(outlane_data_hash, chain_pos, lane_pos, encoded_proof);
    }

    function verify_messages_delivery_proof(
        bytes32 inlane_data_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata encoded_proof
    ) external override view returns (bool) {
        return validate_lane_data_match_root(inlane_data_hash, chain_pos, lane_pos, encoded_proof);
    }

    function validate_lane_data_match_root(
        bytes32 lane_hash,
        uint32 chain_pos,
        uint32 lane_pos,
        bytes calldata proof
    ) internal view returns (bool) {
        MessageProof memory messages_proof = abi.decode(proof, (MessageProof));
        // Validate that the commitment matches the commitment contents
        require(messages_proof.chainProof.root == message_root(), "!message_root");
        return validateLaneDataMatchRoot(
                lane_hash,
                chain_pos,
                lane_pos,
                messages_proof.chainProof,
                messages_proof.laneProof
            );
    }

    function validateLaneDataMatchRoot(
        bytes32 laneHash,
        uint256 chainPosition,
        uint256 lanePosition,
        MessageSingleProof memory chainProof,
        MessageSingleProof memory laneProof
    ) internal pure returns (bool) {
        return
            SparseMerkleProof.singleVerify(
                laneProof.root,
                laneHash,
                lanePosition,
                laneProof.proof
            )
            &&
            SparseMerkleProof.singleVerify(
                chainProof.root,
                laneProof.root,
                chainPosition,
                chainProof.proof
            );
    }
}

////// src/truth/darwinia/DarwiniaMessageVerifier.sol
// This file is part of Darwinia.
// Copyright (C) 2018-2022 Darwinia Network
//
// Darwinia is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Darwinia is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Darwinia. If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity 0.7.6; */
/* pragma abicoder v2; */

/* import "../common/BEEFYMessageVerifier.sol"; */
/* import "../../interfaces/ILightClient.sol"; */

contract DarwiniaMessageVerifier is BEEFYMessageVerifier {
    ILightClient public immutable LIGHT_CLIENT;

    constructor(address lightclient) {
        LIGHT_CLIENT = ILightClient(lightclient);
    }

    function message_root() public view override returns (bytes32) {
        return LIGHT_CLIENT.merkle_root();
    }
}