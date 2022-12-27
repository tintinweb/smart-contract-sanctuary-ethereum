// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";

contract SelfQuest is ERC721, Ownable {
    uint private constant TOKEN_LIMIT = 5;
    uint private _numTokens = 0;
    string private _imageBaseUrl;
    string private _imageBaseExtension;
    
    constructor() ERC721("SelfQuest", "SQ") {
        _imageBaseUrl = 'https://ipfs.io/ipfs/QmVDjMVTfaXg5JesHc3jKHcZpU7nFCEwxW2gQqdw9xDcNh/';
        _imageBaseExtension = '.jpg';

        for (uint i = 0; i < TOKEN_LIMIT; i++) {
            _create();
        }
    }
    
    function totalSupply() public pure returns (uint) {
        return TOKEN_LIMIT;
    }

    function _create() internal onlyOwner {
        require(_numTokens < totalSupply());
        _numTokens = _numTokens + 1;
        _safeMint(msg.sender, _numTokens);
    }

    function setImageBase(string memory imageUrl, string memory imageExtension) public onlyOwner {
        _imageBaseUrl = imageUrl;
        _imageBaseExtension = imageExtension;
    }
    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (tokenId > 0 && tokenId <= _numTokens) {
            return string(abi.encodePacked('data:application/json,{"name":"SelfQuest ', Strings.toString(tokenId), '","description":"One year of SelfQuest","image":"', _imageBaseUrl, Strings.toString(tokenId), _imageBaseExtension, '","external_url":"https://www.jeroenvanlierop.nl/"}'));
        } else {
            return "";
        }
    }
    
    function withdraw() public onlyOwner {
        require(address(this).balance > 0);
        payable(owner()).transfer(address(this).balance);
    }
}