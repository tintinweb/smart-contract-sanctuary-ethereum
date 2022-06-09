//SPDX-License-Identifier: MIT

// this is a modification of original uniswap v3 nft design

// todo add random 1000 number (15k)
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

interface IMint {
    function team(uint256 _tokenID) external view returns (uint256);
}

contract Renderer {
    using Strings for uint256;

    IMint public nft;

    struct SVGParams {
        uint256 tokenId;
        string color0;
        string color1;
        string color2;
        string color3;
        string bordertext;
        string title;
        string subtitle;
        string attribute1;
        string attribute2;
        string attribute3;
    }

    constructor(address _contract) {
        nft = IMint(_contract);
    }

    function render(uint256 _tokenId) external view returns (string memory) {
        uint256 teams = nft.team(_tokenId);
        string memory team = "Sword";

        string memory color1 = "CC5500";
        string memory color2 = "CC5500";
        string memory color3 = "CC5500";
        string memory color4 = "CC5500";

        if (teams == 0) {
            color1 = "0096FF";
            // color1 = '9ec1d9'; //testing
        } else {
            team = "Shield";
            color1 = "CC5500";
            color1 = "6e3a16"; //testing
        }

        return
            generateSVG(
                SVGParams(
                    _tokenId,
                    color1,
                    color2,
                    color3,
                    color4,
                    "XP: 0", //border text
                    "The Quest", //title
                    "", //subtitle
                    _tokenId.toString(), //attr1
                    team, //attr 2
                    "0" //attr3
                )
            );
    }

    function generateSVG(SVGParams memory params)
        internal
        pure
        returns (string memory svg)
    {
        /*
        address: "0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        msg: "Forged in SVG for Uniswap in 2021 by 0xe8ab59d3bcde16a29912de83a90eb39628cfc163",
        sig: "0x2df0e99d9cbfec33a705d83f75666d98b22dea7c1af412c584f7d626d83f02875993df740dc87563b9c73378f8462426da572d7989de88079a382ad96c57b68d1b",
        version: "2"
        */
        return
            string(
                abi.encodePacked(
                    generateSVGDefs(params),
                    generateSVGBorderText(params.bordertext),
                    generateSVGCardMantle(params.title, params.subtitle),
                    generateMiddleImage(params.tokenId),
                    generateSVGLeftData(
                        params.attribute1,
                        params.attribute2,
                        params.attribute3
                    ),
                    "</svg>"
                )
            );
    }

    function generateSVGDefs(SVGParams memory params)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<svg width="290" height="500" viewBox="0 0 290 500" xmlns="http://www.w3.org/2000/svg"',
                ' xmlns:xlink="http://www.w3.org/1999/xlink">',
                "<defs>",
                '<filter id="f1"><feImage result="p0" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><rect width='290px' height='500px' fill='#",
                            params.color0,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feImage result="p1" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            "1",
                            "' cy='",
                            "1",
                            "' r='120px' fill='#",
                            params.color1,
                            "'/></svg>"
                        )
                    )
                ),
                '"/><feImage result="p2" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            "1",
                            "' cy='",
                            "1",
                            "' r='120px' fill='#",
                            params.color2,
                            "'/></svg>"
                        )
                    )
                ),
                '" />',
                '<feImage result="p3" xlink:href="data:image/svg+xml;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            "<svg width='290' height='500' viewBox='0 0 290 500' xmlns='http://www.w3.org/2000/svg'><circle cx='",
                            "1",
                            "' cy='",
                            "1",
                            "' r='100px' fill='#",
                            params.color3,
                            "'/></svg>"
                        )
                    )
                ),
                '" /><feBlend mode="overlay" in="p0" in2="p1" /><feBlend mode="exclusion" in2="p2" /><feBlend mode="overlay" in2="p3" result="blendOut" /><feGaussianBlur ',
                'in="blendOut" stdDeviation="42" /></filter> <clipPath id="corners"><rect width="290" height="500" rx="42" ry="42" /></clipPath>',
                '<path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V460 A28 28 0 0 1 250 488 H40 A28 28 0 0 1 12 460 V40 A28 28 0 0 1 40 12 z" />',
                '<path id="minimap" d="M234 444C234 457.949 242.21 463 253 463" />',
                '<filter id="top-region-blur"><feGaussianBlur in="SourceGraphic" stdDeviation="24" /></filter>',
                '<linearGradient id="grad-up" x1="1" x2="0" y1="1" y2="0"><stop offset="0.0" stop-color="white" stop-opacity="1" />',
                '<stop offset=".9" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<linearGradient id="grad-down" x1="0" x2="1" y1="0" y2="1"><stop offset="0.0" stop-color="white" stop-opacity="1" /><stop offset="0.9" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<mask id="fade-up" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-up)" /></mask>',
                '<mask id="fade-down" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="url(#grad-down)" /></mask>',
                '<mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="white" /></mask>',
                '<linearGradient id="grad-symbol"><stop offset="0.7" stop-color="white" stop-opacity="1" /><stop offset=".95" stop-color="white" stop-opacity="0" /></linearGradient>',
                '<mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)" /></mask></defs>',
                '<g clip-path="url(#corners)">',
                '<rect fill="',
                params.color0,
                '" x="0px" y="0px" width="290px" height="500px" />',
                '<rect style="filter: url(#f1)" x="0px" y="0px" width="290px" height="500px" />',
                ' <g style="filter:url(#top-region-blur); transform:scale(1.5); transform-origin:center top;">',
                '<rect fill="none" x="0px" y="0px" width="290px" height="500px" />',
                '<ellipse cx="50%" cy="0px" rx="180px" ry="120px" fill="#000" opacity="0.85" /></g>',
                '<rect x="0" y="0" width="290" height="500" rx="42" ry="42" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" /></g>'
            )
        );
    }

    function generateSVGBorderText(string memory text)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<text text-rendering="optimizeSpeed">',
                '<textPath startOffset="-100%" fill="white" font-family="\'Verdana\', monospace" font-size="10px" xlink:href="#text-path-a">',
                text,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" />',
                '</textPath> <textPath startOffset="0%" fill="white" font-family="\'Verdana\', monospace" font-size="10px" xlink:href="#text-path-a">',
                text,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /> </textPath>',
                '<textPath startOffset="50%" fill="white" font-family="\'Verdana\', monospace" font-size="10px" xlink:href="#text-path-a">',
                text,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s"',
                ' repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="white" font-family="\'Verdana\', monospace" font-size="10px" xlink:href="#text-path-a">',
                text,
                ' <animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>'
            )
        );
    }

    function generateSVGCardMantle(string memory title, string memory subtitle)
        private
        pure
        returns (string memory svg)
    {
        svg = string(
            abi.encodePacked(
                '<g mask="url(#fade-symbol)"><rect fill="none" x="0px" y="0px" width="290px" height="200px" /> <text y="70px" x="32px" fill="white" font-family="\'Verdana\', monospace" font-weight="200" font-size="36px">',
                title,
                '</text><text y="115px" x="32px" fill="white" font-family="\'Verdana\', monospace" font-weight="200" font-size="36px">',
                subtitle,
                "</text></g>",
                '<rect x="16" y="16" width="258" height="468" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" />'
            )
        );
    }

    function generateMiddleImage(uint256 _tokenid)
        private
        pure
        returns (string memory svg)
    {
        uint256 r = uint256(keccak256(abi.encodePacked(_tokenid)));
        if (r % 2 == 0) {
            svg = renderTower();
        } else {
            svg = renderPyramid();
        }
    }

    function generateSVGLeftData(
        string memory attribute1,
        string memory attribute2,
        string memory attribute3
    ) private pure returns (string memory svg) {
        uint256 str1length = bytes(attribute1).length + 4;
        uint256 str2length = bytes(attribute2).length + 10;
        uint256 str3length = bytes(attribute3).length + 10;
        uint256 score = uint256(keccak256(abi.encodePacked(attribute1))) % 100;
        svg = string(
            abi.encodePacked(
                ' <g style="transform:translate(29px, 384px)">',
                '<rect width="',
                uint256(7 * (str1length + 4)).toString(),
                'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)" />',
                '<text x="12px" y="17px" font-family="\'Verdana\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">ID: </tspan>',
                attribute1,
                "</text></g>",
                ' <g style="transform:translate(29px, 414px)">',
                '<rect width="',
                uint256(7 * (str2length + 4)).toString(),
                'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)" />',
                '<text x="12px" y="17px" font-family="\'Verdana\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Team: </tspan>',
                attribute2,
                "</text></g>",
                ' <g style="transform:translate(29px, 444px)">',
                '<rect width="',
                uint256(7 * (str3length + 4)).toString(),
                'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)" />',
                '<text x="12px" y="17px" font-family="\'Verdana\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Coins: </tspan>',
                attribute3,
                "</text></g>"
                '<g style="transform:translate(226px, 433px)">',
                '<rect width="36px" height="36px" rx="8px" ry="8px" fill="none" stroke="rgba(255,255,255,0.2)" />',
                '<text x="7px" y="21px" font-family="\'Verdana\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)"> </tspan>',
                uint2str(score),
                "k</text>",
                // here goes bottom left image
                "</g>"
            )
        );
    }

    function renderTower() internal pure returns (string memory pyramid) {
        pyramid = string(
            abi.encodePacked(
                '<path transform="translate(30,160) scale(1.7)" id="path2319"  style="fill-rule:evenodd;fill:#ffff" d="m71.188 15.688l-13.25 4.406c-4.603 16.1-8.587 34.293-11.563 50.718-2.927 4.717-4.258 10.391-5.594 16.063 6.542 7.245 14.248 11.782 22.094 18.375 12.628-4.06 18.716-5.289 31.031-11.219l0.438-0.156-0.125-0.437c-0.736-5.112-1.862-10.068-4.219-14.532-2.398-19.073-3.86-35.708-8.531-54.781l-6.531-8.281-3.75-0.156zm3.187 0.562l6.531 7.719-13.312 4.187 13.187-3.844c4.876 18.762 6.145 35.333 8.094 54.094-10.151 3.392-13.144 3.54-23.594 6.906 1.001-21.292 0.987-36.188 2.313-57.156l-0.156 0.032-2.126-9.157 9.063-2.781zm-3.419-0.216l2.861 0.006-9.05 2.845-6.127 1.304 12.316-4.155zm-6.331 3.31l2.75 8.968-0.063-0.031-2.968 56.719c-5.09-4.956-11.028-7.894-17.032-13.875 2.544-16.676 6.206-34.989 11.032-50.687l8.703 7.887-8.086-7.757 5.664-1.224zm17.187 18.437l-13.468 3.688-0.469 18.406 0.063-0.313 0.906-17.718 12.781-3.438 2.594 16.719-15.031 4.625-0.376 0.219 15.907-4.594-2.907-17.594zm-3.937 4.375c-0.697 0.991-1.367 2.078-2.406 1.813l-1.375-0.844c-0.442 0.869-1.311 1.096-1.313 2.625l-2.375-1.219-0.437 0.281 3.156 2.469c0.294-1.693 0.514-3.746 1.375-2.719l1.031 0.626c1.498-0.207 1.494-1.404 2.031-2.25l1.532 1.312 1.687-0.062 0.094-0.376-1.219-0.406-1.781-1.25zm-0.844 6l-2.031 1.594-1.75-1.094c-1.201-0.763-1.896 0.75-2.844 1.125l0.344 0.188c0.844-0.113 1.688-0.768 2.531-0.25 0.574 0.238 0.821 0.804 1.813 0.625 1.413 0.515 1.608-1.053 2.281-1.594l1.656 0.5 0.281-0.469-2.281-0.625zm4.375 2.906c-0.815 0.061-1.363 0.794-2 1.282l-1.937-1.188-2.688 1.875 0.157 0.219 2.437-0.969 1.937 1.188c1.143-0.269 2.091-0.701 3.126-1.938l-0.126-0.281c-0.35-0.168-0.634-0.208-0.906-0.188zm-34.468 20.469c6.244 6.026 11.9 8.905 17.656 14.157-0.632 5.324-1.797 12.476-1.844 18.092-7.732-5.778-15.086-9.996-21.188-17.405 1.17-5.259 2.3-10.538 5.376-14.844zm42.187 7.219c2.659 4.833 3.611 9.667 4 14.5-11.346 5.642-16.905 7.17-29.219 10.87 0.365-5.639 0.729-12.829 1.094-18.182 10.398-3.502 13.774-3.817 24.125-7.188z"/>'
            )
        );
    }

    function renderPyramid() internal pure returns (string memory tent) {
        tent = string(
            abi.encodePacked(
                '<path  transform="translate(30,120) scale(1.7)" style="fill-rule:evenodd;fill:#ffff" d="m66.062 27.75l-14.062 10.938-1-0.438-45.312 29.25 53.312 40.72 20.188-8.939 3.874 3.029 4.938-2.404-0.094-2.062 8.563-4 1.937 1.75 4.594-2.375-0.19-4.375 20-8.875-40.622-37.344-0.907 0.625-15.219-15.5zm0.219 1.594l14.781 14.781-0.75 1.375-8.718 0.5-4.532 5.688-2.468 0.5 1.687-22.844zm-1 0.187l-1.406 22.813h-0.031l-1.375-2.75-7.375-2.344-0.344-6.406-2.469-1.938 13-9.375zm-14.187 9.125l3.187 2.219-0.125 6.563-3.625 5.187c-1.539 0.246-3.067 0.588-4.593 0.906l-5.469 3.281-3.907-0.5v0.157l3.407 0.656-1.344 3.844 1.719-3.75 0.187 0.031 5.469-3.406c1.424-0.293 2.975-0.389 4.406-0.656l2.344 7.562c-1.569 1.452-2.131 3.5-2.75 5.469 0.009 0.063 0.021 0.125 0.031 0.187l-5.75 6.5-3.469 1.344 3.688-1.094 5.688-6.062c0.324 1.356 0.903 2.638 1.406 3.937 0.053 0.066 0.088 0.099 0.094 0.125 0.018-0.019 0.044-0.036 0.124-0.062-0.598-1.471-1.205-3.318-1.531-4.844 0.585-1.863 2.033-3.691 2.688-5.531l-2.313-7.625 4.188-4.938 7.468 1.782 0.844 3.968 0.032-0.031-4.438 52.535-1.844-2-0.625-5.598 0.063 4.938-2.719-2.97-0.844-0.34-2.031-5.628 1.031-3.062-1.281 3.062 1.906 5.468-6.656-2.842 7.844 3.592 4.562 6.13-51.375-39.691 44.313-28.813zm0.687 53.094l0.25-0.625-0.031-0.063-0.219 0.688zm4.5 7.062v-0.187l-0.031-0.094 0.031 0.281zm-15.469-24.562l-0.437 0.125-0.063 0.063 0.5-0.188zm41.376-30.938l39.062 36.344-18.47 8.313-0.75-24-3.874-4.813-3.218 4.063-0.25 21.219-3.344-2.5-4.282-1.157-0.374-10.031-3.75-4.812-3.376 4.25-0.718 28.5-19.188 8.652 2-2.84 0.844-5.156 5.5-2.125 6.938 1.531-4.969-1.281 2.219-3.25-0.094-0.031-2.406 3.187-1.844-0.469-5.282 2 0.813-5.062 2.969-5.532-0.094-0.031-3.094 5.531-1.687 10.468-2.281 2.69 4.874-53.439 3.313-1.406 4.437-5.563 8.188-0.062 3.344 4.031-0.063 8.031 1.188 1.969-0.75-2.125v-7.437l8.343 4.281 0.126-0.188-8.438-4.468-0.031 0.031v-0.281l-2.907-4.188 1.376-2.844zm2.281 17.219l0.093 0.281 0.032-0.062-0.125-0.219zm13.875-0.437l3.036 3.91-3.318 0.965 0.282-4.875zm-0.532 0.406l0.157 4.469-2.657-1.5 2.5-2.969zm-2.49 3.092l2.787 1.51 0.239 29.639-1.286-1.147-0.093-7.469-1.813-1.344 0.166-21.189zm6.268 0.428l0.91 28.73-3.906 2-0.313-29.774 3.309-0.956zm-18.559 2.886l3.094 4-3.25 0.938 3.375-0.75 1.25 28.312-4.328 1.974-0.297-29.536-0.063-0.032 0.219-4.906zm-0.312 0.313l-0.031 4.531-2.75-1.469 2.781-3.062zm-2.75 3.25l2.809 1.432 0.118 29.549-3.49-2.575 0.563-28.406zm7.125 10.906l3.718 1.281-3.406 5.313-0.312-6.594zm4.437 1.23l5.094 3.739-0.156 6.687-1.188 0.531-0.031-6.093-3.75-2-2.938 4.219 0.032 6.968-0.813 0.469-0.343-8.719 4.093-5.801zm0.029 3.128l3.502 1.955 0.034 6.005-6.254 2.864-0.039-6.859 2.757-3.965z"/>'
            )
        );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

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