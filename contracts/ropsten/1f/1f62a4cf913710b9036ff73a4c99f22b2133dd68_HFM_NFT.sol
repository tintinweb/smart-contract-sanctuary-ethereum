// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
 
import "./nf-token-metadata.sol";
import "./ownable.sol";
 
contract HFM_NFT is NFTokenMetadata, Ownable {
 
  constructor() {
    nftName = "Hans & Freya marriage";
    nftSymbol = "HF";
  }
 
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }
 
}