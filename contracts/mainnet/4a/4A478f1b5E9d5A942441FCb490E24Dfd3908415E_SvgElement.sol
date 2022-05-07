//	SPDX-License-Identifier: MIT
/// @notice Helper to build svg elements
pragma solidity ^0.8.0;

library SvgElement {
  struct Rect {
    string class;
    string x;
    string y;
    string width;
    string height;
    string opacity;
    string fill;
    string filter;
  }

  function getRect(Rect memory rect) public pure returns (string memory) {
    string memory element = '<rect ';
    element = !equal(rect.class, '') ? string(abi.encodePacked(element, 'class="', rect.class, '" ')) : element;
    element = !equal(rect.x, '') ? string(abi.encodePacked(element, 'x="', rect.x, '" ')) : element;
    element = !equal(rect.y, '') ? string(abi.encodePacked(element, 'y="', rect.y, '" ')) : element;
    element = !equal(rect.width, '') ? string(abi.encodePacked(element, 'width="', rect.width, '" ')) : element;
    element = !equal(rect.height, '') ? string(abi.encodePacked(element, 'height="', rect.height, '" ')) : element;
    element = !equal(rect.opacity, '') ? string(abi.encodePacked(element, 'opacity="', rect.opacity, '" ')) : element;
    element = !equal(rect.fill, '') ? string(abi.encodePacked(element, 'fill="url(#', rect.fill, ')" ')) : element;
    element = !equal(rect.filter, '') ? string(abi.encodePacked(element, 'filter="url(#', rect.filter, ')" ')) : element;
    element = string(abi.encodePacked(element, '/>'));
    return element;
  }

  struct Circle {
    string class;
    string cx;
    string cy;
    string r;
    string opacity;
  }

  function getCircle(Circle memory circle) public pure returns (string memory) {
    string memory element = '<circle ';
    element = !equal(circle.class, '') ? string(abi.encodePacked(element, 'class="', circle.class, '" ')) : element;
    element = !equal(circle.cx, '') ? string(abi.encodePacked(element, 'cx="', circle.cx, '" ')) : element;
    element = !equal(circle.cy, '') ? string(abi.encodePacked(element, 'cy="', circle.cy, '" ')) : element;
    element = !equal(circle.r, '') ? string(abi.encodePacked(element, 'r="', circle.r, '" ')) : element;
    element = !equal(circle.opacity, '') ? string(abi.encodePacked(element, 'opacity="', circle.opacity, '" ')) : element;
    element = string(abi.encodePacked(element, '/>'));
    return element;
  }

  struct Text {
    string class;
    string x;
    string y;
    string dx;
    string dy;
    string display;
    string baseline;
    string anchor;
    string rotate;
    string transform;
    string clipPath;
    string val;
  }

  function getText(Text memory txt) public pure returns (string memory) {
    string memory element = '<text ';
    element = !equal(txt.class, '') ? string(abi.encodePacked(element, 'class="', txt.class, '" ')) : element;
    element = !equal(txt.x, '') ? string(abi.encodePacked(element, 'x="', txt.x, '" ')) : element;
    element = !equal(txt.y, '') ? string(abi.encodePacked(element, 'y="', txt.y, '" ')) : element;
    element = !equal(txt.dx, '') ? string(abi.encodePacked(element, 'dx="', txt.dx, '" ')) : element;
    element = !equal(txt.dy, '') ? string(abi.encodePacked(element, 'dy="', txt.dy, '" ')) : element;
    element = !equal(txt.display, '') ? string(abi.encodePacked(element, 'display="', txt.display, '" ')) : element;
    element = !equal(txt.baseline, '') ? string(abi.encodePacked(element, 'dominant-baseline="', txt.baseline, '" ')) : element;
    element = !equal(txt.anchor, '') ? string(abi.encodePacked(element, 'text-anchor="', txt.anchor, '" ')) : element;
    element = !equal(txt.rotate, '') ? string(abi.encodePacked(element, 'rotate="', txt.rotate, '" ')) : element;
    element = !equal(txt.transform, '') ? string(abi.encodePacked(element, 'transform="', txt.transform, '" ')) : element;
    element = !equal(txt.clipPath, '') ? string(abi.encodePacked(element, 'clip-path="url(#', txt.clipPath, ')" ')) : element;
    element = string(abi.encodePacked(element, '>', txt.val, '</text>'));
    return element;
  }

  struct TextPath {
    string class;
    string href;
    string val;
  }

  function getTextPath(TextPath memory txtPath) public pure returns (string memory) {
    string memory element = '<textPath ';
    element = !equal(txtPath.class, '') ? string(abi.encodePacked(element, 'class="', txtPath.class, '" ')) : element;
    element = !equal(txtPath.class, '') ? string(abi.encodePacked(element, 'href="#', txtPath.href, '" ')) : element;
    element = string(abi.encodePacked(element, '>', txtPath.val, '</textPath>'));
    return element;
  }

  struct Tspan {
    string class;
    string display;
    string dx;
    string dy;
    string val;
  }

  function getTspan(Tspan memory tspan) public pure returns (string memory) {
    string memory element = '<tspan ';
    element = !equal(tspan.class, '') ? string(abi.encodePacked(element, 'class="', tspan.class, '" ')) : element;
    element = !equal(tspan.display, '') ? string(abi.encodePacked(element, 'display="', tspan.display, '" ')) : element;
    element = !equal(tspan.dx, '') ? string(abi.encodePacked(element, 'dx="', tspan.dx, '" ')) : element;
    element = !equal(tspan.dy, '') ? string(abi.encodePacked(element, 'dy="', tspan.dy, '" ')) : element;
    element = string(abi.encodePacked(element, '>', tspan.val, '</tspan>'));
    return element;
  }

  struct Animate {
    string attributeName;
    string to;
    string values;
    string duration;
    string begin;
    string repeatCount;
    string fill;
  }

  function getAnimate(Animate memory animate) public pure returns (string memory) {
    string memory element = '<animate ';
    element = !equal(animate.attributeName, '') ? string(abi.encodePacked(element, 'attributeName="', animate.attributeName, '" ')) : element;
    element = !equal(animate.to, '') ? string(abi.encodePacked(element, 'to="', animate.to, '" ')) : element;
    element = !equal(animate.values, '') ? string(abi.encodePacked(element, 'values="', animate.values, '" ')) : element;
    element = !equal(animate.duration, '') ? string(abi.encodePacked(element, 'dur="', animate.duration, 'ms" ')) : element;
    element = !equal(animate.begin, '') ? string(abi.encodePacked(element, 'begin="', animate.begin, 'ms" ')) : element;
    element = !equal(animate.repeatCount, '') ? string(abi.encodePacked(element, 'repeatCount="', animate.repeatCount, '" ')) : element;
    element = !equal(animate.fill, '') ? string(abi.encodePacked(element, 'fill="', animate.fill, '" ')) : element;
    element = string(abi.encodePacked(element, '/>'));
    return element;
  }

  struct Path {
    string id;
    string pathAttr;
    string val;
  }

  function getPath(Path memory path) public pure returns (string memory) {
    string memory element = '<path ';
    element = !equal(path.id, '') ? string(abi.encodePacked(element, 'id="', path.id, '" ')) : element;
    element = !equal(path.pathAttr, '') ? string(abi.encodePacked(element, 'd="', path.pathAttr, '" ')) : element;
    element = string(abi.encodePacked(element, '>', path.val, '</path>'));
    return element;
  }

  struct Group {
    string transform;
    string val;
  }

  function getGroup(Group memory group) public pure returns (string memory) {
    string memory element = '<g ';
    element = !equal(group.transform, '') ? string(abi.encodePacked(element, 'transform="', group.transform, '" ')) : element;
    element = string(abi.encodePacked(element, '>', group.val, '</g>'));
    return element;
  }

  struct Pattern {
    string id;
    string x;
    string y;
    string width;
    string height;
    string patternUnits;
    string val;
  }

  function getPattern(Pattern memory pattern) public pure returns (string memory) {
    string memory element = '<pattern ';
    element = !equal(pattern.id, '') ? string(abi.encodePacked(element, 'id="', pattern.id, '" ')) : element;
    element = !equal(pattern.x, '') ? string(abi.encodePacked(element, 'x="', pattern.x, '" ')) : element;
    element = !equal(pattern.y, '') ? string(abi.encodePacked(element, 'y="', pattern.y, '" ')) : element;
    element = !equal(pattern.width, '') ? string(abi.encodePacked(element, 'width="', pattern.width, '" ')) : element;
    element = !equal(pattern.height, '') ? string(abi.encodePacked(element, 'height="', pattern.height, '" ')) : element;
    element = !equal(pattern.patternUnits, '') ? string(abi.encodePacked(element, 'patternUnits="', pattern.patternUnits, '" ')) : element;
    element = string(abi.encodePacked(element, '>', pattern.val, '</pattern>'));
    return element;
  }

  struct Filter {
    string id;
    string val;
  }

  function getFilter(Filter memory filter) public pure returns (string memory) {
    string memory element = '<filter ';
    element = !equal(filter.id, '') ? string(abi.encodePacked(element, 'id="', filter.id, '" ')) : element;
    element = string(abi.encodePacked(element, '>', filter.val, '</filter>'));
    return element;
  }

  struct Turbulance {
    string fType;
    string baseFrequency;
    string octaves;
    string result;
    string val;
  }

  function getTurbulance(Turbulance memory turbulance) public pure returns (string memory) {
    string memory element = '<feTurbulence ';
    element = !equal(turbulance.fType, '') ? string(abi.encodePacked(element, 'type="', turbulance.fType, '" ')) : element;
    element = !equal(turbulance.baseFrequency, '') ? string(abi.encodePacked(element, 'baseFrequency="', turbulance.baseFrequency, '" ')) : element;
    element = !equal(turbulance.octaves, '') ? string(abi.encodePacked(element, 'numOctaves="', turbulance.octaves, '" ')) : element;
    element = !equal(turbulance.result, '') ? string(abi.encodePacked(element, 'result="', turbulance.result, '" ')) : element;
    element = string(abi.encodePacked(element, '>', turbulance.val, '</feTurbulence>'));
    return element;
  }

  struct DisplacementMap {
    string mIn;
    string in2;
    string result;
    string scale;
    string xChannelSelector;
    string yChannelSelector;
    string val;
  }

  function getDisplacementMap(DisplacementMap memory displacementMap) public pure returns (string memory) {
    string memory element = '<feDisplacementMap ';
    element = !equal(displacementMap.mIn, '') ? string(abi.encodePacked(element, 'in="', displacementMap.mIn, '" ')) : element;
    element = !equal(displacementMap.in2, '') ? string(abi.encodePacked(element, 'in2="', displacementMap.in2, '" ')) : element;
    element = !equal(displacementMap.result, '') ? string(abi.encodePacked(element, 'result="', displacementMap.result, '" ')) : element;
    element = !equal(displacementMap.scale, '') ? string(abi.encodePacked(element, 'scale="', displacementMap.scale, '" ')) : element;
    element = !equal(displacementMap.xChannelSelector, '') ? string(abi.encodePacked(element, 'xChannelSelector="', displacementMap.xChannelSelector, '" ')) : element;
    element = !equal(displacementMap.yChannelSelector, '') ? string(abi.encodePacked(element, 'yChannelSelector="', displacementMap.yChannelSelector, '" ')) : element;
    element = string(abi.encodePacked(element, '>', displacementMap.val, '</feDisplacementMap>'));
    return element;
  }

  struct ClipPath {
    string id;
    string val;
  }

  function getClipPath(ClipPath memory clipPath) public pure returns (string memory) {
    string memory element = '<clipPath ';
    element = !equal(clipPath.id, '') ? string(abi.encodePacked(element, 'id="', clipPath.id, '" ')) : element;
    element = string(abi.encodePacked(element, ' >', clipPath.val, '</clipPath>'));
    return element;
  }

  struct LinearGradient {
    string id;
    string[] colors;
    bool blockScheme;
    string animate;
  }

  function getLinearGradient(LinearGradient memory linearGradient) public pure returns (string memory) {
    string memory element = '<linearGradient ';
    element = !equal(linearGradient.id, '') ? string(abi.encodePacked(element, 'id="', linearGradient.id, '">')) : element;
    uint baseOffset = 100 / (linearGradient.colors.length - 1);
    for (uint i=0; i<linearGradient.colors.length; i++) {
      uint offset;
      if (i != linearGradient.colors.length - 1) {
        offset = baseOffset * i;
      } else {
        offset = 100;
      }
      if (linearGradient.blockScheme && i != 0) {
        element = string(abi.encodePacked(element, '<stop offset="', toString(offset), '%"  stop-color="', linearGradient.colors[i-1], '" />'));
      }

      if (!linearGradient.blockScheme || (linearGradient.blockScheme && i != linearGradient.colors.length - 1)) {
        element = string(abi.encodePacked(element, '<stop offset="', toString(offset), '%"  stop-color="', linearGradient.colors[i], '" />'));
      }
    }
    element = !equal(linearGradient.animate, '') ? string(abi.encodePacked(element, linearGradient.animate)) : element;
    element =  string(abi.encodePacked(element, '</linearGradient>'));
    return element;
  }

  struct RadialGradient {
    string id;
    string[] colors;
    bool blockScheme;
    string animate;
  }

  function getRadialGradient(RadialGradient memory radialGradient) public pure returns (string memory) {
    string memory element = '<radialGradient ';
    element = !equal(radialGradient.id, '') ? string(abi.encodePacked(element, 'id="', radialGradient.id, '">')) : element;
    uint baseOffset = 100 / (radialGradient.colors.length - 1);
    for (uint i=0; i<radialGradient.colors.length; i++) {
      uint offset;
      if (i != radialGradient.colors.length - 1) {
        offset = baseOffset * i;
      } else {
        offset = 100;
      }
      if (radialGradient.blockScheme && i != 0) {
        element = string(abi.encodePacked(element, '<stop offset="', toString(offset), '%"  stop-color="', radialGradient.colors[i-1], '" />'));
      }

      if (!radialGradient.blockScheme || (radialGradient.blockScheme && i != radialGradient.colors.length - 1)) {
        element = string(abi.encodePacked(element, '<stop offset="', toString(offset), '%"  stop-color="', radialGradient.colors[i], '" />'));
      }
    }
    element = !equal(radialGradient.animate, '') ? string(abi.encodePacked(element, radialGradient.animate)) : element;
    element =  string(abi.encodePacked(element, '</radialGradient>'));
    return element;
  }

  function equal(string memory a, string memory b) private pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function toString(uint256 value) private pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
}