// SPDX-License-Identifier: MIT

/**
 *
 * Created by Satoshi Nakajima (@snakajima)
 * update for Noun 556 by eiba8884
 */

pragma solidity ^0.8.6;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./NounsAssetProviderV2.sol";
import "randomizer.sol/Randomizer.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "../packages/graphics/Path.sol";
import "../packages/graphics/SVG.sol";
import "../packages/graphics/Text.sol";

contract JapaNounsProvider2 is IAssetProviderEx, Ownable, IERC165 {
    using Strings for uint256;
    using Randomizer for Randomizer.Seed;
    using Vector for Vector.Struct;
    using Path for uint256[];
    using SVG for SVG.Element;
    using TX for string;
    using Trigonometry for uint256;

    NounsAssetProviderV2 public immutable nounsProvider;
    uint256[] public nounsId;

    struct pathElement {
        bytes d;
        string color;
    }

    constructor(
        NounsAssetProviderV2 _nounsProvider,
        uint256[] memory _nounsId
    ) {
        nounsProvider = _nounsProvider;
        nounsId = _nounsId;
    }

    function setNounsId(uint256[] memory _nounsId) external onlyOwner {
        nounsId = _nounsId;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAssetProvider).interfaceId ||
            interfaceId == type(IAssetProviderEx).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }

    function getOwner() external view override returns (address) {
        return owner();
    }

    function getProviderInfo()
        external
        view
        override
        returns (ProviderInfo memory)
    {
        return ProviderInfo("japaNouns", "japaNouns", this);
    }

    function totalSupply() external pure override returns (uint256) {
        return 0;
    }

    function processPayout(uint256 _assetId) external payable override {
        address payable payableTo = payable(owner());
        payableTo.transfer(msg.value);
        emit Payout("japaNouns", _assetId, payableTo, msg.value);
    }

    function generateTraits(uint256 _assetId)
        external
        pure
        override
        returns (string memory traits)
    {
        // nothing to return
    }

    // Hack to deal with too many stack variables
    struct Stackframe {
        uint256 color;
        uint256 y;
    }

    function background(uint256 _assetId)
        internal
        pure
        returns (SVG.Element memory)
    {
        Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);

        // // determine num of elements and each height
        uint256 numOfElements = 0;
        uint256 totalY = 0;
        uint256[] memory heights = new uint256[](10); // elements max num

        while (numOfElements < heights.length) {
            uint256 height;
            (seed, height) = seed.random(256);
            if (height < 100) {
                height += 100;
            }

            if (
                numOfElements == heights.length - 1 || totalY + height >= 1024
            ) {
                heights[numOfElements] = 1024 - totalY;
                break;
            } else {
                heights[numOfElements] = height;
            }
            totalY += height;
            numOfElements++;
        }
        numOfElements++;

        // string[5] memory colors = ['#324e76', '#753a36', '#4f5d2d', '#543c72', '#474747'];
        string[5] memory colors = [
            "#30507c",
            "#7b3935",
            "#53622c",
            "#573b78",
            "#494949"
        ];
        SVG.Element[] memory elements = new SVG.Element[](numOfElements);

        totalY = 0;
        for (uint256 i = 0; i < numOfElements; i++) {
            Stackframe memory stack;
            (seed, stack.color) = seed.random(colors.length);
            stack.y = totalY;
            totalY += heights[i];

            SVG.Element memory ele = SVG
                .rect(0, int256(stack.y), 1024, heights[i])
                .fill(colors[stack.color]);
            elements[i] = ele;
        }

        return SVG.group(elements);
    }

    struct StackFrame2 {
        uint256 nounsId;
        string idNouns;
        SVG.Element svgNouns;
        string svg;
        SVG.Element nouns;
    }

    function hands() public pure returns (SVG.Element memory) {
        bytes
            memory hand = "M1 0h1v2h1V1h1V0h1v1H4v1h2V1h1v1H6v1H5v1h2v1H6v1H5V5H3v1H0V2h1z";
        return
            SVG.list(
                [
                    SVG
                        .path(hand)
                        .fill("#f9f5cb")
                        .transform("scale(26.99) translate(10.93 31.9)")
                        .id("hand"),
                    SVG.use("hand").transform("translate(353 0)")
                ]
            );
    }

    struct RGB {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    function accesories(uint256 _assetId)
        public
        pure
        returns (SVG.Element memory)
    {
        Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);
        bytes
            memory bird = "M4 0h1v2h1v1H5v2H2v1H1V5h1V4H1V3H0V2h3V1h1zm1 2H4v1h1z";
        // string[4] memory colors = ['pink', 'orange', 'yellow', 'white'];
        // uint256 color;
        // (seed, color) = seed.random(colors.length);
        RGB memory rgb;
        (seed, rgb.r) = seed.random(156);
        (seed, rgb.g) = seed.random(156);
        (seed, rgb.b) = seed.random(156);
        string memory color = string(abi.encodePacked(
            "rgb(",
            (rgb.r + 100).toString(),
            ",",
            (rgb.g + 100).toString(),
            ",",
            (rgb.b + 100).toString(),
            ")"
        ));

        string[5] memory distances = ["2", "8.5", "16", "23.5", "30"];
        string memory transform = string(
            abi.encodePacked(
                "scale(26.99) translate(",
                distances[_assetId % 5],
                " 1)"
            )
        );
        // SVG.Element memory birdEle = SVG.path(bird).fill(colors[color]).transform(transform).id('bird');
        SVG.Element memory birdEle = SVG
            .path(bird)
            .fill(color)
            .transform(transform)
            .id("bird");

        // imageType:0 => UFO, 1=>Plane other=>NothingÇ
        uint256 imageType;
        (seed, imageType) = seed.random(20); // percentage

        if ((_assetId % 5) != 4 || imageType > 1) {
            // if (false) {
            return birdEle;
        } else if (imageType == 0) {
            //return bird and ufo
            SVG.Element memory ufo = SVG
                .group(
                    SVG.list(
                        [
                            SVG.path("M1 0h2v1H1zm0 3h1v1H1zm2 0h1v1H3z").fill(
                                "#fb4694"
                            ),
                            SVG.path("M0 1h2v1h1V1h1v2H0z").fill("#2a83f6"),
                            SVG.path("M2 1h1v1H2z").fill("#caeff9"),
                            SVG.path("M0 3h1v1H0zm2 0h1v1H2z").fill("#ffe939")
                        ]
                    )
                )
                .transform("scale(26.99) translate(2 2)")
                .id("ufo");
            return SVG.list([birdEle, ufo]);
        } else {
            //return bird and plane
            SVG.Element memory plane = SVG
                .group(
                    SVG.list(
                        [
                            SVG.path("M0 0h1v1H0zm2 0h2v1h1v1H3V1H2z").fill(
                                "#9cb4b8"
                            ),
                            SVG.path("M1 1h2v1H1z").fill("#f3322c"),
                            SVG.path("M5 1h1v1H5zM2 2h1v1H2z").fill("#fff")
                        ]
                    )
                )
                .transform("scale(26.99) translate(2 2)")
                .id("plane");
            return SVG.list([birdEle, plane]);
        }
    }

    function generateSVGPart(uint256 _assetId)
        public
        view
        override
        returns (string memory svgPart, string memory tag)
    {
        Randomizer.Seed memory seed = Randomizer.Seed(_assetId, 0);
        StackFrame2 memory stack;
        tag = string(abi.encodePacked("japaNouns", _assetId.toString()));

        (seed, stack.nounsId) = seed.random(nounsId.length);
        (stack.svg, stack.idNouns) = nounsProvider.getNounsSVGPart(
            nounsId[stack.nounsId]
        );
        stack.svgNouns = SVG.element(bytes(stack.svg));
        stack.nouns = SVG.group(
            [
                background(_assetId),
                accesories(_assetId),
                SVG.use(stack.idNouns).transform(
                    "scale(0.85) translate(90 180)"
                ),
                hands()
            ]
        );

        svgPart = string(SVG.list([stack.svgNouns, stack.nouns.id(tag)]).svg());
    }

    function generateSVGDocument(uint256 _assetId)
        external
        view
        override
        returns (string memory document)
    {
        string memory svgPart;
        string memory tag;
        (svgPart, tag) = generateSVGPart(_assetId);
        document = SVG.document(
            "0 0 1024 1024",
            bytes(svgPart),
            SVG.use(tag).svg()
        );
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
    for (uint i = 0; i < length; ) {
      (, i) = extractLine(_str, i, _ch);
      count += 1;
    }
    strs = new string[](count);
    count = 0;
    for (uint i = 0; i < length; ) {
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

  function polygon(string memory _points) internal pure returns (Element memory elem) {
    elem.head = abi.encodePacked('<polygon points="', _points);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
  function randomize(
    Seed memory _seed,
    uint256 _value,
    uint256 _ratio
  ) internal pure returns (Seed memory seed, uint256 value) {
    uint256 limit = (_value * _ratio) / 100;
    uint256 delta;
    (seed, delta) = random(_seed, limit * 2);
    value = _value - limit + delta;
  }
}

// SPDX-License-Identifier: MIT

/*
 * NounsAssetProvider is a wrapper around NounsDescriptor so that it offers
 * various characters as assets to compose (not individual parts).
 *
 * Created by Satoshi Nakajima (@snakajima)
 */

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/interfaces/IERC165.sol';
import { Base64 } from 'base64-sol/base64.sol';
import 'assetprovider.sol/IAssetProvider.sol';
import '../external/nouns/interfaces/INounsDescriptor.sol';
import '../external/nouns/interfaces/INounsSeeder.sol';
import { NounsToken } from '../external/nouns/NounsToken.sol';
import '../packages/graphics/SVG.sol';

// IAssetProvider wrapper for composability
contract NounsAssetProviderV2 is IAssetProvider, IERC165, Ownable {
  using Strings for uint256;
  using SVG for SVG.Element;

  string constant providerKey = 'nouns';

  NounsToken public immutable nounsToken;

  constructor(NounsToken _nounsToken) {
    nounsToken = _nounsToken;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IAssetProvider).interfaceId || interfaceId == type(IERC165).interfaceId;
  }

  function getOwner() external view override returns (address) {
    return owner();
  }

  function getProviderInfo() external view override returns (ProviderInfo memory) {
    return ProviderInfo(providerKey, 'Nouns', this);
  }

  function generateSVGPart(uint256 _assetId) public view override returns (string memory svgPart, string memory tag) {
    INounsDescriptor descriptor = INounsDescriptor(address(nounsToken.descriptor())); // @notice explicit downcasting
    uint256 backgroundCount = descriptor.backgroundCount();
    uint256 bodyCount = descriptor.bodyCount();
    uint256 accessoryCount = descriptor.accessoryCount();
    uint256 headCount = descriptor.headCount();
    uint256 glassesCount = descriptor.glassesCount();

    uint256 pseudorandomness = uint256(keccak256(abi.encodePacked(_assetId)));

    INounsSeeder.Seed memory seed = INounsSeeder.Seed({
      background: uint48(uint48(pseudorandomness) % backgroundCount),
      body: uint48(uint48(pseudorandomness >> 48) % bodyCount),
      accessory: uint48(uint48(pseudorandomness >> 96) % accessoryCount),
      head: uint48(uint48(pseudorandomness >> 144) % headCount),
      glasses: uint48(uint48(pseudorandomness >> 192) % glassesCount)
    });

    tag = string(abi.encodePacked(providerKey, _assetId.toString()));
    svgPart = svgForSeed(seed, tag);
  }

  function getNounsSVGPart(uint256 _assetId) external view returns (string memory svgPart, string memory tag) {
    INounsSeeder.Seed memory seed;
    (seed.background, seed.body, seed.accessory, seed.head, seed.glasses) = nounsToken.seeds(_assetId);
    tag = string(abi.encodePacked(providerKey, _assetId.toString()));
    svgPart = svgForSeed(seed, tag);
  }

  function getNounsTotalSuppy() external view returns (uint256) {
    return nounsToken.totalSupply();
  }

  function svgForSeed(INounsSeeder.Seed memory _seed, string memory _tag) public view returns (string memory svgPart) {
    INounsDescriptor descriptor = INounsDescriptor(address(nounsToken.descriptor())); // @notice explicit downcasting
    string memory encodedSvg = descriptor.generateSVGImage(_seed);
    bytes memory svg = Base64.decode(encodedSvg);
    uint256 length = svg.length;
    uint256 start = 0;
    for (uint256 i = 0; i < length; i++) {
      if (uint8(svg[i]) == 0x2F && uint8(svg[i + 1]) == 0x3E) {
        // "/>": looking for the end of <rect ../>
        start = i + 2;
        break;
      }
    }
    length -= start + 6; // "</svg>"

    // substring
    /*
    bytes memory ret = new bytes(length);
    for(uint i = 0; i < length; i++) {
        ret[i] = svg[i+start];
    }
    */

    bytes memory ret;
    assembly {
      ret := mload(0x40)
      mstore(ret, length)
      let retMemory := add(ret, 0x20)
      let svgMemory := add(add(svg, 0x20), start)
      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 0x20)
      } {
        let data := mload(add(svgMemory, i))
        mstore(add(retMemory, i), data)
      }
      mstore(0x40, add(add(ret, 0x20), length))
    }

    svgPart = string(
      abi.encodePacked('<g id="', _tag, '" transform="scale(3.2)" shape-rendering="crispEdges">\n', ret, '\n</g>\n')
    );
  }

  function totalSupply() external pure override returns (uint256) {
    return 0; // indicating "dynamically (but deterministically) generated from the given assetId)
  }

  function processPayout(uint256 _assetId) external payable override {
    address payable payableTo = payable(owner());
    payableTo.transfer(msg.value);
    emit Payout(providerKey, _assetId, payableTo, msg.value);
  }

  function generateTraits(uint256 _assetId) external pure override returns (string memory traits) {
    // nothing to return
  }

  // For debugging
  function generateSVGDocument(uint256 _assetId) external view returns (string memory svgDocument) {
    string memory svgPart;
    string memory tag;
    (svgPart, tag) = generateSVGPart(_assetId);
    svgDocument = string(SVG.document('0 0 1024 1024', bytes(svgPart), SVG.use(tag).svg()));
  }
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

// SPDX-License-Identifier: GPL-3.0

/// @title The Nouns ERC-721 token

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { ERC721Checkpointable } from './base/ERC721Checkpointable.sol';
import { INounsDescriptorMinimal } from './interfaces/INounsDescriptorMinimal.sol';
import { INounsSeeder } from './interfaces/INounsSeeder.sol';
import { INounsToken } from './interfaces/INounsToken.sol';
import { ERC721 } from './base/ERC721.sol';
import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { IProxyRegistry } from './external/opensea/IProxyRegistry.sol';

contract NounsToken is INounsToken, Ownable, ERC721Checkpointable {
    // The nounders DAO address (creators org)
    address public noundersDAO;

    // An address who has permissions to mint Nouns
    address public minter;

    // The Nouns token URI descriptor
    INounsDescriptorMinimal public descriptor;

    // The Nouns token seeder
    INounsSeeder public seeder;

    // Whether the minter can be updated
    bool public isMinterLocked;

    // Whether the descriptor can be updated
    bool public isDescriptorLocked;

    // Whether the seeder can be updated
    bool public isSeederLocked;

    // The noun seeds
    mapping(uint256 => INounsSeeder.Seed) public seeds;

    // The internal noun ID tracker
    uint256 private _currentNounId;

    // IPFS content hash of contract-level metadata
    string private _contractURIHash = 'QmZi1n79FqWt2tTLwCqiy6nLM6xLGRsEPQ5JmReJQKNNzX';

    // OpenSea's Proxy Registry
    IProxyRegistry public immutable proxyRegistry;

    /**
     * @notice Require that the minter has not been locked.
     */
    modifier whenMinterNotLocked() {
        require(!isMinterLocked, 'Minter is locked');
        _;
    }

    /**
     * @notice Require that the descriptor has not been locked.
     */
    modifier whenDescriptorNotLocked() {
        require(!isDescriptorLocked, 'Descriptor is locked');
        _;
    }

    /**
     * @notice Require that the seeder has not been locked.
     */
    modifier whenSeederNotLocked() {
        require(!isSeederLocked, 'Seeder is locked');
        _;
    }

    /**
     * @notice Require that the sender is the nounders DAO.
     */
    modifier onlyNoundersDAO() {
        require(msg.sender == noundersDAO, 'Sender is not the nounders DAO');
        _;
    }

    /**
     * @notice Require that the sender is the minter.
     */
    modifier onlyMinter() {
        require(msg.sender == minter, 'Sender is not the minter');
        _;
    }

    constructor(
        address _noundersDAO,
        address _minter,
        INounsDescriptorMinimal _descriptor,
        INounsSeeder _seeder,
        IProxyRegistry _proxyRegistry
    ) ERC721('Nouns', 'NOUN') {
        noundersDAO = _noundersDAO;
        minter = _minter;
        descriptor = _descriptor;
        seeder = _seeder;
        proxyRegistry = _proxyRegistry;
    }

    /**
     * @notice The IPFS URI of contract-level metadata.
     */
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked('ipfs://', _contractURIHash));
    }

    /**
     * @notice Set the _contractURIHash.
     * @dev Only callable by the owner.
     */
    function setContractURIHash(string memory newContractURIHash) external onlyOwner {
        _contractURIHash = newContractURIHash;
    }

    /**
     * @notice Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator) public view override(IERC721, ERC721) returns (bool) {
        // Whitelist OpenSea proxy contract for easy trading.
        if (proxyRegistry.proxies(owner) == operator) {
            return true;
        }
        return super.isApprovedForAll(owner, operator);
    }

    /**
     * @notice Mint a Noun to the minter, along with a possible nounders reward
     * Noun. Nounders reward Nouns are minted every 10 Nouns, starting at 0,
     * until 183 nounder Nouns have been minted (5 years w/ 24 hour auctions).
     * @dev Call _mintTo with the to address(es).
     */
    function mint() public override onlyMinter returns (uint256) {
        if (_currentNounId <= 1820 && _currentNounId % 10 == 0) {
            _mintTo(noundersDAO, _currentNounId++);
        }
        return _mintTo(minter, _currentNounId++);
    }

    /**
     * @notice Burn a noun.
     */
    function burn(uint256 nounId) public override onlyMinter {
        _burn(nounId);
        emit NounBurned(nounId);
    }

    /**
     * @notice A distinct Uniform Resource Identifier (URI) for a given asset.
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        return descriptor.tokenURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Similar to `tokenURI`, but always serves a base64 encoded data URI
     * with the JSON contents directly inlined.
     */
    function dataURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), 'NounsToken: URI query for nonexistent token');
        return descriptor.dataURI(tokenId, seeds[tokenId]);
    }

    /**
     * @notice Set the nounders DAO.
     * @dev Only callable by the nounders DAO when not locked.
     */
    function setNoundersDAO(address _noundersDAO) external override onlyNoundersDAO {
        noundersDAO = _noundersDAO;

        emit NoundersDAOUpdated(_noundersDAO);
    }

    /**
     * @notice Set the token minter.
     * @dev Only callable by the owner when not locked.
     */
    function setMinter(address _minter) external override onlyOwner whenMinterNotLocked {
        minter = _minter;

        emit MinterUpdated(_minter);
    }

    /**
     * @notice Lock the minter.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockMinter() external override onlyOwner whenMinterNotLocked {
        isMinterLocked = true;

        emit MinterLocked();
    }

    /**
     * @notice Set the token URI descriptor.
     * @dev Only callable by the owner when not locked.
     */
    function setDescriptor(INounsDescriptorMinimal _descriptor) external override onlyOwner whenDescriptorNotLocked {
        descriptor = _descriptor;

        emit DescriptorUpdated(_descriptor);
    }

    /**
     * @notice Lock the descriptor.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockDescriptor() external override onlyOwner whenDescriptorNotLocked {
        isDescriptorLocked = true;

        emit DescriptorLocked();
    }

    /**
     * @notice Set the token seeder.
     * @dev Only callable by the owner when not locked.
     */
    function setSeeder(INounsSeeder _seeder) external override onlyOwner whenSeederNotLocked {
        seeder = _seeder;

        emit SeederUpdated(_seeder);
    }

    /**
     * @notice Lock the seeder.
     * @dev This cannot be reversed and is only callable by the owner when not locked.
     */
    function lockSeeder() external override onlyOwner whenSeederNotLocked {
        isSeederLocked = true;

        emit SeederLocked();
    }

    /**
     * @notice Mint a Noun with `nounId` to the provided `to` address.
     */
    function _mintTo(address to, uint256 nounId) internal returns (uint256) {
        INounsSeeder.Seed memory seed = seeds[nounId] = seeder.generateSeed(nounId, descriptor);

        _mint(owner(), to, nounId);
        emit NounCreated(nounId, seed);

        return nounId;
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, INounsDescriptorMinimal descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from './INounsSeeder.sol';
import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';

interface INounsDescriptor is INounsDescriptorMinimal {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view override returns (uint256);

    function bodyCount() external view override returns (uint256);

    function accessoryCount() external view override returns (uint256);

    function headCount() external view override returns (uint256);

    function glassesCount() external view override returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyGlasses(bytes[] calldata glasses) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addGlasses(bytes calldata glasses) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view override returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view override returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounsSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory);
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
    string key; // short and unique identifier of this provider (e.g., "asset")
    string name; // human readable display name (e.g., "Asset Store")
    IAssetProvider provider;
  }

  function getProviderInfo() external view returns (ProviderInfo memory);

  /**
   * This function returns SVGPart and the tag. The SVGPart consists of one or more SVG elements.
   * The tag specifies the identifier of the SVG element to be displayed (using <use> tag).
   * The tag is the combination of the provider key and assetId (e.e., "asset123")
   */
  function generateSVGPart(uint256 _assetId) external view returns (string memory svgPart, string memory tag);

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
  function totalSupply() external view returns (uint256);

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
  function generateSVGDocument(uint256 _assetId) external view returns (string memory document);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
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
      for {
        let i := 0
      } lt(i, count) {
        i := add(i, 1)
      } {
        let src := mload(bufParts) // read the address
        let dest := retMemory
        let length := mload(src)
        // copy 0x20 bytes each (and let it overrun)
        for {
          let j := 0
        } lt(j, length) {
          j := add(j, 0x20)
        } {
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
  bytes constant sin_table =
    '\x00\x00\x0c\x8c\x18\xf9\x25\x28\x30\xfb\x3c\x56\x47\x1c\x51\x33\x5a\x82\x62\xf1\x6a\x6d\x70\xe2\x76\x41\x7a\x7c\x7d\x89\x7f\x61\x7f\xff';

  function sin_table_lookup(uint index) internal pure returns (uint16) {
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

// SPDX-License-Identifier: GPL-3.0

/// @title Common interface for NounsDescriptor versions, as used by NounsToken and NounsSeeder.

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from './INounsSeeder.sol';

interface INounsDescriptorMinimal {
    ///
    /// USED BY TOKEN
    ///

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    ///
    /// USED BY SEEDER
    ///

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IProxyRegistry {
    function proxies(address) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

/// @title ERC721 Token Implementation

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// ERC721.sol modifies OpenZeppelin's ERC721.sol:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6618f9f18424ade44116d0221719f4c93be6a078/contracts/token/ERC721/ERC721.sol
//
// ERC721.sol source code copyright OpenZeppelin licensed under the MIT License.
// With modifications by Nounders DAO.
//
//
// MODIFICATIONS:
// `_safeMint` and `_mint` contain an additional `creator` argument and
// emit two `Transfer` logs, rather than one. The first log displays the
// transfer (mint) from `address(0)` to the `creator`. The second displays the
// transfer from the `creator` to the `to` address. This enables correct
// attribution on various NFT marketplaces.

pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), 'ERC721: owner query for nonexistent token');
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            'ERC721: approve caller is not owner nor approved for all'
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), 'ERC721: approve to caller');

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), 'ERC721: transfer to non ERC721Receiver implementer');
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId`, transfers it to `to`, and emits two log events -
     * 1. Credits the `minter` with the mint.
     * 2. Shows transfer from the `minter` to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address creator,
        address to,
        uint256 tokenId
    ) internal virtual {
        _safeMint(creator, to, tokenId, '');
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address creator,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(creator, to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            'ERC721: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Mints `tokenId`, transfers it to `to`, and emits two log events -
     * 1. Credits the `creator` with the mint.
     * 2. Shows transfer from the `creator` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address creator,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(to != address(0), 'ERC721: mint to the zero address');
        require(!_exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), creator, tokenId);
        emit Transfer(creator, to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, 'ERC721: transfer of token that is not own');
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721: transfer to non ERC721Receiver implementer');
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsToken

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { IERC721 } from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import { INounsDescriptorMinimal } from './INounsDescriptorMinimal.sol';
import { INounsSeeder } from './INounsSeeder.sol';

interface INounsToken is IERC721 {
    event NounCreated(uint256 indexed tokenId, INounsSeeder.Seed seed);

    event NounBurned(uint256 indexed tokenId);

    event NoundersDAOUpdated(address noundersDAO);

    event MinterUpdated(address minter);

    event MinterLocked();

    event DescriptorUpdated(INounsDescriptorMinimal descriptor);

    event DescriptorLocked();

    event SeederUpdated(INounsSeeder seeder);

    event SeederLocked();

    function mint() external returns (uint256);

    function burn(uint256 tokenId) external;

    function dataURI(uint256 tokenId) external returns (string memory);

    function setNoundersDAO(address noundersDAO) external;

    function setMinter(address minter) external;

    function lockMinter() external;

    function setDescriptor(INounsDescriptorMinimal descriptor) external;

    function lockDescriptor() external;

    function setSeeder(INounsSeeder seeder) external;

    function lockSeeder() external;
}

// SPDX-License-Identifier: BSD-3-Clause

/// @title Vote checkpointing for an ERC-721 token

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// ERC721Checkpointable.sol uses and modifies part of Compound Lab's Comp.sol:
// https://github.com/compound-finance/compound-protocol/blob/ae4388e780a8d596d97619d9704a931a2752c2bc/contracts/Governance/Comp.sol
//
// Comp.sol source code Copyright 2020 Compound Labs, Inc. licensed under the BSD-3-Clause license.
// With modifications by Nounders DAO.
//
// Additional conditions of BSD-3-Clause can be found here: https://opensource.org/licenses/BSD-3-Clause
//
// MODIFICATIONS
// Checkpointing logic from Comp.sol has been used with the following modifications:
// - `delegates` is renamed to `_delegates` and is set to private
// - `delegates` is a public function that uses the `_delegates` mapping look-up, but unlike
//   Comp.sol, returns the delegator's own address if there is no delegate.
//   This avoids the delegator needing to "delegate to self" with an additional transaction
// - `_transferTokens()` is renamed `_beforeTokenTransfer()` and adapted to hook into OpenZeppelin's ERC721 hooks.

pragma solidity ^0.8.6;

import './ERC721Enumerable.sol';

abstract contract ERC721Checkpointable is ERC721Enumerable {
    /// @notice Defines decimals as per ERC-20 convention to make integrations with 3rd party governance platforms easier
    uint8 public constant decimals = 0;

    /// @notice A record of each accounts delegate
    mapping(address => address) private _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @notice The votes a delegator can delegate, which is the current balance of the delegator.
     * @dev Used when calling `_delegate()`
     */
    function votesToDelegate(address delegator) public view returns (uint96) {
        return safe96(balanceOf(delegator), 'ERC721Checkpointable::votesToDelegate: amount exceeds 96 bits');
    }

    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    /**
     * @notice Adapted from `_transferTokens()` in `Comp.sol` to update delegate votes.
     * @dev hooks into OpenZeppelin's `ERC721._transfer`
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        super._beforeTokenTransfer(from, to, tokenId);

        /// @notice Differs from `_transferTokens()` to use `delegates` override method to simulate auto-delegation
        _moveDelegates(delegates(from), delegates(to), 1);
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        if (delegatee == address(0)) delegatee = msg.sender;
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), 'ERC721Checkpointable::delegateBySig: invalid signature');
        require(nonce == nonces[signatory]++, 'ERC721Checkpointable::delegateBySig: invalid nonce');
        require(block.timestamp <= expiry, 'ERC721Checkpointable::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, 'ERC721Checkpointable::getPriorVotes: not yet determined');

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        uint96 amount = votesToDelegate(delegator);

        _moveDelegates(currentDelegate, delegatee, amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, 'ERC721Checkpointable::_moveDelegates: amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, 'ERC721Checkpointable::_moveDelegates: amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            'ERC721Checkpointable::_writeCheckpoint: block number exceeds 32 bits'
        );

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

/// @title ERC721 Enumerable Extension

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

// LICENSE
// ERC721.sol modifies OpenZeppelin's ERC721Enumerable.sol:
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6618f9f18424ade44116d0221719f4c93be6a078/contracts/token/ERC721/extensions/ERC721Enumerable.sol
//
// ERC721Enumerable.sol source code copyright OpenZeppelin licensed under the MIT License.
// With modifications by Nounders DAO.
//
// MODIFICATIONS:
// Consumes modified `ERC721` contract. See notes in `ERC721.sol`.

pragma solidity ^0.8.0;

import './ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), 'ERC721Enumerable: owner index out of bounds');
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), 'ERC721Enumerable: global index out of bounds');
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}