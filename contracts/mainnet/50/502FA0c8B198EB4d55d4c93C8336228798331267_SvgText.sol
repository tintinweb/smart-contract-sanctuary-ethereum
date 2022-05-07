//	SPDX-License-Identifier: MIT
/// @title  Text Logo Elements
/// @notice On-chain SVG
pragma solidity ^0.8.0;

import '../common/SvgFill.sol';
import '../common/SvgElement.sol';
import '../common/LogoHelper.sol';

library SvgText {

  struct Font {
    string link;
    string name;
  }
  
  struct Text {
    string id;
    string class;
    string val;
    string textType;
    Font font;
    uint256 size;
    string paletteName;
    SvgFill.Fill[] fills;
    bool animate;
  }

  function getSvgDefs(string memory seed, Text memory text) public pure returns (string memory) {
    string memory defs = '';

    for (uint i = 0; i < text.fills.length; i++) {
      defs = string(abi.encodePacked(defs, SvgFill.getFillDefs(seed, text.fills[i])));
    }

    if (LogoHelper.equal(text.textType, 'Rug Pull')) {
      uint256[] memory ys = getRugPullY(text);
      for (uint8 i = 0; i < 4; i++) {
        string memory path = SvgElement.getRect(SvgElement.Rect('', '', LogoHelper.toString(ys[i] + 3), '100%', '100%', '', '', ''));
        string memory id = string(abi.encodePacked('clip-', LogoHelper.toString(i)));
        defs = string(abi.encodePacked(defs, SvgElement.getClipPath(SvgElement.ClipPath(id, path))));
      }
    }
    return defs;
  }
  
  // TEXT //
  function getSvgStyles(Text memory text) public pure returns (string memory) {
    string memory styles = !LogoHelper.equal(text.font.link, '') ? string(abi.encodePacked('@import url(', text.font.link, '); ')) : '';
    styles = string(abi.encodePacked(styles, '.', text.class, ' { font-family:', text.font.name, '; font-size: ', LogoHelper.toString(text.size), 'px; font-weight: 800; } '));

    for (uint i=0; i < text.fills.length; i++) {
      styles = string(abi.encodePacked(styles, SvgFill.getFillStyles(text.fills[i])));
    }
    return styles;
  }

  function getSvgContent(Text memory text) public pure returns (string memory) {
    string memory content = '';
    if (LogoHelper.equal(text.textType, 'Plain')) {
      content = SvgElement.getText(SvgElement.Text(text.class, '50%', '50%', '', '', '', 'central', 'middle', '', '', '', text.val));
    } else if (LogoHelper.equal(text.textType, 'Rug Pull')) {
      content = getRugPullContent(text);
    } else if (LogoHelper.equal(text.textType, 'Mailbox') || LogoHelper.equal(text.textType, 'Warped Mailbox')) {
      uint8 iterations = LogoHelper.equal(text.textType, 'Mailbox') ? 2 : 30;
      for (uint8 i = 0; i < iterations; i++) {
        content = string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(string(abi.encodePacked(text.class, ' ', text.fills[i % text.fills.length].class)), '50%', '50%', LogoHelper.toString(iterations - i), LogoHelper.toString(iterations - i), '', 'central', 'middle', '', '', '', text.val))));
      }
      content = string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(string(abi.encodePacked(text.class, ' ', text.fills[text.fills.length - 1].class)), '50%', '50%', '', '', '', 'central', 'middle', '', '', '', text.val))));
    } else if (LogoHelper.equal(text.textType, 'NGMI')) {
      string memory rotate = LogoHelper.getRotate(text.val);
      content = SvgElement.getText(SvgElement.Text(text.class, '50%', '50%', '', '', '', 'central', 'middle', rotate, '', '', text.val));
    }
    return content;
  }

  function getRugPullContent(Text memory text) public pure returns (string memory) {
    // get first animation y via y_prev = (y of txt 1) - font size / 2)
    // next animation goes to y_prev + (font size / 3)
    // clip path is txt elemnt y + 3

    string memory content = '';
    uint256[] memory ys = getRugPullY(text);

    string memory element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[4]), '', '2600', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-3', element));      

    content = element;
    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[3]), '', '2400', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-2', element));    
    content = string(abi.encodePacked(content, element));

    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[2]), '', '2200', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-1', element));      
    content = string(abi.encodePacked(content, element));

    element = SvgElement.getAnimate(SvgElement.Animate('y', LogoHelper.toString(ys[1]), '', '2000', '0', '1', 'freeze'));
    element = string(abi.encodePacked(text.val, element));
    element = SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', 'clip-0', element));
    content = string(abi.encodePacked(content, element));

    return string(abi.encodePacked(content, SvgElement.getText(SvgElement.Text(text.class, '50%', LogoHelper.toString(ys[0]), '', '', '', 'alphabetic', 'middle', '', '', '', text.val))));
  }

  function getRugPullY(Text memory text) public pure returns (uint256[] memory) {
    uint256[] memory ys = new uint256[](5);
    uint256 y =  (text.size - (text.size / 4)) + (text.size / 2) + (text.size / 3) + (text.size / 4) + (text.size / 5);
    y = ((300 - y) / 2) + (text.size - (text.size / 4));
    ys[0] = y;
    y = y + text.size / 2;
    ys[1] = y;
    y = y + text.size / 3;
    ys[2] = y;
    y = y + text.size / 4;
    ys[3] = y;
    y = y + text.size / 5;
    ys[4] = y;
    return ys;
  }
}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SvgElement.sol';
import './LogoHelper.sol';

library SvgFill {
  struct Fill {
    string id;
    string class;
    string fillType;
    string[] colors;
    bool animate;
  }

  // FILL //
  function getFillDefs(string memory seed, Fill memory fill) public pure returns (string memory) {
    string memory defs = '';
    if (LogoHelper.equal(fill.fillType, 'Linear Gradient') || LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient')) {
      if (!fill.animate) {
        defs = SvgElement.getLinearGradient(SvgElement.LinearGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient'), ''));
      } else {
       string memory val = LogoHelper.toString(LogoHelper.randomInRange(seed, 100 , 0));
       string memory values = string(abi.encodePacked(val,
                                                      '%;',
                                                      LogoHelper.toString(LogoHelper.randomInRange(string(abi.encodePacked(seed, 'a')), 100 , 0)),
                                                      '%;',
                                                      val,
                                                      '%;'));
        val = LogoHelper.toString(LogoHelper.randomInRange(seed, 50000 , 5000));
        defs = SvgElement.getLinearGradient(SvgElement.LinearGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient'), SvgElement.getAnimate(SvgElement.Animate(getLinearAnimationType(seed), '', values, val, '0', getAnimationRepeat(seed), 'freeze'))));
      }
    } else if (LogoHelper.equal(fill.fillType, 'Radial Gradient') || LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient')) {
      if (!fill.animate) {
        defs = SvgElement.getRadialGradient(SvgElement.RadialGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient'), ''));
      } else {
        string memory val = LogoHelper.toString(LogoHelper.randomInRange(seed, 100, 0));
        string memory values = string(abi.encodePacked(val,
                                                      '%;',
                                                      LogoHelper.toString(LogoHelper.randomInRange(string(abi.encodePacked(seed, 'a')), 100 , 0)),
                                                      '%;',
                                                      val,
                                                      '%;'));
        val = LogoHelper.toString(LogoHelper.randomInRange(seed, 10000 , 5000));
        defs = SvgElement.getRadialGradient(SvgElement.RadialGradient(fill.id, fill.colors, LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient'), SvgElement.getAnimate(SvgElement.Animate(getRadialAnimationType(seed), '', values, val, '0', getAnimationRepeat(seed), 'freeze'))));
        
      }
    }
    return defs;
  }

  function getFillStyles(Fill memory fill) public pure returns (string memory) {
    if (LogoHelper.equal(fill.fillType, 'Solid')) {
      return string(abi.encodePacked('.', fill.class, ' { fill: ', fill.colors[0], ' } '));
    } else if (LogoHelper.equal(fill.fillType, 'Linear Gradient')
                || LogoHelper.equal(fill.fillType, 'Radial Gradient')
                  || LogoHelper.equal(fill.fillType, 'Blocked Linear Gradient')
                    || LogoHelper.equal(fill.fillType, 'Blocked Radial Gradient')) {
      return string(abi.encodePacked('.', fill.class, ' { fill: url(#', fill.id, ') } '));
    }
    string memory styles = '';
    return styles;
  }

  function getLinearAnimationType(string memory seed) private pure returns (string memory) {
    string[4] memory types = ['x1', 'x2', 'y1', 'y2'];
    return types[LogoHelper.random(seed) % types.length];
  }

  function getRadialAnimationType(string memory seed) private pure returns (string memory) {
    string[3] memory types = ['fx', 'fy', 'r'];
    return types[LogoHelper.random(seed) % types.length];
  }

  function getAnimationRepeat(string memory seed) private pure returns (string memory) {
    string[3] memory types = ['indefinite', '1', '2'];
    return types[LogoHelper.random(seed) % types.length];
  }



}

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

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library LogoHelper {
  function getRotate(string memory text) public pure returns (string memory) {
    bytes memory byteString = bytes(text);
    string memory rotate = string(abi.encodePacked('-', toString(random(text) % 10 + 1)));
    for (uint i=1; i < byteString.length; i++) {
      uint nextRotate = random(rotate) % 10 + 1;
      if (i % 2 == 0) {
        rotate = string(abi.encodePacked(rotate, ',-', toString(nextRotate)));
      } else {
        rotate = string(abi.encodePacked(rotate, ',', toString(nextRotate)));
      }
    }
    return rotate;
  }

  function getTurbulance(string memory seed, uint max, uint magnitudeOffset) public pure returns (string memory) {
    string memory turbulance = decimalInRange(seed, max, magnitudeOffset);
    uint rand = randomInRange(turbulance, max, 0);
    return string(abi.encodePacked(turbulance, ', ', getDecimal(rand, magnitudeOffset)));
  }

  function decimalInRange(string memory seed, uint max, uint magnitudeOffset) public pure returns (string memory) {
    uint rand = randomInRange(seed, max, 0);
    return getDecimal(rand, magnitudeOffset);
  }

  // CORE HELPERS //
  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function randomFromInt(uint256 seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed)));
  }

  function randomInRange(string memory input, uint max, uint offset) public pure returns (uint256) {
    max = max - offset;
    return (random(input) % max) + offset;
  }

  function equal(string memory a, string memory b) public pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function toString(uint256 value) public pure returns (string memory) {
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

  function toString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);            
    }
    return string(s);
  }

function char(bytes1 b) internal pure returns (bytes1 c) {
  if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
  else return bytes1(uint8(b) + 0x57);
}
  
  function getDecimal(uint val, uint magnitudeOffset) public pure returns (string memory) {
    string memory decimal;
    if (val != 0) {
      for (uint i = 10; i < magnitudeOffset / val; i=10*i) {
        decimal = string(abi.encodePacked(decimal, '0'));
      }
    }
    decimal = string(abi.encodePacked('0.', decimal, toString(val)));
    return decimal;
  }

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