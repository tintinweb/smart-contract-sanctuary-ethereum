// SPDX-License-Identifier: TBD
pragma solidity ^0.8.2;

import "./Bytes.sol";
import {TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS, SignedHeader, BlockID, Timestamp, ValidatorSet, Duration, Fraction, Commit, Validator, CommitSig, CanonicalVote, Vote} from "./proto/TendermintLight.sol";
import "./proto/TendermintHelper.sol";
import "./proto/Encoder.sol";
import "../Ed25519Verifier.sol";
import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

library Tendermint {
    using Bytes for bytes;
    using Bytes for bytes32;
    using TendermintHelper for ValidatorSet.Data;
    using TendermintHelper for SignedHeader.Data;
    using TendermintHelper for Timestamp.Data;
    using TendermintHelper for BlockID.Data;
    using TendermintHelper for Commit.Data;
    using TendermintHelper for Vote.Data;

    // TODO: Change visibility to public for deployment. For some reason have to use internal for abigen.
    function verify(
        SignedHeader.Data memory trustedHeader,
        SignedHeader.Data memory untrustedHeader,
        ValidatorSet.Data memory untrustedVals,
        address verifier,
        uint256[2] memory proofA,
        uint256[2][2] memory proofB,
        uint256[2] memory proofC,
        uint256[2] memory proofCommit,
        uint256 proofCommitPub
    ) internal view returns (bool) {
        verifyNewHeaderAndVals(untrustedHeader, untrustedVals, trustedHeader);

        // Check the validator hashes are the same
        require(
            untrustedHeader.header.validators_hash.toBytes32() == trustedHeader.header.next_validators_hash.toBytes32(),
            "expected old header next validators to match those from new header"
        );

        // Ensure that +2/3 of new validators signed correctly.
        bool ok = verifyCommitLight(
            untrustedVals,
            trustedHeader.header.chain_id,
            untrustedHeader.commit.block_id,
            untrustedHeader.header.height,
            untrustedHeader.commit,
            verifier,
            proofA,
            proofB,
            proofC,
            proofCommit,
            proofCommitPub
        );

        return ok;
    }

    function verifyNewHeaderAndVals(
        SignedHeader.Data memory untrustedHeader,
        ValidatorSet.Data memory untrustedVals,
        SignedHeader.Data memory trustedHeader
    ) internal pure {
        // SignedHeader validate basic
        require(
            keccak256(abi.encodePacked(untrustedHeader.header.chain_id)) ==
                keccak256(abi.encodePacked(trustedHeader.header.chain_id)),
            "header belongs to another chain"
        );
        require(untrustedHeader.commit.height == untrustedHeader.header.height, "header and commit height mismatch");

        bytes32 untrustedHeaderBlockHash = untrustedHeader.hash();
        // TODO: Fix block hash
        // require(
        //     untrustedHeaderBlockHash == untrustedHeader.commit.block_id.hash.toBytes32(),
        //     "commit signs signs block failed"
        // );

        require(
            untrustedHeader.header.height > trustedHeader.header.height,
            "expected new header height to be greater than one of old header"
        );

        // Skip time verification for now

        bytes32 validatorsHash = untrustedVals.hash();
        // TODO: Fix validators hash
        // require(
        //     untrustedHeader.header.validators_hash.toBytes32() == validatorsHash,
        //     "expected new header validators to match those that were supplied at height XX"
        // );
    }

    // VerifyCommitLight
    // Proof of concept header verification with batch signature SNARK proof
    function verifyCommitLight(
        ValidatorSet.Data memory vals,
        string memory chainID,
        BlockID.Data memory blockID,
        int64 height,
        Commit.Data memory commit,
        address verifier,
        uint256[2] memory proofA,
        uint256[2][2] memory proofB,
        uint256[2] memory proofC,
        uint256[2] memory proofCommit,
        uint256 proofCommitPub
    ) internal view returns (bool) {
        require(vals.validators.length == commit.signatures.length, "invalid commit signatures");
        require(commit.signatures.length > 8, "insufficient signatures");

        require(height == commit.height, "invalid commit height");

        require(commit.block_id.isEqual(blockID), "invalid commit -- wrong block ID");

        bytes[8] memory pubkeys;
        bytes[8] memory messages;
        uint256 sigCount;
        for (uint256 i = 0; i < commit.signatures.length; i++) {
            // no need to verify absent or nil votes.
            if (
                commit.signatures[i].block_id_flag !=
                TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.BlockIDFlag.BLOCK_ID_FLAG_COMMIT
            ) {
                continue;
            }

            pubkeys[sigCount] = vals.validators[i].pub_key.ed25519;
            messages[sigCount] = Encoder.encodeDelim(voteSignBytes(commit, chainID, i));

            sigCount++;
            if (sigCount == 8) {
                break;
            }
        }

        uint256[57] memory input = prepareInput(pubkeys, messages, proofCommitPub);
        return Ed25519Verifier(verifier).verifyProof(proofA, proofB, proofC, proofCommit, input);
    }

    function prepareInput(
        bytes[8] memory pubkeys,
        bytes[8] memory messages,
        uint256 proofCommitPub
    ) private pure returns (uint256[57] memory input) {
        for (uint256 i = 0; i < 8; i++) {
            bytes memory messagePart0 = BytesLib.slice(messages[i], 0, 25);
            bytes memory messagePart1 = BytesLib.slice(messages[i], 25, 25);
            bytes memory messagePart2 = BytesLib.slice(messages[i], 50, 25);
            bytes memory messagePart3 = BytesLib.slice(messages[i], 75, 25);
            bytes memory messagePart4 = BytesLib.slice(messages[i], 100, 22);
            input[5 * i] = uint256(uint200(bytes25(messagePart0)));
            input[5 * i + 1] = uint256(uint200(bytes25(messagePart1)));
            input[5 * i + 2] = uint256(uint200(bytes25(messagePart2)));
            input[5 * i + 3] = uint256(uint200(bytes25(messagePart3)));
            input[5 * i + 4] = uint256(uint176(bytes22(messagePart4)));
            bytes memory pubkeyHigh = BytesLib.slice(pubkeys[i], 0, 16);
            bytes memory pubkeyLow = BytesLib.slice(pubkeys[i], 16, 16);
            input[2 * i + 40] = uint256(uint128(bytes16(pubkeyHigh)));
            input[2 * i + 1 + 40] = uint256(uint128(bytes16(pubkeyLow)));
        }
        input[56] = proofCommitPub;
        return input;
    }

    function voteSignBytes(
        Commit.Data memory commit,
        string memory chainID,
        uint256 idx
    ) internal pure returns (bytes memory) {
        Vote.Data memory vote;
        vote = commit.toVote(idx);

        return CanonicalVote.encode(vote.toCanonicalVote(chainID));
    }

    function voteSignBytesDelim(
        Commit.Data memory commit,
        string memory chainID,
        uint256 idx
    ) internal pure returns (bytes memory) {
        return Encoder.encodeDelim(voteSignBytes(commit, chainID, idx));
    }
}

// SPDX-License-Identifier: TBD
pragma solidity ^0.8.2;

library Bytes {
    function toBytes32(bytes memory bz) internal pure returns (bytes32 ret) {
        require(bz.length == 32, "Bytes: toBytes32 invalid size");
        assembly {
            ret := mload(add(bz, 32))
        }
    }

    function toBytes(bytes32 data) public pure returns (bytes memory) {
        return abi.encodePacked(data);
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64 ret) {
        require(_bytes.length >= _start + 8, "Bytes: toUint64 out of bounds");
        assembly {
            ret := mload(add(add(_bytes, 0x8), _start))
        }
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "Bytes: toUint256 out of bounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toAddress(bytes memory _bytes) internal pure returns (address addr) {
        // convert last 20 bytes of keccak hash (bytes32) to address
        bytes32 hash = keccak256(_bytes);
        assembly {
            mstore(0, hash)
            addr := mload(0)
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
import "./ProtoBufRuntime.sol";
import "./GoogleProtobufAny.sol";

library Fraction {
    //struct definition
    struct Data {
        uint64 numerator;
        uint64 denominator;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_numerator(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_denominator(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_numerator(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.numerator = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_denominator(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.denominator = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.numerator != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_uint64(r.numerator, pointer, bs);
        }
        if (r.denominator != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_uint64(r.denominator, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_uint64(r.numerator);
        e += 1 + ProtoBufRuntime._sz_uint64(r.denominator);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.numerator != 0) {
            return false;
        }

        if (r.denominator != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.numerator = input.numerator;
        output.denominator = input.denominator;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library Fraction

library Duration {
    //struct definition
    struct Data {
        int64 Seconds;
        int32 nanos;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_Seconds(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_nanos(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_Seconds(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.Seconds = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_nanos(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.nanos = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.Seconds != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.Seconds, pointer, bs);
        }
        if (r.nanos != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int32(r.nanos, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_int64(r.Seconds);
        e += 1 + ProtoBufRuntime._sz_int32(r.nanos);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.Seconds != 0) {
            return false;
        }

        if (r.nanos != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.Seconds = input.Seconds;
        output.nanos = input.nanos;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library Duration

library Consensus {
    //struct definition
    struct Data {
        uint64 block;
        uint64 app;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_block(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_app(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_block(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.block = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_app(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (uint64 x, uint256 sz) = ProtoBufRuntime._decode_uint64(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.app = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.block != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_uint64(r.block, pointer, bs);
        }
        if (r.app != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_uint64(r.app, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_uint64(r.block);
        e += 1 + ProtoBufRuntime._sz_uint64(r.app);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.block != 0) {
            return false;
        }

        if (r.app != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.block = input.block;
        output.app = input.app;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library Consensus

library ClientState {
    //struct definition
    struct Data {
        string chain_id;
        Fraction.Data trust_level;
        Duration.Data trusting_period;
        Duration.Data unbonding_period;
        Duration.Data max_clock_drift;
        int64 frozen_height;
        int64 latest_height;
        bool allow_update_after_expiry;
        bool allow_update_after_misbehaviour;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[10] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_chain_id(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_trust_level(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_trusting_period(pointer, bs, r, counters);
            } else if (fieldId == 4) {
                pointer += _read_unbonding_period(pointer, bs, r, counters);
            } else if (fieldId == 5) {
                pointer += _read_max_clock_drift(pointer, bs, r, counters);
            } else if (fieldId == 6) {
                pointer += _read_frozen_height(pointer, bs, r, counters);
            } else if (fieldId == 7) {
                pointer += _read_latest_height(pointer, bs, r, counters);
            } else if (fieldId == 8) {
                pointer += _read_allow_update_after_expiry(pointer, bs, r, counters);
            } else if (fieldId == 9) {
                pointer += _read_allow_update_after_misbehaviour(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_chain_id(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.chain_id = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_trust_level(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Fraction.Data memory x, uint256 sz) = _decode_Fraction(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.trust_level = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_trusting_period(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Duration.Data memory x, uint256 sz) = _decode_Duration(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.trusting_period = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_unbonding_period(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Duration.Data memory x, uint256 sz) = _decode_Duration(p, bs);
        if (isNil(r)) {
            counters[4] += 1;
        } else {
            r.unbonding_period = x;
            if (counters[4] > 0) counters[4] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_max_clock_drift(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Duration.Data memory x, uint256 sz) = _decode_Duration(p, bs);
        if (isNil(r)) {
            counters[5] += 1;
        } else {
            r.max_clock_drift = x;
            if (counters[5] > 0) counters[5] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_frozen_height(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[6] += 1;
        } else {
            r.frozen_height = x;
            if (counters[6] > 0) counters[6] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_latest_height(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[7] += 1;
        } else {
            r.latest_height = x;
            if (counters[7] > 0) counters[7] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_allow_update_after_expiry(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bool x, uint256 sz) = ProtoBufRuntime._decode_bool(p, bs);
        if (isNil(r)) {
            counters[8] += 1;
        } else {
            r.allow_update_after_expiry = x;
            if (counters[8] > 0) counters[8] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_allow_update_after_misbehaviour(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[10] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bool x, uint256 sz) = ProtoBufRuntime._decode_bool(p, bs);
        if (isNil(r)) {
            counters[9] += 1;
        } else {
            r.allow_update_after_misbehaviour = x;
            if (counters[9] > 0) counters[9] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Fraction(uint256 p, bytes memory bs) internal pure returns (Fraction.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Fraction.Data memory r, ) = Fraction._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Duration(uint256 p, bytes memory bs) internal pure returns (Duration.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Duration.Data memory r, ) = Duration._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (bytes(r.chain_id).length != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_string(r.chain_id, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Fraction._encode_nested(r.trust_level, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Duration._encode_nested(r.trusting_period, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(4, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Duration._encode_nested(r.unbonding_period, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(5, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Duration._encode_nested(r.max_clock_drift, pointer, bs);

        if (r.frozen_height != 0) {
            pointer += ProtoBufRuntime._encode_key(6, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.frozen_height, pointer, bs);
        }
        if (r.latest_height != 0) {
            pointer += ProtoBufRuntime._encode_key(7, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.latest_height, pointer, bs);
        }
        if (r.allow_update_after_expiry != false) {
            pointer += ProtoBufRuntime._encode_key(8, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_bool(r.allow_update_after_expiry, pointer, bs);
        }
        if (r.allow_update_after_misbehaviour != false) {
            pointer += ProtoBufRuntime._encode_key(9, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_bool(r.allow_update_after_misbehaviour, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.chain_id).length);
        e += 1 + ProtoBufRuntime._sz_lendelim(Fraction._estimate(r.trust_level));
        e += 1 + ProtoBufRuntime._sz_lendelim(Duration._estimate(r.trusting_period));
        e += 1 + ProtoBufRuntime._sz_lendelim(Duration._estimate(r.unbonding_period));
        e += 1 + ProtoBufRuntime._sz_lendelim(Duration._estimate(r.max_clock_drift));
        e += 1 + ProtoBufRuntime._sz_int64(r.frozen_height);
        e += 1 + ProtoBufRuntime._sz_int64(r.latest_height);
        e += 1 + 1;
        e += 1 + 1;
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (bytes(r.chain_id).length != 0) {
            return false;
        }

        if (r.frozen_height != 0) {
            return false;
        }

        if (r.latest_height != 0) {
            return false;
        }

        if (r.allow_update_after_expiry != false) {
            return false;
        }

        if (r.allow_update_after_misbehaviour != false) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.chain_id = input.chain_id;
        Fraction.store(input.trust_level, output.trust_level);
        Duration.store(input.trusting_period, output.trusting_period);
        Duration.store(input.unbonding_period, output.unbonding_period);
        Duration.store(input.max_clock_drift, output.max_clock_drift);
        output.frozen_height = input.frozen_height;
        output.latest_height = input.latest_height;
        output.allow_update_after_expiry = input.allow_update_after_expiry;
        output.allow_update_after_misbehaviour = input.allow_update_after_misbehaviour;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library ClientState

library ConsensusState {
    //struct definition
    struct Data {
        Timestamp.Data timestamp;
        MerkleRoot.Data root;
        bytes next_validators_hash;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[4] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_timestamp(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_root(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_next_validators_hash(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_timestamp(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Timestamp.Data memory x, uint256 sz) = _decode_Timestamp(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.timestamp = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_root(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (MerkleRoot.Data memory x, uint256 sz) = _decode_MerkleRoot(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.root = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_next_validators_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.next_validators_hash = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Timestamp(uint256 p, bytes memory bs) internal pure returns (Timestamp.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Timestamp.Data memory r, ) = Timestamp._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_MerkleRoot(uint256 p, bytes memory bs) internal pure returns (MerkleRoot.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (MerkleRoot.Data memory r, ) = MerkleRoot._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Timestamp._encode_nested(r.timestamp, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += MerkleRoot._encode_nested(r.root, pointer, bs);

        if (r.next_validators_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.next_validators_hash, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(Timestamp._estimate(r.timestamp));
        e += 1 + ProtoBufRuntime._sz_lendelim(MerkleRoot._estimate(r.root));
        e += 1 + ProtoBufRuntime._sz_lendelim(r.next_validators_hash.length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.next_validators_hash.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        Timestamp.store(input.timestamp, output.timestamp);
        MerkleRoot.store(input.root, output.root);
        output.next_validators_hash = input.next_validators_hash;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library ConsensusState

library MerkleRoot {
    //struct definition
    struct Data {
        bytes hash;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[2] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_hash(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[2] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.hash = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.hash, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(r.hash.length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.hash.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.hash = input.hash;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library MerkleRoot

// TODO: Fix field order after potential BSC upgrade
library CanonicalPartSetHeader {
    //struct definition
    struct Data {
        bytes hash;
        uint32 total;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_hash(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_total(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_total(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (uint32 x, uint256 sz) = ProtoBufRuntime._decode_uint32(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.total = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.hash = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.hash, pointer, bs);
        }
        if (r.total != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_uint32(r.total, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_uint32(r.total);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.hash.length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.total != 0) {
            return false;
        }

        if (r.hash.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.total = input.total;
        output.hash = input.hash;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library CanonicalPartSetHeader

library CanonicalBlockID {
    //struct definition
    struct Data {
        bytes hash;
        CanonicalPartSetHeader.Data part_set_header;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_hash(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_part_set_header(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.hash = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_part_set_header(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (CanonicalPartSetHeader.Data memory x, uint256 sz) = _decode_CanonicalPartSetHeader(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.part_set_header = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_CanonicalPartSetHeader(
        uint256 p,
        bytes memory bs
    ) internal pure returns (CanonicalPartSetHeader.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (CanonicalPartSetHeader.Data memory r, ) = CanonicalPartSetHeader._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.hash, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += CanonicalPartSetHeader._encode_nested(r.part_set_header, pointer, bs);

        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(r.hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(CanonicalPartSetHeader._estimate(r.part_set_header));
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.hash.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.hash = input.hash;
        CanonicalPartSetHeader.store(input.part_set_header, output.part_set_header);
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library CanonicalBlockID

library CanonicalVote {
    //struct definition
    struct Data {
        TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.SignedMsgType Type;
        int64 height;
        int64 round;
        CanonicalBlockID.Data block_id;
        Timestamp.Data timestamp;
        string chain_id;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[7] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_Type(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_height(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_round(pointer, bs, r, counters);
            } else if (fieldId == 4) {
                pointer += _read_block_id(pointer, bs, r, counters);
            } else if (fieldId == 5) {
                pointer += _read_timestamp(pointer, bs, r, counters);
            } else if (fieldId == 6) {
                pointer += _read_chain_id(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_Type(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[7] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
        TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.SignedMsgType x = TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.decode_SignedMsgType(
            tmp
        );
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.Type = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_height(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[7] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_sfixed64(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.height = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_round(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[7] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_sfixed64(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.round = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_block_id(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[7] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (CanonicalBlockID.Data memory x, uint256 sz) = _decode_CanonicalBlockID(p, bs);
        if (isNil(r)) {
            counters[4] += 1;
        } else {
            r.block_id = x;
            if (counters[4] > 0) counters[4] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_timestamp(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[7] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Timestamp.Data memory x, uint256 sz) = _decode_Timestamp(p, bs);
        if (isNil(r)) {
            counters[5] += 1;
        } else {
            r.timestamp = x;
            if (counters[5] > 0) counters[5] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_chain_id(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[7] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
        if (isNil(r)) {
            counters[6] += 1;
        } else {
            r.chain_id = x;
            if (counters[6] > 0) counters[6] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_CanonicalBlockID(
        uint256 p,
        bytes memory bs
    ) internal pure returns (CanonicalBlockID.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (CanonicalBlockID.Data memory r, ) = CanonicalBlockID._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Timestamp(uint256 p, bytes memory bs) internal pure returns (Timestamp.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Timestamp.Data memory r, ) = Timestamp._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (uint256(r.Type) != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            int32 _enum_Type = TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.encode_SignedMsgType(r.Type);
            pointer += ProtoBufRuntime._encode_enum(_enum_Type, pointer, bs);
        }
        if (r.height != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Fixed64, pointer, bs);
            pointer += ProtoBufRuntime._encode_sfixed64(r.height, pointer, bs);
        }
        if (r.round != 0) {
            pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.Fixed64, pointer, bs);
            pointer += ProtoBufRuntime._encode_sfixed64(r.round, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(4, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += CanonicalBlockID._encode_nested(r.block_id, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(5, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Timestamp._encode_nested(r.timestamp, pointer, bs);

        if (bytes(r.chain_id).length != 0) {
            pointer += ProtoBufRuntime._encode_key(6, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_string(r.chain_id, pointer, bs);
        }
        return pointer - offset;
    }


    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_enum(TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.encode_SignedMsgType(r.Type));
        e += 1 + 8;
        e += 1 + 8;
        e += 1 + ProtoBufRuntime._sz_lendelim(CanonicalBlockID._estimate(r.block_id));
        e += 1 + ProtoBufRuntime._sz_lendelim(Timestamp._estimate(r.timestamp));
        e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.chain_id).length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (uint256(r.Type) != 0) {
            return false;
        }

        if (r.height != 0) {
            return false;
        }

        if (r.round != 0) {
            return false;
        }

        if (bytes(r.chain_id).length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.Type = input.Type;
        output.height = input.height;
        output.round = input.round;
        CanonicalBlockID.store(input.block_id, output.block_id);
        Timestamp.store(input.timestamp, output.timestamp);
        output.chain_id = input.chain_id;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library CanonicalVote

library Vote {
    //struct definition
    struct Data {
        TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.SignedMsgType Type;
        int64 height;
        int32 round;
        BlockID.Data block_id;
        Timestamp.Data timestamp;
        bytes validator_address;
        int32 validator_index;
        bytes signature;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[9] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_Type(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_height(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_round(pointer, bs, r, counters);
            } else if (fieldId == 4) {
                pointer += _read_block_id(pointer, bs, r, counters);
            } else if (fieldId == 5) {
                pointer += _read_timestamp(pointer, bs, r, counters);
            } else if (fieldId == 6) {
                pointer += _read_validator_address(pointer, bs, r, counters);
            } else if (fieldId == 7) {
                pointer += _read_validator_index(pointer, bs, r, counters);
            } else if (fieldId == 8) {
                pointer += _read_signature(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_Type(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[9] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
        TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.SignedMsgType x = TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.decode_SignedMsgType(
            tmp
        );
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.Type = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_height(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[9] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.height = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_round(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[9] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.round = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_block_id(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[9] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (BlockID.Data memory x, uint256 sz) = _decode_BlockID(p, bs);
        if (isNil(r)) {
            counters[4] += 1;
        } else {
            r.block_id = x;
            if (counters[4] > 0) counters[4] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_timestamp(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[9] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Timestamp.Data memory x, uint256 sz) = _decode_Timestamp(p, bs);
        if (isNil(r)) {
            counters[5] += 1;
        } else {
            r.timestamp = x;
            if (counters[5] > 0) counters[5] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_validator_address(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[9] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[6] += 1;
        } else {
            r.validator_address = x;
            if (counters[6] > 0) counters[6] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_validator_index(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[9] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
        if (isNil(r)) {
            counters[7] += 1;
        } else {
            r.validator_index = x;
            if (counters[7] > 0) counters[7] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_signature(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[9] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[8] += 1;
        } else {
            r.signature = x;
            if (counters[8] > 0) counters[8] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_BlockID(uint256 p, bytes memory bs) internal pure returns (BlockID.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (BlockID.Data memory r, ) = BlockID._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Timestamp(uint256 p, bytes memory bs) internal pure returns (Timestamp.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Timestamp.Data memory r, ) = Timestamp._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (uint256(r.Type) != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            int32 _enum_Type = TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.encode_SignedMsgType(r.Type);
            pointer += ProtoBufRuntime._encode_enum(_enum_Type, pointer, bs);
        }
        if (r.height != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.height, pointer, bs);
        }
        if (r.round != 0) {
            pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int32(r.round, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(4, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += BlockID._encode_nested(r.block_id, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(5, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Timestamp._encode_nested(r.timestamp, pointer, bs);

        if (r.validator_address.length != 0) {
            pointer += ProtoBufRuntime._encode_key(6, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.validator_address, pointer, bs);
        }
        if (r.validator_index != 0) {
            pointer += ProtoBufRuntime._encode_key(7, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int32(r.validator_index, pointer, bs);
        }
        if (r.signature.length != 0) {
            pointer += ProtoBufRuntime._encode_key(8, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.signature, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_enum(TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.encode_SignedMsgType(r.Type));
        e += 1 + ProtoBufRuntime._sz_int64(r.height);
        e += 1 + ProtoBufRuntime._sz_int32(r.round);
        e += 1 + ProtoBufRuntime._sz_lendelim(BlockID._estimate(r.block_id));
        e += 1 + ProtoBufRuntime._sz_lendelim(Timestamp._estimate(r.timestamp));
        e += 1 + ProtoBufRuntime._sz_lendelim(r.validator_address.length);
        e += 1 + ProtoBufRuntime._sz_int32(r.validator_index);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.signature.length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (uint256(r.Type) != 0) {
            return false;
        }

        if (r.height != 0) {
            return false;
        }

        if (r.round != 0) {
            return false;
        }

        if (r.validator_address.length != 0) {
            return false;
        }

        if (r.validator_index != 0) {
            return false;
        }

        if (r.signature.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.Type = input.Type;
        output.height = input.height;
        output.round = input.round;
        BlockID.store(input.block_id, output.block_id);
        Timestamp.store(input.timestamp, output.timestamp);
        output.validator_address = input.validator_address;
        output.validator_index = input.validator_index;
        output.signature = input.signature;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library Vote

library ValidatorSet {
    //struct definition
    struct Data {
        Validator.Data[] validators;
        Validator.Data proposer;
        int64 total_voting_power;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[4] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_validators(pointer, bs, nil(), counters);
            } else if (fieldId == 2) {
                pointer += _read_proposer(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_total_voting_power(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        pointer = offset;
        r.validators = new Validator.Data[](counters[1]);

        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_validators(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_proposer(pointer, bs, nil(), counters);
            } else if (fieldId == 3) {
                pointer += _read_total_voting_power(pointer, bs, nil(), counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_validators(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Validator.Data memory x, uint256 sz) = _decode_Validator(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.validators[r.validators.length - counters[1]] = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_proposer(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Validator.Data memory x, uint256 sz) = _decode_Validator(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.proposer = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_total_voting_power(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.total_voting_power = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Validator(uint256 p, bytes memory bs) internal pure returns (Validator.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Validator.Data memory r, ) = Validator._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;
        uint256 i;
        if (r.validators.length != 0) {
            for (i = 0; i < r.validators.length; i++) {
                pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
                pointer += Validator._encode_nested(r.validators[i], pointer, bs);
            }
        }

        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Validator._encode_nested(r.proposer, pointer, bs);

        if (r.total_voting_power != 0) {
            pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.total_voting_power, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        uint256 i;
        for (i = 0; i < r.validators.length; i++) {
            e += 1 + ProtoBufRuntime._sz_lendelim(Validator._estimate(r.validators[i]));
        }
        e += 1 + ProtoBufRuntime._sz_lendelim(Validator._estimate(r.proposer));
        e += 1 + ProtoBufRuntime._sz_int64(r.total_voting_power);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.validators.length != 0) {
            return false;
        }

        if (r.total_voting_power != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        for (uint256 i1 = 0; i1 < input.validators.length; i1++) {
            output.validators.push(input.validators[i1]);
        }

        Validator.store(input.proposer, output.proposer);
        output.total_voting_power = input.total_voting_power;
    }

    //array helpers for Validators
    /**
     * @dev Add value to an array
     * @param self The in-memory struct
     * @param value The value to add
     */
    function addValidators(Data memory self, Validator.Data memory value) internal pure {
        /**
         * First resize the array. Then add the new element to the end.
         */
        Validator.Data[] memory tmp = new Validator.Data[](self.validators.length + 1);
        for (uint256 i = 0; i < self.validators.length; i++) {
            tmp[i] = self.validators[i];
        }
        tmp[self.validators.length] = value;
        self.validators = tmp;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library ValidatorSet

library Validator {
    //struct definition
    struct Data {
        bytes Address;
        PublicKey.Data pub_key;
        int64 voting_power;
        int64 proposer_priority;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[5] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_Address(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_pub_key(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_voting_power(pointer, bs, r, counters);
            } else if (fieldId == 4) {
                pointer += _read_proposer_priority(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_Address(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.Address = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_pub_key(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (PublicKey.Data memory x, uint256 sz) = _decode_PublicKey(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.pub_key = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_voting_power(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.voting_power = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_proposer_priority(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[4] += 1;
        } else {
            r.proposer_priority = x;
            if (counters[4] > 0) counters[4] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_PublicKey(uint256 p, bytes memory bs) internal pure returns (PublicKey.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (PublicKey.Data memory r, ) = PublicKey._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.Address.length != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.Address, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += PublicKey._encode_nested(r.pub_key, pointer, bs);

        if (r.voting_power != 0) {
            pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.voting_power, pointer, bs);
        }
        if (r.proposer_priority != 0) {
            pointer += ProtoBufRuntime._encode_key(4, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.proposer_priority, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(r.Address.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(PublicKey._estimate(r.pub_key));
        e += 1 + ProtoBufRuntime._sz_int64(r.voting_power);
        e += 1 + ProtoBufRuntime._sz_int64(r.proposer_priority);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.Address.length != 0) {
            return false;
        }

        if (r.voting_power != 0) {
            return false;
        }

        if (r.proposer_priority != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.Address = input.Address;
        PublicKey.store(input.pub_key, output.pub_key);
        output.voting_power = input.voting_power;
        output.proposer_priority = input.proposer_priority;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library Validator

library SimpleValidator {
    //struct definition
    struct Data {
        PublicKey.Data pub_key;
        int64 voting_power;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_pub_key(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_voting_power(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_pub_key(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (PublicKey.Data memory x, uint256 sz) = _decode_PublicKey(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.pub_key = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_voting_power(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.voting_power = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_PublicKey(uint256 p, bytes memory bs) internal pure returns (PublicKey.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (PublicKey.Data memory r, ) = PublicKey._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += PublicKey._encode_nested(r.pub_key, pointer, bs);

        if (r.voting_power != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.voting_power, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(PublicKey._estimate(r.pub_key));
        e += 1 + ProtoBufRuntime._sz_int64(r.voting_power);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.voting_power != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        PublicKey.store(input.pub_key, output.pub_key);
        output.voting_power = input.voting_power;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library SimpleValidator

library PublicKey {
    //struct definition
    struct Data {
        bytes ed25519;
        bytes secp256k1;
        bytes sr25519;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[4] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_ed25519(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_secp256k1(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_sr25519(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_ed25519(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.ed25519 = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_secp256k1(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.secp256k1 = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_sr25519(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[4] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.sr25519 = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.ed25519.length != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.ed25519, pointer, bs);
        }
        if (r.secp256k1.length != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.secp256k1, pointer, bs);
        }
        if (r.sr25519.length != 0) {
            pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.sr25519, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(r.ed25519.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.secp256k1.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.sr25519.length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.ed25519.length != 0) {
            return false;
        }

        if (r.secp256k1.length != 0) {
            return false;
        }

        if (r.sr25519.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.ed25519 = input.ed25519;
        output.secp256k1 = input.secp256k1;
        output.sr25519 = input.sr25519;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library PublicKey

library PartSetHeader {
    //struct definition
    struct Data {
        uint32 total;
        bytes hash;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_total(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_hash(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_total(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (uint32 x, uint256 sz) = ProtoBufRuntime._decode_uint32(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.total = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.hash = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.total != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_uint32(r.total, pointer, bs);
        }
        if (r.hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.hash, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_uint32(r.total);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.hash.length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.total != 0) {
            return false;
        }

        if (r.hash.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.total = input.total;
        output.hash = input.hash;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library PartSetHeader

library BlockID {
    //struct definition
    struct Data {
        bytes hash;
        PartSetHeader.Data part_set_header;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_hash(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_part_set_header(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.hash = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_part_set_header(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (PartSetHeader.Data memory x, uint256 sz) = _decode_PartSetHeader(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.part_set_header = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_PartSetHeader(
        uint256 p,
        bytes memory bs
    ) internal pure returns (PartSetHeader.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (PartSetHeader.Data memory r, ) = PartSetHeader._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.hash, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += PartSetHeader._encode_nested(r.part_set_header, pointer, bs);

        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(r.hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(PartSetHeader._estimate(r.part_set_header));
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.hash.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.hash = input.hash;
        PartSetHeader.store(input.part_set_header, output.part_set_header);
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library BlockID

library Commit {
    //struct definition
    struct Data {
        int64 height;
        int32 round;
        BlockID.Data block_id;
        CommitSig.Data[] signatures;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[5] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_height(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_round(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_block_id(pointer, bs, r, counters);
            } else if (fieldId == 4) {
                pointer += _read_signatures(pointer, bs, nil(), counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        pointer = offset;
        r.signatures = new CommitSig.Data[](counters[4]);

        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_height(pointer, bs, nil(), counters);
            } else if (fieldId == 2) {
                pointer += _read_round(pointer, bs, nil(), counters);
            } else if (fieldId == 3) {
                pointer += _read_block_id(pointer, bs, nil(), counters);
            } else if (fieldId == 4) {
                pointer += _read_signatures(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_height(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.height = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_round(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.round = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_block_id(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (BlockID.Data memory x, uint256 sz) = _decode_BlockID(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.block_id = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_signatures(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (CommitSig.Data memory x, uint256 sz) = _decode_CommitSig(p, bs);
        if (isNil(r)) {
            counters[4] += 1;
        } else {
            r.signatures[r.signatures.length - counters[4]] = x;
            if (counters[4] > 0) counters[4] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_BlockID(uint256 p, bytes memory bs) internal pure returns (BlockID.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (BlockID.Data memory r, ) = BlockID._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_CommitSig(uint256 p, bytes memory bs) internal pure returns (CommitSig.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (CommitSig.Data memory r, ) = CommitSig._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;
        uint256 i;
        if (r.height != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.height, pointer, bs);
        }
        if (r.round != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int32(r.round, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += BlockID._encode_nested(r.block_id, pointer, bs);

        if (r.signatures.length != 0) {
            for (i = 0; i < r.signatures.length; i++) {
                pointer += ProtoBufRuntime._encode_key(4, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
                pointer += CommitSig._encode_nested(r.signatures[i], pointer, bs);
            }
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        uint256 i;
        e += 1 + ProtoBufRuntime._sz_int64(r.height);
        e += 1 + ProtoBufRuntime._sz_int32(r.round);
        e += 1 + ProtoBufRuntime._sz_lendelim(BlockID._estimate(r.block_id));
        for (i = 0; i < r.signatures.length; i++) {
            e += 1 + ProtoBufRuntime._sz_lendelim(CommitSig._estimate(r.signatures[i]));
        }
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.height != 0) {
            return false;
        }

        if (r.round != 0) {
            return false;
        }

        if (r.signatures.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.height = input.height;
        output.round = input.round;
        BlockID.store(input.block_id, output.block_id);

        for (uint256 i4 = 0; i4 < input.signatures.length; i4++) {
            output.signatures.push(input.signatures[i4]);
        }
    }

    //array helpers for Signatures
    /**
     * @dev Add value to an array
     * @param self The in-memory struct
     * @param value The value to add
     */
    function addSignatures(Data memory self, CommitSig.Data memory value) internal pure {
        /**
         * First resize the array. Then add the new element to the end.
         */
        CommitSig.Data[] memory tmp = new CommitSig.Data[](self.signatures.length + 1);
        for (uint256 i = 0; i < self.signatures.length; i++) {
            tmp[i] = self.signatures[i];
        }
        tmp[self.signatures.length] = value;
        self.signatures = tmp;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library Commit

library CommitSig {
    //struct definition
    struct Data {
        TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.BlockIDFlag block_id_flag;
        bytes validator_address;
        Timestamp.Data timestamp;
        bytes signature;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[5] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_block_id_flag(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_validator_address(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_timestamp(pointer, bs, r, counters);
            } else if (fieldId == 4) {
                pointer += _read_signature(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_block_id_flag(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 tmp, uint256 sz) = ProtoBufRuntime._decode_enum(p, bs);
        TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.BlockIDFlag x = TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.decode_BlockIDFlag(tmp);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.block_id_flag = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_validator_address(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.validator_address = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_timestamp(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Timestamp.Data memory x, uint256 sz) = _decode_Timestamp(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.timestamp = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_signature(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[4] += 1;
        } else {
            r.signature = x;
            if (counters[4] > 0) counters[4] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Timestamp(uint256 p, bytes memory bs) internal pure returns (Timestamp.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Timestamp.Data memory r, ) = Timestamp._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (uint256(r.block_id_flag) != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            int32 _enum_block_id_flag = TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.encode_BlockIDFlag(r.block_id_flag);
            pointer += ProtoBufRuntime._encode_enum(_enum_block_id_flag, pointer, bs);
        }
        if (r.validator_address.length != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.validator_address, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Timestamp._encode_nested(r.timestamp, pointer, bs);

        if (r.signature.length != 0) {
            pointer += ProtoBufRuntime._encode_key(4, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.signature, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_enum(TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.encode_BlockIDFlag(r.block_id_flag));
        e += 1 + ProtoBufRuntime._sz_lendelim(r.validator_address.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(Timestamp._estimate(r.timestamp));
        e += 1 + ProtoBufRuntime._sz_lendelim(r.signature.length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (uint256(r.block_id_flag) != 0) {
            return false;
        }

        if (r.validator_address.length != 0) {
            return false;
        }

        if (r.signature.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.block_id_flag = input.block_id_flag;
        output.validator_address = input.validator_address;
        Timestamp.store(input.timestamp, output.timestamp);
        output.signature = input.signature;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library CommitSig

library Timestamp {
    //struct definition
    struct Data {
        int64 Seconds;
        int32 nanos;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_Seconds(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_nanos(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_Seconds(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.Seconds = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_nanos(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int32 x, uint256 sz) = ProtoBufRuntime._decode_int32(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.nanos = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        if (r.Seconds != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.Seconds, pointer, bs);
        }
        if (r.nanos != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int32(r.nanos, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_int64(r.Seconds);
        e += 1 + ProtoBufRuntime._sz_int32(r.nanos);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.Seconds != 0) {
            return false;
        }

        if (r.nanos != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.Seconds = input.Seconds;
        output.nanos = input.nanos;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library Timestamp

library LightHeader {
    //struct definition
    struct Data {
        Consensus.Data version;
        string chain_id;
        int64 height;
        Timestamp.Data time;
        BlockID.Data last_block_id;
        bytes last_commit_hash;
        bytes data_hash;
        bytes validators_hash;
        bytes next_validators_hash;
        bytes consensus_hash;
        bytes app_hash;
        bytes last_results_hash;
        bytes evidence_hash;
        bytes proposer_address;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[15] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_version(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_chain_id(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_height(pointer, bs, r, counters);
            } else if (fieldId == 4) {
                pointer += _read_time(pointer, bs, r, counters);
            } else if (fieldId == 5) {
                pointer += _read_last_block_id(pointer, bs, r, counters);
            } else if (fieldId == 6) {
                pointer += _read_last_commit_hash(pointer, bs, r, counters);
            } else if (fieldId == 7) {
                pointer += _read_data_hash(pointer, bs, r, counters);
            } else if (fieldId == 8) {
                pointer += _read_validators_hash(pointer, bs, r, counters);
            } else if (fieldId == 9) {
                pointer += _read_next_validators_hash(pointer, bs, r, counters);
            } else if (fieldId == 10) {
                pointer += _read_consensus_hash(pointer, bs, r, counters);
            } else if (fieldId == 11) {
                pointer += _read_app_hash(pointer, bs, r, counters);
            } else if (fieldId == 12) {
                pointer += _read_last_results_hash(pointer, bs, r, counters);
            } else if (fieldId == 13) {
                pointer += _read_evidence_hash(pointer, bs, r, counters);
            } else if (fieldId == 14) {
                pointer += _read_proposer_address(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_version(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Consensus.Data memory x, uint256 sz) = _decode_Consensus(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.version = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_chain_id(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.chain_id = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_height(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.height = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_time(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Timestamp.Data memory x, uint256 sz) = _decode_Timestamp(p, bs);
        if (isNil(r)) {
            counters[4] += 1;
        } else {
            r.time = x;
            if (counters[4] > 0) counters[4] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_last_block_id(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (BlockID.Data memory x, uint256 sz) = _decode_BlockID(p, bs);
        if (isNil(r)) {
            counters[5] += 1;
        } else {
            r.last_block_id = x;
            if (counters[5] > 0) counters[5] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_last_commit_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[6] += 1;
        } else {
            r.last_commit_hash = x;
            if (counters[6] > 0) counters[6] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_data_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[7] += 1;
        } else {
            r.data_hash = x;
            if (counters[7] > 0) counters[7] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_validators_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[8] += 1;
        } else {
            r.validators_hash = x;
            if (counters[8] > 0) counters[8] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_next_validators_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[9] += 1;
        } else {
            r.next_validators_hash = x;
            if (counters[9] > 0) counters[9] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_consensus_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[10] += 1;
        } else {
            r.consensus_hash = x;
            if (counters[10] > 0) counters[10] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_app_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[11] += 1;
        } else {
            r.app_hash = x;
            if (counters[11] > 0) counters[11] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_last_results_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[12] += 1;
        } else {
            r.last_results_hash = x;
            if (counters[12] > 0) counters[12] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_evidence_hash(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[13] += 1;
        } else {
            r.evidence_hash = x;
            if (counters[13] > 0) counters[13] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_proposer_address(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[15] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[14] += 1;
        } else {
            r.proposer_address = x;
            if (counters[14] > 0) counters[14] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Consensus(uint256 p, bytes memory bs) internal pure returns (Consensus.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Consensus.Data memory r, ) = Consensus._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Timestamp(uint256 p, bytes memory bs) internal pure returns (Timestamp.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Timestamp.Data memory r, ) = Timestamp._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_BlockID(uint256 p, bytes memory bs) internal pure returns (BlockID.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (BlockID.Data memory r, ) = BlockID._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Consensus._encode_nested(r.version, pointer, bs);

        if (bytes(r.chain_id).length != 0) {
            pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_string(r.chain_id, pointer, bs);
        }
        if (r.height != 0) {
            pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.height, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(4, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Timestamp._encode_nested(r.time, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(5, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += BlockID._encode_nested(r.last_block_id, pointer, bs);

        if (r.last_commit_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(6, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.last_commit_hash, pointer, bs);
        }
        if (r.data_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(7, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.data_hash, pointer, bs);
        }
        if (r.validators_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(8, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.validators_hash, pointer, bs);
        }
        if (r.next_validators_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(9, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.next_validators_hash, pointer, bs);
        }
        if (r.consensus_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(10, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.consensus_hash, pointer, bs);
        }
        if (r.app_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(11, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.app_hash, pointer, bs);
        }
        if (r.last_results_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(12, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.last_results_hash, pointer, bs);
        }
        if (r.evidence_hash.length != 0) {
            pointer += ProtoBufRuntime._encode_key(13, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.evidence_hash, pointer, bs);
        }
        if (r.proposer_address.length != 0) {
            pointer += ProtoBufRuntime._encode_key(14, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(r.proposer_address, pointer, bs);
        }
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(Consensus._estimate(r.version));
        e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.chain_id).length);
        e += 1 + ProtoBufRuntime._sz_int64(r.height);
        e += 1 + ProtoBufRuntime._sz_lendelim(Timestamp._estimate(r.time));
        e += 1 + ProtoBufRuntime._sz_lendelim(BlockID._estimate(r.last_block_id));
        e += 1 + ProtoBufRuntime._sz_lendelim(r.last_commit_hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.data_hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.validators_hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.next_validators_hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.consensus_hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.app_hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.last_results_hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.evidence_hash.length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.proposer_address.length);
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (bytes(r.chain_id).length != 0) {
            return false;
        }

        if (r.height != 0) {
            return false;
        }

        if (r.last_commit_hash.length != 0) {
            return false;
        }

        if (r.data_hash.length != 0) {
            return false;
        }

        if (r.validators_hash.length != 0) {
            return false;
        }

        if (r.next_validators_hash.length != 0) {
            return false;
        }

        if (r.consensus_hash.length != 0) {
            return false;
        }

        if (r.app_hash.length != 0) {
            return false;
        }

        if (r.last_results_hash.length != 0) {
            return false;
        }

        if (r.evidence_hash.length != 0) {
            return false;
        }

        if (r.proposer_address.length != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        Consensus.store(input.version, output.version);
        output.chain_id = input.chain_id;
        output.height = input.height;
        Timestamp.store(input.time, output.time);
        BlockID.store(input.last_block_id, output.last_block_id);
        output.last_commit_hash = input.last_commit_hash;
        output.data_hash = input.data_hash;
        output.validators_hash = input.validators_hash;
        output.next_validators_hash = input.next_validators_hash;
        output.consensus_hash = input.consensus_hash;
        output.app_hash = input.app_hash;
        output.last_results_hash = input.last_results_hash;
        output.evidence_hash = input.evidence_hash;
        output.proposer_address = input.proposer_address;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library LightHeader

library SignedHeader {
    //struct definition
    struct Data {
        LightHeader.Data header;
        Commit.Data commit;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_header(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_commit(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_header(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (LightHeader.Data memory x, uint256 sz) = _decode_LightHeader(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.header = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_commit(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (Commit.Data memory x, uint256 sz) = _decode_Commit(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.commit = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_LightHeader(uint256 p, bytes memory bs) internal pure returns (LightHeader.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (LightHeader.Data memory r, ) = LightHeader._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_Commit(uint256 p, bytes memory bs) internal pure returns (Commit.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (Commit.Data memory r, ) = Commit._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += LightHeader._encode_nested(r.header, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += Commit._encode_nested(r.commit, pointer, bs);

        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(LightHeader._estimate(r.header));
        e += 1 + ProtoBufRuntime._sz_lendelim(Commit._estimate(r.commit));
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        LightHeader.store(input.header, output.header);
        Commit.store(input.commit, output.commit);
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library SignedHeader

library TmHeader {
    //struct definition
    struct Data {
        SignedHeader.Data signed_header;
        ValidatorSet.Data validator_set;
        int64 trusted_height;
        ValidatorSet.Data trusted_validators;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(uint256 p, bytes memory bs, uint256 sz) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[5] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_signed_header(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_validator_set(pointer, bs, r, counters);
            } else if (fieldId == 3) {
                pointer += _read_trusted_height(pointer, bs, r, counters);
            } else if (fieldId == 4) {
                pointer += _read_trusted_validators(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_signed_header(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (SignedHeader.Data memory x, uint256 sz) = _decode_SignedHeader(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.signed_header = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_validator_set(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (ValidatorSet.Data memory x, uint256 sz) = _decode_ValidatorSet(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.validator_set = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_trusted_height(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (int64 x, uint256 sz) = ProtoBufRuntime._decode_int64(p, bs);
        if (isNil(r)) {
            counters[3] += 1;
        } else {
            r.trusted_height = x;
            if (counters[3] > 0) counters[3] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_trusted_validators(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[5] memory counters
    ) internal pure returns (uint256) {
        /**
         * if `r` is NULL, then only counting the number of fields.
         */
        (ValidatorSet.Data memory x, uint256 sz) = _decode_ValidatorSet(p, bs);
        if (isNil(r)) {
            counters[4] += 1;
        } else {
            r.trusted_validators = x;
            if (counters[4] > 0) counters[4] -= 1;
        }
        return sz;
    }

    // struct decoder
    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_SignedHeader(
        uint256 p,
        bytes memory bs
    ) internal pure returns (SignedHeader.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (SignedHeader.Data memory r, ) = SignedHeader._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    /**
     * @dev The decoder for reading a inner struct field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The decoded inner-struct
     * @return The number of bytes used to decode
     */
    function _decode_ValidatorSet(
        uint256 p,
        bytes memory bs
    ) internal pure returns (ValidatorSet.Data memory, uint256) {
        uint256 pointer = p;
        (uint256 sz, uint256 bytesRead) = ProtoBufRuntime._decode_varint(pointer, bs);
        pointer += bytesRead;
        (ValidatorSet.Data memory r, ) = ValidatorSet._decode(pointer, bs, sz);
        return (r, sz + bytesRead);
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += SignedHeader._encode_nested(r.signed_header, pointer, bs);

        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += ValidatorSet._encode_nested(r.validator_set, pointer, bs);

        if (r.trusted_height != 0) {
            pointer += ProtoBufRuntime._encode_key(3, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(r.trusted_height, pointer, bs);
        }

        pointer += ProtoBufRuntime._encode_key(4, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += ValidatorSet._encode_nested(r.trusted_validators, pointer, bs);

        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(Data memory r, uint256 p, bytes memory bs) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(SignedHeader._estimate(r.signed_header));
        e += 1 + ProtoBufRuntime._sz_lendelim(ValidatorSet._estimate(r.validator_set));
        e += 1 + ProtoBufRuntime._sz_int64(r.trusted_height);
        e += 1 + ProtoBufRuntime._sz_lendelim(ValidatorSet._estimate(r.trusted_validators));
        return e;
    }

    // empty checker

    function _empty(Data memory r) internal pure returns (bool) {
        if (r.trusted_height != 0) {
            return false;
        }

        return true;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        SignedHeader.store(input.signed_header, output.signed_header);
        ValidatorSet.store(input.validator_set, output.validator_set);
        output.trusted_height = input.trusted_height;
        ValidatorSet.store(input.trusted_validators, output.trusted_validators);
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}

//library TmHeader

library TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS {
    //enum definition
    // Solidity enum definitions
    enum BlockIDFlag {
        BLOCK_ID_FLAG_UNKNOWN,
        BLOCK_ID_FLAG_ABSENT,
        BLOCK_ID_FLAG_COMMIT,
        BLOCK_ID_FLAG_NIL
    }

    // Solidity enum encoder
    function encode_BlockIDFlag(BlockIDFlag x) internal pure returns (int32) {
        if (x == BlockIDFlag.BLOCK_ID_FLAG_UNKNOWN) {
            return 0;
        }

        if (x == BlockIDFlag.BLOCK_ID_FLAG_ABSENT) {
            return 1;
        }

        if (x == BlockIDFlag.BLOCK_ID_FLAG_COMMIT) {
            return 2;
        }

        if (x == BlockIDFlag.BLOCK_ID_FLAG_NIL) {
            return 3;
        }
        revert();
    }

    // Solidity enum decoder
    function decode_BlockIDFlag(int64 x) internal pure returns (BlockIDFlag) {
        if (x == 0) {
            return BlockIDFlag.BLOCK_ID_FLAG_UNKNOWN;
        }

        if (x == 1) {
            return BlockIDFlag.BLOCK_ID_FLAG_ABSENT;
        }

        if (x == 2) {
            return BlockIDFlag.BLOCK_ID_FLAG_COMMIT;
        }

        if (x == 3) {
            return BlockIDFlag.BLOCK_ID_FLAG_NIL;
        }
        revert();
    }

    // Solidity enum definitions
    enum SignedMsgType {
        SIGNED_MSG_TYPE_UNKNOWN,
        SIGNED_MSG_TYPE_PREVOTE,
        SIGNED_MSG_TYPE_PRECOMMIT,
        SIGNED_MSG_TYPE_PROPOSAL
    }

    // Solidity enum encoder
    function encode_SignedMsgType(SignedMsgType x) internal pure returns (int32) {
        if (x == SignedMsgType.SIGNED_MSG_TYPE_UNKNOWN) {
            return 0;
        }

        if (x == SignedMsgType.SIGNED_MSG_TYPE_PREVOTE) {
            return 1;
        }

        if (x == SignedMsgType.SIGNED_MSG_TYPE_PRECOMMIT) {
            return 2;
        }

        if (x == SignedMsgType.SIGNED_MSG_TYPE_PROPOSAL) {
            return 32;
        }
        revert();
    }

    // Solidity enum decoder
    function decode_SignedMsgType(int64 x) internal pure returns (SignedMsgType) {
        if (x == 0) {
            return SignedMsgType.SIGNED_MSG_TYPE_UNKNOWN;
        }

        if (x == 1) {
            return SignedMsgType.SIGNED_MSG_TYPE_PREVOTE;
        }

        if (x == 2) {
            return SignedMsgType.SIGNED_MSG_TYPE_PRECOMMIT;
        }

        if (x == 32) {
            return SignedMsgType.SIGNED_MSG_TYPE_PROPOSAL;
        }
        revert();
    }
}
//library TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;

/**
 * @title Runtime library for ProtoBuf serialization and/or deserialization.
 * All ProtoBuf generated code will use this library.
 */
library ProtoBufRuntime {
    // Types defined in ProtoBuf
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }
    // Constants for bytes calculation
    uint256 constant WORD_LENGTH = 32;
    uint256 constant HEADER_SIZE_LENGTH_IN_BYTES = 4;
    uint256 constant BYTE_SIZE = 8;
    uint256 constant REMAINING_LENGTH = WORD_LENGTH - HEADER_SIZE_LENGTH_IN_BYTES;
    string constant OVERFLOW_MESSAGE = "length overflow";

    //Storages
    /**
     * @dev Encode to storage location using assembly to save storage space.
     * @param location The location of storage
     * @param encoded The encoded ProtoBuf bytes
     */
    function encodeStorage(bytes storage location, bytes memory encoded) internal {
        //
        // This code use the first four bytes as size,
        // and then put the rest of `encoded` bytes.
        //
        uint256 length = encoded.length;
        uint256 firstWord;
        uint256 wordLength = WORD_LENGTH;
        uint256 remainingLength = REMAINING_LENGTH;

        assembly {
            firstWord := mload(add(encoded, wordLength))
        }
        firstWord =
            (firstWord >> (BYTE_SIZE * HEADER_SIZE_LENGTH_IN_BYTES)) |
            (length << (BYTE_SIZE * REMAINING_LENGTH));

        assembly {
            sstore(location.slot, firstWord)
        }

        if (length > REMAINING_LENGTH) {
            length -= REMAINING_LENGTH;
            for (uint256 i = 0; i < ceil(length, WORD_LENGTH); i++) {
                assembly {
                    let offset := add(mul(i, wordLength), remainingLength)
                    let slotIndex := add(i, 1)
                    sstore(add(location.slot, slotIndex), mload(add(add(encoded, wordLength), offset)))
                }
            }
        }
    }

    /**
     * @dev Decode storage location using assembly using the format in `encodeStorage`.
     * @param location The location of storage
     * @return The encoded bytes
     */
    function decodeStorage(bytes storage location) internal view returns (bytes memory) {
        //
        // This code is to decode the first four bytes as size,
        // and then decode the rest using the decoded size.
        //
        uint256 firstWord;
        uint256 remainingLength = REMAINING_LENGTH;
        uint256 wordLength = WORD_LENGTH;

        assembly {
            firstWord := sload(location.slot)
        }

        uint256 length = firstWord >> (BYTE_SIZE * REMAINING_LENGTH);
        bytes memory encoded = new bytes(length);

        assembly {
            mstore(add(encoded, remainingLength), firstWord)
        }

        if (length > REMAINING_LENGTH) {
            length -= REMAINING_LENGTH;
            for (uint256 i = 0; i < ceil(length, WORD_LENGTH); i++) {
                assembly {
                    let offset := add(mul(i, wordLength), remainingLength)
                    let slotIndex := add(i, 1)
                    mstore(add(add(encoded, wordLength), offset), sload(add(location.slot, slotIndex)))
                }
            }
        }
        return encoded;
    }

    /**
     * @dev Fast memory copy of bytes using assembly.
     * @param src The source memory address
     * @param dest The destination memory address
     * @param len The length of bytes to copy
     */
    function copyBytes(
        uint256 src,
        uint256 dest,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_LENGTH; len -= WORD_LENGTH) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_LENGTH;
            src += WORD_LENGTH;
        }

        // Copy remaining bytes
        // TODO: There are two changes in solidity 0.8.x
        // 1. exponential literal handling
        // 2. overflow/underflow check enabled by default
        //
        // https://docs.soliditylang.org/en/latest/080-breaking-changes.html#how-to-update-your-code
        //
        // Here we have underflow / overflow and I don't yet know why. I tested:
        //    uint256 WORD_LENGTH = 32;
        //    uint256 len = 20;
        //    uint256 mask =  256**(WORD_LENGTH - len) - 1;
        //    uint256 mask2 = (256**(5)) - 1;
        //    uint256 mask3 = 256**((5) - 1);
        //
        // all of them seem to return the same value, so I believe this is the overflow issue.
        //
        // To mitigate the issue I wrapped this in unchecked { }
        uint256 mask;
        unchecked {
            mask = 256**(WORD_LENGTH - len) - 1;
        }
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /**
     * @dev Use assembly to get memory address.
     * @param r The in-memory bytes array
     * @return The memory address of `r`
     */
    function getMemoryAddress(bytes memory r) internal pure returns (uint256) {
        uint256 addr;
        assembly {
            addr := r
        }
        return addr;
    }

    /**
     * @dev Implement Math function of ceil
     * @param a The denominator
     * @param m The numerator
     * @return r The result of ceil(a/m)
     */
    function ceil(uint256 a, uint256 m) internal pure returns (uint256 r) {
        return (a + m - 1) / m;
    }

    // Decoders
    /**
     * This section of code `_decode_(u)int(32|64)`, `_decode_enum` and `_decode_bool`
     * is to decode ProtoBuf native integers,
     * using the `varint` encoding.
     */

    /**
     * @dev Decode integers
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_uint32(uint256 p, bytes memory bs) internal pure returns (uint32, uint256) {
        (uint256 varint, uint256 sz) = _decode_varint(p, bs);
        return (uint32(varint), sz);
    }

    /**
     * @dev Decode integers
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_uint64(uint256 p, bytes memory bs) internal pure returns (uint64, uint256) {
        (uint256 varint, uint256 sz) = _decode_varint(p, bs);
        return (uint64(varint), sz);
    }

    /**
     * @dev Decode integers
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_int32(uint256 p, bytes memory bs) internal pure returns (int32, uint256) {
        (uint256 varint, uint256 sz) = _decode_varint(p, bs);
        int32 r;
        assembly {
            r := varint
        }
        return (r, sz);
    }

    /**
     * @dev Decode integers
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_int64(uint256 p, bytes memory bs) internal pure returns (int64, uint256) {
        (uint256 varint, uint256 sz) = _decode_varint(p, bs);
        int64 r;
        assembly {
            r := varint
        }
        return (r, sz);
    }

    /**
     * @dev Decode enum
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded enum's integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_enum(uint256 p, bytes memory bs) internal pure returns (int64, uint256) {
        return _decode_int64(p, bs);
    }

    /**
     * @dev Decode enum
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded boolean
     * @return The length of `bs` used to get decoded
     */
    function _decode_bool(uint256 p, bytes memory bs) internal pure returns (bool, uint256) {
        (uint256 varint, uint256 sz) = _decode_varint(p, bs);
        if (varint == 0) {
            return (false, sz);
        }
        return (true, sz);
    }

    /**
     * This section of code `_decode_sint(32|64)`
     * is to decode ProtoBuf native signed integers,
     * using the `zig-zag` encoding.
     */

    /**
     * @dev Decode signed integers
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_sint32(uint256 p, bytes memory bs) internal pure returns (int32, uint256) {
        (int256 varint, uint256 sz) = _decode_varints(p, bs);
        return (int32(varint), sz);
    }

    /**
     * @dev Decode signed integers
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_sint64(uint256 p, bytes memory bs) internal pure returns (int64, uint256) {
        (int256 varint, uint256 sz) = _decode_varints(p, bs);
        return (int64(varint), sz);
    }

    /**
     * @dev Decode string
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded string
     * @return The length of `bs` used to get decoded
     */
    function _decode_string(uint256 p, bytes memory bs) internal pure returns (string memory, uint256) {
        (bytes memory x, uint256 sz) = _decode_lendelim(p, bs);
        return (string(x), sz);
    }

    /**
     * @dev Decode bytes array
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded bytes array
     * @return The length of `bs` used to get decoded
     */
    function _decode_bytes(uint256 p, bytes memory bs) internal pure returns (bytes memory, uint256) {
        return _decode_lendelim(p, bs);
    }

    /**
     * @dev Decode ProtoBuf key
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded field ID
     * @return The decoded WireType specified in ProtoBuf
     * @return The length of `bs` used to get decoded
     */
    function _decode_key(uint256 p, bytes memory bs)
        internal
        pure
        returns (
            uint256,
            WireType,
            uint256
        )
    {
        (uint256 x, uint256 n) = _decode_varint(p, bs);
        WireType typeId = WireType(x & 7);
        uint256 fieldId = x / 8;
        return (fieldId, typeId, n);
    }

    /**
     * @dev Decode ProtoBuf varint
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded unsigned integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_varint(uint256 p, bytes memory bs) internal pure returns (uint256, uint256) {
        //
        // Read a byte.
        // Use the lower 7 bits and shift it to the left,
        // until the most significant bit is 0.
        // Refer to https://developers.google.com/protocol-buffers/docs/encoding
        //
        uint256 x = 0;
        uint256 sz = 0;
        uint256 length = bs.length + WORD_LENGTH;
        assembly {
            let b := 0x80
            p := add(bs, p)
            for {

            } eq(0x80, and(b, 0x80)) {

            } {
                if eq(lt(sub(p, bs), length), 0) {
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000) //error function selector
                    mstore(4, 32)
                    mstore(36, 15)
                    mstore(68, 0x6c656e677468206f766572666c6f770000000000000000000000000000000000) // length overflow in hex
                    revert(0, 83)
                }
                let tmp := mload(p)
                let pos := 0
                for {

                } and(eq(0x80, and(b, 0x80)), lt(pos, 32)) {

                } {
                    if eq(lt(sub(p, bs), length), 0) {
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000) //error function selector
                        mstore(4, 32)
                        mstore(36, 15)
                        mstore(68, 0x6c656e677468206f766572666c6f770000000000000000000000000000000000) // length overflow in hex
                        revert(0, 83)
                    }
                    b := byte(pos, tmp)
                    x := or(x, shl(mul(7, sz), and(0x7f, b)))
                    sz := add(sz, 1)
                    pos := add(pos, 1)
                    p := add(p, 0x01)
                }
            }
        }
        return (x, sz);
    }

    /**
     * @dev Decode ProtoBuf zig-zag encoding
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded signed integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_varints(uint256 p, bytes memory bs) internal pure returns (int256, uint256) {
        //
        // Refer to https://developers.google.com/protocol-buffers/docs/encoding
        //
        (uint256 u, uint256 sz) = _decode_varint(p, bs);
        int256 s;
        assembly {
            s := xor(shr(1, u), add(not(and(u, 1)), 1))
        }
        return (s, sz);
    }

    /**
     * @dev Decode ProtoBuf fixed-length encoding
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded unsigned integer
     * @return The length of `bs` used to get decoded
     */
    function _decode_uintf(
        uint256 p,
        bytes memory bs,
        uint256 sz
    ) internal pure returns (uint256, uint256) {
        //
        // Refer to https://developers.google.com/protocol-buffers/docs/encoding
        //
        uint256 x = 0;
        uint256 length = bs.length + WORD_LENGTH;
        assert(p + sz <= length);
        assembly {
            let i := 0
            p := add(bs, p)
            let tmp := mload(p)
            for {

            } lt(i, sz) {

            } {
                x := or(x, shl(mul(8, i), byte(i, tmp)))
                p := add(p, 0x01)
                i := add(i, 1)
            }
        }
        return (x, sz);
    }

    /**
     * `_decode_(s)fixed(32|64)` is the concrete implementation of `_decode_uintf`
     */
    function _decode_fixed32(uint256 p, bytes memory bs) internal pure returns (uint32, uint256) {
        (uint256 x, uint256 sz) = _decode_uintf(p, bs, 4);
        return (uint32(x), sz);
    }

    function _decode_fixed64(uint256 p, bytes memory bs) internal pure returns (uint64, uint256) {
        (uint256 x, uint256 sz) = _decode_uintf(p, bs, 8);
        return (uint64(x), sz);
    }

    function _decode_sfixed32(uint256 p, bytes memory bs) internal pure returns (int32, uint256) {
        (uint256 x, uint256 sz) = _decode_uintf(p, bs, 4);
        int256 r;
        assembly {
            r := x
        }
        return (int32(r), sz);
    }

    function _decode_sfixed64(uint256 p, bytes memory bs) internal pure returns (int64, uint256) {
        (uint256 x, uint256 sz) = _decode_uintf(p, bs, 8);
        int256 r;
        assembly {
            r := x
        }
        return (int64(r), sz);
    }

    /**
     * @dev Decode bytes array
     * @param p The memory offset of `bs`
     * @param bs The bytes array to be decoded
     * @return The decoded bytes array
     * @return The length of `bs` used to get decoded
     */
    function _decode_lendelim(uint256 p, bytes memory bs) internal pure returns (bytes memory, uint256) {
        //
        // First read the size encoded in `varint`, then use the size to read bytes.
        //
        (uint256 len, uint256 sz) = _decode_varint(p, bs);
        bytes memory b = new bytes(len);
        uint256 length = bs.length + WORD_LENGTH;
        assert(p + sz + len <= length);
        uint256 sourcePtr;
        uint256 destPtr;
        assembly {
            destPtr := add(b, 32)
            sourcePtr := add(add(bs, p), sz)
        }
        copyBytes(sourcePtr, destPtr, len);
        return (b, sz + len);
    }

    // Encoders
    /**
     * @dev Encode ProtoBuf key
     * @param x The field ID
     * @param wt The WireType specified in ProtoBuf
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The length of encoded bytes
     */
    function _encode_key(
        uint256 x,
        WireType wt,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint256 i;
        assembly {
            i := or(mul(x, 8), mod(wt, 8))
        }
        return _encode_varint(i, p, bs);
    }

    /**
     * @dev Encode ProtoBuf varint
     * @param x The unsigned integer to be encoded
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The length of encoded bytes
     */
    function _encode_varint(
        uint256 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        //
        // Refer to https://developers.google.com/protocol-buffers/docs/encoding
        //
        uint256 sz = 0;
        assembly {
            let bsptr := add(bs, p)
            let byt := and(x, 0x7f)
            for {

            } gt(shr(7, x), 0) {

            } {
                mstore8(bsptr, or(0x80, byt))
                bsptr := add(bsptr, 1)
                sz := add(sz, 1)
                x := shr(7, x)
                byt := and(x, 0x7f)
            }
            mstore8(bsptr, byt)
            sz := add(sz, 1)
        }
        return sz;
    }

    /**
     * @dev Encode ProtoBuf zig-zag encoding
     * @param x The signed integer to be encoded
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The length of encoded bytes
     */
    function _encode_varints(
        int256 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        //
        // Refer to https://developers.google.com/protocol-buffers/docs/encoding
        //
        uint256 encodedInt = _encode_zigzag(x);
        return _encode_varint(encodedInt, p, bs);
    }

    /**
     * @dev Encode ProtoBuf bytes
     * @param xs The bytes array to be encoded
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The length of encoded bytes
     */
    function _encode_bytes(
        bytes memory xs,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint256 xsLength = xs.length;
        uint256 sz = _encode_varint(xsLength, p, bs);
        uint256 count = 0;
        assembly {
            let bsptr := add(bs, add(p, sz))
            let xsptr := add(xs, 32)
            for {

            } lt(count, xsLength) {

            } {
                mstore8(bsptr, byte(0, mload(xsptr)))
                bsptr := add(bsptr, 1)
                xsptr := add(xsptr, 1)
                count := add(count, 1)
            }
        }
        return sz + count;
    }

    /**
     * @dev Encode ProtoBuf string
     * @param xs The string to be encoded
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The length of encoded bytes
     */
    function _encode_string(
        string memory xs,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_bytes(bytes(xs), p, bs);
    }

    //
    // `_encode_(u)int(32|64)`, `_encode_enum` and `_encode_bool`
    // are concrete implementation of `_encode_varint`
    //
    function _encode_uint32(
        uint32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_varint(x, p, bs);
    }

    function _encode_uint64(
        uint64 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_varint(x, p, bs);
    }

    function _encode_int32(
        int32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint64 twosComplement;
        assembly {
            twosComplement := x
        }
        return _encode_varint(twosComplement, p, bs);
    }

    function _encode_int64(
        int64 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint64 twosComplement;
        assembly {
            twosComplement := x
        }
        return _encode_varint(twosComplement, p, bs);
    }

    function _encode_enum(
        int32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_int32(x, p, bs);
    }

    function _encode_bool(
        bool x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        if (x) {
            return _encode_varint(1, p, bs);
        } else return _encode_varint(0, p, bs);
    }

    //
    // `_encode_sint(32|64)`, `_encode_enum` and `_encode_bool`
    // are the concrete implementation of `_encode_varints`
    //
    function _encode_sint32(
        int32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_varints(x, p, bs);
    }

    function _encode_sint64(
        int64 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_varints(x, p, bs);
    }

    //
    // `_encode_(s)fixed(32|64)` is the concrete implementation of `_encode_uintf`
    //
    function _encode_fixed32(
        uint32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_uintf(x, p, bs, 4);
    }

    function _encode_fixed64(
        uint64 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_uintf(x, p, bs, 8);
    }

    function _encode_sfixed32(
        int32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint32 twosComplement;
        assembly {
            twosComplement := x
        }
        return _encode_uintf(twosComplement, p, bs, 4);
    }

    function _encode_sfixed64(
        int64 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint64 twosComplement;
        assembly {
            twosComplement := x
        }
        return _encode_uintf(twosComplement, p, bs, 8);
    }

    /**
     * @dev Encode ProtoBuf fixed-length integer
     * @param x The unsigned integer to be encoded
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The length of encoded bytes
     */
    function _encode_uintf(
        uint256 x,
        uint256 p,
        bytes memory bs,
        uint256 sz
    ) internal pure returns (uint256) {
        assembly {
            let bsptr := add(sz, add(bs, p))
            let count := sz
            for {

            } gt(count, 0) {

            } {
                bsptr := sub(bsptr, 1)
                mstore8(bsptr, byte(sub(32, count), x))
                count := sub(count, 1)
            }
        }
        return sz;
    }

    /**
     * @dev Encode ProtoBuf zig-zag signed integer
     * @param i The unsigned integer to be encoded
     * @return The encoded unsigned integer
     */
    function _encode_zigzag(int256 i) internal pure returns (uint256) {
        if (i >= 0) {
            return uint256(i) * 2;
        } else return uint256(i * -2) - 1;
    }

    // Estimators
    /**
     * @dev Estimate the length of encoded LengthDelim
     * @param i The length of LengthDelim
     * @return The estimated encoded length
     */
    function _sz_lendelim(uint256 i) internal pure returns (uint256) {
        return i + _sz_varint(i);
    }

    /**
     * @dev Estimate the length of encoded ProtoBuf field ID
     * @param i The field ID
     * @return The estimated encoded length
     */
    function _sz_key(uint256 i) internal pure returns (uint256) {
        if (i < 16) {
            return 1;
        } else if (i < 2048) {
            return 2;
        } else if (i < 262144) {
            return 3;
        } else {
            revert("not supported");
        }
    }

    /**
     * @dev Estimate the length of encoded ProtoBuf varint
     * @param i The unsigned integer
     * @return The estimated encoded length
     */
    function _sz_varint(uint256 i) internal pure returns (uint256) {
        uint256 count = 1;
        assembly {
            i := shr(7, i)
            for {

            } gt(i, 0) {

            } {
                i := shr(7, i)
                count := add(count, 1)
            }
        }
        return count;
    }

    /**
     * `_sz_(u)int(32|64)` and `_sz_enum` are the concrete implementation of `_sz_varint`
     */
    function _sz_uint32(uint32 i) internal pure returns (uint256) {
        return _sz_varint(i);
    }

    function _sz_uint64(uint64 i) internal pure returns (uint256) {
        return _sz_varint(i);
    }

    function _sz_int32(int32 i) internal pure returns (uint256) {
        if (i < 0) {
            return 10;
        } else return _sz_varint(uint32(i));
    }

    function _sz_int64(int64 i) internal pure returns (uint256) {
        if (i < 0) {
            return 10;
        } else return _sz_varint(uint64(i));
    }

    function _sz_enum(int64 i) internal pure returns (uint256) {
        if (i < 0) {
            return 10;
        } else return _sz_varint(uint64(i));
    }

    /**
     * `_sz_sint(32|64)` and `_sz_enum` are the concrete implementation of zig-zag encoding
     */
    function _sz_sint32(int32 i) internal pure returns (uint256) {
        return _sz_varint(_encode_zigzag(i));
    }

    function _sz_sint64(int64 i) internal pure returns (uint256) {
        return _sz_varint(_encode_zigzag(i));
    }

    // Soltype extensions
    /**
     * @dev Decode Solidity integer and/or fixed-size bytes array, filling from lowest bit.
     * @param n The maximum number of bytes to read
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The bytes32 representation
     * @return The number of bytes used to decode
     */
    function _decode_sol_bytesN_lower(
        uint8 n,
        uint256 p,
        bytes memory bs
    ) internal pure returns (bytes32, uint256) {
        uint256 r;
        (uint256 len, uint256 sz) = _decode_varint(p, bs);
        if (len + sz > n + 3) {
            revert(OVERFLOW_MESSAGE);
        }
        p += 3;
        assert(p < bs.length + WORD_LENGTH);
        assembly {
            r := mload(add(p, bs))
        }
        for (uint256 i = len - 2; i < WORD_LENGTH; i++) {
            r /= 256;
        }
        return (bytes32(r), len + sz);
    }

    /**
     * @dev Decode Solidity integer and/or fixed-size bytes array, filling from highest bit.
     * @param n The maximum number of bytes to read
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The bytes32 representation
     * @return The number of bytes used to decode
     */
    function _decode_sol_bytesN(
        uint8 n,
        uint256 p,
        bytes memory bs
    ) internal pure returns (bytes32, uint256) {
        (uint256 len, uint256 sz) = _decode_varint(p, bs);
        uint256 wordLength = WORD_LENGTH;
        uint256 byteSize = BYTE_SIZE;
        if (len + sz > n + 3) {
            revert(OVERFLOW_MESSAGE);
        }
        p += 3;
        bytes32 acc;
        assert(p < bs.length + WORD_LENGTH);
        assembly {
            acc := mload(add(p, bs))
            let difference := sub(wordLength, sub(len, 2))
            let bits := mul(byteSize, difference)
            acc := shl(bits, shr(bits, acc))
        }
        return (acc, len + sz);
    }

    /*
     * `_decode_sol*` are the concrete implementation of decoding Solidity types
     */
    function _decode_sol_address(uint256 p, bytes memory bs) internal pure returns (address, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytesN(20, p, bs);
        return (address(bytes20(r)), sz);
    }

    function _decode_sol_bool(uint256 p, bytes memory bs) internal pure returns (bool, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(1, p, bs);
        if (r == 0) {
            return (false, sz);
        }
        return (true, sz);
    }

    function _decode_sol_uint(uint256 p, bytes memory bs) internal pure returns (uint256, uint256) {
        return _decode_sol_uint256(p, bs);
    }

    function _decode_sol_uintN(
        uint8 n,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256, uint256) {
        (bytes32 u, uint256 sz) = _decode_sol_bytesN_lower(n, p, bs);
        uint256 r;
        assembly {
            r := u
        }
        return (r, sz);
    }

    function _decode_sol_uint8(uint256 p, bytes memory bs) internal pure returns (uint8, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(1, p, bs);
        return (uint8(r), sz);
    }

    function _decode_sol_uint16(uint256 p, bytes memory bs) internal pure returns (uint16, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(2, p, bs);
        return (uint16(r), sz);
    }

    function _decode_sol_uint24(uint256 p, bytes memory bs) internal pure returns (uint24, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(3, p, bs);
        return (uint24(r), sz);
    }

    function _decode_sol_uint32(uint256 p, bytes memory bs) internal pure returns (uint32, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(4, p, bs);
        return (uint32(r), sz);
    }

    function _decode_sol_uint40(uint256 p, bytes memory bs) internal pure returns (uint40, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(5, p, bs);
        return (uint40(r), sz);
    }

    function _decode_sol_uint48(uint256 p, bytes memory bs) internal pure returns (uint48, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(6, p, bs);
        return (uint48(r), sz);
    }

    function _decode_sol_uint56(uint256 p, bytes memory bs) internal pure returns (uint56, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(7, p, bs);
        return (uint56(r), sz);
    }

    function _decode_sol_uint64(uint256 p, bytes memory bs) internal pure returns (uint64, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(8, p, bs);
        return (uint64(r), sz);
    }

    function _decode_sol_uint72(uint256 p, bytes memory bs) internal pure returns (uint72, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(9, p, bs);
        return (uint72(r), sz);
    }

    function _decode_sol_uint80(uint256 p, bytes memory bs) internal pure returns (uint80, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(10, p, bs);
        return (uint80(r), sz);
    }

    function _decode_sol_uint88(uint256 p, bytes memory bs) internal pure returns (uint88, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(11, p, bs);
        return (uint88(r), sz);
    }

    function _decode_sol_uint96(uint256 p, bytes memory bs) internal pure returns (uint96, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(12, p, bs);
        return (uint96(r), sz);
    }

    function _decode_sol_uint104(uint256 p, bytes memory bs) internal pure returns (uint104, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(13, p, bs);
        return (uint104(r), sz);
    }

    function _decode_sol_uint112(uint256 p, bytes memory bs) internal pure returns (uint112, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(14, p, bs);
        return (uint112(r), sz);
    }

    function _decode_sol_uint120(uint256 p, bytes memory bs) internal pure returns (uint120, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(15, p, bs);
        return (uint120(r), sz);
    }

    function _decode_sol_uint128(uint256 p, bytes memory bs) internal pure returns (uint128, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(16, p, bs);
        return (uint128(r), sz);
    }

    function _decode_sol_uint136(uint256 p, bytes memory bs) internal pure returns (uint136, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(17, p, bs);
        return (uint136(r), sz);
    }

    function _decode_sol_uint144(uint256 p, bytes memory bs) internal pure returns (uint144, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(18, p, bs);
        return (uint144(r), sz);
    }

    function _decode_sol_uint152(uint256 p, bytes memory bs) internal pure returns (uint152, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(19, p, bs);
        return (uint152(r), sz);
    }

    function _decode_sol_uint160(uint256 p, bytes memory bs) internal pure returns (uint160, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(20, p, bs);
        return (uint160(r), sz);
    }

    function _decode_sol_uint168(uint256 p, bytes memory bs) internal pure returns (uint168, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(21, p, bs);
        return (uint168(r), sz);
    }

    function _decode_sol_uint176(uint256 p, bytes memory bs) internal pure returns (uint176, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(22, p, bs);
        return (uint176(r), sz);
    }

    function _decode_sol_uint184(uint256 p, bytes memory bs) internal pure returns (uint184, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(23, p, bs);
        return (uint184(r), sz);
    }

    function _decode_sol_uint192(uint256 p, bytes memory bs) internal pure returns (uint192, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(24, p, bs);
        return (uint192(r), sz);
    }

    function _decode_sol_uint200(uint256 p, bytes memory bs) internal pure returns (uint200, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(25, p, bs);
        return (uint200(r), sz);
    }

    function _decode_sol_uint208(uint256 p, bytes memory bs) internal pure returns (uint208, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(26, p, bs);
        return (uint208(r), sz);
    }

    function _decode_sol_uint216(uint256 p, bytes memory bs) internal pure returns (uint216, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(27, p, bs);
        return (uint216(r), sz);
    }

    function _decode_sol_uint224(uint256 p, bytes memory bs) internal pure returns (uint224, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(28, p, bs);
        return (uint224(r), sz);
    }

    function _decode_sol_uint232(uint256 p, bytes memory bs) internal pure returns (uint232, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(29, p, bs);
        return (uint232(r), sz);
    }

    function _decode_sol_uint240(uint256 p, bytes memory bs) internal pure returns (uint240, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(30, p, bs);
        return (uint240(r), sz);
    }

    function _decode_sol_uint248(uint256 p, bytes memory bs) internal pure returns (uint248, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(31, p, bs);
        return (uint248(r), sz);
    }

    function _decode_sol_uint256(uint256 p, bytes memory bs) internal pure returns (uint256, uint256) {
        (uint256 r, uint256 sz) = _decode_sol_uintN(32, p, bs);
        return (uint256(r), sz);
    }

    function _decode_sol_int(uint256 p, bytes memory bs) internal pure returns (int256, uint256) {
        return _decode_sol_int256(p, bs);
    }

    function _decode_sol_intN(
        uint8 n,
        uint256 p,
        bytes memory bs
    ) internal pure returns (int256, uint256) {
        (bytes32 u, uint256 sz) = _decode_sol_bytesN_lower(n, p, bs);
        int256 r;
        assembly {
            r := u
            r := signextend(sub(sz, 4), r)
        }
        return (r, sz);
    }

    function _decode_sol_bytes(
        uint8 n,
        uint256 p,
        bytes memory bs
    ) internal pure returns (bytes32, uint256) {
        (bytes32 u, uint256 sz) = _decode_sol_bytesN(n, p, bs);
        return (u, sz);
    }

    function _decode_sol_int8(uint256 p, bytes memory bs) internal pure returns (int8, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(1, p, bs);
        return (int8(r), sz);
    }

    function _decode_sol_int16(uint256 p, bytes memory bs) internal pure returns (int16, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(2, p, bs);
        return (int16(r), sz);
    }

    function _decode_sol_int24(uint256 p, bytes memory bs) internal pure returns (int24, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(3, p, bs);
        return (int24(r), sz);
    }

    function _decode_sol_int32(uint256 p, bytes memory bs) internal pure returns (int32, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(4, p, bs);
        return (int32(r), sz);
    }

    function _decode_sol_int40(uint256 p, bytes memory bs) internal pure returns (int40, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(5, p, bs);
        return (int40(r), sz);
    }

    function _decode_sol_int48(uint256 p, bytes memory bs) internal pure returns (int48, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(6, p, bs);
        return (int48(r), sz);
    }

    function _decode_sol_int56(uint256 p, bytes memory bs) internal pure returns (int56, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(7, p, bs);
        return (int56(r), sz);
    }

    function _decode_sol_int64(uint256 p, bytes memory bs) internal pure returns (int64, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(8, p, bs);
        return (int64(r), sz);
    }

    function _decode_sol_int72(uint256 p, bytes memory bs) internal pure returns (int72, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(9, p, bs);
        return (int72(r), sz);
    }

    function _decode_sol_int80(uint256 p, bytes memory bs) internal pure returns (int80, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(10, p, bs);
        return (int80(r), sz);
    }

    function _decode_sol_int88(uint256 p, bytes memory bs) internal pure returns (int88, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(11, p, bs);
        return (int88(r), sz);
    }

    function _decode_sol_int96(uint256 p, bytes memory bs) internal pure returns (int96, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(12, p, bs);
        return (int96(r), sz);
    }

    function _decode_sol_int104(uint256 p, bytes memory bs) internal pure returns (int104, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(13, p, bs);
        return (int104(r), sz);
    }

    function _decode_sol_int112(uint256 p, bytes memory bs) internal pure returns (int112, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(14, p, bs);
        return (int112(r), sz);
    }

    function _decode_sol_int120(uint256 p, bytes memory bs) internal pure returns (int120, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(15, p, bs);
        return (int120(r), sz);
    }

    function _decode_sol_int128(uint256 p, bytes memory bs) internal pure returns (int128, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(16, p, bs);
        return (int128(r), sz);
    }

    function _decode_sol_int136(uint256 p, bytes memory bs) internal pure returns (int136, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(17, p, bs);
        return (int136(r), sz);
    }

    function _decode_sol_int144(uint256 p, bytes memory bs) internal pure returns (int144, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(18, p, bs);
        return (int144(r), sz);
    }

    function _decode_sol_int152(uint256 p, bytes memory bs) internal pure returns (int152, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(19, p, bs);
        return (int152(r), sz);
    }

    function _decode_sol_int160(uint256 p, bytes memory bs) internal pure returns (int160, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(20, p, bs);
        return (int160(r), sz);
    }

    function _decode_sol_int168(uint256 p, bytes memory bs) internal pure returns (int168, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(21, p, bs);
        return (int168(r), sz);
    }

    function _decode_sol_int176(uint256 p, bytes memory bs) internal pure returns (int176, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(22, p, bs);
        return (int176(r), sz);
    }

    function _decode_sol_int184(uint256 p, bytes memory bs) internal pure returns (int184, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(23, p, bs);
        return (int184(r), sz);
    }

    function _decode_sol_int192(uint256 p, bytes memory bs) internal pure returns (int192, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(24, p, bs);
        return (int192(r), sz);
    }

    function _decode_sol_int200(uint256 p, bytes memory bs) internal pure returns (int200, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(25, p, bs);
        return (int200(r), sz);
    }

    function _decode_sol_int208(uint256 p, bytes memory bs) internal pure returns (int208, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(26, p, bs);
        return (int208(r), sz);
    }

    function _decode_sol_int216(uint256 p, bytes memory bs) internal pure returns (int216, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(27, p, bs);
        return (int216(r), sz);
    }

    function _decode_sol_int224(uint256 p, bytes memory bs) internal pure returns (int224, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(28, p, bs);
        return (int224(r), sz);
    }

    function _decode_sol_int232(uint256 p, bytes memory bs) internal pure returns (int232, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(29, p, bs);
        return (int232(r), sz);
    }

    function _decode_sol_int240(uint256 p, bytes memory bs) internal pure returns (int240, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(30, p, bs);
        return (int240(r), sz);
    }

    function _decode_sol_int248(uint256 p, bytes memory bs) internal pure returns (int248, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(31, p, bs);
        return (int248(r), sz);
    }

    function _decode_sol_int256(uint256 p, bytes memory bs) internal pure returns (int256, uint256) {
        (int256 r, uint256 sz) = _decode_sol_intN(32, p, bs);
        return (int256(r), sz);
    }

    function _decode_sol_bytes1(uint256 p, bytes memory bs) internal pure returns (bytes1, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(1, p, bs);
        return (bytes1(r), sz);
    }

    function _decode_sol_bytes2(uint256 p, bytes memory bs) internal pure returns (bytes2, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(2, p, bs);
        return (bytes2(r), sz);
    }

    function _decode_sol_bytes3(uint256 p, bytes memory bs) internal pure returns (bytes3, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(3, p, bs);
        return (bytes3(r), sz);
    }

    function _decode_sol_bytes4(uint256 p, bytes memory bs) internal pure returns (bytes4, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(4, p, bs);
        return (bytes4(r), sz);
    }

    function _decode_sol_bytes5(uint256 p, bytes memory bs) internal pure returns (bytes5, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(5, p, bs);
        return (bytes5(r), sz);
    }

    function _decode_sol_bytes6(uint256 p, bytes memory bs) internal pure returns (bytes6, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(6, p, bs);
        return (bytes6(r), sz);
    }

    function _decode_sol_bytes7(uint256 p, bytes memory bs) internal pure returns (bytes7, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(7, p, bs);
        return (bytes7(r), sz);
    }

    function _decode_sol_bytes8(uint256 p, bytes memory bs) internal pure returns (bytes8, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(8, p, bs);
        return (bytes8(r), sz);
    }

    function _decode_sol_bytes9(uint256 p, bytes memory bs) internal pure returns (bytes9, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(9, p, bs);
        return (bytes9(r), sz);
    }

    function _decode_sol_bytes10(uint256 p, bytes memory bs) internal pure returns (bytes10, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(10, p, bs);
        return (bytes10(r), sz);
    }

    function _decode_sol_bytes11(uint256 p, bytes memory bs) internal pure returns (bytes11, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(11, p, bs);
        return (bytes11(r), sz);
    }

    function _decode_sol_bytes12(uint256 p, bytes memory bs) internal pure returns (bytes12, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(12, p, bs);
        return (bytes12(r), sz);
    }

    function _decode_sol_bytes13(uint256 p, bytes memory bs) internal pure returns (bytes13, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(13, p, bs);
        return (bytes13(r), sz);
    }

    function _decode_sol_bytes14(uint256 p, bytes memory bs) internal pure returns (bytes14, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(14, p, bs);
        return (bytes14(r), sz);
    }

    function _decode_sol_bytes15(uint256 p, bytes memory bs) internal pure returns (bytes15, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(15, p, bs);
        return (bytes15(r), sz);
    }

    function _decode_sol_bytes16(uint256 p, bytes memory bs) internal pure returns (bytes16, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(16, p, bs);
        return (bytes16(r), sz);
    }

    function _decode_sol_bytes17(uint256 p, bytes memory bs) internal pure returns (bytes17, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(17, p, bs);
        return (bytes17(r), sz);
    }

    function _decode_sol_bytes18(uint256 p, bytes memory bs) internal pure returns (bytes18, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(18, p, bs);
        return (bytes18(r), sz);
    }

    function _decode_sol_bytes19(uint256 p, bytes memory bs) internal pure returns (bytes19, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(19, p, bs);
        return (bytes19(r), sz);
    }

    function _decode_sol_bytes20(uint256 p, bytes memory bs) internal pure returns (bytes20, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(20, p, bs);
        return (bytes20(r), sz);
    }

    function _decode_sol_bytes21(uint256 p, bytes memory bs) internal pure returns (bytes21, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(21, p, bs);
        return (bytes21(r), sz);
    }

    function _decode_sol_bytes22(uint256 p, bytes memory bs) internal pure returns (bytes22, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(22, p, bs);
        return (bytes22(r), sz);
    }

    function _decode_sol_bytes23(uint256 p, bytes memory bs) internal pure returns (bytes23, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(23, p, bs);
        return (bytes23(r), sz);
    }

    function _decode_sol_bytes24(uint256 p, bytes memory bs) internal pure returns (bytes24, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(24, p, bs);
        return (bytes24(r), sz);
    }

    function _decode_sol_bytes25(uint256 p, bytes memory bs) internal pure returns (bytes25, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(25, p, bs);
        return (bytes25(r), sz);
    }

    function _decode_sol_bytes26(uint256 p, bytes memory bs) internal pure returns (bytes26, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(26, p, bs);
        return (bytes26(r), sz);
    }

    function _decode_sol_bytes27(uint256 p, bytes memory bs) internal pure returns (bytes27, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(27, p, bs);
        return (bytes27(r), sz);
    }

    function _decode_sol_bytes28(uint256 p, bytes memory bs) internal pure returns (bytes28, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(28, p, bs);
        return (bytes28(r), sz);
    }

    function _decode_sol_bytes29(uint256 p, bytes memory bs) internal pure returns (bytes29, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(29, p, bs);
        return (bytes29(r), sz);
    }

    function _decode_sol_bytes30(uint256 p, bytes memory bs) internal pure returns (bytes30, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(30, p, bs);
        return (bytes30(r), sz);
    }

    function _decode_sol_bytes31(uint256 p, bytes memory bs) internal pure returns (bytes31, uint256) {
        (bytes32 r, uint256 sz) = _decode_sol_bytes(31, p, bs);
        return (bytes31(r), sz);
    }

    function _decode_sol_bytes32(uint256 p, bytes memory bs) internal pure returns (bytes32, uint256) {
        return _decode_sol_bytes(32, p, bs);
    }

    /*
     * `_encode_sol*` are the concrete implementation of encoding Solidity types
     */
    function _encode_sol_address(
        address x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(uint160(x)), 20, p, bs);
    }

    function _encode_sol_uint(
        uint256 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 32, p, bs);
    }

    function _encode_sol_uint8(
        uint8 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 1, p, bs);
    }

    function _encode_sol_uint16(
        uint16 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 2, p, bs);
    }

    function _encode_sol_uint24(
        uint24 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 3, p, bs);
    }

    function _encode_sol_uint32(
        uint32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 4, p, bs);
    }

    function _encode_sol_uint40(
        uint40 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 5, p, bs);
    }

    function _encode_sol_uint48(
        uint48 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 6, p, bs);
    }

    function _encode_sol_uint56(
        uint56 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 7, p, bs);
    }

    function _encode_sol_uint64(
        uint64 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 8, p, bs);
    }

    function _encode_sol_uint72(
        uint72 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 9, p, bs);
    }

    function _encode_sol_uint80(
        uint80 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 10, p, bs);
    }

    function _encode_sol_uint88(
        uint88 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 11, p, bs);
    }

    function _encode_sol_uint96(
        uint96 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 12, p, bs);
    }

    function _encode_sol_uint104(
        uint104 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 13, p, bs);
    }

    function _encode_sol_uint112(
        uint112 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 14, p, bs);
    }

    function _encode_sol_uint120(
        uint120 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 15, p, bs);
    }

    function _encode_sol_uint128(
        uint128 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 16, p, bs);
    }

    function _encode_sol_uint136(
        uint136 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 17, p, bs);
    }

    function _encode_sol_uint144(
        uint144 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 18, p, bs);
    }

    function _encode_sol_uint152(
        uint152 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 19, p, bs);
    }

    function _encode_sol_uint160(
        uint160 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 20, p, bs);
    }

    function _encode_sol_uint168(
        uint168 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 21, p, bs);
    }

    function _encode_sol_uint176(
        uint176 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 22, p, bs);
    }

    function _encode_sol_uint184(
        uint184 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 23, p, bs);
    }

    function _encode_sol_uint192(
        uint192 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 24, p, bs);
    }

    function _encode_sol_uint200(
        uint200 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 25, p, bs);
    }

    function _encode_sol_uint208(
        uint208 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 26, p, bs);
    }

    function _encode_sol_uint216(
        uint216 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 27, p, bs);
    }

    function _encode_sol_uint224(
        uint224 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 28, p, bs);
    }

    function _encode_sol_uint232(
        uint232 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 29, p, bs);
    }

    function _encode_sol_uint240(
        uint240 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 30, p, bs);
    }

    function _encode_sol_uint248(
        uint248 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 31, p, bs);
    }

    function _encode_sol_uint256(
        uint256 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(uint256(x), 32, p, bs);
    }

    function _encode_sol_int(
        int256 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(x, 32, p, bs);
    }

    function _encode_sol_int8(
        int8 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 1, p, bs);
    }

    function _encode_sol_int16(
        int16 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 2, p, bs);
    }

    function _encode_sol_int24(
        int24 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 3, p, bs);
    }

    function _encode_sol_int32(
        int32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 4, p, bs);
    }

    function _encode_sol_int40(
        int40 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 5, p, bs);
    }

    function _encode_sol_int48(
        int48 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 6, p, bs);
    }

    function _encode_sol_int56(
        int56 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 7, p, bs);
    }

    function _encode_sol_int64(
        int64 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 8, p, bs);
    }

    function _encode_sol_int72(
        int72 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 9, p, bs);
    }

    function _encode_sol_int80(
        int80 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 10, p, bs);
    }

    function _encode_sol_int88(
        int88 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 11, p, bs);
    }

    function _encode_sol_int96(
        int96 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 12, p, bs);
    }

    function _encode_sol_int104(
        int104 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 13, p, bs);
    }

    function _encode_sol_int112(
        int112 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 14, p, bs);
    }

    function _encode_sol_int120(
        int120 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 15, p, bs);
    }

    function _encode_sol_int128(
        int128 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 16, p, bs);
    }

    function _encode_sol_int136(
        int136 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 17, p, bs);
    }

    function _encode_sol_int144(
        int144 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 18, p, bs);
    }

    function _encode_sol_int152(
        int152 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 19, p, bs);
    }

    function _encode_sol_int160(
        int160 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 20, p, bs);
    }

    function _encode_sol_int168(
        int168 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 21, p, bs);
    }

    function _encode_sol_int176(
        int176 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 22, p, bs);
    }

    function _encode_sol_int184(
        int184 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 23, p, bs);
    }

    function _encode_sol_int192(
        int192 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 24, p, bs);
    }

    function _encode_sol_int200(
        int200 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 25, p, bs);
    }

    function _encode_sol_int208(
        int208 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 26, p, bs);
    }

    function _encode_sol_int216(
        int216 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 27, p, bs);
    }

    function _encode_sol_int224(
        int224 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 28, p, bs);
    }

    function _encode_sol_int232(
        int232 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 29, p, bs);
    }

    function _encode_sol_int240(
        int240 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 30, p, bs);
    }

    function _encode_sol_int248(
        int248 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(int256(x), 31, p, bs);
    }

    function _encode_sol_int256(
        int256 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol(x, 32, p, bs);
    }

    function _encode_sol_bytes1(
        bytes1 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 1, p, bs);
    }

    function _encode_sol_bytes2(
        bytes2 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 2, p, bs);
    }

    function _encode_sol_bytes3(
        bytes3 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 3, p, bs);
    }

    function _encode_sol_bytes4(
        bytes4 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 4, p, bs);
    }

    function _encode_sol_bytes5(
        bytes5 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 5, p, bs);
    }

    function _encode_sol_bytes6(
        bytes6 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 6, p, bs);
    }

    function _encode_sol_bytes7(
        bytes7 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 7, p, bs);
    }

    function _encode_sol_bytes8(
        bytes8 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 8, p, bs);
    }

    function _encode_sol_bytes9(
        bytes9 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 9, p, bs);
    }

    function _encode_sol_bytes10(
        bytes10 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 10, p, bs);
    }

    function _encode_sol_bytes11(
        bytes11 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 11, p, bs);
    }

    function _encode_sol_bytes12(
        bytes12 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 12, p, bs);
    }

    function _encode_sol_bytes13(
        bytes13 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 13, p, bs);
    }

    function _encode_sol_bytes14(
        bytes14 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 14, p, bs);
    }

    function _encode_sol_bytes15(
        bytes15 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 15, p, bs);
    }

    function _encode_sol_bytes16(
        bytes16 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 16, p, bs);
    }

    function _encode_sol_bytes17(
        bytes17 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 17, p, bs);
    }

    function _encode_sol_bytes18(
        bytes18 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 18, p, bs);
    }

    function _encode_sol_bytes19(
        bytes19 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 19, p, bs);
    }

    function _encode_sol_bytes20(
        bytes20 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 20, p, bs);
    }

    function _encode_sol_bytes21(
        bytes21 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 21, p, bs);
    }

    function _encode_sol_bytes22(
        bytes22 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 22, p, bs);
    }

    function _encode_sol_bytes23(
        bytes23 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 23, p, bs);
    }

    function _encode_sol_bytes24(
        bytes24 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 24, p, bs);
    }

    function _encode_sol_bytes25(
        bytes25 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 25, p, bs);
    }

    function _encode_sol_bytes26(
        bytes26 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 26, p, bs);
    }

    function _encode_sol_bytes27(
        bytes27 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 27, p, bs);
    }

    function _encode_sol_bytes28(
        bytes28 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 28, p, bs);
    }

    function _encode_sol_bytes29(
        bytes29 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 29, p, bs);
    }

    function _encode_sol_bytes30(
        bytes30 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 30, p, bs);
    }

    function _encode_sol_bytes31(
        bytes31 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(bytes32(x), 31, p, bs);
    }

    function _encode_sol_bytes32(
        bytes32 x,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        return _encode_sol_bytes(x, 32, p, bs);
    }

    /**
     * @dev Encode the key of Solidity integer and/or fixed-size bytes array.
     * @param sz The number of bytes used to encode Solidity types
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The number of bytes used to encode
     */
    function _encode_sol_header(
        uint256 sz,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint256 offset = p;
        p += _encode_varint(sz + 2, p, bs);
        p += _encode_key(1, WireType.LengthDelim, p, bs);
        p += _encode_varint(sz, p, bs);
        return p - offset;
    }

    /**
     * @dev Encode Solidity type
     * @param x The unsinged integer to be encoded
     * @param sz The number of bytes used to encode Solidity types
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The number of bytes used to encode
     */
    function _encode_sol(
        uint256 x,
        uint256 sz,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 size;
        p += 3;
        size = _encode_sol_raw_other(x, p, bs, sz);
        p += size;
        _encode_sol_header(size, offset, bs);
        return p - offset;
    }

    /**
     * @dev Encode Solidity type
     * @param x The signed integer to be encoded
     * @param sz The number of bytes used to encode Solidity types
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The number of bytes used to encode
     */
    function _encode_sol(
        int256 x,
        uint256 sz,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 size;
        p += 3;
        size = _encode_sol_raw_other(x, p, bs, sz);
        p += size;
        _encode_sol_header(size, offset, bs);
        return p - offset;
    }

    /**
     * @dev Encode Solidity type
     * @param x The fixed-size byte array to be encoded
     * @param sz The number of bytes used to encode Solidity types
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The number of bytes used to encode
     */
    function _encode_sol_bytes(
        bytes32 x,
        uint256 sz,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 size;
        p += 3;
        size = _encode_sol_raw_bytes_array(x, p, bs, sz);
        p += size;
        _encode_sol_header(size, offset, bs);
        return p - offset;
    }

    /**
     * @dev Get the actual size needed to encoding an unsigned integer
     * @param x The unsigned integer to be encoded
     * @param sz The maximum number of bytes used to encode Solidity types
     * @return The number of bytes needed for encoding `x`
     */
    function _get_real_size(uint256 x, uint256 sz) internal pure returns (uint256) {
        uint256 base = 0xff;
        uint256 realSize = sz;
        while (x & (base << (realSize * BYTE_SIZE - BYTE_SIZE)) == 0 && realSize > 0) {
            realSize -= 1;
        }
        if (realSize == 0) {
            realSize = 1;
        }
        return realSize;
    }

    /**
     * @dev Get the actual size needed to encoding an signed integer
     * @param x The signed integer to be encoded
     * @param sz The maximum number of bytes used to encode Solidity types
     * @return The number of bytes needed for encoding `x`
     */
    function _get_real_size(int256 x, uint256 sz) internal pure returns (uint256) {
        int256 base = 0xff;
        if (x >= 0) {
            uint256 tmp = _get_real_size(uint256(x), sz);
            int256 remainder = (x & (base << (tmp * BYTE_SIZE - BYTE_SIZE))) >> (tmp * BYTE_SIZE - BYTE_SIZE);
            if (remainder >= 128) {
                tmp += 1;
            }
            return tmp;
        }

        uint256 realSize = sz;
        while (
            x & (base << (realSize * BYTE_SIZE - BYTE_SIZE)) == (base << (realSize * BYTE_SIZE - BYTE_SIZE)) &&
            realSize > 0
        ) {
            realSize -= 1;
        }
        int256 remainder = (x & (base << (realSize * BYTE_SIZE - BYTE_SIZE))) >> (realSize * BYTE_SIZE - BYTE_SIZE);
        if (remainder < 128) {
            realSize += 1;
        }
        return realSize;
    }

    /**
     * @dev Encode the fixed-bytes array
     * @param x The fixed-size byte array to be encoded
     * @param sz The maximum number of bytes used to encode Solidity types
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The number of bytes needed for encoding `x`
     */
    function _encode_sol_raw_bytes_array(
        bytes32 x,
        uint256 p,
        bytes memory bs,
        uint256 sz
    ) internal pure returns (uint256) {
        //
        // The idea is to not encode the leading bytes of zero.
        //
        uint256 actualSize = sz;
        for (uint256 i = 0; i < sz; i++) {
            uint8 current = uint8(x[sz - 1 - i]);
            if (current == 0 && actualSize > 1) {
                actualSize--;
            } else {
                break;
            }
        }
        assembly {
            let bsptr := add(bs, p)
            let count := actualSize
            for {

            } gt(count, 0) {

            } {
                mstore8(bsptr, byte(sub(actualSize, count), x))
                bsptr := add(bsptr, 1)
                count := sub(count, 1)
            }
        }
        return actualSize;
    }

    /**
     * @dev Encode the signed integer
     * @param x The signed integer to be encoded
     * @param sz The maximum number of bytes used to encode Solidity types
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The number of bytes needed for encoding `x`
     */
    function _encode_sol_raw_other(
        int256 x,
        uint256 p,
        bytes memory bs,
        uint256 sz
    ) internal pure returns (uint256) {
        //
        // The idea is to not encode the leading bytes of zero.or one,
        // depending on whether it is positive.
        //
        uint256 realSize = _get_real_size(x, sz);
        assembly {
            let bsptr := add(bs, p)
            let count := realSize
            for {

            } gt(count, 0) {

            } {
                mstore8(bsptr, byte(sub(32, count), x))
                bsptr := add(bsptr, 1)
                count := sub(count, 1)
            }
        }
        return realSize;
    }

    /**
     * @dev Encode the unsigned integer
     * @param x The unsigned integer to be encoded
     * @param sz The maximum number of bytes used to encode Solidity types
     * @param p The offset of bytes array `bs`
     * @param bs The bytes array to encode
     * @return The number of bytes needed for encoding `x`
     */
    function _encode_sol_raw_other(
        uint256 x,
        uint256 p,
        bytes memory bs,
        uint256 sz
    ) internal pure returns (uint256) {
        uint256 realSize = _get_real_size(x, sz);
        assembly {
            let bsptr := add(bs, p)
            let count := realSize
            for {

            } gt(count, 0) {

            } {
                mstore8(bsptr, byte(sub(32, count), x))
                bsptr := add(bsptr, 1)
                count := sub(count, 1)
            }
        }
        return realSize;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.2;
import "./ProtoBufRuntime.sol";

library GoogleProtobufAny {
    //struct definition
    struct Data {
        string type_url;
        bytes value;
    }

    // Decoder section

    /**
     * @dev The main decoder for memory
     * @param bs The bytes array to be decoded
     * @return The decoded struct
     */
    function decode(bytes memory bs) internal pure returns (Data memory) {
        (Data memory x, ) = _decode(32, bs, bs.length);
        return x;
    }

    /**
     * @dev The main decoder for storage
     * @param self The in-storage struct
     * @param bs The bytes array to be decoded
     */
    function decode(Data storage self, bytes memory bs) internal {
        (Data memory x, ) = _decode(32, bs, bs.length);
        store(x, self);
    }

    // inner decoder

    /**
     * @dev The decoder for internal usage
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param sz The number of bytes expected
     * @return The decoded struct
     * @return The number of bytes decoded
     */
    function _decode(
        uint256 p,
        bytes memory bs,
        uint256 sz
    ) internal pure returns (Data memory, uint256) {
        Data memory r;
        uint256[3] memory counters;
        uint256 fieldId;
        ProtoBufRuntime.WireType wireType;
        uint256 bytesRead;
        uint256 offset = p;
        uint256 pointer = p;
        while (pointer < offset + sz) {
            (fieldId, wireType, bytesRead) = ProtoBufRuntime._decode_key(pointer, bs);
            pointer += bytesRead;
            if (fieldId == 1) {
                pointer += _read_type_url(pointer, bs, r, counters);
            } else if (fieldId == 2) {
                pointer += _read_value(pointer, bs, r, counters);
            } else {
                if (wireType == ProtoBufRuntime.WireType.Fixed64) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed64(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Fixed32) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_fixed32(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.Varint) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_varint(pointer, bs);
                    pointer += size;
                }
                if (wireType == ProtoBufRuntime.WireType.LengthDelim) {
                    uint256 size;
                    (, size) = ProtoBufRuntime._decode_lendelim(pointer, bs);
                    pointer += size;
                }
            }
        }
        return (r, sz);
    }

    // field readers

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_type_url(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        //
        // if `r` is NULL, then only counting the number of fields.
        //
        (string memory x, uint256 sz) = ProtoBufRuntime._decode_string(p, bs);
        if (isNil(r)) {
            counters[1] += 1;
        } else {
            r.type_url = x;
            if (counters[1] > 0) counters[1] -= 1;
        }
        return sz;
    }

    /**
     * @dev The decoder for reading a field
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @param r The in-memory struct
     * @param counters The counters for repeated fields
     * @return The number of bytes decoded
     */
    function _read_value(
        uint256 p,
        bytes memory bs,
        Data memory r,
        uint256[3] memory counters
    ) internal pure returns (uint256) {
        //
        // if `r` is NULL, then only counting the number of fields.
        //
        (bytes memory x, uint256 sz) = ProtoBufRuntime._decode_bytes(p, bs);
        if (isNil(r)) {
            counters[2] += 1;
        } else {
            r.value = x;
            if (counters[2] > 0) counters[2] -= 1;
        }
        return sz;
    }

    // Encoder section

    /**
     * @dev The main encoder for memory
     * @param r The struct to be encoded
     * @return The encoded byte array
     */
    function encode(Data memory r) internal pure returns (bytes memory) {
        bytes memory bs = new bytes(_estimate(r));
        uint256 sz = _encode(r, 32, bs);
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // inner encoder

    /**
     * @dev The encoder for internal usage
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode(
        Data memory r,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        uint256 offset = p;
        uint256 pointer = p;

        pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += ProtoBufRuntime._encode_string(r.type_url, pointer, bs);
        pointer += ProtoBufRuntime._encode_key(2, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
        pointer += ProtoBufRuntime._encode_bytes(r.value, pointer, bs);
        return pointer - offset;
    }

    // nested encoder

    /**
     * @dev The encoder for inner struct
     * @param r The struct to be encoded
     * @param p The offset of bytes array to start decode
     * @param bs The bytes array to be decoded
     * @return The number of bytes encoded
     */
    function _encode_nested(
        Data memory r,
        uint256 p,
        bytes memory bs
    ) internal pure returns (uint256) {
        //
        // First encoded `r` into a temporary array, and encode the actual size used.
        // Then copy the temporary array into `bs`.
        //
        uint256 offset = p;
        uint256 pointer = p;
        bytes memory tmp = new bytes(_estimate(r));
        uint256 tmpAddr = ProtoBufRuntime.getMemoryAddress(tmp);
        uint256 bsAddr = ProtoBufRuntime.getMemoryAddress(bs);
        uint256 size = _encode(r, 32, tmp);
        pointer += ProtoBufRuntime._encode_varint(size, pointer, bs);
        ProtoBufRuntime.copyBytes(tmpAddr + 32, bsAddr + pointer, size);
        pointer += size;
        delete tmp;
        return pointer - offset;
    }

    // estimator

    /**
     * @dev The estimator for a struct
     * @param r The struct to be encoded
     * @return The number of bytes encoded in estimation
     */
    function _estimate(Data memory r) internal pure returns (uint256) {
        uint256 e;
        e += 1 + ProtoBufRuntime._sz_lendelim(bytes(r.type_url).length);
        e += 1 + ProtoBufRuntime._sz_lendelim(r.value.length);
        return e;
    }

    //store function
    /**
     * @dev Store in-memory struct to storage
     * @param input The in-memory struct
     * @param output The in-storage struct
     */
    function store(Data memory input, Data storage output) internal {
        output.type_url = input.type_url;
        output.value = input.value;
    }

    //utility functions
    /**
     * @dev Return an empty struct
     * @return r The empty struct
     */
    function nil() internal pure returns (Data memory r) {
        assembly {
            r := 0
        }
    }

    /**
     * @dev Test whether a struct is empty
     * @param x The struct to be tested
     * @return r True if it is empty
     */
    function isNil(Data memory x) internal pure returns (bool r) {
        assembly {
            r := iszero(x)
        }
    }
}
//library Any

// SPDX-License-Identifier: TBD

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS, Validator, SimpleValidator, BlockID, Vote, CanonicalBlockID, CanonicalPartSetHeader, CanonicalVote, TmHeader, ConsensusState, MerkleRoot, Commit, CommitSig, SignedHeader, ValidatorSet, Duration, Timestamp, Consensus} from "./TendermintLight.sol";
import "./Encoder.sol";
import "../crypto/MerkleTree.sol";

library TendermintHelper {
    function toSimpleValidator(Validator.Data memory val) internal pure returns (SimpleValidator.Data memory) {
        return SimpleValidator.Data({pub_key: val.pub_key, voting_power: val.voting_power});
    }

    function toCanonicalBlockID(BlockID.Data memory blockID) internal pure returns (CanonicalBlockID.Data memory) {
        return
            CanonicalBlockID.Data({
                hash: blockID.hash,
                part_set_header: CanonicalPartSetHeader.Data({
                    total: blockID.part_set_header.total,
                    hash: blockID.part_set_header.hash
                })
            });
    }

    function toCanonicalVote(Vote.Data memory vote, string memory chainID)
        internal
        pure
        returns (CanonicalVote.Data memory)
    {
        return
            CanonicalVote.Data({
                Type: vote.Type,
                height: vote.height,
                round: int64(vote.round),
                block_id: toCanonicalBlockID(vote.block_id),
                timestamp: vote.timestamp,
                chain_id: chainID
            });
    }

    function toConsensusState(TmHeader.Data memory tmHeader) internal pure returns (ConsensusState.Data memory) {
        return
            ConsensusState.Data({
                timestamp: tmHeader.signed_header.header.time,
                root: MerkleRoot.Data({hash: tmHeader.signed_header.header.app_hash}),
                next_validators_hash: tmHeader.signed_header.header.next_validators_hash
            });
    }

    function toVote(Commit.Data memory commit, uint256 valIdx) internal pure returns (Vote.Data memory) {
        CommitSig.Data memory commitSig = commit.signatures[valIdx];

        return
            Vote.Data({
                Type: TENDERMINTLIGHT_PROTO_GLOBAL_ENUMS.SignedMsgType.SIGNED_MSG_TYPE_PRECOMMIT,
                height: commit.height,
                round: commit.round,
                block_id: commit.block_id,
                timestamp: commitSig.timestamp,
                validator_address: commitSig.validator_address,
                validator_index: SafeCast.toInt32(int256(valIdx)),
                signature: commitSig.signature
            });
    }

    function isEqual(BlockID.Data memory b1, BlockID.Data memory b2) internal pure returns (bool) {
        if (keccak256(abi.encodePacked(b1.hash)) != keccak256(abi.encodePacked(b2.hash))) {
            return false;
        }

        if (b1.part_set_header.total != b2.part_set_header.total) {
            return false;
        }

        if (
            keccak256(abi.encodePacked(b1.part_set_header.hash)) != keccak256(abi.encodePacked(b2.part_set_header.hash))
        ) {
            return false;
        }

        return true;
    }

    function isEqual(ConsensusState.Data memory cs1, ConsensusState.Data memory cs2) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(ConsensusState.encode(cs1))) ==
            keccak256(abi.encodePacked(ConsensusState.encode(cs2)));
    }

    function isExpired(
        SignedHeader.Data memory header,
        Duration.Data memory trustingPeriod,
        Duration.Data memory currentTime
    ) internal pure returns (bool) {
        Timestamp.Data memory expirationTime = Timestamp.Data({
            Seconds: header.header.time.Seconds + int64(trustingPeriod.Seconds),
            nanos: header.header.time.nanos
        });

        return gt(Timestamp.Data({Seconds: int64(currentTime.Seconds), nanos: 0}), expirationTime);
    }

    function gt(Timestamp.Data memory t1, Timestamp.Data memory t2) internal pure returns (bool) {
        if (t1.Seconds > t2.Seconds) {
            return true;
        }

        if (t1.Seconds == t2.Seconds && t1.nanos > t2.nanos) {
            return true;
        }

        return false;
    }

    function hash(SignedHeader.Data memory h) internal pure returns (bytes32) {
        require(h.header.validators_hash.length > 0, "Tendermint: hash can't be empty");

        bytes memory hbz = Consensus.encode(h.header.version);
        bytes memory pbt = Timestamp.encode(h.header.time);
        bytes memory bzbi = BlockID.encode(h.header.last_block_id);

        bytes[14] memory all = [
            hbz,
            Encoder.cdcEncode(h.header.chain_id),
            Encoder.cdcEncode(h.header.height),
            pbt,
            bzbi,
            Encoder.cdcEncode(h.header.last_commit_hash),
            Encoder.cdcEncode(h.header.data_hash),
            Encoder.cdcEncode(h.header.validators_hash),
            Encoder.cdcEncode(h.header.next_validators_hash),
            Encoder.cdcEncode(h.header.consensus_hash),
            Encoder.cdcEncode(h.header.app_hash),
            Encoder.cdcEncode(h.header.last_results_hash),
            Encoder.cdcEncode(h.header.evidence_hash),
            Encoder.cdcEncode(h.header.proposer_address)
        ];

        return MerkleTree.merkleRootHash(all, 0, all.length);
    }

    function hash(ValidatorSet.Data memory vs) internal pure returns (bytes32) {
        return MerkleTree.merkleRootHash(vs.validators, 0, vs.validators.length);
    }

    function getByAddress(ValidatorSet.Data memory vals, bytes memory addr)
        internal
        pure
        returns (uint256 index, bool found)
    {
        bytes32 addrHash = keccak256(abi.encodePacked(addr));
        for (uint256 idx; idx < vals.validators.length; idx++) {
            if (keccak256(abi.encodePacked(vals.validators[idx].Address)) == addrHash) {
                return (idx, true);
            }
        }

        return (0, false);
    }

    function getTotalVotingPower(ValidatorSet.Data memory vals) internal pure returns (int64) {
        if (vals.total_voting_power == 0) {
            uint256 sum = 0;
            uint256 maxInt64 = 1 << (63 - 1);
            uint256 maxTotalVotingPower = maxInt64 / 8;

            for (uint256 i = 0; i < vals.validators.length; i++) {
                sum += (SafeCast.toUint256(int256(vals.validators[i].voting_power)));
                require(sum <= maxTotalVotingPower, "total voting power should be guarded to not exceed");
            }

            vals.total_voting_power = SafeCast.toInt64(int256(sum));
        }

        return vals.total_voting_power;
    }
}

// SPDX-License-Identifier: TBD
pragma solidity ^0.8.2;

import "./ProtoBufRuntime.sol";

library Encoder {
    uint64 private constant _MAX_UINT64 = 0xFFFFFFFFFFFFFFFF;

    function cdcEncode(string memory item) internal pure returns (bytes memory) {
        uint256 estimatedSize = 1 + ProtoBufRuntime._sz_lendelim(bytes(item).length);
        bytes memory bs = new bytes(estimatedSize);

        uint256 offset = 32;
        uint256 pointer = 32;

        if (bytes(item).length > 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_string(item, pointer, bs);
        }

        uint256 sz = pointer - offset;
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    function cdcEncode(bytes memory item) internal pure returns (bytes memory) {
        uint256 estimatedSize = 1 + ProtoBufRuntime._sz_lendelim(item.length);
        bytes memory bs = new bytes(estimatedSize);

        uint256 offset = 32;
        uint256 pointer = 32;

        if (item.length > 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.LengthDelim, pointer, bs);
            pointer += ProtoBufRuntime._encode_bytes(item, pointer, bs);
        }

        uint256 sz = pointer - offset;
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    function cdcEncode(int64 item) internal pure returns (bytes memory) {
        uint256 estimatedSize = 1 + ProtoBufRuntime._sz_int64(item);
        bytes memory bs = new bytes(estimatedSize);

        uint256 offset = 32;
        uint256 pointer = 32;

        if (item != 0) {
            pointer += ProtoBufRuntime._encode_key(1, ProtoBufRuntime.WireType.Varint, pointer, bs);
            pointer += ProtoBufRuntime._encode_int64(item, pointer, bs);
        }

        uint256 sz = pointer - offset;
        assembly {
            mstore(bs, sz)
        }
        return bs;
    }

    // TODO: Can we make this cheaper?
    // https://docs.soliditylang.org/en/v0.6.5/types.html#allocating-memory-arrays
    function encodeDelim(bytes memory input) internal pure returns (bytes memory) {
        require(input.length < _MAX_UINT64, "Encoder: out of bounds (uint64)");

        uint64 length = uint64(input.length);
        uint256 additionalEstimated = ProtoBufRuntime._sz_uint64(length);

        bytes memory delimitedPrefix = new bytes(additionalEstimated);
        uint256 delimitedPrefixLen = ProtoBufRuntime._encode_uint64(length, 32, delimitedPrefix);

        assembly {
            mstore(delimitedPrefix, delimitedPrefixLen)
        }

        // concatenate buffers
        return abi.encodePacked(delimitedPrefix, input);
    }
}

// SPDX-License-Identifier: TBD
pragma solidity ^0.8.2;

import "../proto/TendermintHelper.sol";
import {SimpleValidator, Validator} from "../proto/TendermintLight.sol";

library MerkleTree {
    /**
     * @dev returns empty hash
     */
    function emptyHash() internal pure returns (bytes32) {
        return sha256(abi.encode());
    }

    /**
     * @dev returns tmhash(0x00 || leaf)
     *
     */
    function leafHash(bytes memory leaf) internal pure returns (bytes32) {
        uint8 leafPrefix = 0x00;
        return sha256(abi.encodePacked(leafPrefix, leaf));
    }

    /**
     * @dev returns tmhash(0x01 || left || right)
     */
    function innerHash(bytes32 leaf, bytes32 right) internal pure returns (bytes32) {
        uint8 innerPrefix = 0x01;
        return sha256(abi.encodePacked(innerPrefix, leaf, right));
    }

    /**
     * @dev returns the largest power of 2 less than length
     *
     * TODO: This function can be optimized with bit shifting approach:
     * https://www.baeldung.com/java-largest-power-of-2-less-than-number
     */
    function getSplitPoint(uint256 input) internal pure returns (uint256) {
        require(input > 1, "MerkleTree: invalid input");

        uint256 result = 1;
        for (uint256 i = input - 1; i > 1; i--) {
            if ((i & (i - 1)) == 0) {
                result = i;
                break;
            }
        }
        return result;
    }

    /**
     * @dev computes a Merkle tree where the leaves are validators, in the provided order
     * Follows RFC-6962
     */
    function merkleRootHash(
        Validator.Data[] memory validators,
        uint256 start,
        uint256 total
    ) internal pure returns (bytes32) {
        if (total == 0) {
            return emptyHash();
        } else if (total == 1) {
            bytes memory encodedValidator = SimpleValidator.encode(
                TendermintHelper.toSimpleValidator(validators[start])
            );
            return leafHash(encodedValidator);
        } else {
            uint256 k = getSplitPoint(total);
            bytes32 left = merkleRootHash(validators, start, k); // validators[:k]
            bytes32 right = merkleRootHash(validators, start + k, total - k); // validators[k:]
            return innerHash(left, right);
        }
    }

    /**
     * @dev computes a Merkle tree where the leaves are the byte slice in the provided order
     * Follows RFC-6962
     */
    function merkleRootHash(
        bytes[14] memory validators,
        uint256 start,
        uint256 total
    ) internal pure returns (bytes32) {
        if (total == 0) {
            return emptyHash();
        } else if (total == 1) {
            return leafHash(validators[start]);
        } else {
            uint256 k = getSplitPoint(total);
            bytes32 left = merkleRootHash(validators, start, k); // validators[:k]
            bytes32 right = merkleRootHash(validators, start + k, total - k); // validators[k:]
            return innerHash(left, right);
        }
    }
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library Pairing {
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {
        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * Same as plus but accepts raw input instead of struct
     * @return The sum of two points of G1, one is represented as array
     */
    function plus_raw(uint256[4] memory input, G1Point memory r) internal view {
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {
        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-mul-failed");
    }

    /*
     * Same as scalar_mul but accepts raw input instead of struct,
     * Which avoid extra allocation. provided input can be allocated outside and re-used multiple times
     */
    function scalar_mul_raw(uint256[3] memory input, G1Point memory r) internal view {
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, "pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {
        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }

        require(success, "pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract Ed25519Verifier {
    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        // []G1Point IC (K in gnark) appears directly in verifyProof
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
        Pairing.G1Point Commit;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(
            uint256(16537564926561257518103578528440315215453761258292367362288728531966371995874),
            uint256(17745573146004211534248579212526935789334969204993357645263388924661264974187)
        );
        vk.beta2 = Pairing.G2Point(
            [
                uint256(18681724724964420256656295617462445194520232343683657023020438565197998259673),
                uint256(12193837689525487485139416036830252517228166559922434453026243184766751424223)
            ],
            [
                uint256(1142689458690077585879713419885020952718961581248594394197708921155425831615),
                uint256(21176592749741182389767016778519001156128344286592614375719960199144776585881)
            ]
        );
        vk.gamma2 = Pairing.G2Point(
            [
                uint256(19799290104465580933750348548810731188007606239377683243716104715153013203241),
                uint256(11029356377690007782073139603897274721732913650225177555357052135977173817932)
            ],
            [
                uint256(14853413044533073822755393458984382667328640010571213879456567827440818416559),
                uint256(1410171095280489347779850966561512432991607061868962673896369110725284404185)
            ]
        );
        vk.delta2 = Pairing.G2Point(
            [
                uint256(14033331354156232558698818931400566889727401262494703861181881854810319611656),
                uint256(1803778019251118312050232705802652879152144501576771122000761003085527364548)
            ],
            [
                uint256(19177018991900245360077248204991378509575348272931358571227777389261756980021),
                uint256(13491338816347045964487197971132020169975241104757177444019867803073686189354)
            ]
        );
    }

    // accumulate scalarMul(mul_input) into q
    // that is computes sets q = (mul_input[0:2] * mul_input[3]) + q
    function accumulate(
        uint256[3] memory mul_input,
        Pairing.G1Point memory p,
        uint256[4] memory buffer,
        Pairing.G1Point memory q
    ) internal view {
        // computes p = mul_input[0:2] * mul_input[3]
        Pairing.scalar_mul_raw(mul_input, p);

        // point addition inputs
        buffer[0] = q.X;
        buffer[1] = q.Y;
        buffer[2] = p.X;
        buffer[3] = p.Y;

        // q = p + q
        Pairing.plus_raw(buffer, q);
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[2] memory commit,
        uint256[57] calldata input
    ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.Commit = Pairing.G1Point(commit[0], commit[1]);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD, "verifier-gte-snark-scalar-field");
        }

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Buffer reused for addition p1 + p2 to avoid memory allocations
        // [0:2] -> p1.X, p1.Y ; [2:4] -> p2.X, p2.Y
        uint256[4] memory add_input;

        // Buffer reused for multiplication p1 * s
        // [0:2] -> p1.X, p1.Y ; [3] -> s
        uint256[3] memory mul_input;

        // temporary point to avoid extra allocations in accumulate
        Pairing.G1Point memory q = Pairing.G1Point(0, 0);

        vk_x.X = uint256(9462447710939432742848424196697728822687813011479891122131648160830275921458); // vk.K[0].X
        vk_x.Y = uint256(11473376488241810165831757536366836850027784981839089792021378256861687455964); // vk.K[0].Y
        mul_input[0] = uint256(2648510173551830043068139172354933052408112984889271406750039349551232576549); // vk.K[1].X
        mul_input[1] = uint256(12122054635554892818275346487442913112730051679642997892313491753063522521582); // vk.K[1].Y
        mul_input[2] = input[0];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[1] * input[0]
        mul_input[0] = uint256(7061394255936047678059253317568688117856036320639226956214975754160049295333); // vk.K[2].X
        mul_input[1] = uint256(14145671141784595839380141874940651481054054987062620771942604522524338984737); // vk.K[2].Y
        mul_input[2] = input[1];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[2] * input[1]
        mul_input[0] = uint256(8218011998118573873686464766508340825013181970169509029207170044008261486193); // vk.K[3].X
        mul_input[1] = uint256(4808589679893008233603109916014512606401750471929338771914335778004460444360); // vk.K[3].Y
        mul_input[2] = input[2];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[3] * input[2]
        mul_input[0] = uint256(6078662146959222742143128212552101384988335461422265821062667538426926541518); // vk.K[4].X
        mul_input[1] = uint256(14225787497847862685225784260006515346740700745306082959617044081310626314439); // vk.K[4].Y
        mul_input[2] = input[3];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[4] * input[3]
        mul_input[0] = uint256(15225699490833575811570520695447458343846017972639836494871931441485526096787); // vk.K[5].X
        mul_input[1] = uint256(15569415315038112005525705058718435821481109166559557245122292405605719408925); // vk.K[5].Y
        mul_input[2] = input[4];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[5] * input[4]
        mul_input[0] = uint256(3942281303299556918937442887343925623486733341136969568571582227745440173807); // vk.K[6].X
        mul_input[1] = uint256(4138173571813503741513576149284418571266189111210058243046675207337729400955); // vk.K[6].Y
        mul_input[2] = input[5];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[6] * input[5]
        mul_input[0] = uint256(723953850260184913681651686455204823265776604606646409438367197633827064461); // vk.K[7].X
        mul_input[1] = uint256(20977669267739599281940138230527850695064911563027213490970977450491160080036); // vk.K[7].Y
        mul_input[2] = input[6];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[7] * input[6]
        mul_input[0] = uint256(15017582390282569744856651205092622236708068694757044392807758501545223739943); // vk.K[8].X
        mul_input[1] = uint256(1265991120483539619897036121722423769988535691692111441020055552301420911354); // vk.K[8].Y
        mul_input[2] = input[7];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[8] * input[7]
        mul_input[0] = uint256(5221873433181937410686676698706306071488292331003715940336123836669316677478); // vk.K[9].X
        mul_input[1] = uint256(14426879645470087966651542997861483039122804778202333350123336907198495445103); // vk.K[9].Y
        mul_input[2] = input[8];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[9] * input[8]
        mul_input[0] = uint256(20573069687094669083259174171204052569713827743866845162450148699057547764918); // vk.K[10].X
        mul_input[1] = uint256(19125182916367006002072229187347273947735042422948150051314675975432464674658); // vk.K[10].Y
        mul_input[2] = input[9];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[10] * input[9]
        mul_input[0] = uint256(653108268157101410313141643706313813985558592438699399282213422712029889715); // vk.K[11].X
        mul_input[1] = uint256(920655015136053252820652067829010626746362759835559920517492343709532195466); // vk.K[11].Y
        mul_input[2] = input[10];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[11] * input[10]
        mul_input[0] = uint256(20917639943585713768528304284726936606521085966431546157561891168025022757887); // vk.K[12].X
        mul_input[1] = uint256(8262496391990750367129442871845474963121866167295779784485121209123609128682); // vk.K[12].Y
        mul_input[2] = input[11];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[12] * input[11]
        mul_input[0] = uint256(21382382741426387778276445265980446660720522906365157168723787305555966928178); // vk.K[13].X
        mul_input[1] = uint256(20304725605418784279352839016897739647529600560330484467516988594075783844854); // vk.K[13].Y
        mul_input[2] = input[12];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[13] * input[12]
        mul_input[0] = uint256(6205744815043738292440949022257329596826099473730575848275490097888497842377); // vk.K[14].X
        mul_input[1] = uint256(14621389881302722659870997782918885566955239423536368018214245647671237084390); // vk.K[14].Y
        mul_input[2] = input[13];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[14] * input[13]
        mul_input[0] = uint256(15814307705747507442630842462045602926477319899462506430805053181751486077929); // vk.K[15].X
        mul_input[1] = uint256(20719845899119367288065102841494811826814842176184748936398855427173476589603); // vk.K[15].Y
        mul_input[2] = input[14];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[15] * input[14]
        mul_input[0] = uint256(13115514590566800662313134167308526149064497604562804026503299495382170121521); // vk.K[16].X
        mul_input[1] = uint256(1332307969280655731716061244811863427539380178344062557717239827752566800649); // vk.K[16].Y
        mul_input[2] = input[15];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[16] * input[15]
        mul_input[0] = uint256(21831548148156992003553031892913267462010789037401082515443630438407722663969); // vk.K[17].X
        mul_input[1] = uint256(6734282036223126997206695046254381537591284089119495472525380311105692037149); // vk.K[17].Y
        mul_input[2] = input[16];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[17] * input[16]
        mul_input[0] = uint256(19824054054568150451544715245329533752342566872920996747743887644800176138756); // vk.K[18].X
        mul_input[1] = uint256(17444883232483823314330637172782524563336237772974332017836978912923943288044); // vk.K[18].Y
        mul_input[2] = input[17];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[18] * input[17]
        mul_input[0] = uint256(11203846533369587519929291820435945242235455090413432458828659220572895771832); // vk.K[19].X
        mul_input[1] = uint256(16148158018136729384412794294904585957329060422316919194693060478106477584261); // vk.K[19].Y
        mul_input[2] = input[18];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[19] * input[18]
        mul_input[0] = uint256(21371926577928441304164289543024513366951022486217703908520862772671592138220); // vk.K[20].X
        mul_input[1] = uint256(18107932227339892218168366645185506844179114579625951614458742714985063933868); // vk.K[20].Y
        mul_input[2] = input[19];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[20] * input[19]
        mul_input[0] = uint256(2078836125811363606455079208654269542518183191401138318514557936552194691549); // vk.K[21].X
        mul_input[1] = uint256(20289036517453961776720656852506924474500493189617637737320825721964408623696); // vk.K[21].Y
        mul_input[2] = input[20];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[21] * input[20]
        mul_input[0] = uint256(20684528615338806451021356191176017140605638913507543305045224022571493583399); // vk.K[22].X
        mul_input[1] = uint256(3903056905414345066553250327072636225389082733080503032794283501727725353966); // vk.K[22].Y
        mul_input[2] = input[21];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[22] * input[21]
        mul_input[0] = uint256(13854622650680331791998959936965711435732154320243563610773598319176375507733); // vk.K[23].X
        mul_input[1] = uint256(1293023507593941743631670346894908106668220179131184101706263206018361614455); // vk.K[23].Y
        mul_input[2] = input[22];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[23] * input[22]
        mul_input[0] = uint256(3806178131996244443364939020206141693542459073159601454749540496458558677609); // vk.K[24].X
        mul_input[1] = uint256(11373982291360652938998008416691951950539326147900435417838815437650728107752); // vk.K[24].Y
        mul_input[2] = input[23];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[24] * input[23]
        mul_input[0] = uint256(2956423360991834768742742798077214208812640276852161493833529280831095074781); // vk.K[25].X
        mul_input[1] = uint256(1036790067266635965218530400023441211296511606457139237137911024262932772523); // vk.K[25].Y
        mul_input[2] = input[24];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[25] * input[24]
        mul_input[0] = uint256(3522982602799278288450494299627381578769489328186449628808472144237402446412); // vk.K[26].X
        mul_input[1] = uint256(13124545182856888320922946645561369145471456600466254299605996043152521299609); // vk.K[26].Y
        mul_input[2] = input[25];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[26] * input[25]
        mul_input[0] = uint256(10203021712642579290406260398074627148768959317126130666994877932179153487975); // vk.K[27].X
        mul_input[1] = uint256(19220206362979524452868254497284191194377622625329987254755474419246348464504); // vk.K[27].Y
        mul_input[2] = input[26];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[27] * input[26]
        mul_input[0] = uint256(13656479319858575241396965583832757201969209361023293619085267873236508281324); // vk.K[28].X
        mul_input[1] = uint256(18653894887361004227161091206020531090371042692329436200109497793456818170297); // vk.K[28].Y
        mul_input[2] = input[27];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[28] * input[27]
        mul_input[0] = uint256(20667457304256598973369559213600706490691854322307004623522066355950536986052); // vk.K[29].X
        mul_input[1] = uint256(10166524048179842305027932295420555626140631584017768928975471213820747864954); // vk.K[29].Y
        mul_input[2] = input[28];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[29] * input[28]
        mul_input[0] = uint256(14451586832169158165406346103518705733160542436336769287947890488919305713536); // vk.K[30].X
        mul_input[1] = uint256(15677358351240766490224933957331428778606486522363230169083418720895728674937); // vk.K[30].Y
        mul_input[2] = input[29];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[30] * input[29]
        mul_input[0] = uint256(8815343788891391302884218656640023092689342750375488785771313089418754129780); // vk.K[31].X
        mul_input[1] = uint256(13009618795398702701706372843804296988960880281370027843016246576371783417574); // vk.K[31].Y
        mul_input[2] = input[30];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[31] * input[30]
        mul_input[0] = uint256(7794542304670317906972413815443657110555785749184277557959662453473304832135); // vk.K[32].X
        mul_input[1] = uint256(13613183423982157012686848485088999158423912294590394357601874166998596036708); // vk.K[32].Y
        mul_input[2] = input[31];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[32] * input[31]
        mul_input[0] = uint256(13829063270265614122932776384418402417255253559219713892264763147960420595663); // vk.K[33].X
        mul_input[1] = uint256(1394492787369205690940389079323334412434996525623614329408676573910762151803); // vk.K[33].Y
        mul_input[2] = input[32];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[33] * input[32]
        mul_input[0] = uint256(13250480124160751683662026425319692126614649754704623898304284468074453566914); // vk.K[34].X
        mul_input[1] = uint256(5842667319974085537473375237026886465714130878203887186671280383692949371367); // vk.K[34].Y
        mul_input[2] = input[33];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[34] * input[33]
        mul_input[0] = uint256(4244396663084445939427850030230353204559612848770696182862006916130063961075); // vk.K[35].X
        mul_input[1] = uint256(5567117583761251190183987315357290694204768312790348596534705058755423324166); // vk.K[35].Y
        mul_input[2] = input[34];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[35] * input[34]
        mul_input[0] = uint256(16468214890309010196842237213567005731971554524310253342503592222181911831216); // vk.K[36].X
        mul_input[1] = uint256(13015440355627709680447076370593216495840212097545614001751347318260304962870); // vk.K[36].Y
        mul_input[2] = input[35];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[36] * input[35]
        mul_input[0] = uint256(1710502514829787762068790998518593585732164832507101474241328558660469459552); // vk.K[37].X
        mul_input[1] = uint256(6641523787174944064207070430739280224248149581740606756642107112326594132092); // vk.K[37].Y
        mul_input[2] = input[36];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[37] * input[36]
        mul_input[0] = uint256(13873688322349022545411654259743538242310790895509577137595893668751435535182); // vk.K[38].X
        mul_input[1] = uint256(2743144454147776739466147084712345009024223781055121185226575029717710864182); // vk.K[38].Y
        mul_input[2] = input[37];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[38] * input[37]
        mul_input[0] = uint256(5515207890157998771775835819329897799964342326708529575708915192914192717763); // vk.K[39].X
        mul_input[1] = uint256(6830846512538057603246995968366818367160206190590285682644456335384380744224); // vk.K[39].Y
        mul_input[2] = input[38];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[39] * input[38]
        mul_input[0] = uint256(12084319035206948715397631350220429569745624512314143843439943565130003131475); // vk.K[40].X
        mul_input[1] = uint256(19823940921149166526761280180611360195654754479337467436765527950957403100421); // vk.K[40].Y
        mul_input[2] = input[39];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[40] * input[39]
        mul_input[0] = uint256(1707966742483292923663665240004271093118893352464133867701833789750341568293); // vk.K[41].X
        mul_input[1] = uint256(2059830066597637963266616577934465643861703524384620495213365657208172372127); // vk.K[41].Y
        mul_input[2] = input[40];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[41] * input[40]
        mul_input[0] = uint256(4335683960535202743801100378397366667909285456099227829020337934512681970900); // vk.K[42].X
        mul_input[1] = uint256(7163760264613823569250071408872840488100394969233714572137432343600611323243); // vk.K[42].Y
        mul_input[2] = input[41];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[42] * input[41]
        mul_input[0] = uint256(18579130060975771189412379077269037710625635418528267671299513425013575199707); // vk.K[43].X
        mul_input[1] = uint256(7413439674648248746853580336851465886481116161464911636828558414649648473619); // vk.K[43].Y
        mul_input[2] = input[42];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[43] * input[42]
        mul_input[0] = uint256(16042514199832592968247672418295024202640592240955629633937928114942675433499); // vk.K[44].X
        mul_input[1] = uint256(9176210646934564968216912647498279795139899070579664859952976743279140133749); // vk.K[44].Y
        mul_input[2] = input[43];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[44] * input[43]
        mul_input[0] = uint256(4605826036674863045915848920224687279865356012358913781882485214370608375866); // vk.K[45].X
        mul_input[1] = uint256(16433469797022838005221089589473953566885756258639853768294415623922164207114); // vk.K[45].Y
        mul_input[2] = input[44];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[45] * input[44]
        mul_input[0] = uint256(21291606718216838223612806394353023159167853021188903625675694115824239986243); // vk.K[46].X
        mul_input[1] = uint256(13861976516244796326502185111204736567218465632382198677006716558365310272234); // vk.K[46].Y
        mul_input[2] = input[45];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[46] * input[45]
        mul_input[0] = uint256(13608539239013691835986711410119733227388008030702193689279242935664405256689); // vk.K[47].X
        mul_input[1] = uint256(21464993448394658273854216484684266808321160947909209851055873325887050492293); // vk.K[47].Y
        mul_input[2] = input[46];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[47] * input[46]
        mul_input[0] = uint256(14508762627123999549076601587501227009682636970076636367483491513461822793735); // vk.K[48].X
        mul_input[1] = uint256(13086806823222303647760776079580932758835172518633536905189386855031527005867); // vk.K[48].Y
        mul_input[2] = input[47];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[48] * input[47]
        mul_input[0] = uint256(19620443629871450449905318328661357670363144885276650727854684127004979439411); // vk.K[49].X
        mul_input[1] = uint256(13512145302109135260648622069026293634594965443783681487284540332451024150941); // vk.K[49].Y
        mul_input[2] = input[48];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[49] * input[48]
        mul_input[0] = uint256(20059550415468532205827328714175420183638104824341229821332085226225097782116); // vk.K[50].X
        mul_input[1] = uint256(12050042602361465175864197068892829808531398334073641526653775817012796904920); // vk.K[50].Y
        mul_input[2] = input[49];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[50] * input[49]
        mul_input[0] = uint256(13306511629433317473594641621219799176423215443967411203563081150777664297203); // vk.K[51].X
        mul_input[1] = uint256(675454852156663320769111000409074913392067853038809175892444203322319080285); // vk.K[51].Y
        mul_input[2] = input[50];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[51] * input[50]
        mul_input[0] = uint256(12076096047127155639652324319628370078197547570757038002713853288385847397853); // vk.K[52].X
        mul_input[1] = uint256(20063073818109035475283913336465472637670645911136973171672153316960017020047); // vk.K[52].Y
        mul_input[2] = input[51];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[52] * input[51]
        mul_input[0] = uint256(7070926176971266168429945375853092488155813841418560246899144119253540102350); // vk.K[53].X
        mul_input[1] = uint256(18608632252819735218114751983460803259577541150988320712643403458973379890618); // vk.K[53].Y
        mul_input[2] = input[52];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[53] * input[52]
        mul_input[0] = uint256(8787738969091605771927429510050738225462363969120867850034866515919420616153); // vk.K[54].X
        mul_input[1] = uint256(280860041417881042842953968111093793049575926737744905886029164850711931023); // vk.K[54].Y
        mul_input[2] = input[53];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[54] * input[53]
        mul_input[0] = uint256(17470729458746471811553625923859580633403777304482076029136929287269138561286); // vk.K[55].X
        mul_input[1] = uint256(11077695780520668039728878524992441159739768910332004302025495828550310823044); // vk.K[55].Y
        mul_input[2] = input[54];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[55] * input[54]
        mul_input[0] = uint256(18820732662126470829529155830450341599504017356119489964316929892787212659148); // vk.K[56].X
        mul_input[1] = uint256(18398462213470099652091858533789910876899706114418611429055433371437676169588); // vk.K[56].Y
        mul_input[2] = input[55];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[56] * input[55]
        mul_input[0] = uint256(10979958723839781582509983389549268556375745246890018812028152329350660809099); // vk.K[57].X
        mul_input[1] = uint256(8614377901484706884530978841565040782347190141813157341928120361805065861265); // vk.K[57].Y
        mul_input[2] = input[56];
        accumulate(mul_input, q, add_input, vk_x); // vk_x += vk.K[57] * input[56]
        if (commit[0] != 0 || commit[1] != 0) {
            vk_x = Pairing.plus(vk_x, proof.Commit);
        }

        return
            Pairing.pairing(Pairing.negate(proof.A), proof.B, vk.alfa1, vk.beta2, vk_x, vk.gamma2, proof.C, vk.delta2);
    }
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
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

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}