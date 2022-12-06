// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersStorage} from "./interfaces/IHeadersStorage.sol";
import {IFactsRegistry} from "./interfaces/IFactsRegistry.sol";

import {RLP} from "./lib/RLP.sol";
import {TrieProofs} from "./lib/TrieProofs.sol";
import {Bitmap16} from "./lib/Bitmap16.sol";

contract FactsRegistry is IFactsRegistry {
    using TrieProofs for bytes;
    using RLP for RLP.RLPItem;
    using RLP for bytes;
    using Bitmap16 for uint16;

    uint8 private constant ACCOUNT_NONCE_INDEX = 0;
    uint8 private constant ACCOUNT_BALANCE_INDEX = 1;
    uint8 private constant ACCOUNT_STORAGE_ROOT_INDEX = 2;
    uint8 private constant ACCOUNT_CODE_HASH_INDEX = 3;

    bytes32 private constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;
    bytes32 private constant EMPTY_CODE_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    IHeadersStorage public immutable headersStorage;

    mapping(address => mapping(uint256 => uint256)) public accountNonces;
    mapping(address => mapping(uint256 => uint256)) public accountBalances;
    mapping(address => mapping(uint256 => bytes32)) public accountCodeHashes;
    mapping(address => mapping(uint256 => bytes32)) public accountStorageHashes;

    constructor(IHeadersStorage _headersStorage) {
        headersStorage = _headersStorage;
    }

    function proveAccount(
        uint16 paramsBitmap,
        uint256 blockNumber,
        address account,
        bytes calldata proof
    ) external {
        bytes32 stateRoot = headersStorage.stateRoots(blockNumber);
        require(stateRoot != bytes32(0), "ERR_EMPTY_STATE_ROOT");

        bytes32 proofPath = keccak256(abi.encodePacked(account));
        bytes memory accountRLP = proof.verify(stateRoot, proofPath);

        bytes32 storageHash = EMPTY_TRIE_ROOT_HASH;
        bytes32 codeHash = EMPTY_CODE_HASH;
        uint256 nonce;
        uint256 balance;

        // TODO check length with assembly to avoid using keccak
        if (keccak256(accountRLP) != 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470) {
            RLP.RLPItem[] memory accountItems = accountRLP.toRLPItem().toList();

            if (paramsBitmap.readBitAtIndexFromRight(0)) {
                storageHash = bytes32(accountItems[ACCOUNT_STORAGE_ROOT_INDEX].toUint());
            }

            if (paramsBitmap.readBitAtIndexFromRight(1)) {
                codeHash = bytes32(accountItems[ACCOUNT_CODE_HASH_INDEX].toUint());
            }

            if (paramsBitmap.readBitAtIndexFromRight(2)) {
                nonce = accountItems[ACCOUNT_NONCE_INDEX].toUint();
            }

            if (paramsBitmap.readBitAtIndexFromRight(3)) {
                balance = accountItems[ACCOUNT_BALANCE_INDEX].toUint();
            }
        }

        // SAVE STORAGE_HASH
        if (paramsBitmap.readBitAtIndexFromRight(0)) {
            accountStorageHashes[account][blockNumber] = storageHash;
        }

        // SAVE CODE_HASH
        if (paramsBitmap.readBitAtIndexFromRight(1)) {
            accountCodeHashes[account][blockNumber] = codeHash;
        }

        // SAVE NONCE
        if (paramsBitmap.readBitAtIndexFromRight(2)) {
            accountNonces[account][blockNumber] = nonce;
        }

        // SAVE BALANCE
        if (paramsBitmap.readBitAtIndexFromRight(3)) {
            accountBalances[account][blockNumber] = balance;
        }
    }

    function proveStorage(
        address account,
        uint256 blockNumber,
        bytes32 slot,
        bytes memory storageProof
    ) public view returns (bytes32) {
        bytes32 root = accountStorageHashes[account][blockNumber];
        require(root != bytes32(0), "ERR_EMPTY_STORAGE_ROOT");
        bytes32 proofPath = keccak256(abi.encodePacked(slot));
        return bytes32(storageProof.verify(root, proofPath).toRLPItem().toUint());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHeadersStorage {
    function parentHashes(uint256) external view returns (bytes32);

    function stateRoots(uint256) external view returns (bytes32);

    function receiptsRoots(uint256) external view returns (bytes32);

    function transactionsRoots(uint256) external view returns (bytes32);

    function unclesHashes(uint256) external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFactsRegistry {
    function proveAccount(
        uint16 paramsBitmap,
        uint256 blockNumber,
        address account,
        bytes calldata proof
    ) external;

    function accountNonces(address account, uint256 blockNumber) external view returns (uint256);

    function accountBalances(address account, uint256 blockNumber) external view returns (uint256);

    function accountCodeHashes(address account, uint256 blockNumber) external view returns (bytes32);

    function accountStorageHashes(address account, uint256 blockNumber) external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library RLP {
    uint8 constant STRING_SHORT_START = 0x80;
    uint8 constant STRING_LONG_START = 0xb8;
    uint8 constant LIST_SHORT_START = 0xc0;
    uint8 constant LIST_LONG_START = 0xf8;

    uint8 constant WORD_SIZE = 32;

    struct RLPItem {
        uint256 len;
        uint256 memPtr;
    }

    /*
     * @param item RLP encoded bytes
     */
    function toRLPItem(bytes memory item) internal pure returns (RLPItem memory) {
        if (item.length == 0) return RLPItem(0, 0);

        uint256 memPtr;
        assembly {
            memPtr := add(item, 0x20)
        }

        return RLPItem(item.length, memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
     */
    function toList(RLPItem memory item) internal pure returns (RLPItem[] memory result) {
        require(isList(item), "Cannot convert to list a non-list RLPItem.");

        uint256 items = numItems(item);
        result = new RLPItem[](items);

        uint256 memPtr = item.memPtr + _payloadOffset(item.memPtr);
        uint256 dataLen;
        for (uint256 i = 0; i < items; i++) {
            dataLen = _itemLength(memPtr);
            result[i] = RLPItem(dataLen, memPtr);
            memPtr = memPtr + dataLen;
        }
    }

    /*
     * Helpers
     */

    // @return indicator whether encoded payload is a list. negate this function call for isData.
    function isList(RLPItem memory item) internal pure returns (bool) {
        uint8 byte0;
        uint256 memPtr = item.memPtr;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < LIST_SHORT_START) return false;
        return true;
    }

    // @return number of payload items inside an encoded list.
    function numItems(RLPItem memory item) internal pure returns (uint256) {
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
    function _itemLength(uint256 memPtr) internal pure returns (uint256 len) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 1;
        else if (byte0 < STRING_LONG_START) return byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
            assembly {
                let byteLen := sub(byte0, 0xb7) // # of bytes the actual length is
                memPtr := add(memPtr, 1) // skip over the first byte

                /* 32 byte word size */
                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to get the len
                len := add(dataLen, add(byteLen, 1))
            }
        } else if (byte0 < LIST_LONG_START) {
            return byte0 - LIST_SHORT_START + 1;
        } else {
            assembly {
                let byteLen := sub(byte0, 0xf7)
                memPtr := add(memPtr, 1)

                let dataLen := div(mload(memPtr), exp(256, sub(32, byteLen))) // right shifting to the correct length
                len := add(dataLen, add(byteLen, 1))
            }
        }
    }

    // @return number of bytes until the data
    function _payloadOffset(uint256 memPtr) internal pure returns (uint256) {
        uint256 byte0;
        assembly {
            byte0 := byte(0, mload(memPtr))
        }

        if (byte0 < STRING_SHORT_START) return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
    }

    /** RLPItem conversions into data types **/

    // @returns raw rlp encoding in bytes
    function toRLPBytes(RLPItem memory item) internal pure returns (bytes memory) {
        bytes memory result = new bytes(item.len);

        uint256 ptr;
        assembly {
            ptr := add(0x20, result)
        }

        copy(item.memPtr, ptr, item.len);
        return result;
    }

    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1, "Invalid RLPItem. Booleans are encoded in 1 byte");
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix according to RLP spec
        require(item.len <= 21, "Invalid RLPItem. Addresses are encoded in 20 bytes or less");

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;
        uint256 memPtr = item.memPtr + offset;

        uint256 result;
        assembly {
            result := div(mload(memPtr), exp(256, sub(32, len))) // shift to the correct location
        }

        return result;
    }

    function toBytes(RLPItem memory item) internal pure returns (bytes memory) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset; // data length
        bytes memory result = new bytes(len);

        uint256 destPtr;
        assembly {
            destPtr := add(0x20, result)
        }

        copy(item.memPtr + offset, destPtr, len);
        return result;
    }

    /*
     * @param src Pointer to source
     * @param dest Pointer to destination
     * @param len Amount of memory to copy from the source
     */
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) internal pure {
        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        // left over bytes. Mask is used to remove unwanted bytes from the word
        unchecked {
            uint256 mask = 256**(WORD_SIZE - len) - 1;
            assembly {
                let srcpart := and(mload(src), not(mask)) // zero out src
                let destpart := and(mload(dest), mask) // retrieve the bytes
                mstore(dest, or(destpart, srcpart))
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./RLP.sol";

/*
Forked from: https://github.com/lorenzb/proveth/blob/master/onchain/ProvethVerifier.sol
*/

library TrieProofs {
    using RLP for RLP.RLPItem;
    using RLP for bytes;

    bytes32 internal constant EMPTY_TRIE_ROOT_HASH = 0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421;

    function verify(
        bytes memory proofRLP,
        bytes32 rootHash,
        bytes32 path32
    ) internal pure returns (bytes memory value) {
        // TODO: Optimize by using word-size paths instead of byte arrays
        bytes memory path = new bytes(32);
        assembly {
            mstore(add(path, 0x20), path32)
        } // careful as path may need to be 64
        path = decodeNibbles(path, 0); // lol, so efficient

        RLP.RLPItem[] memory proof = proofRLP.toRLPItem().toList();

        uint8 nodeChildren;
        RLP.RLPItem memory children;

        uint256 pathOffset = 0; // Offset of the proof
        bytes32 nextHash; // Required hash for the next node

        if (proof.length == 0) {
            // Root hash of empty tx trie
            require(rootHash == EMPTY_TRIE_ROOT_HASH, "Bad empty proof");
            return new bytes(0);
        }

        for (uint256 i = 0; i < proof.length; i++) {
            // We use the fact that an rlp encoded list consists of some
            // encoding of its length plus the concatenation of its
            // *rlp-encoded* items.
            bytes memory rlpNode = proof[i].toRLPBytes(); // TODO: optimize by not encoding and decoding?

            if (i == 0) {
                require(rootHash == keccak256(rlpNode), "Bad first proof part");
            } else {
                require(nextHash == keccak256(rlpNode), "Bad hash");
            }

            RLP.RLPItem[] memory node = proof[i].toList();

            // Extension or Leaf node
            if (node.length == 2) {
                /*
                // TODO: wtf is a divergent node
                // proof claims divergent extension or leaf
                if (proofIndexes[i] == 0xff) {
                    require(i >= proof.length - 1); // divergent node must come last in proof
                    require(prefixLength != nodePath.length); // node isn't divergent
                    require(pathOffset == path.length); // didn't consume entire path

                    return new bytes(0);
                }

                require(proofIndexes[i] == 1); // an extension/leaf node only has two fields.
                require(prefixLength == nodePath.length); // node is divergent
                */

                bytes memory nodePath = merklePatriciaCompactDecode(node[0].toBytes());
                pathOffset += sharedPrefixLength(pathOffset, path, nodePath);

                // last proof item
                if (i == proof.length - 1) {
                    require(pathOffset == path.length, "Unexpected end of proof (leaf)");
                    return node[1].toBytes(); // Data is the second item in a leaf node
                } else {
                    // not last proof item
                    children = node[1];
                    if (!children.isList()) {
                        nextHash = getNextHash(children);
                    } else {
                        nextHash = keccak256(children.toRLPBytes());
                    }
                }
            } else {
                // Must be a branch node at this point
                require(node.length == 17, "Invalid node length");

                if (i == proof.length - 1) {
                    // Proof ends in a branch node, exclusion proof in most cases
                    if (pathOffset + 1 == path.length) {
                        return node[16].toBytes();
                    } else {
                        nodeChildren = extractNibble(path32, pathOffset);
                        children = node[nodeChildren];

                        // Ensure that the next path item is empty, end of exclusion proof
                        require(children.toBytes().length == 0, "Invalid exclusion proof");
                        return new bytes(0);
                    }
                } else {
                    require(pathOffset < path.length, "Continuing branch has depleted path");

                    nodeChildren = extractNibble(path32, pathOffset);
                    children = node[nodeChildren];

                    pathOffset += 1; // advance by one

                    // not last level
                    if (!children.isList()) {
                        nextHash = getNextHash(children);
                    } else {
                        nextHash = keccak256(children.toRLPBytes());
                    }
                }
            }
        }

        // no invalid proof should ever reach this point
        assert(false);
    }

    function getNextHash(RLP.RLPItem memory node) internal pure returns (bytes32 nextHash) {
        bytes memory nextHashBytes = node.toBytes();
        require(nextHashBytes.length == 32, "Invalid node");

        assembly {
            nextHash := mload(add(nextHashBytes, 0x20))
        }
    }

    /*
     * Nibble is extracted as the least significant nibble in the returned byte
     */
    function extractNibble(bytes32 path, uint256 position) internal pure returns (uint8 nibble) {
        require(position < 64, "Invalid nibble position");
        bytes1 shifted = position == 0 ? bytes1(path >> 4) : bytes1(path << ((position - 1) * 4));
        return uint8(bytes1(uint8(shifted) & uint8(0xF)));
    }

    function decodeNibbles(bytes memory compact, uint256 skipNibbles) internal pure returns (bytes memory nibbles) {
        require(compact.length > 0, "Empty bytes array");

        uint256 length = compact.length * 2;
        require(skipNibbles <= length, "Skip nibbles amount too large");
        length -= skipNibbles;

        nibbles = new bytes(length);
        uint256 nibblesLength = 0;

        for (uint256 i = skipNibbles; i < skipNibbles + length; i += 1) {
            if (i % 2 == 0) {
                nibbles[nibblesLength] = bytes1((uint8(compact[i / 2]) >> 4) & 0xF);
            } else {
                nibbles[nibblesLength] = bytes1((uint8(compact[i / 2]) >> 0) & 0xF);
            }
            nibblesLength += 1;
        }

        assert(nibblesLength == nibbles.length);
    }

    function merklePatriciaCompactDecode(bytes memory compact) internal pure returns (bytes memory nibbles) {
        require(compact.length > 0, "Empty bytes array");
        uint256 first_nibble = (uint8(compact[0]) >> 4) & 0xF;
        uint256 skipNibbles;
        if (first_nibble == 0) {
            skipNibbles = 2;
        } else if (first_nibble == 1) {
            skipNibbles = 1;
        } else if (first_nibble == 2) {
            skipNibbles = 2;
        } else if (first_nibble == 3) {
            skipNibbles = 1;
        } else {
            // Not supposed to happen!
            revert();
        }
        return decodeNibbles(compact, skipNibbles);
    }

    function sharedPrefixLength(
        uint256 xsOffset,
        bytes memory xs,
        bytes memory ys
    ) internal pure returns (uint256) {
        uint256 i = 0;
        for (i = 0; i + xsOffset < xs.length && i < ys.length; i++) {
            if (xs[i + xsOffset] != ys[i]) {
                return i;
            }
        }
        return i;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Bitmap16 {
    function readBitAtIndexFromRight(uint16 bitmap, uint256 index) public pure returns (bool value) {
        require(15 >= index, "ERR_OUR_OF_RANGE");
        return (bitmap & (1 << index)) > 0;
    }
}