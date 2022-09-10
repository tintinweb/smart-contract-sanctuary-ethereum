//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./Base64.sol";

contract ThreeDX is Ownable, ERC721 {
    using Strings for *;
    using Base64 for *;

    uint256 private _tokenId = 1;

    mapping(uint256 => string) private _metadata; //Ipfs address

    constructor() ERC721("ThreeDX", "3DX") Ownable() {}

    function getTokenId() public view returns (uint256) {
        return _tokenId;
    }

    function mint(string calldata metadata) public returns (uint256) {
        _safeMint(msg.sender, _tokenId);
        _metadata[_tokenId] = metadata;
        _tokenId++;
        return _tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _metadata[tokenId];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}