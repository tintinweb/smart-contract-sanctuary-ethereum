/*
TextMetadata

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IMembership.sol";
import "./interfaces/IPlugin.sol";
import "./interfaces/IResolver.sol";

library TextMetadata {
  using Strings for uint256;

  struct Style {
    string bg;
    string fg;
    string font;
    uint256 scale;
  }

  /**
   * @notice provide the metadata URI for a membership token class
   * @param membership address of membership contract
   * @param id identifier for membership class
   * @param params optional encoded style for svg (background color, text color, text font, scale)
   */
  function uri(
    address membership,
    uint256 id,
    bytes calldata params
  ) external view returns (string memory) {
    IMembership m = IMembership(membership);

    uint256 pluginCount = m.pluginCount(id);

    // svg style config
    Style memory style = Style("black", "white", "Monospace", 1);
    if (params.length > 0) {
      (style.bg, style.fg, style.font, style.scale) = abi.decode(
        params,
        (string, string, string, uint256)
      );
    }

    // attributes
    bytes memory props = "{";
    for (uint256 i = 0; i < pluginCount; i++) {
      (address plugin, uint256 pclass) = m.plugin(id, i);
      props = abi.encodePacked(
        props,
        '"plugin_',
        i.toString(),
        '":"',
        _sanitize(IPlugin(plugin).metadata(pclass)),
        '",'
      );
    }
    {
      (address resolver, bytes memory resolverParams) = m.resolver(id);
      props = abi.encodePacked(
        props,
        '"resolver":"',
        _sanitize(IResolver(resolver).metadata(resolverParams)),
        '"}'
      );
    }

    // svg
    bytes memory svg = abi.encodePacked(
      '<svg width="',
      (style.scale * 256).toString(),
      '" height="',
      (style.scale * 256).toString(),
      '" fill="',
      style.fg,
      '" font-size="',
      (style.scale * 12).toString(),
      '" font-family="',
      style.font,
      '" xmlns="http://www.w3.org/2000/svg">',
      '<rect x="0" y="0" width="100%" height="100%" style="fill:',
      style.bg,
      '" />'
    );

    svg = abi.encodePacked(
      svg,
      '<text font-size="100%" y="10%" x="5%">',
      m.name(),
      "</text>",
      '<text font-size="80%" y="18%" x="5%">Class #',
      id.toString(),
      "</text>"
    );

    uint256 y = 30;
    for (uint256 i = 0; i < pluginCount; i++) {
      (address plugin, uint256 pclass) = m.plugin(id, i);
      svg = abi.encodePacked(
        svg,
        '<text font-size="60%" y="',
        y.toString(),
        '%" x="5%">',
        IPlugin(plugin).metadata(pclass),
        "</text>"
      );
      y += 8;
    }
    {
      (address resolver, bytes memory resolverParams) = m.resolver(id);
      svg = abi.encodePacked(
        svg,
        '<text font-size="60%" y="',
        y.toString(),
        '%" x="5%">',
        IResolver(resolver).metadata(resolverParams),
        "</text></svg>"
      );
    }

    // assemble metadata
    bytes memory data = abi.encodePacked(
      '{"name":"',
      _sanitize(m.name()),
      ": ",
      id.toString(),
      '","description":"Class #',
      id.toString(),
      " of the ",
      _sanitize(m.name()),
      ' membership program, powered by Passage Protocol","image":"data:image/svg+xml;base64,',
      Base64.encode(svg),
      '","properties":',
      props,
      "}"
    );
    return
      string(
        abi.encodePacked("data:application/json;base64,", Base64.encode(data))
      );
  }

  /**
   * @dev helper method to sanitize string for invalid json characters
   */
  function _sanitize(string memory s) internal pure returns (string memory) {
    bytes memory b = bytes(s);
    for (uint256 i = 0; i < b.length; i++) {
      if (b[i] == 0x22) {
        b[i] = 0x27; // " -> '
      } else if (b[i] == 0x5c) {
        b[i] = 0x2f; // \ -> /
      }
    }
    return string(b);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

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

        /// @solidity memory-safe-assembly
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

/*
IMembership

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC1155MetadataURI.sol";

pragma solidity 0.8.9;

interface IMembership is IERC1155, IERC1155MetadataURI {
  /**
   * @notice get name of membership program
   */
  function name() external view returns (string memory);

  /**
   * @notice get list of all class ids associated with membership program
   */
  function classes() external view returns (uint256[] memory);

  /**
   * @notice get membership of user
   * @param user address of user
   * @param class id of membership class
   */
  function membership(address user, uint256 class)
    external
    view
    returns (uint256);

  /**
   * @notice update cached user balance and emit any associated mint or burn events
   * @param user address of user
   */
  function update(address user) external;

  /**
   * @notice register class definition for membership program
   * @param class membership class id
   * @param plugins list of plugin addresses
   * @param pclasses list of plugin class ids
   * @param resolver address of resolver library
   * @param params arbitrary bytes data for additional resolver parameters
   */
  function register(
    uint256 class,
    address[] calldata plugins,
    uint256[] calldata pclasses,
    address resolver,
    bytes calldata params
  ) external;

  /**
   * @notice getter for registered class plugin data
   */
  function plugin(uint256 class, uint256 index)
    external
    view
    returns (address plugin, uint256 pclass);

  /**
   * @notice getter for registered class plugin count
   */
  function pluginCount(uint256 class) external view returns (uint256);

  /**
   * @notice getter for registered class resolver data
   */
  function resolver(uint256 class)
    external
    view
    returns (address resolver, bytes memory params);

  /**
   * @notice getter for metadata provider and params
   */
  function metadata()
    external
    view
    returns (address metadata, bytes memory params);
}

/*
IPlugin

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface IPlugin {
  /**
   * @notice get metadata about plugin class
   * @param pclass id of membership class
   */
  function metadata(uint256 pclass) external view returns (string memory);

  /**
   * @notice get membership shares for user
   * @param user address of user
   * @param pclass id of membership class
   */
  function shares(address user, uint256 pclass) external view returns (uint256);
}

/*
IResolver

https://github.com/passage-protocol/toll-booth

SPDX-License-Identifier: UNLICENSED
*/

pragma solidity 0.8.9;

interface IResolver {
  /**
   * @notice resolve class membership from underlying plugin shares
   * @param shares list of shares from plugin classes
   * @param params additional encoded data needed by resolver
   */
  function resolve(uint256[] calldata shares, bytes calldata params)
    external
    pure
    returns (uint256);

  /**
   * @notice get a metadata string about the resolver
   * @param params encoded data
   */
  function metadata(bytes calldata params)
    external
    pure
    returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/extensions/IERC1155MetadataURI.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}