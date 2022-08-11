// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/IPathDecoder.sol";

contract SVGPathDecoderA is IPathDecoder {
  /**
  * Decode the compressed binary deta and reconstruct SVG path. 
  * The binaryformat is 12-bit middle endian, where the low 4-bit of the middle byte is
  * the high 4-bit of the even item ("ijkl"), and the high 4-bit of the middle byte is the high
  * 4-bit of the odd item ("IJKL"). 
  *   abcdefgh ijklIJKL ABCDEFG
  *
  * If we want to upgrade this decoder, it is possible to use the high 4-bit of the first
  * element for versioning, because it is guaraneed to be zero for the current version.
  */
//  function decodePath(bytes memory body) external pure override returns (bytes memory) {
  function decodePath(bytes memory body) external pure override returns (bytes memory) {
    bytes memory ret;
//    uint16 i;
//    uint256 length = ((body.length) * 2)/ 3;
    assembly{
      let bodyMemory := add(body, 0x20)
      let length := div(mul(mload(body), 2), 3)
      ret := mload(0x40)
      let retMemory := add(ret, 0x20)
      let retLength := 0
      for {let i := 0} lt(i, length){i := add(i,1)} {
        let offset := mul(div(i, 2), 3)
        let low
        let high
        switch mod(i,2)
        case 0{
          low := mload(add(bodyMemory, offset))
          high := and(shr(240, low),0x0f)
          low := shr(248, low)
        }
        default{
          high := mload(add(bodyMemory, add(offset, 1)))
          low := and(shr(240, high),0xff)
          high := shr(252,high)
        }
        
        switch high
        case 0{
          if and( gt(low, 64), lt(low, 91)){
            mstore(add(retMemory,retLength), shl(248,low))
            retLength := add(retLength, 1)
          }
          if and( gt(low, 96), lt(low, 123)){
            mstore(add(retMemory,retLength), shl(248,low))
            retLength := add(retLength, 1)
          }
        }
        default{
          let cmd := 0
          let lenCmd := 0
          // SVG value: undo (value + 1024) + 0x100 
          let value := sub(add(shl(8, high), low), 0x0100)
          switch lt(value, 1024)
          case 0{
            value := sub(value,1024)
          }
          default{
            // add "-"
            cmd := 45
            lenCmd := 1
            value := sub(1024,value)
          }
          if gt(value,999){
            cmd := or(shl(8,cmd), add(48, div(value, 1000)))
            lenCmd := add(1, lenCmd)
          }
          if gt(value,99){
            cmd := or(shl(8,cmd), add(48, div(mod(value,1000), 100)))
            lenCmd := add(1, lenCmd)
          }
          if gt(value,9){
            value := mod(mod(value,1000), 100)
            cmd := or(shl(8,cmd), add(48, div(value, 10)))
            lenCmd := add(1, lenCmd)
            value := mod(value,10)
          }
          cmd := or(shl(8,cmd), add(48, value))
          lenCmd := add(1, lenCmd)

          cmd := or(shl(8,cmd), 32)
          lenCmd := add(lenCmd, 1)
          mstore(add(retMemory,retLength), shl(sub(256, mul(lenCmd,8)),cmd))
          retLength := add(retLength, lenCmd)
        }
      }
      mstore(ret, retLength)
      mstore(0x40, add(retMemory, retLength))
    }
    return ret;
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

pragma solidity ^0.8.6;

interface IPathDecoder {
  function decodePath(bytes memory body) external pure returns (bytes memory);
}