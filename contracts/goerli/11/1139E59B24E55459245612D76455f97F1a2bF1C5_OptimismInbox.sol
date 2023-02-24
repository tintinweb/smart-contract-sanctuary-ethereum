// SPDX-License-Identifier: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity >=0.5.10 <0.8.17;

library RLPReader {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;
    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    struct Iterator {
        RLPItem item; // Item that's being iterated over.
        uint256 nextPtr; // Position of the next item in the list.
    }

    /*
     * @dev Returns the next element in the iteration. Reverts if it has not next element.
     * @param self The iterator.
     * @return The next element in the iteration.
     */
    function next(Iterator memory self) internal pure returns (RLPItem memory) {
        require(hasNext(self));

        uint256 ptr = self.nextPtr;
        uint256 itemLength = _itemLength(ptr);
        self.nextPtr = ptr + itemLength;

        return RLPItem(itemLength, ptr);
    }

    /*
     * @dev Returns true if the iteration has more elements.
     * @param self The iterator.
     * @return true if the iteration has more elements.
     */
    function hasNext(Iterator memory self) internal pure returns (bool) {
        RLPItem memory item = self.item;
        return self.nextPtr < item.memPtr + item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRlpItem(bytes memory item) internal pure returns (RLPItem memory) {
        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @dev Create an iterator. Reverts if item is not a list.
     * @param self The RLP item.
     * @return An 'Iterator' over the item.
     */
    function iterator(RLPItem memory self) internal pure returns (Iterator memory) {
        require(isList(self));

        uint256 ptr = self.memPtr + _payloadOffset(self.memPtr);
        return Iterator(self, ptr);
    }

    /*
     * @param the RLP item.
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param the RLP item.
     * @return (memPtr, len) pair: location of the item's payload in memory.
     */
    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
    }

    /*
     * @param the RLP item.
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        (, uint256 len) = payloadLocation(item);
        return len;
    }

    /*
     * @param the RLP item containing the encoded list.
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory) {
        require(isList(item));

        uint256 items = numItems(item);
        RLPItem[] memory result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }

        return result;
    }

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        if (item.len == 0) return false;

        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    /*
     * @dev A cheaper version of keccak256(toRlpBytes(item)) that avoids copying memory.
     * @return keccak256 hash of RLP encoded bytes.
     */
    function rlpBytesKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        uint256 ptr = item.memPtr;
        uint256 len = item.len;
        bytes32 result;
        assembly {
            result := keccak256(ptr, len)
        }
        return result;
    }

    /*
     * @dev A cheaper version of keccak256(toBytes(item)) that avoids copying memory.
     * @return keccak256 hash of the item payload.
     */
    function payloadKeccak256(RLPItem memory item) internal pure returns (bytes32) {
        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes32 result;
        assembly {
            result := keccak256(memPtr, len)
        }
        return result;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRlpBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);
        if (result.length == 0) return result;

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    // any non-zero byte except "0x80" is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        // SEE Github Issue #5.
        // Summary: Most commonly used RLP libraries (i.e Geth) will encode
        // "0" as "0x80" instead of as "0". We handle this edge case explicitly
        // here.
        if (result == 0 || result == STRING_SHORT_START) {
            return false;
        } else {
            return true;
        }
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        (uint256 memPtr, uint256 len) = payloadLocation(item);

        uint256 result;
        assembly {
            result := mload(memPtr)

            // shift to the correct location if neccesary
            if lt(len, 32) {
                result := div(result, exp(256, sub(32, len)))
            }
        }

        return result;
    }

    // enforces 32 byte length
    function toUintStrict(RLPItem memory item) internal pure returns (uint256) {
        // one byte prefix
        require(item.len == 33);

        uint256 result;
        uint256 memPtr = item.memPtr + 1;
        assembly {
            result := mload(memPtr)
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        require(item.len > 0);

        (uint256 memPtr, uint256 len) = payloadLocation(item);
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(memPtr, destPtr, len);
        return result;
    }

    /*
     * Private Helpers
     */

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) private pure returns (uint256) {
        if (item.len == 0) return 0;

        uint256 count = 0;
        uint256 currPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 endPtr = item.memPtr + item.len;
        while (currPtr < endPtr) {
            currPtr = currPtr + _itemLength(currPtr); // skip over an item
            count++;
        }

        return count;
    }

    // @return entire rlp item byte length
    function _itemLength(uint256 memPtr) private pure returns (uint256) {
        uint256 itemLen;
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            itemLen = 1;
        } else if (byte0 < STRING_LONG_START) {
            itemLen = byte0 - STRING_SHORT_START + 1;
        } else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                itemLen := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            itemLen = byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                itemLen := add(dataLen, add(byteLen, 1))
            }
        }

        return itemLen;
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) private pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) {
            return 0;
        } else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) {
            return 1;
        } else if (byte0 < LIST_SHORT_START) {
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        } else {
            return byte0 - (LIST_LONG_START - 1) + 1;
        }
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(uint256 src, uint256 dest, uint256 len) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len > 0) {
            // left over bytes. Mask is used to remove unwanted bytes from the word
            uint256 mask = 256**(WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Interface for input of L1 state root to the L2 state prover
/// @author Perseverance - LimeChain
interface ILightClient {
    /// @notice Should return the state root of L1 by its block number
    /// @param blockNumber The block number of the L1 block that the state root is requested
    /// @return The state root for the given block number
    function executionStateRoot(uint64 blockNumber)
        external
        view
        returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {OptimismBedrockStateProver} from "./../../library/optimism/OptimismBedrockStateProver.sol";
import {Types} from "./../../library/optimism/Types.sol";
import {ILightClient} from "./../ILightClient.sol";

/// @notice Contract for verification of MPT inclusion inside Optimism Bedrock from within external other network
/// @author Perseverance - LimeChain
/// @dev Depends on an external contract - ILightClient - that is used for input of the bedrock anchored L1 state roots
/// @dev The verification happens in two stages.
/// @dev Stage 1 is verification that the output root exists inside the Optimism Bedrock Output Oracle via MPT Proof
/// @dev Stage 2 uses the state root inside the output root and performs MPT inclusion proving for data inside
contract L2OptimismBedrockStateProver is OptimismBedrockStateProver {
    ILightClient public immutable lightClient;

    address public immutable berdockOutputOracleAddress;

    uint256 public constant outputOracleOutputProofsSlotPosition = 3;

    constructor(address _lightClient, address _oracleAddress) {
        lightClient = ILightClient(_lightClient);
        berdockOutputOracleAddress = _oracleAddress;
    }

    /// @notice Internal method to verify that the output root corresponding to the output proof exists inside the Optimism Bedrock Output Oracle for the given index
    /// @param blockNumber The block number to request the L1 state root for
    /// @param outputIndex The index to find the output proof at inside the Bedrock OutputOracle
    /// @param outputProof The MPT proof data to verify that the given output root is contained inside the OutputOracle for the expected index
    /// @return isValid if the output root is indeed there
    function proveOutputRoot(
        uint64 blockNumber,
        uint256 outputIndex,
        Types.OutputRootMPTProof calldata outputProof
    ) internal view returns (bool isValid) {
        bytes32 l1StateRoot = lightClient.executionStateRoot(blockNumber);

        // See https://github.com/ethereum-optimism/optimism/blob/develop/specs/proposals.md#l2-output-commitment-construction
        bytes32 calculatedOutputRoot = keccak256(
            abi.encode(
                versionByte,
                outputProof.outputRootProof.stateRoot,
                outputProof.outputRootProof.withdrawalStorageRoot,
                outputProof.outputRootProof.latestBlockhash
            )
        );

        // The data structure that bedrock saves in the array is 2 slots long thus finding the slot with the output proof requires (2 * index)
        uint256 targetSlot = uint256(
            keccak256(abi.encode(outputOracleOutputProofsSlotPosition))
        ) + (2 * outputIndex);

        return
            this.verifyStateProof(
                l1StateRoot,
                berdockOutputOracleAddress,
                bytes32(targetSlot),
                uint256(calculatedOutputRoot),
                outputProof.optimismStateProofsBlob
            );
    }

    /// @notice Verifies that a certain expected value is located at the specified storage slot at the specified target account inside Optimism Bedrock
    /// @dev Performs both stages of verification.
    /// @param blockNumber The block number to request the L1 state root for
    /// @param outputIndex The index to find the output proof at inside the Bedrock OutputOracle
    /// @param outputProof The MPT proof data to verify that the given output root is contained inside the OutputOracle for the expected index
    /// @param inclusionProof The MPT Inclusion proof to verify the expected value is found in the specified storage slot for the specified account inside Optimism
    /// @param expectedValue The expected value to be in the storage slot
    /// @return isValid if the expected value is indeed there
    function proveInOptimismState(
        uint64 blockNumber,
        uint256 outputIndex,
        Types.OutputRootMPTProof calldata outputProof,
        Types.MPTInclusionProof calldata inclusionProof,
        uint256 expectedValue
    ) public view returns (bool isValid) {
        require(
            proveOutputRoot(blockNumber, outputIndex, outputProof),
            "Optimism root state was not found in L1"
        );
        return
            _proveInOptimismState(
                outputProof.outputRootProof.stateRoot,
                inclusionProof.target,
                inclusionProof.slotPosition,
                expectedValue,
                inclusionProof.proofsBlob
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {StateProofVerifier as Verifier} from "./StateProofVerifier.sol";
import {RLPReader} from "Solidity-RLP/RLPReader.sol";

/// @notice Combined Account and Storage Proofs Verifier
/// @author Perseverance - LimeChain
/// @author Inspired from https://github.com/lidofinance/curve-merkle-oracle
contract CombinedProofVerifier {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    /// @dev verifies proof for a specific target based on the state root
    /// @param stateRoot is the state root we are proving against
    /// @param target is the account we are proving for
    /// @param slotPosition is the slot position that we will be getting the value for
    /// @param value is the value we are trying to prove is in the slot
    /// @param proofsBlob is ann rlp encoded array of the account proof and the storage proof. Each of these is the rlp encoded nibbles that is the corresponding proof. This is normally returned by eth_getProof.
    function verifyStateProof(
        bytes32 stateRoot,
        address target,
        bytes32 slotPosition,
        uint256 value,
        bytes calldata proofsBlob
    ) public pure returns (bool) {
        RLPReader.RLPItem[] memory proofs = proofsBlob.toRlpItem().toList();
        require(proofs.length == 2, "total proofs");

        Verifier.Account memory account = Verifier.extractAccountFromProof(
            keccak256(abi.encodePacked(target)),
            stateRoot,
            proofs[0].toList()
        );

        require(account.exists, "Account does not exist or proof is incorrect");

        Verifier.SlotValue memory storageValue = Verifier
            .extractSlotValueFromProof(
                keccak256(abi.encodePacked(slotPosition)),
                account.storageRoot,
                proofs[1].toList()
            );

        require(storageValue.exists, "Storage Value not found");

        require(
            storageValue.value == value,
            "Incorrect value found on this position"
        );

        return true;
    }
}

// SPDX-License-Identifier: MIT

/// @notice Verifier for Ethereum MPT Proofs
/// @author Perseverance - LimeChain
/// @author Copied from https://github.com/lidofinance/curve-merkle-oracle
pragma solidity ^0.8.13;

import {RLPReader} from "Solidity-RLP/RLPReader.sol";

library MerklePatriciaProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    /// @dev Validates a Merkle-Patricia-Trie proof.
    ///      If the proof proves the inclusion of some key-value pair in the
    ///      trie, the value is returned. Otherwise, i.e. if the proof proves
    ///      the exclusion of a key from the trie, an empty byte array is
    ///      returned.
    /// @param rootHash is the Keccak-256 hash of the root node of the MPT.
    /// @param path is the key of the node whose inclusion/exclusion we are
    ///        proving.
    /// @param stack is the stack of MPT nodes (starting with the root) that
    ///        need to be traversed during verification.
    /// @return value whose inclusion is proved or an empty byte array for
    ///         a proof of exclusion
    function extractProofValue(
        bytes32 rootHash,
        bytes memory path,
        RLPReader.RLPItem[] memory stack
    ) internal pure returns (bytes memory value) {
        bytes memory mptKey = _decodeNibbles(path, 0);
        uint256 mptKeyOffset = 0;

        bytes32 nodeHashHash;
        RLPReader.RLPItem[] memory node;

        RLPReader.RLPItem memory rlpValue;

        if (stack.length == 0) {
            // Root hash of empty Merkle-Patricia-Trie
            require(
                rootHash ==
                    0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421
            );
            return new bytes(0);
        }

        // Traverse stack of nodes starting at root.
        for (uint256 i = 0; i < stack.length; i++) {
            // We use the fact that an rlp encoded list consists of some
            // encoding of its length plus the concatenation of its
            // *rlp-encoded* items.

            // The root node is hashed with Keccak-256 ...
            if (i == 0 && rootHash != stack[i].rlpBytesKeccak256()) {
                revert();
            }
            // ... whereas all other nodes are hashed with the MPT
            // hash function.
            if (i != 0 && nodeHashHash != _mptHashHash(stack[i])) {
                revert();
            }
            // We verified that stack[i] has the correct hash, so we
            // may safely decode it.
            node = stack[i].toList();

            if (node.length == 2) {
                // Extension or Leaf node

                bool isLeaf;
                bytes memory nodeKey;
                (isLeaf, nodeKey) = _merklePatriciaCompactDecode(
                    node[0].toBytes()
                );

                uint256 prefixLength = _sharedPrefixLength(
                    mptKeyOffset,
                    mptKey,
                    nodeKey
                );
                mptKeyOffset += prefixLength;

                if (prefixLength < nodeKey.length) {
                    // Proof claims divergent extension or leaf. (Only
                    // relevant for proofs of exclusion.)
                    // An Extension/Leaf node is divergent iff it "skips" over
                    // the point at which a Branch node should have been had the
                    // excluded key been included in the trie.
                    // Example: Imagine a proof of exclusion for path [1, 4],
                    // where the current node is a Leaf node with
                    // path [1, 3, 3, 7]. For [1, 4] to be included, there
                    // should have been a Branch node at [1] with a child
                    // at 3 and a child at 4.

                    // Sanity check
                    if (i < stack.length - 1) {
                        // divergent node must come last in proof
                        revert();
                    }

                    return new bytes(0);
                }

                if (isLeaf) {
                    // Sanity check
                    if (i < stack.length - 1) {
                        // leaf node must come last in proof
                        revert();
                    }

                    if (mptKeyOffset < mptKey.length) {
                        return new bytes(0);
                    }

                    rlpValue = node[1];
                    return rlpValue.toBytes();
                } else {
                    // extension
                    // Sanity check
                    if (i == stack.length - 1) {
                        // shouldn't be at last level
                        revert();
                    }

                    if (!node[1].isList()) {
                        // rlp(child) was at least 32 bytes. node[1] contains
                        // Keccak256(rlp(child)).
                        nodeHashHash = node[1].payloadKeccak256();
                    } else {
                        // rlp(child) was less than 32 bytes. node[1] contains
                        // rlp(child).
                        nodeHashHash = node[1].rlpBytesKeccak256();
                    }
                }
            } else if (node.length == 17) {
                // Branch node

                if (mptKeyOffset != mptKey.length) {
                    // we haven't consumed the entire path, so we need to look at a child
                    uint8 nibble = uint8(mptKey[mptKeyOffset]);
                    mptKeyOffset += 1;
                    if (nibble >= 16) {
                        // each element of the path has to be a nibble
                        revert();
                    }

                    if (_isEmptyBytesequence(node[nibble])) {
                        // Sanity
                        if (i != stack.length - 1) {
                            // leaf node should be at last level
                            revert();
                        }

                        return new bytes(0);
                    } else if (!node[nibble].isList()) {
                        nodeHashHash = node[nibble].payloadKeccak256();
                    } else {
                        nodeHashHash = node[nibble].rlpBytesKeccak256();
                    }
                } else {
                    // we have consumed the entire mptKey, so we need to look at what's contained in this node.

                    // Sanity
                    if (i != stack.length - 1) {
                        // should be at last level
                        revert();
                    }

                    return node[16].toBytes();
                }
            }
        }
    }

    /// @dev Computes the hash of the Merkle-Patricia-Trie hash of the RLP item.
    ///      Merkle-Patricia-Tries use a weird "hash function" that outputs
    ///      *variable-length* hashes: If the item is shorter than 32 bytes,
    ///      the MPT hash is the item. Otherwise, the MPT hash is the
    ///      Keccak-256 hash of the item.
    ///      The easiest way to compare variable-length byte sequences is
    ///      to compare their Keccak-256 hashes.
    /// @param item The RLP item to be hashed.
    /// @return Keccak-256(MPT-hash(item))
    function _mptHashHash(RLPReader.RLPItem memory item)
        private
        pure
        returns (bytes32)
    {
        if (item.len < 32) {
            return item.rlpBytesKeccak256();
        } else {
            return keccak256(abi.encodePacked(item.rlpBytesKeccak256()));
        }
    }

    function _isEmptyBytesequence(RLPReader.RLPItem memory item)
        private
        pure
        returns (bool)
    {
        if (item.len != 1) {
            return false;
        }
        uint8 b;
        uint256 memPtr = item.memPtr;
        assembly {
            b := byte(0, mload(memPtr))
        }
        return b == 0x80; /* empty byte string */
    }

    function _merklePatriciaCompactDecode(bytes memory compact)
        private
        pure
        returns (bool isLeaf, bytes memory nibbles)
    {
        require(compact.length > 0);
        uint256 first_nibble = (uint8(compact[0]) >> 4) & 0xF;
        uint256 skipNibbles;
        if (first_nibble == 0) {
            skipNibbles = 2;
            isLeaf = false;
        } else if (first_nibble == 1) {
            skipNibbles = 1;
            isLeaf = false;
        } else if (first_nibble == 2) {
            skipNibbles = 2;
            isLeaf = true;
        } else if (first_nibble == 3) {
            skipNibbles = 1;
            isLeaf = true;
        } else {
            // Not supposed to happen!
            revert();
        }
        return (isLeaf, _decodeNibbles(compact, skipNibbles));
    }

    function _decodeNibbles(bytes memory compact, uint256 skipNibbles)
        private
        pure
        returns (bytes memory nibbles)
    {
        require(compact.length > 0);

        uint256 length = compact.length * 2;
        require(skipNibbles <= length);
        length -= skipNibbles;

        nibbles = new bytes(length);
        uint256 nibblesLength = 0;

        for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
            if (i % 2 == 0) {
                nibbles[nibblesLength] = bytes1(
                    (uint8(compact[i / 2]) >> 4) & 0xF
                );
            } else {
                nibbles[nibblesLength] = bytes1(
                    (uint8(compact[i / 2]) >> 0) & 0xF
                );
            }
            nibblesLength += 1;
        }

        assert(nibblesLength == nibbles.length);
    }

    function _sharedPrefixLength(
        uint256 xsOffset,
        bytes memory xs,
        bytes memory ys
    ) private pure returns (uint256) {
        uint256 i;
        for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
            if (xs[i + xsOffset] != ys[i]) {
                return i;
            }
        }
        return i;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import {RLPReader} from "Solidity-RLP/RLPReader.sol";
import {MerklePatriciaProofVerifier} from "./MerklePatriciaProofVerifier.sol";

/// @notice A helper library for verification of Merkle Patricia account and state proofs.
/// @author Perseverance - LimeChain
/// @author Copied from https://github.com/lidofinance/curve-merkle-oracle
library StateProofVerifier {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    uint256 constant HEADER_STATE_ROOT_INDEX = 3;
    uint256 constant HEADER_NUMBER_INDEX = 8;
    uint256 constant HEADER_TIMESTAMP_INDEX = 11;

    struct Account {
        bool exists;
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct SlotValue {
        bool exists;
        uint256 value;
    }

    /**
     * @notice Verifies Merkle Patricia proof of an account and extracts the account fields.
     *
     * @param _addressHash Keccak256 hash of the address corresponding to the account.
     * @param _stateRootHash MPT root hash of the Ethereum state trie.
     */
    function extractAccountFromProof(
        bytes32 _addressHash, // keccak256(abi.encodePacked(address))
        bytes32 _stateRootHash,
        RLPReader.RLPItem[] memory _proof
    ) internal pure returns (Account memory) {
        bytes memory acctRlpBytes = MerklePatriciaProofVerifier
            .extractProofValue(
                _stateRootHash,
                abi.encodePacked(_addressHash),
                _proof
            );

        Account memory account;

        if (acctRlpBytes.length == 0) {
            return account;
        }

        RLPReader.RLPItem[] memory acctFields = acctRlpBytes
            .toRlpItem()
            .toList();
        require(acctFields.length == 4);

        account.exists = true;
        account.nonce = acctFields[0].toUint();
        account.balance = acctFields[1].toUint();
        account.storageRoot = bytes32(acctFields[2].toUint());
        account.codeHash = bytes32(acctFields[3].toUint());

        return account;
    }

    /**
     * @notice Verifies Merkle Patricia proof of a slot and extracts the slot's value.
     *
     * @param _slotHash Keccak256 hash of the slot position.
     * @param _storageRootHash MPT root hash of the account's storage trie.
     */
    function extractSlotValueFromProof(
        bytes32 _slotHash,
        bytes32 _storageRootHash,
        RLPReader.RLPItem[] memory _proof
    ) internal pure returns (SlotValue memory) {
        bytes memory valueRlpBytes = MerklePatriciaProofVerifier
            .extractProofValue(
                _storageRootHash,
                abi.encodePacked(_slotHash),
                _proof
            );

        SlotValue memory value;

        if (valueRlpBytes.length != 0) {
            value.exists = true;
            value.value = valueRlpBytes.toRlpItem().toUint();
        }

        return value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CombinedProofVerifier} from "./../../MPT/CombinedProofVerifier.sol";

/// @notice Common functionality for the L1 and L2 Optimism Bedrock State Verifiers
/// @author Perseverance - LimeChain
abstract contract OptimismBedrockStateProver is CombinedProofVerifier {
    /// @dev Current Optimism Bedrock Output Root version_byte.
    /// @dev See https://github.com/ethereum-optimism/optimism/blob/develop/specs/proposals.md#l2-output-commitment-construction
    bytes32 public constant versionByte = bytes32(0);

    /// @dev See CombinedProofVerifier.verifyStateProof
    function _proveInOptimismState(
        bytes32 optimismStateRoot,
        address target,
        bytes32 slotPosition,
        uint256 value,
        bytes calldata proofsBlob
    ) internal view returns (bool) {
        return
            this.verifyStateProof(
                optimismStateRoot,
                target,
                slotPosition,
                value,
                proofsBlob
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Contains various types used throughout the Optimism verification process.
/// @author Perseverance - LimeChain
/// @author Inspired by the Types of Optimism Bedrock https://github.com/ethereum-optimism/optimism/tree/develop/packages/contracts-bedrock/contracts
library Types {
    /// @notice OutputProposal represents a commitment to the L2 state. The timestamp is the L1
    ///        timestamp that the output root is posted. This timestamp is used to verify that the
    ///        finalization period has passed since the output root was submitted.
    ///
    /// outputRoot    Hash of the L2 output.
    /// timestamp     Timestamp of the L1 block that the output root was submitted in.
    /// l2BlockNumber L2 block number that the output corresponds to.

    struct OutputProposal {
        bytes32 outputRoot;
        uint128 timestamp;
        uint128 l2BlockNumber;
    }

    ///@notice Struct representing the elements that are hashed together to generate an output root
    ///        which itself represents a snapshot of the L2 state.
    /// version                  Version of the output root.
    /// stateRoot                Root of the state trie at the block of this output.
    /// withdrawalStorageRoot    Root of the withdrawal storage trie.
    /// latestBlockhash          Hash of the block this output was generated from.
    struct OutputRootProof {
        bytes32 stateRoot;
        bytes32 withdrawalStorageRoot;
        bytes32 latestBlockhash;
    }

    ///@notice Struct representing MPT Inclusion proof
    /// target                  The account that this proof should be proven for
    /// slotPosition            The storage slot that should be proven for
    /// proofsBlob              RLP encoded list of the account and storage proofs
    struct MPTInclusionProof {
        address target;
        bytes32 slotPosition;
        bytes proofsBlob;
    }

    ///@notice Struct representing MPT Inclusion proof
    /// outputRootProof                  The output proof structure
    /// optimismStateProofsBlob          The MPT RLP encoded list of the account and storage proofs to prove the output root
    struct OutputRootMPTProof {
        Types.OutputRootProof outputRootProof;
        bytes optimismStateProofsBlob;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types as CRCTypes} from "./libraries/Types.sol";

abstract contract CRCInbox {
    event InvokeSuccess(address indexed target, bytes32 indexed hash);
    event InvokeFailure(address indexed target, bytes32 indexed hash);

    event MessageReceived(
        address indexed user,
        address indexed target,
        bytes32 indexed hash
    );

    mapping(bytes32 => bool) public isUsed;
    mapping(bytes32 => address) public relayerOf;

    /// @notice generates the message hash of the given envelope
    /// @param envelope the message to get the hash of
    /// @return messageHash the message hash of this envelope
    function getMessageHash(CRCTypes.CRCMessageEnvelope calldata envelope)
        public
        pure
        returns (bytes32 messageHash)
    {
        // TODO add checks
        CRCTypes.CRCMessage memory message = envelope.message;

        return
            keccak256(
                abi.encode(
                    message.version,
                    message.destinationChainId,
                    message.nonce,
                    envelope.sender,
                    message.user,
                    message.target,
                    message.payload,
                    message.stateRelayFee,
                    message.deliveryFee,
                    message.extra
                )
            );
    }

    /// @notice gets the chainId for this contract network
    /// @return the chainId
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice marks the message as relayed and stores the relayer
    /// @dev marks the msg.sender as the relayer
    /// @param messageHash the message hash to mark as relayed
    function markMessageRelayed(bytes32 messageHash) internal virtual {
        isUsed[messageHash] = true;
        relayerOf[messageHash] = msg.sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types as CRCTypes} from "./../../libraries/Types.sol";
import {CRCInbox} from "./../../CRCInbox.sol";
import {L2OptimismBedrockStateProver} from "extractoor-contracts/L2/optimism/L2OptimismBedrockStateProver.sol";
import {Types as OptimismTypes} from "extractoor-contracts/library/optimism/Types.sol";
import {IMessageReceiver} from "./../../interfaces/IMessageReceiver.sol";

contract OptimismInbox is CRCInbox, L2OptimismBedrockStateProver {
    constructor(address _lightClient, address _oracleAddress)
        L2OptimismBedrockStateProver(_lightClient, _oracleAddress)
    {}

    /// @notice Method to trigger the receiving of a CRC message
    /// @dev calls the target contract with the message but does not revert even if the target call reverts.
    /// @param envelope The envelope of the message that is being relayed
    /// @param blockNumber The block number to request the L1 state root for
    /// @param outputIndex The index to find the output proof at inside the Bedrock OutputOracle
    /// @param outputProof The MPT proof data to verify that the given Optimism output root is contained inside the OutputOracle for the expected index
    /// @param inclusionProof The MPT proof data to verify that the given data is contained at a given slot inside Optimism
    /// @return success if the output root is indeed there
    function receiveMessage(
        CRCTypes.CRCMessageEnvelope calldata envelope,
        uint64 blockNumber,
        uint256 outputIndex,
        OptimismTypes.OutputRootMPTProof calldata outputProof,
        OptimismTypes.MPTInclusionProof calldata inclusionProof
    ) public virtual returns (bool success) {
        assert(envelope.message.target != address(this));
        require(
            envelope.message.destinationChainId == getChainID(),
            "Message is not intended for this network"
        );

        bytes32 messageHash = getMessageHash(envelope);

        require(!isUsed[messageHash], "Message already received");
        markMessageRelayed(messageHash);

        proveInOptimismState(
            blockNumber,
            outputIndex,
            outputProof,
            inclusionProof,
            uint256(messageHash)
        );

        (bool callSuccess, bytes memory data) = envelope.message.target.call(
            abi.encodeWithSelector(
                IMessageReceiver.receiveMessage.selector,
                envelope
            )
        );

        bool receiveSuccess = false;
        if (data.length > 0) {
            (receiveSuccess) = abi.decode(data, (bool));
        }

        if (callSuccess && receiveSuccess) {
            emit InvokeSuccess(envelope.message.target, messageHash);
        } else {
            emit InvokeFailure(envelope.message.target, messageHash);
        }

        emit MessageReceived(
            envelope.sender,
            envelope.message.target,
            messageHash
        );
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Types} from "./../libraries/Types.sol";

interface IMessageReceiver {
    /// @notice receives CRCMessageEnvelope
    /// @param envelope the message envelope you are receiving
    function receiveMessage(Types.CRCMessageEnvelope calldata envelope)
        external
        returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Types
 * @notice Contains various types used throughout the Optimism contract system.
 */
library Types {
    /**
     * @notice Input structure for sending a CRC message
     */
    struct CRCMessage {
        uint8 version; // Version of the protocol this message confirms to
        uint256 destinationChainId; // The “chain id” of the network this message is intended for
        uint64 nonce; // A nonce used as an anti-replay attack mechanism. Randomly generated by the user.
        address user; // An arbitrary address that is the actual sender of the message. Can be used by smart contracts that automate the messaging to specify the address of the user or be the same as the msg.sender.
        address target; // The address of a contract that the CRC Smart contract will send the Payload to when finalizing the CRC.
        bytes payload; // Arbitrary bytes that will be sent as calldata to the Execution Target address in the destination contract when finalizing the CRC.
        uint256 stateRelayFee; // Fee in wei that the sender will be locking as a reward for the first relayer that brings the state containing this information inside the destination network.
        uint256 deliveryFee; // Fee in wei that the sender will be locking as a reward for the first relayer that triggers the execution of the CRC delivery. Could be 0 if the Sender is willing to finalize it itself.
        bytes extra; // Arbitrary bytes that will be sent alongside the data for dapps to make sense of
    }

    /**
     * @notice Complete CRCMessage envelop including the sender. Used upon receiving of CRCMessages
     */
    struct CRCMessageEnvelope {
        CRCMessage message; // CRC Message
        address sender; // The sender of the message
    }
}