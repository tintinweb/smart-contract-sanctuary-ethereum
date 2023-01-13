pragma solidity ^0.8.4;

/** @title BitcoinSPV */
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";

library BTCUtils {
    using BytesLib for bytes;
    using SafeMath for uint256;

    // The target at minimum Difficulty. Also the target of the genesis block
    uint256 public constant DIFF1_TARGET = 0xffff0000000000000000000000000000000000000000000000000000;

    uint256 public constant RETARGET_PERIOD = 2 * 7 * 24 * 60 * 60;  // 2 weeks in seconds
    uint256 public constant RETARGET_PERIOD_BLOCKS = 2016;  // 2 weeks in blocks

    uint256 public constant ERR_BAD_ARG = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /* ***** */
    /* UTILS */
    /* ***** */

    /// @notice         Determines the length of a VarInt in bytes
    /// @dev            A VarInt of >1 byte is prefixed with a flag indicating its length
    /// @param _flag    The first byte of a VarInt
    /// @return         The number of non-flag bytes in the VarInt
    function determineVarIntDataLength(bytes memory _flag) internal pure returns (uint8) {
        return determineVarIntDataLengthAt(_flag, 0);
    }

    /// @notice         Determines the length of a VarInt in bytes
    /// @dev            A VarInt of >1 byte is prefixed with a flag indicating its length
    /// @param _b       The byte array containing a VarInt
    /// @param _at      The position of the VarInt in the array
    /// @return         The number of non-flag bytes in the VarInt
    function determineVarIntDataLengthAt(bytes memory _b, uint256 _at) internal pure returns (uint8) {
        if (uint8(_b[_at]) == 0xff) {
            return 8;  // one-byte flag, 8 bytes data
        }
        if (uint8(_b[_at]) == 0xfe) {
            return 4;  // one-byte flag, 4 bytes data
        }
        if (uint8(_b[_at]) == 0xfd) {
            return 2;  // one-byte flag, 2 bytes data
        }

        return 0;  // flag is data
    }

    /// @notice     Parse a VarInt into its data length and the number it represents
    /// @dev        Useful for Parsing Vins and Vouts. Returns ERR_BAD_ARG if insufficient bytes.
    ///             Caller SHOULD explicitly handle this case (or bubble it up)
    /// @param _b   A byte-string starting with a VarInt
    /// @return     number of bytes in the encoding (not counting the tag), the encoded int
    function parseVarInt(bytes memory _b) internal pure returns (uint256, uint256) {
        return parseVarIntAt(_b, 0);
    }

    /// @notice     Parse a VarInt into its data length and the number it represents
    /// @dev        Useful for Parsing Vins and Vouts. Returns ERR_BAD_ARG if insufficient bytes.
    ///             Caller SHOULD explicitly handle this case (or bubble it up)
    /// @param _b   A byte-string containing a VarInt
    /// @param _at  The position of the VarInt
    /// @return     number of bytes in the encoding (not counting the tag), the encoded int
    function parseVarIntAt(bytes memory _b, uint256 _at) internal pure returns (uint256, uint256) {
        uint8 _dataLen = determineVarIntDataLengthAt(_b, _at);

        if (_dataLen == 0) {
            return (0, uint8(_b[_at]));
        }
        if (_b.length < 1 + _dataLen + _at) {
            return (ERR_BAD_ARG, 0);
        }
        uint256 _number;
        if (_dataLen == 2) {
            _number = reverseUint16(uint16(_b.slice2(1 + _at)));
        } else if (_dataLen == 4) {
            _number = reverseUint32(uint32(_b.slice4(1 + _at)));
        } else if (_dataLen == 8) {
            _number = reverseUint64(uint64(_b.slice8(1 + _at)));
        }
        return (_dataLen, _number);
    }

    /// @notice          Changes the endianness of a byte array
    /// @dev             Returns a new, backwards, bytes
    /// @param _b        The bytes to reverse
    /// @return          The reversed bytes
    function reverseEndianness(bytes memory _b) internal pure returns (bytes memory) {
        bytes memory _newValue = new bytes(_b.length);

        for (uint i = 0; i < _b.length; i++) {
            _newValue[_b.length - i - 1] = _b[i];
        }

        return _newValue;
    }

    /// @notice          Changes the endianness of a uint256
    /// @dev             https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint256(uint256 _b) internal pure returns (uint256 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = ((v >> 32) & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);
        // swap 8-byte long pairs
        v = ((v >> 64) & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);
        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    /// @notice          Changes the endianness of a uint64
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint64(uint64 _b) internal pure returns (uint64 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF00FF00FF) |
            ((v & 0x00FF00FF00FF00FF) << 8);
        // swap 2-byte long pairs
        v = ((v >> 16) & 0x0000FFFF0000FFFF) |
            ((v & 0x0000FFFF0000FFFF) << 16);
        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    /// @notice          Changes the endianness of a uint32
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint32(uint32 _b) internal pure returns (uint32 v) {
        v = _b;

        // swap bytes
        v = ((v >> 8) & 0x00FF00FF) |
            ((v & 0x00FF00FF) << 8);
        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    /// @notice          Changes the endianness of a uint24
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint24(uint24 _b) internal pure returns (uint24 v) {
        v =  (_b << 16) | (_b & 0x00FF00) | (_b >> 16);
    }

    /// @notice          Changes the endianness of a uint16
    /// @param _b        The unsigned integer to reverse
    /// @return v        The reversed value
    function reverseUint16(uint16 _b) internal pure returns (uint16 v) {
        v =  (_b << 8) | (_b >> 8);
    }


    /// @notice          Converts big-endian bytes to a uint
    /// @dev             Traverses the byte array and sums the bytes
    /// @param _b        The big-endian bytes-encoded integer
    /// @return          The integer representation
    function bytesToUint(bytes memory _b) internal pure returns (uint256) {
        uint256 _number;

        for (uint i = 0; i < _b.length; i++) {
            _number = _number + uint8(_b[i]) * (2 ** (8 * (_b.length - (i + 1))));
        }

        return _number;
    }

    /// @notice          Get the last _num bytes from a byte array
    /// @param _b        The byte array to slice
    /// @param _num      The number of bytes to extract from the end
    /// @return          The last _num bytes of _b
    function lastBytes(bytes memory _b, uint256 _num) internal pure returns (bytes memory) {
        uint256 _start = _b.length.sub(_num);

        return _b.slice(_start, _num);
    }

    /// @notice          Implements bitcoin's hash160 (rmd160(sha2()))
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash160(bytes memory _b) internal pure returns (bytes memory) {
        return abi.encodePacked(ripemd160(abi.encodePacked(sha256(_b))));
    }

    /// @notice          Implements bitcoin's hash160 (sha2 + ripemd160)
    /// @dev             sha2 precompile at address(2), ripemd160 at address(3)
    /// @param _b        The pre-image
    /// @return res      The digest
    function hash160View(bytes memory _b) internal view returns (bytes20 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            pop(staticcall(gas(), 2, add(_b, 32), mload(_b), 0x00, 32))
            pop(staticcall(gas(), 3, 0x00, 32, 0x00, 32))
            // read from position 12 = 0c
            res := mload(0x0c)
        }
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             abi.encodePacked changes the return to bytes instead of bytes32
    /// @param _b        The pre-image
    /// @return          The digest
    function hash256(bytes memory _b) internal pure returns (bytes32) {
        return sha256(abi.encodePacked(sha256(_b)));
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             sha2 is precompiled smart contract located at address(2)
    /// @param _b        The pre-image
    /// @return res      The digest
    function hash256View(bytes memory _b) internal view returns (bytes32 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            pop(staticcall(gas(), 2, add(_b, 32), mload(_b), 0x00, 32))
            pop(staticcall(gas(), 2, 0x00, 32, 0x00, 32))
            res := mload(0x00)
        }
    }

    /// @notice          Implements bitcoin's hash256 on a pair of bytes32
    /// @dev             sha2 is precompiled smart contract located at address(2)
    /// @param _a        The first bytes32 of the pre-image
    /// @param _b        The second bytes32 of the pre-image
    /// @return res      The digest
    function hash256Pair(bytes32 _a, bytes32 _b) internal view returns (bytes32 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(0x00, _a)
            mstore(0x20, _b)
            pop(staticcall(gas(), 2, 0x00, 64, 0x00, 32))
            pop(staticcall(gas(), 2, 0x00, 32, 0x00, 32))
            res := mload(0x00)
        }
    }

    /// @notice          Implements bitcoin's hash256 (double sha2)
    /// @dev             sha2 is precompiled smart contract located at address(2)
    /// @param _b        The array containing the pre-image
    /// @param at        The start of the pre-image
    /// @param len       The length of the pre-image
    /// @return res      The digest
    function hash256Slice(
        bytes memory _b,
        uint256 at,
        uint256 len
    ) internal view returns (bytes32 res) {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            pop(staticcall(gas(), 2, add(_b, add(32, at)), len, 0x00, 32))
            pop(staticcall(gas(), 2, 0x00, 32, 0x00, 32))
            res := mload(0x00)
        }
    }

    /* ************ */
    /* Legacy Input */
    /* ************ */

    /// @notice          Extracts the nth input from the vin (0-indexed)
    /// @dev             Iterates over the vin. If you need to extract several, write a custom function
    /// @param _vin      The vin as a tightly-packed byte array
    /// @param _index    The 0-indexed location of the input to extract
    /// @return          The input as a byte array
    function extractInputAtIndex(bytes memory _vin, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index < _nIns, "Vin read overrun");

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _len = determineInputLengthAt(_vin, _offset);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
            _offset = _offset + _len;
        }

        _len = determineInputLengthAt(_vin, _offset);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _vin.slice(_offset, _len);
    }

    /// @notice          Determines whether an input is legacy
    /// @dev             False if no scriptSig, otherwise True
    /// @param _input    The input
    /// @return          True for legacy, False for witness
    function isLegacyInput(bytes memory _input) internal pure returns (bool) {
        return _input[36] != hex"00";
    }

    /// @notice          Determines the length of a scriptSig in an input
    /// @dev             Will return 0 if passed a witness input.
    /// @param _input    The LEGACY input
    /// @return          The length of the script sig
    function extractScriptSigLen(bytes memory _input) internal pure returns (uint256, uint256) {
        return extractScriptSigLenAt(_input, 0);
    }

    /// @notice          Determines the length of a scriptSig in an input
    ///                  starting at the specified position
    /// @dev             Will return 0 if passed a witness input.
    /// @param _input    The byte array containing the LEGACY input
    /// @param _at       The position of the input in the array
    /// @return          The length of the script sig
    function extractScriptSigLenAt(bytes memory _input, uint256 _at) internal pure returns (uint256, uint256) {
        if (_input.length < 37 + _at) {
            return (ERR_BAD_ARG, 0);
        }

        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = parseVarIntAt(_input, _at + 36);

        return (_varIntDataLen, _scriptSigLen);
    }

    /// @notice          Determines the length of an input from its scriptSig
    /// @dev             36 for outpoint, 1 for scriptSig length, 4 for sequence
    /// @param _input    The input
    /// @return          The length of the input in bytes
    function determineInputLength(bytes memory _input) internal pure returns (uint256) {
        return determineInputLengthAt(_input, 0);
    }

    /// @notice          Determines the length of an input from its scriptSig,
    ///                  starting at the specified position
    /// @dev             36 for outpoint, 1 for scriptSig length, 4 for sequence
    /// @param _input    The byte array containing the input
    /// @param _at       The position of the input in the array
    /// @return          The length of the input in bytes
    function determineInputLengthAt(bytes memory _input, uint256 _at) internal pure returns (uint256) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLenAt(_input, _at);
        if (_varIntDataLen == ERR_BAD_ARG) {
            return ERR_BAD_ARG;
        }

        return 36 + 1 + _varIntDataLen + _scriptSigLen + 4;
    }

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The LEGACY input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLELegacy(bytes memory _input) internal pure returns (bytes4) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice4(36 + 1 + _varIntDataLen + _scriptSigLen);
    }

    /// @notice          Extracts the sequence from the input
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The LEGACY input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceLegacy(bytes memory _input) internal pure returns (uint32) {
        uint32 _leSeqence = uint32(extractSequenceLELegacy(_input));
        uint32 _beSequence = reverseUint32(_leSeqence);
        return _beSequence;
    }
    /// @notice          Extracts the VarInt-prepended scriptSig from the input in a tx
    /// @dev             Will return hex"00" if passed a witness input
    /// @param _input    The LEGACY input
    /// @return          The length-prepended scriptSig
    function extractScriptSig(bytes memory _input) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _scriptSigLen;
        (_varIntDataLen, _scriptSigLen) = extractScriptSigLen(_input);
        require(_varIntDataLen != ERR_BAD_ARG, "Bad VarInt in scriptSig");
        return _input.slice(36, 1 + _varIntDataLen + _scriptSigLen);
    }


    /* ************* */
    /* Witness Input */
    /* ************* */

    /// @notice          Extracts the LE sequence bytes from an input
    /// @dev             Sequence is used for relative time locks
    /// @param _input    The WITNESS input
    /// @return          The sequence bytes (LE uint)
    function extractSequenceLEWitness(bytes memory _input) internal pure returns (bytes4) {
        return _input.slice4(37);
    }

    /// @notice          Extracts the sequence from the input in a tx
    /// @dev             Sequence is a 4-byte little-endian number
    /// @param _input    The WITNESS input
    /// @return          The sequence number (big-endian uint)
    function extractSequenceWitness(bytes memory _input) internal pure returns (uint32) {
        uint32 _leSeqence = uint32(extractSequenceLEWitness(_input));
        uint32 _inputeSequence = reverseUint32(_leSeqence);
        return _inputeSequence;
    }

    /// @notice          Extracts the outpoint from the input in a tx
    /// @dev             32-byte tx id with 4-byte index
    /// @param _input    The input
    /// @return          The outpoint (LE bytes of prev tx hash + LE bytes of prev tx index)
    function extractOutpoint(bytes memory _input) internal pure returns (bytes memory) {
        return _input.slice(0, 36);
    }

    /// @notice          Extracts the outpoint tx id from an input
    /// @dev             32-byte tx id
    /// @param _input    The input
    /// @return          The tx id (little-endian bytes)
    function extractInputTxIdLE(bytes memory _input) internal pure returns (bytes32) {
        return _input.slice32(0);
    }

    /// @notice          Extracts the outpoint tx id from an input
    ///                  starting at the specified position
    /// @dev             32-byte tx id
    /// @param _input    The byte array containing the input
    /// @param _at       The position of the input
    /// @return          The tx id (little-endian bytes)
    function extractInputTxIdLeAt(bytes memory _input, uint256 _at) internal pure returns (bytes32) {
        return _input.slice32(_at);
    }

    /// @notice          Extracts the LE tx input index from the input in a tx
    /// @dev             4-byte tx index
    /// @param _input    The input
    /// @return          The tx index (little-endian bytes)
    function extractTxIndexLE(bytes memory _input) internal pure returns (bytes4) {
        return _input.slice4(32);
    }

    /// @notice          Extracts the LE tx input index from the input in a tx
    ///                  starting at the specified position
    /// @dev             4-byte tx index
    /// @param _input    The byte array containing the input
    /// @param _at       The position of the input
    /// @return          The tx index (little-endian bytes)
    function extractTxIndexLeAt(bytes memory _input, uint256 _at) internal pure returns (bytes4) {
        return _input.slice4(32 + _at);
    }

    /* ****** */
    /* Output */
    /* ****** */

    /// @notice          Determines the length of an output
    /// @dev             Works with any properly formatted output
    /// @param _output   The output
    /// @return          The length indicated by the prefix, error if invalid length
    function determineOutputLength(bytes memory _output) internal pure returns (uint256) {
        return determineOutputLengthAt(_output, 0);
    }

    /// @notice          Determines the length of an output
    ///                  starting at the specified position
    /// @dev             Works with any properly formatted output
    /// @param _output   The byte array containing the output
    /// @param _at       The position of the output
    /// @return          The length indicated by the prefix, error if invalid length
    function determineOutputLengthAt(bytes memory _output, uint256 _at) internal pure returns (uint256) {
        if (_output.length < 9 + _at) {
            return ERR_BAD_ARG;
        }
        uint256 _varIntDataLen;
        uint256 _scriptPubkeyLength;
        (_varIntDataLen, _scriptPubkeyLength) = parseVarIntAt(_output, 8 + _at);

        if (_varIntDataLen == ERR_BAD_ARG) {
            return ERR_BAD_ARG;
        }

        // 8-byte value, 1-byte for tag itself
        return 8 + 1 + _varIntDataLen + _scriptPubkeyLength;
    }

    /// @notice          Extracts the output at a given index in the TxOuts vector
    /// @dev             Iterates over the vout. If you need to extract multiple, write a custom function
    /// @param _vout     The _vout to extract from
    /// @param _index    The 0-indexed location of the output to extract
    /// @return          The specified output
    function extractOutputAtIndex(bytes memory _vout, uint256 _index) internal pure returns (bytes memory) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);
        require(_varIntDataLen != ERR_BAD_ARG, "Read overrun during VarInt parsing");
        require(_index < _nOuts, "Vout read overrun");

        uint256 _len = 0;
        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 _i = 0; _i < _index; _i ++) {
            _len = determineOutputLengthAt(_vout, _offset);
            require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
            _offset += _len;
        }

        _len = determineOutputLengthAt(_vout, _offset);
        require(_len != ERR_BAD_ARG, "Bad VarInt in scriptPubkey");
        return _vout.slice(_offset, _len);
    }

    /// @notice          Extracts the value bytes from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value as LE bytes
    function extractValueLE(bytes memory _output) internal pure returns (bytes8) {
        return _output.slice8(0);
    }

    /// @notice          Extracts the value from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The output
    /// @return          The output value
    function extractValue(bytes memory _output) internal pure returns (uint64) {
        uint64 _leValue = uint64(extractValueLE(_output));
        uint64 _beValue = reverseUint64(_leValue);
        return _beValue;
    }

    /// @notice          Extracts the value from the output in a tx
    /// @dev             Value is an 8-byte little-endian number
    /// @param _output   The byte array containing the output
    /// @param _at       The starting index of the output in the array
    /// @return          The output value
    function extractValueAt(bytes memory _output, uint256 _at) internal pure returns (uint64) {
        uint64 _leValue = uint64(_output.slice8(_at));
        uint64 _beValue = reverseUint64(_leValue);
        return _beValue;
    }

    /// @notice          Extracts the data from an op return output
    /// @dev             Returns hex"" if no data or not an op return
    /// @param _output   The output
    /// @return          Any data contained in the opreturn output, null if not an op return
    function extractOpReturnData(bytes memory _output) internal pure returns (bytes memory) {
        if (_output[9] != hex"6a") {
            return hex"";
        }
        bytes1 _dataLen = _output[10];
        return _output.slice(11, uint256(uint8(_dataLen)));
    }

    /// @notice          Extracts the hash from the output script
    /// @dev             Determines type by the length prefix and validates format
    /// @param _output   The output
    /// @return          The hash committed to by the pk_script, or null for errors
    function extractHash(bytes memory _output) internal pure returns (bytes memory) {
        return extractHashAt(_output, 8, _output.length - 8);
    }

    /// @notice          Extracts the hash from the output script
    /// @dev             Determines type by the length prefix and validates format
    /// @param _output   The byte array containing the output
    /// @param _at       The starting index of the output script in the array
    ///                  (output start + 8)
    /// @param _len      The length of the output script
    ///                  (output length - 8)
    /// @return          The hash committed to by the pk_script, or null for errors
    function extractHashAt(
        bytes memory _output,
        uint256 _at,
        uint256 _len
    ) internal pure returns (bytes memory) {
        uint8 _scriptLen = uint8(_output[_at]);

        // don't have to worry about overflow here.
        // if _scriptLen + 1 overflows, then output length would have to be < 1
        // for this check to pass. if it's < 1, then we errored when assigning
        // _scriptLen
        if (_scriptLen + 1 != _len) {
            return hex"";
        }

        if (uint8(_output[_at + 1]) == 0) {
            if (_scriptLen < 2) {
                return hex"";
            }
            uint256 _payloadLen = uint8(_output[_at + 2]);
            // Check for maliciously formatted witness outputs.
            // No need to worry about underflow as long b/c of the `< 2` check
            if (_payloadLen != _scriptLen - 2 || (_payloadLen != 0x20 && _payloadLen != 0x14)) {
                return hex"";
            }
            return _output.slice(_at + 3, _payloadLen);
        } else {
            bytes3 _tag = _output.slice3(_at);
            // p2pkh
            if (_tag == hex"1976a9") {
                // Check for maliciously formatted p2pkh
                // No need to worry about underflow, b/c of _scriptLen check
                if (uint8(_output[_at + 3]) != 0x14 ||
                    _output.slice2(_at + _len - 2) != hex"88ac") {
                    return hex"";
                }
                return _output.slice(_at + 4, 20);
            //p2sh
            } else if (_tag == hex"17a914") {
                // Check for maliciously formatted p2sh
                // No need to worry about underflow, b/c of _scriptLen check
                if (uint8(_output[_at + _len - 1]) != 0x87) {
                    return hex"";
                }
                return _output.slice(_at + 3, 20);
            }
        }
        return hex"";  /* NB: will trigger on OPRETURN and any non-standard that doesn't overrun */
    }

    /* ********** */
    /* Witness TX */
    /* ********** */


    /// @notice      Checks that the vin passed up is properly formatted
    /// @dev         Consider a vin with a valid vout in its scriptsig
    /// @param _vin  Raw bytes length-prefixed input vector
    /// @return      True if it represents a validly formatted vin
    function validateVin(bytes memory _vin) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nIns;

        (_varIntDataLen, _nIns) = parseVarInt(_vin);

        // Not valid if it says there are too many or no inputs
        if (_nIns == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nIns; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vin.length) {
                return false;
            }

            // Grab the next input and determine its length.
            uint256 _nextLen = determineInputLengthAt(_vin, _offset);
            if (_nextLen == ERR_BAD_ARG) {
                return false;
            }

            // Increase the offset by that much
            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vin.length;
    }

    /// @notice      Checks that the vout passed up is properly formatted
    /// @dev         Consider a vout with a valid scriptpubkey
    /// @param _vout Raw bytes length-prefixed output vector
    /// @return      True if it represents a validly formatted vout
    function validateVout(bytes memory _vout) internal pure returns (bool) {
        uint256 _varIntDataLen;
        uint256 _nOuts;

        (_varIntDataLen, _nOuts) = parseVarInt(_vout);

        // Not valid if it says there are too many or no outputs
        if (_nOuts == 0 || _varIntDataLen == ERR_BAD_ARG) {
            return false;
        }

        uint256 _offset = 1 + _varIntDataLen;

        for (uint256 i = 0; i < _nOuts; i++) {
            // If we're at the end, but still expect more
            if (_offset >= _vout.length) {
                return false;
            }

            // Grab the next output and determine its length.
            // Increase the offset by that much
            uint256 _nextLen = determineOutputLengthAt(_vout, _offset);
            if (_nextLen == ERR_BAD_ARG) {
                return false;
            }

            _offset += _nextLen;
        }

        // Returns false if we're not exactly at the end
        return _offset == _vout.length;
    }



    /* ************ */
    /* Block Header */
    /* ************ */

    /// @notice          Extracts the transaction merkle root from a block header
    /// @dev             Use verifyHash256Merkle to verify proofs with this root
    /// @param _header   The header
    /// @return          The merkle root (little-endian)
    function extractMerkleRootLE(bytes memory _header) internal pure returns (bytes32) {
        return _header.slice32(36);
    }

    /// @notice          Extracts the target from a block header
    /// @dev             Target is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _header   The header
    /// @return          The target threshold
    function extractTarget(bytes memory _header) internal pure returns (uint256) {
        return extractTargetAt(_header, 0);
    }

    /// @notice          Extracts the target from a block header
    /// @dev             Target is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _header   The array containing the header
    /// @param at        The start of the header
    /// @return          The target threshold
    function extractTargetAt(bytes memory _header, uint256 at) internal pure returns (uint256) {
        uint24 _m = uint24(_header.slice3(72 + at));
        uint8 _e = uint8(_header[75 + at]);
        uint256 _mantissa = uint256(reverseUint24(_m));
        uint _exponent = _e - 3;

        return _mantissa * (256 ** _exponent);
    }

    /// @notice          Calculate difficulty from the difficulty 1 target and current target
    /// @dev             Difficulty 1 is 0x1d00ffff on mainnet and testnet
    /// @dev             Difficulty 1 is a 256-bit number encoded as a 3-byte mantissa and 1-byte exponent
    /// @param _target   The current target
    /// @return          The block difficulty (bdiff)
    function calculateDifficulty(uint256 _target) internal pure returns (uint256) {
        // Difficulty 1 calculated from 0x1d00ffff
        return DIFF1_TARGET.div(_target);
    }

    /// @notice          Extracts the previous block's hash from a block header
    /// @dev             Block headers do NOT include block number :(
    /// @param _header   The header
    /// @return          The previous block's hash (little-endian)
    function extractPrevBlockLE(bytes memory _header) internal pure returns (bytes32) {
        return _header.slice32(4);
    }

    /// @notice          Extracts the previous block's hash from a block header
    /// @dev             Block headers do NOT include block number :(
    /// @param _header   The array containing the header
    /// @param at        The start of the header
    /// @return          The previous block's hash (little-endian)
    function extractPrevBlockLEAt(
        bytes memory _header,
        uint256 at
    ) internal pure returns (bytes32) {
        return _header.slice32(4 + at);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (little-endian bytes)
    function extractTimestampLE(bytes memory _header) internal pure returns (bytes4) {
        return _header.slice4(68);
    }

    /// @notice          Extracts the timestamp from a block header
    /// @dev             Time is not 100% reliable
    /// @param _header   The header
    /// @return          The timestamp (uint)
    function extractTimestamp(bytes memory _header) internal pure returns (uint32) {
        return reverseUint32(uint32(extractTimestampLE(_header)));
    }

    /// @notice          Extracts the expected difficulty from a block header
    /// @dev             Does NOT verify the work
    /// @param _header   The header
    /// @return          The difficulty as an integer
    function extractDifficulty(bytes memory _header) internal pure returns (uint256) {
        return calculateDifficulty(extractTarget(_header));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _hash256MerkleStep(bytes memory _a, bytes memory _b) internal view returns (bytes32) {
        return hash256View(abi.encodePacked(_a, _b));
    }

    /// @notice          Concatenates and hashes two inputs for merkle proving
    /// @param _a        The first hash
    /// @param _b        The second hash
    /// @return          The double-sha256 of the concatenated hashes
    function _hash256MerkleStep(bytes32 _a, bytes32 _b) internal view returns (bytes32) {
        return hash256Pair(_a, _b);
    }


    /// @notice          Verifies a Bitcoin-style merkle tree
    /// @dev             Leaves are 0-indexed. Inefficient version.
    /// @param _proof    The proof. Tightly packed LE sha256 hashes. The last hash is the root
    /// @param _index    The index of the leaf
    /// @return          true if the proof is valid, else false
    function verifyHash256Merkle(bytes memory _proof, uint _index) internal view returns (bool) {
        // Not an even number of hashes
        if (_proof.length % 32 != 0) {
            return false;
        }

        // Special case for coinbase-only blocks
        if (_proof.length == 32) {
            return true;
        }

        // Should never occur
        if (_proof.length == 64) {
            return false;
        }

        bytes32 _root = _proof.slice32(_proof.length - 32);
        bytes32 _current = _proof.slice32(0);
        bytes memory _tree = _proof.slice(32, _proof.length - 64);

        return verifyHash256Merkle(_current, _tree, _root, _index);
    }

    /// @notice          Verifies a Bitcoin-style merkle tree
    /// @dev             Leaves are 0-indexed. Efficient version.
    /// @param _leaf     The leaf of the proof. LE sha256 hash.
    /// @param _tree     The intermediate nodes in the proof.
    ///                  Tightly packed LE sha256 hashes.
    /// @param _root     The root of the proof. LE sha256 hash.
    /// @param _index    The index of the leaf
    /// @return          true if the proof is valid, else false
    function verifyHash256Merkle(
        bytes32 _leaf,
        bytes memory _tree,
        bytes32 _root,
        uint _index
    ) internal view returns (bool) {
        // Not an even number of hashes
        if (_tree.length % 32 != 0) {
            return false;
        }

        // Should never occur
        if (_tree.length == 0) {
            return false;
        }

        uint _idx = _index;
        bytes32 _current = _leaf;

        // i moves in increments of 32
        for (uint i = 0; i < _tree.length; i += 32) {
            if (_idx % 2 == 1) {
                _current = _hash256MerkleStep(_tree.slice32(i), _current);
            } else {
                _current = _hash256MerkleStep(_current, _tree.slice32(i));
            }
            _idx = _idx >> 1;
        }
        return _current == _root;
    }

    /*
    NB: https://github.com/bitcoin/bitcoin/blob/78dae8caccd82cfbfd76557f1fb7d7557c7b5edb/src/pow.cpp#L49-L72
    NB: We get a full-bitlength target from this. For comparison with
        header-encoded targets we need to mask it with the header target
        e.g. (full & truncated) == truncated
    */
    /// @notice                 performs the bitcoin difficulty retarget
    /// @dev                    implements the Bitcoin algorithm precisely
    /// @param _previousTarget  the target of the previous period
    /// @param _firstTimestamp  the timestamp of the first block in the difficulty period
    /// @param _secondTimestamp the timestamp of the last block in the difficulty period
    /// @return                 the new period's target threshold
    function retargetAlgorithm(
        uint256 _previousTarget,
        uint256 _firstTimestamp,
        uint256 _secondTimestamp
    ) internal pure returns (uint256) {
        uint256 _elapsedTime = _secondTimestamp.sub(_firstTimestamp);

        // Normalize ratio to factor of 4 if very long or very short
        if (_elapsedTime < RETARGET_PERIOD.div(4)) {
            _elapsedTime = RETARGET_PERIOD.div(4);
        }
        if (_elapsedTime > RETARGET_PERIOD.mul(4)) {
            _elapsedTime = RETARGET_PERIOD.mul(4);
        }

        /*
          NB: high targets e.g. ffff0020 can cause overflows here
              so we divide it by 256**2, then multiply by 256**2 later
              we know the target is evenly divisible by 256**2, so this isn't an issue
        */

        uint256 _adjusted = _previousTarget.div(65536).mul(_elapsedTime);
        return _adjusted.div(RETARGET_PERIOD).mul(65536);
    }
}

pragma solidity ^0.8.4;

/*

https://github.com/GNSPS/solidity-bytes-utils/

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <https://unlicense.org>
*/


/** @title BytesLib **/
/** @author https://github.com/GNSPS **/

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bytes memory) {
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

    function slice(bytes memory _bytes, uint _start, uint _length) internal  pure returns (bytes memory res) {
        if (_length == 0) {
            return hex"";
        }
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            // Alloc bytes array with additional 32 bytes afterspace and assign it's size
            res := mload(0x40)
            mstore(0x40, add(add(res, 64), _length))
            mstore(res, _length)

            // Compute distance between source and destination pointers
            let diff := sub(res, add(_bytes, _start))

            for {
                let src := add(add(_bytes, 32), _start)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
            } {
                mstore(add(src, diff), mload(src))
            }
        }
    }

    /// @notice Take a slice of the byte array, overwriting the destination.
    /// The length of the slice will equal the length of the destination array.
    /// @dev Make sure the destination array has afterspace if required.
    /// @param _bytes The source array
    /// @param _dest The destination array.
    /// @param _start The location to start in the source array.
    function sliceInPlace(
        bytes memory _bytes,
        bytes memory _dest,
        uint _start
    ) internal pure {
        uint _length = _dest.length;
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            for {
                let src := add(add(_bytes, 32), _start)
                let res := add(_dest, 32)
                let end := add(src, _length)
            } lt(src, end) {
                src := add(src, 32)
                res := add(res, 32)
            } {
                mstore(res, mload(src))
            }
        }
    }

    // Static slice functions, no bounds checking
    /// @notice take a 32-byte slice from the specified position
    function slice32(bytes memory _bytes, uint _start) internal pure returns (bytes32 res) {
        assembly {
            res := mload(add(add(_bytes, 32), _start))
        }
    }

    /// @notice take a 20-byte slice from the specified position
    function slice20(bytes memory _bytes, uint _start) internal pure returns (bytes20) {
        return bytes20(slice32(_bytes, _start));
    }

    /// @notice take a 8-byte slice from the specified position
    function slice8(bytes memory _bytes, uint _start) internal pure returns (bytes8) {
        return bytes8(slice32(_bytes, _start));
    }

    /// @notice take a 4-byte slice from the specified position
    function slice4(bytes memory _bytes, uint _start) internal pure returns (bytes4) {
        return bytes4(slice32(_bytes, _start));
    }

    /// @notice take a 3-byte slice from the specified position
    function slice3(bytes memory _bytes, uint _start) internal pure returns (bytes3) {
        return bytes3(slice32(_bytes, _start));
    }

    /// @notice take a 2-byte slice from the specified position
    function slice2(bytes memory _bytes, uint _start) internal pure returns (bytes2) {
        return bytes2(slice32(_bytes, _start));
    }

    function toAddress(bytes memory _bytes, uint _start) internal  pure returns (address) {
        uint _totalLen = _start + 20;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Address conversion out of bounds.");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint(bytes memory _bytes, uint _start) internal  pure returns (uint256) {
        uint _totalLen = _start + 32;
        require(_totalLen > _start && _bytes.length >= _totalLen, "Uint conversion out of bounds.");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
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
                    // while(uint(mc < end) + cb == 2)
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

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes) internal view returns (bool) {
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
                        // while(uint(mc < end) + cb == 2)
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

    function toBytes32(bytes memory _source) pure internal returns (bytes32 result) {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(bytes memory _bytes, uint _start, uint _length) pure internal returns (bytes32 result) {
        uint _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

pragma solidity ^0.8.4;

/*
The MIT License (MIT)

Copyright (c) 2016 Smart Contract Solutions, Inc.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        require(c / _a == _b, "Overflow during multiplication.");
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // assert(_b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = _a / _b;
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
        return _a / _b;
    }

    /**
     * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a, "Underflow during subtraction.");
        return _a - _b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        require(c >= _a, "Overflow during addition.");
        return c;
    }
}

pragma solidity ^0.8.4;

/** @title ValidateSPV*/
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {SafeMath} from "./SafeMath.sol";
import {BTCUtils} from "./BTCUtils.sol";


library ValidateSPV {

    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using BytesLib for bytes;
    using SafeMath for uint256;

    enum InputTypes { NONE, LEGACY, COMPATIBILITY, WITNESS }
    enum OutputTypes { NONE, WPKH, WSH, OP_RETURN, PKH, SH, NONSTANDARD }

    uint256 constant ERR_BAD_LENGTH = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint256 constant ERR_INVALID_CHAIN = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe;
    uint256 constant ERR_LOW_WORK = 0xfffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffd;

    function getErrBadLength() internal pure returns (uint256) {
        return ERR_BAD_LENGTH;
    }

    function getErrInvalidChain() internal pure returns (uint256) {
        return ERR_INVALID_CHAIN;
    }

    function getErrLowWork() internal pure returns (uint256) {
        return ERR_LOW_WORK;
    }

    /// @notice                     Validates a tx inclusion in the block
    /// @dev                        `index` is not a reliable indicator of location within a block
    /// @param _txid                The txid (LE)
    /// @param _merkleRoot          The merkle root (as in the block header)
    /// @param _intermediateNodes   The proof's intermediate nodes (digests between leaf and root)
    /// @param _index               The leaf's index in the tree (0-indexed)
    /// @return                     true if fully valid, false otherwise
    function prove(
        bytes32 _txid,
        bytes32 _merkleRoot,
        bytes memory _intermediateNodes,
        uint _index
    ) internal view returns (bool) {
        // Shortcut the empty-block case
        if (_txid == _merkleRoot && _index == 0 && _intermediateNodes.length == 0) {
            return true;
        }

        // If the Merkle proof failed, bubble up error
        return BTCUtils.verifyHash256Merkle(
            _txid,
            _intermediateNodes,
            _merkleRoot,
            _index
        );
    }

    /// @notice             Hashes transaction to get txid
    /// @dev                Supports Legacy and Witness
    /// @param _version     4-bytes version
    /// @param _vin         Raw bytes length-prefixed input vector
    /// @param _vout        Raw bytes length-prefixed output vector
    /// @param _locktime    4-byte tx locktime
    /// @return             32-byte transaction id, little endian
    function calculateTxId(
        bytes4 _version,
        bytes memory _vin,
        bytes memory _vout,
        bytes4 _locktime
    ) internal view returns (bytes32) {
        // Get transaction hash double-Sha256(version + nIns + inputs + nOuts + outputs + locktime)
        return abi.encodePacked(_version, _vin, _vout, _locktime).hash256View();
    }

    /// @notice                  Checks validity of header chain
    /// @notice                  Compares the hash of each header to the prevHash in the next header
    /// @param headers           Raw byte array of header chain
    /// @return totalDifficulty  The total accumulated difficulty of the header chain, or an error code
    function validateHeaderChain(
        bytes memory headers
    ) internal view returns (uint256 totalDifficulty) {

        // Check header chain length
        if (headers.length % 80 != 0) {return ERR_BAD_LENGTH;}

        // Initialize header start index
        bytes32 digest;

        totalDifficulty = 0;

        for (uint256 start = 0; start < headers.length; start += 80) {

            // After the first header, check that headers are in a chain
            if (start != 0) {
                if (!validateHeaderPrevHash(headers, start, digest)) {return ERR_INVALID_CHAIN;}
            }

            // ith header target
            uint256 target = headers.extractTargetAt(start);

            // Require that the header has sufficient work
            digest = headers.hash256Slice(start, 80);
            if(uint256(digest).reverseUint256() > target) {
                return ERR_LOW_WORK;
            }

            // Add ith header difficulty to difficulty sum
            totalDifficulty = totalDifficulty + target.calculateDifficulty();
        }
    }

    /// @notice             Checks validity of header work
    /// @param digest       Header digest
    /// @param target       The target threshold
    /// @return             true if header work is valid, false otherwise
    function validateHeaderWork(
        bytes32 digest,
        uint256 target
    ) internal pure returns (bool) {
        if (digest == bytes32(0)) {return false;}
        return (uint256(digest).reverseUint256() < target);
    }

    /// @notice                     Checks validity of header chain
    /// @dev                        Compares current header prevHash to previous header's digest
    /// @param headers              The raw bytes array containing the header
    /// @param at                   The position of the header
    /// @param prevHeaderDigest     The previous header's digest
    /// @return                     true if the connect is valid, false otherwise
    function validateHeaderPrevHash(
        bytes memory headers,
        uint256 at,
        bytes32 prevHeaderDigest
    ) internal pure returns (bool) {

        // Extract prevHash of current header
        bytes32 prevHash = headers.extractPrevBlockLEAt(at);

        // Compare prevHash of current header to previous header's digest
        if (prevHash != prevHeaderDigest) {return false;}

        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-3.0-only

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.17;

/// @title Interface for the Bitcoin relay
/// @notice Contains only the methods needed by tBTC v2. The Bitcoin relay
///         provides the difficulty of the previous and current epoch. One
///         difficulty epoch spans 2016 blocks.
interface IRelay {
    /// @notice Returns the difficulty of the current epoch.
    function getCurrentEpochDifficulty() external view returns (uint256);

    /// @notice Returns the difficulty of the previous epoch.
    function getPrevEpochDifficulty() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only

// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
// ██████████████     ▐████▌     ██████████████
// ██████████████     ▐████▌     ██████████████
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌
//               ▐████▌    ▐████▌

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

import {BytesLib} from "@keep-network/bitcoin-spv-sol/contracts/BytesLib.sol";
import {BTCUtils} from "@keep-network/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {ValidateSPV} from "@keep-network/bitcoin-spv-sol/contracts/ValidateSPV.sol";

import "../bridge/IRelay.sol";

struct Epoch {
    uint32 timestamp;
    // By definition, bitcoin targets have at least 32 leading zero bits.
    // Thus we can only store the bits that aren't guaranteed to be 0.
    uint224 target;
}

interface ILightRelay is IRelay {
    event Genesis(uint256 blockHeight);
    event Retarget(uint256 oldDifficulty, uint256 newDifficulty);
    event ProofLengthChanged(uint256 newLength);
    event AuthorizationRequirementChanged(bool newStatus);
    event SubmitterAuthorized(address submitter);
    event SubmitterDeauthorized(address submitter);

    function retarget(bytes memory headers) external;

    function validateChain(bytes memory headers)
        external
        view
        returns (uint256 startingHeaderTimestamp, uint256 headerCount);

    function getBlockDifficulty(uint256 blockNumber)
        external
        view
        returns (uint256);

    function getEpochDifficulty(uint256 epochNumber)
        external
        view
        returns (uint256);

    function getRelayRange()
        external
        view
        returns (uint256 relayGenesis, uint256 currentEpochEnd);
}

library RelayUtils {
    using BytesLib for bytes;

    /// @notice Extract the timestamp of the header at the given position.
    /// @param headers Byte array containing the header of interest.
    /// @param at The start of the header in the array.
    /// @return The timestamp of the header.
    /// @dev Assumes that the specified position contains a valid header.
    /// Performs no validation whatsoever.
    function extractTimestampAt(bytes memory headers, uint256 at)
        internal
        pure
        returns (uint32)
    {
        return BTCUtils.reverseUint32(uint32(headers.slice4(68 + at)));
    }
}

/// @dev THE RELAY MUST NOT BE USED BEFORE GENESIS AND AT LEAST ONE RETARGET.
contract LightRelay is Ownable, ILightRelay {
    using BytesLib for bytes;
    using BTCUtils for bytes;
    using ValidateSPV for bytes;
    using RelayUtils for bytes;

    bool public ready;
    // Whether the relay requires the address submitting a retarget to be
    // authorised in advance by governance.
    bool public authorizationRequired;
    // Number of blocks required for each side of a retarget proof:
    // a retarget must provide `proofLength` blocks before the retarget
    // and `proofLength` blocks after it.
    // Governable
    // Should be set to a fairly high number (e.g. 20-50) in production.
    uint64 public proofLength;
    // The number of the first epoch recorded by the relay.
    // This should equal the height of the block starting the genesis epoch,
    // divided by 2016, but this is not enforced as the relay has no
    // information about block numbers.
    uint64 public genesisEpoch;
    // The number of the latest epoch whose difficulty is proven to the relay.
    // If the genesis epoch's number is set correctly, and retargets along the
    // way have been legitimate, this equals the height of the block starting
    // the most recent epoch, divided by 2016.
    uint64 public currentEpoch;

    uint256 internal currentEpochDifficulty;
    uint256 internal prevEpochDifficulty;

    // Each epoch from genesis to the current one, keyed by their numbers.
    mapping(uint256 => Epoch) internal epochs;

    mapping(address => bool) public isAuthorized;

    modifier relayActive() {
        require(ready, "Relay is not ready for use");
        _;
    }

    /// @notice Establish a starting point for the relay by providing the
    /// target, timestamp and blockheight of the first block of the relay
    /// genesis epoch.
    /// @param genesisHeader The first block header of the genesis epoch.
    /// @param genesisHeight The block number of the first block of the epoch.
    /// @param genesisProofLength The number of blocks required to accept a
    /// proof.
    /// @dev If the relay is used by querying the current and previous epoch
    /// difficulty, at least one retarget needs to be provided after genesis;
    /// otherwise the prevEpochDifficulty will be uninitialised and zero.
    function genesis(
        bytes calldata genesisHeader,
        uint256 genesisHeight,
        uint64 genesisProofLength
    ) external onlyOwner {
        require(!ready, "Genesis already performed");

        require(genesisHeader.length == 80, "Invalid genesis header length");

        require(
            genesisHeight % 2016 == 0,
            "Invalid height of relay genesis block"
        );

        require(genesisProofLength < 2016, "Proof length excessive");
        require(genesisProofLength > 0, "Proof length may not be zero");

        genesisEpoch = uint64(genesisHeight / 2016);
        currentEpoch = genesisEpoch;
        uint256 genesisTarget = genesisHeader.extractTarget();
        uint256 genesisTimestamp = genesisHeader.extractTimestamp();
        epochs[genesisEpoch] = Epoch(
            uint32(genesisTimestamp),
            uint224(genesisTarget)
        );
        proofLength = genesisProofLength;
        currentEpochDifficulty = BTCUtils.calculateDifficulty(genesisTarget);
        ready = true;

        emit Genesis(genesisHeight);
    }

    /// @notice Set the number of blocks required to accept a header chain.
    /// @param newLength The required number of blocks. Must be less than 2016.
    /// @dev For production, a high number (e.g. 20-50) is recommended.
    /// Small numbers are accepted but should only be used for testing.
    function setProofLength(uint64 newLength) external relayActive onlyOwner {
        require(newLength < 2016, "Proof length excessive");
        require(newLength > 0, "Proof length may not be zero");
        require(newLength != proofLength, "Proof length unchanged");
        proofLength = newLength;
        emit ProofLengthChanged(newLength);
    }

    /// @notice Set whether the relay requires retarget submitters to be
    /// pre-authorised by governance.
    /// @param status True if authorisation is to be required, false if not.
    function setAuthorizationStatus(bool status) external onlyOwner {
        authorizationRequired = status;
        emit AuthorizationRequirementChanged(status);
    }

    /// @notice Authorise the given address to submit retarget proofs.
    /// @param submitter The address to be authorised.
    function authorize(address submitter) external onlyOwner {
        isAuthorized[submitter] = true;
        emit SubmitterAuthorized(submitter);
    }

    /// @notice Rescind the authorisation of the submitter to retarget.
    /// @param submitter The address to be deauthorised.
    function deauthorize(address submitter) external onlyOwner {
        isAuthorized[submitter] = false;
        emit SubmitterDeauthorized(submitter);
    }

    /// @notice Add a new epoch to the relay by providing a proof
    /// of the difficulty before and after the retarget.
    /// @param headers A chain of headers including the last X blocks before
    /// the retarget, followed by the first X blocks after the retarget,
    /// where X equals the current proof length.
    /// @dev Checks that the first X blocks are valid in the most recent epoch,
    /// that the difficulty of the new epoch is calculated correctly according
    /// to the block timestamps, and that the next X blocks would be valid in
    /// the new epoch.
    /// We have no information of block heights, so we cannot enforce that
    /// retargets only happen every 2016 blocks; instead, we assume that this
    /// is the case if a valid proof of work is provided.
    /// It is possible to cheat the relay by providing X blocks from earlier in
    /// the most recent epoch, and then mining X new blocks after them.
    /// However, each of these malicious blocks would have to be mined to a
    /// higher difficulty than the legitimate ones.
    /// Alternatively, if the retarget has not been performed yet, one could
    /// first mine X blocks in the old difficulty with timestamps set far in
    /// the future, and then another X blocks at a greatly reduced difficulty.
    /// In either case, cheating the realy requires more work than mining X
    /// legitimate blocks.
    /// Only the most recent epoch is vulnerable to these attacks; once a
    /// retarget has been proven to the relay, the epoch is immutable even if a
    /// contradictory proof were to be presented later.
    function retarget(bytes memory headers) external relayActive {
        if (authorizationRequired) {
            require(isAuthorized[msg.sender], "Submitter unauthorized");
        }

        require(
            // Require proofLength headers on both sides of the retarget
            headers.length == (proofLength * 2 * 80),
            "Invalid header length"
        );

        Epoch storage latest = epochs[currentEpoch];

        uint256 oldTarget = latest.target;

        bytes32 previousHeaderDigest = bytes32(0);

        // Validate old chain
        for (uint256 i = 0; i < proofLength; i++) {
            (
                bytes32 currentDigest,
                uint256 currentHeaderTarget
            ) = validateHeader(headers, i * 80, previousHeaderDigest);

            require(
                currentHeaderTarget == oldTarget,
                "Invalid target in pre-retarget headers"
            );

            previousHeaderDigest = currentDigest;
        }

        // get timestamp of retarget block
        uint256 epochEndTimestamp = headers.extractTimestampAt(
            (proofLength - 1) * 80
        );

        // An attacker could produce blocks with timestamps in the future,
        // in an attempt to reduce the difficulty after the retarget
        // to make mining the second part of the retarget proof easier.
        // In particular, the attacker could reuse all but one block
        // from the legitimate chain, and only mine the last block.
        // To hinder this, require that the epoch end timestamp does not
        // exceed the ethereum timestamp.
        // NOTE: both are unix seconds, so this comparison should be valid.
        require(
            /* solhint-disable-next-line not-rely-on-time */
            epochEndTimestamp < block.timestamp,
            "Epoch cannot end in the future"
        );

        // Expected target is the full-length target
        uint256 expectedTarget = BTCUtils.retargetAlgorithm(
            oldTarget,
            latest.timestamp,
            epochEndTimestamp
        );

        // Mined target is the header-encoded target
        uint256 minedTarget = 0;

        uint256 epochStartTimestamp = headers.extractTimestampAt(
            proofLength * 80
        );

        // validate new chain
        for (uint256 j = proofLength; j < proofLength * 2; j++) {
            (
                bytes32 _currentDigest,
                uint256 _currentHeaderTarget
            ) = validateHeader(headers, j * 80, previousHeaderDigest);

            if (minedTarget == 0) {
                // The new target has not been set, so check its correctness
                minedTarget = _currentHeaderTarget;
                require(
                    // Although the target is a 256-bit number, there are only 32 bits of
                    // space in the Bitcoin header. Because of that, the version stored in
                    // the header is a less-precise representation of the actual target
                    // using base-256 version of scientific notation.
                    //
                    // The 256-bit unsigned integer returned from BTCUtils.retargetAlgorithm
                    // is the precise target value.
                    // The 256-bit unsigned integer returned from validateHeader is the less
                    // precise target value because it was read from 32 bits of space of
                    // Bitcoin block header.
                    //
                    // We can't compare the precise and less precise representations together
                    // so we first mask them to obtain the less precise version:
                    //   (full & truncated) == truncated
                    _currentHeaderTarget ==
                        (expectedTarget & _currentHeaderTarget),
                    "Invalid target in new epoch"
                );
            } else {
                // The new target has been set, so remaining targets should match.
                require(
                    _currentHeaderTarget == minedTarget,
                    "Unexpected target change after retarget"
                );
            }

            previousHeaderDigest = _currentDigest;
        }

        currentEpoch = currentEpoch + 1;

        epochs[currentEpoch] = Epoch(
            uint32(epochStartTimestamp),
            uint224(minedTarget)
        );

        uint256 oldDifficulty = currentEpochDifficulty;
        uint256 newDifficulty = BTCUtils.calculateDifficulty(minedTarget);

        prevEpochDifficulty = oldDifficulty;
        currentEpochDifficulty = newDifficulty;

        emit Retarget(oldDifficulty, newDifficulty);
    }

    /// @notice Check whether a given chain of headers should be accepted as
    /// valid within the rules of the relay.
    /// If the validation fails, this function throws an exception.
    /// @param headers A chain of 2 to 2015 bitcoin headers.
    /// @return startingHeaderTimestamp The timestamp of the first header.
    /// @return headerCount The number of headers.
    /// @dev A chain of headers is accepted as valid if:
    /// - Its length is between 2 and 2015 headers.
    /// - Headers in the chain are sequential and refer to previous digests.
    /// - Each header is mined with the correct amount of work.
    /// - The difficulty in each header matches an epoch of the relay,
    ///   as determined by the headers' timestamps. The headers must be between
    ///   the genesis epoch and the latest proven epoch (inclusive).
    /// If the chain contains a retarget, it is accepted if the retarget has
    /// already been proven to the relay.
    /// If the chain contains blocks of an epoch that has not been proven to
    /// the relay (after a retarget within the header chain, or when the entire
    /// chain falls within an epoch that has not been proven yet), it will be
    /// rejected.
    /// One exception to this is when two subsequent epochs have exactly the
    /// same difficulty; headers from the latter epoch will be accepted if the
    /// previous epoch has been proven to the relay.
    /// This is because it is not possible to distinguish such headers from
    /// headers of the previous epoch.
    ///
    /// If the difficulty increases significantly between relay genesis and the
    /// present, creating fraudulent proofs for earlier epochs becomes easier.
    /// Users of the relay should check the timestamps of valid headers and
    /// only accept appropriately recent ones.
    function validateChain(bytes memory headers)
        external
        view
        returns (uint256 startingHeaderTimestamp, uint256 headerCount)
    {
        require(headers.length % 80 == 0, "Invalid header length");

        headerCount = headers.length / 80;

        require(
            headerCount > 1 && headerCount < 2016,
            "Invalid number of headers"
        );

        startingHeaderTimestamp = headers.extractTimestamp();

        // Short-circuit the first header's validation.
        // We validate the header here to get the target which is needed to
        // precisely identify the epoch.
        (
            bytes32 previousHeaderDigest,
            uint256 currentHeaderTarget
        ) = validateHeader(headers, 0, bytes32(0));

        Epoch memory nullEpoch = Epoch(0, 0);

        uint256 startingEpochNumber = currentEpoch;
        Epoch memory startingEpoch = epochs[startingEpochNumber];
        Epoch memory nextEpoch = nullEpoch;

        // Find the correct epoch for the given chain
        // Fastest with recent epochs, but able to handle anything after genesis
        //
        // The rules for bitcoin timestamps are:
        // - must be greater than the median of the last 11 blocks' timestamps
        // - must be less than the network-adjusted time +2 hours
        //
        // Because of this, the timestamp of a header may be smaller than the
        // starting time, or greater than the ending time of its epoch.
        // However, a valid timestamp is guaranteed to fall within the window
        // formed by the epochs immediately before and after its timestamp.
        // We can identify cases like these by comparing the targets.
        while (startingHeaderTimestamp < startingEpoch.timestamp) {
            startingEpochNumber -= 1;
            nextEpoch = startingEpoch;
            startingEpoch = epochs[startingEpochNumber];
        }

        // We have identified the centre of the window,
        // by reaching the most recent epoch whose starting timestamp
        // or reached before the genesis where epoch slots are empty.
        // Therefore check that the timestamp is nonzero.
        require(
            startingEpoch.timestamp > 0,
            "Cannot validate chains before relay genesis"
        );

        // The targets don't match. This could be because the block is invalid,
        // or it could be because of timestamp inaccuracy.
        // To cover the latter case, check adjacent epochs.
        if (currentHeaderTarget != startingEpoch.target) {
            // The target matches the next epoch.
            // This means we are right at the beginning of the next epoch,
            // and retargets during the chain should not be possible.
            if (currentHeaderTarget == nextEpoch.target) {
                startingEpoch = nextEpoch;
                nextEpoch = nullEpoch;
            }
            // The target doesn't match the next epoch.
            // Therefore the only valid epoch is the previous one.
            // Because the timestamp can't be more than 2 hours into the future
            // we must be right near the end of the epoch,
            // so a retarget is possible.
            else {
                startingEpochNumber -= 1;
                nextEpoch = startingEpoch;
                startingEpoch = epochs[startingEpochNumber];

                // We have failed to find a match,
                // therefore the target has to be invalid.
                require(
                    currentHeaderTarget == startingEpoch.target,
                    "Invalid target in header chain"
                );
            }
        }

        // We've found the correct epoch for the first header.
        // Validate the rest.
        for (uint256 i = 1; i < headerCount; i++) {
            bytes32 currentDigest;
            (currentDigest, currentHeaderTarget) = validateHeader(
                headers,
                i * 80,
                previousHeaderDigest
            );

            // If the header's target does not match the expected target,
            // check if a retarget is possible.
            //
            // If next epoch timestamp exists, a valid retarget is possible
            // (if next epoch timestamp doesn't exist, either a retarget has
            // already happened in this chain, the relay needs a retarget
            // before this chain can be validated, or a retarget is not allowed
            // because we know the headers are within a timestamp irregularity
            // of the previous retarget).
            //
            // In this case the target must match the next epoch's target,
            // and the header's timestamp must match the epoch's start.
            if (currentHeaderTarget != startingEpoch.target) {
                uint256 currentHeaderTimestamp = headers.extractTimestampAt(
                    i * 80
                );

                require(
                    nextEpoch.timestamp != 0 &&
                        currentHeaderTarget == nextEpoch.target &&
                        currentHeaderTimestamp == nextEpoch.timestamp,
                    "Invalid target in header chain"
                );

                startingEpoch = nextEpoch;
                nextEpoch = nullEpoch;
            }

            previousHeaderDigest = currentDigest;
        }

        return (startingHeaderTimestamp, headerCount);
    }

    /// @notice Get the difficulty of the specified block.
    /// @param blockNumber The number of the block. Must fall within the relay
    /// range (at or after the relay genesis, and at or before the end of the
    /// most recent epoch proven to the relay).
    /// @return The difficulty of the epoch.
    function getBlockDifficulty(uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        return getEpochDifficulty(blockNumber / 2016);
    }

    /// @notice Get the range of blocks the relay can accept proofs for.
    /// @dev Assumes that the genesis has been set correctly.
    /// Additionally, if the next epoch after the current one has the exact
    /// same difficulty, headers for it can be validated as well.
    /// This function should be used for informative purposes,
    /// e.g. to determine whether a retarget must be provided before submitting
    /// a header chain for validation.
    /// @return relayGenesis The height of the earliest block that can be
    /// included in header chains for the relay to validate.
    /// @return currentEpochEnd The height of the last block that can be
    /// included in header chains for the relay to validate.
    function getRelayRange()
        external
        view
        returns (uint256 relayGenesis, uint256 currentEpochEnd)
    {
        relayGenesis = genesisEpoch * 2016;
        currentEpochEnd = (currentEpoch * 2016) + 2015;
    }

    /// @notice Returns the difficulty of the current epoch.
    /// @dev returns 0 if the relay is not ready.
    /// @return The difficulty of the current epoch.
    function getCurrentEpochDifficulty()
        external
        view
        virtual
        returns (uint256)
    {
        return currentEpochDifficulty;
    }

    /// @notice Returns the difficulty of the previous epoch.
    /// @dev Returns 0 if the relay is not ready or has not had a retarget.
    /// @return The difficulty of the previous epoch.
    function getPrevEpochDifficulty() external view virtual returns (uint256) {
        return prevEpochDifficulty;
    }

    function getCurrentAndPrevEpochDifficulty()
        external
        view
        returns (uint256 current, uint256 previous)
    {
        return (currentEpochDifficulty, prevEpochDifficulty);
    }

    /// @notice Get the difficulty of the specified epoch.
    /// @param epochNumber The number of the epoch (the height of the first
    /// block of the epoch, divided by 2016). Must fall within the relay range.
    /// @return The difficulty of the epoch.
    function getEpochDifficulty(uint256 epochNumber)
        public
        view
        returns (uint256)
    {
        require(epochNumber >= genesisEpoch, "Epoch is before relay genesis");
        require(
            epochNumber <= currentEpoch,
            "Epoch is not proven to the relay yet"
        );
        return BTCUtils.calculateDifficulty(epochs[epochNumber].target);
    }

    /// @notice Check that the specified header forms a correct chain with the
    /// digest of the previous header (if provided), and has sufficient work.
    /// @param headers The byte array containing the header of interest.
    /// @param start The start of the header in the array.
    /// @param prevDigest The digest of the previous header
    /// (optional; providing zeros for the digest skips the check).
    /// @return digest The digest of the current header.
    /// @return target The PoW target of the header.
    /// @dev Throws an exception if the header's chain or PoW are invalid.
    /// Performs no other validation.
    function validateHeader(
        bytes memory headers,
        uint256 start,
        bytes32 prevDigest
    ) internal view returns (bytes32 digest, uint256 target) {
        // If previous block digest has been provided, require that it matches
        if (prevDigest != bytes32(0)) {
            require(
                headers.validateHeaderPrevHash(start, prevDigest),
                "Invalid chain"
            );
        }

        // Require that the header has sufficient work for its stated target
        target = headers.extractTargetAt(start);
        digest = headers.hash256Slice(start, 80);
        require(ValidateSPV.validateHeaderWork(digest, target), "Invalid work");

        return (digest, target);
    }
}