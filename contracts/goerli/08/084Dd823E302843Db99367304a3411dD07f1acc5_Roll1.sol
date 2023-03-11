// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

import "../library/SVGUtils.sol";

/**
 * @title Roll1
 * 
 * @author @life_of_pandaa
 * @author @pow_vt
 * 
 * @notice This contract is used to render svg code for a dice roll of 1.
 * 
 * @dev The die is rendered as a single white dot with a red filter.
 */

contract Roll1 {

    function renderDot(uint8 startIndex, uint8 filterStartId) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<g filter="url(#id',SVGUtils.uint2str(filterStartId),')">',
                '<circle cx="',SVGUtils.uint2str(167 + (startIndex * 333)),'" cy="1000" r="10.0386" fill="#fff"/>',
            '</g>'
        ));
    }

    function renderFilter(uint8 startIndex, uint8 filterStartId) internal pure returns (string memory) {
        return string(abi.encodePacked(
            '<defs>',
                '<filter id="id',SVGUtils.uint2str(filterStartId),'" x="',SVGUtils.uint2str(1 + (startIndex * 333)),'" y=".461" width="333.333" height="2000" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB">',
                    '<feFlood flood-opacity="0" result="BackgroundImageFix"/>',
                    '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
                    '<feMorphology radius="51" operator="dilate" in="SourceAlpha" result="effect1_dropShadow_418_10"/>',
                    '<feOffset/>',
                    '<feGaussianBlur stdDeviation="70"/>',
                    '<feComposite in2="hardAlpha" operator="out"/>',
                    '<feColorMatrix values="0 0 0 0 1 0 0 0 0 0.00392157 0 0 0 0 0 0 0 0 0.2 0"/>',
                    '<feBlend mode="normal" in2="BackgroundImageFix" result="effect1_dropShadow_418_10"/>',
                    '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
                    '<feMorphology radius="11" operator="dilate" in="SourceAlpha" result="effect2_dropShadow_418_10"/>',
                    '<feOffset/>',
                    '<feGaussianBlur stdDeviation="25"/>',
                    '<feComposite in2="hardAlpha" operator="out"/>',
                    '<feColorMatrix values="0 0 0 0 1 0 0 0 0 0.00392157 0 0 0 0 0 0 0 0 0.8 0"/>',
                    '<feBlend mode="normal" in2="effect1_dropShadow_418_10" result="effect2_dropShadow_418_10"/>',
                    '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
                    '<feMorphology radius="8" operator="dilate" in="SourceAlpha" result="effect3_dropShadow_418_10"/>',
                    '<feOffset/>',
                    '<feGaussianBlur stdDeviation="10"/>',
                    '<feComposite in2="hardAlpha" operator="out"/>',
                    '<feColorMatrix values="0 0 0 0 1 0 0 0 0 0.00392157 0 0 0 0 0 0 0 0 1 0"/>',
                    '<feBlend mode="normal" in2="effect2_dropShadow_418_10" result="effect3_dropShadow_418_10"/>',
                    '<feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/>',
                    '<feMorphology radius="2" operator="dilate" in="SourceAlpha" result="effect4_dropShadow_418_10"/>',
                    '<feOffset/>',
                    '<feGaussianBlur stdDeviation="2.5"/>',
                    '<feComposite in2="hardAlpha" operator="out"/>',
                    '<feColorMatrix type="matrix" values="0 0 0 0 1 0 0 0 0 0.00392157 0 0 0 0 0 0 0 0 1 0"/>',
                    '<feBlend mode="normal" in2="effect3_dropShadow_418_10" result="effect4_dropShadow_418_10"/>',
                    '<feBlend mode="normal" in="SourceGraphic" in2="effect4_dropShadow_418_10" result="shape"/>',
                '</filter>',
            '</defs>'
        ));
    }

    function renderRoll1(uint8 startIndex, uint8 filterStartId) public pure returns (string memory) {
        return string(abi.encodePacked(
            renderDot(startIndex, filterStartId),
            renderFilter(startIndex, filterStartId)
        ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.7.0;

library SVGUtils {
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