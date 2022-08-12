// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/*
 * This is a part of "On-chain asset store" project (https://assetstore.wtf/), 
 * which is an attempt to create a public asset store on the Ethereum blockchain.
 * SVGPathDecoder is an upgradeable part of AssetStore, which decodes the compressed
 * "path" back to a string representation of path (for SVG). 
 *
 * Github repository: https://github.com/Cryptocoders-wtf/assetstore-contract
 * Contributors: cryptedy, snakajima
 */

import "../interfaces/IPathDecoder.sol";

contract SVGPathDecoderA is IPathDecoder {
  /**
  * @notice Decode the compressed path back to the string represetation of SVG path. 
  * The data format is 12-bit middle endian, where the low 4-bit of the middle byte is
  * the high 4-bit of the even item ("ijkl"), and the high 4-bit of the middle byte is the high
  * 4-bit of the odd item ("IJKL"). 
  *   abcdefgh ijklIJKL ABCDEFG
  *
  * If we want to support different compression format in future, it is possible to use the high 4-bit 
  * of the first element for versioning, because it is guaranteed to be zero for the current version.
  */
  function decodePath(bytes memory body) external pure override returns (bytes memory) {
    bytes memory ret;
    assembly{
      let bodyMemory := add(body, 0x20)
      let length := div(mul(mload(body), 2), 3)
      ret := mload(0x40)
      let retMemory := add(ret, 0x20)
      let data
      for {let i := 0} lt(i, length) {i := add(i, 1)} {
        if eq(mod(i, 16), 0) {
          data := mload(bodyMemory) // reading 8 extra bytes
          bodyMemory := add(bodyMemory, 24)
        }
        let low
        let high
        switch mod(i, 2)
        case 0 {
          low := shr(248, data)
          high := and(shr(240, data), 0x0f)
        }
        default {
          low := and(shr(232, data), 0xff)
          high := and(shr(244, data), 0x0f)
          data := shl(24, data)
        }
        
        switch high
        case 0 {
          if or(and(gt(low, 64), lt(low, 91)), and(gt(low, 96), lt(low, 123))) {
            mstore(retMemory, shl(248, low))
            retMemory := add(retMemory, 1)
          }
        }
        default {
          let cmd := 0
          let lenCmd := 2 // last digit and space
          // SVG value: undo (value + 1024) + 0x100 
          let value := sub(add(shl(8, high), low), 0x0100)
          switch lt(value, 1024)
          case 0 {
            value := sub(value, 1024)
          }
          default {
            cmd := 45 // "-"
            lenCmd := 3
            value := sub(1024,value)
          }
          if gt(value,9) {
            if gt(value,99) {
              if gt(value,999) {
                cmd := or(shl(8, cmd), 49) // always "1"
                lenCmd := add(1, lenCmd)
                value := mod(value, 1000)
              }
              cmd := or(shl(8, cmd), add(48, div(value, 100)))
              lenCmd := add(1, lenCmd)
              value := mod(value, 100)
            }
            cmd := or(shl(8, cmd), add(48, div(value, 10)))
            lenCmd := add(1, lenCmd)
            value := mod(value, 10)
          }
          // last digit and space
          cmd := or(or(shl(16, cmd), shl(8, add(48, value))), 32)

          mstore(retMemory, shl(sub(256, mul(lenCmd, 8)), cmd))
          retMemory := add(retMemory, lenCmd)
        }
      }
      mstore(ret, sub(sub(retMemory, ret), 0x20))
      mstore(0x40, retMemory)
    }
    return ret;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IPathDecoder {
  function decodePath(bytes memory body) external pure returns (bytes memory);
}