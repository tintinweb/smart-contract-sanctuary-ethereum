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

/** @title CheckBitcoinSigs */
/** @author Summa (https://summa.one) */

import {BytesLib} from "./BytesLib.sol";
import {BTCUtils} from "./BTCUtils.sol";


library CheckBitcoinSigs {

    using BytesLib for bytes;
    using BTCUtils for bytes;

    /// @notice          Derives an Ethereum Account address from a pubkey
    /// @dev             The address is the last 20 bytes of the keccak256 of the address
    /// @param _pubkey   The public key X & Y. Unprefixed, as a 64-byte array
    /// @return          The account address
    function accountFromPubkey(bytes memory _pubkey) internal pure returns (address) {
        require(_pubkey.length == 64, "Pubkey must be 64-byte raw, uncompressed key.");

        // keccak hash of uncompressed unprefixed pubkey
        bytes32 _digest = keccak256(_pubkey);
        return address(uint160(uint256(_digest)));
    }

    /// @notice          Calculates the p2wpkh output script of a pubkey
    /// @dev             Compresses keys to 33 bytes as required by Bitcoin
    /// @param _pubkey   The public key, compressed or uncompressed
    /// @return          The p2wkph output script
    function p2wpkhFromPubkey(bytes memory _pubkey) internal view returns (bytes memory) {
        bytes memory _compressedPubkey;
        uint8 _prefix;

        if (_pubkey.length == 64) {
            _prefix = uint8(_pubkey[_pubkey.length - 1]) % 2 == 1 ? 3 : 2;
            _compressedPubkey = abi.encodePacked(_prefix, _pubkey.slice32(0));
        } else if (_pubkey.length == 65) {
            _prefix = uint8(_pubkey[_pubkey.length - 1]) % 2 == 1 ? 3 : 2;
            _compressedPubkey = abi.encodePacked(_prefix, _pubkey.slice32(1));
        } else {
            _compressedPubkey = _pubkey;
        }

        require(_compressedPubkey.length == 33, "Witness PKH requires compressed keys");

        bytes20 _pubkeyHash = _compressedPubkey.hash160View();
        return abi.encodePacked(hex"0014", _pubkeyHash);
    }

    /// @notice          checks a signed message's validity under a pubkey
    /// @dev             does this using ecrecover because Ethereum has no soul
    /// @param _pubkey   the public key to check (64 bytes)
    /// @param _digest   the message digest signed
    /// @param _v        the signature recovery value
    /// @param _r        the signature r value
    /// @param _s        the signature s value
    /// @return          true if signature is valid, else false
    function checkSig(
        bytes memory _pubkey,
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal pure returns (bool) {
        require(_pubkey.length == 64, "Requires uncompressed unprefixed pubkey");
        address _expected = accountFromPubkey(_pubkey);
        address _actual = ecrecover(_digest, _v, _r, _s);
        return _actual == _expected;
    }

    /// @notice                     checks a signed message against a bitcoin p2wpkh output script
    /// @dev                        does this my verifying the p2wpkh matches an ethereum account
    /// @param _p2wpkhOutputScript  the bitcoin output script
    /// @param _pubkey              the uncompressed, unprefixed public key to check
    /// @param _digest              the message digest signed
    /// @param _v                   the signature recovery value
    /// @param _r                   the signature r value
    /// @param _s                   the signature s value
    /// @return                     true if signature is valid, else false
    function checkBitcoinSig(
        bytes memory _p2wpkhOutputScript,
        bytes memory _pubkey,
        bytes32 _digest,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) internal view returns (bool) {
        require(_pubkey.length == 64, "Requires uncompressed unprefixed pubkey");

        bool _isExpectedSigner = keccak256(p2wpkhFromPubkey(_pubkey)) == keccak256(_p2wpkhOutputScript);  // is it the expected signer?
        if (!_isExpectedSigner) {return false;}

        bool _sigResult = checkSig(_pubkey, _digest, _v, _r, _s);
        return _sigResult;
    }

    /// @notice             checks if a message is the sha256 preimage of a digest
    /// @dev                this is NOT the hash256!  this step is necessary for ECDSA security!
    /// @param _digest      the digest
    /// @param _candidate   the purported preimage
    /// @return             true if the preimage matches the digest, else false
    function isSha256Preimage(
        bytes memory _candidate,
        bytes32 _digest
    ) internal pure returns (bool) {
        return sha256(_candidate) == _digest;
    }

    /// @notice             checks if a message is the keccak256 preimage of a digest
    /// @dev                this step is necessary for ECDSA security!
    /// @param _digest      the digest
    /// @param _candidate   the purported preimage
    /// @return             true if the preimage matches the digest, else false
    function isKeccak256Preimage(
        bytes memory _candidate,
        bytes32 _digest
    ) internal pure returns (bool) {
        return keccak256(_candidate) == _digest;
    }

    /// @notice                 calculates the signature hash of a Bitcoin transaction with the provided details
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin UTXO id (32-byte txid + 4-byte output index)
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputScript    the length-prefixed output script
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function wpkhSpendSighash(
        bytes memory _outpoint,  // 36-byte UTXO id
        bytes20 _inputPKH,       // 20-byte hash160
        bytes8 _inputValue,      // 8-byte LE
        bytes8 _outputValue,     // 8-byte LE
        bytes memory _outputScript    // lenght-prefixed output script
    ) internal view returns (bytes32) {
        // Fixes elements to easily make a 1-in 1-out sighash digest
        // Does not support timelocks
        // bytes memory _scriptCode = abi.encodePacked(
        //     hex"1976a914",  // length, dup, hash160, pkh_length
        //     _inputPKH,
        //     hex"88ac");  // equal, checksig

        bytes32 _hashOutputs = abi.encodePacked(
            _outputValue,  // 8-byte LE
            _outputScript).hash256View();

        bytes memory _sighashPreimage = abi.encodePacked(
            hex"01000000",  // version
            _outpoint.hash256View(),  // hashPrevouts
            hex"8cb9012517c817fead650287d61bdd9c68803b6bf9c64133dcab3e65b5a50cb9",  // hashSequence(00000000)
            _outpoint,  // outpoint
            // p2wpkh script code
            hex"1976a914",  // length, dup, hash160, pkh_length
            _inputPKH,
            hex"88ac",  // equal, checksig
            // end script code
            _inputValue,  // value of the input in 8-byte LE
            hex"00000000",  // input nSequence
            _hashOutputs,  // hash of the single output
            hex"00000000",  // nLockTime
            hex"01000000"  // SIGHASH_ALL
        );
        return _sighashPreimage.hash256View();
    }

    /// @notice                 calculates the signature hash of a Bitcoin transaction with the provided details
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin UTXO id (32-byte txid + 4-byte output index)
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputPKH       the output pubkeyhash (hash160(recipient_pubkey))
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function wpkhToWpkhSighash(
        bytes memory _outpoint,  // 36-byte UTXO id
        bytes20 _inputPKH,  // 20-byte hash160
        bytes8 _inputValue,  // 8-byte LE
        bytes8 _outputValue,  // 8-byte LE
        bytes20 _outputPKH  // 20-byte hash160
    ) internal view returns (bytes32) {
        return wpkhSpendSighash(
            _outpoint,
            _inputPKH,
            _inputValue,
            _outputValue,
            abi.encodePacked(
              hex"160014",  // wpkh tag
              _outputPKH)
            );
    }

    /// @notice                 Preserved for API compatibility with older version
    /// @dev                    documented in bip143. many values are hardcoded here
    /// @param _outpoint        the bitcoin UTXO id (32-byte txid + 4-byte output index)
    /// @param _inputPKH        the input pubkeyhash (hash160(sender_pubkey))
    /// @param _inputValue      the value of the input in satoshi
    /// @param _outputValue     the value of the output in satoshi
    /// @param _outputPKH       the output pubkeyhash (hash160(recipient_pubkey))
    /// @return                 the double-sha256 (hash256) signature hash as defined by bip143
    function oneInputOneOutputSighash(
        bytes memory _outpoint,  // 36-byte UTXO id
        bytes20 _inputPKH,  // 20-byte hash160
        bytes8 _inputValue,  // 8-byte LE
        bytes8 _outputValue,  // 8-byte LE
        bytes20 _outputPKH  // 20-byte hash160
    ) internal view returns (bytes32) {
        return wpkhToWpkhSighash(_outpoint, _inputPKH, _inputValue, _outputValue, _outputPKH);
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

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

interface IWalletOwner {
    /// @notice Callback function executed once a new wallet is created.
    /// @dev Should be callable only by the Wallet Registry.
    /// @param walletID Wallet's unique identifier.
    /// @param publicKeyY Wallet's public key's X coordinate.
    /// @param publicKeyY Wallet's public key's Y coordinate.
    function __ecdsaWalletCreatedCallback(
        bytes32 walletID,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) external;

    /// @notice Callback function executed once a wallet heartbeat failure
    ///         is detected.
    /// @dev Should be callable only by the Wallet Registry.
    /// @param walletID Wallet's unique identifier.
    /// @param publicKeyY Wallet's public key's X coordinate.
    /// @param publicKeyY Wallet's public key's Y coordinate.
    function __ecdsaWalletHeartbeatFailedCallback(
        bytes32 walletID,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "../libraries/EcdsaDkg.sol";

interface IWalletRegistry {
    /// @notice Requests a new wallet creation.
    /// @dev Only the Wallet Owner can call this function.
    function requestNewWallet() external;

    /// @notice Closes an existing wallet.
    /// @param walletID ID of the wallet.
    /// @dev Only the Wallet Owner can call this function.
    function closeWallet(bytes32 walletID) external;

    /// @notice Adds all signing group members of the wallet with the given ID
    ///         to the slashing queue of the staking contract. The notifier will
    ///         receive reward per each group member from the staking contract
    ///         notifiers treasury. The reward is scaled by the
    ///         `rewardMultiplier` provided as a parameter.
    /// @param amount Amount of tokens to seize from each signing group member
    /// @param rewardMultiplier Fraction of the staking contract notifiers
    ///        reward the notifier should receive; should be between [0, 100]
    /// @param notifier Address of the misbehavior notifier
    /// @param walletID ID of the wallet
    /// @param walletMembersIDs Identifiers of the wallet signing group members
    /// @dev Only the Wallet Owner can call this function.
    ///      Requirements:
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events.
    ///      - `rewardMultiplier` must be between [0, 100].
    ///      - This function does revert if staking contract call reverts.
    ///        The calling code needs to handle the potential revert.
    function seize(
        uint96 amount,
        uint256 rewardMultiplier,
        address notifier,
        bytes32 walletID,
        uint32[] calldata walletMembersIDs
    ) external;

    /// @notice Gets public key of a wallet with a given wallet ID.
    ///         The public key is returned in an uncompressed format as a 64-byte
    ///         concatenation of X and Y coordinates.
    /// @param walletID ID of the wallet.
    /// @return Uncompressed public key of the wallet.
    function getWalletPublicKey(bytes32 walletID)
        external
        view
        returns (bytes memory);

    /// @notice Check current wallet creation state.
    function getWalletCreationState() external view returns (EcdsaDkg.State);

    /// @notice Checks whether the given operator is a member of the given
    ///         wallet signing group.
    /// @param walletID ID of the wallet
    /// @param walletMembersIDs Identifiers of the wallet signing group members
    /// @param operator Address of the checked operator
    /// @param walletMemberIndex Position of the operator in the wallet signing
    ///        group members list
    /// @return True - if the operator is a member of the given wallet signing
    ///         group. False - otherwise.
    /// @dev Requirements:
    ///      - The `operator` parameter must be an actual sortition pool operator.
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events.
    ///      - The `walletMemberIndex` must be in range [1, walletMembersIDs.length]
    function isWalletMember(
        bytes32 walletID,
        uint32[] calldata walletMembersIDs,
        address operator,
        uint256 walletMemberIndex
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

// Initial version copied from Keep Network Random Beacon:
// https://github.com/keep-network/keep-core/blob/5138c7628868dbeed3ae2164f76fccc6c1fbb9e8/solidity/random-beacon/contracts/DKGValidator.sol
//
// With the following differences:
// - group public key length,
// - group size and related thresholds,
// - documentation.

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@keep-network/random-beacon/contracts/libraries/BytesLib.sol";
import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "./libraries/EcdsaDkg.sol";

/// @title DKG result validator
/// @notice EcdsaDkgValidator allows performing a full validation of DKG result,
///         including checking the format of fields in the result, declared
///         selected group members, and signatures of operators supporting the
///         result. The operator submitting the result should perform the
///         validation using a free contract call before submitting the result
///         to ensure their result is valid and can not be challenged. All other
///         network operators should perform validation of the submitted result
///         using a free contract call and challenge the result if the
///         validation fails.
contract EcdsaDkgValidator {
    using BytesLib for bytes;
    using ECDSA for bytes32;

    /// @dev Size of a group in DKG.
    uint256 public constant groupSize = 100;

    /// @dev The minimum number of group members needed to interact according to
    ///      the protocol to produce a signature. The adversary can not learn
    ///      anything about the key as long as it does not break into
    ///      groupThreshold+1 of members.
    uint256 public constant groupThreshold = 51;

    /// @dev The minimum number of active and properly behaving group members
    ///      during the DKG needed to accept the result. This number is higher
    ///      than `groupThreshold` to keep a safety margin for members becoming
    ///      inactive after DKG so that the group can still produce signature.
    uint256 public constant activeThreshold = 90; // 90% of groupSize

    /// @dev Size in bytes of a public key produced by group members during the
    /// the DKG. The length assumes uncompressed ECDSA public key.
    uint256 public constant publicKeyByteSize = 64;

    /// @dev Size in bytes of a single signature produced by operator supporting
    ///      DKG result.
    uint256 public constant signatureByteSize = 65;

    SortitionPool public immutable sortitionPool;

    constructor(SortitionPool _sortitionPool) {
        sortitionPool = _sortitionPool;
    }

    /// @notice Performs a full validation of DKG result, including checking the
    ///         format of fields in the result, declared selected group members,
    ///         and signatures of operators supporting the result.
    /// @param seed seed used to start the DKG and select group members
    /// @param startBlock DKG start block
    /// @return isValid true if the result is valid, false otherwise
    /// @return errorMsg validation error message; empty for a valid result
    function validate(
        EcdsaDkg.Result calldata result,
        uint256 seed,
        uint256 startBlock
    ) external view returns (bool isValid, string memory errorMsg) {
        (bool hasValidFields, string memory error) = validateFields(result);
        if (!hasValidFields) {
            return (false, error);
        }

        if (!validateSignatures(result, startBlock)) {
            return (false, "Invalid signatures");
        }

        if (!validateGroupMembers(result, seed)) {
            return (false, "Invalid group members");
        }

        // At this point all group members and misbehaved members were verified
        if (!validateMembersHash(result)) {
            return (false, "Invalid members hash");
        }

        return (true, "");
    }

    /// @notice Performs a static validation of DKG result fields: lengths,
    ///         ranges, and order of arrays.
    /// @return isValid true if the result is valid, false otherwise
    /// @return errorMsg validation error message; empty for a valid result
    function validateFields(EcdsaDkg.Result calldata result)
        public
        pure
        returns (bool isValid, string memory errorMsg)
    {
        if (result.groupPubKey.length != publicKeyByteSize) {
            return (false, "Malformed group public key");
        }

        // The number of misbehaved members can not exceed the threshold.
        // Misbehaved member indices needs to be unique, between [1, groupSize],
        // and sorted in ascending order.
        uint8[] calldata misbehavedMembersIndices = result
            .misbehavedMembersIndices;
        if (groupSize - misbehavedMembersIndices.length < activeThreshold) {
            return (false, "Too many members misbehaving during DKG");
        }
        if (misbehavedMembersIndices.length > 1) {
            if (
                misbehavedMembersIndices[0] < 1 ||
                misbehavedMembersIndices[misbehavedMembersIndices.length - 1] >
                groupSize
            ) {
                return (false, "Corrupted misbehaved members indices");
            }
            for (uint256 i = 1; i < misbehavedMembersIndices.length; i++) {
                if (
                    misbehavedMembersIndices[i - 1] >=
                    misbehavedMembersIndices[i]
                ) {
                    return (false, "Corrupted misbehaved members indices");
                }
            }
        }

        // Each signature needs to have a correct length and signatures need to
        // be provided.
        uint256 signaturesCount = result.signatures.length / signatureByteSize;
        if (result.signatures.length == 0) {
            return (false, "No signatures provided");
        }
        if (result.signatures.length % signatureByteSize != 0) {
            return (false, "Malformed signatures array");
        }

        // We expect the same amount of signatures as the number of declared
        // group member indices that signed the result.
        uint256[] calldata signingMembersIndices = result.signingMembersIndices;
        if (signaturesCount != signingMembersIndices.length) {
            return (false, "Unexpected signatures count");
        }
        if (signaturesCount < groupThreshold) {
            return (false, "Too few signatures");
        }
        if (signaturesCount > groupSize) {
            return (false, "Too many signatures");
        }

        // Signing member indices needs to be unique, between [1,groupSize],
        // and sorted in ascending order.
        if (
            signingMembersIndices[0] < 1 ||
            signingMembersIndices[signingMembersIndices.length - 1] > groupSize
        ) {
            return (false, "Corrupted signing member indices");
        }
        for (uint256 i = 1; i < signingMembersIndices.length; i++) {
            if (signingMembersIndices[i - 1] >= signingMembersIndices[i]) {
                return (false, "Corrupted signing member indices");
            }
        }

        return (true, "");
    }

    /// @notice Performs validation of group members as declared in DKG
    ///         result against group members selected by the sortition pool.
    /// @param seed seed used to start the DKG and select group members
    /// @return true if group members matches; false otherwise
    function validateGroupMembers(EcdsaDkg.Result calldata result, uint256 seed)
        public
        view
        returns (bool)
    {
        uint32[] calldata resultMembers = result.members;
        uint32[] memory actualGroupMembers = sortitionPool.selectGroup(
            groupSize,
            bytes32(seed)
        );
        if (resultMembers.length != actualGroupMembers.length) {
            return false;
        }
        for (uint256 i = 0; i < resultMembers.length; i++) {
            if (resultMembers[i] != actualGroupMembers[i]) {
                return false;
            }
        }
        return true;
    }

    /// @notice Performs validation of signatures supplied in DKG result.
    ///         Note that this function does not check if addresses which
    ///         supplied signatures supporting the result are the ones selected
    ///         to the group by sortition pool. This function should be used
    ///         together with `validateGroupMembers`.
    /// @param startBlock DKG start block
    /// @return true if group members matches; false otherwise
    function validateSignatures(
        EcdsaDkg.Result calldata result,
        uint256 startBlock
    ) public view returns (bool) {
        bytes32 hash = keccak256(
            abi.encode(
                block.chainid,
                result.groupPubKey,
                result.misbehavedMembersIndices,
                startBlock
            )
        ).toEthSignedMessageHash();

        uint256[] calldata signingMembersIndices = result.signingMembersIndices;
        uint32[] memory signingMemberIds = new uint32[](
            signingMembersIndices.length
        );
        for (uint256 i = 0; i < signingMembersIndices.length; i++) {
            signingMemberIds[i] = result.members[signingMembersIndices[i] - 1];
        }

        address[] memory signingMemberAddresses = sortitionPool.getIDOperators(
            signingMemberIds
        );

        bytes memory current; // Current signature to be checked.

        uint256 signaturesCount = result.signatures.length / signatureByteSize;
        for (uint256 i = 0; i < signaturesCount; i++) {
            current = result.signatures.slice(
                signatureByteSize * i,
                signatureByteSize
            );
            address recoveredAddress = hash.recover(current);

            if (signingMemberAddresses[i] != recoveredAddress) {
                return false;
            }
        }

        return true;
    }

    /// @notice Performs validation of hashed group members that actively took
    ///         part in DKG.
    /// @param result DKG result
    /// @return true if calculated result's group members hash matches with the
    /// one that is challenged.
    function validateMembersHash(EcdsaDkg.Result calldata result)
        public
        pure
        returns (bool)
    {
        if (result.misbehavedMembersIndices.length > 0) {
            // members that generated a group signing key
            uint32[] memory groupMembers = new uint32[](
                result.members.length - result.misbehavedMembersIndices.length
            );
            uint256 k = 0; // misbehaved members counter
            uint256 j = 0; // group members counter
            for (uint256 i = 0; i < result.members.length; i++) {
                // misbehaved member indices start from 1, so we need to -1 on misbehaved
                if (i != result.misbehavedMembersIndices[k] - 1) {
                    groupMembers[j] = result.members[i];
                    j++;
                } else if (k < result.misbehavedMembersIndices.length - 1) {
                    k++;
                }
            }

            return keccak256(abi.encode(groupMembers)) == result.membersHash;
        }

        return keccak256(abi.encode(result.members)) == result.membersHash;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

// Initial version copied from Keep Network Random Beacon:
// https://github.com/keep-network/keep-core/blob/5138c7628868dbeed3ae2164f76fccc6c1fbb9e8/solidity/random-beacon/contracts/libraries/DKG.sol
//
// With the following differences:
// - the group size was set to 100,
// - offchainDkgTimeout was removed,
// - submission eligibility verification is not performed on-chain,
// - submission eligibility delay was replaced with a submission timeout,
// - seed timeout notification requires seedTimeout period to pass.

pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@keep-network/sortition-pools/contracts/SortitionPool.sol";
import "@keep-network/random-beacon/contracts/libraries/BytesLib.sol";
import "../EcdsaDkgValidator.sol";

library EcdsaDkg {
    using BytesLib for bytes;
    using ECDSAUpgradeable for bytes32;

    struct Parameters {
        // Time in blocks during which a seed is expected to be delivered.
        // DKG starts only after a seed is delivered. The time the contract
        // awaits for a seed is not included in the DKG timeout.
        uint256 seedTimeout;
        // Time in blocks during which a submitted result can be challenged.
        uint256 resultChallengePeriodLength;
        // Extra gas required to be left at the end of the challenge DKG result
        // transaction.
        uint256 resultChallengeExtraGas;
        // Time in blocks during which a result is expected to be submitted.
        uint256 resultSubmissionTimeout;
        // Time in blocks during which only the result submitter is allowed to
        // approve it. Once this period ends and the submitter have not approved
        // the result, anyone can do it.
        uint256 submitterPrecedencePeriodLength;
        // This struct doesn't contain `__gap` property as the structure is
        // stored inside `Data` struct, that already have a gap that can be used
        // on upgrade.
    }

    struct Data {
        // Address of the Sortition Pool contract.
        SortitionPool sortitionPool;
        // Address of the EcdsaDkgValidator contract.
        EcdsaDkgValidator dkgValidator;
        // DKG parameters. The parameters should persist between DKG executions.
        // They should be updated with dedicated set functions only when DKG is not
        // in progress.
        Parameters parameters;
        // Time in block at which DKG state was locked.
        uint256 stateLockBlock;
        // Time in blocks at which DKG started.
        uint256 startBlock;
        // Seed used to start DKG.
        uint256 seed;
        // Time in blocks that should be added to result submission eligibility
        // delay calculation. It is used in case of a challenge to adjust
        // DKG timeout calculation.
        uint256 resultSubmissionStartBlockOffset;
        // Hash of submitted DKG result.
        bytes32 submittedResultHash;
        // Block number from the moment of the DKG result submission.
        uint256 submittedResultBlock;
        // Reserved storage space in case we need to add more variables.
        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        // slither-disable-next-line unused-state
        uint256[38] __gap;
    }

    /// @notice DKG result.
    struct Result {
        // Claimed submitter candidate group member index.
        // Must be in range [1, groupSize].
        uint256 submitterMemberIndex;
        // Generated candidate group public key
        bytes groupPubKey;
        // Array of misbehaved members indices (disqualified or inactive).
        // Indices must be in range [1, groupSize], unique, and sorted in ascending
        // order.
        uint8[] misbehavedMembersIndices;
        // Concatenation of signatures from members supporting the result.
        // The message to be signed by each member is keccak256 hash of the
        // calculated group public key, misbehaved members indices and DKG
        // start block. The calculated hash should be prefixed with prefixed with
        // `\x19Ethereum signed message:\n` before signing, so the message to
        // sign is:
        // `\x19Ethereum signed message:\n${keccak256(
        //    groupPubKey, misbehavedMembersIndices, dkgStartBlock
        // )}`
        bytes signatures;
        // Indices of members corresponding to each signature. Indices must be
        // be in range [1, groupSize], unique, and sorted in ascending order.
        uint256[] signingMembersIndices;
        // Identifiers of candidate group members as outputted by the group
        // selection protocol.
        uint32[] members;
        // Keccak256 hash of group members identifiers that actively took part
        // in DKG (excluding IA/DQ members).
        bytes32 membersHash;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's calldata argument.
    }

    /// @notice States for phases of group creation. The states doesn't include
    ///         timeouts which should be tracked and notified individually.
    enum State {
        // Group creation is not in progress. It is a state set after group creation
        // completion either by timeout or by a result approval.
        IDLE,
        // Group creation is awaiting the seed and sortition pool is locked.
        AWAITING_SEED,
        // DKG protocol execution is in progress. A result is being calculated
        // by the clients in this state and the contract awaits a result submission.
        // This is a state to which group creation returns in case of a result
        // challenge notification.
        AWAITING_RESULT,
        // DKG result was submitted and awaits an approval or a challenge. If a result
        // gets challenge the state returns to `AWAITING_RESULT`. If a result gets
        // approval the state changes to `IDLE`.
        CHALLENGE
    }

    /// @dev Size of a group in ECDSA wallet.
    uint256 public constant groupSize = 100;

    event DkgStarted(uint256 indexed seed);

    // To recreate the members that actively took part in dkg, the selected members
    // array should be filtered out from misbehavedMembersIndices.
    event DkgResultSubmitted(
        bytes32 indexed resultHash,
        uint256 indexed seed,
        Result result
    );

    event DkgTimedOut();

    event DkgResultApproved(
        bytes32 indexed resultHash,
        address indexed approver
    );

    event DkgResultChallenged(
        bytes32 indexed resultHash,
        address indexed challenger,
        string reason
    );

    event DkgStateLocked();

    event DkgSeedTimedOut();

    /// @notice Initializes SortitionPool and EcdsaDkgValidator addresses.
    ///        Can be performed only once.
    /// @param _sortitionPool Sortition Pool reference
    /// @param _dkgValidator EcdsaDkgValidator reference
    function init(
        Data storage self,
        SortitionPool _sortitionPool,
        EcdsaDkgValidator _dkgValidator
    ) internal {
        require(
            address(self.sortitionPool) == address(0),
            "Sortition Pool address already set"
        );

        require(
            address(self.dkgValidator) == address(0),
            "DKG Validator address already set"
        );

        self.sortitionPool = _sortitionPool;
        self.dkgValidator = _dkgValidator;
    }

    /// @notice Determines the current state of group creation. It doesn't take
    ///         timeouts into consideration. The timeouts should be tracked and
    ///         notified separately.
    function currentState(Data storage self)
        internal
        view
        returns (State state)
    {
        state = State.IDLE;

        if (self.sortitionPool.isLocked()) {
            state = State.AWAITING_SEED;

            if (self.startBlock > 0) {
                state = State.AWAITING_RESULT;

                if (self.submittedResultBlock > 0) {
                    state = State.CHALLENGE;
                }
            }
        }
    }

    /// @notice Locks the sortition pool and starts awaiting for the
    ///         group creation seed.
    function lockState(Data storage self) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        emit DkgStateLocked();

        self.sortitionPool.lock();

        self.stateLockBlock = block.number;
    }

    function start(Data storage self, uint256 seed) internal {
        require(
            currentState(self) == State.AWAITING_SEED,
            "Current state is not AWAITING_SEED"
        );

        emit DkgStarted(seed);

        self.startBlock = block.number;
        self.seed = seed;
    }

    /// @notice Allows to submit a DKG result. The submitted result does not go
    ///         through a validation and before it gets accepted, it needs to
    ///         wait through the challenge period during which everyone has
    ///         a chance to challenge the result as invalid one. Submitter of
    ///         the result needs to be in the sortition pool and if the result
    ///         gets challenged, the submitter will get slashed.
    function submitResult(Data storage self, Result calldata result) internal {
        require(
            currentState(self) == State.AWAITING_RESULT,
            "Current state is not AWAITING_RESULT"
        );
        require(!hasDkgTimedOut(self), "DKG timeout already passed");

        SortitionPool sortitionPool = self.sortitionPool;

        // Submitter must be an operator in the sortition pool.
        // Declared submitter's member index in the DKG result needs to match
        // the address calling this function.
        require(
            sortitionPool.isOperatorInPool(msg.sender),
            "Submitter not in the sortition pool"
        );
        require(
            sortitionPool.getIDOperator(
                result.members[result.submitterMemberIndex - 1]
            ) == msg.sender,
            "Unexpected submitter index"
        );

        self.submittedResultHash = keccak256(abi.encode(result));
        self.submittedResultBlock = block.number;

        emit DkgResultSubmitted(self.submittedResultHash, self.seed, result);
    }

    /// @notice Checks if awaiting seed timed out.
    /// @return True if awaiting seed timed out, false otherwise.
    function hasSeedTimedOut(Data storage self) internal view returns (bool) {
        return
            currentState(self) == State.AWAITING_SEED &&
            block.number > (self.stateLockBlock + self.parameters.seedTimeout);
    }

    /// @notice Checks if DKG timed out. The DKG timeout period includes time required
    ///         for off-chain protocol execution and time for the result publication.
    ///         After this time a result cannot be submitted and DKG can be notified
    ///         about the timeout. DKG period is adjusted by result submission
    ///         offset that include blocks that were mined while invalid result
    ///         has been registered until it got challenged.
    /// @return True if DKG timed out, false otherwise.
    function hasDkgTimedOut(Data storage self) internal view returns (bool) {
        return
            currentState(self) == State.AWAITING_RESULT &&
            block.number >
            (self.startBlock +
                self.resultSubmissionStartBlockOffset +
                self.parameters.resultSubmissionTimeout);
    }

    /// @notice Notifies about the seed was not delivered and restores the
    ///         initial DKG state (IDLE).
    function notifySeedTimeout(Data storage self) internal {
        require(hasSeedTimedOut(self), "Awaiting seed has not timed out");

        emit DkgSeedTimedOut();

        complete(self);
    }

    /// @notice Notifies about DKG timeout.
    function notifyDkgTimeout(Data storage self) internal {
        require(hasDkgTimedOut(self), "DKG has not timed out");

        emit DkgTimedOut();

        complete(self);
    }

    /// @notice Approves DKG result. Can be called when the challenge period for
    ///         the submitted result is finished. Considers the submitted result
    ///         as valid. For the first `submitterPrecedencePeriodLength`
    ///         blocks after the end of the challenge period can be called only
    ///         by the DKG result submitter. After that time, can be called by
    ///         anyone.
    /// @dev Can be called after a challenge period for the submitted result.
    /// @param result Result to approve. Must match the submitted result stored
    ///        during `submitResult`.
    /// @return misbehavedMembers Identifiers of members who misbehaved during DKG.
    function approveResult(Data storage self, Result calldata result)
        internal
        returns (uint32[] memory misbehavedMembers)
    {
        require(
            currentState(self) == State.CHALLENGE,
            "Current state is not CHALLENGE"
        );

        uint256 challengePeriodEnd = self.submittedResultBlock +
            self.parameters.resultChallengePeriodLength;

        require(
            block.number > challengePeriodEnd,
            "Challenge period has not passed yet"
        );

        require(
            keccak256(abi.encode(result)) == self.submittedResultHash,
            "Result under approval is different than the submitted one"
        );

        // Extract submitter member address. Submitter member index is in
        // range [1, groupSize] so we need to -1 when fetching identifier from members
        // array.
        address submitterMember = self.sortitionPool.getIDOperator(
            result.members[result.submitterMemberIndex - 1]
        );

        require(
            msg.sender == submitterMember ||
                block.number >
                challengePeriodEnd +
                    self.parameters.submitterPrecedencePeriodLength,
            "Only the DKG result submitter can approve the result at this moment"
        );

        // Extract misbehaved members identifiers. Misbehaved members indices
        // are in range [1, groupSize], so we need to -1 when fetching identifiers from
        // members array.
        misbehavedMembers = new uint32[](
            result.misbehavedMembersIndices.length
        );
        for (uint256 i = 0; i < result.misbehavedMembersIndices.length; i++) {
            misbehavedMembers[i] = result.members[
                result.misbehavedMembersIndices[i] - 1
            ];
        }

        emit DkgResultApproved(self.submittedResultHash, msg.sender);

        return misbehavedMembers;
    }

    /// @notice Challenges DKG result. If the submitted result is proved to be
    ///         invalid it reverts the DKG back to the result submission phase.
    /// @dev Can be called during a challenge period for the submitted result.
    /// @param result Result to challenge. Must match the submitted result
    ///        stored during `submitResult`.
    /// @return maliciousResultHash Hash of the malicious result.
    /// @return maliciousSubmitter Identifier of the malicious submitter.
    function challengeResult(Data storage self, Result calldata result)
        internal
        returns (bytes32 maliciousResultHash, uint32 maliciousSubmitter)
    {
        require(
            currentState(self) == State.CHALLENGE,
            "Current state is not CHALLENGE"
        );

        require(
            block.number <=
                self.submittedResultBlock +
                    self.parameters.resultChallengePeriodLength,
            "Challenge period has already passed"
        );

        require(
            keccak256(abi.encode(result)) == self.submittedResultHash,
            "Result under challenge is different than the submitted one"
        );

        // https://github.com/crytic/slither/issues/982
        // slither-disable-next-line unused-return
        try
            self.dkgValidator.validate(result, self.seed, self.startBlock)
        returns (
            // slither-disable-next-line uninitialized-local,variable-scope
            bool isValid,
            // slither-disable-next-line uninitialized-local,variable-scope
            string memory errorMsg
        ) {
            if (isValid) {
                revert("unjustified challenge");
            }

            emit DkgResultChallenged(
                self.submittedResultHash,
                msg.sender,
                errorMsg
            );
        } catch {
            // if the validation reverted we consider the DKG result as invalid
            emit DkgResultChallenged(
                self.submittedResultHash,
                msg.sender,
                "validation reverted"
            );
        }

        // Consider result hash as malicious.
        maliciousResultHash = self.submittedResultHash;
        maliciousSubmitter = result.members[result.submitterMemberIndex - 1];

        // Adjust DKG result submission block start, so submission stage starts
        // from the beginning.
        self.resultSubmissionStartBlockOffset = block.number - self.startBlock;

        submittedResultCleanup(self);

        return (maliciousResultHash, maliciousSubmitter);
    }

    /// @notice Due to EIP150, 1/64 of the gas is not forwarded to the call, and
    ///         will be kept to execute the remaining operations in the function
    ///         after the call inside the try-catch.
    ///
    ///         To ensure there is no way for the caller to manipulate gas limit
    ///         in such a way that the call inside try-catch fails with out-of-gas
    ///         and the rest of the function is executed with the remaining
    ///         1/64 of gas, we require an extra gas amount to be left at the
    ///         end of the call to the function challenging DKG result and
    ///         wrapping the call to EcdsaDkgValidator and TokenStaking
    ///         contracts inside a try-catch.
    function requireChallengeExtraGas(Data storage self) internal view {
        require(
            gasleft() >= self.parameters.resultChallengeExtraGas,
            "Not enough extra gas left"
        );
    }

    /// @notice Checks if DKG result is valid for the current DKG.
    /// @param result DKG result.
    /// @return True if the result is valid. If the result is invalid it returns
    ///         false and an error message.
    function isResultValid(Data storage self, Result calldata result)
        internal
        view
        returns (bool, string memory)
    {
        require(self.startBlock > 0, "DKG has not been started");

        return self.dkgValidator.validate(result, self.seed, self.startBlock);
    }

    /// @notice Set setSeedTimeout parameter.
    function setSeedTimeout(Data storage self, uint256 newSeedTimeout)
        internal
    {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(newSeedTimeout > 0, "New value should be greater than zero");

        self.parameters.seedTimeout = newSeedTimeout;
    }

    /// @notice Set resultChallengePeriodLength parameter.
    function setResultChallengePeriodLength(
        Data storage self,
        uint256 newResultChallengePeriodLength
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(
            newResultChallengePeriodLength > 0,
            "New value should be greater than zero"
        );

        self
            .parameters
            .resultChallengePeriodLength = newResultChallengePeriodLength;
    }

    /// @notice Set resultChallengeExtraGas parameter.
    function setResultChallengeExtraGas(
        Data storage self,
        uint256 newResultChallengeExtraGas
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        self.parameters.resultChallengeExtraGas = newResultChallengeExtraGas;
    }

    /// @notice Set resultSubmissionTimeout parameter.
    function setResultSubmissionTimeout(
        Data storage self,
        uint256 newResultSubmissionTimeout
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(
            newResultSubmissionTimeout > 0,
            "New value should be greater than zero"
        );

        self.parameters.resultSubmissionTimeout = newResultSubmissionTimeout;
    }

    /// @notice Set submitterPrecedencePeriodLength parameter.
    function setSubmitterPrecedencePeriodLength(
        Data storage self,
        uint256 newSubmitterPrecedencePeriodLength
    ) internal {
        require(currentState(self) == State.IDLE, "Current state is not IDLE");

        require(
            newSubmitterPrecedencePeriodLength <
                self.parameters.resultSubmissionTimeout,
            "New value should be less than result submission period length"
        );

        self
            .parameters
            .submitterPrecedencePeriodLength = newSubmitterPrecedencePeriodLength;
    }

    /// @notice Completes DKG by cleaning up state.
    /// @dev Should be called after DKG times out or a result is approved.
    function complete(Data storage self) internal {
        delete self.startBlock;
        delete self.seed;
        delete self.resultSubmissionStartBlockOffset;
        submittedResultCleanup(self);
        self.sortitionPool.unlock();
    }

    /// @notice Cleans up submitted result state either after DKG completion
    ///         (as part of `complete` method) or after justified challenge.
    function submittedResultCleanup(Data storage self) private {
        delete self.submittedResultHash;
        delete self.submittedResultBlock;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

/// @notice Governable contract.
/// @dev A constructor is not defined, which makes the contract compatible with
///      upgradable proxies. This requires calling explicitly `_transferGovernance`
///      function in a child contract.
abstract contract Governable {
    // Governance of the contract
    // The variable should be initialized by the implementing contract.
    // slither-disable-next-line uninitialized-state
    address public governance;

    // Reserved storage space in case we need to add more variables,
    // since there are upgradeable contracts that inherit from this one.
    // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    // slither-disable-next-line unused-state
    uint256[49] private __gap;

    event GovernanceTransferred(address oldGovernance, address newGovernance);

    modifier onlyGovernance() virtual {
        require(governance == msg.sender, "Caller is not the governance");
        _;
    }

    /// @notice Transfers governance of the contract to `newGovernance`.
    function transferGovernance(address newGovernance)
        external
        virtual
        onlyGovernance
    {
        require(
            newGovernance != address(0),
            "New governance is the zero address"
        );
        _transferGovernance(newGovernance);
    }

    function _transferGovernance(address newGovernance) internal virtual {
        address oldGovernance = governance;
        governance = newGovernance;
        emit GovernanceTransferred(oldGovernance, newGovernance);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//

pragma solidity 0.8.17;

/*
Version pulled from keep-core v1:
https://github.com/keep-network/keep-core/blob/f297202db00c027978ad8e7103a356503de5773c/solidity-v1/contracts/utils/BytesLib.sol

To compile it with solidity 0.8 `_preBytes_slot` was replaced with `_preBytes.slot`.
*/

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
    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
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
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
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

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
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
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
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

    function concat(bytes memory _preBytes, bytes memory _postBytes)
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
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory res) {
        uint256 _end = _start + _length;
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

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        uint256 _totalLen = _start + 20;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Address conversion out of bounds."
        );
        address tempAddress;

        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(
            _bytes.length >= (_start + 1),
            "Uint8 conversion out of bounds."
        );
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        uint256 _totalLen = _start + 32;
        require(
            _totalLen > _start && _bytes.length >= _totalLen,
            "Uint conversion out of bounds."
        );
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
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

    function toBytes32(bytes memory _source)
        internal
        pure
        returns (bytes32 result)
    {
        if (_source.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(_source, 32))
        }
    }

    function keccak256Slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes32 result) {
        uint256 _end = _start + _length;
        require(_end > _start && _bytes.length >= _end, "Slice out of bounds");

        assembly {
            result := keccak256(add(add(_bytes, 32), _start), _length)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
//
// ▓▓▌ ▓▓ ▐▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▄
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▌▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓    ▓▓▓▓▓▓▓▀    ▐▓▓▓▓▓▓    ▐▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▄▄▓▓▓▓▓▓▓▀      ▐▓▓▓▓▓▓▄▄▄▄         ▓▓▓▓▓▓▄▄▄▄         ▐▓▓▓▓▓▌   ▐▓▓▓▓▓▓
//   ▓▓▓▓▓▓▓▓▓▓▓▓▓▀        ▐▓▓▓▓▓▓▓▓▓▓         ▓▓▓▓▓▓▓▓▓▓         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓
//   ▓▓▓▓▓▓▀▀▓▓▓▓▓▓▄       ▐▓▓▓▓▓▓▀▀▀▀         ▓▓▓▓▓▓▀▀▀▀         ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▀
//   ▓▓▓▓▓▓   ▀▓▓▓▓▓▓▄     ▐▓▓▓▓▓▓     ▓▓▓▓▓   ▓▓▓▓▓▓     ▓▓▓▓▓   ▐▓▓▓▓▓▌
// ▓▓▓▓▓▓▓▓▓▓ █▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
// ▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓ ▐▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓  ▓▓▓▓▓▓▓▓▓▓
//
//                           Trust math, not hardware.

pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ReimbursementPool is Ownable, ReentrancyGuard {
    /// @notice Authorized contracts that can interact with the reimbursment pool.
    ///         Authorization can be granted and removed by the owner.
    mapping(address => bool) public isAuthorized;

    /// @notice Static gas includes:
    ///         - cost of the refund function
    ///         - base transaction cost
    uint256 public staticGas;

    /// @notice Max gas price used to reimburse a transaction submitter. Protects
    ///         against malicious operator-miners.
    uint256 public maxGasPrice;

    event StaticGasUpdated(uint256 newStaticGas);

    event MaxGasPriceUpdated(uint256 newMaxGasPrice);

    event SendingEtherFailed(uint256 refundAmount, address receiver);

    event AuthorizedContract(address thirdPartyContract);

    event UnauthorizedContract(address thirdPartyContract);

    event FundsWithdrawn(uint256 withdrawnAmount, address receiver);

    constructor(uint256 _staticGas, uint256 _maxGasPrice) {
        staticGas = _staticGas;
        maxGasPrice = _maxGasPrice;
    }

    /// @notice Receive ETH
    receive() external payable {}

    /// @notice Refunds ETH to a spender for executing specific transactions.
    /// @dev Ignoring the result of sending ETH to a receiver is made on purpose.
    ///      For EOA receiving ETH should always work. If a receiver is a smart
    ///      contract, then we do not want to fail a transaction, because in some
    ///      cases the refund is done at the very end of multiple calls where all
    ///      the previous calls were already paid off. It is a receiver's smart
    ///      contract resposibility to make sure it can receive ETH.
    /// @dev Only authorized contracts are allowed calling this function.
    /// @param gasSpent Gas spent on a transaction that needs to be reimbursed.
    /// @param receiver Address where the reimbursment is sent.
    function refund(uint256 gasSpent, address receiver) external nonReentrant {
        require(
            isAuthorized[msg.sender],
            "Contract is not authorized for a refund"
        );
        require(receiver != address(0), "Receiver's address cannot be zero");

        uint256 gasPrice = tx.gasprice < maxGasPrice
            ? tx.gasprice
            : maxGasPrice;

        uint256 refundAmount = (gasSpent + staticGas) * gasPrice;

        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls,unchecked-lowlevel
        (bool sent, ) = receiver.call{value: refundAmount}("");
        /* solhint-enable avoid-low-level-calls */
        if (!sent) {
            // slither-disable-next-line reentrancy-events
            emit SendingEtherFailed(refundAmount, receiver);
        }
    }

    /// @notice Authorize a contract that can interact with this reimbursment pool.
    ///         Can be authorized by the owner only.
    /// @param _contract Authorized contract.
    function authorize(address _contract) external onlyOwner {
        isAuthorized[_contract] = true;

        emit AuthorizedContract(_contract);
    }

    /// @notice Unauthorize a contract that was previously authorized to interact
    ///         with this reimbursment pool. Can be unauthorized by the
    ///         owner only.
    /// @param _contract Authorized contract.
    function unauthorize(address _contract) external onlyOwner {
        delete isAuthorized[_contract];

        emit UnauthorizedContract(_contract);
    }

    /// @notice Setting a static gas cost for executing a transaction. Can be set
    ///         by the owner only.
    /// @param _staticGas Static gas cost.
    function setStaticGas(uint256 _staticGas) external onlyOwner {
        staticGas = _staticGas;

        emit StaticGasUpdated(_staticGas);
    }

    /// @notice Setting a max gas price for transactions. Can be set by the
    ///         owner only.
    /// @param _maxGasPrice Max gas price used to reimburse tx submitters.
    function setMaxGasPrice(uint256 _maxGasPrice) external onlyOwner {
        maxGasPrice = _maxGasPrice;

        emit MaxGasPriceUpdated(_maxGasPrice);
    }

    /// @notice Withdraws all ETH from this pool which are sent to a given
    ///         address. Can be set by the owner only.
    /// @param receiver An address where ETH is sent.
    function withdrawAll(address receiver) external onlyOwner {
        withdraw(address(this).balance, receiver);
    }

    /// @notice Withdraws ETH amount from this pool which are sent to a given
    ///         address. Can be set by the owner only.
    /// @param amount Amount to withdraw from the pool.
    /// @param receiver An address where ETH is sent.
    function withdraw(uint256 amount, address receiver) public onlyOwner {
        require(
            address(this).balance >= amount,
            "Insufficient contract balance"
        );
        require(receiver != address(0), "Receiver's address cannot be zero");

        emit FundsWithdrawn(amount, receiver);

        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls,arbitrary-send
        (bool sent, ) = receiver.call{value: amount}("");
        /* solhint-enable avoid-low-level-calls */
        require(sent, "Failed to send Ether");
    }
}

pragma solidity 0.8.17;

import "./Constants.sol";

/// @notice The implicit 8-ary trees of the sortition pool
/// rely on packing 8 "slots" of 32-bit values into each uint256.
/// The Branch library permits efficient calculations on these slots.
library Branch {
  /// @notice Calculate the right shift required
  /// to make the 32 least significant bits of an uint256
  /// be the bits of the `position`th slot
  /// when treating the uint256 as a uint32[8].
  ///
  /// @dev Not used for efficiency reasons,
  /// but left to illustrate the meaning of a common pattern.
  /// I wish solidity had macros, even C macros.
  function slotShift(uint256 position) internal pure returns (uint256) {
    unchecked {
      return position * Constants.SLOT_WIDTH;
    }
  }

  /// @notice Return the `position`th slot of the `node`,
  /// treating `node` as a uint32[32].
  function getSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Doing a bitwise AND with `SLOT_MAX`
      // clears all but the 32 least significant bits.
      // Because of the right shift by `slotShift(position)` bits,
      // those 32 bits contain the 32 bits in the `position`th slot of `node`.
      return (node >> shiftBits) & Constants.SLOT_MAX;
    }
  }

  /// @notice Return `node` with the `position`th slot set to zero.
  function clearSlot(uint256 node, uint256 position)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Shifting `SLOT_MAX` left by `slotShift(position)` bits
      // gives us a number where all bits of the `position`th slot are set,
      // and all other bits are unset.
      //
      // Using a bitwise NOT on this number,
      // we get a uint256 where all bits are set
      // except for those of the `position`th slot.
      //
      // Bitwise ANDing the original `node` with this number
      // sets the bits of `position`th slot to zero,
      // leaving all other bits unchanged.
      return node & ~(Constants.SLOT_MAX << shiftBits);
    }
  }

  /// @notice Return `node` with the `position`th slot set to `weight`.
  ///
  /// @param weight The weight of of the node.
  /// Safely truncated to a 32-bit number,
  /// but this should never be called with an overflowing weight regardless.
  function setSlot(
    uint256 node,
    uint256 position,
    uint256 weight
  ) internal pure returns (uint256) {
    unchecked {
      uint256 shiftBits = position * Constants.SLOT_WIDTH;
      // Clear the `position`th slot like in `clearSlot()`.
      uint256 clearedNode = node & ~(Constants.SLOT_MAX << shiftBits);
      // Bitwise AND `weight` with `SLOT_MAX`
      // to clear all but the 32 least significant bits.
      //
      // Shift this left by `slotShift(position)` bits
      // to obtain a uint256 with all bits unset
      // except in the `position`th slot
      // which contains the 32-bit value of `weight`.
      uint256 shiftedWeight = (weight & Constants.SLOT_MAX) << shiftBits;
      // When we bitwise OR these together,
      // all other slots except the `position`th one come from the left argument,
      // and the `position`th gets filled with `weight` from the right argument.
      return clearedNode | shiftedWeight;
    }
  }

  /// @notice Calculate the summed weight of all slots in the `node`.
  function sumWeight(uint256 node) internal pure returns (uint256 sum) {
    unchecked {
      sum = node & Constants.SLOT_MAX;
      // Iterate through each slot
      // by shifting `node` right in increments of 32 bits,
      // and adding the 32 least significant bits to the `sum`.
      uint256 newNode = node >> Constants.SLOT_WIDTH;
      while (newNode > 0) {
        sum += (newNode & Constants.SLOT_MAX);
        newNode = newNode >> Constants.SLOT_WIDTH;
      }
      return sum;
    }
  }

  /// @notice Pick a slot in `node` that corresponds to `index`.
  /// Treats the node like an array of virtual stakers,
  /// the number of virtual stakers in each slot corresponding to its weight,
  /// and picks which slot contains the `index`th virtual staker.
  ///
  /// @dev Requires that `index` be lower than `sumWeight(node)`.
  /// However, this is not enforced for performance reasons.
  /// If `index` exceeds the permitted range,
  /// `pickWeightedSlot()` returns the rightmost slot
  /// and an excessively high `newIndex`.
  ///
  /// @return slot The slot of `node` containing the `index`th virtual staker.
  ///
  /// @return newIndex The index of the `index`th virtual staker of `node`
  /// within the returned slot.
  function pickWeightedSlot(uint256 node, uint256 index)
    internal
    pure
    returns (uint256 slot, uint256 newIndex)
  {
    unchecked {
      newIndex = index;
      uint256 newNode = node;
      uint256 currentSlotWeight = newNode & Constants.SLOT_MAX;
      while (newIndex >= currentSlotWeight) {
        newIndex -= currentSlotWeight;
        slot++;
        newNode = newNode >> Constants.SLOT_WIDTH;
        currentSlotWeight = newNode & Constants.SLOT_MAX;
      }
      return (slot, newIndex);
    }
  }
}

pragma solidity 0.8.17;

/// @title Chaosnet
/// @notice This is a beta staker program for stakers willing to go the extra
/// mile with monitoring, share their logs with the dev team, and allow to more
/// carefully monitor the bootstrapping network. As the network matures, the
/// beta program will be ended.
contract Chaosnet {
  /// @notice Indicates if the chaosnet is active. The chaosnet is active
  /// after the contract deployment and can be ended with a call to
  /// `deactivateChaosnet()`. Once deactivated chaosnet can not be activated
  /// again.
  bool public isChaosnetActive;

  /// @notice Indicates if the given operator is a beta operator for chaosnet.
  mapping(address => bool) public isBetaOperator;

  /// @notice Address controlling chaosnet status and beta operator addresses.
  address public chaosnetOwner;

  event BetaOperatorsAdded(address[] operators);

  event ChaosnetOwnerRoleTransferred(
    address oldChaosnetOwner,
    address newChaosnetOwner
  );

  event ChaosnetDeactivated();

  constructor() {
    _transferChaosnetOwner(msg.sender);
    isChaosnetActive = true;
  }

  modifier onlyChaosnetOwner() {
    require(msg.sender == chaosnetOwner, "Not the chaosnet owner");
    _;
  }

  modifier onlyOnChaosnet() {
    require(isChaosnetActive, "Chaosnet is not active");
    _;
  }

  /// @notice Adds beta operator to chaosnet. Can be called only by the
  /// chaosnet owner when the chaosnet is active. Once the operator is added
  /// as a beta operator, it can not be removed.
  function addBetaOperators(address[] calldata operators)
    public
    onlyOnChaosnet
    onlyChaosnetOwner
  {
    for (uint256 i = 0; i < operators.length; i++) {
      isBetaOperator[operators[i]] = true;
    }

    emit BetaOperatorsAdded(operators);
  }

  /// @notice Deactivates the chaosnet. Can be called only by the chaosnet
  /// owner. Once deactivated chaosnet can not be activated again.
  function deactivateChaosnet() public onlyOnChaosnet onlyChaosnetOwner {
    isChaosnetActive = false;
    emit ChaosnetDeactivated();
  }

  /// @notice Transfers the chaosnet owner role to another non-zero address.
  function transferChaosnetOwnerRole(address newChaosnetOwner)
    public
    onlyChaosnetOwner
  {
    require(
      newChaosnetOwner != address(0),
      "New chaosnet owner must not be zero address"
    );
    _transferChaosnetOwner(newChaosnetOwner);
  }

  function _transferChaosnetOwner(address newChaosnetOwner) internal {
    address oldChaosnetOwner = chaosnetOwner;
    chaosnetOwner = newChaosnetOwner;
    emit ChaosnetOwnerRoleTransferred(oldChaosnetOwner, newChaosnetOwner);
  }
}

pragma solidity 0.8.17;

library Constants {
  ////////////////////////////////////////////////////////////////////////////
  // Parameters for configuration

  // How many bits a position uses per level of the tree;
  // each branch of the tree contains 2**SLOT_BITS slots.
  uint256 constant SLOT_BITS = 3;
  uint256 constant LEVELS = 7;
  ////////////////////////////////////////////////////////////////////////////

  ////////////////////////////////////////////////////////////////////////////
  // Derived constants, do not touch
  uint256 constant SLOT_COUNT = 2**SLOT_BITS;
  uint256 constant SLOT_WIDTH = 256 / SLOT_COUNT;
  uint256 constant LAST_SLOT = SLOT_COUNT - 1;
  uint256 constant SLOT_MAX = (2**SLOT_WIDTH) - 1;
  uint256 constant POOL_CAPACITY = SLOT_COUNT**LEVELS;

  uint256 constant ID_WIDTH = SLOT_WIDTH;
  uint256 constant ID_MAX = SLOT_MAX;

  uint256 constant BLOCKHEIGHT_WIDTH = 96 - ID_WIDTH;
  uint256 constant BLOCKHEIGHT_MAX = (2**BLOCKHEIGHT_WIDTH) - 1;

  uint256 constant SLOT_POINTER_MAX = (2**SLOT_BITS) - 1;
  uint256 constant LEAF_FLAG = 1 << 255;

  uint256 constant WEIGHT_WIDTH = 256 / SLOT_COUNT;
  ////////////////////////////////////////////////////////////////////////////
}

pragma solidity 0.8.17;

import "./Constants.sol";

library Leaf {
  function make(
    address _operator,
    uint256 _creationBlock,
    uint256 _id
  ) internal pure returns (uint256) {
    assert(_creationBlock <= type(uint64).max);
    assert(_id <= type(uint32).max);
    // Converting a bytesX type into a larger type
    // adds zero bytes on the right.
    uint256 op = uint256(bytes32(bytes20(_operator)));
    // Bitwise AND the id to erase
    // all but the 32 least significant bits
    uint256 uid = _id & Constants.ID_MAX;
    // Erase all but the 64 least significant bits,
    // then shift left by 32 bits to make room for the id
    uint256 cb = (_creationBlock & Constants.BLOCKHEIGHT_MAX) <<
      Constants.ID_WIDTH;
    // Bitwise OR them all together to get
    // [address operator || uint64 creationBlock || uint32 id]
    return (op | cb | uid);
  }

  function operator(uint256 leaf) internal pure returns (address) {
    // Converting a bytesX type into a smaller type
    // truncates it on the right.
    return address(bytes20(bytes32(leaf)));
  }

  /// @notice Return the block number the leaf was created in.
  function creationBlock(uint256 leaf) internal pure returns (uint256) {
    return ((leaf >> Constants.ID_WIDTH) & Constants.BLOCKHEIGHT_MAX);
  }

  function id(uint256 leaf) internal pure returns (uint32) {
    // Id is stored in the 32 least significant bits.
    // Bitwise AND ensures that we only get the contents of those bits.
    return uint32(leaf & Constants.ID_MAX);
  }
}

pragma solidity 0.8.17;

import "./Constants.sol";

library Position {
  // Return the last 3 bits of a position number,
  // corresponding to its slot in its parent
  function slot(uint256 a) internal pure returns (uint256) {
    return a & Constants.SLOT_POINTER_MAX;
  }

  // Return the parent of a position number
  function parent(uint256 a) internal pure returns (uint256) {
    return a >> Constants.SLOT_BITS;
  }

  // Return the location of the child of a at the given slot
  function child(uint256 a, uint256 s) internal pure returns (uint256) {
    return (a << Constants.SLOT_BITS) | (s & Constants.SLOT_POINTER_MAX); // slot(s)
  }

  // Return the uint p as a flagged position uint:
  // the least significant 21 bits contain the position
  // and the 22nd bit is set as a flag
  // to distinguish the position 0x000000 from an empty field.
  function setFlag(uint256 p) internal pure returns (uint256) {
    return p | Constants.LEAF_FLAG;
  }

  // Turn a flagged position into an unflagged position
  // by removing the flag at the 22nd least significant bit.
  //
  // We shouldn't _actually_ need this
  // as all position-manipulating code should ignore non-position bits anyway
  // but it's cheap to call so might as well do it.
  function unsetFlag(uint256 p) internal pure returns (uint256) {
    return p & (~Constants.LEAF_FLAG);
  }
}

pragma solidity 0.8.17;

/// @title Rewards
/// @notice Rewards are allocated proportionally to operators
/// present in the pool at payout based on their weight in the pool.
///
/// To facilitate this, we use a global accumulator value
/// to track the total rewards one unit of weight would've earned
/// since the creation of the pool.
///
/// Whenever a reward is paid, the accumulator is increased
/// by the size of the reward divided by the total weight
/// of all eligible operators in the pool.
///
/// Each operator has an individual accumulator value,
/// set to equal the global accumulator when the operator joins the pool.
/// This accumulator reflects the amount of rewards
/// that have already been accounted for with that operator.
///
/// Whenever an operator's weight in the pool changes,
/// we can update the amount of rewards the operator has earned
/// by subtracting the operator's accumulator from the global accumulator.
/// This gives us the amount of rewards one unit of weight has earned
/// since the last time the operator's rewards have been updated.
/// Then we multiply that by the operator's previous (pre-change) weight
/// to determine how much rewards in total the operator has earned,
/// and add this to the operator's earned rewards.
/// Finally, we set the operator's accumulator to the global accumulator value.
contract Rewards {
  struct OperatorRewards {
    // The state of the global accumulator
    // when the operator's rewards were last updated
    uint96 accumulated;
    // The amount of rewards collected by the operator after the latest update.
    // The amount the operator could withdraw may equal `available`
    // or it may be greater, if more rewards have been paid in since then.
    // To evaulate the most recent amount including rewards potentially paid
    // since the last update, use `availableRewards` function.
    uint96 available;
    // If nonzero, the operator is ineligible for rewards
    // and may only re-enable rewards after the specified timestamp.
    // XXX: unsigned 32-bit integer unix seconds, will break around 2106
    uint32 ineligibleUntil;
    // Locally cached weight of the operator,
    // used to reduce the cost of setting operators ineligible.
    uint32 weight;
  }

  // The global accumulator of how much rewards
  // a hypothetical operator of weight 1 would have earned
  // since the creation of the pool.
  uint96 internal globalRewardAccumulator;
  // If the amount of reward tokens paid in
  // does not divide cleanly by pool weight,
  // the difference is recorded as rounding dust
  // and added to the next reward.
  uint96 internal rewardRoundingDust;

  // The amount of rewards that would've been earned by ineligible operators
  // had they not been ineligible.
  uint96 public ineligibleEarnedRewards;

  // Ineligibility times are calculated from this offset,
  // set at contract creation.
  uint256 internal immutable ineligibleOffsetStart;

  mapping(uint32 => OperatorRewards) internal operatorRewards;

  constructor() {
    // solhint-disable-next-line not-rely-on-time
    ineligibleOffsetStart = block.timestamp;
  }

  /// @notice Return whether the operator is eligible for rewards or not.
  function isEligibleForRewards(uint32 operator) internal view returns (bool) {
    return operatorRewards[operator].ineligibleUntil == 0;
  }

  /// @notice Return the time the operator's reward eligibility can be restored.
  function rewardsEligibilityRestorableAt(uint32 operator)
    internal
    view
    returns (uint256)
  {
    uint32 until = operatorRewards[operator].ineligibleUntil;
    require(until != 0, "Operator already eligible");
    return (uint256(until) + ineligibleOffsetStart);
  }

  /// @notice Return whether the operator is able to restore their eligibility
  ///         for rewards right away.
  function canRestoreRewardEligibility(uint32 operator)
    internal
    view
    returns (bool)
  {
    // solhint-disable-next-line not-rely-on-time
    return rewardsEligibilityRestorableAt(operator) <= block.timestamp;
  }

  /// @notice Internal function for updating the global state of rewards.
  function addRewards(uint96 rewardAmount, uint32 currentPoolWeight) internal {
    require(currentPoolWeight > 0, "No recipients in pool");

    uint96 totalAmount = rewardAmount + rewardRoundingDust;
    uint96 perWeightReward = totalAmount / currentPoolWeight;
    uint96 newRoundingDust = totalAmount % currentPoolWeight;

    globalRewardAccumulator += perWeightReward;
    rewardRoundingDust = newRoundingDust;
  }

  /// @notice Internal function for updating the operator's reward state.
  function updateOperatorRewards(uint32 operator, uint32 newWeight) internal {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
    if (o.ineligibleUntil == 0) {
      // If operator is not ineligible, update their earned rewards
      o.available += accruedRewards;
    } else {
      // If ineligible, put the rewards into the ineligible pot
      ineligibleEarnedRewards += accruedRewards;
    }
    // In any case, update their accumulator and weight
    o.accumulated = acc;
    o.weight = newWeight;
    operatorRewards[operator] = o;
  }

  /// @notice Set the amount of withdrawable tokens to zero
  /// and return the previous withdrawable amount.
  /// @dev Does not update the withdrawable amount,
  /// but should usually be accompanied by an update.
  function withdrawOperatorRewards(uint32 operator)
    internal
    returns (uint96 withdrawable)
  {
    OperatorRewards storage o = operatorRewards[operator];
    withdrawable = o.available;
    o.available = 0;
  }

  /// @notice Set the amount of ineligible-earned tokens to zero
  /// and return the previous amount.
  function withdrawIneligibleRewards() internal returns (uint96 withdrawable) {
    withdrawable = ineligibleEarnedRewards;
    ineligibleEarnedRewards = 0;
  }

  /// @notice Set the given operators as ineligible for rewards.
  /// The operators can restore their eligibility at the given time.
  function setIneligible(uint32[] memory operators, uint256 until) internal {
    OperatorRewards memory o = OperatorRewards(0, 0, 0, 0);
    uint96 globalAcc = globalRewardAccumulator;
    uint96 accrued = 0;
    // Record ineligibility as seconds after contract creation
    uint32 _until = uint32(until - ineligibleOffsetStart);

    for (uint256 i = 0; i < operators.length; i++) {
      uint32 operator = operators[i];
      OperatorRewards storage r = operatorRewards[operator];
      o.available = r.available;
      o.accumulated = r.accumulated;
      o.ineligibleUntil = r.ineligibleUntil;
      o.weight = r.weight;

      if (o.ineligibleUntil != 0) {
        // If operator is already ineligible,
        // don't earn rewards or shorten its ineligibility
        if (o.ineligibleUntil < _until) {
          o.ineligibleUntil = _until;
        }
      } else {
        // The operator becomes ineligible -> earn rewards
        o.ineligibleUntil = _until;
        accrued = (globalAcc - o.accumulated) * uint96(o.weight);
        o.available += accrued;
      }
      o.accumulated = globalAcc;

      r.available = o.available;
      r.accumulated = o.accumulated;
      r.ineligibleUntil = o.ineligibleUntil;
      r.weight = o.weight;
    }
  }

  /// @notice Restore the given operator's eligibility for rewards.
  function restoreEligibility(uint32 operator) internal {
    // solhint-disable-next-line not-rely-on-time
    require(canRestoreRewardEligibility(operator), "Operator still ineligible");
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
    ineligibleEarnedRewards += accruedRewards;
    o.accumulated = acc;
    o.ineligibleUntil = 0;
    operatorRewards[operator] = o;
  }

  /// @notice Returns the amount of rewards currently available for withdrawal
  ///         for the given operator.
  function availableRewards(uint32 operator) internal view returns (uint96) {
    uint96 acc = globalRewardAccumulator;
    OperatorRewards memory o = operatorRewards[operator];
    if (o.ineligibleUntil == 0) {
      // If operator is not ineligible, calculate newly accrued rewards and add
      // them to the available ones, calculated during the last update.
      uint96 accruedRewards = (acc - o.accumulated) * uint96(o.weight);
      return o.available + accruedRewards;
    } else {
      // If ineligible, return only the rewards calculated during the last
      // update.
      return o.available;
    }
  }
}

pragma solidity 0.8.17;

import "./Leaf.sol";
import "./Constants.sol";

library RNG {
  /// @notice Get an index in the range `[0 .. range-1]`
  /// and the new state of the RNG,
  /// using the provided `state` of the RNG.
  ///
  /// @param range The upper bound of the index, exclusive.
  ///
  /// @param state The previous state of the RNG.
  /// The initial state needs to be obtained
  /// from a trusted randomness oracle (the random beacon),
  /// or from a chain of earlier calls to `RNG.getIndex()`
  /// on an originally trusted seed.
  ///
  /// @dev Calculates the number of bits required for the desired range,
  /// takes the least significant bits of `state`
  /// and checks if the obtained index is within the desired range.
  /// The original state is hashed with `keccak256` to get a new state.
  /// If the index is outside the range,
  /// the function retries until it gets a suitable index.
  ///
  /// @return index A random integer between `0` and `range - 1`, inclusive.
  ///
  /// @return newState The new state of the RNG.
  /// When `getIndex()` is called one or more times,
  /// care must be taken to always use the output `state`
  /// of the most recent call as the input `state` of a subsequent call.
  /// At the end of a transaction calling `RNG.getIndex()`,
  /// the previous stored state must be overwritten with the latest output.
  function getIndex(
    uint256 range,
    bytes32 state,
    uint256 bits
  ) internal view returns (uint256, bytes32) {
    bool found = false;
    uint256 index = 0;
    bytes32 newState = state;
    while (!found) {
      index = truncate(bits, uint256(newState));
      newState = keccak256(abi.encodePacked(newState, address(this)));
      if (index < range) {
        found = true;
      }
    }
    return (index, newState);
  }

  /// @notice Calculate how many bits are required
  /// for an index in the range `[0 .. range-1]`.
  ///
  /// @param range The upper bound of the desired range, exclusive.
  ///
  /// @return uint The smallest number of bits
  /// that can contain the number `range-1`.
  function bitsRequired(uint256 range) internal pure returns (uint256) {
    unchecked {
      if (range == 1) {
        return 0;
      }

      uint256 bits = Constants.WEIGHT_WIDTH - 1;

      // Left shift by `bits`,
      // so we have a 1 in the (bits + 1)th least significant bit
      // and 0 in other bits.
      // If this number is equal or greater than `range`,
      // the range [0, range-1] fits in `bits` bits.
      //
      // Because we loop from high bits to low bits,
      // we find the highest number of bits that doesn't fit the range,
      // and return that number + 1.
      while (1 << bits >= range) {
        bits--;
      }

      return bits + 1;
    }
  }

  /// @notice Truncate `input` to the `bits` least significant bits.
  function truncate(uint256 bits, uint256 input)
    internal
    pure
    returns (uint256)
  {
    unchecked {
      return input & ((1 << bits) - 1);
    }
  }
}

pragma solidity 0.8.17;

import "@thesis/solidity-contracts/contracts/token/IERC20WithPermit.sol";
import "@thesis/solidity-contracts/contracts/token/IReceiveApproval.sol";

import "@openzeppelin/contracts/access/Ownable.sol";

import "./RNG.sol";
import "./SortitionTree.sol";
import "./Rewards.sol";
import "./Chaosnet.sol";

/// @title Sortition Pool
/// @notice A logarithmic data structure used to store the pool of eligible
/// operators weighted by their stakes. It allows to select a group of operators
/// based on the provided pseudo-random seed.
contract SortitionPool is
  SortitionTree,
  Rewards,
  Ownable,
  Chaosnet,
  IReceiveApproval
{
  using Branch for uint256;
  using Leaf for uint256;
  using Position for uint256;

  IERC20WithPermit public immutable rewardToken;

  uint256 public immutable poolWeightDivisor;

  bool public isLocked;

  event IneligibleForRewards(uint32[] ids, uint256 until);

  event RewardEligibilityRestored(address indexed operator, uint32 indexed id);

  /// @notice Reverts if called while pool is locked.
  modifier onlyUnlocked() {
    require(!isLocked, "Sortition pool locked");
    _;
  }

  /// @notice Reverts if called while pool is unlocked.
  modifier onlyLocked() {
    require(isLocked, "Sortition pool unlocked");
    _;
  }

  constructor(IERC20WithPermit _rewardToken, uint256 _poolWeightDivisor) {
    rewardToken = _rewardToken;
    poolWeightDivisor = _poolWeightDivisor;
  }

  function receiveApproval(
    address sender,
    uint256 amount,
    address token,
    bytes calldata
  ) external override {
    require(token == address(rewardToken), "Unsupported token");
    rewardToken.transferFrom(sender, address(this), amount);
    Rewards.addRewards(uint96(amount), uint32(root.sumWeight()));
  }

  /// @notice Withdraws all available rewards for the given operator to the
  ///         given beneficiary.
  /// @dev Can be called only be the owner. Does not validate if the provided
  ///      beneficiary is associated with the provided operator - this needs to
  ///      be done by the owner calling this function.
  /// @return The amount of rewards withdrawn in this call.
  function withdrawRewards(address operator, address beneficiary)
    public
    onlyOwner
    returns (uint96)
  {
    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(getPoolWeight(operator)));
    uint96 earned = Rewards.withdrawOperatorRewards(id);
    rewardToken.transfer(beneficiary, uint256(earned));
    return earned;
  }

  /// @notice Withdraws rewards not allocated to operators marked as ineligible
  ///         to the given recipient address.
  /// @dev Can be called only by the owner.
  function withdrawIneligible(address recipient) public onlyOwner {
    uint96 earned = Rewards.withdrawIneligibleRewards();
    rewardToken.transfer(recipient, uint256(earned));
  }

  /// @notice Locks the sortition pool. In locked state, members cannot be
  ///         inserted and removed from the pool. Members statuses cannot
  ///         be updated as well.
  /// @dev Can be called only by the contract owner.
  function lock() public onlyOwner {
    isLocked = true;
  }

  /// @notice Unlocks the sortition pool. Removes all restrictions set by
  ///         the `lock` method.
  /// @dev Can be called only by the contract owner.
  function unlock() public onlyOwner {
    isLocked = false;
  }

  /// @notice Inserts an operator to the pool. Reverts if the operator is
  /// already present. Reverts if the operator is not eligible because of their
  /// authorized stake. Reverts if the chaosnet is active and the operator is
  /// not a beta operator.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the inserted operator.
  /// @param authorizedStake Inserted operator's authorized stake for the application.
  function insertOperator(address operator, uint256 authorizedStake)
    public
    onlyOwner
    onlyUnlocked
  {
    uint256 weight = getWeight(authorizedStake);
    require(weight > 0, "Operator not eligible");

    if (isChaosnetActive) {
      require(isBetaOperator[operator], "Not beta operator for chaosnet");
    }

    _insertOperator(operator, weight);
    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(weight));
  }

  /// @notice Update the operator's weight if present and eligible,
  /// or remove from the pool if present and ineligible.
  /// @dev Can be called only by the contract owner.
  /// @param operator Address of the updated operator.
  /// @param authorizedStake Operator's authorized stake for the application.
  function updateOperatorStatus(address operator, uint256 authorizedStake)
    public
    onlyOwner
    onlyUnlocked
  {
    uint256 weight = getWeight(authorizedStake);

    uint32 id = getOperatorID(operator);
    Rewards.updateOperatorRewards(id, uint32(weight));

    if (weight == 0) {
      _removeOperator(operator);
    } else {
      updateOperator(operator, weight);
    }
  }

  /// @notice Set the given operators as ineligible for rewards.
  ///         The operators can restore their eligibility at the given time.
  function setRewardIneligibility(uint32[] calldata operators, uint256 until)
    public
    onlyOwner
  {
    Rewards.setIneligible(operators, until);
    emit IneligibleForRewards(operators, until);
  }

  /// @notice Restores reward eligibility for the operator.
  function restoreRewardEligibility(address operator) public {
    uint32 id = getOperatorID(operator);
    Rewards.restoreEligibility(id);
    emit RewardEligibilityRestored(operator, id);
  }

  /// @notice Returns whether the operator is eligible for rewards or not.
  function isEligibleForRewards(address operator) public view returns (bool) {
    uint32 id = getOperatorID(operator);
    return Rewards.isEligibleForRewards(id);
  }

  /// @notice Returns the time the operator's reward eligibility can be restored.
  function rewardsEligibilityRestorableAt(address operator)
    public
    view
    returns (uint256)
  {
    uint32 id = getOperatorID(operator);
    return Rewards.rewardsEligibilityRestorableAt(id);
  }

  /// @notice Returns whether the operator is able to restore their eligibility
  ///         for rewards right away.
  function canRestoreRewardEligibility(address operator)
    public
    view
    returns (bool)
  {
    uint32 id = getOperatorID(operator);
    return Rewards.canRestoreRewardEligibility(id);
  }

  /// @notice Returns the amount of rewards withdrawable for the given operator.
  function getAvailableRewards(address operator) public view returns (uint96) {
    uint32 id = getOperatorID(operator);
    return availableRewards(id);
  }

  /// @notice Return whether the operator is present in the pool.
  function isOperatorInPool(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  /// @notice Return whether the operator's weight in the pool
  /// matches their eligible weight.
  function isOperatorUpToDate(address operator, uint256 authorizedStake)
    public
    view
    returns (bool)
  {
    return getWeight(authorizedStake) == getPoolWeight(operator);
  }

  /// @notice Return the weight of the operator in the pool,
  /// which may or may not be out of date.
  function getPoolWeight(address operator) public view returns (uint256) {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    if (flaggedPosition == 0) {
      return 0;
    } else {
      uint256 leafPosition = flaggedPosition.unsetFlag();
      uint256 leafWeight = getLeafWeight(leafPosition);
      return leafWeight;
    }
  }

  /// @notice Selects a new group of operators of the provided size based on
  /// the provided pseudo-random seed. At least one operator has to be
  /// registered in the pool, otherwise the function fails reverting the
  /// transaction.
  /// @param groupSize Size of the requested group
  /// @param seed Pseudo-random number used to select operators to group
  /// @return selected Members of the selected group
  function selectGroup(uint256 groupSize, bytes32 seed)
    public
    view
    onlyLocked
    returns (uint32[] memory)
  {
    uint256 _root = root;

    bytes32 rngState = seed;
    uint256 rngRange = _root.sumWeight();
    require(rngRange > 0, "Not enough operators in pool");
    uint256 currentIndex;

    uint256 bits = RNG.bitsRequired(rngRange);

    uint32[] memory selected = new uint32[](groupSize);

    for (uint256 i = 0; i < groupSize; i++) {
      (currentIndex, rngState) = RNG.getIndex(rngRange, rngState, bits);

      uint256 leafPosition = pickWeightedLeaf(currentIndex, _root);

      uint256 leaf = leaves[leafPosition];
      selected[i] = leaf.id();
    }
    return selected;
  }

  function getWeight(uint256 authorization) internal view returns (uint256) {
    return authorization / poolWeightDivisor;
  }
}

pragma solidity 0.8.17;

import "./Branch.sol";
import "./Position.sol";
import "./Leaf.sol";
import "./Constants.sol";

contract SortitionTree {
  using Branch for uint256;
  using Position for uint256;
  using Leaf for uint256;

  // implicit tree
  // root 8
  // level2 64
  // level3 512
  // level4 4k
  // level5 32k
  // level6 256k
  // level7 2M
  uint256 internal root;

  // A 2-index mapping from layer => (index (0-index) => branch). For example,
  // to access the 6th branch in the 2nd layer (right below the root node; the
  // first branch layer), call branches[2][5]. Mappings are used in place of
  // arrays for efficiency. The root is the first layer, the branches occupy
  // layers 2 through 7, and layer 8 is for the leaves. Following this
  // convention, the first index in `branches` is `2`, and the last index is
  // `7`.
  mapping(uint256 => mapping(uint256 => uint256)) internal branches;

  // A 0-index mapping from index => leaf, acting as an array. For example, to
  // access the 42nd leaf, call leaves[41].
  mapping(uint256 => uint256) internal leaves;

  // the flagged (see setFlag() and unsetFlag() in Position.sol) positions
  // of all operators present in the pool
  mapping(address => uint256) internal flaggedLeafPosition;

  // the leaf after the rightmost occupied leaf of each stack
  uint256 internal rightmostLeaf;

  // the empty leaves in each stack
  // between 0 and the rightmost occupied leaf
  uint256[] internal emptyLeaves;

  // Each operator has an uint32 ID number
  // which is allocated when they first join the pool
  // and remains unchanged even if they leave and rejoin the pool.
  mapping(address => uint32) internal operatorID;

  // The idAddress array records the address corresponding to each ID number.
  // The ID number 0 is initialized with a zero address and is not used.
  address[] internal idAddress;

  constructor() {
    root = 0;
    rightmostLeaf = 0;
    idAddress.push();
  }

  /// @notice Return the ID number of the given operator address. An ID number
  /// of 0 means the operator has not been allocated an ID number yet.
  /// @param operator Address of the operator.
  /// @return the ID number of the given operator address
  function getOperatorID(address operator) public view returns (uint32) {
    return operatorID[operator];
  }

  /// @notice Get the operator address corresponding to the given ID number. A
  /// zero address means the ID number has not been allocated yet.
  /// @param id ID of the operator
  /// @return the address of the operator
  function getIDOperator(uint32 id) public view returns (address) {
    return idAddress.length > id ? idAddress[id] : address(0);
  }

  /// @notice Gets the operator addresses corresponding to the given ID
  /// numbers. A zero address means the ID number has not been allocated yet.
  /// This function works just like getIDOperator except that it allows to fetch
  /// operator addresses for multiple IDs in one call.
  /// @param ids the array of the operator ids
  /// @return an array of the associated operator addresses
  function getIDOperators(uint32[] calldata ids)
    public
    view
    returns (address[] memory)
  {
    uint256 idCount = idAddress.length;

    address[] memory operators = new address[](ids.length);
    for (uint256 i = 0; i < ids.length; i++) {
      uint32 id = ids[i];
      operators[i] = idCount > id ? idAddress[id] : address(0);
    }
    return operators;
  }

  /// @notice Checks if operator is already registered in the pool.
  /// @param operator the address of the operator
  /// @return whether or not the operator is already registered in the pool
  function isOperatorRegistered(address operator) public view returns (bool) {
    return getFlaggedLeafPosition(operator) != 0;
  }

  /// @notice Sum the number of operators in each trunk.
  /// @return the number of operators in the pool
  function operatorsInPool() public view returns (uint256) {
    // Get the number of leaves that might be occupied;
    // if `rightmostLeaf` equals `firstLeaf()` the tree must be empty,
    // otherwise the difference between these numbers
    // gives the number of leaves that may be occupied.
    uint256 nPossiblyUsedLeaves = rightmostLeaf;
    // Get the number of empty leaves
    // not accounted for by the `rightmostLeaf`
    uint256 nEmptyLeaves = emptyLeaves.length;

    return (nPossiblyUsedLeaves - nEmptyLeaves);
  }

  /// @notice Convenience method to return the total weight of the pool
  /// @return the total weight of the pool
  function totalWeight() public view returns (uint256) {
    return root.sumWeight();
  }

  /// @notice Give the operator a new ID number.
  /// Does not check if the operator already has an ID number.
  /// @param operator the address of the operator
  /// @return a new ID for that operator
  function allocateOperatorID(address operator) internal returns (uint256) {
    uint256 id = idAddress.length;

    require(id <= type(uint32).max, "Pool capacity exceeded");

    operatorID[operator] = uint32(id);
    idAddress.push(operator);
    return id;
  }

  /// @notice Inserts an operator into the sortition pool
  /// @param operator the address of an operator to insert
  /// @param weight how much weight that operator has in the pool
  function _insertOperator(address operator, uint256 weight) internal {
    require(
      !isOperatorRegistered(operator),
      "Operator is already registered in the pool"
    );

    // Fetch the operator's ID, and if they don't have one, allocate them one.
    uint256 id = getOperatorID(operator);
    if (id == 0) {
      id = allocateOperatorID(operator);
    }

    // Determine which leaf to insert them into
    uint256 position = getEmptyLeafPosition();
    // Record the block the operator was inserted in
    uint256 theLeaf = Leaf.make(operator, block.number, id);

    // Update the leaf, and propagate the weight changes all the way up to the
    // root.
    root = setLeaf(position, theLeaf, weight, root);

    // Without position flags,
    // the position 0x000000 would be treated as empty
    flaggedLeafPosition[operator] = position.setFlag();
  }

  /// @notice Remove an operator (and their weight) from the pool.
  /// @param operator the address of the operator to remove
  function _removeOperator(address operator) internal {
    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    require(flaggedPosition != 0, "Operator is not registered in the pool");
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();

    // Update the leaf, and propagate the weight changes all the way up to the
    // root.
    root = removeLeaf(unflaggedPosition, root);
    removeLeafPositionRecord(operator);
  }

  /// @notice Update an operator's weight in the pool.
  /// @param operator the address of the operator to update
  /// @param weight the new weight
  function updateOperator(address operator, uint256 weight) internal {
    require(
      isOperatorRegistered(operator),
      "Operator is not registered in the pool"
    );

    uint256 flaggedPosition = getFlaggedLeafPosition(operator);
    uint256 unflaggedPosition = flaggedPosition.unsetFlag();
    root = updateLeaf(unflaggedPosition, weight, root);
  }

  /// @notice Helper method to remove a leaf position record for an operator.
  /// @param operator the address of the operator to remove the record for
  function removeLeafPositionRecord(address operator) internal {
    flaggedLeafPosition[operator] = 0;
  }

  /// @notice Removes the data and weight from a particular leaf.
  /// @param position the leaf index to remove
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function removeLeaf(uint256 position, uint256 _root)
    internal
    returns (uint256)
  {
    uint256 rightmostSubOne = rightmostLeaf - 1;
    bool isRightmost = position == rightmostSubOne;

    // Clears out the data in the leaf node, and then propagates the weight
    // changes all the way up to the root.
    uint256 newRoot = setLeaf(position, 0, 0, _root);

    // Infer if need to fall back on emptyLeaves yet
    if (isRightmost) {
      rightmostLeaf = rightmostSubOne;
    } else {
      emptyLeaves.push(position);
    }
    return newRoot;
  }

  /// @notice Updates the tree to give a particular leaf a new weight.
  /// @param position the index of the leaf to update
  /// @param weight the new weight
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function updateLeaf(
    uint256 position,
    uint256 weight,
    uint256 _root
  ) internal returns (uint256) {
    if (getLeafWeight(position) != weight) {
      return updateTree(position, weight, _root);
    } else {
      return _root;
    }
  }

  /// @notice Places a leaf into a particular position, with a given weight and
  /// propagates that change.
  /// @param position the index to place the leaf in
  /// @param theLeaf the new leaf to place in the position
  /// @param leafWeight the weight of the leaf
  /// @param _root the root containing the new leaf
  /// @return the updated root node
  function setLeaf(
    uint256 position,
    uint256 theLeaf,
    uint256 leafWeight,
    uint256 _root
  ) internal returns (uint256) {
    // set leaf
    leaves[position] = theLeaf;

    return (updateTree(position, leafWeight, _root));
  }

  /// @notice Propagates a weight change at a position through the tree,
  /// eventually returning the updated root.
  /// @param position the index of leaf to update
  /// @param weight the new weight of the leaf
  /// @param _root the root node containing the leaf
  /// @return the updated root node
  function updateTree(
    uint256 position,
    uint256 weight,
    uint256 _root
  ) internal returns (uint256) {
    uint256 childSlot;
    uint256 treeNode;
    uint256 newNode;
    uint256 nodeWeight = weight;

    uint256 parent = position;
    // set levels 7 to 2
    for (uint256 level = Constants.LEVELS; level >= 2; level--) {
      childSlot = parent.slot();
      parent = parent.parent();
      treeNode = branches[level][parent];
      newNode = treeNode.setSlot(childSlot, nodeWeight);
      branches[level][parent] = newNode;
      nodeWeight = newNode.sumWeight();
    }

    // set level Root
    childSlot = parent.slot();
    return _root.setSlot(childSlot, nodeWeight);
  }

  /// @notice Retrieves the next available empty leaf position. Tries to fill
  /// left to right first, ignoring leaf removals, and then fills
  /// most-recent-removals first.
  /// @return the position of the empty leaf
  function getEmptyLeafPosition() internal returns (uint256) {
    uint256 rLeaf = rightmostLeaf;
    bool spaceOnRight = (rLeaf + 1) < Constants.POOL_CAPACITY;
    if (spaceOnRight) {
      rightmostLeaf = rLeaf + 1;
      return rLeaf;
    } else {
      uint256 emptyLeafCount = emptyLeaves.length;
      require(emptyLeafCount > 0, "Pool is full");
      uint256 emptyLeaf = emptyLeaves[emptyLeafCount - 1];
      emptyLeaves.pop();
      return emptyLeaf;
    }
  }

  /// @notice Gets the flagged leaf position for an operator.
  /// @param operator the address of the operator
  /// @return the leaf position of that operator
  function getFlaggedLeafPosition(address operator)
    internal
    view
    returns (uint256)
  {
    return flaggedLeafPosition[operator];
  }

  /// @notice Gets the weight of a leaf at a particular position.
  /// @param position the index of the leaf
  /// @return the weight of the leaf at that position
  function getLeafWeight(uint256 position) internal view returns (uint256) {
    uint256 slot = position.slot();
    uint256 parent = position.parent();

    // A leaf's weight information is stored a 32-bit slot in the branch layer
    // directly above the leaf layer. To access it, we calculate that slot and
    // parent position, and always know the hard-coded layer index.
    uint256 node = branches[Constants.LEVELS][parent];
    return node.getSlot(slot);
  }

  /// @notice Picks a leaf given a random index.
  /// @param index a number in `[0, _root.totalWeight())` used to decide
  /// between leaves
  /// @param _root the root of the tree
  function pickWeightedLeaf(uint256 index, uint256 _root)
    internal
    view
    returns (uint256 leafPosition)
  {
    uint256 currentIndex = index;
    uint256 currentNode = _root;
    uint256 currentPosition = 0;
    uint256 currentSlot;

    require(index < currentNode.sumWeight(), "Index exceeds weight");

    // get root slot
    (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);

    // get slots from levels 2 to 7
    for (uint256 level = 2; level <= Constants.LEVELS; level++) {
      currentPosition = currentPosition.child(currentSlot);
      currentNode = branches[level][currentPosition];
      (currentSlot, currentIndex) = currentNode.pickWeightedSlot(currentIndex);
    }

    // get leaf position
    leafPosition = currentPosition.child(currentSlot);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
library SafeCastUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IERC20WithPermit.sol";
import "./IReceiveApproval.sol";

/// @title  ERC20WithPermit
/// @notice Burnable ERC20 token with EIP2612 permit functionality. User can
///         authorize a transfer of their token with a signature conforming
///         EIP712 standard instead of an on-chain transaction from their
///         address. Anyone can submit this signature on the user's behalf by
///         calling the permit function, as specified in EIP2612 standard,
///         paying gas fees, and possibly performing other actions in the same
///         transaction.
contract ERC20WithPermit is IERC20WithPermit, Ownable {
    /// @notice The amount of tokens owned by the given account.
    mapping(address => uint256) public override balanceOf;

    /// @notice The remaining number of tokens that spender will be
    ///         allowed to spend on behalf of owner through `transferFrom` and
    ///         `burnFrom`. This is zero by default.
    mapping(address => mapping(address => uint256)) public override allowance;

    /// @notice Returns the current nonce for EIP2612 permission for the
    ///         provided token owner for a replay protection. Used to construct
    ///         EIP2612 signature provided to `permit` function.
    mapping(address => uint256) public override nonce;

    uint256 public immutable cachedChainId;
    bytes32 public immutable cachedDomainSeparator;

    /// @notice Returns EIP2612 Permit message hash. Used to construct EIP2612
    ///         signature provided to `permit` function.
    bytes32 public constant override PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    /// @notice The amount of tokens in existence.
    uint256 public override totalSupply;

    /// @notice The name of the token.
    string public override name;

    /// @notice The symbol of the token.
    string public override symbol;

    /// @notice The decimals places of the token.
    uint8 public constant override decimals = 18;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;

        cachedChainId = block.chainid;
        cachedDomainSeparator = buildDomainSeparator();
    }

    /// @notice Moves `amount` tokens from the caller's account to `recipient`.
    /// @return True if the operation succeeded, reverts otherwise.
    /// @dev Requirements:
    ///       - `recipient` cannot be the zero address,
    ///       - the caller must have a balance of at least `amount`.
    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /// @notice Moves `amount` tokens from `spender` to `recipient` using the
    ///         allowance mechanism. `amount` is then deducted from the caller's
    ///         allowance unless the allowance was made for `type(uint256).max`.
    /// @return True if the operation succeeded, reverts otherwise.
    /// @dev Requirements:
    ///      - `spender` and `recipient` cannot be the zero address,
    ///      - `spender` must have a balance of at least `amount`,
    ///      - the caller must have allowance for `spender`'s tokens of at least
    ///        `amount`.
    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        uint256 currentAllowance = allowance[spender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "Transfer amount exceeds allowance"
            );
            _approve(spender, msg.sender, currentAllowance - amount);
        }
        _transfer(spender, recipient, amount);
        return true;
    }

    /// @notice EIP2612 approval made with secp256k1 signature.
    ///         Users can authorize a transfer of their tokens with a signature
    ///         conforming EIP712 standard, rather than an on-chain transaction
    ///         from their address. Anyone can submit this signature on the
    ///         user's behalf by calling the permit function, paying gas fees,
    ///         and possibly performing other actions in the same transaction.
    /// @dev    The deadline argument can be set to `type(uint256).max to create
    ///         permits that effectively never expire.  If the `amount` is set
    ///         to `type(uint256).max` then `transferFrom` and `burnFrom` will
    ///         not reduce an allowance.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        /* solhint-disable-next-line not-rely-on-time */
        require(deadline >= block.timestamp, "Permission expired");

        // Validate `s` and `v` values for a malleability concern described in EIP2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order and `v` value of 27 or 28 are considered valid.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Invalid signature 's' value"
        );
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        amount,
                        nonce[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Invalid signature"
        );
        _approve(owner, spender, amount);
    }

    /// @notice Creates `amount` tokens and assigns them to `account`,
    ///         increasing the total supply.
    /// @dev Requirements:
    ///      - `recipient` cannot be the zero address.
    function mint(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Mint to the zero address");

        beforeTokenTransfer(address(0), recipient, amount);

        totalSupply += amount;
        balanceOf[recipient] += amount;
        emit Transfer(address(0), recipient, amount);
    }

    /// @notice Destroys `amount` tokens from the caller.
    /// @dev Requirements:
    ///       - the caller must have a balance of at least `amount`.
    function burn(uint256 amount) external override {
        _burn(msg.sender, amount);
    }

    /// @notice Destroys `amount` of tokens from `account` using the allowance
    ///         mechanism. `amount` is then deducted from the caller's allowance
    ///         unless the allowance was made for `type(uint256).max`.
    /// @dev Requirements:
    ///      - `account` must have a balance of at least `amount`,
    ///      - the caller must have allowance for `account`'s tokens of at least
    ///        `amount`.
    function burnFrom(address account, uint256 amount) external override {
        uint256 currentAllowance = allowance[account][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "Burn amount exceeds allowance"
            );
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }

    /// @notice Calls `receiveApproval` function on spender previously approving
    ///         the spender to withdraw from the caller multiple times, up to
    ///         the `amount` amount. If this function is called again, it
    ///         overwrites the current allowance with `amount`. Reverts if the
    ///         approval reverted or if `receiveApproval` call on the spender
    ///         reverted.
    /// @return True if both approval and `receiveApproval` calls succeeded.
    /// @dev If the `amount` is set to `type(uint256).max` then
    ///      `transferFrom` and `burnFrom` will not reduce an allowance.
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) external override returns (bool) {
        if (approve(spender, amount)) {
            IReceiveApproval(spender).receiveApproval(
                msg.sender,
                amount,
                address(this),
                extraData
            );
            return true;
        }
        return false;
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller's
    ///         tokens.
    /// @return True if the operation succeeded.
    /// @dev If the `amount` is set to `type(uint256).max` then
    ///      `transferFrom` and `burnFrom` will not reduce an allowance.
    ///      Beware that changing an allowance with this method brings the risk
    ///      that someone may use both the old and the new allowance by
    ///      unfortunate transaction ordering. One possible solution to mitigate
    ///      this race condition is to first reduce the spender's allowance to 0
    ///      and set the desired value afterwards:
    ///      https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /// @notice Returns hash of EIP712 Domain struct with the token name as
    ///         a signing domain and token contract as a verifying contract.
    ///         Used to construct EIP2612 signature provided to `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        // As explained in EIP-2612, if the DOMAIN_SEPARATOR contains the
        // chainId and is defined at contract deployment instead of
        // reconstructed for every signature, there is a risk of possible replay
        // attacks between chains in the event of a future chain split.
        // To address this issue, we check the cached chain ID against the
        // current one and in case they are different, we build domain separator
        // from scratch.
        if (block.chainid == cachedChainId) {
            return cachedDomainSeparator;
        } else {
            return buildDomainSeparator();
        }
    }

    /// @dev Hook that is called before any transfer of tokens. This includes
    ///      minting and burning.
    ///
    /// Calling conditions:
    /// - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
    ///   will be to transferred to `to`.
    /// - when `from` is zero, `amount` tokens will be minted for `to`.
    /// - when `to` is zero, `amount` of ``from``'s tokens will be burned.
    /// - `from` and `to` are never both zero.
    // slither-disable-next-line dead-code
    function beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _burn(address account, uint256 amount) internal {
        uint256 currentBalance = balanceOf[account];
        require(currentBalance >= amount, "Burn amount exceeds balance");

        beforeTokenTransfer(account, address(0), amount);

        balanceOf[account] = currentBalance - amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function _transfer(
        address spender,
        address recipient,
        uint256 amount
    ) private {
        require(spender != address(0), "Transfer from the zero address");
        require(recipient != address(0), "Transfer to the zero address");
        require(recipient != address(this), "Transfer to the token address");

        beforeTokenTransfer(spender, recipient, amount);

        uint256 spenderBalance = balanceOf[spender];
        require(spenderBalance >= amount, "Transfer amount exceeds balance");
        balanceOf[spender] = spenderBalance - amount;
        balanceOf[recipient] += amount;
        emit Transfer(spender, recipient, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "Approve from the zero address");
        require(spender != address(0), "Approve to the zero address");
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by tokens supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IApproveAndCall {
    /// @notice Executes `receiveApproval` function on spender as specified in
    ///         `IReceiveApproval` interface. Approves spender to withdraw from
    ///         the caller multiple times, up to the `amount`. If this
    ///         function is called again, it overwrites the current allowance
    ///         with `amount`. Reverts if the approval reverted or if
    ///         `receiveApproval` call on the spender reverted.
    function approveAndCall(
        address spender,
        uint256 amount,
        bytes memory extraData
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

import "./IApproveAndCall.sol";

/// @title  IERC20WithPermit
/// @notice Burnable ERC20 token with EIP2612 permit functionality. User can
///         authorize a transfer of their token with a signature conforming
///         EIP712 standard instead of an on-chain transaction from their
///         address. Anyone can submit this signature on the user's behalf by
///         calling the permit function, as specified in EIP2612 standard,
///         paying gas fees, and possibly performing other actions in the same
///         transaction.
interface IERC20WithPermit is IERC20, IERC20Metadata, IApproveAndCall {
    /// @notice EIP2612 approval made with secp256k1 signature.
    ///         Users can authorize a transfer of their tokens with a signature
    ///         conforming EIP712 standard, rather than an on-chain transaction
    ///         from their address. Anyone can submit this signature on the
    ///         user's behalf by calling the permit function, paying gas fees,
    ///         and possibly performing other actions in the same transaction.
    /// @dev    The deadline argument can be set to `type(uint256).max to create
    ///         permits that effectively never expire.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// @notice Destroys `amount` tokens from the caller.
    function burn(uint256 amount) external;

    /// @notice Destroys `amount` of tokens from `account`, deducting the amount
    ///         from caller's allowance.
    function burnFrom(address account, uint256 amount) external;

    /// @notice Returns hash of EIP712 Domain struct with the token name as
    ///         a signing domain and token contract as a verifying contract.
    ///         Used to construct EIP2612 signature provided to `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Returns the current nonce for EIP2612 permission for the
    ///         provided token owner for a replay protection. Used to construct
    ///         EIP2612 signature provided to `permit` function.
    function nonce(address owner) external view returns (uint256);

    /// @notice Returns EIP2612 Permit message hash. Used to construct EIP2612
    ///         signature provided to `permit` function.
    /* solhint-disable-next-line func-name-mixedcase */
    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @notice An interface that should be implemented by contracts supporting
///         `approveAndCall`/`receiveApproval` pattern.
interface IReceiveApproval {
    /// @notice Receives approval to spend tokens. Called as a result of
    ///         `approveAndCall` call on the token.
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title  MisfundRecovery
/// @notice Allows the owner of the token contract extending MisfundRecovery
///         to recover any ERC20 and ERC721 sent mistakenly to the token
///         contract address.
contract MisfundRecovery is Ownable {
    using SafeERC20 for IERC20;

    function recoverERC20(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(recipient, amount);
    }

    function recoverERC721(
        IERC721 token,
        address recipient,
        uint256 tokenId,
        bytes calldata data
    ) external onlyOwner {
        token.safeTransferFrom(address(this), recipient, tokenId, data);
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

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IReceiveBalanceApproval.sol";
import "../vault/IVault.sol";

/// @title Bitcoin Bank
/// @notice Bank is a central component tracking Bitcoin balances. Balances can
///         be transferred between balance owners, and balance owners can
///         approve their balances to be spent by others. Balances in the Bank
///         are updated for depositors who deposited their Bitcoin into the
///         Bridge and only the Bridge can increase balances.
/// @dev Bank is a governable contract and the Governance can upgrade the Bridge
///      address.
contract Bank is Ownable {
    address public bridge;

    /// @notice The balance of the given account in the Bank. Zero by default.
    mapping(address => uint256) public balanceOf;

    /// @notice The remaining amount of balance a spender will be
    ///         allowed to transfer on behalf of an owner using
    ///         `transferBalanceFrom`. Zero by default.
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice Returns the current nonce for an EIP2612 permission for the
    ///         provided balance owner to protect against replay attacks. Used
    ///         to construct an EIP2612 signature provided to the `permit`
    ///         function.
    mapping(address => uint256) public nonces;

    uint256 public immutable cachedChainId;
    bytes32 public immutable cachedDomainSeparator;

    /// @notice Returns an EIP2612 Permit message hash. Used to construct
    ///         an EIP2612 signature provided to the `permit` function.
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    event BalanceTransferred(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    event BalanceApproved(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    event BalanceIncreased(address indexed owner, uint256 amount);

    event BalanceDecreased(address indexed owner, uint256 amount);

    event BridgeUpdated(address newBridge);

    modifier onlyBridge() {
        require(msg.sender == address(bridge), "Caller is not the bridge");
        _;
    }

    constructor() {
        cachedChainId = block.chainid;
        cachedDomainSeparator = buildDomainSeparator();
    }

    /// @notice Allows the Governance to upgrade the Bridge address.
    /// @dev The function does not implement any governance delay and does not
    ///      check the status of the Bridge. The Governance implementation needs
    ///      to ensure all requirements for the upgrade are satisfied before
    ///      executing this function.
    ///      Requirements:
    ///      - The new Bridge address must not be zero.
    /// @param _bridge The new Bridge address.
    function updateBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "Bridge address must not be 0x0");
        bridge = _bridge;
        emit BridgeUpdated(_bridge);
    }

    /// @notice Moves the given `amount` of balance from the caller to
    ///         `recipient`.
    /// @dev Requirements:
    ///       - `recipient` cannot be the zero address,
    ///       - the caller must have a balance of at least `amount`.
    /// @param recipient The recipient of the balance.
    /// @param amount The amount of the balance transferred.
    function transferBalance(address recipient, uint256 amount) external {
        _transferBalance(msg.sender, recipient, amount);
    }

    /// @notice Sets `amount` as the allowance of `spender` over the caller's
    ///         balance. Does not allow updating an existing allowance to
    ///         a value that is non-zero to avoid someone using both the old and
    ///         the new allowance by unfortunate transaction ordering. To update
    ///         an allowance to a non-zero value please set it to zero first or
    ///         use `increaseBalanceAllowance` or `decreaseBalanceAllowance` for
    ///         an atomic update.
    /// @dev If the `amount` is set to `type(uint256).max`,
    ///      `transferBalanceFrom` will not reduce an allowance.
    /// @param spender The address that will be allowed to spend the balance.
    /// @param amount The amount the spender is allowed to spend.
    function approveBalance(address spender, uint256 amount) external {
        require(
            amount == 0 || allowance[msg.sender][spender] == 0,
            "Non-atomic allowance change not allowed"
        );
        _approveBalance(msg.sender, spender, amount);
    }

    /// @notice Sets the `amount` as an allowance of a smart contract `spender`
    ///         over the caller's balance and calls the `spender` via
    ///         `receiveBalanceApproval`.
    /// @dev If the `amount` is set to `type(uint256).max`, the potential
    ///     `transferBalanceFrom` executed in `receiveBalanceApproval` of
    ///      `spender` will not reduce an allowance. Beware that changing an
    ///      allowance with this function brings the risk that `spender` may use
    ///      both the old and the new allowance by unfortunate transaction
    ///      ordering. Please use `increaseBalanceAllowance` and
    ///      `decreaseBalanceAllowance` to eliminate the risk.
    /// @param spender The smart contract that will be allowed to spend the
    ///        balance.
    /// @param amount The amount the spender contract is allowed to spend.
    /// @param extraData Extra data passed to the `spender` contract via
    ///        `receiveBalanceApproval` call.
    function approveBalanceAndCall(
        address spender,
        uint256 amount,
        bytes calldata extraData
    ) external {
        _approveBalance(msg.sender, spender, amount);
        IReceiveBalanceApproval(spender).receiveBalanceApproval(
            msg.sender,
            amount,
            extraData
        );
    }

    /// @notice Atomically increases the caller's balance allowance granted to
    ///         `spender` by the given `addedValue`.
    /// @param spender The spender address for which the allowance is increased.
    /// @param addedValue The amount by which the allowance is increased.
    function increaseBalanceAllowance(address spender, uint256 addedValue)
        external
    {
        _approveBalance(
            msg.sender,
            spender,
            allowance[msg.sender][spender] + addedValue
        );
    }

    /// @notice Atomically decreases the caller's balance allowance granted to
    ///         `spender` by the given `subtractedValue`.
    /// @dev Requirements:
    ///      - `spender` must not be the zero address,
    ///      - the current allowance for `spender` must not be lower than
    ///        the `subtractedValue`.
    /// @param spender The spender address for which the allowance is decreased.
    /// @param subtractedValue The amount by which the allowance is decreased.
    function decreaseBalanceAllowance(address spender, uint256 subtractedValue)
        external
    {
        uint256 currentAllowance = allowance[msg.sender][spender];
        require(
            currentAllowance >= subtractedValue,
            "Can not decrease balance allowance below zero"
        );
        unchecked {
            _approveBalance(
                msg.sender,
                spender,
                currentAllowance - subtractedValue
            );
        }
    }

    /// @notice Moves `amount` of balance from `spender` to `recipient` using the
    ///         allowance mechanism. `amount` is then deducted from the caller's
    ///         allowance unless the allowance was made for `type(uint256).max`.
    /// @dev Requirements:
    ///      - `recipient` cannot be the zero address,
    ///      - `spender` must have a balance of at least `amount`,
    ///      - the caller must have an allowance for `spender`'s balance of at
    ///        least `amount`.
    /// @param spender The address from which the balance is transferred.
    /// @param recipient The address to which the balance is transferred.
    /// @param amount The amount of balance that is transferred.
    function transferBalanceFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external {
        uint256 currentAllowance = allowance[spender][msg.sender];
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "Transfer amount exceeds allowance"
            );
            unchecked {
                _approveBalance(spender, msg.sender, currentAllowance - amount);
            }
        }
        _transferBalance(spender, recipient, amount);
    }

    /// @notice An EIP2612 approval made with secp256k1 signature. Users can
    ///         authorize a transfer of their balance with a signature
    ///         conforming to the EIP712 standard, rather than an on-chain
    ///         transaction from their address. Anyone can submit this signature
    ///         on the user's behalf by calling the `permit` function, paying
    ///         gas fees, and possibly performing other actions in the same
    ///         transaction.
    /// @dev The deadline argument can be set to `type(uint256).max to create
    ///      permits that effectively never expire.  If the `amount` is set
    ///      to `type(uint256).max` then `transferBalanceFrom` will not
    ///      reduce an allowance. Beware that changing an allowance with this
    ///      function brings the risk that someone may use both the old and the
    ///      new allowance by unfortunate transaction ordering. Please use
    ///      `increaseBalanceAllowance` and `decreaseBalanceAllowance` to
    ///      eliminate the risk.
    /// @param owner The balance owner who signed the permission.
    /// @param spender The address that will be allowed to spend the balance.
    /// @param amount The amount the spender is allowed to spend.
    /// @param deadline The UNIX time until which the permit is valid.
    /// @param v V part of the permit signature.
    /// @param r R part of the permit signature.
    /// @param s S part of the permit signature.
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        /* solhint-disable-next-line not-rely-on-time */
        require(deadline >= block.timestamp, "Permission expired");

        // Validate `s` and `v` values for a malleability concern described in EIP2.
        // Only signatures with `s` value in the lower half of the secp256k1
        // curve's order and `v` value of 27 or 28 are considered valid.
        require(
            uint256(s) <=
                0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Invalid signature 's' value"
        );
        require(v == 27 || v == 28, "Invalid signature 'v' value");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        amount,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(
            recoveredAddress != address(0) && recoveredAddress == owner,
            "Invalid signature"
        );
        _approveBalance(owner, spender, amount);
    }

    /// @notice Increases balances of the provided `recipients` by the provided
    ///         `amounts`. Can only be called by the Bridge.
    /// @dev Requirements:
    ///       - length of `recipients` and `amounts` must be the same,
    ///       - none of `recipients` addresses must point to the Bank.
    /// @param recipients Balance increase recipients.
    /// @param amounts Amounts by which balances are increased.
    function increaseBalances(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyBridge {
        require(
            recipients.length == amounts.length,
            "Arrays must have the same length"
        );
        for (uint256 i = 0; i < recipients.length; i++) {
            _increaseBalance(recipients[i], amounts[i]);
        }
    }

    /// @notice Increases balance of the provided `recipient` by the provided
    ///         `amount`. Can only be called by the Bridge.
    /// @dev Requirements:
    ///      - `recipient` address must not point to the Bank.
    /// @param recipient Balance increase recipient.
    /// @param amount Amount by which the balance is increased.
    function increaseBalance(address recipient, uint256 amount)
        external
        onlyBridge
    {
        _increaseBalance(recipient, amount);
    }

    /// @notice Increases the given smart contract `vault`'s balance and
    ///         notifies the `vault` contract about it.
    ///         Can be called only by the Bridge.
    /// @dev Requirements:
    ///       - `vault` must implement `IVault` interface,
    ///       - length of `recipients` and `amounts` must be the same.
    /// @param vault Address of `IVault` recipient contract.
    /// @param recipients Balance increase recipients.
    /// @param amounts Amounts by which balances are increased.
    function increaseBalanceAndCall(
        address vault,
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyBridge {
        require(
            recipients.length == amounts.length,
            "Arrays must have the same length"
        );
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            totalAmount += amounts[i];
        }
        _increaseBalance(vault, totalAmount);
        IVault(vault).receiveBalanceIncrease(recipients, amounts);
    }

    /// @notice Decreases caller's balance by the provided `amount`. There is no
    ///         way to restore the balance so do not call this function unless
    ///         you really know what you are doing!
    /// @dev Requirements:
    ///      - The caller must have a balance of at least `amount`.
    /// @param amount The amount by which the balance is decreased.
    function decreaseBalance(uint256 amount) external {
        balanceOf[msg.sender] -= amount;
        emit BalanceDecreased(msg.sender, amount);
    }

    /// @notice Returns hash of EIP712 Domain struct with `TBTC Bank` as
    ///         a signing domain and Bank contract as a verifying contract.
    ///         Used to construct an EIP2612 signature provided to the `permit`
    ///         function.
    /* solhint-disable-next-line func-name-mixedcase */
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        // As explained in EIP-2612, if the DOMAIN_SEPARATOR contains the
        // chainId and is defined at contract deployment instead of
        // reconstructed for every signature, there is a risk of possible replay
        // attacks between chains in the event of a future chain split.
        // To address this issue, we check the cached chain ID against the
        // current one and in case they are different, we build domain separator
        // from scratch.
        if (block.chainid == cachedChainId) {
            return cachedDomainSeparator;
        } else {
            return buildDomainSeparator();
        }
    }

    function _increaseBalance(address recipient, uint256 amount) internal {
        require(
            recipient != address(this),
            "Can not increase balance for Bank"
        );
        balanceOf[recipient] += amount;
        emit BalanceIncreased(recipient, amount);
    }

    function _transferBalance(
        address spender,
        address recipient,
        uint256 amount
    ) private {
        require(
            recipient != address(0),
            "Can not transfer to the zero address"
        );
        require(
            recipient != address(this),
            "Can not transfer to the Bank address"
        );

        uint256 spenderBalance = balanceOf[spender];
        require(spenderBalance >= amount, "Transfer amount exceeds balance");
        unchecked {
            balanceOf[spender] = spenderBalance - amount;
        }
        balanceOf[recipient] += amount;
        emit BalanceTransferred(spender, recipient, amount);
    }

    function _approveBalance(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(spender != address(0), "Can not approve to the zero address");
        allowance[owner][spender] = amount;
        emit BalanceApproved(owner, spender, amount);
    }

    function buildDomainSeparator() private view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("TBTC Bank")),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
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

/// @title IReceiveBalanceApproval
/// @notice `IReceiveBalanceApproval` is an interface for a smart contract
///         consuming Bank balances approved to them in the same transaction by
///         other contracts or externally owned accounts (EOA).
interface IReceiveBalanceApproval {
    /// @notice Called by the Bank in `approveBalanceAndCall` function after
    ///         the balance `owner` approved `amount` of their balance in the
    ///         Bank for the contract. This way, the depositor can approve
    ///         balance and call the contract to use the approved balance in
    ///         a single transaction.
    /// @param owner Address of the Bank balance owner who approved their
    ///        balance to be used by the contract.
    /// @param amount The amount of the Bank balance approved by the owner
    ///        to be used by the contract.
    /// @param extraData The `extraData` passed to `Bank.approveBalanceAndCall`.
    /// @dev The implementation must ensure this function can only be called
    ///      by the Bank. The Bank does _not_ guarantee that the `amount`
    ///      approved by the `owner` currently exists on their balance. That is,
    ///      the `owner` could approve more balance than they currently have.
    ///      This works the same as `Bank.approve` function. The contract must
    ///      ensure the actual balance is checked before performing any action
    ///      based on it.
    function receiveBalanceApproval(
        address owner,
        uint256 amount,
        bytes calldata extraData
    ) external;
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

import {BTCUtils} from "@keep-network/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@keep-network/bitcoin-spv-sol/contracts/BytesLib.sol";
import {ValidateSPV} from "@keep-network/bitcoin-spv-sol/contracts/ValidateSPV.sol";

import "./BridgeState.sol";

/// @title Bitcoin transaction
/// @notice Allows to reference Bitcoin raw transaction in Solidity.
/// @dev See https://developer.bitcoin.org/reference/transactions.html#raw-transaction-format
///
///      Raw Bitcoin transaction data:
///
///      | Bytes  |     Name     |        BTC type        |        Description        |
///      |--------|--------------|------------------------|---------------------------|
///      | 4      | version      | int32_t (LE)           | TX version number         |
///      | varies | tx_in_count  | compactSize uint (LE)  | Number of TX inputs       |
///      | varies | tx_in        | txIn[]                 | TX inputs                 |
///      | varies | tx_out_count | compactSize uint (LE)  | Number of TX outputs      |
///      | varies | tx_out       | txOut[]                | TX outputs                |
///      | 4      | lock_time    | uint32_t (LE)          | Unix time or block number |
///
//
///      Non-coinbase transaction input (txIn):
///
///      | Bytes  |       Name       |        BTC type        |                 Description                 |
///      |--------|------------------|------------------------|---------------------------------------------|
///      | 36     | previous_output  | outpoint               | The previous outpoint being spent           |
///      | varies | script_bytes     | compactSize uint (LE)  | The number of bytes in the signature script |
///      | varies | signature_script | char[]                 | The signature script, empty for P2WSH       |
///      | 4      | sequence         | uint32_t (LE)          | Sequence number                             |
///
///
///      The reference to transaction being spent (outpoint):
///
///      | Bytes | Name  |   BTC type    |               Description                |
///      |-------|-------|---------------|------------------------------------------|
///      |    32 | hash  | char[32]      | Hash of the transaction to spend         |
///      |    4  | index | uint32_t (LE) | Index of the specific output from the TX |
///
///
///      Transaction output (txOut):
///
///      | Bytes  |      Name       |     BTC type          |             Description              |
///      |--------|-----------------|-----------------------|--------------------------------------|
///      | 8      | value           | int64_t (LE)          | Number of satoshis to spend          |
///      | 1+     | pk_script_bytes | compactSize uint (LE) | Number of bytes in the pubkey script |
///      | varies | pk_script       | char[]                | Pubkey script                        |
///
///      compactSize uint format:
///
///      |                  Value                  | Bytes |                    Format                    |
///      |-----------------------------------------|-------|----------------------------------------------|
///      | >= 0 && <= 252                          | 1     | uint8_t                                      |
///      | >= 253 && <= 0xffff                     | 3     | 0xfd followed by the number as uint16_t (LE) |
///      | >= 0x10000 && <= 0xffffffff             | 5     | 0xfe followed by the number as uint32_t (LE) |
///      | >= 0x100000000 && <= 0xffffffffffffffff | 9     | 0xff followed by the number as uint64_t (LE) |
///
///      (*) compactSize uint is often references as VarInt)
///
///      Coinbase transaction input (txIn):
///
///      | Bytes  |       Name       |        BTC type        |                 Description                 |
///      |--------|------------------|------------------------|---------------------------------------------|
///      | 32     | hash             | char[32]               | A 32-byte 0x0  null (no previous_outpoint)  |
///      | 4      | index            | uint32_t (LE)          | 0xffffffff (no previous_outpoint)           |
///      | varies | script_bytes     | compactSize uint (LE)  | The number of bytes in the coinbase script  |
///      | varies | height           | char[]                 | The block height of this block (BIP34) (*)  |
///      | varies | coinbase_script  | none                   |  Arbitrary data, max 100 bytes              |
///      | 4      | sequence         | uint32_t (LE)          | Sequence number
///
///      (*)  Uses script language: starts with a data-pushing opcode that indicates how many bytes to push to
///           the stack followed by the block height as a little-endian unsigned integer. This script must be as
///           short as possible, otherwise it may be rejected. The data-pushing opcode will be 0x03 and the total
///           size four bytes until block 16,777,216 about 300 years from now.
library BitcoinTx {
    using BTCUtils for bytes;
    using BTCUtils for uint256;
    using BytesLib for bytes;
    using ValidateSPV for bytes;
    using ValidateSPV for bytes32;

    /// @notice Represents Bitcoin transaction data.
    struct Info {
        /// @notice Bitcoin transaction version.
        /// @dev `version` from raw Bitcoin transaction data.
        ///      Encoded as 4-bytes signed integer, little endian.
        bytes4 version;
        /// @notice All Bitcoin transaction inputs, prepended by the number of
        ///         transaction inputs.
        /// @dev `tx_in_count | tx_in` from raw Bitcoin transaction data.
        ///
        ///      The number of transaction inputs encoded as compactSize
        ///      unsigned integer, little-endian.
        ///
        ///      Note that some popular block explorers reverse the order of
        ///      bytes from `outpoint`'s `hash` and display it as big-endian.
        ///      Solidity code of Bridge expects hashes in little-endian, just
        ///      like they are represented in a raw Bitcoin transaction.
        bytes inputVector;
        /// @notice All Bitcoin transaction outputs prepended by the number of
        ///         transaction outputs.
        /// @dev `tx_out_count | tx_out` from raw Bitcoin transaction data.
        ///
        ///       The number of transaction outputs encoded as a compactSize
        ///       unsigned integer, little-endian.
        bytes outputVector;
        /// @notice Bitcoin transaction locktime.
        ///
        /// @dev `lock_time` from raw Bitcoin transaction data.
        ///      Encoded as 4-bytes unsigned integer, little endian.
        bytes4 locktime;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's calldata argument.
    }

    /// @notice Represents data needed to perform a Bitcoin SPV proof.
    struct Proof {
        /// @notice The merkle proof of transaction inclusion in a block.
        bytes merkleProof;
        /// @notice Transaction index in the block (0-indexed).
        uint256 txIndexInBlock;
        /// @notice Single byte-string of 80-byte bitcoin headers,
        ///         lowest height first.
        bytes bitcoinHeaders;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's calldata argument.
    }

    /// @notice Represents info about an unspent transaction output.
    struct UTXO {
        /// @notice Hash of the transaction the output belongs to.
        /// @dev Byte order corresponds to the Bitcoin internal byte order.
        bytes32 txHash;
        /// @notice Index of the transaction output (0-indexed).
        uint32 txOutputIndex;
        /// @notice Value of the transaction output.
        uint64 txOutputValue;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's calldata argument.
    }

    /// @notice Represents Bitcoin signature in the R/S/V format.
    struct RSVSignature {
        /// @notice Signature r value.
        bytes32 r;
        /// @notice Signature s value.
        bytes32 s;
        /// @notice Signature recovery value.
        uint8 v;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's calldata argument.
    }

    /// @notice Validates the SPV proof of the Bitcoin transaction.
    ///         Reverts in case the validation or proof verification fail.
    /// @param txInfo Bitcoin transaction data.
    /// @param proof Bitcoin proof data.
    /// @return txHash Proven 32-byte transaction hash.
    function validateProof(
        BridgeState.Storage storage self,
        Info calldata txInfo,
        Proof calldata proof
    ) internal view returns (bytes32 txHash) {
        require(
            txInfo.inputVector.validateVin(),
            "Invalid input vector provided"
        );
        require(
            txInfo.outputVector.validateVout(),
            "Invalid output vector provided"
        );

        txHash = abi
            .encodePacked(
                txInfo.version,
                txInfo.inputVector,
                txInfo.outputVector,
                txInfo.locktime
            )
            .hash256View();

        require(
            txHash.prove(
                proof.bitcoinHeaders.extractMerkleRootLE(),
                proof.merkleProof,
                proof.txIndexInBlock
            ),
            "Tx merkle proof is not valid for provided header and tx hash"
        );

        evaluateProofDifficulty(self, proof.bitcoinHeaders);

        return txHash;
    }

    /// @notice Evaluates the given Bitcoin proof difficulty against the actual
    ///         Bitcoin chain difficulty provided by the relay oracle.
    ///         Reverts in case the evaluation fails.
    /// @param bitcoinHeaders Bitcoin headers chain being part of the SPV
    ///        proof. Used to extract the observed proof difficulty.
    function evaluateProofDifficulty(
        BridgeState.Storage storage self,
        bytes memory bitcoinHeaders
    ) internal view {
        IRelay relay = self.relay;
        uint256 currentEpochDifficulty = relay.getCurrentEpochDifficulty();
        uint256 previousEpochDifficulty = relay.getPrevEpochDifficulty();

        uint256 requestedDiff = 0;
        uint256 firstHeaderDiff = bitcoinHeaders
            .extractTarget()
            .calculateDifficulty();

        if (firstHeaderDiff == currentEpochDifficulty) {
            requestedDiff = currentEpochDifficulty;
        } else if (firstHeaderDiff == previousEpochDifficulty) {
            requestedDiff = previousEpochDifficulty;
        } else {
            revert("Not at current or previous difficulty");
        }

        uint256 observedDiff = bitcoinHeaders.validateHeaderChain();

        require(
            observedDiff != ValidateSPV.getErrBadLength(),
            "Invalid length of the headers chain"
        );
        require(
            observedDiff != ValidateSPV.getErrInvalidChain(),
            "Invalid headers chain"
        );
        require(
            observedDiff != ValidateSPV.getErrLowWork(),
            "Insufficient work in a header"
        );

        require(
            observedDiff >= requestedDiff * self.txProofDifficultyFactor,
            "Insufficient accumulated difficulty in header chain"
        );
    }

    /// @notice Extracts public key hash from the provided P2PKH or P2WPKH output.
    ///         Reverts if the validation fails.
    /// @param output The transaction output.
    /// @return pubKeyHash 20-byte public key hash the output locks funds on.
    /// @dev Requirements:
    ///      - The output must be of P2PKH or P2WPKH type and lock the funds
    ///        on a 20-byte public key hash.
    function extractPubKeyHash(BridgeState.Storage storage, bytes memory output)
        internal
        pure
        returns (bytes20 pubKeyHash)
    {
        bytes memory pubKeyHashBytes = output.extractHash();

        require(
            pubKeyHashBytes.length == 20,
            "Output's public key hash must have 20 bytes"
        );

        pubKeyHash = pubKeyHashBytes.slice20(0);

        // The output consists of an 8-byte value and a variable length script.
        // To extract just the script, we ignore the first 8 bytes.
        uint256 scriptLen = output.length - 8;

        // The P2PKH script is 26 bytes long.
        // The P2WPKH script is 23 bytes long.
        // A valid script must have one of these lengths,
        // and we can identify the expected script type by the length.
        require(
            scriptLen == 26 || scriptLen == 23,
            "Output must be P2PKH or P2WPKH"
        );

        if (scriptLen == 26) {
            // Compare to the expected P2PKH script.
            bytes26 script = bytes26(output.slice32(8));

            require(
                script == makeP2PKHScript(pubKeyHash),
                "Invalid P2PKH script"
            );
        }

        if (scriptLen == 23) {
            // Compare to the expected P2WPKH script.
            bytes23 script = bytes23(output.slice32(8));

            require(
                script == makeP2WPKHScript(pubKeyHash),
                "Invalid P2WPKH script"
            );
        }

        return pubKeyHash;
    }

    /// @notice Build the P2PKH script from the given public key hash.
    /// @param pubKeyHash The 20-byte public key hash.
    /// @return The P2PKH script.
    /// @dev The P2PKH script has the following byte format:
    ///      <0x1976a914> <20-byte PKH> <0x88ac>. According to
    ///      https://en.bitcoin.it/wiki/Script#Opcodes this translates to:
    ///      - 0x19: Byte length of the entire script
    ///      - 0x76: OP_DUP
    ///      - 0xa9: OP_HASH160
    ///      - 0x14: Byte length of the public key hash
    ///      - 0x88: OP_EQUALVERIFY
    ///      - 0xac: OP_CHECKSIG
    ///      which matches the P2PKH structure as per:
    ///      https://en.bitcoin.it/wiki/Transaction#Pay-to-PubkeyHash
    function makeP2PKHScript(bytes20 pubKeyHash)
        internal
        pure
        returns (bytes26)
    {
        bytes26 P2PKHScriptMask = hex"1976a914000000000000000000000000000000000000000088ac";

        return ((bytes26(pubKeyHash) >> 32) | P2PKHScriptMask);
    }

    /// @notice Build the P2WPKH script from the given public key hash.
    /// @param pubKeyHash The 20-byte public key hash.
    /// @return The P2WPKH script.
    /// @dev The P2WPKH script has the following format:
    ///      <0x160014> <20-byte PKH>. According to
    ///      https://en.bitcoin.it/wiki/Script#Opcodes this translates to:
    ///      - 0x16: Byte length of the entire script
    ///      - 0x00: OP_0
    ///      - 0x14: Byte length of the public key hash
    ///      which matches the P2WPKH structure as per:
    ///      https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki#P2WPKH
    function makeP2WPKHScript(bytes20 pubKeyHash)
        internal
        pure
        returns (bytes23)
    {
        bytes23 P2WPKHScriptMask = hex"1600140000000000000000000000000000000000000000";

        return ((bytes23(pubKeyHash) >> 24) | P2WPKHScriptMask);
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

import "@keep-network/random-beacon/contracts/Governable.sol";
import "@keep-network/random-beacon/contracts/ReimbursementPool.sol";
import {IWalletOwner as EcdsaWalletOwner} from "@keep-network/ecdsa/contracts/api/IWalletOwner.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import "./IRelay.sol";
import "./BridgeState.sol";
import "./Deposit.sol";
import "./DepositSweep.sol";
import "./Redemption.sol";
import "./BitcoinTx.sol";
import "./EcdsaLib.sol";
import "./Wallets.sol";
import "./Fraud.sol";
import "./MovingFunds.sol";

import "../bank/IReceiveBalanceApproval.sol";
import "../bank/Bank.sol";

/// @title Bitcoin Bridge
/// @notice Bridge manages BTC deposit and redemption flow and is increasing and
///         decreasing balances in the Bank as a result of BTC deposit and
///         redemption operations performed by depositors and redeemers.
///
///         Depositors send BTC funds to the most recently created off-chain
///         ECDSA wallet of the bridge using pay-to-script-hash (P2SH) or
///         pay-to-witness-script-hash (P2WSH) containing hashed information
///         about the depositor’s Ethereum address. Then, the depositor reveals
///         their Ethereum address along with their deposit blinding factor,
///         refund public key hash and refund locktime to the Bridge on Ethereum
///         chain. The off-chain ECDSA wallet listens for these sorts of
///         messages and when it gets one, it checks the Bitcoin network to make
///         sure the deposit lines up. If it does, the off-chain ECDSA wallet
///         may decide to pick the deposit transaction for sweeping, and when
///         the sweep operation is confirmed on the Bitcoin network, the ECDSA
///         wallet informs the Bridge about the sweep increasing appropriate
///         balances in the Bank.
/// @dev Bridge is an upgradeable component of the Bank. The order of
///      functionalities in this contract is: deposit, sweep, redemption,
///      moving funds, wallet lifecycle, frauds, parameters.
contract Bridge is
    Governable,
    EcdsaWalletOwner,
    Initializable,
    IReceiveBalanceApproval
{
    using BridgeState for BridgeState.Storage;
    using Deposit for BridgeState.Storage;
    using DepositSweep for BridgeState.Storage;
    using Redemption for BridgeState.Storage;
    using MovingFunds for BridgeState.Storage;
    using Wallets for BridgeState.Storage;
    using Fraud for BridgeState.Storage;

    BridgeState.Storage internal self;

    event DepositRevealed(
        bytes32 fundingTxHash,
        uint32 fundingOutputIndex,
        address indexed depositor,
        uint64 amount,
        bytes8 blindingFactor,
        bytes20 indexed walletPubKeyHash,
        bytes20 refundPubKeyHash,
        bytes4 refundLocktime,
        address vault
    );

    event DepositsSwept(bytes20 walletPubKeyHash, bytes32 sweepTxHash);

    event RedemptionRequested(
        bytes20 indexed walletPubKeyHash,
        bytes redeemerOutputScript,
        address indexed redeemer,
        uint64 requestedAmount,
        uint64 treasuryFee,
        uint64 txMaxFee
    );

    event RedemptionsCompleted(
        bytes20 indexed walletPubKeyHash,
        bytes32 redemptionTxHash
    );

    event RedemptionTimedOut(
        bytes20 indexed walletPubKeyHash,
        bytes redeemerOutputScript
    );

    event WalletMovingFunds(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event MovingFundsCommitmentSubmitted(
        bytes20 indexed walletPubKeyHash,
        bytes20[] targetWallets,
        address submitter
    );

    event MovingFundsTimeoutReset(bytes20 indexed walletPubKeyHash);

    event MovingFundsCompleted(
        bytes20 indexed walletPubKeyHash,
        bytes32 movingFundsTxHash
    );

    event MovingFundsTimedOut(bytes20 indexed walletPubKeyHash);

    event MovingFundsBelowDustReported(bytes20 indexed walletPubKeyHash);

    event MovedFundsSwept(
        bytes20 indexed walletPubKeyHash,
        bytes32 sweepTxHash
    );

    event MovedFundsSweepTimedOut(
        bytes20 indexed walletPubKeyHash,
        bytes32 movingFundsTxHash,
        uint32 movingFundsTxOutputIndex
    );

    event NewWalletRequested();

    event NewWalletRegistered(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event WalletClosing(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event WalletClosed(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event WalletTerminated(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event FraudChallengeSubmitted(
        bytes20 indexed walletPubKeyHash,
        bytes32 sighash,
        uint8 v,
        bytes32 r,
        bytes32 s
    );

    event FraudChallengeDefeated(
        bytes20 indexed walletPubKeyHash,
        bytes32 sighash
    );

    event FraudChallengeDefeatTimedOut(
        bytes20 indexed walletPubKeyHash,
        bytes32 sighash
    );

    event VaultStatusUpdated(address indexed vault, bool isTrusted);

    event SpvMaintainerStatusUpdated(
        address indexed spvMaintainer,
        bool isTrusted
    );

    event DepositParametersUpdated(
        uint64 depositDustThreshold,
        uint64 depositTreasuryFeeDivisor,
        uint64 depositTxMaxFee,
        uint32 depositRevealAheadPeriod
    );

    event RedemptionParametersUpdated(
        uint64 redemptionDustThreshold,
        uint64 redemptionTreasuryFeeDivisor,
        uint64 redemptionTxMaxFee,
        uint64 redemptionTxMaxTotalFee,
        uint32 redemptionTimeout,
        uint96 redemptionTimeoutSlashingAmount,
        uint32 redemptionTimeoutNotifierRewardMultiplier
    );

    event MovingFundsParametersUpdated(
        uint64 movingFundsTxMaxTotalFee,
        uint64 movingFundsDustThreshold,
        uint32 movingFundsTimeoutResetDelay,
        uint32 movingFundsTimeout,
        uint96 movingFundsTimeoutSlashingAmount,
        uint32 movingFundsTimeoutNotifierRewardMultiplier,
        uint16 movingFundsCommitmentGasOffset,
        uint64 movedFundsSweepTxMaxTotalFee,
        uint32 movedFundsSweepTimeout,
        uint96 movedFundsSweepTimeoutSlashingAmount,
        uint32 movedFundsSweepTimeoutNotifierRewardMultiplier
    );

    event WalletParametersUpdated(
        uint32 walletCreationPeriod,
        uint64 walletCreationMinBtcBalance,
        uint64 walletCreationMaxBtcBalance,
        uint64 walletClosureMinBtcBalance,
        uint32 walletMaxAge,
        uint64 walletMaxBtcTransfer,
        uint32 walletClosingPeriod
    );

    event FraudParametersUpdated(
        uint96 fraudChallengeDepositAmount,
        uint32 fraudChallengeDefeatTimeout,
        uint96 fraudSlashingAmount,
        uint32 fraudNotifierRewardMultiplier
    );

    event TreasuryUpdated(address treasury);

    modifier onlySpvMaintainer() {
        require(
            self.isSpvMaintainer[msg.sender],
            "Caller is not SPV maintainer"
        );
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Initializes upgradable contract on deployment.
    /// @param _bank Address of the Bank the Bridge belongs to.
    /// @param _relay Address of the Bitcoin relay providing the current Bitcoin
    ///        network difficulty.
    /// @param _treasury Address where the deposit and redemption treasury fees
    ///        will be sent to.
    /// @param _ecdsaWalletRegistry Address of the ECDSA Wallet Registry contract.
    /// @param _reimbursementPool Address of the Reimbursement Pool contract.
    /// @param _txProofDifficultyFactor The number of confirmations on the Bitcoin
    ///        chain required to successfully evaluate an SPV proof.
    function initialize(
        address _bank,
        address _relay,
        address _treasury,
        address _ecdsaWalletRegistry,
        address payable _reimbursementPool,
        uint96 _txProofDifficultyFactor
    ) external initializer {
        require(_bank != address(0), "Bank address cannot be zero");
        self.bank = Bank(_bank);

        require(_relay != address(0), "Relay address cannot be zero");
        self.relay = IRelay(_relay);

        require(
            _ecdsaWalletRegistry != address(0),
            "ECDSA Wallet Registry address cannot be zero"
        );
        self.ecdsaWalletRegistry = EcdsaWalletRegistry(_ecdsaWalletRegistry);

        require(
            _reimbursementPool != address(0),
            "Reimbursement Pool address cannot be zero"
        );
        self.reimbursementPool = ReimbursementPool(_reimbursementPool);

        require(_treasury != address(0), "Treasury address cannot be zero");
        self.treasury = _treasury;

        self.txProofDifficultyFactor = _txProofDifficultyFactor;

        //
        // All parameters set in the constructor are initial ones, used at the
        // moment contracts were deployed for the first time. Parameters are
        // governable and values assigned in the constructor do not need to
        // reflect the current ones. Keep in mind the initial parameters are
        // pretty forgiving and valid only for the early stage of the network.
        //

        self.depositDustThreshold = 1000000; // 1000000 satoshi = 0.01 BTC
        self.depositTxMaxFee = 100000; // 100000 satoshi = 0.001 BTC
        self.depositRevealAheadPeriod = 15 days;
        self.depositTreasuryFeeDivisor = 2000; // 1/2000 == 5bps == 0.05% == 0.0005
        self.redemptionDustThreshold = 1000000; // 1000000 satoshi = 0.01 BTC
        self.redemptionTreasuryFeeDivisor = 2000; // 1/2000 == 5bps == 0.05% == 0.0005
        self.redemptionTxMaxFee = 100000; // 100000 satoshi = 0.001 BTC
        self.redemptionTxMaxTotalFee = 1000000; // 1000000 satoshi = 0.01 BTC
        self.redemptionTimeout = 5 days;
        self.redemptionTimeoutSlashingAmount = 100 * 1e18; // 100 T
        self.redemptionTimeoutNotifierRewardMultiplier = 100; // 100%
        self.movingFundsTxMaxTotalFee = 100000; // 100000 satoshi = 0.001 BTC
        self.movingFundsDustThreshold = 200000; // 200000 satoshi = 0.002 BTC
        self.movingFundsTimeoutResetDelay = 6 days;
        self.movingFundsTimeout = 7 days;
        self.movingFundsTimeoutSlashingAmount = 100 * 1e18; // 100 T
        self.movingFundsTimeoutNotifierRewardMultiplier = 100; //100%
        self.movingFundsCommitmentGasOffset = 15000;
        self.movedFundsSweepTxMaxTotalFee = 100000; // 100000 satoshi = 0.001 BTC
        self.movedFundsSweepTimeout = 7 days;
        self.movedFundsSweepTimeoutSlashingAmount = 100 * 1e18; // 100 T
        self.movedFundsSweepTimeoutNotifierRewardMultiplier = 100; //100%
        self.fraudChallengeDepositAmount = 5 ether;
        self.fraudChallengeDefeatTimeout = 7 days;
        self.fraudSlashingAmount = 100 * 1e18; // 100 T
        self.fraudNotifierRewardMultiplier = 100; // 100%
        self.walletCreationPeriod = 1 weeks;
        self.walletCreationMinBtcBalance = 1e8; // 1 BTC
        self.walletCreationMaxBtcBalance = 100e8; // 100 BTC
        self.walletClosureMinBtcBalance = 5 * 1e7; // 0.5 BTC
        self.walletMaxAge = 26 weeks; // ~6 months
        self.walletMaxBtcTransfer = 10e8; // 10 BTC
        self.walletClosingPeriod = 40 days;

        _transferGovernance(msg.sender);
    }

    /// @notice Used by the depositor to reveal information about their P2(W)SH
    ///         Bitcoin deposit to the Bridge on Ethereum chain. The off-chain
    ///         wallet listens for revealed deposit events and may decide to
    ///         include the revealed deposit in the next executed sweep.
    ///         Information about the Bitcoin deposit can be revealed before or
    ///         after the Bitcoin transaction with P2(W)SH deposit is mined on
    ///         the Bitcoin chain. Worth noting, the gas cost of this function
    ///         scales with the number of P2(W)SH transaction inputs and
    ///         outputs. The deposit may be routed to one of the trusted vaults.
    ///         When a deposit is routed to a vault, vault gets notified when
    ///         the deposit gets swept and it may execute the appropriate action.
    /// @param fundingTx Bitcoin funding transaction data, see `BitcoinTx.Info`.
    /// @param reveal Deposit reveal data, see `RevealInfo struct.
    /// @dev Requirements:
    ///      - This function must be called by the same Ethereum address as the
    ///        one used in the P2(W)SH BTC deposit transaction as a depositor,
    ///      - `reveal.walletPubKeyHash` must identify a `Live` wallet,
    ///      - `reveal.vault` must be 0x0 or point to a trusted vault,
    ///      - `reveal.fundingOutputIndex` must point to the actual P2(W)SH
    ///        output of the BTC deposit transaction,
    ///      - `reveal.blindingFactor` must be the blinding factor used in the
    ///        P2(W)SH BTC deposit transaction,
    ///      - `reveal.walletPubKeyHash` must be the wallet pub key hash used in
    ///        the P2(W)SH BTC deposit transaction,
    ///      - `reveal.refundPubKeyHash` must be the refund pub key hash used in
    ///        the P2(W)SH BTC deposit transaction,
    ///      - `reveal.refundLocktime` must be the refund locktime used in the
    ///        P2(W)SH BTC deposit transaction,
    ///      - BTC deposit for the given `fundingTxHash`, `fundingOutputIndex`
    ///        can be revealed only one time.
    ///
    ///      If any of these requirements is not met, the wallet _must_ refuse
    ///      to sweep the deposit and the depositor has to wait until the
    ///      deposit script unlocks to receive their BTC back.
    function revealDeposit(
        BitcoinTx.Info calldata fundingTx,
        Deposit.DepositRevealInfo calldata reveal
    ) external {
        self.revealDeposit(fundingTx, reveal);
    }

    /// @notice Used by the wallet to prove the BTC deposit sweep transaction
    ///         and to update Bank balances accordingly. Sweep is only accepted
    ///         if it satisfies SPV proof.
    ///
    ///         The function is performing Bank balance updates by first
    ///         computing the Bitcoin fee for the sweep transaction. The fee is
    ///         divided evenly between all swept deposits. Each depositor
    ///         receives a balance in the bank equal to the amount inferred
    ///         during the reveal transaction, minus their fee share.
    ///
    ///         It is possible to prove the given sweep only one time.
    /// @param sweepTx Bitcoin sweep transaction data.
    /// @param sweepProof Bitcoin sweep proof data.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain. If no main UTXO exists for the given wallet,
    ///        this parameter is ignored.
    /// @param vault Optional address of the vault where all swept deposits
    ///        should be routed to. All deposits swept as part of the transaction
    ///        must have their `vault` parameters set to the same address.
    ///        If this parameter is set to an address of a trusted vault, swept
    ///        deposits are routed to that vault.
    ///        If this parameter is set to the zero address or to an address
    ///        of a non-trusted vault, swept deposits are not routed to a
    ///        vault but depositors' balances are increased in the Bank
    ///        individually.
    /// @dev Requirements:
    ///      - `sweepTx` components must match the expected structure. See
    ///        `BitcoinTx.Info` docs for reference. Their values must exactly
    ///        correspond to appropriate Bitcoin transaction fields to produce
    ///        a provable transaction hash,
    ///      - The `sweepTx` should represent a Bitcoin transaction with 1..n
    ///        inputs. If the wallet has no main UTXO, all n inputs should
    ///        correspond to P2(W)SH revealed deposits UTXOs. If the wallet has
    ///        an existing main UTXO, one of the n inputs must point to that
    ///        main UTXO and remaining n-1 inputs should correspond to P2(W)SH
    ///        revealed deposits UTXOs. That transaction must have only
    ///        one P2(W)PKH output locking funds on the 20-byte wallet public
    ///        key hash,
    ///      - All revealed deposits that are swept by `sweepTx` must have
    ///        their `vault` parameters set to the same address as the address
    ///        passed in the `vault` function parameter,
    ///      - `sweepProof` components must match the expected structure. See
    ///        `BitcoinTx.Proof` docs for reference. The `bitcoinHeaders`
    ///        field must contain a valid number of block headers, not less
    ///        than the `txProofDifficultyFactor` contract constant,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        If there is no main UTXO, this parameter is ignored.
    function submitDepositSweepProof(
        BitcoinTx.Info calldata sweepTx,
        BitcoinTx.Proof calldata sweepProof,
        BitcoinTx.UTXO calldata mainUtxo,
        address vault
    ) external onlySpvMaintainer {
        self.submitDepositSweepProof(sweepTx, sweepProof, mainUtxo, vault);
    }

    /// @notice Requests redemption of the given amount from the specified
    ///         wallet to the redeemer Bitcoin output script. Handles the
    ///         simplest case in which the redeemer's balance is decreased in
    ///         the Bank.
    /// @param walletPubKeyHash The 20-byte wallet public key hash (computed
    ///        using Bitcoin HASH160 over the compressed ECDSA public key).
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    /// @param redeemerOutputScript The redeemer's length-prefixed output
    ///        script (P2PKH, P2WPKH, P2SH or P2WSH) that will be used to lock
    ///        redeemed BTC.
    /// @param amount Requested amount in satoshi. This is also the Bank balance
    ///        that is taken from the `balanceOwner` upon request.
    ///        Once the request is handled, the actual amount of BTC locked
    ///        on the redeemer output script will be always lower than this value
    ///        since the treasury and Bitcoin transaction fees must be incurred.
    ///        The minimal amount satisfying the request can be computed as:
    ///        `amount - (amount / redemptionTreasuryFeeDivisor) - redemptionTxMaxFee`.
    ///        Fees values are taken at the moment of request creation.
    /// @dev Requirements:
    ///      - Wallet behind `walletPubKeyHash` must be live,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain,
    ///      - `redeemerOutputScript` must be a proper Bitcoin script,
    ///      - `redeemerOutputScript` cannot have wallet PKH as payload,
    ///      - `amount` must be above or equal the `redemptionDustThreshold`,
    ///      - Given `walletPubKeyHash` and `redeemerOutputScript` pair can be
    ///        used for only one pending request at the same time,
    ///      - Wallet must have enough Bitcoin balance to process the request,
    ///      - Redeemer must make an allowance in the Bank that the Bridge
    ///        contract can spend the given `amount`.
    function requestRedemption(
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata mainUtxo,
        bytes calldata redeemerOutputScript,
        uint64 amount
    ) external {
        self.requestRedemption(
            walletPubKeyHash,
            mainUtxo,
            msg.sender,
            redeemerOutputScript,
            amount
        );
    }

    /// @notice Requests redemption of the given amount from the specified
    ///         wallet to the redeemer Bitcoin output script. Used by
    ///         `Bank.approveBalanceAndCall`. Can handle more complex cases
    ///         where balance owner may be someone else than the redeemer.
    ///         For example, vault redeeming its balance for some depositor.
    /// @param balanceOwner The address of the Bank balance owner whose balance
    ///        is getting redeemed.
    /// @param amount Requested amount in satoshi. This is also the Bank balance
    ///        that is taken from the `balanceOwner` upon request.
    ///        Once the request is handled, the actual amount of BTC locked
    ///        on the redeemer output script will be always lower than this value
    ///        since the treasury and Bitcoin transaction fees must be incurred.
    ///        The minimal amount satisfying the request can be computed as:
    ///        `amount - (amount / redemptionTreasuryFeeDivisor) - redemptionTxMaxFee`.
    ///        Fees values are taken at the moment of request creation.
    /// @param redemptionData ABI-encoded redemption data:
    ///        [
    ///          address redeemer,
    ///          bytes20 walletPubKeyHash,
    ///          bytes32 mainUtxoTxHash,
    ///          uint32 mainUtxoTxOutputIndex,
    ///          uint64 mainUtxoTxOutputValue,
    ///          bytes redeemerOutputScript
    ///        ]
    ///
    ///        - redeemer: The Ethereum address of the redeemer who will be able
    ///        to claim Bank balance if anything goes wrong during the redemption.
    ///        In the most basic case, when someone redeems their balance
    ///        from the Bank, `balanceOwner` is the same as `redeemer`.
    ///        However, when a Vault is redeeming part of its balance for some
    ///        redeemer address (for example, someone who has earlier deposited
    ///        into that Vault), `balanceOwner` is the Vault, and `redeemer` is
    ///        the address for which the vault is redeeming its balance to,
    ///        - walletPubKeyHash: The 20-byte wallet public key hash (computed
    ///        using Bitcoin HASH160 over the compressed ECDSA public key),
    ///        - mainUtxoTxHash: Data of the wallet's main UTXO TX hash, as
    ///        currently known on the Ethereum chain,
    ///        - mainUtxoTxOutputIndex: Data of the wallet's main UTXO output
    ///        index, as currently known on Ethereum chain,
    ///        - mainUtxoTxOutputValue: Data of the wallet's main UTXO output
    ///        value, as currently known on Ethereum chain,
    ///        - redeemerOutputScript The redeemer's length-prefixed output
    ///        script (P2PKH, P2WPKH, P2SH or P2WSH) that will be used to lock
    ///        redeemed BTC.
    /// @dev Requirements:
    ///      - The caller must be the Bank,
    ///      - Wallet behind `walletPubKeyHash` must be live,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain,
    ///      - `redeemerOutputScript` must be a proper Bitcoin script,
    ///      - `redeemerOutputScript` cannot have wallet PKH as payload,
    ///      - `amount` must be above or equal the `redemptionDustThreshold`,
    ///      - Given `walletPubKeyHash` and `redeemerOutputScript` pair can be
    ///        used for only one pending request at the same time,
    ///      - Wallet must have enough Bitcoin balance to process the request.
    ///
    ///      Note on upgradeability:
    ///      Bridge is an upgradeable contract deployed behind
    ///      a TransparentUpgradeableProxy. Accepting redemption data as bytes
    ///      provides great flexibility. The Bridge is just like any other
    ///      contract with a balance approved in the Bank and can be upgraded
    ///      to another version without being bound to a particular interface
    ///      forever. This flexibility comes with the cost - developers
    ///      integrating their vaults and dApps with `Bridge` using
    ///      `approveBalanceAndCall` need to pay extra attention to
    ///      `redemptionData` and adjust the code in case the expected structure
    ///      of `redemptionData`  changes.
    function receiveBalanceApproval(
        address balanceOwner,
        uint256 amount,
        bytes calldata redemptionData
    ) external override {
        require(msg.sender == address(self.bank), "Caller is not the bank");

        self.requestRedemption(
            balanceOwner,
            SafeCastUpgradeable.toUint64(amount),
            redemptionData
        );
    }

    /// @notice Used by the wallet to prove the BTC redemption transaction
    ///         and to make the necessary bookkeeping. Redemption is only
    ///         accepted if it satisfies SPV proof.
    ///
    ///         The function is performing Bank balance updates by burning
    ///         the total redeemed Bitcoin amount from Bridge balance and
    ///         transferring the treasury fee sum to the treasury address.
    ///
    ///         It is possible to prove the given redemption only one time.
    /// @param redemptionTx Bitcoin redemption transaction data.
    /// @param redemptionProof Bitcoin redemption proof data.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    /// @param walletPubKeyHash 20-byte public key hash (computed using Bitcoin
    ///        HASH160 over the compressed ECDSA public key) of the wallet which
    ///        performed the redemption transaction.
    /// @dev Requirements:
    ///      - `redemptionTx` components must match the expected structure. See
    ///        `BitcoinTx.Info` docs for reference. Their values must exactly
    ///        correspond to appropriate Bitcoin transaction fields to produce
    ///        a provable transaction hash,
    ///      - The `redemptionTx` should represent a Bitcoin transaction with
    ///        exactly 1 input that refers to the wallet's main UTXO. That
    ///        transaction should have 1..n outputs handling existing pending
    ///        redemption requests or pointing to reported timed out requests.
    ///        There can be also 1 optional output representing the
    ///        change and pointing back to the 20-byte wallet public key hash.
    ///        The change should be always present if the redeemed value sum
    ///        is lower than the total wallet's BTC balance,
    ///      - `redemptionProof` components must match the expected structure.
    ///        See `BitcoinTx.Proof` docs for reference. The `bitcoinHeaders`
    ///        field must contain a valid number of block headers, not less
    ///        than the `txProofDifficultyFactor` contract constant,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        Additionally, the recent main UTXO on Ethereum must be set,
    ///      - `walletPubKeyHash` must be connected with the main UTXO used
    ///        as transaction single input.
    ///      Other remarks:
    ///      - Putting the change output as the first transaction output can
    ///        save some gas because the output processing loop begins each
    ///        iteration by checking whether the given output is the change
    ///        thus uses some gas for making the comparison. Once the change
    ///        is identified, that check is omitted in further iterations.
    function submitRedemptionProof(
        BitcoinTx.Info calldata redemptionTx,
        BitcoinTx.Proof calldata redemptionProof,
        BitcoinTx.UTXO calldata mainUtxo,
        bytes20 walletPubKeyHash
    ) external onlySpvMaintainer {
        self.submitRedemptionProof(
            redemptionTx,
            redemptionProof,
            mainUtxo,
            walletPubKeyHash
        );
    }

    /// @notice Notifies that there is a pending redemption request associated
    ///         with the given wallet, that has timed out. The redemption
    ///         request is identified by the key built as
    ///         `keccak256(keccak256(redeemerOutputScript) | walletPubKeyHash)`.
    ///         The results of calling this function:
    ///         - The pending redemptions value for the wallet will be decreased
    ///           by the requested amount (minus treasury fee),
    ///         - The tokens taken from the redeemer on redemption request will
    ///           be returned to the redeemer,
    ///         - The request will be moved from pending redemptions to
    ///           timed-out redemptions,
    ///         - If the state of the wallet is `Live` or `MovingFunds`, the
    ///           wallet operators will be slashed and the notifier will be
    ///           rewarded,
    ///         - If the state of wallet is `Live`, the wallet will be closed or
    ///           marked as `MovingFunds` (depending on the presence or absence
    ///           of the wallet's main UTXO) and the wallet will no longer be
    ///           marked as the active wallet (if it was marked as such).
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @param redeemerOutputScript  The redeemer's length-prefixed output
    ///        script (P2PKH, P2WPKH, P2SH or P2WSH).
    /// @dev Requirements:
    ///      - The wallet must be in the Live or MovingFunds or Terminated state,
    ///      - The redemption request identified by `walletPubKeyHash` and
    ///        `redeemerOutputScript` must exist,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events of the `WalletRegistry` contract,
    ///      - The amount of time defined by `redemptionTimeout` must have
    ///        passed since the redemption was requested (the request must be
    ///        timed-out).
    function notifyRedemptionTimeout(
        bytes20 walletPubKeyHash,
        uint32[] calldata walletMembersIDs,
        bytes calldata redeemerOutputScript
    ) external {
        self.notifyRedemptionTimeout(
            walletPubKeyHash,
            walletMembersIDs,
            redeemerOutputScript
        );
    }

    /// @notice Submits the moving funds target wallets commitment.
    ///         Once all requirements are met, that function registers the
    ///         target wallets commitment and opens the way for moving funds
    ///         proof submission.
    ///         The caller is reimbursed for the transaction costs.
    /// @param walletPubKeyHash 20-byte public key hash of the source wallet.
    /// @param walletMainUtxo Data of the source wallet's main UTXO, as
    ///        currently known on the Ethereum chain.
    /// @param walletMembersIDs Identifiers of the source wallet signing group
    ///        members.
    /// @param walletMemberIndex Position of the caller in the source wallet
    ///        signing group members list.
    /// @param targetWallets List of 20-byte public key hashes of the target
    ///        wallets that the source wallet commits to move the funds to.
    /// @dev Requirements:
    ///      - The source wallet must be in the MovingFunds state,
    ///      - The source wallet must not have pending redemption requests,
    ///      - The source wallet must not have pending moved funds sweep requests,
    ///      - The source wallet must not have submitted its commitment already,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given source wallet in the ECDSA registry. Those IDs are
    ///        not directly stored in the contract for gas efficiency purposes
    ///        but they can be read from appropriate `DkgResultSubmitted`
    ///        and `DkgResultApproved` events,
    ///      - The `walletMemberIndex` must be in range [1, walletMembersIDs.length],
    ///      - The caller must be the member of the source wallet signing group
    ///        at the position indicated by `walletMemberIndex` parameter,
    ///      - The `walletMainUtxo` components must point to the recent main
    ///        UTXO of the source wallet, as currently known on the Ethereum
    ///        chain,
    ///      - Source wallet BTC balance must be greater than zero,
    ///      - At least one Live wallet must exist in the system,
    ///      - Submitted target wallets count must match the expected count
    ///        `N = min(liveWalletsCount, ceil(walletBtcBalance / walletMaxBtcTransfer))`
    ///        where `N > 0`,
    ///      - Each target wallet must be not equal to the source wallet,
    ///      - Each target wallet must follow the expected order i.e. all
    ///        target wallets 20-byte public key hashes represented as numbers
    ///        must form a strictly increasing sequence without duplicates,
    ///      - Each target wallet must be in Live state.
    function submitMovingFundsCommitment(
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata walletMainUtxo,
        uint32[] calldata walletMembersIDs,
        uint256 walletMemberIndex,
        bytes20[] calldata targetWallets
    ) external {
        uint256 gasStart = gasleft();

        self.submitMovingFundsCommitment(
            walletPubKeyHash,
            walletMainUtxo,
            walletMembersIDs,
            walletMemberIndex,
            targetWallets
        );

        self.reimbursementPool.refund(
            (gasStart - gasleft()) + self.movingFundsCommitmentGasOffset,
            msg.sender
        );
    }

    /// @notice Resets the moving funds timeout for the given wallet if the
    ///         target wallet commitment cannot be submitted due to a lack
    ///         of live wallets in the system.
    /// @param walletPubKeyHash 20-byte public key hash of the moving funds wallet.
    /// @dev Requirements:
    ///      - The wallet must be in the MovingFunds state,
    ///      - The target wallets commitment must not be already submitted for
    ///        the given moving funds wallet,
    ///      - Live wallets count must be zero,
    ///      - The moving funds timeout reset delay must be elapsed.
    function resetMovingFundsTimeout(bytes20 walletPubKeyHash) external {
        self.resetMovingFundsTimeout(walletPubKeyHash);
    }

    /// @notice Used by the wallet to prove the BTC moving funds transaction
    ///         and to make the necessary state changes. Moving funds is only
    ///         accepted if it satisfies SPV proof.
    ///
    ///         The function validates the moving funds transaction structure
    ///         by checking if it actually spends the main UTXO of the declared
    ///         wallet and locks the value on the pre-committed target wallets
    ///         using a reasonable transaction fee. If all preconditions are
    ///         met, this functions closes the source wallet.
    ///
    ///         It is possible to prove the given moving funds transaction only
    ///         one time.
    /// @param movingFundsTx Bitcoin moving funds transaction data.
    /// @param movingFundsProof Bitcoin moving funds proof data.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    /// @param walletPubKeyHash 20-byte public key hash (computed using Bitcoin
    ///        HASH160 over the compressed ECDSA public key) of the wallet
    ///        which performed the moving funds transaction.
    /// @dev Requirements:
    ///      - `movingFundsTx` components must match the expected structure. See
    ///        `BitcoinTx.Info` docs for reference. Their values must exactly
    ///        correspond to appropriate Bitcoin transaction fields to produce
    ///        a provable transaction hash,
    ///      - The `movingFundsTx` should represent a Bitcoin transaction with
    ///        exactly 1 input that refers to the wallet's main UTXO. That
    ///        transaction should have 1..n outputs corresponding to the
    ///        pre-committed target wallets. Outputs must be ordered in the
    ///        same way as their corresponding target wallets are ordered
    ///        within the target wallets commitment,
    ///      - `movingFundsProof` components must match the expected structure.
    ///        See `BitcoinTx.Proof` docs for reference. The `bitcoinHeaders`
    ///        field must contain a valid number of block headers, not less
    ///        than the `txProofDifficultyFactor` contract constant,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        Additionally, the recent main UTXO on Ethereum must be set,
    ///      - `walletPubKeyHash` must be connected with the main UTXO used
    ///        as transaction single input,
    ///      - The wallet that `walletPubKeyHash` points to must be in the
    ///        MovingFunds state,
    ///      - The target wallets commitment must be submitted by the wallet
    ///        that `walletPubKeyHash` points to,
    ///      - The total Bitcoin transaction fee must be lesser or equal
    ///        to `movingFundsTxMaxTotalFee` governable parameter.
    function submitMovingFundsProof(
        BitcoinTx.Info calldata movingFundsTx,
        BitcoinTx.Proof calldata movingFundsProof,
        BitcoinTx.UTXO calldata mainUtxo,
        bytes20 walletPubKeyHash
    ) external onlySpvMaintainer {
        self.submitMovingFundsProof(
            movingFundsTx,
            movingFundsProof,
            mainUtxo,
            walletPubKeyHash
        );
    }

    /// @notice Notifies about a timed out moving funds process. Terminates
    ///         the wallet and slashes signing group members as a result.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @dev Requirements:
    ///      - The wallet must be in the MovingFunds state,
    ///      - The moving funds timeout must be actually exceeded,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events of the `WalletRegistry` contract.
    function notifyMovingFundsTimeout(
        bytes20 walletPubKeyHash,
        uint32[] calldata walletMembersIDs
    ) external {
        self.notifyMovingFundsTimeout(walletPubKeyHash, walletMembersIDs);
    }

    /// @notice Notifies about a moving funds wallet whose BTC balance is
    ///         below the moving funds dust threshold. Ends the moving funds
    ///         process and begins wallet closing immediately.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known
    ///        on the Ethereum chain.
    /// @dev Requirements:
    ///      - The wallet must be in the MovingFunds state,
    ///      - The `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        If the wallet has no main UTXO, this parameter can be empty as it
    ///        is ignored,
    ///      - The wallet BTC balance must be below the moving funds threshold.
    function notifyMovingFundsBelowDust(
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata mainUtxo
    ) external {
        self.notifyMovingFundsBelowDust(walletPubKeyHash, mainUtxo);
    }

    /// @notice Used by the wallet to prove the BTC moved funds sweep
    ///         transaction and to make the necessary state changes. Moved
    ///         funds sweep is only accepted if it satisfies SPV proof.
    ///
    ///         The function validates the sweep transaction structure by
    ///         checking if it actually spends the moved funds UTXO and the
    ///         sweeping wallet's main UTXO (optionally), and if it locks the
    ///         value on the sweeping wallet's 20-byte public key hash using a
    ///         reasonable transaction fee. If all preconditions are
    ///         met, this function updates the sweeping wallet main UTXO, thus
    ///         their BTC balance.
    ///
    ///         It is possible to prove the given sweep transaction only
    ///         one time.
    /// @param sweepTx Bitcoin sweep funds transaction data.
    /// @param sweepProof Bitcoin sweep funds proof data.
    /// @param mainUtxo Data of the sweeping wallet's main UTXO, as currently
    ///        known on the Ethereum chain.
    /// @dev Requirements:
    ///      - `sweepTx` components must match the expected structure. See
    ///        `BitcoinTx.Info` docs for reference. Their values must exactly
    ///        correspond to appropriate Bitcoin transaction fields to produce
    ///        a provable transaction hash,
    ///      - The `sweepTx` should represent a Bitcoin transaction with
    ///        the first input pointing to a moved funds sweep request targeted
    ///        to the wallet, and optionally, the second input pointing to the
    ///        wallet's main UTXO, if the sweeping wallet has a main UTXO set.
    ///        There should be only one output locking funds on the sweeping
    ///        wallet 20-byte public key hash,
    ///      - `sweepProof` components must match the expected structure.
    ///        See `BitcoinTx.Proof` docs for reference. The `bitcoinHeaders`
    ///        field must contain a valid number of block headers, not less
    ///        than the `txProofDifficultyFactor` contract constant,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the sweeping wallet, as currently known on the Ethereum chain.
    ///        If there is no main UTXO, this parameter is ignored,
    ///      - The sweeping wallet must be in the Live or MovingFunds state,
    ///      - The total Bitcoin transaction fee must be lesser or equal
    ///        to `movedFundsSweepTxMaxTotalFee` governable parameter.
    function submitMovedFundsSweepProof(
        BitcoinTx.Info calldata sweepTx,
        BitcoinTx.Proof calldata sweepProof,
        BitcoinTx.UTXO calldata mainUtxo
    ) external onlySpvMaintainer {
        self.submitMovedFundsSweepProof(sweepTx, sweepProof, mainUtxo);
    }

    /// @notice Notifies about a timed out moved funds sweep process. If the
    ///         wallet is not terminated yet, that function terminates
    ///         the wallet and slashes signing group members as a result.
    ///         Marks the given sweep request as TimedOut.
    /// @param movingFundsTxHash 32-byte hash of the moving funds transaction
    ///        that caused the sweep request to be created.
    /// @param movingFundsTxOutputIndex Index of the moving funds transaction
    ///        output that is subject of the sweep request.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @dev Requirements:
    ///      - The moved funds sweep request must be in the Pending state,
    ///      - The moved funds sweep timeout must be actually exceeded,
    ///      - The wallet must be either in the Live or MovingFunds or
    ///        Terminated state,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events of the `WalletRegistry` contract.
    function notifyMovedFundsSweepTimeout(
        bytes32 movingFundsTxHash,
        uint32 movingFundsTxOutputIndex,
        uint32[] calldata walletMembersIDs
    ) external {
        self.notifyMovedFundsSweepTimeout(
            movingFundsTxHash,
            movingFundsTxOutputIndex,
            walletMembersIDs
        );
    }

    /// @notice Requests creation of a new wallet. This function just
    ///         forms a request and the creation process is performed
    ///         asynchronously. Once a wallet is created, the ECDSA Wallet
    ///         Registry will notify this contract by calling the
    ///         `__ecdsaWalletCreatedCallback` function.
    /// @param activeWalletMainUtxo Data of the active wallet's main UTXO, as
    ///        currently known on the Ethereum chain.
    /// @dev Requirements:
    ///      - `activeWalletMainUtxo` components must point to the recent main
    ///        UTXO of the given active wallet, as currently known on the
    ///        Ethereum chain. If there is no active wallet at the moment, or
    ///        the active wallet has no main UTXO, this parameter can be
    ///        empty as it is ignored,
    ///      - Wallet creation must not be in progress,
    ///      - If the active wallet is set, one of the following
    ///        conditions must be true:
    ///        - The active wallet BTC balance is above the minimum threshold
    ///          and the active wallet is old enough, i.e. the creation period
    ///          was elapsed since its creation time,
    ///        - The active wallet BTC balance is above the maximum threshold.
    function requestNewWallet(BitcoinTx.UTXO calldata activeWalletMainUtxo)
        external
    {
        self.requestNewWallet(activeWalletMainUtxo);
    }

    /// @notice A callback function that is called by the ECDSA Wallet Registry
    ///         once a new ECDSA wallet is created.
    /// @param ecdsaWalletID Wallet's unique identifier.
    /// @param publicKeyX Wallet's public key's X coordinate.
    /// @param publicKeyY Wallet's public key's Y coordinate.
    /// @dev Requirements:
    ///      - The only caller authorized to call this function is `registry`,
    ///      - Given wallet data must not belong to an already registered wallet.
    function __ecdsaWalletCreatedCallback(
        bytes32 ecdsaWalletID,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) external override {
        self.registerNewWallet(ecdsaWalletID, publicKeyX, publicKeyY);
    }

    /// @notice A callback function that is called by the ECDSA Wallet Registry
    ///         once a wallet heartbeat failure is detected.
    /// @param publicKeyX Wallet's public key's X coordinate.
    /// @param publicKeyY Wallet's public key's Y coordinate.
    /// @dev Requirements:
    ///      - The only caller authorized to call this function is `registry`,
    ///      - Wallet must be in Live state.
    function __ecdsaWalletHeartbeatFailedCallback(
        bytes32,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) external override {
        self.notifyWalletHeartbeatFailed(publicKeyX, publicKeyY);
    }

    /// @notice Notifies that the wallet is either old enough or has too few
    ///         satoshi left and qualifies to be closed.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMainUtxo Data of the wallet's main UTXO, as currently
    ///        known on the Ethereum chain.
    /// @dev Requirements:
    ///      - Wallet must not be set as the current active wallet,
    ///      - Wallet must exceed the wallet maximum age OR the wallet BTC
    ///        balance must be lesser than the minimum threshold. If the latter
    ///        case is true, the `walletMainUtxo` components must point to the
    ///        recent main UTXO of the given wallet, as currently known on the
    ///        Ethereum chain. If the wallet has no main UTXO, this parameter
    ///        can be empty as it is ignored since the wallet balance is
    ///        assumed to be zero,
    ///      - Wallet must be in Live state.
    function notifyWalletCloseable(
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata walletMainUtxo
    ) external {
        self.notifyWalletCloseable(walletPubKeyHash, walletMainUtxo);
    }

    /// @notice Notifies about the end of the closing period for the given wallet.
    ///         Closes the wallet ultimately and notifies the ECDSA registry
    ///         about this fact.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @dev Requirements:
    ///      - The wallet must be in the Closing state,
    ///      - The wallet closing period must have elapsed.
    function notifyWalletClosingPeriodElapsed(bytes20 walletPubKeyHash)
        external
    {
        self.notifyWalletClosingPeriodElapsed(walletPubKeyHash);
    }

    /// @notice Submits a fraud challenge indicating that a UTXO being under
    ///         wallet control was unlocked by the wallet but was not used
    ///         according to the protocol rules. That means the wallet signed
    ///         a transaction input pointing to that UTXO and there is a unique
    ///         sighash and signature pair associated with that input. This
    ///         function uses those parameters to create a fraud accusation that
    ///         proves a given transaction input unlocking the given UTXO was
    ///         actually signed by the wallet. This function cannot determine
    ///         whether the transaction was actually broadcast and the input was
    ///         consumed in a fraudulent way so it just opens a challenge period
    ///         during which the wallet can defeat the challenge by submitting
    ///         proof of a transaction that consumes the given input according
    ///         to protocol rules. To prevent spurious allegations, the caller
    ///         must deposit ETH that is returned back upon justified fraud
    ///         challenge or confiscated otherwise.
    /// @param walletPublicKey The public key of the wallet in the uncompressed
    ///        and unprefixed format (64 bytes).
    /// @param preimageSha256 The hash that was generated by applying SHA-256
    ///        one time over the preimage used during input signing. The preimage
    ///        is a serialized subset of the transaction and its structure
    ///        depends on the transaction input (see BIP-143 for reference).
    ///        Notice that applying SHA-256 over the `preimageSha256` results
    ///        in `sighash`.  The path from `preimage` to `sighash` looks like
    ///        this:
    ///        preimage -> (SHA-256) -> preimageSha256 -> (SHA-256) -> sighash.
    /// @param signature Bitcoin signature in the R/S/V format.
    /// @dev Requirements:
    ///      - Wallet behind `walletPublicKey` must be in Live or MovingFunds
    ///        or Closing state,
    ///      - The challenger must send appropriate amount of ETH used as
    ///        fraud challenge deposit,
    ///      - The signature (represented by r, s and v) must be generated by
    ///        the wallet behind `walletPubKey` during signing of `sighash`
    ///        which was calculated from `preimageSha256`,
    ///      - Wallet can be challenged for the given signature only once.
    function submitFraudChallenge(
        bytes calldata walletPublicKey,
        bytes memory preimageSha256,
        BitcoinTx.RSVSignature calldata signature
    ) external payable {
        self.submitFraudChallenge(walletPublicKey, preimageSha256, signature);
    }

    /// @notice Allows to defeat a pending fraud challenge against a wallet if
    ///         the transaction that spends the UTXO follows the protocol rules.
    ///         In order to defeat the challenge the same `walletPublicKey` and
    ///         signature (represented by `r`, `s` and `v`) must be provided as
    ///         were used to calculate the sighash during input signing.
    ///         The fraud challenge defeat attempt will only succeed if the
    ///         inputs in the preimage are considered honestly spent by the
    ///         wallet. Therefore the transaction spending the UTXO must be
    ///         proven in the Bridge before a challenge defeat is called.
    ///         If successfully defeated, the fraud challenge is marked as
    ///         resolved and the amount of ether deposited by the challenger is
    ///         sent to the treasury.
    /// @param walletPublicKey The public key of the wallet in the uncompressed
    ///        and unprefixed format (64 bytes).
    /// @param preimage The preimage which produces sighash used to generate the
    ///        ECDSA signature that is the subject of the fraud claim. It is a
    ///        serialized subset of the transaction. The exact subset used as
    ///        the preimage depends on the transaction input the signature is
    ///        produced for. See BIP-143 for reference.
    /// @param witness Flag indicating whether the preimage was produced for a
    ///        witness input. True for witness, false for non-witness input.
    /// @dev Requirements:
    ///      - `walletPublicKey` and `sighash` calculated as `hash256(preimage)`
    ///        must identify an open fraud challenge,
    ///      - the preimage must be a valid preimage of a transaction generated
    ///        according to the protocol rules and already proved in the Bridge,
    ///      - before a defeat attempt is made the transaction that spends the
    ///        given UTXO must be proven in the Bridge.
    function defeatFraudChallenge(
        bytes calldata walletPublicKey,
        bytes calldata preimage,
        bool witness
    ) external {
        self.defeatFraudChallenge(walletPublicKey, preimage, witness);
    }

    /// @notice Allows to defeat a pending fraud challenge against a wallet by
    ///         proving the sighash and signature were produced for an off-chain
    ///         wallet heartbeat message following a strict format.
    ///         In order to defeat the challenge the same `walletPublicKey` and
    ///         signature (represented by `r`, `s` and `v`) must be provided as
    ///         were used to calculate the sighash during heartbeat message
    ///         signing. The fraud challenge defeat attempt will only succeed if
    ///         the signed message follows a strict format required for
    ///         heartbeat messages. If successfully defeated, the fraud
    ///         challenge is marked as resolved and the amount of ether
    ///         deposited by the challenger is sent to the treasury.
    /// @param walletPublicKey The public key of the wallet in the uncompressed
    ///        and unprefixed format (64 bytes).
    /// @param heartbeatMessage Off-chain heartbeat message meeting the heartbeat
    ///        message format requirements which produces sighash used to
    ///        generate the ECDSA signature that is the subject of the fraud
    ///        claim.
    /// @dev Requirements:
    ///      - `walletPublicKey` and `sighash` calculated as
    ///        `hash256(heartbeatMessage)` must identify an open fraud challenge,
    ///      - `heartbeatMessage` must follow a strict format of heartbeat
    ///        messages.
    function defeatFraudChallengeWithHeartbeat(
        bytes calldata walletPublicKey,
        bytes calldata heartbeatMessage
    ) external {
        self.defeatFraudChallengeWithHeartbeat(
            walletPublicKey,
            heartbeatMessage
        );
    }

    /// @notice Notifies about defeat timeout for the given fraud challenge.
    ///         Can be called only if there was a fraud challenge identified by
    ///         the provided `walletPublicKey` and `sighash` and it was not
    ///         defeated on time. The amount of time that needs to pass after
    ///         a fraud challenge is reported is indicated by the
    ///         `challengeDefeatTimeout`. After a successful fraud challenge
    ///         defeat timeout notification the fraud challenge is marked as
    ///         resolved, the stake of each operator is slashed, the ether
    ///         deposited is returned to the challenger and the challenger is
    ///         rewarded.
    /// @param walletPublicKey The public key of the wallet in the uncompressed
    ///        and unprefixed format (64 bytes).
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @param preimageSha256 The hash that was generated by applying SHA-256
    ///        one time over the preimage used during input signing. The preimage
    ///        is a serialized subset of the transaction and its structure
    ///        depends on the transaction input (see BIP-143 for reference).
    ///        Notice that applying SHA-256 over the `preimageSha256` results
    ///        in `sighash`.  The path from `preimage` to `sighash` looks like
    ///        this:
    ///        preimage -> (SHA-256) -> preimageSha256 -> (SHA-256) -> sighash.
    /// @dev Requirements:
    ///      - The wallet must be in the Live or MovingFunds or Closing or
    ///        Terminated state,
    ///      - The `walletPublicKey` and `sighash` calculated from
    ///        `preimageSha256` must identify an open fraud challenge,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events of the `WalletRegistry` contract,
    ///      - The amount of time indicated by `challengeDefeatTimeout` must pass
    ///        after the challenge was reported.
    function notifyFraudChallengeDefeatTimeout(
        bytes calldata walletPublicKey,
        uint32[] calldata walletMembersIDs,
        bytes memory preimageSha256
    ) external {
        self.notifyFraudChallengeDefeatTimeout(
            walletPublicKey,
            walletMembersIDs,
            preimageSha256
        );
    }

    /// @notice Allows the Governance to mark the given vault address as trusted
    ///         or no longer trusted. Vaults are not trusted by default.
    ///         Trusted vault must meet the following criteria:
    ///         - `IVault.receiveBalanceIncrease` must have a known, low gas
    ///           cost,
    ///         - `IVault.receiveBalanceIncrease` must never revert.
    /// @dev Without restricting reveal only to trusted vaults, malicious
    ///      vaults not meeting the criteria would be able to nuke sweep proof
    ///      transactions executed by ECDSA wallet with  deposits routed to
    ///      them.
    /// @param vault The address of the vault.
    /// @param isTrusted flag indicating whether the vault is trusted or not.
    /// @dev Can only be called by the Governance.
    function setVaultStatus(address vault, bool isTrusted)
        external
        onlyGovernance
    {
        self.isVaultTrusted[vault] = isTrusted;
        emit VaultStatusUpdated(vault, isTrusted);
    }

    /// @notice Allows the Governance to mark the given address as trusted
    ///         or no longer trusted SPV maintainer. Addresses are not trusted
    ///         as SPV maintainers by default.
    /// @dev The SPV proof does not check whether the transaction is a part of
    ///      the Bitcoin mainnet, it only checks whether the transaction has been
    ///      mined performing the required amount of work as on Bitcoin mainnet.
    ///      The possibility of submitting SPV proofs is limited to trusted SPV
    ///      maintainers. The system expects transaction confirmations with the
    ///      required work accumulated, so trusted SPV maintainers can not prove
    ///      the transaction without providing the required Bitcoin proof of work.
    ///      Trusted maintainers address the issue of an economic game between
    ///      tBTC and Bitcoin mainnet where large Bitcoin mining pools can decide
    ///      to use their hash power to mine fake Bitcoin blocks to prove them in
    ///      tBTC instead of receiving Bitcoin miner rewards.
    /// @param spvMaintainer The address of the SPV maintainer.
    /// @param isTrusted flag indicating whether the address is trusted or not.
    /// @dev Can only be called by the Governance.
    function setSpvMaintainerStatus(address spvMaintainer, bool isTrusted)
        external
        onlyGovernance
    {
        self.isSpvMaintainer[spvMaintainer] = isTrusted;
        emit SpvMaintainerStatusUpdated(spvMaintainer, isTrusted);
    }

    /// @notice Updates parameters of deposits.
    /// @param depositDustThreshold New value of the deposit dust threshold in
    ///        satoshis. It is the minimal amount that can be requested to
    ////       deposit. Value of this parameter must take into account the value
    ///        of `depositTreasuryFeeDivisor` and `depositTxMaxFee` parameters
    ///        in order to make requests that can incur the treasury and
    ///        transaction fee and still satisfy the depositor.
    /// @param depositTreasuryFeeDivisor New value of the treasury fee divisor.
    ///        It is the divisor used to compute the treasury fee taken from
    ///        each deposit and transferred to the treasury upon sweep proof
    ///        submission. That fee is computed as follows:
    ///        `treasuryFee = depositedAmount / depositTreasuryFeeDivisor`
    ///        For example, if the treasury fee needs to be 2% of each deposit,
    ///        the `depositTreasuryFeeDivisor` should be set to `50`
    ///        because `1/50 = 0.02 = 2%`.
    /// @param depositTxMaxFee New value of the deposit tx max fee in satoshis.
    ///        It is the maximum amount of BTC transaction fee that can
    ///        be incurred by each swept deposit being part of the given sweep
    ///        transaction. If the maximum BTC transaction fee is exceeded,
    ///        such transaction is considered a fraud.
    /// @param depositRevealAheadPeriod New value of the deposit reveal ahead
    ///        period parameter in seconds. It defines the length of the period
    ///        that must be preserved between the deposit reveal time and the
    ///        deposit refund locktime.
    /// @dev Requirements:
    ///      - Deposit dust threshold must be greater than zero,
    ///      - Deposit dust threshold must be greater than deposit TX max fee,
    ///      - Deposit transaction max fee must be greater than zero.
    function updateDepositParameters(
        uint64 depositDustThreshold,
        uint64 depositTreasuryFeeDivisor,
        uint64 depositTxMaxFee,
        uint32 depositRevealAheadPeriod
    ) external onlyGovernance {
        self.updateDepositParameters(
            depositDustThreshold,
            depositTreasuryFeeDivisor,
            depositTxMaxFee,
            depositRevealAheadPeriod
        );
    }

    /// @notice Updates parameters of redemptions.
    /// @param redemptionDustThreshold New value of the redemption dust
    ///        threshold in satoshis. It is the minimal amount that can be
    ///        requested for redemption. Value of this parameter must take into
    ///        account the value of `redemptionTreasuryFeeDivisor` and
    ///        `redemptionTxMaxFee` parameters in order to make requests that
    ///        can incur the treasury and transaction fee and still satisfy the
    ///        redeemer.
    /// @param redemptionTreasuryFeeDivisor New value of the redemption
    ///        treasury fee divisor. It is the divisor used to compute the
    ///        treasury fee taken from each redemption request and transferred
    ///        to the treasury upon successful request finalization. That fee is
    ///        computed as follows:
    ///        `treasuryFee = requestedAmount / redemptionTreasuryFeeDivisor`
    ///        For example, if the treasury fee needs to be 2% of each
    ///        redemption request, the `redemptionTreasuryFeeDivisor` should
    ///        be set to `50` because `1/50 = 0.02 = 2%`.
    /// @param redemptionTxMaxFee New value of the redemption transaction max
    ///        fee in satoshis. It is the maximum amount of BTC transaction fee
    ///        that can be incurred by each redemption request being part of the
    ///        given redemption transaction. If the maximum BTC transaction fee
    ///        is exceeded, such transaction is considered a fraud.
    ///        This is a per-redemption output max fee for the redemption
    ///        transaction.
    /// @param redemptionTxMaxTotalFee New value of the redemption transaction
    ///        max total fee in satoshis. It is the maximum amount of the total
    ///        BTC transaction fee that is acceptable in a single redemption
    ///        transaction. This is a _total_ max fee for the entire redemption
    ///        transaction.
    /// @param redemptionTimeout New value of the redemption timeout in seconds.
    ///        It is the time after which the redemption request can be reported
    ///        as timed out. It is counted from the moment when the redemption
    ///        request was created via `requestRedemption` call. Reported  timed
    ///        out requests are cancelled and locked balance is returned to the
    ///        redeemer in full amount.
    /// @param redemptionTimeoutSlashingAmount New value of the redemption
    ///        timeout slashing amount in T, it is the amount slashed from each
    ///        wallet member for redemption timeout.
    /// @param redemptionTimeoutNotifierRewardMultiplier New value of the
    ///        redemption timeout notifier reward multiplier as percentage,
    ///        it determines the percentage of the notifier reward from the
    ///        staking contact the notifier of a redemption timeout receives.
    ///        The value must be in the range [0, 100].
    /// @dev Requirements:
    ///      - Redemption dust threshold must be greater than moving funds dust
    ///        threshold,
    ///      - Redemption dust threshold must be greater than the redemption TX
    ///        max fee,
    ///      - Redemption transaction max fee must be greater than zero,
    ///      - Redemption transaction max total fee must be greater than or
    ///        equal to the redemption transaction per-request max fee,
    ///      - Redemption timeout must be greater than zero,
    ///      - Redemption timeout notifier reward multiplier must be in the
    ///        range [0, 100].
    function updateRedemptionParameters(
        uint64 redemptionDustThreshold,
        uint64 redemptionTreasuryFeeDivisor,
        uint64 redemptionTxMaxFee,
        uint64 redemptionTxMaxTotalFee,
        uint32 redemptionTimeout,
        uint96 redemptionTimeoutSlashingAmount,
        uint32 redemptionTimeoutNotifierRewardMultiplier
    ) external onlyGovernance {
        self.updateRedemptionParameters(
            redemptionDustThreshold,
            redemptionTreasuryFeeDivisor,
            redemptionTxMaxFee,
            redemptionTxMaxTotalFee,
            redemptionTimeout,
            redemptionTimeoutSlashingAmount,
            redemptionTimeoutNotifierRewardMultiplier
        );
    }

    /// @notice Updates parameters of moving funds.
    /// @param movingFundsTxMaxTotalFee New value of the moving funds transaction
    ///        max total fee in satoshis. It is the maximum amount of the total
    ///        BTC transaction fee that is acceptable in a single moving funds
    ///        transaction. This is a _total_ max fee for the entire moving
    ///        funds transaction.
    /// @param movingFundsDustThreshold New value of the moving funds dust
    ///        threshold. It is the minimal satoshi amount that makes sense to
    ///        be transferred during the moving funds process. Moving funds
    ///        wallets having their BTC balance below that value can begin
    ///        closing immediately as transferring such a low value may not be
    ///        possible due to BTC network fees.
    /// @param movingFundsTimeoutResetDelay New value of the moving funds
    ///        timeout reset delay in seconds. It is the time after which the
    ///        moving funds timeout can be reset in case the target wallet
    ///        commitment cannot be submitted due to a lack of live wallets
    ///        in the system. It is counted from the moment when the wallet
    ///        was requested to move their funds and switched to the MovingFunds
    ///        state or from the moment the timeout was reset the last time.
    /// @param movingFundsTimeout New value of the moving funds timeout in
    ///        seconds. It is the time after which the moving funds process can
    ///        be reported as timed out. It is counted from the moment when the
    ///        wallet was requested to move their funds and switched to the
    ///        MovingFunds state.
    /// @param movingFundsTimeoutSlashingAmount New value of the moving funds
    ///        timeout slashing amount in T, it is the amount slashed from each
    ///        wallet member for moving funds timeout.
    /// @param movingFundsTimeoutNotifierRewardMultiplier New value of the
    ///        moving funds timeout notifier reward multiplier as percentage,
    ///        it determines the percentage of the notifier reward from the
    ///        staking contact the notifier of a moving funds timeout receives.
    ///        The value must be in the range [0, 100].
    /// @param movingFundsCommitmentGasOffset New value of the gas offset for
    ///        moving funds target wallet commitment transaction gas costs
    ///        reimbursement.
    /// @param movedFundsSweepTxMaxTotalFee New value of the moved funds sweep
    ///        transaction max total fee in satoshis. It is the maximum amount
    ///        of the total BTC transaction fee that is acceptable in a single
    ///        moved funds sweep transaction. This is a _total_ max fee for the
    ///        entire moved funds sweep transaction.
    /// @param movedFundsSweepTimeout New value of the moved funds sweep
    ///        timeout in seconds. It is the time after which the moved funds
    ///        sweep process can be reported as timed out. It is counted from
    ///        the moment when the wallet was requested to sweep the received
    ///        funds.
    /// @param movedFundsSweepTimeoutSlashingAmount New value of the moved
    ///        funds sweep timeout slashing amount in T, it is the amount
    ///        slashed from each wallet member for moved funds sweep timeout.
    /// @param movedFundsSweepTimeoutNotifierRewardMultiplier New value of
    ///        the moved funds sweep timeout notifier reward multiplier as
    ///        percentage, it determines the percentage of the notifier reward
    ///        from the staking contact the notifier of a moved funds sweep
    ///        timeout receives. The value must be in the range [0, 100].
    /// @dev Requirements:
    ///      - Moving funds transaction max total fee must be greater than zero,
    ///      - Moving funds dust threshold must be greater than zero and lower
    ///        than the redemption dust threshold,
    ///      - Moving funds timeout reset delay must be greater than zero,
    ///      - Moving funds timeout must be greater than the moving funds
    ///        timeout reset delay,
    ///      - Moving funds timeout notifier reward multiplier must be in the
    ///        range [0, 100],
    ///      - Moved funds sweep transaction max total fee must be greater than zero,
    ///      - Moved funds sweep timeout must be greater than zero,
    ///      - Moved funds sweep timeout notifier reward multiplier must be in the
    ///        range [0, 100].
    function updateMovingFundsParameters(
        uint64 movingFundsTxMaxTotalFee,
        uint64 movingFundsDustThreshold,
        uint32 movingFundsTimeoutResetDelay,
        uint32 movingFundsTimeout,
        uint96 movingFundsTimeoutSlashingAmount,
        uint32 movingFundsTimeoutNotifierRewardMultiplier,
        uint16 movingFundsCommitmentGasOffset,
        uint64 movedFundsSweepTxMaxTotalFee,
        uint32 movedFundsSweepTimeout,
        uint96 movedFundsSweepTimeoutSlashingAmount,
        uint32 movedFundsSweepTimeoutNotifierRewardMultiplier
    ) external onlyGovernance {
        self.updateMovingFundsParameters(
            movingFundsTxMaxTotalFee,
            movingFundsDustThreshold,
            movingFundsTimeoutResetDelay,
            movingFundsTimeout,
            movingFundsTimeoutSlashingAmount,
            movingFundsTimeoutNotifierRewardMultiplier,
            movingFundsCommitmentGasOffset,
            movedFundsSweepTxMaxTotalFee,
            movedFundsSweepTimeout,
            movedFundsSweepTimeoutSlashingAmount,
            movedFundsSweepTimeoutNotifierRewardMultiplier
        );
    }

    /// @notice Updates parameters of wallets.
    /// @param walletCreationPeriod New value of the wallet creation period in
    ///        seconds, determines how frequently a new wallet creation can be
    ///        requested.
    /// @param walletCreationMinBtcBalance New value of the wallet minimum BTC
    ///        balance in satoshi, used to decide about wallet creation.
    /// @param walletCreationMaxBtcBalance New value of the wallet maximum BTC
    ///        balance in satoshi, used to decide about wallet creation.
    /// @param walletClosureMinBtcBalance New value of the wallet minimum BTC
    ///        balance in satoshi, used to decide about wallet closure.
    /// @param walletMaxAge New value of the wallet maximum age in seconds,
    ///        indicates the maximum age of a wallet in seconds, after which
    ///        the wallet moving funds process can be requested.
    /// @param walletMaxBtcTransfer New value of the wallet maximum BTC transfer
    ///        in satoshi, determines the maximum amount that can be transferred
    //         to a single target wallet during the moving funds process.
    /// @param walletClosingPeriod New value of the wallet closing period in
    ///        seconds, determines the length of the wallet closing period,
    //         i.e. the period when the wallet remains in the Closing state
    //         and can be subject of deposit fraud challenges.
    /// @dev Requirements:
    ///      - Wallet maximum BTC balance must be greater than the wallet
    ///        minimum BTC balance,
    ///      - Wallet maximum BTC transfer must be greater than zero,
    ///      - Wallet closing period must be greater than zero.
    function updateWalletParameters(
        uint32 walletCreationPeriod,
        uint64 walletCreationMinBtcBalance,
        uint64 walletCreationMaxBtcBalance,
        uint64 walletClosureMinBtcBalance,
        uint32 walletMaxAge,
        uint64 walletMaxBtcTransfer,
        uint32 walletClosingPeriod
    ) external onlyGovernance {
        self.updateWalletParameters(
            walletCreationPeriod,
            walletCreationMinBtcBalance,
            walletCreationMaxBtcBalance,
            walletClosureMinBtcBalance,
            walletMaxAge,
            walletMaxBtcTransfer,
            walletClosingPeriod
        );
    }

    /// @notice Updates parameters related to frauds.
    /// @param fraudChallengeDepositAmount New value of the fraud challenge
    ///        deposit amount in wei, it is the amount of ETH the party
    ///        challenging the wallet for fraud needs to deposit.
    /// @param fraudChallengeDefeatTimeout New value of the challenge defeat
    ///        timeout in seconds, it is the amount of time the wallet has to
    ///        defeat a fraud challenge. The value must be greater than zero.
    /// @param fraudSlashingAmount New value of the fraud slashing amount in T,
    ///        it is the amount slashed from each wallet member for committing
    ///        a fraud.
    /// @param fraudNotifierRewardMultiplier New value of the fraud notifier
    ///        reward multiplier as percentage, it determines the percentage of
    ///        the notifier reward from the staking contact the notifier of
    ///        a fraud receives. The value must be in the range [0, 100].
    /// @dev Requirements:
    ///      - Fraud challenge defeat timeout must be greater than 0,
    ///      - Fraud notifier reward multiplier must be in the range [0, 100].
    function updateFraudParameters(
        uint96 fraudChallengeDepositAmount,
        uint32 fraudChallengeDefeatTimeout,
        uint96 fraudSlashingAmount,
        uint32 fraudNotifierRewardMultiplier
    ) external onlyGovernance {
        self.updateFraudParameters(
            fraudChallengeDepositAmount,
            fraudChallengeDefeatTimeout,
            fraudSlashingAmount,
            fraudNotifierRewardMultiplier
        );
    }

    /// @notice Updates treasury address. The treasury receives the system fees.
    /// @param treasury New value of the treasury address.
    /// @dev The treasury address must not be 0x0.
    // slither-disable-next-line shadowing-local
    function updateTreasury(address treasury) external onlyGovernance {
        self.updateTreasury(treasury);
    }

    /// @notice Collection of all revealed deposits indexed by
    ///         keccak256(fundingTxHash | fundingOutputIndex).
    ///         The fundingTxHash is bytes32 (ordered as in Bitcoin internally)
    ///         and fundingOutputIndex an uint32. This mapping may contain valid
    ///         and invalid deposits and the wallet is responsible for
    ///         validating them before attempting to execute a sweep.
    function deposits(uint256 depositKey)
        external
        view
        returns (Deposit.DepositRequest memory)
    {
        return self.deposits[depositKey];
    }

    /// @notice Collection of all pending redemption requests indexed by
    ///         redemption key built as
    ///         `keccak256(keccak256(redeemerOutputScript) | walletPubKeyHash)`.
    ///         The walletPubKeyHash is the 20-byte wallet's public key hash
    ///         (computed using Bitcoin HASH160 over the compressed ECDSA
    ///         public key) and `redeemerOutputScript` is a Bitcoin script
    ///         (P2PKH, P2WPKH, P2SH or P2WSH) that will be used to lock
    ///         redeemed BTC as requested by the redeemer. Requests are added
    ///         to this mapping by the `requestRedemption` method (duplicates
    ///         not allowed) and are removed by one of the following methods:
    ///         - `submitRedemptionProof` in case the request was handled
    ///           successfully,
    ///         - `notifyRedemptionTimeout` in case the request was reported
    ///           to be timed out.
    function pendingRedemptions(uint256 redemptionKey)
        external
        view
        returns (Redemption.RedemptionRequest memory)
    {
        return self.pendingRedemptions[redemptionKey];
    }

    /// @notice Collection of all timed out redemptions requests indexed by
    ///         redemption key built as
    ///         `keccak256(keccak256(redeemerOutputScript) | walletPubKeyHash)`.
    ///         The walletPubKeyHash is the 20-byte wallet's public key hash
    ///         (computed using Bitcoin HASH160 over the compressed ECDSA
    ///         public key) and `redeemerOutputScript` is the Bitcoin script
    ///         (P2PKH, P2WPKH, P2SH or P2WSH) that is involved in the timed
    ///         out request.
    ///         Only one method can add to this mapping:
    ///         - `notifyRedemptionTimeout` which puts the redemption key
    ///           to this mapping based on a timed out request stored
    ///           previously in `pendingRedemptions` mapping.
    ///         Only one method can remove entries from this mapping:
    ///         - `submitRedemptionProof` in case the timed out redemption
    ///           request was a part of the proven transaction.
    function timedOutRedemptions(uint256 redemptionKey)
        external
        view
        returns (Redemption.RedemptionRequest memory)
    {
        return self.timedOutRedemptions[redemptionKey];
    }

    /// @notice Collection of main UTXOs that are honestly spent indexed by
    ///         keccak256(fundingTxHash | fundingOutputIndex). The fundingTxHash
    ///         is bytes32 (ordered as in Bitcoin internally) and
    ///         fundingOutputIndex an uint32. A main UTXO is considered honestly
    ///         spent if it was used as an input of a transaction that have been
    ///         proven in the Bridge.
    function spentMainUTXOs(uint256 utxoKey) external view returns (bool) {
        return self.spentMainUTXOs[utxoKey];
    }

    /// @notice Gets details about a registered wallet.
    /// @param walletPubKeyHash The 20-byte wallet public key hash (computed
    ///        using Bitcoin HASH160 over the compressed ECDSA public key).
    /// @return Wallet details.
    function wallets(bytes20 walletPubKeyHash)
        external
        view
        returns (Wallets.Wallet memory)
    {
        return self.registeredWallets[walletPubKeyHash];
    }

    /// @notice Gets the public key hash of the active wallet.
    /// @return The 20-byte public key hash (computed using Bitcoin HASH160
    ///         over the compressed ECDSA public key) of the active wallet.
    ///         Returns bytes20(0) if there is no active wallet at the moment.
    function activeWalletPubKeyHash() external view returns (bytes20) {
        return self.activeWalletPubKeyHash;
    }

    /// @notice Gets the live wallets count.
    /// @return The current count of wallets being in the Live state.
    function liveWalletsCount() external view returns (uint32) {
        return self.liveWalletsCount;
    }

    /// @notice Returns the fraud challenge identified by the given key built
    ///         as keccak256(walletPublicKey|sighash).
    function fraudChallenges(uint256 challengeKey)
        external
        view
        returns (Fraud.FraudChallenge memory)
    {
        return self.fraudChallenges[challengeKey];
    }

    /// @notice Collection of all moved funds sweep requests indexed by
    ///         `keccak256(movingFundsTxHash | movingFundsOutputIndex)`.
    ///         The `movingFundsTxHash` is `bytes32` (ordered as in Bitcoin
    ///         internally) and `movingFundsOutputIndex` an `uint32`. Each entry
    ///         is actually an UTXO representing the moved funds and is supposed
    ///         to be swept with the current main UTXO of the recipient wallet.
    /// @param requestKey Request key built as
    ///        `keccak256(movingFundsTxHash | movingFundsOutputIndex)`.
    /// @return Details of the moved funds sweep request.
    function movedFundsSweepRequests(uint256 requestKey)
        external
        view
        returns (MovingFunds.MovedFundsSweepRequest memory)
    {
        return self.movedFundsSweepRequests[requestKey];
    }

    /// @notice Indicates if the vault with the given address is trusted or not.
    ///         Depositors can route their revealed deposits only to trusted
    ///         vaults and have trusted vaults notified about new deposits as
    ///         soon as these deposits get swept. Vaults not trusted by the
    ///         Bridge can still be used by Bank balance owners on their own
    ///         responsibility - anyone can approve their Bank balance to any
    ///         address.
    function isVaultTrusted(address vault) external view returns (bool) {
        return self.isVaultTrusted[vault];
    }

    /// @notice Returns the current values of Bridge deposit parameters.
    /// @return depositDustThreshold The minimal amount that can be requested
    ///         to deposit. Value of this parameter must take into account the
    ///         value of `depositTreasuryFeeDivisor` and `depositTxMaxFee`
    ///         parameters in order to make requests that can incur the
    ///         treasury and transaction fee and still satisfy the depositor.
    /// @return depositTreasuryFeeDivisor Divisor used to compute the treasury
    ///         fee taken from each deposit and transferred to the treasury upon
    ///         sweep proof submission. That fee is computed as follows:
    ///         `treasuryFee = depositedAmount / depositTreasuryFeeDivisor`
    ///         For example, if the treasury fee needs to be 2% of each deposit,
    ///         the `depositTreasuryFeeDivisor` should be set to `50`
    ///         because `1/50 = 0.02 = 2%`.
    /// @return depositTxMaxFee Maximum amount of BTC transaction fee that can
    ///         be incurred by each swept deposit being part of the given sweep
    ///         transaction. If the maximum BTC transaction fee is exceeded,
    ///         such transaction is considered a fraud.
    /// @return depositRevealAheadPeriod Defines the length of the period that
    ///         must be preserved between the deposit reveal time and the
    ///         deposit refund locktime. For example, if the deposit become
    ///         refundable on August 1st, and the ahead period is 7 days, the
    ///         latest moment for deposit reveal is July 25th. Value in seconds.
    function depositParameters()
        external
        view
        returns (
            uint64 depositDustThreshold,
            uint64 depositTreasuryFeeDivisor,
            uint64 depositTxMaxFee,
            uint32 depositRevealAheadPeriod
        )
    {
        depositDustThreshold = self.depositDustThreshold;
        depositTreasuryFeeDivisor = self.depositTreasuryFeeDivisor;
        depositTxMaxFee = self.depositTxMaxFee;
        depositRevealAheadPeriod = self.depositRevealAheadPeriod;
    }

    /// @notice Returns the current values of Bridge redemption parameters.
    /// @return redemptionDustThreshold The minimal amount that can be requested
    ///         for redemption. Value of this parameter must take into account
    ///         the value of `redemptionTreasuryFeeDivisor` and `redemptionTxMaxFee`
    ///         parameters in order to make requests that can incur the
    ///         treasury and transaction fee and still satisfy the redeemer.
    /// @return redemptionTreasuryFeeDivisor Divisor used to compute the treasury
    ///         fee taken from each redemption request and transferred to the
    ///         treasury upon successful request finalization. That fee is
    ///         computed as follows:
    ///         `treasuryFee = requestedAmount / redemptionTreasuryFeeDivisor`
    ///         For example, if the treasury fee needs to be 2% of each
    ///         redemption request, the `redemptionTreasuryFeeDivisor` should
    ///         be set to `50` because `1/50 = 0.02 = 2%`.
    /// @return redemptionTxMaxFee Maximum amount of BTC transaction fee that
    ///         can be incurred by each redemption request being part of the
    ///         given redemption transaction. If the maximum BTC transaction
    ///         fee is exceeded, such transaction is considered a fraud.
    ///         This is a per-redemption output max fee for the redemption
    ///         transaction.
    /// @return redemptionTxMaxTotalFee Maximum amount of the total BTC
    ///         transaction fee that is acceptable in a single redemption
    ///         transaction. This is a _total_ max fee for the entire redemption
    ///         transaction.
    /// @return redemptionTimeout Time after which the redemption request can be
    ///         reported as timed out. It is counted from the moment when the
    ///         redemption request was created via `requestRedemption` call.
    ///         Reported  timed out requests are cancelled and locked balance is
    ///         returned to the redeemer in full amount.
    /// @return redemptionTimeoutSlashingAmount The amount of stake slashed
    ///         from each member of a wallet for a redemption timeout.
    /// @return redemptionTimeoutNotifierRewardMultiplier The percentage of the
    ///         notifier reward from the staking contract the notifier of a
    ///         redemption timeout receives. The value is in the range [0, 100].
    function redemptionParameters()
        external
        view
        returns (
            uint64 redemptionDustThreshold,
            uint64 redemptionTreasuryFeeDivisor,
            uint64 redemptionTxMaxFee,
            uint64 redemptionTxMaxTotalFee,
            uint32 redemptionTimeout,
            uint96 redemptionTimeoutSlashingAmount,
            uint32 redemptionTimeoutNotifierRewardMultiplier
        )
    {
        redemptionDustThreshold = self.redemptionDustThreshold;
        redemptionTreasuryFeeDivisor = self.redemptionTreasuryFeeDivisor;
        redemptionTxMaxFee = self.redemptionTxMaxFee;
        redemptionTxMaxTotalFee = self.redemptionTxMaxTotalFee;
        redemptionTimeout = self.redemptionTimeout;
        redemptionTimeoutSlashingAmount = self.redemptionTimeoutSlashingAmount;
        redemptionTimeoutNotifierRewardMultiplier = self
            .redemptionTimeoutNotifierRewardMultiplier;
    }

    /// @notice Returns the current values of Bridge moving funds between
    ///         wallets parameters.
    /// @return movingFundsTxMaxTotalFee Maximum amount of the total BTC
    ///         transaction fee that is acceptable in a single moving funds
    ///         transaction. This is a _total_ max fee for the entire moving
    ///         funds transaction.
    /// @return movingFundsDustThreshold The minimal satoshi amount that makes
    ///         sense to be transferred during the moving funds process. Moving
    ///         funds wallets having their BTC balance below that value can
    ///         begin closing immediately as transferring such a low value may
    ///         not be possible due to BTC network fees.
    /// @return movingFundsTimeoutResetDelay Time after which the moving funds
    ///         timeout can be reset in case the target wallet commitment
    ///         cannot be submitted due to a lack of live wallets in the system.
    ///         It is counted from the moment when the wallet was requested to
    ///         move their funds and switched to the MovingFunds state or from
    ///         the moment the timeout was reset the last time. Value in seconds
    ///         This value should be lower than the value of the
    ///         `movingFundsTimeout`.
    /// @return movingFundsTimeout Time after which the moving funds process
    ///         can be reported as timed out. It is counted from the moment
    ///         when the wallet was requested to move their funds and switched
    ///         to the MovingFunds state. Value in seconds.
    /// @return movingFundsTimeoutSlashingAmount The amount of stake slashed
    ///         from each member of a wallet for a moving funds timeout.
    /// @return movingFundsTimeoutNotifierRewardMultiplier The percentage of the
    ///         notifier reward from the staking contract the notifier of a
    ///         moving funds timeout receives. The value is in the range [0, 100].
    /// @return movingFundsCommitmentGasOffset The gas offset used for the
    ///         moving funds target wallet commitment transaction cost
    ///         reimbursement.
    /// @return movedFundsSweepTxMaxTotalFee Maximum amount of the total BTC
    ///         transaction fee that is acceptable in a single moved funds
    ///         sweep transaction. This is a _total_ max fee for the entire
    ///         moved funds sweep transaction.
    /// @return movedFundsSweepTimeout Time after which the moved funds sweep
    ///         process can be reported as timed out. It is counted from the
    ///         moment when the wallet was requested to sweep the received funds.
    ///         Value in seconds.
    /// @return movedFundsSweepTimeoutSlashingAmount The amount of stake slashed
    ///         from each member of a wallet for a moved funds sweep timeout.
    /// @return movedFundsSweepTimeoutNotifierRewardMultiplier The percentage
    ///         of the notifier reward from the staking contract the notifier
    ///         of a moved funds sweep timeout receives. The value is in the
    ///         range [0, 100].
    function movingFundsParameters()
        external
        view
        returns (
            uint64 movingFundsTxMaxTotalFee,
            uint64 movingFundsDustThreshold,
            uint32 movingFundsTimeoutResetDelay,
            uint32 movingFundsTimeout,
            uint96 movingFundsTimeoutSlashingAmount,
            uint32 movingFundsTimeoutNotifierRewardMultiplier,
            uint16 movingFundsCommitmentGasOffset,
            uint64 movedFundsSweepTxMaxTotalFee,
            uint32 movedFundsSweepTimeout,
            uint96 movedFundsSweepTimeoutSlashingAmount,
            uint32 movedFundsSweepTimeoutNotifierRewardMultiplier
        )
    {
        movingFundsTxMaxTotalFee = self.movingFundsTxMaxTotalFee;
        movingFundsDustThreshold = self.movingFundsDustThreshold;
        movingFundsTimeoutResetDelay = self.movingFundsTimeoutResetDelay;
        movingFundsTimeout = self.movingFundsTimeout;
        movingFundsTimeoutSlashingAmount = self
            .movingFundsTimeoutSlashingAmount;
        movingFundsTimeoutNotifierRewardMultiplier = self
            .movingFundsTimeoutNotifierRewardMultiplier;
        movingFundsCommitmentGasOffset = self.movingFundsCommitmentGasOffset;
        movedFundsSweepTxMaxTotalFee = self.movedFundsSweepTxMaxTotalFee;
        movedFundsSweepTimeout = self.movedFundsSweepTimeout;
        movedFundsSweepTimeoutSlashingAmount = self
            .movedFundsSweepTimeoutSlashingAmount;
        movedFundsSweepTimeoutNotifierRewardMultiplier = self
            .movedFundsSweepTimeoutNotifierRewardMultiplier;
    }

    /// @return walletCreationPeriod Determines how frequently a new wallet
    ///         creation can be requested. Value in seconds.
    /// @return walletCreationMinBtcBalance The minimum BTC threshold in satoshi
    ///         that is used to decide about wallet creation.
    /// @return walletCreationMaxBtcBalance The maximum BTC threshold in satoshi
    ///         that is used to decide about wallet creation.
    /// @return walletClosureMinBtcBalance The minimum BTC threshold in satoshi
    ///         that is used to decide about wallet closure.
    /// @return walletMaxAge The maximum age of a wallet in seconds, after which
    ///         the wallet moving funds process can be requested.
    /// @return walletMaxBtcTransfer The maximum BTC amount in satoshi than
    ///         can be transferred to a single target wallet during the moving
    ///         funds process.
    /// @return walletClosingPeriod Determines the length of the wallet closing
    ///         period, i.e. the period when the wallet remains in the Closing
    ///         state and can be subject of deposit fraud challenges. Value
    ///         in seconds.
    function walletParameters()
        external
        view
        returns (
            uint32 walletCreationPeriod,
            uint64 walletCreationMinBtcBalance,
            uint64 walletCreationMaxBtcBalance,
            uint64 walletClosureMinBtcBalance,
            uint32 walletMaxAge,
            uint64 walletMaxBtcTransfer,
            uint32 walletClosingPeriod
        )
    {
        walletCreationPeriod = self.walletCreationPeriod;
        walletCreationMinBtcBalance = self.walletCreationMinBtcBalance;
        walletCreationMaxBtcBalance = self.walletCreationMaxBtcBalance;
        walletClosureMinBtcBalance = self.walletClosureMinBtcBalance;
        walletMaxAge = self.walletMaxAge;
        walletMaxBtcTransfer = self.walletMaxBtcTransfer;
        walletClosingPeriod = self.walletClosingPeriod;
    }

    /// @notice Returns the current values of Bridge fraud parameters.
    /// @return fraudChallengeDepositAmount The amount of ETH in wei the party
    ///         challenging the wallet for fraud needs to deposit.
    /// @return fraudChallengeDefeatTimeout The amount of time the wallet has to
    ///         defeat a fraud challenge.
    /// @return fraudSlashingAmount The amount slashed from each wallet member
    ///         for committing a fraud.
    /// @return fraudNotifierRewardMultiplier The percentage of the notifier
    ///         reward from the staking contract the notifier of a fraud
    ///         receives. The value is in the range [0, 100].
    function fraudParameters()
        external
        view
        returns (
            uint96 fraudChallengeDepositAmount,
            uint32 fraudChallengeDefeatTimeout,
            uint96 fraudSlashingAmount,
            uint32 fraudNotifierRewardMultiplier
        )
    {
        fraudChallengeDepositAmount = self.fraudChallengeDepositAmount;
        fraudChallengeDefeatTimeout = self.fraudChallengeDefeatTimeout;
        fraudSlashingAmount = self.fraudSlashingAmount;
        fraudNotifierRewardMultiplier = self.fraudNotifierRewardMultiplier;
    }

    /// @notice Returns the addresses of contracts Bridge is interacting with.
    /// @return bank Address of the Bank the Bridge belongs to.
    /// @return relay Address of the Bitcoin relay providing the current Bitcoin
    ///         network difficulty.
    /// @return ecdsaWalletRegistry Address of the ECDSA Wallet Registry.
    /// @return reimbursementPool Address of the Reimbursement Pool.
    function contractReferences()
        external
        view
        returns (
            Bank bank,
            IRelay relay,
            EcdsaWalletRegistry ecdsaWalletRegistry,
            ReimbursementPool reimbursementPool
        )
    {
        bank = self.bank;
        relay = self.relay;
        ecdsaWalletRegistry = self.ecdsaWalletRegistry;
        reimbursementPool = self.reimbursementPool;
    }

    /// @notice Address where the deposit treasury fees will be sent to.
    ///         Treasury takes part in the operators rewarding process.
    function treasury() external view returns (address) {
        return self.treasury;
    }

    /// @notice The number of confirmations on the Bitcoin chain required to
    ///         successfully evaluate an SPV proof.
    function txProofDifficultyFactor() external view returns (uint256) {
        return self.txProofDifficultyFactor;
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

import {IWalletRegistry as EcdsaWalletRegistry} from "@keep-network/ecdsa/contracts/api/IWalletRegistry.sol";
import "@keep-network/random-beacon/contracts/ReimbursementPool.sol";

import "./IRelay.sol";
import "./Deposit.sol";
import "./Redemption.sol";
import "./Fraud.sol";
import "./Wallets.sol";
import "./MovingFunds.sol";

import "../bank/Bank.sol";

library BridgeState {
    struct Storage {
        // Address of the Bank the Bridge belongs to.
        Bank bank;
        // Bitcoin relay providing the current Bitcoin network difficulty.
        IRelay relay;
        // The number of confirmations on the Bitcoin chain required to
        // successfully evaluate an SPV proof.
        uint96 txProofDifficultyFactor;
        // ECDSA Wallet Registry contract handle.
        EcdsaWalletRegistry ecdsaWalletRegistry;
        // Reimbursement Pool contract handle.
        ReimbursementPool reimbursementPool;
        // Address where the deposit and redemption treasury fees will be sent
        // to. Treasury takes part in the operators rewarding process.
        address treasury;
        // Move depositDustThreshold to the next storage slot for a more
        // efficient variable layout in the storage.
        // slither-disable-next-line unused-state
        bytes32 __treasuryAlignmentGap;
        // The minimal amount that can be requested to deposit.
        // Value of this parameter must take into account the value of
        // `depositTreasuryFeeDivisor` and `depositTxMaxFee` parameters in order
        // to make requests that can incur the treasury and transaction fee and
        // still satisfy the depositor.
        uint64 depositDustThreshold;
        // Divisor used to compute the treasury fee taken from each deposit and
        // transferred to the treasury upon sweep proof submission. That fee is
        // computed as follows:
        // `treasuryFee = depositedAmount / depositTreasuryFeeDivisor`
        // For example, if the treasury fee needs to be 2% of each deposit,
        // the `depositTreasuryFeeDivisor` should be set to `50` because
        // `1/50 = 0.02 = 2%`.
        uint64 depositTreasuryFeeDivisor;
        // Maximum amount of BTC transaction fee that can be incurred by each
        // swept deposit being part of the given sweep transaction. If the
        // maximum BTC transaction fee is exceeded, such transaction is
        // considered a fraud.
        //
        // This is a per-deposit input max fee for the sweep transaction.
        uint64 depositTxMaxFee;
        // Defines the length of the period that must be preserved between
        // the deposit reveal time and the deposit refund locktime. For example,
        // if the deposit become refundable on August 1st, and the ahead period
        // is 7 days, the latest moment for deposit reveal is July 25th.
        // Value in seconds. The value equal to zero disables the validation
        // of this parameter.
        uint32 depositRevealAheadPeriod;
        // Move movingFundsTxMaxTotalFee to the next storage slot for a more
        // efficient variable layout in the storage.
        // slither-disable-next-line unused-state
        bytes32 __depositAlignmentGap;
        // Maximum amount of the total BTC transaction fee that is acceptable in
        // a single moving funds transaction.
        //
        // This is a TOTAL max fee for the moving funds transaction. Note
        // that `depositTxMaxFee` is per single deposit and `redemptionTxMaxFee`
        // is per single redemption. `movingFundsTxMaxTotalFee` is a total
        // fee for the entire transaction.
        uint64 movingFundsTxMaxTotalFee;
        // The minimal satoshi amount that makes sense to be transferred during
        // the moving funds process. Moving funds wallets having their BTC
        // balance below that value can begin closing immediately as
        // transferring such a low value may not be possible due to
        // BTC network fees. The value of this parameter must always be lower
        // than `redemptionDustThreshold` in order to prevent redemption requests
        // with values lower or equal to `movingFundsDustThreshold`.
        uint64 movingFundsDustThreshold;
        // Time after which the moving funds timeout can be reset in case the
        // target wallet commitment cannot be submitted due to a lack of live
        // wallets in the system. It is counted from the moment when the wallet
        // was requested to move their funds and switched to the MovingFunds
        // state or from the moment the timeout was reset the last time.
        // Value in seconds. This value should be lower than the value
        // of the `movingFundsTimeout`.
        uint32 movingFundsTimeoutResetDelay;
        // Time after which the moving funds process can be reported as
        // timed out. It is counted from the moment when the wallet
        // was requested to move their funds and switched to the MovingFunds
        // state. Value in seconds.
        uint32 movingFundsTimeout;
        // The amount of stake slashed from each member of a wallet for a moving
        // funds timeout.
        uint96 movingFundsTimeoutSlashingAmount;
        // The percentage of the notifier reward from the staking contract
        // the notifier of a moving funds timeout receives. The value is in the
        // range [0, 100].
        uint32 movingFundsTimeoutNotifierRewardMultiplier;
        // The gas offset used for the target wallet commitment transaction cost
        // reimbursement.
        uint16 movingFundsCommitmentGasOffset;
        // Move movedFundsSweepTxMaxTotalFee to the next storage slot for a more
        // efficient variable layout in the storage.
        // slither-disable-next-line unused-state
        bytes32 __movingFundsAlignmentGap;
        // Maximum amount of the total BTC transaction fee that is acceptable in
        // a single moved funds sweep transaction.
        //
        // This is a TOTAL max fee for the moved funds sweep transaction. Note
        // that `depositTxMaxFee` is per single deposit and `redemptionTxMaxFee`
        // is per single redemption. `movedFundsSweepTxMaxTotalFee` is a total
        // fee for the entire transaction.
        uint64 movedFundsSweepTxMaxTotalFee;
        // Time after which the moved funds sweep process can be reported as
        // timed out. It is counted from the moment when the recipient wallet
        // was requested to sweep the received funds. Value in seconds.
        uint32 movedFundsSweepTimeout;
        // The amount of stake slashed from each member of a wallet for a moved
        // funds sweep timeout.
        uint96 movedFundsSweepTimeoutSlashingAmount;
        // The percentage of the notifier reward from the staking contract
        // the notifier of a moved funds sweep timeout receives. The value is
        // in the range [0, 100].
        uint32 movedFundsSweepTimeoutNotifierRewardMultiplier;
        // The minimal amount that can be requested for redemption.
        // Value of this parameter must take into account the value of
        // `redemptionTreasuryFeeDivisor` and `redemptionTxMaxFee`
        // parameters in order to make requests that can incur the
        // treasury and transaction fee and still satisfy the redeemer.
        // Additionally, the value of this parameter must always be greater
        // than `movingFundsDustThreshold` in order to prevent redemption
        // requests with values lower or equal to `movingFundsDustThreshold`.
        uint64 redemptionDustThreshold;
        // Divisor used to compute the treasury fee taken from each
        // redemption request and transferred to the treasury upon
        // successful request finalization. That fee is computed as follows:
        // `treasuryFee = requestedAmount / redemptionTreasuryFeeDivisor`
        // For example, if the treasury fee needs to be 2% of each
        // redemption request, the `redemptionTreasuryFeeDivisor` should
        // be set to `50` because `1/50 = 0.02 = 2%`.
        uint64 redemptionTreasuryFeeDivisor;
        // Maximum amount of BTC transaction fee that can be incurred by
        // each redemption request being part of the given redemption
        // transaction. If the maximum BTC transaction fee is exceeded, such
        // transaction is considered a fraud.
        //
        // This is a per-redemption output max fee for the redemption
        // transaction.
        uint64 redemptionTxMaxFee;
        // Maximum amount of the total BTC transaction fee that is acceptable in
        // a single redemption transaction.
        //
        // This is a TOTAL max fee for the redemption transaction. Note
        // that the `redemptionTxMaxFee` is per single redemption.
        // `redemptionTxMaxTotalFee` is a total fee for the entire transaction.
        uint64 redemptionTxMaxTotalFee;
        // Move redemptionTimeout to the next storage slot for a more efficient
        // variable layout in the storage.
        // slither-disable-next-line unused-state
        bytes32 __redemptionAlignmentGap;
        // Time after which the redemption request can be reported as
        // timed out. It is counted from the moment when the redemption
        // request was created via `requestRedemption` call. Reported
        // timed out requests are cancelled and locked TBTC is returned
        // to the redeemer in full amount.
        uint32 redemptionTimeout;
        // The amount of stake slashed from each member of a wallet for a
        // redemption timeout.
        uint96 redemptionTimeoutSlashingAmount;
        // The percentage of the notifier reward from the staking contract
        // the notifier of a redemption timeout receives. The value is in the
        // range [0, 100].
        uint32 redemptionTimeoutNotifierRewardMultiplier;
        // The amount of ETH in wei the party challenging the wallet for fraud
        // needs to deposit.
        uint96 fraudChallengeDepositAmount;
        // The amount of time the wallet has to defeat a fraud challenge.
        uint32 fraudChallengeDefeatTimeout;
        // The amount of stake slashed from each member of a wallet for a fraud.
        uint96 fraudSlashingAmount;
        // The percentage of the notifier reward from the staking contract
        // the notifier of a fraud receives. The value is in the range [0, 100].
        uint32 fraudNotifierRewardMultiplier;
        // Determines how frequently a new wallet creation can be requested.
        // Value in seconds.
        uint32 walletCreationPeriod;
        // The minimum BTC threshold in satoshi that is used to decide about
        // wallet creation. Specifically, we allow for the creation of a new
        // wallet if the active wallet is old enough and their amount of BTC
        // is greater than or equal this threshold.
        uint64 walletCreationMinBtcBalance;
        // The maximum BTC threshold in satoshi that is used to decide about
        // wallet creation. Specifically, we allow for the creation of a new
        // wallet if the active wallet's amount of BTC is greater than or equal
        // this threshold, regardless of the active wallet's age.
        uint64 walletCreationMaxBtcBalance;
        // The minimum BTC threshold in satoshi that is used to decide about
        // wallet closing. Specifically, we allow for the closure of the given
        // wallet if their amount of BTC is lesser than this threshold,
        // regardless of the wallet's age.
        uint64 walletClosureMinBtcBalance;
        // The maximum age of a wallet in seconds, after which the wallet
        // moving funds process can be requested.
        uint32 walletMaxAge;
        // 20-byte wallet public key hash being reference to the currently
        // active wallet. Can be unset to the zero value under certain
        // circumstances.
        bytes20 activeWalletPubKeyHash;
        // The current number of wallets in the Live state.
        uint32 liveWalletsCount;
        // The maximum BTC amount in satoshi than can be transferred to a single
        // target wallet during the moving funds process.
        uint64 walletMaxBtcTransfer;
        // Determines the length of the wallet closing period, i.e. the period
        // when the wallet remains in the Closing state and can be subject
        // of deposit fraud challenges. This value is in seconds and should be
        // greater than the deposit refund time plus some time margin.
        uint32 walletClosingPeriod;
        // Collection of all revealed deposits indexed by
        // `keccak256(fundingTxHash | fundingOutputIndex)`.
        // The `fundingTxHash` is `bytes32` (ordered as in Bitcoin internally)
        // and `fundingOutputIndex` an `uint32`. This mapping may contain valid
        // and invalid deposits and the wallet is responsible for validating
        // them before attempting to execute a sweep.
        mapping(uint256 => Deposit.DepositRequest) deposits;
        // Indicates if the vault with the given address is trusted.
        // Depositors can route their revealed deposits only to trusted vaults
        // and have trusted vaults notified about new deposits as soon as these
        // deposits get swept. Vaults not trusted by the Bridge can still be
        // used by Bank balance owners on their own responsibility - anyone can
        // approve their Bank balance to any address.
        mapping(address => bool) isVaultTrusted;
        // Indicates if the address is a trusted SPV maintainer.
        // The SPV proof does not check whether the transaction is a part of the
        // Bitcoin mainnet, it only checks whether the transaction has been
        // mined performing the required amount of work as on Bitcoin mainnet.
        // The possibility of submitting SPV proofs is limited to trusted SPV
        // maintainers. The system expects transaction confirmations with the
        // required work accumulated, so trusted SPV maintainers can not prove
        // the transaction without providing the required Bitcoin proof of work.
        // Trusted maintainers address the issue of an economic game between
        // tBTC and Bitcoin mainnet where large Bitcoin mining pools can decide
        // to use their hash power to mine fake Bitcoin blocks to prove them in
        // tBTC instead of receiving Bitcoin miner rewards.
        mapping(address => bool) isSpvMaintainer;
        // Collection of all moved funds sweep requests indexed by
        // `keccak256(movingFundsTxHash | movingFundsOutputIndex)`.
        // The `movingFundsTxHash` is `bytes32` (ordered as in Bitcoin
        // internally) and `movingFundsOutputIndex` an `uint32`. Each entry
        // is actually an UTXO representing the moved funds and is supposed
        // to be swept with the current main UTXO of the recipient wallet.
        mapping(uint256 => MovingFunds.MovedFundsSweepRequest) movedFundsSweepRequests;
        // Collection of all pending redemption requests indexed by
        // redemption key built as
        // `keccak256(keccak256(redeemerOutputScript) | walletPubKeyHash)`.
        // The `walletPubKeyHash` is the 20-byte wallet's public key hash
        // (computed using Bitcoin HASH160 over the compressed ECDSA
        // public key) and `redeemerOutputScript` is a Bitcoin script
        // (P2PKH, P2WPKH, P2SH or P2WSH) that will be used to lock
        // redeemed BTC as requested by the redeemer. Requests are added
        // to this mapping by the `requestRedemption` method (duplicates
        // not allowed) and are removed by one of the following methods:
        // - `submitRedemptionProof` in case the request was handled
        //    successfully,
        // - `notifyRedemptionTimeout` in case the request was reported
        //    to be timed out.
        mapping(uint256 => Redemption.RedemptionRequest) pendingRedemptions;
        // Collection of all timed out redemptions requests indexed by
        // redemption key built as
        // `keccak256(keccak256(redeemerOutputScript) | walletPubKeyHash)`.
        // The `walletPubKeyHash` is the 20-byte wallet's public key hash
        // (computed using Bitcoin HASH160 over the compressed ECDSA
        // public key) and `redeemerOutputScript` is the Bitcoin script
        // (P2PKH, P2WPKH, P2SH or P2WSH) that is involved in the timed
        // out request.
        // Only one method can add to this mapping:
        // - `notifyRedemptionTimeout` which puts the redemption key to this
        //    mapping based on a timed out request stored previously in
        //    `pendingRedemptions` mapping.
        // Only one method can remove entries from this mapping:
        // - `submitRedemptionProof` in case the timed out redemption request
        //    was a part of the proven transaction.
        mapping(uint256 => Redemption.RedemptionRequest) timedOutRedemptions;
        // Collection of all submitted fraud challenges indexed by challenge
        // key built as `keccak256(walletPublicKey|sighash)`.
        mapping(uint256 => Fraud.FraudChallenge) fraudChallenges;
        // Collection of main UTXOs that are honestly spent indexed by
        // `keccak256(fundingTxHash | fundingOutputIndex)`. The `fundingTxHash`
        // is `bytes32` (ordered as in Bitcoin internally) and
        // `fundingOutputIndex` an `uint32`. A main UTXO is considered honestly
        // spent if it was used as an input of a transaction that have been
        // proven in the Bridge.
        mapping(uint256 => bool) spentMainUTXOs;
        // Maps the 20-byte wallet public key hash (computed using Bitcoin
        // HASH160 over the compressed ECDSA public key) to the basic wallet
        // information like state and pending redemptions value.
        mapping(bytes20 => Wallets.Wallet) registeredWallets;
        // Reserved storage space in case we need to add more variables.
        // The convention from OpenZeppelin suggests the storage space should
        // add up to 50 slots. Here we want to have more slots as there are
        // planned upgrades of the Bridge contract. If more entires are added to
        // the struct in the upcoming versions we need to reduce the array size.
        // See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
        // slither-disable-next-line unused-state
        uint256[50] __gap;
    }

    event DepositParametersUpdated(
        uint64 depositDustThreshold,
        uint64 depositTreasuryFeeDivisor,
        uint64 depositTxMaxFee,
        uint32 depositRevealAheadPeriod
    );

    event RedemptionParametersUpdated(
        uint64 redemptionDustThreshold,
        uint64 redemptionTreasuryFeeDivisor,
        uint64 redemptionTxMaxFee,
        uint64 redemptionTxMaxTotalFee,
        uint32 redemptionTimeout,
        uint96 redemptionTimeoutSlashingAmount,
        uint32 redemptionTimeoutNotifierRewardMultiplier
    );

    event MovingFundsParametersUpdated(
        uint64 movingFundsTxMaxTotalFee,
        uint64 movingFundsDustThreshold,
        uint32 movingFundsTimeoutResetDelay,
        uint32 movingFundsTimeout,
        uint96 movingFundsTimeoutSlashingAmount,
        uint32 movingFundsTimeoutNotifierRewardMultiplier,
        uint16 movingFundsCommitmentGasOffset,
        uint64 movedFundsSweepTxMaxTotalFee,
        uint32 movedFundsSweepTimeout,
        uint96 movedFundsSweepTimeoutSlashingAmount,
        uint32 movedFundsSweepTimeoutNotifierRewardMultiplier
    );

    event WalletParametersUpdated(
        uint32 walletCreationPeriod,
        uint64 walletCreationMinBtcBalance,
        uint64 walletCreationMaxBtcBalance,
        uint64 walletClosureMinBtcBalance,
        uint32 walletMaxAge,
        uint64 walletMaxBtcTransfer,
        uint32 walletClosingPeriod
    );

    event FraudParametersUpdated(
        uint96 fraudChallengeDepositAmount,
        uint32 fraudChallengeDefeatTimeout,
        uint96 fraudSlashingAmount,
        uint32 fraudNotifierRewardMultiplier
    );

    event TreasuryUpdated(address treasury);

    /// @notice Updates parameters of deposits.
    /// @param _depositDustThreshold New value of the deposit dust threshold in
    ///        satoshis. It is the minimal amount that can be requested to
    ////       deposit. Value of this parameter must take into account the value
    ///        of `depositTreasuryFeeDivisor` and `depositTxMaxFee` parameters
    ///        in order to make requests that can incur the treasury and
    ///        transaction fee and still satisfy the depositor.
    /// @param _depositTreasuryFeeDivisor New value of the treasury fee divisor.
    ///        It is the divisor used to compute the treasury fee taken from
    ///        each deposit and transferred to the treasury upon sweep proof
    ///        submission. That fee is computed as follows:
    ///        `treasuryFee = depositedAmount / depositTreasuryFeeDivisor`
    ///        For example, if the treasury fee needs to be 2% of each deposit,
    ///        the `depositTreasuryFeeDivisor` should be set to `50`
    ///        because `1/50 = 0.02 = 2%`.
    /// @param _depositTxMaxFee New value of the deposit tx max fee in satoshis.
    ///        It is the maximum amount of BTC transaction fee that can
    ///        be incurred by each swept deposit being part of the given sweep
    ///        transaction. If the maximum BTC transaction fee is exceeded,
    ///        such transaction is considered a fraud.
    /// @param _depositRevealAheadPeriod New value of the deposit reveal ahead
    ///        period parameter in seconds. It defines the length of the period
    ///        that must be preserved between the deposit reveal time and the
    ///        deposit refund locktime.
    /// @dev Requirements:
    ///      - Deposit dust threshold must be greater than zero,
    ///      - Deposit dust threshold must be greater than deposit TX max fee,
    ///      - Deposit transaction max fee must be greater than zero.
    function updateDepositParameters(
        Storage storage self,
        uint64 _depositDustThreshold,
        uint64 _depositTreasuryFeeDivisor,
        uint64 _depositTxMaxFee,
        uint32 _depositRevealAheadPeriod
    ) internal {
        require(
            _depositDustThreshold > 0,
            "Deposit dust threshold must be greater than zero"
        );

        require(
            _depositDustThreshold > _depositTxMaxFee,
            "Deposit dust threshold must be greater than deposit TX max fee"
        );

        require(
            _depositTxMaxFee > 0,
            "Deposit transaction max fee must be greater than zero"
        );

        self.depositDustThreshold = _depositDustThreshold;
        self.depositTreasuryFeeDivisor = _depositTreasuryFeeDivisor;
        self.depositTxMaxFee = _depositTxMaxFee;
        self.depositRevealAheadPeriod = _depositRevealAheadPeriod;

        emit DepositParametersUpdated(
            _depositDustThreshold,
            _depositTreasuryFeeDivisor,
            _depositTxMaxFee,
            _depositRevealAheadPeriod
        );
    }

    /// @notice Updates parameters of redemptions.
    /// @param _redemptionDustThreshold New value of the redemption dust
    ///        threshold in satoshis. It is the minimal amount that can be
    ///        requested for redemption. Value of this parameter must take into
    ///        account the value of `redemptionTreasuryFeeDivisor` and
    ///        `redemptionTxMaxFee` parameters in order to make requests that
    ///        can incur the treasury and transaction fee and still satisfy the
    ///        redeemer.
    /// @param _redemptionTreasuryFeeDivisor New value of the redemption
    ///        treasury fee divisor. It is the divisor used to compute the
    ///        treasury fee taken from each redemption request and transferred
    ///        to the treasury upon successful request finalization. That fee is
    ///        computed as follows:
    ///        `treasuryFee = requestedAmount / redemptionTreasuryFeeDivisor`
    ///        For example, if the treasury fee needs to be 2% of each
    ///        redemption request, the `redemptionTreasuryFeeDivisor` should
    ///        be set to `50` because `1/50 = 0.02 = 2%`.
    /// @param _redemptionTxMaxFee New value of the redemption transaction max
    ///        fee in satoshis. It is the maximum amount of BTC transaction fee
    ///        that can be incurred by each redemption request being part of the
    ///        given redemption transaction. If the maximum BTC transaction fee
    ///        is exceeded, such transaction is considered a fraud.
    ///        This is a per-redemption output max fee for the redemption
    ///        transaction.
    /// @param _redemptionTxMaxTotalFee New value of the redemption transaction
    ///        max total fee in satoshis. It is the maximum amount of the total
    ///        BTC transaction fee that is acceptable in a single redemption
    ///        transaction. This is a _total_ max fee for the entire redemption
    ///        transaction.
    /// @param _redemptionTimeout New value of the redemption timeout in seconds.
    ///        It is the time after which the redemption request can be reported
    ///        as timed out. It is counted from the moment when the redemption
    ///        request was created via `requestRedemption` call. Reported  timed
    ///        out requests are cancelled and locked TBTC is returned to the
    ///        redeemer in full amount.
    /// @param _redemptionTimeoutSlashingAmount New value of the redemption
    ///        timeout slashing amount in T, it is the amount slashed from each
    ///        wallet member for redemption timeout.
    /// @param _redemptionTimeoutNotifierRewardMultiplier New value of the
    ///        redemption timeout notifier reward multiplier as percentage,
    ///        it determines the percentage of the notifier reward from the
    ///        staking contact the notifier of a redemption timeout receives.
    ///        The value must be in the range [0, 100].
    /// @dev Requirements:
    ///      - Redemption dust threshold must be greater than moving funds dust
    ///        threshold,
    ///      - Redemption dust threshold must be greater than the redemption TX
    ///        max fee,
    ///      - Redemption transaction max fee must be greater than zero,
    ///      - Redemption transaction max total fee must be greater than or
    ///        equal to the redemption transaction per-request max fee,
    ///      - Redemption timeout must be greater than zero,
    ///      - Redemption timeout notifier reward multiplier must be in the
    ///        range [0, 100].
    function updateRedemptionParameters(
        Storage storage self,
        uint64 _redemptionDustThreshold,
        uint64 _redemptionTreasuryFeeDivisor,
        uint64 _redemptionTxMaxFee,
        uint64 _redemptionTxMaxTotalFee,
        uint32 _redemptionTimeout,
        uint96 _redemptionTimeoutSlashingAmount,
        uint32 _redemptionTimeoutNotifierRewardMultiplier
    ) internal {
        require(
            _redemptionDustThreshold > self.movingFundsDustThreshold,
            "Redemption dust threshold must be greater than moving funds dust threshold"
        );

        require(
            _redemptionDustThreshold > _redemptionTxMaxFee,
            "Redemption dust threshold must be greater than redemption TX max fee"
        );

        require(
            _redemptionTxMaxFee > 0,
            "Redemption transaction max fee must be greater than zero"
        );

        require(
            _redemptionTxMaxTotalFee >= _redemptionTxMaxFee,
            "Redemption transaction max total fee must be greater than or equal to the redemption transaction per-request max fee"
        );

        require(
            _redemptionTimeout > 0,
            "Redemption timeout must be greater than zero"
        );

        require(
            _redemptionTimeoutNotifierRewardMultiplier <= 100,
            "Redemption timeout notifier reward multiplier must be in the range [0, 100]"
        );

        self.redemptionDustThreshold = _redemptionDustThreshold;
        self.redemptionTreasuryFeeDivisor = _redemptionTreasuryFeeDivisor;
        self.redemptionTxMaxFee = _redemptionTxMaxFee;
        self.redemptionTxMaxTotalFee = _redemptionTxMaxTotalFee;
        self.redemptionTimeout = _redemptionTimeout;
        self.redemptionTimeoutSlashingAmount = _redemptionTimeoutSlashingAmount;
        self
            .redemptionTimeoutNotifierRewardMultiplier = _redemptionTimeoutNotifierRewardMultiplier;

        emit RedemptionParametersUpdated(
            _redemptionDustThreshold,
            _redemptionTreasuryFeeDivisor,
            _redemptionTxMaxFee,
            _redemptionTxMaxTotalFee,
            _redemptionTimeout,
            _redemptionTimeoutSlashingAmount,
            _redemptionTimeoutNotifierRewardMultiplier
        );
    }

    /// @notice Updates parameters of moving funds.
    /// @param _movingFundsTxMaxTotalFee New value of the moving funds transaction
    ///        max total fee in satoshis. It is the maximum amount of the total
    ///        BTC transaction fee that is acceptable in a single moving funds
    ///        transaction. This is a _total_ max fee for the entire moving
    ///        funds transaction.
    /// @param _movingFundsDustThreshold New value of the moving funds dust
    ///        threshold. It is the minimal satoshi amount that makes sense to
    ///        be transferred during the moving funds process. Moving funds
    ///        wallets having their BTC balance below that value can begin
    ///        closing immediately as transferring such a low value may not be
    ///        possible due to BTC network fees.
    /// @param _movingFundsTimeoutResetDelay New value of the moving funds
    ///        timeout reset delay in seconds. It is the time after which the
    ///        moving funds timeout can be reset in case the target wallet
    ///        commitment cannot be submitted due to a lack of live wallets
    ///        in the system. It is counted from the moment when the wallet
    ///        was requested to move their funds and switched to the MovingFunds
    ///        state or from the moment the timeout was reset the last time.
    /// @param _movingFundsTimeout New value of the moving funds timeout in
    ///        seconds. It is the time after which the moving funds process can
    ///        be reported as timed out. It is counted from the moment when the
    ///        wallet was requested to move their funds and switched to the
    ///        MovingFunds state.
    /// @param _movingFundsTimeoutSlashingAmount New value of the moving funds
    ///        timeout slashing amount in T, it is the amount slashed from each
    ///        wallet member for moving funds timeout.
    /// @param _movingFundsTimeoutNotifierRewardMultiplier New value of the
    ///        moving funds timeout notifier reward multiplier as percentage,
    ///        it determines the percentage of the notifier reward from the
    ///        staking contact the notifier of a moving funds timeout receives.
    ///        The value must be in the range [0, 100].
    /// @param _movingFundsCommitmentGasOffset New value of the gas offset for
    ///        moving funds target wallet commitment transaction gas costs
    ///        reimbursement.
    /// @param _movedFundsSweepTxMaxTotalFee New value of the moved funds sweep
    ///        transaction max total fee in satoshis. It is the maximum amount
    ///        of the total BTC transaction fee that is acceptable in a single
    ///        moved funds sweep transaction. This is a _total_ max fee for the
    ///        entire moved funds sweep transaction.
    /// @param _movedFundsSweepTimeout New value of the moved funds sweep
    ///        timeout in seconds. It is the time after which the moved funds
    ///        sweep process can be reported as timed out. It is counted from
    ///        the moment when the wallet was requested to sweep the received
    ///        funds.
    /// @param _movedFundsSweepTimeoutSlashingAmount New value of the moved
    ///        funds sweep timeout slashing amount in T, it is the amount
    ///        slashed from each wallet member for moved funds sweep timeout.
    /// @param _movedFundsSweepTimeoutNotifierRewardMultiplier New value of
    ///        the moved funds sweep timeout notifier reward multiplier as
    ///        percentage, it determines the percentage of the notifier reward
    ///        from the staking contact the notifier of a moved funds sweep
    ///        timeout receives. The value must be in the range [0, 100].
    /// @dev Requirements:
    ///      - Moving funds transaction max total fee must be greater than zero,
    ///      - Moving funds dust threshold must be greater than zero and lower
    ///        than the redemption dust threshold,
    ///      - Moving funds timeout reset delay must be greater than zero,
    ///      - Moving funds timeout must be greater than the moving funds
    ///        timeout reset delay,
    ///      - Moving funds timeout notifier reward multiplier must be in the
    ///        range [0, 100],
    ///      - Moved funds sweep transaction max total fee must be greater than zero,
    ///      - Moved funds sweep timeout must be greater than zero,
    ///      - Moved funds sweep timeout notifier reward multiplier must be in the
    ///        range [0, 100].
    function updateMovingFundsParameters(
        Storage storage self,
        uint64 _movingFundsTxMaxTotalFee,
        uint64 _movingFundsDustThreshold,
        uint32 _movingFundsTimeoutResetDelay,
        uint32 _movingFundsTimeout,
        uint96 _movingFundsTimeoutSlashingAmount,
        uint32 _movingFundsTimeoutNotifierRewardMultiplier,
        uint16 _movingFundsCommitmentGasOffset,
        uint64 _movedFundsSweepTxMaxTotalFee,
        uint32 _movedFundsSweepTimeout,
        uint96 _movedFundsSweepTimeoutSlashingAmount,
        uint32 _movedFundsSweepTimeoutNotifierRewardMultiplier
    ) internal {
        require(
            _movingFundsTxMaxTotalFee > 0,
            "Moving funds transaction max total fee must be greater than zero"
        );

        require(
            _movingFundsDustThreshold > 0 &&
                _movingFundsDustThreshold < self.redemptionDustThreshold,
            "Moving funds dust threshold must be greater than zero and lower than redemption dust threshold"
        );

        require(
            _movingFundsTimeoutResetDelay > 0,
            "Moving funds timeout reset delay must be greater than zero"
        );

        require(
            _movingFundsTimeout > _movingFundsTimeoutResetDelay,
            "Moving funds timeout must be greater than its reset delay"
        );

        require(
            _movingFundsTimeoutNotifierRewardMultiplier <= 100,
            "Moving funds timeout notifier reward multiplier must be in the range [0, 100]"
        );

        require(
            _movedFundsSweepTxMaxTotalFee > 0,
            "Moved funds sweep transaction max total fee must be greater than zero"
        );

        require(
            _movedFundsSweepTimeout > 0,
            "Moved funds sweep timeout must be greater than zero"
        );

        require(
            _movedFundsSweepTimeoutNotifierRewardMultiplier <= 100,
            "Moved funds sweep timeout notifier reward multiplier must be in the range [0, 100]"
        );

        self.movingFundsTxMaxTotalFee = _movingFundsTxMaxTotalFee;
        self.movingFundsDustThreshold = _movingFundsDustThreshold;
        self.movingFundsTimeoutResetDelay = _movingFundsTimeoutResetDelay;
        self.movingFundsTimeout = _movingFundsTimeout;
        self
            .movingFundsTimeoutSlashingAmount = _movingFundsTimeoutSlashingAmount;
        self
            .movingFundsTimeoutNotifierRewardMultiplier = _movingFundsTimeoutNotifierRewardMultiplier;
        self.movingFundsCommitmentGasOffset = _movingFundsCommitmentGasOffset;
        self.movedFundsSweepTxMaxTotalFee = _movedFundsSweepTxMaxTotalFee;
        self.movedFundsSweepTimeout = _movedFundsSweepTimeout;
        self
            .movedFundsSweepTimeoutSlashingAmount = _movedFundsSweepTimeoutSlashingAmount;
        self
            .movedFundsSweepTimeoutNotifierRewardMultiplier = _movedFundsSweepTimeoutNotifierRewardMultiplier;

        emit MovingFundsParametersUpdated(
            _movingFundsTxMaxTotalFee,
            _movingFundsDustThreshold,
            _movingFundsTimeoutResetDelay,
            _movingFundsTimeout,
            _movingFundsTimeoutSlashingAmount,
            _movingFundsTimeoutNotifierRewardMultiplier,
            _movingFundsCommitmentGasOffset,
            _movedFundsSweepTxMaxTotalFee,
            _movedFundsSweepTimeout,
            _movedFundsSweepTimeoutSlashingAmount,
            _movedFundsSweepTimeoutNotifierRewardMultiplier
        );
    }

    /// @notice Updates parameters of wallets.
    /// @param _walletCreationPeriod New value of the wallet creation period in
    ///        seconds, determines how frequently a new wallet creation can be
    ///        requested.
    /// @param _walletCreationMinBtcBalance New value of the wallet minimum BTC
    ///        balance in satoshi, used to decide about wallet creation.
    /// @param _walletCreationMaxBtcBalance New value of the wallet maximum BTC
    ///        balance in satoshi, used to decide about wallet creation.
    /// @param _walletClosureMinBtcBalance New value of the wallet minimum BTC
    ///        balance in satoshi, used to decide about wallet closure.
    /// @param _walletMaxAge New value of the wallet maximum age in seconds,
    ///        indicates the maximum age of a wallet in seconds, after which
    ///        the wallet moving funds process can be requested.
    /// @param _walletMaxBtcTransfer New value of the wallet maximum BTC transfer
    ///        in satoshi, determines the maximum amount that can be transferred
    ///        to a single target wallet during the moving funds process.
    /// @param _walletClosingPeriod New value of the wallet closing period in
    ///        seconds, determines the length of the wallet closing period,
    //         i.e. the period when the wallet remains in the Closing state
    //         and can be subject of deposit fraud challenges.
    /// @dev Requirements:
    ///      - Wallet maximum BTC balance must be greater than the wallet
    ///        minimum BTC balance,
    ///      - Wallet maximum BTC transfer must be greater than zero,
    ///      - Wallet closing period must be greater than zero.
    function updateWalletParameters(
        Storage storage self,
        uint32 _walletCreationPeriod,
        uint64 _walletCreationMinBtcBalance,
        uint64 _walletCreationMaxBtcBalance,
        uint64 _walletClosureMinBtcBalance,
        uint32 _walletMaxAge,
        uint64 _walletMaxBtcTransfer,
        uint32 _walletClosingPeriod
    ) internal {
        require(
            _walletCreationMaxBtcBalance > _walletCreationMinBtcBalance,
            "Wallet creation maximum BTC balance must be greater than the creation minimum BTC balance"
        );
        require(
            _walletMaxBtcTransfer > 0,
            "Wallet maximum BTC transfer must be greater than zero"
        );
        require(
            _walletClosingPeriod > 0,
            "Wallet closing period must be greater than zero"
        );

        self.walletCreationPeriod = _walletCreationPeriod;
        self.walletCreationMinBtcBalance = _walletCreationMinBtcBalance;
        self.walletCreationMaxBtcBalance = _walletCreationMaxBtcBalance;
        self.walletClosureMinBtcBalance = _walletClosureMinBtcBalance;
        self.walletMaxAge = _walletMaxAge;
        self.walletMaxBtcTransfer = _walletMaxBtcTransfer;
        self.walletClosingPeriod = _walletClosingPeriod;

        emit WalletParametersUpdated(
            _walletCreationPeriod,
            _walletCreationMinBtcBalance,
            _walletCreationMaxBtcBalance,
            _walletClosureMinBtcBalance,
            _walletMaxAge,
            _walletMaxBtcTransfer,
            _walletClosingPeriod
        );
    }

    /// @notice Updates parameters related to frauds.
    /// @param _fraudChallengeDepositAmount New value of the fraud challenge
    ///        deposit amount in wei, it is the amount of ETH the party
    ///        challenging the wallet for fraud needs to deposit.
    /// @param _fraudChallengeDefeatTimeout New value of the challenge defeat
    ///        timeout in seconds, it is the amount of time the wallet has to
    ///        defeat a fraud challenge. The value must be greater than zero.
    /// @param _fraudSlashingAmount New value of the fraud slashing amount in T,
    ///        it is the amount slashed from each wallet member for committing
    ///        a fraud.
    /// @param _fraudNotifierRewardMultiplier New value of the fraud notifier
    ///        reward multiplier as percentage, it determines the percentage of
    ///        the notifier reward from the staking contact the notifier of
    ///        a fraud receives. The value must be in the range [0, 100].
    /// @dev Requirements:
    ///      - Fraud challenge defeat timeout must be greater than 0,
    ///      - Fraud notifier reward multiplier must be in the range [0, 100].
    function updateFraudParameters(
        Storage storage self,
        uint96 _fraudChallengeDepositAmount,
        uint32 _fraudChallengeDefeatTimeout,
        uint96 _fraudSlashingAmount,
        uint32 _fraudNotifierRewardMultiplier
    ) internal {
        require(
            _fraudChallengeDefeatTimeout > 0,
            "Fraud challenge defeat timeout must be greater than zero"
        );

        require(
            _fraudNotifierRewardMultiplier <= 100,
            "Fraud notifier reward multiplier must be in the range [0, 100]"
        );

        self.fraudChallengeDepositAmount = _fraudChallengeDepositAmount;
        self.fraudChallengeDefeatTimeout = _fraudChallengeDefeatTimeout;
        self.fraudSlashingAmount = _fraudSlashingAmount;
        self.fraudNotifierRewardMultiplier = _fraudNotifierRewardMultiplier;

        emit FraudParametersUpdated(
            _fraudChallengeDepositAmount,
            _fraudChallengeDefeatTimeout,
            _fraudSlashingAmount,
            _fraudNotifierRewardMultiplier
        );
    }

    /// @notice Updates treasury address. The treasury receives the system fees.
    /// @param _treasury New value of the treasury address.
    /// @dev The treasury address must not be 0x0.
    function updateTreasury(Storage storage self, address _treasury) internal {
        require(_treasury != address(0), "Treasury address must not be 0x0");

        self.treasury = _treasury;
        emit TreasuryUpdated(_treasury);
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

import {BTCUtils} from "@keep-network/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@keep-network/bitcoin-spv-sol/contracts/BytesLib.sol";

import "./BitcoinTx.sol";
import "./BridgeState.sol";
import "./Wallets.sol";

/// @title Bridge deposit
/// @notice The library handles the logic for revealing Bitcoin deposits to
///         the Bridge.
/// @dev The depositor puts together a P2SH or P2WSH address to deposit the
///      funds. This script is unique to each depositor and looks like this:
///
///      ```
///      <depositorAddress> DROP
///      <blindingFactor> DROP
///      DUP HASH160 <walletPubKeyHash> EQUAL
///      IF
///        CHECKSIG
///      ELSE
///        DUP HASH160 <refundPubkeyHash> EQUALVERIFY
///        <refundLocktime> CHECKLOCKTIMEVERIFY DROP
///        CHECKSIG
///      ENDIF
///      ```
///
///      Since each depositor has their own Ethereum address and their own
///      blinding factor, each depositor’s script is unique, and the hash
///      of each depositor’s script is unique.
library Deposit {
    using BTCUtils for bytes;
    using BytesLib for bytes;

    /// @notice Represents data which must be revealed by the depositor during
    ///         deposit reveal.
    struct DepositRevealInfo {
        // Index of the funding output belonging to the funding transaction.
        uint32 fundingOutputIndex;
        // The blinding factor as 8 bytes. Byte endianness doesn't matter
        // as this factor is not interpreted as uint. The blinding factor allows
        // to distinguish deposits from the same depositor.
        bytes8 blindingFactor;
        // The compressed Bitcoin public key (33 bytes and 02 or 03 prefix)
        // of the deposit's wallet hashed in the HASH160 Bitcoin opcode style.
        bytes20 walletPubKeyHash;
        // The compressed Bitcoin public key (33 bytes and 02 or 03 prefix)
        // that can be used to make the deposit refund after the refund
        // locktime passes. Hashed in the HASH160 Bitcoin opcode style.
        bytes20 refundPubKeyHash;
        // The refund locktime (4-byte LE). Interpreted according to locktime
        // parsing rules described in:
        // https://developer.bitcoin.org/devguide/transactions.html#locktime-and-sequence-number
        // and used with OP_CHECKLOCKTIMEVERIFY opcode as described in:
        // https://github.com/bitcoin/bips/blob/master/bip-0065.mediawiki
        bytes4 refundLocktime;
        // Address of the Bank vault to which the deposit is routed to.
        // Optional, can be 0x0. The vault must be trusted by the Bridge.
        address vault;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's calldata argument.
    }

    /// @notice Represents tBTC deposit request data.
    struct DepositRequest {
        // Ethereum depositor address.
        address depositor;
        // Deposit amount in satoshi.
        uint64 amount;
        // UNIX timestamp the deposit was revealed at.
        // XXX: Unsigned 32-bit int unix seconds, will break February 7th 2106.
        uint32 revealedAt;
        // Address of the Bank vault the deposit is routed to.
        // Optional, can be 0x0.
        address vault;
        // Treasury TBTC fee in satoshi at the moment of deposit reveal.
        uint64 treasuryFee;
        // UNIX timestamp the deposit was swept at. Note this is not the
        // time when the deposit was swept on the Bitcoin chain but actually
        // the time when the sweep proof was delivered to the Ethereum chain.
        // XXX: Unsigned 32-bit int unix seconds, will break February 7th 2106.
        uint32 sweptAt;
        // This struct doesn't contain `__gap` property as the structure is stored
        // in a mapping, mappings store values in different slots and they are
        // not contiguous with other values.
    }

    event DepositRevealed(
        bytes32 fundingTxHash,
        uint32 fundingOutputIndex,
        address indexed depositor,
        uint64 amount,
        bytes8 blindingFactor,
        bytes20 indexed walletPubKeyHash,
        bytes20 refundPubKeyHash,
        bytes4 refundLocktime,
        address vault
    );

    /// @notice Used by the depositor to reveal information about their P2(W)SH
    ///         Bitcoin deposit to the Bridge on Ethereum chain. The off-chain
    ///         wallet listens for revealed deposit events and may decide to
    ///         include the revealed deposit in the next executed sweep.
    ///         Information about the Bitcoin deposit can be revealed before or
    ///         after the Bitcoin transaction with P2(W)SH deposit is mined on
    ///         the Bitcoin chain. Worth noting, the gas cost of this function
    ///         scales with the number of P2(W)SH transaction inputs and
    ///         outputs. The deposit may be routed to one of the trusted vaults.
    ///         When a deposit is routed to a vault, vault gets notified when
    ///         the deposit gets swept and it may execute the appropriate action.
    /// @param fundingTx Bitcoin funding transaction data, see `BitcoinTx.Info`.
    /// @param reveal Deposit reveal data, see `RevealInfo struct.
    /// @dev Requirements:
    ///      - This function must be called by the same Ethereum address as the
    ///        one used in the P2(W)SH BTC deposit transaction as a depositor,
    ///      - `reveal.walletPubKeyHash` must identify a `Live` wallet,
    ///      - `reveal.vault` must be 0x0 or point to a trusted vault,
    ///      - `reveal.fundingOutputIndex` must point to the actual P2(W)SH
    ///        output of the BTC deposit transaction,
    ///      - `reveal.blindingFactor` must be the blinding factor used in the
    ///        P2(W)SH BTC deposit transaction,
    ///      - `reveal.walletPubKeyHash` must be the wallet pub key hash used in
    ///        the P2(W)SH BTC deposit transaction,
    ///      - `reveal.refundPubKeyHash` must be the refund pub key hash used in
    ///        the P2(W)SH BTC deposit transaction,
    ///      - `reveal.refundLocktime` must be the refund locktime used in the
    ///        P2(W)SH BTC deposit transaction,
    ///      - BTC deposit for the given `fundingTxHash`, `fundingOutputIndex`
    ///        can be revealed only one time.
    ///
    ///      If any of these requirements is not met, the wallet _must_ refuse
    ///      to sweep the deposit and the depositor has to wait until the
    ///      deposit script unlocks to receive their BTC back.
    function revealDeposit(
        BridgeState.Storage storage self,
        BitcoinTx.Info calldata fundingTx,
        DepositRevealInfo calldata reveal
    ) external {
        require(
            self.registeredWallets[reveal.walletPubKeyHash].state ==
                Wallets.WalletState.Live,
            "Wallet must be in Live state"
        );

        require(
            reveal.vault == address(0) || self.isVaultTrusted[reveal.vault],
            "Vault is not trusted"
        );

        if (self.depositRevealAheadPeriod > 0) {
            validateDepositRefundLocktime(self, reveal.refundLocktime);
        }

        bytes memory expectedScript = abi.encodePacked(
            hex"14", // Byte length of depositor Ethereum address.
            msg.sender,
            hex"75", // OP_DROP
            hex"08", // Byte length of blinding factor value.
            reveal.blindingFactor,
            hex"75", // OP_DROP
            hex"76", // OP_DUP
            hex"a9", // OP_HASH160
            hex"14", // Byte length of a compressed Bitcoin public key hash.
            reveal.walletPubKeyHash,
            hex"87", // OP_EQUAL
            hex"63", // OP_IF
            hex"ac", // OP_CHECKSIG
            hex"67", // OP_ELSE
            hex"76", // OP_DUP
            hex"a9", // OP_HASH160
            hex"14", // Byte length of a compressed Bitcoin public key hash.
            reveal.refundPubKeyHash,
            hex"88", // OP_EQUALVERIFY
            hex"04", // Byte length of refund locktime value.
            reveal.refundLocktime,
            hex"b1", // OP_CHECKLOCKTIMEVERIFY
            hex"75", // OP_DROP
            hex"ac", // OP_CHECKSIG
            hex"68" // OP_ENDIF
        );

        bytes memory fundingOutput = fundingTx
            .outputVector
            .extractOutputAtIndex(reveal.fundingOutputIndex);
        bytes memory fundingOutputHash = fundingOutput.extractHash();

        if (fundingOutputHash.length == 20) {
            // A 20-byte output hash is used by P2SH. That hash is constructed
            // by applying OP_HASH160 on the locking script. A 20-byte output
            // hash is used as well by P2PKH and P2WPKH (OP_HASH160 on the
            // public key). However, since we compare the actual output hash
            // with an expected locking script hash, this check will succeed only
            // for P2SH transaction type with expected script hash value. For
            // P2PKH and P2WPKH, it will fail on the output hash comparison with
            // the expected locking script hash.
            require(
                fundingOutputHash.slice20(0) == expectedScript.hash160View(),
                "Wrong 20-byte script hash"
            );
        } else if (fundingOutputHash.length == 32) {
            // A 32-byte output hash is used by P2WSH. That hash is constructed
            // by applying OP_SHA256 on the locking script.
            require(
                fundingOutputHash.toBytes32() == sha256(expectedScript),
                "Wrong 32-byte script hash"
            );
        } else {
            revert("Wrong script hash length");
        }

        // Resulting TX hash is in native Bitcoin little-endian format.
        bytes32 fundingTxHash = abi
            .encodePacked(
                fundingTx.version,
                fundingTx.inputVector,
                fundingTx.outputVector,
                fundingTx.locktime
            )
            .hash256View();

        DepositRequest storage deposit = self.deposits[
            uint256(
                keccak256(
                    abi.encodePacked(fundingTxHash, reveal.fundingOutputIndex)
                )
            )
        ];
        require(deposit.revealedAt == 0, "Deposit already revealed");

        uint64 fundingOutputAmount = fundingOutput.extractValue();

        require(
            fundingOutputAmount >= self.depositDustThreshold,
            "Deposit amount too small"
        );

        deposit.amount = fundingOutputAmount;
        deposit.depositor = msg.sender;
        /* solhint-disable-next-line not-rely-on-time */
        deposit.revealedAt = uint32(block.timestamp);
        deposit.vault = reveal.vault;
        deposit.treasuryFee = self.depositTreasuryFeeDivisor > 0
            ? fundingOutputAmount / self.depositTreasuryFeeDivisor
            : 0;
        // slither-disable-next-line reentrancy-events
        emit DepositRevealed(
            fundingTxHash,
            reveal.fundingOutputIndex,
            msg.sender,
            fundingOutputAmount,
            reveal.blindingFactor,
            reveal.walletPubKeyHash,
            reveal.refundPubKeyHash,
            reveal.refundLocktime,
            reveal.vault
        );
    }

    /// @notice Validates the deposit refund locktime. The validation passes
    ///         successfully only if the deposit reveal is done respectively
    ///         earlier than the moment when the deposit refund locktime is
    ///         reached, i.e. the deposit become refundable. Reverts otherwise.
    /// @param refundLocktime The deposit refund locktime as 4-byte LE.
    /// @dev Requirements:
    ///      - `refundLocktime` as integer must be >= 500M
    ///      - `refundLocktime` must denote a timestamp that is at least
    ///        `depositRevealAheadPeriod` seconds later than the moment
    ///        of `block.timestamp`
    function validateDepositRefundLocktime(
        BridgeState.Storage storage self,
        bytes4 refundLocktime
    ) internal view {
        // Convert the refund locktime byte array to a LE integer. This is
        // the moment in time when the deposit become refundable.
        uint32 depositRefundableTimestamp = BTCUtils.reverseUint32(
            uint32(refundLocktime)
        );
        // According to https://developer.bitcoin.org/devguide/transactions.html#locktime-and-sequence-number
        // the locktime is parsed as a block number if less than 500M. We always
        // want to parse the locktime as an Unix timestamp so we allow only for
        // values bigger than or equal to 500M.
        require(
            depositRefundableTimestamp >= 500 * 1e6,
            "Refund locktime must be a value >= 500M"
        );
        // The deposit must be revealed before it becomes refundable.
        // This is because the sweeping wallet needs to have some time to
        // sweep the deposit and avoid a potential competition with the
        // depositor making the deposit refund.
        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp + self.depositRevealAheadPeriod <=
                depositRefundableTimestamp,
            "Deposit refund locktime is too close"
        );
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

import {BTCUtils} from "@keep-network/bitcoin-spv-sol/contracts/BTCUtils.sol";

import "./BitcoinTx.sol";
import "./BridgeState.sol";
import "./Wallets.sol";

import "../bank/Bank.sol";

/// @title Bridge deposit sweep
/// @notice The library handles the logic for sweeping transactions revealed to
///         the Bridge
/// @dev Bridge active wallet periodically signs a transaction that unlocks all
///      of the valid, revealed deposits above the dust threshold, combines them
///      into a single UTXO with the existing main wallet UTXO, and relocks
///      those transactions without a 30-day refund clause to the same wallet.
///      This has two main effects: it consolidates the UTXO set and it disables
///      the refund. Balances of depositors in the Bank are increased when the
///      SPV sweep proof is submitted to the Bridge.
library DepositSweep {
    using BridgeState for BridgeState.Storage;
    using BitcoinTx for BridgeState.Storage;

    using BTCUtils for bytes;

    /// @notice Represents temporary information needed during the processing
    ///         of the deposit sweep Bitcoin transaction inputs. This structure
    ///         is an internal one and should not be exported outside of the
    ///         deposit sweep transaction processing code.
    /// @dev Allows to mitigate "stack too deep" errors on EVM.
    struct DepositSweepTxInputsProcessingInfo {
        // Input vector of the deposit sweep Bitcoin transaction. It is
        // assumed the vector's structure is valid so it must be validated
        // using e.g. `BTCUtils.validateVin` function before being used
        // during the processing. The validation is usually done as part
        // of the `BitcoinTx.validateProof` call that checks the SPV proof.
        bytes sweepTxInputVector;
        // Data of the wallet's main UTXO. If no main UTXO exists for the given
        // sweeping wallet, this parameter's fields should be zeroed to bypass
        // the main UTXO validation
        BitcoinTx.UTXO mainUtxo;
        // Address of the vault where all swept deposits should be routed to.
        // It is used to validate whether all swept deposits have been revealed
        // with the same `vault` parameter. It is an optional parameter.
        // Set to zero address if deposits are not routed to a vault.
        address vault;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's memory argument.
    }

    /// @notice Represents an outcome of the sweep Bitcoin transaction
    ///         inputs processing.
    struct DepositSweepTxInputsInfo {
        // Sum of all inputs values i.e. all deposits and main UTXO value,
        // if present.
        uint256 inputsTotalValue;
        // Addresses of depositors who performed processed deposits. Ordered in
        // the same order as deposits inputs in the input vector. Size of this
        // array is either equal to the number of inputs (main UTXO doesn't
        // exist) or less by one (main UTXO exists and is pointed by one of
        // the inputs).
        address[] depositors;
        // Amounts of deposits corresponding to processed deposits. Ordered in
        // the same order as deposits inputs in the input vector. Size of this
        // array is either equal to the number of inputs (main UTXO doesn't
        // exist) or less by one (main UTXO exists and is pointed by one of
        // the inputs).
        uint256[] depositedAmounts;
        // Values of the treasury fee corresponding to processed deposits.
        // Ordered in the same order as deposits inputs in the input vector.
        // Size of this array is either equal to the number of inputs (main
        // UTXO doesn't exist) or less by one (main UTXO exists and is pointed
        // by one of the inputs).
        uint256[] treasuryFees;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's memory argument.
    }

    event DepositsSwept(bytes20 walletPubKeyHash, bytes32 sweepTxHash);

    /// @notice Used by the wallet to prove the BTC deposit sweep transaction
    ///         and to update Bank balances accordingly. Sweep is only accepted
    ///         if it satisfies SPV proof.
    ///
    ///         The function is performing Bank balance updates by first
    ///         computing the Bitcoin fee for the sweep transaction. The fee is
    ///         divided evenly between all swept deposits. Each depositor
    ///         receives a balance in the bank equal to the amount inferred
    ///         during the reveal transaction, minus their fee share.
    ///
    ///         It is possible to prove the given sweep only one time.
    /// @param sweepTx Bitcoin sweep transaction data.
    /// @param sweepProof Bitcoin sweep proof data.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain. If no main UTXO exists for the given wallet,
    ///        this parameter is ignored.
    /// @param vault Optional address of the vault where all swept deposits
    ///        should be routed to. All deposits swept as part of the transaction
    ///        must have their `vault` parameters set to the same address.
    ///        If this parameter is set to an address of a trusted vault, swept
    ///        deposits are routed to that vault.
    ///        If this parameter is set to the zero address or to an address
    ///        of a non-trusted vault, swept deposits are not routed to a
    ///        vault but depositors' balances are increased in the Bank
    ///        individually.
    /// @dev Requirements:
    ///      - `sweepTx` components must match the expected structure. See
    ///        `BitcoinTx.Info` docs for reference. Their values must exactly
    ///        correspond to appropriate Bitcoin transaction fields to produce
    ///        a provable transaction hash,
    ///      - The `sweepTx` should represent a Bitcoin transaction with 1..n
    ///        inputs. If the wallet has no main UTXO, all n inputs should
    ///        correspond to P2(W)SH revealed deposits UTXOs. If the wallet has
    ///        an existing main UTXO, one of the n inputs must point to that
    ///        main UTXO and remaining n-1 inputs should correspond to P2(W)SH
    ///        revealed deposits UTXOs. That transaction must have only
    ///        one P2(W)PKH output locking funds on the 20-byte wallet public
    ///        key hash,
    ///      - All revealed deposits that are swept by `sweepTx` must have
    ///        their `vault` parameters set to the same address as the address
    ///        passed in the `vault` function parameter,
    ///      - `sweepProof` components must match the expected structure. See
    ///        `BitcoinTx.Proof` docs for reference. The `bitcoinHeaders`
    ///        field must contain a valid number of block headers, not less
    ///        than the `txProofDifficultyFactor` contract constant,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        If there is no main UTXO, this parameter is ignored.
    function submitDepositSweepProof(
        BridgeState.Storage storage self,
        BitcoinTx.Info calldata sweepTx,
        BitcoinTx.Proof calldata sweepProof,
        BitcoinTx.UTXO calldata mainUtxo,
        address vault
    ) external {
        // Wallet state validation is performed in the
        // `resolveDepositSweepingWallet` function.

        // The actual transaction proof is performed here. After that point, we
        // can assume the transaction happened on Bitcoin chain and has
        // a sufficient number of confirmations as determined by
        // `txProofDifficultyFactor` constant.
        bytes32 sweepTxHash = self.validateProof(sweepTx, sweepProof);

        // Process sweep transaction output and extract its target wallet
        // public key hash and value.
        (
            bytes20 walletPubKeyHash,
            uint64 sweepTxOutputValue
        ) = processDepositSweepTxOutput(self, sweepTx.outputVector);

        (
            Wallets.Wallet storage wallet,
            BitcoinTx.UTXO memory resolvedMainUtxo
        ) = resolveDepositSweepingWallet(self, walletPubKeyHash, mainUtxo);

        // Process sweep transaction inputs and extract all information needed
        // to perform deposit bookkeeping.
        DepositSweepTxInputsInfo
            memory inputsInfo = processDepositSweepTxInputs(
                self,
                DepositSweepTxInputsProcessingInfo(
                    sweepTx.inputVector,
                    resolvedMainUtxo,
                    vault
                )
            );

        // Helper variable that will hold the sum of treasury fees paid by
        // all deposits.
        uint256 totalTreasuryFee = 0;

        // Determine the transaction fee that should be incurred by each deposit
        // and the indivisible remainder that should be additionally incurred
        // by the last deposit.
        (
            uint256 depositTxFee,
            uint256 depositTxFeeRemainder
        ) = depositSweepTxFeeDistribution(
                inputsInfo.inputsTotalValue,
                sweepTxOutputValue,
                inputsInfo.depositedAmounts.length
            );

        // Make sure the highest value of the deposit transaction fee does not
        // exceed the maximum value limited by the governable parameter.
        require(
            depositTxFee + depositTxFeeRemainder <= self.depositTxMaxFee,
            "Transaction fee is too high"
        );

        // Reduce each deposit amount by treasury fee and transaction fee.
        for (uint256 i = 0; i < inputsInfo.depositedAmounts.length; i++) {
            // The last deposit should incur the deposit transaction fee
            // remainder.
            uint256 depositTxFeeIncurred = i ==
                inputsInfo.depositedAmounts.length - 1
                ? depositTxFee + depositTxFeeRemainder
                : depositTxFee;

            // There is no need to check whether
            // `inputsInfo.depositedAmounts[i] - inputsInfo.treasuryFees[i] - txFee > 0`
            // since the `depositDustThreshold` should force that condition
            // to be always true.
            inputsInfo.depositedAmounts[i] =
                inputsInfo.depositedAmounts[i] -
                inputsInfo.treasuryFees[i] -
                depositTxFeeIncurred;
            totalTreasuryFee += inputsInfo.treasuryFees[i];
        }

        // Record this sweep data and assign them to the wallet public key hash
        // as new main UTXO. Transaction output index is always 0 as sweep
        // transaction always contains only one output.
        wallet.mainUtxoHash = keccak256(
            abi.encodePacked(sweepTxHash, uint32(0), sweepTxOutputValue)
        );

        // slither-disable-next-line reentrancy-events
        emit DepositsSwept(walletPubKeyHash, sweepTxHash);

        if (vault != address(0) && self.isVaultTrusted[vault]) {
            // If the `vault` address is not zero and belongs to a trusted
            // vault, route the deposits to that vault.
            self.bank.increaseBalanceAndCall(
                vault,
                inputsInfo.depositors,
                inputsInfo.depositedAmounts
            );
        } else {
            // If the `vault` address is zero or belongs to a non-trusted
            // vault, increase balances in the Bank individually for each
            // depositor.
            self.bank.increaseBalances(
                inputsInfo.depositors,
                inputsInfo.depositedAmounts
            );
        }

        // Pass the treasury fee to the treasury address.
        if (totalTreasuryFee > 0) {
            self.bank.increaseBalance(self.treasury, totalTreasuryFee);
        }
    }

    /// @notice Resolves sweeping wallet based on the provided wallet public key
    ///         hash. Validates the wallet state and current main UTXO, as
    ///         currently known on the Ethereum chain.
    /// @param walletPubKeyHash public key hash of the wallet proving the sweep
    ///        Bitcoin transaction.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain. If no main UTXO exists for the given wallet,
    ///        this parameter is ignored.
    /// @return wallet Data of the sweeping wallet.
    /// @return resolvedMainUtxo The actual main UTXO of the sweeping wallet
    ///         resolved by cross-checking the `mainUtxo` parameter with
    ///         the chain state. If the validation went well, this is the
    ///         plain-text main UTXO corresponding to the `wallet.mainUtxoHash`.
    /// @dev Requirements:
    ///     - Sweeping wallet must be either in Live or MovingFunds state,
    ///     - If the main UTXO of the sweeping wallet exists in the storage,
    ///       the passed `mainUTXO` parameter must be equal to the stored one.
    function resolveDepositSweepingWallet(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata mainUtxo
    )
        internal
        view
        returns (
            Wallets.Wallet storage wallet,
            BitcoinTx.UTXO memory resolvedMainUtxo
        )
    {
        wallet = self.registeredWallets[walletPubKeyHash];

        Wallets.WalletState walletState = wallet.state;
        require(
            walletState == Wallets.WalletState.Live ||
                walletState == Wallets.WalletState.MovingFunds,
            "Wallet must be in Live or MovingFunds state"
        );

        // Check if the main UTXO for given wallet exists. If so, validate
        // passed main UTXO data against the stored hash and use them for
        // further processing. If no main UTXO exists, use empty data.
        resolvedMainUtxo = BitcoinTx.UTXO(bytes32(0), 0, 0);
        bytes32 mainUtxoHash = wallet.mainUtxoHash;
        if (mainUtxoHash != bytes32(0)) {
            require(
                keccak256(
                    abi.encodePacked(
                        mainUtxo.txHash,
                        mainUtxo.txOutputIndex,
                        mainUtxo.txOutputValue
                    )
                ) == mainUtxoHash,
                "Invalid main UTXO data"
            );
            resolvedMainUtxo = mainUtxo;
        }
    }

    /// @notice Processes the Bitcoin sweep transaction output vector by
    ///         extracting the single output and using it to gain additional
    ///         information required for further processing (e.g. value and
    ///         wallet public key hash).
    /// @param sweepTxOutputVector Bitcoin sweep transaction output vector.
    ///        This function assumes vector's structure is valid so it must be
    ///        validated using e.g. `BTCUtils.validateVout` function before
    ///        it is passed here.
    /// @return walletPubKeyHash 20-byte wallet public key hash.
    /// @return value 8-byte sweep transaction output value.
    function processDepositSweepTxOutput(
        BridgeState.Storage storage self,
        bytes memory sweepTxOutputVector
    ) internal view returns (bytes20 walletPubKeyHash, uint64 value) {
        // To determine the total number of sweep transaction outputs, we need to
        // parse the compactSize uint (VarInt) the output vector is prepended by.
        // That compactSize uint encodes the number of vector elements using the
        // format presented in:
        // https://developer.bitcoin.org/reference/transactions.html#compactsize-unsigned-integers
        // We don't need asserting the compactSize uint is parseable since it
        // was already checked during `validateVout` validation.
        // See `BitcoinTx.outputVector` docs for more details.
        (, uint256 outputsCount) = sweepTxOutputVector.parseVarInt();
        require(
            outputsCount == 1,
            "Sweep transaction must have a single output"
        );

        bytes memory output = sweepTxOutputVector.extractOutputAtIndex(0);
        walletPubKeyHash = self.extractPubKeyHash(output);
        value = output.extractValue();

        return (walletPubKeyHash, value);
    }

    /// @notice Processes the Bitcoin sweep transaction input vector. It
    ///         extracts each input and tries to obtain associated deposit or
    ///         main UTXO data, depending on the input type. Reverts
    ///         if one of the inputs cannot be recognized as a pointer to a
    ///         revealed deposit or expected main UTXO.
    ///         This function also marks each processed deposit as swept.
    /// @return resultInfo Outcomes of the processing.
    function processDepositSweepTxInputs(
        BridgeState.Storage storage self,
        DepositSweepTxInputsProcessingInfo memory processInfo
    ) internal returns (DepositSweepTxInputsInfo memory resultInfo) {
        // If the passed `mainUtxo` parameter's values are zeroed, the main UTXO
        // for the given wallet doesn't exist and it is not expected to be
        // included in the sweep transaction input vector.
        bool mainUtxoExpected = processInfo.mainUtxo.txHash != bytes32(0);
        bool mainUtxoFound = false;

        // Determining the total number of sweep transaction inputs in the same
        // way as for number of outputs. See `BitcoinTx.inputVector` docs for
        // more details.
        (uint256 inputsCompactSizeUintLength, uint256 inputsCount) = processInfo
            .sweepTxInputVector
            .parseVarInt();

        // To determine the first input starting index, we must jump over
        // the compactSize uint which prepends the input vector. One byte
        // must be added because `BtcUtils.parseVarInt` does not include
        // compactSize uint tag in the returned length.
        //
        // For >= 0 && <= 252, `BTCUtils.determineVarIntDataLengthAt`
        // returns `0`, so we jump over one byte of compactSize uint.
        //
        // For >= 253 && <= 0xffff there is `0xfd` tag,
        // `BTCUtils.determineVarIntDataLengthAt` returns `2` (no
        // tag byte included) so we need to jump over 1+2 bytes of
        // compactSize uint.
        //
        // Please refer `BTCUtils` library and compactSize uint
        // docs in `BitcoinTx` library for more details.
        uint256 inputStartingIndex = 1 + inputsCompactSizeUintLength;

        // Determine the swept deposits count. If main UTXO is NOT expected,
        // all inputs should be deposits. If main UTXO is expected, one input
        // should point to that main UTXO.
        resultInfo.depositors = new address[](
            !mainUtxoExpected ? inputsCount : inputsCount - 1
        );
        resultInfo.depositedAmounts = new uint256[](
            resultInfo.depositors.length
        );
        resultInfo.treasuryFees = new uint256[](resultInfo.depositors.length);

        // Initialize helper variables.
        uint256 processedDepositsCount = 0;

        // Inputs processing loop.
        for (uint256 i = 0; i < inputsCount; i++) {
            (
                bytes32 outpointTxHash,
                uint32 outpointIndex,
                uint256 inputLength
            ) = parseDepositSweepTxInputAt(
                    processInfo.sweepTxInputVector,
                    inputStartingIndex
                );

            Deposit.DepositRequest storage deposit = self.deposits[
                uint256(
                    keccak256(abi.encodePacked(outpointTxHash, outpointIndex))
                )
            ];

            if (deposit.revealedAt != 0) {
                // If we entered here, that means the input was identified as
                // a revealed deposit.
                require(deposit.sweptAt == 0, "Deposit already swept");

                require(
                    deposit.vault == processInfo.vault,
                    "Deposit should be routed to another vault"
                );

                if (processedDepositsCount == resultInfo.depositors.length) {
                    // If this condition is true, that means a deposit input
                    // took place of an expected main UTXO input.
                    // In other words, there is no expected main UTXO
                    // input and all inputs come from valid, revealed deposits.
                    revert(
                        "Expected main UTXO not present in sweep transaction inputs"
                    );
                }

                /* solhint-disable-next-line not-rely-on-time */
                deposit.sweptAt = uint32(block.timestamp);

                resultInfo.depositors[processedDepositsCount] = deposit
                    .depositor;
                resultInfo.depositedAmounts[processedDepositsCount] = deposit
                    .amount;
                resultInfo.inputsTotalValue += resultInfo.depositedAmounts[
                    processedDepositsCount
                ];
                resultInfo.treasuryFees[processedDepositsCount] = deposit
                    .treasuryFee;

                processedDepositsCount++;
            } else if (
                mainUtxoExpected != mainUtxoFound &&
                processInfo.mainUtxo.txHash == outpointTxHash &&
                processInfo.mainUtxo.txOutputIndex == outpointIndex
            ) {
                // If we entered here, that means the input was identified as
                // the expected main UTXO.
                resultInfo.inputsTotalValue += processInfo
                    .mainUtxo
                    .txOutputValue;
                mainUtxoFound = true;

                // Main UTXO used as an input, mark it as spent.
                self.spentMainUTXOs[
                    uint256(
                        keccak256(
                            abi.encodePacked(outpointTxHash, outpointIndex)
                        )
                    )
                ] = true;
            } else {
                revert("Unknown input type");
            }

            // Make the `inputStartingIndex` pointing to the next input by
            // increasing it by current input's length.
            inputStartingIndex += inputLength;
        }

        // Construction of the input processing loop guarantees that:
        // `processedDepositsCount == resultInfo.depositors.length == resultInfo.depositedAmounts.length`
        // is always true at this point. We just use the first variable
        // to assert the total count of swept deposit is bigger than zero.
        require(
            processedDepositsCount > 0,
            "Sweep transaction must process at least one deposit"
        );

        // Assert the main UTXO was used as one of current sweep's inputs if
        // it was actually expected.
        require(
            mainUtxoExpected == mainUtxoFound,
            "Expected main UTXO not present in sweep transaction inputs"
        );

        return resultInfo;
    }

    /// @notice Parses a Bitcoin transaction input starting at the given index.
    /// @param inputVector Bitcoin transaction input vector.
    /// @param inputStartingIndex Index the given input starts at.
    /// @return outpointTxHash 32-byte hash of the Bitcoin transaction which is
    ///         pointed in the given input's outpoint.
    /// @return outpointIndex 4-byte index of the Bitcoin transaction output
    ///         which is pointed in the given input's outpoint.
    /// @return inputLength Byte length of the given input.
    /// @dev This function assumes vector's structure is valid so it must be
    ///      validated using e.g. `BTCUtils.validateVin` function before it
    ///      is passed here.
    function parseDepositSweepTxInputAt(
        bytes memory inputVector,
        uint256 inputStartingIndex
    )
        internal
        pure
        returns (
            bytes32 outpointTxHash,
            uint32 outpointIndex,
            uint256 inputLength
        )
    {
        outpointTxHash = inputVector.extractInputTxIdLeAt(inputStartingIndex);

        outpointIndex = BTCUtils.reverseUint32(
            uint32(inputVector.extractTxIndexLeAt(inputStartingIndex))
        );

        inputLength = inputVector.determineInputLengthAt(inputStartingIndex);

        return (outpointTxHash, outpointIndex, inputLength);
    }

    /// @notice Determines the distribution of the sweep transaction fee
    ///         over swept deposits.
    /// @param sweepTxInputsTotalValue Total value of all sweep transaction inputs.
    /// @param sweepTxOutputValue Value of the sweep transaction output.
    /// @param depositsCount Count of the deposits swept by the sweep transaction.
    /// @return depositTxFee Transaction fee per deposit determined by evenly
    ///         spreading the divisible part of the sweep transaction fee
    ///         over all deposits.
    /// @return depositTxFeeRemainder The indivisible part of the sweep
    ///         transaction fee than cannot be distributed over all deposits.
    /// @dev It is up to the caller to decide how the remainder should be
    ///      counted in. This function only computes its value.
    function depositSweepTxFeeDistribution(
        uint256 sweepTxInputsTotalValue,
        uint256 sweepTxOutputValue,
        uint256 depositsCount
    )
        internal
        pure
        returns (uint256 depositTxFee, uint256 depositTxFeeRemainder)
    {
        // The sweep transaction fee is just the difference between inputs
        // amounts sum and the output amount.
        uint256 sweepTxFee = sweepTxInputsTotalValue - sweepTxOutputValue;
        // Compute the indivisible remainder that remains after dividing the
        // sweep transaction fee over all deposits evenly.
        depositTxFeeRemainder = sweepTxFee % depositsCount;
        // Compute the transaction fee per deposit by dividing the sweep
        // transaction fee (reduced by the remainder) by the number of deposits.
        depositTxFee = (sweepTxFee - depositTxFeeRemainder) / depositsCount;

        return (depositTxFee, depositTxFeeRemainder);
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

import "@keep-network/bitcoin-spv-sol/contracts/BytesLib.sol";

library EcdsaLib {
    using BytesLib for bytes;

    /// @notice Converts public key X and Y coordinates (32-byte each) to a
    ///         compressed public key (33-byte). Compressed public key is X
    ///         coordinate prefixed with `02` or `03` based on the Y coordinate parity.
    ///         It is expected that the uncompressed public key is stripped
    ///         (i.e. it is not prefixed with `04`).
    /// @param x Wallet's public key's X coordinate.
    /// @param y Wallet's public key's Y coordinate.
    /// @return Compressed public key (33-byte), prefixed with `02` or `03`.
    function compressPublicKey(bytes32 x, bytes32 y)
        internal
        pure
        returns (bytes memory)
    {
        bytes1 prefix;
        if (uint256(y) % 2 == 0) {
            prefix = hex"02";
        } else {
            prefix = hex"03";
        }

        return bytes.concat(prefix, x);
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

import {BytesLib} from "@keep-network/bitcoin-spv-sol/contracts/BytesLib.sol";
import {BTCUtils} from "@keep-network/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {CheckBitcoinSigs} from "@keep-network/bitcoin-spv-sol/contracts/CheckBitcoinSigs.sol";

import "./BitcoinTx.sol";
import "./EcdsaLib.sol";
import "./BridgeState.sol";
import "./Heartbeat.sol";
import "./MovingFunds.sol";
import "./Wallets.sol";

/// @title Bridge fraud
/// @notice The library handles the logic for challenging Bridge wallets that
///         committed fraud.
/// @dev Anyone can submit a fraud challenge indicating that a UTXO being under
///      the wallet control was unlocked by the wallet but was not used
///      according to the protocol rules. That means the wallet signed
///      a transaction input pointing to that UTXO and there is a unique
///      sighash and signature pair associated with that input.
///
///      In order to defeat the challenge, the same wallet public key and
///      signature must be provided as were used to calculate the sighash during
///      the challenge. The wallet provides the preimage which produces sighash
///      used to generate the ECDSA signature that is the subject of the fraud
///      claim.
///
///      The fraud challenge defeat attempt will succeed if the inputs in the
///      preimage are considered honestly spent by the wallet. Therefore the
///      transaction spending the UTXO must be proven in the Bridge before
///      a challenge defeat is called.
///
///      Another option is when a malicious wallet member used a signed heartbeat
///      message periodically produced by the wallet off-chain to challenge the
///      wallet for a fraud. Anyone from the wallet can defeat the challenge by
///      proving the sighash and signature were produced for a heartbeat message
///      following a strict format.
library Fraud {
    using Wallets for BridgeState.Storage;

    using BytesLib for bytes;
    using BTCUtils for bytes;
    using BTCUtils for uint32;
    using EcdsaLib for bytes;

    struct FraudChallenge {
        // The address of the party challenging the wallet.
        address challenger;
        // The amount of ETH the challenger deposited.
        uint256 depositAmount;
        // The timestamp the challenge was submitted at.
        // XXX: Unsigned 32-bit int unix seconds, will break February 7th 2106.
        uint32 reportedAt;
        // The flag indicating whether the challenge has been resolved.
        bool resolved;
        // This struct doesn't contain `__gap` property as the structure is stored
        // in a mapping, mappings store values in different slots and they are
        // not contiguous with other values.
    }

    event FraudChallengeSubmitted(
        bytes20 indexed walletPubKeyHash,
        bytes32 sighash,
        uint8 v,
        bytes32 r,
        bytes32 s
    );

    event FraudChallengeDefeated(
        bytes20 indexed walletPubKeyHash,
        bytes32 sighash
    );

    event FraudChallengeDefeatTimedOut(
        bytes20 indexed walletPubKeyHash,
        // Sighash calculated as a Bitcoin's hash256 (double sha2) of:
        // - a preimage of a transaction spending UTXO according to the protocol
        //   rules OR
        // - a valid heartbeat message produced by the wallet off-chain.
        bytes32 sighash
    );

    /// @notice Submits a fraud challenge indicating that a UTXO being under
    ///         wallet control was unlocked by the wallet but was not used
    ///         according to the protocol rules. That means the wallet signed
    ///         a transaction input pointing to that UTXO and there is a unique
    ///         sighash and signature pair associated with that input. This
    ///         function uses those parameters to create a fraud accusation that
    ///         proves a given transaction input unlocking the given UTXO was
    ///         actually signed by the wallet. This function cannot determine
    ///         whether the transaction was actually broadcast and the input was
    ///         consumed in a fraudulent way so it just opens a challenge period
    ///         during which the wallet can defeat the challenge by submitting
    ///         proof of a transaction that consumes the given input according
    ///         to protocol rules. To prevent spurious allegations, the caller
    ///         must deposit ETH that is returned back upon justified fraud
    ///         challenge or confiscated otherwise.
    /// @param walletPublicKey The public key of the wallet in the uncompressed
    ///        and unprefixed format (64 bytes).
    /// @param preimageSha256 The hash that was generated by applying SHA-256
    ///        one time over the preimage used during input signing. The preimage
    ///        is a serialized subset of the transaction and its structure
    ///        depends on the transaction input (see BIP-143 for reference).
    ///        Notice that applying SHA-256 over the `preimageSha256` results
    ///        in `sighash`.  The path from `preimage` to `sighash` looks like
    ///        this:
    ///        preimage -> (SHA-256) -> preimageSha256 -> (SHA-256) -> sighash.
    /// @param signature Bitcoin signature in the R/S/V format
    /// @dev Requirements:
    ///      - Wallet behind `walletPublicKey` must be in Live or MovingFunds
    ///        or Closing state,
    ///      - The challenger must send appropriate amount of ETH used as
    ///        fraud challenge deposit,
    ///      - The signature (represented by r, s and v) must be generated by
    ///        the wallet behind `walletPubKey` during signing of `sighash`
    ///        which was calculated from `preimageSha256`,
    ///      - Wallet can be challenged for the given signature only once.
    function submitFraudChallenge(
        BridgeState.Storage storage self,
        bytes calldata walletPublicKey,
        bytes memory preimageSha256,
        BitcoinTx.RSVSignature calldata signature
    ) external {
        require(
            msg.value >= self.fraudChallengeDepositAmount,
            "The amount of ETH deposited is too low"
        );

        // To prevent ECDSA signature forgery `sighash` must be calculated
        // inside the function and not passed as a function parameter.
        // Signature forgery could result in a wrongful fraud accusation
        // against a wallet.
        bytes32 sighash = sha256(preimageSha256);

        require(
            CheckBitcoinSigs.checkSig(
                walletPublicKey,
                sighash,
                signature.v,
                signature.r,
                signature.s
            ),
            "Signature verification failure"
        );

        bytes memory compressedWalletPublicKey = EcdsaLib.compressPublicKey(
            walletPublicKey.slice32(0),
            walletPublicKey.slice32(32)
        );
        bytes20 walletPubKeyHash = compressedWalletPublicKey.hash160View();

        Wallets.Wallet storage wallet = self.registeredWallets[
            walletPubKeyHash
        ];

        require(
            wallet.state == Wallets.WalletState.Live ||
                wallet.state == Wallets.WalletState.MovingFunds ||
                wallet.state == Wallets.WalletState.Closing,
            "Wallet must be in Live or MovingFunds or Closing state"
        );

        uint256 challengeKey = uint256(
            keccak256(abi.encodePacked(walletPublicKey, sighash))
        );

        FraudChallenge storage challenge = self.fraudChallenges[challengeKey];
        require(challenge.reportedAt == 0, "Fraud challenge already exists");

        challenge.challenger = msg.sender;
        challenge.depositAmount = msg.value;
        /* solhint-disable-next-line not-rely-on-time */
        challenge.reportedAt = uint32(block.timestamp);
        challenge.resolved = false;
        // slither-disable-next-line reentrancy-events
        emit FraudChallengeSubmitted(
            walletPubKeyHash,
            sighash,
            signature.v,
            signature.r,
            signature.s
        );
    }

    /// @notice Allows to defeat a pending fraud challenge against a wallet if
    ///         the transaction that spends the UTXO follows the protocol rules.
    ///         In order to defeat the challenge the same `walletPublicKey` and
    ///         signature (represented by `r`, `s` and `v`) must be provided as
    ///         were used to calculate the sighash during input signing.
    ///         The fraud challenge defeat attempt will only succeed if the
    ///         inputs in the preimage are considered honestly spent by the
    ///         wallet. Therefore the transaction spending the UTXO must be
    ///         proven in the Bridge before a challenge defeat is called.
    ///         If successfully defeated, the fraud challenge is marked as
    ///         resolved and the amount of ether deposited by the challenger is
    ///         sent to the treasury.
    /// @param walletPublicKey The public key of the wallet in the uncompressed
    ///        and unprefixed format (64 bytes).
    /// @param preimage The preimage which produces sighash used to generate the
    ///        ECDSA signature that is the subject of the fraud claim. It is a
    ///        serialized subset of the transaction. The exact subset used as
    ///        the preimage depends on the transaction input the signature is
    ///        produced for. See BIP-143 for reference.
    /// @param witness Flag indicating whether the preimage was produced for a
    ///        witness input. True for witness, false for non-witness input.
    /// @dev Requirements:
    ///      - `walletPublicKey` and `sighash` calculated as `hash256(preimage)`
    ///        must identify an open fraud challenge,
    ///      - the preimage must be a valid preimage of a transaction generated
    ///        according to the protocol rules and already proved in the Bridge,
    ///      - before a defeat attempt is made the transaction that spends the
    ///        given UTXO must be proven in the Bridge.
    function defeatFraudChallenge(
        BridgeState.Storage storage self,
        bytes calldata walletPublicKey,
        bytes calldata preimage,
        bool witness
    ) external {
        bytes32 sighash = preimage.hash256();

        uint256 challengeKey = uint256(
            keccak256(abi.encodePacked(walletPublicKey, sighash))
        );

        FraudChallenge storage challenge = self.fraudChallenges[challengeKey];

        require(challenge.reportedAt > 0, "Fraud challenge does not exist");
        require(
            !challenge.resolved,
            "Fraud challenge has already been resolved"
        );

        // Ensure SIGHASH_ALL type was used during signing, which is represented
        // by type value `1`.
        require(extractSighashType(preimage) == 1, "Wrong sighash type");

        uint256 utxoKey = witness
            ? extractUtxoKeyFromWitnessPreimage(preimage)
            : extractUtxoKeyFromNonWitnessPreimage(preimage);

        // Check that the UTXO key identifies a correctly spent UTXO.
        require(
            self.deposits[utxoKey].sweptAt > 0 ||
                self.spentMainUTXOs[utxoKey] ||
                self.movedFundsSweepRequests[utxoKey].state ==
                MovingFunds.MovedFundsSweepRequestState.Processed,
            "Spent UTXO not found among correctly spent UTXOs"
        );

        resolveFraudChallenge(self, walletPublicKey, challenge, sighash);
    }

    /// @notice Allows to defeat a pending fraud challenge against a wallet by
    ///         proving the sighash and signature were produced for an off-chain
    ///         wallet heartbeat message following a strict format.
    ///         In order to defeat the challenge the same `walletPublicKey` and
    ///         signature (represented by `r`, `s` and `v`) must be provided as
    ///         were used to calculate the sighash during heartbeat message
    ///         signing. The fraud challenge defeat attempt will only succeed if
    ///         the signed message follows a strict format required for
    ///         heartbeat messages. If successfully defeated, the fraud
    ///         challenge is marked as resolved and the amount of ether
    ///         deposited by the challenger is sent to the treasury.
    /// @param walletPublicKey The public key of the wallet in the uncompressed
    ///        and unprefixed format (64 bytes),
    /// @param heartbeatMessage Off-chain heartbeat message meeting the heartbeat
    ///        message format requirements which produces sighash used to
    ///        generate the ECDSA signature that is the subject of the fraud
    ///        claim.
    /// @dev Requirements:
    ///      - `walletPublicKey` and `sighash` calculated as
    ///        `hash256(heartbeatMessage)` must identify an open fraud challenge,
    ///      - `heartbeatMessage` must follow a strict format of heartbeat
    ///        messages.
    function defeatFraudChallengeWithHeartbeat(
        BridgeState.Storage storage self,
        bytes calldata walletPublicKey,
        bytes calldata heartbeatMessage
    ) external {
        bytes32 sighash = heartbeatMessage.hash256();

        uint256 challengeKey = uint256(
            keccak256(abi.encodePacked(walletPublicKey, sighash))
        );

        FraudChallenge storage challenge = self.fraudChallenges[challengeKey];

        require(challenge.reportedAt > 0, "Fraud challenge does not exist");
        require(
            !challenge.resolved,
            "Fraud challenge has already been resolved"
        );

        require(
            Heartbeat.isValidHeartbeatMessage(heartbeatMessage),
            "Not a valid heartbeat message"
        );

        resolveFraudChallenge(self, walletPublicKey, challenge, sighash);
    }

    /// @notice Called only for successfully defeated fraud challenges.
    ///         The fraud challenge is marked as resolved and the amount of
    ///         ether deposited by the challenger is sent to the treasury.
    /// @dev Requirements:
    ///      - Must be called only for successfully defeated fraud challenges.
    function resolveFraudChallenge(
        BridgeState.Storage storage self,
        bytes calldata walletPublicKey,
        FraudChallenge storage challenge,
        bytes32 sighash
    ) internal {
        // Mark the challenge as resolved as it was successfully defeated
        challenge.resolved = true;

        // Send the ether deposited by the challenger to the treasury
        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls,unchecked-lowlevel,arbitrary-send
        self.treasury.call{gas: 100000, value: challenge.depositAmount}("");
        /* solhint-enable avoid-low-level-calls */

        bytes memory compressedWalletPublicKey = EcdsaLib.compressPublicKey(
            walletPublicKey.slice32(0),
            walletPublicKey.slice32(32)
        );
        bytes20 walletPubKeyHash = compressedWalletPublicKey.hash160View();

        // slither-disable-next-line reentrancy-events
        emit FraudChallengeDefeated(walletPubKeyHash, sighash);
    }

    /// @notice Notifies about defeat timeout for the given fraud challenge.
    ///         Can be called only if there was a fraud challenge identified by
    ///         the provided `walletPublicKey` and `sighash` and it was not
    ///         defeated on time. The amount of time that needs to pass after
    ///         a fraud challenge is reported is indicated by the
    ///         `challengeDefeatTimeout`. After a successful fraud challenge
    ///         defeat timeout notification the fraud challenge is marked as
    ///         resolved, the stake of each operator is slashed, the ether
    ///         deposited is returned to the challenger and the challenger is
    ///         rewarded.
    /// @param walletPublicKey The public key of the wallet in the uncompressed
    ///        and unprefixed format (64 bytes).
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @param preimageSha256 The hash that was generated by applying SHA-256
    ///        one time over the preimage used during input signing. The preimage
    ///        is a serialized subset of the transaction and its structure
    ///        depends on the transaction input (see BIP-143 for reference).
    ///        Notice that applying SHA-256 over the `preimageSha256` results
    ///        in `sighash`.  The path from `preimage` to `sighash` looks like
    ///        this:
    ///        preimage -> (SHA-256) -> preimageSha256 -> (SHA-256) -> sighash.
    /// @dev Requirements:
    ///      - The wallet must be in the Live or MovingFunds or Closing or
    ///        Terminated state,
    ///      - The `walletPublicKey` and `sighash` calculated from
    ///        `preimageSha256` must identify an open fraud challenge,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events of the `WalletRegistry` contract,
    ///      - The amount of time indicated by `challengeDefeatTimeout` must pass
    ///        after the challenge was reported.
    function notifyFraudChallengeDefeatTimeout(
        BridgeState.Storage storage self,
        bytes calldata walletPublicKey,
        uint32[] calldata walletMembersIDs,
        bytes memory preimageSha256
    ) external {
        // Wallet state is validated in `notifyWalletFraudChallengeDefeatTimeout`.

        bytes32 sighash = sha256(preimageSha256);

        uint256 challengeKey = uint256(
            keccak256(abi.encodePacked(walletPublicKey, sighash))
        );

        FraudChallenge storage challenge = self.fraudChallenges[challengeKey];

        require(challenge.reportedAt > 0, "Fraud challenge does not exist");

        require(
            !challenge.resolved,
            "Fraud challenge has already been resolved"
        );

        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp >=
                challenge.reportedAt + self.fraudChallengeDefeatTimeout,
            "Fraud challenge defeat period did not time out yet"
        );

        challenge.resolved = true;
        // Return the ether deposited by the challenger
        /* solhint-disable avoid-low-level-calls */
        // slither-disable-next-line low-level-calls,unchecked-lowlevel
        challenge.challenger.call{gas: 100000, value: challenge.depositAmount}(
            ""
        );
        /* solhint-enable avoid-low-level-calls */

        bytes memory compressedWalletPublicKey = EcdsaLib.compressPublicKey(
            walletPublicKey.slice32(0),
            walletPublicKey.slice32(32)
        );
        bytes20 walletPubKeyHash = compressedWalletPublicKey.hash160View();

        self.notifyWalletFraudChallengeDefeatTimeout(
            walletPubKeyHash,
            walletMembersIDs,
            challenge.challenger
        );

        // slither-disable-next-line reentrancy-events
        emit FraudChallengeDefeatTimedOut(walletPubKeyHash, sighash);
    }

    /// @notice Extracts the UTXO keys from the given preimage used during
    ///         signing of a witness input.
    /// @param preimage The preimage which produces sighash used to generate the
    ///        ECDSA signature that is the subject of the fraud claim. It is a
    ///        serialized subset of the transaction. The exact subset used as
    ///        the preimage depends on the transaction input the signature is
    ///        produced for. See BIP-143 for reference
    /// @return utxoKey UTXO key that identifies spent input.
    function extractUtxoKeyFromWitnessPreimage(bytes calldata preimage)
        internal
        pure
        returns (uint256 utxoKey)
    {
        // The expected structure of the preimage created during signing of a
        // witness input:
        // - transaction version (4 bytes)
        // - hash of previous outpoints of all inputs (32 bytes)
        // - hash of sequences of all inputs (32 bytes)
        // - outpoint (hash + index) of the input being signed (36 bytes)
        // - the unlocking script of the input (variable length)
        // - value of the outpoint (8 bytes)
        // - sequence of the input being signed (4 bytes)
        // - hash of all outputs (32 bytes)
        // - transaction locktime (4 bytes)
        // - sighash type (4 bytes)

        // See Bitcoin's BIP-143 for reference:
        // https://github.com/bitcoin/bips/blob/master/bip-0143.mediawiki.

        // The outpoint (hash and index) is located at the constant offset of
        // 68 (4 + 32 + 32).
        bytes32 outpointTxHash = preimage.extractInputTxIdLeAt(68);
        uint32 outpointIndex = BTCUtils.reverseUint32(
            uint32(preimage.extractTxIndexLeAt(68))
        );

        return
            uint256(keccak256(abi.encodePacked(outpointTxHash, outpointIndex)));
    }

    /// @notice Extracts the UTXO key from the given preimage used during
    ///         signing of a non-witness input.
    /// @param preimage The preimage which produces sighash used to generate the
    ///        ECDSA signature that is the subject of the fraud claim. It is a
    ///        serialized subset of the transaction. The exact subset used as
    ///        the preimage depends on the transaction input the signature is
    ///        produced for. See BIP-143 for reference.
    /// @return utxoKey UTXO key that identifies spent input.
    function extractUtxoKeyFromNonWitnessPreimage(bytes calldata preimage)
        internal
        pure
        returns (uint256 utxoKey)
    {
        // The expected structure of the preimage created during signing of a
        // non-witness input:
        // - transaction version (4 bytes)
        // - number of inputs written as compactSize uint (1 byte, 3 bytes,
        //   5 bytes or 9 bytes)
        // - for each input
        //   - outpoint (hash and index) (36 bytes)
        //   - unlocking script for the input being signed (variable length)
        //     or `00` for all other inputs (1 byte)
        //   - input sequence (4 bytes)
        // - number of outputs written as compactSize uint (1 byte, 3 bytes,
        //   5 bytes or 9 bytes)
        // - outputs (variable length)
        // - transaction locktime (4 bytes)
        // - sighash type (4 bytes)

        // See example for reference:
        // https://en.bitcoin.it/wiki/OP_CHECKSIG#Code_samples_and_raw_dumps.

        // The input data begins at the constant offset of 4 (the first 4 bytes
        // are for the transaction version).
        (uint256 inputsCompactSizeUintLength, uint256 inputsCount) = preimage
            .parseVarIntAt(4);

        // To determine the first input starting index, we must jump 4 bytes
        // over the transaction version length and the compactSize uint which
        // prepends the input vector. One byte must be added because
        // `BtcUtils.parseVarInt` does not include compactSize uint tag in the
        // returned length.
        //
        // For >= 0 && <= 252, `BTCUtils.determineVarIntDataLengthAt`
        // returns `0`, so we jump over one byte of compactSize uint.
        //
        // For >= 253 && <= 0xffff there is `0xfd` tag,
        // `BTCUtils.determineVarIntDataLengthAt` returns `2` (no
        // tag byte included) so we need to jump over 1+2 bytes of
        // compactSize uint.
        //
        // Please refer `BTCUtils` library and compactSize uint
        // docs in `BitcoinTx` library for more details.
        uint256 inputStartingIndex = 4 + 1 + inputsCompactSizeUintLength;

        for (uint256 i = 0; i < inputsCount; i++) {
            uint256 inputLength = preimage.determineInputLengthAt(
                inputStartingIndex
            );

            (, uint256 scriptSigLength) = preimage.extractScriptSigLenAt(
                inputStartingIndex
            );

            if (scriptSigLength > 0) {
                // The input this preimage was generated for was found.
                // All the other inputs in the preimage are marked with a null
                // scriptSig ("00") which has length of 1.
                bytes32 outpointTxHash = preimage.extractInputTxIdLeAt(
                    inputStartingIndex
                );
                uint32 outpointIndex = BTCUtils.reverseUint32(
                    uint32(preimage.extractTxIndexLeAt(inputStartingIndex))
                );

                utxoKey = uint256(
                    keccak256(abi.encodePacked(outpointTxHash, outpointIndex))
                );

                break;
            }

            inputStartingIndex += inputLength;
        }

        return utxoKey;
    }

    /// @notice Extracts the sighash type from the given preimage.
    /// @param preimage Serialized subset of the transaction. See BIP-143 for
    ///        reference.
    /// @dev Sighash type is stored as the last 4 bytes in the preimage (little
    ///      endian).
    /// @return sighashType Sighash type as a 32-bit integer.
    function extractSighashType(bytes calldata preimage)
        internal
        pure
        returns (uint32 sighashType)
    {
        bytes4 sighashTypeBytes = preimage.slice4(preimage.length - 4);
        uint32 sighashTypeLE = uint32(sighashTypeBytes);
        return sighashTypeLE.reverseUint32();
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

import {BytesLib} from "@keep-network/bitcoin-spv-sol/contracts/BytesLib.sol";

/// @title Bridge wallet heartbeat
/// @notice The library establishes expected format for heartbeat messages
///         signed by wallet ECDSA signing group. Heartbeat messages are
///         constructed in such a way that they can not be used as a Bitcoin
///         transaction preimages.
/// @dev The smallest Bitcoin non-coinbase transaction is a one spending an
///      OP_TRUE anyonecanspend output and creating 1 OP_TRUE anyonecanspend
///      output. Such a transaction has 61 bytes (see `BitcoinTx` documentation):
///        4  bytes  for version
///        1  byte   for tx_in_count
///        36 bytes  for tx_in.previous_output
///        1  byte   for tx_in.script_bytes (value: 0)
///        0  bytes  for tx_in.signature_script
///        4  bytes  for tx_in.sequence
///        1  byte   for tx_out_count
///        8  bytes  for tx_out.value
///        1  byte   for tx_out.pk_script_bytes
///        1  byte   for tx_out.pk_script
///        4  bytes  for lock_time
///
///
///      The smallest Bitcoin coinbase transaction is a one creating
///      1 OP_TRUE anyonecanspend output and having an empty coinbase script.
///      Such a transaction has 65 bytes:
///        4  bytes  for version
///        1  byte   for tx_in_count
///        32 bytes  for tx_in.hash  (all 0x00)
///        4  bytes  for tx_in.index (all 0xff)
///        1  byte   for tx_in.script_bytes (value: 0)
///        4  bytes  for tx_in.height
///        0  byte   for tx_in.coinbase_script
///        4  bytes  for tx_in.sequence
///        1  byte   for tx_out_count
///        8  bytes  for tx_out.value
///        1  byte   for tx_out.pk_script_bytes
///        1  byte   for tx_out.pk_script
///        4  bytes  for lock_time
///
///
///      A SIGHASH flag is used to indicate which part of the transaction is
///      signed by the ECDSA signature. There are currently 3 flags:
///      SIGHASH_ALL, SIGHASH_NONE, SIGHASH_SINGLE, and different combinations
///      of these flags.
///
///      No matter the SIGHASH flag and no matter the combination, the following
///      fields from the transaction are always included in the constructed
///      preimage:
///        4  bytes  for version
///        36 bytes  for tx_in.previous_output (or tx_in.hash + tx_in.index for coinbase)
///        4  bytes  for lock_time
///
///      Additionally, the last 4 bytes of the preimage determines the SIGHASH
///      flag.
///
///      This is enough to say there is no way the preimage could be shorter
///      than 4 + 36 + 4 + 4 = 48 bytes.
///
///      For this reason, we construct the heartbeat message, as a 16-byte
///      message. The first 8 bytes are 0xffffffffffffffff. The last 8 bytes
///      are for an arbitrary uint64, being a signed heartbeat nonce (for
///      example, the last Ethereum block hash).
///
///      The message being signed by the wallet when executing the heartbeat
///      protocol should be Bitcoin's hash256 (double SHA-256) of the heartbeat
///      message:
///        heartbeat_sighash = hash256(heartbeat_message)
library Heartbeat {
    using BytesLib for bytes;

    /// @notice Determines if the signed byte array is a valid, non-fraudulent
    ///         heartbeat message.
    /// @param message Message signed by the wallet. It is a potential heartbeat
    ///        message, Bitcoin transaction preimage, or an arbitrary signed
    ///        bytes.
    /// @dev Wallet heartbeat message must be exactly 16 bytes long with the first
    ///      8 bytes set to 0xffffffffffffffff.
    /// @return True if valid heartbeat message, false otherwise.
    function isValidHeartbeatMessage(bytes calldata message)
        internal
        pure
        returns (bool)
    {
        if (message.length != 16) {
            return false;
        }

        if (message.slice8(0) != 0xffffffffffffffff) {
            return false;
        }

        return true;
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

import {BTCUtils} from "@keep-network/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@keep-network/bitcoin-spv-sol/contracts/BytesLib.sol";

import "./BitcoinTx.sol";
import "./BridgeState.sol";
import "./Redemption.sol";
import "./Wallets.sol";

/// @title Moving Bridge wallet funds
/// @notice The library handles the logic for moving Bitcoin between Bridge
///         wallets.
/// @dev A wallet that failed a heartbeat, did not process requested redemption
///      on time, or qualifies to be closed, begins the procedure of moving
///      funds to other wallets in the Bridge. The wallet needs to commit to
///      which other Live wallets it is moving the funds to and then, provide an
///      SPV proof of moving funds to the previously committed wallets.
///      Once the proof is submitted, all target wallets are supposed to
///      sweep the received UTXOs with their own main UTXOs in order to
///      update their BTC balances.
library MovingFunds {
    using BridgeState for BridgeState.Storage;
    using Wallets for BridgeState.Storage;
    using BitcoinTx for BridgeState.Storage;

    using BTCUtils for bytes;
    using BytesLib for bytes;

    /// @notice Represents temporary information needed during the processing
    ///         of the moving funds Bitcoin transaction outputs. This structure
    ///         is an internal one and should not be exported outside of the
    ///         moving funds transaction processing code.
    /// @dev Allows to mitigate "stack too deep" errors on EVM.
    struct MovingFundsTxOutputsProcessingInfo {
        // 32-byte hash of the moving funds Bitcoin transaction.
        bytes32 movingFundsTxHash;
        // Output vector of the moving funds Bitcoin transaction. It is
        // assumed the vector's structure is valid so it must be validated
        // using e.g. `BTCUtils.validateVout` function before being used
        // during the processing. The validation is usually done as part
        // of the `BitcoinTx.validateProof` call that checks the SPV proof.
        bytes movingFundsTxOutputVector;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's memory argument.
    }

    /// @notice Represents moved funds sweep request state.
    enum MovedFundsSweepRequestState {
        /// @dev The request is unknown to the Bridge.
        Unknown,
        /// @dev Request is pending and can become either processed or timed out.
        Pending,
        /// @dev Request was processed by the target wallet.
        Processed,
        /// @dev Request was not processed in the given time window and
        ///      the timeout was reported.
        TimedOut
    }

    /// @notice Represents a moved funds sweep request. The request is
    ///         registered in `submitMovingFundsProof` where we know funds
    ///         have been moved to the target wallet and the only step left is
    ///         to have the target wallet sweep them.
    struct MovedFundsSweepRequest {
        // 20-byte public key hash of the wallet supposed to sweep the UTXO
        // representing the received funds with their own main UTXO
        bytes20 walletPubKeyHash;
        // Value of the received funds.
        uint64 value;
        // UNIX timestamp the request was created at.
        // XXX: Unsigned 32-bit int unix seconds, will break February 7th 2106.
        uint32 createdAt;
        // The current state of the request.
        MovedFundsSweepRequestState state;
        // This struct doesn't contain `__gap` property as the structure is stored
        // in a mapping, mappings store values in different slots and they are
        // not contiguous with other values.
    }

    event MovingFundsCommitmentSubmitted(
        bytes20 indexed walletPubKeyHash,
        bytes20[] targetWallets,
        address submitter
    );

    event MovingFundsTimeoutReset(bytes20 indexed walletPubKeyHash);

    event MovingFundsCompleted(
        bytes20 indexed walletPubKeyHash,
        bytes32 movingFundsTxHash
    );

    event MovingFundsTimedOut(bytes20 indexed walletPubKeyHash);

    event MovingFundsBelowDustReported(bytes20 indexed walletPubKeyHash);

    event MovedFundsSwept(
        bytes20 indexed walletPubKeyHash,
        bytes32 sweepTxHash
    );

    event MovedFundsSweepTimedOut(
        bytes20 indexed walletPubKeyHash,
        bytes32 movingFundsTxHash,
        uint32 movingFundsTxOutputIndex
    );

    /// @notice Submits the moving funds target wallets commitment.
    ///         Once all requirements are met, that function registers the
    ///         target wallets commitment and opens the way for moving funds
    ///         proof submission.
    /// @param walletPubKeyHash 20-byte public key hash of the source wallet.
    /// @param walletMainUtxo Data of the source wallet's main UTXO, as
    ///        currently known on the Ethereum chain.
    /// @param walletMembersIDs Identifiers of the source wallet signing group
    ///        members.
    /// @param walletMemberIndex Position of the caller in the source wallet
    ///        signing group members list.
    /// @param targetWallets List of 20-byte public key hashes of the target
    ///        wallets that the source wallet commits to move the funds to.
    /// @dev Requirements:
    ///      - The source wallet must be in the MovingFunds state,
    ///      - The source wallet must not have pending redemption requests,
    ///      - The source wallet must not have pending moved funds sweep requests,
    ///      - The source wallet must not have submitted its commitment already,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given source wallet in the ECDSA registry. Those IDs are
    ///        not directly stored in the contract for gas efficiency purposes
    ///        but they can be read from appropriate `DkgResultSubmitted`
    ///        and `DkgResultApproved` events,
    ///      - The `walletMemberIndex` must be in range [1, walletMembersIDs.length],
    ///      - The caller must be the member of the source wallet signing group
    ///        at the position indicated by `walletMemberIndex` parameter,
    ///      - The `walletMainUtxo` components must point to the recent main
    ///        UTXO of the source wallet, as currently known on the Ethereum
    ///        chain,
    ///      - Source wallet BTC balance must be greater than zero,
    ///      - At least one Live wallet must exist in the system,
    ///      - Submitted target wallets count must match the expected count
    ///        `N = min(liveWalletsCount, ceil(walletBtcBalance / walletMaxBtcTransfer))`
    ///        where `N > 0`,
    ///      - Each target wallet must be not equal to the source wallet,
    ///      - Each target wallet must follow the expected order i.e. all
    ///        target wallets 20-byte public key hashes represented as numbers
    ///        must form a strictly increasing sequence without duplicates,
    ///      - Each target wallet must be in Live state.
    function submitMovingFundsCommitment(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata walletMainUtxo,
        uint32[] calldata walletMembersIDs,
        uint256 walletMemberIndex,
        bytes20[] calldata targetWallets
    ) external {
        Wallets.Wallet storage wallet = self.registeredWallets[
            walletPubKeyHash
        ];

        require(
            wallet.state == Wallets.WalletState.MovingFunds,
            "Source wallet must be in MovingFunds state"
        );

        require(
            wallet.pendingRedemptionsValue == 0,
            "Source wallet must handle all pending redemptions first"
        );

        require(
            wallet.pendingMovedFundsSweepRequestsCount == 0,
            "Source wallet must handle all pending moved funds sweep requests first"
        );

        require(
            wallet.movingFundsTargetWalletsCommitmentHash == bytes32(0),
            "Target wallets commitment already submitted"
        );

        require(
            self.ecdsaWalletRegistry.isWalletMember(
                wallet.ecdsaWalletID,
                walletMembersIDs,
                msg.sender,
                walletMemberIndex
            ),
            "Caller is not a member of the source wallet"
        );

        uint64 walletBtcBalance = self.getWalletBtcBalance(
            walletPubKeyHash,
            walletMainUtxo
        );

        require(walletBtcBalance > 0, "Wallet BTC balance is zero");

        uint256 expectedTargetWalletsCount = Math.min(
            self.liveWalletsCount,
            Math.ceilDiv(walletBtcBalance, self.walletMaxBtcTransfer)
        );

        // This requirement fails only when `liveWalletsCount` is zero. In
        // that case, the system cannot accept the commitment and must provide
        // new wallets first. However, the wallet supposed to submit the
        // commitment can keep resetting the moving funds timeout until then.
        require(expectedTargetWalletsCount > 0, "No target wallets available");

        require(
            targetWallets.length == expectedTargetWalletsCount,
            "Submitted target wallets count is other than expected"
        );

        uint160 lastProcessedTargetWallet = 0;

        for (uint256 i = 0; i < targetWallets.length; i++) {
            bytes20 targetWallet = targetWallets[i];

            require(
                targetWallet != walletPubKeyHash,
                "Submitted target wallet cannot be equal to the source wallet"
            );

            require(
                uint160(targetWallet) > lastProcessedTargetWallet,
                "Submitted target wallet breaks the expected order"
            );

            require(
                self.registeredWallets[targetWallet].state ==
                    Wallets.WalletState.Live,
                "Submitted target wallet must be in Live state"
            );

            lastProcessedTargetWallet = uint160(targetWallet);
        }

        wallet.movingFundsTargetWalletsCommitmentHash = keccak256(
            abi.encodePacked(targetWallets)
        );

        emit MovingFundsCommitmentSubmitted(
            walletPubKeyHash,
            targetWallets,
            msg.sender
        );
    }

    /// @notice Resets the moving funds timeout for the given wallet if the
    ///         target wallet commitment cannot be submitted due to a lack
    ///         of live wallets in the system.
    /// @param walletPubKeyHash 20-byte public key hash of the moving funds wallet
    /// @dev Requirements:
    ///      - The wallet must be in the MovingFunds state,
    ///      - The target wallets commitment must not be already submitted for
    ///        the given moving funds wallet,
    ///      - Live wallets count must be zero,
    ///      - The moving funds timeout reset delay must be elapsed.
    function resetMovingFundsTimeout(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash
    ) external {
        Wallets.Wallet storage wallet = self.registeredWallets[
            walletPubKeyHash
        ];

        require(
            wallet.state == Wallets.WalletState.MovingFunds,
            "Wallet must be in MovingFunds state"
        );

        // If the moving funds wallet already submitted their target wallets
        // commitment, there is no point to reset the timeout since the
        // wallet can make the BTC transaction and submit the proof.
        require(
            wallet.movingFundsTargetWalletsCommitmentHash == bytes32(0),
            "Target wallets commitment already submitted"
        );

        require(self.liveWalletsCount == 0, "Live wallets count must be zero");

        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp >
                wallet.movingFundsRequestedAt +
                    self.movingFundsTimeoutResetDelay,
            "Moving funds timeout cannot be reset yet"
        );

        /* solhint-disable-next-line not-rely-on-time */
        wallet.movingFundsRequestedAt = uint32(block.timestamp);

        emit MovingFundsTimeoutReset(walletPubKeyHash);
    }

    /// @notice Used by the wallet to prove the BTC moving funds transaction
    ///         and to make the necessary state changes. Moving funds is only
    ///         accepted if it satisfies SPV proof.
    ///
    ///         The function validates the moving funds transaction structure
    ///         by checking if it actually spends the main UTXO of the declared
    ///         wallet and locks the value on the pre-committed target wallets
    ///         using a reasonable transaction fee. If all preconditions are
    ///         met, this functions closes the source wallet.
    ///
    ///         It is possible to prove the given moving funds transaction only
    ///         one time.
    /// @param movingFundsTx Bitcoin moving funds transaction data.
    /// @param movingFundsProof Bitcoin moving funds proof data.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    /// @param walletPubKeyHash 20-byte public key hash (computed using Bitcoin
    ///        HASH160 over the compressed ECDSA public key) of the wallet
    ///        which performed the moving funds transaction.
    /// @dev Requirements:
    ///      - `movingFundsTx` components must match the expected structure. See
    ///        `BitcoinTx.Info` docs for reference. Their values must exactly
    ///        correspond to appropriate Bitcoin transaction fields to produce
    ///        a provable transaction hash,
    ///      - The `movingFundsTx` should represent a Bitcoin transaction with
    ///        exactly 1 input that refers to the wallet's main UTXO. That
    ///        transaction should have 1..n outputs corresponding to the
    ///        pre-committed target wallets. Outputs must be ordered in the
    ///        same way as their corresponding target wallets are ordered
    ///        within the target wallets commitment,
    ///      - `movingFundsProof` components must match the expected structure.
    ///        See `BitcoinTx.Proof` docs for reference. The `bitcoinHeaders`
    ///        field must contain a valid number of block headers, not less
    ///        than the `txProofDifficultyFactor` contract constant,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        Additionally, the recent main UTXO on Ethereum must be set,
    ///      - `walletPubKeyHash` must be connected with the main UTXO used
    ///        as transaction single input,
    ///      - The wallet that `walletPubKeyHash` points to must be in the
    ///        MovingFunds state,
    ///      - The target wallets commitment must be submitted by the wallet
    ///        that `walletPubKeyHash` points to,
    ///      - The total Bitcoin transaction fee must be lesser or equal
    ///        to `movingFundsTxMaxTotalFee` governable parameter.
    function submitMovingFundsProof(
        BridgeState.Storage storage self,
        BitcoinTx.Info calldata movingFundsTx,
        BitcoinTx.Proof calldata movingFundsProof,
        BitcoinTx.UTXO calldata mainUtxo,
        bytes20 walletPubKeyHash
    ) external {
        // Wallet state is validated in `notifyWalletFundsMoved`.

        // The actual transaction proof is performed here. After that point, we
        // can assume the transaction happened on Bitcoin chain and has
        // a sufficient number of confirmations as determined by
        // `txProofDifficultyFactor` constant.
        bytes32 movingFundsTxHash = self.validateProof(
            movingFundsTx,
            movingFundsProof
        );

        // Assert that main UTXO for passed wallet exists in storage.
        bytes32 mainUtxoHash = self
            .registeredWallets[walletPubKeyHash]
            .mainUtxoHash;
        require(mainUtxoHash != bytes32(0), "No main UTXO for given wallet");

        // Assert that passed main UTXO parameter is the same as in storage and
        // can be used for further processing.
        require(
            keccak256(
                abi.encodePacked(
                    mainUtxo.txHash,
                    mainUtxo.txOutputIndex,
                    mainUtxo.txOutputValue
                )
            ) == mainUtxoHash,
            "Invalid main UTXO data"
        );

        // Process the moving funds transaction input. Specifically, check if
        // it refers to the expected wallet's main UTXO.
        OutboundTx.processWalletOutboundTxInput(
            self,
            movingFundsTx.inputVector,
            mainUtxo
        );

        (
            bytes32 targetWalletsHash,
            uint256 outputsTotalValue
        ) = processMovingFundsTxOutputs(
                self,
                MovingFundsTxOutputsProcessingInfo(
                    movingFundsTxHash,
                    movingFundsTx.outputVector
                )
            );

        require(
            mainUtxo.txOutputValue - outputsTotalValue <=
                self.movingFundsTxMaxTotalFee,
            "Transaction fee is too high"
        );

        self.notifyWalletFundsMoved(walletPubKeyHash, targetWalletsHash);
        // slither-disable-next-line reentrancy-events
        emit MovingFundsCompleted(walletPubKeyHash, movingFundsTxHash);
    }

    /// @notice Processes the moving funds Bitcoin transaction output vector
    ///         and extracts information required for further processing.
    /// @param processInfo Processing info containing the moving funds tx
    ///        hash and output vector.
    /// @return targetWalletsHash keccak256 hash over the list of actual
    ///         target wallets used in the transaction.
    /// @return outputsTotalValue Sum of all outputs values.
    /// @dev Requirements:
    ///      - The `movingFundsTxOutputVector` must be parseable, i.e. must
    ///        be validated by the caller as stated in their parameter doc,
    ///      - Each output must refer to a 20-byte public key hash,
    ///      - The total outputs value must be evenly divided over all outputs.
    function processMovingFundsTxOutputs(
        BridgeState.Storage storage self,
        MovingFundsTxOutputsProcessingInfo memory processInfo
    ) internal returns (bytes32 targetWalletsHash, uint256 outputsTotalValue) {
        // Determining the total number of Bitcoin transaction outputs in
        // the same way as for number of inputs. See `BitcoinTx.outputVector`
        // docs for more details.
        (
            uint256 outputsCompactSizeUintLength,
            uint256 outputsCount
        ) = processInfo.movingFundsTxOutputVector.parseVarInt();

        // To determine the first output starting index, we must jump over
        // the compactSize uint which prepends the output vector. One byte
        // must be added because `BtcUtils.parseVarInt` does not include
        // compactSize uint tag in the returned length.
        //
        // For >= 0 && <= 252, `BTCUtils.determineVarIntDataLengthAt`
        // returns `0`, so we jump over one byte of compactSize uint.
        //
        // For >= 253 && <= 0xffff there is `0xfd` tag,
        // `BTCUtils.determineVarIntDataLengthAt` returns `2` (no
        // tag byte included) so we need to jump over 1+2 bytes of
        // compactSize uint.
        //
        // Please refer `BTCUtils` library and compactSize uint
        // docs in `BitcoinTx` library for more details.
        uint256 outputStartingIndex = 1 + outputsCompactSizeUintLength;

        bytes20[] memory targetWallets = new bytes20[](outputsCount);
        uint64[] memory outputsValues = new uint64[](outputsCount);

        // Outputs processing loop. Note that the `outputIndex` must be
        // `uint32` to build proper `movedFundsSweepRequests` keys.
        for (
            uint32 outputIndex = 0;
            outputIndex < outputsCount;
            outputIndex++
        ) {
            uint256 outputLength = processInfo
                .movingFundsTxOutputVector
                .determineOutputLengthAt(outputStartingIndex);

            bytes memory output = processInfo.movingFundsTxOutputVector.slice(
                outputStartingIndex,
                outputLength
            );

            bytes20 targetWalletPubKeyHash = self.extractPubKeyHash(output);

            // Add the wallet public key hash to the list that will be used
            // to build the result list hash. There is no need to check if
            // given output is a change here because the actual target wallet
            // list must be exactly the same as the pre-committed target wallet
            // list which is guaranteed to be valid.
            targetWallets[outputIndex] = targetWalletPubKeyHash;

            // Extract the value from given output.
            outputsValues[outputIndex] = output.extractValue();
            outputsTotalValue += outputsValues[outputIndex];

            // Register a moved funds sweep request that must be handled
            // by the target wallet. The target wallet must sweep the
            // received funds with their own main UTXO in order to update
            // their BTC balance. Worth noting there is no need to check
            // if the sweep request already exists in the system because
            // the moving funds wallet is moved to the Closing state after
            // submitting the moving funds proof so there is no possibility
            // to submit the proof again and register the sweep request twice.
            self.movedFundsSweepRequests[
                uint256(
                    keccak256(
                        abi.encodePacked(
                            processInfo.movingFundsTxHash,
                            outputIndex
                        )
                    )
                )
            ] = MovedFundsSweepRequest(
                targetWalletPubKeyHash,
                outputsValues[outputIndex],
                /* solhint-disable-next-line not-rely-on-time */
                uint32(block.timestamp),
                MovedFundsSweepRequestState.Pending
            );
            // We added a new moved funds sweep request for the target wallet
            // so we must increment their request counter.
            self
                .registeredWallets[targetWalletPubKeyHash]
                .pendingMovedFundsSweepRequestsCount++;

            // Make the `outputStartingIndex` pointing to the next output by
            // increasing it by current output's length.
            outputStartingIndex += outputLength;
        }

        // Compute the indivisible remainder that remains after dividing the
        // outputs total value over all outputs evenly.
        uint256 outputsTotalValueRemainder = outputsTotalValue % outputsCount;
        // Compute the minimum allowed output value by dividing the outputs
        // total value (reduced by the remainder) by the number of outputs.
        uint256 minOutputValue = (outputsTotalValue -
            outputsTotalValueRemainder) / outputsCount;
        // Maximum possible value is the minimum value with the remainder included.
        uint256 maxOutputValue = minOutputValue + outputsTotalValueRemainder;

        for (uint256 i = 0; i < outputsCount; i++) {
            require(
                minOutputValue <= outputsValues[i] &&
                    outputsValues[i] <= maxOutputValue,
                "Transaction amount is not distributed evenly"
            );
        }

        targetWalletsHash = keccak256(abi.encodePacked(targetWallets));

        return (targetWalletsHash, outputsTotalValue);
    }

    /// @notice Notifies about a timed out moving funds process. Terminates
    ///         the wallet and slashes signing group members as a result.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @dev Requirements:
    ///      - The wallet must be in the MovingFunds state,
    ///      - The moving funds timeout must be actually exceeded,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events of the `WalletRegistry` contract.
    function notifyMovingFundsTimeout(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        uint32[] calldata walletMembersIDs
    ) external {
        // Wallet state is validated in `notifyWalletMovingFundsTimeout`.

        uint32 movingFundsRequestedAt = self
            .registeredWallets[walletPubKeyHash]
            .movingFundsRequestedAt;

        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp > movingFundsRequestedAt + self.movingFundsTimeout,
            "Moving funds has not timed out yet"
        );

        self.notifyWalletMovingFundsTimeout(walletPubKeyHash, walletMembersIDs);

        // slither-disable-next-line reentrancy-events
        emit MovingFundsTimedOut(walletPubKeyHash);
    }

    /// @notice Notifies about a moving funds wallet whose BTC balance is
    ///         below the moving funds dust threshold. Ends the moving funds
    ///         process and begins wallet closing immediately.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known
    ///        on the Ethereum chain.
    /// @dev Requirements:
    ///      - The wallet must be in the MovingFunds state,
    ///      - The `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        If the wallet has no main UTXO, this parameter can be empty as it
    ///        is ignored,
    ///      - The wallet BTC balance must be below the moving funds threshold.
    function notifyMovingFundsBelowDust(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata mainUtxo
    ) external {
        // Wallet state is validated in `notifyWalletMovingFundsBelowDust`.

        uint64 walletBtcBalance = self.getWalletBtcBalance(
            walletPubKeyHash,
            mainUtxo
        );

        require(
            walletBtcBalance < self.movingFundsDustThreshold,
            "Wallet BTC balance must be below the moving funds dust threshold"
        );

        self.notifyWalletMovingFundsBelowDust(walletPubKeyHash);

        // slither-disable-next-line reentrancy-events
        emit MovingFundsBelowDustReported(walletPubKeyHash);
    }

    /// @notice Used by the wallet to prove the BTC moved funds sweep
    ///         transaction and to make the necessary state changes. Moved
    ///         funds sweep is only accepted if it satisfies SPV proof.
    ///
    ///         The function validates the sweep transaction structure by
    ///         checking if it actually spends the moved funds UTXO and the
    ///         sweeping wallet's main UTXO (optionally), and if it locks the
    ///         value on the sweeping wallet's 20-byte public key hash using a
    ///         reasonable transaction fee. If all preconditions are
    ///         met, this function updates the sweeping wallet main UTXO, thus
    ///         their BTC balance.
    ///
    ///         It is possible to prove the given sweep transaction only
    ///         one time.
    /// @param sweepTx Bitcoin sweep funds transaction data.
    /// @param sweepProof Bitcoin sweep funds proof data.
    /// @param mainUtxo Data of the sweeping wallet's main UTXO, as currently
    ///        known on the Ethereum chain.
    /// @dev Requirements:
    ///      - `sweepTx` components must match the expected structure. See
    ///        `BitcoinTx.Info` docs for reference. Their values must exactly
    ///        correspond to appropriate Bitcoin transaction fields to produce
    ///        a provable transaction hash,
    ///      - The `sweepTx` should represent a Bitcoin transaction with
    ///        the first input pointing to a wallet's sweep Pending request and,
    ///        optionally, the second input pointing to the wallet's main UTXO,
    ///        if the sweeping wallet has a main UTXO set. There should be only
    ///        one output locking funds on the sweeping wallet 20-byte public
    ///        key hash,
    ///      - `sweepProof` components must match the expected structure.
    ///        See `BitcoinTx.Proof` docs for reference. The `bitcoinHeaders`
    ///        field must contain a valid number of block headers, not less
    ///        than the `txProofDifficultyFactor` contract constant,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the sweeping wallet, as currently known on the Ethereum chain.
    ///        If there is no main UTXO, this parameter is ignored,
    ///      - The sweeping wallet must be in the Live or MovingFunds state,
    ///      - The total Bitcoin transaction fee must be lesser or equal
    ///        to `movedFundsSweepTxMaxTotalFee` governable parameter.
    function submitMovedFundsSweepProof(
        BridgeState.Storage storage self,
        BitcoinTx.Info calldata sweepTx,
        BitcoinTx.Proof calldata sweepProof,
        BitcoinTx.UTXO calldata mainUtxo
    ) external {
        // Wallet state validation is performed in the
        // `resolveMovedFundsSweepingWallet` function.

        // The actual transaction proof is performed here. After that point, we
        // can assume the transaction happened on Bitcoin chain and has
        // a sufficient number of confirmations as determined by
        // `txProofDifficultyFactor` constant.
        bytes32 sweepTxHash = self.validateProof(sweepTx, sweepProof);

        (
            bytes20 walletPubKeyHash,
            uint64 sweepTxOutputValue
        ) = processMovedFundsSweepTxOutput(self, sweepTx.outputVector);

        (
            Wallets.Wallet storage wallet,
            BitcoinTx.UTXO memory resolvedMainUtxo
        ) = resolveMovedFundsSweepingWallet(self, walletPubKeyHash, mainUtxo);

        uint256 sweepTxInputsTotalValue = processMovedFundsSweepTxInputs(
            self,
            sweepTx.inputVector,
            resolvedMainUtxo,
            walletPubKeyHash
        );

        require(
            sweepTxInputsTotalValue - sweepTxOutputValue <=
                self.movedFundsSweepTxMaxTotalFee,
            "Transaction fee is too high"
        );

        // Use the sweep transaction output as the new sweeping wallet's main UTXO.
        // Transaction output index is always 0 as sweep transaction always
        // contains only one output.
        wallet.mainUtxoHash = keccak256(
            abi.encodePacked(sweepTxHash, uint32(0), sweepTxOutputValue)
        );

        // slither-disable-next-line reentrancy-events
        emit MovedFundsSwept(walletPubKeyHash, sweepTxHash);
    }

    /// @notice Processes the Bitcoin moved funds sweep transaction output vector
    ///         by extracting the single output and using it to gain additional
    ///         information required for further processing (e.g. value and
    ///         wallet public key hash).
    /// @param sweepTxOutputVector Bitcoin moved funds sweep transaction output
    ///        vector.
    ///        This function assumes vector's structure is valid so it must be
    ///        validated using e.g. `BTCUtils.validateVout` function before
    ///        it is passed here.
    /// @return walletPubKeyHash 20-byte wallet public key hash.
    /// @return value 8-byte moved funds sweep transaction output value.
    /// @dev Requirements:
    ///      - Output vector must contain only one output,
    ///      - The single output must be of P2PKH or P2WPKH type and lock the
    ///        funds on a 20-byte public key hash.
    function processMovedFundsSweepTxOutput(
        BridgeState.Storage storage self,
        bytes memory sweepTxOutputVector
    ) internal view returns (bytes20 walletPubKeyHash, uint64 value) {
        // To determine the total number of sweep transaction outputs, we need to
        // parse the compactSize uint (VarInt) the output vector is prepended by.
        // That compactSize uint encodes the number of vector elements using the
        // format presented in:
        // https://developer.bitcoin.org/reference/transactions.html#compactsize-unsigned-integers
        // We don't need asserting the compactSize uint is parseable since it
        // was already checked during `validateVout` validation performed as
        // part of the `BitcoinTx.validateProof` call.
        // See `BitcoinTx.outputVector` docs for more details.
        (, uint256 outputsCount) = sweepTxOutputVector.parseVarInt();
        require(
            outputsCount == 1,
            "Moved funds sweep transaction must have a single output"
        );

        bytes memory output = sweepTxOutputVector.extractOutputAtIndex(0);
        walletPubKeyHash = self.extractPubKeyHash(output);
        value = output.extractValue();

        return (walletPubKeyHash, value);
    }

    /// @notice Resolves sweeping wallet based on the provided wallet public key
    ///         hash. Validates the wallet state and current main UTXO, as
    ///         currently known on the Ethereum chain.
    /// @param walletPubKeyHash public key hash of the wallet proving the sweep
    ///        Bitcoin transaction.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain. If no main UTXO exists for the given wallet,
    ///        this parameter is ignored.
    /// @return wallet Data of the sweeping wallet.
    /// @return resolvedMainUtxo The actual main UTXO of the sweeping wallet
    ///         resolved by cross-checking the `mainUtxo` parameter with
    ///         the chain state. If the validation went well, this is the
    ///         plain-text main UTXO corresponding to the `wallet.mainUtxoHash`.
    /// @dev Requirements:
    ///     - Sweeping wallet must be either in Live or MovingFunds state,
    ///     - If the main UTXO of the sweeping wallet exists in the storage,
    ///       the passed `mainUTXO` parameter must be equal to the stored one.
    function resolveMovedFundsSweepingWallet(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata mainUtxo
    )
        internal
        view
        returns (
            Wallets.Wallet storage wallet,
            BitcoinTx.UTXO memory resolvedMainUtxo
        )
    {
        wallet = self.registeredWallets[walletPubKeyHash];

        Wallets.WalletState walletState = wallet.state;
        require(
            walletState == Wallets.WalletState.Live ||
                walletState == Wallets.WalletState.MovingFunds,
            "Wallet must be in Live or MovingFunds state"
        );

        // Check if the main UTXO for given wallet exists. If so, validate
        // passed main UTXO data against the stored hash and use them for
        // further processing. If no main UTXO exists, use empty data.
        resolvedMainUtxo = BitcoinTx.UTXO(bytes32(0), 0, 0);
        bytes32 mainUtxoHash = wallet.mainUtxoHash;
        if (mainUtxoHash != bytes32(0)) {
            require(
                keccak256(
                    abi.encodePacked(
                        mainUtxo.txHash,
                        mainUtxo.txOutputIndex,
                        mainUtxo.txOutputValue
                    )
                ) == mainUtxoHash,
                "Invalid main UTXO data"
            );
            resolvedMainUtxo = mainUtxo;
        }
    }

    /// @notice Processes the Bitcoin moved funds sweep transaction input vector.
    ///         It extracts the first input and tries to match it with one of
    ///         the moved funds sweep requests targeting the sweeping wallet.
    ///         If the sweep request is an existing Pending request, this
    ///         function marks it as Processed. If the sweeping wallet has a
    ///         main UTXO, this function extracts the second input, makes sure
    ///         it refers to the wallet main UTXO, and marks that main UTXO as
    ///         correctly spent.
    /// @param sweepTxInputVector Bitcoin moved funds sweep transaction input vector.
    ///        This function assumes vector's structure is valid so it must be
    ///        validated using e.g. `BTCUtils.validateVin` function before
    ///        it is passed here.
    /// @param mainUtxo Data of the sweeping wallet's main UTXO. If no main UTXO
    ///        exists for the given the wallet, this parameter's fields should
    ///        be zeroed to bypass the main UTXO validation.
    /// @param walletPubKeyHash 20-byte public key hash of the sweeping wallet.
    /// @return inputsTotalValue Total inputs value sum.
    /// @dev Requirements:
    ///      - The input vector must consist of one mandatory and one optional
    ///        input,
    ///      - The mandatory input must be the first input in the vector,
    ///      - The mandatory input must point to a Pending moved funds sweep
    ///        request that is targeted to the sweeping wallet,
    ///      - The optional output must be the second input in the vector,
    ///      - The optional input is required if the sweeping wallet has a
    ///        main UTXO (i.e. the `mainUtxo` is not zeroed). In that case,
    ///        that input must point the the sweeping wallet main UTXO.
    function processMovedFundsSweepTxInputs(
        BridgeState.Storage storage self,
        bytes memory sweepTxInputVector,
        BitcoinTx.UTXO memory mainUtxo,
        bytes20 walletPubKeyHash
    ) internal returns (uint256 inputsTotalValue) {
        // To determine the total number of Bitcoin transaction inputs,
        // we need to parse the compactSize uint (VarInt) the input vector is
        // prepended by. That compactSize uint encodes the number of vector
        // elements using the format presented in:
        // https://developer.bitcoin.org/reference/transactions.html#compactsize-unsigned-integers
        // We don't need asserting the compactSize uint is parseable since it
        // was already checked during `validateVin` validation performed as
        // part of the `BitcoinTx.validateProof` call.
        // See `BitcoinTx.inputVector` docs for more details.
        (
            uint256 inputsCompactSizeUintLength,
            uint256 inputsCount
        ) = sweepTxInputVector.parseVarInt();

        // To determine the first input starting index, we must jump over
        // the compactSize uint which prepends the input vector. One byte
        // must be added because `BtcUtils.parseVarInt` does not include
        // compactSize uint tag in the returned length.
        //
        // For >= 0 && <= 252, `BTCUtils.determineVarIntDataLengthAt`
        // returns `0`, so we jump over one byte of compactSize uint.
        //
        // For >= 253 && <= 0xffff there is `0xfd` tag,
        // `BTCUtils.determineVarIntDataLengthAt` returns `2` (no
        // tag byte included) so we need to jump over 1+2 bytes of
        // compactSize uint.
        //
        // Please refer `BTCUtils` library and compactSize uint
        // docs in `BitcoinTx` library for more details.
        uint256 inputStartingIndex = 1 + inputsCompactSizeUintLength;

        // We always expect the first input to be the swept UTXO. Additionally,
        // if the sweeping wallet has a main UTXO, that main UTXO should be
        // pointed by the second input.
        require(
            inputsCount == (mainUtxo.txHash != bytes32(0) ? 2 : 1),
            "Moved funds sweep transaction must have a proper inputs count"
        );

        // Parse the first input and extract its outpoint tx hash and index.
        (
            bytes32 firstInputOutpointTxHash,
            uint32 firstInputOutpointIndex,
            uint256 firstInputLength
        ) = parseMovedFundsSweepTxInputAt(
                sweepTxInputVector,
                inputStartingIndex
            );

        // Build the request key and fetch the corresponding moved funds sweep
        // request from contract storage.
        MovedFundsSweepRequest storage sweepRequest = self
            .movedFundsSweepRequests[
                uint256(
                    keccak256(
                        abi.encodePacked(
                            firstInputOutpointTxHash,
                            firstInputOutpointIndex
                        )
                    )
                )
            ];

        require(
            sweepRequest.state == MovedFundsSweepRequestState.Pending,
            "Sweep request must be in Pending state"
        );
        // We must check if the wallet extracted from the moved funds sweep
        // transaction output is truly the owner of the sweep request connected
        // with the swept UTXO. This is needed to prevent a case when a wallet
        // handles its own sweep request but locks the funds on another
        // wallet public key hash.
        require(
            sweepRequest.walletPubKeyHash == walletPubKeyHash,
            "Sweep request belongs to another wallet"
        );
        // If the validation passed, the sweep request must be marked as
        // processed and its value should be counted into the total inputs
        // value sum.
        sweepRequest.state = MovedFundsSweepRequestState.Processed;
        inputsTotalValue += sweepRequest.value;

        self
            .registeredWallets[walletPubKeyHash]
            .pendingMovedFundsSweepRequestsCount--;

        // If the main UTXO for the sweeping wallet exists, it must be processed.
        if (mainUtxo.txHash != bytes32(0)) {
            // The second input is supposed to point to that sweeping wallet
            // main UTXO. We need to parse that input.
            (
                bytes32 secondInputOutpointTxHash,
                uint32 secondInputOutpointIndex,

            ) = parseMovedFundsSweepTxInputAt(
                    sweepTxInputVector,
                    inputStartingIndex + firstInputLength
                );
            // Make sure the second input refers to the sweeping wallet main UTXO.
            require(
                mainUtxo.txHash == secondInputOutpointTxHash &&
                    mainUtxo.txOutputIndex == secondInputOutpointIndex,
                "Second input must point to the wallet's main UTXO"
            );

            // If the validation passed, count the main UTXO value into the
            // total inputs value sum.
            inputsTotalValue += mainUtxo.txOutputValue;

            // Main UTXO used as an input, mark it as spent. This is needed
            // to defend against fraud challenges referring to this main UTXO.
            self.spentMainUTXOs[
                uint256(
                    keccak256(
                        abi.encodePacked(
                            secondInputOutpointTxHash,
                            secondInputOutpointIndex
                        )
                    )
                )
            ] = true;
        }

        return inputsTotalValue;
    }

    /// @notice Parses a Bitcoin transaction input starting at the given index.
    /// @param inputVector Bitcoin transaction input vector.
    /// @param inputStartingIndex Index the given input starts at.
    /// @return outpointTxHash 32-byte hash of the Bitcoin transaction which is
    ///         pointed in the given input's outpoint.
    /// @return outpointIndex 4-byte index of the Bitcoin transaction output
    ///         which is pointed in the given input's outpoint.
    /// @return inputLength Byte length of the given input.
    /// @dev This function assumes vector's structure is valid so it must be
    ///      validated using e.g. `BTCUtils.validateVin` function before it
    ///      is passed here.
    function parseMovedFundsSweepTxInputAt(
        bytes memory inputVector,
        uint256 inputStartingIndex
    )
        internal
        pure
        returns (
            bytes32 outpointTxHash,
            uint32 outpointIndex,
            uint256 inputLength
        )
    {
        outpointTxHash = inputVector.extractInputTxIdLeAt(inputStartingIndex);

        outpointIndex = BTCUtils.reverseUint32(
            uint32(inputVector.extractTxIndexLeAt(inputStartingIndex))
        );

        inputLength = inputVector.determineInputLengthAt(inputStartingIndex);

        return (outpointTxHash, outpointIndex, inputLength);
    }

    /// @notice Notifies about a timed out moved funds sweep process. If the
    ///         wallet is not terminated yet, that function terminates
    ///         the wallet and slashes signing group members as a result.
    ///         Marks the given sweep request as TimedOut.
    /// @param movingFundsTxHash 32-byte hash of the moving funds transaction
    ///        that caused the sweep request to be created.
    /// @param movingFundsTxOutputIndex Index of the moving funds transaction
    ///        output that is subject of the sweep request.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @dev Requirements:
    ///      - The moved funds sweep request must be in the Pending state,
    ///      - The moved funds sweep timeout must be actually exceeded,
    ///      - The wallet must be either in the Live or MovingFunds or
    ///        Terminated state,,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events of the `WalletRegistry` contract.
    function notifyMovedFundsSweepTimeout(
        BridgeState.Storage storage self,
        bytes32 movingFundsTxHash,
        uint32 movingFundsTxOutputIndex,
        uint32[] calldata walletMembersIDs
    ) external {
        // Wallet state is validated in `notifyWalletMovedFundsSweepTimeout`.

        MovedFundsSweepRequest storage sweepRequest = self
            .movedFundsSweepRequests[
                uint256(
                    keccak256(
                        abi.encodePacked(
                            movingFundsTxHash,
                            movingFundsTxOutputIndex
                        )
                    )
                )
            ];

        require(
            sweepRequest.state == MovedFundsSweepRequestState.Pending,
            "Sweep request must be in Pending state"
        );

        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp >
                sweepRequest.createdAt + self.movedFundsSweepTimeout,
            "Sweep request has not timed out yet"
        );

        bytes20 walletPubKeyHash = sweepRequest.walletPubKeyHash;

        self.notifyWalletMovedFundsSweepTimeout(
            walletPubKeyHash,
            walletMembersIDs
        );

        Wallets.Wallet storage wallet = self.registeredWallets[
            walletPubKeyHash
        ];
        sweepRequest.state = MovedFundsSweepRequestState.TimedOut;
        wallet.pendingMovedFundsSweepRequestsCount--;

        // slither-disable-next-line reentrancy-events
        emit MovedFundsSweepTimedOut(
            walletPubKeyHash,
            movingFundsTxHash,
            movingFundsTxOutputIndex
        );
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

import {BTCUtils} from "@keep-network/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {BytesLib} from "@keep-network/bitcoin-spv-sol/contracts/BytesLib.sol";

import "./BitcoinTx.sol";
import "./BridgeState.sol";
import "./Wallets.sol";

import "../bank/Bank.sol";

/// @notice Aggregates functions common to the redemption transaction proof
///         validation and to the moving funds transaction proof validation.
library OutboundTx {
    using BTCUtils for bytes;

    /// @notice Checks whether an outbound Bitcoin transaction performed from
    ///         the given wallet has an input vector that contains a single
    ///         input referring to the wallet's main UTXO. Marks that main UTXO
    ///         as correctly spent if the validation succeeds. Reverts otherwise.
    ///         There are two outbound transactions from a wallet possible: a
    ///         redemption transaction or a moving funds to another wallet
    ///         transaction.
    /// @param walletOutboundTxInputVector Bitcoin outbound transaction's input
    ///        vector. This function assumes vector's structure is valid so it
    ///        must be validated using e.g. `BTCUtils.validateVin` function
    ///        before it is passed here.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    function processWalletOutboundTxInput(
        BridgeState.Storage storage self,
        bytes memory walletOutboundTxInputVector,
        BitcoinTx.UTXO calldata mainUtxo
    ) internal {
        // Assert that the single outbound transaction input actually
        // refers to the wallet's main UTXO.
        (
            bytes32 outpointTxHash,
            uint32 outpointIndex
        ) = parseWalletOutboundTxInput(walletOutboundTxInputVector);
        require(
            mainUtxo.txHash == outpointTxHash &&
                mainUtxo.txOutputIndex == outpointIndex,
            "Outbound transaction input must point to the wallet's main UTXO"
        );

        // Main UTXO used as an input, mark it as spent.
        self.spentMainUTXOs[
            uint256(
                keccak256(
                    abi.encodePacked(mainUtxo.txHash, mainUtxo.txOutputIndex)
                )
            )
        ] = true;
    }

    /// @notice Parses the input vector of an outbound Bitcoin transaction
    ///         performed from the given wallet. It extracts the single input
    ///         then the transaction hash and output index from its outpoint.
    ///         There are two outbound transactions from a wallet possible: a
    ///         redemption transaction or a moving funds to another wallet
    ///         transaction.
    /// @param walletOutboundTxInputVector Bitcoin outbound transaction input
    ///        vector. This function assumes vector's structure is valid so it
    ///        must be validated using e.g. `BTCUtils.validateVin` function
    ///        before it is passed here.
    /// @return outpointTxHash 32-byte hash of the Bitcoin transaction which is
    ///         pointed in the input's outpoint.
    /// @return outpointIndex 4-byte index of the Bitcoin transaction output
    ///         which is pointed in the input's outpoint.
    function parseWalletOutboundTxInput(
        bytes memory walletOutboundTxInputVector
    ) internal pure returns (bytes32 outpointTxHash, uint32 outpointIndex) {
        // To determine the total number of Bitcoin transaction inputs,
        // we need to parse the compactSize uint (VarInt) the input vector is
        // prepended by. That compactSize uint encodes the number of vector
        // elements using the format presented in:
        // https://developer.bitcoin.org/reference/transactions.html#compactsize-unsigned-integers
        // We don't need asserting the compactSize uint is parseable since it
        // was already checked during `validateVin` validation.
        // See `BitcoinTx.inputVector` docs for more details.
        (, uint256 inputsCount) = walletOutboundTxInputVector.parseVarInt();
        require(
            inputsCount == 1,
            "Outbound transaction must have a single input"
        );

        bytes memory input = walletOutboundTxInputVector.extractInputAtIndex(0);

        outpointTxHash = input.extractInputTxIdLE();

        outpointIndex = BTCUtils.reverseUint32(
            uint32(input.extractTxIndexLE())
        );

        // There is only one input in the transaction. Input has an outpoint
        // field that is a reference to the transaction being spent (see
        // `BitcoinTx` docs). The outpoint contains the hash of the transaction
        // to spend (`outpointTxHash`) and the index of the specific output
        // from that transaction (`outpointIndex`).
        return (outpointTxHash, outpointIndex);
    }
}

/// @title Bridge redemption
/// @notice The library handles the logic for redeeming Bitcoin balances from
///         the Bridge.
/// @dev To initiate a redemption, a user with a Bank balance supplies
///      a Bitcoin address. Then, the system calculates the redemption fee, and
///      releases balance to the provided Bitcoin address. Just like in case of
///      sweeps of revealed deposits, redemption requests are processed in
///      batches and require SPV proof to be submitted to the Bridge.
library Redemption {
    using BridgeState for BridgeState.Storage;
    using Wallets for BridgeState.Storage;
    using BitcoinTx for BridgeState.Storage;

    using BTCUtils for bytes;
    using BytesLib for bytes;

    /// @notice Represents a redemption request.
    struct RedemptionRequest {
        // ETH address of the redeemer who created the request.
        address redeemer;
        // Requested TBTC amount in satoshi.
        uint64 requestedAmount;
        // Treasury TBTC fee in satoshi at the moment of request creation.
        uint64 treasuryFee;
        // Transaction maximum BTC fee in satoshi at the moment of request
        // creation.
        uint64 txMaxFee;
        // UNIX timestamp the request was created at.
        // XXX: Unsigned 32-bit int unix seconds, will break February 7th 2106.
        uint32 requestedAt;
        // This struct doesn't contain `__gap` property as the structure is stored
        // in a mapping, mappings store values in different slots and they are
        // not contiguous with other values.
    }

    /// @notice Represents an outcome of the redemption Bitcoin transaction
    ///         outputs processing.
    struct RedemptionTxOutputsInfo {
        // Sum of all outputs values i.e. all redemptions and change value,
        // if present.
        uint256 outputsTotalValue;
        // Total TBTC value in satoshi that should be burned by the Bridge.
        // It includes the total amount of all BTC redeemed in the transaction
        // and the fee paid to BTC miners for the redemption transaction.
        uint64 totalBurnableValue;
        // Total TBTC value in satoshi that should be transferred to
        // the treasury. It is a sum of all treasury fees paid by all
        // redeemers included in the redemption transaction.
        uint64 totalTreasuryFee;
        // Index of the change output. The change output becomes
        // the new main wallet's UTXO.
        uint32 changeIndex;
        // Value in satoshi of the change output.
        uint64 changeValue;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's memory argument.
    }

    /// @notice Represents temporary information needed during the processing of
    ///         the redemption Bitcoin transaction outputs. This structure is an
    ///         internal one and should not be exported outside of the redemption
    ///         transaction processing code.
    /// @dev Allows to mitigate "stack too deep" errors on EVM.
    struct RedemptionTxOutputsProcessingInfo {
        // The first output starting index in the transaction.
        uint256 outputStartingIndex;
        // The number of outputs in the transaction.
        uint256 outputsCount;
        // P2PKH script for the wallet. Needed to determine the change output.
        bytes32 walletP2PKHScriptKeccak;
        // P2WPKH script for the wallet. Needed to determine the change output.
        bytes32 walletP2WPKHScriptKeccak;
        // This struct doesn't contain `__gap` property as the structure is not
        // stored, it is used as a function's memory argument.
    }

    event RedemptionRequested(
        bytes20 indexed walletPubKeyHash,
        bytes redeemerOutputScript,
        address indexed redeemer,
        uint64 requestedAmount,
        uint64 treasuryFee,
        uint64 txMaxFee
    );

    event RedemptionsCompleted(
        bytes20 indexed walletPubKeyHash,
        bytes32 redemptionTxHash
    );

    event RedemptionTimedOut(
        bytes20 indexed walletPubKeyHash,
        bytes redeemerOutputScript
    );

    /// @notice Requests redemption of the given amount from the specified
    ///         wallet to the redeemer Bitcoin output script.
    ///         This function handles the simplest case, where balance owner is
    ///         the redeemer.
    /// @param walletPubKeyHash The 20-byte wallet public key hash (computed
    ///        using Bitcoin HASH160 over the compressed ECDSA public key).
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    /// @param balanceOwner The address of the Bank balance owner whose balance
    ///        is getting redeemed. Balance owner address is stored as
    ///        a redeemer address who will be able co claim back the Bank
    ///        balance if anything goes wrong during the redemption.
    /// @param redeemerOutputScript The redeemer's length-prefixed output
    ///        script (P2PKH, P2WPKH, P2SH or P2WSH) that will be used to lock
    ///        redeemed BTC.
    /// @param amount Requested amount in satoshi. This is also the Bank balance
    ///        that is taken from the `balanceOwner` upon request.
    ///        Once the request is handled, the actual amount of BTC locked
    ///        on the redeemer output script will be always lower than this value
    ///        since the treasury and Bitcoin transaction fees must be incurred.
    ///        The minimal amount satisfying the request can be computed as:
    ///        `amount - (amount / redemptionTreasuryFeeDivisor) - redemptionTxMaxFee`.
    ///        Fees values are taken at the moment of request creation.
    /// @dev Requirements:
    ///      - Wallet behind `walletPubKeyHash` must be live,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain,
    ///      - `redeemerOutputScript` must be a proper Bitcoin script,
    ///      - `redeemerOutputScript` cannot have wallet PKH as payload,
    ///      - `amount` must be above or equal the `redemptionDustThreshold`,
    ///      - Given `walletPubKeyHash` and `redeemerOutputScript` pair can be
    ///        used for only one pending request at the same time,
    ///      - Wallet must have enough Bitcoin balance to proceed the request,
    ///      - Balance owner must make an allowance in the Bank that the Bridge
    ///        contract can spend the given `amount`.
    function requestRedemption(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata mainUtxo,
        address balanceOwner,
        bytes calldata redeemerOutputScript,
        uint64 amount
    ) external {
        requestRedemption(
            self,
            walletPubKeyHash,
            mainUtxo,
            balanceOwner,
            balanceOwner,
            redeemerOutputScript,
            amount
        );
    }

    /// @notice Requests redemption of the given amount from the specified
    ///         wallet to the redeemer Bitcoin output script. Used by
    ///         `Bridge.receiveBalanceApproval`. Can handle more complex cases
    ///         where balance owner may be someone else than the redeemer.
    /// @param balanceOwner The address of the Bank balance owner whose balance
    ///        is getting redeemed.
    /// @param amount Requested amount in satoshi. This is also the Bank balance
    ///        that is taken from the `balanceOwner` upon request.
    ///        Once the request is handled, the actual amount of BTC locked
    ///        on the redeemer output script will be always lower than this value
    ///        since the treasury and Bitcoin transaction fees must be incurred.
    ///        The minimal amount satisfying the request can be computed as:
    ///        `amount - (amount / redemptionTreasuryFeeDivisor) - redemptionTxMaxFee`.
    ///        Fees values are taken at the moment of request creation.
    /// @param redemptionData ABI-encoded redemption data:
    ///        [
    ///          address redeemer,
    ///          bytes20 walletPubKeyHash,
    ///          bytes32 mainUtxoTxHash,
    ///          uint32 mainUtxoTxOutputIndex,
    ///          uint64 mainUtxoTxOutputValue,
    ///          bytes redeemerOutputScript
    ///        ]
    ///
    ///        - redeemer: The Ethereum address of the redeemer who will be able
    ///        to claim Bank balance if anything goes wrong during the redemption.
    ///        In the most basic case, when someone redeems their Bitcoin
    ///        balance from the Bank, `balanceOwner` is the same as `redeemer`.
    ///        However, when a Vault is redeeming part of its balance for some
    ///        redeemer address (for example, someone who has earlier deposited
    ///        into that Vault), `balanceOwner` is the Vault, and `redeemer` is
    ///        the address for which the vault is redeeming its balance to,
    ///        - walletPubKeyHash: The 20-byte wallet public key hash (computed
    ///        using Bitcoin HASH160 over the compressed ECDSA public key),
    ///        - mainUtxoTxHash: Data of the wallet's main UTXO TX hash, as
    ///        currently known on the Ethereum chain,
    ///        - mainUtxoTxOutputIndex: Data of the wallet's main UTXO output
    ///        index, as currently known on Ethereum chain,
    ///        - mainUtxoTxOutputValue: Data of the wallet's main UTXO output
    ///        value, as currently known on Ethereum chain,
    ///        - redeemerOutputScript The redeemer's length-prefixed output
    ///        script (P2PKH, P2WPKH, P2SH or P2WSH) that will be used to lock
    ///        redeemed BTC.
    /// @dev Requirements:
    ///      - Wallet behind `walletPubKeyHash` must be live,
    ///      - `mainUtxo*` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain,
    ///      - `redeemerOutputScript` must be a proper Bitcoin script,
    ///      - `redeemerOutputScript` cannot have wallet PKH as payload,
    ///      - `amount` must be above or equal the `redemptionDustThreshold`,
    ///      - Given `walletPubKeyHash` and `redeemerOutputScript` pair can be
    ///        used for only one pending request at the same time,
    ///      - Wallet must have enough Bitcoin balance to proceed the request,
    ///      - Balance owner must make an allowance in the Bank that the Bridge
    ///        contract can spend the given `amount`.
    function requestRedemption(
        BridgeState.Storage storage self,
        address balanceOwner,
        uint64 amount,
        bytes calldata redemptionData
    ) external {
        (
            address redeemer,
            bytes20 walletPubKeyHash,
            bytes32 mainUtxoTxHash,
            uint32 mainUtxoTxOutputIndex,
            uint64 mainUtxoTxOutputValue,
            bytes memory redeemerOutputScript
        ) = abi.decode(
                redemptionData,
                (address, bytes20, bytes32, uint32, uint64, bytes)
            );

        requestRedemption(
            self,
            walletPubKeyHash,
            BitcoinTx.UTXO(
                mainUtxoTxHash,
                mainUtxoTxOutputIndex,
                mainUtxoTxOutputValue
            ),
            balanceOwner,
            redeemer,
            redeemerOutputScript,
            amount
        );
    }

    /// @notice Requests redemption of the given amount from the specified
    ///         wallet to the redeemer Bitcoin output script.
    /// @param walletPubKeyHash The 20-byte wallet public key hash (computed
    ///        using Bitcoin HASH160 over the compressed ECDSA public key).
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    /// @param balanceOwner The address of the Bank balance owner whose balance
    ///        is getting redeemed.
    /// @param redeemer The Ethereum address of the redeemer who will be able to
    ///        claim Bank balance if anything goes wrong during the redemption.
    ///        In the most basic case, when someone redeems their Bitcoin
    ///        balance from the Bank, `balanceOwner` is the same as `redeemer`.
    ///        However, when a Vault is redeeming part of its balance for some
    ///        redeemer address (for example, someone who has earlier deposited
    ///        into that Vault), `balanceOwner` is the Vault, and `redeemer` is
    ///        the address for which the vault is redeeming its balance to.
    /// @param redeemerOutputScript The redeemer's length-prefixed output
    ///        script (P2PKH, P2WPKH, P2SH or P2WSH) that will be used to lock
    ///        redeemed BTC.
    /// @param amount Requested amount in satoshi. This is also the Bank balance
    ///        that is taken from the `balanceOwner` upon request.
    ///        Once the request is handled, the actual amount of BTC locked
    ///        on the redeemer output script will be always lower than this value
    ///        since the treasury and Bitcoin transaction fees must be incurred.
    ///        The minimal amount satisfying the request can be computed as:
    ///        `amount - (amount / redemptionTreasuryFeeDivisor) - redemptionTxMaxFee`.
    ///        Fees values are taken at the moment of request creation.
    /// @dev Requirements:
    ///      - Wallet behind `walletPubKeyHash` must be live,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain,
    ///      - `redeemerOutputScript` must be a proper Bitcoin script,
    ///      - `redeemerOutputScript` cannot have wallet PKH as payload,
    ///      - `amount` must be above or equal the `redemptionDustThreshold`,
    ///      - Given `walletPubKeyHash` and `redeemerOutputScript` pair can be
    ///        used for only one pending request at the same time,
    ///      - Wallet must have enough Bitcoin balance to proceed the request,
    ///      - Balance owner must make an allowance in the Bank that the Bridge
    ///        contract can spend the given `amount`.
    function requestRedemption(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO memory mainUtxo,
        address balanceOwner,
        address redeemer,
        bytes memory redeemerOutputScript,
        uint64 amount
    ) internal {
        Wallets.Wallet storage wallet = self.registeredWallets[
            walletPubKeyHash
        ];

        require(
            wallet.state == Wallets.WalletState.Live,
            "Wallet must be in Live state"
        );

        bytes32 mainUtxoHash = wallet.mainUtxoHash;
        require(
            mainUtxoHash != bytes32(0),
            "No main UTXO for the given wallet"
        );
        require(
            keccak256(
                abi.encodePacked(
                    mainUtxo.txHash,
                    mainUtxo.txOutputIndex,
                    mainUtxo.txOutputValue
                )
            ) == mainUtxoHash,
            "Invalid main UTXO data"
        );

        // Validate if redeemer output script is a correct standard type
        // (P2PKH, P2WPKH, P2SH or P2WSH). This is done by using
        // `BTCUtils.extractHashAt` on it. Such a function extracts the payload
        // properly only from standard outputs so if it succeeds, we have a
        // guarantee the redeemer output script is proper. The underlying way
        // of validation is the same as in tBTC v1.
        bytes memory redeemerOutputScriptPayload = redeemerOutputScript
            .extractHashAt(0, redeemerOutputScript.length);

        require(
            redeemerOutputScriptPayload.length > 0,
            "Redeemer output script must be a standard type"
        );
        // Check if the redeemer output script payload does not point to the
        // wallet public key hash.
        require(
            redeemerOutputScriptPayload.length != 20 ||
                walletPubKeyHash != redeemerOutputScriptPayload.slice20(0),
            "Redeemer output script must not point to the wallet PKH"
        );

        require(
            amount >= self.redemptionDustThreshold,
            "Redemption amount too small"
        );

        // The redemption key is built on top of the wallet public key hash
        // and redeemer output script pair. That means there can be only one
        // request asking for redemption from the given wallet to the given
        // BTC script at the same time.
        uint256 redemptionKey = getRedemptionKey(
            walletPubKeyHash,
            redeemerOutputScript
        );

        // Check if given redemption key is not used by a pending redemption.
        // There is no need to check for existence in `timedOutRedemptions`
        // since the wallet's state is changed to other than Live after
        // first time out is reported so making new requests is not possible.
        // slither-disable-next-line incorrect-equality
        require(
            self.pendingRedemptions[redemptionKey].requestedAt == 0,
            "There is a pending redemption request from this wallet to the same address"
        );

        // No need to check whether `amount - treasuryFee - txMaxFee > 0`
        // since the `redemptionDustThreshold` should force that condition
        // to be always true.
        uint64 treasuryFee = self.redemptionTreasuryFeeDivisor > 0
            ? amount / self.redemptionTreasuryFeeDivisor
            : 0;
        uint64 txMaxFee = self.redemptionTxMaxFee;

        // The main wallet UTXO's value doesn't include all pending redemptions.
        // To determine if the requested redemption can be performed by the
        // wallet we need to subtract the total value of all pending redemptions
        // from that wallet's main UTXO value. Given that the treasury fee is
        // not redeemed from the wallet, we are subtracting it.
        wallet.pendingRedemptionsValue += amount - treasuryFee;
        require(
            mainUtxo.txOutputValue >= wallet.pendingRedemptionsValue,
            "Insufficient wallet funds"
        );

        self.pendingRedemptions[redemptionKey] = RedemptionRequest(
            redeemer,
            amount,
            treasuryFee,
            txMaxFee,
            /* solhint-disable-next-line not-rely-on-time */
            uint32(block.timestamp)
        );

        // slither-disable-next-line reentrancy-events
        emit RedemptionRequested(
            walletPubKeyHash,
            redeemerOutputScript,
            redeemer,
            amount,
            treasuryFee,
            txMaxFee
        );

        self.bank.transferBalanceFrom(balanceOwner, address(this), amount);
    }

    /// @notice Used by the wallet to prove the BTC redemption transaction
    ///         and to make the necessary bookkeeping. Redemption is only
    ///         accepted if it satisfies SPV proof.
    ///
    ///         The function is performing Bank balance updates by burning
    ///         the total redeemed Bitcoin amount from Bridge balance and
    ///         transferring the treasury fee sum to the treasury address.
    ///
    ///         It is possible to prove the given redemption only one time.
    /// @param redemptionTx Bitcoin redemption transaction data.
    /// @param redemptionProof Bitcoin redemption proof data.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    /// @param walletPubKeyHash 20-byte public key hash (computed using Bitcoin
    ///        HASH160 over the compressed ECDSA public key) of the wallet which
    ///        performed the redemption transaction.
    /// @dev Requirements:
    ///      - `redemptionTx` components must match the expected structure. See
    ///        `BitcoinTx.Info` docs for reference. Their values must exactly
    ///        correspond to appropriate Bitcoin transaction fields to produce
    ///        a provable transaction hash,
    ///      - The `redemptionTx` should represent a Bitcoin transaction with
    ///        exactly 1 input that refers to the wallet's main UTXO. That
    ///        transaction should have 1..n outputs handling existing pending
    ///        redemption requests or pointing to reported timed out requests.
    ///        There can be also 1 optional output representing the
    ///        change and pointing back to the 20-byte wallet public key hash.
    ///        The change should be always present if the redeemed value sum
    ///        is lower than the total wallet's BTC balance,
    ///      - `redemptionProof` components must match the expected structure.
    ///        See `BitcoinTx.Proof` docs for reference. The `bitcoinHeaders`
    ///        field must contain a valid number of block headers, not less
    ///        than the `txProofDifficultyFactor` contract constant,
    ///      - `mainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        Additionally, the recent main UTXO on Ethereum must be set,
    ///      - `walletPubKeyHash` must be connected with the main UTXO used
    ///        as transaction single input.
    ///      Other remarks:
    ///      - Putting the change output as the first transaction output can
    ///        save some gas because the output processing loop begins each
    ///        iteration by checking whether the given output is the change
    ///        thus uses some gas for making the comparison. Once the change
    ///        is identified, that check is omitted in further iterations.
    function submitRedemptionProof(
        BridgeState.Storage storage self,
        BitcoinTx.Info calldata redemptionTx,
        BitcoinTx.Proof calldata redemptionProof,
        BitcoinTx.UTXO calldata mainUtxo,
        bytes20 walletPubKeyHash
    ) external {
        // Wallet state validation is performed in the `resolveRedeemingWallet`
        // function.

        // The actual transaction proof is performed here. After that point, we
        // can assume the transaction happened on Bitcoin chain and has
        // a sufficient number of confirmations as determined by
        // `txProofDifficultyFactor` constant.
        bytes32 redemptionTxHash = self.validateProof(
            redemptionTx,
            redemptionProof
        );

        Wallets.Wallet storage wallet = resolveRedeemingWallet(
            self,
            walletPubKeyHash,
            mainUtxo
        );

        // Process the redemption transaction input. Specifically, check if it
        // refers to the expected wallet's main UTXO.
        OutboundTx.processWalletOutboundTxInput(
            self,
            redemptionTx.inputVector,
            mainUtxo
        );

        // Process redemption transaction outputs to extract some info required
        // for further processing.
        RedemptionTxOutputsInfo memory outputsInfo = processRedemptionTxOutputs(
            self,
            redemptionTx.outputVector,
            walletPubKeyHash
        );

        require(
            mainUtxo.txOutputValue - outputsInfo.outputsTotalValue <=
                self.redemptionTxMaxTotalFee,
            "Transaction fee is too high"
        );

        if (outputsInfo.changeValue > 0) {
            // If the change value is grater than zero, it means the change
            // output exists and can be used as new wallet's main UTXO.
            wallet.mainUtxoHash = keccak256(
                abi.encodePacked(
                    redemptionTxHash,
                    outputsInfo.changeIndex,
                    outputsInfo.changeValue
                )
            );
        } else {
            // If the change value is zero, it means the change output doesn't
            // exists and no funds left on the wallet. Delete the main UTXO
            // for that wallet to represent that state in a proper way.
            delete wallet.mainUtxoHash;
        }

        wallet.pendingRedemptionsValue -= outputsInfo.totalBurnableValue;

        emit RedemptionsCompleted(walletPubKeyHash, redemptionTxHash);

        self.bank.decreaseBalance(outputsInfo.totalBurnableValue);

        if (outputsInfo.totalTreasuryFee > 0) {
            self.bank.transferBalance(
                self.treasury,
                outputsInfo.totalTreasuryFee
            );
        }
    }

    /// @notice Resolves redeeming wallet based on the provided wallet public
    ///         key hash. Validates the wallet state and current main UTXO, as
    ///         currently known on the Ethereum chain.
    /// @param walletPubKeyHash public key hash of the wallet proving the sweep
    ///        Bitcoin transaction.
    /// @param mainUtxo Data of the wallet's main UTXO, as currently known on
    ///        the Ethereum chain.
    /// @return wallet Data of the sweeping wallet.
    /// @dev Requirements:
    ///     - Sweeping wallet must be either in Live or MovingFunds state,
    ///     - Main UTXO of the redeeming wallet must exists in the storage,
    ///     - The passed `mainUTXO` parameter must be equal to the stored one.
    function resolveRedeemingWallet(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata mainUtxo
    ) internal view returns (Wallets.Wallet storage wallet) {
        wallet = self.registeredWallets[walletPubKeyHash];

        // Assert that main UTXO for passed wallet exists in storage.
        bytes32 mainUtxoHash = wallet.mainUtxoHash;
        require(mainUtxoHash != bytes32(0), "No main UTXO for given wallet");

        // Assert that passed main UTXO parameter is the same as in storage and
        // can be used for further processing.
        require(
            keccak256(
                abi.encodePacked(
                    mainUtxo.txHash,
                    mainUtxo.txOutputIndex,
                    mainUtxo.txOutputValue
                )
            ) == mainUtxoHash,
            "Invalid main UTXO data"
        );

        Wallets.WalletState walletState = wallet.state;
        require(
            walletState == Wallets.WalletState.Live ||
                walletState == Wallets.WalletState.MovingFunds,
            "Wallet must be in Live or MovingFunds state"
        );
    }

    /// @notice Processes the Bitcoin redemption transaction output vector.
    ///         It extracts each output and tries to identify it as a pending
    ///         redemption request, reported timed out request, or change.
    ///         Reverts if one of the outputs cannot be recognized properly.
    ///         This function also marks each request as processed by removing
    ///         them from `pendingRedemptions` mapping.
    /// @param redemptionTxOutputVector Bitcoin redemption transaction output
    ///        vector. This function assumes vector's structure is valid so it
    ///        must be validated using e.g. `BTCUtils.validateVout` function
    ///        before it is passed here.
    /// @param walletPubKeyHash 20-byte public key hash (computed using Bitcoin
    ///        HASH160 over the compressed ECDSA public key) of the wallet which
    ///        performed the redemption transaction.
    /// @return info Outcomes of the processing.
    function processRedemptionTxOutputs(
        BridgeState.Storage storage self,
        bytes memory redemptionTxOutputVector,
        bytes20 walletPubKeyHash
    ) internal returns (RedemptionTxOutputsInfo memory info) {
        // Determining the total number of redemption transaction outputs in
        // the same way as for number of inputs. See `BitcoinTx.outputVector`
        // docs for more details.
        (
            uint256 outputsCompactSizeUintLength,
            uint256 outputsCount
        ) = redemptionTxOutputVector.parseVarInt();

        // To determine the first output starting index, we must jump over
        // the compactSize uint which prepends the output vector. One byte
        // must be added because `BtcUtils.parseVarInt` does not include
        // compactSize uint tag in the returned length.
        //
        // For >= 0 && <= 252, `BTCUtils.determineVarIntDataLengthAt`
        // returns `0`, so we jump over one byte of compactSize uint.
        //
        // For >= 253 && <= 0xffff there is `0xfd` tag,
        // `BTCUtils.determineVarIntDataLengthAt` returns `2` (no
        // tag byte included) so we need to jump over 1+2 bytes of
        // compactSize uint.
        //
        // Please refer `BTCUtils` library and compactSize uint
        // docs in `BitcoinTx` library for more details.
        uint256 outputStartingIndex = 1 + outputsCompactSizeUintLength;

        // Calculate the keccak256 for two possible wallet's P2PKH or P2WPKH
        // scripts that can be used to lock the change. This is done upfront to
        // save on gas. Both scripts have a strict format defined by Bitcoin.
        //
        // The P2PKH script has the byte format: <0x1976a914> <20-byte PKH> <0x88ac>.
        // According to https://en.bitcoin.it/wiki/Script#Opcodes this translates to:
        // - 0x19: Byte length of the entire script
        // - 0x76: OP_DUP
        // - 0xa9: OP_HASH160
        // - 0x14: Byte length of the public key hash
        // - 0x88: OP_EQUALVERIFY
        // - 0xac: OP_CHECKSIG
        // which matches the P2PKH structure as per:
        // https://en.bitcoin.it/wiki/Transaction#Pay-to-PubkeyHash
        bytes32 walletP2PKHScriptKeccak = keccak256(
            abi.encodePacked(BitcoinTx.makeP2PKHScript(walletPubKeyHash))
        );
        // The P2WPKH script has the byte format: <0x160014> <20-byte PKH>.
        // According to https://en.bitcoin.it/wiki/Script#Opcodes this translates to:
        // - 0x16: Byte length of the entire script
        // - 0x00: OP_0
        // - 0x14: Byte length of the public key hash
        // which matches the P2WPKH structure as per:
        // https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki#P2WPKH
        bytes32 walletP2WPKHScriptKeccak = keccak256(
            abi.encodePacked(BitcoinTx.makeP2WPKHScript(walletPubKeyHash))
        );

        return
            processRedemptionTxOutputs(
                self,
                redemptionTxOutputVector,
                walletPubKeyHash,
                RedemptionTxOutputsProcessingInfo(
                    outputStartingIndex,
                    outputsCount,
                    walletP2PKHScriptKeccak,
                    walletP2WPKHScriptKeccak
                )
            );
    }

    /// @notice Processes all outputs from the redemption transaction. Tries to
    ///         identify output as a change output, pending redemption request
    ///         or reported redemption. Reverts if one of the outputs cannot be
    ///         recognized properly. Marks each request as processed by removing
    ///         them from `pendingRedemptions` mapping.
    /// @param redemptionTxOutputVector Bitcoin redemption transaction output
    ///        vector. This function assumes vector's structure is valid so it
    ///        must be validated using e.g. `BTCUtils.validateVout` function
    ///        before it is passed here.
    /// @param walletPubKeyHash 20-byte public key hash (computed using Bitcoin
    ///        HASH160 over the compressed ECDSA public key) of the wallet which
    ///        performed the redemption transaction.
    /// @param processInfo RedemptionTxOutputsProcessingInfo identifying output
    ///        starting index, the number of outputs and possible wallet change
    ///        P2PKH and P2WPKH scripts.
    function processRedemptionTxOutputs(
        BridgeState.Storage storage self,
        bytes memory redemptionTxOutputVector,
        bytes20 walletPubKeyHash,
        RedemptionTxOutputsProcessingInfo memory processInfo
    ) internal returns (RedemptionTxOutputsInfo memory resultInfo) {
        // Helper flag indicating whether there was at least one redemption
        // output present (redemption must be either pending or reported as
        // timed out).
        bool redemptionPresent = false;

        // Outputs processing loop.
        for (uint256 i = 0; i < processInfo.outputsCount; i++) {
            uint256 outputLength = redemptionTxOutputVector
                .determineOutputLengthAt(processInfo.outputStartingIndex);

            // Extract the value from given output.
            uint64 outputValue = redemptionTxOutputVector.extractValueAt(
                processInfo.outputStartingIndex
            );

            // The output consists of an 8-byte value and a variable length
            // script. To hash that script we slice the output starting from
            // 9th byte until the end.
            uint256 scriptLength = outputLength - 8;
            uint256 outputScriptStart = processInfo.outputStartingIndex + 8;

            bytes32 outputScriptHash;
            /* solhint-disable-next-line no-inline-assembly */
            assembly {
                // The first argument to assembly keccak256 is the pointer.
                // We point to `redemptionTxOutputVector` but at the position
                // indicated by `outputScriptStart`. To load that position, we
                // need to call `add(outputScriptStart, 32)` because
                // `outputScriptStart` has 32 bytes.
                outputScriptHash := keccak256(
                    add(redemptionTxOutputVector, add(outputScriptStart, 32)),
                    scriptLength
                )
            }

            if (
                resultInfo.changeValue == 0 &&
                (outputScriptHash == processInfo.walletP2PKHScriptKeccak ||
                    outputScriptHash == processInfo.walletP2WPKHScriptKeccak) &&
                outputValue > 0
            ) {
                // If we entered here, that means the change output with a
                // proper non-zero value was found.
                resultInfo.changeIndex = uint32(i);
                resultInfo.changeValue = outputValue;
            } else {
                // If we entered here, that the means the given output is
                // supposed to represent a redemption.
                (
                    uint64 burnableValue,
                    uint64 treasuryFee
                ) = processNonChangeRedemptionTxOutput(
                        self,
                        _getRedemptionKey(walletPubKeyHash, outputScriptHash),
                        outputValue
                    );
                resultInfo.totalBurnableValue += burnableValue;
                resultInfo.totalTreasuryFee += treasuryFee;
                redemptionPresent = true;
            }

            resultInfo.outputsTotalValue += outputValue;

            // Make the `outputStartingIndex` pointing to the next output by
            // increasing it by current output's length.
            processInfo.outputStartingIndex += outputLength;
        }

        // Protect against the cases when there is only a single change output
        // referring back to the wallet PKH and just burning main UTXO value
        // for transaction fees.
        require(
            redemptionPresent,
            "Redemption transaction must process at least one redemption"
        );
    }

    /// @notice Processes a single redemption transaction output. Tries to
    ///         identify output as a pending redemption request or reported
    ///         redemption timeout. Output script passed to this function must
    ///         not be the change output. Such output needs to be identified
    ///         separately before calling this function.
    ///         Reverts if output is neither requested pending redemption nor
    ///         requested and reported timed-out redemption.
    ///         This function also marks each pending request as processed by
    ///         removing them from `pendingRedemptions` mapping.
    /// @param redemptionKey Redemption key of the output being processed.
    /// @param outputValue Value of the output being processed.
    /// @return burnableValue The value burnable as a result of processing this
    ///         single redemption output. This value needs to be summed up with
    ///         burnable values of all other outputs to evaluate total burnable
    ///         value for the entire redemption transaction. This value is 0
    ///         for a timed-out redemption request.
    /// @return treasuryFee The treasury fee from this single redemption output.
    ///         This value needs to be summed up with treasury fees of all other
    ///         outputs to evaluate the total treasury fee for the entire
    ///         redemption transaction. This value is 0 for a timed-out
    ///         redemption request.
    /// @dev Requirements:
    ///      - This function should be called only if the given output
    ///        represents redemption. It must not be the change output.
    function processNonChangeRedemptionTxOutput(
        BridgeState.Storage storage self,
        uint256 redemptionKey,
        uint64 outputValue
    ) internal returns (uint64 burnableValue, uint64 treasuryFee) {
        if (self.pendingRedemptions[redemptionKey].requestedAt != 0) {
            // If we entered here, that means the output was identified
            // as a pending redemption request.
            RedemptionRequest storage request = self.pendingRedemptions[
                redemptionKey
            ];
            // Compute the request's redeemable amount as the requested
            // amount reduced by the treasury fee. The request's
            // minimal amount is then the redeemable amount reduced by
            // the maximum transaction fee.
            uint64 redeemableAmount = request.requestedAmount -
                request.treasuryFee;
            // Output value must fit between the request's redeemable
            // and minimal amounts to be deemed valid.
            require(
                redeemableAmount - request.txMaxFee <= outputValue &&
                    outputValue <= redeemableAmount,
                "Output value is not within the acceptable range of the pending request"
            );
            // Add the redeemable amount to the total burnable value
            // the Bridge will use to decrease its balance in the Bank.
            burnableValue = redeemableAmount;
            // Add the request's treasury fee to the total treasury fee
            // value the Bridge will transfer to the treasury.
            treasuryFee = request.treasuryFee;
            // Request was properly handled so remove its redemption
            // key from the mapping to make it reusable for further
            // requests.
            delete self.pendingRedemptions[redemptionKey];
        } else {
            // If we entered here, the output is not a redemption
            // request but there is still a chance the given output is
            // related to a reported timed out redemption request.
            // If so, check if the output value matches the request
            // amount to confirm this is an overdue request fulfillment
            // then bypass this output and process the subsequent
            // ones. That also means the wallet was already punished
            // for the inactivity. Otherwise, just revert.
            RedemptionRequest storage request = self.timedOutRedemptions[
                redemptionKey
            ];

            require(
                request.requestedAt != 0,
                "Output is a non-requested redemption"
            );

            uint64 redeemableAmount = request.requestedAmount -
                request.treasuryFee;

            require(
                redeemableAmount - request.txMaxFee <= outputValue &&
                    outputValue <= redeemableAmount,
                "Output value is not within the acceptable range of the timed out request"
            );

            delete self.timedOutRedemptions[redemptionKey];
        }
    }

    /// @notice Notifies that there is a pending redemption request associated
    ///         with the given wallet, that has timed out. The redemption
    ///         request is identified by the key built as
    ///         `keccak256(keccak256(redeemerOutputScript) | walletPubKeyHash)`.
    ///         The results of calling this function:
    ///         - the pending redemptions value for the wallet will be decreased
    ///           by the requested amount (minus treasury fee),
    ///         - the tokens taken from the redeemer on redemption request will
    ///           be returned to the redeemer,
    ///         - the request will be moved from pending redemptions to
    ///           timed-out redemptions,
    ///         - if the state of the wallet is `Live` or `MovingFunds`, the
    ///           wallet operators will be slashed and the notifier will be
    ///           rewarded,
    ///         - if the state of wallet is `Live`, the wallet will be closed or
    ///           marked as `MovingFunds` (depending on the presence or absence
    ///           of the wallet's main UTXO) and the wallet will no longer be
    ///           marked as the active wallet (if it was marked as such).
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @param redeemerOutputScript  The redeemer's length-prefixed output
    ///        script (P2PKH, P2WPKH, P2SH or P2WSH).
    /// @dev Requirements:
    ///      - The wallet must be in the Live or MovingFunds or Terminated state,
    ///      - The redemption request identified by `walletPubKeyHash` and
    ///        `redeemerOutputScript` must exist,
    ///      - The expression `keccak256(abi.encode(walletMembersIDs))` must
    ///        be exactly the same as the hash stored under `membersIdsHash`
    ///        for the given `walletID`. Those IDs are not directly stored
    ///        in the contract for gas efficiency purposes but they can be
    ///        read from appropriate `DkgResultSubmitted` and `DkgResultApproved`
    ///        events of the `WalletRegistry` contract,
    ///      - The amount of time defined by `redemptionTimeout` must have
    ///        passed since the redemption was requested (the request must be
    ///        timed-out).
    function notifyRedemptionTimeout(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        uint32[] calldata walletMembersIDs,
        bytes calldata redeemerOutputScript
    ) external {
        // Wallet state is validated in `notifyWalletRedemptionTimeout`.
        uint256 redemptionKey = getRedemptionKey(
            walletPubKeyHash,
            redeemerOutputScript
        );
        Redemption.RedemptionRequest memory request = self.pendingRedemptions[
            redemptionKey
        ];

        require(request.requestedAt > 0, "Redemption request does not exist");
        require(
            /* solhint-disable-next-line not-rely-on-time */
            request.requestedAt + self.redemptionTimeout < block.timestamp,
            "Redemption request has not timed out"
        );

        // Update the wallet's pending redemptions value
        Wallets.Wallet storage wallet = self.registeredWallets[
            walletPubKeyHash
        ];
        wallet.pendingRedemptionsValue -=
            request.requestedAmount -
            request.treasuryFee;

        // It is worth noting that there is no need to check if
        // `timedOutRedemption` mapping already contains the given redemption
        // key. There is no possibility to re-use a key of a reported timed-out
        // redemption because the wallet responsible for causing the timeout is
        // moved to a state that prevents it to receive new redemption requests.

        // Propagate timeout consequences to the wallet
        self.notifyWalletRedemptionTimeout(walletPubKeyHash, walletMembersIDs);

        // Move the redemption from pending redemptions to timed-out redemptions
        self.timedOutRedemptions[redemptionKey] = request;
        delete self.pendingRedemptions[redemptionKey];

        // slither-disable-next-line reentrancy-events
        emit RedemptionTimedOut(walletPubKeyHash, redeemerOutputScript);

        // Return the requested amount of tokens to the redeemer
        self.bank.transferBalance(request.redeemer, request.requestedAmount);
    }

    /// @notice Calculate redemption key without allocations.
    /// @param walletPubKeyHash the pubkey hash of the wallet.
    /// @param script the output script of the redemption.
    /// @return The key = keccak256(keccak256(script) | walletPubKeyHash).
    function getRedemptionKey(bytes20 walletPubKeyHash, bytes memory script)
        internal
        pure
        returns (uint256)
    {
        bytes32 scriptHash = keccak256(script);
        uint256 key;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            mstore(0, scriptHash)
            mstore(32, walletPubKeyHash)
            key := keccak256(0, 52)
        }
        return key;
    }

    /// @notice Finish calculating redemption key without allocations.
    /// @param walletPubKeyHash the pubkey hash of the wallet.
    /// @param scriptHash the output script hash of the redemption.
    /// @return The key = keccak256(scriptHash | walletPubKeyHash).
    function _getRedemptionKey(bytes20 walletPubKeyHash, bytes32 scriptHash)
        internal
        pure
        returns (uint256)
    {
        uint256 key;
        /* solhint-disable-next-line no-inline-assembly */
        assembly {
            mstore(0, scriptHash)
            mstore(32, walletPubKeyHash)
            key := keccak256(0, 52)
        }
        return key;
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

import {BTCUtils} from "@keep-network/bitcoin-spv-sol/contracts/BTCUtils.sol";
import {EcdsaDkg} from "@keep-network/ecdsa/contracts/libraries/EcdsaDkg.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import "./BitcoinTx.sol";
import "./EcdsaLib.sol";
import "./BridgeState.sol";

/// @title Wallet library
/// @notice Library responsible for handling integration between Bridge
///         contract and ECDSA wallets.
library Wallets {
    using BTCUtils for bytes;

    /// @notice Represents wallet state:
    enum WalletState {
        /// @dev The wallet is unknown to the Bridge.
        Unknown,
        /// @dev The wallet can sweep deposits and accept redemption requests.
        Live,
        /// @dev The wallet was deemed unhealthy and is expected to move their
        ///      outstanding funds to another wallet. The wallet can still
        ///      fulfill their pending redemption requests although new
        ///      redemption requests and new deposit reveals are not accepted.
        MovingFunds,
        /// @dev The wallet moved or redeemed all their funds and is in the
        ///      closing period where it is still a subject of fraud challenges
        ///      and must defend against them. This state is needed to protect
        ///      against deposit frauds on deposits revealed but not swept.
        ///      The closing period must be greater that the deposit refund
        ///      time plus some time margin.
        Closing,
        /// @dev The wallet finalized the closing period successfully and
        ///      can no longer perform any action in the Bridge.
        Closed,
        /// @dev The wallet committed a fraud that was reported, did not move
        ///      funds to another wallet before a timeout, or did not sweep
        ///      funds moved to if from another wallet before a timeout. The
        ///      wallet is blocked and can not perform any actions in the Bridge.
        ///      Off-chain coordination with the wallet operators is needed to
        ///      recover funds.
        Terminated
    }

    /// @notice Holds information about a wallet.
    struct Wallet {
        // Identifier of a ECDSA Wallet registered in the ECDSA Wallet Registry.
        bytes32 ecdsaWalletID;
        // Latest wallet's main UTXO hash computed as
        // keccak256(txHash | txOutputIndex | txOutputValue). The `tx` prefix
        // refers to the transaction which created that main UTXO. The `txHash`
        // is `bytes32` (ordered as in Bitcoin internally), `txOutputIndex`
        // an `uint32`, and `txOutputValue` an `uint64` value.
        bytes32 mainUtxoHash;
        // The total redeemable value of pending redemption requests targeting
        // that wallet.
        uint64 pendingRedemptionsValue;
        // UNIX timestamp the wallet was created at.
        // XXX: Unsigned 32-bit int unix seconds, will break February 7th 2106.
        uint32 createdAt;
        // UNIX timestamp indicating the moment the wallet was requested to
        // move their funds.
        // XXX: Unsigned 32-bit int unix seconds, will break February 7th 2106.
        uint32 movingFundsRequestedAt;
        // UNIX timestamp indicating the moment the wallet's closing period
        // started.
        // XXX: Unsigned 32-bit int unix seconds, will break February 7th 2106.
        uint32 closingStartedAt;
        // Total count of pending moved funds sweep requests targeting this wallet.
        uint32 pendingMovedFundsSweepRequestsCount;
        // Current state of the wallet.
        WalletState state;
        // Moving funds target wallet commitment submitted by the wallet. It
        // is built by applying the keccak256 hash over the list of 20-byte
        // public key hashes of the target wallets.
        bytes32 movingFundsTargetWalletsCommitmentHash;
        // This struct doesn't contain `__gap` property as the structure is stored
        // in a mapping, mappings store values in different slots and they are
        // not contiguous with other values.
    }

    event NewWalletRequested();

    event NewWalletRegistered(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event WalletMovingFunds(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event WalletClosing(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event WalletClosed(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    event WalletTerminated(
        bytes32 indexed ecdsaWalletID,
        bytes20 indexed walletPubKeyHash
    );

    /// @notice Requests creation of a new wallet. This function just
    ///         forms a request and the creation process is performed
    ///         asynchronously. Outcome of that process should be delivered
    ///         using `registerNewWallet` function.
    /// @param activeWalletMainUtxo Data of the active wallet's main UTXO, as
    ///        currently known on the Ethereum chain.
    /// @dev Requirements:
    ///      - `activeWalletMainUtxo` components must point to the recent main
    ///        UTXO of the given active wallet, as currently known on the
    ///        Ethereum chain. If there is no active wallet at the moment, or
    ///        the active wallet has no main UTXO, this parameter can be
    ///        empty as it is ignored,
    ///      - Wallet creation must not be in progress,
    ///      - If the active wallet is set, one of the following
    ///        conditions must be true:
    ///        - The active wallet BTC balance is above the minimum threshold
    ///          and the active wallet is old enough, i.e. the creation period
    ///           was elapsed since its creation time,
    ///        - The active wallet BTC balance is above the maximum threshold.
    function requestNewWallet(
        BridgeState.Storage storage self,
        BitcoinTx.UTXO calldata activeWalletMainUtxo
    ) external {
        require(
            self.ecdsaWalletRegistry.getWalletCreationState() ==
                EcdsaDkg.State.IDLE,
            "Wallet creation already in progress"
        );

        bytes20 activeWalletPubKeyHash = self.activeWalletPubKeyHash;

        // If the active wallet is set, fetch this wallet's details from
        // storage to perform conditions check. The `registerNewWallet`
        // function guarantees an active wallet is always one of the
        // registered ones.
        if (activeWalletPubKeyHash != bytes20(0)) {
            uint64 activeWalletBtcBalance = getWalletBtcBalance(
                self,
                activeWalletPubKeyHash,
                activeWalletMainUtxo
            );
            uint32 activeWalletCreatedAt = self
                .registeredWallets[activeWalletPubKeyHash]
                .createdAt;
            /* solhint-disable-next-line not-rely-on-time */
            bool activeWalletOldEnough = block.timestamp >=
                activeWalletCreatedAt + self.walletCreationPeriod;

            require(
                (activeWalletOldEnough &&
                    activeWalletBtcBalance >=
                    self.walletCreationMinBtcBalance) ||
                    activeWalletBtcBalance >= self.walletCreationMaxBtcBalance,
                "Wallet creation conditions are not met"
            );
        }

        emit NewWalletRequested();

        self.ecdsaWalletRegistry.requestNewWallet();
    }

    /// @notice Registers a new wallet. This function should be called
    ///         after the wallet creation process initiated using
    ///         `requestNewWallet` completes and brings the outcomes.
    /// @param ecdsaWalletID Wallet's unique identifier.
    /// @param publicKeyX Wallet's public key's X coordinate.
    /// @param publicKeyY Wallet's public key's Y coordinate.
    /// @dev Requirements:
    ///      - The only caller authorized to call this function is `registry`,
    ///      - Given wallet data must not belong to an already registered wallet.
    function registerNewWallet(
        BridgeState.Storage storage self,
        bytes32 ecdsaWalletID,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) external {
        require(
            msg.sender == address(self.ecdsaWalletRegistry),
            "Caller is not the ECDSA Wallet Registry"
        );

        // Compress wallet's public key and calculate Bitcoin's hash160 of it.
        bytes20 walletPubKeyHash = bytes20(
            EcdsaLib.compressPublicKey(publicKeyX, publicKeyY).hash160View()
        );

        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];
        require(
            wallet.state == WalletState.Unknown,
            "ECDSA wallet has been already registered"
        );
        wallet.ecdsaWalletID = ecdsaWalletID;
        wallet.state = WalletState.Live;
        /* solhint-disable-next-line not-rely-on-time */
        wallet.createdAt = uint32(block.timestamp);

        // Set the freshly created wallet as the new active wallet.
        self.activeWalletPubKeyHash = walletPubKeyHash;

        self.liveWalletsCount++;

        emit NewWalletRegistered(ecdsaWalletID, walletPubKeyHash);
    }

    /// @notice Handles a notification about a wallet redemption timeout.
    ///         Triggers the wallet moving funds process only if the wallet is
    ///         still in the Live state. That means multiple action timeouts can
    ///         be reported for the same wallet but only the first report
    ///         requests the wallet to move their funds. Executes slashing if
    ///         the wallet is in Live or MovingFunds state. Allows to notify
    ///         redemption timeout also for a Terminated wallet in case the
    ///         redemption was requested before the wallet got terminated.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @dev Requirements:
    ///      - The wallet must be in the `Live`, `MovingFunds`,
    ///        or `Terminated` state.
    function notifyWalletRedemptionTimeout(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        uint32[] calldata walletMembersIDs
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];
        WalletState walletState = wallet.state;

        require(
            walletState == WalletState.Live ||
                walletState == WalletState.MovingFunds ||
                walletState == WalletState.Terminated,
            "Wallet must be in Live or MovingFunds or Terminated state"
        );

        if (
            walletState == Wallets.WalletState.Live ||
            walletState == Wallets.WalletState.MovingFunds
        ) {
            // Slash the wallet operators and reward the notifier
            self.ecdsaWalletRegistry.seize(
                self.redemptionTimeoutSlashingAmount,
                self.redemptionTimeoutNotifierRewardMultiplier,
                msg.sender,
                wallet.ecdsaWalletID,
                walletMembersIDs
            );
        }

        if (walletState == WalletState.Live) {
            moveFunds(self, walletPubKeyHash);
        }
    }

    /// @notice Handles a notification about a wallet heartbeat failure and
    ///         triggers the wallet moving funds process.
    /// @param publicKeyX Wallet's public key's X coordinate.
    /// @param publicKeyY Wallet's public key's Y coordinate.
    /// @dev Requirements:
    ///      - The only caller authorized to call this function is `registry`,
    ///      - Wallet must be in Live state.
    function notifyWalletHeartbeatFailed(
        BridgeState.Storage storage self,
        bytes32 publicKeyX,
        bytes32 publicKeyY
    ) external {
        require(
            msg.sender == address(self.ecdsaWalletRegistry),
            "Caller is not the ECDSA Wallet Registry"
        );

        // Compress wallet's public key and calculate Bitcoin's hash160 of it.
        bytes20 walletPubKeyHash = bytes20(
            EcdsaLib.compressPublicKey(publicKeyX, publicKeyY).hash160View()
        );

        require(
            self.registeredWallets[walletPubKeyHash].state == WalletState.Live,
            "Wallet must be in Live state"
        );

        moveFunds(self, walletPubKeyHash);
    }

    /// @notice Notifies that the wallet is either old enough or has too few
    ///         satoshis left and qualifies to be closed.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMainUtxo Data of the wallet's main UTXO, as currently
    ///        known on the Ethereum chain.
    /// @dev Requirements:
    ///      - Wallet must not be set as the current active wallet,
    ///      - Wallet must exceed the wallet maximum age OR the wallet BTC
    ///        balance must be lesser than the minimum threshold. If the latter
    ///        case is true, the `walletMainUtxo` components must point to the
    ///        recent main UTXO of the given wallet, as currently known on the
    ///        Ethereum chain. If the wallet has no main UTXO, this parameter
    ///        can be empty as it is ignored since the wallet balance is
    ///        assumed to be zero,
    ///      - Wallet must be in Live state.
    function notifyWalletCloseable(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata walletMainUtxo
    ) external {
        require(
            self.activeWalletPubKeyHash != walletPubKeyHash,
            "Active wallet cannot be considered closeable"
        );

        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];
        require(
            wallet.state == WalletState.Live,
            "Wallet must be in Live state"
        );

        /* solhint-disable-next-line not-rely-on-time */
        bool walletOldEnough = block.timestamp >=
            wallet.createdAt + self.walletMaxAge;

        require(
            walletOldEnough ||
                getWalletBtcBalance(self, walletPubKeyHash, walletMainUtxo) <
                self.walletClosureMinBtcBalance,
            "Wallet needs to be old enough or have too few satoshis"
        );

        moveFunds(self, walletPubKeyHash);
    }

    /// @notice Notifies about the end of the closing period for the given wallet.
    ///         Closes the wallet ultimately and notifies the ECDSA registry
    ///         about this fact.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @dev Requirements:
    ///      - The wallet must be in the Closing state,
    ///      - The wallet closing period must have elapsed.
    function notifyWalletClosingPeriodElapsed(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];

        require(
            wallet.state == WalletState.Closing,
            "Wallet must be in Closing state"
        );

        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp >
                wallet.closingStartedAt + self.walletClosingPeriod,
            "Closing period has not elapsed yet"
        );

        finalizeWalletClosing(self, walletPubKeyHash);
    }

    /// @notice Notifies that the wallet completed the moving funds process
    ///         successfully. Checks if the funds were moved to the expected
    ///         target wallets. Closes the source wallet if everything went
    ///         good and reverts otherwise.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param targetWalletsHash 32-byte keccak256 hash over the list of
    ///        20-byte public key hashes of the target wallets actually used
    ///        within the moving funds transactions.
    /// @dev Requirements:
    ///      - The caller must make sure the moving funds transaction actually
    ///        happened on Bitcoin chain and fits the protocol requirements,
    ///      - The source wallet must be in the MovingFunds state,
    ///      - The target wallets commitment must be submitted by the source
    ///        wallet,
    ///      - The actual target wallets used in the moving funds transaction
    ///        must be exactly the same as the target wallets commitment.
    function notifyWalletFundsMoved(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        bytes32 targetWalletsHash
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];
        // Check that the wallet is in the MovingFunds state but don't check
        // if the moving funds timeout is exceeded. That should give a
        // possibility to move funds in case when timeout was hit but was
        // not reported yet.
        require(
            wallet.state == WalletState.MovingFunds,
            "Wallet must be in MovingFunds state"
        );

        bytes32 targetWalletsCommitmentHash = wallet
            .movingFundsTargetWalletsCommitmentHash;

        require(
            targetWalletsCommitmentHash != bytes32(0),
            "Target wallets commitment not submitted yet"
        );

        // Make sure that the target wallets where funds were moved to are
        // exactly the same as the ones the source wallet committed to.
        require(
            targetWalletsCommitmentHash == targetWalletsHash,
            "Target wallets don't correspond to the commitment"
        );

        // If funds were moved, the wallet has no longer a main UTXO.
        delete wallet.mainUtxoHash;

        beginWalletClosing(self, walletPubKeyHash);
    }

    /// @notice Called when a MovingFunds wallet has a balance below the dust
    ///         threshold. Begins the wallet closing.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @dev Requirements:
    ///      - The wallet must be in the MovingFunds state.
    function notifyWalletMovingFundsBelowDust(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash
    ) internal {
        WalletState walletState = self
            .registeredWallets[walletPubKeyHash]
            .state;

        require(
            walletState == Wallets.WalletState.MovingFunds,
            "Wallet must be in MovingFunds state"
        );

        beginWalletClosing(self, walletPubKeyHash);
    }

    /// @notice Called when the timeout for MovingFunds for the wallet elapsed.
    ///         Slashes wallet members and terminates the wallet.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @dev Requirements:
    ///      - The wallet must be in the MovingFunds state.
    function notifyWalletMovingFundsTimeout(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        uint32[] calldata walletMembersIDs
    ) internal {
        Wallets.Wallet storage wallet = self.registeredWallets[
            walletPubKeyHash
        ];

        require(
            wallet.state == Wallets.WalletState.MovingFunds,
            "Wallet must be in MovingFunds state"
        );

        self.ecdsaWalletRegistry.seize(
            self.movingFundsTimeoutSlashingAmount,
            self.movingFundsTimeoutNotifierRewardMultiplier,
            msg.sender,
            wallet.ecdsaWalletID,
            walletMembersIDs
        );

        terminateWallet(self, walletPubKeyHash);
    }

    /// @notice Called when a wallet which was asked to sweep funds moved from
    ///         another wallet did not provide a sweeping proof before a timeout.
    ///         Slashes and terminates the wallet who failed to provide a proof.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet which was
    ///        supposed to sweep funds.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @dev Requirements:
    ///      - The wallet must be in the `Live`, `MovingFunds`,
    ///        or `Terminated` state.
    function notifyWalletMovedFundsSweepTimeout(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        uint32[] calldata walletMembersIDs
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];
        WalletState walletState = wallet.state;

        require(
            walletState == WalletState.Live ||
                walletState == WalletState.MovingFunds ||
                walletState == WalletState.Terminated,
            "Wallet must be in Live or MovingFunds or Terminated state"
        );

        if (
            walletState == Wallets.WalletState.Live ||
            walletState == Wallets.WalletState.MovingFunds
        ) {
            self.ecdsaWalletRegistry.seize(
                self.movedFundsSweepTimeoutSlashingAmount,
                self.movedFundsSweepTimeoutNotifierRewardMultiplier,
                msg.sender,
                wallet.ecdsaWalletID,
                walletMembersIDs
            );

            terminateWallet(self, walletPubKeyHash);
        }
    }

    /// @notice Called when a wallet which was challenged for a fraud did not
    ///         defeat the challenge before the timeout. Slashes and terminates
    ///         the wallet who failed to defeat the challenge. If the wallet is
    ///         already terminated, it does nothing.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet which was
    ///        supposed to sweep funds.
    /// @param walletMembersIDs Identifiers of the wallet signing group members.
    /// @param challenger Address of the party which submitted the fraud
    ///        challenge.
    /// @dev Requirements:
    ///      - The wallet must be in the `Live`, `MovingFunds`, `Closing`
    ///        or `Terminated` state.
    function notifyWalletFraudChallengeDefeatTimeout(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        uint32[] calldata walletMembersIDs,
        address challenger
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];
        WalletState walletState = wallet.state;

        if (
            walletState == Wallets.WalletState.Live ||
            walletState == Wallets.WalletState.MovingFunds ||
            walletState == Wallets.WalletState.Closing
        ) {
            self.ecdsaWalletRegistry.seize(
                self.fraudSlashingAmount,
                self.fraudNotifierRewardMultiplier,
                challenger,
                wallet.ecdsaWalletID,
                walletMembersIDs
            );

            terminateWallet(self, walletPubKeyHash);
        } else if (walletState == Wallets.WalletState.Terminated) {
            // This is a special case when the wallet was already terminated
            // due to a previous deliberate protocol violation. In that
            // case, this function should be still callable for other fraud
            // challenges timeouts in order to let the challenger unlock its
            // ETH deposit back. However, the wallet termination logic is
            // not called and the challenger is not rewarded.
        } else {
            revert(
                "Wallet must be in Live or MovingFunds or Closing or Terminated state"
            );
        }
    }

    /// @notice Requests a wallet to move their funds. If the wallet balance
    ///         is zero, the wallet closing begins immediately. If the move
    ///         funds request refers to the current active wallet, such a wallet
    ///         is no longer considered active and the active wallet slot
    ///         is unset allowing to trigger a new wallet creation immediately.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @dev Requirements:
    ///      - The caller must make sure that the wallet is in the Live state.
    function moveFunds(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];

        if (wallet.mainUtxoHash == bytes32(0)) {
            // If the wallet has no main UTXO, that means its BTC balance
            // is zero and the wallet closing should begin immediately.
            beginWalletClosing(self, walletPubKeyHash);
        } else {
            // Otherwise, initialize the moving funds process.
            wallet.state = WalletState.MovingFunds;
            /* solhint-disable-next-line not-rely-on-time */
            wallet.movingFundsRequestedAt = uint32(block.timestamp);

            // slither-disable-next-line reentrancy-events
            emit WalletMovingFunds(wallet.ecdsaWalletID, walletPubKeyHash);
        }

        if (self.activeWalletPubKeyHash == walletPubKeyHash) {
            // If the move funds request refers to the current active wallet,
            // unset the active wallet and make the wallet creation process
            // possible in order to get a new healthy active wallet.
            delete self.activeWalletPubKeyHash;
        }

        self.liveWalletsCount--;
    }

    /// @notice Begins the closing period of the given wallet.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @dev Requirements:
    ///      - The caller must make sure that the wallet is in the
    ///        MovingFunds state.
    function beginWalletClosing(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];
        // Initialize the closing period.
        wallet.state = WalletState.Closing;
        /* solhint-disable-next-line not-rely-on-time */
        wallet.closingStartedAt = uint32(block.timestamp);

        // slither-disable-next-line reentrancy-events
        emit WalletClosing(wallet.ecdsaWalletID, walletPubKeyHash);
    }

    /// @notice Finalizes the closing period of the given wallet and notifies
    ///         the ECDSA registry about this fact.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @dev Requirements:
    ///      - The caller must make sure that the wallet is in the Closing state.
    function finalizeWalletClosing(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];

        wallet.state = WalletState.Closed;

        emit WalletClosed(wallet.ecdsaWalletID, walletPubKeyHash);

        self.ecdsaWalletRegistry.closeWallet(wallet.ecdsaWalletID);
    }

    /// @notice Terminates the given wallet and notifies the ECDSA registry
    ///         about this fact. If the wallet termination refers to the current
    ///         active wallet, such a wallet is no longer considered active and
    ///         the active wallet slot is unset allowing to trigger a new wallet
    ///         creation immediately.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @dev Requirements:
    ///      - The caller must make sure that the wallet is in the
    ///        Live or MovingFunds or Closing state.
    function terminateWallet(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash
    ) internal {
        Wallet storage wallet = self.registeredWallets[walletPubKeyHash];

        if (wallet.state == WalletState.Live) {
            self.liveWalletsCount--;
        }

        wallet.state = WalletState.Terminated;

        // slither-disable-next-line reentrancy-events
        emit WalletTerminated(wallet.ecdsaWalletID, walletPubKeyHash);

        if (self.activeWalletPubKeyHash == walletPubKeyHash) {
            // If termination refers to the current active wallet,
            // unset the active wallet and make the wallet creation process
            // possible in order to get a new healthy active wallet.
            delete self.activeWalletPubKeyHash;
        }

        self.ecdsaWalletRegistry.closeWallet(wallet.ecdsaWalletID);
    }

    /// @notice Gets BTC balance for given the wallet.
    /// @param walletPubKeyHash 20-byte public key hash of the wallet.
    /// @param walletMainUtxo Data of the wallet's main UTXO, as currently
    ///        known on the Ethereum chain.
    /// @return walletBtcBalance Current BTC balance for the given wallet.
    /// @dev Requirements:
    ///      - `walletMainUtxo` components must point to the recent main UTXO
    ///        of the given wallet, as currently known on the Ethereum chain.
    ///        If the wallet has no main UTXO, this parameter can be empty as it
    ///        is ignored.
    function getWalletBtcBalance(
        BridgeState.Storage storage self,
        bytes20 walletPubKeyHash,
        BitcoinTx.UTXO calldata walletMainUtxo
    ) internal view returns (uint64 walletBtcBalance) {
        bytes32 walletMainUtxoHash = self
            .registeredWallets[walletPubKeyHash]
            .mainUtxoHash;

        // If the wallet has a main UTXO hash set, cross-check it with the
        // provided plain-text parameter and get the transaction output value
        // as BTC balance. Otherwise, the BTC balance is just zero.
        if (walletMainUtxoHash != bytes32(0)) {
            require(
                keccak256(
                    abi.encodePacked(
                        walletMainUtxo.txHash,
                        walletMainUtxo.txOutputIndex,
                        walletMainUtxo.txOutputValue
                    )
                ) == walletMainUtxoHash,
                "Invalid wallet main UTXO data"
            );

            walletBtcBalance = walletMainUtxo.txOutputValue;
        }

        return walletBtcBalance;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

library GovernanceUtils {
    /// @notice Reverts if the governance delay has not passed since
    ///         the change initiated time or if the change has not been
    ///         initiated.
    /// @param changeInitiatedTimestamp The timestamp at which the change has
    ///        been initiated.
    /// @param delay Governance delay.
    function onlyAfterGovernanceDelay(
        uint256 changeInitiatedTimestamp,
        uint256 delay
    ) internal view {
        require(changeInitiatedTimestamp > 0, "Change not initiated");
        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp - changeInitiatedTimestamp >= delay,
            "Governance delay has not elapsed"
        );
    }

    /// @notice Gets the time remaining until the governable parameter update
    ///         can be committed.
    /// @param changeInitiatedTimestamp Timestamp indicating the beginning of
    ///        the change.
    /// @param delay Governance delay.
    /// @return Remaining time in seconds.
    function getRemainingGovernanceDelay(
        uint256 changeInitiatedTimestamp,
        uint256 delay
    ) internal view returns (uint256) {
        require(changeInitiatedTimestamp > 0, "Change not initiated");
        /* solhint-disable-next-line not-rely-on-time */
        uint256 elapsed = block.timestamp - changeInitiatedTimestamp;
        if (elapsed >= delay) {
            return 0;
        } else {
            return delay - elapsed;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "@thesis/solidity-contracts/contracts/token/ERC20WithPermit.sol";
import "@thesis/solidity-contracts/contracts/token/MisfundRecovery.sol";

contract TBTC is ERC20WithPermit, MisfundRecovery {
    constructor() ERC20WithPermit("tBTC v2", "tBTC") {}
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

import "../bank/IReceiveBalanceApproval.sol";

/// @title Bank Vault interface
/// @notice `IVault` is an interface for a smart contract consuming Bank
///         balances of other contracts or externally owned accounts (EOA).
interface IVault is IReceiveBalanceApproval {
    /// @notice Called by the Bank in `increaseBalanceAndCall` function after
    ///         increasing the balance in the Bank for the vault. It happens in
    ///         the same transaction in which deposits were swept by the Bridge.
    ///         This allows the depositor to route their deposit revealed to the
    ///         Bridge to the particular smart contract (vault) in the same
    ///         transaction in which the deposit is revealed. This way, the
    ///         depositor does not have to execute additional transaction after
    ///         the deposit gets swept by the Bridge to approve and transfer
    ///         their balance to the vault.
    /// @param depositors Addresses of depositors whose deposits have been swept.
    /// @param depositedAmounts Amounts deposited by individual depositors and
    ///        swept.
    /// @dev The implementation must ensure this function can only be called
    ///      by the Bank. The Bank guarantees that the vault's balance was
    ///      increased by the sum of all deposited amounts before this function
    ///      is called, in the same transaction.
    function receiveBalanceIncrease(
        address[] calldata depositors,
        uint256[] calldata depositedAmounts
    ) external;
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

import "../bridge/Bridge.sol";
import "../bridge/Deposit.sol";
import "../GovernanceUtils.sol";

/// @title TBTC Optimistic Minting
/// @notice The Optimistic Minting mechanism allows to mint TBTC before
///         `TBTCVault` receives the Bank balance. There are two permissioned
///         sets in the system: Minters and Guardians, both set up in 1-of-n
///         mode. Minters observe the revealed deposits and request minting TBTC.
///         Any single Minter can perform this action. There is an
///         `optimisticMintingDelay` between the time of the request from
///         a Minter to the time TBTC is minted. During the time of the delay,
///         any Guardian can cancel the minting.
/// @dev This functionality is a part of `TBTCVault`. It is implemented in
///      a separate abstract contract to achieve better separation of concerns
///      and easier-to-follow code.
abstract contract TBTCOptimisticMinting is Ownable {
    // Represents optimistic minting request for the given deposit revealed
    // to the Bridge.
    struct OptimisticMintingRequest {
        // UNIX timestamp at which the optimistic minting was requested.
        uint64 requestedAt;
        // UNIX timestamp at which the optimistic minting was finalized.
        // 0 if not yet finalized.
        uint64 finalizedAt;
    }

    /// @notice The time delay that needs to pass between initializing and
    ///         finalizing the upgrade of governable parameters.
    uint256 public constant GOVERNANCE_DELAY = 24 hours;

    /// @notice Multiplier to convert satoshi to TBTC token units.
    uint256 public constant SATOSHI_MULTIPLIER = 10**10;

    Bridge public immutable bridge;

    /// @notice Indicates if the optimistic minting has been paused. Only the
    ///         Governance can pause optimistic minting. Note that the pause of
    ///         the optimistic minting does not stop the standard minting flow
    ///         where wallets sweep deposits.
    bool public isOptimisticMintingPaused;

    /// @notice Divisor used to compute the treasury fee taken from each
    ///         optimistically minted deposit and transferred to the treasury
    ///         upon finalization of the optimistic mint. This fee is computed
    ///         as follows: `fee = amount / optimisticMintingFeeDivisor`.
    ///         For example, if the fee needs to be 2%, the
    ///         `optimisticMintingFeeDivisor` should be set to `50` because
    ///         `1/50 = 0.02 = 2%`.
    ///         The optimistic minting fee does not replace the deposit treasury
    ///         fee cut by the Bridge. The optimistic fee is a percentage AFTER
    ///         the treasury fee is cut:
    ///         `optimisticMintingFee = (depositAmount - treasuryFee) / optimisticMintingFeeDivisor`
    uint32 public optimisticMintingFeeDivisor = 500; // 1/500 = 0.002 = 0.2%

    /// @notice The time that needs to pass between the moment the optimistic
    ///         minting is requested and the moment optimistic minting is
    ///         finalized with minting TBTC.
    uint32 public optimisticMintingDelay = 3 hours;

    /// @notice Indicates if the given address is a Minter. Only Minters can
    ///         request optimistic minting.
    mapping(address => bool) public isMinter;

    /// @notice List of all Minters.
    /// @dev May be used to establish an order in which the Minters should
    ///      request for an optimistic minting.
    address[] public minters;

    /// @notice Indicates if the given address is a Guardian. Only Guardians can
    ///         cancel requested optimistic minting.
    mapping(address => bool) public isGuardian;

    /// @notice Collection of all revealed deposits for which the optimistic
    ///         minting was requested. Indexed by a deposit key computed as
    ///         `keccak256(fundingTxHash | fundingOutputIndex)`.
    mapping(uint256 => OptimisticMintingRequest)
        public optimisticMintingRequests;

    /// @notice Optimistic minting debt value per depositor's address. The debt
    ///         represents the total value of all depositor's deposits revealed
    ///         to the Bridge that has not been yet swept and led to the
    ///         optimistic minting of TBTC. When `TBTCVault` sweeps a deposit,
    ///         the debt is fully or partially paid off, no matter if that
    ///         particular swept deposit was used for the optimistic minting or
    ///         not. The values are in 1e18 Ethereum precision.
    mapping(address => uint256) public optimisticMintingDebt;

    /// @notice New optimistic minting fee divisor value. Set only when the
    ///         parameter update process is pending. Once the update gets
    //          finalized, this will be the value of the divisor.
    uint32 public newOptimisticMintingFeeDivisor;
    /// @notice The timestamp at which the update of the optimistic minting fee
    ///         divisor started. Zero if update is not in progress.
    uint256 public optimisticMintingFeeUpdateInitiatedTimestamp;

    /// @notice New optimistic minting delay value. Set only when the parameter
    ///         update process is pending. Once the update gets finalized, this
    //          will be the value of the delay.
    uint32 public newOptimisticMintingDelay;
    /// @notice The timestamp at which the update of the optimistic minting
    ///         delay started. Zero if update is not in progress.
    uint256 public optimisticMintingDelayUpdateInitiatedTimestamp;

    event OptimisticMintingRequested(
        address indexed minter,
        uint256 indexed depositKey,
        address indexed depositor,
        uint256 amount, // amount in 1e18 Ethereum precision
        bytes32 fundingTxHash,
        uint32 fundingOutputIndex
    );
    event OptimisticMintingFinalized(
        address indexed minter,
        uint256 indexed depositKey,
        address indexed depositor,
        uint256 optimisticMintingDebt
    );
    event OptimisticMintingCancelled(
        address indexed guardian,
        uint256 indexed depositKey
    );
    event OptimisticMintingDebtRepaid(
        address indexed depositor,
        uint256 optimisticMintingDebt
    );
    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event GuardianAdded(address indexed guardian);
    event GuardianRemoved(address indexed guardian);
    event OptimisticMintingPaused();
    event OptimisticMintingUnpaused();

    event OptimisticMintingFeeUpdateStarted(
        uint32 newOptimisticMintingFeeDivisor
    );
    event OptimisticMintingFeeUpdated(uint32 newOptimisticMintingFeeDivisor);

    event OptimisticMintingDelayUpdateStarted(uint32 newOptimisticMintingDelay);
    event OptimisticMintingDelayUpdated(uint32 newOptimisticMintingDelay);

    modifier onlyMinter() {
        require(isMinter[msg.sender], "Caller is not a minter");
        _;
    }

    modifier onlyGuardian() {
        require(isGuardian[msg.sender], "Caller is not a guardian");
        _;
    }

    modifier onlyOwnerOrGuardian() {
        require(
            owner() == msg.sender || isGuardian[msg.sender],
            "Caller is not the owner or guardian"
        );
        _;
    }

    modifier whenOptimisticMintingNotPaused() {
        require(!isOptimisticMintingPaused, "Optimistic minting paused");
        _;
    }

    modifier onlyAfterGovernanceDelay(uint256 updateInitiatedTimestamp) {
        GovernanceUtils.onlyAfterGovernanceDelay(
            updateInitiatedTimestamp,
            GOVERNANCE_DELAY
        );
        _;
    }

    constructor(Bridge _bridge) {
        require(
            address(_bridge) != address(0),
            "Bridge can not be the zero address"
        );

        bridge = _bridge;
    }

    /// @dev Mints the given amount of TBTC to the given depositor's address.
    ///      Implemented by TBTCVault.
    function _mint(address minter, uint256 amount) internal virtual;

    /// @notice Allows to fetch a list of all Minters.
    function getMinters() external view returns (address[] memory) {
        return minters;
    }

    /// @notice Allows a Minter to request for an optimistic minting of TBTC.
    ///         The following conditions must be met:
    ///         - There is no optimistic minting request for the deposit,
    ///           finalized or not.
    ///         - The deposit with the given Bitcoin funding transaction hash
    ///           and output index has been revealed to the Bridge.
    ///         - The deposit has not been swept yet.
    ///         - The deposit is targeted into the TBTCVault.
    ///         - The optimistic minting is not paused.
    ///         After calling this function, the Minter has to wait for
    ///         `optimisticMintingDelay` before finalizing the mint with a call
    ///         to finalizeOptimisticMint.
    /// @dev The deposit done on the Bitcoin side must be revealed early enough
    ///      to the Bridge on Ethereum to pass the Bridge's validation. The
    ///      validation passes successfully only if the deposit reveal is done
    ///      respectively earlier than the moment when the deposit refund
    ///      locktime is reached, i.e. the deposit becomes refundable. It may
    ///      happen that the wallet does not sweep a revealed deposit and one of
    ///      the Minters requests an optimistic mint for that deposit just
    ///      before the locktime is reached. Guardians must cancel optimistic
    ///      minting for this deposit because the wallet will not be able to
    ///      sweep it. The on-chain optimistic minting code does not perform any
    ///      validation for gas efficiency: it would have to perform the same
    ///      validation as `validateDepositRefundLocktime` and expect the entire
    ///      `DepositRevealInfo` to be passed to assemble the expected script
    ///      hash on-chain. Guardians must validate if the deposit happened on
    ///      Bitcoin, that the script hash has the expected format, and that the
    ///      wallet is an active one so they can also validate the time left for
    ///      the refund.
    function requestOptimisticMint(
        bytes32 fundingTxHash,
        uint32 fundingOutputIndex
    ) external onlyMinter whenOptimisticMintingNotPaused {
        uint256 depositKey = calculateDepositKey(
            fundingTxHash,
            fundingOutputIndex
        );

        OptimisticMintingRequest storage request = optimisticMintingRequests[
            depositKey
        ];
        require(
            request.requestedAt == 0,
            "Optimistic minting already requested for the deposit"
        );

        Deposit.DepositRequest memory deposit = bridge.deposits(depositKey);

        require(deposit.revealedAt != 0, "The deposit has not been revealed");
        require(deposit.sweptAt == 0, "The deposit is already swept");
        require(deposit.vault == address(this), "Unexpected vault address");

        /* solhint-disable-next-line not-rely-on-time */
        request.requestedAt = uint64(block.timestamp);

        emit OptimisticMintingRequested(
            msg.sender,
            depositKey,
            deposit.depositor,
            deposit.amount * SATOSHI_MULTIPLIER,
            fundingTxHash,
            fundingOutputIndex
        );
    }

    /// @notice Allows a Minter to finalize previously requested optimistic
    ///         minting. The following conditions must be met:
    ///         - The optimistic minting has been requested for the given
    ///           deposit.
    ///         - The deposit has not been swept yet.
    ///         - At least `optimisticMintingDelay` passed since the optimistic
    ///           minting was requested for the given deposit.
    ///         - The optimistic minting has not been finalized earlier for the
    ///           given deposit.
    ///         - The optimistic minting request for the given deposit has not
    ///           been canceled by a Guardian.
    ///         - The optimistic minting is not paused.
    ///         This function mints TBTC and increases `optimisticMintingDebt`
    ///         for the given depositor. The optimistic minting request is
    ///         marked as finalized.
    function finalizeOptimisticMint(
        bytes32 fundingTxHash,
        uint32 fundingOutputIndex
    ) external onlyMinter whenOptimisticMintingNotPaused {
        uint256 depositKey = calculateDepositKey(
            fundingTxHash,
            fundingOutputIndex
        );

        OptimisticMintingRequest storage request = optimisticMintingRequests[
            depositKey
        ];
        require(
            request.requestedAt != 0,
            "Optimistic minting not requested for the deposit"
        );
        require(
            request.finalizedAt == 0,
            "Optimistic minting already finalized for the deposit"
        );

        require(
            /* solhint-disable-next-line not-rely-on-time */
            block.timestamp > request.requestedAt + optimisticMintingDelay,
            "Optimistic minting delay has not passed yet"
        );

        Deposit.DepositRequest memory deposit = bridge.deposits(depositKey);
        require(deposit.sweptAt == 0, "The deposit is already swept");

        // Bridge, when sweeping, cuts a deposit treasury fee and splits
        // Bitcoin miner fee for the sweep transaction evenly between the
        // depositors in the sweep.
        //
        // When tokens are optimistically minted, we do not know what the
        // Bitcoin miner fee for the sweep transaction will look like.
        // The Bitcoin miner fee is ignored. When sweeping, the miner fee is
        // subtracted so the optimisticMintingDebt may stay non-zero after the
        // deposit is swept.
        //
        // This imbalance is supposed to be solved by a donation to the Bridge.
        uint256 amountToMint = (deposit.amount - deposit.treasuryFee) *
            SATOSHI_MULTIPLIER;

        // The Optimistic Minting mechanism may additionally cut a fee from the
        // amount that is left after deducting the Bridge deposit treasury fee.
        // Think of this fee as an extra payment for faster processing of
        // deposits. One does not need to use the Optimistic Minting mechanism
        // and they may wait for the Bridge to sweep their deposit if they do
        // not want to pay the Optimistic Minting fee.
        uint256 optimisticMintFee = optimisticMintingFeeDivisor > 0
            ? (amountToMint / optimisticMintingFeeDivisor)
            : 0;

        // Both the optimistic minting fee and the share that goes to the
        // depositor are optimistically minted. All TBTC that is optimistically
        // minted should be added to the optimistic minting debt. When the
        // deposit is swept, it is paying off both the depositor's share and the
        // treasury's share (optimistic minting fee).
        uint256 newDebt = optimisticMintingDebt[deposit.depositor] +
            amountToMint;
        optimisticMintingDebt[deposit.depositor] = newDebt;

        _mint(deposit.depositor, amountToMint - optimisticMintFee);
        if (optimisticMintFee > 0) {
            _mint(bridge.treasury(), optimisticMintFee);
        }

        /* solhint-disable-next-line not-rely-on-time */
        request.finalizedAt = uint64(block.timestamp);

        emit OptimisticMintingFinalized(
            msg.sender,
            depositKey,
            deposit.depositor,
            newDebt
        );
    }

    /// @notice Allows a Guardian to cancel optimistic minting request. The
    ///         following conditions must be met:
    ///         - The optimistic minting request for the given deposit exists.
    ///         - The optimistic minting request for the given deposit has not
    ///           been finalized yet.
    ///         Optimistic minting request is removed. It is possible to request
    ///         optimistic minting again for the same deposit later.
    /// @dev Guardians must validate the following conditions for every deposit
    ///      for which the optimistic minting was requested:
    ///      - The deposit happened on Bitcoin side and it has enough
    ///        confirmations.
    ///      - The optimistic minting has been requested early enough so that
    ///        the wallet has enough time to sweep the deposit.
    ///      - The wallet is an active one and it does perform sweeps or it will
    ///        perform sweeps once the sweeps are activated.
    function cancelOptimisticMint(
        bytes32 fundingTxHash,
        uint32 fundingOutputIndex
    ) external onlyGuardian {
        uint256 depositKey = calculateDepositKey(
            fundingTxHash,
            fundingOutputIndex
        );

        OptimisticMintingRequest storage request = optimisticMintingRequests[
            depositKey
        ];
        require(
            request.requestedAt != 0,
            "Optimistic minting not requested for the deposit"
        );
        require(
            request.finalizedAt == 0,
            "Optimistic minting already finalized for the deposit"
        );

        // Delete it. It allows to request optimistic minting for the given
        // deposit again. Useful in case of an errant Guardian.
        delete optimisticMintingRequests[depositKey];

        emit OptimisticMintingCancelled(msg.sender, depositKey);
    }

    /// @notice Adds the address to the Minter list.
    function addMinter(address minter) external onlyOwner {
        require(!isMinter[minter], "This address is already a minter");
        isMinter[minter] = true;
        minters.push(minter);
        emit MinterAdded(minter);
    }

    /// @notice Removes the address from the Minter list.
    function removeMinter(address minter) external onlyOwnerOrGuardian {
        require(isMinter[minter], "This address is not a minter");
        delete isMinter[minter];

        // We do not expect too many Minters so a simple loop is safe.
        for (uint256 i = 0; i < minters.length; i++) {
            if (minters[i] == minter) {
                minters[i] = minters[minters.length - 1];
                // slither-disable-next-line costly-loop
                minters.pop();
                break;
            }
        }

        emit MinterRemoved(minter);
    }

    /// @notice Adds the address to the Guardian set.
    function addGuardian(address guardian) external onlyOwner {
        require(!isGuardian[guardian], "This address is already a guardian");
        isGuardian[guardian] = true;
        emit GuardianAdded(guardian);
    }

    /// @notice Removes the address from the Guardian set.
    function removeGuardian(address guardian) external onlyOwner {
        require(isGuardian[guardian], "This address is not a guardian");
        delete isGuardian[guardian];
        emit GuardianRemoved(guardian);
    }

    /// @notice Pauses the optimistic minting. Note that the pause of the
    ///         optimistic minting does not stop the standard minting flow
    ///         where wallets sweep deposits.
    function pauseOptimisticMinting() external onlyOwner {
        require(
            !isOptimisticMintingPaused,
            "Optimistic minting already paused"
        );
        isOptimisticMintingPaused = true;
        emit OptimisticMintingPaused();
    }

    /// @notice Unpauses the optimistic minting.
    function unpauseOptimisticMinting() external onlyOwner {
        require(isOptimisticMintingPaused, "Optimistic minting is not paused");
        isOptimisticMintingPaused = false;
        emit OptimisticMintingUnpaused();
    }

    /// @notice Begins the process of updating optimistic minting fee.
    ///         The fee is computed as follows:
    ///         `fee = amount / optimisticMintingFeeDivisor`.
    ///         For example, if the fee needs to be 2% of each deposit,
    ///         the `optimisticMintingFeeDivisor` should be set to `50` because
    ///         `1/50 = 0.02 = 2%`.
    /// @dev See the documentation for optimisticMintingFeeDivisor.
    function beginOptimisticMintingFeeUpdate(
        uint32 _newOptimisticMintingFeeDivisor
    ) external onlyOwner {
        /* solhint-disable-next-line not-rely-on-time */
        optimisticMintingFeeUpdateInitiatedTimestamp = block.timestamp;
        newOptimisticMintingFeeDivisor = _newOptimisticMintingFeeDivisor;
        emit OptimisticMintingFeeUpdateStarted(_newOptimisticMintingFeeDivisor);
    }

    /// @notice Finalizes the update process of the optimistic minting fee.
    function finalizeOptimisticMintingFeeUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(optimisticMintingFeeUpdateInitiatedTimestamp)
    {
        optimisticMintingFeeDivisor = newOptimisticMintingFeeDivisor;
        emit OptimisticMintingFeeUpdated(newOptimisticMintingFeeDivisor);

        newOptimisticMintingFeeDivisor = 0;
        optimisticMintingFeeUpdateInitiatedTimestamp = 0;
    }

    /// @notice Begins the process of updating optimistic minting delay.
    function beginOptimisticMintingDelayUpdate(
        uint32 _newOptimisticMintingDelay
    ) external onlyOwner {
        /* solhint-disable-next-line not-rely-on-time */
        optimisticMintingDelayUpdateInitiatedTimestamp = block.timestamp;
        newOptimisticMintingDelay = _newOptimisticMintingDelay;
        emit OptimisticMintingDelayUpdateStarted(_newOptimisticMintingDelay);
    }

    /// @notice Finalizes the update process of the optimistic minting delay.
    function finalizeOptimisticMintingDelayUpdate()
        external
        onlyOwner
        onlyAfterGovernanceDelay(optimisticMintingDelayUpdateInitiatedTimestamp)
    {
        optimisticMintingDelay = newOptimisticMintingDelay;
        emit OptimisticMintingDelayUpdated(newOptimisticMintingDelay);

        newOptimisticMintingDelay = 0;
        optimisticMintingDelayUpdateInitiatedTimestamp = 0;
    }

    /// @notice Calculates deposit key the same way as the Bridge contract.
    ///         The deposit key is computed as
    ///         `keccak256(fundingTxHash | fundingOutputIndex)`.
    function calculateDepositKey(
        bytes32 fundingTxHash,
        uint32 fundingOutputIndex
    ) public pure returns (uint256) {
        return
            uint256(
                keccak256(abi.encodePacked(fundingTxHash, fundingOutputIndex))
            );
    }

    /// @notice Used by `TBTCVault.receiveBalanceIncrease` to repay the optimistic
    ///         minting debt before TBTC is minted. When optimistic minting is
    ///         finalized, debt equal to the value of the deposit being
    ///         a subject of the optimistic minting is incurred. When `TBTCVault`
    ///         sweeps a deposit, the debt is fully or partially paid off, no
    ///         matter if that particular deposit was used for the optimistic
    ///         minting or not.
    /// @dev See `TBTCVault.receiveBalanceIncrease`
    /// @param depositor The depositor whose balance increase is received.
    /// @param amount The balance increase amount for the depositor received.
    /// @return The TBTC amount that should be minted after paying off the
    ///         optimistic minting debt.
    function repayOptimisticMintingDebt(address depositor, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 debt = optimisticMintingDebt[depositor];
        if (debt == 0) {
            return amount;
        }

        if (amount > debt) {
            optimisticMintingDebt[depositor] = 0;
            emit OptimisticMintingDebtRepaid(depositor, 0);
            return amount - debt;
        } else {
            optimisticMintingDebt[depositor] = debt - amount;
            emit OptimisticMintingDebtRepaid(depositor, debt - amount);
            return 0;
        }
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

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IVault.sol";
import "./TBTCOptimisticMinting.sol";
import "../bank/Bank.sol";
import "../token/TBTC.sol";

/// @title TBTC application vault
/// @notice TBTC is a fully Bitcoin-backed ERC-20 token pegged to the price of
///         Bitcoin. It facilitates Bitcoin holders to act on the Ethereum
///         blockchain and access the decentralized finance (DeFi) ecosystem.
///         TBTC Vault mints and unmints TBTC based on Bitcoin balances in the
///         Bank.
/// @dev TBTC Vault is the owner of TBTC token contract and is the only contract
///      minting the token.
contract TBTCVault is IVault, Ownable, TBTCOptimisticMinting {
    using SafeERC20 for IERC20;

    Bank public immutable bank;
    TBTC public immutable tbtcToken;

    /// @notice The address of a new TBTC vault. Set only when the upgrade
    ///         process is pending. Once the upgrade gets finalized, the new
    ///         TBTC vault will become an owner of TBTC token.
    address public newVault;
    /// @notice The timestamp at which an upgrade to a new TBTC vault was
    ///         initiated. Set only when the upgrade process is pending.
    uint256 public upgradeInitiatedTimestamp;

    event Minted(address indexed to, uint256 amount);
    event Unminted(address indexed from, uint256 amount);

    event UpgradeInitiated(address newVault, uint256 timestamp);
    event UpgradeFinalized(address newVault);

    modifier onlyBank() {
        require(msg.sender == address(bank), "Caller is not the Bank");
        _;
    }

    constructor(
        Bank _bank,
        TBTC _tbtcToken,
        Bridge _bridge
    ) TBTCOptimisticMinting(_bridge) {
        require(
            address(_bank) != address(0),
            "Bank can not be the zero address"
        );

        require(
            address(_tbtcToken) != address(0),
            "TBTC token can not be the zero address"
        );

        bank = _bank;
        tbtcToken = _tbtcToken;
    }

    /// @notice Mints the given `amount` of TBTC to the caller previously
    ///         transferring `amount / SATOSHI_MULTIPLIER` of the Bank balance
    ///         from caller to TBTC Vault. If `amount` is not divisible by
    ///         SATOSHI_MULTIPLIER, the remainder is left on the caller's
    ///         Bank balance.
    /// @dev TBTC Vault must have an allowance for caller's balance in the
    ///      Bank for at least `amount / SATOSHI_MULTIPLIER`.
    /// @param amount Amount of TBTC to mint.
    function mint(uint256 amount) external {
        (uint256 convertibleAmount, , uint256 satoshis) = amountToSatoshis(
            amount
        );

        require(
            bank.balanceOf(msg.sender) >= satoshis,
            "Amount exceeds balance in the bank"
        );
        _mint(msg.sender, convertibleAmount);
        bank.transferBalanceFrom(msg.sender, address(this), satoshis);
    }

    /// @notice Transfers `satoshis` of the Bank balance from the caller
    ///         to TBTC Vault and mints `satoshis * SATOSHI_MULTIPLIER` of TBTC
    ///         to the caller.
    /// @dev Can only be called by the Bank via `approveBalanceAndCall`.
    /// @param owner The owner who approved their Bank balance.
    /// @param satoshis Amount of satoshis used to mint TBTC.
    function receiveBalanceApproval(
        address owner,
        uint256 satoshis,
        bytes calldata
    ) external override onlyBank {
        require(
            bank.balanceOf(owner) >= satoshis,
            "Amount exceeds balance in the bank"
        );
        _mint(owner, satoshis * SATOSHI_MULTIPLIER);
        bank.transferBalanceFrom(owner, address(this), satoshis);
    }

    /// @notice Mints the same amount of TBTC as the deposited satoshis amount
    ///         multiplied by SATOSHI_MULTIPLIER for each depositor in the array.
    ///         Can only be called by the Bank after the Bridge swept deposits
    ///         and Bank increased balance for the vault.
    /// @dev Fails if `depositors` array is empty. Expects the length of
    ///      `depositors` and `depositedSatoshiAmounts` is the same.
    function receiveBalanceIncrease(
        address[] calldata depositors,
        uint256[] calldata depositedSatoshiAmounts
    ) external override onlyBank {
        require(depositors.length != 0, "No depositors specified");
        for (uint256 i = 0; i < depositors.length; i++) {
            address depositor = depositors[i];
            uint256 satoshis = depositedSatoshiAmounts[i];
            _mint(
                depositor,
                repayOptimisticMintingDebt(
                    depositor,
                    satoshis * SATOSHI_MULTIPLIER
                )
            );
        }
    }

    /// @notice Burns `amount` of TBTC from the caller's balance and transfers
    ///         `amount / SATOSHI_MULTIPLIER` back to the caller's balance in
    ///         the Bank. If `amount` is not divisible by SATOSHI_MULTIPLIER,
    ///         the remainder is left on the caller's account.
    /// @dev Caller must have at least `amount` of TBTC approved to
    ///       TBTC Vault.
    /// @param amount Amount of TBTC to unmint.
    function unmint(uint256 amount) external {
        (uint256 convertibleAmount, , ) = amountToSatoshis(amount);

        _unmint(msg.sender, convertibleAmount);
    }

    /// @notice Burns `amount` of TBTC from the caller's balance and transfers
    ///        `amount / SATOSHI_MULTIPLIER` of Bank balance to the Bridge
    ///         requesting redemption based on the provided `redemptionData`.
    ///         If `amount` is not divisible by SATOSHI_MULTIPLIER, the
    ///         remainder is left on the caller's account.
    /// @dev Caller must have at least `amount` of TBTC approved to
    ///       TBTC Vault.
    /// @param amount Amount of TBTC to unmint and request to redeem in Bridge.
    /// @param redemptionData Redemption data in a format expected from
    ///        `redemptionData` parameter of Bridge's `receiveBalanceApproval`
    ///        function.
    function unmintAndRedeem(uint256 amount, bytes calldata redemptionData)
        external
    {
        (uint256 convertibleAmount, , ) = amountToSatoshis(amount);

        _unmintAndRedeem(msg.sender, convertibleAmount, redemptionData);
    }

    /// @notice Burns `amount` of TBTC from the caller's balance. If `extraData`
    ///         is empty, transfers `amount` back to the caller's balance in the
    ///         Bank. If `extraData` is not empty, requests redemption in the
    ///         Bridge using the `extraData` as a `redemptionData` parameter to
    ///         Bridge's `receiveBalanceApproval` function.
    ///         If `amount` is not divisible by SATOSHI_MULTIPLIER, the
    ///         remainder is left on the caller's account. Note that it may
    ///         left a token approval equal to the remainder.
    /// @dev This function is doing the same as `unmint` or `unmintAndRedeem`
    ///      (depending on `extraData` parameter) but it allows to execute
    ///      unminting without a separate approval transaction. The function can
    ///      be called only via `approveAndCall` of TBTC token.
    /// @param from TBTC token holder executing unminting.
    /// @param amount Amount of TBTC to unmint.
    /// @param token TBTC token address.
    /// @param extraData Redemption data in a format expected from
    ///        `redemptionData` parameter of Bridge's `receiveBalanceApproval`
    ///        function. If empty, `receiveApproval` is not requesting a
    ///        redemption of Bank balance but is instead performing just TBTC
    ///        unminting to a Bank balance.
    function receiveApproval(
        address from,
        uint256 amount,
        address token,
        bytes calldata extraData
    ) external {
        require(token == address(tbtcToken), "Token is not TBTC");
        require(msg.sender == token, "Only TBTC caller allowed");
        (uint256 convertibleAmount, , ) = amountToSatoshis(amount);
        if (extraData.length == 0) {
            _unmint(from, convertibleAmount);
        } else {
            _unmintAndRedeem(from, convertibleAmount, extraData);
        }
    }

    /// @notice Initiates vault upgrade process. The upgrade process needs to be
    ///         finalized with a call to `finalizeUpgrade` function after the
    ///         `UPGRADE_GOVERNANCE_DELAY` passes. Only the governance can
    ///         initiate the upgrade.
    /// @param _newVault The new vault address.
    function initiateUpgrade(address _newVault) external onlyOwner {
        require(_newVault != address(0), "New vault address cannot be zero");
        /* solhint-disable-next-line not-rely-on-time */
        emit UpgradeInitiated(_newVault, block.timestamp);
        /* solhint-disable-next-line not-rely-on-time */
        upgradeInitiatedTimestamp = block.timestamp;
        newVault = _newVault;
    }

    /// @notice Allows the governance to finalize vault upgrade process. The
    ///         upgrade process needs to be first initiated with a call to
    ///         `initiateUpgrade` and the `GOVERNANCE_DELAY` needs to pass.
    ///         Once the upgrade is finalized, the new vault becomes the owner
    ///         of the TBTC token and receives the whole Bank balance of this
    ///         vault.
    function finalizeUpgrade()
        external
        onlyOwner
        onlyAfterGovernanceDelay(upgradeInitiatedTimestamp)
    {
        emit UpgradeFinalized(newVault);
        // slither-disable-next-line reentrancy-no-eth
        tbtcToken.transferOwnership(newVault);
        bank.transferBalance(newVault, bank.balanceOf(address(this)));
        newVault = address(0);
        upgradeInitiatedTimestamp = 0;
    }

    /// @notice Allows the governance of the TBTCVault to recover any ERC20
    ///         token sent mistakenly to the TBTC token contract address.
    /// @param token Address of the recovered ERC20 token contract.
    /// @param recipient Address the recovered token should be sent to.
    /// @param amount Recovered amount.
    function recoverERC20FromToken(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        tbtcToken.recoverERC20(token, recipient, amount);
    }

    /// @notice Allows the governance of the TBTCVault to recover any ERC721
    ///         token sent mistakenly to the TBTC token contract address.
    /// @param token Address of the recovered ERC721 token contract.
    /// @param recipient Address the recovered token should be sent to.
    /// @param tokenId Identifier of the recovered token.
    /// @param data Additional data.
    function recoverERC721FromToken(
        IERC721 token,
        address recipient,
        uint256 tokenId,
        bytes calldata data
    ) external onlyOwner {
        tbtcToken.recoverERC721(token, recipient, tokenId, data);
    }

    /// @notice Allows the governance of the TBTCVault to recover any ERC20
    ///         token sent - mistakenly or not - to the vault address. This
    ///         function should be used to withdraw TBTC v1 tokens transferred
    ///         to TBTCVault as a result of VendingMachine > TBTCVault upgrade.
    /// @param token Address of the recovered ERC20 token contract.
    /// @param recipient Address the recovered token should be sent to.
    /// @param amount Recovered amount.
    function recoverERC20(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        token.safeTransfer(recipient, amount);
    }

    /// @notice Allows the governance of the TBTCVault to recover any ERC721
    ///         token sent mistakenly to the vault address.
    /// @param token Address of the recovered ERC721 token contract.
    /// @param recipient Address the recovered token should be sent to.
    /// @param tokenId Identifier of the recovered token.
    /// @param data Additional data.
    function recoverERC721(
        IERC721 token,
        address recipient,
        uint256 tokenId,
        bytes calldata data
    ) external onlyOwner {
        token.safeTransferFrom(address(this), recipient, tokenId, data);
    }

    /// @notice Returns the amount of TBTC to be minted/unminted, the remainder,
    ///         and the Bank balance to be transferred for the given mint/unmint.
    ///         Note that if the `amount` is not divisible by SATOSHI_MULTIPLIER,
    ///         the remainder is left on the caller's account when minting or
    ///         unminting.
    /// @return convertibleAmount Amount of TBTC to be minted/unminted.
    /// @return remainder Not convertible remainder if amount is not divisible
    ///         by SATOSHI_MULTIPLIER.
    /// @return satoshis Amount in satoshis - the Bank balance to be transferred
    ///         for the given mint/unmint
    function amountToSatoshis(uint256 amount)
        public
        view
        returns (
            uint256 convertibleAmount,
            uint256 remainder,
            uint256 satoshis
        )
    {
        remainder = amount % SATOSHI_MULTIPLIER;
        convertibleAmount = amount - remainder;
        satoshis = convertibleAmount / SATOSHI_MULTIPLIER;
    }

    // slither-disable-next-line calls-loop
    function _mint(address minter, uint256 amount) internal override {
        emit Minted(minter, amount);
        tbtcToken.mint(minter, amount);
    }

    /// @dev `amount` MUST be divisible by SATOSHI_MULTIPLIER with no change.
    function _unmint(address unminter, uint256 amount) internal {
        emit Unminted(unminter, amount);
        tbtcToken.burnFrom(unminter, amount);
        bank.transferBalance(unminter, amount / SATOSHI_MULTIPLIER);
    }

    /// @dev `amount` MUST be divisible by SATOSHI_MULTIPLIER with no change.
    function _unmintAndRedeem(
        address redeemer,
        uint256 amount,
        bytes calldata redemptionData
    ) internal {
        emit Unminted(redeemer, amount);
        tbtcToken.burnFrom(redeemer, amount);
        bank.approveBalanceAndCall(
            address(bridge),
            amount / SATOSHI_MULTIPLIER,
            redemptionData
        );
    }
}