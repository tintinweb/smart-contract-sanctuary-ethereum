// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Utils.sol";

contract SvgParser {

    // Limits
    uint256 constant DEFAULT_THRESHOLD_COUNTER = 2800;

    // Bits & Masks
    bytes1 constant tagBit            = bytes1(0x80);
    bytes1 constant startTagBit       = bytes1(0x40);
    bytes1 constant tagTypeMask       = bytes1(0x3F);
    bytes1 constant attributeTypeMask = bytes1(0x7F);

    bytes1 constant dCommandBit       = bytes1(0x80);
    bytes1 constant percentageBit     = bytes1(0x40);
    bytes1 constant negativeBit       = bytes1(0x20);
    bytes1 constant decimalBit        = bytes1(0x10);

    bytes1 constant numberMask        = bytes1(0x0F);

    bytes1 constant filterInIdBit     = bytes1(0x80);

    bytes1 constant filterInIdMask    = bytes1(0x7F);

    // SVG tags
    bytes constant SVG_OPEN_TAG = bytes('<?xml version="1.0" encoding="UTF-8"?><svg width="1320px" height="1760px" viewBox="0 0 1320 1760" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">');
    bytes constant SVG_CLOSE_TAG = bytes("</svg>");

    bytes[25] TAGS = [
        bytes("g"),
        bytes("polygon"),
        bytes("path"),
        bytes("circle"),
        bytes("defs"),
        bytes("linearGradient"),
        bytes("stop"),
        bytes("rect"),
        bytes("polyline"),
        bytes("text"),
        bytes("tspan"),
        bytes("mask"),
        bytes("use"),
        bytes("ellipse"),
        bytes("radialGradient"),
        bytes("filter"),
        bytes("feColorMatrix"),
        bytes("feComposite"),
        bytes("feGaussianBlur"),
        bytes("feMorphology"),
        bytes("feOffset"),
        bytes("pattern"),
        bytes("feMergeNode"),
        bytes("feMerge"),
        bytes("INVALIDTAG")
    ];

    bytes[54] ATTRIBUTES = [
        bytes("d"),
        bytes("points"),
        bytes("transform"),
        bytes("cx"),
        bytes("cy"),
        bytes("r"),
        bytes("stroke"),
        bytes("stroke-width"),
        bytes("fill"),
        bytes("fill-opacity"),
        bytes("translate"),
        bytes("rotate"),
        bytes("scale"),
        bytes("x1"),
        bytes("y1"),
        bytes("x2"),
        bytes("y2"),
        bytes("stop-color"),
        bytes("offset"),
        bytes("stop-opacity"),
        bytes("width"),
        bytes("height"),
        bytes("x"),
        bytes("y"),
        bytes("font-size"),
        bytes("letter-spacing"),
        bytes("opacity"),
        bytes("id"),
        bytes("xlink:href"),
        bytes("rx"),
        bytes("ry"),
        bytes("mask"),
        bytes("fx"),
        bytes("fy"),
        bytes("gradientTransform"),
        bytes("filter"),
        bytes("filterUnits"),
        bytes("result"),
        bytes("in"),
        bytes("in2"),
        bytes("type"),
        bytes("values"),
        bytes("operator"),
        bytes("k1"),
        bytes("k2"),
        bytes("k3"),
        bytes("k4"),
        bytes("stdDeviation"),
        bytes("edgeMode"),
        bytes("radius"),
        bytes("fill-rule"),
        bytes("dx"),
        bytes("dy"),
        bytes("INVALIDATTRIBUTE")
    ];

    bytes[2] PAIR_NUMBER_SET_ATTRIBUTES = [
        bytes("translate"),
        bytes("scale")
    ];

    bytes[4] PAIR_COLOR_ATTRIBUTES = [
        bytes("stroke"),
        bytes("fill"),
        bytes("stop-color"),
        bytes("mask")
    ];

    bytes[23] SINGLE_NUMBER_SET_ATTRIBUTES = [
        bytes("cx"),
        bytes("cy"),
        bytes("r"),
        bytes("rotate"),
        bytes("x1"),
        bytes("y1"),
        bytes("x2"),
        bytes("y2"),
        bytes("offset"),
        bytes("x"),
        bytes("y"),
        bytes("rx"),
        bytes("ry"),
        bytes("fx"),
        bytes("fy"),
        bytes("font-size"),
        bytes("letter-spacing"),
        bytes("stroke-width"),
        bytes("width"),
        bytes("height"),
        bytes("fill-opacity"),
        bytes("stop-opacity"),
        bytes("opacity")
    ];

    bytes[20] D_COMMANDS = [
        bytes("M"),
        bytes("m"),
        bytes("L"),
        bytes("l"),
        bytes("H"),
        bytes("h"),
        bytes("V"),
        bytes("v"),
        bytes("C"),
        bytes("c"),
        bytes("S"),
        bytes("s"),
        bytes("Q"),
        bytes("q"),
        bytes("T"),
        bytes("t"),
        bytes("A"),
        bytes("a"),
        bytes("Z"),
        bytes("z")
    ];

    bytes[2] FILL_RULE = [
        bytes("nonzero"),
        bytes("evenodd")
    ];

    bytes[2] FILTER_UNIT = [
        bytes("userSpaceOnUse"),
        bytes("objectBoundingBox")
    ];

    bytes[6] FILTER_IN = [
        bytes("SourceGraphic"),
        bytes("SourceAlpha"),
        bytes("BackgroundImage"),
        bytes("BackgroundAlpha"),
        bytes("FillPaint"),
        bytes("StrokePaint")
    ];

    bytes[16] FILTER_TYPE = [
        bytes("translate"),
        bytes("scale"),
        bytes("rotate"),
        bytes("skewX"),
        bytes("skewY"),
        bytes("matrix"),
        bytes("saturate"),
        bytes("hueRotate"),
        bytes("luminanceToAlpha"),
        bytes("identity"),
        bytes("table"),
        bytes("discrete"),
        bytes("linear"),
        bytes("gamma"),
        bytes("fractalNoise"),
        bytes("turbulence")
    ];

    bytes[9] FILTER_OPERATOR = [
        bytes("over"),
        bytes("in"),
        bytes("out"),
        bytes("atop"),
        bytes("xor"),
        bytes("lighter"),
        bytes("arithmetic"),
        bytes("erode"),
        bytes("dilate")
    ];

    bytes[3] FILTER_EDGEMODE = [
        bytes("duplicate"),
        bytes("wrap"),
        bytes("none")
    ];


    function checkTag(bytes1 line) internal pure returns (bool) {
        return line & tagBit > 0;
    }

    function checkStartTag(bytes1 line) internal pure returns (bool) {
        return line & startTagBit > 0;
    }

    function getTag(bytes1 line) internal view returns (bytes memory) {
        uint8 key = uint8(line & tagTypeMask);

        if (key >= TAGS.length - 1) {
            return TAGS[TAGS.length - 1];
        }

        return TAGS[key];
    }

    function getAttribute(bytes1 line) internal view returns (bytes memory) {
        uint8 key = uint8(line & attributeTypeMask);

        if (key >= ATTRIBUTES.length - 1) {
            return ATTRIBUTES[ATTRIBUTES.length - 1];
        }

        return ATTRIBUTES[key];
    }

    function compareAttrib(bytes memory attrib, string memory compareTo) internal pure returns (bool) {
        return keccak256(attrib) == keccak256(bytes(compareTo));
    }

    function compareAttrib(bytes memory attrib, bytes storage compareTo) internal pure returns (bool) {
        return keccak256(attrib) == keccak256(compareTo);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum) internal pure returns (uint256) {
        for (uint256 _idx; _idx < _addendum.length; _idx++) {
            _output[_outputIdx++] = _addendum[_idx];
        }
        return _outputIdx;
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2, bytes memory _addendum3)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2), _addendum3);
    }

    function addOutput(bytes memory _output, uint256 _outputIdx, bytes memory _addendum1, bytes memory _addendum2, bytes memory _addendum3, bytes memory _addendum4)
        internal pure returns (uint256)
    {
        return addOutput(_output, addOutput(_output, addOutput(_output, addOutput(_output, _outputIdx, _addendum1), _addendum2), _addendum3), _addendum4);
    }

    function parse(bytes memory input, uint256 idx) public view returns (string memory, uint256) {
        return parse(input, idx, DEFAULT_THRESHOLD_COUNTER);
    }

    function parse(bytes memory input, uint256 idx, uint256 thresholdCounter) public view returns (string memory, uint256) {
        // Keep track of what we're returning
        bytes memory output = new bytes(thresholdCounter * 15); // Plenty of padding
        uint256 outputIdx = 0;

        bool isTagOpen = false;
        uint256 counter = idx;

        // Start the output with SVG tags if needed
        if (idx == 0) {
            outputIdx = addOutput(output, outputIdx, SVG_OPEN_TAG);
        }

        // Go through all bytes we want to review
        while (idx < input.length)
        {
            // Get the current byte
            bytes1 _b = bytes1(input[idx]);

            // If this is a tag, determine if we're creating a new tag
            if (checkTag(_b)) {
                // Close the current tag
                bool closeTag = false;
                if (isTagOpen) {
                    closeTag = true;
                    isTagOpen = false;

                    if ((idx - counter) >= thresholdCounter) {
                        outputIdx = addOutput(output, outputIdx, bytes(">"));
                        break;
                    }
                }

                // Start the next tag
                if (checkStartTag(_b)) {
                    isTagOpen = true;

                    if (closeTag) {
                        outputIdx = addOutput(output, outputIdx, bytes("><"), getTag(_b));
                    } else {
                        outputIdx = addOutput(output, outputIdx, bytes("<"), getTag(_b));
                    }
                } else {
                    // If needed, open and close an end tag
                    if (closeTag) {
                        outputIdx = addOutput(output, outputIdx, bytes("></"), getTag(_b), bytes(">"));
                    } else {
                        outputIdx = addOutput(output, outputIdx, bytes("</"), getTag(_b), bytes(">"));
                    }
                }
            }
            else
            {
                // Attributes
                bytes memory attrib = getAttribute(_b);

                if (compareAttrib(attrib, "transform") || compareAttrib(attrib, "gradientTransform")) {
                    // Keep track of which transform we're doing
                    bool isGradientTransform = compareAttrib(attrib, "gradientTransform");

                    // Get the next byte & attribute
                    idx += 2;
                    _b = bytes1(input[idx]);
                    attrib = getAttribute(_b);

                    outputIdx = addOutput(output, outputIdx, bytes(" "), isGradientTransform ? bytes('gradientTransform="') : bytes('transform="'));
                    while (compareAttrib(attrib, 'translate') || compareAttrib(attrib, 'rotate') || compareAttrib(attrib, 'scale')) {
                        outputIdx = addOutput(output, outputIdx, bytes(" "));
                        (idx, outputIdx) = parseAttributeValues(output, outputIdx, attrib, input, idx);

                        // Get the next byte & attribute
                        idx += 2;
                        _b = bytes1(input[idx]);
                        attrib = getAttribute(_b);
                    }

                    outputIdx = addOutput(output, outputIdx, bytes('"'));

                    // Undo the previous index increment
                    idx -= 2;
                }
                else if (compareAttrib(attrib, "d")) {
                    (idx, outputIdx) = packDPoints(output, outputIdx, input, idx);
                }
                else if (compareAttrib(attrib, "points"))
                {
                    (idx, outputIdx) = packPoints(output, outputIdx, input, idx, bytes(' points="'));
                }
                else if (compareAttrib(attrib, "values"))
                {
                    (idx, outputIdx) = packPoints(output, outputIdx, input, idx, bytes(' values="'));
                }
                else
                {
                    outputIdx = addOutput(output, outputIdx, bytes(" "));
                    (idx, outputIdx) = parseAttributeValues(output, outputIdx, attrib, input, idx);
                }
            }

            idx += 2;
        }

        if (idx >= input.length) {
            // Close out the SVG tags
            outputIdx = addOutput(output, outputIdx, SVG_CLOSE_TAG);
            idx = 0;
        }

        // Pack everything down to the size that actually fits
        bytes memory finalOutput = new bytes(outputIdx);
        for (uint256 _idx; _idx < outputIdx; _idx++) {
            finalOutput[_idx] = output[_idx];
        }

        return (string(finalOutput), idx);
    }

    function packDPoints(bytes memory output, uint256 outputIdx, bytes memory input, uint256 idx) internal view returns (uint256, uint256) {
        outputIdx = addOutput(output, outputIdx, bytes(' d="'));

        // Due to the open-ended nature of points, we concat directly to local_output
        idx += 2;
        uint256 count = uint256(uint8(input[idx + 1])) * 2**8 + uint256(uint8(input[idx]));
        for (uint256 countIdx = 0; countIdx < count; countIdx++) {
            idx += 2;

            // Add the d command prior to any bits
            if (uint8(input[idx + 1] & dCommandBit) > 0) {
                outputIdx = addOutput(output, outputIdx, bytes(" "), D_COMMANDS[uint8(input[idx])]);
            }
            else
            {
                countIdx++;
                outputIdx = addOutput(output, outputIdx, bytes(" "), parseNumberSetValues(input[idx], input[idx + 1]), bytes(","), parseNumberSetValues(input[idx + 2], input[idx + 3]));
                idx += 2;
            }
        }

        outputIdx = addOutput(output, outputIdx, bytes('"'));

        return (idx, outputIdx);
    }

    function packPoints(bytes memory output, uint256 outputIdx, bytes memory input, uint256 idx, bytes memory attributePreface) internal view returns (uint256, uint256) {
        outputIdx = addOutput(output, outputIdx, attributePreface);

        // Due to the open-ended nature of points, we concat directly to local_output
        idx += 2;
        uint256 count = uint256(uint8(input[idx + 1])) * 2**8 + uint256(uint8(input[idx]));
        for (uint256 countIdx = 0; countIdx < count; countIdx++) {
            idx += 2;
            bytes memory numberSet = parseNumberSetValues(input[idx], input[idx + 1]);

            if (countIdx > 0) {
                outputIdx = addOutput(output, outputIdx, bytes(" "), numberSet);
            } else {
                outputIdx = addOutput(output, outputIdx, numberSet);
            }
        }

        outputIdx = addOutput(output, outputIdx, bytes('"'));

        return (idx, outputIdx);
    }

    function parseAttributeValues(
        bytes memory output,
        uint256 outputIdx,
        bytes memory attrib,
        bytes memory input,
        uint256 idx
    )
        internal
        view
        returns (uint256, uint256)
    {
        // Handled in main function
        if (compareAttrib(attrib, "d") || compareAttrib(attrib, "points") || compareAttrib(attrib, "values") || compareAttrib(attrib, 'transform')) {
            return (idx + 2, outputIdx);
        }

        if (compareAttrib(attrib, 'id') || compareAttrib(attrib, 'xlink:href') || compareAttrib(attrib, 'filter') || compareAttrib(attrib, 'result'))
        {
            bytes memory number = Utils.uint2bytes(
                uint256(uint8(input[idx + 2])) * 2**16 +
                uint256(uint8(input[idx + 5])) * 2**8 +
                uint256(uint8(input[idx + 4]))
            );

            if (compareAttrib(attrib, 'xlink:href')) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="#id-'), number, bytes('"'));
            } else if (compareAttrib(attrib, 'filter')) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="url(#id-'), number, bytes(')"'));
            } else {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="id-'), number, bytes('"'));
            }

            return (idx + 4, outputIdx);
        }

        for (uint256 attribIdx = 0; attribIdx < PAIR_NUMBER_SET_ATTRIBUTES.length; attribIdx++) {
            if (compareAttrib(attrib, PAIR_NUMBER_SET_ATTRIBUTES[attribIdx])) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('('), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes(','));
                outputIdx = addOutput(output, outputIdx, parseNumberSetValues(input[idx + 4], input[idx + 5]), bytes(')'));
                return (idx + 4, outputIdx);
            }
        }

        for (uint256 attribIdx = 0; attribIdx < PAIR_COLOR_ATTRIBUTES.length; attribIdx++) {
            if (compareAttrib(attrib, PAIR_COLOR_ATTRIBUTES[attribIdx])) {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), parseColorValues(input[idx + 2], input[idx + 3], input[idx + 4], input[idx + 5]), bytes('"'));
                return (idx + 4, outputIdx);
            }
        }

        if (compareAttrib(attrib, 'rotate')) {
            // Default, single number set values
            outputIdx = addOutput(output, outputIdx, attrib, bytes('('), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes(')'));
            return (idx + 2, outputIdx);
        }

        // Dictionary lookups
        if (compareAttrib(attrib, 'in') || compareAttrib(attrib, 'in2')) {
            // Special case for the dictionary lookup for in & in2 => allow for ID lookup
            if (uint8(input[idx + 3] & filterInIdBit) > 0) {
                bytes memory number = Utils.uint2bytes(
                    uint256(uint8(input[idx + 2] & filterInIdMask)) * 2**16 +
                    uint256(uint8(input[idx + 5] & filterInIdMask)) * 2**8 +
                    uint256(uint8(input[idx + 4]))
                );

                outputIdx = addOutput(output, outputIdx, attrib, bytes('="id-'), number, bytes('"'));
            } else {
                outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_IN[uint8(input[idx + 2])], bytes('"'));
            }

            return (idx + 4, outputIdx);
        } else if (compareAttrib(attrib, 'type')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_TYPE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'operator')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_OPERATOR[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'edgeMode')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_EDGEMODE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'fill-rule')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILL_RULE[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        } else if (compareAttrib(attrib, 'filterUnits')) {
            outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), FILTER_UNIT[uint8(input[idx + 2])], bytes('"'));
            return (idx + 2, outputIdx);
        }

        // Default, single number set values
        outputIdx = addOutput(output, outputIdx, attrib, bytes('="'), parseNumberSetValues(input[idx + 2], input[idx + 3]), bytes('"'));
        return (idx + 2, outputIdx);
    }

    function parseColorValues(bytes1 one, bytes1 two, bytes1 three, bytes1 four) internal pure returns (bytes memory) {
        if (uint8(two) == 0xFF && uint8(one) == 0 && uint8(four) == 0 && uint8(three) == 0) {
            // None identifier case
            return bytes("none");
        }
        else if (uint8(two) == 0x80)
        {
            // URL identifier case
            bytes memory number = Utils.uint2bytes(
                uint256(uint8(one)) * 2**16 +
                uint256(uint8(four)) * 2**8 +
                uint256(uint8(three))
            );
            return abi.encodePacked("url(#id-", number, ")");
        } else {
            return Utils.unpackHexColorValues(uint8(one), uint8(four), uint8(three));
        }
    }

    function parseNumberSetValues(bytes1 one, bytes1 two) internal pure returns (bytes memory) {
        return Utils.unpackNumberSetValues(
            uint256(uint8(two & numberMask)) * 2**8 + uint256(uint8(one)), // number
            uint8(two & decimalBit) > 0, // decimal
            uint8(two & negativeBit) > 0, // negative
            uint8(two & percentageBit) > 0 // percent
        );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Utils {

  /**
   * From https://github.com/provable-things/ethereum-api/blob/master/oraclizeAPI_0.5.sol
   **/

   function uint2bytes(uint _i) internal pure returns (bytes memory) {
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
    uint k = len - 1;
    while (_i != 0) {
      unchecked {
        bstr[k--] = bytes1(uint8(48 + _i % 10));
      }

      _i /= 10;
    }
    return bstr;
  }

  function unpackNumberSetValues(uint _i, bool decimal, bool negative, bool percent) internal pure returns (bytes memory) {
    // Base case
    if (_i == 0) {
      if (percent) {
        return "0%";
      } else {
        return "0";
      }
    }

    // Kick off length with the slots needed to make room for, considering certain bits
    uint j = _i;
    uint len = (negative ? 1 : 0) + (percent ? 1 : 0) + (decimal ? 2 : 0);

    // See how many tens we need
    uint numTens;
    while (j != 0) {
      numTens++;
      j /= 10;
    }

    // Expand length
    // Special case: if decimal & numTens is less than 3, need to pad by 3 since we'll left-pad zeroes
    if (decimal && numTens < 3) {
      len += 3;
    } else {
      len += numTens;
    }

    // Now create the byte "string"
    bytes memory bstr = new bytes(len);

    // Index from right-most to left-most
    uint k = len - 1;

    // Percent character
    if (percent) {
      bstr[k--] = bytes1("%");
    }

    // The entire number
    while (_i != 0) {
      unchecked {
        bstr[k--] = bytes1(uint8(48 + _i % 10));
      }

      _i /= 10;
    }

    // If a decimal, we need to left-pad if the numTens isn't enough
    if (decimal) {
      while (numTens < 3) {
        bstr[k--] = bytes1("0");
        numTens++;
      }
      bstr[k--] = bytes1(".");

      unchecked {
        bstr[k--] = bytes1("0");
      }
    }

    // If negative, the last byte should be negative
    if (negative) {
      bstr[0] = bytes1("-");
    }

    return bstr;
  }

  /**
   * Reference pulled from https://gist.github.com/okwme/f3a35193dc4eb9d1d0db65ccf3eb4034
   **/

  function unpackHexColorValues(uint8 r, uint8 g, uint8 b) internal pure returns (bytes memory) {
    bytes memory rHex = Utils.uint2hexchar(r);
    bytes memory gHex = Utils.uint2hexchar(g);
    bytes memory bHex = Utils.uint2hexchar(b);
    bytes memory bstr = new bytes(7);
    bstr[6] = bHex[1];
    bstr[5] = bHex[0];
    bstr[4] = gHex[1];
    bstr[3] = gHex[0];
    bstr[2] = rHex[1];
    bstr[1] = rHex[0];
    bstr[0] = bytes1("#");
    return bstr;
  }

  function uint2hexchar(uint8 _i) internal pure returns (bytes memory) {
    uint8 mask = 15;
    bytes memory bstr = new bytes(2);
    bstr[1] = (_i & mask) > 9 ? bytes1(uint8(55 + (_i & mask))) : bytes1(uint8(48 + (_i & mask)));
    bstr[0] = ((_i >> 4) & mask) > 9 ? bytes1(uint8(55 + ((_i >> 4) & mask))) : bytes1(uint8(48 + ((_i >> 4) & mask)));
    return bstr;
  }

}