// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

interface IBSCValidatorSet {
    function isCurrentValidator(address valAddress) external view returns (bool);
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

interface IEthereumLightClient {
    function finalizedExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot);
}

// SPDX-License-Identifier: MIT
//
// OpenZeppelin Contracts (v3.4.2-solc-0.7) (cryptography/ECDSA.sol)
// Diff:
// * Fixed: https://github.com/OpenZeppelin/openzeppelin-contracts/security/advisories/GHSA-4h98-2769-gh6h
// * Add `toTypedDataHash(bytes32, bytes32)` function

pragma solidity 0.8.18;

/// @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
///
/// These functions can be used to verify that a message was signed by the holder
/// of the private keys of a given address.
library ECDSA {
    /// @dev Returns the address that signed a hashed message (`hash`) with
    /// `signature`. This address can then be used for verification purposes.
    ///
    /// The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
    /// this function rejects them by requiring the `s` value to be in the lower
    /// half order, and the `v` value to be either 27 or 28.
    ///
    /// IMPORTANT: `hash` _must_ be the result of a hash operation for the
    /// verification to be secure: it is possible to craft signatures that
    /// recover to arbitrary addresses for non-hashed data. A safe way to ensure
    /// this is by receiving a hash of the original message (which may otherwise
    /// be too long), and then calling {toEthSignedMessageHash} on it.
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /// @dev Returns the address that signed a hashed message (`hash`) with
    /// `signature`. This address can then be used for verification purposes.
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        // Check the signature length
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098)
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);

        return recover(hash, v, r, s);
    }

    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "ECDSA: invalid signature 's' value"
        );
        if (v == 0 || v == 1) {
            v += 27;
        }
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /// @dev Returns an Ethereum Signed Message, created from a `hash`. This
    /// replicates the behavior of the
    /// https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
    /// JSON-RPC method.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /// @dev Returns an Ethereum Signed Typed Data, created from a
    /// `domainSeparator` and a `structHash`. This produces hash corresponding
    /// to the one signed with the
    /// https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
    /// JSON-RPC method as part of EIP-712.
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

pragma solidity 0.8.18;

library Memory {
    /**
     * Copies a part of bytes.
     * @param source original bytes
     * @param from the first index to be copied, data included
     * @param to the last index(to be copied) + 1, data excluded.
     */
    function range(bytes memory source, uint256 from, uint256 to) internal  pure returns (bytes memory) {
        if (from >= to) {
            return "";
        }

        require(from < source.length && from >= 0, 'Memory: from out of bounds');
        require(to <= source.length && to >= 0, 'Memory: to out of bounds');

        bytes memory result = new bytes(to - from);

        uint256 srcPtr;
        assembly {
            srcPtr := add(source, 0x20)
        }

        srcPtr += from;

        uint256 destPtr;
        assembly {
            destPtr := add(result, 0x20)
        }

        copy(destPtr, srcPtr, to - from);

        return result;
    }

    /**
     * Copies a piece of memory to another location
     * @notice From: https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol
     * @param _destPtr Destination location pointer
     * @param _srcPtr Source location pointer
     * @param _length Length of memory(in bytes) to be copied.
     */
    function copy(uint256 _destPtr, uint256 _srcPtr, uint256 _length) internal pure {
        uint256 destPtr = _destPtr;
        uint256 srcPtr = _srcPtr;
        uint256 remainingLength = _length;

        for (; remainingLength >= 32; remainingLength -= 32) {
            assembly {
                mstore(destPtr, mload(srcPtr))
            }
            destPtr += 32;
            srcPtr += 32;
        }

        uint256 mask;
        unchecked {
            mask = 256 ** (32 - remainingLength) - 1;
        }

        assembly {
            let srcPart := and(mload(srcPtr), not(mask))
            let destPart := and(mload(destPtr), mask)
            mstore(destPtr, or(destPart, srcPart))
        }
    }
}

// Inspired: https://github.com/ethereum-optimism/optimism/blob/develop/packages/contracts/contracts/libraries/rlp/Lib_RLPWriter.sol

pragma solidity 0.8.18;

import "./Memory.sol";

// import "hardhat/console.sol";

library RLPWriter {
    /**
     * RLP encodes bool
     * @param _input The bool value to be encoded
     * @return RLP encoded bool value in bytes
     */
    function writeBool(bool _input) internal pure returns (bytes memory) {
        bytes memory encoded = new bytes(1);
        encoded[0] = (_input ? bytes1(0x01) : bytes1(0x80));
        return encoded;
    }

    /**
     * RLP encodes bytes
     * @param _input The byte string to be encoded
     * @return RLP encoded string in bytes
     */
    function writeBytes(bytes memory _input) internal pure returns (bytes memory) {
        bytes memory encoded;

        // input ∈ [0x00, 0x7f]
        if (_input.length == 1 && uint8(_input[0]) < 128) {
            encoded = _input;
        } else {
            // Offset 0x80
            encoded = abi.encodePacked(_writeLength(_input.length, 128), _input);
        }

        return encoded;
    }

    /**
     * RLP encodes a list of RLP encoded items
     * @param _input The list of RLP encoded items
     * @return RLP encoded list of items in bytes
     */
    function writeList(bytes[] memory _input) internal pure returns (bytes memory) {
        bytes memory flatten = _flatten(_input);
        // offset 0xc0
        return abi.encodePacked(_writeLength(flatten.length, 192), flatten);
    }

    /**
     * RLP encodes a string
     * @param _input The string to be encoded
     * @return RLP encoded string in bytes
     */
    function writeString(string memory _input) internal pure returns (bytes memory) {
        return writeBytes(bytes(_input));
    }

    /**
     * RLP encodes an address
     * @param _input The address to be encoded
     * @return RLP encoded address in bytes
     */
    function writeAddress(address _input) internal pure returns (bytes memory) {
        return writeBytes(abi.encodePacked(_input));
    }

    /**
     * RLP encodes a uint256 value
     * @param _input The uint256 to be encoded
     * @return RLP encoded uint256 in bytes
     */
    function writeUint(uint256 _input) internal pure returns (bytes memory) {
        return writeBytes(_toBinary(_input));
    }

    /**
     * Encode offset + length as first byte, followed by length in hex display if needed
     * _offset: 0x80 for single item, 0xc0/192 for list
     * If length is greater than 55, offset should add 55. 0xb7 for single item, 0xf7 for list
     * @param _length The length of single item or list
     * @param _offset Type indicator
     * @return RLP encoded bytes
     */
    function _writeLength(uint256 _length, uint256 _offset) private pure returns (bytes memory) {
        bytes memory encoded;

        if (_length < 56) {
            encoded = new bytes(1);
            encoded[0] = bytes1(uint8(_offset) + uint8(_length));
        } else {
            uint256 hexLengthForInputLength = 0;
            uint256 index = 1;
            while (_length / index != 0) {
                index *= 256;
                hexLengthForInputLength++;
            }
            encoded = new bytes(hexLengthForInputLength + 1);

            // 0x80 + 55 = 0xb7
            // 0xc0 + 55 = 0xf7
            encoded[0] = bytes1(uint8(_offset) + 55 + uint8(hexLengthForInputLength));
            for (index = 1; index <= hexLengthForInputLength; index++) {
                encoded[index] = bytes1(uint8((_length / (256**(hexLengthForInputLength - index))) % 256));
            }
        }

        return encoded;
    }

    function toBinary(uint256 _input) internal pure returns (bytes memory) {
        return _toBinary(_input);
    }

    /**
     * Encode integer into big endian without leading zeros
     * @param _input The integer to be encoded
     * @return RLP encoded bytes
     */
    function _toBinary(uint256 _input) private pure returns (bytes memory) {
        // if input value is 0, return 0x00
        if (_input == 0) {
            bytes memory zeroResult = new bytes(1);
            zeroResult[0] = 0;
            return zeroResult;
        }

        bytes memory data = abi.encodePacked(_input);

        uint8 index = 0;
        for (; index < 32; ) {
            if (data[index] != 0) {
                break;
            }

            unchecked {
                ++index;
            }
        }

        bytes memory result = new bytes(32 - index);
        uint256 resultPtr;
        assembly {
            resultPtr := add(result, 0x20)
        }

        uint256 dataPtr;
        assembly {
            dataPtr := add(data, 0x20)
        }

        Memory.copy(resultPtr, dataPtr + index, 32 - index);

        return result;
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

        uint256 length = 0;
        uint256 index = 0;

        for (; index < _list.length; ) {
            length += _list[index].length;
            unchecked {
                ++index;
            }
        }

        bytes memory flattened = new bytes(length);
        uint256 flattenedPtr;
        assembly {
            flattenedPtr := add(flattened, 0x20)
        }

        for (index = 0; index < _list.length; ) {
            bytes memory item = _list[index];
            uint256 itemPtr;
            assembly {
                itemPtr := add(item, 0x20)
            }

            Memory.copy(flattenedPtr, itemPtr, item.length);
            flattenedPtr += _list[index].length;

            unchecked {
                ++index;
            }
        }

        return flattened;
    }
}

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.18;

import "../bsc-tendermint/interfaces/IBSCValidatorSet.sol";
import "../interfaces/IEthereumLightClient.sol";

import "./libraries/ECDSA.sol";
import "./libraries/Memory.sol";
import "./libraries/RLPWriter.sol";

// Sample header
// curl --location --request POST 'https://bsc.getblock.io/API_KEY/testnet/'
//  -H "Content-Type: application/json"
//  --data-raw '{"jsonrpc": "2.0", "method": "eth_getBlockByNumber", "params": ["0x68B3", true], "id": "getblock.io"}'
// {
// "difficulty":"0x2",
// "extraData":"0xd983010000846765746889676f312e31322e3137856c696e7578000000000000c3daa60d95817e2789de3eafd44dc354fe804bf5f08059cde7c86bc1215941d022bf9609ca1dee2881baf2144aa93fc80082e6edd0b9f8eac16f327e7d59f16500",
// "gasLimit":"0x1c9c380",
// "gasUsed":"0x0",
// "hash":"0xc3fa2927a8e5b7cfbd575188a30c34994d3356607deb4c10d7fefe0dd5cdcc83",
// "logsBloom":"0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
// "miner":"0x35552c16704d214347f29fa77f77da6d75d7c752",
// "mixHash":"0x0000000000000000000000000000000000000000000000000000000000000000",
// "nonce":"0x0000000000000000",
// "number":"0x68b3",
// "parentHash":"0xbf4d16769b8fd946394957049eef29ed938da92454762fc6ac65e0364ea004c7",
// "receiptsRoot":"0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
// "sha3Uncles":"0x1dcc4de8dec75d7aab85b567b6ccd41ad312451b948a7413f0a142fd40d49347",
// "size":"0x261",
// "stateRoot":"0x7b5a72075082c31ec909afe5c5df032b6e7f19c686a9a408a2cb6b75dec072a3",
// "timestamp":"0x5f080818",
// "totalDifficulty":"0xd167",
// "transactions":[],
// "transactionsRoot":"0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
// "uncles":[]
// }

contract PoALightClient is IEthereumLightClient {
    using Memory for bytes;

    struct BNBHeaderInfo {
        bytes32 parentHash;
        bytes32 sha3Uncles;
        address miner;
        bytes32 stateRoot;
        bytes32 transactionsRoot;
        bytes32 receiptsRoot;
        bytes logsBloom;
        uint256 difficulty;
        uint256 number;
        uint64 gasLimit;
        uint64 gasUsed;
        uint64 timestamp;
        bytes extraData;
        bytes32 mixHash;
        bytes8 nonce;
    }

    IBSCValidatorSet public bscValidatorSet;

    uint64 number;
    bytes32 stateRoot;

    constructor(address _bscValidatorSet) {
        bscValidatorSet = IBSCValidatorSet(_bscValidatorSet);
        number = 0;
        stateRoot = hex"0000000000000000000000000000000000000000000000000000000000000000";
    }

    // Fixed number of extra-data prefix bytes reserved for signer vanity.
    // https://eips.ethereum.org/EIPS/eip-225
    uint256 private constant EXTRA_VANITY_LENGTH = 32;

    // Length of signer's signature
    uint256 private constant SIGNATURE_LENGTH = 65;

    uint64 private constant CHAIN_ID = 97;

    function updateHeader(BNBHeaderInfo calldata header) external {
        require(header.number > number, "PoALightClient: invalid block number");

        address signer = _retrieveSignerInfo(header);
        require(bscValidatorSet.isCurrentValidator(signer), "PoALightClient: invalid signer address");

        number = uint64(header.number);
        stateRoot = header.stateRoot;
    }

    function _retrieveSignerInfo(BNBHeaderInfo calldata header) internal pure returns (address signer) {
        bytes memory extraData = header.extraData;

        require(extraData.length > EXTRA_VANITY_LENGTH, "PoALightClient: invalid extra data for vanity");
        require(
            extraData.length >= EXTRA_VANITY_LENGTH + SIGNATURE_LENGTH,
            "PoALightClient: invalid extra data for signature"
        );

        // data: [0, extraData.length - SIGNATURE_LENGTH)
        // signature: [extraData.length - SIGNATURE_LENGTH, extraData.length)
        bytes memory extraDataWithoutSignature = Memory.range(extraData, 0, extraData.length - SIGNATURE_LENGTH);
        bytes memory signature = Memory.range(extraData, extraData.length - SIGNATURE_LENGTH, extraData.length);

        require(signature.length == SIGNATURE_LENGTH, "PoALightClient: signature retrieval failed");
        BNBHeaderInfo memory unsignedHeader = BNBHeaderInfo({
            difficulty: header.difficulty,
            extraData: extraDataWithoutSignature,
            gasLimit: header.gasLimit,
            gasUsed: header.gasUsed,
            logsBloom: header.logsBloom,
            miner: header.miner,
            mixHash: header.mixHash,
            nonce: header.nonce,
            number: header.number,
            parentHash: header.parentHash,
            receiptsRoot: header.receiptsRoot,
            sha3Uncles: header.sha3Uncles,
            stateRoot: header.stateRoot,
            timestamp: header.timestamp,
            transactionsRoot: header.transactionsRoot
        });

        bytes32 message = _hashHeaderWithChainId(unsignedHeader, CHAIN_ID);

        return ECDSA.recover(message, signature);
    }

    function _hashHeaderWithChainId(BNBHeaderInfo memory header, uint64 chainId) internal pure returns (bytes32) {
        bytes[] memory list = new bytes[](16);

        list[0] = RLPWriter.writeUint(chainId);
        list[1] = RLPWriter.writeBytes(abi.encodePacked(header.parentHash));
        list[2] = RLPWriter.writeBytes(abi.encodePacked(header.sha3Uncles));
        list[3] = RLPWriter.writeAddress(header.miner);
        list[4] = RLPWriter.writeBytes(abi.encodePacked(header.stateRoot));
        list[5] = RLPWriter.writeBytes(abi.encodePacked(header.transactionsRoot));
        list[6] = RLPWriter.writeBytes(abi.encodePacked(header.receiptsRoot));
        list[7] = RLPWriter.writeBytes(header.logsBloom);
        list[8] = RLPWriter.writeUint(header.difficulty);
        list[9] = RLPWriter.writeUint(header.number);
        list[10] = RLPWriter.writeUint(header.gasLimit);
        list[11] = RLPWriter.writeUint(header.gasUsed);
        list[12] = RLPWriter.writeUint(header.timestamp);
        list[13] = RLPWriter.writeBytes(header.extraData);
        list[14] = RLPWriter.writeBytes(abi.encodePacked(header.mixHash));
        list[15] = RLPWriter.writeBytes(abi.encodePacked(header.nonce));

        return keccak256(RLPWriter.writeList(list));
    }

    function finalizedExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot) {
        return (stateRoot, number);
    }

    function optimisticExecutionStateRootAndSlot() external view returns (bytes32 root, uint64 slot) {
        return (stateRoot, number);
    }
}