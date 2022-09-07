// SPDX-License-Identifier: MIT

/*
 *                ,dPYb,   I8         ,dPYb,
 *                IP'`Yb   I8         IP'`Yb
 *                I8  8I88888888 gg   I8  8I
 *                I8  8'   I8    ""   I8  8'
 *   ,ggg,,ggg,   I8 dP    I8    gg   I8 dP   ,ggg,     ,g,
 *  ,8" "8P" "8,  I8dP     I8    88   I8dP   i8" "8i   ,8'8,
 *  I8   8I   8I  I8P     ,I8,   88   I8P    I8, ,8I  ,8'  Yb
 * ,dP   8I   Yb,,d8b,_  ,d88b,_,88,_,d8b,_  `YbadP' ,8'_   8)
 * 8P'   8I   `Y8PI8"888 8P""Y88P""Y88P'"Y88888P"Y888P' "YY8P8P
 *                I8 `8,
 *                I8  `8,
 *                I8   8I
 *                I8   8I
 *                I8, ,8'
 *                 "Y8P'
 */

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "base64-sol/base64.sol";
import "./ITileRenderer.sol";

contract TileRenderer is ITileRenderer, ERC165 {
    uint24[] palette = [
        0x000000,
        0x959595,
        0xe89c9f,
        0xf4c892,
        0xfff8a5,
        0x92c8a0,
        0x86cdf2,
        0x9d87ba,
        0xf0f0f0,
        0x6f4e2b,
        0xda3832,
        0xea983e,
        0xfff34a,
        0x00a359,
        0x006fb6,
        0x5f308c
    ];

    function renderTileMetadata(uint256 number, uint256 _id)
        external
        view
        returns (string memory)
    {
        string memory tileNumber = uint2str(number);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"Tile ',
                                tileNumber,
                                '", "description":"Tile ',
                                tileNumber,
                                ' is an on-chain canvas", "image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(renderTile(_id, palette))),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function renderTile(uint256 _id) external view returns (string memory) {
        return renderTile(_id, palette);
    }

    function renderTile(uint256 _colors, uint24[] memory _palette)
        internal
        pure
        returns (string memory)
    {
        string memory tile;
        tile = string(
            '<svg xmlns="http://www.w3.org/2000/svg" width="800" height="800" shape-rendering="crispEdges">'
        );
        for (uint8 i = 0; i < 8; i = i + 1) {
            tile = string(
                abi.encodePacked(tile, renderRow(_colors, i, _palette))
            );
        }
        tile = string(abi.encodePacked(tile, "</svg>"));
        return tile;
    }

    function renderRow(
        uint256 _colors,
        uint8 _row,
        uint24[] memory _palette
    ) internal pure returns (string memory) {
        string memory row;
        for (uint8 i = 0; i < 8; i = i + 1) {
            // The data is encoded as 64 4-bit integers.
            uint8 colorIndex = uint8(_colors >> (((8 * _row) + i) * 4)) & 0x0f;
            string memory color = uint24tohexstr(_palette[colorIndex]);
            row = string(
                abi.encodePacked(
                    row,
                    '<rect x="',
                    uint8tohexchar(uint8(i & 0x0f)),
                    '00" y="',
                    uint8tohexchar(uint8(_row & 0x0f)),
                    '00" width="100" height="100" style="fill:#',
                    color,
                    ';" />'
                )
            );
        }
        return row;
    }

    function uint8tohexchar(uint8 i) internal pure returns (uint8) {
        return (i > 9) ? (i + 87) : (i + 48);
    }

    function uint24tohexstr(uint24 i) internal pure returns (string memory) {
        bytes memory o = new bytes(6);
        uint24 mask = 0x00000f;
        o[5] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[4] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[3] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[2] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[1] = bytes1(uint8tohexchar(uint8(i & mask)));
        i = i >> 4;
        o[0] = bytes1(uint8tohexchar(uint8(i & mask)));
        return string(o);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165, ERC165)
        returns (bool)
    {
        return
            interfaceId == type(ITileRenderer).interfaceId ||
            super.supportsInterface(interfaceId);
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

/*
 *                ,dPYb,   I8         ,dPYb,
 *                IP'`Yb   I8         IP'`Yb
 *                I8  8I88888888 gg   I8  8I
 *                I8  8'   I8    ""   I8  8'
 *   ,ggg,,ggg,   I8 dP    I8    gg   I8 dP   ,ggg,     ,g,
 *  ,8" "8P" "8,  I8dP     I8    88   I8dP   i8" "8i   ,8'8,
 *  I8   8I   8I  I8P     ,I8,   88   I8P    I8, ,8I  ,8'  Yb
 * ,dP   8I   Yb,,d8b,_  ,d88b,_,88,_,d8b,_  `YbadP' ,8'_   8)
 * 8P'   8I   `Y8PI8"888 8P""Y88P""Y88P'"Y88888P"Y888P' "YY8P8P
 *                I8 `8,
 *                I8  `8,
 *                I8   8I
 *                I8   8I
 *                I8, ,8'
 *                 "Y8P'
 */

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface ITileRenderer is IERC165 {
    function renderTileMetadata(uint256 number, uint256 _id)
        external
        view
        returns (string memory);

    function renderTile(uint256 _id) external view returns (string memory);
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