// SPDX-License-Identifier: MIT

/**
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import 'assetprovider.sol/IAssetProvider.sol';
import 'randomizer.sol/Randomizer.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import '../packages/graphics/Path.sol';
import '../packages/graphics/SVG.sol';
import '../packages/graphics/Text.sol';
import '../packages/graphics/IFontProvider.sol';

contract PNounsPrivider is IAssetProviderEx, Ownable, IERC165 {
  using Strings for uint256;
  using Randomizer for Randomizer.Seed;
  using Vector for Vector.Struct;
  using Path for uint[];
  using SVG for SVG.Element;
  using TX for string;
  using Trigonometry for uint;

  IFontProvider public immutable font;
  IAssetProvider public immutable nounsProvider;

  constructor(IFontProvider _font, IAssetProvider _nounsProvider) {
    font = _font;
    nounsProvider = _nounsProvider;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(IAssetProvider).interfaceId ||
      interfaceId == type(IAssetProviderEx).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  function getOwner() external view override returns (address) {
    return owner();
  }

  function getProviderInfo() external view override returns (ProviderInfo memory) {
    return ProviderInfo('pnouns', 'pNouns', this);
  }

  function totalSupply() external pure override returns (uint256) {
    return 0;
  }

  function processPayout(uint256 _assetId) external payable override {
    address payable payableTo = payable(owner());
    payableTo.transfer(msg.value);
    emit Payout('pnouns', _assetId, payableTo, msg.value);
  }

  function generateTraits(uint256 _assetId) external pure override returns (string memory traits) {
    // nothing to return
  }

  // Hack to deal with too many stack variables
  struct Stackframe {
    uint trait; // 0:small, 1:middle, 2:large
    uint degree;
    uint distance;
    uint radius;
    uint rotate;
    int x;
    int y;
  }

  function circles(uint _assetId, string[] memory idNouns) internal pure returns (SVG.Element memory) {
    string[4] memory colors = ['red', 'green', 'yellow', 'blue'];
    uint count = 10;
    SVG.Element[] memory elements = new SVG.Element[](count);
    Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);

    for (uint i = 0; i < count; i++) {
      Stackframe memory stack;
      stack.trait = (i + 1) / 4; // 3:4:3
      if (stack.trait == 0) {
        (seed, stack.distance) = seed.random(100);
        stack.distance += 380;
        (seed, stack.radius) = seed.random(40);
        stack.radius += 40;
        (seed, stack.rotate) = seed.random(360);
      } else if (stack.trait == 1) {
        (seed, stack.distance) = seed.random(100);
        stack.distance += 200;
        (seed, stack.radius) = seed.random(70);
        stack.radius += 70;
        (seed, stack.rotate) = seed.random(240);
        stack.rotate += 240;
      } else {
        (seed, stack.distance) = seed.random(180);
        (seed, stack.radius) = seed.random(70);
        stack.radius += 180;
        (seed, stack.rotate) = seed.random(120);
        stack.rotate += 300;
      }
      (seed, stack.degree) = seed.random(0x4000);
      stack.x = 512 + (stack.degree.cos() * int(stack.distance)) / Vector.ONE;
      stack.y = 512 + (stack.degree.sin() * int(stack.distance)) / Vector.ONE;
      elements[i] = SVG.group(
        [
          SVG.use(idNouns[i % idNouns.length]).transform(
            TX
              .translate(stack.x - int(stack.radius), stack.y - int(stack.radius))
              .scale1000((1000 * stack.radius) / 512)
              .rotate(string(abi.encodePacked(stack.rotate.toString(), ',512,512')))
          ),
          SVG.circle(stack.x, stack.y, int(stack.radius + stack.radius / 10)).fill(colors[i % 4]).opacity('0.333')
        ]
      );
    }
    return SVG.group(elements);
  }

  struct StackFrame2 {
    uint width;
    SVG.Element pnouns;
    string[] idNouns;
    SVG.Element[] svgNouns;
    string svg;
    string seriesText;
    SVG.Element series;
  }

  function generateSVGPart(uint256 _assetId) public view override returns (string memory svgPart, string memory tag) {
    StackFrame2 memory stack;
    tag = string(abi.encodePacked('circles', _assetId.toString()));
    stack.width = SVG.textWidth(font, 'pNouns');
    stack.pnouns = SVG.text(font, 'pNouns').fill('#224455').transform(TX.scale1000((1000 * 1024) / stack.width));

    if (_assetId < 10) {
      stack.seriesText = string(abi.encodePacked('000', _assetId.toString(), '/2000'));
    } else if (_assetId < 100) {
      stack.seriesText = string(abi.encodePacked('00', _assetId.toString(), '/2000'));
    } else if (_assetId < 1000) {
      stack.seriesText = string(abi.encodePacked('0', _assetId.toString(), '/2000'));
    } else {
      stack.seriesText = string(abi.encodePacked(_assetId.toString(), '/2000'));
    }
    stack.width = SVG.textWidth(font, stack.seriesText);
    stack.series = SVG.text(font, stack.seriesText).fill('#224455').transform(
      TX.translate(1024 - int(stack.width / 10), 1024 - 102).scale('0.1')
    );

    stack.idNouns = new string[](3);
    stack.svgNouns = new SVG.Element[](3);
    for (uint i = 0; i < stack.idNouns.length; i++) {
      (stack.svg, stack.idNouns[i]) = nounsProvider.generateSVGPart(i + _assetId);
      stack.svgNouns[i] = SVG.element(bytes(stack.svg));
    }

    svgPart = string(
      SVG
        .list(
          [
            SVG.list(stack.svgNouns),
            SVG
              .group(
                [
                  circles(_assetId, stack.idNouns).transform('translate(102,204) scale(0.8)'),
                  stack.pnouns,
                  stack.series
                ]
              )
              .id(tag)
          ]
        )
        .svg()
    );
  }

  function generateSVGDocument(uint256 _assetId) external view override returns (string memory document) {
    string memory svgPart;
    string memory tag;
    (svgPart, tag) = generateSVGPart(_assetId);
    document = SVG.document('0 0 1024 1024', bytes(svgPart), SVG.use(tag).svg());
  }
}

// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import './Vector.sol';

library Path {
  function roundedCorner(Vector.Struct memory _vector) internal pure returns (uint) {
    return uint(_vector.x / 0x8000) + (uint(_vector.y / 0x8000) << 32) + (566 << 64);
  }

  function sharpCorner(Vector.Struct memory _vector) internal pure returns (uint) {
    return uint(_vector.x / 0x8000) + (uint(_vector.y / 0x8000) << 32) + (0x1 << 80);
  }

  function closedPath(uint[] memory points) internal pure returns (bytes memory newPath) {
    uint length = points.length;
    assembly {
      function toString(_wbuf, _value) -> wbuf {
        let len := 2
        let cmd := 0
        if gt(_value, 9) {
          if gt(_value, 99) {
            if gt(_value, 999) {
              cmd := or(shl(8, cmd), add(48, div(_value, 1000)))
              len := add(1, len)
              _value := mod(_value, 1000)
            }
            cmd := or(shl(8, cmd), add(48, div(_value, 100)))
            len := add(1, len)
            _value := mod(_value, 100)
          }
          cmd := or(shl(8, cmd), add(48, div(_value, 10)))
          len := add(1, len)
          _value := mod(_value, 10)
        }
        cmd := or(or(shl(16, cmd), shl(8, add(48, _value))), 32)

        mstore(_wbuf, shl(sub(256, mul(len, 8)), cmd))
        wbuf := add(_wbuf, len)
      }

      // dynamic allocation
      newPath := mload(0x40)
      let wbuf := add(newPath, 0x20)
      let rbuf := add(points, 0x20)

      let wordP := mload(add(rbuf, mul(sub(length, 1), 0x20)))
      let word := mload(rbuf)
      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 1)
      } {
        let x := and(word, 0xffffffff)
        let y := and(shr(32, word), 0xffffffff)
        let r := and(shr(64, word), 0xffff)
        let sx := div(add(x, and(wordP, 0xffffffff)), 2)
        let sy := div(add(y, and(shr(32, wordP), 0xffffffff)), 2)
        if eq(i, 0) {
          mstore(wbuf, shl(248, 0x4D)) // M
          wbuf := add(wbuf, 1)
          wbuf := toString(wbuf, sx)
          wbuf := toString(wbuf, sy)
        }

        let wordN := mload(add(rbuf, mul(mod(add(i, 1), length), 0x20)))
        {
          let ex := div(add(x, and(wordN, 0xffffffff)), 2)
          let ey := div(add(y, and(shr(32, wordN), 0xffffffff)), 2)

          switch and(shr(80, word), 0x01)
          case 0 {
            mstore(wbuf, shl(248, 0x43)) // C
            wbuf := add(wbuf, 1)
            x := mul(x, r)
            y := mul(y, r)
            r := sub(1024, r)
            wbuf := toString(wbuf, div(add(x, mul(sx, r)), 1024))
            wbuf := toString(wbuf, div(add(y, mul(sy, r)), 1024))
            wbuf := toString(wbuf, div(add(x, mul(ex, r)), 1024))
            wbuf := toString(wbuf, div(add(y, mul(ey, r)), 1024))
          }
          default {
            mstore(wbuf, shl(248, 0x4C)) // L
            wbuf := add(wbuf, 1)
            wbuf := toString(wbuf, x)
            wbuf := toString(wbuf, y)
          }
          wbuf := toString(wbuf, ex)
          wbuf := toString(wbuf, ey)
        }
        wordP := word
        word := wordN
      }

      mstore(newPath, sub(sub(wbuf, newPath), 0x20))
      mstore(0x40, wbuf)
    }
  }

  function decode(bytes memory body) internal pure returns (bytes memory) {
    bytes memory ret;
    assembly {
      let bodyMemory := add(body, 0x20)
      let length := div(mul(mload(body), 2), 3)
      ret := mload(0x40)
      let retMemory := add(ret, 0x20)
      let data
      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 1)
      } {
        if eq(mod(i, 16), 0) {
          data := mload(bodyMemory) // reading 8 extra bytes
          bodyMemory := add(bodyMemory, 24)
        }
        let low
        let high
        switch mod(i, 2)
        case 0 {
          low := shr(248, data)
          high := and(shr(240, data), 0x0f)
        }
        default {
          low := and(shr(232, data), 0xff)
          high := and(shr(244, data), 0x0f)
          data := shl(24, data)
        }

        switch high
        case 0 {
          if or(and(gt(low, 64), lt(low, 91)), and(gt(low, 96), lt(low, 123))) {
            mstore(retMemory, shl(248, low))
            retMemory := add(retMemory, 1)
          }
        }
        default {
          let cmd := 0
          let lenCmd := 2 // last digit and space
          // SVG value: undo (value + 1024) + 0x100
          let value := sub(add(shl(8, high), low), 0x0100)
          switch lt(value, 1024)
          case 0 {
            value := sub(value, 1024)
          }
          default {
            cmd := 45 // "-"
            lenCmd := 3
            value := sub(1024, value)
          }
          if gt(value, 9) {
            if gt(value, 99) {
              if gt(value, 999) {
                cmd := or(shl(8, cmd), 49) // always "1"
                lenCmd := add(1, lenCmd)
                value := mod(value, 1000)
              }
              cmd := or(shl(8, cmd), add(48, div(value, 100)))
              lenCmd := add(1, lenCmd)
              value := mod(value, 100)
            }
            cmd := or(shl(8, cmd), add(48, div(value, 10)))
            lenCmd := add(1, lenCmd)
            value := mod(value, 10)
          }
          // last digit and space
          cmd := or(or(shl(16, cmd), shl(8, add(48, value))), 32)

          mstore(retMemory, shl(sub(256, mul(lenCmd, 8)), cmd))
          retMemory := add(retMemory, lenCmd)
        }
      }
      mstore(ret, sub(sub(retMemory, ret), 0x20))
      mstore(0x40, retMemory)
    }
    return ret;
  }
}

// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

interface IFontProvider {
  function height() external view returns (uint);

  function baseline() external view returns (uint);

  function widthOf(string memory _char) external view returns (uint);

  function pathOf(string memory _char) external view returns (bytes memory);

  /**
   * This function processes the royalty payment from the decentralized autonomous marketplace.
   */
  function processPayout() external payable;

  event Payout(string providerKey, address payable to, uint256 amount);
}

// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

library Text {
  function extractLine(
    string memory _text,
    uint _index,
    uint _ch
  ) internal pure returns (string memory line, uint index) {
    uint length = bytes(_text).length;
    assembly {
      line := mload(0x40)
      let wbuf := add(line, 0x20)
      let rbuf := add(add(_text, 0x20), _index)
      let word := 0
      let shift := 0
      let i
      for {
        i := _index
      } lt(i, length) {
        i := add(i, 1)
      } {
        if eq(shift, 0) {
          word := mload(rbuf)
          mstore(wbuf, word)
          rbuf := add(rbuf, 0x20)
          wbuf := add(wbuf, 0x20)
          shift := 256
        }
        shift := sub(shift, 8)
        if eq(and(shr(shift, word), 0xff), _ch) {
          length := i
        }
      }

      index := i
      length := sub(i, _index)
      mstore(line, length) //sub(i, _index))
      mstore(0x40, add(add(line, 0x20), length))
    }
  }

  function split(string memory _str, uint _ch) internal pure returns (string[] memory strs) {
    uint length = bytes(_str).length;
    uint count;
    for (uint i = 0; i < length; i += 1) {
      (, i) = extractLine(_str, i, _ch);
      count += 1;
    }
    strs = new string[](count);
    count = 0;
    for (uint i = 0; i < length; i += 1) {
      (strs[count], i) = extractLine(_str, i, _ch);
      count += 1;
    }
  }
}

// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import 'bytes-array.sol/BytesArray.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import './IFontProvider.sol';
import './Path.sol';
import './Transform.sol';

library SVG {
  using Strings for uint;
  using BytesArray for bytes[];

  struct Attribute {
    string key;
    string value;
  }

  struct Element {
    bytes head;
    bytes tail;
    Attribute[] attrs;
  }

  function path(bytes memory _path) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<path d="', _path);
    elem.tail = bytes('"/>\n');
  }

  function char(IFontProvider _font, string memory _char) internal view returns (Element memory elem) {
    elem = SVG.path(Path.decode(_font.pathOf(_char)));
  }

  function textWidth(IFontProvider _font, string memory _str) internal view returns (uint x) {
    bytes memory data = bytes(_str);
    bytes memory ch = new bytes(1);
    for (uint i = 0; i < data.length; i++) {
      ch[0] = data[i];
      x += _font.widthOf(string(ch));
    }
  }

  function text(IFontProvider _font, string[2] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](2);
    strs[0] = _strs[0];
    strs[1] = _strs[1];
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[3] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](3);
    strs[0] = _strs[0];
    strs[1] = _strs[1];
    strs[2] = _strs[2];
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[4] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](4);
    for (uint i = 0; i < _strs.length; i++) {
      strs[i] = _strs[i];
    }
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[5] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](5);
    for (uint i = 0; i < _strs.length; i++) {
      strs[i] = _strs[i];
    }
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[6] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](6);
    for (uint i = 0; i < _strs.length; i++) {
      strs[i] = _strs[i];
    }
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[7] memory _strs, uint _width) internal view returns (Element memory elem) {
    string[] memory strs = new string[](7);
    for (uint i = 0; i < _strs.length; i++) {
      strs[i] = _strs[i];
    }
    elem = text(_font, strs, _width);
  }

  function text(IFontProvider _font, string[] memory _strs, uint _width) internal view returns (Element memory elem) {
    uint height = _font.height();
    uint maxWidth = _width;
    Element[] memory elems = new Element[](_strs.length);
    for (uint i = 0; i < _strs.length; i++) {
      uint width = textWidth(_font, _strs[i]);
      if (width > maxWidth) {
        maxWidth = width;
      }
      elems[i] = transform(text(_font, _strs[i]), TX.translate(0, int(height * i)));
    }
    // extra group is necessary to let it transform
    elem = group(svg(transform(group(elems), TX.scale1000((1000 * _width) / maxWidth))));
  }

  function text(IFontProvider _font, string memory _str) internal view returns (Element memory elem) {
    bytes memory data = bytes(_str);
    bytes memory ch = new bytes(1);
    Element[] memory elems = new Element[](data.length);
    uint x;
    for (uint i = 0; i < data.length; i++) {
      ch[0] = data[i];
      elems[i] = SVG.path(Path.decode(_font.pathOf(string(ch))));
      if (x > 0) {
        elems[i] = transform(elems[i], string(abi.encodePacked('translate(', x.toString(), ' 0)')));
      }
      x += _font.widthOf(string(ch));
    }
    elem = group(elems);
  }

  function circle(int _cx, int _cy, int _radius) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked(
      '<circle cx="',
      uint(_cx).toString(),
      '" cy="',
      uint(_cy).toString(),
      '" r="',
      uint(_radius).toString()
    );
    elem.tail = '"/>\n';
  }

  function ellipse(int _cx, int _cy, int _rx, int _ry) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked(
      '<ellipse cx="',
      uint(_cx).toString(),
      '" cy="',
      uint(_cy).toString(),
      '" rx="',
      uint(_rx).toString(),
      '" ry="',
      uint(_ry).toString()
    );
    elem.tail = '"/>\n';
  }

  function rect(int _x, int _y, uint _width, uint _height) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked(
      '<rect x="',
      uint(_x).toString(),
      '" y="',
      uint(_y).toString(),
      '" width="',
      _width.toString(),
      '" height="',
      _height.toString()
    );
    elem.tail = '"/>\n';
  }

  function rect() internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<rect width="100%" height="100%');
    elem.tail = '"/>\n';
  }

  function stop(uint ratio) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<stop offset="', ratio.toString(), '%');
    elem.tail = '"/>\n';
  }

  function use(string memory _id) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<use href="#', _id);
    elem.tail = '"/>\n';
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function packed(Element[8] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](8);
    svgs[0] = svg(_elements[0]);
    svgs[1] = svg(_elements[1]);
    svgs[2] = svg(_elements[2]);
    svgs[3] = svg(_elements[3]);
    svgs[4] = svg(_elements[4]);
    svgs[5] = svg(_elements[5]);
    svgs[6] = svg(_elements[6]);
    svgs[7] = svg(_elements[7]);
    output = svgs.packed();
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function packed(Element[4] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](4);
    svgs[0] = svg(_elements[0]);
    svgs[1] = svg(_elements[1]);
    svgs[2] = svg(_elements[2]);
    svgs[3] = svg(_elements[3]);
    output = svgs.packed();
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function packed(Element[3] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](3);
    svgs[0] = svg(_elements[0]);
    svgs[1] = svg(_elements[1]);
    svgs[2] = svg(_elements[2]);
    output = svgs.packed();
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function packed(Element[2] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](2);
    svgs[0] = svg(_elements[0]);
    svgs[1] = svg(_elements[1]);
    output = svgs.packed();
  }

  function packed(Element[] memory _elements) internal pure returns (bytes memory output) {
    bytes[] memory svgs = new bytes[](_elements.length);
    for (uint i = 0; i < _elements.length; i++) {
      svgs[i] = svg(_elements[i]);
    }
    output = svgs.packed();
  }

  function pattern(
    string memory _id,
    string memory _viewbox,
    string memory _width,
    string memory _height,
    bytes memory _elements
  ) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked(
      '<pattern id="',
      _id,
      '" viewBox="',
      _viewbox,
      '" width="',
      _width,
      '" height="',
      _height
    );
    elem.tail = abi.encodePacked('">', _elements, '</pattern>\n');
  }

  function pattern(
    string memory _id,
    string memory _viewbox,
    string memory _width,
    string memory _height,
    Element memory _element
  ) internal pure returns (Element memory elem) {
    elem = pattern(_id, _viewbox, _width, _height, svg(_element));
  }

  function filter(string memory _id, bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<filter id="', _id);
    elem.tail = abi.encodePacked('">', _elements, '</filter>\n');
  }

  function filter(string memory _id, Element memory _element) internal pure returns (Element memory elem) {
    elem = filter(_id, svg(_element));
  }

  function feGaussianBlur(string memory _src, string memory _stdDeviation) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<feGaussianBlur in="', _src, '" stdDeviation="', _stdDeviation);
    elem.tail = '" />';
  }

  /*
      '  <feOffset result="offOut" in="SourceAlpha" dx="24" dy="32" />\n'
      '  <feGaussianBlur result="blurOut" in="offOut" stdDeviation="16" />\n'
      '  <feBlend in="SourceGraphic" in2="blurOut" mode="normal" />\n'
  */
  function feOffset(
    string memory _src,
    string memory _dx,
    string memory _dy
  ) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<feOffset in="', _src, '" dx="', _dx, '" dy="', _dy);
    elem.tail = '" />';
  }

  function feBlend(
    string memory _src,
    string memory _src2,
    string memory _mode
  ) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<feBlend in="', _src, '" in2="', _src2, '" mode="', _mode);
    elem.tail = '" />';
  }

  function linearGradient(string memory _id, bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<linearGradient id="', _id);
    elem.tail = abi.encodePacked('">', _elements, '</linearGradient>\n');
  }

  function linearGradient(string memory _id, Element memory _element) internal pure returns (Element memory elem) {
    elem = linearGradient(_id, svg(_element));
  }

  function radialGradient(string memory _id, bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<radialGradient id="', _id);
    elem.tail = abi.encodePacked('">', _elements, '</radialGradient>\n');
  }

  function radialGradient(string memory _id, Element memory _element) internal pure returns (Element memory elem) {
    elem = radialGradient(_id, svg(_element));
  }

  function group(bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<g x_x="x'); // HACK: dummy header for trailing '"'
    elem.tail = abi.encodePacked('">', _elements, '</g>\n');
  }

  function group(Element memory _element) internal pure returns (Element memory elem) {
    elem = group(svg(_element));
  }

  function group(Element[] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function group(Element[2] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function group(Element[3] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function group(Element[4] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  function group(Element[8] memory _elements) internal pure returns (Element memory elem) {
    elem = group(packed(_elements));
  }

  function element(bytes memory _body) internal pure returns (Element memory elem) {
    elem.tail = _body;
  }

  function list(Element[] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function list(Element[2] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function list(Element[3] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function list(Element[4] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  // HACK: Solidity does not support literal expression of dynamic array yet
  function list(Element[8] memory _elements) internal pure returns (Element memory elem) {
    elem.tail = packed(_elements);
  }

  function mask(string memory _id, bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<mask id="', _id, ''); // HACK: dummy header for trailing '"'
    elem.tail = abi.encodePacked(
      '">'
      '<rect x="0" y="0" width="100%" height="100%" fill="black"/>'
      '<g fill="white">',
      _elements,
      '</g>'
      '</mask>\n'
    );
  }

  function mask(string memory _id, Element memory _element) internal pure returns (Element memory elem) {
    elem = mask(_id, svg(_element));
  }

  function stencil(bytes memory _elements) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<mask x_x="x'); // HACK: dummy header for trailing '"'
    elem.tail = abi.encodePacked(
      '">'
      '<rect x="0" y="0" width="100%" height="100%" fill="white"/>'
      '<g fill="black">',
      _elements,
      '</g>'
      '</mask>\n'
    );
  }

  function stencil(Element memory _element) internal pure returns (Element memory elem) {
    elem = stencil(svg(_element));
  }

  function _append(Element memory _element, Attribute memory _attr) internal pure returns (Element memory elem) {
    elem.head = _element.head;
    elem.tail = _element.tail;
    elem.attrs = new Attribute[](_element.attrs.length + 1);
    for (uint i = 0; i < _element.attrs.length; i++) {
      elem.attrs[i] = _element.attrs[i];
    }
    elem.attrs[_element.attrs.length] = _attr;
  }

  function _append2(
    Element memory _element,
    Attribute memory _attr,
    Attribute memory _attr2
  ) internal pure returns (Element memory elem) {
    elem.head = _element.head;
    elem.tail = _element.tail;
    elem.attrs = new Attribute[](_element.attrs.length + 2);
    for (uint i = 0; i < _element.attrs.length; i++) {
      elem.attrs[i] = _element.attrs[i];
    }
    elem.attrs[_element.attrs.length] = _attr;
    elem.attrs[_element.attrs.length + 1] = _attr2;
  }

  function id(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('id', _value));
  }

  function fill(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('fill', _value));
  }

  function opacity(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('opacity', _value));
  }

  function stopColor(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('stop-color', _value));
  }

  function x1(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('x1', _value));
  }

  function x2(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('x2', _value));
  }

  function y1(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('y1', _value));
  }

  function y2(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('y2', _value));
  }

  function cx(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('cy', _value));
  }

  function cy(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('cy', _value));
  }

  function r(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('r', _value));
  }

  function fx(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('fx', _value));
  }

  function fy(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('fy', _value));
  }

  function result(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('result', _value));
  }

  function fillRef(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('fill', string(abi.encodePacked('url(#', _value, ')'))));
  }

  function filter(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('filter', string(abi.encodePacked('url(#', _value, ')'))));
  }

  function style(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('style', _value));
  }

  function transform(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('transform', _value));
  }

  function mask(Element memory _element, string memory _value) internal pure returns (Element memory elem) {
    elem = _append(_element, Attribute('mask', string(abi.encodePacked('url(#', _value, ')'))));
  }

  function stroke(
    Element memory _element,
    string memory _color,
    uint _width
  ) internal pure returns (Element memory elem) {
    elem = _append2(_element, Attribute('stroke', _color), Attribute('stroke-width', _width.toString()));
  }

  function svg(Element memory _element) internal pure returns (bytes memory output) {
    if (_element.head.length > 0) {
      output = _element.head;
      for (uint i = 0; i < _element.attrs.length; i++) {
        Attribute memory attr = _element.attrs[i];
        output = abi.encodePacked(output, '" ', attr.key, '="', attr.value);
      }
    } else {
      require(_element.attrs.length == 0, 'Attributes on list');
    }
    output = abi.encodePacked(output, _element.tail);
  }

  function document(
    string memory _viewBox,
    bytes memory _defs,
    bytes memory _body
  ) internal pure returns (string memory) {
    bytes memory output = abi.encodePacked(
      '<?xml version="1.0" encoding="UTF-8"?>'
      '<svg viewBox="',
      _viewBox,
      '"'
      ' xmlns="http://www.w3.org/2000/svg">\n'
    );
    if (_defs.length > 0) {
      output = abi.encodePacked(output, '<defs>\n', _defs, '</defs>\n');
    }
    output = abi.encodePacked(output, _body, '</svg>\n');
    return string(output);
  }
}

// SPDX-License-Identifier: MIT

/*
 * Pseudo Random genearation library.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

library Randomizer {
  struct Seed {
    uint256 seed;
    uint256 value;
  }

  /**
   * Returns a seudo random number between 0 and _limit-1.
   * It also returns an updated seed.
   */
  function random(Seed memory _seed, uint256 _limit) internal pure returns (Seed memory seed, uint256 value) {
    seed = _seed;
    if (seed.value < _limit * 256) {
      seed.seed = uint256(keccak256(abi.encodePacked(seed.seed)));
      seed.value = seed.seed;
    }
    value = seed.value % _limit;
    seed.value /= _limit;
  }

  /**
   * Returns a randomized value based on the original value and ration (in percentage).
   * It also returns an updated seed. 
   */
  function randomize(Seed memory _seed, uint256 _value, uint256 _ratio) internal pure returns (Seed memory seed, uint256 value) {
    uint256 limit = _value * _ratio / 100;
    uint256 delta;
    (seed, delta) = random(_seed, limit * 2);
    value = _value - limit + delta;
  }
}

// SPDX-License-Identifier: MIT

/**
 * This is a part of an effort to create a decentralized autonomous marketplace for digital assets,
 * which allows artists and developers to sell their arts and generative arts.
 *
 * Please see "https://fullyonchain.xyz/" for details. 
 *
 * Created by Satoshi Nakajima (@snakajima)
 */
pragma solidity ^0.8.6;

/**
 * IAssetProvider is the interface each asset provider implements.
 * We assume there are three types of asset providers.
 * 1. Static asset provider, which has a collection of assets (either in the storage or the code) and returns them.
 * 2. Generative provider, which dynamically (but deterministically from the seed) generates assets.
 * 3. Data visualizer, which generates assets based on various data on the blockchain.
 *
 * Note: Asset providers MUST implements IERC165 (supportsInterface method) as well. 
 */
interface IAssetProvider {
  struct ProviderInfo {
    string key;  // short and unique identifier of this provider (e.g., "asset")
    string name; // human readable display name (e.g., "Asset Store")
    IAssetProvider provider;
  }
  function getProviderInfo() external view returns(ProviderInfo memory);

  /**
   * This function returns SVGPart and the tag. The SVGPart consists of one or more SVG elements.
   * The tag specifies the identifier of the SVG element to be displayed (using <use> tag).
   * The tag is the combination of the provider key and assetId (e.e., "asset123")
   */
  function generateSVGPart(uint256 _assetId) external view returns(string memory svgPart, string memory tag);

  /**
   * This is an optional function, which returns various traits of the image for ERC721 token.
   * Format: {"trait_type":"TRAIL_TYPE","value":"VALUE"},{...}
   */
  function generateTraits(uint256 _assetId) external view returns (string memory);
  
  /**
   * This function returns the number of assets available from this provider. 
   * If the total supply is 100, assetIds of available assets are 0,1,...99.
   * The generative providers may returns 0, which indicates the provider dynamically but
   * deterministically generates assets using the given assetId as the random seed.
   */
  function totalSupply() external view returns(uint256);

  /**
   * Returns the onwer. The registration update is possible only if both contracts have the same owner. 
   */
  function getOwner() external view returns (address);

  /**
   * This function processes the royalty payment from the decentralized autonomous marketplace. 
   */
  function processPayout(uint256 _assetId) external payable;

  event Payout(string providerKey, uint256 assetId, address payable to, uint256 amount);
}

interface IAssetProviderEx is IAssetProvider {
  function generateSVGDocument(uint256 _assetId) external view returns(string memory document);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import 'trigonometry.sol/Trigonometry.sol';

library Vector {
  using Trigonometry for uint;
  int constant PI = 0x2000;
  int constant PI2 = 0x4000;
  int constant ONE = 0x8000;

  struct Struct {
    int x; // fixed point * ONE
    int y; // fixed point * ONE
  }

  function vector(int _x, int _y) internal pure returns (Struct memory newVector) {
    newVector.x = _x * ONE;
    newVector.y = _y * ONE;
  }

  function vectorWithAngle(int _angle, int _radius) internal pure returns (Struct memory newVector) {
    uint angle = uint(_angle + (PI2 << 64));
    newVector.x = _radius * angle.cos();
    newVector.y = _radius * angle.sin();
  }

  function div(Struct memory _vector, int _value) internal pure returns (Struct memory newVector) {
    newVector.x = _vector.x / _value;
    newVector.y = _vector.y / _value;
  }

  function mul(Struct memory _vector, int _value) internal pure returns (Struct memory newVector) {
    newVector.x = _vector.x * _value;
    newVector.y = _vector.y * _value;
  }

  function add(Struct memory _vector, Struct memory _vector2) internal pure returns (Struct memory newVector) {
    newVector.x = _vector.x + _vector2.x;
    newVector.y = _vector.y + _vector2.y;
  }

  function rotate(Struct memory _vector, int _angle) internal pure returns (Struct memory newVector) {
    uint angle = uint(_angle + (PI2 << 64));
    int cos = angle.cos();
    int sin = angle.sin();
    newVector.x = (cos * _vector.x - sin * _vector.y) / ONE;
    newVector.y = (sin * _vector.x + cos * _vector.y) / ONE;
  }
}

/**
 * Basic trigonometry functions
 *
 * Solidity library offering the functionality of basic trigonometry functions
 * with both input and output being integer approximated.
 *
 * This code was originally written by Lefteris Karapetsas
 * https://github.com/Sikorkaio/sikorka/blob/master/contracts/trigonometry.sol
 *
 * I made several changes to make it easy for me to manage and use. 
 *
 * @author Lefteris Karapetsas 
 * @author Satoshi Nakajima (snakajima)
 * @license BSD3
 */

// SPDX-License-Identifier: BSD3
pragma solidity ^0.8.6;

library Trigonometry {

    // constant sine lookup table generated by gen_tables.py
    // We have no other choice but this since constant arrays don't yet exist
    uint8 constant entry_bytes = 2;
    bytes constant sin_table = "\x00\x00\x0c\x8c\x18\xf9\x25\x28\x30\xfb\x3c\x56\x47\x1c\x51\x33\x5a\x82\x62\xf1\x6a\x6d\x70\xe2\x76\x41\x7a\x7c\x7d\x89\x7f\x61\x7f\xff";

    function sin_table_lookup(uint index) pure internal returns (uint16) {
        bytes memory table = sin_table;
        uint offset = (index + 1) * entry_bytes;
        uint16 trigint_value;
        assembly {
            trigint_value := mload(add(table, offset))
        }

        return trigint_value;
    }

    /**
     * Return the sine of an integer approximated angle as a signed 16-bit
     * integer.
     *
     * @param _angle A 14-bit angle. This divides the circle into 16384 (0x4000)
     *               angle units, instead of the standard 360 degrees.
     * @return The sine result as a number in the range -32767 to 32767.
     */
    function sin(uint _angle) internal pure returns (int) {
        uint angle = _angle % 0x4000;
        if (angle < 0x2000) {
            return sinQuarter(angle < 0x1000 ? angle : 0x2000 - angle);
        }
        return -sinQuarter(angle < 0x3000 ? angle - 0x2000 : 0x4000 - angle);
    }

    function sinQuarter(uint _angle) internal pure returns (int) {
        if (_angle == 0x1000) {
            return 0x7fff;
        }
        uint index = _angle / 0x100; // high 4-bit
        uint interp = _angle & 0xFF; // low 8-bit
        uint x1 = sin_table_lookup(index);
        uint x2 = sin_table_lookup(index + 1);
        return int(x1 + ((x2 - x1) * interp) / 0x100);
    }

    /**
     * Return the cos of an integer approximated angle.
     * It functions just like the sin() method but uses the trigonometric
     * identity sin(x + pi/2) = cos(x) to quickly calculate the cos.
     */
    function cos(uint _angle) internal pure returns (int) {
        return sin(_angle + 0x1000);
    }
}

// SPDX-License-Identifier: MIT

/*
 * This is a part of fully-on-chain.sol, a npm package that allows developers
 * to create fully on-chain generative art.
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'bytes-array.sol/BytesArray.sol';

library TX {
  using Strings for uint;
  using BytesArray for bytes[];

  function toString(int _value) internal pure returns (string memory) {
    if (_value > 0) {
      return uint(_value).toString();
    }
    return string(abi.encodePacked('-', uint(-_value).toString()));
  }

  function translate(int x, int y) internal pure returns (string memory) {
    return string(abi.encodePacked('translate(', toString(x), ' ', toString(y), ')'));
  }

  function rotate(string memory _base, string memory _value) internal pure returns (string memory) {
    return string(abi.encodePacked(_base, ' rotate(', _value, ')'));
  }

  function scale(string memory _base, string memory _scale) internal pure returns (string memory) {
    return string(abi.encodePacked(_base, ' scale(', _scale, ')'));
  }

  function scale1000(uint _value) internal pure returns (string memory) {
    return string(abi.encodePacked('scale(', fixed1000(_value), ')'));
  }

  function scale1000(string memory _base, uint _value) internal pure returns (string memory) {
    return string(abi.encodePacked(_base, ' scale(', fixed1000(_value), ')'));
  }

  function fixed1000(uint _value) internal pure returns (string memory) {
    bytes[] memory array = new bytes[](3);
    if (_value > 1000) {
      array[0] = bytes((_value / 1000).toString());
    } else {
      array[0] = '0';
    }
    if (_value < 10) {
      array[1] = '.00';
    } else if (_value < 100) {
      array[1] = '.0';
    } else {
      array[1] = '.';
    }
    array[2] = bytes(_value.toString());
    return string(array.packed());
  }
}

// SPDX-License-Identifier: MIT

/*
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

library BytesArray {
  /**
   * Equivalent to abi.encodedPacked(parts[0], parts[1], ..., parts[N-1]), where
   * N is the length of bytes.
   *
   * The complexty of this algorithm is O(M), where M is the number of total bytes.
   * Calling abi.encodePacked() in a loop reallocates memory N times, therefore,
   * the complexity will become O(M * N). 
   */
  function packed(bytes[] memory parts) internal pure returns (bytes memory ret) {
    uint count = parts.length;
    assembly {
      ret := mload(0x40)
      let retMemory := add(ret, 0x20)
      let bufParts := add(parts, 0x20)
      for {let i := 0} lt(i, count) {i := add(i, 1)} {
        let src := mload(bufParts) // read the address
        let dest := retMemory
        let length := mload(src)
        // copy 0x20 bytes each (and let it overrun)
        for {let j := 0} lt(j, length) {j := add(j, 0x20)} {
          src := add(src, 0x20) // dual purpose
          mstore(dest, mload(src))
          dest := add(dest, 0x20)
        }
        retMemory := add(retMemory, length)
        bufParts := add(bufParts, 0x20)
      }
      mstore(ret, sub(sub(retMemory, ret), 0x20))
      mstore(0x40, retMemory)
    }
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}