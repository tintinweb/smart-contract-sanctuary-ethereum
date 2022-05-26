//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ERC721Enumerable.sol";
import "./ERC721.sol";
import "./Strings.sol";
import "./Base64.sol";

contract ThreeDX is Ownable, ERC721, ERC721Enumerable {
    using Strings for *;
    using Base64 for *;

    uint256 private _tokenId = 1;

    mapping(uint256 => string) private _images; //Ipfs address

    constructor() ERC721("ThreeDX", "3DX") ERC721Enumerable() Ownable() {}

    function mint(string calldata image) public returns (uint256) {
        _safeMint(msg.sender, _tokenId);
        _images[_tokenId] = image;
        _tokenId++;
        return _tokenId;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        string memory image = _images[tokenId];
        if (bytes(image).length == 0) {
            return "";
        }
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"3dx #',
                        Strings.toString(tokenId),
                        '","description":"generate by 3dx","image":"ipfs://',
                        image,
                        '","model":"xxx"}'
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );
        return output;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721) {
        super._burn(tokenId);
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