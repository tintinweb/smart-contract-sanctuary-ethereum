//	SPDX-License-Identifier: MIT
/// @title  Logo Searcher
/// @notice Searcher for client to use
pragma solidity ^0.8.0;

import '../common/LogoModel.sol';

interface ILogoDescriptor {
  function logos(uint256 tokenId) external returns (Model.Logo memory);
  function metaData(uint256 tokenId, string memory key) external returns (string memory);
  function getTextElement(uint256 tokenId) external view returns (Model.LogoElement memory);
  function getLayers(uint256 tokenId) external view returns (Model.LogoElement[] memory);
}

contract LogoSearcher {
  address public logoDescriptorAddress;
  ILogoDescriptor descriptor;

  constructor(address _address) {
    logoDescriptorAddress = _address;
    descriptor = ILogoDescriptor(_address);
  }

  function getNextConfiguredLogos(uint256 quantity, string memory configuredAttr, string memory configuredAttrVal, uint256 startTokenId, uint256 endTokenId) public returns (uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](quantity);
    for (uint i; i < quantity; i++) {
      if (startTokenId != type(uint256).max && startTokenId <= endTokenId) {
        tokenIds[i] = getNextConfiguredLogo(configuredAttr, configuredAttrVal, startTokenId, endTokenId);
        startTokenId = tokenIds[i] != type(uint256).max ? tokenIds[i] + 1: type(uint256).max;
      } else {
        tokenIds[i] = type(uint256).max;
      }
    }
    return tokenIds;
  }

  function getPreviousConfiguredLogos(uint256 quantity, string memory configuredAttr, string memory configuredAttrVal, uint256 startTokenId, uint256 endTokenId) public returns (uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](quantity);
    for (uint i; i < quantity; i++) {
      if (startTokenId != type(uint256).max && startTokenId >= endTokenId) {
        tokenIds[i] = getPreviousConfiguredLogo(configuredAttr, configuredAttrVal, startTokenId, endTokenId);
        startTokenId = tokenIds[i] != type(uint256).max && tokenIds[i] > 0 ? tokenIds[i] - 1: type(uint256).max;
      } else {
        tokenIds[i] = type(uint256).max;
      }
    }
    return tokenIds;
  }

  function getNextConfiguredLogo(string memory configuredAttr, string memory configuredAttrVal, uint256 startTokenId, uint256 endTokenId) public returns (uint256) {
    for (uint i = startTokenId; i <= endTokenId; i++) {
      if (logoIsConfigured(i, configuredAttr, configuredAttrVal)) {
        return i;
      }
    }
    return type(uint256).max;
  }

  function getPreviousConfiguredLogo(string memory configuredAttr,  string memory configuredAttrVal, uint256 startTokenId, uint256 endTokenId) public returns (uint256) {
    for (uint i = startTokenId; i >= endTokenId; i--) {
      if (logoIsConfigured(i, configuredAttr, configuredAttrVal)) {
        return i;
      }
    }
    return type(uint256).max;
  }

  function logoIsConfigured(uint256 tokenId, string memory configuredAttr,  string memory configuredAttrVal) public returns (bool) {
    if (equals(configuredAttr, 'layers')) {
      Model.LogoElement[] memory layers = descriptor.getLayers(tokenId);
      for (uint j; j < layers.length; j++) {
        if (layers[j].contractAddress != address(0x0)) {
          return true;
        }
      }
      Model.LogoElement memory text = descriptor.getTextElement(tokenId);
      if (text.contractAddress != address(0x0)) {
        return true;
      }
    } else {
      string memory metaDataVal = descriptor.metaData(tokenId, configuredAttr);
      if ((!equals(configuredAttrVal, '') && equals(metaDataVal, configuredAttrVal)) || (equals(configuredAttrVal, '') && !equals(metaDataVal, ''))) {
        return true;
      }
    }
    return false;
  }

  function equals(string memory a, string memory b) public pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
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