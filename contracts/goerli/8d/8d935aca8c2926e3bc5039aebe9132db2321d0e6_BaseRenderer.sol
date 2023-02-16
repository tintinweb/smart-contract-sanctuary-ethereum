// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but we allocate 160 bytes
            // to keep the free memory pointer word aligned. We'll need 1 word for the length, 1 word for the
            // trailing zeros padding, and 3 other words for a max of 78 digits. In total: 5 * 32 = 160 bytes.
            let newFreeMemoryPointer := add(mload(0x40), 160)

            // Update the free memory pointer to avoid overriding our string.
            mstore(0x40, newFreeMemoryPointer)

            // Assign str to the end of the zone of newly allocated memory.
            str := sub(newFreeMemoryPointer, 32)

            // Clean the last word of memory it may not be overwritten.
            mstore(str, 0)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                // Move the pointer 1 byte to the left.
                str := sub(str, 1)

                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))

                // Keep dividing temp until zero.
                temp := div(temp, 10)

                 // prettier-ignore
                if iszero(temp) { break }
            }

            // Compute and cache the final total length of the string.
            let length := sub(end, str)

            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 32)

            // Store the string's length at the start of memory allocated for our string.
            mstore(str, length)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { LibString } from "solmate/utils/LibString.sol";

import { ITokenRenderer } from "@/contracts/interfaces/ITokenRenderer.sol";

contract BaseRenderer is ITokenRenderer {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice A lookup table for hex characters.
    uint256 private constant UINT_LUT = 0x46454443424139383736353433323130;

    /// @notice The SVG header.
    string constant SVG_HEADER = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 8 8">';

    /// @notice The SVG footer.
    string constant SVG_FOOTER = "</svg>";

    // -------------------------------------------------------------------------
    // Functions
    // -------------------------------------------------------------------------

    /// @inheritdoc ITokenRenderer
    function render(uint256 _id, uint8 _phase) external pure override returns (string memory) {
        uint256 seed = uint256(keccak256(abi.encodePacked(_id)));
        // TODO: if (_phase == 1) return shields;

        uint256 fill = seed & 0xFFFFFF;
        seed >>= 24;

        string memory svg = SVG_HEADER;
        for (uint256 i = 0xEFAE78CF2C70AEAA688E28606DA6584D24502CA2480C2040; i != 0; i >>= 6) {
            if (seed & 1 == 1) {
                (uint256 x, uint256 y) = (i & 7, (i >> 3) & 7);
                uint256 darkenedFill = darkenColor(fill, _phase == 2 ? seed & 3 : 0);

                svg = string.concat(svg, rect(x, y, darkenedFill));
                unchecked {
                    svg = string.concat(svg, rect(7 - x, y, darkenedFill));
                }
            }

            seed >>= 1;
        }

        return string.concat(svg, SVG_FOOTER);
    }

    function rect(uint256 _x, uint256 _y, uint256 _fill) internal pure returns (string memory) {
        return string.concat(
            '<rect width="1" height="1" x="',
            LibString.toString(_x),
            '" y="',
            LibString.toString(_y),
            '" fill="#',
            toHexString(_fill),
            '" />'
        );
    }

    function toHexString(uint256 _a) internal pure returns (string memory) {
        bytes memory b = new bytes(32);

        uint256 data = (((UINT_LUT >> (((_a >> 20) & 0xF) << 3)) & 0xFF) << 40)
            | (((UINT_LUT >> (((_a >> 16) & 0xF) << 3)) & 0xFF) << 32)
            | (((UINT_LUT >> (((_a >> 12) & 0xF) << 3)) & 0xFF) << 24)
            | (((UINT_LUT >> (((_a >> 8) & 0xF) << 3)) & 0xFF) << 16)
            | (((UINT_LUT >> (((_a >> 4) & 0xF) << 3)) & 0xFF) << 8)
            | ((UINT_LUT >> ((_a & 0xF) << 3)) & 0xFF);

        assembly {
            mstore(add(b, 32), data)
        }

        return string(b);
    }

    function darkenColor(uint256 _color, uint256 _num) internal pure returns (uint256) {
        return (((_color >> 0x10) >> _num) << 0x10) | ((((_color >> 8) & 0xFF) >> _num) << 8)
            | ((_color & 0xFF) >> _num);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for puzzle's token renderers on Curta
/// @notice A token renderer is responsible for generating a token's image URI,
/// which will be returned as part of the token's URI. Curta comes with a base
/// renderer initialized at deploy, but a puzzle author may set a custom token
/// renderer contract. If it is not set, Curta's base renderer will be used.
/// @dev The image URI must be a valid SVG image.
interface ITokenRenderer {
    /// @notice Generates a string of some token's SVG image.
    /// @param _id The ID of a token.
    /// @param _phase The phase the token was solved in.
    /// @return The new URI of a token.
    function render(uint256 _id, uint8 _phase) external view returns (string memory);
}