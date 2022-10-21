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

pragma solidity ^0.8.15;

interface ITokenMetadata {
    function baseURI() external view returns (string memory);

    function baseURILocked() external view returns (bool);

    function uriSuffix() external view returns (string memory);

    function uriSuffixLocked() external view returns (bool);

    function fallbackURI() external view returns (string memory);

    function fallbackURILocked() external view returns (bool);

    function lastLockedTokenId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./ITokenMetadata.sol";
import "./TokenMetadataStorage.sol";

/**
 * @title NFT Token Metadata
 * @notice Provides common functions for various NFT metadata standards. This extension supports base URI, per-token URI, and a fallback URI. You can also freeze URIs until a certain token ID.
 *
 * @custom:type eip-2535-facet
 * @custom:category NFTs
 * @custom:provides-interfaces ITokenMetadata
 */
contract TokenMetadata is ITokenMetadata {
    function baseURI() external view virtual returns (string memory) {
        return TokenMetadataStorage.layout().baseURI;
    }

    function fallbackURI() external view virtual returns (string memory) {
        return TokenMetadataStorage.layout().fallbackURI;
    }

    function uriSuffix() external view virtual returns (string memory) {
        return TokenMetadataStorage.layout().uriSuffix;
    }

    function baseURILocked() external view virtual returns (bool) {
        return TokenMetadataStorage.layout().baseURILocked;
    }

    function fallbackURILocked() external view virtual returns (bool) {
        return TokenMetadataStorage.layout().fallbackURILocked;
    }

    function uriSuffixLocked() external view virtual returns (bool) {
        return TokenMetadataStorage.layout().uriSuffixLocked;
    }

    function lastLockedTokenId() external view virtual returns (uint256) {
        return TokenMetadataStorage.layout().lastLockedTokenId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library TokenMetadataStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.TokenMetadata");

    struct Layout {
        string baseURI;
        bool baseURILocked;
        string fallbackURI;
        bool fallbackURILocked;
        string uriSuffix;
        bool uriSuffixLocked;
        uint256 lastLockedTokenId;
        mapping(uint256 => string) tokenURIs;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}