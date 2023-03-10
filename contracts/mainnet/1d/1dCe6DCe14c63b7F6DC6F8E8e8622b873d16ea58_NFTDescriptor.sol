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

// SPDX-License-Identifier: GPL-3.0

/// Based on Nouns

pragma solidity ^0.8.6;

import {Base64} from "base64-sol/base64.sol";
import {iSVGRenderer} from "./interfaces/iSVGRenderer.sol";

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        string background;
        string sky;
        string altitude;
        iSVGRenderer.Part[] parts;
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(
        iSVGRenderer renderer,
        TokenURIParams memory params
    ) public view returns (string memory) {
        string memory image = generateSVGImage(
            renderer,
            iSVGRenderer.SVGParams({
                parts: params.parts,
                background: params.background
            })
        );

        //prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', params.name, '", ',
                            '"description":"', params.description, '", ',
                            '"image": "', 'data:image/svg+xml;base64,', image, '", ',
                            '"attributes": [',
                            '{"trait_type": "Altitude", "value": ', params.altitude,'},'
                            '{"trait_type": "Sky", "value": "', params.sky,'"}'
                            ']',
                            '}')
                    )
                )
            )
        );
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructBurnedTokenURI(
        string memory tokenId,
        string memory name,
        string memory description
    ) public view returns (string memory) {
        //prettier-ignore
        string memory burnedPlaceholder = "PHN2ZyB3aWR0aD0iMzIwIiBoZWlnaHQ9IjMyMCIgdmlld0JveD0iMCAwIDMyMCAzMjAiIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgc2hhcGUtcmVuZGVyaW5nPSJjcmlzcEVkZ2VzIj48cG9seWdvbiBwb2ludHM9IjMxMCAwIDMwMCAwIDI5MCAwIDI4MCAwIDI3MCAwIDI2MCAwIDI1MCAwIDI0MCAwIDIzMCAwIDIyMCAwIDIxMCAwIDIwMCAwIDE5MCAwIDE4MCAwIDE3MCAwIDE2MCAwIDE1MCAwIDE0MCAwIDEzMCAwIDEyMCAwIDExMCAwIDEwMCAwIDkwIDAgODAgMCA3MCAwIDYwIDAgNTAgMCA0MCAwIDMwIDAgMjAgMCAxMCAwIDAgMCAwIDEwIDAgMjAgMCAzMCAwIDQwIDAgNTAgMCA2MCAwIDcwIDAgODAgMCA5MCAwIDEwMCAwIDExMCAwIDEyMCAwIDEzMCAwIDE0MCAwIDE1MCAwIDE2MCAwIDE3MCAwIDE4MCAwIDE5MCAwIDIwMCAwIDIxMCAwIDIyMCAwIDIzMCAwIDI0MCAwIDI1MCAwIDI2MCAwIDI3MCAwIDI4MCAwIDI5MCAwIDMwMCAwIDMxMCAwIDMyMCAxMCAzMjAgMjAgMzIwIDMwIDMyMCA0MCAzMjAgNTAgMzIwIDYwIDMyMCA3MCAzMjAgODAgMzIwIDkwIDMyMCAxMDAgMzIwIDExMCAzMjAgMTIwIDMyMCAxMzAgMzIwIDE0MCAzMjAgMTUwIDMyMCAxNjAgMzIwIDE3MCAzMjAgMTgwIDMyMCAxOTAgMzIwIDIwMCAzMjAgMjEwIDMyMCAyMjAgMzIwIDIzMCAzMjAgMjQwIDMyMCAyNTAgMzIwIDI2MCAzMjAgMjcwIDMyMCAyODAgMzIwIDI5MCAzMjAgMzAwIDMyMCAzMTAgMzIwIDMyMCAzMjAgMzIwIDMxMCAzMjAgMzAwIDMyMCAyOTAgMzIwIDI4MCAzMjAgMjcwIDMyMCAyNjAgMzIwIDI1MCAzMjAgMjQwIDMyMCAyMzAgMzIwIDIyMCAzMjAgMjEwIDMyMCAyMDAgMzIwIDE5MCAzMjAgMTgwIDMyMCAxNzAgMzIwIDE2MCAzMjAgMTUwIDMyMCAxNDAgMzIwIDEzMCAzMjAgMTIwIDMyMCAxMTAgMzIwIDEwMCAzMjAgOTAgMzIwIDgwIDMyMCA3MCAzMjAgNjAgMzIwIDUwIDMyMCA0MCAzMjAgMzAgMzIwIDIwIDMyMCAxMCAzMjAgMCAzMTAgMCIvPjxyZWN0IHg9IjIwMCIgeT0iMTEwIiB3aWR0aD0iMTAiIGhlaWdodD0iMTAiIHN0eWxlPSJmaWxsOiAjYmUxZTJkOyIvPjxyZWN0IHg9IjIyMCIgeT0iOTAiIHdpZHRoPSIxMCIgaGVpZ2h0PSIxMCIgc3R5bGU9ImZpbGw6ICNiZTFlMmQ7Ii8+PHJlY3QgeD0iMjIwIiB5PSIxMzAiIHdpZHRoPSIxMCIgaGVpZ2h0PSIxMCIgc3R5bGU9ImZpbGw6ICNiZTFlMmQ7Ii8+PHBvbHlnb24gcG9pbnRzPSIyMjAgMTUwIDIxMCAxNTAgMjEwIDE2MCAyMDAgMTYwIDIwMCAxNTAgMjAwIDE0MCAxOTAgMTQwIDE5MCAxMzAgMTkwIDEyMCAxOTAgMTEwIDE4MCAxMTAgMTgwIDEwMCAxODAgOTAgMTcwIDkwIDE3MCAxMDAgMTYwIDEwMCAxNjAgMTEwIDE2MCAxMjAgMTUwIDEyMCAxNTAgMTMwIDE1MCAxNDAgMTQwIDE0MCAxNDAgMTMwIDE0MCAxMjAgMTMwIDEyMCAxMzAgMTMwIDEyMCAxMzAgMTIwIDE0MCAxMTAgMTQwIDExMCAxNTAgMTEwIDE2MCAxMDAgMTYwIDEwMCAxNzAgMTAwIDE4MCAxMDAgMTkwIDEwMCAyMDAgMTEwIDIwMCAxMTAgMjEwIDEyMCAyMTAgMTIwIDIyMCAxMzAgMjIwIDEzMCAyMzAgMTQwIDIzMCAxNTAgMjMwIDE2MCAyMzAgMTcwIDIzMCAxODAgMjMwIDE5MCAyMzAgMTkwIDIyMCAyMDAgMjIwIDIwMCAyMTAgMjEwIDIxMCAyMTAgMjAwIDIyMCAyMDAgMjIwIDE5MCAyMzAgMTkwIDIzMCAxODAgMjMwIDE3MCAyMzAgMTYwIDIyMCAxNjAgMjIwIDE1MCIgc3R5bGU9ImZpbGw6ICNiZTFlMmQ7Ii8+PHJlY3QgeD0iMTQwIiB5PSIxMDAiIHdpZHRoPSIxMCIgaGVpZ2h0PSIxMCIgc3R5bGU9ImZpbGw6ICNiZTFlMmQ7Ii8+PHJlY3QgeD0iMTAwIiB5PSIxMTAiIHdpZHRoPSIxMCIgaGVpZ2h0PSIxMCIgc3R5bGU9ImZpbGw6ICNiZTFlMmQ7Ii8+PHJlY3QgeD0iOTAiIHk9IjEyMCIgd2lkdGg9IjEwIiBoZWlnaHQ9IjEwIiBzdHlsZT0iZmlsbDogI2JlMWUyZDsiLz48L3N2Zz4=";

        //prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', string(abi.encodePacked("Burned Pepe ", tokenId)), '", ',
                            '"description":"', description, '", ',
                            '"image": "', 'data:image/svg+xml;base64,', burnedPlaceholder, '"',
                            '}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(
        iSVGRenderer renderer,
        iSVGRenderer.SVGParams memory params
    ) public view returns (string memory svg) {
        return Base64.encode(bytes(renderer.generateSVG(params)));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// Based on Nouns

pragma solidity ^0.8.6;

interface iSVGRenderer {
    struct Part {
        bytes image;
        bytes palette;
    }

    struct SVGParams {
        Part[] parts;
        string background;
    }

    function generateSVG(
        SVGParams memory params
    ) external view returns (string memory svg);

    function generateSVGPart(
        Part memory part
    ) external view returns (string memory partialSVG);

    function generateSVGParts(
        Part[] memory parts
    ) external view returns (string memory partialSVG);
}