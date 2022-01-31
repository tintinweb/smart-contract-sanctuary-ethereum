/**
 *Submitted for verification at Etherscan.io on 2022-01-27
*/

// hevm: flattened sources of src/LlamaZoo.sol
// SPDX-License-Identifier: MIT AND AGPL-3.0-only AND Unlicense
pragma solidity >=0.8.0 >=0.8.10 >=0.8.0 <0.9.0 >=0.8.10 <0.9.0;

////// lib/fx-portal/src/lib/RLPReader.sol
/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
/* pragma solidity ^0.8.0; */

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

    // any non-zero byte is considered true
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

            // shfit to the correct location if neccesary
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

////// lib/fx-portal/src/lib/ExitPayloadReader.sol
/* pragma solidity ^0.8.0; */

/* import {RLPReader} from "./RLPReader.sol"; */

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
            // pop first byte before parsting receipt
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

////// lib/fx-portal/src/lib/Merkle.sol
/* pragma solidity ^0.8.0; */

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

////// lib/fx-portal/src/lib/MerklePatriciaProof.sol
/* pragma solidity ^0.8.0; */

/* import {RLPReader} from "./RLPReader.sol"; */

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

////// lib/fx-portal/src/tunnel/FXBaseChildTunnel.sol
/* pragma solidity ^0.8.0; */

// IFxMessageProcessor represents interface to process message
interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

/**
 * @notice Mock child tunnel contract to receive and send message from L2
 */
abstract contract FxBaseChildTunnel is IFxMessageProcessor {
    // MessageTunnel on L1 will get data from this event
    event MessageSent(bytes message);

    // fx child
    address public fxChild;

    // fx root tunnel
    address public fxRootTunnel;

    constructor(address _fxChild) {
        fxChild = _fxChild;
    }

    // Sender must be fxRootTunnel in case of ERC20 tunnel
    modifier validateSender(address sender) {
        require(sender == fxRootTunnel, "FxBaseChildTunnel: INVALID_SENDER_FROM_ROOT");
        _;
    }

    // set fxRootTunnel if not set already
    function setFxRootTunnel(address _fxRootTunnel) external {
        require(fxRootTunnel == address(0x0), "FxBaseChildTunnel: ROOT_TUNNEL_ALREADY_SET");
        fxRootTunnel = _fxRootTunnel;
    }

    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external override {
        require(msg.sender == fxChild, "FxBaseChildTunnel: INVALID_SENDER");
        _processMessageFromRoot(stateId, rootMessageSender, data);
    }

    /**
     * @notice Emit message that can be received on Root Tunnel
     * @dev Call the internal function when need to emit message
     * @param message bytes message that will be sent to Root Tunnel
     * some message examples -
     *   abi.encode(tokenId);
     *   abi.encode(tokenId, tokenMetadata);
     *   abi.encode(messageType, messageData);
     */
    function _sendMessageToRoot(bytes memory message) internal {
        emit MessageSent(message);
    }

    /**
     * @notice Process message received from Root Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal virtual;
}

////// lib/fx-portal/src/tunnel/FXBaseRootTunnel.sol
/* pragma solidity ^0.8.0; */

/* import {RLPReader} from "../lib/RLPReader.sol"; */
/* import {MerklePatriciaProof} from "../lib/MerklePatriciaProof.sol"; */
/* import {Merkle} from "../lib/Merkle.sol"; */
/* import "../lib/ExitPayloadReader.sol"; */

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
    function setFxChildTunnel(address _fxChildTunnel) public {
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
    ) private view returns (uint256) {
        (bytes32 headerRoot, uint256 startBlock, , uint256 createdAt, ) = checkpointManager.headerBlocks(headerNumber);

        require(
            keccak256(abi.encodePacked(blockNumber, blockTime, txRoot, receiptRoot)).checkMembership(
                blockNumber - startBlock,
                headerRoot,
                blockProof
            ),
            "FxRootTunnel: INVALID_HEADER"
        );
        return createdAt;
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
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function _processMessageFromChild(bytes memory message) internal virtual;
}

////// lib/solmate/src/tokens/ERC1155.sol
/* pragma solidity >=0.8.0; */

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*///////////////////////////////////////////////////////////////
                            ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                             ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver_1(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver_1.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        for (uint256 i = 0; i < idsLength; ) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver_1(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver_1.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] memory owners, uint256[] memory ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        uint256 ownersLength = owners.length; // Saves MLOADs.

        require(ownersLength == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < ownersLength; i++) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*///////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver_1(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver_1.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver_1(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver_1.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                i++;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC1155.sol)
interface ERC1155TokenReceiver_1 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4);
}

////// lib/solmate/src/tokens/ERC20.sol
/* pragma solidity >=0.8.0; */

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

////// lib/solmate/src/tokens/ERC721.sol
/* pragma solidity >=0.8.0; */

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            totalSupply++;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            totalSupply--;

            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

////// src/Ownable.sol
/* pragma solidity ^0.8.10; */

error NotOwner();

// https://github.com/m1guelpf/erc721-drop/blob/main/src/LilOwnable.sol
abstract contract Ownable {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    modifier onlyOwner() {
        require(_owner == msg.sender);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function owner() external view returns (address) {
        return _owner;
    }

    function transferOwnership(address _newOwner) external {
        if (msg.sender != _owner) revert NotOwner();

        _owner = _newOwner;
    }

    function renounceOwnership() public {
        if (msg.sender != _owner) revert NotOwner();

        _owner = address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        returns (bool)
    {
        return interfaceId == 0x7f5828d0; // ERC165 Interface ID for ERC173
    }
}

////// src/SpitToken.sol
/* pragma solidity ^0.8.10; */

/* import "../lib/solmate/src/tokens/ERC20.sol"; */
/* import "../lib/fx-portal/src/tunnel/FXBaseChildTunnel.sol"; */
/* import "./Ownable.sol"; */

/**
   __ _                                               
  / /| | __ _ _ __ ___   __ _/\   /\___ _ __ ___  ___ 
 / / | |/ _` | '_ ` _ \ / _` \ \ / / _ \ '__/ __|/ _ \
/ /__| | (_| | | | | | | (_| |\ V /  __/ |  \__ \  __/
\____/_|\__,_|_| |_| |_|\__,_| \_/ \___|_|  |___/\___|

**/

enum TokenType {
    StaticLlama,
    AnimatedLlama,
    SilverBoost,
    GoldBoost,
    PixletCanvas,
    LlamaDraws
} 

contract SpitToken is ERC20, FxBaseChildTunnel, Ownable {
    uint private allocatedStakingSupply;
    
    uint public lastUpdateTime;

    struct Rewards {
        uint staticLlama;
        uint animatedLlama;
        uint silverEnergy;
        uint goldEnergy;
        uint pixletCanvas;
        uint llamaDraws;
    }
 
    Rewards public rewards;

    mapping(address => mapping(uint256 => uint256)) balances;
    mapping(address => uint256) public lastUpdated;

    constructor(address _fxChild) FxBaseChildTunnel(_fxChild) ERC20("Spit Token", "SPIT", 18) {
        lastUpdateTime = block.timestamp;
        rewards.staticLlama = (uint(100) * 1e18) / 1 days;
        rewards.animatedLlama = (uint(200) * 1e18) / 1 days;
        rewards.silverEnergy = (uint(10) * 1e18) / 1 days;
        rewards.goldEnergy = (uint(20) * 1e18) / 1 days;
        rewards.llamaDraws = (uint(5) * 1e18) / 1 days;
        rewards.pixletCanvas = (uint(5) * 1e18) / 1 days;
    }

    function setRewardRates(
        uint staticLlama,
        uint animatedLlama,
        uint silverEnergy,
        uint goldEnergy,
        uint pixletCanvas,
        uint llamaDraws
    ) public onlyOwner {
        rewards.staticLlama = staticLlama;
        rewards.animatedLlama = animatedLlama;
        rewards.silverEnergy = silverEnergy;
        rewards.goldEnergy = goldEnergy;
        rewards.pixletCanvas = pixletCanvas;
        rewards.llamaDraws = llamaDraws;
    }


    function earned(address account) public view returns (uint) {
        return (
            (balances[account][0] * rewards.staticLlama)+
            (balances[account][1] * rewards.animatedLlama)+ 
            (min(balances[account][2], balances[account][0]) * rewards.silverEnergy)+
            (min(balances[account][3], balances[account][1]) * rewards.goldEnergy)+
            (balances[account][4] * rewards.pixletCanvas) +
            (balances[account][5] * rewards.llamaDraws)
        ) * (
            block.timestamp - lastUpdated[account]
        );
    }

    modifier updateReward(address account) {
        _mint(account, earned(account));
        lastUpdated[account] = block.timestamp;
        _;
    }

    function withdrawalSpit(address recipient) public onlyOwner {
        transfer(recipient, balanceOf[address(this)]);
    }

    function initialAllocation() internal {
        // TODO
    }

    function mockProcessStake(address account, TokenType tokenType, uint amount) public updateReward(account) {
        processStake(account, tokenType, amount);
    }

    function mockProcessUnstake(address account, TokenType tokenType, uint amount) public updateReward(account) {
        processUnstake(account, tokenType, amount);
    }

    function processStake(address account, TokenType tokenType, uint amount) internal updateReward(account) {
        balances[account][uint(tokenType)] += amount;
    }

    function processUnstake(address account, TokenType tokenType, uint amount) internal updateReward(account) {
        balances[account][uint(tokenType)] -= amount;
    }

    function getBalance(address account) public updateReward(account) returns (uint) {
        return balanceOf[account];
    }

    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override validateSender(msg.sender) {
        (address from, uint256 token, uint256 count, bool action) = abi.decode(message, (address, uint256, uint256, bool));
        action ? processStake(from, TokenType(token), count) : processUnstake(from, TokenType(token), count);
    }

    function process(uint256 stateId, address sender, bytes memory message) external  {
        _processMessageFromRoot(stateId, sender, message);
    }

    function min(uint x, uint y) public pure returns (uint) {
        if (x <= y) {
            return x;
        }
        return y;
    }
}

////// src/LlamaZoo.sol
/* pragma solidity >=0.8.10; */


/* import "../lib/solmate/src/tokens/ERC1155.sol"; */
/* import "./SpitToken.sol"; */
/* import "../lib/solmate/src/tokens/ERC721.sol"; */
/* import "../lib/fx-portal/src/tunnel/FXBaseRootTunnel.sol"; */
/* import "./Ownable.sol"; */


contract LlamaZoo is FxBaseRootTunnel, Ownable {
    ERC721 public pixellatedLlamaContract;
    ERC721 public llamaDrawsContract;
    ERC1155 public boostContract;
    ERC1155 public pixletContract;

    // TODO: Use one uint256 to hold all balances
    mapping(address => uint256) public stakedStaticLlamas;
    mapping(address => uint256) public stakedAnimatedLlamas;
    mapping(address => uint256) public stakedSilverBoosts;
    mapping(address => uint256) public stakedGoldBoosts;

    mapping(address => uint256) public stakedPixletCanvas;
    mapping(address => uint256) public stakedLlamaDraws;

    mapping(uint => address) public llamaOwners;
    mapping(uint => address) public llamaDrawsOwners;


    constructor(
        address checkpointManager,
        address fxRoot,
        address _pixellatedLlamaContract,
        address _llamaDrawsContract,
        address _boostContract,
        address _pixletContract
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        pixellatedLlamaContract = ERC721(_pixellatedLlamaContract);
        llamaDrawsContract = ERC721(_llamaDrawsContract);
        boostContract = ERC1155(_boostContract);
        pixletContract = ERC1155(_pixletContract);
    }

    function setContractAddresses(
        address _pixellatedLlamaContract,
        address _llamaDrawsContract,
        address _boostContract,
        address _pixletContract
    ) public onlyOwner {
        pixellatedLlamaContract = ERC721(_pixellatedLlamaContract);
        llamaDrawsContract = ERC721(_llamaDrawsContract);
        boostContract = ERC1155(_boostContract);
        pixletContract = ERC1155(_pixletContract);
    }

    function stakeStaticLlama(uint tokenId) external {
        stakedStaticLlamas[msg.sender] += 1;
        llamaOwners[tokenId] = msg.sender;
        pixellatedLlamaContract.transferFrom(msg.sender, address(this), tokenId);
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.StaticLlama), 1, true));
    }

    function unstakeStaticLlama(uint tokenId) external {
        require(llamaOwners[tokenId] == msg.sender, "You do not own this tokenId.");
        delete llamaOwners[tokenId];

        stakedStaticLlamas[msg.sender] -= 1;
        pixellatedLlamaContract.transferFrom(address(this), msg.sender, tokenId);
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.StaticLlama), 1, false));
    }

    function stakeAnimatedLlama(uint tokenId) external {
        stakedAnimatedLlamas[msg.sender] += 1;
        llamaOwners[tokenId] = msg.sender;
        pixellatedLlamaContract.transferFrom(msg.sender, address(this), tokenId);
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.AnimatedLlama), 1, true));
    }

    function unstakeAnimatedLlama(uint tokenId) external {
        require(llamaOwners[tokenId] == msg.sender, "You do not own this tokenId.");
        delete llamaOwners[tokenId];

        stakedAnimatedLlamas[msg.sender] -= 1;
        pixellatedLlamaContract.transferFrom(address(this), msg.sender, tokenId);
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.AnimatedLlama), 1, false));
    }

    function stakeSilverBoosts(uint amount) external {
        stakedSilverBoosts[msg.sender] += amount;
        boostContract.safeTransferFrom(msg.sender, address(this), 1, amount, "");
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.SilverBoost), amount, true));
    }

    function unstakeSilverBoosts(uint amount) external {
        stakedSilverBoosts[msg.sender] -= amount;
        boostContract.safeTransferFrom(address(this), msg.sender, 1, amount, "");
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.SilverBoost), amount, false));
    }

    function stakeGoldBoosts(uint amount) external {
        stakedGoldBoosts[msg.sender] += amount;
        boostContract.safeTransferFrom(msg.sender, address(this), 2, amount, "");
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.GoldBoost), amount, true));
    }

    function unstakeGoldBoosts(uint amount) external {
        stakedGoldBoosts[msg.sender] -= amount;
        boostContract.safeTransferFrom(address(this), msg.sender, 2, amount, "");
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.GoldBoost), amount, false));
    }

    function stakePixletCanvas(uint tokenId) external {
        require(stakedPixletCanvas[msg.sender] == 0, "You already have a pixlet canvas staked.");
        stakedPixletCanvas[msg.sender] = tokenId;
        pixletContract.safeTransferFrom(msg.sender, address(this), tokenId, 1, "");
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.PixletCanvas), 1, true));
    }

    function unstakePixletCanvas() external {
        require(stakedPixletCanvas[msg.sender] != 0, "You do not have a pixlet canvas staked.");
        pixletContract.safeTransferFrom(address(this), msg.sender, stakedPixletCanvas[msg.sender], 1, "");

        delete stakedPixletCanvas[msg.sender];
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.PixletCanvas), 1, false));
    }

    function stakeLlamaDraws(uint tokenId) external {
        require(stakedLlamaDraws[msg.sender] == 0, "You already have a llamadraws staked.");
        stakedLlamaDraws[msg.sender] = tokenId;
        llamaDrawsContract.transferFrom(msg.sender, address(this), tokenId);
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.LlamaDraws), 1, true));
    }

    function unstakeLlamaDraws() external {
        require(stakedLlamaDraws[msg.sender] != 0, "You do not have a llamadraws staked.");
        llamaDrawsContract.transferFrom(address(this), msg.sender, stakedLlamaDraws[msg.sender]);

        delete stakedLlamaDraws[msg.sender];
        _sendMessageToChild(abi.encode(msg.sender, uint(TokenType.LlamaDraws), 1, false));
    }

    function _processMessageFromChild(bytes memory message) internal override {
        // We don't need a message from child
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        return ERC1155TokenReceiver_1.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4) {
        return ERC1155TokenReceiver_1.onERC1155BatchReceived.selector;
    }
}