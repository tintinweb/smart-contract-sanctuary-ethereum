// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../ERC721.sol";
import "../ERC721Enumerable.sol";
import "../ERC721URIStorage.sol";
import "../Ownable.sol";
import "../Counters.sol";
import "../ERC721Burnable.sol";

contract DragonBallZ is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Burnable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("DragonBallZ", "DBZ") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://dgbz.nft.com/tokens/";
    }

    function safeMint(address to, string memory uri) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override (ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns(string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override (ERC721, ERC721Enumerable) returns(bool) {
        return super.supportsInterface(interfaceId);
    }
}