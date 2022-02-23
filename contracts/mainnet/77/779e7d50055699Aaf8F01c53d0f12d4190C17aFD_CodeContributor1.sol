//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../ImageAndDescription.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract CodeContributor1 is ImageAndDescription {

    constructor(address _parent) ImageAndDescription(_parent) {}

    function image(uint256) external override view onlyParent returns (string memory) {
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px" viewBox="0 0 400 400" xml:space="preserve">',
                    '<style>',
                        'svg{',
                        'font-family: monospace;',
                        '}',
                        '.ringtext{',
                        'letter-spacing: 1.5px;',
                        'font-size: 15px;',
                        'fill: #ffffff;',
                        '}',
                        '.cointext{',
                        'letter-spacing: 9px;',
                        'font-size: 28px;',
                        'text-anchor: middle;',
                        'fill: #ffffff;',
                        '}',
                        '.obverse{',
                        'letter-spacing: 2px;',
                        'font-size: 18px;',
                        'text-anchor: middle;',
                        'fill: #ffffff;',
                        '}',
                        '.star{',
                        'font-size: 30px;',
                        '}',
                    '</style>',
                    '<defs>',
                        '<path id="ring" d="M80,200a120,120 0 1,0 240,0a120,120 0 1,0 -240,0" fill="none"/>',
                        '<clipPath id="clip1"><rect x="300" y="0" width="100" height="400">',
                            '<animate attributeName="x" values="300;300;0;0" keyTimes="0;.5;.8;1" dur="8s" repeatCount="indefinite"/>',
                            '<animate attributeName="width" values="100;100;300;70" keyTimes="0;.5;.8;1" dur="8s" repeatCount="indefinite"/>',
                        '</rect></clipPath>',
                        '<clipPath id="clip2"><rect x="300" y="0" width="100" height="400">',
                            '<animate attributeName="x" values="300;0;0;0" keyTimes="0;.3;.5;1" dur="8s" repeatCount="indefinite"/>',
                            '<animate attributeName="width" values="100;300;100;100" keyTimes="0;.3;.5;1" dur="8s" repeatCount="indefinite"/>',
                        '</rect></clipPath>',
                        '<radialGradient id="background">',
                        '<stop offset="0%" style="stop-color:#6E2F5D;" />',
                        '<stop offset="100%" style="stop-color:#2E0F2B;" />',
                        '</radialGradient>',
                    '</defs>',
                    '<rect width="400" height="400" fill="url(#background)"/>',
                    '<text>',
                        '<textPath xlink:href="#ring"><tspan class="ringtext">TOKEN OF APPRECIATION \u2726 TOKEN OF APPRECIATION \u2726 TOKEN OF APPRECIATION \u2726</tspan></textPath>',
                        '<animateTransform attributeName="transform" type="rotate" from="360 200 200" to="0 200 200" dur="74s" repeatCount="indefinite"/>',
                    '</text>',
                    '<g>',
                        '<ellipse cx="185" cy="200" rx="0" ry="88" fill="#FE267D">',
                            '<animate attributeName="cx" values="185;200;215" keyTimes="0;.5;1" dur="4s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                            '<animate attributeName="rx" values="0;88;0" keyTimes="0;.5;1" dur="4s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                            '<animate attributeName="fill" values="#FE267D;#95023D;#FE267D" keyTimes="0;.5;1" dur="4s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                        '</ellipse>',
                        '<rect x="185" y="112" width="30" height="176" fill="#FE267D">',
                            '<animate attributeName="x" values="185;200;185;200;185" keyTimes="0;.25;.5;.75;1" dur="8s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5;0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                            '<animate attributeName="width" values="30;0;30;0;30" keyTimes="0;.25;.5;.75;1" dur="8s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5;0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                            '<animate attributeName="fill" values="#FE267D;#95023D;#FE267D;#95023D;#FE267D" keyTimes="0;.25;.5;.75;1" dur="8s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5;0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                        '</rect>',
                        '<ellipse cx="215" cy="200" rx="0" ry="88" fill="#EEDACC">',
                            '<animate attributeName="cx" values="215;200;185" keyTimes="0;.5;1" dur="4s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                            '<animate attributeName="rx" values="0;88;0" keyTimes="0;.5;1" dur="4s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                            '<animate attributeName="fill" values="#510020;#F45A98;#510020" keyTimes="0;.5;1" dur="4s" repeatCount="indefinite" calcMode="spline" keySplines="0.5 0.5 0.5 1; 0.5 0 0.5 0.5"/>',
                        '</ellipse>',
                    '</g>',
                    '<g clip-path="url(#clip1)">',
                        '<text transform="translate(200,149)" class="obverse"><tspan class="star" x="0" y="0"></tspan><tspan class="star" x="0" y="20">\u2726</tspan><tspan x="0" y="45">CODE</tspan><tspan x="0" y="70">CONTRIBUTOR</tspan><tspan class="star" x="0" y="95"></tspan><tspan class="star" x="0" y="115"></tspan></text>',
                    '</g>',
                    '<g clip-path="url(#clip2)">',
                        '<text transform="translate(200,172)" class="cointext"><tspan>NFT</tspan><tspan x="0" y="34">PAWN</tspan><tspan x="0" y="68">SHOP</tspan></text>',
                    '</g>',
                    '</svg>'
                )
            );
    }

    function description(uint256) external override view onlyParent returns (string memory) {
        return string(
            abi.encodePacked(
                "Level 1 Code Contributor token, given to community members who contributed code that has been deployed to production."
                )
            );
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

abstract contract ImageAndDescription {
    address public parent;

    modifier onlyParent() {
        require(msg.sender == parent, "ImageAndDescription: only parent");
        _;
    }

    constructor(address _parent) {
        parent = _parent;
    }

    function image(uint256 tokenId) external view virtual returns (string memory);
    function description(uint256 tokenId) external view virtual returns (string memory);
}

// SPDX-License-Identifier: MIT

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