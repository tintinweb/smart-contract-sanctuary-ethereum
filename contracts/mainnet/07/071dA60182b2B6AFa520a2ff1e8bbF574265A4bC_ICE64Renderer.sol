// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*


        .++++++    .-=+**++=:  -+++++++++++-      .-=+**.     .++++:      
         :@@@@. .+%@#++++#@@@@#=*@@@%++*@@@*   :*@@%+=-:      [email protected]@@+       
          %@@# [email protected]@+        :#@@#[email protected]@@=    :#+ .#@@*.          [email protected]@@+        
          #@@#*@@=           *@# @@@@-      [email protected]@@*+*+=-      :@@@= =       
          #@@@@@@             += @@@@@@%%%=:@@@@*++#@@@#:  :@@@--%#       
          #@@@@@@                @@@= -*@@=#@@@     .*@@@[email protected]@# [email protected]@#   =   
          #@@@@@@-               @@@=    :[email protected]@@%       #@@@@@[email protected]@%-*@@   
          #@@#%@@@-           .%@@@@=      #@@@:      [email protected]@@@@@@@@@@@@@@@   
          %@@# #@@@#-       :[email protected]%[email protected]@@=     :%@@@%.     *@@+     [email protected]@%       
         :@@@@. :*@@@@%###%@@#= [email protected]@@#++#%@@@**@@@#=-=%@%-     [email protected]@@@-      
        .*****+    :=*###*+-.  -************:  -*###*=:      :******=

        M E T A D A T A   &   R E N D E R I N G   C O N T R A C T

*/

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DynamicBuffer} from "@divergencetech/ethier/contracts/utils/DynamicBuffer.sol";
import {Base64} from "./Base64.sol";

import {IICE64} from "./interfaces/IICE64.sol";
import {IICE64DataStore} from "./interfaces/IICE64DataStore.sol";
import {IICE64Renderer} from "./interfaces/IICE64Renderer.sol";
import {IExquisiteGraphics} from "./interfaces/IExquisiteGraphics.sol";

/**
@title ICE64 Renderer
@author Sam King (samkingstudio.eth)
@notice This contract renders token metadata for the main ICE64 contract: a standard baseURI
        for original photos stored off-chain, and base64 encoded on-chain SVGs for editions.

        Code is licensed as MIT.
        https://spdx.org/licenses/MIT.html

        Token metadata and images licensed as CC BY-NC 4.0
        https://creativecommons.org/licenses/by-nc/4.0/
        You are free to:
            - Share: copy and redistribute the material in any medium or format
            - Adapt: remix, transform, and build upon the material
        Under the following terms:
            - Attribution: You must give appropriate credit, provide a link to the license,
            and indicate if changes were made. You may do so in any reasonable manner, but not
            in any way that suggests the licensor endorses you or your use.
            - NonCommercial: You may not use the material for commercial purposes
            - No additional restrictions: You may not apply legal terms or technological measures
            that legally restrict others from doing anything the license permits.

*/
contract ICE64Renderer is IICE64Renderer {
    using Strings for uint256;
    using DynamicBuffer for bytes;

    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @dev The address of the token ownership contract
    IICE64 public ice64;

    /// @dev The address of the on-chain data storage contract
    IICE64DataStore public dataStore;

    /// @dev The address of the xqstgfx public rendering contract
    IExquisiteGraphics public xqstgfx;

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /// @param ice64_ The address of the token ownership contract
    /// @param ice64DataStore_ The address of the on-chain data storage contract
    /// @param xqstgfx_ The address of the xqstgfx public rendering contract
    constructor(
        address ice64_,
        address ice64DataStore_,
        address xqstgfx_
    ) {
        ice64 = IICE64(ice64_);
        dataStore = IICE64DataStore(ice64DataStore_);
        xqstgfx = IExquisiteGraphics(payable(xqstgfx_));
    }

    /* ------------------------------------------------------------------------
                             R A W   R E N D E R I N G
    ------------------------------------------------------------------------ */

    /// @notice Draws an SVG from data in the .xqst format to a string
    /// @param data The photo data in .xqst format
    function drawSVGToString(bytes memory data) public view returns (string memory) {
        return string(drawSVGToBytes(data));
    }

    /// @notice Draws an SVG from data in the .xqst format to bytes
    /// @param data The photo data in .xqst format
    function drawSVGToBytes(bytes memory data) public view returns (bytes memory) {
        string memory rects = xqstgfx.drawPixelsUnsafe(data);
        bytes memory svg = DynamicBuffer.allocate(2**19);

        svg.appendSafe(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" width="100%" height="100%" version="1.1" viewBox="0 0 128 128" fill="#fff"><rect width="128" height="128" fill="#fff" /><g transform="translate(32,32)">',
                rects,
                "</g></svg>"
            )
        );

        return svg;
    }

    /* ------------------------------------------------------------------------
                 P U B L I C   F R I E N D L Y   R E N D E R I N G
    ------------------------------------------------------------------------ */

    /// @notice Gets a photo in SVG format
    /// @param id The id of the photo to render
    function getEditionPhotoSVG(uint256 id) external view returns (string memory) {
        bytes memory data = dataStore.getRawPhotoData(id);
        return drawSVGToString(data);
    }

    /// @notice Gets a photo in Base64 encoded SVG format
    /// @param id The id of the photo to render (use original photo's id: `getEditionId(id)`)
    function getEditionPhotoBase64SVG(uint256 id) external view returns (string memory) {
        bytes memory data = dataStore.getRawPhotoData(id);
        bytes memory svg = drawSVGToBytes(data);
        bytes memory svgBase64 = DynamicBuffer.allocate(2**19);

        svgBase64.appendSafe("data:image/svg+xml;base64,");
        svgBase64.appendSafe(bytes(Base64.encode(svg)));

        return string(svgBase64);
    }

    /* ------------------------------------------------------------------------
                         O N - C H A I N   T O K E N U R I
    ------------------------------------------------------------------------ */

    /// @notice Renders metadata for a given token id
    /// @dev If the photo is an edition, then render an SVG, otherwise return the constructed URI
    /// @param id The token id to render
    function tokenURI(uint256 id) external view returns (string memory) {
        if (!ice64.isEdition(id)) {
            return string(abi.encodePacked(dataStore.getBaseURI(), id.toString()));
        }

        uint256 originalId = ice64.getOriginalTokenId(id);
        string memory originalIdStr = originalId.toString();

        bytes memory data = dataStore.getRawPhotoData(originalId);
        bytes memory svg = drawSVGToBytes(data);

        bytes memory svgBase64 = DynamicBuffer.allocate(2**19);
        svgBase64.appendSafe("data:image/svg+xml;base64,");
        svgBase64.appendSafe(bytes(Base64.encode(svg)));

        bytes memory json = DynamicBuffer.allocate(2**19);
        bytes memory jsonBase64 = DynamicBuffer.allocate(2**19);

        json.appendSafe(
            abi.encodePacked(
                '{"symbol":"ICE64","name":"ICE64 #',
                originalIdStr,
                ' (Edition)","description":"A fully on-chain edition of ICE64 #',
                originalIdStr,
                ". Edition size of ",
                ice64.getMaxEditions().toString(),
                '. Each edition is 64x64px in size with a 32px border, 64 colors, and stored on the Ethereum blockchain forever.","image":"',
                string(svgBase64),
                '","external_url":"https://ice64.com/photo/',
                id.toString(),
                '","attributes":[{"trait_type":"Size","value":"64x64px"},{"trait_type":"Border","value":"32px"},{"trait_type":"Colors","value":"64"}]}'
            )
        );

        jsonBase64.appendSafe("data:application/json;base64,");
        jsonBase64.appendSafe(bytes(Base64.encode(json)));

        return string(jsonBase64);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64 {
    function getOriginalTokenId(uint256 editionId) external pure returns (uint256);

    function getEditionTokenId(uint256 id) external pure returns (uint256);

    function getMaxEditions() external view returns (uint256);

    function isEdition(uint256 id) external pure returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64DataStore {
    function getBaseURI() external view returns (string memory);

    function getRawPhotoData(uint256 id) external view returns (bytes memory);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64Renderer {
    function drawSVGToString(bytes memory data) external view returns (string memory);

    function drawSVGToBytes(bytes memory data) external view returns (bytes memory);

    function tokenURI(uint256 id) external view returns (string memory);
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
    function drawPixelsUnsafe(bytes memory data) external pure returns (string memory);

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
    function decodeHeader(bytes memory data) external pure returns (Header memory);

    /// @notice Decodes the palette from a binary .xqst blob
    /// @param data Binary data in the .xqst format.
    /// @return bytes8[] the decoded palette
    function decodePalette(bytes memory data) external pure returns (string[] memory);

    /// @notice Decodes all of the data needed to draw an SVG from the .xqst file
    /// @param data Binary data in the .xqst format.
    /// @return ctx The Draw Context containing all of the decoded data
    function decodeDrawContext(bytes memory data) external pure returns (DrawContext memory ctx);

    /// @notice A way to say "Thank You"
    function ty() external payable;

    /// @notice A way to say "Thank You"
    function ty(string memory message) external payable;

    /// @notice Able to receive ETH from anyone
    receive() external payable;
}