// SPDX-License-Identifier: MIT
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

import "Strings.sol";
import "IMetadata.sol";

/// @title ERC-721 Non-Fungible Token Standard, metadata extension
/// @author Shadow Syndicate / Andrey Pelipenko ([email protected])
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///      Can be changed in future to support new features
contract Metadata is IMetadata {
    using Strings for uint256;
    string public baseURI;
    string public contractUri;

    constructor(string memory _baseURI, string memory _contractURI) {
        baseURI = _baseURI;
        contractUri = _contractURI;
    }

    /// @notice Returns token metadata URI according to IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /// @notice Returns roach name by index
    /// @dev In future realizations there will a possibility to change name
    function getName(uint256 tokenId) external view returns (string memory) {
        return string(abi.encodePacked("Roach ", tokenId.toString()));
    }

    /// @notice Returns whole collection metadata URI
    function contractURI() external view returns (string memory) {
        return contractUri;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
// Roach Racing Club: the first strategic p2e game with deflationary mechanisms (https://roachracingclub.com/)
pragma solidity ^0.8.10;

/// @title ERC-721 Non-Fungible Token Standard, metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface IMetadata {

    /// @notice Returns token metadata URI according to IERC721Metadata
    function tokenURI(uint256 tokenId) external view returns (string memory);

    /// @notice Returns whole collection metadata URI
    function contractURI() external view returns (string memory);

    /// @notice Returns roach name by index
    function getName(uint256 tokenId) external view returns (string memory);

}