// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "./NFTokenMetadata.sol";
import "./Ownable.sol";
import {NFToken} from "./NFToken.sol";

contract NovaNFT is NFTokenMetadata, Ownable {
  constructor() {
    nftName = "dongmeiNFT";
    nftSymbol = "DONGMEI";
  }
  function mint(address _to, uint256 _tokenId, string calldata _uri) external onlyOwner {
    super._mint(_to, _tokenId);
    super._setTokenUri(_tokenId, _uri);
  }


  function burn(address user,uint256 _tokenId)  external onlyOwner {
    address owner  = NFToken(address(this)).ownerOf(_tokenId);
    require((owner == user),"user must be owner of the tokenId");
    super._burn(_tokenId);
  }
}