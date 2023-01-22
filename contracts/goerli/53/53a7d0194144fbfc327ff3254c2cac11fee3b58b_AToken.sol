//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./AProject.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";

contract AToken is ERC721, ERC721Enumerable, ERC721URIStorage {
    address public owner;
    uint currentTokenId;

    constructor() ERC721("AToken", "ATK") {
        owner = msg.sender;
    }

   function mint(address to, string memory tokenId, string memory tokenURI) public {
        require(owner == msg.sender, "not an owner!");

        _mint(to, currentTokenId);
        _setTokenURI(currentTokenId, tokenId);

        currentTokenId++;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _baseURI() internal pure override returns(string memory) {
        return "ipfs://";
    }

    function _burn(uint tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
}