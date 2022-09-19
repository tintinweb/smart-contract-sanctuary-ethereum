// SPDX-License-Identifier: GPL-3.0

/**
  @title CapsuleRenderer

  @author peri

  @notice Renders SVG images for Capsules tokens.
 */

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ITypeface.sol";
import "./interfaces/ICapsuleRenderer.sol";
import "./utils/Base64.sol";

struct SvgSpecs {
    // Color code for SVG fill property
    string fill;
    // ID for row elements used on top and bottom edges of svg.
    bytes edgeRowId;
    // ID for row elements placed behind text rows.
    bytes textRowId;
    // Number of non-empty lines in Capsule text. Only trailing empty lines are excluded.
    uint256 linesCount;
    // Number of characters in the longest line of text.
    uint256 charWidth;
    // Width of the text area (in dots).
    uint256 textAreaWidthDots;
    // Height of the text area (in dots).
    uint256 textAreaHeightDots;
}

contract CapsuleRenderer is ICapsuleRenderer {
    /// Address of CapsulesTypeface contract
    address public immutable capsulesTypeface;

    constructor(address _capsulesTypeface) {
        capsulesTypeface = _capsulesTypeface;
    }

    function typeface() external view returns (address) {
        return capsulesTypeface;
    }

    /// @notice Return Base64-encoded SVG for Capsule.
    /// @param capsule Capsule data to return SVG for.
    /// @return svg SVG for Capsule.
    function svgOf(Capsule memory capsule)
        external
        view
        returns (string memory)
    {
        return svgOf(capsule, false);
    }

    /// @notice Return Base64-encoded SVG for Capsule. Can optionally return a square ratio image, regardless of text content shape.
    /// @param capsule Capsule to return SVG for.
    /// @param square Fit image to square with content centered.
    /// @return base64Svg Base64-encoded SVG for Capsule.
    function svgOf(Capsule memory capsule, bool square)
        public
        view
        returns (string memory base64Svg)
    {
        uint256 dotSize = 4;

        // If text is empty or invalid, use default text
        if (_isEmptyText(capsule.text) || !isValidText(capsule.text)) {
            capsule = Capsule({
                text: _defaultTextOf(capsule.color),
                id: capsule.id,
                color: capsule.color,
                font: capsule.font,
                isPure: capsule.isPure
            });
        }

        SvgSpecs memory specs = _svgSpecsOf(capsule);

        // Define reusable <g> elements to minimize overall SVG size
        bytes memory defs;
        {
            bytes
                memory dots1x12 = '<g id="dots1x12"><circle cx="2" cy="2" r="1.5"></circle><circle cx="2" cy="6" r="1.5"></circle><circle cx="2" cy="10" r="1.5"></circle><circle cx="2" cy="14" r="1.5"></circle><circle cx="2" cy="18" r="1.5"></circle><circle cx="2" cy="22" r="1.5"></circle><circle cx="2" cy="26" r="1.5"></circle><circle cx="2" cy="30" r="1.5"></circle><circle cx="2" cy="34" r="1.5"></circle><circle cx="2" cy="38" r="1.5"></circle><circle cx="2" cy="42" r="1.5"></circle><circle cx="2" cy="46" r="1.5"></circle></g>';

            // <g> row of dots 1 dot high that spans entire canvas width
            bytes memory edgeRowDots;
            edgeRowDots = abi.encodePacked('<g id="', specs.edgeRowId, '">');
            for (uint256 i = 1; i < specs.textAreaWidthDots - 1; i++) {
                edgeRowDots = abi.encodePacked(
                    edgeRowDots,
                    '<circle cx="',
                    Strings.toString(dotSize * i + 2),
                    '" cy="2" r="1.5"></circle>'
                );
            }
            edgeRowDots = abi.encodePacked(edgeRowDots, "</g>");

            // <g> row of dots with text height that spans entire canvas width
            bytes memory textRowDots;
            textRowDots = abi.encodePacked('<g id="', specs.textRowId, '">');
            for (uint256 i; i < specs.textAreaWidthDots; i++) {
                textRowDots = abi.encodePacked(
                    textRowDots,
                    '<use href="#dots1x12" transform="translate(',
                    Strings.toString(dotSize * i),
                    ')"></use>'
                );
            }
            textRowDots = abi.encodePacked(textRowDots, "</g>");

            defs = abi.encodePacked(dots1x12, edgeRowDots, textRowDots);
        }

        // Define <style> for svg element
        bytes memory style;
        {
            string memory fontWeightString = Strings.toString(
                capsule.font.weight
            );
            style = abi.encodePacked(
                "<style>.capsules-",
                fontWeightString,
                "{ font-size: 40px; white-space: pre; font-family: Capsules-",
                fontWeightString,
                ' } @font-face { font-family: "Capsules-',
                fontWeightString,
                '"; src: url(data:font/truetype;charset=utf-8;base64,',
                ITypeface(capsulesTypeface).sourceOf(capsule.font),
                ') format("opentype")}</style>'
            );
        }

        // Content area group will contain dot background and text.
        bytes memory contentArea;
        {
            // Create <g> element and define color of dots and text.
            contentArea = abi.encodePacked('<g fill="', specs.fill, '"');

            // If square image, translate contentArea group to center of svg viewbox
            if (square) {
                // Square size of the entire svg (in dots) equal to longest edge, including padding of 2 dots
                uint256 squareSizeDots = 2;
                if (specs.textAreaHeightDots >= specs.textAreaWidthDots) {
                    squareSizeDots += specs.textAreaHeightDots;
                } else {
                    squareSizeDots += specs.textAreaWidthDots;
                }

                contentArea = abi.encodePacked(
                    contentArea,
                    ' transform="translate(',
                    Strings.toString(
                        ((squareSizeDots - specs.textAreaWidthDots) / 2) *
                            dotSize
                    ),
                    " ",
                    Strings.toString(
                        ((squareSizeDots - specs.textAreaHeightDots) / 2) *
                            dotSize
                    ),
                    ')"'
                );
            }

            // Add dots by tiling edge row and text row elements defined in `defs`.

            // Add top edge row element
            contentArea = abi.encodePacked(
                contentArea,
                '><g opacity="0.2"><use href="#',
                specs.edgeRowId,
                '"></use>'
            );

            // Add a text row element for each line of text
            for (uint256 i; i < specs.linesCount; i++) {
                contentArea = abi.encodePacked(
                    contentArea,
                    '<use href="#',
                    specs.textRowId,
                    '" transform="translate(0 ',
                    Strings.toString(48 * i + dotSize),
                    ')"></use>'
                );
            }

            // Add bottom edge row element and close <g> group element
            contentArea = abi.encodePacked(
                contentArea,
                '<use href="#',
                specs.edgeRowId,
                '" transform="translate(0 ',
                Strings.toString((specs.textAreaHeightDots - 1) * dotSize),
                ')"></use></g>'
            );
        }

        // Create <g> group of text elements
        bytes memory texts;
        {
            // Create <g> element for texts and position using translate
            texts = '<g transform="translate(10 44)">';

            // Add a <text> element for each line of text, excluding trailing empty lines.
            // Each <text> has its own Y position.
            // Setting class on individual <text> elements increases CSS specificity and helps ensure styles are not overwritten by external stylesheets.
            for (uint256 i; i < specs.linesCount; i++) {
                texts = abi.encodePacked(
                    texts,
                    '<text y="',
                    Strings.toString(48 * i),
                    '" class="capsules-',
                    Strings.toString(capsule.font.weight),
                    '">',
                    _toUnicodeString(capsule.text[i]),
                    "</text>"
                );
            }

            // Close <g> texts group.
            texts = abi.encodePacked(texts, "</g>");
        }

        // Add texts to content area group and close <g> group.
        contentArea = abi.encodePacked(contentArea, texts, "</g>");

        {
            string memory x;
            string memory y;
            if (square) {
                // Square size of the entire svg (in dots) equal to longest edge, including padding of 2 dots
                uint256 squareSizeDots = 2;
                if (specs.textAreaHeightDots >= specs.textAreaWidthDots) {
                    squareSizeDots += specs.textAreaHeightDots;
                } else {
                    squareSizeDots += specs.textAreaWidthDots;
                }

                // If square image, use square viewbox
                x = Strings.toString(squareSizeDots * dotSize);
                y = Strings.toString(squareSizeDots * dotSize);
            } else {
                // Else fit to text area
                x = Strings.toString(specs.textAreaWidthDots * dotSize);
                y = Strings.toString(specs.textAreaHeightDots * dotSize);
            }

            // Construct parent svg element with defs, style, and content area groups.
            bytes memory svg = abi.encodePacked(
                '<svg viewBox="0 0 ',
                x,
                " ",
                y,
                '" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg"><defs>',
                defs,
                "</defs>",
                style,
                '<rect x="0" y="0" width="100%" height="100%" fill="#000"></rect>',
                contentArea,
                "</svg>"
            );

            // Base64 encode the svg data with prefix
            base64Svg = string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
        }
    }

    /// @notice Check if text is valid.
    /// @dev Text is valid if every unicode is supported by CapsulesTypeface, or is 0x00.
    /// @param text Text to check validity of.
    /// @return true True if text is valid.
    function isValidText(bytes32[8] memory text) public view returns (bool) {
        unchecked {
            for (uint256 i; i < 8; i++) {
                bytes2[16] memory line = _bytes32ToBytes2Array(text[i]);

                for (uint256 j; j < 16; j++) {
                    bytes2 char = line[j];

                    if (
                        char != 0 &&
                        !ITypeface(capsulesTypeface).supportsCodePoint(
                            // convert to bytes3 by adding 0 byte padding to left side
                            bytes3(abi.encodePacked(bytes1(0), char))
                        )
                    ) {
                        // return false if any single character is unsupported
                        return false;
                    }
                }
            }
        }

        return true;
    }

    /// @notice Returns default text for a Capsule with specified color
    /// @param color Color of Capsule
    /// @return defaultText Default text for Capsule
    function _defaultTextOf(bytes3 color)
        internal
        pure
        returns (bytes32[8] memory defaultText)
    {
        defaultText[0] = bytes32(
            abi.encodePacked(
                bytes1(0),
                "C",
                bytes1(0),
                "A",
                bytes1(0),
                "P",
                bytes1(0),
                "S",
                bytes1(0),
                "U",
                bytes1(0),
                "L",
                bytes1(0),
                "E"
            )
        );
        bytes memory _color = bytes(_bytes3ToColorCode(color));
        defaultText[1] = bytes32(
            abi.encodePacked(
                bytes1(0),
                _color[0],
                bytes1(0),
                _color[1],
                bytes1(0),
                _color[2],
                bytes1(0),
                _color[3],
                bytes1(0),
                _color[4],
                bytes1(0),
                _color[5],
                bytes1(0),
                _color[6]
            )
        );
    }

    /// @notice Calculate specs used to build SVG for capsule. The SvgSpecs struct allows using memory more efficiently when constructing a SVG for a Capsule.
    /// @param capsule Capsule to calculate specs for
    /// @return specs SVG specs calculated for Capsule
    function _svgSpecsOf(Capsule memory capsule)
        internal
        pure
        returns (SvgSpecs memory)
    {
        // Calculate number of lines of Capsule text to render. Only trailing empty lines are excluded.
        uint256 linesCount;
        for (uint256 i = 8; i > 0; i--) {
            if (!_isEmptyLine(capsule.text[i - 1])) {
                linesCount = i;
                break;
            }
        }

        // Calculate the width of the Capsule text in characters. Equal to the number of non-empty characters in the longest line.
        uint256 charWidth;
        for (uint256 i; i < linesCount; i++) {
            // Reverse iterate over line
            bytes2[16] memory line = _bytes32ToBytes2Array(capsule.text[i]);
            for (uint256 j = 16; j > charWidth; j--) {
                if (line[j - 1] != 0) charWidth = j;
            }
        }

        // Define the id of the svg row element.
        bytes memory edgeRowId = abi.encodePacked(
            "row",
            Strings.toString(charWidth)
        );

        // Width of the text area (in dots)
        uint256 textAreaWidthDots = charWidth * 5 + (charWidth - 1) + 6;
        // Height of the text area (in dots)
        uint256 textAreaHeightDots = linesCount * 12 + 2;

        return
            SvgSpecs({
                fill: _bytes3ToColorCode(capsule.color),
                edgeRowId: edgeRowId,
                textRowId: abi.encodePacked(
                    "textRow",
                    Strings.toString(charWidth)
                ),
                linesCount: linesCount,
                charWidth: charWidth,
                textAreaWidthDots: textAreaWidthDots,
                textAreaHeightDots: textAreaHeightDots
            });
    }

    /// @notice Check if all lines of text are empty.
    /// @dev Returns true if every line of text is empty.
    /// @param text Text to check.
    /// @return true if text is empty.
    function _isEmptyText(bytes32[8] memory text) internal pure returns (bool) {
        for (uint256 i; i < 8; i++) {
            if (!_isEmptyLine(text[i])) return false;
        }
        return true;
    }

    /// @notice Check if line is empty.
    /// @dev Returns true if every byte of text is 0x00.
    /// @param line line to check.
    /// @return true if line is empty.
    function _isEmptyLine(bytes32 line) internal pure returns (bool) {
        bytes2[16] memory _line = _bytes32ToBytes2Array(line);
        for (uint256 i; i < 16; i++) {
            if (_line[i] != 0) return false;
        }
        return true;
    }

    /// @notice Check if font is valid Capsules typeface font.
    /// @dev A font is valid if its source has been set in the CapsulesTypeface contract.
    /// @param font Font to check.
    /// @return true True if font is valid.
    function isValidFont(Font memory font) external view returns (bool) {
        return ITypeface(capsulesTypeface).hasSource(font);
    }

    /// @notice Returns text formatted as an array of readable strings.
    /// @param text Text to format.
    /// @return _stringText Text string array.
    function stringText(bytes32[8] memory text)
        external
        pure
        returns (string[8] memory _stringText)
    {
        for (uint256 i; i < 8; i++) {
            _stringText[i] = _toUnicodeString(text[i]);
        }
    }

    /// @notice Returns line of text formatted as a readable string.
    /// @dev Iterates through each byte in line of text and replaces each byte as needed to create a string that will render in html without issue. Ensures that no illegal characters or 0x00 bytes remain. Non-trailing 0x00 bytes are converted to spaces, trailing 0x00 bytes are trimmed.
    /// @param line Line of text to format.
    /// @return unicodeString Text string that can be safely rendered in html.
    function _toUnicodeString(bytes32 line)
        internal
        pure
        returns (string memory unicodeString)
    {
        bytes2[16] memory arr = _bytes32ToBytes2Array(line);

        for (uint256 i; i < 16; i++) {
            bytes2 char = arr[i];

            // 0 bytes cannot be rendered
            if (char == 0) continue;

            unicodeString = string.concat(
                unicodeString,
                _bytes2ToUnicodeString(char)
            );
        }
    }

    /// @notice Format bytes32 type as array of bytes2
    /// @param b bytes32 value to convert to array
    /// @return a Array of bytes2
    function _bytes32ToBytes2Array(bytes32 b)
        internal
        pure
        returns (bytes2[16] memory a)
    {
        for (uint256 i; i < 16; i++) {
            a[i] = bytes2(abi.encodePacked(b[i * 2], b[i * 2 + 1]));
        }
    }

    /// @notice Format bytes3 as html hex color code.
    /// @param b bytes3 value representing hex-encoded RGB color.
    /// @return o Formatted color code string.
    function _bytes3ToColorCode(bytes3 b)
        internal
        pure
        returns (string memory o)
    {
        bytes memory hexCode = bytes(Strings.toHexString(uint24(b)));
        o = "#";
        // Trim leading 0x from hexCode
        for (uint256 i = 2; i < 8; i++) {
            o = string.concat(o, string(abi.encodePacked(hexCode[i])));
        }
    }

    /// @notice Format bytes2 type as decimal unicode string for html.
    /// @param b bytes2 value representing hex unicode.
    /// @return unicode Formatted decimal unicode string.
    function _bytes2ToUnicodeString(bytes2 b)
        internal
        pure
        returns (string memory)
    {
        return string.concat("&#", Strings.toString(uint16(b)), ";");
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

/**
  @title ITypeface

  @author peri

  @notice Interface for Typeface contract
 */

pragma solidity ^0.8.8;

struct Font {
    uint256 weight;
    string style;
}

interface ITypeface {
    /// @notice Emitted when the source is set for a font.
    /// @param font The font the source has been set for.
    event SetSource(Font font);

    /// @notice Emitted when the source hash is set for a font.
    /// @param font The font the source hash has been set for.
    /// @param sourceHash The source hash that was set.
    event SetSourceHash(Font font, bytes32 sourceHash);

    /// @notice Emitted when the donation address is set.
    /// @param donationAddress New donation address.
    event SetDonationAddress(address donationAddress);

    /// @notice Returns the typeface name.
    function name() external view returns (string memory);

    /// @notice Check if typeface includes a glyph for a specific character code point.
    /// @dev 3 bytes supports all possible unicodes.
    /// @param codePoint Character code point.
    /// @return true True if supported.
    function supportsCodePoint(bytes3 codePoint) external view returns (bool);

    /// @notice Return source data of Font.
    /// @param font Font to return source data for.
    /// @return source Source data of font.
    function sourceOf(Font memory font) external view returns (bytes memory);

    /// @notice Checks if source data has been stored for font.
    /// @param font Font to check if source data exists for.
    /// @return true True if source exists.
    function hasSource(Font memory font) external view returns (bool);

    /// @notice Stores source data for a font.
    /// @param font Font to store source data for.
    /// @param source Source data of font.
    function setSource(Font memory font, bytes memory source) external;

    /// @notice Sets a new donation address.
    /// @param donationAddress New donation address.
    function setDonationAddress(address donationAddress) external;

    /// @notice Returns donation address
    /// @return donationAddress Donation address.
    function donationAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/**
  @title ICapsuleRenderer

  @author peri

  @notice Interface for CapsuleRenderer contract
 */

pragma solidity ^0.8.8;

import "./ICapsuleToken.sol";
import "./ITypeface.sol";

interface ICapsuleRenderer {
    function typeface() external view returns (address);

    function svgOf(Capsule memory capsule)
        external
        view
        returns (string memory);

    function isValidFont(Font memory font) external view returns (bool);

    function isValidText(bytes32[8] memory line) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
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

// SPDX-License-Identifier: GPL-3.0

/**
  @title ICapsuleToken

  @author peri

  @notice Interface for CapsuleToken contract
 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITypeface.sol";

struct Capsule {
    uint256 id;
    bytes3 color;
    Font font;
    bytes32[8] text;
    bool isPure;
}

interface ICapsuleToken {
    event AddValidRenderer(address renderer);
    event MintCapsule(
        uint256 indexed id,
        address indexed to,
        bytes3 indexed color,
        Font font,
        bytes32[8] text
    );
    event MintGift(address minter);
    event SetDefaultRenderer(address renderer);
    event SetFeeReceiver(address receiver);
    event SetMetadata(address metadata);
    event SetPureColors(bytes3[] colors);
    event SetRoyalty(uint256 royalty);
    event SetCapsuleFont(uint256 indexed id, Font font);
    event SetCapsuleRenderer(uint256 indexed id, address renderer);
    event SetCapsuleText(uint256 indexed id, bytes32[8] text);
    event SetContractURI(string contractURI);
    event SetGiftCount(address _address, uint256 count);
    event Withdraw(address to, uint256 amount);

    function capsuleOf(uint256 capsuleId)
        external
        view
        returns (Capsule memory);

    function isPureColor(bytes3 color) external view returns (bool);

    function colorOf(uint256 capsuleId) external view returns (bytes3);

    function textOf(uint256 capsuleId)
        external
        view
        returns (bytes32[8] memory);

    function fontOf(uint256 capsuleId) external view returns (Font memory);

    function svgOf(uint256 capsuleId) external view returns (string memory);

    function mint(
        bytes3 color,
        Font calldata font,
        bytes32[8] memory text
    ) external payable returns (uint256);

    function mintPureColorForFont(address to, Font calldata font)
        external
        returns (uint256);

    function mintAsOwner(
        address to,
        bytes3 color,
        Font calldata font,
        bytes32[8] calldata text
    ) external payable returns (uint256);

    function setGiftCounts(
        address[] calldata addresses,
        uint256[] calldata counts
    ) external;

    function setTextAndFont(
        uint256 capsuleId,
        bytes32[8] calldata text,
        Font calldata font
    ) external;

    function setText(uint256 capsuleId, bytes32[8] calldata text) external;

    function setFont(uint256 capsuleId, Font calldata font) external;

    function setRendererOf(uint256 capsuleId, address renderer) external;

    function setDefaultRenderer(address renderer) external;

    function addValidRenderer(address renderer) external;

    function burn(uint256 capsuleId) external;

    function isValidFontForRenderer(Font memory font, address renderer)
        external
        view
        returns (bool);

    function isValidColor(bytes3 color) external view returns (bool);

    function isValidCapsuleText(uint256 capsuleId) external view returns (bool);

    function isValidRenderer(address renderer) external view returns (bool);

    function contractURI() external view returns (string memory);

    function withdraw() external;

    function setFeeReceiver(address _feeReceiver) external;

    function setRoyalty(uint256 _royalty) external;

    function setContractURI(string calldata _contractURI) external;

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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