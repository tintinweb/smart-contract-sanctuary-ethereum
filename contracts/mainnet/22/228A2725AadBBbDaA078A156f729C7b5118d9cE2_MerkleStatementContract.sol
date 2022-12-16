/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "IQueryableFactRegistry.sol";

contract FactRegistry is IQueryableFactRegistry {
    // Mapping: fact hash -> true.
    mapping(bytes32 => bool) private verifiedFact;

    // Indicates whether the Fact Registry has at least one fact registered.
    bool anyFactRegistered = false;

    /*
      Checks if a fact has been verified.
    */
    function isValid(bytes32 fact) external view override returns (bool) {
        return _factCheck(fact);
    }

    /*
      This is an internal method to check if the fact is already registered.
      In current implementation of FactRegistry it's identical to isValid().
      But the check is against the local fact registry,
      So for a derived referral fact registry, it's not the same.
    */
    function _factCheck(bytes32 fact) internal view returns (bool) {
        return verifiedFact[fact];
    }

    function registerFact(bytes32 factHash) internal {
        // This function stores the fact hash in the mapping.
        verifiedFact[factHash] = true;

        // Mark first time off.
        if (!anyFactRegistered) {
            anyFactRegistered = true;
        }
    }

    /*
      Indicates whether at least one fact was registered.
    */
    function hasRegisteredFact() external view override returns (bool) {
        return anyFactRegistered;
    }
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

/*
  The Fact Registry design pattern is a way to separate cryptographic verification from the
  business logic of the contract flow.

  A fact registry holds a hash table of verified "facts" which are represented by a hash of claims
  that the registry hash check and found valid. This table may be queried by accessing the
  isValid() function of the registry with a given hash.

  In addition, each fact registry exposes a registry specific function for submitting new claims
  together with their proofs. The information submitted varies from one registry to the other
  depending of the type of fact requiring verification.

  For further reading on the Fact Registry design pattern see this
  `StarkWare blog post <https://medium.com/starkware/the-fact-registry-a64aafb598b6>`_.
*/
interface IFactRegistry {
    /*
      Returns true if the given fact was previously registered in the contract.
    */
    function isValid(bytes32 fact) external view returns (bool);
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

abstract contract IMerkleVerifier {
    uint256 internal constant MAX_N_MERKLE_VERIFIER_QUERIES = 128;

    // The size of a SLOT in the verifyMerkle queue.
    // Every slot holds a (index, hash) pair.
    uint256 internal constant MERKLE_SLOT_SIZE_IN_BYTES = 0x40;

    function verifyMerkle(
        uint256 channelPtr,
        uint256 queuePtr,
        bytes32 root,
        uint256 n
    ) internal view virtual returns (bytes32 hash);
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "IFactRegistry.sol";

/*
  Extends the IFactRegistry interface with a query method that indicates
  whether the fact registry has successfully registered any fact or is still empty of such facts.
*/
interface IQueryableFactRegistry is IFactRegistry {
    /*
      Returns true if at least one fact has been registered.
    */
    function hasRegisteredFact() external view returns (bool);
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "FactRegistry.sol";
import "MerkleVerifier.sol";

contract MerkleStatementContract is MerkleVerifier, FactRegistry {
    /*
      This function receives an initial Merkle queue (consists of indices of leaves in the Merkle
      in addition to their values) and a Merkle view (contains the values of all the nodes
      required to be able to validate the queue). In case of success it registers the Merkle fact,
      which is the hash of the queue together with the resulting root.
    */
    // NOLINTNEXTLINE: external-function.
    function verifyMerkle(
        uint256[] memory merkleView,
        uint256[] memory initialMerkleQueue,
        uint256 height,
        uint256 expectedRoot
    ) public {
        // Ensure 'height' is bounded from above as a sanity check
        // (the bound is somewhat arbitrary).
        require(height < 200, "Height must be < 200.");
        require(
            initialMerkleQueue.length <= MAX_N_MERKLE_VERIFIER_QUERIES * 2,
            "TOO_MANY_MERKLE_QUERIES"
        );
        require(initialMerkleQueue.length % 2 == 0, "ODD_MERKLE_QUEUE_SIZE");

        uint256 merkleQueuePtr;
        uint256 channelPtr;
        uint256 nQueries;
        uint256 dataToHashPtr;
        uint256 badInput = 0;

        assembly {
            // Skip 0x20 bytes length at the beginning of the merkleView.
            let merkleViewPtr := add(merkleView, 0x20)
            // Let channelPtr point to a free space.
            channelPtr := mload(0x40) // freePtr.
            // channelPtr will point to the merkleViewPtr since the 'verify' function expects
            // a pointer to the proofPtr.
            mstore(channelPtr, merkleViewPtr)
            // Skip 0x20 bytes length at the beginning of the initialMerkleQueue.
            merkleQueuePtr := add(initialMerkleQueue, 0x20)
            // Get number of queries.
            nQueries := div(mload(initialMerkleQueue), 0x2) //NOLINT: divide-before-multiply.
            // Get a pointer to the end of initialMerkleQueue.
            let initialMerkleQueueEndPtr := add(
                merkleQueuePtr,
                mul(nQueries, MERKLE_SLOT_SIZE_IN_BYTES)
            )
            // Let dataToHashPtr point to a free memory.
            dataToHashPtr := add(channelPtr, 0x20) // Next freePtr.

            // Copy initialMerkleQueue to dataToHashPtr and validaite the indices.
            // The indices need to be in the range [2**height..2*(height+1)-1] and
            // strictly incrementing.

            // First index needs to be >= 2**height.
            let idxLowerLimit := shl(height, 1)
            for {

            } lt(merkleQueuePtr, initialMerkleQueueEndPtr) {

            } {
                let curIdx := mload(merkleQueuePtr)
                // badInput |= curIdx < IdxLowerLimit.
                badInput := or(badInput, lt(curIdx, idxLowerLimit))

                // The next idx must be at least curIdx + 1.
                idxLowerLimit := add(curIdx, 1)

                // Copy the pair (idx, hash) to the dataToHash array.
                mstore(dataToHashPtr, curIdx)
                mstore(add(dataToHashPtr, 0x20), mload(add(merkleQueuePtr, 0x20)))

                dataToHashPtr := add(dataToHashPtr, 0x40)
                merkleQueuePtr := add(merkleQueuePtr, MERKLE_SLOT_SIZE_IN_BYTES)
            }

            // We need to enforce that lastIdx < 2**(height+1)
            // => fail if lastIdx >= 2**(height+1)
            // => fail if (lastIdx + 1) > 2**(height+1)
            // => fail if idxLowerLimit > 2**(height+1).
            badInput := or(badInput, gt(idxLowerLimit, shl(height, 2)))

            // Reset merkleQueuePtr.
            merkleQueuePtr := add(initialMerkleQueue, 0x20)
            // Let freePtr point to a free memory (one word after the copied queries - reserved
            // for the root).
            mstore(0x40, add(dataToHashPtr, 0x20))
        }
        require(badInput == 0, "INVALID_MERKLE_INDICES");
        bytes32 resRoot = verifyMerkle(channelPtr, merkleQueuePtr, bytes32(expectedRoot), nQueries);
        bytes32 factHash;
        assembly {
            // Append the resulted root (should be the return value of verify) to dataToHashPtr.
            mstore(dataToHashPtr, resRoot)
            // Reset dataToHashPtr.
            dataToHashPtr := add(channelPtr, 0x20)
            factHash := keccak256(dataToHashPtr, add(mul(nQueries, 0x40), 0x20))
        }

        registerFact(factHash);
    }
}

/*
  Copyright 2019-2022 StarkWare Industries Ltd.

  Licensed under the Apache License, Version 2.0 (the "License").
  You may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  https://www.starkware.co/open-source-license/

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions
  and limitations under the License.
*/
// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.6.12;

import "IMerkleVerifier.sol";

contract MerkleVerifier is IMerkleVerifier {
    // Commitments are masked to 160bit using the following mask to save gas costs.
    uint256 internal constant COMMITMENT_MASK = (
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000
    );

    // The size of a commitment. We use 32 bytes (rather than 20 bytes) per commitment as it
    // simplifies the code.
    uint256 internal constant COMMITMENT_SIZE_IN_BYTES = 0x20;

    // The size of two commitments.
    uint256 internal constant TWO_COMMITMENTS_SIZE_IN_BYTES = 0x40;

    // The size of and index in the verifyMerkle queue.
    uint256 internal constant INDEX_SIZE_IN_BYTES = 0x20;

    /*
      Verifies a Merkle tree decommitment for n leaves in a Merkle tree with N leaves.

      The inputs data sits in the queue at queuePtr.
      Each slot in the queue contains a 32 bytes leaf index and a 32 byte leaf value.
      The indices need to be in the range [N..2*N-1] and strictly incrementing.
      Decommitments are read from the channel in the ctx.

      The input data is destroyed during verification.
    */
    function verifyMerkle(
        uint256 channelPtr,
        uint256 queuePtr,
        bytes32 root,
        uint256 n
    ) internal view virtual override returns (bytes32 hash) {
        require(n <= MAX_N_MERKLE_VERIFIER_QUERIES, "TOO_MANY_MERKLE_QUERIES");

        assembly {
            // queuePtr + i * MERKLE_SLOT_SIZE_IN_BYTES gives the i'th index in the queue.
            // hashesPtr + i * MERKLE_SLOT_SIZE_IN_BYTES gives the i'th hash in the queue.
            let hashesPtr := add(queuePtr, INDEX_SIZE_IN_BYTES)
            let queueSize := mul(n, MERKLE_SLOT_SIZE_IN_BYTES)

            // The items are in slots [0, n-1].
            let rdIdx := 0
            let wrIdx := 0 // = n % n.

            // Iterate the queue until we hit the root.
            let index := mload(add(rdIdx, queuePtr))
            let proofPtr := mload(channelPtr)

            // while(index > 1).
            for {

            } gt(index, 1) {

            } {
                let siblingIndex := xor(index, 1)
                // sibblingOffset := COMMITMENT_SIZE_IN_BYTES * lsb(siblingIndex).
                let sibblingOffset := mulmod(
                    siblingIndex,
                    COMMITMENT_SIZE_IN_BYTES,
                    TWO_COMMITMENTS_SIZE_IN_BYTES
                )

                // Store the hash corresponding to index in the correct slot.
                // 0 if index is even and 0x20 if index is odd.
                // The hash of the sibling will be written to the other slot.
                mstore(xor(0x20, sibblingOffset), mload(add(rdIdx, hashesPtr)))
                rdIdx := addmod(rdIdx, MERKLE_SLOT_SIZE_IN_BYTES, queueSize)

                // Inline channel operation:
                // Assume we are going to read a new hash from the proof.
                // If this is not the case add(proofPtr, COMMITMENT_SIZE_IN_BYTES) will be reverted.
                let newHashPtr := proofPtr
                proofPtr := add(proofPtr, COMMITMENT_SIZE_IN_BYTES)

                // Push index/2 into the queue, before reading the next index.
                // The order is important, as otherwise we may try to read from an empty queue (in
                // the case where we are working on one item).
                // wrIdx will be updated after writing the relevant hash to the queue.
                mstore(add(wrIdx, queuePtr), div(index, 2))

                // Load the next index from the queue and check if it is our sibling.
                index := mload(add(rdIdx, queuePtr))
                if eq(index, siblingIndex) {
                    // Take sibling from queue rather than from proof.
                    newHashPtr := add(rdIdx, hashesPtr)
                    // Revert reading from proof.
                    proofPtr := sub(proofPtr, COMMITMENT_SIZE_IN_BYTES)
                    rdIdx := addmod(rdIdx, MERKLE_SLOT_SIZE_IN_BYTES, queueSize)

                    // Index was consumed, read the next one.
                    // Note that the queue can't be empty at this point.
                    // The index of the parent of the current node was already pushed into the
                    // queue, and the parent is never the sibling.
                    index := mload(add(rdIdx, queuePtr))
                }

                mstore(sibblingOffset, mload(newHashPtr))

                // Push the new hash to the end of the queue.
                mstore(
                    add(wrIdx, hashesPtr),
                    and(COMMITMENT_MASK, keccak256(0x00, TWO_COMMITMENTS_SIZE_IN_BYTES))
                )
                wrIdx := addmod(wrIdx, MERKLE_SLOT_SIZE_IN_BYTES, queueSize)
            }
            hash := mload(add(rdIdx, hashesPtr))

            // Update the proof pointer in the context.
            mstore(channelPtr, proofPtr)
        }
        require(hash == root, "INVALID_MERKLE_PROOF");
    }
}