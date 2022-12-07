// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TypeVVriter is Ownable {
    /// @notice The SVG path definition for each character in the VV alphabet.
    mapping(string => string) public LETTERS;

    /// @notice Width in pixels for characters in the VV alphabet.
    mapping(string => uint256) public LETTER_WIDTHS;

    constructor(address owner) {
        _transferOwnership(owner);
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a text as an SVG font inheriting text color and letter-spaced with 1px.
    /// @param text The text you want to write out.
    function write(string memory text) public view returns (string memory) {
        return write(text, "currentColor", 6);
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a text as an SVG font with 1px space between letters.
    /// @param text The text you want to write out.
    /// @param color The SVG-compatible color code to use for the text.
    function write(string memory text, string memory color) public view returns (string memory) {
        return write(text, color, 6);
    }

    /// @notice Write with the VV font on chain.
    /// @dev Write a given text as an SVG font in given `color` and letter `spacing`.
    /// @param text The text you want to write out.
    /// @param color The SVG-compatible color code to use for the text.
    /// @param spacing The space between letters in pixels.
    function write(
        string memory text,
        string memory color,
        uint256 spacing
    ) public view returns (string memory) {
        bytes memory byteText = upper(bytes(text));

        uint256 letterPos = 0;
        string memory letters = "";

        for (uint256 i = 0; i < byteText.length; i++) {
            bool overflow = byteText[i] >= 0xC0;
            bytes memory character = overflow ? new bytes(2) : new bytes(1);
            character[0] = byteText[i];
            if (overflow) {
                i += 1;
                character[1] = byteText[i];
            }
            string memory normalized = string(character);

            string memory path = LETTERS[normalized];
            if (bytes(path).length <= 0) continue;

            letters = string(abi.encodePacked(
                letters,
                '<g transform="translate(', Strings.toString(letterPos), ')">',
                    '<path d="', path, '"/>',
                '</g>'
            ));

            uint256 width = LETTER_WIDTHS[normalized] == 0
                ? LETTER_WIDTHS["DEFAULT"]
                : LETTER_WIDTHS[normalized];

            letterPos = letterPos + width + spacing;
        }

        uint256 lineWidth = letterPos - spacing;
        string memory svg = string(abi.encodePacked(
            '<svg ',
                'viewBox="0 0 ', Strings.toString(lineWidth), ' 30" ',
                'width="', Strings.toString(lineWidth), '" height="30" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg"',
            '>',
                '<g fill-rule="evenodd" clip-rule="evenodd" fill="', color, '">',
                    letters,
                '</g>',
            '</svg>'
        ));

        return svg;
    }

    /// @dev Uppercase some byte text.
    function upper(bytes memory _text) internal pure returns (bytes memory) {
        for (uint i = 0; i < _text.length; i++) {
            _text[i] = _upper(_text[i]);
        }
        return _text;
    }

    /// @dev Uppercase a single byte letter.
    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /// @dev Store a Glyph on-chain
    function setGlyph(string memory glyph, string memory path) public onlyOwner {
        _setGlyph(glyph, path);
    }

    /// @dev Store multiple Glyphs on-chain
    function setGlyphs(string[] memory glyphs, string[] memory paths) public onlyOwner {
        for (uint i = 0; i < glyphs.length; i++) {
            _setGlyph(glyphs[i], paths[i]);
        }
    }

    /// @dev Store a Glyph width on-chain
    function setGlyphWidth(string memory glyph, uint256 width) public onlyOwner {
        _setGlyphWidth(glyph, width);
    }

    /// @dev Store multiple Glyph widths on-chain
    function setGlyphWidths(string[] memory glyphs, uint256[] memory widths) public onlyOwner {
        for (uint i = 0; i < glyphs.length; i++) {
            _setGlyphWidth(glyphs[i], widths[i]);
        }
    }

    /// @dev Store a Glyph on-chain
    function _setGlyph(string memory glyph, string memory path) private {
        LETTERS[glyph] = path;
    }

    /// @dev Store a Glyph width on-chain
    function _setGlyphWidth(string memory glyph, uint256 width) private {
        LETTER_WIDTHS[glyph] = width;
    }
}