// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/BinaryDecoder.sol';
import '../utils/PackedVarArray.sol';


library NamelessDataV1 {
  /*
   * up to 2^32 generations each separated in space by
   * 2^223 empty slots for safety
   * leaving 223 bits of space for collision resistance
   */
  function getGenerationalSlot(uint256 columnName, uint32 generation) internal pure returns (uint256) {
    uint256 finalSlot =
      (columnName & 0x000000007FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) |
      (uint(generation) << 224);

    return finalSlot;
  }

  /*
   * Special Column Types
   */

  uint256 private constant MAX_COLUMN_WORDS = 65535;
  uint256 private constant MAX_CONTENT_LIBRARIES_PER_COLUMN = 256;
  uint256 private constant CONTENT_LIBRARY_SECTION_SIZE = 32 * MAX_CONTENT_LIBRARIES_PER_COLUMN;

  uint256 public constant COLUMN_TYPE_STRING = 1;
  uint256 public constant COLUMN_TYPE_UINT256 = 2;
  uint256 public constant COLUMN_TYPE_UINT128 = 3;
  uint256 public constant COLUMN_TYPE_UINT64 = 4;
  uint256 public constant COLUMN_TYPE_UINT32 = 5;
  uint256 public constant COLUMN_TYPE_UINT16 = 6;
  uint256 public constant COLUMN_TYPE_UINT8  = 7;
  uint256 public constant COLUMN_TYPE_NATIVE_STRING = 8;

  /**
    * @dev Returns an `uint256[MAX_COLUMN_WORDS]` located at `slot`.
    */
  function getColumn(bytes32 slot) internal pure returns (bytes32[MAX_COLUMN_WORDS] storage r) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
          r.slot := slot
      }
  }

  function getBufferIndexAndOffset(uint index, uint stride) internal pure returns (uint, uint) {
    uint offset = index * stride;
    return (offset / 32, offset % 32);
  }

  function getBufferIndexAndOffset(uint index, uint stride, uint baseOffset) internal pure returns (uint, uint) {
    uint offset = (index * stride) + baseOffset;
    return (offset / 32, offset % 32);
  }

  /*
   * Content Library Column
   *
   * @dev a content library column references content from a secondary data source like arweave of IPFS
   *      this content has been batched into libraries to save space.  Each library is a JSON-encoded
   *      array stored on the secondary data source that provides an indirection to the "real" content.
   *      each content library can hold up to 256 content references and each column can reference 256
   *      libraries. This results in a total of 65536 addressable content hashes while only consuming
   *      2 bytes per distinct token.
   */
  function readContentLibraryColumn(bytes32 columnSlot, uint ordinal) public view returns (
    uint contentLibraryHash,
    uint contentIndex
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    (uint bufferIndex, uint offset) = getBufferIndexAndOffset(ordinal, 2, CONTENT_LIBRARY_SECTION_SIZE);
    uint row = 0;
    (row, , ) = BinaryDecoder.decodeUint16Aligned(column, bufferIndex, offset);

    uint contentLibraryIndex = row >> 8;
    contentIndex = row & 0xFF;
    contentLibraryHash = uint256(column[contentLibraryIndex]);
  }

  function readDictionaryString(bytes32 dictionarySlot, uint ordinal) public view returns ( string memory ) {
    return PackedVarArray.getString(getColumn(dictionarySlot), ordinal);
  }

  function getDictionaryStringInfo(bytes32 dictionarySlot, uint ordinal) internal view returns ( bytes32 firstSlot, uint offset, uint length ) {
    return PackedVarArray.getStringInfo(getColumn(dictionarySlot), ordinal);
  }

  function readDictionaryStringLength(bytes32 dictionarySlot, uint ordinal) public view returns ( uint ) {
    return PackedVarArray.getStringLength(getColumn(dictionarySlot), ordinal);
  }

  /*
   * Uint256 Column
   *
   */
  function readUint256Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    return uint256(column[ordinal]);
  }

  /*
   * Uint128 Column
   *
   */
  function readUint128Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 2;
    uint shift = (1 - (ordinal % 2)) * 128;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  }

  /*
   * Uint64 Column
   *
   */
  function readUint64Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 4;
    uint shift = (3 - (ordinal % 4)) * 64;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFFFFFFFFFF;
  }

  /*
   * Uint32 Column
   *
   */
  function readUint32Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 8;
    uint shift = (7 - (ordinal % 8)) * 32;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFFFFFF;
  }

  /*
   * Uint16 Column
   *
   */
  function readUint16Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 16;
    uint shift = (15 - (ordinal % 16)) * 16;
    return (uint256(column[bufferIndex]) >> shift) & 0xFFFF;
  }

  /*
   * Uint8 Column
   *
   */
  function readUint8Column(bytes32 columnSlot, uint ordinal) public view returns (
    uint
  ) {
    bytes32[MAX_COLUMN_WORDS] storage column = getColumn(columnSlot);
    uint bufferIndex = ordinal / 32;
    uint shift = (31 - (ordinal % 32)) * 8;
    return (uint256(column[bufferIndex]) >> shift) & 0xFF;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './BinaryDecoder.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

library PackedVarArray {
  function getString(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (string memory) {
    bytes memory result = new bytes(len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while( bufferOffset < lastOffset) {
        result[outIdx++] = buffer[bufferOffset++];
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return string(result);
  }

  function getString(bytes32[0xFFFF] storage buffers, uint index) internal view returns (string memory) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFF;
    uint stringLen = stringOffsetLen >> 16;

    return getString(buffers, stringOffset, stringLen);
  }

  function getStringInfo(bytes32[0xFFFF] storage buffers, uint index) internal view returns ( bytes32 firstSlot, uint offset, uint length ) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint stringOffset = stringOffsetLen & 0xFFFF;
    uint stringLen = stringOffsetLen >> 16;
    uint bufferIdx = stringOffset / 32;
    uint bufferOffset = stringOffset % 32;
    bytes32 bufferSlot;

    //solhint-disable-next-line no-inline-assembly
    assembly {
      bufferSlot := buffers.slot
    }

    bufferSlot = bytes32(uint(bufferSlot) +  bufferIdx);


    return (bufferSlot, bufferOffset, stringLen);
  }

  function getStringLength(bytes32[0xFFFF] storage buffers, uint index) internal view returns (uint) {
    uint offsetLoc = uint(index) * 4;
    uint stringOffsetLen;
    (stringOffsetLen,,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    return stringOffsetLen >> 24;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint offset, uint len) internal view returns (uint16[] memory) {
    uint16[] memory result = new uint16[](len);

    uint bufferIdx = offset / 32;
    uint bufferOffset = offset % 32;
    uint outIdx = 0;
    uint remaining = len * 2;
    uint bufferCap = 32 - bufferOffset;


    while (outIdx < len) {
      uint copyCount = remaining > bufferCap ? bufferCap : remaining;
      uint lastOffset = bufferOffset + copyCount;
      bytes32 buffer = bytes32(buffers[bufferIdx]);
      while (bufferOffset < lastOffset) {
        result[outIdx]  = uint16(uint8(buffer[bufferOffset++])) << 8;
        result[outIdx] |= uint16(uint8(buffer[bufferOffset++]));
        outIdx++;
      }
      remaining -= copyCount;
      bufferCap = 32;
      bufferOffset = 0;
      bufferIdx++;
    }

    return result;
  }

  function getUint16Array(bytes32[0xFFFF] storage buffers, uint index) internal view returns (uint16[] memory) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;

    return getUint16Array(buffers, arrOffset, arrLen);
  }

  function getUint16ArrayInfo(bytes32[0xFFFF] storage buffers, uint index) internal view returns ( uint, uint, uint ) {
    uint offsetLoc = uint(index) * 4;
    uint arrOffsetLen;
    (arrOffsetLen, ,) = BinaryDecoder.decodeUint32Aligned(buffers, offsetLoc / 32, offsetLoc % 32);
    uint arrOffset = arrOffsetLen & 0xFFFFFF;
    uint arrLen = arrOffsetLen >> 24;
    uint bufferIdx = arrOffset / 32;
    uint bufferOffset = arrOffset % 32;

    return (bufferIdx, bufferOffset, arrLen);
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
pragma solidity ^0.8.0;

library BinaryDecoder {
    function increment(uint bufferIdx, uint offset, uint amount) internal pure returns (uint, uint) {
      offset+=amount;
      return (bufferIdx + (offset / 32), offset % 32);
    }

    function decodeUint8(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint8, uint, uint) {
      uint8 result = 0;
      result |= uint8(buffers[bufferIdx][offset]);
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (result, bufferIdx, offset);
    }

    function decodeUint16(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      if (offset % 32 < 31) {
        return decodeUint16Aligned(buffers, bufferIdx, offset);
      }

      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint16Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint16, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 1]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 2);
      return (uint16(result), bufferIdx, offset);
    }

    function decodeUint32(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      if (offset % 32 < 29) {
        return decodeUint32Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint32Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint32, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 3]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 4);
      return (uint32(result), bufferIdx, offset);
    }

    function decodeUint64(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
      if (offset % 32 < 25) {
        return decodeUint64Aligned(buffers, bufferIdx, offset);
      }

      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 48;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 40;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 32;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 24;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 16;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset])) << 8;
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      result |= uint(uint8(buffers[bufferIdx][offset]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 1);
      return (uint64(result), bufferIdx, offset);
    }

    function decodeUint64Aligned(bytes32[0xFFFF] storage buffers, uint bufferIdx, uint offset) internal view returns (uint64, uint, uint) {
      uint result = 0;
      result |= uint(uint8(buffers[bufferIdx][offset])) << 56;
      result |= uint(uint8(buffers[bufferIdx][offset + 1])) << 48;
      result |= uint(uint8(buffers[bufferIdx][offset + 2])) << 40;
      result |= uint(uint8(buffers[bufferIdx][offset + 3])) << 32;
      result |= uint(uint8(buffers[bufferIdx][offset + 4])) << 24;
      result |= uint(uint8(buffers[bufferIdx][offset + 5])) << 16;
      result |= uint(uint8(buffers[bufferIdx][offset + 6])) << 8;
      result |= uint(uint8(buffers[bufferIdx][offset + 7]));
      (bufferIdx, offset) = increment(bufferIdx, offset, 8);
      return (uint64(result), bufferIdx, offset);
    }
}