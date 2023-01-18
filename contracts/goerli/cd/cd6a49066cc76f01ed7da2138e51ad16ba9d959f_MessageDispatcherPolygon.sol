pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library ExitPayloadReader {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    uint8 constant WORD_SIZE = 32;

    struct ExitPayload {
        RLPReader.RLPItem[] data;
    }

    struct Receipt {
        RLPReader.RLPItem[] data;
        bytes raw;
        uint256 logIndex;
    }

    struct Log {
        RLPReader.RLPItem data;
        RLPReader.RLPItem[] list;
    }

    struct LogTopics {
        RLPReader.RLPItem[] data;
    }

    // copy paste of private copy() from RLPReader to avoid changing of existing contracts
    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toExitPayload(bytes memory data) internal pure returns (ExitPayload memory) {
        RLPReader.RLPItem[] memory payloadData = data.toRlpItem().toList();

        return ExitPayload(payloadData);
    }

    function getHeaderNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[0].toUint();
    }

    function getBlockProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[1].toBytes();
    }

    function getBlockNumber(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[2].toUint();
    }

    function getBlockTime(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[3].toUint();
    }

    function getTxRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[4].toUint());
    }

    function getReceiptRoot(ExitPayload memory payload) internal pure returns (bytes32) {
        return bytes32(payload.data[5].toUint());
    }

    function getReceipt(ExitPayload memory payload) internal pure returns (Receipt memory receipt) {
        receipt.raw = payload.data[6].toBytes();
        RLPReader.RLPItem memory receiptItem = receipt.raw.toRlpItem();

        if (receiptItem.isList()) {
            // legacy tx
            receipt.data = receiptItem.toList();
        } else {
            // pop first byte before parsing receipt
            bytes memory typedBytes = receipt.raw;
            bytes memory result = new bytes(typedBytes.length - 1);
            uint256 srcPtr;
            uint256 destPtr;
            assembly {
                srcPtr := add(33, typedBytes)
                destPtr := add(0x20, result)
            }

            copy(srcPtr, destPtr, result.length);
            receipt.data = result.toRlpItem().toList();
        }

        receipt.logIndex = getReceiptLogIndex(payload);
        return receipt;
    }

    function getReceiptProof(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[7].toBytes();
    }

    function getBranchMaskAsBytes(ExitPayload memory payload) internal pure returns (bytes memory) {
        return payload.data[8].toBytes();
    }

    function getBranchMaskAsUint(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[8].toUint();
    }

    function getReceiptLogIndex(ExitPayload memory payload) internal pure returns (uint256) {
        return payload.data[9].toUint();
    }

    // Receipt methods
    function toBytes(Receipt memory receipt) internal pure returns (bytes memory) {
        return receipt.raw;
    }

    function getLog(Receipt memory receipt) internal pure returns (Log memory) {
        RLPReader.RLPItem memory logData = receipt.data[3].toList()[receipt.logIndex];
        return Log(logData, logData.toList());
    }

    // Log methods
    function getEmitter(Log memory log) internal pure returns (address) {
        return RLPReader.toAddress(log.list[0]);
    }

    function getTopics(Log memory log) internal pure returns (LogTopics memory) {
        return LogTopics(log.list[1].toList());
    }

    function getData(Log memory log) internal pure returns (bytes memory) {
        return log.list[2].toBytes();
    }

    function toRlpBytes(Log memory log) internal pure returns (bytes memory) {
        return log.data.toRlpBytes();
    }

    // LogTopics methods
    function getField(LogTopics memory topics, uint256 index) internal pure returns (RLPReader.RLPItem memory) {
        return topics.data[index];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Merkle {
    function checkMembership(
        bytes32 leaf,
        uint256 index,
        bytes32 rootHash,
        bytes memory proof
    ) internal pure returns (bool) {
        require(proof.length % 32 == 0, "Invalid proof length");
        uint256 proofHeight = proof.length / 32;
        // Proof of size n means, height of the tree is n+1.
        // In a tree of height n+1, max #leafs possible is 2 ^ n
        require(index < 2**proofHeight, "Leaf index is too big");

        bytes32 proofElement;
        bytes32 computedHash = leaf;
        for (uint256 i = 32; i <= proof.length; i += 32) {
            assembly {
                proofElement := mload(add(proof, i))
            }

            if (index % 2 == 0) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

            index = index / 2;
        }
        return computedHash == rootHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "./RLPReader.sol";

library MerklePatriciaProof {
    /*
     * @dev Verifies a merkle patricia proof.
     * @param value The terminating value in the trie.
     * @param encodedPath The path in the trie leading to value.
     * @param rlpParentNodes The rlp encoded stack of nodes.
     * @param root The root hash of the trie.
     * @return The boolean validity of the proof.
     */
    function verify(
        bytes memory value,
        bytes memory encodedPath,
        bytes memory rlpParentNodes,
        bytes32 root
    ) internal pure returns (bool) {
        RLPReader.RLPItem memory item = RLPReader.toRlpItem(rlpParentNodes);
        RLPReader.RLPItem[] memory parentNodes = RLPReader.toList(item);

        bytes memory currentNode;
        RLPReader.RLPItem[] memory currentNodeList;

        bytes32 nodeKey = root;
        uint256 pathPtr = 0;

        bytes memory path = _getNibbleArray(encodedPath);
        if (path.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < parentNodes.length; i++) {
            if (pathPtr > path.length) {
                return false;
            }

            currentNode = RLPReader.toRlpBytes(parentNodes[i]);
            if (nodeKey != keccak256(currentNode)) {
                return false;
            }
            currentNodeList = RLPReader.toList(parentNodes[i]);

            if (currentNodeList.length == 17) {
                if (pathPtr == path.length) {
                    if (keccak256(RLPReader.toBytes(currentNodeList[16])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                uint8 nextPathNibble = uint8(path[pathPtr]);
                if (nextPathNibble > 16) {
                    return false;
                }
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[nextPathNibble]));
                pathPtr += 1;
            } else if (currentNodeList.length == 2) {
                uint256 traversed = _nibblesToTraverse(RLPReader.toBytes(currentNodeList[0]), path, pathPtr);
                if (pathPtr + traversed == path.length) {
                    //leaf node
                    if (keccak256(RLPReader.toBytes(currentNodeList[1])) == keccak256(value)) {
                        return true;
                    } else {
                        return false;
                    }
                }

                //extension node
                if (traversed == 0) {
                    return false;
                }

                pathPtr += traversed;
                nodeKey = bytes32(RLPReader.toUintStrict(currentNodeList[1]));
            } else {
                return false;
            }
        }
    }

    function _nibblesToTraverse(
        bytes memory encodedPartialPath,
        bytes memory path,
        uint256 pathPtr
    ) private pure returns (uint256) {
        uint256 len = 0;
        // encodedPartialPath has elements that are each two hex characters (1 byte), but partialPath
        // and slicedPath have elements that are each one hex character (1 nibble)
        bytes memory partialPath = _getNibbleArray(encodedPartialPath);
        bytes memory slicedPath = new bytes(partialPath.length);

        // pathPtr counts nibbles in path
        // partialPath.length is a number of nibbles
        for (uint256 i = pathPtr; i < pathPtr + partialPath.length; i++) {
            bytes1 pathNibble = path[i];
            slicedPath[i - pathPtr] = pathNibble;
        }

        if (keccak256(partialPath) == keccak256(slicedPath)) {
            len = partialPath.length;
        } else {
            len = 0;
        }
        return len;
    }

    // bytes b must be hp encoded
    function _getNibbleArray(bytes memory b) internal pure returns (bytes memory) {
        bytes memory nibbles = "";
        if (b.length > 0) {
            uint8 offset;
            uint8 hpNibble = uint8(_getNthNibbleOfBytes(0, b));
            if (hpNibble == 1 || hpNibble == 3) {
                nibbles = new bytes(b.length * 2 - 1);
                bytes1 oddNibble = _getNthNibbleOfBytes(1, b);
                nibbles[0] = oddNibble;
                offset = 1;
            } else {
                nibbles = new bytes(b.length * 2 - 2);
                offset = 0;
            }

            for (uint256 i = offset; i < nibbles.length; i++) {
                nibbles[i] = _getNthNibbleOfBytes(i - offset + 2, b);
            }
        }
        return nibbles;
    }

    function _getNthNibbleOfBytes(uint256 n, bytes memory str) private pure returns (bytes1) {
        return bytes1(n % 2 == 0 ? uint8(str[n / 2]) / 0x10 : uint8(str[n / 2]) % 0x10);
    }
}

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity ^0.8.0;

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
     * @param item RLP encoded bytes
     */
    function rlpLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len;
    }

    /*
     * @param item RLP encoded bytes
     */
    function payloadLen(RLPItem memory item) internal pure returns (uint256) {
        return item.len - _payloadOffset(item.memPtr);
    }

    /*
     * @param item RLP encoded list in bytes
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

    function payloadLocation(RLPItem memory item) internal pure returns (uint256, uint256) {
        uint256 offset = _payloadOffset(item.memPtr);
        uint256 memPtr = item.memPtr + offset;
        uint256 len = item.len - offset; // data length
        return (memPtr, len);
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

    // any non-zero byte < 128 is considered true
    function toBoolean(RLPItem memory item) internal pure returns (bool) {
        require(item.len == 1);
        uint256 result;
        uint256 memPtr = item.memPtr;
        assembly {
            result := byte(0, mload(memPtr))
        }

        return result == 0 ? false : true;
    }

    function toAddress(RLPItem memory item) internal pure returns (address) {
        // 1 byte for the length prefix
        require(item.len == 21);

        return address(uint160(toUint(item)));
    }

    function toUint(RLPItem memory item) internal pure returns (uint256) {
        require(item.len > 0 && item.len <= 33);

        uint256 offset = _payloadOffset(item.memPtr);
        uint256 len = item.len - offset;

        uint256 result;
        uint256 memPtr = item.memPtr + offset;
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

        if (byte0 < STRING_SHORT_START) itemLen = 1;
        else if (byte0 < STRING_LONG_START) itemLen = byte0 - STRING_SHORT_START + 1;
        else if (byte0 < LIST_SHORT_START) {
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

        if (byte0 < STRING_SHORT_START) return 0;
        else if (byte0 < STRING_LONG_START || (byte0 >= LIST_SHORT_START && byte0 < LIST_LONG_START)) return 1;
        else if (byte0 < LIST_SHORT_START)
            // being explicit
            return byte0 - (STRING_LONG_START - 1) + 1;
        else return byte0 - (LIST_LONG_START - 1) + 1;
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
    ) private pure {
        if (len == 0) return;

        // copy as many word sizes as possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }

            src += WORD_SIZE;
            dest += WORD_SIZE;
        }

        if (len == 0) return;

        // left over bytes. Mask is used to remove unwanted bytes from the word
        uint256 mask = 256**(WORD_SIZE - len) - 1;

        assembly {
            let srcpart := and(mload(src), not(mask)) // zero out src
            let destpart := and(mload(dest), mask) // retrieve the bytes
            mstore(dest, or(destpart, srcpart))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RLPReader} from "../lib/RLPReader.sol";
import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol";
import {Merkle} from "../lib/Merkle.sol";
import "../lib/ExitPayloadReader.sol";

interface IFxStateSender {
    function sendMessageToChild(address _receiver, bytes calldata _data) external;
}

contract ICheckpointManager {
    struct HeaderBlock {
        bytes32 root;
        uint256 start;
        uint256 end;
        uint256 createdAt;
        address proposer;
    }

    /**
     * @notice mapping of checkpoint header numbers to block details
     * @dev These checkpoints are submited by plasma contracts
     */
    mapping(uint256 => HeaderBlock) public headerBlocks;
}

abstract contract FxBaseRootTunnel {
    using RLPReader for RLPReader.RLPItem;
    using Merkle for bytes32;
    using ExitPayloadReader for bytes;
    using ExitPayloadReader for ExitPayloadReader.ExitPayload;
    using ExitPayloadReader for ExitPayloadReader.Log;
    using ExitPayloadReader for ExitPayloadReader.LogTopics;
    using ExitPayloadReader for ExitPayloadReader.Receipt;

    // keccak256(MessageSent(bytes))
    bytes32 public constant SEND_MESSAGE_EVENT_SIG = 0x8c5261668696ce22758910d05bab8f186d6eb247ceac2af2e82c7dc17669b036;

    // state sender contract
    IFxStateSender public fxRoot;
    // root chain manager
    ICheckpointManager public checkpointManager;
    // child tunnel contract which receives and sends messages
    address public fxChildTunnel;

    // storage to avoid duplicate exits
    mapping(bytes32 => bool) public processedExits;

    constructor(address _checkpointManager, address _fxRoot) {
        checkpointManager = ICheckpointManager(_checkpointManager);
        fxRoot = IFxStateSender(_fxRoot);
    }

    // set fxChildTunnel if not set already
    function setFxChildTunnel(address _fxChildTunnel) public virtual {
        require(fxChildTunnel == address(0x0), "FxBaseRootTunnel: CHILD_TUNNEL_ALREADY_SET");
        fxChildTunnel = _fxChildTunnel;
    }

    /**
     * @notice Send bytes message to Child Tunnel
     * @param message bytes message that will be sent to Child Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToChild(bytes memory message) internal {
        fxRoot.sendMessageToChild(fxChildTunnel, message);
    }

    function _validateAndExtractMessage(bytes memory inputData) internal returns (bytes memory) {
        ExitPayloadReader.ExitPayload memory payload = inputData.toExitPayload();

        bytes memory branchMaskBytes = payload.getBranchMaskAsBytes();
        uint256 blockNumber = payload.getBlockNumber();
        // checking if exit has already been processed
        // unique exit is identified using hash of (blockNumber, branchMask, receiptLogIndex)
        bytes32 exitHash = keccak256(
            abi.encodePacked(
                blockNumber,
                // first 2 nibbles are dropped while generating nibble array
                // this allows branch masks that are valid but bypass exitHash check (changing first 2 nibbles only)
                // so converting to nibble array and then hashing it
                MerklePatriciaProof._getNibbleArray(branchMaskBytes),
                payload.getReceiptLogIndex()
            )
        );
        require(processedExits[exitHash] == false, "FxRootTunnel: EXIT_ALREADY_PROCESSED");
        processedExits[exitHash] = true;

        ExitPayloadReader.Receipt memory receipt = payload.getReceipt();
        ExitPayloadReader.Log memory log = receipt.getLog();

        // check child tunnel
        require(fxChildTunnel == log.getEmitter(), "FxRootTunnel: INVALID_FX_CHILD_TUNNEL");

        bytes32 receiptRoot = payload.getReceiptRoot();
        // verify receipt inclusion
        require(
            MerklePatriciaProof.verify(receipt.toBytes(), branchMaskBytes, payload.getReceiptProof(), receiptRoot),
            "FxRootTunnel: INVALID_RECEIPT_PROOF"
        );

        // verify checkpoint inclusion
        _checkBlockMembershipInCheckpoint(
            blockNumber,
            payload.getBlockTime(),
            payload.getTxRoot(),
            receiptRoot,
            payload.getHeaderNumber(),
            payload.getBlockProof()
        );

        ExitPayloadReader.LogTopics memory topics = log.getTopics();

        require(
            bytes32(topics.getField(0).toUint()) == SEND_MESSAGE_EVENT_SIG, // topic0 is event sig
            "FxRootTunnel: INVALID_SIGNATURE"
        );

        // received message data
        bytes memory message = abi.decode(log.getData(), (bytes)); // event decodes params again, so decoding bytes to get message
        return message;
    }

    function _checkBlockMembershipInCheckpoint(
        uint256 blockNumber,
        uint256 blockTime,
        bytes32 txRoot,
        bytes32 receiptRoot,
        uint256 headerNumber,
        bytes memory blockProof
    ) private view {
        (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)).checkMembership(
                blockNumber - startBlock,
                headerRoot,
                blockProof
            ),
            "FxRootTunnel: INVALID_HEADER"
        );
    }

    /**
     * @notice receive message from  L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param inputData RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(bytes memory inputData) public virtual {
        bytes memory message = _validateAndExtractMessage(inputData);
        _processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by receiveMessage function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { FxBaseRootTunnel } from "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";

import { IMessageExecutor } from "../interfaces/IMessageExecutor.sol";
import { IMessageDispatcher, ISingleMessageDispatcher } from "../interfaces/ISingleMessageDispatcher.sol";
import { IBatchedMessageDispatcher } from "../interfaces/IBatchedMessageDispatcher.sol";

import "../libraries/MessageLib.sol";

/**
 * @title MessageDispatcherPolygon contract
 * @notice The MessageDispatcherPolygon contract allows a user or contract to send messages from Ethereum to Polygon.
 *         It lives on the Ethereum chain and communicates with the `MessageExecutorPolygon` contract on the Polygon chain.
 */
contract MessageDispatcherPolygon is
  ISingleMessageDispatcher,
  IBatchedMessageDispatcher,
  FxBaseRootTunnel
{
  /* ============ Variables ============ */

  /// @notice Nonce used to compute unique `messageId`s.
  uint256 internal nonce;

  /// @notice ID of the chain receiving the dispatched messages. i.e.: 137 for Mainnet, 80001 for Mumbai.
  uint256 internal immutable toChainId;

  /* ============ Constructor ============ */

  /**
   * @notice MessageDispatcherPolygon constructor.
   * @param _checkpointManager Address of the root chain manager contract on Ethereum
   * @param _fxRoot Address of the state sender contract on Ethereum
   * @param _toChainId ID of the chain receiving the dispatched messages
   */
  constructor(
    address _checkpointManager,
    address _fxRoot,
    uint256 _toChainId
  ) FxBaseRootTunnel(_checkpointManager, _fxRoot) {
    require(_toChainId != 0, "Dispatcher/chainId-not-zero");
    toChainId = _toChainId;
  }

  /* ============ External Functions ============ */

  /// @inheritdoc ISingleMessageDispatcher
  function dispatchMessage(
    uint256 _toChainId,
    address _to,
    bytes calldata _data
  ) external returns (bytes32) {
    _checkDispatchParams(_toChainId);

    uint256 _nonce = _incrementNonce();
    bytes32 _messageId = MessageLib.computeMessageId(_nonce, msg.sender, _to, _data);

    MessageLib.Message[] memory _messages = new MessageLib.Message[](1);
    _messages[0] = MessageLib.Message({ to: _to, data: _data });

    _sendMessageToChild(abi.encode(_messages, _messageId, block.chainid, msg.sender));

    emit MessageDispatched(_messageId, msg.sender, _toChainId, _to, _data);

    return _messageId;
  }

  /// @inheritdoc IBatchedMessageDispatcher
  function dispatchMessageBatch(uint256 _toChainId, MessageLib.Message[] calldata _messages)
    external
    returns (bytes32)
  {
    _checkDispatchParams(_toChainId);

    uint256 _nonce = _incrementNonce();
    bytes32 _messageId = MessageLib.computeMessageBatchId(_nonce, msg.sender, _messages);

    bytes memory _message = abi.encode(_messages, _messageId, block.chainid, msg.sender);

    _sendMessageToChild(_message);

    emit MessageBatchDispatched(_messageId, msg.sender, _toChainId, _messages);

    return _messageId;
  }

  /// @inheritdoc IMessageDispatcher
  function getMessageExecutorAddress(uint256 _chainId) external view returns (address) {
    _checkToChainId(_chainId);
    return address(fxChildTunnel);
  }

  /* ============ Internal Functions ============ */

  /**
   * @notice Check toChainId to ensure messages can be dispatched to this chain.
   * @dev Will revert if `_toChainId` is not supported.
   * @param _toChainId ID of the chain receiving the message
   */
  function _checkToChainId(uint256 _toChainId) internal view {
    require(_toChainId == toChainId, "Dispatcher/chainId-not-supported");
  }

  /**
   * @notice Check dispatch parameters to ensure messages can be dispatched.
   * @dev Will revert if `fxChildTunnel` is not set.
   * @dev Will revert if `_toChainId` is not supported.
   * @param _toChainId ID of the chain receiving the message
   */
  function _checkDispatchParams(uint256 _toChainId) internal view {
    require(address(fxChildTunnel) != address(0), "Dispatcher/fxChildTunnel-not-set");
    _checkToChainId(_toChainId);
  }

  /**
   * @notice Helper to increment nonce.
   * @return uint256 Incremented nonce
   */
  function _incrementNonce() internal returns (uint256) {
    unchecked {
      nonce++;
    }

    return nonce;
  }

  /**
   * @inheritdoc FxBaseRootTunnel
   * @dev This contract must not be used to receive and execute messages from Polygon.
   *      We need to implement the following function to be able to inherit from FxBaseRootTunnel.
   */
  function _processMessageFromChild(bytes memory data) internal override {
    /// no-op
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./IMessageDispatcher.sol";

/**
 * @title ERC-5164: Cross-Chain Execution Standard, optional BatchMessageDispatcher extension
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface IBatchedMessageDispatcher is IMessageDispatcher {
  /**
   * @notice Dispatch `messages` to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the `messages`.
   * @dev Must emit the `MessageBatchDispatched` event when successfully dispatched.
   * @param toChainId ID of the receiving chain
   * @param messages Array of Message dispatched
   * @return bytes32 ID uniquely identifying the `messages`
   */
  function dispatchMessageBatch(uint256 toChainId, MessageLib.Message[] calldata messages)
    external
    returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "../libraries/MessageLib.sol";

/**
 * @title ERC-5164: Cross-Chain Execution Standard
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface IMessageDispatcher {
  /**
   * @notice Emitted when a message has successfully been dispatched to the executor chain.
   * @param messageId ID uniquely identifying the message
   * @param from Address that dispatched the message
   * @param toChainId ID of the chain receiving the message
   * @param to Address that will receive the message
   * @param data Data that was dispatched
   */
  event MessageDispatched(
    bytes32 indexed messageId,
    address indexed from,
    uint256 indexed toChainId,
    address to,
    bytes data
  );

  /**
   * @notice Emitted when a batch of messages has successfully been dispatched to the executor chain.
   * @param messageId ID uniquely identifying the messages
   * @param from Address that dispatched the messages
   * @param toChainId ID of the chain receiving the messages
   * @param messages Array of Message that was dispatched
   */
  event MessageBatchDispatched(
    bytes32 indexed messageId,
    address indexed from,
    uint256 indexed toChainId,
    MessageLib.Message[] messages
  );

  /**
   * @notice Retrieves address of the MessageExecutor contract on the receiving chain.
   * @dev Must revert if `toChainId` is not supported.
   * @param toChainId ID of the chain with which MessageDispatcher is communicating
   * @return address MessageExecutor contract address
   */
  function getMessageExecutorAddress(uint256 toChainId) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./IMessageDispatcher.sol";

import "../libraries/MessageLib.sol";

/**
 * @title MessageExecutor interface
 * @notice MessageExecutor interface of the ERC-5164 standard as defined in the EIP.
 */
interface IMessageExecutor {
  /**
   * @notice Emitted when a message has successfully been executed.
   * @param fromChainId ID of the chain that dispatched the message
   * @param dispatcher Address of the contract that dispatched the message on the origin chain
   * @param messageId ID uniquely identifying the message
   */
  event ExecutedMessage(
    uint256 indexed fromChainId,
    IMessageDispatcher indexed dispatcher,
    bytes32 indexed messageId
  );

  /**
   * @notice Emitted when messages have successfully been executed.
   * @param fromChainId ID of the chain that dispatched the messages
   * @param dispatcher Address of the contract that dispatched the messages on the origin chain
   * @param messageId ID uniquely identifying the messages
   */
  event ExecutedMessageBatch(
    uint256 indexed fromChainId,
    IMessageDispatcher indexed dispatcher,
    bytes32 indexed messageId
  );

  /**
   * @notice Execute message from the origin chain.
   * @dev Should authenticate that the call has been performed by the bridge transport layer.
   * @dev Must revert if the message fails.
   * @dev Must emit the `ExecutedMessage` event once the message has been executed.
   * @param to Address that will receive `data`
   * @param data Data forwarded to address `to`
   * @param messageId ID uniquely identifying the message
   * @param fromChainId ID of the chain that dispatched the message
   * @param from Address of the sender on the origin chain
   */
  function executeMessage(
    address to,
    bytes calldata data,
    bytes32 messageId,
    uint256 fromChainId,
    address from
  ) external;

  /**
   * @notice Execute a batch messages from the origin chain.
   * @dev Should authenticate that the call has been performed by the bridge transport layer.
   * @dev Must revert if one of the messages fails.
   * @dev Must emit the `ExecutedMessageBatch` event once messages have been executed.
   * @param messages Array of messages being executed
   * @param messageId ID uniquely identifying the messages
   * @param fromChainId ID of the chain that dispatched the messages
   * @param from Address of the sender on the origin chain
   */
  function executeMessageBatch(
    MessageLib.Message[] calldata messages,
    bytes32 messageId,
    uint256 fromChainId,
    address from
  ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import "./IMessageDispatcher.sol";

/**
 * @title ERC-5164: Cross-Chain Execution Standard, optional SingleMessageDispatcher extension
 * @dev See https://eips.ethereum.org/EIPS/eip-5164
 */
interface ISingleMessageDispatcher is IMessageDispatcher {
  /**
   * @notice Dispatch a message to the receiving chain.
   * @dev Must compute and return an ID uniquely identifying the message.
   * @dev Must emit the `MessageDispatched` event when successfully dispatched.
   * @param toChainId ID of the receiving chain
   * @param to Address on the receiving chain that will receive `data`
   * @param data Data dispatched to the receiving chain
   * @return bytes32 ID uniquely identifying the message
   */
  function dispatchMessage(
    uint256 toChainId,
    address to,
    bytes calldata data
  ) external returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

import { IMessageExecutor } from "../interfaces/IMessageExecutor.sol";

/**
 * @title MessageLib
 * @notice Library to declare and manipulate Message(s).
 */
library MessageLib {
  /* ============ Structs ============ */

  /**
   * @notice Message data structure
   * @param to Address that will be dispatched on the receiving chain
   * @param data Data that will be sent to the `to` address
   */
  struct Message {
    address to;
    bytes data;
  }

  /* ============ Events ============ */

  /* ============ Custom Errors ============ */

  /**
   * @notice Emitted when a messageId has already been executed.
   * @param messageId ID uniquely identifying the message or message batch that were re-executed
   */
  error MessageIdAlreadyExecuted(bytes32 messageId);

  /**
   * @notice Emitted if a call to a contract fails.
   * @param messageId ID uniquely identifying the message
   * @param errorData Error data returned by the call
   */
  error MessageFailure(bytes32 messageId, bytes errorData);

  /**
   * @notice Emitted if a call to a contract fails inside a batch of messages.
   * @param messageId ID uniquely identifying the batch of messages
   * @param messageIndex Index of the message
   * @param errorData Error data returned by the call
   */
  error MessageBatchFailure(bytes32 messageId, uint256 messageIndex, bytes errorData);

  /* ============ Internal Functions ============ */

  /**
   * @notice Helper to compute messageId.
   * @param nonce Monotonically increased nonce to ensure uniqueness
   * @param from Address that dispatched the message
   * @param to Address that will receive the message
   * @param data Data that was dispatched
   * @return bytes32 ID uniquely identifying the message that was dispatched
   */
  function computeMessageId(
    uint256 nonce,
    address from,
    address to,
    bytes memory data
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(nonce, from, to, data));
  }

  /**
   * @notice Helper to compute messageId for a batch of messages.
   * @param nonce Monotonically increased nonce to ensure uniqueness
   * @param from Address that dispatched the messages
   * @param messages Array of Message dispatched
   * @return bytes32 ID uniquely identifying the message that was dispatched
   */
  function computeMessageBatchId(
    uint256 nonce,
    address from,
    Message[] memory messages
  ) internal pure returns (bytes32) {
    return keccak256(abi.encode(nonce, from, messages));
  }

  /**
   * @notice Helper to encode message for execution by the MessageExecutor.
   * @param to Address that will receive the message
   * @param data Data that will be dispatched
   * @param messageId ID uniquely identifying the message being dispatched
   * @param fromChainId ID of the chain that dispatched the message
   * @param from Address that dispatched the message
   */
  function encodeMessage(
    address to,
    bytes memory data,
    bytes32 messageId,
    uint256 fromChainId,
    address from
  ) internal pure returns (bytes memory) {
    return
      abi.encodeWithSelector(
        IMessageExecutor.executeMessage.selector,
        to,
        data,
        messageId,
        fromChainId,
        from
      );
  }

  /**
   * @notice Helper to encode a batch of messages for execution by the MessageExecutor.
   * @param messages Array of Message that will be dispatched
   * @param messageId ID uniquely identifying the batch of messages being dispatched
   * @param fromChainId ID of the chain that dispatched the batch of messages
   * @param from Address that dispatched the batch of messages
   */
  function encodeMessageBatch(
    Message[] memory messages,
    bytes32 messageId,
    uint256 fromChainId,
    address from
  ) internal pure returns (bytes memory) {
    return
      abi.encodeWithSelector(
        IMessageExecutor.executeMessageBatch.selector,
        messages,
        messageId,
        fromChainId,
        from
      );
  }

  /**
   * @notice Execute message from the origin chain.
   * @dev Will revert if `message` has already been executed.
   * @param to Address that will receive the message
   * @param data Data that was dispatched
   * @param messageId ID uniquely identifying message
   * @param fromChainId ID of the chain that dispatched the `message`
   * @param from Address of the sender on the origin chain
   * @param executedMessageId Whether `message` has already been executed or not
   */
  function executeMessage(
    address to,
    bytes memory data,
    bytes32 messageId,
    uint256 fromChainId,
    address from,
    bool executedMessageId
  ) internal {
    if (executedMessageId) {
      revert MessageIdAlreadyExecuted(messageId);
    }

    _requireContract(to);

    (bool _success, bytes memory _returnData) = to.call(
      abi.encodePacked(data, messageId, fromChainId, from)
    );

    if (!_success) {
      revert MessageFailure(messageId, _returnData);
    }
  }

  /**
   * @notice Execute messages from the origin chain.
   * @dev Will revert if `messages` have already been executed.
   * @param messages Array of messages being executed
   * @param messageId Nonce to uniquely identify the messages
   * @param from Address of the sender on the origin chain
   * @param fromChainId ID of the chain that dispatched the `messages`
   * @param executedMessageId Whether `messages` have already been executed or not
   */
  function executeMessageBatch(
    Message[] memory messages,
    bytes32 messageId,
    uint256 fromChainId,
    address from,
    bool executedMessageId
  ) internal {
    if (executedMessageId) {
      revert MessageIdAlreadyExecuted(messageId);
    }

    uint256 _messagesLength = messages.length;

    for (uint256 _messageIndex; _messageIndex < _messagesLength; ) {
      Message memory _message = messages[_messageIndex];
      _requireContract(_message.to);

      (bool _success, bytes memory _returnData) = _message.to.call(
        abi.encodePacked(_message.data, messageId, fromChainId, from)
      );

      if (!_success) {
        revert MessageBatchFailure(messageId, _messageIndex, _returnData);
      }

      unchecked {
        _messageIndex++;
      }
    }
  }

  /**
   * @notice Check that the call is being made to a contract.
   * @param to Address to check
   */
  function _requireContract(address to) internal view {
    require(to.code.length > 0, "MessageLib/no-contract-at-to");
  }
}