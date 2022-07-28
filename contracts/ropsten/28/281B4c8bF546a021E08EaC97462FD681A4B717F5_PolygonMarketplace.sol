// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721.sol";
import "./ERC721URIStorage.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Enumerable.sol";

contract PolygonMarketplace is ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable {
    uint256 private token_id = 0;
      
    string private base_token_URI;

    constructor() ERC721("PolygonMarketplace", "PolygonNFT") {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return base_token_URI;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        base_token_URI = baseURI;
    }

    function safeMint(address to, uint256 count) public onlyOwner {
        for(uint16 i = 0; i < count; i++){          
            token_id++;
            _safeMint(to, token_id); 
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
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

    // The following functions are overrides required by Solidity.

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

    function tokenOwner(address _user) public view returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_user);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_user, i);
        }
        return tokenIds;
    }

    function getbaseURI() public view returns (string memory) {
        return base_token_URI;
    }
}