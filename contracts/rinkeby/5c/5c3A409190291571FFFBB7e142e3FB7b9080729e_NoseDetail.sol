// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma abicoder v2;

import 'base64-sol/base64.sol';

/// @title Nose SVG generator
library NoseDetail {
    /// @dev Nose N°1 => Classic
    function item_1() public pure returns (string memory) {
        return "";
    }

    /// @dev Nose N°2 => Bleeding
    function item_2() public pure returns (string memory) {
        return
            base(
                string(
                    abi.encodePacked(
                        '<path fill="#E90000" d="M205.8,254.1C205.8,254.1,205.9,254.1,205.8,254.1c0.1,0,0.1,0.1,0.1,0.1c0,0.2,0,0.5-0.2,0.7c-0.1,0.1-0.3,0.1-0.4,0.1c-0.4,0-0.8,0.1-1.2,0.1c-0.2,0-0.7,0.2-0.8,0s0.1-0.4,0.2-0.5c0.3-0.2,0.7-0.2,1-0.3C204.9,254.3,205.4,254.1,205.8,254.1z"/>',
                        '<path fill="#E90000" d="M204.3,252.8c0.3-0.1,0.6-0.2,0.9-0.1c0.1,0.2,0.1,0.4,0.2,0.6c0,0.1,0,0.1,0,0.2c0,0.1-0.1,0.1-0.2,0.1c-0.7,0.2-1.4,0.3-2.1,0.5c-0.2,0-0.3,0.1-0.4-0.1c0-0.1-0.1-0.2,0-0.3c0.1-0.2,0.4-0.3,0.6-0.4C203.6,253.1,203.9,252.9,204.3,252.8z"/>',
                        '<path fill="#FF0000" d="M204.7,240.2c0.3,1.1,0.1,2.3-0.1,3.5c-0.3,2-0.5,4.1,0,6.1c0.1,0.4,0.3,0.9,0.2,1.4c-0.2,0.9-1.1,1.3-2,1.6c-0.1,0-0.2,0.1-0.4,0.1c-0.3-0.1-0.4-0.5-0.4-0.8c-0.1-1.9,0.5-3.9,0.8-5.8c0.3-1.7,0.3-3.2-0.1-4.8c-0.1-0.5-0.3-0.9,0.1-1.3C203.4,239.7,204.6,239.4,204.7,240.2z"/>'
                    )
                )
            );
    }

    /// @notice Return the nose name of the given id
    /// @param id The nose Id
    function getItemNameById(uint8 id) public pure returns (string memory name) {
        name = "";
        if (id == 1) {
            name = "Classic";
        } else if (id == 2) {
            name = "Bleeding";
        }
    }

    /// @dev The base SVG for the Nose
    function base(string memory children) private pure returns (string memory) {
        return string(abi.encodePacked('<g id="Nose bonus">', children, "</g>"));
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