/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

pragma solidity ^0.8.17;

// Adopted from https://github.com/lazyledger/protobuf3-solidity-lib/blob/master/contracts/ProtobufLib.sol
library ProtobufLib {
    /// @notice Protobuf wire types.
    enum WireType {
        Varint,
        Bits64,
        LengthDelimited,
        StartGroup,
        EndGroup,
        Bits32,
        WIRE_TYPE_MAX
    }

    /// @dev Maximum number of bytes for a varint.
    /// @dev 64 bits, in groups of base-128 (7 bits).
    uint64 internal constant MAX_VARINT_BYTES = 10;

    ////////////////////////////////////
    // Decoding
    ////////////////////////////////////

    /// @notice Decode key.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#structure
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Field number
    /// @return Wire type
    function decode_key(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64,
            WireType
        )
    {
        // The key is a varint with encoding
        // (field_number << 3) | wire_type
        (bool success, uint64 pos, uint64 key) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }

        uint64 field_number = key >> 3;
        uint64 wire_type_val = key & 0x07;
        // Check that wire type is bounded
        if (wire_type_val >= uint64(WireType.WIRE_TYPE_MAX)) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }
        WireType wire_type = WireType(wire_type_val);

        // Start and end group types are deprecated, so forbid them
        if (
            wire_type == WireType.StartGroup || wire_type == WireType.EndGroup
        ) {
            return (false, pos, 0, WireType.WIRE_TYPE_MAX);
        }

        return (true, pos, field_number, wire_type);
    }

    /// @notice Decode varint.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#varints
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_varint(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        uint64 val;
        uint64 i;

        for (i = 0; i < MAX_VARINT_BYTES; i++) {
            // Check that index is within bounds
            if (i + p >= buf.length) {
                return (false, p, 0);
            }

            // Get byte at offset
            uint8 b = uint8(buf[p + i]);

            // Highest bit is used to indicate if there are more bytes to come
            // Mask to get 7-bit value: 0111 1111
            uint8 v = b & 0x7F;

            // Groups of 7 bits are ordered least significant first
            val |= uint64(v) << uint64(i * 7);

            // Mask to get keep going bit: 1000 0000
            if (b & 0x80 == 0) {
                // [STRICT]
                // Check for trailing zeroes if more than one byte is used
                // (the value 0 still uses one byte)
                if (i > 0 && v == 0) {
                    return (false, p, 0);
                }

                break;
            }
        }

        // Check that at most MAX_VARINT_BYTES are used
        if (i >= MAX_VARINT_BYTES) {
            return (false, p, 0);
        }

        // [STRICT]
        // If all 10 bytes are used, the last byte (most significant 7 bits)
        // must be at most 0000 0001, since 7*9 = 63
        if (i == MAX_VARINT_BYTES - 1) {
            if (uint8(buf[p + i]) > 1) {
                return (false, p, 0);
            }
        }

        return (true, p + i + 1, val);
    }

    /// @notice Decode varint int32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_int32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // [STRICT]
        // Highest 4 bytes must be 0 if positive
        if (val >> 63 == 0) {
            if (val & 0xFFFFFFFF00000000 != 0) {
                return (false, pos, 0);
            }
        }

        return (true, pos, int32(uint32(val)));
    }

    /// @notice Decode varint int64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_int64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int64(val));
    }

    /// @notice Decode varint uint32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_uint32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // [STRICT]
        // Highest 4 bytes must be 0
        if (val & 0xFFFFFFFF00000000 != 0) {
            return (false, pos, 0);
        }

        return (true, pos, uint32(val));
    }

    /// @notice Decode varint uint64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_uint64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    // /// @notice Decode varint sint32.
    // /// @param p Position
    // /// @param buf Buffer
    // /// @return Success
    // /// @return New position
    // /// @return Decoded int
    // function decode_sint32(uint64 p, bytes memory buf)
    //     internal
    //     pure
    //     returns (
    //         bool,
    //         uint64,
    //         int32
    //     )
    // {
    //     (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
    //     if (!success) {
    //         return (false, pos, 0);
    //     }

    //     // [STRICT]
    //     // Highest 4 bytes must be 0
    //     if (val & 0xFFFFFFFF00000000 != 0) {
    //         return (false, pos, 0);
    //     }

    //     // https://stackoverflow.com/questions/2210923/zig-zag-decoding/2211086#2211086
    //     uint64 zigzag_val = (val >> 1) ^ (-(val & 1));

    //     return (true, pos, int32(uint32(zigzag_val)));
    // }

    // /// @notice Decode varint sint64.
    // /// @param p Position
    // /// @param buf Buffer
    // /// @return Success
    // /// @return New position
    // /// @return Decoded int
    // function decode_sint64(uint64 p, bytes memory buf)
    //     internal
    //     pure
    //     returns (
    //         bool,
    //         uint64,
    //         int64
    //     )
    // {
    //     (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
    //     if (!success) {
    //         return (false, pos, 0);
    //     }

    //     // https://stackoverflow.com/questions/2210923/zig-zag-decoding/2211086#2211086
    //     uint64 zigzag_val = (val >> 1) ^ (-(val & 1));

    //     return (true, pos, int64(zigzag_val));
    // }

    /// @notice Decode Boolean.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded bool
    function decode_bool(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            bool
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, false);
        }

        // [STRICT]
        // Value must be 0 or 1
        if (val > 1) {
            return (false, pos, false);
        }

        if (val == 0) {
            return (true, pos, false);
        }

        return (true, pos, true);
    }

    /// @notice Decode enumeration.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded enum as raw int
    function decode_enum(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        return decode_int32(p, buf);
    }

    /// @notice Decode fixed 64-bit int.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_bits64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        uint64 val;

        // Check that index is within bounds
        if (8 + p > buf.length) {
            return (false, p, 0);
        }

        for (uint64 i = 0; i < 8; i++) {
            uint8 b = uint8(buf[p + i]);

            // Little endian
            val |= uint64(b) << uint64(i * 8);
        }

        return (true, p + 8, val);
    }

    /// @notice Decode fixed uint64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_fixed64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_bits64(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    /// @notice Decode fixed int64.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_sfixed64(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int64
        )
    {
        (bool success, uint64 pos, uint64 val) = decode_bits64(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int64(val));
    }

    /// @notice Decode fixed 32-bit int.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_bits32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        uint32 val;

        // Check that index is within bounds
        if (4 + p > buf.length) {
            return (false, p, 0);
        }

        for (uint64 i = 0; i < 4; i++) {
            uint8 b = uint8(buf[p + i]);

            // Little endian
            val |= uint32(b) << uint32(i * 8);
        }

        return (true, p + 4, val);
    }

    /// @notice Decode fixed uint32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_fixed32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint32
        )
    {
        (bool success, uint64 pos, uint32 val) = decode_bits32(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, val);
    }

    /// @notice Decode fixed int32.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Decoded int
    function decode_sfixed32(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            int32
        )
    {
        (bool success, uint64 pos, uint32 val) = decode_bits32(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        return (true, pos, int32(val));
    }

    /// @notice Decode length-delimited field.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_length_delimited(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        // Length-delimited fields begin with a varint of the number of bytes that follow
        (bool success, uint64 pos, uint64 size) = decode_varint(p, buf);
        if (!success) {
            return (false, pos, 0);
        }

        // Check for overflow
        if (pos + size < pos) {
            return (false, pos, 0);
        }

        // Check that index is within bounds
        if (size + pos > buf.length) {
            return (false, pos, 0);
        }

        return (true, pos, size);
    }

    /// @notice Decode string.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position
    /// @return Size in bytes
    function decode_string(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            string memory
        )
    {
        (bool success, uint64 pos, uint64 size) =
            decode_length_delimited(p, buf);
        if (!success) {
            return (false, pos, "");
        }

        bytes memory field = new bytes(size);
        for (uint64 i = 0; i < size; i++) {
            field[i] = buf[pos + i];
        }

        return (true, pos + size, string(field));
    }

    /// @notice Decode bytes array.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_bytes(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    /// @notice Decode embedded message.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_embedded_message(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    /// @notice Decode packed repeated field.
    /// @param p Position
    /// @param buf Buffer
    /// @return Success
    /// @return New position (after size)
    /// @return Size in bytes
    function decode_packed_repeated(uint64 p, bytes memory buf)
        internal
        pure
        returns (
            bool,
            uint64,
            uint64
        )
    {
        return decode_length_delimited(p, buf);
    }

    ////////////////////////////////////
    // Encoding
    ////////////////////////////////////

    /// @notice Encode key.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#structure
    /// @param field_number Field number
    /// @param wire_type Wire type
    /// @return Marshaled bytes
    function encode_key(uint64 field_number, uint64 wire_type)
        internal
        pure
        returns (bytes memory)
    {
        uint64 key = (field_number << 3) | wire_type;

        bytes memory buf = encode_varint(key);

        return buf;
    }

    /// @notice Encode varint.
    /// @dev https://developers.google.com/protocol-buffers/docs/encoding#varints
    /// @param n Number
    /// @return Marshaled bytes
    function encode_varint(uint64 n) internal pure returns (bytes memory) {
        // Count the number of groups of 7 bits
        // We need this pre-processing step since Solidity doesn't allow dynamic memory resizing
        uint64 tmp = n;
        uint64 num_bytes = 1;
        while (tmp > 0x7F) {
            tmp = tmp >> 7;
            num_bytes += 1;
        }

        bytes memory buf = new bytes(num_bytes);

        tmp = n;
        for (uint64 i = 0; i < num_bytes; i++) {
            // Set the first bit in the byte for each group of 7 bits
            buf[i] = bytes1(0x80 | uint8(tmp & 0x7F));
            tmp = tmp >> 7;
        }
        // Unset the first bit of the last byte
        buf[num_bytes - 1] &= 0x7F;

        return buf;
    }

    /// @notice Encode varint int32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_int32(int32 n) internal pure returns (bytes memory) {
        return encode_varint(uint64(uint32(n)));
    }

    /// @notice Decode varint int64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_int64(int64 n) internal pure returns (bytes memory) {
        return encode_varint(uint64(n));
    }

    /// @notice Encode varint uint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_uint32(uint32 n) internal pure returns (bytes memory) {
        return encode_varint(n);
    }

    /// @notice Encode varint uint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_uint64(uint64 n) internal pure returns (bytes memory) {
        return encode_varint(n);
    }

    /// @notice Encode varint sint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sint32(int32 n) internal pure returns (bytes memory) {
        // https://developers.google.com/protocol-buffers/docs/encoding#signed_integers
        uint32 mask = 0;
        if (n < 0) {
            mask -= 1;
        }
        uint32 zigzag_val = (uint32(n) << 1) ^ mask;

        return encode_varint(zigzag_val);
    }

    /// @notice Encode varint sint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sint64(int64 n) internal pure returns (bytes memory) {
        // https://developers.google.com/protocol-buffers/docs/encoding#signed_integers
        uint64 mask = 0;
        if (n < 0) {
            mask -= 1;
        }
        uint64 zigzag_val = (uint64(n) << 1) ^ mask;

        return encode_varint(zigzag_val);
    }

    /// @notice Encode Boolean.
    /// @param b Boolean
    /// @return Marshaled bytes
    function encode_bool(bool b) internal pure returns (bytes memory) {
        uint64 n = b ? 1 : 0;

        return encode_varint(n);
    }

    /// @notice Encode enumeration.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_enum(int32 n) internal pure returns (bytes memory) {
        return encode_int32(n);
    }

    /// @notice Encode fixed 64-bit int.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_bits64(uint64 n) internal pure returns (bytes memory) {
        bytes memory buf = new bytes(8);

        uint64 tmp = n;
        for (uint64 i = 0; i < 8; i++) {
            // Little endian
            buf[i] = bytes1(uint8(tmp & 0xFF));
            tmp = tmp >> 8;
        }

        return buf;
    }

    /// @notice Encode fixed uint64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_fixed64(uint64 n) internal pure returns (bytes memory) {
        return encode_bits64(n);
    }

    /// @notice Encode fixed int64.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sfixed64(int64 n) internal pure returns (bytes memory) {
        return encode_bits64(uint64(n));
    }

    /// @notice Decode fixed 32-bit int.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_bits32(uint32 n) internal pure returns (bytes memory) {
        bytes memory buf = new bytes(4);

        uint64 tmp = n;
        for (uint64 i = 0; i < 4; i++) {
            // Little endian
            buf[i] = bytes1(uint8(tmp & 0xFF));
            tmp = tmp >> 8;
        }

        return buf;
    }

    /// @notice Encode fixed uint32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_fixed32(uint32 n) internal pure returns (bytes memory) {
        return encode_bits32(n);
    }

    /// @notice Encode fixed int32.
    /// @param n Number
    /// @return Marshaled bytes
    function encode_sfixed32(int32 n) internal pure returns (bytes memory) {
        return encode_bits32(uint32(n));
    }

    /// @notice Encode length-delimited field.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_length_delimited(bytes memory b)
        internal
        pure
        returns (bytes memory)
    {
        // Length-delimited fields begin with a varint of the number of bytes that follow
        bytes memory length_buf = encode_uint64(uint64(b.length));
        bytes memory buf = new bytes(b.length + length_buf.length);

        for (uint64 i = 0; i < length_buf.length; i++) {
            buf[i] = length_buf[i];
        }

        for (uint64 i = 0; i < b.length; i++) {
            buf[i + length_buf.length] = b[i];
        }

        return buf;
    }

    /// @notice Encode string.
    /// @param s String
    /// @return Marshaled bytes
    function encode_string(string memory s)
        internal
        pure
        returns (bytes memory)
    {
        return encode_length_delimited(bytes(s));
    }

    /// @notice Encode bytes array.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_bytes(bytes memory b) internal pure returns (bytes memory) {
        return encode_length_delimited(b);
    }

    /// @notice Encode embedded message.
    /// @param m Message
    /// @return Marshaled bytes
    function encode_embedded_message(bytes memory m)
        internal
        pure
        returns (bytes memory)
    {
        return encode_length_delimited(m);
    }

    /// @notice Encode packed repeated field.
    /// @param b Bytes
    /// @return Marshaled bytes
    function encode_packed_repeated(bytes memory b)
        internal
        pure
        returns (bytes memory)
    {
        return encode_length_delimited(b);
    }
}

/// @dev Helper utility library for calculating Merkle proof and managing bytes.
library Utils {
    /// @dev Returns the hash of a Merkle leaf node.
    function merkleLeafHash(bytes memory value)
        internal
        pure
        returns (bytes32)
    {
        return sha256(abi.encodePacked(uint8(0), value));
    }

    /// @dev Returns the hash of internal node, calculated from child nodes.
    function merkleInnerHash(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32)
    {
        return sha256(abi.encodePacked(uint8(1), left, right));
    }

    /// @dev Returns the encoded bytes using signed varint encoding of the given input.
    function encodeVarintSigned(uint256 value)
        internal
        pure
        returns (bytes memory)
    {
        return encodeVarintUnsigned(value * 2);
    }

    /// @dev Returns the encoded bytes using unsigned varint encoding of the given input.
    function encodeVarintUnsigned(uint256 value)
        internal
        pure
        returns (bytes memory)
    {
        // Computes the size of the encoded value.
        uint256 tempValue = value;
        uint256 size = 0;
        while (tempValue > 0) {
            ++size;
            tempValue >>= 7;
        }
        // Allocates the memory buffer and fills in the encoded value.
        bytes memory result = new bytes(size);
        tempValue = value;
        for (uint256 idx = 0; idx < size; ++idx) {
            result[idx] = bytes1(uint8(128) | uint8(tempValue & 127));
            tempValue >>= 7;
        }
        result[size - 1] &= bytes1(uint8(127)); // Drop the first bit of the last byte.
        return result;
    }

    /// @dev Returns the encoded bytes follow how tendermint encode time.
    function encodeTime(uint64 second, uint32 nanoSecond)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory result =
            abi.encodePacked(hex"08", encodeVarintUnsigned(uint256(second)));
        if (nanoSecond > 0) {
            result = abi.encodePacked(
                result,
                hex"10",
                encodeVarintUnsigned(uint256(nanoSecond))
            );
        }
        return result;
    }
}

/// @dev Library for computing Tendermint's block header hash from app hash, time, and height.
///
/// In Tendermint, a block header hash is the Merkle hash of a binary tree with 14 leaf nodes.
/// Each node encodes a data piece of the blockchain. The notable data leaves are: [A] app_hash,
/// [2] height, and [3] - time. All data pieces are combined into one 32-byte hash to be signed
/// by block validators. The structure of the Merkle tree is shown below.
///
///                                   [BlockHeader]
///                                /                \
///                   [3A]                                    [3B]
///                 /      \                                /      \
///         [2A]                [2B]                [2C]                [2D]
///        /    \              /    \              /    \              /    \
///    [1A]      [1B]      [1C]      [1D]      [1E]      [1F]        [C]    [D]
///    /  \      /  \      /  \      /  \      /  \      /  \
///  [0]  [1]  [2]  [3]  [4]  [5]  [6]  [7]  [8]  [9]  [A]  [B]
///
///  [0] - version               [1] - chain_id            [2] - height        [3] - time
///  [4] - last_block_id         [5] - last_commit_hash    [6] - data_hash     [7] - validators_hash
///  [8] - next_validators_hash  [9] - consensus_hash      [A] - app_hash      [B] - last_results_hash
///  [C] - evidence_hash         [D] - proposer_address
///
/// Notice that NOT all leaves of the Merkle tree are needed in order to compute the Merkle
/// root hash, since we only want to validate the correctness of [A], [2], and [3]. In fact, only
/// [1A], [2B], [1E], [B], and [2D] are needed in order to compute [BlockHeader].
library BlockHeaderMerkleParts {
    struct Data {
        bytes32 versionAndChainIdHash; // [1A]
        uint64 height; // [2]
        uint64 timeSecond; // [3]
        uint32 timeNanoSecondFraction; // between 0 to 10^9 [3]
        bytes32 lastBlockIdAndOther; // [2B]
        bytes32 nextValidatorHashAndConsensusHash; // [1E]
        bytes32 lastResultsHash; // [B]
        bytes32 evidenceAndProposerHash; // [2D]
    }

    /// @dev Returns the block header hash after combining merkle parts with necessary data.
    /// @param appHash The Merkle hash of BandChain application state.
    function getBlockHeader(Data memory self, bytes32 appHash)
        internal
        pure
        returns (bytes32)
    {
        return
            Utils.merkleInnerHash( // [BlockHeader]
                Utils.merkleInnerHash( // [3A]
                    Utils.merkleInnerHash( // [2A]
                        self.versionAndChainIdHash, // [1A]
                        Utils.merkleInnerHash( // [1B]
                            Utils.merkleLeafHash( // [2]
                                abi.encodePacked(
                                    uint8(8),
                                    Utils.encodeVarintUnsigned(self.height)
                                )
                            ),
                            Utils.merkleLeafHash( // [3]
                                Utils.encodeTime(
                                    self.timeSecond,
                                    self.timeNanoSecondFraction
                                )
                            )
                        )
                    ),
                    self.lastBlockIdAndOther // [2B]
                ),
                Utils.merkleInnerHash( // [3B]
                    Utils.merkleInnerHash( // [2C]
                        self.nextValidatorHashAndConsensusHash, // [1E]
                        Utils.merkleInnerHash( // [1F]
                            Utils.merkleLeafHash( // [A]
                                abi.encodePacked(uint8(10), uint8(32), appHash)
                            ),
                            self.lastResultsHash // [B]
                        )
                    ),
                    self.evidenceAndProposerHash // [2D]
                )
            );
    }
}

// MultiStoreProof stores a compact of other Cosmos-SDK modules' storage hash in multistore to
// compute (in combination with oracle store hash) Tendermint's application state hash at a given block.
//                                              ________________[AppHash]_________________
//                                             /                                          \
//                         _________________[I14]_________________                     __[I15]__
//                        /                                        \				  /         \
//             _______[I12]______                          _______[I13]________     [G]         [H]
//            /                  \                        /                    \
//       __[I8]__             __[I9]__                __[I10]__              __[I11]__
//      /         \          /         \            /          \            /         \
//    [I0]       [I1]     [I2]        [I3]        [I4]        [I5]        [I6]       [I7]
//   /   \      /   \    /    \      /    \      /    \      /    \      /    \     /    \
// [0]   [1]  [2]   [3] [4]   [5]  [6]    [7]  [8]    [9]  [A]    [B]  [C]    [D]  [E]   [F]
// [0] - acc (auth) [1] - authz    [2] - bank     [3] - capability [4] - crisis   [5] - dist
// [6] - evidence   [7] - feegrant [8] - gov      [9] - ibccore    [A] - icahost  [B] - mint
// [C] - oracle     [D] - params   [E] - slashing [F] - staking    [G] - transfer [H] - upgrade
// Notice that NOT all leaves of the Merkle tree are needed in order to compute the Merkle
// root hash, since we only want to validate the correctness of [B] In fact, only
// [A], [I4], [I11], [I12], and [G] are needed in order to compute [AppHash].

library MultiStore {

    struct Data {
        bytes32 oracleIAVLStateHash; // [C]
        bytes32 paramsStoreMerkleHash; // [D]
        bytes32 slashingToStakingStoresMerkleHash; // [I7]
        bytes32 govToMintStoresMerkleHash; // [I10]
        bytes32 authToFeegrantStoresMerkleHash; // [I12]
        bytes32 transferToUpgradeStoresMerkleHash; // [I15]
    }

    function getAppHash(Data memory self) internal pure returns (bytes32) {
        return
            Utils.merkleInnerHash( // [AppHash]
                Utils.merkleInnerHash( // [I14]
                    self.authToFeegrantStoresMerkleHash, // [I12]
                    Utils.merkleInnerHash( // [I13]
                        self.govToMintStoresMerkleHash, // [I10]
                        Utils.merkleInnerHash( // [I11]
                            Utils.merkleInnerHash( // [I6]
                                Utils.merkleLeafHash( // [C]
                                    abi.encodePacked(
                                        hex"066f7261636c6520", // oracle prefix (uint8(6) + "oracle" + uint8(32))
                                        sha256(
                                            abi.encodePacked(
                                                self.oracleIAVLStateHash
                                            )
                                        )
                                    )
                                ),
                                self.paramsStoreMerkleHash // [D]
                            ),
                            self.slashingToStakingStoresMerkleHash // [I7]
                        )
                    )
                ),
                self.transferToUpgradeStoresMerkleHash // [I15]
            );
    }
}

/// @dev Library for performing concatenation of all common parts together into a single common part.
/// The common part is used for the signature verification process, and it should be the same bytes for all validators.
/// The library also performs a sanity check to ensure the integrity of the data.
///
/// ================================ Original structs on Tendermint ================================
///
/// type SignedMsgType int32
///
/// type CanonicalPartSetHeader struct {
///        Total uint32 `protobuf:"varint,1,opt,name=total`
///        Hash  []byte `protobuf:"bytes,2,opt,name=hash`
/// }
///
/// type CanonicalBlockID struct {
///        Hash          []byte                 `protobuf:"bytes,1,opt,name=hash`
///        PartSetHeader CanonicalPartSetHeader `protobuf:"bytes,2,opt,name=part_set_header`
/// }
///
/// type CanonicalVote struct {
///        Type      SignedMsgType     `protobuf:"varint,1,opt,name=type`
///        Height    int64             `protobuf:"fixed64,2,opt,name=height`
///        Round     int64             `protobuf:"fixed64,3,opt,name=round`
///        BlockID   *CanonicalBlockID `protobuf:"bytes,4,opt,name=block_id`
///        Timestamp time.Time         `protobuf:"bytes,5,opt,name=timestamp`
///        ChainID   string            `protobuf:"bytes,6,opt,name=chain_id`
/// }
///
/// ================================ Original structs on Tendermint ================================
///
library CommonEncodedVotePart {
    struct Data {
        bytes signedDataPrefix;
        bytes signedDataSuffix;
    }

    /// @dev Returns the address that signed on the given block hash.
    /// @param blockHash The block hash that the validator signed data on.
    function checkPartsAndEncodedCommonParts(Data memory self, bytes32 blockHash)
        internal
        pure
        returns (bytes memory)
    {
        // We need to limit the possible size of the prefix and suffix to ensure only one possible block hash.

        // There are only two possible prefix sizes.
        // 1. If Round == 0, the prefix size should be 15 because the encoded Round was cut off.
        // 2. If not then the prefix size should be 24 (15 + 9).
        require(
            self.signedDataPrefix.length == 15 || self.signedDataPrefix.length == 24,
            "CommonEncodedVotePart: Invalid prefix's size"
        );

        // The suffix is encoded of a CanonicalPartSetHeader, which has a fixed size in practical.
        // There are two reasons why.
        // 1. The maximum value of CanonicalPartSetHeader.Total is 48 (3145728 / 65536) because Band's MaxBlockSizeBytes
        // is 3145728 bytes, and the max BlockPartSizeBytes's size is 65536 bytes.
        // 2. The CanonicalPartSetHeader.Hash's size is fixed (32 bytes) because it is a product of SHA256.
        // Therefore, the overall size is fixed.
        require(self.signedDataSuffix.length == 38, "CommonEncodedVotePart: Invalid suffix's size");

        return abi.encodePacked(
            self.signedDataPrefix,
            blockHash,
            self.signedDataSuffix
        );
    }
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

/// @dev Library for computing iAVL Merkle root from (1) data leaf and (2) a list of "MerklePath"
/// from such leaf to the root of the tree. Each Merkle path (i.e. proof component) consists of:
///
/// - isDataOnRight: whether the data is on the right subtree of this internal node.
/// - subtreeHeight: well, it is the height of this subtree.
/// - subtreeVersion: the latest block height that this subtree has been updated.
/// - siblingHash: 32-byte hash of the other child subtree
///
/// To construct a hash of an internal Merkle node, the hashes of the two subtrees are combined
/// with extra data of this internal node. See implementation below. Repeatedly doing this from
/// the leaf node until you get to the root node to get the final iAVL Merkle hash.
library IAVLMerklePath {
    struct Data {
        bool isDataOnRight;
        uint8 subtreeHeight;
        uint256 subtreeSize;
        uint256 subtreeVersion;
        bytes32 siblingHash;
    }

    /// @dev Returns the upper Merkle hash given a proof component and hash of data subtree.
    /// @param dataSubtreeHash The hash of data subtree up until this point.
    function getParentHash(Data memory self, bytes32 dataSubtreeHash)
        internal
        pure
        returns (bytes32)
    {
        (bytes32 leftSubtree, bytes32 rightSubtree) =
            self.isDataOnRight ? (self.siblingHash, dataSubtreeHash) : (dataSubtreeHash, self.siblingHash);
        return
            sha256(
                abi.encodePacked(
                    self.subtreeHeight << 1, // Tendermint signed-int8 encoding requires multiplying by 2
                    Utils.encodeVarintSigned(self.subtreeSize),
                    Utils.encodeVarintSigned(self.subtreeVersion),
                    uint8(32), // Size of left subtree hash
                    leftSubtree,
                    uint8(32), // Size of right subtree hash
                    rightSubtree
                )
            );
    }
}

/// @dev Library for performing signer recovery for ECDSA secp256k1 signature. Note that the
/// library is written specifically for signature signed on Tendermint's precommit data, which
/// includes the block hash and some additional information prepended and appended to the block
/// hash. The prepended part (prefix) and the appended part (suffix) are different for each signer
/// (including signature size, machine clock, validator index, etc).
///
library TMSignature {
    struct Data {
        bytes32 r;
        bytes32 s;
        uint8 v;
        bytes encodedTimestamp;
    }

    /// @dev Returns the address that signed on the given encoded canonical vote message on Cosmos.
    /// @param commonEncodedPart The first common part of the encoded canonical vote.
    /// @param encodedChainID The last part of the encoded canonical vote.
    function checkTimeAndRecoverSigner(Data memory self, bytes memory commonEncodedPart, bytes memory encodedChainID)
        internal
        pure
        returns (address)
    {
        // We need to limit the possible size of the encodedCanonicalVote to ensure only one possible block hash.
        // The size of the encodedTimestamp will be between 6 and 12 according to the following two constraints.
        // 1. The size of an encoded Unix's second is 6 bytes until over a thousand years in the future.
        // 2. The NanoSecond size can vary from 0 to 6 bytes.
        // Therefore, 6 + 0 <= the size <= 6 + 6.
        require(
            6 <= self.encodedTimestamp.length && self.encodedTimestamp.length <= 12,
            "TMSignature: Invalid timestamp's size"
        );
        bytes memory encodedCanonicalVote = abi.encodePacked(
            commonEncodedPart,
            uint8(42),
            uint8(self.encodedTimestamp.length),
            self.encodedTimestamp,
            encodedChainID
        );
        return
            ecrecover(
                sha256(abi.encodePacked(uint8(encodedCanonicalVote.length), encodedCanonicalVote)),
                self.v,
                self.r,
                self.s
            );
    }
}

interface IBridge {
    enum ResolveStatus {
        RESOLVE_STATUS_OPEN_UNSPECIFIED,
        RESOLVE_STATUS_SUCCESS,
        RESOLVE_STATUS_FAILURE,
        RESOLVE_STATUS_EXPIRED
    }
    /// Result struct is similar packet on Bandchain using to re-calculate result hash.
    struct Result {
        string clientID;
        uint64 oracleScriptID;
        bytes params;
        uint64 askCount;
        uint64 minCount;
        uint64 requestID;
        uint64 ansCount;
        uint64 requestTime;
        uint64 resolveTime;
        ResolveStatus resolveStatus;
        bytes result;
    }

    /// Performs oracle state relay and oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and data verification.
    function relayAndVerify(bytes calldata data)
        external
        returns (Result memory);

    /// Performs oracle state relay and many times of oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and an array of data verification.
    function relayAndMultiVerify(bytes calldata data)
        external
        returns (Result[] memory);

    // Performs oracle state relay and requests count verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready tobe validated and used.
    /// @param data The encoded data for oracle state relay and requests count verification.
    function relayAndVerifyCount(bytes calldata data)
        external
        returns (uint64, uint64); // block time, requests count
}

library ResultCodec {
    function encode(IBridge.Result memory instance)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory finalEncoded;

        // Omit encoding clientID if default value
        if (bytes(instance.clientID).length > 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(
                    1,
                    uint64(ProtobufLib.WireType.LengthDelimited)
                ),
                ProtobufLib.encode_uint64(
                    uint64(bytes(instance.clientID).length)
                ),
                bytes(instance.clientID)
            );
        }

        // Omit encoding oracleScriptID if default value
        if (uint64(instance.oracleScriptID) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(2, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.oracleScriptID)
            );
        }

        // Omit encoding params if default value
        if (bytes(instance.params).length > 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(
                    3,
                    uint64(ProtobufLib.WireType.LengthDelimited)
                ),
                ProtobufLib.encode_uint64(
                    uint64(bytes(instance.params).length)
                ),
                bytes(instance.params)
            );
        }

        // Omit encoding askCount if default value
        if (uint64(instance.askCount) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(4, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.askCount)
            );
        }

        // Omit encoding minCount if default value
        if (uint64(instance.minCount) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(5, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.minCount)
            );
        }

        // Omit encoding requestID if default value
        if (uint64(instance.requestID) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(6, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.requestID)
            );
        }

        // Omit encoding ansCount if default value
        if (uint64(instance.ansCount) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(7, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.ansCount)
            );
        }

        // Omit encoding requestTime if default value
        if (uint64(instance.requestTime) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(8, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.requestTime)
            );
        }

        // Omit encoding resolveTime if default value
        if (uint64(instance.resolveTime) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(9, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_uint64(instance.resolveTime)
            );
        }

        // Omit encoding resolveStatus if default value
        if (uint64(instance.resolveStatus) != 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(10, uint64(ProtobufLib.WireType.Varint)),
                ProtobufLib.encode_int32(int32(uint32(instance.resolveStatus)))
            );
        }

        // Omit encoding result if default value
        if (bytes(instance.result).length > 0) {
            finalEncoded = abi.encodePacked(
                finalEncoded,
                ProtobufLib.encode_key(
                    11,
                    uint64(ProtobufLib.WireType.LengthDelimited)
                ),
                ProtobufLib.encode_uint64(
                    uint64(bytes(instance.result).length)
                ),
                bytes(instance.result)
            );
        }

        return finalEncoded;
    }
}

/// @title BandChain Bridge
/// @author Band Protocol Team
contract Bridge is IBridge, Ownable {
    using BlockHeaderMerkleParts for BlockHeaderMerkleParts.Data;
    using MultiStore for MultiStore.Data;
    using IAVLMerklePath for IAVLMerklePath.Data;
    using CommonEncodedVotePart for CommonEncodedVotePart.Data;
    using TMSignature for TMSignature.Data;
    using EnumerableMap for EnumerableMap.AddressToUintMap;

    struct ValidatorWithPower {
        address addr;
        uint256 power;
    }

    struct BlockDetail {
        bytes32 oracleState;
        uint64 timeSecond;
        uint32 timeNanoSecondFraction; // between 0 to 10^9
    }

    /// Mapping from block height to the struct that contains block time and hash of "oracle" iAVL Merkle tree.
    mapping(uint256 => BlockDetail) public blockDetails;
    /// Mapping from an address to its voting power.
    EnumerableMap.AddressToUintMap private validatorPowers;
    /// The total voting power of active validators currently on duty.
    uint256 public totalValidatorPower;
    /// The encoded chain's ID of Band.
    bytes public encodedChainID;

    /// Initializes an oracle bridge to BandChain.
    /// @param validators The initial set of BandChain active validators.
    constructor(ValidatorWithPower[] memory validators, bytes memory _encodedChainID) {
        for (uint256 idx = 0; idx < validators.length; ++idx) {
            ValidatorWithPower memory validator = validators[idx];
            require(
                validatorPowers.set(validator.addr, validator.power),
                "DUPLICATION_IN_INITIAL_VALIDATOR_SET"
            );
            totalValidatorPower += validator.power;
        }
        encodedChainID = _encodedChainID;
    }

    /// Get number of validators.
    function getNumberOfValidators() public view returns(uint256) {
        return validatorPowers.length();
    }

    /// Get validators by specifying an offset index and a chunk's size.
    /// @param offset An offset index of validators mapping.
    /// @param size The size of the validators chunk.
    function getValidators(uint256 offset, uint256 size) public view returns(ValidatorWithPower[] memory) {
        ValidatorWithPower[] memory validatorWithPowerList;
        uint256 numberOfValidators = getNumberOfValidators();

        if (offset >= numberOfValidators) {
            // return an empty list
            return validatorWithPowerList;
        } else if (offset + size > numberOfValidators) {
            // reduce size of the entire list
            size = numberOfValidators - offset;
        }

        validatorWithPowerList = new ValidatorWithPower[](size);
        for (uint256 idx = 0; idx < size; ++idx) {
            (address addr, uint256 power) = validatorPowers.at(idx + offset);
            validatorWithPowerList[idx] = ValidatorWithPower({addr: addr, power: power});
        }
        return validatorWithPowerList;
    }

    /// Get all validators with power.
    function getAllValidatorPowers() external view returns(ValidatorWithPower[] memory) {
        return getValidators(0, getNumberOfValidators());
    }

    /// Get validator by address
    /// @param addr is an address of the specific validator.
    function getValidatorPower(address addr) public view returns(uint256 power) {
        (, power) = validatorPowers.tryGet(addr);
    }

    /// Update validator powers by owner.
    /// @param validators The changed set of BandChain validators.
    /// @param expectedTotalPower The value that the totalValidatorPower should be after updating.
    function updateValidatorPowers(ValidatorWithPower[] calldata validators, uint256 expectedTotalPower)
        external
        onlyOwner
    {
        uint256 _totalValidatorPower = totalValidatorPower;
        for (uint256 idx = 0; idx < validators.length; ++idx) {
            ValidatorWithPower memory validator = validators[idx];
            (bool found, uint256 oldPower) = validatorPowers.tryGet(validator.addr);
            if (found) {
                _totalValidatorPower -= oldPower;
            }

            if (validator.power > 0) {
                validatorPowers.set(validator.addr, validator.power);
                _totalValidatorPower += validator.power;
            } else {
                validatorPowers.remove(validator.addr);
            }
        }

        require(_totalValidatorPower == expectedTotalPower, "TOTAL_POWER_CHECKING_FAIL");
        totalValidatorPower = _totalValidatorPower;
    }

    /// Relays a detail of Bandchain block to the bridge contract.
    /// @param multiStore Extra multi store to compute app hash. See MultiStore lib.
    /// @param merkleParts Extra merkle parts to compute block hash. See BlockHeaderMerkleParts lib.
    /// @param signatures The signatures signed on this block, sorted alphabetically by address.
    function relayBlock(
        MultiStore.Data calldata multiStore,
        BlockHeaderMerkleParts.Data calldata merkleParts,
        CommonEncodedVotePart.Data calldata commonEncodedVotePart,
        TMSignature.Data[] calldata signatures
    ) public {
        if (
            blockDetails[merkleParts.height].oracleState == multiStore.oracleIAVLStateHash &&
            blockDetails[merkleParts.height].timeSecond == merkleParts.timeSecond &&
            blockDetails[merkleParts.height].timeNanoSecondFraction == merkleParts.timeNanoSecondFraction
        ) return;

        // Computes Tendermint's block header hash at this given block.
        bytes32 blockHeader = merkleParts.getBlockHeader(multiStore.getAppHash());
        // Verify the prefix, suffix and then compute the common encoded part.
        bytes memory commonEncodedPart = commonEncodedVotePart.checkPartsAndEncodedCommonParts(blockHeader);
        // Create a local variable to prevent reading that state repeatedly.
        bytes memory _encodedChainID = encodedChainID;

        // Counts the total number of valid signatures signed by active validators.
        address lastSigner = address(0);
        uint256 sumVotingPower = 0;
        for (uint256 idx = 0; idx < signatures.length; ++idx) {
            address signer = signatures[idx].checkTimeAndRecoverSigner(commonEncodedPart, _encodedChainID);
            require(signer > lastSigner, "INVALID_SIGNATURE_SIGNER_ORDER");
            (bool success, uint256 power) = validatorPowers.tryGet(signer);
            if (success) {
                sumVotingPower += power;
            }
            lastSigner = signer;
        }
        // Verifies that sufficient validators signed the block and saves the oracle state.
        require(
            sumVotingPower * 3 > totalValidatorPower * 2,
            "INSUFFICIENT_VALIDATOR_SIGNATURES"
        );
        blockDetails[merkleParts.height] = BlockDetail({
            oracleState: multiStore.oracleIAVLStateHash,
            timeSecond: merkleParts.timeSecond,
            timeNanoSecondFraction: merkleParts.timeNanoSecondFraction
        });
    }

    /// Verifies that the given data is a valid data on BandChain as of the relayed block height.
    /// @param blockHeight The block height. Someone must already relay this block.
    /// @param result The result of this request.
    /// @param version Lastest block height that the data node was updated.
    /// @param merklePaths Merkle proof that shows how the data leave is part of the oracle iAVL.
    function verifyOracleData(
        uint256 blockHeight,
        Result calldata result,
        uint256 version,
        IAVLMerklePath.Data[] calldata merklePaths
    ) public view returns (Result memory) {
        bytes32 oracleStateRoot = blockDetails[blockHeight].oracleState;
        require(
            oracleStateRoot != bytes32(uint256(0)),
            "NO_ORACLE_ROOT_STATE_DATA"
        );
        // Computes the hash of leaf node for iAVL oracle tree.
        bytes32 dataHash = sha256(ResultCodec.encode(result));

        // Verify proof
        require(
            verifyProof(
                oracleStateRoot,
                version,
                abi.encodePacked(
                    uint8(255),
                    result.requestID
                ),
                dataHash,
                merklePaths
            ),
            "INVALID_ORACLE_DATA_PROOF"
        );

        return result;
    }

    /// Verifies that the given data is a valid data on BandChain as of the relayed block height.
    /// @param blockHeight The block height. Someone must already relay this block.
    /// @param count The requests count on the block.
    /// @param version Lastest block height that the data node was updated.
    /// @param merklePaths Merkle proof that shows how the data leave is part of the oracle iAVL.
    function verifyRequestsCount(
        uint256 blockHeight,
        uint256 count,
        uint256 version,
        IAVLMerklePath.Data[] memory merklePaths
    ) public view returns (uint64, uint64) {
        BlockDetail memory blockDetail = blockDetails[blockHeight];
        bytes32 oracleStateRoot = blockDetail.oracleState;
        require(
            oracleStateRoot != bytes32(uint256(0)),
            "NO_ORACLE_ROOT_STATE_DATA"
        );

        // Encode and calculate hash of count
        bytes32 dataHash = sha256(abi.encodePacked(uint64(count)));

        // Verify proof
        require(
            verifyProof(
                oracleStateRoot,
                version,
                hex"0052657175657374436f756e74",
                dataHash,
                merklePaths
            ),
            "INVALID_ORACLE_DATA_PROOF"
        );

        return (blockDetail.timeSecond, uint64(count));
    }

    /// Performs oracle state relay and oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and data verification.
    function relayAndVerify(bytes calldata data)
        external
        override
        returns (Result memory)
    {
        (bytes memory relayData, bytes memory verifyData) = abi.decode(
            data, 
            (bytes, bytes)
        );
        (bool relayOk, ) = address(this).call(
            abi.encodePacked(this.relayBlock.selector, relayData)
        );
        require(relayOk, "RELAY_BLOCK_FAILED");
        (bool verifyOk, bytes memory verifyResult) = address(this).staticcall(
            abi.encodePacked(this.verifyOracleData.selector, verifyData)
        );
        require(verifyOk, "VERIFY_ORACLE_DATA_FAILED");
        return abi.decode(verifyResult, (Result));
    }

    /// Performs oracle state relay and many times of oracle data verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data for oracle state relay and an array of data verification.
    function relayAndMultiVerify(bytes calldata data)
        external
        override
        returns (Result[] memory)
    {
        (bytes memory relayData, bytes[] memory manyVerifyData) = abi.decode(
            data, 
            (bytes, bytes[])
        );
        (bool relayOk, ) = address(this).call(
            abi.encodePacked(this.relayBlock.selector, relayData)
        );
        require(relayOk, "RELAY_BLOCK_FAILED");

        Result[] memory results = new Result[](manyVerifyData.length);
        for (uint256 i = 0; i < manyVerifyData.length; i++) {
            (bool verifyOk, bytes memory verifyResult) =
                address(this).staticcall(
                    abi.encodePacked(
                        this.verifyOracleData.selector,
                        manyVerifyData[i]
                    )
                );
            require(verifyOk, "VERIFY_ORACLE_DATA_FAILED");
            results[i] = abi.decode(verifyResult, (Result));
        }

        return results;
    }

    /// Performs oracle state relay and requests count verification in one go. The caller submits
    /// the encoded proof and receives back the decoded data, ready to be validated and used.
    /// @param data The encoded data
    function relayAndVerifyCount(bytes calldata data)
        external
        override
        returns (uint64, uint64) 
    {
        (bytes memory relayData, bytes memory verifyData) = abi.decode(
            data,
            (bytes, bytes)
        );
        (bool relayOk, ) = address(this).call(
            abi.encodePacked(this.relayBlock.selector, relayData)
        );
        require(relayOk, "RELAY_BLOCK_FAILED");

        (bool verifyOk, bytes memory verifyResult) = address(this).staticcall(
            abi.encodePacked(this.verifyRequestsCount.selector, verifyData)
        );
        require(verifyOk, "VERIFY_REQUESTS_COUNT_FAILED");

        return abi.decode(verifyResult, (uint64, uint64));
    }
    
    /// Verifies validity of the given data in the Oracle store. This function is used for both
    /// querying an oracle request and request count.
    /// @param rootHash The expected rootHash of the oracle store.
    /// @param version Lastest block height that the data node was updated.
    /// @param key The encoded key of an oracle request or request count. 
    /// @param dataHash Hashed data corresponding to the provided key.
    /// @param merklePaths Merkle proof that shows how the data leave is part of the oracle iAVL.
    function verifyProof(
        bytes32 rootHash,
        uint256 version,
        bytes memory key,
        bytes32 dataHash,
        IAVLMerklePath.Data[] memory merklePaths
    ) private pure returns (bool) {
        bytes memory encodedVersion = Utils.encodeVarintSigned(version);

        bytes32 currentMerkleHash = sha256(
            abi.encodePacked(
                uint8(0), // Height of tree (only leaf node) is 0 (signed-varint encode)
                uint8(2), // Size of subtree is 1 (signed-varint encode)
                encodedVersion,
                uint8(key.length), // Size of data key
                key,
                uint8(32), // Size of data hash
                dataHash
            )
        );

        // Goes step-by-step computing hash of parent nodes until reaching root node.
        for (uint256 idx = 0; idx < merklePaths.length; ++idx) {
            currentMerkleHash = merklePaths[idx].getParentHash(
                currentMerkleHash
            );
        }

        // Verifies that the computed Merkle root matches what currently exists.
        return currentMerkleHash == rootHash;
    }
}