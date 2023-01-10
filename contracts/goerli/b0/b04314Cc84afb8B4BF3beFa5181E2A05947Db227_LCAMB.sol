// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "../../interfaces/IEthereumLightClient.sol";

interface ILCAMB {
    
    enum MessageStatus {
        NEW,
        INVALID,
        FAILED,
        EXECUTED
    }

    event MessageSent(bytes32 indexed messageHash, uint256 indexed nonce, bytes message);
    event MessageExecuted(bytes32 indexed messageHash, uint256 indexed nonce, bytes message, bool success);
    event StorageRootVerified(uint256 indexed slot, bytes32 indexed storageRoot);

    function lightClient() external view returns (IEthereumLightClient);

    function messageId() external view returns (bytes32);

    function messageSender() external view returns (address);

    function sendMessage(
        address receiver, 
        bytes calldata message, 
        uint256 gasLimit
    ) external returns (bytes32);

    function executeMessage(
        uint64 slot, 
        bytes calldata message, 
        bytes32[] calldata stateRootProof, 
        bytes[] calldata accountProof, 
        bytes[] calldata storageProof
    ) external returns (bool);
    
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;
    
import "./libraries/RLPReader.sol";
import "./LCAMBStruct.sol";
import "./libraries/MerkleProofTree.sol";
import "../interfaces/IEthereumLightClient.sol";

contract LCAMB is LCAMBStruct {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    bytes32 internal constant NO_MESSAGE_ID = bytes32(0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
    address internal constant NO_SENDER_ADDRESS = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);

    struct MessageVars {
        bytes32 messageHash;
        bytes32 finalizedExecutionStateRoots;
        bytes32 storageRoot;
        uint256 nonce;
        address sender;
        address receiver;
        uint256 gasLimit;
        bytes   data;
    }


    function setup(address newLightClient, uint256 newGasLimitPerTransaction, address newOtherAMB) public {
        lightClient = IEthereumLightClient(newLightClient);
        gasLimitPerTransaction = newGasLimitPerTransaction;
        otherAMB = newOtherAMB;
        otherAMBHash = keccak256(abi.encodePacked(newOtherAMB));

        messageId = NO_MESSAGE_ID;
        messageSender = NO_SENDER_ADDRESS;
    }

    function sendMessage(
        address receiver, 
        bytes calldata data, 
        uint256 gasLimit
    ) public returns (bytes32) {
        require(gasLimit <= gasLimitPerTransaction, "LCAMB: exceed gas limit");

        bytes memory message = abi.encode(
            nonce,
            msg.sender,
            receiver,
            gasLimit,
            data
        );

        bytes32 messageHash = keccak256(message);
        messages[nonce] = messageHash;

        emit MessageSent(messageHash, nonce++, message);

        return messageHash;
    }

    function executeMessage(
        uint64 slot, 
        bytes calldata message, 
        bytes32[] calldata stateRootsProof, 
        bytes[] calldata accountProof, 
        bytes[] calldata storageProof
    ) external returns (bool success) {
        MessageVars memory vars;
        vars.messageHash = keccak256(message);
        require(messageStatus[vars.messageHash] == MessageStatus.NEW, "LCAMB: message already executed");

        vars.storageRoot = storageRoot[slot];

        if (vars.storageRoot == bytes32(0)) {
            vars.finalizedExecutionStateRoots = lightClient.finalizedExecutionStateRoots(slot);
            require(vars.finalizedExecutionStateRoots != bytes32(0), "LCAMB: stateRoot not found");
            require(accountProof.length > 0, "LCAMB: accountRroof not found");

            {
                uint256 index = 32 + 24;
                index = index * 16 + 2;
                bytes32 executionStateRoot = keccak256(accountProof[0]);
                bytes32 restoredMerkleRoot = MerkleProofTree.restoreMerkleRoot(executionStateRoot, index, stateRootsProof);
                require(vars.finalizedExecutionStateRoots == restoredMerkleRoot, "LCAMB: invalid payload proof");
            }

            {
                bytes memory accountInfo = MerkleProofTree.read(otherAMBHash, accountProof);
                RLPReader.RLPItem[] memory items = accountInfo.toRlpItem().toList();
                require(items.length == 4, "LCAMB: invalid account decoded from RLP");
                vars.storageRoot = bytes32(items[2].toUint());
                storageRoot[slot] = vars.storageRoot;
                emit StorageRootVerified(slot, vars.storageRoot);
            }
        }

        (
            vars.nonce,
            vars.sender,
            vars.receiver,
            vars.gasLimit,
            vars.data
        ) = abi.decode(message, (uint256, address, address, uint256, bytes));

        {
            require(vars.storageRoot == keccak256(storageProof[0]), "LCAMB: invalid storage root");
            bytes32 key = keccak256(abi.encode(keccak256(abi.encode(vars.nonce, 0))));
            bytes memory proof = MerkleProofTree.read(key, storageProof);
            require(bytes32(proof.toRlpItem().toUint()) == vars.messageHash, "LCAMB: invalid message hash");
        }

        {
            require(messageId == NO_MESSAGE_ID, "LCAMB: message execution ongoing");
            messageId = vars.messageHash;
            messageSender = vars.sender;
            require((gasleft() * 63) / 64 > vars.gasLimit + 40000, "LCAMB: insufficient gas");
            (success,) = vars.receiver.call {gas: vars.gasLimit} (vars.data);
            messageId = NO_MESSAGE_ID;
            messageSender = NO_SENDER_ADDRESS;
        }
        messageStatus[vars.messageHash] = success ? MessageStatus.EXECUTED : MessageStatus.FAILED;
        emit MessageExecuted(vars.messageHash, vars.nonce, message, success);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "./interfaces/ILCAMB.sol";
import "../interfaces/IEthereumLightClient.sol";

abstract contract LCAMBStruct is ILCAMB {
    mapping (uint256 => bytes32) public messages;
    mapping (bytes32 => MessageStatus) public messageStatus;
    mapping (uint256 => bytes32) public storageRoot;

    IEthereumLightClient public lightClient;
    
    uint256 public nonce;
    uint256 public gasLimitPerTransaction;

    address public messageSender;
    bytes32 public messageId;

    address public otherAMB;
    bytes32 public otherAMBHash;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.17;

import "./RLPReader.sol";

library MerkleProofTree {
    using RLPReader for RLPReader.RLPItem;
    using RLPReader for bytes;

    function _gnaw(uint256 index, bytes32 key) private pure returns (uint256 gnaw) {
        assembly {
            gnaw := shr(mul(sub(63, index), 4), key)
        }
        return gnaw % 16;
    }

    function _pathLength(bytes memory path) private pure returns (uint256, bool) {
        uint256  gnaw = uint256(uint8(path[0])) / 16;
        return ((path.length - 1) * 2 + gnaw % 2, gnaw > 1);
    }

    function read(bytes32 key, bytes[] memory proof) internal pure returns (bytes memory result) {
        bytes32 root;
        bytes memory node = proof[0];

        uint256 index = 0;
        uint256 pathLength = 0;
        
        while(true) {
            RLPReader.RLPItem[] memory items = node.toRlpItem().toList();
            if (items.length == 17) {
                uint256 gnaw = _gnaw(pathLength++, key);
                root = bytes32(items[gnaw].toUint());
            } else {
                require(items.length == 2, "Invalid RLP list length");
                (uint256 nodePathLength, bool isLeaf) = _pathLength(items[0].toBytes());
                pathLength += nodePathLength;
                if (isLeaf) {
                    return items[1].toBytes();
                } else {
                    root = bytes32(items[1].toUint());
                }
            }

            node = proof[++index];
            require(root == keccak256(node), "Node hash mismatched");
        }
    }

    function restoreMerkleRoot(
        bytes32 leaf,
        uint256 index,
        bytes32[] memory proof
    ) internal pure returns (bytes32) {
        bytes32 value = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            if ((index / (2 ** i)) % 2 == 1) {
                value = sha256(bytes.concat(proof[i], value));
            } else {
                value = sha256(bytes.concat(value, proof[i]));
            }
        }
        return value;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
 * @author Hamdi Allam [email protected]
 * Please reach out with any questions or concerns
 */
pragma solidity >=0.5.10 <0.9.0;

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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.17;

interface IEthereumLightClient {
    function finalizedExecutionStateRoots(uint64 slot) external returns (bytes32);
}