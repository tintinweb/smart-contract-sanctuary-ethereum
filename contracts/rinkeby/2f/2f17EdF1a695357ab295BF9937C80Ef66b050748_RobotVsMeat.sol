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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
pragma solidity ^0.8.0;

/// @title ISVG image library types interface
/// @dev Allows Solidity files to reference the library's input and return types without referencing the library itself
interface ISVGTypes {

	/// Represents a color in RGB format with alpha
	struct Color {
		uint8 red;
		uint8 green;
		uint8 blue;
		uint8 alpha;
	}

	/// Represents a color attribute in an SVG image file
	enum ColorAttribute {
		Fill, Stroke, Stop
	}

	/// Represents the kind of color attribute in an SVG image file
	enum ColorAttributeKind {
		RGB, URL
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Base64.sol";

/// @title OnChain metadata support library
/**
* @dev These methods are best suited towards view/pure only function calls (ALL the way through the call stack).
* Do not waste gas using these methods in functions that also update state, unless your need requires it.
*/
library OnChain {

	/// Returns the prefix needed for a base64-encoded on chain svg image
	function baseSvgImageURI() internal pure returns (bytes memory) {
		return "data:image/svg+xml;base64,";
	}

	/// Returns the prefix needed for a base64-encoded on chain nft metadata
	function baseURI() internal pure returns (bytes memory) {
		return "data:application/json;base64,";
	}

	/// Returns the contents joined with a comma between them
	/// @param contents1 The first content to join
	/// @param contents2 The second content to join
	/// @return A collection of bytes that represent all contents joined with a comma
	function commaSeparated(bytes memory contents1, bytes memory contents2) internal pure returns (bytes memory) {
		return abi.encodePacked(contents1, continuesWith(contents2));
	}

	/// Returns the contents joined with commas between them
	/// @param contents1 The first content to join
	/// @param contents2 The second content to join
	/// @param contents3 The third content to join
	/// @return A collection of bytes that represent all contents joined with commas
	function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3) internal pure returns (bytes memory) {
		return abi.encodePacked(commaSeparated(contents1, contents2), continuesWith(contents3));
	}

	/// Returns the contents joined with commas between them
	/// @param contents1 The first content to join
	/// @param contents2 The second content to join
	/// @param contents3 The third content to join
	/// @param contents4 The fourth content to join
	/// @return A collection of bytes that represent all contents joined with commas
	function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4) internal pure returns (bytes memory) {
		return abi.encodePacked(commaSeparated(contents1, contents2, contents3), continuesWith(contents4));
	}

	/// Returns the contents joined with commas between them
	/// @param contents1 The first content to join
	/// @param contents2 The second content to join
	/// @param contents3 The third content to join
	/// @param contents4 The fourth content to join
	/// @param contents5 The fifth content to join
	/// @return A collection of bytes that represent all contents joined with commas
	function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4, bytes memory contents5) internal pure returns (bytes memory) {
		return abi.encodePacked(commaSeparated(contents1, contents2, contents3, contents4), continuesWith(contents5));
	}

	/// Returns the contents joined with commas between them
	/// @param contents1 The first content to join
	/// @param contents2 The second content to join
	/// @param contents3 The third content to join
	/// @param contents4 The fourth content to join
	/// @param contents5 The fifth content to join
	/// @param contents6 The sixth content to join
	/// @return A collection of bytes that represent all contents joined with commas
	function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4, bytes memory contents5, bytes memory contents6) internal pure returns (bytes memory) {
		return abi.encodePacked(commaSeparated(contents1, contents2, contents3, contents4, contents5), continuesWith(contents6));
	}

	/// Returns the contents prefixed by a comma
	/// @dev This is used to append multiple attributes into the json
	/// @param contents The contents with which to prefix
	/// @return A bytes collection of the contents prefixed with a comma
	function continuesWith(bytes memory contents) internal pure returns (bytes memory) {
		return abi.encodePacked(",", contents);
	}

	/// Returns the contents wrapped in a json dictionary
	/// @param contents The contents with which to wrap
	/// @return A bytes collection of the contents wrapped as a json dictionary
	function dictionary(bytes memory contents) internal pure returns (bytes memory) {
		return abi.encodePacked("{", contents, "}");
	}

	/// Returns an unwrapped key/value pair where the value is an array
	/// @param key The name of the key used in the pair
	/// @param value The value of pair, as an array
	/// @return A bytes collection that is suitable for inclusion in a larger dictionary
	function keyValueArray(string memory key, bytes memory value) internal pure returns (bytes memory) {
		return abi.encodePacked("\"", key, "\":[", value, "]");
	}

	/// Returns an unwrapped key/value pair where the value is a string
	/// @param key The name of the key used in the pair
	/// @param value The value of pair, as a string
	/// @return A bytes collection that is suitable for inclusion in a larger dictionary
	function keyValueString(string memory key, bytes memory value) internal pure returns (bytes memory) {
		return abi.encodePacked("\"", key, "\":\"", value, "\"");
	}

	/// Encodes an SVG as base64 and prefixes it with a URI scheme suitable for on-chain data
	/// @param svg The contents of the svg
	/// @return A bytes collection that may be added to the "image" key/value pair in ERC-721 or ERC-1155 metadata
	function svgImageURI(bytes memory svg) internal pure returns (bytes memory) {
		return abi.encodePacked(baseSvgImageURI(), Base64.encode(svg));
	}

	/// Encodes json as base64 and prefixes it with a URI scheme suitable for on-chain data
	/// @param metadata The contents of the metadata
	/// @return A bytes collection that may be returned as the tokenURI in a ERC-721 or ERC-1155 contract
	function tokenURI(bytes memory metadata) internal pure returns (bytes memory) {
		return abi.encodePacked(baseURI(), Base64.encode(metadata));
	}

	/// Returns the json dictionary of a single trait attribute for an ERC-721 or ERC-1155 NFT
	/// @param name The name of the trait
	/// @param value The value of the trait
	/// @return A collection of bytes that can be embedded within a larger array of attributes
	function traitAttribute(string memory name, bytes memory value) internal pure returns (bytes memory) {
		return dictionary(commaSeparated(
			keyValueString("trait_type", bytes(name)),
			keyValueString("value", value)
		));
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ISVGTypes.sol";
import "./OnChain.sol";
import "./SVGErrors.sol";

/// @title SVG image library
/**
* @dev These methods are best suited towards view/pure only function calls (ALL the way through the call stack).
* Do not waste gas using these methods in functions that also update state, unless your need requires it.
*/
library SVG {

	using Strings for uint256;

	/// Returns a named element based on the supplied attributes and contents
	/// @dev attributes and contents is usually generated from abi.encodePacked, attributes is expecting a leading space
	/// @param name The name of the element
	/// @param attributes The attributes of the element, as bytes, with a leading space
	/// @param contents The contents of the element, as bytes
	/// @return a bytes collection representing the whole element
	function createElement(string memory name, bytes memory attributes, bytes memory contents) internal pure returns (bytes memory) {
		return abi.encodePacked(
			"<", attributes.length == 0 ? bytes(name) : abi.encodePacked(name, attributes),
			contents.length == 0 ? bytes("/>") : abi.encodePacked(">", contents, "</", name, ">")
		);
	}

	/// Returns the root SVG attributes based on the supplied width and height
	/// @dev includes necessary leading space for createElement's `attributes` parameter
	/// @param width The width of the SVG view box
	/// @param height The height of the SVG view box
	/// @return a bytes collection representing the root SVG attributes, including a leading space
	function svgAttributes(uint256 width, uint256 height) internal pure returns (bytes memory) {
		return abi.encodePacked(" viewBox='0 0 ", width.toString(), " ", height.toString(), "' xmlns='http://www.w3.org/2000/svg'");
	}

	/// Returns an RGB bytes collection suitable as an attribute for SVG elements based on the supplied Color and ColorType
	/// @dev includes necessary leading space for all types _except_ None
	/// @param attribute The `ISVGTypes.ColorAttribute` of the desired attribute
	/// @param value The converted color value as bytes
	/// @return a bytes collection representing a color attribute in an SVG element
	function colorAttribute(ISVGTypes.ColorAttribute attribute, bytes memory value) internal pure returns (bytes memory) {
		if (attribute == ISVGTypes.ColorAttribute.Fill) return _attribute("fill", value);
		if (attribute == ISVGTypes.ColorAttribute.Stop) return _attribute("stop-color", value);
		return  _attribute("stroke", value); // Fallback to Stroke
	}

	/// Returns an RGB color attribute value
	/// @param color The `ISVGTypes.Color` of the color
	/// @return a bytes collection representing the url attribute value
	function colorAttributeRGBValue(ISVGTypes.Color memory color) internal pure returns (bytes memory) {
		return _colorValue(ISVGTypes.ColorAttributeKind.RGB, OnChain.commaSeparated(
			bytes(uint256(color.red).toString()),
			bytes(uint256(color.green).toString()),
			bytes(uint256(color.blue).toString())
		));
	}

	/// Returns a URL color attribute value
	/// @param url The url to the color
	/// @return a bytes collection representing the url attribute value
	function colorAttributeURLValue(bytes memory url) internal pure returns (bytes memory) {
		return _colorValue(ISVGTypes.ColorAttributeKind.URL, url);
	}

	/// Returns an `ISVGTypes.Color` that is brightened by the provided percentage
	/// @param source The `ISVGTypes.Color` to brighten
	/// @param percentage The percentage of brightness to apply
	/// @param minimumBump A minimum increase for each channel to ensure dark Colors also brighten
	/// @return color the brightened `ISVGTypes.Color`
	function brightenColor(ISVGTypes.Color memory source, uint32 percentage, uint8 minimumBump) internal pure returns (ISVGTypes.Color memory color) {
		color.red = _brightenComponent(source.red, percentage, minimumBump);
		color.green = _brightenComponent(source.green, percentage, minimumBump);
		color.blue = _brightenComponent(source.blue, percentage, minimumBump);
		color.alpha = source.alpha;
	}

	/// Returns an `ISVGTypes.Color` based on a packed representation of r, g, and b
	/// @notice Useful for code where you want to utilize rgb hex values provided by a designer (e.g. #835525)
	/// @dev Alpha will be hard-coded to 100% opacity
	/// @param packedColor The `ISVGTypes.Color` to convert, e.g. 0x835525
	/// @return color representing the packed input
	function fromPackedColor(uint24 packedColor) internal pure returns (ISVGTypes.Color memory color) {
		color.red = uint8(packedColor >> 16);
		color.green = uint8(packedColor >> 8);
		color.blue = uint8(packedColor);
		color.alpha = 0xFF;
	}

	/// Returns a mixed Color by balancing the ratio of `color1` over `color2`, with a total percentage (for overmixing and undermixing outside the source bounds)
	/// @dev Reverts with `RatioInvalid()` if `ratioPercentage` is > 100
	/// @param color1 The first `ISVGTypes.Color` to mix
	/// @param color2 The second `ISVGTypes.Color` to mix
	/// @param ratioPercentage The percentage ratio of `color1` over `color2` (e.g. 60 = 60% first, 40% second)
	/// @param totalPercentage The total percentage after mixing (for overmixing and undermixing outside the input colors)
	/// @return color representing the result of the mixture
	function mixColors(ISVGTypes.Color memory color1, ISVGTypes.Color memory color2, uint32 ratioPercentage, uint32 totalPercentage) internal pure returns (ISVGTypes.Color memory color) {
		if (ratioPercentage > 100) revert RatioInvalid();
		color.red = _mixComponents(color1.red, color2.red, ratioPercentage, totalPercentage);
		color.green = _mixComponents(color1.green, color2.green, ratioPercentage, totalPercentage);
		color.blue = _mixComponents(color1.blue, color2.blue, ratioPercentage, totalPercentage);
		color.alpha = _mixComponents(color1.alpha, color2.alpha, ratioPercentage, totalPercentage);
	}

	/// Returns a proportionally-randomized Color between the start and stop colors using a random Color seed
	/// @dev Each component (r,g,b) will move proportionally together in the direction from start to stop
	/// @param start The starting bound of the `ISVGTypes.Color` to randomize
	/// @param stop The stopping bound of the `ISVGTypes.Color` to randomize
	/// @param random An `ISVGTypes.Color` to use as a seed for randomization
	/// @return color representing the result of the randomization
	function randomizeColors(ISVGTypes.Color memory start, ISVGTypes.Color memory stop, ISVGTypes.Color memory random) internal pure returns (ISVGTypes.Color memory color) {
		uint16 percent = uint16((1320 * (uint(random.red) + uint(random.green) + uint(random.blue)) / 10000) % 101); // Range is from 0-100
		color.red = _randomizeComponent(start.red, stop.red, random.red, percent);
		color.green = _randomizeComponent(start.green, stop.green, random.green, percent);
		color.blue = _randomizeComponent(start.blue, stop.blue, random.blue, percent);
		color.alpha = 0xFF;
	}

	function _attribute(bytes memory name, bytes memory contents) private pure returns (bytes memory) {
		return abi.encodePacked(" ", name, "='", contents, "'");
	}

	function _brightenComponent(uint8 component, uint32 percentage, uint8 minimumBump) private pure returns (uint8 result) {
		uint32 wideComponent = uint32(component);
		uint32 brightenedComponent = wideComponent * (percentage + 100) / 100;
		uint32 wideMinimumBump = uint32(minimumBump);
		if (brightenedComponent - wideComponent < wideMinimumBump) {
			brightenedComponent = wideComponent + wideMinimumBump;
		}
		if (brightenedComponent > 0xFF) {
			result = 0xFF; // Clamp to 8 bits
		} else {
			result = uint8(brightenedComponent);
		}
	}

	function _colorValue(ISVGTypes.ColorAttributeKind attributeKind, bytes memory contents) private pure returns (bytes memory) {
		return abi.encodePacked(attributeKind == ISVGTypes.ColorAttributeKind.RGB ? "rgb(" : "url(#", contents, ")");
	}

	function _mixComponents(uint8 component1, uint8 component2, uint32 ratioPercentage, uint32 totalPercentage) private pure returns (uint8 component) {
		uint32 mixedComponent = (uint32(component1) * ratioPercentage + uint32(component2) * (100 - ratioPercentage)) * totalPercentage / 10000;
		if (mixedComponent > 0xFF) {
			component = 0xFF; // Clamp to 8 bits
		} else {
			component = uint8(mixedComponent);
		}
	}

	function _randomizeComponent(uint8 start, uint8 stop, uint8 random, uint16 percent) private pure returns (uint8 component) {
		if (start == stop) {
			component = start;
		} else { // This is the standard case
			(uint8 floor, uint8 ceiling) = start < stop ? (start, stop) : (stop, start);
			component = floor + uint8(uint16(ceiling - (random & 0x01) - floor) * percent / uint16(100));
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the ratio percentage provided to a function is > 100
error RatioInvalid();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ITicTacToe.sol";

/// @title Provides the on-chain metadata (including svg image) to the contract
/// @dev Supports the ERC-721 contract
interface IMetadataProvider is IERC165 {

	/// Represents the utf-8 string of the contract's player in the output image
	function contractSymbol() external returns (string memory);

	/// @dev Returns the on-chain ERC-721 metadata for a TicTacToe game given its GameUtils.GameInfo structure and tokenId
	/// @param game The game's state structure
	/// @param tokenId The game's Token Id
	/// @return The raw json uri as a string
	function metadata(ITicTacToe.Game memory game, uint256 tokenId) external view returns (string memory);

	/// Represents the utf-8 string of the owner's player in the output image
	function ownerSymbol() external returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ITicTacToe interface
interface ITicTacToe {

	/// Represents the state of a Game
	enum GameState {
		InPlay, OwnerWon, ContractWon, Tie
	}

	/// Contains aggregated information about game results
	struct GameHistory {
		uint32 wins;
		uint32 losses;
		uint32 ties;
		uint32 restarts;
	}

	/// Contains information about a TicTacToe game
	struct Game {
		uint8[] moves;
		GameState state;
		GameHistory history;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title GameConnector
abstract contract GameConnector is Ownable, IERC165 {

	/// @dev Wen the caller is not allowed
	error CallerNotAllowed();

	/// @dev The address to the game;
	mapping(address => bool) private _allowedCallers;

	/// Assigns the address to the mapping of allowed callers
	/// @dev If assigning allowed to address(0), anyone may call the `onlyAllowedCallers` functions
	/// @param caller The address of the caller with which to assign allowed
	/// @param allowed Whether the `caller` will be allowed to call `onlyAllowedCallers` functions
	function assignAllowedCaller(address caller, bool allowed) external onlyOwner {
		if (allowed) {
			_allowedCallers[caller] = allowed;
		} else {
			delete _allowedCallers[caller];
		}
	}

	/// Prevents a function from executing if not called by an allowed caller
	modifier onlyAllowedCallers() {
		if (!_allowedCallers[_msgSender()] && !_allowedCallers[address(0)]) revert CallerNotAllowed();
		_;
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public pure virtual override returns (bool) {
		return interfaceId == type(IERC165).interfaceId;
	}

	/// @inheritdoc Ownable
	function transferOwnership(address newOwner) public virtual override {
		if (newOwner != owner()) {
			delete _allowedCallers[owner()];
		}
		super.transferOwnership(newOwner);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/ITicTacToe.sol";
// import "hardhat/console.sol";

/// @title GameUtils
library GameUtils {

	/// @dev When the player attempts a change that is not valid for the current GameState
	error InvalidGameState();

	/// @dev When the player attempts to make an invalid move
	error InvalidMove();

	/// @dev When a player attempts to make multiple moves within the same block for the same game
	error NoMagic();

	/// Represents one of the game players
	enum GamePlayer {
		Contract, Owner
	}

	/// Represents the storage of a game, suitable for the contract to make choices
	struct GameInfo {
		ITicTacToe.GameState state;
		uint8 moves;
		uint8[9] board;
		uint40 blockNumber; // The block number of the last move. To save gas, not updated on a win/lose/tie
		ITicTacToe.GameHistory history;
	}

	/// @dev Constant for reporting an invalid index
	uint256 internal constant INVALID_MOVE_INDEX = 0xFF;

	/// Returns whether the bits under test match the bits being tested for
	/// @param bits The bits to test
	/// @param matchBits The bits being tested for
	/// @return Whether the bits under test match the bits being tested for
	function bitsMatch(uint256 bits, uint256 matchBits) internal pure returns (bool) {
		return (bits & matchBits) == matchBits;
	}

	/// Returns an ITicTacToe.Game from the supplied GameInfo
	/// @param gameInfo The GameInfo structure to convert
	/// @return game The converted Game structure
	function gameFromGameInfo(GameInfo memory gameInfo) internal pure returns (ITicTacToe.Game memory game) {
		game.state = gameInfo.state;
		game.history = gameInfo.history;
		game.moves = new uint8[](gameInfo.moves);
		for (uint256 move = 0; move < gameInfo.moves; move++) {
			game.moves[move] = gameInfo.board[move];
		}
	}

	/// Returns an GameInfo from the supplied ITicTacToe.Game
	/// @param game The ITicTacToe.Game structure to convert
	/// @return gameInfo The converted GameInfo structure
	function gameInfoFromGame(ITicTacToe.Game memory game) internal pure returns (GameInfo memory gameInfo) {
		gameInfo.state = game.state;
		gameInfo.history = game.history;
		gameInfo.moves = uint8(game.moves.length);
		for (uint256 move = 0; move < game.moves.length; move++) {
			gameInfo.board[move] = game.moves[move];
		}
	}

	/// Returns the index of the desired position in the GameInfo's board array
	/// @param gameInfo The GameInfo to examine
	/// @param position The position to search
	/// @return The index within the board array of the result, or `INVALID_MOVE_INDEX` if not found
	function indexOfPosition(GameInfo memory gameInfo, uint256 position) internal pure returns (uint256) {
		for (uint256 index = gameInfo.moves; index < gameInfo.board.length; index++) {
			if (position == gameInfo.board[index]) {
				return index;
			}
		}
		return INVALID_MOVE_INDEX;
	}

	/// Returns a new initialized GameUtils.GameInfo struct using the existing GameHistory
	/// @param history The history of games to attach to the new instance
	/// @param seed An initial seed for the contract's first move
	/// @param blockNumber A optional value to use as the initial block number, which will be collapsed to uint40
	/// @return A new intitialzed GameUtils.GameInfo struct
	function initializeGame(ITicTacToe.GameHistory memory history, uint256 seed, uint256 blockNumber) internal pure returns (GameUtils.GameInfo memory) {
		uint8 firstMove = uint8(seed % 9);
		uint8[9] memory board;
		board[0] = firstMove;
		for (uint256 i = 1; i < 9; i++) {
			board[i] = i <= firstMove ? uint8(i-1) : uint8(i);
		}
		return GameUtils.GameInfo(ITicTacToe.GameState.InPlay, 1, board, uint40(blockNumber), history);
	}

	/// Returns the bits representing the player's moves
	/// @param gameInfo The GameInfo structure
	/// @param gamePlayer The GamePlayer for which to generate the map
	/// @return map A single integer value representing a bitmap of the player's moves
	function mapForPlayer(GameInfo memory gameInfo, GamePlayer gamePlayer) internal pure returns (uint256 map) {
		// These are the bits for each board position
		uint16[9] memory positionsToBits = [256, 128, 64, 32, 16, 8, 4, 2, 1];
		for (uint256 index = uint256(gamePlayer); index < gameInfo.moves; index += 2) {
			uint256 position = gameInfo.board[index];
			map += positionsToBits[position];
		}
	}

	/// Updates the GameInfo structure based on the positionIndex being moved
	/// @param gameInfo The GameInfo structure
	/// @param positionIndex The index within the board array representing the desired move
	function performMove(GameInfo memory gameInfo, uint256 positionIndex) internal pure {
		uint8 movePosition = gameInfo.moves & 0x0F;
		uint8 nextPosition = gameInfo.board[positionIndex];
		gameInfo.board[positionIndex] = gameInfo.board[movePosition];
		gameInfo.board[movePosition] = nextPosition;
		gameInfo.moves += 1;
	}

	/// Returns whether the player has won based on its playerMap
	/// @param playerMap The bitmap of the player's moves
	/// @return Whether the bitmap represents a winning game
	function playerHasWon(uint256 playerMap) internal pure returns (bool) {
		// These are winning boards when bits are combined
		uint16[8] memory winningBits = [448, 292, 273, 146, 84, 73, 56, 7];
		for (uint256 index = 0; index < winningBits.length; index++) {
			if (bitsMatch(playerMap, winningBits[index])) {
				return true;
			}
		}
		return false;
	}

	/// Processes a move on an incoming GameInfo structure and returns a resulting GameInfo structure
	/// @param gameInfo The incoming GameInfo structure
	/// @param position The player's attempted move
	/// @param seed A seed used for randomness
	/// @return A resulting GameInfo structure that may also include the contract's move if the game continues
	function processMove(GameUtils.GameInfo memory gameInfo, uint256 position, uint256 seed) internal view returns (GameUtils.GameInfo memory) {
		if (gameInfo.state != ITicTacToe.GameState.InPlay) revert InvalidGameState();
		// console.log("block number %d vs %d", gameInfo.blockNumber, block.number);
		if (gameInfo.blockNumber >= block.number) revert NoMagic();
		uint256 positionIndex = indexOfPosition(gameInfo, position);
		if (positionIndex == INVALID_MOVE_INDEX) revert InvalidMove();
		// console.log("Playing position:", position); //, positionIndex, gameInfo.moves);
		performMove(gameInfo, positionIndex);

		if (gameInfo.moves < 4) { // No chance of winning just yet
			uint256 openSlot = uint8(seed % (9 - gameInfo.moves));
			// console.log(" - random move:", gameInfo.board[openSlot + gameInfo.moves]);
			performMove(gameInfo, openSlot + gameInfo.moves);
			gameInfo.blockNumber = uint40(block.number);
		} else /* if (gameInfo.moves < 9) */ { // Owner or Contract may win
			uint256 ownerMap = mapForPlayer(gameInfo, GamePlayer.Owner);
			if (playerHasWon(ownerMap)) {
				gameInfo.state = ITicTacToe.GameState.OwnerWon;
				gameInfo.history.wins += 1;
			} else {
				bool needsMove = true;
				uint256 contractMap = mapForPlayer(gameInfo, GamePlayer.Contract);
				// If the Contract has an imminent win, take it.
				for (uint256 openSlot = gameInfo.moves; openSlot < 9; openSlot++) {
					if (winableMove(contractMap, gameInfo.board[openSlot])) {
						// console.log(" - seizing move:", gameInfo.board[openSlot]); //, gameInfo.moves);
						performMove(gameInfo, openSlot);
						needsMove = false;
						break;
					}
				}
				if (needsMove) {
					// If the Owner has an imminent win, block it.
					for (uint256 openSlot = gameInfo.moves; openSlot < 9; openSlot++) {
						if (winableMove(ownerMap, gameInfo.board[openSlot])) {
							// console.log(" - blocking move:", gameInfo.board[openSlot]); //, gameInfo.moves);
							performMove(gameInfo, openSlot);
							needsMove = false;
							break;
						}
					}
				}
				if (needsMove) {
					uint256 openSlot = uint8(seed % (9 - gameInfo.moves));
					// console.log(" - random move:", gameInfo.board[openSlot + gameInfo.moves]);
					performMove(gameInfo, openSlot + gameInfo.moves);
				}
				if (playerHasWon(mapForPlayer(gameInfo, GamePlayer.Contract))) {
					gameInfo.state = ITicTacToe.GameState.ContractWon;
					gameInfo.history.losses += 1;
				} else if (gameInfo.moves > 8) {
					gameInfo.state = ITicTacToe.GameState.Tie;
					gameInfo.history.ties += 1;
				} else {
					gameInfo.blockNumber = uint40(block.number);
				}
			}
		}
		return gameInfo;
	}

	/// Returns whether the next position would result in a winning board if applied
	/// @param playerMap The bitmap representing the player's current moves
	/// @param nextPosition The next move being considered
	/// @return Whether the next position would result in a winning board
	function winableMove(uint256 playerMap, uint256 nextPosition) internal pure returns (bool) {
		if (nextPosition == 0) {
			return bitsMatch(playerMap, 192) || bitsMatch(playerMap, 36) || bitsMatch(playerMap, 17);
		} else if (nextPosition == 1) {
			return bitsMatch(playerMap, 320) || bitsMatch(playerMap, 18);
		} else if (nextPosition == 2) {
			return bitsMatch(playerMap, 384) || bitsMatch(playerMap, 20) || bitsMatch(playerMap, 9);
		} else if (nextPosition == 3) {
			return bitsMatch(playerMap, 260) || bitsMatch(playerMap, 24);
		} else if (nextPosition == 4) {
			return bitsMatch(playerMap, 257) || bitsMatch(playerMap, 130) || bitsMatch(playerMap, 68) || bitsMatch(playerMap, 40);
		} else if (nextPosition == 5) {
			return bitsMatch(playerMap, 65) || bitsMatch(playerMap, 48);
		} else if (nextPosition == 6) {
			return bitsMatch(playerMap, 288) || bitsMatch(playerMap, 80) || bitsMatch(playerMap, 3);
		} else if (nextPosition == 7) {
			return bitsMatch(playerMap, 144) || bitsMatch(playerMap, 5);
		} else /* if (nextPosition == 8) */ {
			return bitsMatch(playerMap, 272) || bitsMatch(playerMap, 72) || bitsMatch(playerMap, 6);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@theappstudio/solidity/contracts/utils/SVG.sol";
import "../interfaces/IMetadataProvider.sol";
import "../utils/GameUtils.sol";
import "./GameConnector.sol";

/// @title RobotVsMeat
contract RobotVsMeat is GameConnector, IMetadataProvider {

	using Strings for uint256;

	string private constant _CONTRACT_SYMBOL = "\xF0\x9F\xA4\x96";
	string private constant _OWNER_SYMBOL = "\xF0\x9F\xA5\xA9";

	/// @inheritdoc IMetadataProvider
	function contractSymbol() external pure returns (string memory) {
		return _CONTRACT_SYMBOL;
	}

	/// @inheritdoc IMetadataProvider
	function metadata(ITicTacToe.Game memory game, uint256 tokenId) external view onlyAllowedCallers returns (string memory) {
		return string(OnChain.tokenURI(OnChain.dictionary(OnChain.commaSeparated(
			OnChain.keyValueString("name",  abi.encodePacked("Game ", tokenId.toString())),
			OnChain.keyValueArray("attributes", _attributesFromGame(game)),
			OnChain.keyValueString("image", OnChain.svgImageURI(_createSvg(game)))
		))));
	}

	/// @inheritdoc IMetadataProvider
	function ownerSymbol() external pure returns (string memory) {
		return _OWNER_SYMBOL;
	}

	/// @inheritdoc IERC165
	function supportsInterface(bytes4 interfaceId) public pure override(GameConnector, IERC165) returns (bool) {
		return interfaceId == type(IMetadataProvider).interfaceId || super.supportsInterface(interfaceId);
	}

	function _attributesFromGame(ITicTacToe.Game memory game) private pure returns (bytes memory) {
		return OnChain.commaSeparated(
			OnChain.traitAttribute("Wins", bytes(uint256(game.history.wins).toString())),
			OnChain.traitAttribute("Losses", bytes(uint256(game.history.losses).toString())),
			OnChain.traitAttribute("Ties", bytes(uint256(game.history.ties).toString())),
			OnChain.traitAttribute("Restarts", bytes(uint256(game.history.restarts).toString())),
			OnChain.traitAttribute("Voting Power", bytes(uint256(game.history.wins).toString()))
		);
	}

	function _boardElements() private pure returns (bytes memory) {
		return abi.encodePacked(
			_rectElement(100, 100, " fill='whitesmoke'"),
			_rectElement(100, 5, _boardElementAttributes(0, 30)),
			_rectElement(100, 5, _boardElementAttributes(0, 65)),
			_rectElement(5, 100, _boardElementAttributes(30, 0)),
			_rectElement(5, 100, _boardElementAttributes(65, 0)),
			_slotElements()
		);
	}

	function _boardElementAttributes(uint256 xPercent, uint256 yPercent) private pure returns (bytes memory) {
		return abi.encodePacked(" x='", xPercent.toString(), "%' y='", yPercent.toString(), "%' fill='black'");
	}

	function _createSvg(ITicTacToe.Game memory game) private pure returns (bytes memory) {
		return SVG.createElement("svg", SVG.svgAttributes(540, 540), abi.encodePacked(
			_defsForSvg(),
			SVG.createElement("g", " clip-path='url(#clip)'", abi.encodePacked(
				_boardElements(),
				_movesForGame(game),
				_winningCrosses(game)
			))
		));
	}

	function _defsForSvg() private pure returns (bytes memory) {
		return SVG.createElement("defs", "", abi.encodePacked(
			_winFilter(),
			_winElements(),
			SVG.createElement("clipPath", " id='clip'", _rectElement(100, 100, ""))
		));
	}

	function _movesForGame(ITicTacToe.Game memory game) private pure returns (bytes memory result) {
		uint8[3] memory xPercentages = [15, 50, 85];
		uint8[3] memory yPercentages = [19, 54, 89];
		result = ""; // <text x="15%" y="19%" dominant-baseline='middle' text-anchor='middle' font-size='22em'>X</text>
		for (uint256 move = 0; move < game.moves.length; move++) {
			uint256 position = game.moves[move];
			bytes memory attributes = abi.encodePacked(" font-size='10em' x='", uint256(xPercentages[position % 3]).toString(), "%' text-anchor='middle' y='", uint256(yPercentages[position / 3]).toString(), "%' dominant-baseline='middle'");
			result = abi.encodePacked(result, SVG.createElement("text", attributes, move % 2 == 0 ? bytes(_CONTRACT_SYMBOL) : bytes(_OWNER_SYMBOL)));
		}
	}

	function _rectElement(uint256 widthPercentage, uint256 heightPercentage, bytes memory attributes) private pure returns (bytes memory) {
		return abi.encodePacked("<rect width='", widthPercentage.toString(), "%' height='", heightPercentage.toString(), "%'", attributes, "/>");
	}

	function _slotElements() private pure returns (bytes memory result) {
		uint8[3] memory percentages = [29, 64, 99];
		result = ""; // <text x='29%' y='29%' text-anchor='end' filter='url(#roughtext)' font-size='2em'>0</text>
		for (uint256 slot = 0; slot < 9; slot++) {
			bytes memory attributes = abi.encodePacked(" font-size='1em' x='", uint256(percentages[slot % 3]).toString(), "%' text-anchor='end' y='", uint256(percentages[slot / 3]).toString(), "%' filter='url(#roughtext)'");
			result = abi.encodePacked(result, SVG.createElement("text", attributes, bytes(slot.toString())));
		}
	}

	function _useElement(uint256 x, uint256 y, string memory name) private pure returns (bytes memory) {
		return abi.encodePacked("<use stroke-linecap='round' x='", x.toString(), "%' y='", y.toString(), "%' filter='url(#win)' href='#", name, "' stroke='red'/>");
	}

	function _winElements() private pure returns (bytes memory) {
		// 'M0 0 M90 90' works around a Chrome rendering issue
		return abi.encodePacked(
			_winPath("horizontal", "M0 0 M90 90 M81 81 L459 81"),
			_winPath("vertical", "M0 0 M90 90 M81 81 L81 459"),
			_winPath("criss", "M81 81 L459 459"),
			_winPath("cross", "M459 81 L81 459")
		);
	}

	function _winFilter() private pure returns (bytes memory) {
		return SVG.createElement("filter", " id='win'",
			abi.encodePacked(
				"<feColorMatrix type='matrix' values='1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0'/>",
				"<feComposite operator='in' in2='SourceGraphic'/>"
			)
		);
	}

	function _winningCrosses(ITicTacToe.Game memory game) private pure returns (bytes memory) {
		if (game.state == ITicTacToe.GameState.OwnerWon) {
			GameUtils.GameInfo memory gameInfo = GameUtils.gameInfoFromGame(game);
			return _winningCrossesForMap(GameUtils.mapForPlayer(gameInfo, GameUtils.GamePlayer.Owner));
		} else if (game.state == ITicTacToe.GameState.ContractWon) {
			GameUtils.GameInfo memory gameInfo = GameUtils.gameInfoFromGame(game);
			return _winningCrossesForMap(GameUtils.mapForPlayer(gameInfo, GameUtils.GamePlayer.Contract));
		}
		return "";
	}

	function _winningCrossesForMap(uint256 map) private pure returns (bytes memory result) {
		result = "";
		if (GameUtils.bitsMatch(map, 448)) {
			result = abi.encodePacked(result, _useElement(0, 0, "horizontal"));
		}
		if (GameUtils.bitsMatch(map, 292)) {
			result = abi.encodePacked(result, _useElement(0, 0, "vertical"));
		}
		if (GameUtils.bitsMatch(map, 273)) {
			result = abi.encodePacked(result, _useElement(0, 0, "criss"));
		}
		if (GameUtils.bitsMatch(map, 146)) {
			result = abi.encodePacked(result, _useElement(35, 0, "vertical"));
		}
		if (GameUtils.bitsMatch(map, 84)) {
			result = abi.encodePacked(result, _useElement(0, 0, "cross"));
		}
		if (GameUtils.bitsMatch(map, 73)) {
			result = abi.encodePacked(result, _useElement(70, 0, "vertical"));
		}
		if (GameUtils.bitsMatch(map, 56)) {
			result = abi.encodePacked(result, _useElement(0, 35, "horizontal"));
		}
		if (GameUtils.bitsMatch(map, 7)) {
			result = abi.encodePacked(result, _useElement(0, 70, "horizontal"));
		}
		return result;
	}

	function _winPath(string memory id, string memory path) private pure returns (bytes memory) {
		return abi.encodePacked("<path id='", id, "' d='", path, "' stroke-width='4%'/>");
	}
}