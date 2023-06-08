// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.18;

import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { Base64 }  from '@base64-sol/base64.sol';

/**
    @title  Position NFT SVG library
    @notice External library containing logic for generating `SVG` for a Position `NFT`.
 */
library PositionNFTSVG {

    using Strings for uint256;

    /**********************/
    /*** Params Structs ***/
    /**********************/

    struct ConstructTokenURIParams {
        string collateralTokenSymbol; // the symbol of collateral token of the pool
        string quoteTokenSymbol;      // the symbol of quote token of the pool
        uint256 tokenId;              // the ID of positions NFT token
        address pool;                 // the address of pool tracked in positions NFT token
        address owner;                // the owner of positions NFT token
        uint256[] indexes;            // the array of price buckets index with LP to be tracked by the NFT
    }

    /*******************************/
    /*** External View Functions ***/
    /*******************************/

    function constructTokenURI(ConstructTokenURIParams memory params_) external pure returns (string memory) {
        // set token metadata
        string memory description = "Ajna Positions NFT-V1";
        string memory image = _generateSVGofTokenById(params_);
        string memory name = string(
            abi.encodePacked("Ajna Token #", Strings.toString(params_.tokenId))
        );
        string memory ownerHexString = (uint256(uint160(params_.owner))).toHexString(20);

        // encode metadata as JSON object in base64
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"',
                            name,
                            '", "description":"',
                            description,
                            '", "image":"',
                            'data:image/svg+xml;base64,',
                            image,
                            '", "owner":"',
                            ownerHexString,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    /**********************************/
    /*** Image Generation Functions ***/
    /**********************************/

    function _generateSVGofTokenById(ConstructTokenURIParams memory params_) internal pure returns (string memory svg_) {
        svg_ = string(
            abi.encodePacked(
                '<svg fill="none" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">',
                    _generateBackground(),
                    _generateSVGDefs(),
                    _generatePoolTag(params_.collateralTokenSymbol, params_.quoteTokenSymbol),
                    _generateTokenIdTag(params_.tokenId),
                "</svg>"
            )
        );
    }

    function _generateBackground() private pure returns (string memory background_) {
        string memory backgroundTop = string(abi.encodePacked(
            '<rect width="512" height="512" rx="32" fill="url(#paint0_linear_115_51)"/>',
            '<rect width="512" height="512" rx="32" fill="black" fill-opacity="0.5"/>',
            '<g filter="url(#filter0_f_115_51)">',
            '<ellipse cx="374" cy="390.5" rx="122" ry="121.5" fill="#B45CD6"/>',
            '<circle cx="157" cy="315" r="122" fill="#37FCFB"/>',
            '<ellipse cx="137.783" cy="137.5" rx="121.783" ry="121.5" fill="#642DD2"/>',
            '</g>',
            '<rect opacity="0.5" x="16.5" y="16.5" width="479" height="479" rx="23.5" fill="black" stroke="white"/>',
            '<circle cx="256" cy="256" r="228.5" stroke="white"/>',
            '<circle cx="256" cy="256" r="219.5" stroke="white"/>'
        ));

        string memory backgroundMiddle = string(abi.encodePacked(
            '<path d="M410.273 467C410.204 467 410.139 466.974 410.078 466.922C410.026 466.861 410 466.796 410 466.727C410 466.684 410.004 466.645 410.013 466.61L413.068 458.264C413.094 458.169 413.146 458.086 413.224 458.017C413.311 457.939 413.428 457.9 413.575 457.9H415.499C415.646 457.9 415.759 457.939 415.837 458.017C415.924 458.086 415.98 458.169 416.006 458.264L419.048 466.61C419.065 466.645 419.074 466.684 419.074 466.727C419.074 466.796 419.044 466.861 418.983 466.922C418.931 466.974 418.866 467 418.788 467H417.189C417.059 467 416.959 466.97 416.89 466.909C416.829 466.84 416.79 466.779 416.773 466.727L416.266 465.401H412.795L412.301 466.727C412.284 466.779 412.245 466.84 412.184 466.909C412.123 466.97 412.019 467 411.872 467H410.273ZM413.328 463.529H415.746L414.524 460.097L413.328 463.529Z" fill="white"/>',
            '<path d="M431.118 467.13C430.624 467.13 430.151 467.069 429.701 466.948C429.259 466.818 428.864 466.627 428.518 466.376C428.171 466.125 427.894 465.813 427.686 465.44C427.486 465.067 427.378 464.634 427.361 464.14C427.361 464.062 427.387 463.997 427.439 463.945C427.491 463.884 427.56 463.854 427.647 463.854H429.402C429.523 463.854 429.614 463.884 429.675 463.945C429.744 464.006 429.8 464.097 429.844 464.218C429.887 464.461 429.969 464.66 430.091 464.816C430.212 464.963 430.364 465.076 430.546 465.154C430.736 465.223 430.949 465.258 431.183 465.258C431.616 465.258 431.95 465.119 432.184 464.842C432.418 464.556 432.535 464.14 432.535 463.594V459.837H428.323C428.236 459.837 428.158 459.807 428.089 459.746C428.028 459.685 427.998 459.607 427.998 459.512V458.225C427.998 458.13 428.028 458.052 428.089 457.991C428.158 457.93 428.236 457.9 428.323 457.9H434.615C434.71 457.9 434.788 457.93 434.849 457.991C434.918 458.052 434.953 458.13 434.953 458.225V463.659C434.953 464.413 434.788 465.05 434.459 465.57C434.129 466.081 433.679 466.471 433.107 466.74C432.535 467 431.872 467.13 431.118 467.13Z" fill="white"/>',
            '<path d="M445.006 467C444.91 467 444.832 466.97 444.772 466.909C444.711 466.848 444.681 466.77 444.681 466.675V458.225C444.681 458.13 444.711 458.052 444.772 457.991C444.832 457.93 444.91 457.9 445.006 457.9H446.384C446.531 457.9 446.635 457.935 446.696 458.004C446.765 458.065 446.808 458.112 446.826 458.147L449.998 463.152V458.225C449.998 458.13 450.028 458.052 450.089 457.991C450.149 457.93 450.227 457.9 450.323 457.9H451.883C451.978 457.9 452.056 457.93 452.117 457.991C452.177 458.052 452.208 458.13 452.208 458.225V466.675C452.208 466.762 452.177 466.84 452.117 466.909C452.056 466.97 451.978 467 451.883 467H450.492C450.353 467 450.249 466.965 450.18 466.896C450.119 466.827 450.08 466.779 450.063 466.753L446.891 461.943V466.675C446.891 466.77 446.86 466.848 446.8 466.909C446.739 466.97 446.661 467 446.566 467H445.006Z" fill="white"/>',
            '<path d="M461.504 467C461.435 467 461.37 466.974 461.309 466.922C461.257 466.861 461.231 466.796 461.231 466.727C461.231 466.684 461.236 466.645 461.244 466.61L464.299 458.264C464.325 458.169 464.377 458.086 464.455 458.017C464.542 457.939 464.659 457.9 464.806 457.9H466.73C466.878 457.9 466.99 457.939 467.068 458.017C467.155 458.086 467.211 458.169 467.237 458.264L470.279 466.61C470.297 466.645 470.305 466.684 470.305 466.727C470.305 466.796 470.275 466.861 470.214 466.922C470.162 466.974 470.097 467 470.019 467H468.42C468.29 467 468.191 466.97 468.121 466.909C468.061 466.84 468.022 466.779 468.004 466.727L467.497 465.401H464.026L463.532 466.727C463.515 466.779 463.476 466.84 463.415 466.909C463.355 466.97 463.251 467 463.103 467H461.504ZM464.559 463.529H466.977L465.755 460.097L464.559 463.529Z" fill="white"/>',
            '<path d="M106.178 169.5L256 429L405.822 169.5H106.178Z" stroke="white"/>',
            '<path d="M106.178 342.5L256 83L405.822 342.5H106.178Z" stroke="white"/>',
            '<circle cx="256" cy="256" r="71.5" stroke="white"/>',
            '<circle cx="256" cy="256" r="20" fill="#974EEA"/>',
            '<circle cx="264" cy="248" r="4" fill="white"/>'
        ));

        string memory backgroundBottom = string(abi.encodePacked(
            '<path d="M406.5 170L256 82.5L106 170V342.5L256 429.5L406.5 342.5V170Z" stroke="white"/>',
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M274.117 74.4853C268.265 68.9211 262.248 66 256.1 66C249.951 66 243.935 68.9211 238.082 74.4853C237.582 74.9614 237.562 75.753 238.039 76.2534C238.515 76.7537 239.307 76.7733 239.808 76.2972C245.372 71.0072 250.802 68.5011 256.1 68.5011C261.393 68.5011 266.818 71.003 272.377 76.2837C272.464 76.3739 272.535 76.4979 272.576 76.6272C272.562 76.7036 272.554 76.7824 272.554 76.863C272.554 77.1585 272.457 77.3175 272.378 77.3853C272.361 77.3999 272.344 77.415 272.328 77.4305C272.191 77.5605 272.055 77.6888 271.919 77.8155C266.738 73.508 261.454 71.2583 256.069 71.2583C250.395 71.2583 244.833 73.7554 239.386 78.5252C239.376 78.5335 239.366 78.5419 239.356 78.5506L239.342 78.5621C238.925 78.9192 238.471 79.3086 238.012 79.765C236.759 80.9406 236.661 82.8987 237.766 84.2415C237.773 84.2532 237.781 84.2649 237.788 84.2766C237.896 84.4377 238.024 84.5532 238.145 84.6346C243.958 90.1209 249.931 93 256.036 93C262.184 93 268.201 90.0789 274.053 84.5147C274.554 84.0386 274.573 83.247 274.097 82.7467C273.62 82.2463 272.828 82.2267 272.327 82.7028C266.764 87.9928 261.333 90.4989 256.036 90.4989C250.738 90.4989 245.308 87.9928 239.744 82.7028L239.735 82.6944C239.396 82.3274 239.458 81.8356 239.73 81.5841C239.743 81.5728 239.755 81.5613 239.767 81.5495C239.904 81.4122 240.042 81.2814 240.182 81.1533C245.596 85.6616 251.124 87.9289 256.749 87.733C262.141 87.5451 267.419 85.1012 272.58 80.589C272.699 80.5218 272.809 80.4337 272.905 80.3252C272.928 80.2985 272.951 80.271 272.971 80.243C273.327 79.9248 273.681 79.5969 274.036 79.2593C274.648 78.7211 274.938 78.0102 275.026 77.3361C275.086 77.1902 275.119 77.0304 275.119 76.863C275.119 75.9642 274.731 75.0984 274.139 74.507C274.131 74.4997 274.124 74.4925 274.117 74.4853ZM256.069 73.7594C260.611 73.7594 265.25 75.6084 270.012 79.4864C265.466 83.2206 261.019 85.0815 256.662 85.2334C251.927 85.3983 247.085 83.5523 242.109 79.4994C246.877 75.6126 251.521 73.7594 256.069 73.7594Z" fill="white"/>',
            '<path fill-rule="evenodd" clip-rule="evenodd" d="M256.059 74.8325C253.492 74.8325 251.411 76.9138 251.411 79.4812C251.411 82.0486 253.492 84.1299 256.059 84.1299C258.627 84.1299 260.708 82.0486 260.708 79.4812C260.708 76.9138 258.627 74.8325 256.059 74.8325ZM256.06 82.2704C257.6 82.2704 258.849 81.0216 258.849 79.4812C258.849 77.9408 257.6 76.692 256.06 76.692C254.519 76.692 253.27 77.9408 253.27 79.4812C253.27 81.0216 254.519 82.2704 256.06 82.2704Z" fill="white"/>',
            '<path opacity="0.5" d="M154.5 176C154.5 198.914 135.702 217.5 112.5 217.5C89.2984 217.5 70.5 198.914 70.5 176C70.5 153.086 89.2984 134.5 112.5 134.5C135.702 134.5 154.5 153.086 154.5 176Z" stroke="white"/>',
            '<circle opacity="0.5" cx="256.5" cy="89.5" r="42" stroke="white"/>',
            '<circle opacity="0.5" cx="256.5" cy="422.5" r="42" stroke="white"/>',
            '<path opacity="0.5" d="M154.5 337C154.5 359.914 135.702 378.5 112.5 378.5C89.2984 378.5 70.5 359.914 70.5 337C70.5 314.086 89.2984 295.5 112.5 295.5C135.702 295.5 154.5 314.086 154.5 337Z" stroke="white"/>',
            '<path opacity="0.5" d="M441.5 176C441.5 198.914 422.702 217.5 399.5 217.5C376.298 217.5 357.5 198.914 357.5 176C357.5 153.086 376.298 134.5 399.5 134.5C422.702 134.5 441.5 153.086 441.5 176Z" stroke="white"/>',
            '<path opacity="0.5" d="M441.5 337C441.5 359.914 422.702 378.5 399.5 378.5C376.298 378.5 357.5 359.914 357.5 337C357.5 314.086 376.298 295.5 399.5 295.5C422.702 295.5 441.5 314.086 441.5 337Z" stroke="white"/>',
            '<circle cx="256" cy="256" r="35.5" stroke="white"/>',
            '<path d="M195.378 221L256 326L316.622 221H195.378Z" stroke="white" stroke-width="2"/>'
        ));

        // elements are broken up to avoid stack too deep errors
        background_ = string(abi.encodePacked(
            '<g clip-path="url(#clip0_115_51)">',
            backgroundTop,
            backgroundMiddle,
            backgroundBottom,
            '</g>'
        ));
    }

    function _generateSVGDefs() private pure returns (string memory defs_) {
        defs_ = string(abi.encodePacked(
            '<defs>',
                '<filter id="filter0_f_115_51" x="-184" y="-184" width="880" height="896" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                '<feFlood flood-opacity="0" result="BackgroundImageFix"/>',
                '<feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/>',
                '<feGaussianBlur stdDeviation="100" result="effect1_foregroundBlur_115_51"/>',
                '</filter>',
                '<linearGradient id="paint0_linear_115_51" x1="15.0588" y1="152.615" x2="512" y2="152.615" gradientUnits="userSpaceOnUse">',
                '<stop stop-color="#B1A6CE"/>',
                '<stop offset="0.505208" stop-color="#B45CD6"/>',
                '<stop offset="1" stop-color="#642DD2"/>',
                '</linearGradient>',
                '<clipPath id="clip0_115_51">',
                '<rect width="512" height="512" rx="32" fill="white"/>',
                '</clipPath>'
            '</defs>'
        ));
    }

    function _generatePoolTag(string memory collateral_, string memory quote_) private pure returns (string memory poolTag_) {
        poolTag_ = string(abi.encodePacked(
            '<g>',
                '<text text-anchor="start" x="32px" y="46px" fill="white" font-family="\'andale mono\', \'Courier New\', monospace" font-size="18px">',
                abi.encodePacked(
                    collateral_,
                    '/',
                    quote_
                ),
                '</text>',
            '</g>'
        ));
    }

    function _generateTokenIdTag(uint256 tokenId_) private pure returns (string memory tokenIdTag_) {
        tokenIdTag_ = string(abi.encodePacked(
            '<g style="transform:translate(32px, 456px)">',
                '<rect width="92px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.8)"/>',
                '<text x="12px" y="17px" fill="violet" font-family="\'andale mono\', \'Courier New\', monospace" font-size="12px">',
                    '<tspan fill="rgba(255,255,255,0.6)">ID: </tspan>',
                    Strings.toString(tokenId_),
                '</text>',
            '</g>'
        ));
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}