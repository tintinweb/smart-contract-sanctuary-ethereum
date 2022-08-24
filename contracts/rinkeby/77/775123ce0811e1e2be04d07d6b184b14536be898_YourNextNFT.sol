// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs
pragma solidity ^0.8.4;

import './Erc721A.sol';
  
contract YourNextNFT is ERC721A {  
    constructor() ERC721A("MY Next NFT", "MYNFTNEXT") {}  
  
    function mint(uint256 quantity) external payable {  
        // _safeMint's second argument now takes in a quantity, not a tokenId.  
  _safeMint(msg.sender, quantity);  
  }  
}