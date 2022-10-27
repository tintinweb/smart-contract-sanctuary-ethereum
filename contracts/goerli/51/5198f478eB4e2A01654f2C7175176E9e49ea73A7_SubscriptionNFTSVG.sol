// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../libs/Base64.sol";

/// @title NFTSVG
library SubscriptionNFTSVG {
    using Strings for uint256;

    struct SVGParams {
        // merchant info
        uint256 merchantTokenId;
        string merchantName;
        // plan info
        string planName;
        string planPeriod;
        string paymentTokenName;
        string paymentTokenSymbol;
        string payeeAddress;
        // sub info
        string startDateTime;
        string endDateTime;
        string nextBillDateTime;
        //        string termDateTime;
        string price;
        string payerAddress;
        string isSBT;
    }

    function generateSVG(SVGParams memory params)
    external
    pure
    returns (string memory svg)
    {
        string memory meta = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" version="1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:svgjs="http://svgjs.dev/svgjs" width="800" height="800" viewBox="0 0 800 800" style="background-color:black">',
                '<defs>',
                '<path id="text-path-a" d="M100 55 H700 A45 45 0 0 1 745 100 V700 A45 45 0 0 1 700 745 H100 A45 45 0 0 1 55 700 V100 A45 45 0 0 1 100 55 z"/>',
                '<linearGradient x1="50%" y1="0%" x2="50%" y2="100%" id="nnneon-grad">',
                '<stop stop-color="hsl(162, 100%, 58%)" stop-opacity="1" offset="0%"/>',
                '<stop stop-color="hsl(230, 55%, 70%)" stop-opacity="1" offset="100%"/>',
                '</linearGradient>',
                '<filter id="nnneon-filter" x="-100%" y="-100%" width="400%" height="400%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="17 8" x="0%" y="0%" width="100%" height="100%" in="SourceGraphic" edgeMode="none" result="blur"/>',
                '</filter>',
                '<filter id="nnneon-filter2" x="-100%" y="-100%" width="100%" height="100%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                '<feGaussianBlur stdDeviation="10 17" x="0%" y="0%" width="100%" height="100%" in="SourceGraphic" edgeMode="none" result="blur"/>',
                '</filter>',
                '</defs>',
                '<g stroke-width="16" stroke="url(#nnneon-grad)" fill="none">',
                '<rect width="700" height="700" x="50" y="50" filter="url(#nnneon-filter)" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="88" y="50" filter="url(#nnneon-filter2)" opacity="0.25" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="12" y="50" filter="url(#nnneon-filter2)" opacity="0.25" rx="45" ry="45"/>',
                '<rect width="700" height="700" x="50" y="50" rx="45" ry="45"/>',
                '</g>',
                '<g>',
                '<text y="200" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="60px">',
                params.merchantName,
                '</text>',
                '<text y="260" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="35px">',
                params.planName,
                '</text>',
                '<text y="450" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Price Per Billing Period : ', params.price, ' (', params.paymentTokenSymbol, ')',
                '</text>',
                '<text y="480" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Billing Period : ', params.planPeriod,
                '</text>',
                '<text y="510" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Payer Address : ', params.payerAddress,
                '</text>',
                '<text y="540" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Payee Address : ', params.payeeAddress,
                '</text>',
                '<text y="570" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Subscription Start Time : ', params.startDateTime,
                '</text>',
                '<text y="600" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Subscription End Time : ', params.endDateTime,
                '</text>',
                '<text y="630" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Next Bill Time : ', params.nextBillDateTime,
                '</text>',
                '<text y="660" x="100" fill="white" font-family="\\\'Courier New\\\', monospace" font-weight="200" font-size="16px">',
                'Is SBT : ', params.isSBT,
                '</text>',
                '</g>',
                '<g>',
                '<svg version="1.0" xmlns="http://www.w3.org/2000/svg" width="80" height="80" viewBox="0 0 1920 1920" preserveAspectRatio="xMidYMid meet" x="600" y="630">',
                '<g transform="translate(0.000000,1920.000000) scale(0.100000,-0.100000)" fill="white" stroke="none">',
                '<path d="M8833 13027 c-1855 -1855 -3373 -3379 -3373 -3386 0 -13 1393 -1411 ',
                '1407 -1411 4 0 1210 1202 2680 2672 l2672 2672 27 -24 c73 -68 3899 -3902 ',
                '3902 -3910 2 -5 -753 -766 -1677 -1690 -925 -925 -1681 -1687 -1681 -1693 0 ',
                '-22 1383 -1397 1405 -1397 13 0 823 803 2404 2384 1905 1905 2382 2387 2377 ',
                '2402 -9 27 -6738 6754 -6756 6754 -8 0 -1533 -1518 -3387 -3373z"/>',
                '<path d="M3492 13007 c-1854 -1854 -3372 -3376 -3372 -3381 0 -5 1521 -1530 ',
                '3380 -3389 l3381 -3381 3379 3379 c1859 1859 3380 3385 3380 3390 0 13 -1392 ',
                '1405 -1405 1405 -6 0 -1209 -1199 -2675 -2665 -1466 -1466 -2672 -2665 -2680 ',
                '-2665 -16 0 -3930 3909 -3930 3925 0 6 1199 1209 2665 2675 1466 1466 2665 ',
                '2672 2665 2680 0 20 -1380 1400 -1400 1400 -8 0 -1533 -1518 -3388 -3373z"/>',
                '<path d="M11517 4992 c-383 -383 -697 -702 -697 -707 0 -6 315 -325 699 -709 ',
                '643 -643 701 -698 718 -685 53 42 1383 1381 1383 1393 0 12 -1378 1397 -1397 ',
                '1403 -4 2 -322 -311 -706 -695z"/>',
                '</g>',
                '</svg>',
                '<text text-rendering="optimizeSpeed">',
                '<textPath startOffset="-100%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Subscription Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="0%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Subscription Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="50%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Subscription Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '<textPath startOffset="-50%" fill="black" font-family="\\\'Courier New\\\', monospace" font-size="13px" xlink:href="#text-path-a">',
                'S10N Protocol',
                unicode' • ',
                'Subscription Token',
                '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite"/>',
                '</textPath>',
                '</text>',
                '</g>',
                '</svg>'
            )
        );

        string memory image = string(
            abi.encodePacked(
                "data:image/svg+xml;base64,",
                Base64.encode(bytes(meta))
            )
        );

        return image;
    }

}