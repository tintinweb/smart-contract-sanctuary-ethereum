// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
 
import "./nf-token-metadata.sol";
import "./ownable.sol";
 
contract MarketplaceNFT is NFTokenMetadata, Ownable {

  string internal baseUrlIPFS;
 
  constructor() {
    nftName = "Visual NFT";
    nftSymbol = "VSL-NFT";
  }

  function setBaseUrlIPFS(string memory url) external onlyOwner{
    baseUrlIPFS = url;
  }

  function getBaseUrlIPFS() external view returns (string memory){
    return baseUrlIPFS;
  }
 
  function mint(address _to, uint256 _tokenId, uint256 _royality,string calldata _uri) external {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
    super.setRoyalityDetails(_tokenId,_royality,_to);
  }

  function tokenURI(uint256 _tokenId) public override view returns (string memory)
  {
    return string(abi.encodePacked(baseUrlIPFS, super.tokenURI(_tokenId)));
  }


  
}