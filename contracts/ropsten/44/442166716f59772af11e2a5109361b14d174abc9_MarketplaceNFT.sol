// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
 
import "./nf-token-metadata.sol";
import "./ownable.sol";
 
contract MarketplaceNFT is NFTokenMetadata, Ownable {
 
  constructor() {
    nftName = "Defi Marketplace NFT";
    nftSymbol = "DMPNFT";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
}