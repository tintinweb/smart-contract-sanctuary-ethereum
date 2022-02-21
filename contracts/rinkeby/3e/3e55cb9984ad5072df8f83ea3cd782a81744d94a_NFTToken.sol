// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./OpenZepplin.sol";

contract NFTToken is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable  {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(string => uint8) hashExistsMapping;

    constructor() ERC721("VR Avatars", "VRvatar") {}
    
    function mintToken(address recipient, string memory hash, string memory metadata) public onlyOwner returns (uint256) {
        //  Require unique hash and document it
        require(hashExistsMapping [hash] != 1);
        hashExistsMapping [hash] = 1;

        // Create new Token ID
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        _safeMint(recipient, newItemId);
        _setTokenURI(newItemId, metadata);        
        
        return newItemId;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
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