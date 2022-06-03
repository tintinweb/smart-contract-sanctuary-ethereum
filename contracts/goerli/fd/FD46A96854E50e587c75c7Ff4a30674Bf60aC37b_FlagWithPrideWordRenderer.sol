//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/Base64.sol';

import './IRenderer.sol';

contract FlagWithPrideWordRenderer is IRenderer {
    function description() external pure returns (string memory) {
        return
            'The original 8-stripe rainbow flag with the word PRIDE written on it in 20 languages, automatically changing every 1969 blocks.';
    }

    function render(bytes32)
        external
        view
        override
        returns (string memory imageURI, string memory animationURI)
    {
        imageURI = Base64.toB64SVG(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1280 800">'
                '<path fill="#8e008e" d="M0 0h1280v800H0z"/>'
                '<path fill="#400098" d="M0 0h1280v700H0z"/>'
                '<path fill="#00c0c0" d="M0 0h1280v600H0z"/>'
                '<path fill="#008e00" d="M0 0h1280v500H0z"/>'
                '<path fill="#ffff00" d="M0 0h1280v400H0z"/>'
                '<path fill="#ff8e00" d="M0 0h1280v300H0z"/>'
                '<path fill="#ff0000" d="M0 0h1280v200H0z"/>'
                '<path fill="#ff69b4" d="M0 0h1280v100H0z"/>'
                '<text x="50%" y="50%" text-anchor="middle" dominant-baseline="central" font-size="150px"'
                ' font-weight="bold" fill="#fff" font-family="sans-serif" style="text-shadow:2px 2px 7px #000;text-transform:uppercase;">',
                _pickWord(),
                '</text></svg>'
            )
        );

        animationURI = '';
    }

    function _pickWord() internal view returns (string memory) {
        string[20] memory words = [
            'pride',
            unicode'fierté',
            'stolz',
            'orgullo',
            unicode'qürur',
            'orgoglio',
            'stolt',
            unicode'ความภาคภูมิใจ',
            'lepnums',
            'duma',
            unicode'mândrie',
            'orgulho',
            'ponos',
            'stolthet',
            'sharaf',
            unicode'自豪',
            'fahari',
            'kareueus',
            'kburija',
            'ylpeys'
        ];

        return words[(block.number / 1969) % words.length];
    }
}

pragma solidity ^0.8.0;

interface IRenderer {
    function description() external view returns (string memory);

    function render(bytes32 seed)
        external
        view
        returns (string memory, string memory);
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64

/// modified to add some utility functions
library Base64 {
    string internal constant TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

    function toB64JSON(bytes memory toEncode)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    encode(toEncode)
                )
            );
    }

    function toB64JSON(string memory toEncode)
        internal
        pure
        returns (string memory)
    {
        return toB64JSON(bytes(toEncode));
    }

    function toB64SVG(bytes memory toEncode)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked('data:image/svg+xml;base64,', encode(toEncode))
            );
    }

    function toB64SVG(string memory toEncode)
        internal
        pure
        returns (string memory)
    {
        return toB64SVG(bytes(toEncode));
    }
}