//	SPDX-License-Identifier: MIT
/// @title  Logo Descriptor
/// @notice Descriptor which allow configuratin of logo containers and fetching of on-chain assets
pragma solidity ^0.8.0;

import './common/LogoHelper.sol';
import './common/LogoModel.sol';
import './common/SvgElement.sol';
import './common/SvgHeader.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

interface ILogoElementProvider {
  function mustBeOwnerForLogo() external view returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
  function getSvg(uint256 tokenId) external view returns (string memory);
  function getSvg(uint256 tokenId, string memory txt, string memory font, string memory fontLink) external view returns (string memory);
  function setTxtVal(uint256 tokenId, string memory val) external;
  function setFont(uint256 tokenId, string memory link, string memory font) external;
}

interface ILogos {
  function ownerOf(uint256 tokenId) external view returns (address);
}

interface INftDescriptor {
  function namePrefix() external view returns (string memory);
  function description() external view returns (string memory);
  function getAttributes(Model.Logo memory logo) external view returns (string memory);
}

contract LogoDescriptor is Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  address public logosAddress;
  ILogos nft;

  address public nftDescriptorAddress;
  INftDescriptor nftDescriptor;

  /// @notice Boolean which sets whether or not only approved contracts can be used for logo layers
  bool public onlyApprovedContracts;

  /// @notice Approved contracts that can be used for logo layers
  mapping(address => bool) public approvedContracts;

  mapping(uint256 => Model.Logo) public logos;
  mapping(uint256 => mapping(string => string)) public metaData;

  modifier onlyWhileUnsealed() {
    require(!contractSealed, 'Contract is sealed');
    _;
  }

  modifier onlyLogoOwner(uint256 tokenId) {
    require(msg.sender == nft.ownerOf(tokenId), 'Only logo owner can be caller');
    _;
  }

  constructor(address _logosAddress, address _nftDescriptorAddress) Ownable() {
    logosAddress = _logosAddress;
    nft = ILogos(logosAddress);

    nftDescriptorAddress = _nftDescriptorAddress;
    nftDescriptor = INftDescriptor(nftDescriptorAddress);

    onlyApprovedContracts = true;
  }

  /// @notice Sets the address of the nft descriptor contract
  function setDescriptorAddress(address _address) external onlyOwner onlyWhileUnsealed {
    nftDescriptorAddress = _address;
    nftDescriptor = INftDescriptor(_address);
  }

  /// @notice Toggles whether or not only approved contracts can be used for logo layers
  function toggleOnlyApprovedContracts() external onlyOwner onlyWhileUnsealed {
    onlyApprovedContracts = !onlyApprovedContracts;
  }

  /// @notice Sets approved contracts which can be used for logo layers
  /// @param addresses, addresses of contracts that can be used for logo layers
  function setApprovedContracts(address[] memory addresses) external onlyOwner onlyWhileUnsealed {
    for(uint i; i < addresses.length; i++) {
      approvedContracts[addresses[i]] = true;
    }
  }

  /// @notice Unapproves a previously approved contract for logo layers
  /// @param addresses, addresses of contracts that cannot be used for logo layers
  function setUnapprovedContracts(address[] memory addresses) external onlyOwner onlyWhileUnsealed {
    for(uint i; i < addresses.length; i++) {
      approvedContracts[addresses[i]] = false;
    }
  }

  /// @notice Sets an individual logo layer
  /// @param tokenId, logo tokenId to set layer for
  /// @param layerIndex, array index of layer to set, use max uint256 for text element
  /// @param element, the new logo element
  /// @param txt, text to use for the text element of the logo, optional -  Only needed for text layer
  /// @param font, font to use for the text element of the logo, optional - use emptry string for default or non text layer
  /// @param fontLink, a url with the font specification for the chosen font, optional - use emptry string for default or non text layer
  function setLogoElement(uint256 tokenId, uint256 layerIndex, Model.LogoElement memory element, string memory txt, string memory font, string memory fontLink) public onlyLogoOwner(tokenId) {
    require(canSetElement(element.contractAddress, element.tokenId), 'Contract not approved or ownership requirements not met');
    Model.Logo storage sLogo = logos[tokenId];
    if (layerIndex == type(uint8).max) {
      sLogo.text = element;
      if (element.contractAddress != address(0x0) && !LogoHelper.equal(font, '')) {
        ILogoElementProvider provider = ILogoElementProvider(element.contractAddress);
        provider.setFont(element.tokenId, fontLink, font);
      } 
      if (element.contractAddress != address(0x0) && !LogoHelper.equal(txt, '')) {
        ILogoElementProvider provider = ILogoElementProvider(element.contractAddress);
        provider.setTxtVal(element.tokenId, txt);
      }
    } else {
      if (layerIndex >= sLogo.layers.length) {
        sLogo.layers.push(element);
      } else {
        sLogo.layers[layerIndex] = element;
      }
    }
  }

  /// @notice Sets logo visual attributes
  /// @notice Will not remove existing layers if new layers at index are not specified
  /// @notice To remove layers, the client should set the layer at index to null address
  /// @param tokenId, number of logo containers to mint
  /// @param logo, configuration of the logo container, see Logo struct
  /// @param txt, text to use for the text element of the logo
  /// @param font, font to use for the text element of the logo, optional - use emptry string for default
  /// @param fontLink, a url with the font specification for the chosen font, optional - use emptry string for default
  function setLogo(uint256 tokenId, Model.Logo memory logo, string memory txt, string memory font, string memory fontLink) external onlyLogoOwner(tokenId) {
    // set layers
    for (uint i; i < logo.layers.length; i++) {
      setLogoElement(tokenId, i, logo.layers[i], '', '', '');
    }
    // set text
    setLogoElement(tokenId, type(uint8).max, logo.text, txt, font, fontLink);
    Model.Logo storage sLogo = logos[tokenId];
    sLogo.width = logo.width;
    sLogo.height = logo.height;
  }

  /// @notice Contracts used for layers specify whether or not the layer can be used by non-owners of the token
  function canSetElement(address contractAddress, uint256 tokenId) public view returns (bool) {
    if (contractAddress == address(0x0)) {
      return true;
    }

    if (onlyApprovedContracts && !approvedContracts[contractAddress]) {
      return false;
    }

    ILogoElementProvider provider = ILogoElementProvider(contractAddress);
    if (provider.mustBeOwnerForLogo()) {
      return provider.ownerOf(tokenId) == msg.sender;
    }
    return true;
  }

  /// @notice Sets logo data
  /// @param tokenId, logo container tokenId
  /// @param _metaData, metadata to set for the specified logo
  function setMetaData(uint256 tokenId, Model.MetaData[] memory _metaData) external onlyLogoOwner(tokenId) {
    mapping(string => string) storage metaDataForToken = metaData[tokenId];
    for (uint256 i = 0; i < _metaData.length; i++) {
      metaDataForToken[_metaData[i].key] = _metaData[i].value;
    }
  }

  /// @notice Returns metadata for a list of keys
  /// @param tokenId, tokenId to return metadata for
  /// @param keys, keys of the metadata that values will be returned for
  function getMetaDataForKeys(uint tokenId, string[] memory keys) public view returns (string[] memory) {
    string[] memory values = new string[](keys.length);
    for (uint i; i < keys.length; i++) {
      values[i] = metaData[tokenId][keys[i]];
    }
    return values;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    string memory svg = getSvg(tokenId);
    string memory name = string(abi.encodePacked(nftDescriptor.namePrefix(), LogoHelper.toString(tokenId)));
    string memory json = LogoHelper.encode(abi.encodePacked('{"name": "', name, '", "description": "', nftDescriptor.description(), '", "image": "data:image/svg+xml;base64,', LogoHelper.encode(bytes(svg)), '", "attributes": ', nftDescriptor.getAttributes(logos[tokenId]),'}'));
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  /// @notice Fetches attributes of logo
  /// @param tokenId, logo container tokenId
  function getAttributes(uint256 tokenId) external view returns (string memory) {
    return nftDescriptor.getAttributes(logos[tokenId]);
  }

  /// @notice Fetches text of the logo container
  /// @param tokenId, logo container tokenId
  function getTextElement(uint256 tokenId) external view returns (Model.LogoElement memory) {
    return logos[tokenId].text;
  }

  /// @notice Fetches layers of the logo container
  /// @param tokenId, logo container tokenId
  function getLayers(uint256 tokenId) external view returns (Model.LogoElement[] memory) {
    return logos[tokenId].layers;
  }

  /// @notice Returns svg of a specified logo
  /// @param tokenId, logo container tokenId
  function getSvg(uint256 tokenId) public view returns (string memory) {
    return getLogoSvg(logos[tokenId], '', '', '');
  }

  /// @notice Returns svg of a logo with given configuration, used for preview purposes
  /// @param logo, configuration of logo which svg should be generated
  /// @param overrideTxt, text to use for the text element of the logo
  /// @param overrideFont, font to use for the text element of the logo, optional - use emptry string for default
  /// @param overrideFontLink, a url with the font specification for the chosen font, optional - use emptry string for default
  function getLogoSvg(Model.Logo memory logo, string memory overrideTxt, string memory overrideFont, string memory overrideFontLink) public view returns (string memory) {
    string memory svg = SvgHeader.getHeader(logo.width, logo.height);

    ILogoElementProvider provider;
    Model.LogoElement memory element;
    for (uint i; i < logo.layers.length; i++) {
      element = logo.layers[i];
      if (element.contractAddress != address(0x0)) {
        provider = ILogoElementProvider(element.contractAddress);
        svg = string(abi.encodePacked(svg, SvgElement.getGroup(SvgElement.Group(getTransform(element), provider.getSvg(element.tokenId)))));
      }
    }

    element = logo.text;
    if (element.contractAddress != address(0x0)) {
      provider = ILogoElementProvider(element.contractAddress);
      if (!LogoHelper.equal(overrideTxt, '') || !LogoHelper.equal(overrideFont, '') || !LogoHelper.equal(overrideFontLink, '') ) {
        svg = string(abi.encodePacked(svg, SvgElement.getGroup(SvgElement.Group(getTransform(element), provider.getSvg(element.tokenId, overrideTxt, overrideFont, overrideFontLink)))));
      } else {
        svg = string(abi.encodePacked(svg, SvgElement.getGroup(SvgElement.Group(getTransform(element), provider.getSvg(element.tokenId)))));
      }
    }
    return string(abi.encodePacked(svg, '</svg>'));
  }

  /// @dev Gets svg transform element for the specified transform of the logo
  function getTransform(Model.LogoElement memory element) public pure returns (string memory) {
    return SvgHeader.getTransform(element.translateXDirection, element.translateX, element.translateYDirection, element.translateY, element.scaleDirection, element.scaleMagnitude);
  }

  /// @notice Permananetly seals the contract from being modified
  function sealContract() external onlyOwner {
    contractSealed = true;
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
/// @notice Definition of Logo model
pragma solidity ^0.8.0;

library Model {

  /// @notice A logo container which holds layers of composable visual onchain assets
  struct Logo {
    uint16 width;
    uint16 height;
    LogoElement[] layers;
    LogoElement text;
  }

  /// @notice A layer of a logo displaying a visual onchain asset
  struct LogoElement {
    address contractAddress;
    uint32 tokenId;
    uint8 translateXDirection;
    uint16 translateX;
    uint8 translateYDirection;
    uint16 translateY;
    uint8 scaleDirection;
    uint8 scaleMagnitude;
  }

  /// @notice Data that can be set by logo owners and can be used in a composable onchain manner
  struct MetaData {
    string key;
    string value;
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
/// @notice Helper to build svg elements
pragma solidity ^0.8.0;

import './LogoHelper.sol';

library SvgHeader {
  function getHeader(uint16 width, uint16 height) public pure returns (string memory) {
    string memory svg = '<svg version="2.0" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 ';
    if (width != 0 && height != 0) {
      svg = string(abi.encodePacked(svg, LogoHelper.toString(width), ' ', LogoHelper.toString(height), '">'));
    } else {
      svg = string(abi.encodePacked(svg, '300 300">'));
    }
    return svg;
  }

  function getTransform(uint8 translateXDirection, uint16 translateX, uint8 translateYDirection, uint16 translateY, uint8 scaleDirection, uint8 scaleMagnitude) public pure returns (string memory) {
    string memory translateXStr = translateXDirection == 0 ? string(abi.encodePacked('-', LogoHelper.toString(translateX))) : LogoHelper.toString(translateX);
    string memory translateYStr = translateYDirection == 0 ? string(abi.encodePacked('-', LogoHelper.toString(translateY))) : LogoHelper.toString(translateY);

    string memory scale = '1';
    if (scaleMagnitude != 0) {
      if (scaleDirection == 0) { 
        scale = string(abi.encodePacked('0.', scaleMagnitude < 10 ? LogoHelper.toString(scaleMagnitude): LogoHelper.toString(scaleMagnitude % 10)));
      } else {
        scale = string(abi.encodePacked(LogoHelper.toString((scaleMagnitude / 10) + 1), '.', LogoHelper.toString(scaleMagnitude % 10)));
      }
    }

    return string(abi.encodePacked('translate(', translateXStr, ', ', translateYStr, ') ', 'scale(', scale, ')'));
  }

}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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