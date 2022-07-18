// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "./Sanitize.sol";
import "./Creatable.sol";
import "./IImageRenderer.sol";
import "openzeppelin/utils/Strings.sol";

contract ImageRenderer is IImageRenderer {
    using Strings for uint8;
    using Strings for uint256;
    using Sanitize for string;

    string constant DATA_URL_SVG_IMAGE = "data:image/svg+xml;utf8,";

    function imageURL(uint256 tokenID, string calldata style)
        external
        pure
        override
        returns (string memory)
    {
        return string.concat(DATA_URL_SVG_IMAGE, svg(tokenID, style));
    }

    function svg(uint256 tokenID, string memory style)
        public
        pure
        returns (string memory)
    {
        string memory s = string.concat(
            "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'>"
            "<style>svg{background:white} rect{fill:black;width:1px;height:1px} ",
            style,
            "</style>"
        );

        for (uint256 i = 0; i < 256; ++i) {
            uint256 shift = 255 - i;
            if (tokenID & (1 << shift) != 0) {
                string memory x = (i % 16).toString();
                string memory y = (i / 16).toString();
                s = string.concat(
                    s,
                    "<rect class='x",
                    x,
                    " y",
                    y,
                    "' x='",
                    x,
                    "' y='",
                    y,
                    "'/>"
                );
            }
        }
        return string.concat(s, "</svg>");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Sanitize {
    /// @notice 34 for double quote, 39 for single quote
    function sanitizeForJSON(string memory s, uint8 quote)
        internal
        pure
        returns (string memory)
    {
        bytes memory b = bytes(s);
        uint8 ch;
        for (uint256 i = 0; i < b.length; i++) {
            ch = uint8(b[i]);
            if (
                ch < 32 || // "
                ch == quote
            ) {
                b[i] = " ";
            } else {
                b[i] = bytes1(ch);
            }
        }
        return string(b);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract Creatable {
    error CreatorOnly();

    /// @notice Creator of the token.
    mapping(uint256 => address) public creatorOf;

    /// @notice Creator can change the creator address
    /// @param tokenID the ID of the token
    /// @param newCreator the new creator address
    function setCreator(uint256 tokenID, address newCreator)
        external
        virtual
        creatorOnly(tokenID)
    {
        creatorOf[tokenID] = newCreator;
    }

    modifier creatorOnly(uint256 tokenID) {
        if (creatorOf[tokenID] != msg.sender) {
            revert CreatorOnly();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

abstract contract IImageRenderer {
    function imageURL(uint256 tokenID, string memory style)
        external
        view
        virtual
        returns (string memory);
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