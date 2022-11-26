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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TicketURIDescriptor  {
    using Strings for uint256;


    function generateLogoURI() public view
    returns (string memory)
    {
        bytes memory svg = abi.encodePacked(
            '<?xml version="1.0" encoding="UTF-8"?>',
            '<svg id="Layer_2" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1529.28 468.87">',
                '<rect width="100%" height="100%" fill="skyblue" />',
                '<defs>',
                '<style>.cls-1{fill:white;}</style>',
                '</defs>',
                '<g id="Layer_1-2">',
                    '<g>',
                        '<path class="cls-1" d="M462.51,98.52c-2.65,21.83,.2,30.19,7.34,30.19,4.69,0,8.98-3.67,11.22-8.57l5.3-41.82c-1.84-4.08-4.89-7.14-10-7.14-7.34,0-11.42,7.14-13.87,27.33m33.45-39.78h.41l4.9-10h25.5l-13.26,106.27h-30.6l.41-4.08,4.49-13.05h-2.86c-6.12,11.83-17.34,19.58-31.21,19.58-23.05,0-34.47-19.17-30.19-55.28,4.89-39.98,20.6-56.09,44.67-56.09,14.89,0,24.07,6.93,27.74,12.65"/>',
                        '<path class="cls-1" d="M589.39,48.75h19.58l-3.47,27.74h-19.38l-5.1,42.02c-1.02,7.14,1.63,9.79,6.32,9.79,3.26,0,6.53-.61,10.4-1.63l-1.84,27.74c-9.18,2.04-15.71,3.06-23.87,3.06-25.9,0-31.21-13.26-28.15-38.35l5.3-42.84h-12.44l2.65-20.4,12.85-4.69,2.65-21.21,37.53-6.32-3.06,25.09Z"/>',
                        '<path class="cls-1" d="M664.66,19.38c-1.22,10.81-11.83,19.38-22.44,19.38s-19.17-8.57-17.95-19.38c1.22-10.61,11.42-19.38,22.64-19.38,10.61,0,19.17,8.77,17.75,19.38m-18.36,135.65h-36.92l12.85-106.27h36.92l-12.85,106.27Z"/>',
                        '<path class="cls-1" d="M706.47,100.56c-2.86,22.85-.41,33.04,6.73,33.04s12.24-10.2,15.09-33.04c2.65-21.83,0-30.39-7.34-30.39s-11.83,8.57-14.48,30.39m59.77,.41c-5.1,43.04-26.31,56.5-56.09,56.5-28.15,0-47.32-13.67-42.22-56.5,5.1-41.61,25.7-54.87,55.89-54.87s47.53,13.67,42.43,54.87"/>',
                        '<path class="cls-1" d="M875.78,87.3l-8.16,67.72h-36.92l7.75-64.05c1.43-10-1.02-13.87-6.73-13.87-4.28,0-8.57,2.86-11.42,6.94l-8.57,70.98h-36.92l13.05-106.27h30.8l-.41,3.88-3.88,12.85h2.65c7.34-11.22,18.77-19.38,33.04-19.38,20.4,0,29.17,13.67,25.7,41.2"/>',
                        '<path class="cls-1" d="M175.1,48.96l-7.75,34.47c-3.06-1.43-5.92-2.04-9.18-2.04-8.36,0-15.09,3.26-20.6,13.26l-7.34,60.38h-36.92l13.05-106.27h30.8l-.61,4.69-3.67,13.05h2.65c7.55-13.26,17.95-19.99,29.17-19.99,4.28,0,7.34,.82,10.4,2.45"/>',
                        '<path class="cls-1" d="M73.32,48.75h19.58l-3.47,27.74h-19.38l-5.1,42.02c-1.02,7.14,1.63,9.79,6.32,9.79,3.26,0,6.53-.61,10.4-1.63l-1.84,27.74c-9.18,2.04-15.71,3.06-23.86,3.06-25.91,0-31.21-13.26-28.15-38.35l5.3-42.84h-12.44l2.65-20.4,12.85-4.69,2.65-21.21,37.53-6.32-3.06,25.09Z"/>',
                        '<path class="cls-1" d="M263.22,155.02h-27.33l-2.45-12.85h-1.22c-5.92,10.2-17.54,15.3-28.97,15.3-22.03,0-30.19-13.05-26.93-39.57l8.57-69.15h36.72l-7.75,63.64c-1.22,9.18,.41,14.07,6.73,14.07,4.08,0,7.55-2.85,10-6.93l8.77-70.78h36.72l-12.85,106.27Z"/>',
                        '<path class="cls-1" d="M408.25,128.51c1.84,0,3.26-.41,4.9-.82v27.13c-6.73,1.43-13.67,2.45-20.19,2.45-22.85,0-30.39-11.01-26.92-39.16l10.4-85.06c-6.12-.61-11.63-1.02-16.73-1.02-12.85,0-18.56,3.06-19.58,11.42l-.61,5.3h17.34l-3.47,27.54h-17.34l-14.28,120.35-38.14,4.08,15.5-124.43h-12.24l2.65-22.23,12.65-3.26,.61-5.1c3.67-29.17,26.52-41.41,61.4-41.41,7.14,0,17.95,.82,26.31,2.24l26.31-2.24-14.07,114.84c-1.02,6.94,1.43,9.38,5.51,9.38"/>',
                        '<g>',
                            '<path class="cls-1" d="M209.11,408.55h-53.77l7.11-73.4,11.38-71.41h-1.14l-40.68,131.73h-53.2l-9.96-131.73h-1.42l-4.84,70.56-10.24,74.26H0L42.39,213.38h63.73l6.83,80.8-.28,42.11h2.84l9.67-42.11,25.61-80.8h63.16l-4.84,195.17Z"/>',
                            '<path class="cls-1" d="M334.58,274.26h.57l6.83-13.94h35.56l-18.49,148.23h-42.68l.57-5.69,6.26-18.21h-3.98c-8.53,16.5-24.18,27.31-43.53,27.31-32.15,0-48.08-26.74-42.11-77.1,6.83-55.76,28.74-78.24,62.31-78.24,20.77,0,33.57,9.67,38.69,17.64Zm-46.66,55.48c-3.7,30.44,.28,42.11,10.24,42.11,6.54,0,12.52-5.12,15.65-11.95l7.4-58.32c-2.56-5.69-6.83-9.96-13.94-9.96-10.24,0-15.93,9.96-19.35,38.12Z"/>',
                            '<path class="cls-1" d="M498.17,260.61l-10.81,48.08c-4.27-1.99-8.25-2.84-12.8-2.84-11.67,0-21.05,4.55-28.74,18.49l-10.24,84.21h-51.5l18.21-148.23h42.96l-.85,6.54-5.12,18.21h3.7c10.53-18.49,25.04-27.88,40.68-27.88,5.97,0,10.24,1.14,14.51,3.41Z"/>',
                            '<path class="cls-1" d="M559.05,309.83h6.26l24.18-49.51h55.76l-27.03,43.53-21.62,27.88,15.65,28.17,20.48,48.65h-54.06l-18.49-58.04h-6.26l-7.11,58.04h-51.5l25.04-205.7,52.35-4.55-13.66,111.53Z"/>',
                            '<path class="cls-1" d="M772.72,330.31l-1.99,14.51h-76.82c0,19.92,6.54,27.6,23.33,27.6,13.66,0,27.31-2.85,41.54-6.26l1.71,35.85c-17.64,5.97-34.71,9.96-52.35,9.96-56.05,0-71.41-29.3-65.44-80.52,5.69-45.81,30.73-74.83,77.39-74.83s58.04,29.02,52.63,73.69Zm-75.68-13.66h29.59c0-1.71,.28-3.7,.57-5.41,1.42-10.81,0-22.19-10.53-22.19s-15.93,8.82-19.63,27.6Z"/>',
                            '<path class="cls-1" d="M864.9,260.32h27.31l-4.84,38.69h-27.03l-7.11,58.61c-1.42,9.96,2.28,13.66,8.82,13.66,4.55,0,9.1-.85,14.51-2.27l-2.56,38.69c-12.8,2.85-21.91,4.27-33.29,4.27-36.13,0-43.53-18.49-39.26-53.49l7.4-59.75h-17.35l3.7-28.45,17.92-6.54,3.7-29.59,52.35-8.82-4.27,34.99Z"/>',
                            '<path class="cls-1" d="M1037.59,331.73c-6.83,54.91-27.03,80.23-62.02,80.23-10.53,0-20.77-2.84-29.87-9.39l-.85,.57-7.97,65.72h-51.5l25.61-208.55h43.53l-.85,6.83-5.97,16.5h3.7c12.8-17.07,31.01-27.03,48.94-27.03,27.31,0,43.53,24.47,37.27,75.11Zm-80.52-23.05l-7.11,58.89c2.56,5.41,7.4,9.67,13.94,9.67,11.1,0,16.22-12.23,19.35-39.55,3.41-26.17,0-40.68-10.24-40.68-6.54,0-12.52,4.84-15.93,11.66Z"/>',
                            '<path class="cls-1" d="M1105.3,358.48c-1.14,9.67,2.27,13.09,7.68,13.09,2.56,0,4.55-.57,7.11-1.14l-.28,37.84c-9.39,1.99-18.78,3.41-28.17,3.41-31.86,0-42.39-15.36-37.55-54.63l18.78-154.2,52.06-4.55-19.63,160.18Z"/>',
                            '<path class="cls-1" d="M1235.61,274.26h.57l6.83-13.94h35.56l-18.49,148.23h-42.68l.57-5.69,6.26-18.21h-3.98c-8.53,16.5-24.18,27.31-43.53,27.31-32.15,0-48.08-26.74-42.11-77.1,6.83-55.76,28.74-78.24,62.31-78.24,20.77,0,33.57,9.67,38.69,17.64Zm-46.66,55.48c-3.7,30.44,.28,42.11,10.24,42.11,6.54,0,12.52-5.12,15.65-11.95l7.4-58.32c-2.56-5.69-6.83-9.96-13.94-9.96-10.24,0-15.93,9.96-19.35,38.12Z"/>',
                            '<path class="cls-1" d="M1395.78,260.61l-8.54,40.12c-7.4-1.99-12.23-2.84-19.35-2.84-14.23,0-21.05,7.97-24.18,35.28-3.98,31.3,3.13,36.42,16.5,36.42,5.97,0,12.52-.57,19.35-1.99l-2.56,40.97c-11.95,2.56-22.76,3.41-33.86,3.41-42.96,0-58.33-32.15-52.63-78.81,6.26-50.64,24.75-76.25,71.7-76.25,14.8,0,20.77,.85,33.57,3.7Z"/>',
                            '<path class="cls-1" d="M1528.07,330.31l-1.99,14.51h-76.82c0,19.92,6.54,27.6,23.33,27.6,13.66,0,27.31-2.85,41.54-6.26l1.71,35.85c-17.64,5.97-34.71,9.96-52.35,9.96-56.05,0-71.41-29.3-65.44-80.52,5.69-45.81,30.73-74.83,77.39-74.83s58.04,29.02,52.63,73.69Zm-75.68-13.66h29.59c0-1.71,.28-3.7,.57-5.41,1.42-10.81,0-22.19-10.53-22.19s-15.93,8.82-19.63,27.6Z"/>',
                        '</g>',
                    '</g>',
                '</g>',
            '</svg>'
        );

        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            ));
    }

    function generateImageURI(uint256 productId, uint256 startTime, uint256 endTime) public view
    returns (string memory)
    {
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 180 180">',
            '<rect width="100%" height="100%" fill="blue" />',
            '<image overflow="visible" width="157" height="43" href="', generateLogoURI(), '" x="10" y="10"/>',
            '<text x="40" y="90" style="fill:white; font-size: 10px;" text-decoration="underline">Data Subscription Ticket</text>',
            '<text x="40" y="110" style="fill:white; font-size: 8px;">Product ID: ', productId.toString(), '</text>',
            '<text x="40" y="120" style="fill:white; font-size: 8px;" >Subscription Period: </text>',
            '<text style="fill:white; font-size: 6px;">',
                '<tspan x="50" y="130" >Start Time: ', startTime.toString(), '</tspan>',
                '<tspan x="50" y="140" >End Time: ', endTime.toString(), '</tspan>',
            '</text>',
            '</svg>'
        );

        //Note: could not use following external http link configuration in above svg xml.
        //      This will not be supported in OpenSea or other NFT marketplace unfortunately. (Browser will show the logo correctly)
        //'<image overflow="visible" width="157" height="43" href="https://bafkreic4uf2clrepfxpfaqmicul7kb57b22qkd7tycmwsysjeujyzc5sfe.ipfs.nftstorage.link/" x="10" y="10"/>',
        return string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(svg)
            ));
    }

    function generateTokenURI(uint256 tokenId, uint256 productId, uint256 startTime, uint256 endTime) public view returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Truflation Data Subscription Ticket",',
                '"description": "Token ID: ', tokenId.toString(), '  This NFT enable its holder to access given Trufulation data product during given period. Contact to Truflation Support Team if need any support.",',
                '"image_data": "', generateImageURI(productId, startTime, endTime), '"',
            '}'
        );
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(dataURI)
            )
        );
    }



}