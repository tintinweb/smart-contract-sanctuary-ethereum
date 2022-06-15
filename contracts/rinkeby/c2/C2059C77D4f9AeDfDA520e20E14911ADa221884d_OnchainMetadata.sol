// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Base64.sol";

contract OnchainMetadata {

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        string memory charName = "Reza";
        string memory charInfo = "this is the first try";
        uint256 credit = 1 ether;

        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(
            '{',
                '"name": "', charName, '", ',
                '"description": "', charInfo, '", ',
                '"image": "', _image(charName, charInfo, credit), '"', 
            '}'
            ))
        )); 
    }

    function _image(
        string memory charName,
        string memory charInfo,
        uint256 credit
    ) internal pure returns(string memory) {
        return string(abi.encodePacked(
            'data:image/svg+xml;base64,', Base64.encode(abi.encodePacked(
                '<svg width="560" height="687" xmlns="http://www.w3.org/2000/svg" fill="none"><defs><clipPath id="a"><rect id="svg_1" rx="40" height="687" width="560" fill="#fff"/></clipPath><clipPath id="e"><path id="svg_2" fill="#fff" d="m170,32l58,0l0,51l-58,0l0,-51z"/></clipPath><radialGradient gradientUnits="userSpaceOnUse" gradientTransform="rotate(90 -32 312) scale(372.991)" r="1" cy="0" cx="0" id="b"><stop stop-opacity="0" stop-color="#fff" offset="0.46"/><stop stop-color="#fff" offset="1"/></radialGradient><radialGradient gradientUnits="userSpaceOnUse" gradientTransform="rotate(90 -32 311.5) scale(603.5)" r="1" cy="0" cx="0" id="c"><stop stop-opacity="0" stop-color="#fff" offset="0.46"/><stop stop-color="#fff" offset="1"/></radialGradient><filter height="200%" width="200%" y="-50%" x="-50%" id="svg_18_blur"><feGaussianBlur stdDeviation="4.9" in="SourceGraphic"/></filter></defs><g><title>Layer 1</title><g id="svg_3" clip-path="url(#a)"><rect id="svg_4" rx="40" height="687" width="560" fill="#8247E5"/><g id="svg_5" opacity="0.1" fill-opacity="0.44"><circle id="svg_6" r="372.99" cy="343.99" cx="279.99" fill="url(#b)"/><circle id="svg_7" r="603.5" cy="343.5" cx="279.5" fill="url(#c)"/></g><path id="svg_9" fill="#000" d="m0,0l560,0l0,116l-560,0l0,-116z"/><g id="svg_10" clip-path="url(#e)"><path id="svg_11" fill="#8247E5" d="m213.8,47.53a3.82,3.82 0 0 0 -3.62,0l-8.46,5.02l-5.74,3.2l-8.3,5.02a3.83,3.83 0 0 1 -3.63,0l-6.5,-3.96a3.72,3.72 0 0 1 -1.81,-3.2l0,-7.61c0,-1.25 0.6,-2.47 1.8,-3.2l6.5,-3.8c1.06,-0.6 2.42,-0.6 3.63,0l6.5,3.97a3.72,3.72 0 0 1 1.8,3.2l0,5.02l5.75,-3.35l0,-5.17c0,-1.22 -0.6,-2.44 -1.81,-3.2l-12.09,-7.16a3.82,3.82 0 0 0 -3.62,0l-12.39,7.3a3.35,3.35 0 0 0 -1.8,3.06l0,14.3c0,1.23 0.6,2.44 1.8,3.2l12.24,7.16c1.05,0.6 2.41,0.6 3.62,0l8.3,-4.87l5.75,-3.35l8.3,-4.87a3.83,3.83 0 0 1 3.63,0l6.5,3.8a3.72,3.72 0 0 1 1.8,3.2l0,7.6c0,1.23 -0.6,2.45 -1.8,3.2l-6.35,3.8a3.8,3.8 0 0 1 -3.62,0l-6.5,-3.8a3.72,3.72 0 0 1 -1.8,-3.2l0,-4.86l-5.75,3.35l0,5.02c0,1.22 0.6,2.44 1.81,3.2l12.24,7.16c1.05,0.6 2.41,0.6 3.62,0l12.24,-7.16a3.72,3.72 0 0 0 1.8,-3.2l0,-14.47c0,-1.22 -0.6,-2.44 -1.8,-3.2l-12.24,-7.15z"/></g><ellipse filter="url(#svg_18_blur)" stroke="null" opacity="0.31" ry="37.34304" rx="367.10096" id="svg_18" cy="497.66758" cx="305.95017" stroke-width="0" fill="#9569e0"/><text id="svg_14" text-anchor="start" font-weight="bold" font-size="48" font-family="Lexend" stroke-width="0" y="238.5" x="65.4" fill="#333" xml:space="preserve">',
                charName,
                '</text><text transform="matrix(1.45223 0 0 1.45223 -229.949 -118.83)" stroke="null" id="svg_15" text-anchor="start" font-size="16" font-family="Lexend" stroke-width="0" y="278.63839" x="451.43951" fill="#333" xml:space="preserve">',
                charInfo,
                '</text><text id="svg_16" text-anchor="start" font-size="24" font-family="Lexend" stroke-width="0" y="632.5" x="80.88" fill="#5e5e5e" xml:space="preserve">',
                credit,
                '</text><text id="svg_17" text-anchor="start" font-weight="bold" font-size="40" font-family="Lexend" stroke-width="0" y="71.5" x="240" fill="#fff" xml:space="preserve">',
                'Character Card',
                '</text></g></svg>'
            ))
        ));
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