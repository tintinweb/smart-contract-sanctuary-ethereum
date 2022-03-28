// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Counters.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract TestToken721 is ERC721, Ownable, ERC721Enumerable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

   constructor() ERC721("TEST", "TST") {}

    struct Item {
        uint256 id;
        address creater;
        string uri;
    }

    mapping (uint256 => Item) public Items;

   function createItem(string memory uri) public returns (uint256,address) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);

        Items[newItemId] = Item(newItemId, msg.sender, uri);

        return (newItemId,msg.sender);
    }

     function tokenURI(uint256 tokenId) public view  override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return Items[tokenId].uri;
    }

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

    
}