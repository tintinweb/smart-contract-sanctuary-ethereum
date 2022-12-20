// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { Lib_OVMCodec } from "../../libraries/codec/Lib_OVMCodec.sol";

/* Interface Imports */
import { ICrossDomainMessenger } from "../../libraries/bridge/ICrossDomainMessenger.sol";

/**
 * @title IL1CrossDomainMessenger
 */
interface IL1CrossDomainMessenger is ICrossDomainMessenger {
    /*******************
     * Data Structures *
     *******************/

    struct L2MessageInclusionProof {
        bytes32 stateRoot;
        Lib_OVMCodec.ChainBatchHeader stateRootBatchHeader;
        Lib_OVMCodec.ChainInclusionProof stateRootProof;
        bytes stateTrieWitness;
        bytes storageTrieWitness;
    }

    /********************
     * Public Functions *
     ********************/

    /**
     * Relays a cross domain message to a contract.
     * @param _target Target contract address.
     * @param _sender Message sender address.
     * @param _message Message to send to the target.
     * @param _messageNonce Nonce for the provided message.
     * @param _proof Inclusion proof for the given message.
     */
    function relayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _messageNonce,
        L2MessageInclusionProof memory _proof
    ) external;

    /**
     * Replays a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _sender Original sender address.
     * @param _message Message to send to the target.
     * @param _queueIndex CTC Queue index for the message to replay.
     * @param _oldGasLimit Original gas limit used to send the message.
     * @param _newGasLimit New gas limit to be used for this message.
     */
    function replayMessage(
        address _target,
        address _sender,
        bytes memory _message,
        uint256 _queueIndex,
        uint32 _oldGasLimit,
        uint32 _newGasLimit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.9.0;

/**
 * @title ICrossDomainMessenger
 */
interface ICrossDomainMessenger {
    /**********
     * Events *
     **********/

    event SentMessage(
        address indexed target,
        address sender,
        bytes message,
        uint256 messageNonce,
        uint256 gasLimit
    );
    event RelayedMessage(bytes32 indexed msgHash);
    event FailedRelayedMessage(bytes32 indexed msgHash);

    /*************
     * Variables *
     *************/

    function xDomainMessageSender() external view returns (address);

    /********************
     * Public Functions *
     ********************/

    /**
     * Sends a cross domain message to the target messenger.
     * @param _target Target contract address.
     * @param _message Message to send to the target.
     * @param _gasLimit Gas limit for the provided message.
     */
    function sendMessage(
        address _target,
        bytes calldata _message,
        uint32 _gasLimit
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/* Library Imports */
import { Lib_RLPReader } from "../rlp/Lib_RLPReader.sol";
import { Lib_RLPWriter } from "../rlp/Lib_RLPWriter.sol";
import { Lib_BytesUtils } from "../utils/Lib_BytesUtils.sol";
import { Lib_Bytes32Utils } from "../utils/Lib_Bytes32Utils.sol";

/**
 * @title Lib_OVMCodec
 */
library Lib_OVMCodec {
    /*********
     * Enums *
     *********/

    enum QueueOrigin {
        SEQUENCER_QUEUE,
        L1TOL2_QUEUE
    }

    /***********
     * Structs *
     ***********/

    struct EVMAccount {
        uint256 nonce;
        uint256 balance;
        bytes32 storageRoot;
        bytes32 codeHash;
    }

    struct ChainBatchHeader {
        uint256 batchIndex;
        bytes32 batchRoot;
        uint256 batchSize;
        uint256 prevTotalElements;
        bytes extraData;
    }

    struct ChainInclusionProof {
        uint256 index;
        bytes32[] siblings;
    }

    struct Transaction {
        uint256 timestamp;
        uint256 blockNumber;
        QueueOrigin l1QueueOrigin;
        address l1TxOrigin;
        address entrypoint;
        uint256 gasLimit;
        bytes data;
    }

    struct TransactionChainElement {
        bool isSequenced;
        uint256 queueIndex; // QUEUED TX ONLY
        uint256 timestamp; // SEQUENCER TX ONLY
        uint256 blockNumber; // SEQUENCER TX ONLY
        bytes txData; // SEQUENCER TX ONLY
    }

    struct QueueElement {
        bytes32 transactionHash;
        uint40 timestamp;
        uint40 blockNumber;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Encodes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return Encoded transaction bytes.
     */
    function encodeTransaction(Transaction memory _transaction)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                _transaction.timestamp,
                _transaction.blockNumber,
                _transaction.l1QueueOrigin,
                _transaction.l1TxOrigin,
                _transaction.entrypoint,
                _transaction.gasLimit,
                _transaction.data
            );
    }

    /**
     * Hashes a standard OVM transaction.
     * @param _transaction OVM transaction to encode.
     * @return Hashed transaction
     */
    function hashTransaction(Transaction memory _transaction) internal pure returns (bytes32) {
        return keccak256(encodeTransaction(_transaction));
    }

    /**
     * @notice Decodes an RLP-encoded account state into a useful struct.
     * @param _encoded RLP-encoded account state.
     * @return Account state struct.
     */
    function decodeEVMAccount(bytes memory _encoded) internal pure returns (EVMAccount memory) {
        Lib_RLPReader.RLPItem[] memory accountState = Lib_RLPReader.readList(_encoded);

        return
            EVMAccount({
                nonce: Lib_RLPReader.readUint256(accountState[0]),
                balance: Lib_RLPReader.readUint256(accountState[1]),
                storageRoot: Lib_RLPReader.readBytes32(accountState[2]),
                codeHash: Lib_RLPReader.readBytes32(accountState[3])
            });
    }

    /**
     * Calculates a hash for a given batch header.
     * @param _batchHeader Header to hash.
     * @return Hash of the header.
     */
    function hashBatchHeader(Lib_OVMCodec.ChainBatchHeader memory _batchHeader)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    _batchHeader.batchRoot,
                    _batchHeader.batchSize,
                    _batchHeader.prevTotalElements,
                    _batchHeader.extraData
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_RLPReader
 * @dev Adapted from "RLPReader" by Hamdi Allam ([email protected]).
 */
library Lib_RLPReader {
    /*************
     * Constants *
     *************/

    uint256 internal constant MAX_LIST_LENGTH = 32;

    /*********
     * Enums *
     *********/

    enum RLPItemType {
        DATA_ITEM,
        LIST_ITEM
    }

    /***********
     * Structs *
     ***********/

    struct RLPItem {
        uint256 length;
        uint256 ptr;
    }

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts bytes to a reference to memory position and length.
     * @param _in Input bytes to convert.
     * @return Output memory reference.
     */
    function toRLPItem(bytes memory _in) internal pure returns (RLPItem memory) {
        uint256 ptr;
        assembly {
            ptr := add(_in, 32)
        }

        return RLPItem({ length: _in.length, ptr: ptr });
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(RLPItem memory _in) internal pure returns (RLPItem[] memory) {
        (uint256 listOffset, , RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.LIST_ITEM, "Invalid RLP list value.");

        // Solidity in-memory arrays can't be increased in size, but *can* be decreased in size by
        // writing to the length. Since we can't know the number of RLP items without looping over
        // the entire input, we'd have to loop twice to accurately size this array. It's easier to
        // simply set a reasonable maximum list length and decrease the size before we finish.
        RLPItem[] memory out = new RLPItem[](MAX_LIST_LENGTH);

        uint256 itemCount = 0;
        uint256 offset = listOffset;
        while (offset < _in.length) {
            require(itemCount < MAX_LIST_LENGTH, "Provided RLP list exceeds max list length.");

            (uint256 itemOffset, uint256 itemLength, ) = _decodeLength(
                RLPItem({ length: _in.length - offset, ptr: _in.ptr + offset })
            );

            out[itemCount] = RLPItem({ length: itemLength + itemOffset, ptr: _in.ptr + offset });

            itemCount += 1;
            offset += itemOffset + itemLength;
        }

        // Decrease the array size to match the actual item count.
        assembly {
            mstore(out, itemCount)
        }

        return out;
    }

    /**
     * Reads an RLP list value into a list of RLP items.
     * @param _in RLP list value.
     * @return Decoded RLP list items.
     */
    function readList(bytes memory _in) internal pure returns (RLPItem[] memory) {
        return readList(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes value.");

        return _copy(_in.ptr, itemOffset, itemLength);
    }

    /**
     * Reads an RLP bytes value into bytes.
     * @param _in RLP bytes value.
     * @return Decoded bytes.
     */
    function readBytes(bytes memory _in) internal pure returns (bytes memory) {
        return readBytes(toRLPItem(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(RLPItem memory _in) internal pure returns (string memory) {
        return string(readBytes(_in));
    }

    /**
     * Reads an RLP string value into a string.
     * @param _in RLP string value.
     * @return Decoded string.
     */
    function readString(bytes memory _in) internal pure returns (string memory) {
        return readString(toRLPItem(_in));
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(RLPItem memory _in) internal pure returns (bytes32) {
        require(_in.length <= 33, "Invalid RLP bytes32 value.");

        (uint256 itemOffset, uint256 itemLength, RLPItemType itemType) = _decodeLength(_in);

        require(itemType == RLPItemType.DATA_ITEM, "Invalid RLP bytes32 value.");

        uint256 ptr = _in.ptr + itemOffset;
        bytes32 out;
        assembly {
            out := mload(ptr)

            // Shift the bytes over to match the item size.
            if lt(itemLength, 32) {
                out := div(out, exp(256, sub(32, itemLength)))
            }
        }

        return out;
    }

    /**
     * Reads an RLP bytes32 value into a bytes32.
     * @param _in RLP bytes32 value.
     * @return Decoded bytes32.
     */
    function readBytes32(bytes memory _in) internal pure returns (bytes32) {
        return readBytes32(toRLPItem(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(RLPItem memory _in) internal pure returns (uint256) {
        return uint256(readBytes32(_in));
    }

    /**
     * Reads an RLP uint256 value into a uint256.
     * @param _in RLP uint256 value.
     * @return Decoded uint256.
     */
    function readUint256(bytes memory _in) internal pure returns (uint256) {
        return readUint256(toRLPItem(_in));
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(RLPItem memory _in) internal pure returns (bool) {
        require(_in.length == 1, "Invalid RLP boolean value.");

        uint256 ptr = _in.ptr;
        uint256 out;
        assembly {
            out := byte(0, mload(ptr))
        }

        require(out == 0 || out == 1, "Lib_RLPReader: Invalid RLP boolean value, must be 0 or 1");

        return out != 0;
    }

    /**
     * Reads an RLP bool value into a bool.
     * @param _in RLP bool value.
     * @return Decoded bool.
     */
    function readBool(bytes memory _in) internal pure returns (bool) {
        return readBool(toRLPItem(_in));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(RLPItem memory _in) internal pure returns (address) {
        if (_in.length == 1) {
            return address(0);
        }

        require(_in.length == 21, "Invalid RLP address value.");

        return address(uint160(readUint256(_in)));
    }

    /**
     * Reads an RLP address value into a address.
     * @param _in RLP address value.
     * @return Decoded address.
     */
    function readAddress(bytes memory _in) internal pure returns (address) {
        return readAddress(toRLPItem(_in));
    }

    /**
     * Reads the raw bytes of an RLP item.
     * @param _in RLP item to read.
     * @return Raw RLP bytes.
     */
    function readRawBytes(RLPItem memory _in) internal pure returns (bytes memory) {
        return _copy(_in);
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Decodes the length of an RLP item.
     * @param _in RLP item to decode.
     * @return Offset of the encoded data.
     * @return Length of the encoded data.
     * @return RLP item type (LIST_ITEM or DATA_ITEM).
     */
    function _decodeLength(RLPItem memory _in)
        private
        pure
        returns (
            uint256,
            uint256,
            RLPItemType
        )
    {
        require(_in.length > 0, "RLP item cannot be null.");

        uint256 ptr = _in.ptr;
        uint256 prefix;
        assembly {
            prefix := byte(0, mload(ptr))
        }

        if (prefix <= 0x7f) {
            // Single byte.

            return (0, 1, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xb7) {
            // Short string.

            // slither-disable-next-line variable-scope
            uint256 strLen = prefix - 0x80;

            require(_in.length > strLen, "Invalid RLP short string.");

            return (1, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xbf) {
            // Long string.
            uint256 lenOfStrLen = prefix - 0xb7;

            require(_in.length > lenOfStrLen, "Invalid RLP long string length.");

            uint256 strLen;
            assembly {
                // Pick out the string length.
                strLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfStrLen)))
            }

            require(_in.length > lenOfStrLen + strLen, "Invalid RLP long string.");

            return (1 + lenOfStrLen, strLen, RLPItemType.DATA_ITEM);
        } else if (prefix <= 0xf7) {
            // Short list.
            // slither-disable-next-line variable-scope
            uint256 listLen = prefix - 0xc0;

            require(_in.length > listLen, "Invalid RLP short list.");

            return (1, listLen, RLPItemType.LIST_ITEM);
        } else {
            // Long list.
            uint256 lenOfListLen = prefix - 0xf7;

            require(_in.length > lenOfListLen, "Invalid RLP long list length.");

            uint256 listLen;
            assembly {
                // Pick out the list length.
                listLen := div(mload(add(ptr, 1)), exp(256, sub(32, lenOfListLen)))
            }

            require(_in.length > lenOfListLen + listLen, "Invalid RLP long list.");

            return (1 + lenOfListLen, listLen, RLPItemType.LIST_ITEM);
        }
    }

    /**
     * Copies the bytes from a memory location.
     * @param _src Pointer to the location to read from.
     * @param _offset Offset to start reading from.
     * @param _length Number of bytes to read.
     * @return Copied bytes.
     */
    function _copy(
        uint256 _src,
        uint256 _offset,
        uint256 _length
    ) private pure returns (bytes memory) {
        bytes memory out = new bytes(_length);
        if (out.length == 0) {
            return out;
        }

        uint256 src = _src + _offset;
        uint256 dest;
        assembly {
            dest := add(out, 32)
        }

        // Copy over as many complete words as we can.
        for (uint256 i = 0; i < _length / 32; i++) {
            assembly {
                mstore(dest, mload(src))
            }

            src += 32;
            dest += 32;
        }

        // Pick out the remaining bytes.
        uint256 mask;
        unchecked {
            mask = 256**(32 - (_length % 32)) - 1;
        }

        assembly {
            mstore(dest, or(and(mload(src), not(mask)), and(mload(dest), mask)))
        }
        return out;
    }

    /**
     * Copies an RLP item into bytes.
     * @param _in RLP item to copy.
     * @return Copied bytes.
     */
    function _copy(RLPItem memory _in) private pure returns (bytes memory) {
        return _copy(_in.ptr, 0, _in.length);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_RLPWriter
 * @author Bakaoh (with modifications)
 */
library Lib_RLPWriter {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * RLP encodes a byte string.
     * @param _in The byte string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeBytes(bytes memory _in) internal pure returns (bytes memory) {
        bytes memory encoded;

        if (_in.length == 1 && uint8(_in[0]) < 128) {
            encoded = _in;
        } else {
            encoded = abi.encodePacked(_writeLength(_in.length, 128), _in);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded byte byte strings.
     * @param _in The list of RLP encoded byte strings.
     * @return The RLP encoded list of items in bytes.
     */
    function writeList(bytes[] memory _in) internal pure returns (bytes memory) {
        bytes memory list = _flatten(_in);
        return abi.encodePacked(_writeLength(list.length, 192), list);
    }

    /**
     * RLP encodes a string.
     * @param _in The string to encode.
     * @return The RLP encoded string in bytes.
     */
    function writeString(string memory _in) internal pure returns (bytes memory) {
        return writeBytes(bytes(_in));
    }

    /**
     * RLP encodes an address.
     * @param _in The address to encode.
     * @return The RLP encoded address in bytes.
     */
    function writeAddress(address _in) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_in));
    }

    /**
     * RLP encodes a uint.
     * @param _in The uint256 to encode.
     * @return The RLP encoded uint256 in bytes.
     */
    function writeUint(uint256 _in) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_in));
    }

    /**
     * RLP encodes a bool.
     * @param _in The bool to encode.
     * @return The RLP encoded bool in bytes.
     */
    function writeBool(bool _in) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_in ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /*********************
     * Private Functions *
     *********************/

    /**
     * Encode the first byte, followed by the `len` in binary form if `length` is more than 55.
     * @param _len The length of the string or the payload.
     * @param _offset 128 if item is string, 192 if item is list.
     * @return RLP encoded bytes.
     */
    function _writeLength(uint256 _len, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_len < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_len) + uint8(_offset));
        } else {
            uint256 lenLen;
            uint256 i = 1;
            while (_len / i != 0) {
                lenLen++;
                i *= 256;
            }

            encoded = new bytes(lenLen + 1);
            encoded[0] = bytes1(uint8(lenLen) + uint8(_offset) + 55);
            for (i = 1; i <= lenLen; i++) {
                encoded[i] = bytes1(uint8((_len / (256**(lenLen - i))) % 256));
            }
        }

        return encoded;
    }

    /**
     * Encode integer in big endian binary form with no leading zeroes.
     * @notice TODO: This should be optimized with assembly to save gas costs.
     * @param _x The integer to encode.
     * @return RLP encoded bytes.
     */
    function _toBinary(uint256 _x) private pure returns (bytes memory) {
        bytes memory b = abi.encodePacked(_x);

        uint256 i = 0;
        for (; i < 32; i++) {
            if (b[i] != 0) {
                break;
            }
        }

        bytes memory res = new bytes(32 - i);
        for (uint256 j = 0; j < res.length; j++) {
            res[j] = b[i++];
        }

        return res;
    }

    /**
     * Copies a piece of memory to another location.
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol.
     * @param _dest Destination location.
     * @param _src Source location.
     * @param _len Length of memory to copy.
     */
    function _memcpy(
        uint256 _dest,
        uint256 _src,
        uint256 _len
    ) private pure {
        uint256 dest = _dest;
        uint256 src = _src;
        uint256 len = _len;

        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256**(32 - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * Flattens a list of byte strings into one byte string.
     * @notice From: https://github.com/sammayo/solidity-rlp-encoder/blob/master/RLPEncode.sol.
     * @param _list List of byte strings to flatten.
     * @return The flattened byte string.
     */
    function _flatten(bytes[] memory _list) private pure returns (bytes memory) {
        if (_list.length == 0) {
            return new bytes(0);
        }

        uint256 len;
        uint256 i = 0;
        for (; i < _list.length; i++) {
            len += _list[i].length;
        }

        bytes memory flattened = new bytes(len);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (i = 0; i < _list.length; i++) {
            bytes memory item = _list[i];

            uint256 listPtr;
            assembly {
                listPtr := add(item, 0x20)
            }

            _memcpy(flattenedPtr, listPtr, item.length);
            flattenedPtr += _list[i].length;
        }

        return flattened;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_Byte32Utils
 */
library Lib_Bytes32Utils {
    /**********************
     * Internal Functions *
     **********************/

    /**
     * Converts a bytes32 value to a boolean. Anything non-zero will be converted to "true."
     * @param _in Input bytes32 value.
     * @return Bytes32 as a boolean.
     */
    function toBool(bytes32 _in) internal pure returns (bool) {
        return _in != 0;
    }

    /**
     * Converts a boolean to a bytes32 value.
     * @param _in Input boolean value.
     * @return Boolean as a bytes32.
     */
    function fromBool(bool _in) internal pure returns (bytes32) {
        return bytes32(uint256(_in ? 1 : 0));
    }

    /**
     * Converts a bytes32 value to an address. Takes the *last* 20 bytes.
     * @param _in Input bytes32 value.
     * @return Bytes32 as an address.
     */
    function toAddress(bytes32 _in) internal pure returns (address) {
        return address(uint160(uint256(_in)));
    }

    /**
     * Converts an address to a bytes32.
     * @param _in Input address value.
     * @return Address as a bytes32.
     */
    function fromAddress(address _in) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_in)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title Lib_BytesUtils
 */
library Lib_BytesUtils {
    /**********************
     * Internal Functions *
     **********************/

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_start + _length >= _start, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function slice(bytes memory _bytes, uint256 _start) internal pure returns (bytes memory) {
        if (_start >= _bytes.length) {
            return bytes("");
        }

        return slice(_bytes, _start, _bytes.length - _start);
    }

    function toBytes32(bytes memory _bytes) internal pure returns (bytes32) {
        if (_bytes.length < 32) {
            bytes32 ret;
            assembly {
                ret := mload(add(_bytes, 32))
            }
            return ret;
        }

        return abi.decode(_bytes, (bytes32)); // will truncate if input length > 32 bytes
    }

    function toUint256(bytes memory _bytes) internal pure returns (uint256) {
        return uint256(toBytes32(_bytes));
    }

    function toNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory nibbles = new bytes(_bytes.length * 2);

        for (uint256 i = 0; i < _bytes.length; i++) {
            nibbles[i * 2] = _bytes[i] >> 4;
            nibbles[i * 2 + 1] = bytes1(uint8(_bytes[i]) % 16);
        }

        return nibbles;
    }

    function fromNibbles(bytes memory _bytes) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(_bytes.length / 2);

        for (uint256 i = 0; i < ret.length; i++) {
            ret[i] = (_bytes[i * 2] << 4) | (_bytes[i * 2 + 1]);
        }

        return ret;
    }

    function equal(bytes memory _bytes, bytes memory _other) internal pure returns (bool) {
        return keccak256(_bytes) == keccak256(_other);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.9;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.9;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../libraries/LibAppStorage.sol";
import "../../libraries/cb/LibLeagues.sol";
import "../../interfaces/cb/ITeamNFT.sol";
import {LibMeta} from "../../libraries/shared/LibMeta.sol";
import {LibERC721} from "../../libraries/shared/LibERC721.sol";
import {LibChainballers} from "../../libraries/LibChainballers.sol";

contract DataFacet is Modifiers {

    function getSkillByIndex(uint _tokenId, uint idx) public view returns (uint16){
        if (idx == 0 ){ return s.attributes[_tokenId].Stamina;}
        if (idx == 1 ){ return s.attributes[_tokenId].Playmaking;}
        if (idx == 2 ){ return s.attributes[_tokenId].Scoring;}
        if (idx == 3 ){ return s.attributes[_tokenId].Winger;}
        if (idx == 4 ){ return s.attributes[_tokenId].Goalkeeping;}
        if (idx == 5 ){ return s.attributes[_tokenId].Passing;}
        if (idx == 6 ){ return s.attributes[_tokenId].Defending;}
        if (idx == 7 ){ return s.attributes[_tokenId].SetPieces;}
        if (idx == 9 ){ return s.attributes[_tokenId].LearningRate;}
    }

    function getCoachSkillByIndex(uint _tokenId, uint idx) public view returns (uint16){
        if (idx == 0 ){ return s.coachAttributes[_tokenId].Tactic;}
        if (idx == 1 ){ return s.coachAttributes[_tokenId].Offence;}
        if (idx == 2 ){ return s.coachAttributes[_tokenId].Defence;}
        if (idx == 3 ){ return s.coachAttributes[_tokenId].Motivation;}
    }

    function getSpecialTrait(uint _tokenId) public view returns (string memory){
        return LibChainballers.getSpecialTrait(_tokenId);
    }

    function getCoachStyle(uint _tokenId) public view returns (string memory){
        return s.coachAttributes[_tokenId].Style;
    }

    function getName(uint256 _tokenId) public view returns (string memory, string memory) {
        return (s.ballers[_tokenId].name,s.ballers[_tokenId].surname);
    }

    function getAttributes(uint256 _tokenId) external view returns (uint[] memory) {
        uint[] memory attrArray = new uint[](8);
        for (uint i =0; i < 8; i++){
            attrArray[i] = getSkillByIndex(_tokenId,i);
        }
        return attrArray;
    }

    function upgradeSkill(uint tokenId, uint idx) external {
        require(msg.sender == s.L1TrainingContract, "Not Auth");
        if (idx == 0 ){ s.attributes[tokenId].Stamina++;}
        if (idx == 1 ){ s.attributes[tokenId].Playmaking++;}
        if (idx == 2 ){ s.attributes[tokenId].Scoring++;}
        if (idx == 3 ){ s.attributes[tokenId].Winger++;}
        if (idx == 4 ){ s.attributes[tokenId].Goalkeeping++;}
        if (idx == 5 ){ s.attributes[tokenId].Passing++;}
        if (idx == 6 ){ s.attributes[tokenId].Defending++;}
        if (idx == 7 ){ s.attributes[tokenId].SetPieces++;}
    }

    // function assignLR(uint tokenId) external {
    //     require(msg.sender == s.L1TrainingContract, "Not Auth");
    //     require(s.attributes[tokenId].LearningRate == 0, "LR already assigned");
    //     ChainBaller memory baller = s.ballers[tokenId];
    //     s.attributes[tokenId].LearningRate = uint16(uint(keccak256(abi.encodePacked(blockhash(block.number), baller.dna)))%5);
    //     _registerData(tokenId, baller.dna, baller.name, baller.surname, "P");
    // }

    // doesn't need to be 10 length
    function setNames(string[10] memory _names) external {
        uint len = _names.length;
        for (uint i =0; i< len;i++){
            s.names.push(_names[i]);
        }
    }

    function setSurnames(string[10] memory _surnames) external {
        uint len = _surnames.length;
        for (uint i =0; i< len;i++){
            s.surnames.push(_surnames[i]);
        }
    }

    function genName(uint dna) public view returns (string memory, string memory) {
        return(s.names[dna%10], s.surnames[dna%10]);
    }

    function getTeamOwner(uint teamId) public view returns (address) {
        return ITeamNFT(s.L1TeamNFTContract).ownerOf(teamId);
    }

    function getDefaultFormation(
        uint teamId
    ) 
        external 
        view 
        returns (FormationType formationType, uint[] memory defaultFormation) 
    {
        formationType = s.teamDefaultFormationType[teamId];
        defaultFormation = s.teamDefaultFormation[teamId];
    }

    function getGameFormation(
        uint gameId, 
        uint side
    ) public view returns (FormationType formationType, uint[] memory formation)
    {
       (formationType,formation) = LibChainballers.getGameFormation(gameId,side);
    }

    function getFounderReserveAmount() public view returns (uint) {
        return s.FOUNDERS_RESERVE_AMOUNT;
    }

    function getRemainingFounderMints(address _addr) public view returns (uint256) {
        return s.founderMintCountsRemaining[_addr];
    }

    // function retireToCoach(uint tokenId) external {
    //     require(ownerOf(tokenId) == msg.sender,"Player not owned");
    //     uint dna = getDna(tokenId);
    //     s.coachAttributes[tokenId] = LibChainballers.generateCoachAttributes(dna,tokenId);
    //     s.attributes[tokenId] = retirePlayer();
    //     ChainBaller memory baller = s.ballers[tokenId];
    //     _registerData(tokenId, dna, baller.name, baller.surname, "C");
    // }

    function retirePlayer() internal view returns (BallerAttributes memory attr){
        attr.Stamina = 0;
        attr.Playmaking = 0;
        attr.Scoring = 0;
        attr.Winger = 0;
        attr.Goalkeeping = 0;
        attr.Passing = 0;
        attr.Defending = 0;
        attr.SetPieces = 0;
        attr.SpecialTrait = "Coach";
    }

    function getFormationForGame(uint gameId, uint teamSide) public view returns (FormationType) {
        return s.gamesFormation[gameId][teamSide];
    }

    function getTeamNextGameId(uint teamId) public view returns (uint) {
        return LibLeagues.getNextGame(teamId);
    }

    function getTeamLeague(uint teamId) public view returns (uint){
        return LibLeagues.getTeamLeague(teamId);
    }

    function getLeagueTeams(uint leagueId) public view returns (uint[] memory teams) {
        return LibLeagues.getLeagueTeams(leagueId);
    }

    function getUndisputedFirstFour(uint leagueId) public view returns (uint[] memory){
        return LibLeagues.getUndisputedFirstFour(leagueId);
    }

    function getStandingPosition(uint teamId) public view returns (uint) {
        return LibLeagues.getTeamStandingPosition(teamId);
    }

    function getPromotedTeam(uint leagueId) public view returns (uint) {
        return LibLeagues.getUndisputedFirst(leagueId);
    }

    function getRecessionTeams(uint leagueId) public view returns (uint, uint) {
        return LibLeagues.getUndisputedLastTwo(leagueId);
    }

    function getNumberOfLeagues() external view returns (uint){
        return s.leaguesCounter;
    }

    function getLeagueData(uint leagueId) external view 
        returns (uint,uint,uint[] memory,uint[4][] memory, uint[2][] memory , uint[6] memory){
        return (s.leagues[leagueId].id,s.leagues[leagueId].division,s.leagues[leagueId].teams,s.leagues[leagueId].schedule,s.leagues[leagueId].standing,s.leagues[leagueId].inOut);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
/* is ERC165 */
interface IERC721 {
    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.9;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721TokenReceiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface IChainBallers is IERC721Enumerable {
    function initialize(address _L2NFTContract, address L1VaultContract) external;
    function initialize(address _L1NFTContract) external;
    function initializeChainballers() external;
    function assignLR(uint tokenId) external;
    function getDna(uint256 _tokenId) external view returns (uint256);
    function getName(uint256 _tokenId) external view returns (string memory, string memory);
    function getFounderReserveAmount() external view returns (uint);
    function getSkillByIndex(uint256 _tokenId, uint256 idx) external view returns (uint16);
    function upgradeSkill(uint tokenId, uint idx) external;
    function ownerOf(uint tokenId) external view returns(address owner);
    function getSpecialTrait(uint _tokenId) external view returns (string memory);
    function getSpecialTraits(string memory trait, uint[] memory homeTeam, uint[] memory awayTeam) external view returns (uint[] memory);
    function setTrainingContractAddress(address _L1TrainingContract) external;
    function setRenderingContractAddress(address _L1RendererContract) external;
    function setTeamNFTContractAddress(address _L1TeamNFTContract) external;
    function setEarlyAccessTimestamp(uint256 timestamp) external;
    function setPublicSaleTimestamp(uint256 timestamp) external;
    function allocateFounderMint(address _addr, uint256 _count) external; 
    function founderMint(uint256 _count) external returns (uint256, uint256);
    function mintCoach() payable external;
    function getCoachSkillByIndex(uint _tokenId, uint idx) external view returns (uint16);
    function getCoachStyle(uint _tokenId) external view returns (string memory);
    function retireToCoach(uint tokenId) external;
    function setNames(string[10] memory _names) external;
    function setSurnames(string[10] memory _names) external;
    function teamMint(uint256 _count, address receiver) external returns (uint256, uint256);
    function tokenURI(uint256 _tokenId) external view returns (string calldata);
    function trainPlayer(uint tokenId, uint attIndex, bytes32 data) external returns (bool success);
    function transferAllTeam(address from, address to) external;
    function setVault(address _L1VaultContract) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {FormationType} from "../../libraries/LibAppStorage.sol";

interface IGameMaster {
    
    function getTeamOwner(uint teamId) external view returns (address);
    function getFormationForGame(uint gameId, uint teamSide) external view returns (FormationType);
    function createTeam() external;
    function createGame(uint teamHomeId, uint teamAwayId, uint gameTime) external returns (uint gameId);
    function startGame (uint gameId) external returns (uint homeGoals, uint awayGoals);
    function setFormation(uint gameId, uint teamId, FormationType formation, uint[] calldata team) external;
    function createLeague(uint startTime, uint[] memory teamIds) external returns (uint leagueId, uint division);
    function getTeamNextGameId(uint teamId) external view returns (uint);
    function getStandingPosition(uint teamId) external view returns (uint);
    function getPromotedTeam(uint leagueId) external view returns (uint);
    function getUndisputedFirstFour(uint leagueID) external view returns (uint[] memory);
    function getTeamLeague(uint teamId) external view returns (uint);
    function getRecessionTeams(uint leagueId) external view returns (uint, uint);
    function finaliseSeasonEnd(uint[] memory leagueIds) external;
    function newSeasonPrep(uint leagueId) external;
    function initializeNewSeason(uint leagueId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";


interface ITeamNFT is IERC721Enumerable {
    function initialize(address _L2NFTContract) external;
    function mint(address to,uint teamId) external;
    function sellTeam(uint teamId, address to) external;
    function setDiamond(address _diamondContract) external;
    function setL1TeamContract(address _L1TeamNFTContract) external;
    function setCrossDomainMessenger(address _ovmL2CrossDomainMessenger) external;
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./LibDiamond.sol";

struct ChainBaller {
    uint256 dna;
    uint256 birthdate;
    string name;
    string surname;
    bytes placer;
}

struct BallerAttributes {
    uint16 Stamina; // Decides how much of his ability to perform a player loses during the course of the match.
    uint16 Playmaking; // The ability to control the ball and turn it into scoring opportunities.
    uint16 Scoring; // The ball is supposed to go into the net.
    uint16 Winger; //The ability to finish off scoring opportunities by advancing down the sides.
    uint16 Goalkeeping; // The ball should not make it into your own net.
    uint16 Passing; //Players who know how to pass the decisive pass are a great help for the team's attack.
    uint16 Defending; //The ability to stop opponent attacks.
    uint16 SetPieces; // The outcome of your free kicks and penalties depends on how skilled your set pieces taker is.
    string SpecialTrait;
    uint16 LearningRate;
}

struct CoachAttributes {
    uint16 Tactic;
    uint16 Offence;
    uint16 Defence;
    uint16 Motivation;
    string Style;
}

struct Team{
    uint[][12] tokenIds;
}

struct individualEvents{
        uint16 placeholder;
        // uint16 injuryMild; // out for the match
        // uint16 injurySerious; // out for several matches
        uint16 CrossWingerToAnyone; //If your winger manages to break through the defense on his side of the pitch, he might pass the ball to the other Winger, Forward, or an Inner Midfielder, finished by an attacker with head skill or good scoring
        uint16 CrossWingerToHead; //If your winger manages to break through the defense on his side of the pitch, he might pass the ball to the other Winger, Forward, or an Inner Midfielder, finished by an attacker with head skill or good scoring
        uint16 QuickPasses; //Again, Wingers, Inner Midfielders, and Forwards can start a quick rush with potential for a subsequent pass. Any Winger and Forward can be the ball receiver.:
        uint16 QuickScores; //Quick Score: Winger, Forward or Inner Midfielder may create an event when facing defender (although defending skill and quick skill helps defend against this event),
        uint16 TechnicalDribbling; // dribbling and one on one with goalkeeper
        uint16 TechnicalCounterAttack;//Every Technical Defender and Wing Back will give you a non-tactical counter attack from a missed normal chance of your opponent with a small chance to trigger (from 1.7 to 3% based on how many technical back players you have).
        uint16 UnpredictableLongPass; //The keeper, wing backs and central defenders can initiate this scoring opportunity.
        uint16 UnpredictableScores; // Wingers, Inner Midfielders or Forwards one on one with the goalkeeper. Keep in mind that a lost chance can create a counter attack for your opponent.
        uint16 UnpredictableMistake; // Defenders, Wing Backs and Inner Midfielders, only if unpredictable with low defending skill, can have a bad day and make a fatal mistake. An opposing Winger or Forward can take advantage of this.
        uint16 UnpredictableOwnGoal; // Unpredictable Wingers and Forwards with low passing skill level can make a wrong move towards to your defense and your goalkeeper might not be able to stop it.
        uint16 PowerfulForward; // if players wins, own attack +1
        uint16 PowerfulDefence; //if player wins, opp attacks -1 
        // uint16 ManOfTheMatch; //skills +3
}


struct teamEvents{
        uint16 CornerAnyone;
        uint16 CornerHeadSpecialist;
        uint16 DefenderMistake;
        uint16 InexperiencedDefender;
        uint16 ExperiencedForward;
}

enum FormationType { FourFourTwo, FourThreeThree, FourFiveOne, ThreeFiveTwo, FiveFourOne } // Enum

struct SVGCursor {
    uint8 x;
    uint8 y;
    string color1;
    string color2;
    string color3;
    string color4;
}

struct Buffer {
    string one;
    string two;
    string three;
    string four;
    string five;
    string six;
    string seven;
    string eight;
}

struct Color {
    string hexString;
    uint alpha;
    uint red;
    uint green;
    uint blue;
}

struct Layer {
    string name;
    bytes hexString;
}

struct LayerInput {
    string name;
    bytes hexString;
    uint8 layerIndex;
    uint8 itemIndex;
}

struct League {
    uint id;
    uint division;
    uint[] teams;
    uint[4][] schedule;
    uint[2][] standing;
    uint[6] inOut;
    bool upgraded;
    bool rolled;
    bool hasChildLeft;
    bool hasChildRight;
}

struct AttackData {
    uint[] MUL_IDX_ATTK_SIDE;
    uint[] ATTR_IDX_ATTK_SIDE;
    uint[] TEAM_IDX_ATTK_LEFT;
    uint[] TEAM_IDX_ATTK_RIGHT;
    uint[] MUL_IDX_ATTK_CENTRE;
    uint[] TEAM_IDX_ATTK_CENTRE;
    uint[] ATTR_IDX_ATTK_CENTRE;
    uint[] MUL_IDX_ATTK_SP;
    uint[] TEAM_IDX_ATTK_SP;
    uint[] ATTR_IDX_ATTK_SP;
}

struct DefenceData {
    uint[] MUL_IDX_DEF_SIDE;
    uint[] ATTR_IDX_DEF_SIDE;
    uint[] TEAM_IDX_DEF_LEFT;
    uint[] TEAM_IDX_DEF_RIGHT;
    uint[] MUL_IDX_DEF_CENTRE;
    uint[] TEAM_IDX_DEF_CENTRE;
    uint[] ATTR_IDX_DEF_CENTRE;
    uint[] MUL_IDX_DEF_SP;
    uint[] TEAM_IDX_DEF_SP;
    uint[] ATTR_IDX_DEF_SP;
}

struct MidfieldData {
    uint[] MUL_IDX_MID;
    uint[] TEAM_IDX_MID;
    uint[] ATTR_IDX_MID;
}

struct ChainBallers {
    string name;
    address owner;
}

struct AppStorage {
    // L1 Addresses
    address chainBallersContract;
    address L1TeamNFTContract;
    address L1RendererContract;
    address L1TrainingContract;
    address L1VaultContract;
    address ovmL1CrossDomainMessenger;
    // L2 Addresses
    address L2NFTContract;
    address L2TeamNFTContract;
    address L2RendererContract;
    address L2TrainingAddress;
    address L2VaultAddress;
    address gameMaster;
    address gameplayMidfield;
    address gameplayAttack;
    address gameplayDefence;
    address gameEngine;
    address gameEngineSE;
    address leaguesContract;
    address ovmL2CrossDomainMessenger;
    // ----- chainballers ------ //
    mapping(uint256 => ChainBaller) ballers;
    mapping(uint256 => BallerAttributes) attributes;
    mapping(uint256 => CoachAttributes) coachAttributes;
    mapping(address => uint256) founderMintCountsRemaining;
    mapping(uint => uint) lastMint;  // teamId to timestamp
    uint256 tokenIds;
    mapping(address => uint256) NFTbalances;
    mapping(uint256 => address) NFTowners;
    mapping(uint256 => ChainBallers) chainBallers;
    mapping(address => mapping(address => bool)) operators;
    mapping(uint256 => address) approved;
    mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
    mapping(address => uint32[]) ownerTokenIds;
    uint256 _reservedTokenIds;
    uint256 FOUNDERS_RESERVE_AMOUNT;
    uint256 MINT_PRICE;
    uint256 publicSaleStartTimestamp;
    uint256 earlyAccessStartTimestamp;
    uint256 founderMintCountsTotal;
    string[] names;
    string[] surnames;
    bool cbInitialized;
    string name;
    string symbol;
    // ------ Renderer ------ // 
    uint256 NUM_LAYERS;
    uint256 NUM_COLORS;
    mapping(uint256 => Layer) [13] layers;
    mapping(uint256 => Layer) shirts;
    uint16[][13] WEIGHTS;
    // ------ Game Master ------ //
    // gameId to team side (1/2) to team array
    mapping(uint => mapping(uint => uint[])) gamesLineup;
    // gameId => team side (1/2) to formation
    mapping(uint => mapping(uint => FormationType)) gamesFormation;
    // default formation
    mapping(uint => FormationType) teamDefaultFormationType;
    mapping(uint => uint[]) teamDefaultFormation;
    // gameId => team Id home, team id away, gameTime, leagueId
    mapping(uint => uint[]) matches;
    uint teamsCounter;
    uint gameIdCounter;
    // ------ Leagues ------ //
    uint NUM_LEAGUE_TEAMS;
    uint NUM_LEAGUE_ROUNDS;
    uint leaguesCounter;
    mapping( uint => League) leagues;
    // to ensure a team is only in 1 league at a time
    // inLeague[0] 0-1 if inLeague, inLeague[1] the div number 
    mapping( uint => uint[2]) inLeague;
    uint[] cupTeams;
    uint cupCounter;
    uint CUP_FEE;
    uint seasonStart;
    uint seasonEnd;
    // ------ Vault ------ //
    // teamOwner to balance
    mapping(address => uint) owedBalances;
    // ------ L2 Training ------ //
    // tokenId to timestamp
    mapping(uint => uint) trainingTime;
    // tokenId to timestamp, attIndex
    mapping(uint => uint[]) whenTrained;
    // tokenId has trained once yet
    mapping(uint => bool) hasTrained;
    // ------ L2 Vault ------ //
    // teams to balance
    mapping(uint => uint) balances;
    // league to prize
    mapping(uint => uint[]) prizes;
    uint undistributed;
    uint16[10] MULTIPLIER;
    uint16[15] STAMINA;
    mapping (uint => AttackData) attackDatas;
    mapping (uint => DefenceData) defenceDatas;
    mapping (uint => MidfieldData) midfieldDatas;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }

    function abs(int256 x) internal pure returns (uint256) {
        return uint256(x >= 0 ? x : -x);
    }
}


contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@eth-optimism/contracts/L1/messaging/IL1CrossDomainMessenger.sol";
import {LibERC20} from "../libraries/shared/LibERC20.sol";
import {LibMeta} from "../libraries/shared/LibMeta.sol";
import {LibERC721} from "../libraries/shared/LibERC721.sol";
import {IERC721} from "../interfaces/IERC721.sol";
import {IChainBallers} from "../interfaces/cb/IChainBallers.sol";
import {ITeamNFT} from "../interfaces/cb/ITeamNFT.sol";
import {IERC721Enumerable} from "../interfaces/IERC721Enumerable.sol";
import "../libraries/cb/Base64.sol";
import {Layer, Color} from "./LibAppStorage.sol";
import "./LibAppStorage.sol";

library LibChainballers {
    
    // chainballers

    // function addTokenToUser(address _to, uint256 _tokenId) internal {}

    // function removeTokenFromUser(address _from, uint256 _tokenId) internal {}

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // remove
        uint256 index = s.ownerTokenIdIndexes[_from][_tokenId];
        uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
        if (index != lastIndex) {
            uint32 lastTokenId = s.ownerTokenIds[_from][lastIndex];
            s.ownerTokenIds[_from][index] = lastTokenId;
            s.ownerTokenIdIndexes[_from][lastTokenId] = index;
        }
        s.ownerTokenIds[_from].pop();
        delete s.ownerTokenIdIndexes[_from][_tokenId];
        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit LibERC721.Approval(_from, address(0), _tokenId);
        }
        // add
        s.chainBallers[_tokenId].owner = _to;
        s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
        s.ownerTokenIds[_to].push(uint32(_tokenId));
        emit LibERC721.Transfer(_from, _to, _tokenId);
    }

    function mint(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit LibERC721.Approval(_from, address(0), _tokenId);
        }
        // add
        s.chainBallers[_tokenId].owner = _to;
        s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
        s.ownerTokenIds[_to].push(uint32(_tokenId));
        emit LibERC721.Transfer(_from, _to, _tokenId);
    }


    function teamMint(uint256 _count, address receiver) internal returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(s.founderMintCountsRemaining[receiver] >= _count, "You cannot mint this many reserved Ballers");

        uint256 firstMintedId = s.tokenIds + 1;
        for (uint256 i = 0; i < _count; i++) {
            s.tokenIds++;
            mintTo(s.tokenIds, receiver);
        }
        s.founderMintCountsRemaining[receiver] -= _count;
        return (firstMintedId, _count);
    }

    function mintTo(uint256 tokenId, address to) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        ChainBaller memory baller;
        baller.dna = uint256(keccak256(abi.encodePacked(
                tokenId,
                to,
                block.difficulty,
                block.timestamp
            )));
        baller.birthdate = block.timestamp;
        s.attributes[tokenId] = generateAttributes(baller.dna);
        // (baller.name, baller.surname) = genName(baller.dna);
        _registerData(tokenId, baller.dna, baller.name, baller.surname, "C");
        _mint(to, tokenId);
        s.ballers[tokenId] = baller;
    }

    function generateAttributes(uint dna) internal returns (BallerAttributes memory attr) {
        uint16[] memory indexes = new uint16[](8);
        uint16[9] memory numbers = splitNumber9(dna);
        uint16 attrIndex;
        for (uint16 i=0; i < 8; i++) {
            attrIndex = numbers[i] % (20);
            if (attrIndex == 17 || attrIndex == 18 || attrIndex == 19){
                attrIndex = uint16(uint(keccak256(abi.encodePacked(blockhash(block.number-i), dna)))%20);
            }
            if (attrIndex == 0 || attrIndex == 1 || attrIndex == 2){
                attrIndex = uint16(uint(keccak256(abi.encodePacked(blockhash(block.number-i), dna)))%14);
            }
            if (i == 4 && attrIndex > 14){
                attrIndex = uint16(uint(keccak256(abi.encodePacked(blockhash(block.number-i), dna)))%20);
            }
            if (attrIndex == 0) {
                attrIndex = 1;
            } 
            indexes[i] = attrIndex;
        }
        attr.Stamina = indexes[0];
        attr.Playmaking = indexes[1];
        attr.Scoring = indexes[2];
        attr.Winger = indexes[3];
        attr.Goalkeeping = indexes[4];
        attr.Passing = indexes[5];
        attr.Defending = indexes[6];
        attr.SetPieces = indexes[7];
        if (numbers[8]%20 > 14){
            if (numbers[8] % 20 == 15){ attr.SpecialTrait = "Technical";}
            if (numbers[8] % 20 == 16){ attr.SpecialTrait = "Quick";}
            if (numbers[8] % 20 == 17){ attr.SpecialTrait = "Powerful";}
            if (numbers[8] % 20 == 18){ attr.SpecialTrait = "Unpredictable";}
            if (numbers[8] % 20 == 19){ attr.SpecialTrait = "Winger";}
        }
    }

    function generateCoachAttributes(uint dna, uint tokenId) internal returns (CoachAttributes memory attr) {
        uint16[] memory indexes = new uint16[](8);
        uint16[9] memory numbers = splitNumber9(dna);
        uint16 attrIndex;
        for (uint16 i=0; i < 4; i++) {
            attrIndex = numbers[i] % (20);
            if (attrIndex == 17 || attrIndex == 18 || attrIndex == 19){
                attrIndex = uint16(uint(keccak256(abi.encodePacked(blockhash(block.number-i), dna)))%20);
            }
            if (attrIndex == 0 || attrIndex == 1 || attrIndex == 2){
                attrIndex = uint16(uint(keccak256(abi.encodePacked(blockhash(block.number-i), dna)))%14);
            }
            if (attrIndex == 0) {
                attrIndex = 1;
            } 
            indexes[i] = attrIndex;
        }

        if (getSkillByIndex(tokenId,1) > 15){ indexes[0]++;}
        if (getSkillByIndex(tokenId,2) > 15){ indexes[1]++;}
        if (getSkillByIndex(tokenId,6) > 15){ indexes[2]++;}
        if (getSkillByIndex(tokenId,0) > 15){ indexes[3]++;}

        attr.Tactic = indexes[0];
        attr.Offence = indexes[1];
        attr.Defence = indexes[2];
        attr.Motivation = indexes[3];

        if (numbers[8] % 5 == 0){ attr.Style = "Pragmatic";}
        if (numbers[8] % 5 == 1){ attr.Style = "Offensive";}
        if (numbers[8] % 5 == 2){ attr.Style = "Defensive";}
        if (numbers[8] % 5 == 3){ attr.Style = "Opportunist";}
        if (numbers[8] % 5 == 4){ attr.Style = "Driver";}
        

        if (getSkillByIndex(tokenId,2) > 14 && getSkillByIndex(tokenId,6) < 9) {
            attr.Style = "Offensive";
        }
        if (getSkillByIndex(tokenId,2) < 9 && getSkillByIndex(tokenId,6) > 14) {
            attr.Style = "Defensive";
        }
    }

    function splitNumber9(uint256 _number) internal pure returns (uint16[9] memory numbers) {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % 10000);
            _number >>= 14;
        }
        return numbers;
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        LibChainballers.mint(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /// @dev Returns whether `tokenId` exists.
    function _exists(uint256 tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.chainBallers[tokenId].owner != address(0);
    }

    //// ----- RENDERING ------ ////

    /*
    Generate base64 encoded tokenURI.

    All string constants are pre-base64 encoded to save gas.
    Input strings are padded with spacing/etc to ensure their length is a multiple of 3.
    This way the resulting base64 encoded string is a multiple of 4 and will not include any '=' padding characters,
    which allows these base64 string snippets to be concatenated with other snippets.
    */
    function renderTokenURI(uint256 tokenId, ChainBaller memory runnerData) internal view returns (string memory) {
        string memory attributes;
        (Layer [13] memory tokenLayers, Color [8][13] memory tokenPalettes, uint8 numTokenLayers, string[13] memory traitTypes) = LibChainballers.getTokenDataFromAttributes(runnerData);
        {
            AppStorage storage s = LibAppStorage.diamondStorage();
            for (uint8 i = 0; i < numTokenLayers; i++) {
                if (block.timestamp > runnerData.birthdate + (60*60*24*1530)){
                    // check if it's one of the aging layers 
                    if (keccak256(abi.encodePacked(traitTypes[i])) == keccak256(abi.encodePacked("SGVhZCBCZWxvdyAg")) || keccak256(abi.encodePacked(traitTypes[i])) == keccak256(abi.encodePacked("RmFjZSAg"))){
                        tokenPalettes[i][1] = aging(tokenPalettes[i][1],1);
                        tokenPalettes[i][2] = aging(tokenPalettes[i][2],2);
                        tokenPalettes[i][3] = aging(tokenPalettes[i][3],3);
                    }
                }
                if (keccak256(abi.encodePacked(traitTypes[i])) == keccak256(abi.encodePacked("U2hpcnQgU3R5bGUg"))){
                    if (s.shirts[tokenId].hexString.length > 0){
                        tokenLayers[i] = getShirtLayer(tokenId);
                        tokenPalettes[i] = palette(tokenLayers[i].hexString);
                    } else {
                        tokenLayers[i].hexString = fromHex('0x000000000000ff570000ff624956ff646464ff646464ff0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000024920000000124900000000924924000000924924000004924924800004924924800');
                        tokenPalettes[i] = palette(tokenLayers[i].hexString);
                    }
                }
                attributes = string(abi.encodePacked(attributes,
                    bytes(attributes).length == 0 ? 'eyAg' : 'LCB7',
                    'InRyYWl0X3R5cGUiOiAi', traitTypes[i], 'IiwidmFsdWUiOiAi', tokenLayers[i].name, 'IiB9'
                    ));
            }
        }
        string[4] memory svgBuffers = tokenSVGBuffer(tokenLayers, tokenPalettes, numTokenLayers, runnerData);
        return string(abi.encodePacked(
                'data:application/json;base64,eyAgImltYWdlX2RhdGEiOiAiPHN2ZyB2ZXJzaW9uPScxLjEnIHZpZXdCb3g9JzAgMCAzMjAgMzIwJyB4bWxucz0naHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmcnIHNoYXBlLXJlbmRlcmluZz0nY3Jpc3BFZGdlcyc+',
                svgBuffers[0], svgBuffers[1], svgBuffers[2], svgBuffers[3],
                'PHN0eWxlPnJlY3R7d2lkdGg6MTBweDtoZWlnaHQ6MTBweDt9PC9zdHlsZT48L3N2Zz4gIiwgImF0dHJpYnV0ZXMiOiBb',
                attributes,
                'XSwgICAibmFtZSI6IlJ1bm5lciAj',
                Base64.encode(uintToByteString(tokenId, 6)),
                'IiwgImRlc2NyaXB0aW9uIjogIkNoYWluIFJ1bm5lcnMgYXJlIE1lZ2EgQ2l0eSByZW5lZ2FkZXMgMTAwJSBnZW5lcmF0ZWQgb24gY2hhaW4uIn0g'
            ));
    }

    function getTokenDataFromAttributes(ChainBaller memory data) internal view returns (Layer [13] memory tokenLayers, Color [8][13] memory tokenPalettes, uint8 numTokenLayers, string [13] memory traitTypes) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint16[13] memory dna = splitNumber(data.dna);
        bool useHeadAbove;
        // bool hasMouthAcc= 
        if (block.timestamp > data.birthdate + (60*60*24*1530)){ useHeadAbove = true;}
        // for each of the 13 attributes/layers, assign a layer index based on dna
        for (uint8 i = 0; i < 13; i ++) {
            Layer memory layer = s.layers[i][getLayerIndex(dna[i], i)]; // layers set by owner (incl name and bytes attribute svg)
            // Layer memory layer = s.layers[0][1];
            if (layer.hexString.length > 0) {
                /*
                These conditions help make sure layer selection matches coach/player attributes.
                    if coach (use head above) don't add hair layer 9
                    if coach add layer 10, 11
                */
                if ( (i != 8 && i != 9 && i != 10 && i != 11 && i != 12 ) || (i == 9 && !useHeadAbove) || (i==10 && useHeadAbove) || (i == 11 && useHeadAbove) || (i == 12 && useHeadAbove)) { 
                    tokenLayers[numTokenLayers] = layer;
                    tokenPalettes[numTokenLayers] = palette(tokenLayers[numTokenLayers].hexString);
                    traitTypes[numTokenLayers] = ["QmFja2dyb3VuZCAg","UmFjZSAg","RmFjZSAg","TW91dGgg","Tm9zZSAg","RXllcyAg","RWFyIEFjY2Vzc29yeSAg","U2hpcnQgU3R5bGUg","TWFzayAg","SGVhZCBCZWxvdyAg","RXllIEFjY2Vzc29yeSAg","SGVhZCBBYm92ZSAg","TW91dGggQWNjZXNzb3J5"][i];
                    // 0) Background - 1) Race - 2) Face 3) Mouth 4) Nose 5) Eyes 6) Ear Accessory
                    // 7) Shirt Style 8) Mask 9) Head Below 10) Eye Accessory 11) Head Above 12) Mouth Accessory
                    numTokenLayers++;
                }
            }
        }
        return (tokenLayers, tokenPalettes, numTokenLayers, traitTypes);
    }

    function getLayerIndex(uint16 _dna, uint8 _index) internal view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        if (_index == 7){return 0;} //shirt style is not assigned
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < s.WEIGHTS[_index].length; i++) {
            percentage = s.WEIGHTS[_index][i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                return i;
            }
            lowerBound += percentage;
        }
        // If not found, return index higher than available layers.  Will get filtered out.
        return s.WEIGHTS[_index].length;
    }

  /*
    Generate svg rects, leaving un-concatenated to save a redundant concatenation in calling functions to reduce gas.
    Shout out to Blitmap for a lot of the inspiration for efficient rendering here.
    */
    function tokenSVGBuffer(Layer [13] memory tokenLayers, Color [8][13] memory tokenPalettes, uint8 numTokenLayers, ChainBaller memory runnerData ) internal pure returns (string[4] memory) {
        // Base64 encoded lookups into x/y position strings from 010 to 310.
        string[32] memory lookup = ["MDAw", "MDEw", "MDIw", "MDMw", "MDQw", "MDUw", "MDYw", "MDcw", "MDgw", "MDkw", "MTAw", "MTEw", "MTIw", "MTMw", "MTQw", "MTUw", "MTYw", "MTcw", "MTgw", "MTkw", "MjAw", "MjEw", "MjIw", "MjMw", "MjQw", "MjUw", "MjYw", "Mjcw", "Mjgw", "Mjkw", "MzAw", "MzEw"];
        SVGCursor memory cursor;

        /*
        Rather than concatenating the result string with itself over and over (e.g. result = abi.encodePacked(result, newString)),
        we fill up multiple levels of buffers.  This reduces redundant intermediate concatenations, performing O(log(n)) concats
        instead of O(n) concats.  Buffers beyond a length of about 12 start hitting stack too deep issues, so using a length of 8
        because the pixel math is convenient.
        */
        Buffer memory buffer4;
        // 4 pixels per slot, 32 total.  Struct is ever so slightly better for gas, so using when convenient.
        string[8] memory buffer32;
        // 32 pixels per slot, 256 total
        string[4] memory buffer256;
        // 256 pixels per slot, 1024 total
        uint8 buffer32count;
        uint8 buffer256count;
        for (uint k = 32; k < 416;) {
            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.one = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.two = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.three = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.four = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.five = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.six = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            cursor.color1 = colorForIndex(tokenLayers, k, 0, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 1, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 2, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 3, tokenPalettes, numTokenLayers);
            buffer4.seven = pixel4(lookup, cursor);
            cursor.x += 4;

            cursor.color1 = colorForIndex(tokenLayers, k, 4, tokenPalettes, numTokenLayers);
            cursor.color2 = colorForIndex(tokenLayers, k, 5, tokenPalettes, numTokenLayers);
            cursor.color3 = colorForIndex(tokenLayers, k, 6, tokenPalettes, numTokenLayers);
            cursor.color4 = colorForIndex(tokenLayers, k, 7, tokenPalettes, numTokenLayers);
            buffer4.eight = pixel4(lookup, cursor);
            cursor.x += 4;

            k += 3;

            buffer32[buffer32count++] = string(abi.encodePacked(buffer4.one, buffer4.two, buffer4.three, buffer4.four, buffer4.five, buffer4.six, buffer4.seven, buffer4.eight));
            cursor.x = 0;
            cursor.y += 1;
            if (buffer32count >= 8) {
                buffer256[buffer256count++] = string(abi.encodePacked(buffer32[0], buffer32[1], buffer32[2], buffer32[3], buffer32[4], buffer32[5], buffer32[6], buffer32[7]));
                buffer32count = 0;
            }
        }
        // At this point, buffer256 contains 4 strings or 256*4=1024=32x32 pixels
        // string memory textBuffer = generateNameSVG(runnerData.name, runnerData.surname);
        // string memory textBuffer = Base64.encode(bytes("LUK1"));
        // buffer256[3] = string(abi.encodePacked(buffer256[3],textBuffer));
        return buffer256;
    }

    function palette(bytes memory data) internal pure returns (Color [8] memory) {
        Color [8] memory colors;
        for (uint16 i = 0; i < 8; i++) {
            // Even though this can be computed later from the RGBA values below, it saves gas to pre-compute it once upfront.
            colors[i].hexString = Base64.encode(bytes(abi.encodePacked(
                    byteToHexString(data[i * 4]),
                    byteToHexString(data[i * 4 + 1]),
                    byteToHexString(data[i * 4 + 2])
                )));
            colors[i].red = byteToUint(data[i * 4]);
            colors[i].green = byteToUint(data[i * 4 + 1]);
            colors[i].blue = byteToUint(data[i * 4 + 2]);
            colors[i].alpha = byteToUint(data[i * 4 + 3]);
        }
        return colors;
    }

    function colorForIndex(Layer[13] memory tokenLayers, uint k, uint index, Color [8][13] memory palettes, uint numTokenLayers) internal pure returns (string memory) {
        for (uint256 i = numTokenLayers - 1; i >= 0; i--) {
            Color memory fg = palettes[i][colorIndex(tokenLayers[i].hexString, k, index)];
            // Since most layer pixels are transparent, performing this check first saves gas
            if (fg.alpha == 0) {
                continue;
            } else if (fg.alpha == 255) {
                return fg.hexString;
            } else {
                for (uint256 j = i - 1; j >= 0; j--) {
                    Color memory bg = palettes[j][colorIndex(tokenLayers[j].hexString, k, index)];
                    /* As a simplification, blend with first non-transparent layer then stop.
                    We won't generally have overlapping semi-transparent pixels.
                    */
                    if (bg.alpha > 0) {
                        return Base64.encode(bytes(blendColors(fg, bg)));
                    }
                }
            }
        }
        return "000000";
    }

    /*
    Each color index is 3 bits (there are 8 colors, so 3 bits are needed to index into them).
    Since 3 bits doesn't divide cleanly into 8 bits (1 byte), we look up colors 24 bits (3 bytes) at a time.
    "k" is the starting byte index, and "index" is the color index within the 3 bytes starting at k.
    */
    function colorIndex(bytes memory data, uint k, uint index) internal pure returns (uint8) {
        if (index == 0) {
            return uint8(data[k]) >> 5;
        } else if (index == 1) {
            return (uint8(data[k]) >> 2) % 8;
        } else if (index == 2) {
            return ((uint8(data[k]) % 4) * 2) + (uint8(data[k + 1]) >> 7);
        } else if (index == 3) {
            return (uint8(data[k + 1]) >> 4) % 8;
        } else if (index == 4) {
            return (uint8(data[k + 1]) >> 1) % 8;
        } else if (index == 5) {
            return ((uint8(data[k + 1]) % 2) * 4) + (uint8(data[k + 2]) >> 6);
        } else if (index == 6) {
            return (uint8(data[k + 2]) >> 3) % 8;
        } else {
            return uint8(data[k + 2]) % 8;
        }
    }

    function colorIndexDataK(bytes memory data, uint k, uint index) internal pure returns (uint8) {
        if (index == 0) {
            return uint8(data[k]);
        } else if (index == 1) {
            return (uint8(data[k]));
        } else if (index == 2) {
            return ((uint8(data[k])) + (uint8(data[k + 1])));
        } else if (index == 3) {
            return (uint8(data[k + 1]));
        } else if (index == 4) {
            return (uint8(data[k + 1]));
        } else if (index == 5) {
            return ((uint8(data[k + 1])) + (uint8(data[k + 2])));
        } else if (index == 6) {
            return (uint8(data[k + 2]));
        } else {
            return uint8(data[k + 2]);
        }
    }

    function generateNameSVG(string memory name, string memory surname) internal pure returns (string memory) {
            return Base64.encode(bytes(string(abi.encodePacked(
            ' <text text-rendering="optimizeSpeed" height="0" x="0" y="20" fill="#00000" id="name"> ',
            name,
            ' ',
            surname,
            ' <animate xlink:href="#name" attributeName="x" from="-40" to="330" dur="10s" begin="0s" repeatCount="indefinite" id="nameAnim"/> </text> '
        ))));
    }

    /*
    Create 4 svg rects, pre-base64 encoding the svg constants to save gas.
    */
    function pixel4(string[32] memory lookup, SVGCursor memory cursor) internal pure returns (string memory result) {
        return string(abi.encodePacked(
                "PHJlY3QgICBmaWxsPScj", cursor.color1, "JyAgeD0n", lookup[cursor.x], "JyAgeT0n", lookup[cursor.y],
                "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color2, "JyAgeD0n", lookup[cursor.x + 1], "JyAgeT0n", lookup[cursor.y],
                "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color3, "JyAgeD0n", lookup[cursor.x + 2], "JyAgeT0n", lookup[cursor.y],
                "JyAvPjxyZWN0ICBmaWxsPScj", cursor.color4, "JyAgeD0n", lookup[cursor.x + 3], "JyAgeT0n", lookup[cursor.y], "JyAgIC8+"
            ));
    }

    /*
    Blend colors, inspired by https://stackoverflow.com/a/12016968
    */
    function blendColors(Color memory fg, Color memory bg) internal pure returns (string memory) {
        uint alpha = uint16(fg.alpha + 1);
        uint inv_alpha = uint16(256 - fg.alpha);
        return uintToHexString6(uint24((alpha * fg.blue + inv_alpha * bg.blue) >> 8) + (uint24((alpha * fg.green + inv_alpha * bg.green) >> 8) << 8) + (uint24((alpha * fg.red + inv_alpha * bg.red) >> 8) << 16));
    }

    function splitNumber(uint256 _number) internal pure returns (uint16[13] memory numbers) {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % 10000);
            _number >>= 14;
        }
        return numbers;
    }

    function uintToHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        revert();
    }

    /*
    Convert uint to hex string, padding to 6 hex nibbles
    */
    function uintToHexString6(uint a) internal pure returns (string memory) {
        string memory str = uintToHexString2(a);
        if (bytes(str).length == 2) {
            return string(abi.encodePacked("0000", str));
        } else if (bytes(str).length == 3) {
            return string(abi.encodePacked("000", str));
        } else if (bytes(str).length == 4) {
            return string(abi.encodePacked("00", str));
        } else if (bytes(str).length == 5) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /*
    Convert uint to hex string, padding to 2 hex nibbles
    */
    function uintToHexString2(uint a) internal pure returns (string memory) {
        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i = 0; i < count; ++i) {
            b = a % 16;
            res[count - i - 1] = uintToHexDigit(uint8(b));
            a /= 16;
        }

        string memory str = string(res);
        if (bytes(str).length == 0) {
            return "00";
        } else if (bytes(str).length == 1) {
            return string(abi.encodePacked("0", str));
        }
        return str;
    }

    /*
    Convert uint to byte string, padding number string with spaces at end.
    Useful to ensure result's length is a multiple of 3, and therefore base64 encoding won't
    result in '=' padding chars.
    */
    function uintToByteString(uint a, uint fixedLen) internal pure returns (bytes memory _uintAsString) {
        uint j = a;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(fixedLen);
        j = fixedLen;
        if (a == 0) {
            bstr[0] = "0";
            len = 1;
        }
        while (j > len) {
            j = j - 1;
            bstr[j] = bytes1(' ');
        }
        uint k = len;
        while (a != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(a - a / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            a /= 10;
        }
        return bstr;
    }

    function byteToUint(bytes1 b) internal pure returns (uint) {
        return uint(uint8(b));
    }

    function byteToHexString(bytes1 b) internal pure returns (string memory) {
        return uintToHexString2(byteToUint(b));
    }


    function rgbToHex(uint r,uint g, uint b) internal view returns (string memory) { 
        return string(Base64.encode(abi.encodePacked(uintToHexString2(r),uintToHexString2(g),uintToHexString2(b))));
    }

    function aging(Color memory inPalette, uint agingType) internal view returns (Color memory){
        if(agingType == 1){
            inPalette.red = 80;
            inPalette.green = 80;
            inPalette.blue = 80;
            string memory hexColor = rgbToHex(inPalette.red, inPalette.green, inPalette.blue); 
            inPalette.hexString = hexColor;
        } else if (agingType == 2) {
            inPalette.red = 210;
            inPalette.green = 210;
            inPalette.blue = 210;
            string memory hexColor = rgbToHex(inPalette.red, inPalette.green, inPalette.blue); 
            inPalette.hexString = hexColor;
        } else {
            inPalette.red += 50;
            inPalette.green += 50;
            inPalette.blue += 50;
            string memory hexColor = rgbToHex(inPalette.red, inPalette.green, inPalette.blue); 
            inPalette.hexString = hexColor;
        }

        return inPalette;
    }


    // Convert an hexadecimal character to their value
    function fromHexChar(uint8 c) internal pure returns (uint8) {
        if (bytes1(c) >= bytes1('0') && bytes1(c) <= bytes1('9')) {
            return c - uint8(bytes1('0'));
        }
        if (bytes1(c) >= bytes1('a') && bytes1(c) <= bytes1('f')) {
            return 10 + c - uint8(bytes1('a'));
        }
        if (bytes1(c) >= bytes1('A') && bytes1(c) <= bytes1('F')) {
            return 10 + c - uint8(bytes1('A'));
        }
    }

    // Convert an hexadecimal string to raw bytes
    function fromHex(string memory _s) internal pure returns (bytes memory) {
        bytes memory ss = bytes(_s);
        require(ss.length%2 == 0); // length must be even
        bytes memory r = new bytes(ss.length/2);
        for (uint i=0; i<ss.length/2; ++i) {
            r[i] = bytes1(fromHexChar(uint8(ss[2*i])) * 16 +
                        fromHexChar(uint8(ss[2*i+1])));
        }
        return r;
    }

    function getShirtLayer(uint tokenId) internal view returns (Layer memory){
        AppStorage storage s = LibAppStorage.diamondStorage();
        address teamOwner = IChainBallers(s.chainBallersContract).ownerOf(tokenId);
        uint teamId = ITeamNFT(s.L1TeamNFTContract).tokenOfOwnerByIndex(teamOwner, 0);
        return s.shirts[teamId];
    }

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return owner_ The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) internal view returns (address owner_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        owner_ = s.chainBallers[_tokenId].owner;
        require(owner_ != address(0), "ChainballersFacet: invalid _tokenId");
    }


    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this.
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return balance_ The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) internal view returns (uint256 balance_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_owner != address(0), "AavegotchiFacet: _owner can't be address(0)");
        balance_ = s.ownerTokenIds[_owner].length;
    }

    /// @notice Get all the Ids of NFTs owned by an address
    /// @param _owner The address to check for the NFTs
    /// @return tokenIds_ an array of unsigned integers,each representing the tokenId of each NFT
    function tokenIdsOfOwner(address _owner) internal view returns (uint32[] memory tokenIds_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        tokenIds_ = s.ownerTokenIds[_owner];
    }

    function getSpecialTrait(uint _tokenId) internal view returns (string memory){
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.attributes[_tokenId].SpecialTrait;
    }

    function getCoachStyle(uint _tokenId) internal view returns (string memory){
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        return s.coachAttributes[_tokenId].Style;
    }

    function getSkillByIndex(uint _tokenId, uint idx) internal view returns (uint16){
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        if (idx == 0 ){ return s.attributes[_tokenId].Stamina;}
        if (idx == 1 ){ return s.attributes[_tokenId].Playmaking;}
        if (idx == 2 ){ return s.attributes[_tokenId].Scoring;}
        if (idx == 3 ){ return s.attributes[_tokenId].Winger;}
        if (idx == 4 ){ return s.attributes[_tokenId].Goalkeeping;}
        if (idx == 5 ){ return s.attributes[_tokenId].Passing;}
        if (idx == 6 ){ return s.attributes[_tokenId].Defending;}
        if (idx == 7 ){ return s.attributes[_tokenId].SetPieces;}
        if (idx == 9 ){ return s.attributes[_tokenId].LearningRate;}
    }

    function getCoachSkillByIndex(uint _tokenId, uint idx) internal view returns (uint16){
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        if (idx == 0 ){ return s.coachAttributes[_tokenId].Tactic;}
        if (idx == 1 ){ return s.coachAttributes[_tokenId].Offence;}
        if (idx == 2 ){ return s.coachAttributes[_tokenId].Defence;}
        if (idx == 3 ){ return s.coachAttributes[_tokenId].Motivation;}
    }

    function checkTeam(address owner, uint[] memory team) internal view {
        uint len = team.length;
        for (uint i = 0; i< len; i++){
            require(LibChainballers.ownerOf(team[i]) == owner,"Player not owned");
        }
    }

        
    function checkTeamNR(address owner, uint[] memory team) internal view returns (bool notOwner) {
        uint len = team.length;
        for (uint i = 0; i< len; i++){
            if (LibChainballers.ownerOf(team[i]) == owner){
                notOwner = true;
            }
        }
    }

    function createGame(uint teamHomeId, uint teamAwayId, uint gameTime) internal returns (uint){
        AppStorage storage s = LibAppStorage.diamondStorage();
        
        require(gameTime >= block.timestamp);
        s.gameIdCounter++;
        s.matches[s.gameIdCounter] = [teamHomeId,teamAwayId,gameTime];
        return s.gameIdCounter;
    }


    function getGameFormation(
        uint gameId, 
        uint side
    ) internal view returns (FormationType formationType, uint[] memory formation)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address owner = ITeamNFT(s.L1TeamNFTContract).ownerOf(s.matches[gameId][side-1]);
        formation = s.gamesLineup[gameId][side];
        formationType = s.gamesFormation[gameId][side];
        if(LibChainballers.checkTeamNR(owner, formation)){
            uint teamId = ITeamNFT(s.L1TeamNFTContract).tokenOfOwnerByIndex(owner,0);
            if (!LibChainballers.checkTeamNR(owner, s.teamDefaultFormation[teamId])){
                formation = s.teamDefaultFormation[teamId];
                formationType = s.teamDefaultFormationType[teamId];
            } else {
                require(LibChainballers.balanceOf(owner)>10, "Not enough players");
                uint32[] memory allNFTs = LibChainballers.tokenIdsOfOwner(owner);
                for (uint i =0; i<11;i++){
                    formation[i] = allNFTs[i];
                }
                LibChainballers.checkTeam(owner, formation);
                formationType = FormationType.FourFourTwo;
            }
        }
    }

    // L2 HOOKS

    //@dev Hook to register data on L2 contract
    function _registerData(
        uint256 tokenId,
        uint dna, 
        string memory name, 
        string memory surname, 
        string memory mintType
    ) 
        internal 
    {
            AppStorage storage s = LibAppStorage.diamondStorage();
        
            bytes memory data;
            if (keccak256(abi.encodePacked(mintType)) == keccak256(abi.encodePacked("P"))){
                data = abi.encode(dna,name,surname,s.attributes[tokenId]);
            } else if (keccak256(abi.encodePacked(mintType)) == keccak256(abi.encodePacked("C"))){
                data = abi.encode(dna,name,surname,s.coachAttributes[tokenId]);
            }
            IL1CrossDomainMessenger(s.ovmL1CrossDomainMessenger).sendMessage(
            s.L2NFTContract, 
            abi.encodeWithSignature(
                "registerData(uint256,string,bytes)",
                tokenId, mintType,data
            ),
            1000000);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal
    {    
            AppStorage storage s = LibAppStorage.diamondStorage();
        
            IL1CrossDomainMessenger(s.ovmL1CrossDomainMessenger).sendMessage(
            s.L2NFTContract, 
            abi.encodeWithSignature(
                "safeTransferFrom(address,address,uint256,bytes)",
                from,to,tokenId,""
            ),
            1000000);
    }
 

    //// ------ ------- ////

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // uint16 selectorCount = uint16(diamondStorage().selectors.length);
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint16 selectorPosition = uint16(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
            ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = uint16(ds.facetAddresses.length);
            ds.facetAddresses.push(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            // add function
            ds.selectorToFacetAndPosition[selector].functionSelectorPosition = selectorPosition;
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(selector);
            ds.selectorToFacetAndPosition[selector].facetAddress = _facetAddress;
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint16(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = uint16(facetAddressPosition);
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.0;


/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../../interfaces/cb/IGameMaster.sol";
import "../../libraries/LibAppStorage.sol";

library LibLeagues {


    function getTeamLeague(uint teamId) internal view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.inLeague[teamId][1];
    }
    
    function createCup(uint[] memory teams) internal returns (uint){
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint leagueId = 1e18 + s.cupCounter;
        League storage league = s.leagues[leagueId];
        league.id = leagueId;
        league.teams = teams;
        s.cupCounter++;
        return leagueId;
    }

    function updateCupStanding(
        uint teamIdHome,
        uint teamIdAway,
        uint homeGoals,
        uint awayGoals
    ) 
        internal 
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint[] memory teams = s.cupTeams;
        uint idH = indexOf(teams,teamIdHome);
        uint idA = indexOf(teams,teamIdAway);
        // uint teamToPop;
        if (homeGoals > awayGoals) {
            // teamToPop = s.cupTeams[idA];
            s.cupTeams[idA] = s.cupTeams[s.cupTeams.length - 1];
            s.cupTeams.pop();
        } else {
            // teamToPop = s.cupTeams[idA];
            s.cupTeams[idH] = s.cupTeams[s.cupTeams.length - 1];
            s.cupTeams.pop();
        }
    }

    function inCup(uint teamId) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint len = s.cupTeams.length;
        uint flag = 0;
        for (uint i; i< len; i++){
            if (s.cupTeams[i] != teamId){ flag++;}
        }
        require(flag == 0," Already in cup");
    }

    function getTeamStandingPosition(uint teamId) internal view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint leagueId = getTeamLeague(teamId);
        League storage league = s.leagues[leagueId];
        uint idx = indexOf(league.teams,teamId);
        uint[2][] memory standing = league.standing;
        uint points = league.standing[idx][0];
        uint len = league.standing.length;
        uint pos = 1;
        for (uint i = 0; i < len; i++) {
            if (standing[i][0] > points){
                pos++;
            }
        }
        return pos;
    }

    function getUndisputedFirst(uint leagueId) internal view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        League storage league = s.leagues[leagueId];
        uint[2][] memory standing = league.standing;
        uint[] memory teams = league.teams;
        uint[] memory bestMatch = new uint[](3);
        uint len = league.standing.length;
        for (uint i = 0; i < len; i++) {
            // points
            if (standing[i][0] > bestMatch[0]){
                bestMatch[0] = standing[i][0];
                bestMatch[1] = standing[i][1];
                bestMatch[2] = i;
            } else if (standing[i][0] == bestMatch[0]){
                // num of wins
                if(standing[i][1] > bestMatch[1]){
                    bestMatch[0] = standing[i][0];
                    bestMatch[1] = standing[i][1];
                    bestMatch[2] = i;
                } else if (standing[i][1] == bestMatch[1]){
                    // longevity - can't be equal
                    if (teams[i] < teams[bestMatch[2]]){
                        bestMatch[0] = standing[i][0];
                        bestMatch[1] = standing[i][1];
                        bestMatch[2] = i;
                    }
                }
            } 
        }
        return teams[bestMatch[2]];
    }

    function getUndisputedFirstFour(uint leagueId) internal view returns (uint[] memory qualified) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        qualified = new uint[](4);
        League storage league = s.leagues[leagueId];
        uint[2][] memory standing = league.standing;
        uint[] memory teams = league.teams;
        uint[] memory bestMatch = new uint[](3);
        uint len = league.standing.length;
        for (uint qn = 0; qn < 4; qn++){
            if (qn>0){ 
                //zero out points to exclude prev team
                standing[bestMatch[2]][0] = 0;
                standing[bestMatch[2]][1] = 0;
                bestMatch = new uint[](3);
            } 
            for (uint i = 0; i < len; i++) {
                // points
                if (standing[i][0] > bestMatch[0]){
                    bestMatch[0] = standing[i][0];
                    bestMatch[1] = standing[i][1];
                    bestMatch[2] = i;
                } else if (standing[i][0] == bestMatch[0]){
                    // num of wins
                    if(standing[i][1] > bestMatch[1]){
                        bestMatch[0] = standing[i][0];
                        bestMatch[1] = standing[i][1];
                        bestMatch[2] = i;
                    } else if (standing[i][1] == bestMatch[1]){
                        // longevity - can't be equal
                        if (teams[i] < teams[bestMatch[2]]){
                            bestMatch[0] = standing[i][0];
                            bestMatch[1] = standing[i][1];
                            bestMatch[2] = i;
                        } else if (qn>0){
                            if (!isAlreadyQualified(teams[bestMatch[2]],qualified)){
                                bestMatch[0] = standing[i][0];
                                bestMatch[1] = standing[i][1];
                                bestMatch[2] = i;
                            }
                        }
                    }
                } 
            } 
            qualified[qn] = teams[bestMatch[2]];
        }
    }

    function getUndisputedLastTwo(uint leagueId) internal view returns (uint,uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        League storage league = s.leagues[leagueId];
        uint[2][] memory standing = league.standing;
        uint[] memory teams = league.teams;
        uint lastIdx = getUndisputedLastIndex(teams,standing);
        standing[lastIdx][0] = 1000; // last is now out of picture
        uint secondLastIdx = getUndisputedLastIndex(teams,standing);
        return (teams[lastIdx], teams[secondLastIdx]);
    }

    // Schedule matches of 'n' teams, plus game start time
    function allFixtures(uint startTime, uint interval) internal view returns ( uint[3][] memory fixtures){
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint[][] memory rounds = new uint[][]((s.NUM_LEAGUE_TEAMS*2)-1);
        fixtures = new uint[3][](s.NUM_LEAGUE_TEAMS*(s.NUM_LEAGUE_TEAMS-1));
        uint matchNum = 0;
        uint roundNum = 0;
        uint roundTracker = 0;
        for(uint i=0; i< s.NUM_LEAGUE_TEAMS-1; i++){
            rounds[i] = round(s.NUM_LEAGUE_TEAMS, i);
            for (uint j=0; j< rounds[i].length; j++){
                fixtures[matchNum][0] = j;
                fixtures[matchNum][1] = rounds[i][j];
                fixtures[matchNum][2] = startTime + (interval*roundNum);
                uint searchPeriod = roundTracker; // lookback window
                for(uint k=searchPeriod; k> 0;k--){
                    if (fixtures[matchNum-k][0] == rounds[i][j]){
                        // match belongs to second half schedule
                        fixtures[matchNum][2] = startTime + (interval*roundNum) + (interval*s.NUM_LEAGUE_ROUNDS/2);
                    } 
                }
                roundTracker++;
                if (roundTracker%s.NUM_LEAGUE_TEAMS == 0){
                    roundNum++; roundTracker = 0;
                }
                matchNum++;
            }
        }
    }

    // Schedule matches of 'n' teams, plus game start time - one-leg only
    function allFixturesCup(uint startTime, uint interval) internal view returns (uint[3][] memory fixtures){
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint[] memory rounds = new uint[]((s.NUM_LEAGUE_TEAMS*2)-1);
        fixtures = new uint[3][](s.NUM_LEAGUE_TEAMS*(s.NUM_LEAGUE_TEAMS-1));
        uint matchNum = 0;
        rounds = round(s.NUM_LEAGUE_TEAMS, 0);
        for (uint j=0; j< rounds.length; j++){
            fixtures[matchNum][0] = j;
            fixtures[matchNum][1] = rounds[j];
            fixtures[matchNum][2] = startTime + (interval);
            matchNum++;
        }
    }

    function setLeague(uint[] memory teams) internal returns (uint,uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.leaguesCounter++;
        League storage league = s.leagues[s.leaguesCounter];
        league.id = s.leaguesCounter;
        league.teams = teams;
        league.division = calcDivision(s.leaguesCounter);
        league.upgraded = true;
        league.rolled = true;
        updateInLeagueFirst(teams, s.leaguesCounter);
        return (s.leaguesCounter,league.division);
    }

    function setLeagueSchedule(uint leagueId, uint[4][] memory schedule) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        League storage league = s.leagues[leagueId];
        league.schedule = schedule;
    }

    function getLeagueTeams(uint leagueId) internal view returns (uint[] memory teams) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        League storage league = s.leagues[leagueId];
        teams = league.teams;
    }

    function getNextGame(uint teamId) internal view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint leagueId = getTeamLeague(teamId);
        League storage league = s.leagues[leagueId];
        uint[4][] memory schedule = league.schedule;
        uint len = schedule.length;
        uint[] memory bestMatch = new uint[](2);
        for (uint i = 0; i < len; i++){
            if (schedule[i][2] > block.timestamp) {
                uint h = schedule[i][0];
                uint a = schedule[i][1];
                if (h == teamId || a == teamId){
                    if (bestMatch[0] == 0 || bestMatch[0] > schedule[i][2]){
                        bestMatch[0] = schedule[i][2];
                        bestMatch[1] = schedule[i][3];
                    }
                }
            }
        }
        return bestMatch[1];
    }

    function updateStanding(
        uint teamIdHome,
        uint teamIdAway,
        uint homeGoals,
        uint awayGoals
    ) 
        internal 
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint divH = getTeamLeague(teamIdHome);
        uint divA = getTeamLeague(teamIdAway);
        if (divH == divA){
            League storage league = s.leagues[divA];
            uint[] memory teams = league.teams;
            uint idH = indexOf(teams,teamIdHome);
            uint idA = indexOf(teams,teamIdAway);
            if (homeGoals == awayGoals){
                league.standing[idH][0] += 1;
                league.standing[idA][0] += 1;
            } else if (homeGoals > awayGoals) {
                league.standing[idH][0] += 3;
                league.standing[idH][1]++;
            } else {
                league.standing[idA][0] += 3;
                league.standing[idA][1] ++;
            }
        } 
    }

    function assignCupSpots(uint[] memory leagueIds, uint[][] memory newQualified) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint len = newQualified.length;
        for (uint i = 0; i < len; i++){
            // only first 3 league tiers qualify
            if(leagueIds[i] <= 15){
                for (uint j = 0; j < 4; j++){
                    s.cupTeams.push(newQualified[i][j]);
                }
            }
        }
    }

    function buyCupLastSpot(uint teamId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.cupTeams.length > 60 && s.cupTeams.length < 65, "Not available");
        if (s.leaguesCounter >= 15){
            // if is not in s.cupTeams already
            inCup(teamId);
            // add team to s.cupTeams
            s.cupTeams.push(teamId);
        }
    }

    function changeCupFee(uint newFee) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.CUP_FEE = newFee;
    }

    function rollOver(uint leagueId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(!s.leagues[leagueId].rolled, "Already rolled");
        canRollOver(leagueId); // will revert otherwise
        League storage league = s.leagues[leagueId];
        uint[] memory teams = league.teams;
        uint idxOut1 = indexOf(teams,league.inOut[5]);
        uint idxOut2 = indexOf(teams,league.inOut[4]);
        uint idxOut3 = indexOf(teams,league.inOut[3]); 
        if (getParentLeague(leagueId)>0){
            // winner of league gets replaced by relegated from upper div
            teams[idxOut1] = league.inOut[2];
        }
        if (league.hasChildLeft){
            // last placed gets replaced from winner left child - if any
            teams[idxOut3] = league.inOut[0];
        } 
        if (league.hasChildRight){
            // second last placed gets replaced from winner right child - if any
            teams[idxOut2] = league.inOut[1];
        }
        updateInLeague(teams, leagueId);
        league.teams = teams;
        league.rolled = true;
    }

    function endOfSeason(uint[] memory leagueIds) internal returns (uint[][] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require( block.timestamp > s.seasonEnd, "Season not ended yet");
        uint len = leagueIds.length;
        uint[][] memory qualified = new uint[][](len);
        for (uint i = 0; i< len; i++){
            qualified[i] = getUndisputedFirstFour(leagueIds[i]);
            endOfSeasonPrep(leagueIds[i]);
            updateOut(leagueIds[i]);
            updateIn(leagueIds[i]);
        }
        return qualified;
    }

    function startNewSeason(uint leagueId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        canInitializeSeason(leagueId);
        League storage league = s.leagues[leagueId];
        league.standing = initStanding();
        (bool hasChildLeft, bool hasChildRight) = checkOnChildren(leagueId);
        league.hasChildLeft = hasChildLeft;
        league.hasChildRight = hasChildRight;
    }

    function getCupTeam(uint idx) internal view returns (uint){
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.cupTeams[idx];
    }

    function getCupFee() internal view returns (uint){
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.CUP_FEE;
    }

        // at the start of the season lower league doesnt exist -> teams wont be relegated
    function checkOnChildren(uint leagueId) internal view returns (bool,bool){
        AppStorage storage s = LibAppStorage.diamondStorage();
        (uint childLeft, uint childRight) = getChildrenLeagues(leagueId);
        return (childLeft<= s.leaguesCounter, childRight<= s.leaguesCounter);
    }

    function initStanding() internal view returns (uint[2][] memory cleanStanding) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        cleanStanding = new uint[2][](s.NUM_LEAGUE_TEAMS);
    }

    function updateInLeague(uint[] memory teams, uint leagueId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint len = teams.length;
        for(uint i =0; i< len; i++){
            // require(s.inLeague[teams[i]][0] == 0, "Team already in a league");
            s.inLeague[teams[i]][0] = 1;
            s.inLeague[teams[i]][1] = leagueId;
        }
    }

    function updateInLeagueFirst(uint[] memory teams, uint leagueId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint len = teams.length;
        for(uint i =0; i< len; i++){
            require(s.inLeague[teams[i]][0] == 0, "Team already in a league");
            s.inLeague[teams[i]][0] = 1;
            s.inLeague[teams[i]][1] = leagueId;
        }
    }

    function updateParentLeague(uint leagueId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        League storage league = s.leagues[leagueId];
        (bool hasChildLeft, bool hasChildRight) = checkOnChildren(leagueId);
        league.hasChildLeft = hasChildLeft;
        league.hasChildRight = hasChildRight;
    }

    function calcDivision(uint leagueId) internal pure returns (uint division){
        division = 1;
        uint cutoff;
        // 2m teams limit
        for (uint i=0; i< 20; i++){
            cutoff += 2**i;
            if (leagueId > cutoff){
                division++;
            } else {
                break;
            }
        }
    }

    function canRollOver(uint leagueId) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // its own, the upper league and the two children need to be finalised
        uint parentLeague = getParentLeague(leagueId);
        (uint childLeague1, uint childLeague2) = getChildrenLeagues(leagueId);
        require(s.leagues[leagueId].upgraded,"End of Season not finalized");
        if (parentLeague>0){
            require(s.leagues[parentLeague].upgraded,"Parent eos not finalized");
        }
        if (s.leagues[leagueId].hasChildLeft){
            require(s.leagues[childLeague1].upgraded,"Child eos not finalized");
        }
        if (s.leagues[leagueId].hasChildRight){
            require(s.leagues[childLeague2].upgraded,"Child eos not finalized");
        }
    }

    function canInitializeSeason(uint leagueId) internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(s.leagues[leagueId].rolled,"End of Season not rolled");
    }

    function endOfSeasonPrep(uint leagueId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        League storage league = s.leagues[leagueId];
        league.upgraded = false;
        league.rolled = false;
    }

    function updateOut(uint leagueId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        League storage league = s.leagues[leagueId];
        require(!league.upgraded, "Already upgraded");
        uint first = getUndisputedFirst(leagueId);
        (uint last, uint secondLast) = getUndisputedLastTwo(leagueId);
        league.inOut[5] = first;
        league.inOut[4] = secondLast;
        league.inOut[3] = last;
    }

    function updateIn(uint leagueId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        League storage league = s.leagues[leagueId];
        require(!league.upgraded, "Already upgraded");
        uint fromAbove;
        uint upperLeague = getParentLeague(leagueId);
        if (leagueId > 1){
            (uint last, uint secondLast) = getUndisputedLastTwo(upperLeague);
            if ( leagueId == 3 || leagueId%upperLeague != 0) {
                // is right child - gets last
                fromAbove = last;
            } else {  
                // is left child - gets second last
                fromAbove = secondLast;
            }
        } else {
            fromAbove = 0;
        }
        (uint childLeagueLeft, uint childLeagueRight) = getChildrenLeagues(leagueId);
        (uint fromBottomL, uint fromBottomR) = getUndisputedLastTwo(leagueId);
        if (childLeagueLeft < s.leaguesCounter){
            fromBottomL = getUndisputedFirst(childLeagueLeft);
        }
        if (childLeagueRight < s.leaguesCounter){
            fromBottomR = getUndisputedFirst(childLeagueRight);
        }
        
        league.inOut[0] = fromBottomL;
        league.inOut[1] = fromBottomR;
        league.inOut[2] = fromAbove;
        league.upgraded = true; // here because updateIn is after updateOut
    }

    function getParentLeague(uint leagueId) internal pure returns (uint){
        return (leagueId/2); // solc compiles as floor.math
    }

    function getChildrenLeagues(uint leagueId) internal pure returns (uint,uint){
        return (leagueId*2,leagueId*2+1); // sol implicitly gives floor.math
    }

    function isAlreadyQualified(uint teamId, uint[] memory qualified) internal pure returns (bool) {
        return (teamId != qualified[0] && teamId != qualified[1] && teamId != qualified[2] && teamId != qualified[3]);
    }

    function getUndisputedLastIndex(uint[] memory teams,uint[2][] memory standing) internal pure returns (uint) {
        uint[] memory bestMatch = new uint[](3);
        bestMatch[0] == 1000; // just an imp high starting point
        uint len = standing.length;
        for (uint i = 0; i < len; i++) {
            // points
            if (standing[i][0] < bestMatch[0]){
                bestMatch[0] = standing[i][0];
                bestMatch[1] = standing[i][1];
                bestMatch[2] = i;
            } else if (standing[i][0] == bestMatch[0]){
                // num of wins
                if(standing[i][1] < bestMatch[1]){
                    bestMatch[0] = standing[i][0];
                    bestMatch[1] = standing[i][1];
                    bestMatch[2] = i;
                } else if (standing[i][1] == bestMatch[1]){
                    // longevity - can't be equal
                    if (teams[i] > teams[bestMatch[2]]){
                        bestMatch[0] = standing[i][0];
                        bestMatch[1] = standing[i][1];
                        bestMatch[2] = i;
                    }
                }
            } 
        }
        return bestMatch[2];
    }

    function leaguesCounter() internal view returns (uint) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.leaguesCounter;
    }

    function indexOf(uint[] memory arr, uint searchFor ) internal pure returns (uint) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        return 400;
    }

    // Schedule single round `j` for 'n' teams:
    function round(uint n, uint j) internal pure returns (uint[] memory round_) {
        uint m = n - 1;
        round_ = new uint[](n);
        for(uint i =0; i< n; i++){
            round_[i] =  (m + j - i) % m; // circular shift
        }
        round_[round_[m] = j * (n >> 1) % m] = m; // swapping self-match
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge
*
/******************************************************************************/

import {IERC20} from "../../interfaces/IERC20.sol";

library LibERC20 {
    function transferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _value));
        handleReturn(success, result);
    }

    function transfer(
        address _token,
        address _to,
        uint256 _value
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_token)
        }
        require(size > 0, "LibERC20: ERC20 token address has no code");
        (bool success, bytes memory result) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _value));
        handleReturn(success, result);
    }

    function handleReturn(bool _success, bytes memory _result) internal pure {
        if (_success) {
            if (_result.length > 0) {
                require(abi.decode(_result, (bool)), "LibERC20: transfer or transferFrom returned false");
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(string(_result));
            } else {
                revert("LibERC20: transfer or transferFrom reverted");
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../interfaces/IERC721TokenReceiver.sol";

library LibERC721 {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    function checkOnERC721Received(
        address _operator,
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal {
        uint256 size;
        assembly {
            size := extcodesize(_to)
        }
        if (size > 0) {
            require(
                ERC721_RECEIVED == IERC721TokenReceiver(_to).onERC721Received(_operator, _from, _tokenId, _data),
                "AavegotchiFacet: Transfer rejected/failed by _to"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library LibMeta {
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(bytes("EIP712Domain(string name,string version,uint256 salt,address verifyingContract)"));

    function domainSeparator(string memory name, string memory version) internal view returns (bytes32 domainSeparator_) {
        domainSeparator_ = keccak256(
            abi.encode(EIP712_DOMAIN_TYPEHASH, keccak256(bytes(name)), keccak256(bytes(version)), getChainID(), address(this))
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}