// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract MyNFT is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    uint256 public mintRate = 0.01 ether ;
    uint public MAX_SUPPLY = 10000;

    constructor() ERC721("MyNFT", "NFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://api.mynft.com/tokens/";
    }

    function safeMint(address to) public payable 
     {
         require(totalSupply() < MAX_SUPPLY , " can not mint more ") ;
        require(msg.value >= mintRate , " not enough ether to sent");
        _tokenIdCounter.increment();
        //uint256 tokenId = _tokenIdCounter.current());
        
        _safeMint(to, _tokenIdCounter.current());
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    function withdraw() public onlyOwner
    {
        require(address(this).balance > 0 , " balance is 0");
        payable(owner()).transfer(address(this).balance);
    }
}