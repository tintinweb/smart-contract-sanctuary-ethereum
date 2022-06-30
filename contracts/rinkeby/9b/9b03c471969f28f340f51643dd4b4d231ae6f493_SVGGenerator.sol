// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {ISVGGenerator} from "./interfaces/ISVGGenerator.sol";

contract SVGGenerator is ISVGGenerator {
    bytes constant SVG_OPEN_TAG = bytes('<svg width="500" height="500" viewBox="0 0 500 500" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">');
    bytes constant SVG_CLOSE_TAG = bytes("</svg>");
    bytes constant DEFS_OPEN_TAG = bytes("<defs>");
    bytes constant DEFS_CLOSE_TAG = bytes("</defs>");

    bytes[7] TAGS = [
        bytes("linearGradient"),
        bytes("radialGradient"),
        bytes("stop"),
        bytes("circle"),
        bytes("path"),
        bytes("rect")
    ];

    bytes[2] PATH_DEFAULT_PROPS_BY_IDX = [
        bytes('d="M178.386 341.396C209.527 341.396 234.772 316.151 234.772 285.01C234.772 253.869 209.527 228.624 178.386 228.624C147.245 228.624 122 253.869 122 285.01C122 316.151 147.245 341.396 178.386 341.396Z"'),
        bytes('d="M364.407 341.395H302.708C291.042 341.395 280.38 334.796 275.176 324.355L201.64 176.839C197.32 168.176 203.624 157.994 213.305 158H275.004C286.67 158 297.331 164.598 302.536 175.038L376.072 322.557C380.393 331.22 374.088 341.402 364.407 341.395Z"')
    ];

    bytes[4][4] OFFSET_LOOKUP = [
        [bytes('0'), bytes('0x0'), bytes('0x0'), bytes('0x0')],
        [bytes('0'), bytes('1'), bytes('0x0'), bytes('0x0')],
        [bytes('0'), bytes('0.5'), bytes('1'), bytes('0x0')],
        [bytes('0'), bytes('0.33'), bytes('0.66'), bytes('1')]
    ];

    bytes[4] GRADIENT_IDS = [
        bytes('g0'),
        bytes('g1'),
        bytes('g2'),
        bytes('g3')
    ];

    bytes constant BACKGROUND_DEFAULT_PROPS = bytes('width="500" height="500"');
    bytes constant CIRCLE_DEFAULT_PROPS = bytes('cx="249.5" cy="249.5" r="194.5" stroke-width="4"');
    bytes constant GRADIENT_DEFAULT_PROPS = bytes('gradientUnits="userSpaceOnUse"');

    function removeFromArray(bytes[] memory array, uint256 idx) internal pure {
        array[idx] = array[array.length - 1];
        assembly { mstore(array, sub(mload(array), 1)) }
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum) internal pure returns (uint256) {
        for (uint256 _idx; _idx < _addendum.length; _idx++) {
            _output[_outputIdx++] = _addendum[_idx];
        }
        return _outputIdx;
    }

    function compareValue(bytes memory value, string memory compareTo) internal pure returns (bool) {
        return keccak256(value) == keccak256(bytes(compareTo));
    }

    function generateStops(SVGParams memory params, bytes memory output, uint256 outputIdx) internal view returns(uint256) {
        uint256 len = params.palette.length - 1;
        for(uint256 i = 0; i < len; i++) {
            bytes memory stop = bytes(abi.encodePacked(
                '<',
                TAGS[2],
                ' offset="',
                OFFSET_LOOKUP[len - 1][i],
                '" stop-color="',
                params.palette[i],
                '"/>'
            ));
            outputIdx = addOutput(output, outputIdx, stop);
        }
        return outputIdx;
    }

    function generateGradient(SVGParams memory params, bytes memory gradientId, uint256 gradientIdx, bytes memory output, uint256 outputIdx) internal view returns(uint256) {
        bytes memory gradientOpenTag = bytes(abi.encodePacked(
            '<',
            TAGS[params.gradientType],
            ' id="',
            gradientId,
            '" ',
            GRADIENT_DEFAULT_PROPS,
            ' ',
            params.gradientStaticProps,
            ' ',
            params.gradientDynamicProps.length > 0 ? params.gradientDynamicProps[gradientIdx] : bytes(''),
            '>'
        ));
        bytes memory gradientClosingTag = bytes(abi.encodePacked(
            '</',
            TAGS[params.gradientType],
            '>'
        ));
        outputIdx = addOutput(output, outputIdx, gradientOpenTag);
        outputIdx = generateStops(params, output, outputIdx);
        outputIdx = addOutput(output, outputIdx, gradientClosingTag);
        return outputIdx;
    }

    function genenerateGradients(SVGParams memory params, bytes memory output, uint256 outputIdx) internal view returns (uint256) {
        uint256 numGradients = params.gradientDynamicProps.length;
        if(numGradients > 0) {
            for(uint256 i = 0; i < numGradients; i++) {
                outputIdx = generateGradient(params, GRADIENT_IDS[i], i, output, outputIdx);
            }
        } else {
            outputIdx = generateGradient(params, GRADIENT_IDS[0], 0, output, outputIdx);
        }
        return outputIdx;
    }

    function generatePath(SVGParams memory params, uint256 pathIdx, bytes memory output, uint256 outputIdx) internal view returns (uint256) {
        bytes memory props = params.pathProps;
        if(compareValue(props, '0x0')) {
            props = bytes(abi.encodePacked(
                'fill="url(#',
                GRADIENT_IDS[pathIdx],
                ')"'
            ));
        }
        bytes memory path = bytes(abi.encodePacked(
            '<',
            TAGS[4],
            ' ',
            PATH_DEFAULT_PROPS_BY_IDX[pathIdx],
            ' ',
            props,
            '/>'
        ));
        return addOutput(output, outputIdx, path);
    }

    function generateCircle(SVGParams memory params, bytes memory output, uint256 outputIdx) internal view returns (uint256) {
        bytes memory circle = bytes(abi.encodePacked(
            '<',
            TAGS[3],
            ' ',
            CIRCLE_DEFAULT_PROPS,
            ' ',
            params.circleProps,
            '/>'
        ));
        return addOutput(output, outputIdx, circle);
    }

    function generateBackground(SVGParams memory params, bytes memory output, uint256 outputIdx) internal view returns (uint256) {
        bytes memory props = params.backgroundProps;
        if(compareValue(props, '0x0')) {
            props = bytes(abi.encodePacked(
                'fill="',
                params.palette[params.palette.length - 1],
                '"'
            ));
        }
        bytes memory background = bytes(abi.encodePacked(
            '<',
            TAGS[5],
            ' ',
            BACKGROUND_DEFAULT_PROPS,
            ' ',
            props,
            '/>'
        ));
        return addOutput(output, outputIdx, background);
    } 

    function generateSVGImage(SVGParams memory params) public view returns (string memory) {
        // Keep track of what we're returning
        bytes memory output = new bytes(2000);
        uint256 outputIdx = 0;

        // Start the output with SVG tags
        outputIdx = addOutput(output, outputIdx, SVG_OPEN_TAG);

        //Generate def tags and gradients
        outputIdx = addOutput(output, outputIdx, DEFS_OPEN_TAG);
        outputIdx = genenerateGradients(params, output, outputIdx);
        outputIdx = addOutput(output, outputIdx, DEFS_CLOSE_TAG);

        //Generate background
        outputIdx = generateBackground(params, output, outputIdx);

        //Generate background circle
        outputIdx = generateCircle(params, output, outputIdx);

        //Generate two logo paths
        outputIdx = generatePath(params, 0, output, outputIdx);
        outputIdx = generatePath(params, 1, output, outputIdx);

        //Generate closing svg tag
        outputIdx = addOutput(output, outputIdx, SVG_CLOSE_TAG);

        bytes memory finalOutput = new bytes(outputIdx);
        for (uint256 _idx; _idx < outputIdx; _idx++) {
            finalOutput[_idx] = output[_idx];
        }
        
        return (string(finalOutput));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

interface ISVGGenerator {
    struct SVGParams {
        bytes backgroundProps;
        bytes circleProps;
        bytes pathProps;
        bytes gradientStaticProps;
        uint48 gradientType;
        bytes[] gradientDynamicProps;
        bytes[] palette;
    }

    function generateSVGImage(SVGParams memory params) external view returns (string memory);
}