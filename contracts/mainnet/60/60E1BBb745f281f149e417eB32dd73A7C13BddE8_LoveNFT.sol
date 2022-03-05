// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FullERC721.sol";

contract LoveNFT is ERC721Enumerable, Ownable {

    uint256 public _maxSupply = 10000;
    uint256 public _price = 0.069 ether;
    bool public _paused = false;

    mapping (uint256 => string) private _tokenId2tokenURI;
    
    constructor() ERC721("LoveNFT", "LOVENFT") Ownable() {
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "LoveNFT #', Strings.toString(tokenId), '", "description": "LoveNFT - NFT message for a loved one", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(_tokenId2tokenURI[tokenId])), '"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }
    function mint(string memory loveURI) external payable {
        uint256 tokenId = totalSupply() + 1;
        require(!_paused, "Sale paused");
        require(tokenId <= _maxSupply, "Exceeds maximum supply");
        require(msg.value >= _price, "Ether sent is not correct");

        _tokenId2tokenURI[tokenId] = loveURI;
        _safeMint(msg.sender, tokenId);
    }
    function setMaxSupply(uint256 newVal) external onlyOwner {
        _maxSupply = newVal;
    }
    function setPrice(uint256 _newPrice) external onlyOwner {
        _price = _newPrice;
    }
    function setPause(bool val) external onlyOwner {
        _paused = val;
    }
    function withdraw() external payable onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}