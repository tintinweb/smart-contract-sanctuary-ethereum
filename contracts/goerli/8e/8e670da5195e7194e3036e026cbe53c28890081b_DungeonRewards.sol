/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

// File: default_workspace/contracts/lib/Merkle.sol


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

// File: default_workspace/contracts/lib/RLPReader.sol

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

// File: default_workspace/contracts/lib/ExitPayloadReader.sol

pragma solidity ^0.8.0;


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

// File: default_workspace/contracts/lib/MerklePatriciaProof.sol


pragma solidity ^0.8.0;


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

// File: default_workspace/contracts/tunnel/FxBaseRootTunnel.sol


pragma solidity ^0.8.0;





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

// File: default_workspace/contracts/ERC721.sol


pragma solidity >=0.8.0;

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

// File: default_workspace/contracts/Ownable.sol


pragma solidity ^0.8.10;

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

// File: default_workspace/contracts/tunnel/FxBaseChildTunnel.sol


pragma solidity ^0.8.0;

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
    function setFxRootTunnel(address _fxRootTunnel) external virtual {
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

// File: default_workspace/contracts/ERC20.sol


pragma solidity >=0.8.0;

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

// File: default_workspace/contracts/DNGToken.sol


pragma solidity ^0.8.12;




/**
 ________  ________   ________          _________  ________  ___  __    _______   ________      
|\   ___ \|\   ___  \|\   ____\        |\___   ___\\   __  \|\  \|\  \ |\  ___ \ |\   ___  \    
\ \  \_|\ \ \  \\ \  \ \  \___|        \|___ \  \_\ \  \|\  \ \  \/  /|\ \   __/|\ \  \\ \  \   
 \ \  \ \\ \ \  \\ \  \ \  \  ___           \ \  \ \ \  \\\  \ \   ___  \ \  \_|/_\ \  \\ \  \  
  \ \  \_\\ \ \  \\ \  \ \  \|\  \           \ \  \ \ \  \\\  \ \  \\ \  \ \  \_|\ \ \  \\ \  \ 
   \ \_______\ \__\\ \__\ \_______\           \ \__\ \ \_______\ \__\\ \__\ \_______\ \__\\ \__\
    \|_______|\|__| \|__|\|_______|            \|__|  \|_______|\|__| \|__|\|_______|\|__| \|__|
                                                                                                
**/

enum NftType {
    Dungeon,
    Avatar,
    Quest
}

contract DNGToken is ERC20, FxBaseChildTunnel, Ownable {

    address public childChainManagerProxy;

    struct Rewards {
        uint256 dungeon;
        uint256 avatar;
        uint256 quest;
    }

    Rewards public rewards;

    // staking balances for each NFT type, mapped to holder wallets.
    mapping(address => mapping(uint256 => uint256)) public balances;

    // timestamp when holder last withdrew their rewards.
    mapping(address => uint256) public lastUpdated;

    // feed in the FX Child from FX Portal so we can auto mint on polygon after staking --> https://docs.polygon.technology/docs/develop/l1-l2-communication/fx-portal
    // and setup the child chain address so holders have option to withdraw back to the ETH token
    constructor(address _fxChild, address _childChainManagerProxy)
        FxBaseChildTunnel(_fxChild)
        ERC20("TNT Token", "TNT", 18)
    {
        childChainManagerProxy = _childChainManagerProxy;

        rewards.dungeon = (uint256(10) * 1e18) / 1 days;
        rewards.avatar = (uint256(5) * 1e18) / 1 days;
        rewards.quest = (uint256(3) * 1e18) / 1 days;

        _mint(address(this), 75_000_000 * 1e18);
        uint256 allocation = (35_000_000 + 4_000_000) *
            1e18;
        balanceOf[address(this)] -= allocation;

        unchecked {
            balanceOf[
                0xddd9d4D84a24385545780766cA302d36440ED4Ec
            ] += (35_000_000 * 1e18); // 35,000,000 reserved for p2e rewards
            balanceOf[
                0x887e50815a297822DA63fe892B827fb1A10c87ba
            ] += (4_000_000 * 1e18); // 4,000,000 reserved for team (in-game promotions, partnerships, growth)
        }

        emit Transfer(
            address(this),
            0xddd9d4D84a24385545780766cA302d36440ED4Ec,
            30_000_000 * 1e18
        );
        emit Transfer(
            address(this),
            0x887e50815a297822DA63fe892B827fb1A10c87ba,
            4_000_000 * 1e18
        );
    }

    // childchainmanager - for use with polygon bridge in case we ever want to bridge back to ETH version of token
    function updateChildChainManager(address _childChainManagerProxy) external onlyOwner {
        require(_childChainManagerProxy != address(0), "Bad ChildChainManagerProxy address.");

        childChainManagerProxy = _childChainManagerProxy;
    }
    // for use with polygon bridge
    // https://docs.matic.today/docs/develop/ethereum-matic/submit-mapping-request/    
    function deposit(address user, bytes calldata depositData) external {
        require(msg.sender == childChainManagerProxy, "Address not allowed to deposit.");

        uint256 amount = abi.decode(depositData, (uint256));

        _mint(user, amount);
    }
    // for use with polygon bridge
    function withdraw(uint256 amount) external {
        _burn(msg.sender, amount);
    }
    // end polygon bridge functions


    // updates rewards. $DNG is transferred to the address and the lastUpdated field is updated.
    modifier updateReward(address account) {
        uint256 amount = earned(account);
        balanceOf[address(this)] -= amount;

        // won't overflow: sum of all user balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[account] += amount;
        }

        lastUpdated[account] = block.timestamp;
        emit Transfer(address(this), account, amount);
        _;
    }

    // @param account The address which will be staking.
    // @param tokenType The token type to stake.
    // @param amount The amount to stake.
    // note: any unclaimed rewards are updated when a stake occurs (via updateReward)    
    function processStake(
        address account,
        NftType nftType,
        uint256 amount
    ) internal updateReward(account) {
        balances[account][uint256(nftType)] += amount;
    }

    // @param account The address which will be unstaking.
    // @param tokenType The token type to unstake.
    // @param amount The amount to unstake.
    // note: any unclaimed rewards are updated when an unstake occurs (via updateReward)    
    function processUnstake(
        address account,
        NftType nftType,
        uint256 amount
    ) internal updateReward(account) {
        balances[account][uint256(nftType)] -= amount;
    }

    /**
     * Process message received from FxChild
     * @param stateId unique state id
     * @param sender root message sender
     * @param message bytes message that was sent from Root Tunnel
     */
    function _processMessageFromRoot(
        uint256 stateId,
        address sender,
        bytes memory message
    ) internal override validateSender(sender) {
        (address from, uint256 token, uint256 count, bool action) = abi.decode(
            message,
            (address, uint256, uint256, bool)
        );
        action
            ? processStake(from, NftType(token), count)
            : processUnstake(from, NftType(token), count);
    }

    // Uses EIP-2612 to give our provider wallet permission to transfer the tokens and pay the gas for the wallet
    // encapsulates permit and transfer in a single transaction. Check out DAI token source code for more ideas
    // note: any unclaimed rewards are withdrawn automatically when a gasless purchase is made (via updateReward)
    function purchaseGasless(
        address owner,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public updateReward(owner) {
        permit(owner, msg.sender, value, deadline, v, r, s);
        transferFrom(owner, address(this), value);
    }

    // calculate total rewards accumulated for given wallet address
    // based on when that wallet last withdrew rewards versus current block's timestamp.
    function earned(address account) public view returns (uint256) {
        return
            dngPerSecond(account) * (block.timestamp - lastUpdated[account]);
    }

    // calculates current total balance of the user including unclaimed rewards.
    function totalBalance(address account) public view returns (uint256) {
        return balanceOf[account] + earned(account);
    }

    function dngPerSecond(address account) public view returns (uint256) {
        return ((balances[account][0] * rewards.dungeon) +
            (balances[account][1] * rewards.avatar) +
            (balances[account][2] * rewards.quest));
    }


    // allos the contract owner to burn DNG owned by the contract.
    function burn(uint256 amount) public onlyOwner {
        _burn(address(this), amount);
    }

    // allow the contract owner to airdrop DNG owned by the contract to an array of owners.
    function airdrop(address[] calldata accounts, uint256[] calldata amounts) public onlyOwner {
        require(accounts.length == amounts.length);
        for(uint i = 0; i < accounts.length; i++) {
            uint amount = amounts[i];
            balanceOf[address(this)] -= amount;

        // won't overflow: sum of all user balances can't exceed the max uint256 value.
            unchecked {
                balanceOf[accounts[i]] += amount;
            }

            emit Transfer(address(this), accounts[i], amount);
        }
    }

    // allow the contract owner to mint DNG to the contract.
    function mint(uint256 amount) public onlyOwner {
        _mint(address(this), amount);
    }

    // Withdraw DNG to the requested address.
    // @param recipient The address to withdraw the funds to.
    // @param amount The amount of DNG to withdraw
    function withdrawDng(address recipient, uint256 amount) public onlyOwner {
        balanceOf[address(this)] -= amount;

        // won't overflow: sum of all user balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[recipient] += amount;
        }

        emit Transfer(address(this), recipient, amount);
    }

    // let contract deployer update reward rates for each NFT type.
    function setRewardRates(
        uint256 dungeon,
        uint256 avatar,
        uint256 quest
    ) public onlyOwner {
        rewards.dungeon = dungeon;
        rewards.avatar = avatar;
        rewards.quest = quest;
    }

    function updateFxRootRunnel(address _fxRootTunnel) external onlyOwner {
        fxRootTunnel = _fxRootTunnel;
    }


    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x < y ? x : y;
    }
}

// File: default_workspace/contracts/DungeonRewards.sol


pragma solidity ^0.8.12;





/**
 ________  ___  ___  ________   ________  _______   ________  ________          
|\   ___ \|\  \|\  \|\   ___  \|\   ____\|\  ___ \ |\   __  \|\   ___  \        
\ \  \_|\ \ \  \\\  \ \  \\ \  \ \  \___|\ \   __/|\ \  \|\  \ \  \\ \  \       
 \ \  \ \\ \ \  \\\  \ \  \\ \  \ \  \  __\ \  \_|/_\ \  \\\  \ \  \\ \  \      
  \ \  \_\\ \ \  \\\  \ \  \\ \  \ \  \|\  \ \  \_|\ \ \  \\\  \ \  \\ \  \     
   \ \_______\ \_______\ \__\\ \__\ \_______\ \_______\ \_______\ \__\\ \__\    
    \|_______|\|_______|\|__| \|__|\|_______|\|_______|\|_______|\|__| \|__|    
                                                                                
                                                                                
                                                                                
 ________  _______   ___       __   ________  ________  ________  ________      
|\   __  \|\  ___ \ |\  \     |\  \|\   __  \|\   __  \|\   ___ \|\   ____\     
\ \  \|\  \ \   __/|\ \  \    \ \  \ \  \|\  \ \  \|\  \ \  \_|\ \ \  \___|_    
 \ \   _  _\ \  \_|/_\ \  \  __\ \  \ \   __  \ \   _  _\ \  \ \\ \ \_____  \   
  \ \  \\  \\ \  \_|\ \ \  \|\__\_\  \ \  \ \  \ \  \\  \\ \  \_\\ \|____|\  \  
   \ \__\\ _\\ \_______\ \____________\ \__\ \__\ \__\\ _\\ \_______\____\_\  \ 
    \|__|\|__|\|_______|\|____________|\|__|\|__|\|__|\|__|\|_______|\_________\
                                                                    \|_________|
                                                                                
**/

contract DungeonRewards is FxBaseRootTunnel, Ownable {
    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    ERC721 public dungeonContract;
    ERC721 public avatarContract;
    ERC721 public questContract;

    struct Staker {
        uint256[] stakedDungeons;
        uint256 dungeonStakedOn;     // timestamp of when holder first staked their dungeon(s) (used to calculated eligibility for avatars).
        uint256[] stakedAvatars;
        uint256 avatarStakedOn;     // timestamp of when holder first staked their avatar(s)
        uint256[] stakedQuests;
        uint256 questStakedOn;     // timestamp of when holder first staked their quest(s)
    }

    mapping(address => Staker) public userInfo;

    bool public stakingPaused;

    constructor(
        address checkpointManager,
        address fxRoot,
        address _dungeonContract
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        dungeonContract = ERC721(_dungeonContract);
    }

    // @notice Set the contract addresses for all future instances.
    function setContractAddresses(
        address _avatarContract,
        address _questContract
    ) public onlyOwner {
        avatarContract = ERC721(_avatarContract);
        questContract = ERC721(_questContract);
    }

    // Pause staking and unstaking
    function setStakingPaused(bool paused) public onlyOwner {
        stakingPaused = paused;
    }


    // For collab.land to give a role based on staking status
    function balanceOf(address owner) public view returns (uint256) {
        if(balanceOfDungeons(owner)>0 && balanceOfAvatars(owner)>0 && balanceOfQuests(owner)>0) return 3;
        if(balanceOfDungeons(owner)>0 && balanceOfAvatars(owner)>0 && balanceOfQuests(owner)==0) return 2;
        if(balanceOfDungeons(owner)>0 && balanceOfAvatars(owner)==0 && balanceOfQuests(owner)==0) return 1;
        return 0;
    }

    // so we can confirm whether a wallet holds any staked dungeons, useful for Generative Avatars gas-only mint
    function balanceOfDungeons(address owner) public view returns (uint256) {
        return userInfo[owner].stakedDungeons.length;
    }
    // so we can confirm when a wallet staked their dungeons, useful for Generative Avatars gas-only mint
    function dungeonFirstStaked(address owner) public view returns (uint256) {
        return userInfo[owner].dungeonStakedOn;
    }

    function balanceOfAvatars(address owner) public view returns (uint256) {
        return userInfo[owner].stakedAvatars.length;
    }
    function avatarFirstStaked(address owner) public view returns (uint256) {
        return userInfo[owner].avatarStakedOn;
    }

    function balanceOfQuests(address owner) public view returns (uint256) {
        return userInfo[owner].stakedQuests.length;
    }
    function questFirstStaked(address owner) public view returns (uint256) {
        return userInfo[owner].questStakedOn;
    }


    // get staked tokens for address
    function getStakedTokens(address user)
        public
        view
        returns (
            uint256[] memory dungeons,
            uint256[] memory avatars,
            uint256[] memory quests
        )
    {
        Staker memory staker = userInfo[user];
        return (
            staker.stakedDungeons,
            staker.stakedAvatars,
            staker.stakedQuests
        );
    }

    function bulkStake(
        uint256[] memory dungeons,
        uint256[] memory avatars,
        uint256[] memory quests
    ) public {
        if (dungeons.length > 0) stakeMultipleDungeons(dungeons);
        if (avatars.length > 0) stakeMultipleAvatars(avatars);
        if (quests.length > 0) stakeMultipleQuests(quests);        
    }

    function bulkUnstake(
        uint256[] memory dungeons,
        uint256[] memory avatars,
        uint256[] memory quests
    ) public {
        if (dungeons.length > 0) unstakeMultipleDungeons(dungeons);
        if (avatars.length > 0) unstakeMultipleAvatars(avatars);
        if (quests.length > 0) unstakeMultipleQuests(quests);        
    }

    function stakeMultipleDungeons(uint256[] memory tokenIds) public {
        require(!stakingPaused, "Staking currently paused.");
        require(tokenIds.length>0, "No tokenIds provided.");

        Staker storage staker = userInfo[msg.sender];

        if (staker.dungeonStakedOn == 0) { // set our dungeon staked on once (if they unstake, it resets to zero and will be reset when they stake again)
            staker.dungeonStakedOn = block.timestamp; 
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            staker.stakedDungeons.push(tokenIds[i]);
            dungeonContract.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }
        // start accumulating $DNG rewards on polygon
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Dungeon),
                tokenIds.length,
                true
            )
        );
    }

    function unstakeMultipleDungeons(uint256[] memory tokenIds) public {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(containsElement(staker.stakedDungeons, tokenId), "Not dungeon owner.");
            dungeonContract.transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
            removeDungeonFromStaker(staker, tokenId);
        }

        if (staker.stakedDungeons.length == 0) { // no more staked dungeons? 
            staker.dungeonStakedOn = 0; // then we reset the staked on date to 0 (so can be set to block.timestamp when it's staked again)
        }
        // stop accumulating $DNG rewards on polygon for these dungeons
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Dungeon),
                tokenIds.length,
                false
            )
        );
    }

    // Stake a single Dungeon (separate function to optimize for gas)
    // @param tokenId The tokenId of the dungeon to stake
    function stakeDungeon(uint256 tokenId) external {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        staker.stakedDungeons.push(tokenId);
        dungeonContract.transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        if (staker.dungeonStakedOn == 0) { // set our dungeon staked on once (if they unstake, it resets to zero and will be reset when they stake again)
            staker.dungeonStakedOn = block.timestamp; 
        }
        // start accumulating $DNG rewards on polygon
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Dungeon),
                1,
                true
            )
        );
    }

    // Unstake a Dungeon
    // @param tokenId The tokenId of the dungeon to unstake
    function unstakeDungeon(uint256 tokenId) external {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        require(containsElement(staker.stakedDungeons, tokenId), "Not dungeon owner.");

        dungeonContract.transferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        removeDungeonFromStaker(staker, tokenId);

        if (staker.stakedDungeons.length == 0) { // no more staked dungeons? 
            staker.dungeonStakedOn = 0; // then we reset the staked on date to 0 (so can be set to block.timestamp when it's staked again)
        }

        // stop accumulating $DNG rewards on polygon for these dungeons
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Dungeon),
                1,
                false
            )
        );

    }

    function stakeMultipleAvatars(uint256[] memory tokenIds) public {
        require(!stakingPaused, "Staking currently paused.");
        require(tokenIds.length>0, "No tokenIds provided.");

        Staker storage staker = userInfo[msg.sender];

        if (staker.avatarStakedOn == 0) { // set our avatar staked on once (if they unstake, it resets to zero and will be reset when they stake again)
            staker.avatarStakedOn = block.timestamp; 
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            staker.stakedAvatars.push(tokenIds[i]);
            avatarContract.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }
        // start accumulating $DNG rewards on polygon
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Avatar),
                tokenIds.length,
                true
            )
        );
    }

    function unstakeMultipleAvatars(uint256[] memory tokenIds) public {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(containsElement(staker.stakedAvatars, tokenId), "Not avatar owner.");
            avatarContract.transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
            removeAvatarFromStaker(staker, tokenId);
        }

        if (staker.stakedAvatars.length == 0) { // no more staked avatars? 
            staker.avatarStakedOn = 0; // then we reset the staked on date to 0 (so can be set to block.timestamp when it's staked again)
        }
        // stop accumulating $DNG rewards on polygon for these avatars
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Avatar),
                tokenIds.length,
                false
            )
        );
    }

    // Stake a single Avatar (separate function to optimize for gas)
    // @param tokenId The tokenId of the avatar to stake
    function stakeAvatar(uint256 tokenId) external {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        staker.stakedAvatars.push(tokenId);
        avatarContract.transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        if (staker.avatarStakedOn == 0) { // set our avatar staked on once (if they unstake, it resets to zero and will be reset when they stake again)
            staker.avatarStakedOn = block.timestamp; 
        }
        // start accumulating $DNG rewards on polygon
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Avatar),
                1,
                true
            )
        );
    }

    // Unstake a Avatar
    // @param tokenId The tokenId of the avatar to unstake
    function unstakeAvatar(uint256 tokenId) external {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        require(containsElement(staker.stakedAvatars, tokenId), "Not avatar owner.");

        avatarContract.transferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        removeAvatarFromStaker(staker, tokenId);

        if (staker.stakedAvatars.length == 0) { // no more staked avatars? 
            staker.avatarStakedOn = 0; // then we reset the staked on date to 0 (so can be set to block.timestamp when it's staked again)
        }

        // stop accumulating $DNG rewards on polygon for these avatars
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Avatar),
                1,
                false
            )
        );

    }


    function stakeMultipleQuests(uint256[] memory tokenIds) public {
        require(!stakingPaused, "Staking currently paused.");
        require(tokenIds.length>0, "No tokenIds provided.");

        Staker storage staker = userInfo[msg.sender];

        if (staker.questStakedOn == 0) { // set our quest staked on once (if they unstake, it resets to zero and will be reset when they stake again)
            staker.questStakedOn = block.timestamp; 
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            staker.stakedQuests.push(tokenIds[i]);
            questContract.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }
        // start accumulating $DNG rewards on polygon
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Quest),
                tokenIds.length,
                true
            )
        );
    }

    function unstakeMultipleQuests(uint256[] memory tokenIds) public {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(containsElement(staker.stakedQuests, tokenId), "Not quest owner.");
            questContract.transferFrom(
                address(this),
                msg.sender,
                tokenId
            );
            removeQuestFromStaker(staker, tokenId);
        }

        if (staker.stakedQuests.length == 0) { // no more staked quests? 
            staker.questStakedOn = 0; // then we reset the staked on date to 0 (so can be set to block.timestamp when it's staked again)
        }
        // stop accumulating $DNG rewards on polygon for these quests
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Quest),
                tokenIds.length,
                false
            )
        );
    }

    // Stake a single Quest (separate function to optimize for gas)
    // @param tokenId The tokenId of the quest to stake
    function stakeQuest(uint256 tokenId) external {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        staker.stakedQuests.push(tokenId);
        questContract.transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        if (staker.questStakedOn == 0) { // set our quest staked on once (if they unstake, it resets to zero and will be reset when they stake again)
            staker.questStakedOn = block.timestamp; 
        }

        // start accumulating $DNG rewards on polygon
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Quest),
                1,
                true
            )
        );
    }

    // Unstake a Quest
    // @param tokenId The tokenId of the quest to unstake
    function unstakeQuest(uint256 tokenId) external {
        require(!stakingPaused, "Staking is currently paused.");
        Staker storage staker = userInfo[msg.sender];
        require(containsElement(staker.stakedQuests, tokenId), "Not quest owner.");

        questContract.transferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        removeQuestFromStaker(staker, tokenId);

        if (staker.stakedQuests.length == 0) { // no more staked quests? 
            staker.questStakedOn = 0; // then we reset the staked on date to 0 (so can be set to block.timestamp when it's staked again)
        }

        // stop accumulating $DNG rewards on polygon for these quests
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(NftType.Quest),
                1,
                false
            )
        );

    }

    function removeDungeonFromStaker(Staker storage staker, uint256 tokenId) private {
        uint256[] memory stakedDungeons = staker.stakedDungeons;
        uint256 index;
        for (uint256 j; j < stakedDungeons.length; j++) {
            if (stakedDungeons[j] == tokenId) index = j;
        }
        if (stakedDungeons[index] == tokenId) {
            staker.stakedDungeons[index] = stakedDungeons[
                staker.stakedDungeons.length - 1
            ];
            staker.stakedDungeons.pop();
        }
    }

    function removeAvatarFromStaker(Staker storage staker, uint256 tokenId) private {
        uint256[] memory stakedAvatars = staker.stakedAvatars;
        uint256 index;
        for (uint256 j; j < stakedAvatars.length; j++) {
            if (stakedAvatars[j] == tokenId) index = j;
        }
        if (stakedAvatars[index] == tokenId) {
            staker.stakedAvatars[index] = stakedAvatars[
                staker.stakedAvatars.length - 1
            ];
            staker.stakedAvatars.pop();
        }
    }

    function removeQuestFromStaker(Staker storage staker, uint256 tokenId) private {
        uint256[] memory stakedQuests = staker.stakedQuests;
        uint256 index;
        for (uint256 j; j < stakedQuests.length; j++) {
            if (stakedQuests[j] == tokenId) index = j;
        }
        if (stakedQuests[index] == tokenId) {
            staker.stakedQuests[index] = stakedQuests[
                staker.stakedQuests.length - 1
            ];
            staker.stakedQuests.pop();
        }
    }

    function _processMessageFromChild(bytes memory message) internal override {
        // we don't process any messages from the child chain (Polygon)
    }

    function containsElement(uint[] memory elements, uint tokenId) internal pure returns (bool) {
        for (uint256 i = 0; i < elements.length; i++) {
           if(elements[i] == tokenId) return true;
        }
        return false;
    }


    /**
     * Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external pure returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

}