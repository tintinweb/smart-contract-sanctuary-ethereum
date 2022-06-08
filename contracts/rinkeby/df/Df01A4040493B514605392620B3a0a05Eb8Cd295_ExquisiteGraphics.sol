// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IExquisiteGraphics} from './interfaces/IExquisiteGraphics.sol';
import {ThankYou} from './utils/ThankYou.sol';
import {ExquisiteUtils as utils} from './utils/ExquisiteUtils.sol';
import {ExquisiteDecoder as decoder} from './utils/ExquisiteDecoder.sol';
import {ExquisiteValidator as validator} from './utils/ExquisiteValidator.sol';
import '@divergencetech/ethier/contracts/utils/DynamicBuffer.sol';

contract ExquisiteGraphics is IExquisiteGraphics {
  using DynamicBuffer for bytes;

  enum DrawType {
    SVG,
    PIXELS
  }

  /// @notice Draw an SVG from the provided data
  /// @param data Binary data in the .xqst format.
  /// @return string the <svg>
  function draw(bytes memory data) public pure returns (string memory) {
    return _draw(data, DrawType.SVG, true);
  }

  /// @notice Draw an SVG from the provided data. No validation
  /// @param data Binary data in the .xqst format.
  /// @return string the <svg>
  function drawUnsafe(bytes memory data) public pure returns (string memory) {
    return _draw(data, DrawType.SVG, false);
  }

  /// @notice Draw the <rect> elements of an SVG from the data
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawPixels(bytes memory data) public pure returns (string memory) {
    return _draw(data, DrawType.PIXELS, true);
  }

  /// @notice Draw the <rect> elements of an SVG from the data. No validation
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawPixelsUnsafe(bytes memory data)
    public
    pure
    returns (string memory)
  {
    return _draw(data, DrawType.PIXELS, false);
  }

  /// @notice validates if the given data is a valid .xqst file
  /// @param data Binary data in the .xqst format.
  /// @return bool true if the data is valid
  function validate(bytes memory data) public pure returns (bool) {
    return validator._validate(data);
  }

  // Check if the header of some data is an XQST Graphics Compatible file
  /// @notice validates the header for some data is a valid .xqst header
  /// @param data Binary data in the .xqst format.
  /// @return bool true if the header is valid
  function validateHeader(bytes memory data) public pure returns (bool) {
    return validator._validateHeader(decoder._decodeHeader(data));
  }

  /// @notice Decodes the header from a binary .xqst blob
  /// @param data Binary data in the .xqst format.
  /// @return Header the decoded header
  function decodeHeader(bytes memory data) public pure returns (Header memory) {
    return decoder._decodeHeader(data);
  }

  /// @notice Decodes the palette from a binary .xqst blob
  /// @param data Binary data in the .xqst format.
  /// @return bytes8[] the decoded palette
  function decodePalette(bytes memory data)
    public
    pure
    returns (string[] memory)
  {
    return decoder._decodePalette(data, decoder._decodeHeader(data));
  }

  /// @notice Decodes all of the data needed to draw an SVG from the .xqst file
  /// @param data Binary data in the .xqst format.
  /// @return ctx The Draw Context containing all of the decoded data
  function decodeDrawContext(bytes memory data)
    public
    pure
    returns (DrawContext memory ctx)
  {
    _initDrawContext(ctx, data, true);
  }

  /// Initializes the Draw Context from the given data
  /// @param ctx The Draw Context to initialize
  /// @param data Binary data in the .xqst format.
  /// @param safe bool whether to validate the data
  function _initDrawContext(
    DrawContext memory ctx,
    bytes memory data,
    bool safe
  ) internal pure {
    ctx.header = decoder._decodeHeader(data);
    if (safe) {
      validator._validateHeader(ctx.header);
      validator._validateDataLength(ctx.header, data);
    }

    ctx.palette = decoder._decodePalette(data, ctx.header);
    ctx.pixels = decoder._decodePixels(data, ctx.header);
  }

  /// Draws the SVG or <rect> elements from the given data
  /// @param data Binary data in the .xqst format.
  /// @param t The SVG or Rectangles to draw
  /// @param safe bool whether to validate the data
  function _draw(
    bytes memory data,
    DrawType t,
    bool safe
  ) internal pure returns (string memory) {
    DrawContext memory ctx;
    bytes memory buffer = DynamicBuffer.allocate(2**18);

    _initDrawContext(ctx, data, safe);

    t == DrawType.PIXELS
      ? _writeSVGPixels(ctx, buffer)
      : _writeSVG(ctx, buffer);

    return string(buffer);
  }

  /// Writes the entire SVG to the given buffer
  /// @param ctx The Draw Context
  /// @param buffer The buffer to write the SVG to
  function _writeSVG(DrawContext memory ctx, bytes memory buffer)
    internal
    pure
  {
    _writeSVGHeader(ctx, buffer);
    _writeSVGPixels(ctx, buffer);
    buffer.appendSafe('</svg>');
  }

  /// Writes the SVG header to the given buffer
  /// @param ctx The Draw Context
  /// @param buffer The buffer to write the SVG header to
  function _writeSVGHeader(DrawContext memory ctx, bytes memory buffer)
    internal
    pure
  {
    uint256 scale = uint256(ctx.header.scale);
    // default scale to >=512px.
    if (scale == 0) {
      scale =
        512 /
        (
          ctx.header.width > ctx.header.height
            ? ctx.header.width
            : ctx.header.height
        ) +
        1;
    }

    buffer.appendSafe(
      abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" version="1.1" viewBox="0 0 ',
        utils.toBytes(ctx.header.width),
        ' ',
        utils.toBytes(ctx.header.height),
        '" width="',
        utils.toBytes(ctx.header.width * scale),
        '" height="',
        utils.toBytes(ctx.header.height * scale),
        '">'
      )
    );
  }

  /// Writes the SVG <rect> elements to the given buffer
  /// @param ctx The Draw Context
  /// @param buffer The buffer to write the SVG <rect> elements to
  function _writeSVGPixels(DrawContext memory ctx, bytes memory buffer)
    internal
    pure
  {
    uint256 colorIndex;
    uint256 width;
    uint256 pixelNum;
    bytes[] memory numberStrings = utils._getNumberStrings(ctx.header);

    // create a rect that fills the entirety of the svg as the background
    if (ctx.header.hasBackground) {
      buffer.appendSafe(
        abi.encodePacked(
          '"<rect fill="#',
          ctx.palette[ctx.header.backgroundColorIndex],
          '" height="',
          numberStrings[ctx.header.height],
          '" width="',
          numberStrings[ctx.header.width],
          '"/>'
        )
      );
    }

    // Write every pixel into the buffer
    while (pixelNum < ctx.header.totalPixels) {
      colorIndex = ctx.pixels[pixelNum];

      // Check if we need to write a new rect to the buffer at all
      if (utils._canSkipPixel(ctx, colorIndex)) {
        pixelNum++;
        continue;
      }

      // Calculate the width of a continuous rect with the same color
      width = 1;
      while ((pixelNum + width) % ctx.header.width != 0) {
        if (colorIndex == ctx.pixels[pixelNum + width]) {
          width++;
        } else break;
      }

      buffer.appendSafe(
        abi.encodePacked(
          '<rect fill="#',
          ctx.palette[colorIndex],
          '" x="',
          numberStrings[pixelNum % ctx.header.width],
          '" y="',
          numberStrings[pixelNum / ctx.header.width],
          '" height="1" width="',
          numberStrings[width],
          '"/>'
        )
      );

      unchecked {
        pixelNum += width;
      }
    }
  }

  /// @notice A way to say "Thank You"
  function ty() external payable {
    ThankYou._ty('');
  }

  /// @notice A way to say "Thank You"
  function ty(string memory message) external payable {
    ThankYou._ty(message);
  }

  /// @notice Able to receive ETH from anyone
  receive() external payable {
    ThankYou._ty('');
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IExquisiteGraphics {
  struct Header {
    /* HEADER START */
    uint8 version; // 8 bits
    uint16 width; // 8 bits
    uint16 height; // 8 bits
    uint16 numColors; // 16 bits
    uint8 backgroundColorIndex; // 8 bits
    uint16 scale; // 10 bits
    uint8 reserved; // 4 bits
    bool alpha; // 1 bit
    bool hasBackground; // 1 bit
    /* HEADER END */

    /* CALCULATED DATA START */
    uint24 totalPixels; // total pixels in the image
    uint8 bitsPerPixel; // bits per pixel
    uint8 pixelsPerByte; // pixels per byte
    uint16 paletteStart; // number of the byte where the palette starts
    uint16 dataStart; // number of the byte where the data starts
    /* CALCULATED DATA END */
  }

  struct DrawContext {
    bytes data; // the binary data in .xqst format
    Header header; // the header of the data
    string[] palette; // hex color for each color in the image
    uint8[] pixels; // color index (in the palette) for a pixel
  }

  error ExceededMaxPixels();
  error ExceededMaxRows();
  error ExceededMaxColumns();
  error ExceededMaxColors();
  error BackgroundColorIndexOutOfRange();
  error PixelColorIndexOutOfRange();
  error MissingHeader();
  error NotEnoughData();

  /// @notice Draw an SVG from the provided data
  /// @param data Binary data in the .xqst format.
  /// @return string the <svg>
  function draw(bytes memory data) external pure returns (string memory);

  /// @notice Draw an SVG from the provided data. No validation.
  /// @param data Binary data in the .xqst format.
  /// @return string the <svg>
  function drawUnsafe(bytes memory data) external pure returns (string memory);

  /// @notice Draw the <rect> elements of an SVG from the data
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawPixels(bytes memory data) external pure returns (string memory);

  /// @notice Draw the <rect> elements of an SVG from the data. No validation
  /// @param data Binary data in the .xqst format.
  /// @return string the <rect> elements
  function drawPixelsUnsafe(bytes memory data)
    external
    pure
    returns (string memory);

  /// @notice validates if the given data is a valid .xqst file
  /// @param data Binary data in the .xqst format.
  /// @return bool true if the data is valid
  function validate(bytes memory data) external pure returns (bool);

  // Check if the header of some data is an XQST Graphics Compatible file
  /// @notice validates the header for some data is a valid .xqst header
  /// @param data Binary data in the .xqst format.
  /// @return bool true if the header is valid
  function validateHeader(bytes memory data) external pure returns (bool);

  /// @notice Decodes the header from a binary .xqst blob
  /// @param data Binary data in the .xqst format.
  /// @return Header the decoded header
  function decodeHeader(bytes memory data)
    external
    pure
    returns (Header memory);

  /// @notice Decodes the palette from a binary .xqst blob
  /// @param data Binary data in the .xqst format.
  /// @return bytes8[] the decoded palette
  function decodePalette(bytes memory data)
    external
    pure
    returns (string[] memory);

  /// @notice Decodes all of the data needed to draw an SVG from the .xqst file
  /// @param data Binary data in the .xqst format.
  /// @return ctx The Draw Context containing all of the decoded data
  function decodeDrawContext(bytes memory data)
    external
    pure
    returns (DrawContext memory ctx);

  /// @notice A way to say "Thank You"
  function ty() external payable;

  /// @notice A way to say "Thank You"
  function ty(string memory message) external payable;

  /// @notice Able to receive ETH from anyone
  receive() external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library ThankYou {
  event ThankYouMessage(address sender, string message);

  error ThankYouFailed();

  address public constant addr =
    address(0x20a596e602c56948532B3626FC94db28FA9C41D3);

  function _ty(string memory message) internal {
    if (msg.value > 0) {
      (bool success, ) = addr.call{value: msg.value}('');
      if (!success) revert ThankYouFailed();
    }
    emit ThankYouMessage(msg.sender, message);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IExquisiteGraphics as xqstgfx} from '../interfaces/IExquisiteGraphics.sol';

library ExquisiteUtils {
  /// Gets an array of numbers in string format
  /// @dev index 0 is the string '0' and index 255 is the string '255'
  /// @param header used to figure out how many numbers we need to store
  /// @return numberStrings the array of numbers
  function _getNumberStrings(xqstgfx.Header memory header)
    internal
    pure
    returns (bytes[] memory numberStrings)
  {
    uint256 max;

    max = (header.width > header.height ? header.width : header.height) + 1;
    max = header.numColors > max ? header.numColors : max;

    numberStrings = new bytes[](max);
    for (uint256 i = 0; i < max; i++) {
      numberStrings[i] = toBytes(i);
    }
  }

  /// Determines if we can skip rendering a pixel
  /// @dev Can skip rendering a pixel under 3 Conditions
  /// @dev 1. The pixel's color is the same as the background color
  /// @dev 2. We are rendering in 0-color mode, and the pixel is a 0
  /// @dev 3. The pixel's color doesn't exist in the palette
  /// @param ctx the draw context
  /// @param colorIndex the index of the color for this pixel
  function _canSkipPixel(xqstgfx.DrawContext memory ctx, uint256 colorIndex)
    internal
    pure
    returns (bool)
  {
    return ((ctx.header.hasBackground &&
      colorIndex == ctx.header.backgroundColorIndex) ||
      (ctx.header.numColors == 0 && colorIndex == 0) ||
      (ctx.header.numColors > 0 && colorIndex >= ctx.header.numColors));
  }

  /// Returns the bytes representation of a number
  /// @param value the number to convert to bytes
  /// @return bytes representation of the number
  function toBytes(uint256 value) internal pure returns (bytes memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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
    return buffer;
  }

  /// Gets the ascii hex character for a uint8 (byte)
  /// @param char the uint8 to get the ascii hex character for
  /// @return bytes1 ascii hex character for the given uint8
  function _getHexChar(uint8 char) internal pure returns (bytes1) {
    return
      (char > 9)
        ? bytes1(char + 87) // ascii a-f
        : bytes1(char + 48); // ascii 0-9
  }

  /// Converts 4 bytes (uint32) to a RGBA hex string
  /// @param u the uint32 to convert to a color
  /// @return bytes8 the color in RBGA hex format
  function _uint32ToColor(uint32 u) internal pure returns (string memory) {
    bytes memory b = new bytes(8);
    for (uint256 j = 0; j < 8; j++) {
      b[7 - j] = _getHexChar(uint8(uint32(u) & 0x0f));
      u = u >> 4;
    }
    return string(b);
  }

  /// Converts 3 bytes (uint24) to a RGB hex string
  /// @param u the uint24 to convert to a color
  /// @return string the color in RBG hex format
  function _uint24ToColor(uint24 u) internal pure returns (string memory) {
    bytes memory b = new bytes(6);
    for (uint256 j = 0; j < 6; j++) {
      b[5 - j] = _getHexChar(uint8(uint24(u) & 0x0f));
      u = u >> 4;
    }
    return string(b);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IExquisiteGraphics as xqstgfx} from '../interfaces/IExquisiteGraphics.sol';
import {ExquisiteUtils as utils} from './ExquisiteUtils.sol';

library ExquisiteDecoder {
  /// Decode the header from raw binary data into a Header struct
  /// @param data Binary data in the .xqst format.
  /// @return header the header decoded from the data
  function _decodeHeader(bytes memory data)
    internal
    pure
    returns (xqstgfx.Header memory header)
  {
    if (data.length < 8) revert xqstgfx.MissingHeader();

    // Fetch the 8 Bytes representing the header from the data
    uint64 h;
    assembly {
      h := mload(add(data, 8))
    }

    header.version = uint8(h >> 56);
    header.width = uint16((h >> 48) & 0xFF);
    header.height = uint16((h >> 40) & 0xFF);
    header.numColors = uint16(h >> 24);
    header.backgroundColorIndex = uint8(h >> 16);
    header.scale = uint16((h >> 6) & 0x3FF);
    header.reserved = uint8((h >> 2) & 0x0F);
    header.alpha = ((h >> 1) & 0x1) == 1 ? true : false;
    header.hasBackground = (h & 0x1) == 1 ? true : false;

    header.paletteStart = 8;
    header.dataStart = header.alpha
      ? (header.numColors * 4) + 8
      : (header.numColors * 3) + 8;

    // if the height or width is '0' this really represents 256
    if (header.height == 0) header.height = 256;
    if (header.width == 0) header.width = 256;

    header.totalPixels = uint24(header.width) * uint24(header.height);

    _setColorDepthParams(header);
  }

  /// Decode the palette from raw binary data into a palette array
  /// @dev Each element of the palette array is a hex color with alpha channel
  /// @param data Binary data in the .xqst format.
  /// @return palette the palette from the data
  function _decodePalette(bytes memory data, xqstgfx.Header memory header)
    internal
    pure
    returns (string[] memory palette)
  {
    if (header.numColors > 0) {
      if (data.length < header.dataStart) revert xqstgfx.NotEnoughData();

      // the first 32 bytes of `data` represents `data.length` using assembly.
      // we offset 32 bytes to read the actual data
      uint256 offset = 32 + header.paletteStart;

      palette = new string[](header.numColors);

      if (header.alpha) {
        // read 4 bytes at a time if alpha
        bytes4 d;
        for (uint256 i = 0; i < header.numColors; i++) {
          // load 4 bytes of data at offset into d
          assembly {
            d := mload(add(data, offset))
          }

          palette[i] = utils._uint32ToColor(uint32(d));
          unchecked {
            offset += 4;
          }
        }
      } else {
        // read 3 bytes at a time if no alpha
        bytes3 d;
        for (uint256 i = 0; i < header.numColors; i++) {
          // load 3 bytes of data at offset into d
          assembly {
            d := mload(add(data, offset))
          }

          palette[i] = utils._uint24ToColor(uint24(d));
          unchecked {
            offset += 3;
          }
        }
      }
    } else {
      palette = new string[](2);
    }
  }

  /// Get a table of the color values (index) for each pixel in the image
  /// @param data Binary data in the .xqst format.
  /// @param header the header of the image
  /// @return table table of color index for each pixel
  function _decodePixels(bytes memory data, xqstgfx.Header memory header)
    internal
    pure
    returns (uint8[] memory table)
  {
    uint8 workingByte;
    table = new uint8[](header.totalPixels + 8); // add extra byte for safety
    if (header.bitsPerPixel == 1) {
      for (uint256 i = 0; i < header.totalPixels; i += 8) {
        workingByte = uint8(data[i / 8 + header.dataStart]);
        table[i] = workingByte >> 7;
        table[i + 1] = (workingByte >> 6) & 0x01;
        table[i + 2] = (workingByte >> 5) & 0x01;
        table[i + 3] = (workingByte >> 4) & 0x01;
        table[i + 4] = (workingByte >> 3) & 0x01;
        table[i + 5] = (workingByte >> 2) & 0x01;
        table[i + 6] = (workingByte >> 1) & 0x01;
        table[i + 7] = workingByte & 0x01;
      }
    } else if (header.bitsPerPixel == 2) {
      for (uint256 i = 0; i < header.totalPixels; i += 4) {
        workingByte = uint8(data[i / 4 + header.dataStart]);
        table[i] = workingByte >> 6;
        table[i + 1] = (workingByte >> 4) & 0x03;
        table[i + 2] = (workingByte >> 2) & 0x03;
        table[i + 3] = workingByte & 0x03;
      }
    } else if (header.bitsPerPixel == 4) {
      for (uint256 i = 0; i < header.totalPixels; i += 2) {
        workingByte = uint8(data[i / 2 + header.dataStart]);
        table[i] = workingByte >> 4;
        table[i + 1] = workingByte & 0x0F;
      }
    } else {
      for (uint256 i = 0; i < header.totalPixels; i++) {
        table[i] = uint8(data[i + header.dataStart]);
      }
    }
  }

  /// Set the color depth of the image in the header provided
  /// @param header the header of the image
  function _setColorDepthParams(xqstgfx.Header memory header) internal pure {
    if (header.numColors > 16) {
      // 8 bit Color Depth: images with 16 < numColors <= 256
      header.bitsPerPixel = 8;
      header.pixelsPerByte = 1;
    } else if (header.numColors > 4) {
      // 4 bit Color Depth: images with 4 < numColors <= 16
      header.bitsPerPixel = 4;
      header.pixelsPerByte = 2;
    } else if (header.numColors > 2) {
      // 2 bit Color Depth: images with 2 < numColors <= 4
      header.bitsPerPixel = 2;
      header.pixelsPerByte = 4;
    } else {
      // 1 bit Color Depth: images with 0 <= numColors <= 2
      header.bitsPerPixel = 1;
      header.pixelsPerByte = 8;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IExquisiteGraphics as xqstgfx} from '../interfaces/IExquisiteGraphics.sol';
import {ExquisiteDecoder as decoder} from './ExquisiteDecoder.sol';

library ExquisiteValidator {
  uint32 public constant MAX_COLORS = 256;
  uint32 public constant MAX_PIXELS = 4096;
  uint32 public constant MAX_ROWS = 256;
  uint32 public constant MAX_COLS = 256;

  /// @notice validates if the given data is a valid .xqst file
  /// @param data Binary data in the .xqst format.
  /// @return bool true if the data is valid
  function _validate(bytes memory data) internal pure returns (bool) {
    xqstgfx.DrawContext memory ctx;

    ctx.header = decoder._decodeHeader(data);
    _validateHeader(ctx.header);
    _validateDataLength(ctx.header, data);
    ctx.palette = decoder._decodePalette(data, ctx.header);

    return true;
  }

  /// @notice checks if the given data contains a valid .xqst header
  /// @param header the header of the data
  /// @return bool true if the header is valid
  function _validateHeader(xqstgfx.Header memory header)
    internal
    pure
    returns (bool)
  {
    if (uint32(header.width) * uint32(header.height) > MAX_PIXELS)
      revert xqstgfx.ExceededMaxPixels();
    if (header.height > MAX_ROWS) revert xqstgfx.ExceededMaxRows(); // This shouldn't be possible
    if (header.width > MAX_COLS) revert xqstgfx.ExceededMaxColumns(); // This shouldn't be possible
    if (header.numColors > MAX_COLORS) revert xqstgfx.ExceededMaxColors();

    if (
      header.hasBackground && header.backgroundColorIndex >= header.numColors
    ) {
      revert xqstgfx.BackgroundColorIndexOutOfRange();
    }

    return true;
  }

  /// @notice checks if the given data is long enough to render an .xqst image
  /// @param header the header of the data
  /// @param data the data to validate
  /// @return bool true if the data is long enough
  function _validateDataLength(xqstgfx.Header memory header, bytes memory data)
    internal
    pure
    returns (bool)
  {
    uint256 pixelDataLen = (header.totalPixels % 2 == 0) ||
      header.pixelsPerByte == 1
      ? (header.totalPixels / header.pixelsPerByte)
      : (header.totalPixels / header.pixelsPerByte) + 1;
    if (data.length < header.dataStart + pixelDataLen)
      revert xqstgfx.NotEnoughData();
    return true;
  }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(bytes memory buffer, bytes memory data)
        internal
        pure
    {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        uint256 capacity;
        uint256 length;
        assembly {
            capacity := sub(mload(sub(buffer, 0x20)), 0x40)
            length := mload(buffer)
        }

        require(
            length + data.length <= capacity,
            "DynamicBuffer: Appending out of bounds."
        );
        appendUnchecked(buffer, data);
    }
}