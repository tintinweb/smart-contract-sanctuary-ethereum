// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IHeadersProcessor} from "./interfaces/IHeadersProcessor.sol";
import {IHeadersStorage} from "./interfaces/IHeadersStorage.sol";
import {ICommitmentsInbox} from "./interfaces/ICommitmentsInbox.sol";

import {EVMHeaderRLP} from "./lib/EVMHeaderRLP.sol";
import {Bitmap16} from "./lib/Bitmap16.sol";

contract HeadersProcessor is IHeadersProcessor, IHeadersStorage {
    using Bitmap16 for uint16;
    using EVMHeaderRLP for bytes;

    ICommitmentsInbox public immutable commitmentsInbox;

    uint256 public latestReceived;
    mapping(uint256 => bytes32) public receivedParentHashes;

    mapping(uint256 => bytes32) public parentHashes;
    mapping(uint256 => bytes32) public stateRoots;
    mapping(uint256 => bytes32) public receiptsRoots;
    mapping(uint256 => bytes32) public transactionsRoots;
    mapping(uint256 => bytes32) public unclesHashes;

    constructor(ICommitmentsInbox _commitmentsInbox) {
        commitmentsInbox = _commitmentsInbox;
    }

    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external onlyCommitmentsInbox {
        if (blockNumber > latestReceived) {
            latestReceived = blockNumber;
        }
        receivedParentHashes[blockNumber] = parentHash;
    }

    function processBlock(
        uint16 paramsBitmap,
        uint256 blockNumber,
        bytes calldata headerSerialized
    ) external {
        bytes32 expectedHash = parentHashes[blockNumber + 1];
        if (expectedHash == bytes32(0)) {
            expectedHash = receivedParentHashes[blockNumber + 1];
        }
        require(expectedHash != bytes32(0), "ERR_NO_REFERENCE_HASH");

        bool isValid = isHeaderValid(expectedHash, headerSerialized);
        require(isValid, "ERR_INVALID_HEADER");

        _processBlock(paramsBitmap, blockNumber, headerSerialized);
    }

    function _processBlock(
        uint16 paramsBitmap,
        uint256 blockNumber,
        bytes calldata headerSerialized
    ) internal {
        bytes32 parentHash = headerSerialized.getParentHash();
        parentHashes[blockNumber] = parentHash;

        // Uncles hash
        if (paramsBitmap.readBitAtIndexFromRight(1)) {
            bytes32 unclesHash = headerSerialized.getUnclesHash();
            unclesHashes[blockNumber] = unclesHash;
        }

        // State root
        if (paramsBitmap.readBitAtIndexFromRight(3)) {
            bytes32 stateRoot = headerSerialized.getStateRoot();
            stateRoots[blockNumber] = stateRoot;
        }

        // Transactions root
        if (paramsBitmap.readBitAtIndexFromRight(4)) {
            bytes32 transactionsRoot = headerSerialized.getTransactionsRoot();
            transactionsRoots[blockNumber] = transactionsRoot;
        }

        // Receipts root
        if (paramsBitmap.readBitAtIndexFromRight(5)) {
            bytes32 receiptsRoot = headerSerialized.getReceiptsRoot();
            receiptsRoots[blockNumber] = receiptsRoot;
        }
    }

    function isHeaderValid(bytes32 hash, bytes memory header) public pure returns (bool) {
        return keccak256(header) == hash;
    }

    modifier onlyCommitmentsInbox() {
        require(msg.sender == address(commitmentsInbox), "ERR_ONLY_INBOX");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHeadersProcessor {
    function receiveParentHash(uint256 blockNumber, bytes32 parentHash) external;

    function receivedParentHashes(uint256) external view returns (bytes32);
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

interface ICommitmentsInbox {
    event FraudProven(uint256 fraudaulentBlock, bytes32 validParentHash, bytes32 invalidParentHash, address penaltyRecipient);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// This library extracts data from Block header encoded in RLP format.
// It is not a complete implementation, but optimized for specific cases - thus many hardcoded values.
// Here's the current RLP structure and the values we're looking for:
//
// idx  Element                 element length with 1 byte storing its length
// ==========================================================================
// Static elements (always same size):
//
// 0    RLP length              1+2
// 1    parentHash              1+32
// 2    ommersHash              1+32
// 3    beneficiary             1+20
// 4    stateRoot               1+32
// 5    TransactionRoot         1+32
// 6    receiptsRoot            1+32
//      logsBloom length        1+2
// 7    logsBloom               256
//                              =========
//  Total static elements size: 448 bytes
//
// Dynamic elements (need to read length) start at position 448
// and each one is preceeded with 1 byte length (if element is >= 128)
// or if element is < 128 - then length byte is skipped and it is just the 1-byte element:
//
// 8	difficulty  - starts at pos 448
// 9	number      - blockNumber
// 10	gasLimit
// 11	gasUsed
// 12	timestamp
// 13	extraData
// 14	mixHash
// 15	nonce

// SAFEMATH DISCLAIMER:
// We and don't use SafeMath here intentionally, because input values are bytes in a byte-array, thus limited to 255
library EVMHeaderRLP {
    function nextElementJump(uint8 prefix) public pure returns (uint8) {
        // RLP has much more options for element lenghts
        // But we are safe between 56 bytes and 2MB
        if (prefix <= 128) {
            return 1;
        } else if (prefix <= 183) {
            return prefix - 128 + 1;
        }
        revert("EVMHeaderRLP.nextElementJump: Given element length not implemented");
    }

    // no loop saves ~300 gas
    function getBlockNumberPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    // no loop saves ~300 gas
    function getGasLimitPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    // no loop saves ~300 gas
    function getTimestampPositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        uint256 pos;
        //jumpting straight to the 1st dynamic element at pos 448 - difficulty
        pos = 448;
        //2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        //3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        //4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        //timestamp - jackpot!
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function getBaseFeePositionNoLoop(bytes memory rlp) public pure returns (uint256) {
        //jumping straight to the 1st dynamic element at pos 448 - difficulty
        uint256 pos = 448;

        // 2nd element - block number
        pos += nextElementJump(uint8(rlp[pos]));
        // 3rd element - gas limit
        pos += nextElementJump(uint8(rlp[pos]));
        // 4th element - gas used
        pos += nextElementJump(uint8(rlp[pos]));
        // timestamp
        pos += nextElementJump(uint8(rlp[pos]));
        // extradata
        pos += nextElementJump(uint8(rlp[pos]));
        // mixhash
        pos += nextElementJump(uint8(rlp[pos]));
        // nonce
        pos += nextElementJump(uint8(rlp[pos]));
        // nonce
        pos += nextElementJump(uint8(rlp[pos]));

        return pos;
    }

    function extractFromRLP(bytes calldata rlp, uint256 elementPosition) public pure returns (uint256 element) {
        // RLP hint: If the byte is less than 128 - than this byte IS the value needed - just return it.
        if (uint8(rlp[elementPosition]) < 128) {
            return uint256(uint8(rlp[elementPosition]));
        }

        // RLP hint: Otherwise - this byte stores the length of the element needed (in bytes).
        uint8 elementSize = uint8(rlp[elementPosition]) - 128;

        // ABI Encoding hint for dynamic bytes element:
        //  0x00-0x04 (4 bytes): Function signature
        //  0x05-0x23 (32 bytes uint): Offset to raw data of RLP[]
        //  0x24-0x43 (32 bytes uint): Length of RLP's raw data (in bytes)
        //  0x44-.... The RLP raw data starts here
        //  0x44 + elementPosition: 1 byte stores a length of our element
        //  0x44 + elementPosition + 1: Raw data of the element

        // Copies the element from calldata to uint256 stored in memory
        assembly {
            calldatacopy(
                add(mload(0x40), sub(32, elementSize)), // Copy to: Memory 0x40 (free memory pointer) + 32bytes (uint256 size) - length of our element (in bytes)
                add(0x44, add(elementPosition, 1)), // Copy from: Calldata 0x44 (RLP raw data offset) + elementPosition + 1 byte for the size of element
                elementSize
            )
            element := mload(mload(0x40)) // Load the 32 bytes (uint256) stored at memory 0x40 pointer - into return value
        }
        return element;
    }

    function getBlockNumber(bytes calldata rlp) public pure returns (uint256 bn) {
        return extractFromRLP(rlp, getBlockNumberPositionNoLoop(rlp));
    }

    function getTimestamp(bytes calldata rlp) external pure returns (uint256 ts) {
        return extractFromRLP(rlp, getTimestampPositionNoLoop(rlp));
    }

    function getDifficulty(bytes calldata rlp) external pure returns (uint256 diff) {
        return extractFromRLP(rlp, 448);
    }

    function getGasLimit(bytes calldata rlp) external pure returns (uint256 gasLimit) {
        return extractFromRLP(rlp, getGasLimitPositionNoLoop(rlp));
    }

    function getBaseFee(bytes calldata rlp) external pure returns (uint256 baseFee) {
        return extractFromRLP(rlp, getBaseFeePositionNoLoop(rlp));
    }

    function getParentHash(bytes calldata rlp) external pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 3));
    }

    function getUnclesHash(bytes calldata rlp) external pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 36));
    }

    function getBeneficiary(bytes calldata rlp) external pure returns (address) {
        return address(uint160(extractFromRLP(rlp, 70)));
    }

    function getStateRoot(bytes calldata rlp) external pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 90));
    }

    function getTransactionsRoot(bytes calldata rlp) external pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 123));
    }

    function getReceiptsRoot(bytes calldata rlp) external pure returns (bytes32) {
        return bytes32(extractFromRLP(rlp, 156));
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