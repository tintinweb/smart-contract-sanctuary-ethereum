//	SPDX-License-Identifier: MIT
/// @notice Initializes data transfer objects so svg can be built
pragma solidity ^0.8.0;

import './LogoType.sol';
import '../emoticon/SvgEmoticonBuilder.sol';
import '../background/SvgBackground.sol';
import '../text/SvgText.sol';
import './LogoHelper.sol';

library LogoFactory {
  function initBackground(uint256 tokenId, uint256 seed) public view returns (SvgBackground.Background memory) {
    Color.Palette memory palette = LogoType.getPalette(seed);
    return getBackground(tokenId, seed, palette);
  }

  function initEmoticon(uint256 tokenId, uint256 seed, string memory val, SvgText.Font memory font) public view returns (SvgEmoticonBuilder.Emoticon memory) {
    Color.Palette memory palette = LogoType.getPalette(seed);
    return getEmoticon(tokenId, seed, val, font, palette);
  }

  function initText(uint256 tokenId, uint256 seed, string memory val, SvgText.Font memory font) public view returns (SvgText.Text memory) {
    Color.Palette memory palette = LogoType.getPalette(seed);
    string memory textType = LogoType.getTextType(seed);
    return getText(tokenId, seed >> 1, val, textType, font, palette);
  }

  function getBackground(uint256 tokenId, uint256 seed, Color.Palette memory palette) public view returns (SvgBackground.Background memory) {
    string memory backgroundType = LogoType.getBackgroundType(seed);
    SvgFill.Fill[] memory fills;
    string memory class = '';
    if (LogoHelper.equal(backgroundType, 'None')) {
      //
    } else if (LogoHelper.equal(backgroundType,'Box')) {
      class = getIdOrClass(tokenId, 'box-background');
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'box-background');
      fills = getFills(seed, fillClasses, 1, palette.backgroundColors, LogoType.getFillTypeAlt(seed));
    } else if (LogoHelper.equal(backgroundType, 'Pattern A') 
                || LogoHelper.equal(backgroundType, 'Pattern B')) {
      class = getIdOrClass(tokenId, 'pattern-background');
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'pattern-background');
      fills = getFills(seed, fillClasses, 1, palette.backgroundColors, '');
    } else if (LogoHelper.equal(backgroundType, 'Pattern AX2') 
                || LogoHelper.equal(backgroundType, 'Pattern BX2') 
                  || LogoHelper.equal(backgroundType, 'Pattern AB')) {
      class = getIdOrClass(tokenId, 'pattern-background');
      string[] memory fillClasses = new string[](2);
      fillClasses[0] = getIdOrClass(tokenId, 'pattern-background-1');
      fillClasses[1] = getIdOrClass(tokenId, 'pattern-background-2');
      fills = getFills(seed, fillClasses, 2, palette.backgroundColors, '');
    } else if (LogoHelper.equal(backgroundType, 'GM')) {
      class = getIdOrClass(tokenId, 'pattern-background');
      string[] memory fillClasses = new string[](5);
      fillClasses[0] = getIdOrClass(tokenId, 'pattern-background-1-1');
      fillClasses[1] = getIdOrClass(tokenId, 'pattern-background-1-2');

      fillClasses[2] = getIdOrClass(tokenId, 'pattern-background-2-1');
      fillClasses[3] = getIdOrClass(tokenId, 'pattern-background-2-2');

      fillClasses[4] = getIdOrClass(tokenId, 'pattern-background-3');
      fills = getFills(seed, fillClasses, 5, palette.backgroundColors, '');
    }
    SvgFilter.Filter memory filter = getFilter(tokenId, seed >> 10);
    return SvgBackground.Background(getIdOrClass(tokenId, 'background'), class, backgroundType, palette.name, 0, 0, fills, filter);
  }

  function getEmoticon(uint256 tokenId, uint256 seed, string memory txtVal, SvgText.Font memory font, Color.Palette memory palette) public view returns (SvgEmoticonBuilder.Emoticon memory) {
    SvgFill.Fill[] memory fills;
    string memory class = getIdOrClass(tokenId, 'emoticon');
    string memory emoticonType = LogoType.getEmoticonType(seed);
    SvgText.Text memory text = getText(tokenId, seed, txtVal, emoticonType, font, palette);
    if (LogoHelper.equal(emoticonType, 'Text')) {
      fills = new SvgFill.Fill[](0);
    } else {
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'emoticon');
      fills = getFills(seed >> 1, fillClasses, 1, palette.emoticonColors, 'Solid');
    }
    return SvgEmoticonBuilder.Emoticon(getIdOrClass(tokenId, 'emoticon'), class, emoticonType, text, palette.name, fills, true);
  }

  function getText(uint256 tokenId, uint256 seed, string memory val, string memory textType, SvgText.Font memory font, Color.Palette memory palette) public pure returns (SvgText.Text memory) {
    SvgFill.Fill[] memory fills;
    string memory class;
    uint256 size;

    if (LogoHelper.equal(textType, 'Mailbox') 
          || LogoHelper.equal(textType, 'Warped Mailbox')) {
      uint256 iSize = 300 / (bytes(val).length - 1);
      iSize = iSize <= 80 ? iSize : 80;
      size = iSize;
      string[] memory fillClasses = new string[](4);
      fillClasses[0] = getIdOrClass(tokenId, 'text-1');
      fillClasses[1] = getIdOrClass(tokenId, 'text-2');
      fillClasses[2] = getIdOrClass(tokenId, 'text-3');
      fillClasses[3] = getIdOrClass(tokenId, 'text-4');
      fills = getFills(seed, fillClasses, 4, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'text');
    } else if (LogoHelper.equal(textType, 'The Flippening')
                  || LogoHelper.equal(textType, 'Probably Nothing')) {
      uint256 iSize = 150 / (bytes(val).length - 1);
      iSize = iSize <= 12 ? iSize : 12;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'emoticon-text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'emoticon-text');
    } else if (LogoHelper.equal(textType, 'Rug Pull')) {
      uint256 iSize = 300 / (bytes(val).length - 1);
      iSize = iSize <= 80 ? iSize : 80;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'text');
    } else if (LogoHelper.equal(textType, 'Fren')) {
      uint256 iSize = 150 / (bytes(val).length - 1);
      iSize = iSize <= 12 ? iSize : 12;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'emoticon-text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'emoticon-text');
    } else if (LogoHelper.equal(textType, 'NGMI')) {
      uint256 iSize = 300 / (bytes(val).length - 1);
      iSize = iSize <= 80 ? iSize : 80;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'text');
    } else if (LogoHelper.equal(textType, 'Plain')) {
      uint256 iSize = 300 / (bytes(val).length - 1);
      iSize = iSize <= 80 ? iSize : 80;
      size = iSize;
      string[] memory fillClasses = new string[](1);
      fillClasses[0] = getIdOrClass(tokenId, 'text');
      fills = getFills(seed, fillClasses, 1, palette.textColors, 'Solid');
      class = getIdOrClass(tokenId, 'text');
    }
    return SvgText.Text(class, class, val, textType, font, size, palette.name, fills, LogoType.getAnimationType(seed));
  }

  function getFills(uint256 seed, string[] memory classes, uint num, string[] memory palette, string memory fillTypeOverride) public pure returns (SvgFill.Fill[] memory) {
    SvgFill.Fill[] memory fills = new SvgFill.Fill[](num);
    for (uint i=0; i < num; i++) {
      string memory fillType = LogoHelper.equal(fillTypeOverride, '') ? LogoType.getFillType(seed >> i) : fillTypeOverride;
      string[] memory colors;
      if (LogoHelper.equal(fillType, 'Solid')) {
        colors = new string[](1);
        colors[0] = LogoType.getFillColor(seed >> i * 8, palette);
      } else if (LogoHelper.equal(fillType, 'Linear Gradient')
                  || LogoHelper.equal(fillType, 'Radial Gradient')
                      || LogoHelper.equal(fillType, 'Blocked Linear Gradient')
                        || LogoHelper.equal(fillType, 'Blocked Radial Gradient')) {
        colors = new string[](5);
        colors[0] = LogoType.getFillColor(seed >> (i * 5) + 1, palette);
        colors[1] = LogoType.getFillColor(seed >> (i * 5) + 2, palette);
        colors[2] = LogoType.getFillColor(seed >> (i * 5) + 3, palette);
        colors[3] = LogoType.getFillColor(seed >> (i * 5) + 4, palette);
        colors[4] = LogoType.getFillColor(seed >> (i * 5) + 5, palette);
      }
      string memory fillId = string(abi.encodePacked(classes[i], '-fill'));
      fills[i] = SvgFill.Fill(fillId, classes[i], fillType, colors, LogoType.getAnimationType(seed >> (i * 5) + 6));
    }
    return fills;
  }

  function getFilter(uint256 tokenId, uint256 seed) public pure returns (SvgFilter.Filter memory) {
    string memory filterType = LogoType.getFilterType(seed);
    bool animate = LogoType.getAnimationType(seed >> 1);
    return SvgFilter.Filter(getIdOrClass(tokenId, 'filter'), filterType, '50', animate);
  }

  function getIdOrClass(uint256 tokenId, string memory name) public pure returns (string memory) {
    return string(abi.encodePacked('tid', LogoHelper.toString(tokenId), '-', name));
  }
}

//	SPDX-License-Identifier: MIT
/// @notice Helper to pick the logo types based on seed
pragma solidity ^0.8.0;

import './Color.sol';

library LogoType {
  function getPalette(uint256 seed) public pure returns (Color.Palette memory) {
    Color.Palette[] memory palettes = Color.getPalettes();
    return palettes[seed % palettes.length];
  }

  function getBackgroundType(uint256 seed) public pure returns (string memory) {
    string[7] memory backgroundTypes = ['Box', 'Pattern A', 'Pattern B', 'Pattern AX2', 'Pattern BX2', 'Pattern AB', 'GM'];
    uint256 index = random(seed) % 100;
    uint8[7] memory distribution = [8, 26, 39, 52, 65, 78, 100];
    for (uint8 i = 0; i < backgroundTypes.length; i++) {
      if (index < distribution[i]) {
        return backgroundTypes[i];
      }
    }
    return backgroundTypes[6];
  }

  function getEmoticonType(uint256 seed) public pure returns (string memory) {
    string[3] memory emoticonTypes = ['The Flippening', 'Probably Nothing', 'Fren'];
    return emoticonTypes[seed % emoticonTypes.length];
  }

  function getTextType(uint256 seed) public pure returns (string memory) {
    string[5] memory textTypes = ['Plain', 'Rug Pull', 'Mailbox', 'Warped Mailbox', 'NGMI'];
    uint256 index = random(seed) % 1000;
    uint16[5] memory distribution = [250, 350, 550, 750, 1000];
    for (uint8 i = 0; i < textTypes.length; i++) {
      if (index < distribution[i]) {
        return textTypes[i];
      }
    }
    return textTypes[0];
  }
  function getFillType(uint256 seed) public pure returns (string memory) {
    string[5] memory fillTypes = ['Solid', 'Linear Gradient', 'Radial Gradient', 'Blocked Linear Gradient', 'Blocked Radial Gradient'];
    return fillTypes[seed % fillTypes.length];
  }

  function getFillTypeAlt(uint256 seed) public pure returns (string memory) {
    string[4] memory fillTypes = ['Linear Gradient', 'Radial Gradient', 'Blocked Linear Gradient', 'Blocked Radial Gradient'];
    return fillTypes[seed % fillTypes.length];
  }

  function getFillColor(uint256 seed, string[] memory palette) public pure returns (string memory) {
    return palette[seed % palette.length];
  }

  function getFilterType(uint256 seed) public pure returns (string memory) {
    string[2] memory filterTypes = ['None', 'A'];
    return filterTypes[seed % filterTypes.length];
  }

  function getAnimationType(uint256 seed) public pure returns (bool) {
    bool[2] memory animationTypes = [true, false];
    return animationTypes[seed % animationTypes.length];
  }

  function random(uint256 input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
  
  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './SvgEmoticon.sol';
import '../text/SvgText.sol';
import '../common/SvgFill.sol';
import '../common/SvgElement.sol';
import '../common/LogoHelper.sol';

library SvgEmoticonBuilder {

  struct Emoticon {
    string id;
    string class;
    string emoticonType;
    SvgText.Text text;
    string paletteName;
    SvgFill.Fill[] fills;
    bool animate;
  }

  function getSvgDefs(string memory seed, Emoticon memory emoticon) public pure returns (string memory) {
    string memory defs = '';

    for (uint i=0; i < emoticon.fills.length; i++) {
      defs = string(abi.encodePacked(defs, SvgFill.getFillDefs(seed, emoticon.fills[i])));
    }

    defs = string(abi.encodePacked(defs, SvgText.getSvgDefs(seed, emoticon.text)));
    return defs;
  }

  function getSvgStyles(Emoticon memory emoticon) public pure returns (string memory) {
    string memory styles = '';

    styles = string(abi.encodePacked(styles, SvgText.getSvgStyles(emoticon.text)));

    for (uint i=0; i < emoticon.fills.length; i++) {
      styles = string(abi.encodePacked(styles, SvgFill.getFillStyles(emoticon.fills[i])));
    }

    if (LogoHelper.equal(emoticon.emoticonType, 'The Flippening')) {
      styles = string(abi.encodePacked(styles, string(abi.encodePacked('.', emoticon.class, ' { font-size: 28px; font-family: Helvetica } '))));
    } else if (LogoHelper.equal(emoticon.emoticonType, 'Probably Nothing')) {
      styles = string(abi.encodePacked(styles, string(abi.encodePacked('.', emoticon.class, ' { font-size: 48px; font-family: Helvetica } '))));
    } else if (LogoHelper.equal(emoticon.emoticonType, 'Fren')) {
      styles = string(abi.encodePacked(styles, string(abi.encodePacked('.', emoticon.class, ' { font-size: 112px; font-family: Helvetica } '))));
    } 
    return styles;
  }

  function getSvgContent(Emoticon memory emoticon) public pure returns (string memory) {
    string memory content;
    if (LogoHelper.equal(emoticon.emoticonType, 'The Flippening')) {
      content = SvgEmoticon.getTheFlippeningContent(emoticon.text.animate, emoticon.class, emoticon.text.class, emoticon.text.val);
    } else if (LogoHelper.equal(emoticon.emoticonType, 'Probably Nothing')) {
      content = SvgEmoticon.getProbablyNothingContent(emoticon.animate, emoticon.class, emoticon.text.class, emoticon.text.val);
    } else if (LogoHelper.equal(emoticon.emoticonType, 'Fren')) {
      content = SvgEmoticon.getFrenContent(emoticon.animate, emoticon.class, emoticon.text.class, emoticon.text.val);
    }
    return content;
  }
}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../common/SvgFill.sol';
import '../common/SvgFilter.sol';
import '../common/SvgElement.sol';
import '../common/LogoHelper.sol';
import './SvgPattern.sol';

library SvgBackground {

  struct Background {
    string id;
    string class;
    string backgroundType;
    string paletteName;
    uint16 width;
    uint16 height;
    SvgFill.Fill[] fills;
    SvgFilter.Filter filter;
  }

  function getSvgDefs(string memory seed, Background memory background) public pure returns (string memory) {
    string memory defs = '';
    // Fill defs
    for (uint i=0; i < background.fills.length; i++) {
      defs = string(abi.encodePacked(defs, SvgFill.getFillDefs(seed, background.fills[i])));
    }

    // Filter defs
    if (LogoHelper.equal(background.filter.filterType, 'A')) {
      defs = string(abi.encodePacked(defs, SvgFilter.getFilterDef(string(abi.encodePacked(seed, 'a')), background.filter)));
      if (LogoHelper.equal(background.backgroundType, 'GM')) {
        string memory originalId = background.filter.id;
        background.filter.id = string(abi.encodePacked(background.filter.id, '-2'));
        defs = string(abi.encodePacked(defs, SvgFilter.getFilterDef(string(abi.encodePacked(seed, 'b')), background.filter)));
        background.filter.id = originalId;
      }
    }

    // Pattern defs
    if (LogoHelper.equal(background.backgroundType, 'Pattern A')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getADef(seed, background.id, background.fills[0].fillType, background.fills[0].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern B')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getBDef(seed, background.id, background.fills[0].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern AX2')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getAX2Def(seed, background.id, background.fills[0].class, background.fills[0].fillType, background.fills[1].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern BX2')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getBX2Def(seed, background.id, background.fills[0].class, background.fills[1].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern AB')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getABDef(seed, background.id, background.fills[0].fillType, background.fills[0].class, background.fills[1].class)));
    } else if (LogoHelper.equal(background.backgroundType, 'GM')) { 
      defs = string(abi.encodePacked(defs, SvgPattern.getGMDef(seed, background.id, background.fills[0].class, background.fills[1].class, background.fills[2].class, background.fills[3].class)));
    }
    return defs;
  }

  function getSvgStyles(Background memory background) public pure returns (string memory) {
    string memory styles = '';
    for (uint i=0; i < background.fills.length; i++) {
      styles = string(abi.encodePacked(styles, SvgFill.getFillStyles(background.fills[i])));
    }
    return styles;
  }

  function getSvgContent(Background memory background) public pure returns (string memory) {
    if (LogoHelper.equal(background.backgroundType, 'Box')) {
      return SvgElement.getRect(SvgElement.Rect(background.class, '0', '0', '100%', '100%', '', '', ''));
    } else if (LogoHelper.equal(background.backgroundType, 'Pattern A')
                || LogoHelper.equal(background.backgroundType, 'Pattern AX2')
                  || LogoHelper.equal(background.backgroundType, 'Pattern B')
                    || LogoHelper.equal(background.backgroundType, 'Pattern BX2')
                      || LogoHelper.equal(background.backgroundType, 'Pattern AB')) {
      if (LogoHelper.equal(background.filter.filterType, 'None')) {
        return SvgElement.getRect(SvgElement.Rect('', '0', '0', '100%', '100%', '', background.id, ''));
      } else {
        return SvgElement.getRect(SvgElement.Rect('', '0', '0', '100%', '100%', '', background.id, background.filter.id));
      }
    } else if (LogoHelper.equal(background.backgroundType, 'GM')) {
      string memory backgroundId1 = string(abi.encodePacked(background.id, '-1'));
      string memory backgroundId2 = string(abi.encodePacked(background.id, '-2'));
      string memory content = '';
      if (LogoHelper.equal(background.filter.filterType, 'None')) {
        content = SvgElement.getRect(SvgElement.Rect('', '0', '0', '100%', '70%', '0.8', backgroundId1, ''));
        content = string(abi.encodePacked(content, SvgElement.getCircle(SvgElement.Circle(background.fills[4].class, '80%', '50%', '15%', ''))));
        content = string(abi.encodePacked(content, SvgElement.getRect(SvgElement.Rect('', '0', '60%', '100%', '70%', '', backgroundId2, ''))));
        return content;
      } else {
        content = SvgElement.getRect(SvgElement.Rect('', '0', '0', '100%', '100%', '0.8', backgroundId1, background.filter.id));
        content = string(abi.encodePacked(content, SvgElement.getCircle(SvgElement.Circle(background.fills[4].class, '80%', '50%', '15%', ''))));
        content = string(abi.encodePacked(content, SvgElement.getRect(SvgElement.Rect('', '0', '60%', '100%', '70%', '', backgroundId2, string(abi.encodePacked(background.filter.id, '-2'))))));
        return content;
      }
    }
  }
}

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

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Color {
  
  struct Palette {
    string name;
    string[] backgroundColors;
    string[] emoticonColors;
    string[] textColors;
  }

  function getPalettes() public pure returns (Palette[] memory) {
    Palette[] memory palettes = new Palette[](9);
    palettes[0] = getPalette1();
    palettes[1] = getPalette2();
    palettes[2] = getPalette3();
    palettes[3] = getPalette4();
    palettes[4] = getPalette5();
    palettes[5] = getPalette6();
    palettes[6] = getPalette7();
    palettes[7] = getPalette8();
    palettes[8] = getPalette9();
    return palettes;
  }

  function getPalette1() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#D9D161';
    backgroundColors[1] = '#FFC9ED';
    backgroundColors[2] = '#C9CAF7';
    backgroundColors[3] = '#F2FA7F';
    backgroundColors[4] = '#53B7F0';

    string[] memory textColors = new string[](5);
    textColors[0] = '#AFA1C7';
    textColors[1] = '#644A91';
    textColors[2] = '#6C637A';
    textColors[3] = '#CCB9ED';
    textColors[4] = '#3F3A47';

    return Palette('1', backgroundColors, textColors, textColors);
  }

  function getPalette2() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#C25F4A';
    backgroundColors[1] = '#F5DDD7';
    backgroundColors[2] = '#8F4561';
    backgroundColors[3] = '#7D9C72';
    backgroundColors[4] = '#94C24A';

    string[] memory textColors = new string[](5);
    textColors[0] = '#3E7F8C';
    textColors[1] = '#425559';
    textColors[2] = '#1C3A40';
    textColors[3] = '#68868C';
    textColors[4] = '#998971';

    return Palette('2', backgroundColors, textColors, textColors);
  }

  function getPalette3() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#885FBD';
    backgroundColors[1] = '#80788D';
    backgroundColors[2] = '#495AF0';
    backgroundColors[3] = '#F5F1DF';
    backgroundColors[4] = '#BD955C';

    string[] memory textColors = new string[](5);
    textColors[0] = '#3E3D54';
    textColors[1] = '#716BDB';
    textColors[2] = '#9D9BD4';
    textColors[3] = '#312E5E';
    textColors[4] = '#7775A1';

    return Palette('3', backgroundColors, textColors, textColors);
  }

  function getPalette4() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#568F82';
    backgroundColors[1] = '#79DBC5';
    backgroundColors[2] = '#DBB36E';
    backgroundColors[3] = '#59478F';
    backgroundColors[4] = '#8163DB';

    string[] memory textColors = new string[](5);
    textColors[0] = '#5C441E';
    textColors[1] = '#E1C18E';
    textColors[2] = '#FFBE54';
    textColors[3] = '#574C3A';
    textColors[4] = '#A87D03';

    return Palette('4', backgroundColors, textColors, textColors);
  }

  function getPalette5() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#D9A561';
    backgroundColors[1] = '#FFEFED';
    backgroundColors[2] = '#FACAF7';
    backgroundColors[3] = '#CBED2E';
    backgroundColors[4] = '#78C7AC';

    string[] memory textColors = new string[](5);
    textColors[0] = '#B8A561';
    textColors[1] = '#856F1E';
    textColors[2] = '#C21D3E';
    textColors[3] = '#D1EAED';
    textColors[4] = '#769C96';

    return Palette('5', backgroundColors, textColors, textColors);
  }

  function getPalette6() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#D9D161';
    backgroundColors[1] = '#FFC9ED';
    backgroundColors[2] = '#C9CAF7';
    backgroundColors[3] = '#F2FA7F';
    backgroundColors[4] = '#53B7F0';

    string[] memory textColors = new string[](5);
    textColors[0] = '#AFA1C7';
    textColors[1] = '#644A91';
    textColors[2] = '#6C637A';
    textColors[3] = '#CCB9ED';
    textColors[4] = '#3F3A47';

    return Palette('6', backgroundColors, textColors, textColors);
  }

  function getPalette7() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#F5E564';
    backgroundColors[1] = '#F5C971';
    backgroundColors[2] = '#F5595B';
    backgroundColors[3] = '#D0C6F5';
    backgroundColors[4] = '#95BAF5';

    string[] memory textColors = new string[](5);
    textColors[0] = '#FFEE00';
    textColors[1] = '#F5A318';
    textColors[2] = '#F50008';
    textColors[3] = '#4B00F5';
    textColors[4] = '#1685F5';

    return Palette('7', backgroundColors, textColors, textColors);
  }

  function getPalette8() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#FDAD0E';
    backgroundColors[1] = '#F4671F';
    backgroundColors[2] = '#D60441';
    backgroundColors[3] = '#84265E';
    backgroundColors[4] = '#247D75';

    string[] memory textColors = new string[](5);
    textColors[0] = '#FFF6E1';
    textColors[1] = '#A01356';
    textColors[2] = '#4F516A';
    textColors[3] = '#F25322';
    textColors[4] = '#5B3486';

    return Palette('8', backgroundColors, textColors, textColors);
  }

  function getPalette9() public pure returns (Palette memory) {
    string[] memory backgroundColors = new string[](5);
    backgroundColors[0] = '#5E4D3D';
    backgroundColors[1] = '#FFFFE9';
    backgroundColors[2] = '#C1C9C3';
    backgroundColors[3] = '#F4F3F0';
    backgroundColors[4] = '#CFC9A5';

    string[] memory textColors = new string[](5);
    textColors[0] = '#85A383';
    textColors[1] = '#CCCCBA';
    textColors[2] = '#A6ADA8';
    textColors[3] = '#4A4A48';
    textColors[4] = '#D1D0CD';

    return Palette('9', backgroundColors, textColors, textColors);
  }
}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../common/SvgElement.sol';

library SvgEmoticon {
  function getTheFlippeningContent(bool animate, string memory emoticonClass, string memory textClass, string memory text) public pure returns (string memory) {
    string memory animate = SvgElement.getAnimate(SvgElement.Animate('rotate', '', '0;20;0', '500', '0', '1', 'freeze'));
    string memory element = string(abi.encodePacked('\xE2\x95\xAF', animate, ''));

    string memory content = SvgElement.getTspan(SvgElement.Tspan(emoticonClass, '', '', '', element));

    content = string(abi.encodePacked(content, '\xC2\xB0\xE2\x96\xA1\xC2\xB0\xEF\xBC\x89', ''));
    element = string(abi.encodePacked('\xE2\x95\xAF', animate));

    content = string(abi.encodePacked(content, SvgElement.getTspan(SvgElement.Tspan(emoticonClass, '', '', '', element)), ''));

    element = string(abi.encodePacked('(', content, ''));

    content = SvgElement.getText(SvgElement.Text(emoticonClass, '20', '50%', '', '', '', 'central', 'start', '', '', '', element));
    
    animate = '<animateTransform attributeName="transform" attributeType="XML" type="rotate" from="0 160 110" to="180 220 150" begin="250ms" dur="500ms" repeatCount="1" fill="freeze"/>';
    element = SvgElement.getTspan(SvgElement.Tspan(textClass, '', '', '', text));
    element = string(abi.encodePacked(element, 'T', animate));
    element = string(abi.encodePacked('T', element));

    element = SvgElement.getText(SvgElement.Text(emoticonClass, '160', '140', '', '', '', 'hanging', 'start', '', '', '', element));
    return string(abi.encodePacked(content, element)); 
  }

  function getProbablyNothingContent(bool animate, string memory emoticonClass, string memory textClass, string memory text) public pure returns (string memory) {
    string memory element = SvgElement.getTspan(SvgElement.Tspan(textClass, '', '2', '-18', text));
    element = string(abi.encodePacked('\xC2\xAF\x5C\x5F\x28\xE3\x83\x84\x29\x5F\x2F', element));
    element = string(abi.encodePacked(element, '<animate attributeName="dy" values="0;-2,0,0,2,0,0,-2;0;-2,0,0,2,0,0,-2;0" dur="2s" repeatCount="1"/>'));
    return SvgElement.getText(SvgElement.Text(emoticonClass, '10%', '50%', '', '', '', 'central', 'start', '', '', '', element));
  }

  function getFrenContent(bool animate, string memory emoticonClass, string memory textClass, string memory text) public pure returns (string memory) {
    string memory element = SvgElement.getTspan(SvgElement.Tspan(textClass, '', '1', '', text));
    element = string(abi.encodePacked('(^', element, '^)'));

    bytes memory byteString = bytes(text);
    string memory dy = '0,-2,2,';
    for (uint i = 1; i < byteString.length; i++) {
      dy = string(abi.encodePacked(dy, '0,'));
    }
    dy = string(abi.encodePacked('0;', dy, '-2,2;', '0;'));
    element = string(abi.encodePacked(element, SvgElement.getAnimate(SvgElement.Animate('dy', '', dy, '1500', '500', '1', ''))));
    return SvgElement.getText(SvgElement.Text(emoticonClass, '50%', '50%', '', '', '', 'central', 'middle', '', '', '', element));
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

import './SvgElement.sol';
import './LogoHelper.sol';

library SvgFilter {

  struct Filter {
    string id;
    string filterType;
    string scale;
    bool animate;
  }

  function getFilterDef(string memory seed, Filter memory filter) public pure returns (string memory) {
    string memory defs = '';
    string memory turbulance;
    string memory animateTurbulance;
    if (LogoHelper.equal(filter.scale, '50')) {
      turbulance = LogoHelper.getTurbulance(seed, 10000, 100000);
      if (filter.animate) {
        animateTurbulance = string(abi.encodePacked(turbulance, '; ', LogoHelper.getTurbulance(filter.id, 10000, 100000), '; ', turbulance, '; '));
      }
    }

    if (filter.animate) {
      string memory element = SvgElement.getAnimate(SvgElement.Animate('baseFrequency', '', animateTurbulance, LogoHelper.toString(LogoHelper.randomInRange(seed, 100000, 100)), '0', 'indefinite', ''));
      element = SvgElement.getTurbulance(SvgElement.Turbulance('fractalNoise', turbulance, '5', 'r1', element));
      element = string(abi.encodePacked(element, SvgElement.getDisplacementMap(SvgElement.DisplacementMap('SourceGraphic', 'r1', 'r2', filter.scale, 'R', 'G', ''))));
      defs = string(abi.encodePacked(defs, SvgElement.getFilter(SvgElement.Filter(filter.id, element))));
    } else {
      string memory element = SvgElement.getTurbulance(SvgElement.Turbulance('fractalNoise', turbulance, '5', 'r1', ''));
      element = string(abi.encodePacked(element, SvgElement.getDisplacementMap(SvgElement.DisplacementMap('SourceGraphic', 'r1', 'r2', filter.scale, 'R', 'G', ''))));
      defs = string(abi.encodePacked(defs, SvgElement.getFilter(SvgElement.Filter(filter.id, element))));
    }
    return defs;
  }

}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../common/SvgElement.sol';
import '../common/LogoHelper.sol';
import '../common/InlineSvgElement.sol';

library SvgPattern {
  function getADef(string memory seed, string memory backgroundId, string memory fillType, string memory fillZeroClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 140, 10);
    // pattern should end in frame
    for (uint i = 0; i < 150; i++) {
      if (300 % (patternSize + i) == 0) {
        patternSize = patternSize + i;
        break;
      } 
    }
    uint squareSize = randomInRange(string(abi.encodePacked(seed, 'b')), LogoHelper.equal(fillType, 'Solid') ? patternSize - (patternSize / 6) : patternSize + (patternSize / 2), patternSize / 6);
    string memory element = SvgElement.getRect(SvgElement.Rect(fillZeroClass, '0', '0', LogoHelper.toString(squareSize), LogoHelper.toString(squareSize), '', '', ''));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }

  function getBDef(string memory seed, string memory backgroundId, string memory fillZeroClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 200, 10);
    for (uint i = 0; i < 150; i++) {
      if (300 % (patternSize + i) == 0) {
        patternSize = patternSize + i;
        break;
      }  
    }
    uint circleRadius = randomInRange(string(abi.encodePacked(seed, 'b')), patternSize - (patternSize / 4), patternSize / 12);
    string memory center = LogoHelper.toString(randomInRange(string(abi.encodePacked(seed, 'c')), patternSize, patternSize / 4));
    string memory element = SvgElement.getCircle(SvgElement.Circle(fillZeroClass, center, center, LogoHelper.toString(circleRadius), ''));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }
  
  function getAX2Def(string memory seed, string memory backgroundId, string memory fillZeroClass, string memory fillType, string memory fillOneClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 200, 2);
    for (uint i = 0; i < 150; i++) {
      if (300 % (patternSize + i) == 0) {
        patternSize = patternSize + i;
        break;
      } 
    }
    uint squareSize1 = randomInRange(string(abi.encodePacked(seed, 'b')), LogoHelper.equal(fillType, 'Solid') ? patternSize : patternSize + (patternSize / 2), patternSize / 6);
    uint squareSize2 = randomInRange(string(abi.encodePacked(seed, 'c')), LogoHelper.equal(fillType, 'Solid') ? patternSize : patternSize + (patternSize / 2), patternSize / 6);

    uint offset = randomInRange(string(abi.encodePacked(seed, 'd')), patternSize - (squareSize2 / 2) , 0);
    string memory opactiy = LogoHelper.decimalInRange(seed, 8, 10);
    string memory element = SvgElement.getRect(SvgElement.Rect(fillZeroClass, '0', '0', LogoHelper.toString(squareSize1), LogoHelper.toString(squareSize1), '', '', ''));
    element = string(abi.encodePacked(element, SvgElement.getRect(SvgElement.Rect(fillOneClass, LogoHelper.toString(offset), LogoHelper.toString(offset), LogoHelper.toString(squareSize2), LogoHelper.toString(squareSize2), opactiy, '', ''))));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }

  function getBX2Def(string memory seed, string memory backgroundId, string memory fillZeroClass, string memory fillOneClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 200, 20);
    for (uint i = 0; i < 150; i++) {
      if (300 % (patternSize + i) == 0) {
        patternSize = patternSize + i;
        break;
      } 
    }
    uint circleRadius = randomInRange(string(abi.encodePacked(seed, 'b')), patternSize - (patternSize / 4), patternSize / 6);

    string memory center = LogoHelper.toString(randomInRange(string(abi.encodePacked(seed, 'c')), patternSize, patternSize / 4));
    string memory element = SvgElement.getCircle(SvgElement.Circle(fillZeroClass, center, center, LogoHelper.toString(circleRadius), ''));

    circleRadius = randomInRange(string(abi.encodePacked(seed, 'e')), patternSize, patternSize / 6);
    center = LogoHelper.toString(randomInRange(string(abi.encodePacked(seed, 'f')), patternSize, patternSize / 4));
    string memory opactiy = LogoHelper.decimalInRange(seed, 8, 10);
    element = string(abi.encodePacked(element, SvgElement.getCircle(SvgElement.Circle(fillOneClass, center, center, LogoHelper.toString(circleRadius), opactiy))));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }

  function getABDef(string memory seed, string memory backgroundId, string memory fillType, string memory fillZeroClass, string memory fillOneClass) public pure returns (string memory) {
    uint patternSize = randomInRange(string(abi.encodePacked(seed, 'a')), 200, 20);
    for (uint i = 0; i < 150; i++) {
      if ((patternSize + i) % 300 == 0) {
        patternSize = patternSize + i;
        break;
      } 
    }
    uint squareSize1 = randomInRange(string(abi.encodePacked(seed, 'b')), LogoHelper.equal(fillType, 'Solid') ? patternSize : patternSize + (patternSize / 2), patternSize / 6);
    string memory element = SvgElement.getRect(SvgElement.Rect(fillZeroClass, '0', '0', LogoHelper.toString(squareSize1), LogoHelper.toString(squareSize1), '', '', ''));

    uint circleRadius = randomInRange(string(abi.encodePacked(seed, 'b')), patternSize - (patternSize / 4), patternSize / 6);
    string memory center = LogoHelper.toString(randomInRange(string(abi.encodePacked(seed, 'c')), patternSize, patternSize / 4));
    element = string(abi.encodePacked(element, SvgElement.getCircle(SvgElement.Circle(fillOneClass, center, center, LogoHelper.toString(circleRadius), ''))));
    return SvgElement.getPattern(SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSize), LogoHelper.toString(patternSize), 'userSpaceOnUse', element));
  }

  function getGMDef(string memory seed, string memory backgroundId, string memory fillZeroClass, string memory fillOneClass, string memory fillTwoClass, string memory fillThreeClass) public pure returns (string memory) {
    // sky
    uint patternSizeX = randomInRange(string(abi.encodePacked(seed, 'a')), 300, 6);
    uint patternSizeY = randomInRange(string(abi.encodePacked(seed, 'b')), 300, 6);
    uint squareSize2 = randomInRange(seed, patternSizeX / 2, patternSizeX / 6);

    uint offset = randomInRange(seed, patternSizeX - (squareSize2 / 2) , 0);

    string memory element = SvgElement.getRect(SvgElement.Rect(fillZeroClass, '0', '0', LogoHelper.toString(patternSizeX), LogoHelper.toString(patternSizeX), '', '', ''));
    element = string(abi.encodePacked(element, SvgElement.getRect(SvgElement.Rect(fillOneClass, LogoHelper.toString(offset), LogoHelper.toString(offset), LogoHelper.toString(squareSize2), LogoHelper.toString(squareSize2), '0.8', '', ''))));
    SvgElement.Pattern memory pattern = SvgElement.Pattern(string(abi.encodePacked(backgroundId, '-1')), '0', '0', LogoHelper.toString(patternSizeX), LogoHelper.toString(patternSizeY), 'userSpaceOnUse', element);
    string memory defs = SvgElement.getPattern(pattern);

    // ocean
    patternSizeX = 300;
    patternSizeY = randomInRange(string(abi.encodePacked(seed, 'c')), 30, 0);
    squareSize2 = randomInRange(seed, patternSizeX, patternSizeX / 4);
    offset = 230 - (squareSize2 / 2);
    backgroundId = string(abi.encodePacked(backgroundId, '-2'));

    element = SvgElement.getRect(SvgElement.Rect(fillTwoClass, '0', '0', LogoHelper.toString(patternSizeX), LogoHelper.toString(squareSize2), '', '', ''));
    // element = string(abi.encodePacked(element, SvgElement.getRect(SvgElement.Rect(fillThreeClass, LogoHelper.toString(offset), '5', LogoHelper.toString(squareSize2), '10', '0.8', '', ''))));
    element = string(abi.encodePacked(element, SvgElement.getRect(SvgElement.Rect(fillThreeClass, LogoHelper.toString(offset), LogoHelper.toString(patternSizeY), LogoHelper.toString(squareSize2), LogoHelper.toString(patternSizeY), '0.8', '', ''))));
    patternSizeY = randomInRange(string(abi.encodePacked(seed, 'd')), 100, 0);
    pattern = SvgElement.Pattern(backgroundId, '0', '0', LogoHelper.toString(patternSizeX), LogoHelper.toString(patternSizeY), 'userSpaceOnUse', element);
    return string(abi.encodePacked(defs, SvgElement.getPattern(pattern)));
  }

  function randomInRange(string memory input, uint max, uint offset) public pure returns (uint256) {
    max = max - offset;
    return (random(input) % max) + offset;
  }

  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
}

//	SPDX-License-Identifier: MIT
/// @notice A helper to create svg elements
pragma solidity ^0.8.0;


library InlineSvgElement {
  function getTspanBytes1(
      string memory class,
      string memory display, 
      string memory dx, 
      string memory dy, 
      bytes1 val)
      public pure 
      returns (string memory) {
    return string(abi.encodePacked('<tspan class="', class, '" display="', display, '" dx="', dx, '" dy="', dy, '" >', val));
  }

  function getAnimate(
      string memory attributeName,
      string memory values,
      string memory duration,
      string memory begin,
      string memory repeatCount,
      string memory fill) 
      public pure 
      returns (string memory) {
    return string(abi.encodePacked('<animate attributeName="', attributeName, '" values="', values, '" dur="', duration, 'ms" begin="', begin, 'ms" repeatCount="', repeatCount, '"  fill="', fill, '" />'));
  }
}