pragma solidity ^0.8.0;

import './ERC721.sol';

contract NFT is ERC721 {
  uint public nextTokenId;
  address public admin;

  constructor() ERC721('My NFT', 'NFT', 0x2420F15fAAe0A2847B230C5644F954C647DE5AcA) {
    admin = msg.sender;
  }

  function mint(address to) external {
    require(msg.sender == admin, 'only admin');
    _safeMint(to, nextTokenId);
    nextTokenId++;
  }



  function _baseURI() internal view override returns (string memory) {
    return '';
  }

}