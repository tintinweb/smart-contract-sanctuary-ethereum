// SPDX-License-Identifier: MIT

/*
 * Helper methods for SVG generative.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ISVGHelper.sol";

contract SVGHelperA is ISVGHelper {
  using Strings for uint32;

  /**
   * Generate a SVG path from series of control points
   *
   * Note: It is possible to significantly improve this using assembly (see SVGPathDecoderA). 
   */
  function pathFromPoints(uint[] memory points) external override pure returns(bytes memory path) {
    uint length = points.length;
    assembly{
      function toString(_wbuf, _value) -> wbuf {
        let len := 2
        let cmd := 0
        if gt(_value,9) {
          if gt(_value,99) {
            if gt(_value,999) {
              cmd := or(shl(8, cmd), add(48, div(_value, 1000))) 
              len := add(1, len)
              _value := mod(_value, 1000)
            }
            cmd := or(shl(8, cmd), add(48, div(_value, 100)))
            len := add(1, len)
            _value := mod(_value, 100)
          }
          cmd := or(shl(8, cmd), add(48, div(_value, 10)))
          len := add(1, len)
          _value := mod(_value, 10)
        }
        cmd := or(or(shl(16, cmd), shl(8, add(48, _value))), 32)

        mstore(_wbuf, shl(sub(256, mul(len, 8)), cmd))
        wbuf := add(_wbuf, len)
      }

      // dynamic allocation
      path := mload(0x40)
      let wbuf := add(path, 0x20)
      let rbuf := add(points, 0x20)

      let wordP := mload(add(rbuf, mul(sub(length,1), 0x20)))
      let word := mload(rbuf)
      for {let i := 0} lt(i, length) {i := add(i, 1)} {
        let x := and(word, 0xffff)
        let y := and(shr(16, word), 0xffff)
        let r := and(shr(32, word), 0xffff)
        let sx := div(add(x, and(wordP, 0xffff)),2)
        let sy := div(add(y, and(shr(16, wordP), 0xffff)),2)
        if eq(i, 0) {
          mstore(wbuf, shl(248, 0x4D)) // M
          wbuf := add(wbuf, 1)
          wbuf := toString(wbuf, sx)
          wbuf := toString(wbuf, sy)
        }
        
        let wordN := mload(add(rbuf, mul(mod(add(i,1), length), 0x20)))
        {
          let ex := div(add(x, and(wordN, 0xffff)),2)
          let ey := div(add(y, and(shr(16, wordN), 0xffff)),2)

          switch and(shr(48, word), 0x01) 
            case 0 {
              mstore(wbuf, shl(248, 0x43)) // C
              wbuf := add(wbuf, 1)
              x := mul(x, r)
              y := mul(y, r)
              r := sub(1024, r)
              wbuf := toString(wbuf, div(add(x, mul(sx, r)),1024))
              wbuf := toString(wbuf, div(add(y, mul(sy, r)),1024))
              wbuf := toString(wbuf, div(add(x, mul(ex, r)),1024))
              wbuf := toString(wbuf, div(add(y, mul(ey, r)),1024))
            }
            default {
              mstore(wbuf, shl(248, 0x4C)) // L
              wbuf := add(wbuf, 1)
              wbuf := toString(wbuf, x)
              wbuf := toString(wbuf, y)
            }
          wbuf := toString(wbuf, ex)
          wbuf := toString(wbuf, ey)
        }
        wordP := word
        word := wordN
      }

      mstore(path, sub(sub(wbuf, path), 0x20))
      mstore(0x40, wbuf)
    }
  }  

  /**
   * Benchmarking
   */
  function generateSVGPart(IAssetProvider provider, uint256 _assetId) external view override returns(string memory svgPart, string memory tag, uint256 gas) {
    gas = gasleft();
    (svgPart, tag) = provider.generateSVGPart(_assetId);
    gas -= gasleft();
  }
}

// SPDX-License-Identifier: MIT

/*
 * Interface to helper contract(s) for SVG generative.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { IAssetProvider } from './IAssetProvider.sol';

interface ISVGHelper {
  // point
  // 0-15: int x
  // 16-31: int y
  // 32-47: uint r
  // 48: bool c
  function pathFromPoints(uint[] memory points) external pure returns(bytes memory);
  function generateSVGPart(IAssetProvider provider, uint256 _assetId) external view returns(string memory svgPart, string memory tag, uint256 gas);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT

/**
 * This is a part of an effort to create a decentralized autonomous marketplace for digital assets,
 * which allows artists and developers to sell their arts and generative arts.
 *
 * Please see "https://fullyonchain.xyz/" for details. 
 *
 * Created by Satoshi Nakajima (@snakajima)
 */
pragma solidity ^0.8.6;

/**
 * IAssetProvider is the interface each asset provider implements.
 * We assume there are three types of asset providers.
 * 1. Static asset provider, which has a collection of assets (either in the storage or the code) and returns them.
 * 2. Generative provider, which dynamically (but deterministically from the seed) generates assets.
 * 3. Data visualizer, which generates assets based on various data on the blockchain.
 *
 * Note: Asset providers MUST implements IERC165 (supportsInterface method) as well. 
 */
interface IAssetProvider {
  struct ProviderInfo {
    string key;  // short and unique identifier of this provider (e.g., "asset")
    string name; // human readable display name (e.g., "Asset Store")
    IAssetProvider provider;
  }
  function getProviderInfo() external view returns(ProviderInfo memory);

  /**
   * This function returns SVGPart and the tag. The SVGPart consists of one or more SVG elements.
   * The tag specifies the identifier of the SVG element to be displayed (using <use> tag).
   * The tag is the combination of the provider key and assetId (e.e., "asset123")
   */
  function generateSVGPart(uint256 _assetId) external view returns(string memory svgPart, string memory tag);

  /**
   * This is an optional function, which returns various traits of the image for ERC721 token.
   * Format: {"trait_type":"TRAIL_TYPE","value":"VALUE"},{...}
   */
  function generateTraits(uint256 _assetId) external pure returns (string memory);
  
  /**
   * This function returns the number of assets available from this provider. 
   * If the total supply is 100, assetIds of available assets are 0,1,...99.
   * The generative providers may returns 0, which indicates the provider dynamically but
   * deterministically generates assets using the given assetId as the random seed.
   */
  function totalSupply() external view returns(uint256);

  /**
   * Returns the onwer. The registration update is possible only if both contracts have the same owner. 
   */
  function getOwner() external view returns (address);

  /**
   * This function processes the royalty payment from the decentralized autonomous marketplace. 
   */
  function processPayout(uint256 _assetId) external payable;

  event Payout(string providerKey, uint256 assetId, address payable to, uint256 amount);
}