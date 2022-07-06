// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./Masher.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./MultiPartRLEToSVG.sol";
import "./Base64.sol";

// Gone
contract Masher is IMasher, Ownable {
  function gluepixelstogether(
    uint256 token,
    Part[] memory parts,
    string[] memory palette,
    string memory distortion
  ) external pure returns (string memory) {
    string memory image = Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(parts, palette, distortion)));

    return
      string.concat(
        "data:application/json;base64,",
        Base64.encode(
          bytes(
            string.concat(
              '{"name":"',
              bastianpleasecallmyname(token),
              '", "description":"',
              "foobar",
              '", "image": "',
              "data:image/svg+xml;base64,",
              image,
              '", "attributes":',
              partstotraits(parts),
              "}"
            )
          )
        )
      );
  }

  function bastianpleasecallmyname(uint256 token) internal pure returns (string memory) {
    return string.concat("picopanda#", Strings.toString(token));
  }

  function partstotraits(Part[] memory parts) internal pure returns (string memory) {
    string memory str = "";
    uint8 len = uint8(parts.length);

    for (uint8 i = 0; i < len; i++) {
      if (parts[i].nothing == false || parts[i].weight == 255) {
        if (i > 0) {
          str = string.concat(str, ",");
        }
        str = string.concat(str, '{"trait_type":"', parts[i].trait, '", ');
        // Special weight
        if (parts[i].weight == 255) {
          str = string.concat(str, '"display_type":"number", "value":', parts[i].name, "}");
        } else {
          str = string.concat(str, '"value":"', parts[i].name, '"}');
        }
      }
    }

    return string.concat("[", str, "]");
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

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

/// Changes:
//  - No solid background color, use a palette instead.
//  - 170 px wide instead of 320

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.12;

import "./IMasher.sol";

library MultiPartRLEToSVG {
  struct ContentBounds {
    uint8 top;
    uint8 right;
    uint8 bottom;
    uint8 left;
  }

  struct Rect {
    uint8 length;
    uint8 colorIndex;
  }

  struct DecodedImage {
    uint8 paletteIndex;
    ContentBounds bounds;
    uint256 width;
    Rect[] rects;
  }

  /**
   * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
   */
  function generateSVG(
    IMasher.Part[] memory parts,
    string[] memory palette,
    string memory distortionAmount
  ) internal pure returns (string memory svg) {
    return
      string.concat(
        '<svg viewBox="0 0 170 170" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
        '<filter id="b"><feTurbulence type="turbulence" baseFrequency="0.05" numOctaves="2" result="bt"/><feDisplacementMap in2="bt" in="SourceGraphic" scale="1" xChannelSelector="R" yChannelSelector="G"/></filter>',
        '<filter id="d"><feTurbulence type="turbulence" baseFrequency="0.01" numOctaves="5" result="dt"/><feDisplacementMap in2="dt" in="SourceGraphic" scale="',
        distortionAmount,
        '" /></filter>',
        _generateSVGRects(parts, palette),
        "</svg>"
      );
  }

  /**
   * @notice Given RLE image parts and color palettes, generate SVG rects.
   */
  function _generateSVGRects(IMasher.Part[] memory parts, string[] memory palette)
    private
    pure
    returns (string memory svg)
  {
    // prettier-ignore
    string[33] memory lookup = [
      '0', '10', '20', '30', '40', '50', '60', '70', '80',
      '90', '100', '110', '120', '130', '140', '150', '160',
      '170', '180', '190', '200', '210', '220', '230', '240',
      '250', '260', '270', '280', '290', '300', '310', '320'
    ];
    string memory rects;
    for (uint8 p = 0; p < parts.length; p++) {
      if (parts[p].nothing == false) {
        DecodedImage memory image = _decodeRLEImage(parts[p].data);
        uint256 currentX = image.bounds.left;
        uint256 currentY = image.bounds.top;
        uint256 cursor;
        string[16] memory buffer;

        string memory part;
        for (uint256 i = 0; i < image.rects.length; i++) {
          Rect memory rect = image.rects[i];
          if (rect.colorIndex != 0) {
            buffer[cursor] = lookup[rect.length]; // width
            buffer[cursor + 1] = lookup[currentX]; // x
            buffer[cursor + 2] = lookup[currentY]; // y
            buffer[cursor + 3] = palette[rect.colorIndex]; // color

            cursor += 4;

            if (cursor >= 16) {
              part = string.concat(part, _getChunk(cursor, buffer, p == 0 ? "b" : "d"));
              cursor = 0;
            }
          }

          currentX += rect.length;
          if (currentX - image.bounds.left > image.width) {
            currentX = image.bounds.left;
            currentY++;
          }
        }

        if (cursor != 0) {
          part = string.concat(part, _getChunk(cursor, buffer, p == 0 ? "b" : "d"));
        }
        rects = string.concat(rects, part);
      }
    }
    return rects;
  }

  /**
   * @notice Return a string that consists of all rects in the provided `buffer`.
   */
  function _getChunk(
    uint256 cursor,
    string[16] memory buffer,
    string memory filter
  ) private pure returns (string memory) {
    string memory chunk;
    for (uint256 i = 0; i < cursor; i += 4) {
      chunk = string.concat(
        chunk,
        "<rect",
        ' style="filter:url(#',
        filter,
        ')"',
        ' width="',
        buffer[i],
        '" height="10" x="',
        buffer[i + 1],
        '" y="',
        buffer[i + 2],
        '" fill="#',
        buffer[i + 3],
        '" />'
      );
    }
    return chunk;
  }

  /**
   * @notice Decode a single RLE compressed image into a `DecodedImage`.
   */
  function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
    uint8 paletteIndex = uint8(image[0]);
    ContentBounds memory bounds = ContentBounds({
      top: uint8(image[1]),
      right: uint8(image[2]),
      bottom: uint8(image[3]),
      left: uint8(image[4])
    });
    uint256 width = bounds.right - bounds.left;

    uint256 cursor;
    Rect[] memory rects = new Rect[]((image.length - 5) / 2);
    for (uint256 i = 5; i < image.length; i += 2) {
      rects[cursor] = Rect({length: uint8(image[i]), colorIndex: uint8(image[i + 1])});
      cursor++;
    }
    return DecodedImage({paletteIndex: paletteIndex, bounds: bounds, width: width, rects: rects});
  }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>

pragma solidity ^0.8.9;

library Base64 {
  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
    uint256 len = data.length;
    if (len == 0) return "";

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((len + 2) / 3);

    // Add some extra buffer at the end
    bytes memory result = new bytes(encodedLen + 32);

    bytes memory table = TABLE;

    assembly {
      let tablePtr := add(table, 1)
      let resultPtr := add(result, 32)

      for {
        let i := 0
      } lt(i, len) {

      } {
        i := add(i, 3)
        let input := and(mload(add(data, i)), 0xffffff)

        let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
        out := shl(8, out)
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
        out := shl(224, out)

        mstore(resultPtr, out)

        resultPtr := add(resultPtr, 4)
      }

      switch mod(len, 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }

      mstore(result, encodedLen)
    }

    return string(result);
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
pragma solidity ^0.8.12;

interface IMasher {
  struct Part {
    string trait;
    string name;
    bytes data;
    bool nothing;
    uint128 weight;
  }

  function gluepixelstogether(
    uint256 token,
    Part[] memory parts,
    string[] memory palette,
    string memory distortion
  ) external view returns (string memory);
}