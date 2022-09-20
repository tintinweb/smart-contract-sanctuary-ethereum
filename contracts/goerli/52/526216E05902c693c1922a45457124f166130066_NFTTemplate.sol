// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./ERC721Enumerable.sol";

contract NFTTemplate is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;
    uint256 public constant TOTAL_SUPPLY = 20; // TODO
    string public baseTokenUri; // 
    string public baseExtension = ".json";
    bool public stopMint = false;

    constructor() ERC721("XXX NFT", "_^.^_") { // TODO
    }
    function setBaseUri(string memory _baseTokenUri) external onlyOwner{
        baseTokenUri = _baseTokenUri;
    }
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }
    function mintStopped() public onlyOwner {
        stopMint = true;
    }
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require( _exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    function mint(uint  beginIndex, uint  endIndex) public onlyOwner {
        require(!stopMint);
        require(beginIndex > 0 && beginIndex <= endIndex && endIndex <= TOTAL_SUPPLY);
        for (uint256 i = beginIndex; i <= endIndex; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}