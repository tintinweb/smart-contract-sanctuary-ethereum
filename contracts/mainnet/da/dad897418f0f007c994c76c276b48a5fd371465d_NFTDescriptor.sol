// SPDX-License-Identifier: MIT

/// @title A library used to construct ERC721 token URIs and SVG images

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

pragma solidity ^0.8.17;

import { Base64 } from 'base64-sol/base64.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';

library NFTDescriptor {
  struct TokenURIParams {
    string name;
    string description;
    string background;
    bytes[] elements;
    string attributes;
    uint256 advantage;
    uint8 width;
    uint8 height;
  }

  /**
   * @notice Construct an ERC721 token URI.
   */
  function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
    public
    view
    returns (string memory)
  {
    string memory image = generateSVGImage(
      MultiPartRLEToSVG.SVGParams({
        background: params.background,
        elements: params.elements,
        advantage: params.advantage,
        width: uint256(params.width),
        height: uint256(params.height)
      }),
      palettes
    );

    string memory attributesJson;

    if (bytes(params.attributes).length > 0) {
      attributesJson = string.concat(' "attributes":', params.attributes, ',');
    } else {
      attributesJson = string.concat('');
    }

    // prettier-ignore
    return string.concat(
			'data:application/json;base64,',
			Base64.encode(
				bytes(
					string.concat('{"name":"', params.name, '",',
					' "description":"', params.description, '",',
					attributesJson,
					' "image": "', 'data:image/svg+xml;base64,', image, '"}')
				)
			)
    );
  }

  /**
   * @notice Generate an SVG image for use in the ERC721 token URI.
   */
  function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, mapping(uint8 => string[]) storage palettes)
    public
    view
    returns (string memory svg)
  {
    return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
  }
}

// SPDX-License-Identifier: MIT

/// @title A library used to convert multi-part RLE compressed images to SVG

/*

&_--~- ,_                     /""\      ,
{        ",       THE       <>^  L____/|
(  )_ ,{ ,[email protected]       FARM	     `) /`   , /
 |/  {|\{           GAME       \ `---' /
 ""   " "                       `'";\)`
W: https://thefarm.game           _/_Y
T: @The_Farm_Game

 * Howdy folks! Thanks for glancing over our contracts
 * If you're interested in working with us, you can email us at [email protected]
 * Found a broken egg in our contracts? We have a bug bounty program [email protected]
 * Y'all have a nice day

*/

/*
Adopted from Nouns.wtf source code
Modification allow for 48x48 pixel & 32x32 RLE images & using string.concat
*/

pragma solidity ^0.8.17;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';

library MultiPartRLEToSVG {
  using Strings for uint256;
  struct SVGParams {
    string background;
    bytes[] elements;
    uint256 advantage;
    uint256 width;
    uint256 height;
  }

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
    Rect[] rects;
  }

  /**
   * @notice Given RLE image elements and color palettes, merge to generate a single SVG image.
   */
  function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
    internal
    view
    returns (string memory svg)
  {
    string memory width = (params.width * 10).toString();
    string memory height = (params.width * 10).toString();
    string memory _background = '';
    if (keccak256(abi.encodePacked(params.background)) != keccak256(abi.encodePacked('------'))) {
      _background = string.concat('<rect width="100%" height="100%" fill="#', params.background, '" />');
    }
    return
      string.concat(
        '<svg width="',
        width,
        '" height="',
        height,
        '"',
        ' viewBox="0 0 ',
        width,
        ' ',
        height,
        '"',
        ' xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
        _background,
        _generateSVGRects(params, palettes),
        '</svg>'
      );
  }

  /**
   * @notice Given RLE image elements and color palettes, generate SVG rects.
   */
  // prettier-ignore
  function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
			private
			view
			returns (string memory svg)
    {
			string[49] memory lookup;

			// This is a lookup table that enables very cheap int to string
			// conversions when operating on a set of predefined integers.
			// This is used below to convert the integer length of each rectangle
			// in a 32x32 pixel grid to the string representation of the length
			// in a 320x320 pixel grid.
			// For example: A length of 3 gets mapped to '30'.
			// This lookup can be used for up to a 48x48 pixel grid
				lookup = [
					'0', '10', '20', '30', '40', '50', '60', '70',
					'80', '90', '100', '110', '120', '130', '140', '150',
					'160', '170', '180', '190', '200', '210', '220', '230',
					'240', '250', '260', '270', '280', '290', '300', '310',
					'320', '330', '340', '350', '360', '370', '380', '390',
					'400', '410', '420', '430', '440', '450', '460', '470',
					'480'
        ];

			// The string of SVG rectangles
			string memory rects;
			// Loop through all element create svg rects
			uint256 elementSize = 0;
			for (uint8 p = 0; p < params.elements.length; p++) {
				elementSize = elementSize + params.elements[p].length;

				// Convert the element data into a format that's easier to consume
    		// than a byte array.
				DecodedImage memory image = _decodeRLEImage(params.elements[p]);

				// Get the color palette used by the current element (`params.elements[p]`)
				string[] storage palette = palettes[image.paletteIndex];

				// These are the x and y coordinates of the rect that's currently being drawn.
    		// We start at the top-left of the pixel grid when drawing a new element.

				uint256 currentX = image.bounds.left;
				uint256 currentY = image.bounds.top;

				// The `cursor` and `buffer` are used here as a gas-saving technique.
				// We load enough data into a string array to draw four rectangles.
				// Once the string array is full, we call `_getChunk`, which writes the
				// four rectangles to a `chunk` variable before concatenating them with the
				// existing element string. If there is remaining, unwritten data inside the
				// `buffer` after we exit the rect loop, it will be written before the
				// element rectangles are merged with the existing element data.
				// This saves gas by reducing the size of the strings we're concatenating
				// during most loops.
				uint256 cursor;
				string[16] memory buffer;

				// The element rectangles
				string memory element;
				for (uint256 i = 0; i < image.rects.length; i++) {
					Rect memory rect = image.rects[i];
					// Skip fully transparent rectangles. Transparent rectangles
					// always have a color index of 0.
					if (rect.colorIndex != 0) {
							// Load the rectangle data into the buffer
							buffer[cursor] = lookup[rect.length];          // width
							buffer[cursor + 1] = lookup[currentX];         // x
							buffer[cursor + 2] = lookup[currentY];         // y
							buffer[cursor + 3] = palette[rect.colorIndex]; // color

							cursor += 4;

							if (cursor >= 16) {
								// Write the rectangles from the buffer to a string
								// and concatenate with the existing element string.
								element = string.concat(element, _getChunk(cursor, buffer));
								cursor = 0;
							}
					}

					// Move the x coordinate `rect.length` pixels to the right
					currentX += rect.length;

					// If the right bound has been reached, reset the x coordinate
					// to the left bound and shift the y coordinate down one row.
					if (currentX == image.bounds.right) {
							currentX = image.bounds.left;
							currentY++;
					}
				}

				// If there are unwritten rectangles in the buffer, write them to a
   			// `chunk` and concatenate with the existing element data.
				if (cursor != 0) {
					element = string.concat(element, _getChunk(cursor, buffer));
				}

				// Concatenate the element with all previous elements
				rects = string.concat(rects, element);

			}
			return rects;
    }

  /**
   * @notice Return a string that consists of all rects in the provided `buffer`.
   */
  // prettier-ignore
  function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
		string memory chunk;
		for (uint256 i = 0; i < cursor; i += 4) {
			chunk = string.concat(
					chunk,
					'<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
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

    uint256 cursor;

    // why is it length - 5? and why divide by 2?
    Rect[] memory rects = new Rect[]((image.length - 5) / 2);
    for (uint256 i = 5; i < image.length; i += 2) {
      rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
      cursor++;
    }
    return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
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