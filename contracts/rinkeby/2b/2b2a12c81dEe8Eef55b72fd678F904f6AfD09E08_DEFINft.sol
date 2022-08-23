// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
 
import "./nf-token-metadata.sol";
import "./ownable.sol";
 
contract DEFINft is NFTokenMetadata, Ownable {

    string internal baseUrlIPFS;
    uint256 internal maxRoyalityLimit;  

    constructor() {
      maxRoyalityLimit = 10;
      nftName = "DeFi NFT";
      nftSymbol = "DEFI-NFT";
    }

    function setBaseUrlIPFS(string memory url) external onlyOwner{
      baseUrlIPFS = url;
    }
    
    function setRoyalityLimit(uint256 _maxRoyalityLimit) external onlyOwner{
      maxRoyalityLimit = _maxRoyalityLimit;
    }
    function getRoyalityLimit() external view returns (uint256){
      return maxRoyalityLimit;
    }
    function getBaseUrlIPFS() external view returns (string memory){
      return baseUrlIPFS;
    }
  
    function mint(address _to, uint256 _tokenId, uint256 _royality, string calldata _uri) external {
      require(_royality <= maxRoyalityLimit,"Royality limit must be less than or equal to max. royality limit");
      super._mint(_to, _tokenId);
      super._setTokenUri(_tokenId, _uri);
      super.setRoyalityDetails(_tokenId,_royality,_to);
    }

    function tokenURI(uint256 _tokenId) public override view returns (string memory)
    {
      return string(abi.encodePacked(baseUrlIPFS, super.tokenURI(_tokenId)));
    }

}