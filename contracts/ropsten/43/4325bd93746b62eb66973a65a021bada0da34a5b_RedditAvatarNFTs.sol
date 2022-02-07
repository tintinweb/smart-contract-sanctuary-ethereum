pragma solidity ^0.7.3;

import "./ERC721.sol";
import "./Ownable.sol";

contract RedditAvatarNFTs is ERC721, Ownable {
  constructor() public ERC721("RedditNFT", "SNOO") {}

  function mintNFT(uint tokenId, address ownerId, string memory tokenURI) public onlyOwner {
    _mint(ownerId, tokenId);
    _setTokenURI(tokenId, tokenURI);
  }
}