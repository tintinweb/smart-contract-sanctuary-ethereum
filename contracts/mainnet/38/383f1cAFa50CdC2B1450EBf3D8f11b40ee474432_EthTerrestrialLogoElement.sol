//	SPDX-License-Identifier: MIT
/// @title  EthTerrestrials wrapper to be used as a Logo Element
pragma solidity ^0.8.0;

interface IEthTerrestrials {
  function getTokenSeed(uint256 tokenId) external view returns (uint8[10] memory);
  function tokenSVG(uint256 tokenId, bool background) external view returns (string memory);
}

interface IV2Descriptor {
  function getSvgFromSeed(uint8[10] memory seed) external view returns (string memory);
}

/// @notice A wrapper contract which allows EthTerrestrials to be used for logo layers
/// @dev Use as an example for your own contract to be used for a logo layers
/// @dev mustBeOwner() and getSvg(uint256 tokenId) are required
contract EthTerrestrialLogoElement {
  IEthTerrestrials ethTerrestrials;
  IV2Descriptor v2Descriptor;

  constructor(address _ethTerrestrials, address _v2Descriptor) {
    ethTerrestrials = IEthTerrestrials(_ethTerrestrials);
    v2Descriptor = IV2Descriptor(_v2Descriptor);
  }

  /// @notice Specifies whether or not non-owners can use a token for their logo layer
  /// @dev Required for any element used for a logo layer
  function mustBeOwnerForLogo() external view returns (bool) {
    return false;
  }

  /// @notice Gets the SVG for the logo layer
  /// @dev Required for any element used for a logo layer
  /// @param tokenId, the tokenId that SVG will be fetched for
  function getSvg(uint256 tokenId) public view returns (string memory) {
    // tripped ethT
    if (tokenId > 111) {
      uint8[10] memory seed = ethTerrestrials.getTokenSeed(tokenId);
      seed[0] = type(uint8).max;
      seed[9] = type(uint8).max;
      return v2Descriptor.getSvgFromSeed(seed);
    } else {
      // 1:1 or genesis ethT
      return ethTerrestrials.tokenSVG(tokenId, true);
    }

  }
}