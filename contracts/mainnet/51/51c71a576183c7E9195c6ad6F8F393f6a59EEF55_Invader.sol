// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/// @creator: denkozeth
/// Special thanks to Pak and his Censored collection for inspiring us.

//    ██ ███    ██ ██    ██  █████  ██████  ███████ ██████
//    ██ ████   ██ ██    ██ ██   ██ ██   ██ ██      ██   ██
//    ██ ██ ██  ██ ██    ██ ███████ ██   ██ █████   ██   ██
//    ██ ██  ██ ██  ██  ██  ██   ██ ██   ██ ██      ██   ██
//    ██ ██   ████   ████   ██   ██ ██████  ███████ ██████

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Invader {
    using Strings for uint256;

    string private constant _MESSAGE_TAG = "<MESSAGE>";
    string private constant _TRACK_TAG = "<TRACK>";
    string private constant _COMMUNITY_TAG = "<COMMUNITY>";
    string[] private _imageParts;

    constructor() {
        _imageParts.push(
            "<svg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000' viewBox='0 0 1000 1000'>"
        );
        _imageParts.push("<style>@font-face {font-family: 'C';src: ");
        _imageParts.push(
            "url('data:font/woff2;charset=utf-8;base64,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') format('woff2');"
        );
        _imageParts.push(
            "font-weight: 500; font-style: normal; font-display: swap;}"
        );
        _imageParts.push(".f { width: 100%; height: 100%; }");
        _imageParts.push(".b { fill: black; }");
        _imageParts.push(".a { animation: o 2s ease-out forwards; }");
        _imageParts.push(
            "@keyframes o { 10% { opacity: 1; } 100% { opacity: 0; } }"
        );
        _imageParts.push(
            "tspan { fill: lightgray; font-family: 'C'; font-size: 70px; text-transform: uppercase; text-anchor: middle; }"
        );
        _imageParts.push("</style>");
        _imageParts.push("<rect class='b f' />");
        _imageParts.push("<svg>");
        _imageParts.push(_TRACK_TAG);
        _imageParts.push("</svg>");
        _imageParts.push(_MESSAGE_TAG);
        _imageParts.push("<svg overflow='visible'><text>");
        _imageParts.push(_COMMUNITY_TAG);
        _imageParts.push(
            "<tspan y='85' x='150'>%23nowar</tspan><tspan y='85' x='740'>%23freeukraine</tspan></text></svg><rect class='b f a' />"
        );
        _imageParts.push("</svg>");
    }

    function metadata(
        uint256 tokenId,
        string memory message,
        uint256 value,
        uint256 angle,
        string memory community
    ) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    'data:application/json;utf8,{"name":"Invaded #',
                    tokenId.toString(),
                    '", "description":"',
                    _toUpperCase(message),
                    '", "created_by":"You", "image":"data:image/svg+xml;utf8,',
                    svg(tokenId, message, value, angle, community),
                    '","attributes":[{"trait_type":"Invaded","value":"True"},{"trait_type":"Initial Price","value":',
                    _valueString(value),
                    bytes(community).length > 0
                        ? string(
                            abi.encodePacked(
                                '},{"trait_type":"Community","value":"',
                                community,
                                '"}]}'
                            )
                        )
                        : "}]}"
                )
            );
    }

    function _toUpperCase(string memory message)
        private
        pure
        returns (string memory)
    {
        bytes memory messageBytes = bytes(message);
        bytes memory upperMessageBytes = new bytes(messageBytes.length);
        for (uint256 i = 0; i < messageBytes.length; i++) {
            bytes1 char = messageBytes[i];
            if (char >= 0x61 && char <= 0x7A) {
                // So we add 32 to make it lowercase
                upperMessageBytes[i] = bytes1(uint8(char) - 32);
            } else {
                upperMessageBytes[i] = char;
            }
        }
        return string(upperMessageBytes);
    }

    function renderLines(string memory message)
        public
        pure
        returns (string memory)
    {
        // Allocate memory for max number of lines (7) at 18 characters each (126)
        bytes memory lineBytes = new bytes(126);
        uint8[] memory lineLengths = new uint8[](7);

        // Compute line count
        bytes memory messageBytes = bytes(message);
        uint8 wordLength;
        uint8 lineLength;
        uint8 lineIndex;
        uint256 messageLastIndex = messageBytes.length - 1;
        for (uint256 i = 0; i <= messageLastIndex; i++) {
            bytes1 char = messageBytes[i];
            if (i == 0 || char != 0x20 || i == messageLastIndex) {
                wordLength += 1;
            }
            if (char == 0x20 || i == messageLastIndex) {
                // Check line length is < 18 after adding new word
                if (
                    (lineLength == 0 && lineLength + wordLength <= 18) ||
                    (lineLength + wordLength <= 17)
                ) {
                    // Add into the current lineBytes
                    uint256 lineBytesOffset = lineIndex * 18;
                    if (lineLength > 0) {
                        // Additional word, add a space
                        lineBytes[lineBytesOffset + lineLength] = 0x20;
                        lineLength += 1;
                    }
                    for (uint256 j = 0; j < wordLength; j++) {
                        lineBytes[
                            lineBytesOffset + lineLength + j
                        ] = messageBytes[
                            (i == messageLastIndex ? 1 : 0) + i - wordLength + j
                        ];
                    }
                    lineLength += wordLength;
                    lineLengths[lineIndex] = lineLength;
                } else {
                    // Word plus existing line length over max
                    if (wordLength > 18) {
                        if (lineLength > 0) {
                            // Move to new line if there have already been words added to this line
                            lineIndex += 1;
                            lineLength = 0;
                        }
                        uint256 lineBytesOffset = lineIndex * 18;
                        for (uint256 j = 0; j < wordLength; j++) {
                            lineLength += 1;
                            lineBytes[
                                lineBytesOffset + (j % 18)
                            ] = messageBytes[
                                (i == messageLastIndex ? 1 : 0) +
                                    i -
                                    wordLength +
                                    j
                            ];
                            if (j > 0 && j % 18 == 17) {
                                // New line every 18 characters
                                lineLengths[lineIndex] = lineLength;
                                lineIndex += 1;
                                lineLength = 0;
                                lineBytesOffset = lineIndex * 18;
                            }
                        }
                        lineLengths[lineIndex] = lineLength;
                    } else {
                        // New line
                        lineIndex += 1;
                        uint256 lineBytesOffset = lineIndex * 18;
                        for (uint256 j = 0; j < wordLength; j++) {
                            lineBytes[lineBytesOffset + j] = messageBytes[
                                (i == messageLastIndex ? 1 : 0) +
                                    i -
                                    wordLength +
                                    j
                            ];
                        }
                        lineLength = wordLength;
                        lineLengths[lineIndex] = lineLength;
                    }
                }
                wordLength = 0;
            }
        }

        string memory lines;
        uint8 lineCount;
        for (uint256 i = 0; i <= lineIndex; i++) {
            uint256 lineBytesOffset = i * 18;
            if (lineLengths[i] > 0) {
                lineCount += 1;
                bytes memory line = new bytes(lineLengths[i]);
                for (uint256 j = 0; j < lineLengths[i]; j++) {
                    line[j] = lineBytes[lineBytesOffset + j];
                }
                if (i == 0) {
                    lines = string(
                        abi.encodePacked(
                            lines,
                            "<tspan x='500'>",
                            line,
                            "</tspan>"
                        )
                    );
                } else {
                    lines = string(
                        abi.encodePacked(
                            lines,
                            "<tspan x='500' dy='1em'>",
                            line,
                            "</tspan>"
                        )
                    );
                }
            }
        }
        return
            string(
                abi.encodePacked(
                    "<svg y='",
                    (560 - uint256(lineCount) * 35).toString(),
                    "' overflow='visible'><text>",
                    lines,
                    "</text></svg>"
                )
            );
    }

    function _valueString(uint256 value) private pure returns (string memory) {
        uint256 eth = value / 10**18;
        uint256 decimal4 = value / 10**14 - eth * 10**4;
        return
            string(
                abi.encodePacked(
                    eth.toString(),
                    ".",
                    _decimal4ToString(decimal4)
                )
            );
    }

    function _decimal4ToString(uint256 decimal4)
        private
        pure
        returns (string memory)
    {
        bytes memory decimal4Characters = new bytes(4);
        for (uint256 i = 0; i < 4; i++) {
            decimal4Characters[3 - i] = bytes1(uint8(0x30 + (decimal4 % 10)));
            decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }

    function _renderTrack(uint256 offset) private pure returns (string memory) {
        bytes memory byteString;
        byteString = abi.encodePacked(
            byteString,
            abi.encodePacked(
                "<g fill='grey' transform='translate(",
                offset.toString(),
                ",-150)' style='fill-opacity: .4;'>"
            )
        );
        uint256 y = 0;
        for (uint256 z = 0; z < 35; z++) {
            uint256 x = 0;
            for (uint256 i = 0; i < 4; i++) {
                byteString = abi.encodePacked(
                    byteString,
                    abi.encodePacked(
                        "<rect transform='translate(",
                        x.toString(),
                        ",",
                        (i % 2 == 0 ? y + 10 : y).toString(),
                        ") rotate(",
                        (i % 2 != 0 ? "" : "-"),
                        "35)' x='0' width='50' height='20' rx='10' />"
                    )
                );
                x = i % 2 == 0 ? x + 55 : x + 35;
            }
            y = y + 40;
        }
        byteString = abi.encodePacked(byteString, abi.encodePacked("</g>"));
        return string(byteString);
    }

    function _renderTracks(uint256 angle) private pure returns (string memory) {
        bytes memory byteString;
        byteString = abi.encodePacked(
            byteString,
            abi.encodePacked(
                "<g transform='rotate(",
                angle.toString(),
                ", 500, 500)'>"
            )
        );
        byteString = abi.encodePacked(byteString, _renderTrack(100));
        byteString = abi.encodePacked(byteString, _renderTrack(650));
        byteString = abi.encodePacked(byteString, abi.encodePacked("</g>"));
        return string(byteString);
    }

    function _renderCommunityTag(string memory community)
        private
        pure
        returns (string memory)
    {
        bytes memory byteString;
        byteString = abi.encodePacked(
            byteString,
            abi.encodePacked(
                "<tspan y='970' x='500' style='font-size: 50px; font-style: italic'>",
                community,
                "</tspan>"
            )
        );
        return string(byteString);
    }

    function svg(
        uint256,
        string memory message,
        uint256,
        uint256 angle,
        string memory community
    ) public view returns (string memory) {
        bytes memory byteString;
        for (uint256 i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _MESSAGE_TAG)) {
                byteString = abi.encodePacked(byteString, renderLines(message));
            } else {
                if (_checkTag(_imageParts[i], _TRACK_TAG)) {
                    byteString = abi.encodePacked(
                        byteString,
                        _renderTracks(angle)
                    );
                } else {
                    if (_checkTag(_imageParts[i], _COMMUNITY_TAG)) {
                        byteString = abi.encodePacked(
                            byteString,
                            _renderCommunityTag(community)
                        );
                    } else {
                        byteString = abi.encodePacked(
                            byteString,
                            _imageParts[i]
                        );
                    }
                }
            }
        }
        return string(byteString);
    }

    function _checkTag(string storage a, string memory b)
        private
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function getAngle() public view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / block.timestamp) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            block.timestamp) +
                        block.number
                )
            )
        );

        return (seed - ((seed / 1000) * 1000)) % 360;
    }

    function validateMessage(string memory message_)
        public
        pure
        returns (bool)
    {
        // Max length 72, a-z- only
        bytes memory messageBytes = bytes(message_);
        require(
            messageBytes.length > 0 &&
                messageBytes[0] != 0x20 &&
                messageBytes[messageBytes.length - 1] != 0x20,
            "Invalid characters"
        );
        require(messageBytes.length <= 72, "Message too long");

        for (uint256 i = 0; i < messageBytes.length; i++) {
            bytes1 char = messageBytes[i];
            if (
                !(char >= 0x61 && char <= 0x7A) && char != 0x20 && char != 0x2D
            ) {
                revert("Invalid character");
            } else if (i >= 1 && char == 0x20 && messageBytes[i - 1] == 0x20) {
                revert("Cannot have multiple sequential spaces");
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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